# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.2.5-beta

Forever scoring model for every class, a Wowhead re-ingest, readable hunt text, and warrior-tank honesty.

### Scoring (all nine classes, every spec, 1–60)

Leveling hunts now follow a fixed order: **damage first**, then **survivability**, then **endurance**. The spec primary still leads (Agi, Str, spell power, tank threat). Below 60, stamina / health / hp5 count ×3 and armor ×2 so a naked +1 primary-stat stick cannot beat a real leveling chest (Brawler's / Trapper's vs Panther Armor at 22). Mana keep-up — intellect, spirit, mp5, mana — counts ×2, less than stam, so paladin seals, shaman shocks, hunter shots, and casters stay in the fight. Level 60 uses the raw raid-scale weights. Classic/TBC BiS guides do not pin Forever 60 (`GQ_NO_GUIDES=1`).

**Random-enchant jackpot is BiS.** A green is ranked on the best suffix it can roll (top of the range), not the average of every suffix. If Superior Shoulders of Agility can roll +7 Agi and that would be #1, it is #1. The log still says the roll is slim (~9.5%). Chance never hides the hunt.

**Three unique names + one notable** per slot. Notables are procs, leftover jackpots, or a tank-relevant extra — they are not rank 1–3.

**Warrior Protection is a physical tank.** Spell power and healing no longer inflate prot-warrior ranks. **Silvered Gauntlets** (spell damage + healing, +3 Defense) is the Hands *notable* for the defense, not fake BiS. Paladin Protection still scores holy/spell threat.

All nine classes were re-scored on this model (hunter and shaman first, then paladin, warrior, druid, rogue, priest, mage, warlock), then re-scored again after the 20 Sep ingest.

### New and updated gear

Wowhead Forever index compared to `items.json`: **24** missing ids ingested (one tooltip 404 — Wildstalker's Helm). After re-score, these mid-level rares made a top-3 or notable list:

- **Silvered Gauntlets** (27) — paladin BiS; warrior-prot notable (+3 Defense)
- **Cultist's Armguards** (29) — paladin, warrior, hunter, shaman, druid, rogue
- **Dark Ritual Leggings** (29) — druid

Ilvl-65 set pieces (Manaflare, Grimstitch, Wildstalker, Conviction, Spiritcaller) were scored and did not beat the existing level-60 lists.

### Hunt parchment

Quest descriptions no longer read `Worlddrop - dropsfrom364creaturetypes` / `ItemLevel27Bindswhenequipped`. Causes: `QuestFont` in this client has no usable space glyph (titles and body now use the readable UI font), and the mashed Wowhead audit tooltip is no longer pasted into the description. Instructions were cleaned: world drops say `World drop around level 23-28.` instead of creature-type counts; quest/vendor/drop copy no longer repeats the zone. Auction House is one BoE line. **Source** always prints.

Random-enchant suffix stats still paint on the item tooltip when Forever returns the unsuffixed green.

## v0.2.4-beta

Random-enchant greens show the suffix on the **item tooltip**, not only in the hunt text.

- Forever often answers a suffixed `item:` link with the unsuffixed base green (Bandit Cloak, armor only). The log already had `of Nature's Wrath` / `+3-4 spNature`; the hover tooltip did not.
- If the client tooltip title does not contain the suffix, GearQuest paints the hunt name and the roll stats for **every class, spec, and level**.
- Shaman 10–60 re-score remains Wowhead Forever only (no TBC, 404s pruned).

## v0.2.3-beta

Repo-only follow-up (logo, veldt diff script, local audit helpers). **In-game build matches v0.2.2-beta** — CurseForge file **`v0.2.3-beta`** for version alignment after the GitHub tooling commit.

## v0.2.2-beta

BiS quality pass, relic combat scoring, simulator UX, and local install workflow.

- **BiS = combat value:** generated picks dedupe same-name variants (PvP rank twins), skip Forever-audit **404** ids at score time, and fill three **unique** names per slot where the pool allows. **Notables** are not rank 1–3; proc-driven hunter ranged weapons that lose to inflated Forever bow DPS can promote into the top 3 when still competitive.
- **Relics (Totem / Idol / Libram):** effect text from Wowhead tooltips (`patch_relic_effects.py`) and **`relic_score.py`** — e.g. elemental **Polished Driftwood Icon** (casting mana reg) ranks above utility CD trims; ilvl-only ordering is fallback only.
- **Log UI:** banner under the title — simulation mode shows level, spec, class, faction; live character mode explains spec picker. **Simulator** faction dropdown; list tabs re-attached to the hunt panel after the banner layout fix.
- **Runtime:** `GetTopUpgradesForSlot` uses candidates only (not notables in the rank pool); Compare keeps pipeline `curatedRank`; Forever-missing items hidden when audit says 404.
- **Authoring:** after any `GearQuest/` or `_generated/` change, run **`scripts/sync-addon.ps1`** (default `_classic_beta_` → `Interface/AddOns/GearQuestForever`). Re-score with `score_all.py` / `reemit_all.py` after pipeline edits.
- CurseForge **Files** name is **`v0.2.2-beta`**.

## v0.2.1-beta

Wowhead re-scrape, Horde ring toast fix, and CurseForge files named `vX.Y.Z-beta`.

- **Wowhead (18 Sep 2026):** catalog 3,244 → 3,245. Only new item: **Mirror of Rath'mael** (271213), a level-19 rare shield. Paladin / warrior / shaman re-scored.
- **Finger at 9:** the “ring slot eligible” toast was Alliance paladin/warrior data. Horde shaman has no Finger hunts at 9 (The 1 Ring 8350 and Woven Copper Ring 21931 404 on Forever; Barrens/Silverpine rings land ~15). Toast and log now require hunts for this character.
- CurseForge **Files** name is **`v0.2.1-beta`**.

## v0.2.0-forever-beta

Nine-class re-score after Forever Wowhead hunt audit and the Horde trinket gap.

- **Trinkets at 20:** Warsong Gulch Rune of Duty / Rune of Perfection (21565–21568) are the same item IDs for both factions. Sources no longer pin Illiyana only, so Horde enhancement (and every other Horde spec) gets a trinket hunt from 20 instead of waiting until Defiler's Talisman at 28.
- **Three hunts per slot:** lists aim for three items at each level; a lower-required-level leftover is a valid rank 2/3. Empty slots are treated as data bugs.
- **Wowhead Forever audit:** hunt ids probed against nether tooltips. Classic ids that 404 are dropped from hunts. Items that exist but have no combat stats, suffixes, or effects show “Has not been datamined yet” (source text is not a tooltip). Re-scrape as the Forever catalog grows.

## v0.1.0-beta.6-forever

Forever beta client pass: profession-style window, per-spec early BiS, and Wowhead as the item-fact source.

### Window and portrait

- GearQuest log uses `PortraitFrameTemplate` (profession-style metal chrome and circular portrait well).
- Portrait sits in the socket (61px, offset -6 / 7). `SetTexCoord` is skipped while the CircleMask is attached.

### Hunts and item info (no more login freeze)

- Do not bulk-request item data for every list row. `RequestLoadItemDataByID` runs only on hover.
- Hunt names and colors come from pipeline facts (`quality`, `ilvl`, `reqLevel`) plus `ITEM_QUALITY_COLORS`, not from unidentified client stubs (quality 0 / gold “Retrieving item information”).
- Hover falls back to the fact tooltip when the client has no item payload. Classic ids that 404 on Wowhead Forever (e.g. Bands of Serra'kis, 6902) still show that way until the community catalogs a replacement.

### Descriptions

- Curly quotes, em dashes, and replacement characters are folded to ASCII so WoW fonts no longer draw empty `[]` boxes (`quest 'The Den'` instead of `[]The Den[]`).

### Early BiS

- Generated 1–9 is scored **per spec** (enhancement vs resto, arms vs fury, …) instead of one hybrid `levelling_1_9` list.

### Data source

- Forever item facts come from Wowhead `/forever/items` (ids ≥ 200000) via `scripts/scrape-forever-wowhead-items.mjs` and `pipeline/scripts/ingest_forever_wowhead.py`.
- The in-game seen-item notebook is retired: Collector is not started, `/gq seen` prints that Wowhead is the source, and `sync-addon.ps1` no longer backs up `notebook/seenItems/`.
- New or retuned Forever items will land as Wowhead’s catalog grows; lists can still include classic ids that this client cannot identify.

## v0.1.0-beta.5-forever

- Same Horde Forever deltas and item notebook as beta.4 (that tag did not reach CurseForge).
- Fix CurseForge upload metadata so changelog punctuation cannot break the multipart field.

## v0.1.0-beta.4-forever

- Horde **phase-4 Forever deltas** for all nine classes in `Data.lua` (`foreverDelta`). Zephras Isle quest whites and Shen'dar crafts (sashes, copper boots, mageweave slippers, shaman totem, druid idol) compete across generated per-level bands; Compare still shows the top 3.
- Local item notebook (`GQ.Collector` / `/gq seen`) records unique equippable items this client has seen so Forever IDs can be ingested without inventing rows.
- `scripts/sync-addon.ps1` prefers `_classic_beta_` (Forever) and can still target `_anniversary_` for side-by-side UI tests.

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
