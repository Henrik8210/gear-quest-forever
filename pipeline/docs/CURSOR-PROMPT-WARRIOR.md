# Paste this into Cursor (in the GearQuest repo)

Adding generated best-in-slot data for **Warrior**, the same way Paladin was added —
plus a **fix-only revision of the Paladin files**, explained below. The data and the
loader are written and tested; merge them, review the loader, then extend the UI work
already started for Paladin to cover Warrior too.

## Files to merge

Extracted from `GearQuest-Warrior-BiS.zip`. Confirm each is present before you start.

| file | where | note |
|---|---|---|
| `Data.Warrior.generated.lua` | `GearQuest/_generated/` | **new** — 9,582 picks, levels **10–69**, arms/fury/protection, both factions |
| `Data.Warrior.Horde.1to9.generated.lua` | `GearQuest/_generated/` | **new** — 248 picks, **Horde only, levels 1–9** |
| `Data.Paladin.generated.lua` | `GearQuest/_generated/` | **replaces** the merged one — 9,180 picks (was 9,180 — same count, different content). Bug fix, see below |
| `Data.Paladin.Horde.1to9.generated.lua` | `GearQuest/_generated/` | **replaces** the merged one — 221 picks. Same fix |
| `DataAdapter.lua` | `GearQuest/` | **replaces** the existing one — now handles both classes |
| `WARRIOR.weights.json` | `GearQuest/_generated/` | reference — the scoring model |
| `WARRIOR.guides.json` | `GearQuest/_generated/` | reference — the two Wowhead guide lists with their Rank tiers, as used |
| `GEARQUEST-BIS-PIPELINE.md` | `GearQuest/_generated/` | **replaces** the existing one — gained sections 6 and 7 |

**`.toc`: insert two lines**, immediately after the two Paladin generated lines and
**before** `DataAdapter.lua`:

```
_generated\Data.Warrior.generated.lua
_generated\Data.Warrior.Horde.1to9.generated.lua
```

Order is the only constraint: every generated file after `Data.lua`, all of them
before `DataAdapter.lua`.

## Why the Paladin files are being replaced

A proc-valuation bug charged every **on-use** effect as though it fired twice a
minute. It fires once per cooldown. An engineering trinket with a 30-minute
cooldown was priced as a permanent damage source, and a quest-scripted effect
("Use **on** Dar'Khan Drathir…", which only works on one quest NPC) was priced as a
general nuke worth 116 points — enough to put *Sunwell Orb*, a green +3 Intellect
off-hand, at rank 1 for every level from 1 to 19.

Two more followed from the same review — **a stun is worth zero** (bosses are
stun-immune; *Tidal Charm*'s tooltip even says it is resisted above level 60, and
priced as avoidance it was the entire score of a trinket with no stats), and a
level-60 displacement must now beat the **best-scoring** item on the guide list
rather than whichever one the guide ranked first.

The revision is measured, not asserted:

- 14,832 per-level pick slots; **571 changed (3.85%)** across the three fixes
- **6 changes at level 60**, all from the stricter displacement bar, and all
  removing a displacement rather than adding one
- Level-60 guide agreement: **40/41**, and model-#1-endorsed improved 38→39
- Removed: *Tidal Charm* (64 picks), *Electromagnetic Gigaflux Reactivator* (62),
  *Goblin Bomb Dispenser* (52), *Sunwell Blade* (22), *Sunwell Orb* (19), *Goblin
  Dragon Gun* (16), *Thunderbrew's Boot Flask* (13), *Witching Band* — every one
  an on-use, quest-scripted or PvP-only effect
- Added in their place: ordinary stat items that were being outbid — *Philosopher's
  Stone*, *Figurine – Truesilver Boar*, *Hand of Justice*, *Drake Fang Talisman*,
  *Talisman of Arathor* / *Defiler's Talisman*

**The table names are unchanged**, so this is a drop-in file swap: Paladin still
emits `GQ.Data.itemFacts` / `paladinPicks` / `paladinNotable`. No adapter change is
needed for the Paladin side beyond the one described next.

## About the DataAdapter replacement

The new one is table-driven — a `SOURCES` list of `{class, picks, facts, hasSpec,
specs, faction}` entries — so the next class is one more entry, not another code
path. Two things it fixes that matter:

- **The entry id now includes the class.** The old id was
  `gen:<itemId>:<slot>:<minLevel>:<spec>:<faction>`. A Paladin and a Warrior
  Horde 1–9 row for the same item, slot and level collide under that scheme,
  because both carry `spec = nil`. Ids are now prefixed `gen:warrior:` / `gen:paladin:`.
- **A class whose files are not loaded is skipped silently**, so the adapter is
  safe if a `.toc` line is missing or a file is removed.

Paladin's generated tables stay unprefixed (`GQ.Data.itemFacts`,
`GQ.Data.paladinPicks`); Warrior's are prefixed (`warriorItemFacts`, `warriorPicks`,
`warriorNotable`). Nothing collides.

## Do not change these things

- **`Data.lua` is hand-curated and authoritative.** For Warrior it holds the 131
  level-70 entries (arms/fury/protection) and the Alliance early-level entries
  shared with Paladin via `ALLIANCE_MAIL` / `MAIL_MELEE` — 252 rows below level 10.
  Do not edit or regenerate it.
- **There is deliberately no generated Alliance 1–9 file.** `MAIL_MELEE` already
  covers a Warrior for levels 1–14 by hand. A generated Alliance file would compete
  with it for the same bands.
- **Level 70 is intentionally absent** from the generated data, for Warrior as for
  Paladin. Do not extend the generated range to 70.
- **Level 60 picks come from Wowhead's Classic BiS guides.** Rows with
  `origin="guide"` are in the guide's deliberate order — do not re-sort by `score`.
- **`score` is a ranking number only** — comparable within one slot/spec/level,
  meaningless across them. Never display it as a stat.
- **Row shapes differ between the two file kinds** — main is
  `{itemId, slot, minLevel, maxLevel, rank, spec, faction, score}`, Horde 1–9 is
  `{itemId, slot, minLevel, maxLevel, rank, score}`. The adapter declares the shape
  rather than sniffing it.

## What I want, in order

**1. Merge the files, replace the four listed as replacements, insert the two `.toc`
lines.** Report anything that conflicts with work in progress.

**2. Review the new `DataAdapter.lua` for WoW Lua 5.1 correctness.** It was tested
in a Lua 5.5 runtime, never in-game.

**3. Verify these hold:**
- `#GQ.Data.entries` == **curated count + 19,231**. With 1,179 curated entries that
  is **20,410**. A different number means a double-load or a missing file.
- **Zero duplicate `id` values** across all entries. This is the check that catches
  the class-collision bug, so please actually run it.
- Warrior level 70, any spec: every pick is a curated entry (`generated` is nil).
- Warrior Arms at 60: `MainHand` picks are **two-handers**. Fury: `MainHand` and
  `SecondaryHand` are both **one-handers, no shields**. Protection: `SecondaryHand`
  is **shields**.
- **Below level 20, no Warrior spec has a weapon in the off hand** — Dual Wield is a
  level-20 skill, so those bands are shields.
- **PvP rank rewards appear on one faction only.** *Field Marshal's* / *Marshal's* /
  *Grand Marshal's* / *Knight-* / *Lieutenant Commander's* / *Stormpike* are Alliance;
  *Warlord's* / *General's* / *High Warlord's* / *Champion's* / *Legionnaire's* /
  *Blood Guard's* / *Frostwolf* are Horde. If you see both halves of a pair in one
  faction's list, something regressed.
- Warrior has a working **`Ranged`** slot with bows/guns/crossbows/thrown — unlike
  Paladin, whose Ranged slot is a relic.
- No entry has `minLevel > maxLevel`; no generated entry exceeds level 69.

**4. Extend the Paladin UI work to Warrior.** It is the same fields, so mostly this
should be a matter of not having hardcoded `paladin` anywhere:
- random-enchantment hunts (`suffix` / `suffixChance`) — still the highest-value item
- `proc` text on the facts table
- `warriorNotable` — the "value is a proc the score cannot price" shelf
- `origin="guide"` marking on level-60 picks

Start with steps 1–3 and report before touching the UI.

---

**Level-60 lists now carry the guide's own Rank column.** Wowhead ranks each row
*Insane / Best / Close Second / Best Mitigation / Great / Good / Hit Alternative /
Situational*, and inside a rank it is not claiming an order. Guide entries are stored
as `[tier, name]` and sorted by **(tier, −score)** — the guide sets the tier, the
model breaks ties the guide never made. That is what moved **Thunderfury** to rank 1
in Protection's main hand: it and *The Hungering Cold* are both "Best", and taking
them in printed order had Thunderfury second.

**Consequence for the UI: an `origin="guide"` band is NOT sorted by score, and must
not be re-sorted.** *Dreadnaught Helmet* scores 130.7 behind *Conqueror's Crown*'s
104.9 because the guide calls the Crown the plain Best and the Helmet the Best
Mitigation. `rank` is authoritative; `score` is context.

**Faction matters more than you might expect.** 25% of all spec/slot/level cells
differ between Alliance and Horde — 688 of 2,719. Mostly PvP rank sets (which are
faction-exclusive, though the item data does not say so — the gate is the
quartermaster) and faction-zone quest rewards. Both factions are in the same file,
distinguished by the `faction` column; the adapter already maps it to `factions`.

Agreement: **44/44** guide-Best-in-top-3, 43/44 model-#1-endorsed, **one**
displacement — Protection Trinket, where *Gnomish Poultryizer* (+45 Stamina flat,
TBC engineering) beats the best-scoring guide trinket for tank weights (*Drake Fang
Talisman*, 24.5) by more than the 20% bar. That one is the model's opinion rather
than a professional's; everything else at 60 is a guide pick in guide order.

**One open question for Henrik, not a bug:** *Manual Crowd Pummeler* is rank 1 for
Arms from level 28 to 32, over half its score coming from "Use: Increases your haste
rating by 500 for 30 sec". It is the most famous levelling weapon in the game, which
argues it belongs there — but it has 3 charges and is consumed, which the tooltip
text does not carry. Left as-is rather than quietly damped.
