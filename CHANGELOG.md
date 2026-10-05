# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.3.5-beta

You can hold your current hunts when you ding, then load the new level when you are ready. The log, the simulator, and the character panel are easier to click. A main-hand-only weapon no longer shows up as an off-hand hunt, and a Horde dagger no longer shows up for Alliance.

The window title reads **GearQuest Forever v0.3.5-beta**.

### Level up On Demand

**Enable Level Up On Demand** sits at the bottom of the log. It starts off. It is per character.

Leave it off and a ding still loads the new BiS lists immediately. Hovering the box says **Lag spikes on level up?**

Check it and the list stays on the level you were already hunting. A **Level up!** button appears beside the box. After you ding, hovering that button shows a yellow title for the level you jump to, and a smaller white line for the level you leave. If you are 26 and you have just become 27, the yellow line is **Level up to 27** and the white line is **From level 26.** One click covers every level you gained while the box was on.

Looting or equipping a hunt that is still on that held list still toasts, and the hunt still moves to **Completed**. **Hide obtain popup** only hides the popup. The hunt is still marked complete, and the chat line still prints.

The green upgrade arrows on the quest log, the quest giver, loot, and vendors keep painting for the list you are still on.

The spec picker still changes your spec immediately, including while **Level up!** is waiting. The list reloads for the spec you picked, at the level the list is held on.

A hunt says **New** only when it was not on the previous level's list. **Trapper's Leather Helm** is on the Enhancement head list at 26 and still there at 27, so it does not say New again at 27. A piece that first shows up at the new level still says New. Level 1 has no New labels. This is every class, spec, slot, and level.

Uncheck the box and the lists follow your level automatically again. Hovering a checked box says **Switch to automatic level up!**

The simulator is separate. While a simulation is on, the lists are the class, spec, faction, and level in the simulator. **Level up!** updates your own character's held level. It does not replace the simulation.

### Filter

Checking a source, or a profession in the sub-list, no longer rebuilds the log on every click. **Apply filter** sits at the bottom of the dropdown and applies every box at once, including professions. Close the menu without Apply and the list stays as it was.

### Simulator

The faction and specialization you have chosen are no longer greyed out. A bright gold rim sits around that button, and a slow river of small gold dust motes circles it. That is Alliance or Horde, and each spec button: Elemental, Enhancement, Enhancement Tank, Restoration, and the same kind of choice on every class.

Open the simulator while you are not simulating and the form matches you. A level 27 Horde Enhancement shaman opens as Horde Enhancement, not as Elemental.

**Reset** stays grey until you click **Simulate**. Hovering the grey button says you are already seeing your character unsimulated. After you apply a simulation, Reset turns on and brings the lists back to you.

### The log

Dragging the scrollbar to the bottom of **Active**, **Completed**, or **Removed** no longer leaves the hunts unclickable.

Clicking a BiS icon on the character panel opens that hunt in the log, even when the window was sitting on **Simulator** or **Settings**.

**Credits** lists Eao, MainWon, and Stikmyre.

### Character panel

Right-click a gear slot and the upgrade bar opens beside it, the same as before. Click outside that bar and it closes: the character model, the stats, the ground, or another window. You no longer have to right-click a second slot to dismiss the first. A right-click on a slot still opens that slot's bar. A left-click on a BiS icon still opens the hunt.

### Goblin Hammer

**Goblin Hammer** drops from **Gilnid** in the Deadmines. It is a boss drop, not a world drop. The tooltip says **Boss drop**. **Show on map** opens the Deadmines entrance in Westfall, 42.5, 71.7. It requires level 18. Shaman, warrior, paladin, rogue, and druid lists that include it use that source.

### Off hand

A weapon whose tooltip says **Main Hand** is no longer an off-hand hunt. **Royal Diplomatic Scepter** was an off-hand option for a level 30 Combat rogue. It is a main-hand mace. The same correction is on the rogue, warrior, and hunter off-hand lists, wherever a main-hand-only weapon had been copied into the off hand. A weapon whose tooltip says **One-Hand** can still sit in either hand.

Level **30** Alliance **Combat** rogue, off hand:

1. **Ironspine's Fist**
2. **Bloody Brass Knuckles**
3. **Sentinel's Blade**

Level **28–30** Alliance **Assassination** and **Subtlety**, off hand:

1. **Sentinel's Blade**
2. **Thornspike**
3. **Subdued Dragon's Fang**

### Serrated Raptor Claw

**Serrated Raptor Claw** is a one-hand dagger, item level 33, so the off hand is a legal slot. It is a reward from **Changing Tastes**, which starts with **Borstan** in Orgrimmar, 57.4, 53.4. That quest is Horde only. Alliance no longer sees the claw, in the main hand or the off hand. Horde still does. **Show on map** opens Borstan.

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
