# Paste this into Cursor (in the GearQuest repo)

Adding **Rogue** (all three specs, 1–69) and re-issuing **Warrior**, which carried the
same off-hand scoring bug rogue exposed. Paladin, druid, hunter and shaman are unchanged.

## Files

From `GearQuest-Rogue-BiS.zip`.

| file | where | note |
|---|---|---|
| `Data.Rogue.generated.lua` | `GearQuest/_generated/` | **new** — 7,314 picks, 10–69, combat / assassination / subtlety |
| `Data.Rogue.Early.1to9.generated.lua` | `GearQuest/_generated/` | **new** — 429 picks, 1–9, both factions |
| `Data.Warrior.generated.lua` | `GearQuest/_generated/` | **replaces** — 8,136 picks (was 8,106). Fury off-hand fix |
| `DataAdapter.lua` | `GearQuest/` | **replaces** — two new SOURCES entries |
| everything else | | unchanged — skip if already merged |
| `ROGUE.weights.json`, `ROGUE.guides.json` | `GearQuest/_generated/` | reference only |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` | **replaces** — gained section 12 |

**`.toc`: add two lines** after the shaman pair, before `DataAdapter.lua`:

```
_generated\Data.Rogue.generated.lua
_generated\Data.Rogue.Early.1to9.generated.lua
```

## Why Warrior changes: the Dual Wield penalty was half applied

Off-hand weapon damage is halved by Dual Wield. That was being applied only to
one-handers *duplicated* into the off hand from the main-hand pool — not to
`InventoryType 22` weapons, which are off-hand-**only** and reach the slot by a
different route. Those were paid full weapon dps for a swing that lands at half.

*Shekketh Talons* — a TBC fist weapon with **47.9 dps and no stats at all** — scored 718
and displaced *The Hungering Cold* (73.0 dps, 14 stamina, 14 expertise) in all three
rogue off-hand lists. A weapon with less damage and no stats scoring higher is
arithmetically impossible, which is what made it findable.

Warrior impact: **207 cells (1.30%), all of them fury `SecondaryHand`, none at level 60.**
*Claw of Celebras*, *Left-Handed Blades*, *High Warlord's Left Claw* and other off-hand-only
weapons dropping back to their real value.

## Rogue specifics worth knowing before you review

- **Assassination and Subtlety are dagger-locked in the main hand.** Backstab, Ambush
  and Mutilate do not fire with a sword, so this is a hard filter, not a preference.
  Currently 228/228 Dagger for both. Combat takes swords, daggers, maces or fists —
  per Henrik, "both combat with sword or dagger" is a real thing.
- **The Ranged slot is ranked with weapon dps weighted ZERO.** A rogue never fires the
  bow; it is a stat stick. Level 60 comes out *Crossbow of Imminent Doom* (50.8 dps) and
  *Striker's Mark* (48.4) **above** *Nerubian Slavemaker* (67.5). That is correct and is
  the exact inverse of the hunter, where the bow is everything. Do not "fix" it by
  sorting Ranged on dps.
- **Assassination and Subtlety have no guide main-hand entry**, because the guide page
  has no dagger main-hand table (verified). Their guide denominator is 14 against
  combat's 15. That asymmetry is correct — don't pad it.
- Leather and cloth only. No mail, plate, shields, axes, or anything two-handed.
- `Spec.lua` marks assassination and subtlety `comingLater = true`. There is data for
  both now (409 and 408 entries), so those flags can come off.

## Verify

- `#GQ.Data.entries` == **1,177 curated + 46,698 = 47,875**.
- **Zero duplicate `id` values.**
- Rogue legality: no mail, plate, shield, axe, or two-handed item in any pick.
  Currently 0 violations.
- **Dagger lock**: every assassination and subtlety `MainHand` pick is a Dagger.
- Rogue early file: all 429 rows have a faction.
- Fury warrior off-hand no longer leads with a statless off-hand-only weapon.
- No entry with `minLevel > maxLevel`; nothing above level 69.

## Then

Extend the UI to Rogue. Nothing structurally new — same fields as the other physical
classes. Six classes done; remaining: priest, mage, warlock.
