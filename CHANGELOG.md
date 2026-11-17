# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v1.2.2

The window title reads **GearQuest Forever v1.2.2**. Item tooltips now show the rank for every spec of your class, so you can gear two specs at once. Play style has a second page with **No crafted BoP!**, and crafted hunts show their recipe. The hunt lists now only hold gear that is actually in WoW: Forever and in your game client. Creature and quest giver tooltips find more of your upgrades and no longer freeze the game on hover. The log is smoother and easier to use with a gamepad. Your Completed, Removed, and Tracked hunts, your custom specs, and your settings are kept.

**Ranks for your other specs on item tooltips**

Under your own rank line, the item tooltip now lists the rank the item has at your level for each other spec of your class, for example **Restoration: Rank #3 for your level**. You can gear Enhancement and Restoration, or Shadow and Holy, without tracking hunts for both. The lines show on items in your bags, on your character panel, in chat links, on the hunt list, in Lookup, and on the (i) rank list. They also show while you simulate another class.

- **Random-enchant greens.** Each spec ranks its own best roll, and the line names that roll. For a level 47 Beast Mastery hunter, the **Fire Opal Necklace of Agility** hunt reads **Marksmanship: Rank #1 for your level (of the Falcon)** and **Survival: Rank #1 for your level (of the Tiger)**.
- **Not ranked.** A spec that does not rank the item at your level gets a grey line, such as **Holy: Not ranked for your level**. **Netherpearl Shoulders** only add Shadow damage, so a level 47 Shadow priest sees Shadow #2 and Discipline and Holy not ranked. An item no spec of your class ranks, like plate on a mage, gets no lines.
- **Setting.** **General settings → Ranks for your other specs** is on by default. Turn it off to see only the spec you are playing or simulating.
- **Quick first hover.** The other specs' lists are built in the background after your own list is ready.

**Settings are grouped**

Both settings pages have headings now. **General** has **Interface** (language, minimap icon, window size, background art, hide chat messages) and **Tooltips and score** (score on tooltips, ranks for your other specs, score bar). **Hunt settings** has **Hunt list** (hide lower ranks, obtain popup), **Tooltips** (recommended enchantment, unit gear tips), and **Arrows, map and tracker** (upgrade arrows, guide arrow, map pins, map pin size, hide tracker). Every setting keeps its saved value.

**New play style: No crafted BoP!**

The Play style panel has a second page. Use the arrows and **Page 1 / 2** just above Close to switch. **No crafted BoP!** hides crafted gear that binds when picked up until you have the profession and the skill its recipe needs.

- It works no matter where the hunt is filed. That covers the crafts whose recipe a vendor sells, such as the Jim'bek tailoring pieces, and the leather and mail helms whose pattern drops from dungeon bosses. The source filter could not separate those.
- **Stalker's Mail Shoulders** need Leatherworking 210, so a leatherworker at 195 does not see them. They come back by themselves at 210, without turning the style off.
- Crafted gear that binds when equipped stays, because another player can make it for you. Fishing, skinning, mining, and herbalism are not crafts.
- Rank numbers do not change.
- Turning **No Zephras!** on or off now refreshes the list at once. Before, it could show the old list.

**Recipes on crafted hunts**

896 of the 1,087 crafted hunts show their recipe just above the **Requires Leatherworking (210) to craft** line. The row has the recipe's icon and its name in its quality color. Hovering it shows the game's own item tooltip, and Shift-click links it in chat. **Stalker's Mail Shoulders** show **Pattern: Stalker's Mail Shoulders**. A craft the trainer teaches has no recipe row and lists its materials instead.

**Cleaner hunt descriptions**

The description no longer repeats what another line already says:

- "Pick it over the other reward choices", "Indexed from Wowhead Forever", and "Source not listed yet" are gone.
- A description that only said "Quest reward." or "Bought from a vendor." is gone, because Source says the same.
- A reputation requirement shows once, on the standing line with your own standing.
- Set bonus sentences are gone, because the item tooltip lists them.
- A craft with a recipe row drops its materials, because the recipe tooltip lists them. The tracker still shows the materials.

**Weapons you have not learned yet**

A hunt for a weapon type your character has not learned adds a red line, such as **You haven't learned to use Daggers yet.** It uses the skill name the weapon master trains, like Daggers, Staves, or One-Handed Maces. A priest starts with maces and buys Daggers and Staves, so a dagger or a staff hunt says so. The piece stays on the list and keeps its rank. Simulation adds no such line.

**Click (i) to open the rank list in Lookup**

Clicking a slot's (i) on the hunt list, or the open rank panel, switches to Lookup with that whole list in rank order. Each row starts with its #N, and clicking a row opens its description, so you no longer have to type item names. The search box reads **Head rank list**, and typing a search replaces it. Lookup now scrolls and shows up to 100 results, up from 10.

**Only gear that is in WoW: Forever**

- **Raids that are not in the game.** Molten Core, Blackwing Lair, Zul'Gurub, both Ahn'Qiraj raids, and Naxxramas are not hunts anymore. Neither are the Brood of Nozdormu and Zandalar Tribe reputation rewards, the Thunderfury, Sageblade, and Persuader parts, or the C'Thun quest rewards. That is 880 items, 357 of them on hunt lists. Onyxia's Lair stays, and so do world drops such as Onyx Shredder Plate. These come back when a raid opens.
- **Ice Barbed Spear, Bloodseeker, and Wand of Biting Cold** are off the lists. Korrak the Bloodrager is not offered, and the Alterac Valley victory quests give reputation only.
- **Gear your game client does not have.** 684 hunts were items Wowhead Forever lists but the game cannot load. Their hover could only say this game client does not have it yet. Most are level 60 Season of Discovery PvP rank gear from the rank quartermasters, plus the Inquisition, Fireleaf, and Waywatcher sets. Only 2 were below level 20. They are kept aside and come back when a client patch adds them.
- **Unsourced.** Items Wowhead Forever marks Unconfirmed or "This item may not be in WoW: Forever", such as the Rune Broker librams, idols, and totems, are listed under **Unsourced** (the orange circle), which starts hidden.
- **(Set piece).** Every piece of a Wowhead item set now has the (Set piece) label. Only Embrace of the Viper, Defias, Scarlet, and Rotmender's Raiment count a set bonus in the score.

**Krol'dok Stronghold**

The dungeon in northern Riverglades is now a dungeon in GearQuest. Its six bosses are Slavecrusher Grox, Twilight Commander Zarmok, War Handler Ashka, Nar'gurk, Bossman Toof, and Overlord Mugg. Their 19 pieces are **Boss drop** in Krol'dok Stronghold, not world drops. The nine pieces from the Krol'dok elites, all dropped by Krol'dok Brute, are **Dungeon & Raid trash**. Krol'dok is on the Boss drop and trash flyouts. The three Eye of Mugg quest rewards are pinned at their quest givers in Riverglades. The door has no pin until a coordinate is published. The zone name is translated in every language, including Traditional Chinese.

**More map pins and fixed places**

- 174 more world-drop hunts have real spawn pins, from the creatures Wowhead lists as droppers. 152 world drops have no published spawn and stay unpinned.
- A pin can no longer land on a whole-continent map. Three Stranglethorn Vale world drops are no longer counted as Zul'Gurub.
- **Silkweb Gloves** are filed under Blackrock Depths, pinned at its doors in Searing Gorge and Burning Steppes, not Wailing Caverns.
- **A Tale Spun Around the Fire** (Horde, level 30) shows its five-step Drowned City chain, pinned at the first step in Stranglethorn Vale (32.2, 27.8). It rewards **Ceremonial Mallet**, **Sacrificial Sword**, and **I'lalai Flayer**.

**Creature, vendor, trainer, and quest giver tooltips**

- **Quest givers.** 832 quest-reward items gained their quest giver. **Chief Engineer Bilgewhizzle** in Gadgetzan now lists **Masons Fraternity Ring** for a level 47 hunter.
- **World drops on mobs.** A mob you can attack adds a second header, **Your top world drops from this mob:**, with up to three world drops that beat what you wear. Each world drop's level range has to include the mob's level. Friendly units, players, and pets get none.
- **No freeze on hover.** Hovering a blacksmith trainer used to freeze the game for a moment while 355 crafts were checked. The answer is now remembered until your level, spec, or gear changes.
- **Looted pieces leave at once.** A piece you obtained, or a hunt you removed, leaves those tooltips on the next hover.
- **Inside dungeons** the game still hides a creature's name, so those tooltips add no lines there, and they do not error.
- **Hunt settings → Hide unit gear tips** hides both headers.

**Tooltip score fixes**

- "GearQuest has no score for this item" now reads **GearQuest is not scoring this item for your class.**, because the item is known.
- The **Target random enchant** line wraps, so the tooltip no longer gets very wide.
- **Hunters and warlocks.** Stamina now counts when a worn item is scored from its link, the same as on the hunt list. Before, an upgrade could look bigger than it was.
- **Off-hand weapons.** A worn off-hand weapon scored from its link now counts its full weapon damage, the same as the hunt list. A rogue's or a fury warrior's off-hand row on the score bar read low before.

**Enhancement shaman weights**

Enhancement agility is now **0.65** (was 1.0) and intellect **0.75** (was 0.7). All five Embrace of the Viper pieces stay rank 1 through level 27, and at 28 the whole set leaves the list. **Kodohide Legguards** drop from rank 4 to rank 10 for Horde at 25–27 (rank 9 for Alliance). No other class or spec changed.

**Smoother play**

- The hunt list no longer checks every bag slot for every piece. It reads what you own once, after a bag or gear change.
- Quest log updates only count your completed quests right after a turn-in.
- The memory clean-up after closing the guide, logging in, or switching class in the Simulator runs in small steps instead of one long frame.
- Weapon sorts for casters score each weapon once.
- Bag updates are handled once per frame, and an equipment-set swap updates the score bar once.

**Gamepad**

- On Settings, Lookup, and the Simulator, up and down stay in the column. Down from Language goes to Minimap icon.
- A page never opens on the close button, so A does not close the log by accident.
- The language menu takes the pad, and B closes the menu instead of the log.
- The source filter opens on the first source. Moving onto Boss drop, Trash, Vendor, Quest reward, or Profession opens its list, and it stays open while you are in it. Before, it closed after a fraction of a second.
- Y now also reaches each slot header's (i), Hunts per gear slot, the spec name, and Turn off simulation.

**Languages and other fixes**

- In Russian, Korean, and Chinese, the guide arrow's zone name and the source filter rows no longer draw as empty boxes.
- Dismissing a hunt on the Completed tab removes it at once, and that piece can show on Active again.
- Every new line is translated in all eight GearQuest languages.

### v1.2.1

The window title reads **GearQuest Forever v1.2.1**. GearQuest Forever uses about half the memory of v1.2.0 (a mage went from 99.8 MB to 50.1 MB), with no change to hunts, ranks, pins, or windows. Only the faction on screen is unpacked, and Lookup still searches both. Item stats for custom specs moved to their own addon, **GearQuest Forever: Item Stats**, which loads the first time a custom spec is scored; keep it enabled if you use custom specs. Map pins and the class hunt lists are stored more compactly. Settings → **The GearQuest Community** adds **kaeldrin**.

### v1.2.0

The window title reads **GearQuest Forever v1.2.0**. Each hunt on the Tracked tab has a checkbox that untracks it. Get it now hides a piece you need a profession to wear, such as **Flying Tiger Goggles** without Engineering. **Replica Crescent Necklace** is Alliance only and recommends 25. A two-hander's arrow counts both hands you would replace, including a shield. A worn piece's school spell power and armor count, so **Scaled Cloak of Shadow Wrath** reads about 74 for a shadow priest. Ten new Forever hunts are on the lists, including **Gravetoll Gavel**, **Soulwoven Drape**, and **Predator's Shroud**, and several hunts joined or left a class. **Dreamer's Chestguard** is rare. **Desperate Barrier** and 23 other pieces have less armor. The level-30 Molten Core beta copies, **Invisible Dagger**, and the test items are not hunts.

### v1.1.9

The window title reads **GearQuest Forever v1.1.9**. This is a hotfix. Mousing over a creature in a dungeon no longer throws a Lua error, and the upgrade lines still show when the creature's name can be read. The knight's face pulses gold the first time you open the log, until the guide opens.

### v1.1.8

The window title reads **GearQuest Forever v1.1.8**. A creature, vendor, trainer, or quest giver tooltip lists only pieces that beat what you are wearing, each with the green comparison number. **Disengagement Ring** now shows on Friz Frazzlespark for a hunter at 44.

### v1.1.7

The window title reads **GearQuest Forever v1.1.7**. Weapon rank #1 is the piece that reads 100. **Eyegouger** is Beast Mastery Horde rank #1 at 44. Casters count the best off hand in a one-hander's number. 751 items Forever already listed use the current tooltip, including **Dragon's Eye**, and all nine classes were scored again. Recovered quest hunts list their chains. Hovering a creature, a vendor, a trainer, or a quest giver adds up to three hunt pieces. The Map pin size labels no longer overlap.

### v1.1.6

The window title reads **GearQuest Forever v1.1.6**. A worn piece that is not on your hunt list is scored from its tooltip, so the score bar no longer prints 0 for gear you are wearing. An empty slot is still 0. Hunt names use the tooltip color. The Twisted Evils rewards are the green pieces: Sprightring Helm is rank 5 for Combat at 40–43, Hulkstone Pauldrons are rank 6 for Arms at 40–41, Acumen Robes are rank 9 for Holy at 40–41, and Relentless Chain leaves the Beast Mastery chest list. No Dungeons hides a quest that enters a dungeon. Crafts both factions can make stay on both lists, including Brawler's Leather Hood. Bear prices weapon damage at 4.9, the same as cat. Map pins keep the size you pick when the map zooms. GearQuest adds a launcher for minimap-button collectors. The weight tooltip says Melee weapon DPS and Ranged weapon DPS. On a ding, the weapon lists are walked a few milliseconds at a time.

### v1.1.5

The window title reads **GearQuest Forever v1.1.5**. Crafted hunts Forever names are sourced again: 409 vendors, 101 boss drops, and 20 named creatures. Merchant's Favor leather from Pawani and Daniel Stitchsong, including Brawler's Leather Hood, is a vendor hunt. Veteran's Chain Helm lists the Stockade bosses. Veteran's Silvered Chain Helm is the camp recipe. Guise of Battle is a world drop at 40. Whitemane's Chapeau and Jumanza Grips use the current tooltips. Cat prices weapon damage at 4.9 and bear at 2.52, and an on-hit proc does not fire in form. Scout's Medallion and Sentinel's Medallion require Honored. Settings has a Donations page.

### v1.1.4

The window title reads **GearQuest Forever v1.1.4**. The knight's 13 pages are translated. Guild chat says once when a guild mate runs a newer version. The (i) list writes Equipped and the raw score. Show on map uses TomTom when it is installed and leaves the earlier TomTom pins. Enhancement intellect is 0.7 and is not doubled. Rage of the Storm and the other Tempest's Weapons are shaman only. A crafted hunt with no named seller is Unsourced, with no pin. 37 new Forever pieces are on the lists.

### v1.1.3

The window title reads **GearQuest Forever v1.1.3**. **Save and score items!** scores a custom spec with the numbers you typed, including the classic damage-and-healing line. An off-hand weapon uses the full weapon-damage weight. Healing stays 0 on a damage spec unless you type a number. For a priest, a mage, a warlock, a non-feral druid, and Elemental or Restoration, a one-hander is ranked with the best off-hand. Horde **Brutal Legguards**, **Brutal Gauntlets**, and **Brutal Hauberk** list the Speak with Ruga chain. The pin is the closest of Torm Ragetotem, Sorek, and Baltus Fowler. Brutal Legguards requires 20.

### v1.1.2

The window title reads **GearQuest Forever v1.1.2**. Quest reward adds **Quest chain** and **Single quest**. The parchment header, quest names, chain steps, and story use the selected language. **Stopping the Cycle** and **The Wrath of Rath'mael** keep their real chains. Hunt settings adds **Hide lower ranks** and **Hide map pins**. **No Zephras!** hides Skyborne-only hunts. A worn piece that is not on the list is not an empty slot. Beast Mastery 26–28 keeps the two-handers.

### v1.1.1

The window title reads **GearQuest Forever v1.1.1**. Settings has a Language menu, and GearQuest Forever: Languages carries French, German, Spanish, Latin American Spanish, Portuguese, Russian, Korean, Simplified Chinese, and Traditional Chinese. A fury warrior's off hand is a one-hand weapon from level 20, not a shield. Dungeon and raid trash and each profession use their own picture. Dropped plans point at the drop, not the capital trainer. Lookup stays inside the parchment. The GearQuest Community lists TheWawan.

### v1.1.0

The window title reads **GearQuest Forever v1.1.0**. Their Cities hides the other faction's city dungeons. Quest reward splits into Regular quest and Dungeon quest. 196 new Forever hunts were added, 33 of them quest rewards. Stopping the Cycle lists its eight steps, starting at the Tattered Spellbook in the Wetlands. Lookup, Removed, and tooltips were fixed.

### v1.0.9

The window title reads **GearQuest Forever v1.0.9**. Each hunt shows a small source picture. Horde hides The Stockade and Hall of Thanes. Alliance hides Ragefire Chasm and Ruins of Lordaeron. Hovers use the client tooltip, and the Wowhead Forever tip only when the client has no such item.

### v1.0.8

The window title reads **GearQuest Forever v1.0.8**. Hunt rows are two lines tall, and the parchment shows the full reward name. A quest chain lists every step, and a quest with no earlier step says there are no prequests. **Deviate Scale Belt** is the pattern from Deviate Eradication. A hunter ranks a one-hander in the main hand until Dual Wield at 20. A caster's one-hand rank names the off-hand it is worn with. The right stick opens a paper-doll slot. **Bladewhisper's Namesake** is a new thrown weapon, the Watcher's Signets were renamed, and 140 pieces left the lists.

### v1.0.7

The window title reads **GearQuest Forever v1.0.7**. Settings → The GearQuest Community now shows the current Discord invite, `https://discord.gg/gQSVunBsR`. That is the same link as on the CurseForge addon description. The old invite had expired.

### v1.0.6

The window title reads **GearQuest Forever v1.0.6**. The AddOn List shows the loot sack on GearQuest Forever, the same picture as the minimap button. Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, and Warrior each use that class's icon.

### v1.0.5

The window title reads **GearQuest Forever v1.0.5**. The **Hunts per gear slot** bar matches the hunt list, and a hovered hunt fades out to the right. **Play style** lines up with the parchment. The knight's bubble has no border, the speaker shows one, two, or three lines, and the tail stays on the portrait when the window is larger. Page 4 glows the Weapons filter. Deadlybrew is on **The GearQuest Community**.

### v1.0.4

The window title reads **GearQuest Forever v1.0.4**. **Hunts per gear slot** runs from 3 to 10 at the lower left of the log. The first time you open GearQuest, The GearQuest Knight speaks through 12 pages, with **Yes!** on the first page, a speaker and three volumes, and a gold glow on what he is explaining.

### v1.0.3

The window title reads **GearQuest Forever v1.0.3**. The reward name uses the item's rarity color. A flyout can select or clear every box on that list. A boss drop says **Recommended dungeon entry at level N.** The guide still finds the ship when the client is not English. **Garb of Florid Feathers**, **Raptorclaw Greaves**, **Raptor's Gaze**, **Glinteye Slippers**, **Saltscale Girdle**, and **Supple Bellyskin Leggings** drop in Excavation Site. **Pendulum of Doom** and **Annealed Blade** come from Uldaman. **Axe of Inevitable Ruin**, **Cloudkeeper Legplates**, **Changuk Smasher**, and **Rog'mar Trainee Shoulderpads** are on the lists.

### v1.0.2

The window title reads **GearQuest Forever v1.0.2**. While the log is open in gamepad UI, a gold chevron eases toward the focused control, a blue highlight marks it, and the window gets a soft gold glow. The d-pad and the left stick move through the hunts, the tabs, and Track, Show on map, and Remove. Y opens the filters without applying one. The bumpers change pages. A dark bar under the window names the buttons. The level box and the search box open the on-screen keyboard. Opening a Blizzard window gives that window the pad. **The GearQuest Community** lists Alteredigor.

### v1.0.1

The window title reads **GearQuest Forever v1.0.1**. **Hunts → Recommended gear enchantment** is off until you turn it on. The tooltip then says **Recommended enchantment** in yellow, then the formula and the effect in white, just above the rank line. A quest reward says **Recommended to pick this quest up at level M.** A rogue hunts every one-hand type in both hands. The log could already be opened with a controller.

### v1.0.0

This is the first release. The window title reads **GearQuest Forever v1.0.0**. The score bar says **Your GearQuest Index Score is N Rank**. Off-hand shields follow the source filter. City of Dalaran and the Ruins of Lordaeron name the attunement and the entrance. New Forever hunts include **Serrated Knife**.

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
