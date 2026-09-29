# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.2.20-beta

The log has a backdrop for your class. The simulator shows each class on a strip of that same art. Priest, mage, and warlock wands count their damage, and a green "of the …" hunt completes only when the name matches.

The window title reads **GearQuest Forever v0.2.20-beta**.

### Class art on the log

Every class has a scene behind the upgrade list and the parchment: warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, and druid. The window shows the center of the picture and leaves out the edges that do not fit, so nothing is squeezed. A round shape in the art stays round. The corners are shadowed. The list is darker on the left and opens toward the art on the right. The parchment is slightly see-through, so the scene shows behind the text.

Only the class you are playing, or the class you are simulating, is loaded.

**Settings**, under **Hide minimap icon**: **Remove background art**. Leave it unchecked and the scene stays on. Check it and the log goes back to the plain brown background.

### Simulator class list

The nine classes fill the list beside the parchment. The list does not scroll, and it stays the same height as the parchment. Each row uses the full width of that list and shows a slice of that class's scene, with the name in the class color. The left side of the row is dark so the name stays readable. The selected class has a light gold tint.

### Wands

From level **10**, priest, mage, and warlock ranged weapons count their damage. A large damage gap beats a small intellect or spirit roll. Levels **1–9** are unchanged.

**Greater Magic Wand** matches the client: **22–41 Arcane**, **17.5** damage per second. The old line was 14–27 and 11.39.

**Holy and Discipline, both factions**, levels **13–16**, ranged:

- Rank **1**: **Deepblaze**, from the quest Old Ironforge Incursion.
- Rank **2**: **Greater Magic Wand** (+2 spell damage, 17.5 dps).
- Rank **3**: **Dwarven Flamestick** (+2 spirit, 8.89 dps).

### Lookie's Spyglass

**Lookie's Spyglass** drops from **Cookie** in **The Deadmines**. It is not a world drop. The detail says "Drops from Cookie." Holy priests see it as trinket rank **1** from level **18** through **20**.

### Hovers that skipped the stats

A hunt with no Wowhead tooltip now uses the client tip, and any scored stat still missing from that tip is written on the hover: armor, strength, agility, stamina, intellect, spirit, spell power, healing, and attack power.

**Belt of the Stars** (Look To The Stars, Duskwood, requires level **20**) shows **117** armor, **+6 Strength**, and **+6 Stamina**.

### Green names

A random enchant completes on the full name, not the base item.

- Looting **Shimmering Gloves of Arcane Wrath** does not complete **Shimmering Gloves of Healing**.
- Buying **Wrangler's Boots of the Bear** does not complete **Wrangler's Boots of the Falcon**.

The toast names the piece you actually picked up.

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
