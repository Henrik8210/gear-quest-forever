# GearQuest Forever — CurseForge listing copy

Paste into [GearQuest Forever](https://www.curseforge.com/wow/addons/gearquest-forever) (project **1698950**). This is **not** TBC Anniversary GearQuest.

Drop each screenshot in the CurseForge editor where the italic line says so. The line under it is the caption. Keep the caption. Do not add a paragraph.

---

## 1. Project summary

> Best gear for your class, spec, and level on WoW Forever. The log lists the hunt, the map shows where, and a toast fires when it is yours.

---

## 2. Tagline

> Know what to wear. Know where it drops. Know the moment it's yours.

---

## 3. Full description

### GearQuest Forever

GearQuest Forever tells you the best thing you could be wearing right now, and where it comes from. It is for WoW Forever, levels 1–60, every class and spec, Alliance and Horde.

Left-click the minimap button for the log. Right-click a paper-doll slot for that slot. Right-click the minimap button for the simulator.

---

### Your hunts

*Screenshot 1 — the log, one slot open.*

Each row is a piece for that slot. The grey number is its rank. It matches the (i) list, including #4 and later once you already have an earlier piece.

**- Recommended** marks up to three rank #1 upgrades, the ones that beat what you are wearing by the most. **- Rank #1 BiS acquired** means you already have the best piece in that slot.

---

### Where it comes from

*Screenshot 2 — the parchment for one hunt.*

Open a hunt for the source, the quest level, the craft, and the materials. **Track** pins it. **Show on map** opens the spot. **Remove** takes that hunt off the list until you restore it.

A vendor hunt names the person at the pin you are closest to. **Dirty Leather Bracers** in Mulgore is **Varia Hardhide**, not the Undercity cloth merchant. Walk to another town that sells it and the name follows. The tracker uses the same name.

A quest reward says the level it can be picked up. A craft says the skill in green when you can make it, and red when you cannot. A burnt mark means the item is new in Forever.

---

### On the map

*Screenshot 3 — the world map pin, and the guide arrow.*

The pin is a real place: the quest that starts the chain, a dungeon entrance, a vendor, a named creature, or a camp. GearQuest does not invent one.

Track a hunt and an arrow can point the way. On another continent it points at the boat or zeppelin first.

---

### Play your way

*Screenshot 4 — the six play-style cards.*

**No Dungeons** hides dungeon and raid hunts, including a quest that steps inside one. A world drop stays.

**Dungeon Enjoyer** keeps only those dungeon and raid hunts.

**Get it now** waits until you have the reputation, or can make a bind-on-pickup craft.

**Don't look back** hides a quest once it would be gray.

**Manageable Quests** hides a quest reward until you are 4 levels under its item level. That wait stops at 60.

**Buy it** keeps vendor pieces and gear that is not bind on pickup.

The two dungeon cards turn each other off. The other four can be on with either. The button reads **Play style*** while one is on.

---

### Filter

*Screenshot 5 — the filter menu, with a dungeon flyout open.*

Hide a source, a profession, or one dungeon. Boss drop and Dungeon & Raid trash are separate lists. The rank number does not change because a filter is on.

---

### Is this an upgrade?

*Screenshot 6 — an item tooltip with the GearQuest score.*

Hover gear in your bags, on the character panel, in chat, or on a hunt. The line is a score for this level: best in the slot is 100, worst is 0. The arrow compares it to what you have equipped.

*Screenshot 7 — the score bar in the log header.*

The bar is your equipped gear, averaged. **General → GearQuest score on tooltips** and **GearQuest score bar** turn the two off separately.

While the simulator is on, the tooltip tells you to turn it off before it will score your item.

---

### Why that piece won

*Screenshot 8 — the spec weight tooltip.*

Hover the spec name. Those are the weights for this spec. While you level, stamina and armor count for more than a naked +1 of your main stat, and mana counts for less than stamina. Level 60 keeps those same multipliers. The tooltip index is still 0 to 100 for the slot, and the header bar is the average of what you have equipped. An empty slot counts as 0. Filtering weapons does not move the bar.

A random-enchant green is ranked on its best possible roll. The tooltip says how rare that roll is. A slim chance does not hide the hunt.

You cannot edit the weights in the addon. Suggest a change here: [GearQuest Forever - Class Stat Weights](https://docs.google.com/spreadsheets/d/1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok/edit). The live numbers stay locked. A suggestion does not change the addon by itself.

---

### Look ahead

*Screenshot 9 — the simulator.*

Right-click the minimap button, or open the Simulator tab. Pick another class, spec, faction, or level. **Turn off simulation** brings the list back to your character.

---

### When you ding

The new list builds in the background, one slot at a time, with a spare frame between slots. The paper-doll arrows rebuild the same way, and the ones already on your character stay until the new set is ready. Changing zone, logging in, or opening a vendor does that arrow pass without clearing them first. Opening the log or a filter keeps the rows you are looking at until the ranks are ready, then swaps the list once.

---

### When it is yours

*Screenshot 10 — the obtain toast.*

Loot the hunt and GearQuest toasts you. The toast names that hunt. A different suffix on the same green is not that hunt.

---

## FAQ

**The game freezes when I level up.**
A ding builds the new list one slot at a time, with a spare frame between slots, then checks what you just outgrew, then redraws. The paper-doll arrows follow one slot per frame. If it still freezes, comment the version in the window title.

**My FPS drops when I hover items in my bags.**
Update to **v0.5.3-beta** or newer and `/reload`. The window title shows the version. That version stopped the bag hover from loading every other piece in the slot. If it still happens, comment the item name and the version in the title.

**Why does Main Hand show a two-hander?**
The headers are the weapons that spec uses. Enhancement is **Two-hand** only. A hunter gets **Two-hand**, then **Main hand** for weapons that can only go in the main hand, then **Off Hand** for weapons that can go in either hand. A rogue's **Main Hand** is weapons the tooltip calls Main Hand. There is no "swords only" box yet.

*Screenshot 11 — a hunter's weapon headers, if you have the room.*

**Why is this the best piece?**
Hover the spec. Screenshot 8. The hunt follows those weights. While leveling, a piece with stamina beats a naked +1 of your main stat. Level 60 keeps that same stamina, armor, and mana weighting. The tooltip score is still 0 to 100 inside the slot.

**Can I change the stat weights?**
Not in the addon. Suggest the spec, the stat, and the weight you want on the [stat weight sheet](https://docs.google.com/spreadsheets/d/1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok/edit).

**Holy paladin keeps suggesting cloth.**
Holy levels in mail and plate. Cloth is scored lower on purpose, so a tailoring robe does not beat blacksmithing healing mail of the same band. Hover the spec to see it. If one piece is still wrong, name it, your level, and your faction.

**Enhancement is using agility over strength.**
That is the current weight. Agility is priced a little above strength. Suggest the change on the sheet if you want strength first.

**Why does my warlock want healing gear?**
A warlock does not hunt healing. A line that says both healing and damage is scored as damage. Intellect and spirit still show up because they keep you casting. If a pure healing piece is rank 1, name it.

**I am Horde and I see an Alliance reward.**
You only see rewards your faction can get. Defender of Dalaran is Alliance. A Tauren sees the Horde Heart of Disruption rewards, including Striking Staff. If the other faction's piece is still on your list, name it and your race.

**The toast named a suffix I did not loot.**
The hunt is the best suffix that green can roll. Shimmering Gloves of Arcane Wrath is not Shimmering Gloves of Healing. The tooltip says how rare the jackpot roll is.

**How do I hide dungeons, or only chase what I can get today?**
Play style. Screenshot 4. There is no "this zone only" filter. **Show on map** is per hunt.

**How do I look at another level or another class?**
Simulator. Screenshot 9. The item tooltip will not score your gear until you turn simulation off.

**How do I hide the minimap button?**
Open the log, the gear icon, **General**, **Hide minimap icon**. Drag the button around the minimap before you hide it.

*Screenshot 12 — the General settings page.*

**I already have the best piece.**
The slot says **- Rank #1 BiS acquired**. Later ranks stay so you can see what is next. **Recommended** only marks a rank #1 you do not have yet.

**It uses a lot of memory.**
The list is every spec from 1 to 60. A ding, a zone change, and opening a cold log are spread across frames as of v0.5.5-beta. Bag hovers stopped loading every other piece in v0.5.3-beta. If a hitch is still sharp, comment the version in the window title and what you had just clicked.

**GearQuest is not in my addon list.**
The folder must be `Interface/AddOns/GearQuestForever`. This is not the TBC Anniversary GearQuest. The two can be installed together. `/reload`, or restart the client.

**A gamepad popup locks the game when I close the map.**
That was fixed. If it still happens, comment the version in the window title and what you clicked.

**I do not want one specific hunt.**
Open it and press **Remove**. Restore brings it back.

---

### Also

The window title is the version to quote in a comment. Include class, spec, level, faction, and the item.

Questions and weight ideas also go to the [Discord](https://discord.gg/jQ2GdDEeN).

---

## 4. Screenshots to take

Take them on a character around level 20–30 so the log is full but not a raid list. Crop to the addon. Leave the window title in shot when the shot is about a version or a bug.

| # | What to shoot | Why it is there |
|---|---|---|
| 1 | The log with one slot expanded. Show the item icon, the grey #N, one **- Recommended**, and one **- Rank #1 BiS acquired** if you have one. | The first thing people need to read. |
| 2 | One parchment. A quest reward is best, so the pickup level and Source are both visible. Include Track, Show on map, and Remove. | Stops "where do I get this?" |
| 3 | The world map with one pin, and a second crop of the guide arrow on the tracker. Two images under one caption is fine. | Stops "put it on the map." |
| 4 | Play style open, all six cards, names under the pictures. | The filter people cannot find. |
| 5 | The filter menu with the boss-drop or trash dungeon flyout open. | Shows that dungeons are a list, not one checkbox. |
| 6 | A bag or character-panel tooltip with the GearQuest score and a green or red arrow. | "Is this an upgrade?" |
| 7 | The log header score bar, not simulating. | Separate from the tooltip score. |
| 8 | The spec weight tooltip. Holy paladin is the one people argue about. Enhancement is the other. | "Why did this win?" |
| 9 | The simulator on another class or level, with **Turn off simulation** visible. | "How do I look ahead?" |
| 10 | The obtain toast. | "You got it." |
| 11 | Optional. A hunter log scrolled to Two-hand, Main hand, and Off Hand. | The weapon-slot question. |
| 12 | Optional. General settings, with **Hide minimap icon** and the two score checkboxes. | "Where is the off switch?" |

The gallery on the CurseForge page can be the same set, in this order. The description should use 1–10. 11 and 12 are for the FAQ if the page is not already long.

---

## Notes for the author (not the listing)

- CurseForge project **1698950**. Never use TBC `1669225`.
- File names are `vX.Y.Z-beta` on the beta channel.
- Do not put the notable shelf back in this text. It is gone.
- Do not promise an in-game weight editor or a "swords only" filter. Neither exists. The sheet is the suggestion box.
- Enhancement agility above strength, and Holy cloth below mail and plate, are the current weights. Do not "correct" them in the FAQ.
- Keep this file in sync when a player-facing behavior changes.
