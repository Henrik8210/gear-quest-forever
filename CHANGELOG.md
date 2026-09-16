# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.1.0-beta.3-forever

- Target CurseForge **WoW Forever 1.60.1** (`## Interface: 16001`).
- Zip `GearQuest/` as `GearQuestForever` and upload to the Forever game version directly (BigWigs packager still treats 1.x as Classic Era).

## v0.1.0-beta.2-forever

- Target CurseForge **WoW Forever 1.60.1** (`## Interface: 16001`).
- First successful packaging pass: zip as `GearQuestForever` (the previous `move-folders` step emptied the archive).

## v0.1.0-beta.1-forever

First CurseForge beta. Project **1698950** (`X-Curse-Project-ID`). Not TBC GearQuest (`1669225`).

- Two-column GearQuest log: hunt list on the left, parchment description on the right. **GearQuest Log** and **Simulator** are handle tabs on the right of the frame.
- **Active** / **Completed** sit on the quest-list border. Spec picker sits above the parchment (far right). The Simulator tab has its own spec; while simulation is on it overrides the log spec until Reset (`/gq set me`).
- Click the minimap button to open GearQuest (any click). Right-click a character-panel slot for upgrades.
- Simulator and `/gq level` cap at **60**. Art paths use the `GearQuestForever` folder name.
- Random-enchant greens in curated Alliance paladin/warrior 1–9 now carry Classic suffix rolls (e.g. Infantry Tunic / Spiked Club of Strength). Suffix hints use commas, not middle dots. Player-facing text strips em-dashes and other glyphs WoW fonts cannot draw.

- New repo and CurseForge packaging for WoW Forever (beta 17 Sep 2026).
- In-game title **GearQuest Forever**; slash commands stay `/gq` and `/gearquest`.
- `## Interface: 11507` is a placeholder until the beta client reports `lastAddonVersion`.
- Sync script targets a Forever client folder (`_forever_` and similar), not `_anniversary_`.
- No TBC CurseForge project ID or GitHub secrets were copied.

### Install name (distinct from TBC GearQuest)

- Game / CurseForge folder **`GearQuestForever`** (`GearQuestForever.toc`); saved variables **`GearQuestForeverDB`** so it can sit beside TBC **`GearQuest`** on the same client.

### Data (Forever migration phase 3 — complete)

- Filtered generated picks to a Classic-era pool, then re-scored **all nine classes** in-repo via `pipeline/scripts/score.py` (Classic item pool, Classic suffixes, cap 60).
- Paladin/Warrior Alliance 1–9 stays curated; Horde 1–9 and every other class’s Early 1–9 are generated.
- **57,202** generated rows (was 67,033 TBC; 56,576 after the filter slice). Stat weights are still TBC-derived — retune on the Forever client ([docs/FOREVER-DATA-MIGRATION.md](docs/FOREVER-DATA-MIGRATION.md#stat-weights-tbc-model--forever-client)).

### Data (Forever migration phase 2 — complete)

- Classic Wowhead random-enchant scrape/apply pipeline (`classic-suffix-sync.mjs --retry-403 --phase2-gate`).
- Cache: `items_random.classic.json` — **610** scrapeable suffix items with Classic tables; **162** TBC-era IDs marked `noClassicPage` (Classic Wowhead 404).
- Scraper preserves existing enchant rows; records 404 as non-scrapeable; `--phase2-gate` enforces ≥80% scrapeable coverage.
- Generated picks/notables patched for Classic suffix metadata where tables exist (e.g. **9640** +17 @ 9%); **0** stale TBC +20/@7.9% rows.

### Data (Forever migration phase 1)

- Cap addon scope at **level 60** (`GQ.MAX_PLAYER_LEVEL`); preview/simulate clamped accordingly.
- Removed ~1,200 TBC Phase 3 **level 70** curated entries from `Data.lua`.
- Migration plan: [docs/FOREVER-DATA-MIGRATION.md](docs/FOREVER-DATA-MIGRATION.md).
