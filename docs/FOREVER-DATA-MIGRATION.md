# Forever data migration (phased)

GearQuest Forever targets **WoW Forever 1–60** (Classic+). The fork inherited TBC Anniversary data and tooling; we migrate in phases.

## Current state vs target (audit summary)

| Question | Answer |
|----------|--------|
| **Is the fork set up correctly?** | **Yes** — separate toc/package/SavedVariables, max level 60, L70 curated removed, migration phases documented. |
| **Is all BiS data Classic-correct?** | **Not yet** — still **TBC Anniversary leveling** (`_generated` 10–69) clamped at runtime to 60; Classic suffixes only where scraped/applied; weights still TBC-derived. |

**Done:** product split, `GQ.MAX_PLAYER_LEVEL`, Classic suffix scrape/apply/check tooling, partial Classic tables in `items_random.classic.json`, pick + **notable** row patches for cached items (e.g. Vice Grips +17 @ 9%).

**Not done:** regen **10–59** from Classic-only pool (phase 3); Classic/Forever **StatWeights**; Forever beta item deltas (phase 4). **162** suffix item IDs have no Classic Wowhead random-enchant page (TBC-era greens) — suffix metadata on those rows stays TBC until phase 3 pool regen. Do **not** copy TBC CurseForge ID `1669225` or TBC `CF_API_KEY`.

**Repo:** commit `scripts/`, `GearQuest/_generated/data/items_random.classic.json`, generated Lua patches, and docs together so another clone sees the same state — cache and generated files must stay in sync.

Fork base: GearQuest **v0.1.1-beta.3-bcc**, not a greenfield Classic regen.

| Phase | Scope | Status |
|-------|--------|--------|
| **1** | Product scope: max level **60**, remove TBC **level 70** curated data, clamp preview/simulate | **Done** |
| **2** | Random green suffix tables: Classic-era scrapes (not TBC R34) | **Done** — `count-suffix-coverage.mjs` **≥80% of scrapeable** IDs (Classic Wowhead 404 rows excluded via `noClassicPage`; gate: `--phase2-gate`) |
| **3** | Regenerate 10–59 picks: Classic-only item pool + revised stat weights | **Next** — requires external `score.py` / pipeline (not in repo); see § Phase 3 |
| **4** | Forever delta: beta tooltips, retuned item IDs, new quests/items | After beta client |
| **5** | Tag rows `forever-verified` vs `classic-assumption` as needed | Ongoing |

## Phase 1 details

- `GQ.MAX_PLAYER_LEVEL = 60` in `Core.lua`; `/gq level` and the simulate panel cap at 60.
- ~1,200 TBC Phase 3 (BT/Hyjal) entries removed from `GearQuest/Data.lua`.
- Generated pipeline still covers **10–69** (TBC-era pool until phase 3); level **60** guide rows and early curated bands remain.
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

## Phase 3 — Classic item pool regen (not started)

When `count-stale-tbc-suffix-rows.mjs` stays at **0** and `items_random.classic.json` covers the ~772 suffix-item IDs:

1. Rebuild item stats/sources from **Classic** Wowhead (not wowsims-tbc).
2. Filter to Classic 1.12 item ID set (+ Forever additions later).
3. Re-run ranking (`score.py` / pipeline — lives outside this repo today) with **Classic** stat weights.
4. Re-emit `GearQuest/_generated/*.generated.lua` and run `verify-generated-bis.mjs`.

Until then, generated **10–69 TBC picks** remain the BiS database, capped at **60** in the addon.

See also [DATA_RULES.md](./DATA_RULES.md), [SUFFIX-RANDOM-ENCHANT.md](./SUFFIX-RANDOM-ENCHANT.md), and [PROJECT_BRIEF.md](./PROJECT_BRIEF.md).
