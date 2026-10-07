# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.4.1-beta

Play style is now five pictured cards. A filter or a play style no longer takes the green arrow off your real best pieces, and Track still toasts when you loot a hunt the list is hiding. Crafted hunts name the materials and color the skill line.

The window title reads **GearQuest Forever v0.4.1-beta**.

### Play style

**Play style** at the bottom of the log opens five cards. The name sits under the picture. Three are on the first row and two on the second. The heading says you can turn several on at once, and that each one can cover several sources. The filter still only chooses a source. A gold rim shows which cards are on.

**No Dungeons!** hides a hunt that sends you into a dungeon or raid: a boss, trash, and a quest that enters an instance at any step. A world drop stays, even when its zone is a dungeon name or the pin is that entrance. **Captain Melrache's Cape** drops from Captain Melrache in the outdoor graveyard. The stored zone is Scarlet Monastery, and the cape stays. World bosses stay. A craft you can buy stays.

**Dungeon Enjoyer** keeps only those dungeon and raid hunts. World bosses, crafts, vendors, and outdoor hunts stay hidden. No Dungeons and Dungeon Enjoyer turn each other off.

**Get it now!** hides a hunt this character cannot get yet. A vendor piece waits until you reach the reputation stored on that item. A bind-on-pickup craft waits until you have that profession and the skill printed on the hunt. A bind-on-equip craft stays, unless the item itself requires the profession to wear. When you reach the standing or the skill, the hunt comes back on its own.

**Don't look back** hides a hunt once its required level would be a gray quest. Green and yellow stay. On a live character that uses the game's own green range. A level 18 hunt is still on the list at 25 and drops off at 26.

**Buy it** keeps hunts you can purchase. Vendor pieces stay. So does anything that binds when equipped, binds when used, or does not bind. Bind on pickup stays hidden, unless a vendor sells that piece. At level 27, Elemental Horde, Head with every source still checked: **Scaled Leather Headband** and **Robust Helm** stay, and **Holy Shroud** fills the open row. **Totemic Leather Helm** and **Totemic Leather Hood** leave, because both bind when picked up. The hood is the notable. Buy it hides it with the helm.

Get it now, Don't look back, and Buy it can be on together, and with either dungeon card.

With any of them on, a slot still fills to three hunts that fit, then keeps the notable when that notable fits too. A bind-on-pickup notable does not stay under Buy it.

### Green arrows

The green arrow on the quest log, a quest giver, loot, and a vendor stays on the unfiltered best pieces when a filter or a play style hides them. It also stays on every hunt still on the list, including a later rank, a notable, and a tracked hunt.

The character panel bar follows the list you are looking at. A piece a filter hid is not on that bar.

**Hide upgrade arrows** on the Hunts settings page still removes all of them.

### Toasts and Track

The obtain toast follows the unfiltered top three and the notable. A filter or a play style does not change that. A rank 6 that is only on the list because of a filter does not toast when you loot it.

**Track** does. Hovering Track, while the button still says Track, says: the toast still fires when you obtain it, rank does not matter, and a filter or a play style does not stop it. Untrack and Remove do not show that line. A piece you already own does not toast again. **Hide obtain toast** still skips the popup. The chat line still prints.

### Crafted hunts

The old sentence **Crafted with Leatherworking (requires skill N).** is gone from the description. In its place, when Forever has the recipe, the description lists the materials. **Totemic Leather Hood** (Leatherworking 100) reads **Materials: Medium Leather (8), Cured Medium Hide (2), Pristine Leather (4), Fine Thread (2), Sulfuric Acid (4).** The recipe vendor sentence stays under that, when the hunt has one.

The skill line just before Source is unchanged in wording. **Requires Leatherworking (100) to craft. Your Leatherworking is 157.** That status clause is green when your skill is at least the recipe, and red when you are short. **You don't have Leatherworking.** is red too. The words "Requires … to craft." stay the parchment color.

Learning the profession, or gaining a point, updates that line on an open craft hunt. The hunt list itself rebuilds only when Get it now is on and the skill number actually changed.

**Dress Shoes** have no Forever recipe, so they get neither a skill line nor a materials line.

### World drop pins

A world drop with no named creature, through level 15, now has a map pin on your own side. Alliance 1–7 is Elwynn Forest (48.2, 42.8). Horde 1–7 is Durotar (42.0, 68.4). Alliance 8–15 is Westfall (31.0, 46.2). Horde 8–15 is the Crossroads in the Barrens (51.0, 29.4). Above 15 both factions share the catalog spot. A drop from a named creature stays on that creature's pin. **Show on map** opens that spot.

### Smaller fixes

Reset on the Simulator, after a filter was on at a simulated level, returns the list to your character. It used to keep the simulated rows.

Turning in a quest with a gamepad no longer locks the action bar. The upgrade arrows and the level-up refresh wait one frame, so they are not painted inside the gamepad's own focus change.

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
