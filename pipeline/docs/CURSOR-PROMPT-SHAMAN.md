# Paste this into Cursor (in the GearQuest repo)

Adding **Shaman** (all three specs, 1–69) and re-issuing **Paladin** and **Druid**,
which both gained a slot they had been shipping empty. Warrior and Hunter are unchanged.

## Files

From `GearQuest-Shaman-BiS.zip`.

| file | where | note |
|---|---|---|
| `Data.Shaman.generated.lua` | `GearQuest/_generated/` | **new** — 6,379 picks, 10–69, elemental / enhancement / restoration |
| `Data.Shaman.Early.1to9.generated.lua` | `GearQuest/_generated/` | **new** — 433 picks, 1–9, both factions |
| `Data.Paladin.generated.lua` | `GearQuest/_generated/` | **replaces** — 7,092 picks (was 7,020). Libram slot added |
| `Data.Druid.generated.lua` | `GearQuest/_generated/` | **replaces** — 8,398 picks (was 8,332). Idol slot added |
| `DataAdapter.lua` | `GearQuest/` | **replaces** — two new SOURCES entries |
| `Data.Warrior.*`, `Data.Hunter.*`, `Data.Paladin.Horde.*`, `Data.Druid.Early.*` | | unchanged — skip if merged |
| `SHAMAN.weights.json`, `SHAMAN.guides.json` | `GearQuest/_generated/` | reference only |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` | **replaces** — gained section 11 |

**`.toc`: add two lines** after the druid pair, before `DataAdapter.lua`:

```
_generated\Data.Shaman.generated.lua
_generated\Data.Shaman.Early.1to9.generated.lua
```

## Why Paladin and Druid change: the relic slot was empty

There are 108 relics in the dataset — Libram, Idol, Totem — and **only two carry a
single stat**. Everything they do is an effect line ("Increases healing done by Lesser
Healing Wave by up to 80"), which scores 0 on stats, and a `score <= 0` guard was
discarding all of them. **Paladin, druid and shaman were all shipping with nothing in
the relic slot**, and nothing caught it because the guide-agreement metric only counted
slots that produced data.

Relics are now ordered by item level (they improve strictly within a spell line) and
filtered by whether the effect names an ability the spec actually uses. Item-level
order alone gave every paladin spec the same three *healing* librams:

| spec | ilvl order alone | corrected |
|---|---|---|
| paladin retribution | Libram of Light / Grace / Divinity — all healing | **Libram of Fervor**, Libram of Hope |
| druid balance | Idol of Longevity / Health / the Moon — two healing | **Idol of the Moon** |
| shaman elemental | — | **Totem of the Storm** |

Relic bands cover levels **52–69** (52 is the earliest relic RequiredLevel), so nothing
below 52 changed for either class.

## Shaman specifics worth knowing before you review

- **Dual Wield is an Enhancement talent, not a class skill.** Elemental and
  Restoration can never hold a weapon in the off hand at any level; Enhancement not
  before 30. Their off hand is shields and held items throughout. Currently: 59
  off-hand weapon picks for enhancement earliest at level 30, **zero** for the other two.
- **Level-60 enhancement main hand is three two-handers** — Might of Menethil, Dark
  Edge of Insanity, Severance — because the Classic guide lists only two-handers. That
  is correct for Classic-era content, not a filter bug.
- **Elemental and Restoration have no armour-class preference.** Their guide BiS is
  largely *cloth* (Mish'undare, Bloodvine, Crystal Webbed Robe). A mail preference
  would fight the guide, so there isn't one.
- Weapons: Axe, Mace, Staff, Dagger, Fist. **No swords, no polearms.** Ranged slot
  holds a Totem.

## Verify

- `#GQ.Data.entries` == **1,177 curated + 38,925 = 40,102**.
- **Zero duplicate `id` values.**
- **Relic slot is populated** for paladin, druid and shaman at levels 52–69. An empty
  relic band is the bug this release fixes — worth a permanent assertion.
- **Relic spec-appropriateness**: no *healing* libram/idol/totem in a retribution,
  protection, balance, feral, bear, elemental or enhancement list.
- Shaman legality: no plate, no swords, no polearms, no bows/guns/crossbows. Currently 0.
- Shaman elemental and restoration: **zero** off-hand weapons at any level.
- Shaman early file: all 433 rows have a faction.
- No entry with `minLevel > maxLevel`; nothing above level 69.

## Then

Extend the UI to Shaman, and add the relic slot to the three classes that now have one.
Two display notes:

- The Ranged slot should be labelled by class — **Totem** (shaman), **Idol** (druid),
  **Libram** (paladin), **Ranged** (hunter/warrior).
- A relic's `score` is an item-level ordering key, not a value. **Show the effect text
  instead of the score for relics** — the effect is the entire reason to pick one.

Five classes done. Remaining: rogue, priest, mage, warlock.
