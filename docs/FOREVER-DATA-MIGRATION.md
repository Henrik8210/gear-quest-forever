# Forever data migration (phased)

GearQuest Forever targets **WoW Forever 1–60** (Classic+). The fork inherited TBC Anniversary data and tooling; we migrate in phases.

## Current state vs target (audit summary)

| Question | Answer |
|----------|--------|
| **Is the fork set up correctly?** | **Yes** — separate toc/package/SavedVariables, max level 60, L70 curated removed, migration phases documented. |
| **Is all BiS data Classic-correct?** | **Mostly** — all nine classes were re-scored on the Classic item pool (cap 60, Classic suffixes). Stat **weights** are still the TBC model. Forever-only item deltas are phase 4. |

**Done:** product split, `GQ.MAX_PLAYER_LEVEL`, phase **2** Classic suffix cache, phase **3** Classic `score.py` regen for all classes. **0** stale TBC +20/@7.9% fingerprint rows.

**Not done:** Classic/Forever **StatWeights**; Forever beta item deltas (phase 4). Do **not** copy TBC CurseForge ID `1669225` or TBC `CF_API_KEY`.

**Repo:** commit `scripts/`, `GearQuest/_generated/data/items_random.classic.json`, generated Lua patches, and docs together so another clone sees the same state — cache and generated files must stay in sync.

Fork base: GearQuest **v0.1.1-beta.3-bcc**, not a greenfield Classic regen.

| Phase | Scope | Status |
|-------|--------|--------|
| **1** | Product scope: max level **60**, remove TBC **level 70** curated data, clamp preview/simulate | **Done** |
| **2** | Random green suffix tables: Classic-era scrapes (not TBC R34) | **Done** — `count-suffix-coverage.mjs` **≥80% of scrapeable** IDs (Classic Wowhead 404 rows excluded via `noClassicPage`; gate: `--phase2-gate`) |
| **3** | Classic item pool: strip TBC/Outland IDs, cap generated bands at 60, then full re-score | **Done** — all classes re-scored via `pipeline/` (weights still TBC-derived) |
| **4** | Forever delta: beta tooltips, retuned item IDs, new quests/items | After beta client |
| **5** | Tag rows `forever-verified` vs `classic-assumption` as needed | Ongoing |

## Phase 1 details

- `GQ.MAX_PLAYER_LEVEL = 60` in `Core.lua`; `/gq level` and the simulate panel cap at 60.
- ~1,200 TBC Phase 3 (BT/Hyjal) entries removed from `GearQuest/Data.lua`.
- Generated lists are **10–60** Classic-pool `score.py` output; level **60** guide rows and early curated bands remain.
- TBC level-70 import scripts (`import-atlasloot-p3-bis.mjs`, `merge-all-p3-into-data.mjs`, etc.) are **legacy** for this repo — do not re-run into `Data.lua`.

## Phase 2 — Classic random enchants (workflow)

1. **Scrape** Wowhead **Classic** `/item={id}/random-enchants` for every item ID that appears on a generated row with `suffix=`:

   ```powershell
   # Wowhead rate-limits aggressive scrapes — use a slow delay and retry failures.
   $env:GQ_SCRAPE_DELAY_MS = "2000"
   node scripts/scrape-classic-random-enchants.mjs
   node scripts/scrape-classic-random-enchants.mjs --retry-403
   # Or one shot: scrape → apply → stale count
   node scripts/classic-suffix-sync.mjs --retry-403
   node scripts/classic-suffix-sync.mjs --retry-403 --phase2-gate   # exit 1 if scrapeable coverage below 80%
   ```

   Parser accepts Wowhead **q2** and **q3** suffix lines. Pass `--reprobe-empty` only when intentionally refetching stale **empty** cache rows (sync does **not** enable it by default). The scraper **never** replaces an existing enchant table with an empty parse. **Do not** use global `--refresh` without `--ids` unless you mean to re-fetch every item.

   Cache: `GearQuest/_generated/data/items_random.classic.json`

2. **Patch** generated pick rows — `suffixChance`, `suffixRange`, and **score** (expected suffix-stat delta vs cached TBC tables):

   ```powershell
   node scripts/apply-classic-random-enchants.mjs
   ```

   When the stat band changes, **`suffixId` is dropped** on that row until re-verified on the Forever/Classic client (wrong id is worse than range-only tooltips).

3. **Verify**:

   ```powershell
   node scripts/check-era-classic.mjs
   node scripts/count-suffix-coverage.mjs         # % of suffix item IDs with Classic tables
   node scripts/count-stale-tbc-suffix-rows.mjs   # known TBC fingerprint rows left
   node scripts/verify-generated-bis.mjs
   ```

**Note:** `apply-classic-random-enchants.mjs` patches both **pick** rows (with `score`) and **notable** rows (jackpot shelf, no score). An earlier pass only updated picks; notables at 53+ kept TBC suffix text until fixed.

Era fingerprint: **Vice Grips (9640)** — Classic `of Strength` **+17 @ 9.0%**; TBC **+20 @ 7.9%**.

## Phase 2 learnings (Sep 2026)

Operational lessons from finishing the Classic random-enchant pass. Use this before re-scraping or re-applying.

### Wowhead scraping

- **Rate limits (403):** Default to slow scrapes (`GQ_SCRAPE_DELAY_MS=2500`–`3000`). Use `--retry-403`; expect multi-hour full passes on ~772 IDs.
- **Do not run two scrapes or apply+scrape concurrently** on `items_random.classic.json` — incremental `writeFileSync` races can shrink or corrupt the cache.
- **Never overwrite good cache rows with empty parses** — rate-limited HTML that parses as “no enchants” must not replace a row that already has `enchants`. The scraper now skips that; `--reprobe-empty` is opt-in only.
- **Global `--refresh` without `--ids`** once wiped the whole cache (fixed: always load existing file; refresh only per forced id).
- **404 on Classic Wowhead:** **162** suffix item IDs (mostly TBC green templates, e.g. 24xxx / 31xxx) have no Classic `/random-enchants` page. Store as `noClassicPage` and exclude from the **scrapeable** denominator; do not retry them every sync.
- **Parser:** Wowhead suffix lines use **q2** and **q3** spans; missing q2 caused false `empty` until fixed.

### Apply / verify

- **Notable rows** (no `score` in the row) must use the same patch regex as picks — an early apply pass left notables on TBC suffix text until fixed.
- When Classic **suffixRange** differs from TBC, **`suffixId` is stripped** on that row (intentional). `verify-generated-bis.mjs` accepts Classic band spot checks (e.g. 6570, 9775) without `suffixId`.
- **`suffixId` coverage** in generated data will stay **below** the old 95% bundle target until phase 3 regen or in-client re-verification — not a phase 2 failure by itself.
- **`apply-classic-random-enchants.mjs`** builds/refreshes `items_random.tbc.json` for score deltas; keep it with the Classic cache in git.

### Pipeline / CI

- **`classic-suffix-sync.mjs --phase2-gate`:** Phase 2 “done” = **≥80% of scrapeable** suffix IDs with Classic tables (not raw 772 if 404s are marked). Sep 2026 result: **610 / 610 scrapeable (100%)**, **79%** of all 772 IDs.
- **`check-era-classic.mjs`** may hit a Node **UV_HANDLE_CLOSING** assertion on Windows after live fetch; sync treats era check as non-fatal. Prefer cache-only checks when Wowhead is rate-limited.
- **`prune-classic-cache.mjs`:** Only when intentionally dropping bad empty rows before a refetch — never prune rows with `enchants`.

### Outstanding after phase 3 regen

| Item | Notes |
|------|--------|
| **Stat weights** | Still TBC-derived in `pipeline/data/weights.json`. See [Stat weights](#stat-weights-tbc-model--forever-client) below. Do **not** invent a full Forever scale until the beta client is in hand. |
| **Forever client** | Interface version, tooltips, new/retuned items — phase 4. |
| **Push hygiene** | After regen, commit **generated Lua + pipeline inputs + scripts** together. |

## Phase 3 — Classic item pool regen (done)

Prerequisites: `count-stale-tbc-suffix-rows.mjs` at **0** (met) and phase 2 scrapeable coverage gate (met).

### Pipeline in this repo (Sep 2026)

The TBC authoring tree is now `pipeline/` (ignored by CurseForge). Operational
guide for beta item deltas: [../pipeline/docs/FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md).

All nine classes were re-scored with `score.py` (Classic `classic_item_ids.json` pool,
Classic `items_random.json`, bands **10–60**). Paladin/Warrior Alliance 1–9 stays
curated in `Data.lua`; their Horde 1–9 files are generated. Other classes have
both-faction Early 1–9 files.

Sep 2026 counts: **57,202** generated + **287** curated = **57,489**. Relic/libram
slots stay thin (few Classic relics have stats).

The older filter (`filter-generated-classic.mjs`) is only for emergency rollback;
do not re-run it over a Classic regen.

**Honest limit:** rank order is a real Classic-pool top 3, but **stat weights** are
still the TBC model (expertise, armour pen, TBC paladin seals). Forever-only items
are phase 4.

### Still required after phase 3

1. **Stat weights** — see below. Optional Classic zero-out now; real Forever scale after the beta client.
2. Phase 4: Forever-only item ids and tooltip retunes as the beta client shows them.

Keep the pipeline **out of the CurseForge addon zip** (`.pkgmeta` already ignores `pipeline/`).

## Stat weights (TBC model → Forever client)

`pipeline/data/weights.json` is still the **TBC Anniversary** scale. Phase 3 re-scored the **item pool** (Classic IDs, Classic suffixes, cap 60) but did not retune what a point of each stat is worth. Level **60** rows mostly come from Wowhead Classic guides, so bad weights hurt **10–59** the most.

What is TBC-specific today (not just “a bit off”):

- **Expertise** and **armor penetration** are non-zero on melee specs. Classic 1–60 does not have those ratings, so leftover TBC rating lines in `items.json` can still steal ranks.
- Paladin **`dpsWeight` 4.31** was derived from TBC seal/judgement math (including Seal of Blood). Classic seals differ.
- Hunter ranged weight includes **TBC Steady Shot** scaling off weapon damage.

**Do this on the Forever client (phase 4), not from memory:**

1. After first login, note whether rating stats exist, how seals/shots/talents work, and any Forever-only stats.
2. Edit `pipeline/data/weights.json` (and `score.py` comments such as `DPS_PER_STR` if seal math changes).
3. Re-run `score.py` / `payload.py` / the 1–9 emitter per affected class; copy Lua into `GearQuest/_generated/`.
4. Run `node scripts/verify-generated-bis.mjs`.

Forever is Classic+, so do **not** blindly paste vanilla 1.12 weights if the combat model moved.

**Optional before beta** (cheap Classic cleanup, redo after Forever): set `expertise` and `armorPen` to `0` on every spec, and stop using TBC-only weapon formulas. Do not invent a full Forever scale until you have played the client.

After a Classic/`score.py` regen, do **not** run `apply-classic-random-enchants.mjs` — that patches TBC-scored Lua against Classic tables. Suffixes are already Classic in `pipeline/data/items_random.json`.

See also [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md), [DATA_RULES.md](./DATA_RULES.md), [SUFFIX-RANDOM-ENCHANT.md](./SUFFIX-RANDOM-ENCHANT.md), and [PROJECT_BRIEF.md](./PROJECT_BRIEF.md).
