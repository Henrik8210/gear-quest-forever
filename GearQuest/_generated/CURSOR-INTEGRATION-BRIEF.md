# GearQuest — integrating the generated Paladin BiS data

Brief for Cursor. Read §1–3 before writing code; §4 is the implementation.

---

## 1. What GearQuest is

A World of Warcraft **TBC Anniversary (Interface 20505)** levelling addon. For any
class/spec/level it shows the three best-in-slot options per gear slot, ranked, so
a levelling player knows what to chase. Each option is a "hunt" the player can
track — the addon watches loot, quest turn-ins and crafting, and fires a toast
when a tracked item is obtained.

`## Notes: Leveling gear upgrades — click a slot, pick a hunt, track it in the log.`

Existing files and load order (`GearQuest.toc`):

```
Core.lua  Spec.lua  Preview.lua  Equip.lua  Data.lua  Compare.lua
Indicator.lua  Log.lua  Toast.lua  Tracker.lua  Popup.lua
PaperDoll.lua  Minimap.lua  Commands.lua
```

`Data.lua` holds **1,176 hand-curated entries** — Alliance levels 1–9, and level
70 for all specs from AtlasLoot Phase 3 BiS lists. **Do not modify or replace
them.** They are more trustworthy than anything generated, and the generated data
is deliberately built to not overlap them.

---

## 2. The existing data contract

`GQ.Data.entries` is a plain **array**, iterated with `ipairs` in three places:
`Indicator.lua:321` (priming item names), `Log.lua:213` and `Log.lua:1018`
(obtain detection). One entry:

```lua
{
    id = "early4_all_head_crown_fire_festival",  -- unique string
    itemId = 23323,
    slot = "Head",                -- "Head","Neck","Shoulder","Back","Chest","Wrist",
                                  -- "Hands","Waist","Legs","Feet","Finger","Trinket",
                                  -- "MainHand","SecondaryHand","Shield","Ranged"
    minLevel = 1, maxLevel = 8,
    curatedRank = 1,              -- 1, 2 or 3
    classes  = { PALADIN = true },       -- optional; absent means all classes
    specs    = { retribution = true },   -- optional; absent means all specs
    factions = { Alliance = true },      -- optional; absent means both
    sourceType   = "seasonal_quest",
    instructions = "...",         -- human-readable "how to get it"
    zone = "...", npc = "...", questName = "...", profession = "...",  -- all optional
}
```

**The generated data uses identical key names and identical value spellings** —
`PALADIN` uppercase, `retribution`/`protection`/`holy` lowercase, `Alliance`/`Horde`
capitalised. No translation needed.

---

## 3. The generated files

### 3.1 Coverage — the four sources never overlap

| level range | faction | source |
|---|---|---|
| 1–9 | Alliance | **Henrik's hand-made entries in `Data.lua`** |
| 1–9 | Horde | `_generated/Data.Paladin.Horde.1to9.generated.lua` |
| 10–69 | both | `_generated/Data.Paladin.generated.lua` |
| 70 | both | **Henrik's curated AtlasLoot entries in `Data.lua`** |

Level 70 is absent from the generated data on purpose: the stat-weight model
measured 0/44 against the curated AtlasLoot lists, because endgame BiS turns on
set bonuses, gem sockets and librams that the model cannot see. Never generate
over it.

### 3.2 `Data.Paladin.generated.lua` — levels 10–69

Three tables. Item facts are stored **once** rather than per row, because the same
item appears in dozens of level bands and inlining the instruction text per row
would multiply the file by ~6x.

```lua
GQ.Data.itemFacts = {
  [22798] = { name="Might of Menethil", sourceType="boss_drop",
              instructions="Drops from Kel'Thuzad in Naxxramas.",
              zone="Naxxramas", npc="Kel'Thuzad",
              proc="Chance on hit: ..." },     -- proc/effect text, optional
  ...
}

-- { itemId, slot, minLevel, maxLevel, rank, spec, faction, score }
GQ.Data.paladinPicks = {
  { 22798, "MainHand", 60, 60, 1, "retribution", "Alliance", 457.47, origin="guide" },
  { 15487, "Chest", 13, 13, 2, "retribution", "Alliance", 7.27,
    suffix="of Strength", suffixChance=9.7 },
  ...
}

-- { itemId, slot, minLevel, maxLevel, spec, faction }
GQ.Data.paladinNotable = { { 19019, "MainHand", 60, 60, "protection", "Alliance" }, ... }
```

9,180 picks, 1,950 interned items, 1.13 MB.

**Positional fields 1–8** are always present in that order. **Named fields are
optional:**

- `suffix` / `suffixChance` — a random-enchantment item. The score assumes the
  **best roll**; `suffixChance` is the percentage odds of getting *any* roll of
  that suffix. Worth surfacing: *"War Torn Tunic **of Strength** — 9.5% chance"*
  is far more useful than the bare item name, because the player needs to know
  they are hunting a specific roll.
- `origin="guide"` — this level-60 pick came from the Wowhead Classic BiS guide
  rather than the model. 206 rows. Worth a UI distinction; these are the most
  trustworthy rows in the file.

`score` is a ranking number only. It is comparable **within** a slot/spec/level
and meaningless across them. Do not show it as a stat.

`GQ.Data.paladinNotable` holds items whose value is a **proc the score cannot
price** — Thunderfury's printed stats are 5 Agility and 8 Stamina, yet every guide
ranks it first in slot for a tank. They are *not* part of the top three. Show them
beside it ("worth considering — the proc is the point") using the `proc` text from
`itemFacts`. Ignoring this table is acceptable for a first pass; the picks table
is complete without it.

### 3.3 `Data.Paladin.Horde.1to9.generated.lua` — Horde levels 1–9

Separate namespace so it cannot collide with the hand-made Alliance data:

```lua
GQ.Data.paladinHorde1to9Facts = { [727] = { name=..., sourceType=..., ... }, ... }
-- { itemId, slot, minLevel, maxLevel, rank, score }
GQ.Data.paladinHorde1to9 = { { 2570, "Back", 1, 2, 1, 0.07 }, ... }
```

221 picks, 156 items, 37 KB. **No spec column and no faction column** — paladins
have no talents before level 10, so one list serves all three specs, and every row
is Horde by construction.

---

## 4. Implementation

### 4.1 `.toc` — INSERT, do not replace

**Do not overwrite the existing `.toc` with a supplied one.** This addon is under
active development on other fronts; the live `.toc` may list files that did not
exist when this data was generated. Insert three lines into whatever is there now.

Find the `Data.lua` line and add immediately after it:

```
_generated\Data.Paladin.generated.lua
_generated\Data.Paladin.Horde.1to9.generated.lua
DataAdapter.lua
```

Order matters and is the only constraint: both generated files must load **after**
`Data.lua` (so the curated entries exist first) and **before** `DataAdapter.lua`
(which expands them). Everything already in the `.toc` keeps its current position.

Paths are relative to the `.toc`. The backslash is the `.toc` format's separator
for subdirectories — if the client fails to find the files, move the two `.lua`
files to the addon root and drop the `_generated\` prefix.

### 4.2 `DataAdapter.lua` — expand into `GQ.Data.entries`

The lowest-risk integration: append expanded rows onto the existing array, so
`Indicator.lua`, `Log.lua` and `Tracker.lua` need **no changes at all**.

```lua
local _, GQ = ...

local PALADIN = { PALADIN = true }
local SPEC    = { retribution = { retribution = true },
                  protection  = { protection  = true },
                  holy        = { holy        = true } }
local FACTION = { Alliance = { Alliance = true }, Horde = { Horde = true } }

-- The two files have DIFFERENT row shapes, so the shape is passed in explicitly
-- rather than inferred positionally:
--   main       { itemId, slot, minLevel, maxLevel, rank, spec, faction, score }
--   Horde 1-9  { itemId, slot, minLevel, maxLevel, rank, score }
-- Reading r[6] as the spec in both would read the Horde file's SCORE as its spec.
local function Expand(rows, facts, shape)
    if not rows or not facts then return end
    local out = GQ.Data.entries
    for i = 1, #rows do
        local r = rows[i]
        local itemId, slot, minL, maxL, rank = r[1], r[2], r[3], r[4], r[5]
        local spec    = shape.hasSpec and r[6] or shape.spec
        local faction = shape.hasSpec and r[7] or shape.faction
        local f = facts[itemId]
        if f then
            out[#out + 1] = {
                id           = ("gen:%d:%s:%d:%s:%s"):format(
                                   itemId, slot, minL, tostring(spec), tostring(faction)),
                itemId       = itemId,
                slot         = slot,
                minLevel     = minL,
                maxLevel     = maxL,
                curatedRank  = rank,
                classes      = PALADIN,
                specs        = spec and SPEC[spec] or nil,
                factions     = faction and FACTION[faction] or nil,
                sourceType   = f.sourceType,
                instructions = f.instructions,
                zone         = f.zone,
                npc          = f.npc,
                questName    = f.questName,
                profession   = f.profession,
                -- generated-only extras; safe for existing consumers to ignore
                suffix       = r.suffix,
                suffixChance = r.suffixChance,
                origin       = r.origin,
                proc         = f.proc,
                generated    = true,
            }
        end
    end
end

function GQ.Data:LoadGenerated()
    if self._generatedLoaded then return end
    self._generatedLoaded = true
    Expand(self.paladinPicks,     self.itemFacts,
           { hasSpec = true })                       -- spec + faction are in the row
    Expand(self.paladinHorde1to9, self.paladinHorde1to9Facts,
           { hasSpec = false, spec = nil, faction = "Horde" })  -- all specs, Horde
end
```

Call `GQ.Data:LoadGenerated()` once during your existing init in `Core.lua`,
**before** `GQ.Indicator:PrimeDataItemInfo()` runs.

Notes on the shape above, all load-bearing:

- **`id` must be unique.** Prefix with `gen:` so it can never collide with a
  curated id, and include spec and faction — the same item legitimately appears
  for several specs and both factions at the same level.
- **Reuse the shared `PALADIN` / `SPEC` / `FACTION` tables** rather than building
  a fresh table per row. 9,401 rows × 3 tiny tables is a lot of garbage for no
  benefit; these are read-only.
- **Copying `f.instructions` is free.** Lua interns strings, so each entry stores
  a pointer, not a copy. That is why interning the facts table works.
- **`spec` is `nil` only for the Horde 1–9 file**, where it means "applies to all
  three specs". The main file always names one. This is why the shape is passed in
  rather than sniffed from the row.

### 4.3 Sanity checks after wiring

1. `#GQ.Data.entries` should be **1179 + 9180 + 221 = 10,580** (run `node scripts/verify-paladin-bis.mjs` — do not trust stale counts).
2. Level 70, any spec: every pick should be a curated entry (`generated` nil).
3. Level 5 Alliance: curated only. Level 5 Horde: generated only.
4. Level 60 Protection main hand: rank 1 should be **Thunderfury, Blessed Blade of
   the Windseeker**, carrying `origin = "guide"`.
5. Level 13 Retribution chest: rank 1 **Soldier's Armor** with
   `suffix = "of Strength"`, `suffixChance = 9.5`.
6. No entry should have `minLevel > maxLevel`, and none should exceed level 69
   outside the curated set.

### 4.4 UI opportunities this data enables

Not required, but the data is there:

- **Random-enchant hunts** need the suffix shown and the odds stated, or the
  player will think a plain drop counts. This is the single most valuable addition.
- **`origin="guide"`** marks the level-60 picks as guide-sourced rather than
  model-derived.
- **`proc` text** answers "why is this item good?" for items whose stats look
  unremarkable.
- **`paladinNotable`** is the "the proc is the point" shelf beside the top three.

---

## 5. Regenerating

The pipeline lives outside the addon. To rebuild:

```
build_items.py  ->  items.json        (stats, effects, procs, from Wowhead tooltips)
build_sources.py -> sources.json      (how to get each item)
build_random_wh.py -> items_random.json (random enchantments, scraped from Wowhead)
obtainability.py -> obtainability.json (acquisition-chain audit)
score.py        ->  paladin.json      (ranking, banding, level-60 guide override)
payload.py      ->  Data.Paladin.generated.lua + the review page payload
emit_horde19.py ->  Data.Paladin.Horde.1to9.generated.lua
```

`GEARQUEST-BIS-PIPELINE.md` documents every rule the pipeline encodes and why —
read it before changing weights or adding a class.
