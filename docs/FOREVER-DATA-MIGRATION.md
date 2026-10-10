# Forever data migration (phased)

GearQuest Forever targets **WoW Forever 1–60** (Classic+). The fork inherited TBC Anniversary data and tooling; we migrate in phases.

## Current state vs target (audit summary)

| Question | Answer |
|----------|--------|
| **Is the fork set up correctly?** | **Yes** — separate toc/package/SavedVariables, max level 60, L70 curated removed, migration phases documented. |
| **Is all BiS data Classic-correct?** | **Mostly** — all nine classes are on the Forever combat scale (jackpot suffixes, leveling survivability + endurance, `GQ_NO_GUIDES=1`). Item facts come from Wowhead Forever hunt tips (`sync_forever_item_stats.py`). Classic ids that 404 still need replacements. |

**Done:** product split, `GQ.MAX_PLAYER_LEVEL`, phase **2** Classic suffix cache, phase **3** Classic `score.py` regen for all classes. **0** stale TBC +20/@7.9% fingerprint rows.

**Not done:** Classic/Forever **StatWeights**; Alliance Forever deltas; classic ids that 404 on Wowhead Forever still need replacements as the community catalogs them. Expect **many Wowhead scrape/ingest/re-score cycles** over the coming months — the catalog is incomplete, not a one-shot import. CurseForge project is **1698950**. Do **not** copy TBC CurseForge ID `1669225` or TBC `CF_API_KEY`.

**Hunts:** target **three items per slot per level** (lower-req leftovers are valid rank 2/3). Empty slots are usually a gate bug (example: Horde WSG runes 21565–21568 pinned to Illiyana, so no trinket until 28). Level-9 Finger toast is Alliance paladin/warrior only — Horde shaman has no Forever-ok ring until ~15 (8350/21931 404).

**Repo:** commit `scripts/`, `GearQuest/_generated/data/items_random.classic.json`, generated Lua patches, and docs together so another clone sees the same state — cache and generated files must stay in sync.

**Local playtest:** after `_generated/` or `GearQuest/*.lua` changes, run `scripts/sync-addon.ps1` so `_classic_beta_/Interface/AddOns/GearQuestForever` matches the repo (documented in README and DATA_RULES).

**Relics (phase 4+):** ingest tooltips → `patch_relic_effects.py` → re-score; combat BiS for totems/idols/librams uses `relic_score.py`, not ilvl alone.

Fork base: GearQuest **v0.1.1-beta.3-bcc**, not a greenfield Classic regen.

| Phase | Scope | Status |
|-------|--------|--------|
| **1** | Product scope: max level **60**, remove TBC **level 70** curated data, clamp preview/simulate | **Done** |
| **2** | Random green suffix tables: Classic-era scrapes (not TBC R34) | **Done** — `count-suffix-coverage.mjs` **≥80% of scrapeable** IDs (Classic Wowhead 404 rows excluded via `noClassicPage`; gate: `--phase2-gate`) |
| **3** | Classic item pool: strip TBC/Outland IDs, cap generated bands at 60, then full re-score | **Done** — nine classes, Forever weights, bands 1–60. See [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md) |
| **4** | Forever delta: beta tooltips, retuned item IDs, new quests/items, new zones | **Horde `foreverDelta` in `Data.lua` done.** New Forever-only loot (id ≥ 200000) comes from Wowhead ingest. Alliance Wowhead coverage still incomplete. |
| **5** | Tag rows `forever-verified` vs `classic-assumption` as needed | Ongoing |

### Phase 4 watch list (do not invent Data.lua rows)

Forever-only loot stays out of generated lists until Wowhead has an item page. Scrape and ingest:

```powershell
node scripts/scrape-forever-wowhead-items.mjs
python pipeline/scripts/ingest_forever_wowhead.py
node scripts/diff-veldt-wowhead.mjs
```

Ingest inserts new ids only. An existing `items.json` row keeps its facts. Then recheck every item still marked Unsourced: if Wowhead now names a quest, a vendor, or a dropper, fill that source and run `index_coordinates.py --ids` for those ids. Re-score with `python pipeline/scripts/rescore_hunter_shaman.py`, one class at a time. Do not `reemit_all.py` from stale `pipeline/out/*.json`. The scrape cache (`pipeline/data/forever_wowhead/`) is gitignored. Full steps: [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md).

**Wowhead is still the ingest source.** [veldt1 Forever Item Explorer](https://veldt1.github.io/wowf-items/) is a second reference: a client-diff of beta `1.60.1` vs Classic `1.15.9` with stats computed from DBC (`StatPercentEditor × RandPropPoints`). `diff-veldt-wowhead.mjs` downloads that table and reports (1) Forever equipment veldt has that Wowhead has not indexed yet, and (2) Wowhead tooltips still missing combat stats where veldt already has numbers. Do **not** merge veldt rows into `items.json` from that report — use it to decide what to re-scrape or verify on Wowhead.

The in-game **seen-item notebook is retired**. Do not run `scripts/backup-seen-notebook.ps1`. `GQ.Collector` is not started. `/gq seen` tells you Wowhead is the source. Horde `foreverDelta` rows already in `Data.lua` stay; new Forever items come from Wowhead as the catalog grows.

Classic ids that 404 on `wowhead.com/forever/item={id}` (example: **Bands of Serra'kis**, 6902) are likely gone or retuned. Leave them until a Forever replacement is catalogued — do not invent ids.

New zones to attach hunts to later ([Wowhead zone guide](https://www.wowhead.com/forever/guide/zones-maps-locations-rewards)):

| Zone | Band / notes |
|------|----------------|
| **Zephras Isle** | Skyborne start **1–12**. Faction (Alliance/Horde) is chosen at 1. Horde quest/craft IDs from the beta notebook are in `Data.lua`; Alliance starter items wait on Wowhead. |
| **Riverglades** | Frontier **35–45**. Steamwheedle boat to **Powderfuse Port**. |
| **Shen'Dralas** | Between Mulgore and Desolace (Shen'dralar / Dire Maul). Quests send you to Razorfen Downs and Maraudon. |
| **Mount Hyjal** | **Level 60** after Archimonde. First 20-player raid **Hyjal Summit** in December. |

Curated Alliance paladin/warrior 1–9 greens need the same `suffix` / `suffixChance` / `suffixRange` fields as generated rows, or the log shows the base name with no roll. Runtime `Data:SanitizeText` replaces em-dash / middle-dot (WoW fonts cannot draw them). Pipeline world-drop copy uses ASCII hyphens.

### Phase 4 — Horde notebook (done)

Horde `foreverDelta` rows in `Data.lua` were scored from beta `seenItems` tooltips against generated #1 until they lose. Compare still shows the top 3. Do not invent IDs or stats.

| Class | What landed |
|-------|-------------|
| **Shaman** | Windcarved totem, Skychain / Ranger shoes / Highlands mail 1–9, ele/resto sashes, copper boots |
| **Mage** | Sashes plus Frothing / Fiery / Golden / Gilded slippers |
| **Warlock** | Sashes, Black / Gilded / Fiery dest crafts |
| **Druid** | Windcharged Leaf idol, balance/resto sashes, Gilded resto/balance |
| **Rogue** | Bandit’s Jerkin, Vuldren wrist (leather only) |
| **Priest** | Ardent / Arcanist / Gilded / Black sashes by spec |
| **Hunter** | Mail 1–9 plus Gemmed / Glowing copper at 10 |
| **Paladin** | Short mail 1–2/3, holy healer crafts, ret/prot copper; no Forever libram yet |
| **Warrior** | Mail 1–2/3 + Watcher L1, Gemmed 10–15, Strange prot r2 |

Alliance Forever items stay out until Wowhead (or a verified tooltip) has IDs and stats.

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
| **Stat weights** | Forever scale in `pipeline/data/weights.json`. Do not retune unless asked. Look up proposals in the [class stat-weight sheet](https://docs.google.com/spreadsheets/d/1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok/edit). Live rules: [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md). |
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

Sep 2026 counts after per-spec 1–9 scoring: **59,403** generated
+ **368** curated = **59,771**. Relic/libram slots stay thin (few Classic relics
have stats). New Forever items can displace Classic rows in the top 3.

The older filter (`filter-generated-classic.mjs`) is only for emergency rollback;
do not re-run it over a Classic regen.

Rank order is the Forever model: Classic pool plus indexed Forever gear, jackpot suffixes, and the weights in `weights.json`. Priest, mage, and warlock ranged damage is 7. Hunter ranged is a bow, gun, or crossbow. Horde Forever starter rows in `Data.lua` still use `foreverDelta`. Alliance early pieces come from the generated Early 1–9 files.

### Still required after phase 3

Phase 4 continues as Wowhead Forever gains items: ingest new ids, recheck Unsourced, index coordinates, re-score the class. Do not retune weights unless asked.

Keep the pipeline **out of the CurseForge addon zip** (`.pkgmeta` already ignores `pipeline/`).

## Stat weights

`pipeline/data/weights.json` is the Forever scale. Damage first, then survivability below 60, then endurance. Level 60 is the raw raid-scale weights. Priest, mage, and warlock `dpsWeightRanged` is **7**. Hunter ranged damage is real, and the ranged weapon is a bow, gun, or crossbow. Do not change a weight unless asked. Proposed changes are looked up in [GearQuest Forever - Class Stat Weights](https://docs.google.com/spreadsheets/d/1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok/edit): the live grid is locked, and suggestions sit at the bottom of each class tab. A suggestion does not change the addon until it is copied into `weights.json`. The rules live in [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md).

Re-score with `python pipeline/scripts/rescore_hunter_shaman.py` and the class name. Do not `reemit_all.py` from stale JSON.

After a re-score, do **not** run `apply-classic-random-enchants.mjs`. Suffixes are already Classic in `pipeline/data/items_random.json`.

See also [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md), [DATA_RULES.md](./DATA_RULES.md), [SUFFIX-RANDOM-ENCHANT.md](./SUFFIX-RANDOM-ENCHANT.md), and [PROJECT_BRIEF.md](./PROJECT_BRIEF.md).
