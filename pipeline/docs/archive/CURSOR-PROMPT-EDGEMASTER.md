# GearQuest — retire the Edgemaster patch; fix it in the weights instead (R38)

## Summary

Delete `scripts/fix-edgemaster-warrior.mjs` and stop post-processing warrior hands.
Edgemaster's Handguards now earns **rank 1 for arms and fury from level 44 to 59** from
the model itself, in the four attached regenerated files. No patch, no forced ranks.

## Why the patch had to go

Henrik spotted three symptoms in the patched output, and all three are consequences of
reordering ranks after the fact rather than fixing the scoring:

1. **Rows where #2 outscored #1.** arms L51-52 had Edgemaster at 28.81 in rank 1 with
   Fists of Phalanx at 29.59 in rank 2. Same at arms L55 (28.81 over 34.24) and fury
   L58 (30.36 over 39.08). The list stopped being sorted by its own score.
2. **A gap at arms 56-59.** The patch promoted Edgemaster "only where it already
   exists", and the model had already dropped it out of the arms top 3 by 56 — so the
   intended "BiS 44-60" was never actually delivered for arms.
3. **A spec-mismatched score.** The protection L60 row carried **28.81**, which is the
   *arms* number. Protection's real figure for that item is **17.96** — a prot warrior
   weights Mail at 0.55 and does not value hit and expertise the way a DPS spec does. So
   a 17.96 item was displaying as 28.81 and holding a top-3 slot it had not earned.

It is also what corrupted `Data.Warrior.generated.lua` this morning — the same script's
splice offset bug.

## The actual root cause: the item changed in TBC, and my weights were pre-TBC

Henrik found this. In Classic, Edgemaster's Handguards is 201 armor with **+7 Axes, +7
Daggers, +7 Swords**. Weapon skill in Classic reduced miss, dodge and parry *and* raised
glancing-blow damage — worth far more than the tooltip suggested, which is why the item
was famously BiS for a huge level range.

In TBC it is **230 armor, +19 hit rating, +17 expertise rating** — good, but ordinary.

My item table already had the TBC version (verified: the whole table has **zero** items
carrying weapon skill or flat weapon damage, and 1,500+ carrying expertise, resilience,
spell haste and armor penetration — all TBC-only stats). So the data was right. What was
wrong was the **weights**: arms and fury valued hit at 0.85 and expertise at 0.75
against strength at 1.0. For TBC melee that is too low — hit rating is the top stat until
the cap and expertise is close behind, since each removes a miss or a dodge that costs a
whole swing. Common TBC melee EP puts hit at 1.3-1.6 strength-equivalents pre-cap.

Corrected:

| spec | hit | expertise |
|---|---|---|
| warrior arms | 0.85 → **1.35** | 0.75 → **1.15** |
| warrior fury | 0.90 → **1.45** | 0.80 → **1.25** |
| paladin retribution | 0.85 → **1.35** | 0.75 → **1.15** |

Protection and holy are untouched — a tank's valuation of hit and expertise is a
different question and this change is deliberately narrow.

## What that produces

Edgemaster's, earned rather than forced:

| spec | placement |
|---|---|
| arms | **rank 1 at L44-59**, rank 2 at L60 |
| fury | **rank 1 at L44-59**, rank 2 at L60 |
| protection | not in any top 3, at any level |

**Level 60 goes to Gauntlets of Annihilation** (702 armor, 35 str, 15 sta, 14 crit, 10
hit) and it should. I tested whether any defensible weight could put Edgemaster first at
60 and none can — even at an extreme hit/expertise of 1.85 each it lands 4th, because
Annihilation carries 10 hit of its own so it rises too. So the honest answer to "BiS from
44-60" is **44-59 by merit, with 60 going to a raid epic.** The item was nerfed in TBC;
that is the finding, not a modelling failure.

Protection having none of it is correct, not an omission: prot's real hands picks score
35-58 across those levels against Edgemaster's 17.96.

## What else the weight change moves

This is a weights change, so it is not confined to one slot. Measured:

* **warrior: 659 cells** — biggest movers are Ranged (66 each for arms and fury, because
  hit rating on a gun or bow now counts properly), Legs, SecondaryHand, Neck.
* **paladin: 253 cells** — retribution only; Legs, Feet, Head, Neck, Finger, Trinket.
* protection and holy: unchanged.

Guide agreement is unchanged: **warrior 44/44, paladin 40/41** (the one paladin miss is
the pre-existing retribution Neck row, not new).

## Also in this change: two dead weight keys zeroed

`wpnSkill` and `wpnDmg` still carried non-zero values in 31 spec blocks, and **no item in
the TBC table can ever match them** — weapon skill and flat weapon damage were removed in
TBC. Harmless, but exactly the kind of stale key that caused the `spSchool` bug: a weight
that looks meaningful and silently applies to nothing. Zeroed; confirmed it changed no
picks (659/253 cell counts are identical before and after).

## What to do

1. Drop in the four attached files, replacing what is in `GearQuest/_generated/`:
   * `Data.Warrior.generated.lua`
   * `Data.Warrior.Horde.1to9.generated.lua`
   * `Data.Paladin.generated.lua`
   * `Data.Paladin.Horde.1to9.generated.lua`
2. **Delete `scripts/fix-edgemaster-warrior.mjs`** and remove it from the import
   pipeline. Also drop the protection @60 rank-3 insert it applied — that row should not
   exist.
3. Still re-run, as before: `fix-bow-searing-arrows-warrior.mjs` and
   `fix-rare-elite-sourcetype.mjs`.
4. Update the verify target: **68,209** entries (1,176 curated placeholders + 67,033
   generated) in my harness. Your own count will differ by the curated total.

## Verification

```
guide agreement:  warrior 44/44   paladin 40/41  (both unchanged)
luatest, against your live DataAdapter.lua:
   total entries 68209   malformed 0   duplicate ids 0   second call a no-op
picks offered before an item's RequiredLevel: 0
role check OK, era check OK, off-hand OK, ranged OK, school OK, caster-weapon OK
suffixIds audited against the client data: 17604, value mismatches 0
```

## Worth a decision at some point, but not in this change

The armour-class multiplier scales the **whole** score, including hit and expertise. A
mail glove's hit rating is worth exactly what a plate glove's hit rating is worth, so
multiplying it by 0.86 double-counts the armour deficit that the `armor` stat already
captures. Fixing that properly means the multiplier applies only to the armour-derived
part, which touches every class — a bigger change than this one, and worth doing
deliberately rather than as a side effect. Flagging it, not doing it.
