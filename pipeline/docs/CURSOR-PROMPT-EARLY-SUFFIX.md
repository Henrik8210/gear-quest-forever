# GearQuest — random enchants below level 10 show no stats (R37)

## The symptom

On a level 6 Alliance paladin, the tooltip for **Charger's Pants of Strength** reads:

```
Target random enchant: of Strength · ~10% on drop
```

…and nothing else. No stat numbers. Above level 9 the same kind of row prints the
actual values, so it looks like a paladin problem or a starter-zone problem. It is
neither — it is **every random enchant below level 10, for every class and both
factions**, and it has two independent causes that happen to stack on this character.

---

## Cause 1 — my generated 1-9 files were missing two fields (fixed, files attached)

`suffixId` and `suffixRange` are what let the addon resolve *which tier* of a suffix
a row means and print its numbers. `payload.py`, which emits the main per-class files,
has written them since the random-enchant fix. The two **1-9 emitters** were missed.

Result, before this fix:

| | suffix rows | missing `suffixId` |
|---|---|---|
| the nine 1-9 files | 137 | **137 — all of them** |
| the nine main files | 13,733 | 169 (1.2%) |

`DataAdapter.lua` behaves correctly given that input — `ingest` bails on its first line:

```lua
if not suffix or suffix == "" or not suffixId or suffixId == 0 then
```

so no lookup entry is ever built for those rows, and there is no other level band of
Charger's Pants to borrow a range from. Nothing to fall back to, so nothing prints.

**Fixed. All nine 1-9 files are attached and now carry both fields on 137/137 rows.**
Shipped random-enchant coverage across the whole addon goes from 95.5% to **99.5%**.

Nothing else changed in those files — same picks, same order, same scores. Just drop
them into `GearQuest/_generated/`. No `.toc`, `DataAdapter.lua` or `Spec.lua` change.

---

## Cause 2 — one hand-curated row in `Data.lua` (this is the bit for you)

The row Henrik was actually looking at is not generated at all. He is a **Human**
paladin, and Alliance 1-9 paladin data is curated in `Data.lua` — the generated paladin
1-9 file is Horde-only. There is **exactly one** curated row in the whole file that
carries a `suffix` field, and it has no `suffixId` and no `suffixRange`:

```lua
{
    id = "early6_legs_chargers_pants",
    itemId = 15477,
    slot = "Legs",
    minLevel = LEVEL6_MIN,
    maxLevel = LEVEL6_MAX,
    classes = MAIL_MELEE,
    factions = ALLIANCE,
    curatedRank = 2,
    sourceType = "world_drop",
    suffix = "of Strength",
    suffixChance = 10.0,
    instructions = "Charger's Pants of Strength (req 6) are a green mail world drop in starter zones (101 armor, +1–2 Strength). Hunt the of Strength roll.",
    zone = "Elwynn Forest",
},
```

### The change

Add these two fields to that row, next to `suffixChance`:

```lua
    suffixId = 23,
    suffixRange = "+1-2 Strength",
```

### Where the numbers come from — please don't take them on trust, they are checkable

* `suffixId = 23` is `ItemRandomProperties` id **23** in the 2.5.4 client data. Its
  `Name_lang` is `"of Strength"` and its single enchantment (id 69) is `"+2 Strength"`.
  That is the top tier — the roll to hunt — which is what `suffixId` means everywhere
  else in this addon.
* `suffixRange = "+1-2 Strength"` is the span Wowhead shows for this item, `+(1 - 2)
  Strength`, because two different property ids share the name "of Strength" and both
  can land on a level 6 item.
* Independent cross-check: the regenerated **Horde** paladin 1-9 file now contains the
  same item at the same level, emitted by the pipeline rather than by hand, and it says
  exactly the same thing:

  ```lua
  {15477,"Legs",6,6,1,2.8,suffix="of Strength",suffixChance=10.0,suffixId=23,suffixRange="+1-2 Strength"}
  ```

  So after this change the Alliance curated row and the Horde generated row agree,
  which is the outcome to aim for.

The `instructions` prose already says "+1–2 Strength", so no text change is needed —
the tooltip just needs the structured field to render from.

---

## How to verify the fix in-game

1. Level 6 Alliance paladin or warrior, hover the Charger's Pants entry. The tooltip
   should now read the suffix name, the ~10% chance **and** `+1-2 Strength`.
2. Level 6 **Horde** paladin or warrior — same item, now served by the regenerated
   generated file. Should show the same numbers. If Alliance and Horde disagree, one of
   the two paths did not pick up.
3. Any class at levels 1-9 with a random-enchant pick — priest, mage and warlock have
   the fewest (4-15 rows each), shaman the most (32). All should print numbers now.

---

## A note on why this slipped, in case it shapes where you look next

This is the third emitter to miss the same pair of fields. The first time, `suffixId`
went into `payload.py`'s picks path but not its notable path, and shipped at 21%
coverage until it was caught. This time it went into `payload.py` but not
`emit_early.py` or `emit_horde19.py`.

The standing check I have counts coverage across the *whole* dataset, where 137 rows out
of 13,870 is a 1% dip — small enough to look like the known unresolvable tail rather
than a systematic hole in one file group. A per-file assertion would have caught it on
the first run. That is on my side and I am adding it.
