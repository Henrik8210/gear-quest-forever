# Scoring Forever / Classic items

This folder is the **authoring asset**. Players never see it. CurseForge zips
ignore `pipeline/` (`.pkgmeta`). The addon ships `GearQuest/_generated/*.lua`.

## When you find a new or retuned item in Forever beta

Do not hand-edit generated Lua as the long-term fix. Put the item in the
pipeline inputs, re-score the class, then copy Lua back.

1. **Item facts** — add or edit `pipeline/data/items.json` keyed by item id
   (string). Copy a nearby item of the same slot and fill:

   | Field | What it is |
   |---|---|
   | `id`, `name`, `slot`, `kind`, `inv` | Identity and inventory type |
   | `quality`, `ilvl`, `rlvl` | Quality, item level, required level |
   | `cls` / `sub` | Item class / subclass (armor, weapon, …) |
   | `allowClass`, `allowRace` | Bitmasks (`-1` = anyone) |
   | `stats` | Named stats the scorer weights (`str`, `agi`, `spFire`, …) |
   | `dps`, `speed` | Weapons only |
   | `effects`, `procs` | Tooltip lines; procs.py prices `Chance on hit` / `Use:` |
   | `randomEnchant` | `true` if it rolls a suffix |

2. **How to get it** — same id in `pipeline/data/sources.json`:

   ```json
   {
     "sourceType": "quest_reward",
     "instructions": "One or two sentences the log can show.",
     "zone": "The Barrens",
     "npc": null,
     "questName": "Quest title",
     "profession": null,
     "dropChance": null,
     "alts": [],
     "gateLevel": 18,
     "questClasses": 0,
     "questRaces": 0,
     "seasonal": false,
     "obtainable": true,
     "excludedBecause": null
   }
   ```

3. **Pool** — append the numeric id to `pipeline/data/classic_item_ids.json`.
   `score.py` only considers ids in that list (TBC/Outland stays out).

   Forever-only items (id ≥ 200000) come from Wowhead `/forever/items`:

   ```powershell
   node scripts/scrape-forever-wowhead-items.mjs
   python pipeline/scripts/ingest_forever_wowhead.py
   ```

4. **Random green?** — scrape Classic/Forever suffix tables, then convert:

   ```powershell
   node scripts/scrape-classic-random-enchants.mjs --ids 12345
   node scripts/convert-classic-random-to-pipeline.mjs
   ```

   Era fingerprint: Vice Grips **9640** must stay **+17 Strength @ 9%**.

5. **Re-score** (needs Python 3, run from `pipeline/scripts`):

   ```powershell
   $env:GQ_CLASS = "HUNTER"
   $env:GQ_GUIDES = "guides_hunter.json"
   $env:GQ_OUT = "hunter.json"
   python score.py
   python payload.py
   python emit_early.py
   ```

   Copy the emitted Lua into `GearQuest/_generated/`, then:

   ```powershell
   node scripts/verify-generated-bis.mjs
   ```

   After a Classic `score.py` regen, do **not** run `apply-classic-random-enchants.mjs`
   (that tool patches TBC-scored Lua). Suffixes already come from Classic
   `items_random.json`.

Python 3.12 is installed on the authoring PC. A one-off curated row in
`GearQuest/Data.lua` is only for levels 1–9 Alliance bands (see
`docs/DATA_RULES.md`).

## What is already wired

- Paths are repo-relative (`gq_paths.py`). No `/home/claude/gq/`.
- Scoring bands are **10–60** (not 69).
- `items_random.json` is converted Classic tables (TBC copy kept as
  `items_random.tbc.json`).
- `check_era.py` asserts Classic Vice Grips, not TBC.
- All nine classes have been re-scored into `GearQuest/_generated/`.

## Stat weights (still TBC — retune on the Forever client)

`data/weights.json` is the TBC Anniversary scale (expertise, armour pen, TBC
paladin seals, Steady Shot in the hunter ranged weight). Rank order is a
Classic-pool top 3 under those weights. Level 60 is mostly Classic guides, so
this mainly affects **10–59**.

**On the Forever client:** inspect whether ratings exist and how seals/shots
work, then edit `weights.json`, re-score affected classes, copy Lua, verify.
Forever is Classic+ — do not paste vanilla 1.12 weights if the combat model
moved.

**Optional before beta:** zero `expertise` / `armorPen`. Do not invent a full
Forever scale until you have played.

Full write-up: [../../docs/FOREVER-DATA-MIGRATION.md](../../docs/FOREVER-DATA-MIGRATION.md#stat-weights-tbc-model--forever-client).
