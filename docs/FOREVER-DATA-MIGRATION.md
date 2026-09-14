# Forever data migration (phased)

GearQuest Forever targets **WoW Forever 1–60** (Classic+). The fork inherited TBC Anniversary data and tooling; we migrate in phases.

## Current state vs target (audit summary)

| Question | Answer |
|----------|--------|
| **Is the fork set up correctly?** | **Yes** — separate toc/package/SavedVariables, max level 60, L70 curated removed, migration phases documented. |
| **Is all BiS data Classic-correct?** | **Not yet** — still **TBC Anniversary leveling** (`_generated` 10–69) clamped at runtime to 60; Classic suffixes only where scraped/applied; weights still TBC-derived. |

**Done:** product split, `GQ.MAX_PLAYER_LEVEL`, phase **2** Classic suffix cache (**610** scrapeable IDs, **100%** Classic tables), apply pass on pick + **notable** rows, **0** stale TBC +20/@7.9% fingerprint rows.

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

### Outstanding after phase 2 (not blockers for phase 3 planning)

| Item | Notes |
|------|--------|
| **162 suffix rows** | Still TBC suffix metadata in `_generated` until phase 3 removes/remaps those item IDs. |
| **BiS pool / levels** | Generated picks still **10–69 TBC** pool, runtime cap **60** — phase 3. |
| **Stat weights** | Still TBC-derived JSON in `_generated` — phase 3. |
| **Forever client** | Interface version, tooltips, new items — phase 4. |
| **Push hygiene** | After scrape/apply, commit **cache + generated Lua + scripts** together (see repo note above). |

## Phase 3 — Classic item pool regen (not started)

Prerequisites: `count-stale-tbc-suffix-rows.mjs` at **0** (met) and phase 2 scrapeable coverage gate (met). Then:

1. Rebuild item stats/sources from **Classic** Wowhead (not wowsims-tbc).
2. Filter to Classic 1.12 item ID set (+ Forever additions later).
3. Re-run ranking (`score.py` / pipeline — lives outside this repo today) with **Classic** stat weights.
4. Re-emit `GearQuest/_generated/*.generated.lua` and run `verify-generated-bis.mjs`.

Until then, generated **10–69 TBC picks** remain the BiS database, capped at **60** in the addon.

See also [DATA_RULES.md](./DATA_RULES.md), [SUFFIX-RANDOM-ENCHANT.md](./SUFFIX-RANDOM-ENCHANT.md), and [PROJECT_BRIEF.md](./PROJECT_BRIEF.md).
