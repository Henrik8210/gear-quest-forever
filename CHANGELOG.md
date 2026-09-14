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

### Data (Forever migration phase 2 — complete)

- Classic Wowhead random-enchant scrape/apply pipeline (`classic-suffix-sync.mjs --retry-403 --phase2-gate`).
- Cache: `items_random.classic.json` — **610** scrapeable suffix items with Classic tables; **162** TBC-era IDs marked `noClassicPage` (Classic Wowhead 404).
- Scraper preserves existing enchant rows; records 404 as non-scrapeable; `--phase2-gate` enforces ≥80% scrapeable coverage.
- Generated picks/notables patched for Classic suffix metadata where tables exist (e.g. **9640** +17 @ 9%); **0** stale TBC +20/@7.9% rows.

### Data (Forever migration phase 1)

- Cap addon scope at **level 60** (`GQ.MAX_PLAYER_LEVEL`); preview/simulate clamped accordingly.
- Removed ~1,200 TBC Phase 3 **level 70** curated entries from `Data.lua`.
- Migration plan: [docs/FOREVER-DATA-MIGRATION.md](docs/FOREVER-DATA-MIGRATION.md).
