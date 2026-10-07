# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.4.0-beta

You can hide the hunts that do not fit how you are playing, narrow a source down to one profession or one dungeon, and still see the real slot rank on the parchment. A few long quest chains now open at the level where you can finish them.

The window title reads **GearQuest Forever v0.4.0-beta**.

### Play style

**Play style** sits at the bottom of the log. It opens two cards, and both can be on at once. A gold rim shows which ones are on. A play style can hide several sources together. The filter still only chooses a source.

**No Dungeons!** hides a hunt that sends you into a dungeon or raid. That is a dungeon or raid boss, dungeon and raid trash, and a quest whose text names a dungeon or whose pin is a dungeon entrance. World bosses stay. A craft you can buy stays. Whelgar's dig site in the Wetlands is not the Excavation Site dungeon, so that hunt stays.

**Get it now!** hides a hunt this character cannot get yet. A vendor piece waits until you reach the reputation stored on that item. A bind-on-pickup craft waits until you have that profession and the skill printed on the hunt. A bind-on-equip craft stays on the list, unless the item itself requires the profession to wear. When you reach the standing or the skill, the hunt comes back on its own. You do not have to turn the style off.

The character panel and the green arrows follow the same list. With a play style on, they show the hunts that are still allowed, not the full unfiltered top three.

### Source filter

The filter list is alphabetical: Boss drop, Container, Dungeon & Raid trash, Profession, Quest reward, Rare NPC, Seasonal quest, Special, Unsourced, Vendor, and World drop.

Checking **Profession**, **Boss drop**, or **Dungeon & Raid trash** opens the list beside that row immediately. The label gains a `>`. You do not have to move the cursor away and back.

**Profession** lists Alchemy, Blacksmithing, Enchanting, Engineering, Fishing, Leatherworking, and Tailoring. Clearing one craft hides only that craft.

**Boss drop** lists only the dungeons and raids that have a boss hunt for your class, spec, faction, and level, including ranks below the top three. Hall of Thanes, Ruins of Lordaeron, and Excavation Site are on that list. **Other** is a world boss, and it sits between Onyxia's Lair and Ragefire Chasm. Clearing Wailing Caverns hides Wailing Caverns bosses only.

**Dungeon & Raid trash** has the same kind of list, for trash hunts at your level. Those boxes are separate. Clearing Wailing Caverns under trash does not hide the Wailing Caverns bosses, and the reverse is true too.

The flyouts do not scroll. A box you clear stays cleared when you level or change spec. **Select all** and **Deselect all** cover the sources and all three lists. **Apply filter** still commits the boxes.

### Rank on the parchment

Above the item name, a black box reads **Rank #1**, **Rank #2**, and so on. The number is that hunt's place in the slot. A filter or a play style does not renumber it, so a piece that was rank 6 is still Rank #6 when it is the only row left.

Hovering the box says what that means. On the normal list, with no filter and no play style, rank 1 says **This is the best in slot [slot] for you.** Rank 2 says **2nd best**, rank 3 says **3rd best**, and a notable in the fourth row says **4th best**. A hunt that is only on the list because a filter is on, a play style is on, or both, uses that same line from its stored rank, and then says which of those is on.

Hunter and Enhancement two-hand weapons say **Two-hand**. A hunter weapon that can only go in the main hand says **Main hand**.

### Crafted hunts

A crafted hunt says the Forever recipe skill on the line just before Source. Example: **Requires Leatherworking (155) to craft. Your Leatherworking is 157.** If you do not have the profession, it says **You don't have Leatherworking.** A craft with no Forever recipe does not invent a skill of 1.

### Quest chains that end in a dungeon

These rewards were opening at the first step of a long chain. The dungeon step is much later, so the hunt now opens at that step.

**Windstorm Hammer** and **Dancing Flame** are the choice at the end of **Final Passage**, the tenth step after **Test of Faith** in Thousand Needles. The book is in Scarlet Monastery Library, a level 36 quest. Both now require **36**. They were showing from the mid 20s. **Dancing Flame** is ranged rank 1 at 36 for Horde mage (Frost, Fire, Arcane, and all three Battle Mage specs), Horde priest (Holy, Discipline, and Shadow), and Horde warlock (Affliction, Demonology, and Destruction). **Windstorm Hammer** is main hand rank 1 at 36–37 for Horde Combat.

**Ragefire Wand**, **Icefury Wand**, and **Nether Force Wand** are the choice from **Mage's Wand**. The chain starts with Tabetha in Dustwallow Marsh. **Rituals of Power** sends you into Scarlet Monastery Library at level 40. All three now require **40**. They were 30.

**Faded Hakkari Cloak** and **Tattered Hakkari Cape** are the choice from **Confront Yeh'kinya**. The chain starts with Prospector Ironboot in Tanaris. **The Final Tablets** are in Blackrock Spire at level 58. Both cloaks now require **58**. They were 40.

**Drakefire Amulet** is the reward from **Drakefire Amulet**. The chain starts with Haleh in Winterspring. The blood comes from General Drakkisath in Blackrock Spire at level 60. The amulet now requires **60**. It was 50.

**Crescent Staff** and **Wingblade** (Leaders of the Fang) stay **10**. **Staff of Westfall**, **Tunic of Westfall**, and **Chausses of Westfall** stay **14**.

### v0.3.6-beta

Every class was scored again from the current Wowhead Forever tooltip. A reward that is new in Forever has a burnt mark beside the icon. Malignant Root and White Obsidian Wand have it. Blackened Defias Leggings does not. Holy paladin prefers healing mail and plate over cloth. Beast Mastery and Marksmanship no longer hunt Armor of the Fang. Survival and Feral keep Embrace of the Viper through 23. A gamepad no longer opens Blizzard's restrictions dialog on login.

### v0.3.5-beta

You can hold your hunts when you ding with **Enable Level Up On Demand**, then press **Level up!** when you are ready. **Apply filter** commits the source boxes at once. The simulator marks your faction and spec with a gold rim. The character panel's upgrade bar closes when you click outside it. **Goblin Hammer** is a Deadmines boss drop. A weapon whose tooltip says **Main Hand** is no longer an off-hand hunt. **Serrated Raptor Claw** is Horde only.


### v0.3.4-beta

Hunter ranged is bows, guns, and crossbows, ranked on the weapon's damage. Thrown weapons are not hunter hunts. Beast Mastery Horde at 22 is Alliance Outrunner Bow, Double-barreled Shotgun, and Naga Heartpiercer. At 26 it is Concealed Hand Crossbow, Dun Garok Rifle, and Outrider's Bow. Embrace of the Viper pins the Wailing Caverns entrance in the Barrens. Deadmines, Scarlet Monastery, Gnomeregan, Razorfen Kraul, Stratholme, Blackwing Lair, and Lord Kazzak have entrance pins. Simulation mode is yellow. Reset stays grey until you simulate. Hide upgrade arrows is on the Hunts page. GearQuest Commands is a settings page. Sharing a map pin no longer opens the Blizzard clipboard warning.

### v0.3.3-beta

Hunts with no known source are **Unsourced**, with no map pin. Dungeon bosses the tooltip already named are boss drops, pinned at the entrance, including Worgpelt Leggings in Shadowfang Keep. White Obsidian Wand, Unbreakable Golem Grips, Horseman's Unyielding Shroud, and Molok's Masher are hunts. Erudite's Amulet and Scholarly Pendant are greens. Priest, mage, and warlock wands rank on wand damage. Rotmender's Raiment and Embrace of the Viper count their set bonuses. **Removed** sits beside Active and Completed. Profession has a box per craft.

### v0.3.2-beta

The zone line names the parent zone. A quest reward with no Requires Level opens at the quest's pickup level. Fallen Guard's Pendant, Arcane Infused Rod, Restorer's Fine Gloves, Arena Master, and Dog Whistle are hunts.

### v0.3.1-beta

Hovers use the current Wowhead Forever tooltip. Dungeon bosses are boss drops. Open-world rares are Rare NPC, with a pin. Camp recipes point at the profession hubs. An Alliance-only quest stays off Horde.

### v0.3.0-beta

Hunts that have a place to go now say where, and **Show on map** opens that spot. Track and Untrack are one button. **Coldflame Saber** drops from Baron Silverlaine in Shadowfang Keep.

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
