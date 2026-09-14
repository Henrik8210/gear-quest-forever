# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.1.0-beta.1-forever

- New repo and CurseForge packaging for WoW Forever (beta 17 Sep 2026).
- In-game title **GearQuest Forever**; slash commands stay `/gq` and `/gearquest`.
- `## Interface: 11507` is a placeholder until the beta client reports `lastAddonVersion`.
- Sync script targets a Forever client folder (`_forever_` and similar), not `_anniversary_`.
- No TBC CurseForge project ID or GitHub secrets were copied.

### Install name (distinct from TBC GearQuest)

- Game / CurseForge folder **`GearQuestForever`** (`GearQuestForever.toc`); saved variables **`GearQuestForeverDB`** so it can sit beside TBC **`GearQuest`** on the same client.

### Data (Forever migration phase 2 — partial)

- Classic Wowhead random-enchant scrape/apply pipeline (`scripts/scrape-classic-random-enchants.mjs`, `apply-classic-random-enchants.mjs`, `classic-suffix-sync.mjs`, `check-era-classic.mjs`).
- Cache: `GearQuest/_generated/data/items_random.classic.json` — run `node scripts/classic-suffix-sync.mjs --retry-403` with `GQ_SCRAPE_DELAY_MS=2500` (add `--reprobe-empty` only when intentionally refetching stale empties).
- Scraper no longer overwrites cached enchant tables with empty rows on parse/rate-limit failures.
- Generated picks/notables patched for Classic suffix chance, range, and score where cache has tables (Vice Grips **9640**: **+17 @ 9%**); `suffixId` dropped when Classic range differs from TBC.
- Apply script patches **notable** rows as well as scored pick rows.
- Phase 2 target: `count-suffix-coverage.mjs` ≥80% (re-run sync after Wowhead 403/404 bursts; many high-id green templates 404 on Classic).

### Data (Forever migration phase 1)

- Cap addon scope at **level 60** (`GQ.MAX_PLAYER_LEVEL`); preview/simulate clamped accordingly.
- Removed ~1,200 TBC Phase 3 **level 70** curated entries from `Data.lua`.
- Migration plan: [docs/FOREVER-DATA-MIGRATION.md](docs/FOREVER-DATA-MIGRATION.md).
