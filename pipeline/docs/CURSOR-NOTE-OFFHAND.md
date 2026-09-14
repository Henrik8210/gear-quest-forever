# GearQuest — off-hand fix (R32): hunter, rogue, shaman

## What Henrik found

> "you do know that off-hand for rogues/hunters are also one-handed weapons, right?
> You fx. with the hunter only calculate with the use of two and instead of main hand +
> one hand. And for rogue you calculate many times with the off hand is a literal
> off-hand item even though the rogue can wear a one-handed weapon in it's 'off-hand'
> slot like the hunter"

Correct on both counts. Two separate bugs in the generator, both in the off-hand slot.

## Bug 1 — one-handers never reached the off hand for hunters

`InventoryType 13` ("One Hand", equippable in either hand) was copied into the
off-hand candidate pool only when the spec's weapon style was literally
`onehand_dual`. Hunter's style is `twohand_or_onehand`, because its level-60 guide
offers both a Two-Hand section and a Main Hand / Off Hand section — so **no hunter
spec ever saw a single one-hander in the off hand, at any level**. The pool was 189
held-in-off-hand items and 24 off-hand-only weapons, and zero inv-13.

The gate is now "can this class dual wield at this level, and would this spec put a
weapon in that hand", not the style string.

## Bug 2 — held-in-off-hand items ranked against weapons

`InventoryType 23` ("Held In Off-hand": orbs, tomes, steins, lanterns) is equippable
by any class, but it **disables off-hand attacks**. For anyone who can dual wield it is
strictly worse than any weapon. It was being scored on stats alone, so Ritual Stein
(+3 Agi, +3 Spi) could out-rank a real off-hand dagger, and did.

Held items are now excluded once the character can dual wield. They are kept where
they are legitimate:

* below the dual-wield level — rogue < 10, hunter/warrior < 20, enhancement shaman < 30;
  a hunter at 15 cannot dual wield and cannot use a shield, so a held item is the only
  legal off-hand it has
* for caster specs that never make an off-hand attack — elemental and restoration
  shaman keep orbs and totems alongside shields

Dual-wield levels used: rogue 10 and warrior/hunter 20 (class skills), enhancement
shaman 30 (talent). Other shaman specs, paladin and druid cannot dual wield at all.

## Bug 3 (found while fixing 1 and 2) — off-hand weapon damage

Off-hand weapon damage is halved by Dual Wield. The 0.5 dps multiplier was applied
only to items duplicated from the main hand, not to `InventoryType 22` off-hand-only
weapons, so a stat-less fast off-hander scored on full dps. Both routes into the slot
now agree.

## What changed in the data

| file | off-hand cells changed | before → after |
|---|---|---|
| `Data.Hunter.generated.lua` | 300 | 678 held + 222 off-hand-only → 864 one-handers + 36 off-hand-only |
| `Data.Rogue.generated.lua` | 60 | 150 held + 30 off-hand-only → 180 one-handers |
| `Data.Shaman.generated.lua` | 80 | 206 off-hand-only + 34 shields → 218 one-handers + 22 off-hand-only |

Examples:

* hunter BM, level 61+ off hand: Claw of the Frost Wyrm / Hellfire Skiver /
  Grand Marshal's Left Hand Blade → **Kingsfall / Harbinger of Doom / Claw of the
  Frost Wyrm**
* hunter marksmanship, level 20 off hand: Shimmering Stave / Buccaneer's Orb /
  Ritual Stein → **Thief's Blade / Smite's Reaver / Buzzer Blade**
* rogue combat, level 12 off hand: Left-Handed Brass Knuckles / Runic Cane / Carved
  Crystalline Orb → **Daryl's Shortsword / Slicer Blade / Wicked Blackjack**
* enhancement shaman, level 43 off hand: Left-Handed Blades / Savage Boar's Guard /
  Tyrant's Shield → **Gut Ripper / Flurry Axe / Galgann's Firehammer**

**Nothing else moved.** Warrior, paladin and druid regenerate byte-identical — a fury
warrior already had the `onehand_dual` style, prot and arms want a shield or nothing,
and paladin and druid cannot dual wield. The 1-9 early files for all classes are also
byte-identical, since no class can dual wield before level 10.

Row counts move slightly (hunter −111, rogue +66, shaman +69 pick rows) because
adjacent levels whose top 3 are identical are merged into one band, and the off-hand
answer is now more stable across levels for hunters and less so for rogues.

## What to import

Three files, replacing the ones in `GearQuest/_generated/`:

* `Data.Hunter.generated.lua`
* `Data.Rogue.generated.lua`
* `Data.Shaman.generated.lua`

No `.toc` change, no `DataAdapter.lua` change, no `Data.lua` change. The row shape is
identical to what is already there.

## Verification

Run against Henrik's live `DataAdapter.lua` (staged from the repo, not my older copy):

```
total entries: 48266   expected 48266 -> OK
second call is a no-op: OK
malformed generated entries: 0
duplicate ids: 0
random-enchant rows: 2319, of which carry a suffixId: 2219 (95.7%)
illegal off-hand picks: 0        <- new standing check, see below
guide agreement:  hunter 45/45   rogue 43/43   shaman 44/44   warrior 44/44
suffixIds audited against the client data: 17604, value mismatches 0
picks offered before an item's RequiredLevel: 0 (all four classes)
role check OK, era check OK
```

New standing check, so this class of bug fails loudly next time: for every
`SecondaryHand` pick, assert that a weapon only appears where the class can dual wield
at that level, that a shield only appears for a class with shield proficiency, that a
held-in-off-hand item never appears where dual wield is available, and that a two-hand
or main-hand-only item never appears at all. Currently 0 violations across all six
classes.

## One thing that needs a UI decision, not a data fix

For a hunter the melee weapons are pure stat sticks, so two one-handers carry more
total stats than one two-hander — but Henrik's level-60 guide legitimately lists **both**
a Two-Hand section and a Main Hand / Off Hand section, and the model keeps both, ranked
independently. That means at level 60 a hunter can be shown a two-hander as the #1
MainHand *and* a one-hander as the #1 SecondaryHand at the same time, which is not a
combination you can actually equip.

The same applies to enhancement shaman, whose Classic guide lists only two-handers
while the model also offers a dual-wield off hand.

Forcing hunter to `onehand_dual` would fix the display but would make the guide's
Two-Hand "Best" pick (*The Eye of Nerub*) unrankable and drop hunter's guide agreement
from 45/45. So this is left as-is in the data, and the addon should say which it is —
e.g. grey the off-hand row when the equipped main hand is a two-hander, or label the
two sections "Two-Hand build" / "Dual-wield build". Henrik to decide.
