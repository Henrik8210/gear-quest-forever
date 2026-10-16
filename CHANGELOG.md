# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.5.7-beta

The log has a **Lookup** tab. Quest text reads as a person wrote it. A piece you already have leaves the hunt list on that character only. Protection and Shockadin prefer a faster weapon. **Manageable Dungeons** replaces Don't look back. Hovers match the current Wowhead Forever page. The window title reads **GearQuest Forever v0.5.7-beta**.

### Lookup

A handle on the left of the log says **Lookup**. It searches the database for the class you are viewing. Open the Simulator to switch that class. Type part of a name and press Search.

While the list is building, the portrait turns grey and spins, and the line says **Searching for matching items**.

Click a result and the parchment is that item. The row's rank line says the spec, the rank, the levels, and the faction. **Thunderbrew's Boot Flask** is Alliance, from Sweet Amber in Westfall, and it requires 40. The parchment says **Part of a quest chain.** and **5 quests until you get this.** A quest that is not part of a chain does not get those lines.

Leaving Lookup puts the parchment back on the hunt you had open. It does not change your hunts or the Simulator.

### Quest text

**Wildhunter Cloak**, the reward from The Hunt Completed, used to print the code from the quest page. It now uses your character's name, a real space, and a space after **commended!** The same cleanup is on every description, the lore, and the tracker. A class token uses your class. A race token uses your race. Sir or madam follows your character.

### This character only

If you already have a hunt, it leaves **Active** on that character and sits on **Completed**. Another character still sees it. **Hammerbone** on a druid does not hide **Hammerbone** on a level 16 paladin. The weapon (i) list was already that character's ranks. The hunt rows follow the same rule.

### Protection and Shockadin

Hover Protection or Shockadin. The spec tooltip has **Weapon speed** at **-2**. A faster weapon loses less when the other stats are close, because the seal lands on each hit. A 2 second weapon loses 4 points and a 3 second weapon loses 6, on top of the weapon damage. Holy and Retribution do not use that row. Protection and Shockadin were scored again. Holy and Retribution were not.

### Play style

**Don't look back** is gone. **Manageable Dungeons** is the card in its place. It hides a boss drop, and dungeon and raid trash, until the level you are viewing is 4 under that item's level. An item of level 49 can show from 45. The wait stops at 60. Quests, vendors, crafts, and world drops stay. If Don't look back was on, it is off. Turn Manageable Dungeons on yourself.

**Get it now** still waits on reputation, and on a bind-on-pickup craft until you can make it. A bind-on-equip craft stays, because you can buy it. **Darksoul Breastplate** stays. **Flying Tiger Goggles** still wait, because the goggles themselves require Engineering to wear.

### Vendor prices

A vendor hunt states the price with the same coin icons the game uses. **Sergeant's Cape**, from Officer Areyn in Stormwind, shows that price beside the coins. Honor uses your faction's honor icon. A badge uses that badge's icon. The old sentence about Honor Points and tokens is left off once the price line is there. The rank requirement stays.

### Tooltips

222 stored rare tooltips were checked against Wowhead Forever and updated where the page had changed. 220 of them stayed rare. The text changed. **Rot-Covered Harpoon** and **Scoutmaster's Eyepatch** are uncommon. **Whirlwind Axe**, **Triprunner Dungarees**, **Gravestone Scepter**, **Crescent Staff**, and **Vanquisher's Sword** stay rare, because Wowhead Forever still lists them as rare. **Gravestone Scepter** no longer has the extra shadow resistance the old tooltip carried.

### The minimap button

The minimap button sits on the rim of the minimap.

### v0.5.6-beta

Paladins have a fourth spec, **Shockadin**. Holy, Shockadin, Elemental, and Restoration hunt a two-hander and a one-hander together. Rogues can hunt one-hand axes. **Axe of the Deep Woods** is the Horde Combat main hand from 52 through 59. **Coldflame Saber** and **Blade of Silverlaine** match the Forever page. Ten new Forever pieces are on the lists, including **Firebird Leggings** at 43 and **Stone Keeper Spire** at 44. The Desolace centaur weapons require 35. The window title reads **GearQuest Forever v0.5.6-beta**.

### v0.5.5-beta

A vendor hunt names the person standing at the pin. **Dirty Leather Bracers** in Mulgore says **Bought from Varia Hardhide.** **Manageable Quests** hides a quest reward until the level you are viewing is 4 under that item's level. **Clergy Ring** can show from 18. The wait stops at 60. Leveling up, changing zone, and opening a cold log are spread across frames. The GearQuest index stays 0 to 100 at level 60. The window title reads **GearQuest Forever v0.5.5-beta**.


### v0.5.4-beta

Weapons have one filter: two-hand and one-hand, then the types in the current band. Rank numbers stay the real ones, and the (i) list stops at 30. Hunters can dual wield. Shamans cannot. **Invisible Dagger** and placeholder items are gone. The six camp leather chests and pants are bought from Pawani and Daniel Stitchsong. The score bar does not move when you filter weapons. **General → Hide chat messages** silences chat and leaves the log. A vendor only one faction sells stays off the other list. Protection paladin armor, spell power, and mana per 5 were rescored, and level 60 kept the leveling stamina and mana multipliers. The window title reads **GearQuest Forever v0.5.4-beta**.

### v0.5.3-beta

The hunt list shows an icon and a faded grey **#N** on every row, including **#4** and later. **Leafre's Ring** shows **#1** when that tooltip says it is first. A quest reward says **This quest can be picked up at level N.** **Windstorm Hammer** and **Dancing Flame** say 36. **Ragefire Wand**, **Icefury Wand**, and **Nether Force Wand** say 40. **Heart of Disruption** says 30. **- Recommended** skips an empty slot unless that piece's raw score beats the best upgrade in a slot that already has gear. On a level 11 Retribution paladin, **Hammerbone** is the hunt over **Talbar Mantle**. Hovering bags scores a slot once and does not load every other piece. **Armor of the Fang** is +3 Strength, +3 Intellect, and +10 Spirit. Beast Mastery and Marksmanship hunt the other Fang pieces from about 18 to 24. Survival and Feral keep the chest only through 21. Enhancement keeps it through 27. **Medal of Courage** requires 35. The five Zandalar wraps and robes require 58. The level 60 dungeon sets still require 60. The window title reads **GearQuest Forever v0.5.3-beta**.

### v0.5.2-beta

The log header shows a GearQuest Index Score bar while you are not simulating. Up to three rank #1 hunts are marked Recommended. Notables are gone. Heart of Disruption is the right faction, at level 30, pinned on the quest that starts the chain. The leather helms are boss drops. The guide samples your position every 5 seconds. The window title reads **GearQuest Forever v0.5.2-beta**.

### v0.5.1-beta

The hunt list marks **- Rank #1 BiS acquired** when you already have that slot's best piece, and **- Recommended** on the biggest rank #1 upgrade from what you are wearing. Rank lists count only hunts this character can get. The window title reads **GearQuest Forever v0.5.1-beta**.

Menethil Harbor, Southshore, and Auberdine are one Alliance ship. Stormwind Harbor and Auberdine are another. Steamwheedle Port and Powderfuse Port are one ship for both factions. Alliance skycutters run Valanaar to Dalaran. Horde zeppelins run Valanaar to Skywatcher Plateau. **Coldspire Staff** drops from Rath'Mael in the Ruins of Lordaeron and requires 19. Credits lists Click.

### v0.5.0-beta

Hover any piece of gear and the tooltip says **Rank #N for your level** and a GearQuest index from −100 to +100, with a green or red arrow against what you are wearing. **General → GearQuest score on tooltips** is on by default. The dungeon upgrade sets require 60, and the pin is An Earnest Proposition. Closing the world map with a gamepad no longer locks jump or talking to NPCs. The window title reads **GearQuest Forever v0.5.0-beta**.

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
