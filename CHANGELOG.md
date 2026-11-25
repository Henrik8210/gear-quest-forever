# Changelog

Forked from [GearQuest](https://github.com/Henrik8210/gear-quest) `v0.1.1-beta.3-bcc` for **World of Warcraft: Forever**.

## v1.3.9

The log header reads **GearQuest Forever v1.3.9**. `/reload` after the update. Every class was scored again, levels 1–60, Alliance and Horde. Ranks move. The spec tooltip shows the new weights.

### Attack power is one stat

**Who:** Every class and spec, including while you simulate.

**What you see:** The spec tooltip lists Attack power and does not list Ranged attack power. A gear line that says ranged attack power is scored as attack power. Hunter attack power is the old ranged weight: **0.45** at levels 1–9, **0.4** for Beast Mastery, **0.38** for Marksmanship, and **0.34** for Survival.

### One percent is one percent

**Who:** Every class and spec, including a custom spec. Spell hit, spell crit, and spell haste use the same hit, crit, and haste weights as a weapon line.

**What you see:** An Equip line that says 2% hit scores as the hit weight times 2. 0.5% scores as times 0.5. Crit, haste, dodge, parry, and expertise work the same way. Chance on hit stays a proc, and a crit line for one spell is still not your crit.

The first percent scale priced 1% hit like about 55 attack power on a Beast Mastery hunter, so a caster neck outranked a hunter neck. Hit was then halved on every spec. 1% hit now sits near 1% crit.

**Level 60 hunter necks:**

- Beast Mastery, Horde: **Mark of Fordring** (In Dreams, 26 attack power and 1% crit) is rank 1, score 21.3. Alliance rank 1 is **Medallion of the Dawn** (21.7), rank 2 is **Mark of Fordring**, rank 3 is **Amulet of the Darkmoon**.
- Marksmanship: the same shape. Horde rank 1 is **Mark of Fordring** (21.8). Alliance rank 1 is **Medallion of the Dawn** (22.2) and rank 2 is **Mark of Fordring**.
- Survival, both factions: rank 1 is **Amulet of the Darkmoon** (27). Alliance rank 3 and Horde rank 2 are **Mark of Fordring** (20).
- **Star of Mystaria** (Balnazzar, 1.3% hit) is Beast Mastery and Marksmanship rank 4 (16.2 and 18.9). Survival Alliance has it at rank 6. **Horn of Ve'han** is Beast Mastery rank 6 (15.4).

Warrior Protection still prices hit at **25** and crit at **42** per 1%. A protection piece with those percents leads on those two stats.

**Feral chest:** **Armor of the Fang** stays rank 1 at 18 for both factions. At 20 the set no longer beats the other leather. Horde rank 1 is **Brawler's Leather Armor**, and the Fang chest is rank 23. It leaves the list at 21. Enhancement still keeps the Fang chest at rank 1 through 24.

### Only Guide Gear includes weapons

**Who:** Level 60, when **Only Guide Gear** is on. Below 60 the card does nothing. It still starts off.

**What you see:** With the card on, the weapon hunt, the weapons (i) list, shields and held off-hand items, the off-hand a caster one-hander is paired with, and the paper-doll upgrade list follow the Wowhead Forever page. A slot the page leaves empty stays the scored list. Retribution's page has no off-hand piece, so the shields stay the scored shields. With the card off, level 60 is still the scored list, and a page piece is labeled (Guide) on the hunt and (Guide #N) on the rank list.

### Ashbringer and Atiesh are not hunts

**Ashbringer** stays off every list until that quest can be finished. The four **Atiesh, Greatstaff of the Guardian** staves stay off until Naxxramas is open: mage, warlock, priest, and druid.

### Weights on the spec tooltip

Hover the spec name. These are the numbers, per 1% for hit, crit, haste, dodge, parry, and expertise. A blank cell is 0, so that row stays off the tooltip. The class stat weight sheet uses the same grid, including Shockadin, Enhancement Tank, and the three Battle Mage columns.

| Class | Spec | Hit | Crit | Haste | Dodge | Parry | Expertise | Attack power |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Paladin | Levels 1–9 | 3.5 | 9.1 | 5.3 | 0.72 | 0.9 | 0.6 | 0.5 |
| Paladin | Retribution | 6.85 | 7.98 | 4.7 | 0.48 | 0.6 | 1.4 | 0.5 |
| Paladin | Protection | 3.25 | 4.9 | 2.5 | 7.8 | 9 | 1 | 0.15 |
| Paladin | Holy | 0.25 | 11.2 | 5 | 0.36 | 0.3 |  |  |
| Paladin | Shockadin | 2 | 7.7 | 3 | 0.48 | 0.6 | 0.6 | 0.1 |
| Warrior | Levels 1–9 | 3.1 | 7.98 | 3.7 | 2.16 | 2.7 | 0.8 | 0.5 |
| Warrior | Arms | 6.75 | 8.4 | 4 | 0.72 | 0.9 | 4.5 | 0.5 |
| Warrior | Fury | 7.25 | 9.1 | 4.5 | 0.72 | 0.9 | 5 | 0.55 |
| Warrior | Protection | 25 | 42 | 1.7 | 7.8 | 9 | 3 | 0.48 |
| Hunter | Levels 1–9 | 6 | 7 | 6.5 | 0.6 |  | 0.6 | 0.45 |
| Hunter | Beast Mastery | 11 | 10.92 | 6.5 | 0.6 |  | 0.4 | 0.4 |
| Hunter | Marksmanship | 11.75 | 11.9 | 6.5 | 0.6 |  | 0.4 | 0.38 |
| Hunter | Survival | 11 | 11.2 | 6.5 | 0.6 |  | 1.2 | 0.34 |
| Druid | Levels 1–9 | 2 | 3.5 | 0.5 | 0.6 |  | 0.4 | 0.12 |
| Druid | Guardian (Bear) | 4.4 | 8.12 | 1 | 8.4 |  | 1.2 | 0.18 |
| Druid | Feral (Cat) | 6.5 | 11.9 | 6 | 1.2 |  | 1.3 | 0.35 |
| Druid | Balance | 6 | 9.8 | 6 | 0.6 |  |  |  |
| Druid | Restoration |  | 4.9 | 4 | 0.6 |  |  |  |
| Shaman | Levels 1–9 | 2 | 7 |  | 0.6 | 0.3 | 0.4 | 0.15 |
| Shaman | Elemental | 6.25 | 10.5 | 6 | 0.6 | 0.3 |  |  |
| Shaman | Enhancement | 7 | 11.9 | 5.5 | 0.6 | 0.3 | 1.4 | 0.55 |
| Shaman | Enhancement Tank | 3.75 | 4.9 | 2 | 7.8 | 8.25 | 1.2 | 0.22 |
| Shaman | Restoration |  | 4.9 | 4 | 0.6 | 0.3 |  |  |
| Rogue | Levels 1–9 | 6 | 7 | 3 | 1.2 | 0.45 | 1 | 0.35 |
| Rogue | Combat | 10 | 11.9 | 6.5 | 1.2 | 0.45 | 1.6 | 0.35 |
| Rogue | Assassination | 9.25 | 12.6 | 8.5 | 1.2 | 0.45 | 1.9 | 0.4 |
| Rogue | Subtlety | 9.25 | 14 | 6 | 1.2 | 0.45 | 1.6 | 0.35 |
| Priest | Levels 1–9 | 2 | 4.2 |  | 0.6 |  |  |  |
| Priest | Holy |  | 5.6 | 4 | 0.6 |  |  |  |
| Priest | Discipline |  | 4.9 | 4 | 0.6 |  |  |  |
| Priest | Shadow | 6.25 | 9.8 | 6 | 0.6 |  |  |  |
| Warlock | Levels 1–9 | 2 | 4.2 |  | 0.6 |  |  |  |
| Warlock | Affliction | 6.25 | 9.8 | 5 | 0.6 |  |  |  |
| Warlock | Demonology | 6.25 | 9.1 | 5 | 0.6 |  |  |  |
| Warlock | Destruction | 6.25 | 13.3 | 5 | 0.6 |  |  |  |
| Mage | Levels 1–9 | 2 | 4.2 |  | 0.6 |  |  |  |
| Mage | Frost | 6.25 | 9.1 | 5.5 | 0.6 |  |  |  |
| Mage | Fire | 6.25 | 11.9 | 5.5 | 0.6 |  |  |  |
| Mage | Arcane | 6.25 | 9.8 | 5.5 | 0.6 |  |  |  |
| Mage | Battle Mage (Frost) | 6.25 | 9.1 | 5.5 | 0.6 |  |  |  |
| Mage | Battle Mage (Fire) | 6.25 | 11.9 | 5.5 | 0.6 |  |  |  |
| Mage | Battle Mage (Arcane) | 6.25 | 9.8 | 5.5 | 0.6 |  |  |  |

### v1.3.8

Only Guide Gear no longer rebuilds the hunt list once a second while you stand still. Turning a play style off gives that extra copy back over about 20 seconds. Closing the guide arrow still does the same. Hunts, ranks, scores, and pins are unchanged.

### v1.3.7

An Equip percent is scored as that percent, on every class and spec, including a custom spec. Chance on hit is a proc. A crit line for one spell is not your crit. Critical strike with spells is still crit. Only Guide Gear is a level-60 play style and starts off. Off, level 60 is the scored list, and a Wowhead Forever page piece is labeled (Guide). Raids that are not open stay off the hunt until 8 December 2026, including the Onyxia and Nefarian head rewards, Quel'Serrar, the green dragons, Lord Kazzak, Azuregos, the Silithus lords, and Ivus. Blackrock Spire stays. Orb of Soran'ruk and Staff of Soran'ruk show for Alliance and Horde. The Web of Magic lists its chain from Sergeant Yohwa. Crafting orders show the recipe and the Auctionator material price. Recommended enchantment wraps onto its own lines. Guiggiani is a top donator.

### v1.3.6

Level 60 guide pages were the hunt for specs with a Wowhead Forever page. Stamina, armor, intellect, spirit, and mana use the sheet number while you level. Removing a hunt hides the row and leaves the rank and the score. Plans: Lionheart Helm drops from Ferra in Dire Maul. Krol'dok Stronghold and Shaper's Terrace have entrance pins. In Dreams starts with Tirion Fordring. Top donators are listed under Donations.

### v1.3.4

A piece stays while it still scores at least a quarter of the best in that slot, and inside the top 30 once you are past its item level. Weapons stay capped at 30. **Heavy Woolen Pants** stay on Affliction through 24 Alliance and 25 Horde. A one-faction zone does not hide a hunt the other faction can get. **Orb of Soran'ruk** is both factions. Right-click a hunt for Track, Add order, Copy name, and Show on map. Thanks **nohemeier**, **cope7736**, and **ja.he**.

### v1.3.3

Level **60** specs with a Wowhead Forever Best in Slot page follow that list, marked **(Guide)**. Dungeon-set upgrades are the level **60** quest chain from **An Earnest Proposition** through **Saving the Best for Last**, pinned on **Deliana** or **Mokvar**. Pattern drops name the creature, including the dragonscale pieces, **Robe of the Archmage**, and the Stormcloth set. **Ancient Giant's Gaze**, **Shadow Scalper**, **Cannibal's Cleaver**, and **Reforged Atal'ai Spear** are new hunts with no pin. **Ward of the Dead** is gone. Lookup can be searched again without leaving the tab. A crafting order that is already on the list says so.

### v1.3.2

Account crafting orders are saved on the account. Collapse and Filter sit above the tabs, and a source header shows a star when a box under it is off. The parchment reward name is white, with the rarity color on the icon border. Holy, Protection, and Retribution price generic spell power and holy spell power the same. **Pauldrons of Vindication** are Alliance only. **Swiftrunner Cape**, **Deadliest Catch**, **Mark of the Pack Leader**, and the **Pioneer Tunic** pin were corrected. The minimap button comes back after login when it is not hidden. The Tooltips window can show when GearQuest is not scoring an item. Boss drops were checked against the Forever dungeon journal.

### v1.3.1

The log header reads **GearQuest Forever v1.3.1**. The **Hunts per gear slot** name is no longer painted on the bar. Hunt ranks are unchanged. **`/reload`** after updating.

### Hunts per gear slot

**Who:** Every class and spec, levels **1–60**, Alliance and Horde, including while you simulate. Mage, warlock, and priest still have no **Armor types** button, so their bar is the full width.

**What you see:** An (i) sits at the left of the slider, the same icon as the slot headers. The number stays on the right, and the slider fills the space between. Hovering the (i), or the slider, says **Hunts per gear slot** and that the list updates when you let go. Rank 1, 2, and 3 stay the best in the slot. The words are not painted on the bar, so a long translation is not cut off. **Armor types** is unchanged.

### v1.3.0

**GearQuest Forever v1.3.0** — **Armor types** beside the hunts bar (cloth classes keep the full bar). World-drop lines are a short list, at most ten a slot. The Tooltips example is **Elder Crag Coyote** with **Icemail Jerkin**, **Blackforge Cowl**, and **Blackforge Bracers**.

### v1.2.9

**GearQuest Forever v1.2.9** — Unit-gear world drops are scored off the hover frame. Hold **Shift** to see the lines. Hunt lists are unchanged.

### v1.2.8

**GearQuest Forever v1.2.8** — NPC tooltips stay cheap until Shift. The Tooltips window wheel scrolls again. The spec hover shows raw sheet weights. Druid Bear hit **0.88**, crit **0.58**, stamina **0.72**. Shaman Enhancement agility **0.6**. Enhancement Tank strength **1.0**.

### v1.2.7

**GearQuest Forever v1.2.7** — **v1.2.5 → v1.2.6** log-open hotfix shipped on CurseForge (`GQ.Log.GQ.Log.*` typos in `Log.lua`); CI guards the doubled prefix. Same hunts as **v1.2.6** if you already patched manually.

### v1.2.5

**GearQuest Forever v1.2.5** — Footer **Tooltips** window; unit tooltip settings; world-drop **%** data; opposite-faction NPC guard; hunter **Dual Wield (20+)** rescoring. **Do not stay on v1.2.5** — the log will not open until **v1.2.6+**.

### v1.2.4

**GearQuest Forever v1.2.4** — **Catalog.lua** lazy-loads hunt rows per query; same hunts, ranks, and saved ids. First install needs a full restart (not `/reload` alone). Thanks **kaeldrin-gh**.

### v1.2.3

**GearQuest Forever v1.2.3** — Unit BiS lines need **Shift**; grey hint when upgrades exist. Hunts unchanged.

### v1.2.2

**GearQuest Forever v1.2.2** — Other-spec tooltip ranks, **No crafted BoP!**, craft recipes, Lookup **(i)**, removed absent raids and client-missing hunts, **Krol'dok**, pins and unit-tip performance, gamepad and font fixes.

### v1.2.1

**GearQuest Forever v1.2.1** — Roughly half the memory of v1.2.0; one faction unpacked; **Item Stats** addon split; compact staging.

### v1.2.0

**GearQuest Forever v1.2.0** — Track / untrack boxes, **Get it now** profession wear, scoring and hunt fixes, new Forever pieces.

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
