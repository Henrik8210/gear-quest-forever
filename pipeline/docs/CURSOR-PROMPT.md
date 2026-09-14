# Paste this into Cursor (in the REAL GearQuest repo)

We're adding generated best-in-slot data for **Paladin** to GearQuest. The data
and the loader are written and tested — your job is to **merge them into this
repo**, review the loader, then build the UI that uses the new fields.

## Context you need

GearQuest is a World of Warcraft **TBC Anniversary** addon (Interface 20505). It
shows the three best-in-slot gear options per slot for a given class/spec/level
while levelling, and lets the player track one as a "hunt" — the addon watches
loot, quest turn-ins and crafting, and fires a toast on pickup.

The data was generated outside this repo from Wowhead's TBC item data, the cmangos
2.4.3 world database, and Wowhead's Classic BiS guides. Two documents come with it:

- **`CURSOR-INTEGRATION-BRIEF.md`** — read first. Data contract, row shapes,
  the loader, sanity checks.
- **`GEARQUEST-BIS-PIPELINE.md`** — the 14 rules the generation encodes and the
  measurement behind each. Read before changing anything about the data.

## Files to merge

These six files have been added to this repo (extracted from
`GearQuest-Paladin-BiS.zip`). Confirm each is present before you start.

| file | where | note |
|---|---|---|
| `Data.Paladin.generated.lua` | `_generated/` | 9,180 picks, levels **10–69**, 3 specs, both factions |
| `Data.Paladin.Horde.1to9.generated.lua` | `_generated/` | 221 picks, **Horde only, levels 1–9** |
| `DataAdapter.lua` | addon root | new file, expands both into `GQ.Data.entries`, self-invoking |
| `GEARQUEST-BIS-PIPELINE.md` | `_generated/` | reference |
| `CURSOR-INTEGRATION-BRIEF.md` | `_generated/` | reference |
| `PALADIN.weights.json` | `_generated/` | reference — the scoring model |

**`.toc`: insert, do not replace.** No `.toc` is supplied on purpose — this repo
has moved on since the data was generated and a supplied one would clobber that.
Find the `Data.lua` line and add immediately after it:

```
_generated\Data.Paladin.generated.lua
_generated\Data.Paladin.Horde.1to9.generated.lua
DataAdapter.lua
```

The only constraint is order: both generated files after `Data.lua`, both before
`DataAdapter.lua`. Everything else keeps its current position.

## Do not change these things

- **`Data.lua` is hand-curated and authoritative.** It holds Alliance levels 1–9
  and all of level 70 (from AtlasLoot Phase 3 BiS lists). Do not edit, regenerate
  or "improve" it. The generated data is deliberately built to not overlap it:
  Alliance 1–9 and level 70 are absent from the generated files.
- **Level 70 is intentionally absent.** A stat-weight model measured 0/44 against
  the curated level-70 lists, because endgame BiS turns on set bonuses, gem
  sockets and librams it cannot see. Do not extend the generated range to 70.
- **Level 60 picks come from Wowhead's Classic BiS guides**, not from the scoring
  model. Rows carrying `origin="guide"` are in the guide's deliberate order — do
  not re-sort them by `score`, that undoes the point of them.
- **`score` is a ranking number only.** Comparable within one slot/spec/level and
  meaningless across them. Never display it as a stat.
- **The two generated files have different row shapes.** Main is
  `{itemId, slot, minLevel, maxLevel, rank, spec, faction, score}`; Horde 1–9 is
  `{itemId, slot, minLevel, maxLevel, rank, score}` — no spec, no faction column.
  Reading `r[6]` as the spec in both would read the Horde file's *score* as its
  spec. `DataAdapter.lua` passes the shape in explicitly for this reason.

## What I want, in order

**1. Merge the files and insert the three `.toc` lines.** Report anything that
conflicts with work already in this repo.

**2. Review `DataAdapter.lua` for WoW Lua 5.1 correctness.** It was tested in a
Lua 5.5 runtime, never in-game. Flag anything that will not work under 5.1 or in
the addon environment. Confirm the `.toc` backslash subdirectory syntax is right
for this client; if not, say so and I'll move the files to the root.

**3. Verify these hold:**
- `#GQ.Data.entries` == **curated count + 9,401**. With the current 1,176 curated
  entries that is **10,577**. A different number means a double-load or a missing file.
- Level 70, any spec: every pick is a curated entry (`generated` is nil).
- Level 5 Alliance: curated only. Level 5 Horde: generated only.
- Level 60 Protection main hand rank 1 is **Thunderfury, Blessed Blade of the
  Windseeker**, with `origin = "guide"`.
- Level 13 Retribution chest rank 1 is **Soldier's Armor**, `suffix = "of Strength"`,
  `suffixChance = 9.5`.
- No entry has `minLevel > maxLevel`; no generated entry exceeds level 69.

**4. Then the UI work this data unlocks**, highest value first:

- **Random-enchantment hunts.** ~46% of picks carry `suffix` and `suffixChance`.
  The UI would currently show "War Torn Tunic" when the player is actually hunting
  "War Torn Tunic **of Strength**", a 9.5% roll. Without the suffix and the odds on
  screen a player will think a plain drop completed the hunt — so this affects
  obtain-detection too, not just display: a tracked random-enchant item should only
  complete when the right suffix is rolled.
- **`proc` text on `itemFacts`** — answers "why is this item good?" for items whose
  stats look unremarkable. Thunderfury prints 5 Agility and 8 Stamina; its entire
  value is the proc.
- **`GQ.Data.paladinNotable`** — items whose value is a proc the score cannot
  price. Not part of the top three; show them beside it ("worth considering — the
  proc is the point") using the `proc` text.
- **`origin="guide"`** — optionally mark level-60 picks as guide-sourced. They are
  the most trustworthy rows in the file.

Start with steps 1 and 2 and report before writing any UI code.

---

**Note on a stray copy.** There is a `Desktop\GearQuest` folder on this machine
that is a copy, not this repo. It contains the same generated files, but its `.toc`
was overwritten with a version that does not know about the portrait work in this
repo. **Do not sync that folder over this one in either direction, and do not read
its `.toc` as a reference.** The authoritative copies of the six files are the ones
listed in the "Files to merge" table above, which have been added to this repo.
