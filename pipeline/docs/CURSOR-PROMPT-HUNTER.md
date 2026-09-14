# Paste this into Cursor (in the GearQuest repo)

Adding generated best-in-slot data for **Hunter**, plus corrected **Warrior** and
**Paladin** files. Four scoring bugs were fixed since the last import, so all three
classes are regenerated — details below, because two of them change data you already
merged.

## Files

Extracted from `GearQuest-Hunter-BiS.zip`.

| file | where | note |
|---|---|---|
| `Data.Hunter.generated.lua` | `GearQuest/_generated/` | **new** — 7,233 picks, levels 10–69, beast_mastery / marksmanship / survival, both factions |
| `Data.Hunter.Early.1to9.generated.lua` | `GearQuest/_generated/` | **new** — 427 picks, levels 1–9, **both factions in one file** |
| `Data.Warrior.generated.lua` | `GearQuest/_generated/` | **replaces** — 8,094 picks |
| `Data.Warrior.Horde.1to9.generated.lua` | `GearQuest/_generated/` | **replaces** — 248 picks |
| `Data.Paladin.generated.lua` | `GearQuest/_generated/` | **replaces** — 6,999 picks |
| `Data.Paladin.Horde.1to9.generated.lua` | `GearQuest/_generated/` | **replaces** — 221 picks |
| `DataAdapter.lua` | `GearQuest/` | **replaces** — two new SOURCES entries and `factionInRow` |
| `HUNTER.weights.json`, `HUNTER.guides.json`, `pvp_prefix_faction.json` | `GearQuest/_generated/` | reference only, not loaded |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` | **replaces** — gained sections 8 and 9 |

**`.toc`: add two lines** after the warrior pair and before `DataAdapter.lua`:

```
_generated\Data.Hunter.generated.lua
_generated\Data.Hunter.Early.1to9.generated.lua
```

## The adapter change

Two new `SOURCES` entries, and one new flag. Hunter is **not** in `ALLIANCE_MAIL` /
`MAIL_MELEE`, so unlike warrior and paladin it has no hand-curated early data on
either side. Its 1–9 file therefore carries **both** factions and each row names its
own:

```lua
{ class = "HUNTER", picks = "hunterEarly1to9", facts = "hunterEarly1to9Facts",
  hasSpec = false, factionInRow = true },
```

Without `factionInRow` every row falls back to the source's fixed faction, which is
nil for this file — so all 427 rows would show to both factions.

`Spec.lua` currently has `marksmanship` marked `comingLater = true`. There is now
data for it (2,407 entries), so that flag can come off when you are ready.

## Why Warrior and Paladin are regenerated too

Four fixes, all found by Henrik pointing at single items. Two change data you merged:

1. **A stun is worth zero.** Bosses are stun-immune, and *Tidal Charm*'s tooltip says
   it is resisted above level 60 — it is a PvP trinket. Priced as damage avoidance it
   was the entire score of an item with no stats. 64 picks per class removed.
2. **Ranking moved from the best random-enchant roll to the expected roll.** Valuing
   every random item at its jackpot let *Vice Grips* "of Strength" — a **7.9%** roll —
   outrank *Edgemaster's Handguards*, a guaranteed epic, from level 44 to 55. The
   jackpot is still shown: it moved to the notable shelf with its suffix and
   `suffixChance`, which is where a hunt target belongs. **This is the change that
   moved the most rows** — about 49% of paladin cells, and band counts fell ~15%
   because a lot of one-level flicker was roll noise.
3. **Conditional stats count at one third.** "Increases attack power by 60 **when
   fighting Undead**" was scored as flat +60 AP. 41 items affected.
4. **PvP name families are faction-gated**, now including *Sentinel's* / *Protector's*
   / *Senior Sergeant's*, which were settled by mirror-pairing against already-gated
   Horde families.

**If your repo has `scripts/fix-edgemaster-warrior.mjs`, read this before re-running
it.** Edgemaster's now comes out rank 1 for arms and fury at 44–54, rank 2–3 at 55–58,
out of the top 3 at 59, and rank 2 at 60 where the guide puts it. So the script is no
longer correcting a bug — it is a judgement call about a close race with *Backusarian
Gauntlets*. Henrik's call whether to keep it. `scripts/fix-rare-elite-sourcetype.mjs`
is unaffected and should be re-run.

## Do not change

- **`Data.lua` is hand-curated and authoritative.** Hunter holds 80 level-70 rows
  (beast_mastery 45, survival 35 — none for marksmanship).
- **Level 70 is absent from all generated data.** Do not extend the range.
- **`origin="guide"` bands are in the guide's tier order and must never be re-sorted
  by `score`.** The score column is deliberately non-monotonic down those lists.
- **`score` is comparable only within one slot/spec/level.** Never show it as a stat.

## Verify

- `#GQ.Data.entries` == **curated + 23,222**. With 1,177 curated that is **24,399**.
- **Zero duplicate `id` values.**
- Hunter: **no plate, no shields, no maces** in any pick — hunters cannot use them.
  This is the cheapest regression test for the class and it currently passes at 0.
- Hunter `Ranged` is populated at **every** level 1–69. It is the hunter's real
  weapon, so an empty Ranged band is a serious bug, not cosmetic.
- Hunter early file: every one of the 427 rows has a faction. `noFaction` must be 0.
- PvP pairs still split by faction — `Sentinel's Chain Leggings` Alliance only,
  `Outrider's Chain Leggings` Horde only, and the five warrior pairs from last time.
- No entry with `minLevel > maxLevel`; nothing above level 69.

## Then

Extend the class-agnostic UI work to Hunter. It is the same fields; the only new thing
is that `hunterNotable` now carries `suffix` / `suffixChance` on its rows, so the
"hunt this roll" affordance applies to the notable shelf as well as the top 3.
