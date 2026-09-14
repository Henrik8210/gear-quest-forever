# GearQuest — add WARLOCK (affliction, demonology, destruction), levels 1–69

Seventh generated class. Additive: two new data files, two `.toc` lines, two `SOURCES`
rows. Also included: a corrected **priest** pair (see the last section).

## 1. Drop in the new files

```
GearQuest/_generated/Data.Warlock.generated.lua            (0.63 MB, 6276 picks)
GearQuest/_generated/Data.Warlock.Early.1to9.generated.lua (49 KB, 367 picks)
GearQuest/_generated/Data.Priest.generated.lua             (replaces — see below)
GearQuest/_generated/Data.Priest.Early.1to9.generated.lua  (replaces — see below)
```

Tables the warlock files define: `warlockItemFacts`, `warlockPicks`, `warlockNotable`,
`warlockEarly1to9Facts`, `warlockEarly1to9`.

## 2. Two lines in `GearQuest.toc`, after the priest pair

```
_generated\Data.Warlock.generated.lua
_generated\Data.Warlock.Early.1to9.generated.lua
```

## 3. Two rows appended to `SOURCES` in `DataAdapter.lua`, after the priest pair

```lua
  { class = "WARLOCK", picks = "warlockPicks",     facts = "warlockItemFacts",
    hasSpec = true,
    specs = { affliction  = { affliction  = true },
              demonology  = { demonology  = true },
              destruction = { destruction = true } } },
  { class = "WARLOCK", picks = "warlockEarly1to9", facts = "warlockEarly1to9Facts",
    hasSpec = false, factionInRow = true },
```

Tested: `luatest` loads all sixteen generated files plus Henrik's live `DataAdapter.lua`
with the priest and warlock rows added, and the expansion is clean.

## 4. `Spec.lua`

All three warlock specs now have full 10–69 coverage, so **remove `comingLater = true`
from `affliction` and `demonology`**. Destruction never had it.

Note this only fixes levels 10–69. At level 70 affliction and demonology still have no
curated AtlasLoot rows, so if `comingLater` also gates the level-70 view, that needs
handling separately — see the level-70 audit below.

---

# The caster mechanics

Henrik: *"they are not a melee class so weapon physical damage does nothing, they need
stats like the priest."*

**A warlock is never paid for weapon damage in a hand.** `dpsWeight` is 0.0 for all
three specs *and* for levels 1–9. Verified in the output: 396 hand-slot picks are
weapons carrying real physical dps, and not one point of it is scored. Only the **wand**
carries a damage weight (0.15) — a warlock genuinely wands between casts for mana.

**Proficiencies.** Daggers, one-handed swords, staves and wands. No maces, no axes, no
shield. Confirmed in the output: main-hand picks are only Staff, Dagger and Sword1H, and
the off hand is 100% held-in-off-hand items across every spec.

**One guide, three specs.** The page is a single list covering all warlock DPS builds —
it does not split the specs — so all three share it, the way the one hunter DPS guide
serves all three hunter specs. Where they differ is the weights:

| | spell crit | Shadow | Fire | stamina |
|---|---|---|---|---|
| affliction | 0.50 | 0.92 | 0.03 | 0.18 |
| demonology | 0.60 | 0.88 | 0.05 | 0.20 |
| destruction | 0.75 | 0.60 | 0.35 | 0.18 |

Two things drive that. **A DoT cannot crit in this era**, so Corruption, Curse of Agony
and Siphon Life get nothing from spell crit — affliction values it least, while
Destruction's Ruin doubles crit damage on Shadow Bolt, so it values it most. And the
school split is real: affliction is almost pure Shadow, destruction splits with
Immolate, Conflagrate and Searing Pain. **Stamina is weighted higher than for a priest**
(0.18–0.20 against 0.08) because Life Tap makes a warlock's health pool part of its
mana pool.

The effect is small and correctly placed: the three spec lists agree on 12 of 15 slots
at level 60 and differ only in within-tier ordering at Hands, Head and Wrist — which is
exactly what you'd want from three specs sharing one guide.

**Two guide rows deliberately dropped.** The guide lists *"Random of Shadow Wrath Bind
on Equip"* for Head and *"Random of Shadow Wrath"* for Wand. Those are not items — they
mean "any BoE that rolls the of Shadow Wrath suffix", a family rather than a pick. There
is nothing to match them to, so the model decides those slots, which it already does
properly since it ranks every rolled variant on its own.

**One guide typo caught.** The page says *"Cloak of the Hakkari Worshipers"*; the item is
*"Cloak of the Hakkari Worshippers"*, with two Ps. The builder now accepts a near-miss
only when exactly one item name is that close, and **reports it out loud** — a near-miss
that silently resolved to the wrong item would be worse than a failure.

---

# Priest correction (R35)

Henrik: *"priests are no melee class, so ranking weapons after physical damage like the
staff is wrong ... they purely use the benefits of the stats."*

Holy, discipline and shadow were already at `dpsWeight` 0.0 — but **levels 1–9 carried
1.5**, which was the one place a priest's staff damage was still being priced. Now 0.0,
so the rule is absolute for the class. **18 cells changed**, all in the levels 1–9 main
hand. The wand keeps its small weight, which Henrik called out separately as correct.

To be clear about what this did and did not change: at levels 10–69 the priest weapon
lists are unchanged, because weapon damage was already worth nothing there. If a staff
still looks mis-ranked to you at some level, it is not the dps term — send me the slot
and level and I will dig into that specific row.

New standing check `check_caster_weapons.py`: for every pure-caster spec, `dpsWeight`
must be 0 in both hands, levels 1–9 included. 1,511 hand-slot picks are weapons with
real dps and none of it is scored. Paladin holy is deliberately excluded from that rule
— it keeps 0.086, because a Holy paladin really does swing its mace, and at 60 that
turns a 50-dps weapon into 4 points against 30–40 from its stats: a tiebreaker, never a
driver.

**Bench pages also fixed.** The review pages were printing raw stat keys — `sp_from_heal`
and `spShadow` — instead of labels, and showing the school damage twice (once as
`spShadow`, once as the old blended "School spell dmg"). Display only; the scores were
right. All seven pages now label them properly and group the schools separately.

---

# Verification

```
guide agreement (guide's best pick inside my top 3):
   warlock 45/45   priest 43/43   paladin 40/41   warrior 44/44
   hunter  45/45   druid  57/57   shaman 44/44    rogue  43/43
warlock matched 45/45 on the first generation, no tuning

luatest, against Henrik's live DataAdapter.lua + the PRIEST and WARLOCK rows:
   generated rows expanded: 60504
   total entries: 61680  (1176 curated placeholders + 60504 generated)
   malformed generated entries: 0
   duplicate ids: 0
   second call is a no-op: OK

picks offered before an item's RequiredLevel: 0 (all eight classes)
role check OK, era check OK
off-hand check OK (4298 picks, 8 classes)
ranged check OK
school check OK (958 picks carrying a school stat, 8 classes)
caster-weapon check OK (1511 weapon picks in caster hands, no dps scored)
zero unmatched guide item names
```

---

# Level 70 — the audit, for reference

Separate from this bundle, since level 70 is curated and nothing generated here touches
it. Your level-70 block has 936 entries across 22 spec sets; the addon offers 28 specs.
Six have no level-70 list:

| class | spec | flagged `comingLater`? |
|---|---|---|
| ROGUE | assassination | **no — silent hole** |
| ROGUE | subtlety | **no — silent hole** |
| PRIEST | discipline | **no — silent hole** |
| MAGE | frost | yes |
| WARLOCK | affliction | yes |
| WARLOCK | demonology | yes |

Plus two defects inside specs that *are* covered:

* Three warrior protection rows use `slot = "Shield"`. That string appears nowhere else
  in the addon — every other row says `SecondaryHand`, and `PaperDoll.lua`'s
  `SUPPORTED_SLOTS` has no "Shield" either. So a level-70 protection warrior's off hand
  is empty and Bulwark of Azzinoth (32375), Kaz'rogal's Hardened Heart (30889) and
  Vengeful Gladiator's Shield Wall (33755) never appear. One word, three times.
* Shaman enhancement has no `SecondaryHand` row at 70, which is a real gap since
  enhancement dual-wields. Paladin retribution and druid bear/feral are also missing it,
  but those are plausibly deliberate two-hand builds.
