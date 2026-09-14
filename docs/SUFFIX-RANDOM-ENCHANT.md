# Random enchant: two systems, one rule

WoW has **two** random-enchant systems. They are not interchangeable.

| System | DB table | Value source | Link field 7 |
|---|---|---|---|
| `ItemRandomProperties` | fixed tiers (hard-coded stat pairs) | **Positive** id |
| `ItemRandomSuffix` | `RandPropPoints[ilvl][quality][slot] × allocationPct` | **Negative** id |

The sign is deliberate and load-bearing. Field 7 in an item link uses the same sign as
the table id — no translation, no sign flip, no separate branch in the addon.

Across the generated data: ~9,897 positive ids, ~882 negative ids. Both ship in
`suffixId`.

---

## Addon rules (do not violate)

### 1. Match on `suffixId`, never on suffix name

A suffix name maps to many tiers. Examples:

| Name | tiers | consequence of name lookup |
|---|---|---|
| `of Healing` | 38 | wrong stat band |
| `of the Tiger` | 85 | Infiltrator Cap showed +29/+29 instead of +7/+8 |

Each tier has its own client id. Data ships `suffixId` + `suffixRange` per row.

### 2. Never compute stats for positive-id items

The old probe/RandPropPoints path computed values from ilvl. That produced:

- Shimmering Sash `6570` → computed **11** instead of tier `2032` (+11–13 / +4–5)
- Bandit Cinch `9775` → computed **8** instead of tier `2031` (+9–11 / +3–4)

**Delete computation paths.** The scaling formula is only ever correct for negative
ids, and even then a lookup is safer.

### 3. Negative `suffixId` is an identifier, not a failure marker

`of Concentration` on Spectral Necklace `12047` is `suffixId=-30`. That builds:

```
item:12047:0:0:0:0:0:-30:{ilvl}:0
```

The client renders the tooltip. Do **not** write a "negative-id family cannot be
resolved" fallback — it permanently downgrades every `of Concentration`, `of Power`,
and scaling-item roll to a text hint when a real client tooltip is available.

For negative ids, field 8 is the ilvl factor (`GetSuffixLinkLevel` → item level, required
level, or `minLevel` fallback).

### 4. Enrichment lookup is item-scoped only

When filling a missing `suffixId`, lookup by **item + suffix + level band** only.

Never cross-item or take the max id for a suffix name at a level — that caused Infiltrator
Cap `7413` to resolve to family max `753` instead of the correct item tier `690`.

### 5. Notable tables need the same fields as picks

Notables (`*Notable` tables) are separate rows from main picks. They must emit
`suffixId` and `suffixRange` on the **notable emit path**, not just the picks path.

Coverage after fix (six class files):

| | count |
|---|---|
| notable rows with a suffix | 8,458 |
| …with `suffixId` | 8,372 (**99%**) |
| …with `suffixRange` | 8,458 (**100%**) |

`BuildNotableEntry` passes `row.suffixId` / `row.suffixRange` into entries.
`BuildSuffixLookup` ingests both picks and notable tables.

---

## Runtime priority order

For any row carrying a random enchant:

1. **`suffixId` present** → build suffixed link via `MakeSuffixTargetLink`, let the
   client render the tooltip. Works for both signs. ~98% of suffixed picks, ~99% of
   notables.
2. **`suffixId` absent** (~1%) → show base item tooltip + print `suffixRange` as stat
   lines (`AppendSuffixRangeLines`). Never compute.
3. **Completion** → read field 7 from the owned item link; compare with `rolled >= entry.suffixId`.
   Same rule for positive and negative ids.

### Tooltips and async cache

Suffixed links need a client round trip before stats appear. Keep
`GET_ITEM_INFO_RECEIVED` retry (`TrackPendingSuffixTooltip`) for **all** suffixed rows,
not only the no-`suffixId` fallback — first hover can show base stats until the client
caches the link.

Log list quality colors: prime `GetItemInfo` on list build and refresh on
`GET_ITEM_INFO_RECEIVED` so uncached items do not render white (quality 1 default).

---

## Data fields

| field | meaning |
|---|---|
| `suffix` | display name only (`"of Healing"`) — **not** an identifier |
| `suffixId` | client tier id; positive = Property, negative = Suffix |
| `suffixRange` | human-readable stat band for fallback tooltips and log hints |
| `suffixChance` | drop probability from Wowhead enchant tables |

Emit all four on suffixed pick rows **and** notable rows.

---

## Regression cases

| item | level | suffix | correct `suffixId` | wrong approaches |
|---|---|---|---|---|
| Shimmering Sash `6570` | 17 | of Healing | `2032` | computed 11; `2031` must not complete |
| Bandit Cinch `9775` | 14 | of Healing | `2031` | computed 8 |
| Infiltrator Cap `7413` | 28 | of the Tiger | `690` | family max 753 |
| Rigid Shoulders `15116` | 21 | of the Owl | `766` | notable missing id → hint-only tooltip |
| Spectral Necklace `12047` | 25 | of Concentration | `-30` | treating negative as unresolved |

Link field 7 for `6570` holy @17: **2031** must not complete, **2032** must.

---

## Verification

```powershell
node scripts/verify-generated-bis.mjs
python scripts/check_suffix_ids.py   # full id/value audit when bundle updates
```

Expect ≥95% `suffixId` coverage on suffixed pick rows; notable rows should be ~99%.
If notables still lack ids after import, the old generated files are still loaded.

After `/reload` in-game:

- Notable with `suffixId` → full client tooltip with suffix stats
- Notable without `suffixId` (rare) → base item + `suffixRange` text lines
- Never computed stat values

---

## Code map

| file | role |
|---|---|
| `GearQuest/Data.lua` | `MakeSuffixTargetLink`, `EntrySuffixMatchesLink`, `BuildNotableEntry`, tooltip paths |
| `GearQuest/DataAdapter.lua` | `BuildSuffixLookup`, `EnrichEntrySuffix`, passes `suffixId` from generated rows |
| `GearQuest/Log.lua` | list quality colors, tooltip hover |
| `GearQuest/Core.lua` | clears legacy `GearQuestDB.suffixLinks` cache on login |

See also `_rootcause-import/CURSOR-NOTE-ROOT-CAUSE.md` for the original diagnosis.
