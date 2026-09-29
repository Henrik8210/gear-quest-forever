# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v0.2.19-beta

Weapon hovers show spell power again, hunts follow the required level on the tooltip, and a filtered list no longer includes gear from a source you turned off.

The window title reads **GearQuest Forever v0.2.19-beta**.

### Spell power on weapons

Hovering a weapon that increases spell damage and healing used to drop that Equip line, so the weapon looked like it had no spell power. Chest pieces already showed it. The line is back, and it is scored.

"Increases damage and healing done by magical spells and effects by up to N" counts as both healing and spell damage. A green "+N Spell Power" line is spell power only. A line that affects the whole party is not treated as your own spell power. Green world drops are unchanged: **Barbed Club of Healing** still shows the best suffix roll and the slim-chance line.

**Alliance Holy and Discipline**

- From level **14**, **Staff of Westfall** is main hand rank **1**. It is the reward from **The Defias Brotherhood** in The Deadmines. It requires level 14. The tip is +5 Intellect, +6 Spirit, up to 48 healing, and up to 16 spell damage.
- At level **13**, before that staff: **Trogg Scepter** rank 1, **Golemheart Stave** rank 2, **Fang of Magmatus** rank 3.

**Horde Holy and Discipline**

- **Crescent Staff** (Leaders of the Fang, Wailing Caverns, requires 10) stays rank **1** from level 10 through 17.
- **Staff of Orgrimmar** (Hidden Enemies, from Thrall in Orgrimmar, requires 9) is on the list from level **10** and is rank **3** from 10 through 17. **Kris of Orgrimmar** is the one-hand from the same quest.
- **Fang of Magmatus** is scored for Horde Holy. It sits behind Crescent Staff, Trogg Scepter, and Staff of Orgrimmar, so it is not in the top three there.

**Fang of Magmatus** requires level **13**. The item level is 18, and that no longer holds it back. It drops from Magmatus in Hall of Thanes: +4 Intellect, up to 18 healing, and up to 18 spell damage. **Golemheart Stave** drops from Plunder in the same dungeon, also requires 13, and adds stamina, intellect, and spirit on the same 18 / 18.

**Frost mages**, both factions: Golemheart Stave is rank **1** from 13 through 18, and Fang of Magmatus is rank **2**. Shadow priests follow the same shape at 13.

**Royal Dagger** (A Friend of the Family, Stormwind, requires 20, Alliance) shows +4 Intellect and up to 18 healing and 18 spell damage on the hover.

### Required level, not item level

A hunt uses the **Requires Level** printed on the tooltip. Item level does not push the piece to a later band when the tooltip already states a level.

If the tooltip has no required level, that piece is treated as a quest reward, or as some other source that has a level gate, and the quest is looked up. The lowest level that can pick up that quest becomes the required level. Several quests use the lowest one. A required level already printed on the tooltip is never replaced.

- **Staff of Westfall** is 14, from The Defias Brotherhood.
- **Grave Shroud** is 16.
- **Staff of Orgrimmar** and **Kris of Orgrimmar** are 9, from Hidden Enemies, so Horde priests see the staff from level 10.

Wowhead stopped answering partway through that lookup. Quest rewards that were reached now use the quest's pickup level. The ones that were not reached still use the previous gate.

### Grave Shroud

**Grave Shroud** is a back with 20 armor, +3 Strength, +2 Agility, and +5 Stamina. It requires level 16.

- Alliance: quest **Abominable Creatures**.
- Horde: quest **Unending Torment**.

Bear tank, both factions: rank **1** at level **16**. From 19 through 22 on Horde Bear it is rank **3**, behind **Sporid Cape** and **Sentry Cloak**.

Cloaks, rings, necks, trinkets, and held-in-off-hand items that had no item type in the data can be hunts now. Grave Shroud was one of those.

### Weapon slot headers

The main-hand and off-hand lists stay separate. The header names the choice.

- Mage, priest, and warlock: **Staff or main hand**. Off Hand stays Off Hand.
- Druid and Enhancement shaman: **Two-hand or main hand**. Enhancement does not dual wield.
- Hunter: **Two-hand or dual wield**. The ranged slot is labeled **Bow**.
- Rogue, and Warrior Fury: **Dual wield**.
- Paladin Retribution and Warrior Arms: **Two-hand**.
- Paladin Protection and Holy, Warrior Protection, and Shaman Elemental, Restoration, and Enhancement Tank: the off-hand header reads **Shield**.

If a staff is rank 1, rank 2 in that section is the one-hand, and Off Hand rank 1 is the piece that pairs with that one-hand. A second staff can sit at rank 3.

### Source filter

Fishing is a profession. With only **Boss drop** checked, **The 1 Ring** no longer appears. It follows the **Profession** box, and the detail line says Profession. The note still says it is fished up. **Steelscale Crushfish** and **Broken Wine Bottle** follow the same box.

Items found inside another item follow **Container**. Mail and pickpocket follow **Special**. A piece with no known source stays off the list while a filter is on, and still shows when the filter is off.

### Item names

The list and the hover title use the real name when the game client only knows "Item" plus a number.

- **Item 23173** is **Abomination Skin Leggings**.
- **Item 6750** is **Snake Hoop**.

Every hunt on the lists already had a stored name. Those rows no longer fall back to the number.

### Sets and pinned hunts stay

Re-scoring used the refreshed tooltips. It did not drop the set bonuses or the pieces already treated as the hunt.

- **Embrace of the Viper** (Wailing Caverns) is still the hunt for hunter, rogue, Enhancement shaman, and Feral druid in the same level windows as before.
- **Defias Leather** and **Chain of the Scarlet Crusade** still rank the way they did in 0.2.18.
- **Wolfsbane** is still Horde Retribution only. Main hand, rank 1, from level 20 through 26.
- **Snake Eye Kaleidoscope** is unchanged.

### Earlier versions

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
