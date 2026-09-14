# Paste this into Cursor (in the GearQuest repo)

Adding generated best-in-slot data for **Druid** — all four specs, levels 1–69. Nothing
else changed since the Hunter import: paladin, warrior and hunter files are identical
to that bundle and are included only so the set is self-consistent.

## Files

From `GearQuest-Druid-BiS.zip`.

| file | where | note |
|---|---|---|
| `Data.Druid.generated.lua` | `GearQuest/_generated/` | **new** — 8,341 picks, levels 10–69, bear / feral / balance / restoration, both factions |
| `Data.Druid.Early.1to9.generated.lua` | `GearQuest/_generated/` | **new** — 388 picks, levels 1–9, **both factions in one file** |
| `DataAdapter.lua` | `GearQuest/` | **replaces** — two new SOURCES entries |
| `Data.Hunter.*`, `Data.Warrior.*`, `Data.Paladin.*` | `GearQuest/_generated/` | unchanged from the Hunter bundle — skip if already merged |
| `DRUID.weights.json`, `DRUID.guides.json` | `GearQuest/_generated/` | reference only |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` | **replaces** — gained section 10 |

**`.toc`: add two lines** after the hunter pair, before `DataAdapter.lua`:

```
_generated\Data.Druid.generated.lua
_generated\Data.Druid.Early.1to9.generated.lua
```

## The one thing to understand before reviewing the data

**In Cat or Bear form a druid never swings the weapon.** Attack power in form comes
from the weapon's `+N attack power in Cat, Bear, Dire Bear and Moonkin forms only`
line, not from its damage. So weapon dps is weighted **zero** for all four specs, and
the level-60 feral main hand comes out:

| item | dps | feral AP |
|---|---|---|
| Manual Crowd Pummeler | 29.0 | none — it is there for the haste on-use |
| Atiesh, Greatstaff of the Guardian | 64.3 | **592** |
| Ursol's Claw | 57.5 | 197 |

**A 29-dps mace above a 64-dps staff is correct.** If a reviewer "fixes" this by
sorting feral weapons on dps, the list gets worse. The dps column is in the data for
display only; for druids it is not a ranking input at all.

## Adapter change

Two `SOURCES` entries. Druid, like hunter, is in neither `ALLIANCE_MAIL` nor
`MAIL_MELEE`, so it has no hand-curated early data on either side and its 1–9 file
carries both factions with `factionInRow = true`.

Druid's spec ids match `Data.lua` exactly: `bear`, `feral`, `balance`, `restoration`.

## Verify

- `#GQ.Data.entries` == **curated + 31,951**. With 1,177 curated that is **33,128**.
- **Zero duplicate `id` values.**
- **Druid legality — the cheapest regression test for this class.** No pick may be
  mail, plate, a shield, a sword, an axe, or a bow/gun/crossbow. Druids can use only
  Staff, Mace, Dagger, Fist and Polearm, and wear only leather and cloth. Currently 0
  violations across 8,341 picks.
- Druid `Ranged` slot holds **Idols**, not weapons.
- Druid early file: all 388 rows have a faction. `noFaction` must be 0.
- No entry with `minLevel > maxLevel`; nothing above level 69.

## Then

Extend the class-agnostic UI to Druid. Two things are new for this class:

- The **Ranged slot label** should read Idol/Relic for druids (and Relic for paladins),
  not "Ranged" — a druid has no ranged weapon.
- `feralAp` is worth surfacing in the tooltip for bear and feral, because it is the
  stat that decides those weapon picks and it is invisible on a normal item comparison.

Druid brings the total to five classes. Remaining: rogue, priest, mage, warlock, shaman.
