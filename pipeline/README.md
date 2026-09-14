# GearQuest BiS pipeline (developer asset)

This folder **rebuilds** the generated BiS Lua. It is **not** shipped on CurseForge
(`.pkgmeta` ignores `pipeline/`). Players only get `GearQuest/_generated/*.lua`.

When Forever beta shows a new or retuned item, follow
[docs/FOREVER-SCORING.md](docs/FOREVER-SCORING.md): add facts to `data/items.json`
and `data/sources.json`, append the id to `data/classic_item_ids.json`, re-score,
copy Lua into `GearQuest/_generated/`.

**Requires Python 3** (3.12 is installed on the authoring PC as of Sep 2026).

Paths: `scripts/gq_paths.py` (repo-relative). Scoring is capped at **level 60** and
the item pool is `classic_item_ids.json`. Random suffixes are Classic (Vice Grips
**+17 @ 9%**), converted from `GearQuest/_generated/data/items_random.classic.json`.

Original archive notes below.

---

# GearQuest BiS pipeline — archive

Everything needed to regenerate GearQuest's gear data from scratch. Archived
2026-09-14 from the cloud session that built it, because none of this lived in
the addon repo — the repo has only the *outputs*.

Verified before archiving: re-running the scorer on mage reproduced the shipped
`mage.json` **byte for byte** (13.51 MB, identical JSON). The pipeline works.

---

## Layout

| Folder | What it is |
|---|---|
| `scripts/` | The pipeline. 41 Python files. |
| `data/` | Inputs the scripts read — item tables, sources, stat weights, lore. |
| `data/dbc/` | Raw client DBC extracts (TBC 2.4.3 and 2.5.4) as CSV. |
| `guides/` | Level-60 BiS guide overrides per class, plus the raw text they were parsed from. |
| `exports/` | Per-class guide/weight copies as handed to Cursor. |
| `generated/` | The 18 `Data.*.generated.lua` files and `lore.json` as shipped. |
| `docs/` | Pipeline documentation and every Cursor hand-off note, in order. |

---

## The important file

`scripts/score.py` (831 lines) is the scorer and the heart of the whole thing.
For every class x spec x level x slot it scores every eligible item, takes the
top 3, and collapses consecutive identical results into level bands.

Read the comments before changing anything — they record *why* each rule exists,
usually because it was wrong once. A few that cost real time to find:

- `DPS_PER_STR = 4.31` — derived, not guessed. 1 Strength = 2 attack power,
  which buys 0.143 white dps + 0.044 seal dps + 0.045 judgement dps = 0.232.
  So 1 weapon dps = 4.31 Strength, independent of weapon speed. The old
  hand-set retribution `dpsWeight` of 1.75 was 2.5x too low and let a crit-heavy
  rare outrank the level-60 PvP epics.
- `CLASS_RACES` — a Horde paladin in TBC is a Blood Elf and nothing else. The
  blanket faction mask had put Durotar and Mulgore quest gear in its list.
- Faction-exclusive *zones* are gated separately from races: a vendor in
  Darnassus is not race-restricted, the city is.
- The off-hand rules: one-handers are duplicated into the off hand only for
  `onehand_dual` / `twohand_or_onehand` styles (gating on "can dual wield"
  alone gave prot warriors one-handers on their notable shelf), and the proc
  weight is *not* halved there — Dual Wield halves swing damage, not procs.
- `onUseOnly` — if a slot's dps weight is 0 the character never attacks with it,
  so only `Use:` lines can fire. Without this, a zero-stat proc bow was the #1
  rogue ranged pick in 204 bands.
- `route_for()` — the two-hander versus main-hand+off-hand call.

---

## How to run it

Scoring scripts import `gq_paths.py` (repo-relative). Run them from
`pipeline/scripts`. JSON outputs go to `pipeline/out/` (gitignored).
DBC rebuild scripts (`build_items.py`, `build_sources.py`) still expect a
TBC `tbc.db` that is **not** in this repo — do not run those for Forever.

Scoring one class:

```powershell
cd pipeline/scripts
$env:GQ_CLASS = "MAGE"
$env:GQ_GUIDES = "guides_mage.json"
$env:GQ_OUT = "mage.json"
python score.py
python payload.py
python emit_early.py
```

`GQ_GUIDES` is under `pipeline/guides/`. `GQ_OUT` is under `pipeline/out/`.
Defaults are `guides.json` and `paladin.json` — paladin was the first class,
which is why there is no `PALADIN.guides.json`.

Then copy the emitted Lua into `GearQuest/_generated/` and run
`node scripts/apply-classic-random-enchants.mjs` plus
`node scripts/verify-generated-bis.mjs` from the repo root.

After refreshing Classic Wowhead suffix cache:

```powershell
node scripts/convert-classic-random-to-pipeline.mjs
```

## The checks

Ten standing checks, plus a Lua integration test that loads the output against
the addon's real `DataAdapter.lua`. Run them after any scoring change:

```
check_era.py  check_roles.py  check_levels.py  check_suffix_ids.py
check_offhand.py  check_ranged.py  check_school.py  check_caster_weapons.py
guide_check2.py  luatest.py
```

They exist because three separate times a fix was applied to one code path and
missed a parallel one — suffix ids (picks vs notables vs the 1-9 emitters), and
school-specific spell damage (base items vs random suffixes). Several checks
therefore assert **per file** rather than on a global aggregate, because a 1%
dip in a global coverage number hid a bug that had broken 137 of 137 rows.

`rebuild_bench.py` re-splices a class's current payload into its bench HTML page,
so a bench page cannot silently go stale.
