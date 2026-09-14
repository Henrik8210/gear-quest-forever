# The random-enchant bug: stop matching on the suffix NAME

Henrik's Shimmering Sash of Healing shows **+11 Healing**. He expected 13 + 5 and
concluded the data was Classic-era. It isn't. Both are TBC, and they are **two
different items**.

## The actual mechanic

`ItemRandomProperties` in the TBC client data has **2,012 rows sharing only 45 names**.
43 of those names appear on multiple ids — up to **85 tiers called exactly the same
thing**. "of Healing" alone is 38 fixed tiers:

```
2027   +2  Healing Spells and +1  Damage Spells
...
2031   +11 Healing Spells and +4  Damage Spells    <-- what Henrik looted
2032   +13 Healing Spells and +5  Damage Spells    <-- the tier he wants
...
2064   +84 Healing Spells and +28 Damage Spells
```

Shimmering Sash (6570) can roll **either 2031 or 2032**. He got 2031. That is a
legitimate TBC roll of a legitimate TBC item — just the worse of the two tiers this
item can produce. Wowhead prints the pair as "+(11 - 13) Healing Spells and +(4 - 5)
Damage Spells" because it is showing the whole span the item can roll.

`ItemRandomSuffix` (the ilvl-scaling families) is better behaved — 75 rows, 66 names,
9 names on two ids — but still not unique.

**So a name is not an identifier.** Matching "of Healing" cannot distinguish +2/+1 from
+84/+28. That is why a bad roll registers as the target and a good roll is not
recognised as an upgrade.

## What the addon must do

**1. Read the id out of the item link, not the name.**

In TBC Classic an item link is
`item:itemId:enchant:gem1:gem2:gem3:gem4:suffixId:uniqueId:level:...` — the **7th**
numeric field:

```lua
local function SuffixIdFromLink(link)
    if not link then return nil end
    local id = select(7, strsplit(":", link))     -- 7th field
    return tonumber(id)                           -- nil / 0 when not random
end
```

Positive = an `ItemRandomProperties` id (fixed tiers, the case above).
Negative = an `ItemRandomSuffix` id (values scale with item level).
`0` or nil = not a random-enchant item.

**2. Compare ids, and exploit that they are ordered.** Inside one name family the ids
are monotonic in value (2027 < 2028 < … < 2064 is worst → best). So "is my roll good
enough" is a `>=` on the id *within the same name*:

```lua
if rolled == target then           -- exact match, done
elseif rolled > target then        -- better tier than we asked for, also done
else                               -- same suffix name, weaker tier: NOT a match
end
```

That last branch is the one currently missing. It is why Henrik cannot get past 11.

**3. Show the tier, not just the name.** "of Healing" alone is useless to a player
comparing two drops. Show what it actually granted, and what the target grants.

## What changed in the data to make that possible

The generated rows now carry two new optional fields next to `suffix`:

```lua
{6570,"Waist",17,17,3,"holy","Alliance",4.16,
  suffix="of Healing", suffixChance=3.7,
  suffixId=2032,
  suffixRange="+11-13 Healing, +4-5 Spell Damage"},
```

- **`suffixId`** — the client id of the exact tier being recommended. **Match on this.**
  Present on **98%** of the 10,993 suffixed rows across all twelve files (99% of the
  17,789 underlying variants resolve). Positive = an `ItemRandomProperties` id,
  negative = an `ItemRandomSuffix` id — the same sign convention as the item link, so it
  compares directly. **If `suffixId` is present, use it; on the remaining 2%, fall back
  to the name.**
- **`suffixRange`** — the printable span, e.g. `"+11-13 Healing, +4-5 Spell Damage"`.
  Show this in a tooltip. Do not show only the top of the range: a looted item reading
  +11 is still the right item, just not the best tier.

Scoring also changed with it: the rank score is now the **midpoint** of each suffix's
range rather than the top, since 35% of variants have a real range. Small effect
(median low/high ratio is 1.00), but it stops the list implying every roll is a jackpot.

## The second case Henrik found, and why it is worse

*Infiltrator Cap of the Tiger* showed **+29 Agility, +29 Strength** in the addon.
Wowhead TBC says the item rolls **+(7 - 8) Agility, +(7 - 8) Strength** at 5.0%.

"of the Tiger" is **85 ItemRandomProperties tiers**, ids 669 → 753, a clean ladder:

```
669   +1  Agility, +1  Strength
...
690   +8  Agility, +8  Strength     <-- what Infiltrator Cap can actually roll
...
753   +29 Agility, +29 Strength     <-- what the addon displayed: the LAST id in the family
```

The addon landed on **753**, the top of the family. Infiltrator Cap's property group
cannot produce it. So this is not "the wrong tier of a real roll" like the Shimmering
Sash — **the addon was showing a target that does not exist on that item.** A player
could farm it forever.

Shimmering Sash landing low (2031 instead of 2032) and Infiltrator Cap landing at the
family maximum (753 instead of 690) are the same defect: a name being resolved to an
arbitrary member of a family of up to 85. There is nothing to resolve now — the id is
in the data.

Both are fixed in this bundle:

```lua
{7413,"Head",28,28,3,"combat","Alliance",3.88,
  suffix="of the Tiger", suffixChance=5.0,
  suffixId=690, suffixRange="+7-8 Agility, +7-8 Strength"}

{6570,"Waist",17,17,3,"holy","Horde",3.71,
  suffix="of Healing", suffixChance=3.7,
  suffixId=2032, suffixRange="+11-13 Healing, +4-5 Spell Damage"}
```

## Verify

- `#GQ.Data.entries` == **1,177 curated + 46,701 = 47,878**. Zero duplicate ids.
- Item 6570 (holy paladin, level 17) carries `suffixId=2032`,
  `suffixRange="+11-13 Healing, +4-5 Spell Damage"`.
- Item 7413 (combat rogue, level 28) carries `suffixId=690`,
  `suffixRange="+7-8 Agility, +7-8 Strength"` — **not** the +29/+29 tier, which that
  item cannot roll.
- `suffixId` is present on 98% of suffixed rows, in the **notable** table as well as the
  picks table. An id-less row means fall back to the name for that one.
- A looted Shimmering Sash with link field 7 == `2031` must **not** count as that pick.
  With `2032` it must. That single case is the regression test for this whole class of bug.
