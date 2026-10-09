# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.5.0-beta

Hover any piece of gear and GearQuest tells you how it ranks for your level, how it compares with what you are wearing, and why a piece has no score. The dungeon upgrade sets are level 60 quests. Closing the world map with a gamepad no longer locks jump or talking to NPCs.

The window title reads **GearQuest Forever v0.5.0-beta**.

### GearQuest score

Item tooltips gain a line after the stats. The same trail is on each row of the (i) rank list beside a slot header. The hunt list itself does not show the number.

The line names the rank for your current level: **Rank #1 for your level**, or **Notable for your level**. Beside it is the GearQuest index, from **-100** to **+100**. **+100** is the best stored score in that slot at your level. **-100** is the worst. The number is only how the tooltip draws the score. The hunt order still uses the same scores as before.

When that slot has something equipped, the same line compares this piece to it. A green up arrow and a green **+N** means this piece is better by that many index points. A red down arrow and a red **−N** means it is worse. An empty slot shows the index only. The same item, or a difference of zero, shows no arrow. Rings and trinkets compare to the weaker of the two pieces, and only when both slots are filled. An empty ring or trinket slot is a place to fill, not a piece to replace.

A piece you are still wearing that has aged out of the current level band is still compared. **Slick Deviate Leggings**, last scored for Enhancement at 21-23, still compare when you are wearing them at 27.

**Leggings of the Fang** stay rank 1 for Enhancement at 25-27 because **Embrace of the Viper** is scored as a set. The stored score on the legs can sit under **Triprunner Dungarees**, which then reads **+100**. When that happens the tooltip adds **Rank 1 when you wear multiple pieces of this set.**

The arrows are the green and red pictures shipped with the addon.

### Where the line shows

The line is inside the item tooltip. A hunt hover, the character panel, a chat link, and a quest-log item all get it. On the character-panel upgrade hover it sits above **World drop** and **Left-click to see more details.** Bags, quivers, and ammo are skipped.

A chat link uses the same rank as the hunt list. **Pathfinder Belt** is the unsuffixed item. Enhancement ranks **Pathfinder Belt of the Falcon**. **Kodohide Legguards** is rank 4 for Enhancement Horde at 25-27, on the list and on a chat link.

### When there is no score

If the piece is gear and it is not on the ranked list, the tooltip says why.

**Only Pathfinder Belt of the Falcon is ranked for your level.** One ranked suffix.

**Not this roll. Ranked for your level:** and then the names, when several suffixes are ranked.

**Not ranked at your level. Ranked from 18 to 24.** Or **Ranked at level 20.**

**Not ranked for Enhancement.** The name is the spec you are on.

**Not ranked for your class.** **Not ranked for your faction.**

**GearQuest has no score for this item.**

### The setting, simulation, and Play style

**General** has **GearQuest score on tooltips**, under **Remove background art**, checked by default. Uncheck it and the line leaves item tooltips and the (i) rank list. The hunt order does not change.

Simulation mode does not show a score. The line says **Turn off simulation mode to see your GearQuest Score for this item.** The Simulator button that used to say Reset now says **Turn off simulation**.

The **Play style** button reads **Play style*** while any play style is on: **No Dungeons!**, **Dungeon Enjoyer**, **Get it now!**, **Don't look back**, or **Buy it**. It matches **Filter***.

### Required level and the level 60 dungeon sets

Pieces that had no Requires Level were looked up as quest rewards. The stored level is the minimum level that can pick up that quest. Starter pieces with item level 15 or below, and no quest, can be worn at level 1.

The dungeon upgrade sets are level 60 quests for every class. **Feralheart**, **Beastmaster**, **Heroism**, **The Five Thunders**, **Darkmantle**, **Deathmist**, **Soulforge**, **Virtuous**, and **Sorcerer's**, including the Forever copies of those pieces, require **60**. They are quest rewards, not world drops. Both factions see the Forever copies. Wrists come from **An Earnest Proposition**. Hands and waist come from **Just Compensation**. Feet, legs, and shoulders come from **Anthion's Parting Words**. Head and chest come from **Saving the Best for Last**. The chain starts with **An Earnest Proposition**, and that is where the map pin sits.

**Truthseeker's Bow** requires **40**.

### Where to find a piece

A new item stores every published spot in the same pass it is added. That is the first quest in the chain, a dungeon or raid entrance, a named creature, every vendor who sells it, and a farm in each zone a dropping creature lives in, up to three spawns per zone when they are far apart. The log, the guide, and the map use the spot closest to you.

An item already in the list gets new coordinates only when its places change: new droppers, new sellers, a source that was empty, or a pin that moved. A stat or tooltip change leaves the stored spots where they are.

A world drop uses the sunset picture shipped with the addon.

### Gamepad and the world map

Opening the world map and closing it, with a gamepad, no longer blocks jump or talking to an NPC. Map pins are drawn by GearQuest on the map. They are not registered with the map's own pin list, so closing the map does not run addon code inside the gamepad focus clear.

### v0.4.2-beta

A tracked hunt can point the way. The arrow sits above the tracker, and dragging it moves the tracker. On another continent it aims at the boat or zeppelin and names the dock. `/reload` keeps the guided hunt. World-map pins use a different icon per source, including the sunset for a world drop. Through level 15 a generic world drop is pinned on a published mob: Kobold Vermin, Mottled Boar, Harvest Watcher, or Plainstrider. **Track** pulses gold the first time you can click it.

### v0.4.1-beta

Play style is five cards: **No Dungeons!**, **Dungeon Enjoyer**, **Get it now!**, **Don't look back**, and **Buy it**. The two dungeon cards turn each other off. The other three can be on with either. The green arrow stays on the real best pieces when a filter hides them, and on every hunt still showing. **Track** still toasts when you loot a hunt the list is hiding. A crafted hunt lists its materials. **Totemic Leather Hood** (Leatherworking 100) names Medium Leather, Cured Medium Hide, Pristine Leather, Fine Thread, and Sulfuric Acid. The skill line is green when you meet the recipe and red when you are short. **Dress Shoes** have no recipe. Reset on the Simulator returns the list to your character.

### v0.4.0-beta

**Play style** opened with **No Dungeons!** and **Get it now!**, and both could be on. The filter gained a profession list, a boss-drop dungeon list, and a separate trash list. The parchment shows **Rank #N** from the real slot rank. A crafted hunt states the recipe skill just before Source. **Windstorm Hammer** and **Dancing Flame** require **36**. **Ragefire Wand**, **Icefury Wand**, and **Nether Force Wand** require **40**. **Faded Hakkari Cloak** and **Tattered Hakkari Cape** require **58**. **Drakefire Amulet** requires **60**.

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
