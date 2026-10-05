# GearQuest — weapon-slot fixes: off hand (R32) and ranged (R33)

Two things Henrik caught, one after the other. Both are about the same underlying
mistake: the model was scoring a weapon without asking whether the character ever
attacks with it.

Import: **6 files, 5 classes.** Paladin is unchanged and is not in this bundle.

---

# R32 — the off hand

> "you do know that off-hand for rogues/hunters are also one-handed weapons, right?
> You fx. with the hunter only calculate with the use of two and instead of main hand +
> one hand. And for rogue you calculate many times with the off hand is a literal
> off-hand item even though the rogue can wear a one-handed weapon in it's 'off-hand'
> slot like the hunter"

Correct on both counts. Three bugs.

### 1. One-handers never reached the off hand for hunters

`InventoryType 13` ("One Hand", equippable in either hand) was copied into the off-hand
candidate pool only when the spec's weapon style was literally `onehand_dual`. Hunter's
style is `twohand_or_onehand`, because its level-60 guide offers both a Two-Hand section
and a Main Hand / Off Hand section — so **no hunter spec ever saw a single one-handed
weapon in the off hand, at any level**. The pool was 189 held-in-off-hand items and 24
off-hand-only weapons, and zero inv-13.

The gate is now "can this class dual wield at this level, and does this spec put a
weapon in that hand" rather than a style string. It is still not simply "can dual
wield": a protection warrior can dual wield mechanically, and the first version of this
fix duly started offering it one-handers, which is wrong — the answer there is always a
shield. Styles that take an off-hand weapon are `onehand_dual` and
`twohand_or_onehand`; `onehand_shield` and `twohand` do not.

### 2. Held-in-off-hand items ranked against weapons

`InventoryType 23` ("Held In Off-hand": orbs, tomes, steins, lanterns) is equippable by
any class, but it **disables off-hand attacks**, so for anyone who can dual wield it is
strictly worse than any weapon. It was scored on stats alone, so Ritual Stein
(+3 Agi, +3 Spi) could out-rank a real off-hand dagger, and did.

Held items are now excluded once the character can dual wield, and kept where they are
legitimate:

* below the dual-wield level — rogue < 10, hunter/warrior < 20, enhancement shaman < 30.
  A hunter at 15 cannot dual wield and cannot use a shield, so a held item is the only
  legal off-hand it has.
* for caster specs that never make an off-hand attack — elemental and restoration
  shaman keep orbs and totems alongside shields.

Dual-wield levels: rogue 10, warrior and hunter 20 (class skills), enhancement shaman
30 (talent). Other shaman specs, paladin and druid cannot dual wield at all.

### 3. Off-hand weapon damage

Dual Wield halves off-hand swing damage. The 0.5 multiplier was applied only to items
duplicated in from the main-hand pool, not to `InventoryType 22` off-hand-only weapons,
which reach the slot by another route — so a stat-less fast off-hander was paid full
dps. Both routes now agree. Proc value is deliberately **not** halved: a proc that deals
100 damage deals 100 damage whichever hand triggered it, and how often it triggers is
already carried by the item's speed.

### What moved

| | off-hand cells changed | before → after |
|---|---|---|
| hunter | 300 | 678 held + 222 off-hand-only → 864 one-handers + 36 off-hand-only |
| rogue | 60 | 150 held + 30 off-hand-only → 180 one-handers |
| shaman | 80 | 206 off-hand-only + 34 shields → 218 one-handers + 22 off-hand-only |

* hunter BM, level 61+: Claw of the Frost Wyrm / Hellfire Skiver / Grand Marshal's Left
  Hand Blade → **Kingsfall / Harbinger of Doom / Claw of the Frost Wyrm**
* hunter marksmanship, level 20: Shimmering Stave / Buccaneer's Orb / Ritual Stein →
  **Thief's Blade / Smite's Reaver / Buzzer Blade**
* rogue combat, level 12: Left-Handed Brass Knuckles / Runic Cane / Carved Crystalline
  Orb → **Daryl's Shortsword / Slicer Blade / Wicked Blackjack**
* enhancement shaman, level 43: Left-Handed Blades / Savage Boar's Guard / Tyrant's
  Shield → **Gut Ripper / Flurry Axe / Galgann's Firehammer**

Prot warrior, arms warrior, paladin and druid off hands did not move at all.

---

# R33 — the ranged slot

> "remember that rogues doesn't need the damage on the ranged, they just need stats so
> ranged procs etc. is not relevant for rogues on the ranged. It can be for hunters of
> course as that is their main weapon"

Right, and it was wrong in three places.

### 1. Warrior had no ranged weight at all

`dpsWeightRanged` fell back to `dpsWeight` when the key was absent — and **warrior never
declared one**, for any spec. So a warrior's gun was scored as though its damage
mattered as much as its axe's. The default is now 0, not the melee weight, so a class
that really fights with a ranged weapon has to say so. Warrior now declares 0.0 for
arms/fury/protection and 1.0 for levels 1-9, where a thrown weapon is a real part of
the kit (same as rogue).

### 2. Procs on a ranged weapon were priced at the MELEE weight

The proc model was handed `dpsWeight` regardless of slot. Venomstrike — "Equip: Chance
to strike your ranged target with a Venom Shot for 31 to 45 Nature damage", **zero
stats** — was therefore priced for a rogue at dpsWeight 15.0, the weight of a weapon it
swings every 1.4 seconds, for a bow it never fires. It was the #1 rogue ranged pick
across 204 level bands, and Quillshooter (same effect, no stats) across 216.

### 3. …and the mirror of it: hunters were getting nothing for their bow procs

Same line of code, opposite direction. Hunter specs carry `dpsWeight` 0.0 (a hunter
never swings its melee weapon), so a hunter's *ranged* procs were priced at zero too.
Venomstrike is now correctly the best a low-level hunter can hold — 30 bands gained it.

### The rule now

If the spec's dps weight for **that slot** is zero, the character does not attack with
the item, so nothing that triggers on an attack can fire — only a `Use:` line counts,
because that fires from the item rather than from a swing. That covers the ranged slot
for everyone but a hunter, the melee slots for a hunter, and both weapon hands for a
druid (weapon procs do not fire in cat or bear form) and for an elemental or
restoration shaman.

It picks up a class of error beyond damage procs: a "Chance on hit: +30 Strength for 8
sec" line is priced by uptime × stat weight, not by dpsWeight, so it was scoring in full
on weapons that are never swung. That is what moved the druid list — **The Jackhammer**
("Chance on hit: +300 haste rating"), which cannot proc in form, was the #2 feral main
hand across 40 bands and is gone. Manual Crowd Pummeler stays #1, correctly: its **Use:**
+500 haste does work in cat form.

### What moved

| | ranged cells changed | most often dropped | most often added |
|---|---|---|---|
| warrior | 356 | Soulstring, Venomstrike, Bow of Searing Arrows | Thick Bronze Darts, Naga Heartpiercer, Throat Piercers |
| rogue | 300 | Quillshooter (216), Venomstrike (204) | Precisely Calibrated Boomstick, Baelog's Shortbow, Monolithic Bow |
| hunter | 114 | Ranger Bow, Stinging Bow, Naga Heartpiercer | Venomstrike (30), Bow of Searing Arrows, Verdant Keeper's Aim |
| druid | 40 (MainHand) | The Jackhammer (40) | The Rockpounder, Grimlok's Charge, Impervious Giant |

Paladin, druid and shaman have no ranged *weapon* — their Ranged slot is the relic
(Libram / Idol / Totem) — so nothing there changed. They now declare
`dpsWeightRanged: 0.0` explicitly anyway, so the check below can insist nobody inherits
the melee weight silently again.

### Level 60 is untouched, with one improvement

Worth stating plainly, because these fixes land on the weapon slots and level 60 is
where the Classic guides are the authority. Comparing level 60 before both fixes to
level 60 now, across all three hunter specs and all three rogue specs, main hand /
off hand / ranged:

* **rogue: all nine cells identical.** Nothing moved at 60.
* **hunter: main hand and ranged identical; the off hand improved.** It was
  `Claw of the Frost Wyrm / Hellfire Skiver / Dreamseeker Dandelion` — one guide pick
  and two the model invented, the third of which is a *held-in-off-hand flower*. It is
  now `Kingsfall / Claw of the Frost Wyrm / Harbinger of Doom`, and all three are from
  the guide's own Main Hand / Off Hand list (Kingsfall and Claw at its top tier,
  Harbinger at tier 4). That is the R32 bug in one cell: the guide's one-handers could
  not reach the hunter off hand at all, so the model filled the gap with junk.

The rogue level-60 ranged order — Crossbow of Imminent Doom, Striker's Mark, Nerubian
Slavemaker — is **not** a divergence from the guide, which lists six items at its top
tier including all three of those. Within one tier the order is stat score, and with
the ranged slot correctly worth stats only, +10 hit rating (20 points at the rogue hit
weight of 2.0) beats +24 AP and +14 crit (20.3). Nerubian Slavemaker is the guide's
*first-listed* item because of its 67.5 dps, which is worth nothing to a rogue.

### Level 70 is not generated at all

Every generated band stops at level 69 — verified, max band `hi` is 69 for all six
classes. Level 70 comes entirely from the curated `Data.lua` block, and none of these
files emit a single level-70 row, so nothing here can have touched it.

There is a **pre-existing hole** at 70 that is easy to mistake for one of these fixes.
The curated level-70 block has 891 entries across 21 spec sets, and three specs are
missing from it entirely:

* `HUNTER` marksmanship (beast mastery has 45 entries, survival 35, marksmanship none)
* `ROGUE` assassination and subtlety (combat has 42, the other two none)

A level-70 marksmanship hunter or assassination rogue therefore sees an empty list. It
was like that before this bundle. Filling it is a separate job and the weapon slots are
the part that needs care: at 70 marksmanship gear is effectively the same as beast
mastery and survival, but assassination and subtlety want daggers where combat wants
swords, so combat's list cannot simply be copied across.

---

# What to import

Replacing the files in `GearQuest/_generated/`:

* `Data.Warrior.generated.lua`
* `Data.Warrior.Horde.1to9.generated.lua`  ← changed too, because warrior 1-9 now has its own ranged weight
* `Data.Hunter.generated.lua`
* `Data.Druid.generated.lua`
* `Data.Shaman.generated.lua`
* `Data.Rogue.generated.lua`

`Data.Paladin.*` is byte-identical to what you already have and is not included. The
1-9 files for hunter, druid, shaman and rogue are also byte-identical — no class can
dual wield before level 10 — so they are not included either.

No `.toc` change, no `DataAdapter.lua` change, no `Data.lua` change. The row shape is
exactly what is already there.

**Re-run the two post-processing scripts after dropping the warrior file in** —
`scripts/fix-edgemaster-warrior.mjs` and `scripts/fix-rare-elite-sourcetype.mjs`. Fresh
output has Edgemaster's Handguards in the top 3 for arms at 44-55 and 60 and for fury at
44-58 and 60, so the 56-59 gap the script fills is still there.

# Verification

Run against Henrik's live `DataAdapter.lua`, staged from the repo — not my older copy,
which Cursor has since extended:

```
total entries: 47987  (1176 curated placeholders + 46811 generated)
second call is a no-op: OK
malformed generated entries: 0
duplicate ids: 0
random-enchant rows: 2319, of which carry a suffixId: 2219

guide agreement (guide's best pick inside my top 3):
   paladin 40/41   warrior 44/44   hunter 45/45
   druid   57/57   shaman  44/44   rogue   43/43
picks offered before an item's RequiredLevel: 0 (all six classes)
suffixIds audited against the client data: 17604, value mismatches 0
role check OK, era check OK
off-hand check OK  (3470 picks, 0 violations)
ranged check  OK
```

Row count fell from 47,066 to 46,811 because adjacent levels whose top 3 are identical
are merged into one band, and the ranged and off-hand answers are now more stable across
levels.

Two new standing checks, so neither class of bug can come back quietly:

`check_offhand.py` — for every off-hand pick: a weapon only where the class can dual
wield at that level; a shield only for a class with shield proficiency; a
held-in-off-hand never where dual wield is available; a two-hander or main-hand-only
never, at any level.

`check_ranged.py` — every non-hunter combat spec must declare `dpsWeightRanged == 0`
explicitly rather than inheriting the melee weight by omission, and no non-hunter ranged
pick may owe its place to an on-attack proc.

---

# Still open, needs a UI decision rather than a data fix

For a hunter the melee weapons are pure stat sticks, so two one-handers carry more total
stats than one two-hander — but Henrik's level-60 guide legitimately lists **both** a
Two-Hand section and a Main Hand / Off Hand section, and the model keeps both, ranked
independently. So at level 60 a hunter can be shown a two-hander as the #1 MainHand
*and* a one-hander as the #1 SecondaryHand at once, which is not a combination you can
equip. The same applies to enhancement shaman, whose Classic guide lists only
two-handers while the model also offers a dual-wield off hand.

Forcing hunter to `onehand_dual` would fix the display but make the guide's Two-Hand
"Best" pick (*The Eye of Nerub*) unrankable and drop hunter's guide agreement from
45/45. So the data keeps both, and the addon should say which is which — grey the
off-hand row when the equipped main hand is a two-hander, or label the two routes
"Two-Hand build" / "Dual-wield build". Henrik to decide.
