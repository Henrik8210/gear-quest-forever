# GearQuest — auction-house wording, and item flavour text (R40)

Two changes Henrik asked for. All 18 generated files are attached. The data side is done;
`DataAdapter.lua` and the tooltip/description UI need one new field passed through.

---

## 1. Stop calling the auction house the cheapest option

Every world-drop row used to read:

> World drop — drops from 596 creature types around level 38-63. **Often cheapest on the
> auction house.**

It now reads:

> World drop — drops from 596 creature types around level 38-63. **Also found on the
> auction house.**

3,825 rows carried the old wording; **zero remain**. The claim was about a live market the
addon cannot see — on a quiet realm a world drop may not be listed at all, or may be
priced well above what it is worth. Availability is a fact; cheapest was a guess dressed
as advice.

Verified: regenerating `sources.json` changed **4,275 entries and every one of them
differed only in the instructions string** — no gating, no source type, no zone or NPC
moved. So this is a pure wording change and no scoring was affected.

---

## 2. New `lore` field — flavour text under the item's name

Henrik: *"for named gear that has a background story to it, could you add some nice text
before the description/below the title of the item ... just to have a nice 'Ah, cool - i
didn't know this about this item' feeling."*

Each facts row may now carry a `lore` string:

```lua
[19019]={name="Thunderfury, Blessed Blade of the Windseeker",sourceType="quest_reward",
  instructions="Reward from the quest “Rise, Thunderfury!”.",
  lore="Forged for a Windseeker of the elemental lords and lost for an age. Waking it again takes the bindings of the left and right hand, the blessing of Thunderaan's own essence, and a smith willing to defy Ragnaros.",
  ...}
```

**3,603 rows across the 18 files carry one.** It is deliberately absent on the rest.

### Where the text comes from — three sources, none of them invented

| source | items | what it is |
|---|---|---|
| **quest text** | 2,631 | The actual in-game quest text from `quest_template.Details`, trimmed to its first sentence or two. Canonical; covers 100% of shipped quest rewards. |
| **boss note** | 632 | A note about the boss who drops it. 65 bosses cover every shipped epic drop, so this is written once per boss and inherited by each of their items. |
| **hand-written** | 9 | The seven legendaries plus Benediction and Quel'Serrar, where the story *is* the item. |

Anything else gets nothing. A world drop off 358 creature types has no story, and
inventing one would be worse than a blank. Two Blackwing Lair trash dragonkin are
deliberately excluded for the same reason.

Examples of each:

* *Ashbringer* — "The blade the Silver Hand carried against the Scourge, and the one Tirion
  Fordring's order was built around. Corrupted when Renault Mograine used it on his own
  father, Alexandros, in the Scarlet Monastery."
* *Soulseeker* (Kel'Thuzad) — "Once an archmage of the Kirin Tor, he left Dalaran to found
  the Cult of the Damned and served Ner'zhul willingly. Killed at Andorhal and raised as a
  lich, he rules Naxxramas from a phylactery at its heart."
* *Belt of the People's Militia* (quest) — "Stormwind has abandoned us. A foul wind of
  depravity rustles through the plains of Westfall. This was my homeland and I will not
  turn my back on the citizens who choose to remain here."

### Change 1 — `DataAdapter.lua`, pass it through

In `Expand()`, alongside the other fact fields:

```lua
                sourceType   = f.sourceType,
                instructions = f.instructions,
                lore         = f.lore,          -- NEW
                zone         = f.zone,
```

### Change 2 — render it above the description

In the detail panel, `lore` goes **between the item name and the DESCRIPTION heading**, as
its own block. Suggested treatment, matching the screenshot Henrik shared:

* italic, one shade dimmer than the description text, so it reads as flavour rather than
  instruction
* no heading of its own — it should feel like part of the item, not another labelled field
* wrap at the panel width; the longest entry is about 240 characters, most are well under
* when `lore` is nil, the layout must close up with no gap — most items have none

Rough shape:

```lua
if entry.lore and entry.lore ~= "" then
    loreText:SetText(entry.lore)
    loreText:Show()
else
    loreText:Hide()
end
```

---

## Verification

```
18/18 generated files compile
luatest: total entries 68209, malformed 0, duplicate ids 0
lore entries emitted: 3603
rows still saying "cheapest": 0
sources.json diff: 4275 entries, all instructions-only, 0 other field changes
```

Worth a look in-game on these four, one per source path: **Thunderfury** (hand-written),
**Soulseeker** or any Naxxramas epic (boss note), **Belt of the People's Militia** (quest
text), and any plain world drop such as **Vice Grips** — that last one should show no lore
block at all and no empty gap where it would have been.
