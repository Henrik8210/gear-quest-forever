# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v1.2.5

The log header reads **GearQuest Forever v1.2.5**. Saved hunts, **Completed**, **Removed**, tracked pins, and hunt **id** strings are unchanged. Your progress is not reset.

**First restart after updating**

- This release adds **TooltipsPanel.lua**, **Data.MobDrops.generated.lua**, and **Data.WorldDropOpenChance.generated.lua** to **GearQuestForever.toc**. A **/reload is not enough** the first time you install v1.2.5 on a machine that only had v1.2.4 or older. Quit to the character screen or desktop and log in again so the client loads the new files.

### Tooltips window

A **Tooltips** button sits on the log footer beside **Play style**. The first time you open it on an account, the button pulses gold like Play style until you click it.

The window has live previews: a sample **target tooltip** on the left and a sample **item tooltip** on the right. Changing a checkbox, slider, or source filter updates the previews immediately, so you can see what you are turning on before you mouse over a mob in the world.

Unit settings moved here from Hunt settings:

- **Hide unit gear tips** — removes every GearQuest line on creatures, vendors, trainers, and quest givers.
- **Always show unit gear tips** — lists upgrades without holding **Shift**.
- **Show drop chance on unit tooltip lines** — adds a grey **(N%)** when GearQuest knows the rate.
- **Unit gear sources on tooltips** — filters boss, trash, rare, world, vendor, profession, and quest lines (outside instances only; inside dungeons Blizzard often hides the creature name from addons, so those filters do not apply there).
- **Minimum drop chance** — slider from 0% upward; when every line is below the cutoff, the tooltip shows a grey hint to lower the slider.

Item settings in the same window:

- **Recommended gear enchantment** (off until you turn it on).
- **GearQuest score on tooltips** and **Ranks for your other specs** (same behavior as **General settings**).

### Unit BiS lines on NPCs

Mousing over a creature, vendor, trainer, or quest giver still lists up to three upgrades that beat what you wear (or fill an empty slot). Downgrades stay off. Rings and trinkets compare to the weaker worn piece. The line still includes rank, slot, the white GearQuest index, the green arrow, and the green comparison number.

**Shift** still gates the lines unless **Always show** is on. Without Shift, when GearQuest has lines to show, the tooltip ends with **Hold Shift to see BiS items from this NPC**.

**Attackable mobs** can show **two** blocks: named drops or sells on that creature, and **Your top world drops from this mob** for generic world drops whose level band fits the mob's level. Both blocks use the same upgrade test.

**Opposite-faction NPCs** get no GearQuest lines. You cannot farm their drops on your hunt list, so friendly guards and town NPCs on the wrong faction no longer show misleading upgrades.

Obtained or removed hunts drop off on the next hover without waiting for a cache rebuild.

### Drop chance percentages

For **named** droppers, the grey **%** comes from the mob-drop index when Wowhead stored a rate for that creature and item.

For **generic** world drops (no named creature on the hunt), GearQuest uses an **averaged outdoor sample rate** from Wowhead classic **Dropped By** data (uild_world_drop_open_chance.py). This release ships about **1,845** of those averages. Items with no average yet show no grey **%**; hunts and ranks are unchanged.

Turn **Show drop chance** off to hide every **%**. The minimum-drop slider filters lines that have a known positive chance below your cutoff.

### Hunter weapons from level 20

Hunters learn **Dual Wield** at 20. Forever ranks either-hand one-handers on the **off-hand** weapon list. v1.2.5 scores the **best two distinct one-handers** as a pair against the best two-hander, in the hunt lists, the Weapons filter, upgrade arrows, GearQuest score, and paper-doll logic — not a phantom main-hand one-hander plus a trinket-style off-hand.

After rescoring, **Main Hand** hunt rows still favor two-handers where the model says so; **Off Hand** rows use the combined dual-wield score. If you wear a two-hander, comparisons still treat the off-hand slot correctly.

All three hunter specs were rescored from the current Forever tooltips. Expect rank shuffles on one-hand and two-hand bands from level 20 upward, especially Marksmanship and Survival.

### Data, mob drops, and coordinates

The mob-drop table and vendor or trainer maps were rebuilt from the Forever ingest pass (Data.MobDrops.generated.lua). More creatures and vendors can answer on unit tooltips when their drops or wares are on your hunt list.

Quest faction gates, coordinates, and item stats were refreshed where the pipeline found new sources. Class hunt files for all nine classes were re-emitted from the current scored JSON.

**Weights were not retuned** for player specs in this release. Custom stat weights you saved on your account are unchanged.

### Languages and settings layout

New player-facing sentences for the Tooltips window and unit-tooltip controls were added to every **GearQuest/Locales/** file in this release.

**Hunt settings** no longer duplicates unit-tooltip or enchant controls; use the **Tooltips** window or **General settings** for item score lines.

### For developers

CI gains **Recommended enchants** (scripts/ci/check_enchants.py) so enchantable hunt rows keep a formula at the item's level. Hunter dual-wield pairing is covered in 	ests/pipeline/test_score.py.

### v1.2.4

**GearQuest Forever v1.2.4** — **Catalog.lua** lazy-loads hunt rows per query instead of materializing the whole class at login; same hunts, ranks, and saved ids. First install needs a full restart (not /reload alone). Thanks **kaeldrin-gh**.

### v1.2.3

**GearQuest Forever v1.2.3** — Unit BiS lines need **Shift**; grey hint when upgrades exist. Hunts unchanged.

### v1.2.2

**GearQuest Forever v1.2.2** — Other-spec tooltip ranks, **No crafted BoP!**, craft recipes, Lookup **(i)**, removed absent raids and client-missing hunts, **Krol'dok**, pins and unit-tip performance, gamepad and font fixes.

### v1.2.1

**GearQuest Forever v1.2.1** — Roughly half the memory of v1.2.0; one faction unpacked; **Item Stats** addon split; compact staging.

### v1.2.0

**GearQuest Forever v1.2.0** — Track untrack boxes, **Get it now** profession wear, scoring and hunt fixes, new Forever pieces.

### v1.1.9

**GearQuest Forever v1.1.9** — Dungeon unit-tooltip error hotfix; knight pulse on first open.

### v1.1.8

**GearQuest Forever v1.1.8** — Unit tips show real upgrades only; **Disengagement Ring** on vendors.

### v1.1.7

**GearQuest Forever v1.1.7** — GearQuest score on tooltips, tooltip rescore, quest chains, unit BiS lines.

### v1.1.6

**GearQuest Forever v1.1.6** — Worn gear scoring on the bar; Twisted Evils greens; ding weapon warm.

### v1.1.5

**GearQuest Forever v1.1.5** — Craft and drop sourcing refresh; vendor hunts; Donations page.

### v1.1.4

**GearQuest Forever v1.1.4** — Translated knight guide; TomTom pins; 37 new hunts.

### v1.1.3

**GearQuest Forever v1.1.3** — Custom spec scoring; caster one-hand pairs; Brutal mail chain.

### v1.1.2

**GearQuest Forever v1.1.2** — Quest chain filters; localized parchment; **No Zephras!**; hide lower ranks and map pins.

### v1.1.1

**GearQuest Forever v1.1.1** — Languages addon; fury off-hand weapons; Lookup layout.

### v1.1.0

**GearQuest Forever v1.1.0** — **Their Cities**; 196 hunts; dungeon quest filter.

### v1.0.9

**GearQuest Forever v1.0.9** — Hunt source icons; client-first hovers.

### v1.0.8

**GearQuest Forever v1.0.8** — Two-line hunts; full parchment names; hunter dual-wield ranks.

### v1.0.7

**GearQuest Forever v1.0.7** — Discord invite update on Community page.

### v1.0.6

**GearQuest Forever v1.0.6** — Class icons in the AddOn list.

### v1.0.5

**GearQuest Forever v1.0.5** — Hunts-per-slot layout; knight speaker UI.

### v1.0.4

**GearQuest Forever v1.0.4** — Hunts-per-slot slider 3–10; 12-page knight intro.

### v1.0.3

**GearQuest Forever v1.0.3** — Rarity-colored rewards; flyout select all; dungeon entry line.

### v1.0.2

**GearQuest Forever v1.0.2** — Gamepad log navigation and filter focus.

### v1.0.1

**GearQuest Forever v1.0.1** — Optional recommended enchantment line; controller log.

### v1.0.0

**GearQuest Forever v1.0.0** — First release-channel build; GearQuest Index score bar.

### v0.6.1-beta

The window title reads **GearQuest Forever v0.6.1-beta**. Paladin and warrior levels 1–9 are scored per spec for both factions. Alliance Retribution hunts **Northshire Hammer**, **Empyrean Greatsword**, and **Ironforge Greathammer**. Horde Arms hunts **Rusty Cutlass**, **Goblin Smasher**, and **Riptear's Cleaver**. Turning the guide off frees the memory it used. **Recommended** follows the filters. **Dun Garok Rifle** and the Stormpike pieces are Horde only. **Friend of the Library** is both factions. **Ashbringer**, **Sulfuras**, and **Nature's Whisper** are on the lists. A priest, a mage, a warlock, and a balance or restoration druid start with two-hand and main hand both on. Hunters have Bow, Gun, and Crossbow on the Ranged header.

### v0.6.0-beta

You can make your own spec weights from **+ custom stat weights**. **Save and score items!** rebuilds that list, and the spinner stays on the GearQuest window. **Focus Zone** keeps hunts in the zone you are standing in. **Stormrider's Leather Pants** scores the damage-and-healing line as healing and damage. The window title reads **GearQuest Forever v0.6.0-beta**.

### v0.5.8-beta

**General → Window size** runs from 100% to 150%. A reputation vendor says the standing this character has. **Ratchet Wristwraps** says **Your standing is Neutral.** Auctionator prices sit under a hunt hover when that addon is on. Eight starter drops are green, including **Wispy Cloak** at 5 and **Ratty Old Belt** from Narg the Taskmaster. **The GearQuest Community** lists Thrayne. The window title reads **GearQuest Forever v0.5.8-beta**.

### v0.5.7-beta

The log has a **Lookup** tab. Quest text uses your character's name. **Wildhunter Cloak** no longer prints the code from the quest page. A piece you already have leaves the hunt list on that character only. **Hammerbone** on a druid does not hide it on a paladin. Protection and Shockadin score weapon speed at -2. **Manageable Dungeons** replaces Don't look back. A bind-on-equip craft stays under **Get it now**. Vendor prices use coin icons. 222 rare tooltips were checked against Wowhead Forever. **Rot-Covered Harpoon** and **Scoutmaster's Eyepatch** are uncommon. The minimap button sits on the rim. The window title reads **GearQuest Forever v0.5.7-beta**.

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
