# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.3.0-beta

Hunts that have a place to go now say where, and you can open that spot on the map. Track and Untrack are one button under the reward. **Coldflame Saber** drops in Shadowfang Keep, and its hover uses the Equip line.

The window title reads **GearQuest Forever v0.3.0-beta**.

### Where to get it

Under **Source** in the hunt description, a coordinate line appears when we know a spot:

```
Coordinates: Elwynn Forest 48.2, 42.8 (beginning of the quest or chain)
Coordinates: Silverpine Forest 44.8, 67.8 (entrance to dungeon or raid)
Coordinates: Ashenvale 61.4, 83.8 more coordinates for this (vendor that sells this)
```

The zone name is part of the line, because a dungeon door is on a different map than the dungeon. You see your faction, or the faction the simulator is using, plus neutral spots. **more coordinates for this** means another valid spot exists. The line shows the first one.

The note depends on how you get the item:

- A quest reward points at the start of the quest or its chain.
- A boss drop or raid trash points at the dungeon or raid entrance, not the boss's room. Classic doors use the classic entrance. **Hall of Thanes** is Ironforge 43.6, 51.7. **Ruins of Lordaeron** is Tirisfal Glades 71.6, 11.4.
- A vendor is the NPC who sells it.
- A named world drop is one farming spot for that creature.
- A crafted piece points at a capital-city trainer for your faction.

**5,555** hunts have a line. **2,541** do not. Most of those are world drops whose text is only "World drop around level X–Y", with no creature to stand on. **Staff of Jordan**, **Fiery War Axe**, and **Hammer of the Northern Wind** are in that group. Some vendors are unnamed, or they stand inside a battleground.

### Show on map, and the pin

**Show on map** sits beside Track, under the reward. It opens the zone and places a waypoint on that coordinate.

If the hunt has no coordinate, **Show on map** stays grey. Hovering it says: "We are missing exact coordinates for this item."

**Track** puts one pin on the world map, the same spot as the coordinate line. The icon matches the source: quest, boss, profession, vendor, or world drop. The pin also shows on the minimap when you are close. Click the pin to toggle a blue circle. **Untrack** removes the pin. Hovering the pin shows the hunt name and the coordinate.

### Track, and Exit

Track and Untrack are one button. It reads **Track** until you track the hunt, then **Untrack**. On **Completed** it reads **Remove**.

The list and the description stop above the footer on the log, the simulator, and settings. **Exit** is in that footer on all three.

### Coldflame Saber

Mage main hand from level **21**. It drops from **Baron Silverlaine** in **Shadowfang Keep**. It is not a world drop. The hover uses the Equip line, "Increases damage and healing done by magical spells and effects by up to 32," instead of separate spell power and healing lines. The description still says how to combine the Blade of Silverlaine and Imbue Blade.

### Credits

**Settings** has **Credits to collaborators** under **General**, listing **Eao** and **MainWon**.

### v0.2.20-beta

Class art behind the log and the simulator class rows. Priest, mage, and warlock wands count damage from level 10. Greater Magic Wand is 17.5 dps. Lookie's Spyglass drops from Cookie. A green "of the …" hunt completes only when the full name matches.

### v0.2.19-beta

Weapon hovers show spell power again, and a hunt uses the tooltip's required level instead of item level. **Fang of Magmatus** requires **13**. Alliance Holy and Discipline: **Staff of Westfall** is main hand rank **1** from level **14**. Fishing follows the Profession filter. A name that was only "Item" plus a number uses the real item name.


### v0.2.18-beta

GearQuest loads one class at a time, so it uses far less memory. Hovers that used to say **Not found in the client** now show the Wowhead Forever tooltip. A toast only fires for a top upgrade, the notable, or a hunt you are tracking at your current level. **Wyvern Heart Band** is finger rank 1 from level 29 through 37 for Arms, Fury, Retribution, Combat, Subtlety, Survival, and Feral, and through 47 for Assassination.

### v0.2.17-beta

Hover the spec name or icon to see how that spec is scored. Below 60, Enhancement shaman intellect counts at **1.2**. **Wolfsbane** is Horde Retribution main hand rank 1 from level 20 through 26.

### v0.2.16-beta

The window title reads **GearQuest Forever** plus the version. Gear you already have stays on **Completed** when a source filter is on. After `/gq wipe data`, jumping the simulator to a higher level marks the pieces you are wearing as completed again.

### v0.2.15-beta

Profession windows stay responsive. A piece you already carry or wear leaves **Active** and sits on **Completed**. Horde lists no longer show Alliance-only librams or Stormwind quests. **Snake Eye Kaleidoscope** is a neck hunt from level 17 while it stays in the top three.

### v0.2.14-beta

Settings can hide the minimap icon. Set pieces are marked **(Set piece)**. **Embrace of the Viper** is the Wailing Caverns hunt for hunter, rogue, Enhancement, and Feral in the high teens and twenties. **Defias Leather** is legs at 14–15 and boots at 15–16 for rogues. **Chain of the Scarlet Crusade** ranks on its own stats for Retribution, Arms, Fury, and Protection around the low 30s.

### v0.2.13-beta

An upgrade toasts once, the first time it lands in your bags or on your character.

### v0.2.12-beta

Worn gear shows beside a hunt tooltip. Bag clicks and the profession book work again. Completed opens without freezing. Dungeon hunts name the boss, including Witherfang, The Baron, Magmatus, and Plunder. A spec you pick stays on this character. Duty Bound Leggings and Remembrance Armor are Alliance only. Heat Resistant Mitts and Safety Boots are Horde only.

### v0.2.11-beta

The source filter hides World drop, Boss drop, Raid trash, Quest reward, Seasonal quest, Vendor, Profession, Container, and Special. Quest rewards and vendor gear use the source you can actually use. **Healing Done** counts for healers. Damage specs score **+Damage Done** as spell power. Completed is per character.

### v0.2.10-beta

Your talent tree picks the spec again after `/reload`. The log spec menu is for this session. Wowhead PvP stats were refreshed, and **Death Prophet Spine** is an Enhancement shaman hunt at 26.

### v0.2.9-beta

Crafted hunts name who sells the recipe. Horde buys from Durotar Supply and Logistics in The Barrens. Alliance buys from Azeroth Commerce Authority in Redridge Mountains.

### v0.2.8-beta

Mage **Battle Mage** is in the spec menu. **Coldflame Saber** is the mage main hand from level 21, using the Forever client tooltip. The imbue line reads **Use: Combine the Blade of Silverlaine and Imbue Blade.**

### v0.2.7-beta

Talking to a profession trainer no longer freezes the client. GearQuest does not scan trainers for new items.

### v0.2.6-beta

Hunt tooltips follow Wowhead Forever, including set layout and quality color. **Enhancement Tank** is a one-hand and shield hunt: stamina and armor first, then threat.

### v0.2.5-beta

Leveling hunts rank damage first, then stamina and armor, then mana. A random-enchant green is ranked on its best suffix, not the average roll. Warrior Protection does not score spell power. **Silvered Gauntlets** are the Protection hands notable.

### v0.2.4-beta

Random-enchant greens show the suffix on the item tooltip, not only in the hunt text.

### v0.2.3-beta

Repo-only follow-up. The in-game build matches v0.2.2-beta.

### v0.2.2-beta

Lists aim for three different names per slot. Totem, idol, and libram hunts score the effect on the tooltip. The simulator has a faction dropdown.

### v0.2.1-beta

**Mirror of Rath'mael** was the new Wowhead piece. The “ring slot eligible” toast no longer fires for Horde characters who have no ring hunts at level 9.

### v0.2.0-forever-beta

Warsong Gulch rune trinkets are hunts for both factions from level 20. Classic items Wowhead Forever does not have are dropped from the lists.

### v0.1.0-beta.6-forever

The log uses the profession-style window. Hunt names come from stored facts, so login no longer requests every item. Early hunts are scored per spec.

### v0.1.0-beta.5-forever

Same Horde notes as beta.4. The CurseForge upload no longer breaks on changelog punctuation.

### v0.1.0-beta.4-forever

Horde phase-4 quest and crafted pieces compete on the generated lists.

### v0.1.0-beta.3-forever

CurseForge target is WoW Forever 1.60.1.

### v0.1.0-beta.2-forever

First zip that actually contained the addon.

### v0.1.0-beta.1-forever

First CurseForge beta, project **1698950**. Two-column log, Active and Completed, simulator capped at 60. The folder name is **GearQuestForever**, separate from TBC GearQuest. Lists are Classic-era, level 60, not TBC level 70.
