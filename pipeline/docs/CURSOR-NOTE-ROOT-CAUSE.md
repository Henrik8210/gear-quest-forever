# Root cause found, and it is one line

Three items reported: Shimmering Sash showing **11** healing, Bandit Cinch **8**,
Infiltrator Cap **+29/+29**. Two of the three reproduce exactly from one mistake.

## The addon is using the wrong random-enchant table

WoW has **two** systems and they are not interchangeable:

| | how the value is computed | how it appears in an item link |
|---|---|---|
| `ItemRandomProperties` | **fixed tiers.** Each id is a hard-coded stat pair. No scaling. | **positive** id |
| `ItemRandomSuffix` | `RandPropPoints[ilvl][quality][slotBucket] x allocationPct` | **negative** id |

An item uses one or the other. `item_template` says which: `RandomProperty` set means
tiers, `RandomSuffix` set means scaling.

**All three reported items are PROPERTY items** — `randSuffix = 0`:

| item | ilvl | randProp | randSuffix |
|---|---|---|---|
| Shimmering Sash (6570) | 22 | 878 | **0** |
| Bandit Cinch (9775) | 19 | 898 | **0** |
| Infiltrator Cap (7413) | 33 | 650 | **0** |

Run the *scaling* formula on them anyway, with `ItemRandomSuffix` id 26 ("of Healing",
allocation 22000), and you get:

```
Shimmering Sash   RandPropPoints[22].Good_1 = 5  ->  5 x 2.2 = 11   <-- reported 11
Bandit Cinch      RandPropPoints[19].Good_1 = 4  ->  4 x 2.2 =  8   <-- reported 8
```

Both numbers reproduce to the digit. **That is the bug**: the addon computes a
fixed-tier item as though it scaled with item level.

The truth for those two is a tier id, no arithmetic involved:

```
2029  +7  Healing, +3 Damage Spells
2030  +9  Healing, +3 Damage Spells
2031  +11 Healing, +4 Damage Spells   <-- Bandit Cinch's best (0.8%)
2032  +13 Healing, +5 Damage Spells   <-- Shimmering Sash's best (3.7%)
```

Note **8 is not on that ladder at all** — no tier of "of Healing" grants 8. A value
that cannot exist in the game is the tell that it was calculated rather than looked up.

Infiltrator Cap is a second, separate mistake: **+29/+29 is `of the Tiger` id 753, the
LAST id in a family of 85.** That looks like a name-to-id lookup taking the highest
match. Its real tier is **690** (+8/+8).

## What to change

1. **Do not compute random-enchant stats.** Read the id from the item link (7th field)
   and look the tier up. Positive id -> `ItemRandomProperties`. Negative -> and only
   then -> the `RandPropPoints` formula.
2. **Do not resolve a suffix by name.** `ItemRandomProperties` has 2,012 rows sharing 45
   names; "of the Tiger" alone is 85 tiers and "of Healing" 38.
3. **Use the `suffixId` now in the data.** It is on **98%** of suffixed rows, sign-matched
   to the link convention, so it compares directly with no translation.

## My side is audited, not asserted

`check_suffix_ids.py` recomputes every resolved id from the client files and compares it
to the stored value — positive ids against `ItemRandomProperties` + `SpellItemEnchantment`,
negative ids against `ItemRandomSuffix` x `RandPropPoints`:

```
suffixIds audited against the client data: 17,604
  values agree:                            17,604  (100.00%)
  name mismatches:                              0
  VALUE mismatches:                             0
  no id at all (fall back to the name):       185  (1.0%)
```

So the data is not the source of any of these three. It ships:

```lua
{6570,...,suffix="of Healing",   suffixChance=3.7, suffixId=2032, suffixRange="+11-13 Healing, +4-5 Spell Damage"}
{9775,...,suffix="of Healing",   suffixChance=0.8, suffixId=2031, suffixRange="+9-11 Healing, +3-4 Spell Damage"}
{7413,...,suffix="of the Tiger", suffixChance=5.0, suffixId=690,  suffixRange="+7-8 Agility, +7-8 Strength"}
```

All three match Wowhead TBC exactly. The audit runs with the other standing checks, so
this class of error cannot come back silently — and it should not need reporting item by
item again.
