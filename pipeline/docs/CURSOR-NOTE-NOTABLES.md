# Re: "notables lack suffixId" — correct conclusion, one wrong premise

Cursor's read is right that it needs the newer bundle. But it is diagnosing against the
files currently merged in the repo, and one of its stated reasons is wrong in a way that
would bake a permanent bad branch into the addon. Correcting that before it ships.

## What is actually in the current generated files

Both examples Cursor named are already resolved, `suffixId` included, in the **notable**
tables:

```lua
{15116,"Shoulder",21,21,"restoration","Alliance",
  suffix="of the Owl", suffixChance=17.3,
  suffixId=766,  suffixRange="+4-5 Intellect, +4-5 Spirit"}

{12047,"Neck",25,25,"restoration","Horde",
  suffix="of Concentration", suffixChance=1.0,
  suffixId=-30, suffixRange="+2 Mana per 5"}
```

Notable-table coverage across the six classes:

| | count |
|---|---|
| notable rows carrying a suffix | 8,458 |
| …with `suffixId` | **8,372 (99%)** |
| …with `suffixRange` | **8,458 (100%)** |

So there is no notable-specific data gap left. The previous bundle had one — `suffixId`
was added to the picks emit path but not the notable path — and that is fixed.

## The premise to drop

> "Concentration rows in picks have `suffixRange` but no `suffixId` (ilvl-scaling /
> negative-id family)"

**Negative-id families are resolved.** `of Concentration` on item 12047 is
`suffixId=-30`. The sign is deliberate and load-bearing:

| sign | table | in the item link |
|---|---|---|
| **positive** | `ItemRandomProperties` — fixed tiers | positive 7th field |
| **negative** | `ItemRandomSuffix` — scales with item level | negative 7th field |

Across all twelve files: **9,897 positive, 882 negative.** Both kinds ship. Because the
sign already matches the link convention, `suffixId` compares against
`select(7, strsplit(":", link))` directly — no branch, no translation, no sign flip.

Do **not** write a "negative-id family cannot be resolved" fallback. It would
permanently degrade every `of Concentration`, `of Power`, `of the Bear`-on-a-scaling-item
row to a text hint when a real client tooltip is available.

## Priority order for a random-enchant row

1. **`suffixId` present** → build the suffixed item link and let the client render it.
   Works for both signs. This is 98% of suffixed rows and 99% of notable rows.
2. **`suffixId` absent** (the remaining 1%) → print `suffixRange` as the stat lines.
   That is what it is for, and Cursor's fallback here is the right idea.
3. **Never compute the value.** Computing is what produced 11 on Shimmering Sash and 8
   on Bandit Cinch — see CURSOR-NOTE-ROOT-CAUSE.md. The scaling formula is only ever
   correct for negative ids, and even then a lookup is safer.

The async `GET_ITEM_INFO_RECEIVED` retry Cursor added is worth keeping regardless —
suffixed links legitimately need a round trip before the client has the data.

## After import, verify

- `15116` at level 21, druid/shaman restoration Shoulder notable → `suffixId=766`,
  tooltip shows +4-5 Intellect / +4-5 Spirit.
- `12047` at level 25, restoration Neck notable → `suffixId=-30`, tooltip shows
  +2 Mana per 5.
- A notable row with a suffix and **no** `suffixId` should be rare (1%) — if it is
  common, the old files are still loaded.
