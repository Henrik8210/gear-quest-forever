# GearQuest — add MAGE (frost, fire, arcane), levels 1–69

**The last class.** All nine are now generated for levels 1–69.

## 1. Drop in the new files

```
GearQuest/_generated/Data.Mage.generated.lua            (0.58 MB, 6138 picks)
GearQuest/_generated/Data.Mage.Early.1to9.generated.lua (48 KB, 367 picks)
```

Tables: `mageItemFacts`, `magePicks`, `mageNotable`, `mageEarly1to9Facts`, `mageEarly1to9`.

## 2. Two lines in `GearQuest.toc`, after the warlock pair

```
_generated\Data.Mage.generated.lua
_generated\Data.Mage.Early.1to9.generated.lua
```

## 3. Two rows appended to `SOURCES` in `DataAdapter.lua`

```lua
  { class = "MAGE",    picks = "magePicks",        facts = "mageItemFacts",
    hasSpec = true,
    specs = { frost  = { frost  = true },
              fire   = { fire   = true },
              arcane = { arcane = true } } },
  { class = "MAGE",    picks = "mageEarly1to9",    facts = "mageEarly1to9Facts",
    hasSpec = false, factionInRow = true },
```

Tested: `luatest` loads all eighteen generated files plus Henrik's live `DataAdapter.lua`
with all six new rows (priest, warlock, mage), and the expansion is clean.

## 4. `Spec.lua`

**Remove `comingLater = true` from mage `frost`.** With that, and the warlock removals
from the previous bundle, no spec in the addon is flagged `comingLater` for levels
10–69 any more — every one of the 28 specs has data.

---

# How the guide was handled

The page is **a single list written for Fire**, and says so: *"The gear list below focuses
on Fire Mage gameplay. However, if you are playing a different specialization, you will
find several alternatives across the lists."* So all three specs share it, as Henrik
asked, and the specs differ in the weights rather than the list.

**Spell crit is the axis that separates them.** Fire carries the highest spell crit
weight in the whole file (0.85) — Ignite stacks off crits and Combustion is a crit-streak
cooldown, so crit compounds for fire in a way it does not for anyone else. Frost gets
ordinary value (0.65), arcane sits between (0.70).

| | spell crit | Frost | Fire | Arcane | int |
|---|---|---|---|---|---|
| frost | 0.65 | 0.92 | 0.03 | — | 0.45 |
| fire | 0.85 | 0.03 | 0.92 | — | 0.45 |
| arcane | 0.70 | 0.35 | 0.05 | 0.50 | 0.50 |

**Spec-tagged guide rows are honoured per spec.** Four rows carry a spec in the rank
label — `Optional - Frost` on Boreal Mantle, Freezing Lich Robes and Robe of Winter
Night. Those sit at their stated tier for **frost** and one tier lower for fire and
arcane, the same treatment the rogue guide's "(Swords)" sections get. `Optional - Hit`
and `Optional - Mana sustain` are conditional and demote for everyone.

**19 rows name two items.** "Field Marshal's Coronet / Warlord's Silk Cowl" is one slot's
Alliance/Horde PvP pair. Each half is entered as its own pick and the existing faction
gate shows each side only its own — so an Alliance mage sees the Field Marshal's piece
and a Horde mage the Warlord's, never both.

**Not a melee class.** `dpsWeight` is 0.0 for all three specs and for levels 1–9;
proficiencies are daggers, one-handed swords, staves and wands, no shield. Verified:
main-hand picks are only Staff, Dagger and Sword1H, and the off hand is 100%
held-in-off-hand items. Only the wand carries a damage weight (0.15).

Against a warlock, a mage values **intellect more and stamina less** — a bigger mana pool
is a bigger damage pool once Evocation is in the rotation, and a mage has no Life Tap, so
its health is not part of its mana.

---

# Two slots the guide did not give me, and how they were checked

Wowhead's page truncates before the Off-Hand and Wand tables, and I could not retrieve
them. Rather than invent rows, those two slots are left to the model — exactly as priest
holy and discipline have no guide wand section. Mage's guide denominator is therefore 13
slots, not 15.

That is checkable, though, because the **warlock** guide does cover both slots and a mage
shares the item pool and nearly the same stat profile. The model's unguided mage answers
land on the warlock guide's own picks:

| slot | mage (no guide) | warlock guide says |
|---|---|---|
| Off hand | Sapphiron's Left Eye, Royal Scepter of Vek'lor, … | Sapphiron's Left Eye, Royal Scepter of Vek'lor, … |
| Wand | Doomfinger, Wand of Fates, Wand of Qiraji Nobility | Wand of Fates, Doomfinger, Wand of Qiraji Nobility |

Ranks 1 and 2 of the off hand match exactly. The wand names the same three items, with
Doomfinger and Wand of Fates swapped — the model prefers Doomfinger because it carries
more stats, and the ranged slot is scored on stats.

**If you can paste those two tables, folding them in is a regeneration, not a rewrite.**

---

# One judgement call worth your eye

**Arcane's school split.** Frost and fire are unambiguous — a frost mage casts Frostbolt,
a fire mage casts Fireball. Arcane is not: in this era a mage specced Arcane still nukes
with Frostbolt more often than with Arcane Missiles, because deep Arcane is a
support/utility tree rather than a standalone rotation. So arcane is weighted
Arcane 0.50 / Frost 0.35 / Fire 0.05 rather than pure arcane. If you would rather it read
as a true Arcane-Missiles rotation, that is a one-line change and a regeneration.

---

# Verification

```
guide agreement (guide's best pick inside my top 3):
   mage    39/39 (13 slots)   warlock 45/45   priest 43/43
   hunter  45/45              druid   57/57   shaman  44/44
   rogue   43/43              warrior 44/44   paladin 40/41
mage matched 39/39 on the first generation, no tuning

luatest, against Henrik's live DataAdapter.lua + all six new SOURCES rows:
   generated rows expanded: 67009
   total entries: 68185  (1176 curated placeholders + 67009 generated)
   malformed generated entries: 0
   duplicate ids: 0
   second call is a no-op: OK

picks offered before an item's RequiredLevel: 0 (all nine classes)
suffixIds audited against the client data: 17604, value mismatches 0
role check OK (37 specs)
era check OK
off-hand check OK        (4676 picks, 9 classes)
ranged check OK
school check OK          (1236 picks carrying a school stat, 9 classes)
caster-weapon check OK   (1925 weapon picks in caster hands, no dps scored)
zero unmatched guide item names
```

One near-miss reported and accepted: the page says *"Cloak of the Hakkari Worshipers"*;
the item is *"Cloak of the Hakkari Worshippers"*. Same typo the warlock page had. The
builder only accepts a near-miss when exactly one item name is that close, and always
prints it.

---

# Where the project stands

Nine classes, 28 specs, levels 1–69 generated; 67,009 generated rows alongside the 1,177
curated ones. Eight standing checks, each of which exists because something got through
once: `check_levels`, `check_roles`, `check_era`, `check_suffix_ids`, `check_offhand`,
`check_ranged`, `check_school`, `check_caster_weapons`, plus `guide_check2` and a real
Lua integration test.

Still open, none of it blocking:

1. **Level 70 holes** — six spec sets have no curated AtlasLoot rows: rogue
   assassination and subtlety, priest discipline (all three unflagged, so the picker
   offers them silently), plus mage frost, warlock affliction and warlock demonology.
2. **Three warrior protection level-70 rows use `slot = "Shield"`**, a string that exists
   nowhere else in the addon — so Bulwark of Azzinoth, Kaz'rogal's Hardened Heart and
   Vengeful Gladiator's Shield Wall never display. One word, three times.
3. **Shaman enhancement has no level-70 off-hand row**, which is a real gap since
   enhancement dual-wields.
4. **The staff-versus-pair display problem.** For a caster the model ranks a two-hand
   staff and a one-hander in the same slot, so it can show a staff as the #1 main hand
   and an off-hand item as the #1 off hand — not equippable together. It affects priest,
   warlock and mage heavily (over three quarters of main-hand picks are staves) and
   hunter and enhancement shaman for the two-hand/dual-wield version. The data knows
   which route wins per level; a per-band `route = "staff" | "pair"` field is a
   regeneration away if the UI wants to grey the row that does not apply.
