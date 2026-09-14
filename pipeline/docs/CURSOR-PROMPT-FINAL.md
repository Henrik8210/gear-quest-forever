# GearQuest generated BiS data — the one bundle to import

This supersedes **every** earlier zip. Six classes, all specs, levels 1–69, plus the
adapter and the notes. If a file exists in an earlier bundle and here, **this one wins.**

The rogue data in `GearQuest-Rogue-BiS.zip` is stale — same 7,314 picks and identical
rankings, but no `suffixId` on any of its 1,331 suffixed rows. Do not import that zip.

## Files

| file | where |
|---|---|
| `Data.Paladin.generated.lua` + `Data.Paladin.Horde.1to9.generated.lua` | `GearQuest/_generated/` |
| `Data.Warrior.generated.lua` + `Data.Warrior.Horde.1to9.generated.lua` | `GearQuest/_generated/` |
| `Data.Hunter.generated.lua` + `Data.Hunter.Early.1to9.generated.lua` | `GearQuest/_generated/` |
| `Data.Druid.generated.lua` + `Data.Druid.Early.1to9.generated.lua` | `GearQuest/_generated/` |
| `Data.Shaman.generated.lua` + `Data.Shaman.Early.1to9.generated.lua` | `GearQuest/_generated/` |
| `Data.Rogue.generated.lua` + `Data.Rogue.Early.1to9.generated.lua` | `GearQuest/_generated/` |
| `DataAdapter.lua` | `GearQuest/` |
| `*.weights.json`, `*.guides.json`, `pvp_prefix_faction.json` | `GearQuest/_generated/` — reference only, not loaded |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` |

**`.toc` — twelve generated lines, all after `Data.lua`, all before `DataAdapter.lua`:**

```
Data.lua
_generated\Data.Paladin.generated.lua
_generated\Data.Paladin.Horde.1to9.generated.lua
_generated\Data.Warrior.generated.lua
_generated\Data.Warrior.Horde.1to9.generated.lua
_generated\Data.Hunter.generated.lua
_generated\Data.Hunter.Early.1to9.generated.lua
_generated\Data.Druid.generated.lua
_generated\Data.Druid.Early.1to9.generated.lua
_generated\Data.Shaman.generated.lua
_generated\Data.Shaman.Early.1to9.generated.lua
_generated\Data.Rogue.generated.lua
_generated\Data.Rogue.Early.1to9.generated.lua
DataAdapter.lua
```

## Verify

- `#GQ.Data.entries` == **1,177 curated + 46,701 = 47,878**. Zero duplicate `id` values.
- `suffixId` present on **98%** of suffixed rows and **99%** of notable suffixed rows.
  Rare absence is fine (1%) — fall back to `suffixRange`. Common absence means an older
  file is still loaded.
- Spot checks: `6570` → `suffixId=2032`; `9775` → `2031`; `7413` → `690`;
  `15116` → `766`; `12047` → `-30` (negative is correct — see CURSOR-NOTE-NOTABLES.md).
- Class legality, each 0 violations currently: druid takes no mail/plate/shield/sword/axe;
  rogue no mail/plate/shield/axe/two-hander; hunter no plate/shield/mace;
  shaman no plate/sword/polearm.
- Relic slot populated at 52–69 for paladin, druid, shaman.
- Nothing above level 69; no `minLevel > maxLevel`.

## Read these three notes before touching tooltip code

1. **`CURSOR-NOTE-ROOT-CAUSE.md`** — why 11 / 8 / +29 appeared. The addon was computing
   random-enchant stats instead of looking them up. Read this first.
2. **`CURSOR-NOTE-SUFFIX-IDS.md`** — why a suffix name is never an identifier
   ("of the Tiger" is 85 tiers), and how to read the id from the link.
3. **`CURSOR-NOTE-NOTABLES.md`** — negative `suffixId` values are valid, not failures.

## Still outstanding, not in this bundle

- **Priests, mages and warlocks** have no generated data yet.
- `Spec.lua` marks hunter *marksmanship*, rogue *assassination* and *subtlety*
  `comingLater = true`. All three have data now.
- Curated `Data.lua` has no level-70 rows for hunter marksmanship (80 hunter rows cover
  beast mastery and survival only) or for rogue assassination/subtlety (42 rows, combat
  only). Those specs fall through to nothing at 70.
- Label the Ranged slot per class — **Totem** (shaman), **Idol** (druid), **Libram**
  (paladin), **Ranged** (hunter/warrior/rogue).
- For relics, show the **effect text** rather than the score: the score is only an
  item-level ordering key.
