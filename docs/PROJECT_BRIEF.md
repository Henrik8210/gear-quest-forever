# GearQuest Forever — project brief for agents

## Problem

When leveling (e.g. lvl 37 Hunter with a bad weapon), there is no good way to ask: *"What should I upgrade next, and how do I get it?"*

Existing tools are wrong for this:

| Tool | Gap |
|------|-----|
| BiS trackers (Wick's, AtlasLoot) | Endgame raid lists, not leveling upgrades |
| Pawn / Sharpie's Gear Judge | "Is this item better?" only after you already have it |
| Questie | Quest locations, not gear-aware |
| Zygor Gear Finder (paid) | Closest, but not slot-click UX and not free |

## Core UX

1. Open Character panel (`C`) and click a gear slot (e.g. Main Hand weapon).
2. Show ~3 upgrade options with normal item tooltips, each tagged: **World drop**, **Boss drop**, **Quest reward**.
3. Clicking an option opens the GearQuest log with a short how-to (e.g. "Form a group and kill Baelog in Uldaman.").
4. Each hunt can be taken/activated like a quest and tracked in the log.
5. Two entry points: click slot on paperdoll (primary) or browse/activate from the GearQuest log window.

## Data model

Pre-made **gear quests** per item, not generated at runtime. Each entry roughly:

- Item ID, slot, level range, class/spec filters (optional)
- Source type: `world_drop` | `boss_drop` | `quest_reward` | `vendor` | `auction_house`
- Brief instructions (1–3 sentences)
- Optional: quest ID, NPC ID, dungeon/zone, coordinates for map pins later

Compare equipped item vs candidates by item level + simple stat relevance for class/spec at that level — not full BiS sims.

**Data curation rules:** [DATA_RULES.md](./DATA_RULES.md) — equippability, level bands, spec, import checklist.

## MVP scope

- One slot type first (Main Hand weapons) for one class (Hunter) across levels 30–45
- Character panel slot click → popup with 3 options
- GearQuest log frame: list active/completed hunts
- Static data file (`GearQuest/Data.lua`)
- WoW Forever beta: `## Interface: 16001` (CurseForge game version **1.60.1**). Confirm `lastAddonVersion` from the beta `WTF/Config.wtf` after first login. Do not use TBC `20505`.

## Level cap

WoW Forever is **1–60**. The addon uses `GQ.MAX_PLAYER_LEVEL = 60`. TBC level-70 data and tooling are out of scope; see [FOREVER-DATA-MIGRATION.md](./FOREVER-DATA-MIGRATION.md).

## Out of scope for v1

- Full BiS for all classes/phases
- TBC / level 70 endgame lists
- Live AH pricing
- AI / Wowhead API (addons cannot use internet)
- Account-wide alt tracking

## Tech notes

- Standard WoW addon (Lua; LibStub/Ace3 only if useful)
- Hook `PaperDollFrame` / `CharacterFrame` slot buttons
- Reuse Blizzard item tooltips (`GameTooltip:SetHyperlink`)
- Repo source folder `GearQuest/`; install/CurseForge package **`GearQuestForever`** (`GearQuestForever.toc`); Lua global `GearQuest` / `GQ`

## CurseForge

See [RELEASE.md](../RELEASE.md) in repo root. Tag discipline: never tag unless explicitly publishing.

This is a **new CurseForge project**. Never copy `X-Curse-Project-ID` `1669225` or the TBC repo's `CF_API_KEY` secret.
