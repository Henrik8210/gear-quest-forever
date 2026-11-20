# Open-world drop % on unit tooltips

Grey drop **%** on generic world-drop lines uses an **average outdoor sample rate** from Wowhead (classic item `?power` → `dropped-by` listview, dungeon droppers excluded). Named mob rows still use per-NPC `mobDrops` when Wowhead stored one.

## Status (v1.2.5)

| Item | State |
|------|--------|
| Addon wiring | Shipped: `MobDrop.lua`, `Data.WorldDropOpenChance.generated.lua` |
| Pipeline data | `world_drop_open_chance.json` — bulk fetch run (**~1,898** ids processed, **~1,845** with `avg`, **~53** skipped) |
| UI | Grey **%** on generic world-drop unit lines when GearQuest has an average; named mob rows still use per-NPC `mobDrops` |

Rows without an average show no grey **%**. Resume `--fetch --all` to fill gaps; keep **10–15 s** between Wowhead item pages.

## Wowhead rules (follow these)

Same contract as `pipeline/scripts/wowhead_random.py` and `pipeline/scripts/index_coordinates.py`:

- User-Agent: `wow-classic-data-research/1.0 (+contact: local script)` — not a spoofed browser UA.
- URL: `https://www.wowhead.com/classic/item={id}?power`
- **One HTTP request per item.**
- **10–15 seconds between item page fetches** for this bulk pass (`GQ_COORD_DELAY=12` is a good default). Do not rerun at sub-second spacing; that triggers CloudFront blocks.
- HTTP **403** after the script’s waits means **stop**, save progress, wait hours or days, then resume.
- Resume skips ids that already have an `avg` in `world_drop_open_chance.json`.

Nether `dataEnv=16` tooltips do **not** carry dropped-by %; this dataset is separate from `refresh_forever_tips.py`.

## Commands

Cache-only (no HTTP), rebuild packed Lua from JSON:

```powershell
python pipeline/scripts/build_world_drop_open_chance.py --emit-only
```

Resume the bulk fetch (requires explicit `--fetch --all` and `GQ_COORD_DELAY>=10`):

```powershell
$env:GQ_COORD_DELAY = "12"
python pipeline/scripts/build_world_drop_open_chance.py --fetch --all
python pipeline/scripts/build_world_drop_open_chance.py --emit-only
scripts/sync-addon.ps1
```

Small batch (sanity check after a block clears):

```powershell
$env:GQ_COORD_DELAY = "12"
python pipeline/scripts/build_world_drop_open_chance.py --fetch --ids 1981 --refetch
```

`emit_mob_drops.py` runs `--emit-only` automatically when `world_drop_open_chance.json` exists.

## Outputs

- `pipeline/data/world_drop_open_chance.json` — `{ "items": { "1981": { "avg": 0.28, "n": 29 }, ... } }`
- `pipeline/data/forever_wowhead/world_drop_dropped_by_cache.json` — cached listview rows (resume-safe)
- `GearQuest/_generated/Data.WorldDropOpenChance.generated.lua` — one packed string (`id:hundredths`), lazy-parsed in `MobDrop.lua` when drop % is enabled