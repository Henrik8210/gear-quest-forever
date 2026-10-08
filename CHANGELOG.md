# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.4.2-beta

A tracked hunt can point the way. The world map uses a different icon for each source, a world drop sits on a mob instead of a quest camp, and Track pulses gold the first time you can click it.

The window title reads **GearQuest Forever v0.4.2-beta**.

### Guide

Each row on the tracker has **Enable Guide**. One hunt is guided at a time. The arrow sits just above the tracker. Dragging the arrow moves the tracker with it. The picture is a strip of 32 frames. The frame changes so the tip points the way you are facing, including when that way is west. The picture itself does not spin.

Inside 12 yards the line says **Here**. On the same continent it says the yards. On another continent it aims at the boat or zeppelin you can board, and the line says **Ship** or **Zeppelin**. The map pin stays on the hunt. When you arrive on that continent the arrow aims at the pin again.

Horde zeppelins: Durotar 50.8, 13.6, Tirisfal Glades 61.0, 59.0, and Grom'gol in Stranglethorn Vale 31.5, 29.6. Both factions: the ship at Ratchet 63.6, 38.7 and Booty Bay 26.0, 73.2. Alliance ships: Auberdine 32.7, 43.7 and Menethil Harbor 4.7, 57.0, and Menethil 5.0, 63.0 with Theramore 71.0, 56.0.

**Hide guide arrow** on the Hunts settings page hides it for the account. The hunt you are guiding is stored on that character. Logging out clears it. `/reload` keeps it. The hunts you are tracking stay either way.

Left-click a world-map pin to guide. The tooltip says **Left-click to Guide**. Right-click says **Right click to open Hunt** and opens that hunt in the log.

### World map pins

Tracked hunts pin the world map. The minimap does not draw them. The guided pin has a blue ring.

The icon matches the source, all the same size. A boss is a skull. A container is a chest. Dungeon and raid trash is the red raid mark. A profession, including fishing and skinning, is a book. A quest reward is a yellow exclamation. A rare is a silver dragon. A seasonal quest is a wrapped present. Special, including mail and pickpocket, is a gold star. Unsourced is a red X. A vendor is a sack. A world drop is a sunset over dark hills.

The Filter list uses those same icons, after the checkbox and before the name. The profession, boss, and trash lists do not.

Hovering **Show on map**, in white, says: See where you can find this on the world map, and let the guide show directions. With no coordinates it still says, in white: We are missing exact coordinates for this item.

### Where a world drop is pinned

A generic world drop through level 15 is on a published mob, not the quest camp.

Alliance 1–7 is Kobold Vermin in Elwynn Forest, 47.4, 35.0. **Patchwork Cloak** is there. Horde 1–7 is a Mottled Boar in Durotar, 41.2, 64.4. The Den at 42.0, 68.4 stays the start of a Durotar quest. Alliance 8–15 is a Harvest Watcher in Westfall, 36.4, 50.4. **Calico** is there. Horde 8–15 is a Plainstrider in the Barrens, 47.5, 26.8. Above 15 both factions share the catalog spot. A named creature stays on that creature.

When a hunt has several spots, the coordinate line and the guide use the closest. That spot stays until another is at least 20 yards closer.

### Track

The first time **Track** is on screen and can be clicked, it pulses gold, the same wash as Play Style. With no hunt selected it stays grey and still. It stays still on Removed, and on the Simulator and Settings. The first click marks it seen for the account.

Hovering Track, while the button still says Track, is white: Click to track this hunt. The Guide feature can be enabled.

Untrack asks "Are you sure you want to untrack this gear quest? It will become unavailable once you do" only when that hunt would leave the active list. The dialog sits in front of the log.

### Hunt page

The rank list beside a slot header, the one that says which pieces were ranked for your level, opens only when the cursor is on the info mark. The rest of that line still collapses the slot.

A vendor with a required standing gets a line just before Source. **Requires Honored with Booty Bay. Your standing is Friendly.** The standing is green when you have met it and red when you have not. **Souvenier Sea Shell** is that kind of neck.

The simulator can show a hunt the character you are logged in on could not equip, once the hunt's required level is met. A level 2 looking at level 15 still sees the weapon.

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
