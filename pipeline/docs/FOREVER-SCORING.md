# Scoring Forever / Classic items

Player-edited stat weights (not built): [CURSOR-NOTE-PLAYER-WEIGHTS.md](CURSOR-NOTE-PLAYER-WEIGHTS.md).

This folder is the **authoring asset**. Players never see it. CurseForge zips
ignore `pipeline/` (`.pkgmeta`). The addon ships `GearQuest/_generated/*.lua`.

## Philosophy: damage, then survive, then endure

Leveling BiS is not a raid spreadsheet. The model answers “what should I hunt
**now** so I kill faster, die less, and keep playing.” Weights apply in this
order of importance. Do not invert them.

1. **Damage first.** The spec primary still leads: Agility for a hunter,
   Strength for arms, spell power for a mage. A hunt that does not make you
   hit harder (or threaten harder, for a tank) is not BiS. Dual-wield rules,
   weapon style, and “does this proc even fire in this slot” stay in the
   damage layer.

2. **Survivability second (below 60).** A naked +1 primary-stat upgrade that
   leaves you squishy loses to a piece with stamina, health, hp5, or armor.
   `weights_at_level()` multiplies sta / health / hp5 ×3 and armor ×2 when
   `level < 60`. Example: at 22, **Brawler’s / Trapper’s Leather Tunic**
   (8 Agi + stam / str / int) beat **Panther Armor** (9 Agi, no stam).
   Leveling is travel, extra pulls, and no healer. Dying costs more time than
   a one-stat edge saves.

3. **Endurance third (below 60).** Staying effective also means having and
   keeping mana. Int / spirit / mp5 / mana ×2 — real, but **less than stam**.
   Paladin seals and heals, shaman shocks, hunter shots, and caster drinks
   all run out. A glass cannon that is OOM every two pulls is not a better
   hunt.

Level **60** uses the raw raid-scale weights (`GQ_NO_GUIDES=1` until Forever
guides exist). Do not apply the leveling multipliers at 60.

The same multipliers live in the addon as `GQ.ScoringLeveling` in
`GearQuest/_generated/ScoringWeights.generated.lua` (from
`pipeline/data/weights.json` via `scripts/generate-stat-weights-lua.mjs`).
Hovering the spec name or icon in the log shows the **effective** weights
for the current level: below 60 the tooltip already includes ×3 / ×2.
If you change `LEVELING_*` in `score.py`, change `GQ.ScoringLeveling` to
match and regenerate that file. `GQ.StatWeights` is still the Compare.lua
reorder table; the tooltip does not read it.

**Jackpot greens are BiS, not an average.** Rank a random-enchant on the
**best suffix it can roll** (top of that suffix’s range). Superior Shoulders
of Agility at 22 is +6–7 Agi (~9.5%). If +7 would be #1, the item **is** #1.
`suffixChance` tells the player the roll is slim; chance never buries the
hunt. Implemented in `score.py` `best_variant` (`ROLL_POLICY="bestRoll"`).

## Rules that stay unless you ask

**Do not change weights unless asked.** `pipeline/data/weights.json`, the
numbers in `score.py` `weights_at_level()`, and
`GearQuest/_generated/ScoringWeights.generated.lua` stay as they are until
you explicitly ask for a retune. A piece ranking first because of an
existing weight is the model working.

Priest, mage, and warlock ranged damage (`dpsWeightRanged`) is **7**, the
same scale as a warrior's melee weapon. These classes cast, then wand. A
higher-DPS wand is the ranged hunt. **White Obsidian Wand** (274425) is
rank 1 ranged at 39 for mage (including Battle Mage), priest, and warlock
because 7 × 41.47 DPS dominates the slot. Do not lower that weight to bury
the wand. Greater Magic Wand stays the client **17.5** DPS (22–41 Arcane,
+2 spell power, requires 13). Warlock school weights stay as written under
Stat weights: Affliction is shadow, Destruction is fire, Demonology is
generic spell power, and a healing-only line scores as nothing for those
three. Enhancement Tank armor stays **0.20** (0.40 below 60), with one
agility also counting as 2 armor plus dodge and crit.

**A hunt gets a coordinate when one can be found.** Quest start, dungeon or
raid entrance, named creature, vendor, or object. Shared dungeon, farm,
rare, boss, and object pins ignore the faction-zone deny. Do not invent a
pin, a zone center, or a city for a battleground vendor. An Unsourced item
has no pin until a source exists. Ruins of Lordaeron is **Undercity**
(map 1458) at 71.6, 11.4. Patch with
`python pipeline/scripts/index_coordinates.py --ids <json list>`. Do not
full-emit. `emit()` rewrites the whole coordinate file. A source `zone` is
not a pin. The log reads `Data.Coordinates.generated.lua`. A boss drop
whose zone is already a known door still has no **Show on map** until that
file has a row. On 5 Oct 2026, 25 boss drops had the dungeon and no row.
**Embrace of the Viper** (6473 Armor of the Fang, 10410 Leggings, 10411
Footpads, 10412 Belt, 10413 Gloves) now pins Wailing Caverns at The Barrens
46.0, 36.5, the same door as the other cavern hunts. The same pass pinned
Blackened Defias (Deadmines, Westfall 42.5, 71.7), Scarlet chest, legs,
wrists, Mantle of Doan, and Dog Training Gloves (Scarlet Monastery), the
four Gnomeregan boss weapons, Wind Spirit Staff and the two Agamaggan pieces
(Razorfen Kraul), Windshrieker Pauldrons (Stratholme), Emberweave Leggings
(Blackwing Lair), and Ring of Entropy (Lord Kazzak, Blasted Lands 45.3, 55.0).

**A re-score always counts set bonuses.** Embrace of the Viper,
Rotmender's Raiment, and any later `(N) Set` are part of the score for the
specs that wear them. Scoring the pieces on their own stats and skipping
`apply_embrace_package` / `apply_rotmender_package` produces the wrong list.

**Tooltip layout stays the Wowhead line order.** Slot and type are one
double line (`Feet` | `Cloth`), and so are Damage and Speed. The client set
is spliced where the Wowhead set sat. Drop Chance, Requires Level, and
Sell Price stay in the tail. If the stored tip already has `(N) Set`, do
not add the client set again. `Unique-Equipped` splits only when the next
character is not `:` or a space. Random-suffix greens keep the jackpot
tooltip. The hover background is opaque.

**A Wowhead Forever scrape also rechecks Unsourced.** See
[Scraping Wowhead Forever](#scraping-wowhead-forever).

## Embrace of the Viper (set 162)

Forever reworked this Wailing Caverns leather set. The pieces were already
in `items.json` on Classic stats, and the tooltip scrape had 404'd them, so
`forever_missing_ids()` hid every hunt. Stats are the Forever tooltip
(27 Sep 2026): chest is +6 Strength, +4 Stamina, +7 Spirit, not the old
+8/+8.

A piece is still scored alone. After the slot lists exist,
`apply_embrace_package` compares two packages in the same point currency:
the set, and the best item already chosen for each of those slots. If the
set wins, those pieces become the hunt. Bonuses, same weights as printed
stats:

- 2 pieces: +10 Intellect
- 3 pieces: +10 Attack Power
- 4 pieces: 100 health (10 stamina) and 100 mana, once per 5 min at 25% health
- 5 pieces: Dream Venom, a 1-second melee stun. Raid stuns stay worth 0 in
  `procs.py` (bosses are immune). This stun is priced as one second of white
  melee at item level 22, because the proc does not grow with the wearer.

DPS specs only: hunter (all three), rogue (all three), enhancement, feral.
Bear, Balance, Restoration, Elemental, and Enhancement Tank are not on it.

Verified windows, both factions (7 Oct 2026, after Beast Mastery and
Marksmanship melee `dpsWeight` was set to **0.05** and every class was
re-scored from the refreshed tooltips):

- Beast Mastery and Marksmanship: legs, feet, belt, and gloves from 18
  through about 24. **Armor of the Fang is not on the list.** The chest has
  no agility, and Dream Venom is priced at `dpsWeight` 0.05, so the stun is
  almost nothing. Alliance chest rank 1 in that band is **Tunic of Westfall**.
  Horde is **Trapper's Leather Armor**. Do not force the chest back unless
  asked. The hunt text must say the chest is not the hunt.
- Survival: all five through 23. At 24 the legs are what remain.
- Combat, Assassination, Subtlety: all five from 18 through 23.
- Enhancement: all five from 18 through 28. At 29 the chest falls off and
  the other four remain. The 2-piece intellect is why it lasts.
- Feral: all five from 18 through 23. At 24 the chest falls off.

The belt becomes BiS with the set. For Survival, rogues, Enhancement, and
Feral, the chest does too. Gloves (from 14) and legs (from 17) are already
hunts on their own stats. Dream Venom is priced at item level 22, not the
wearer’s level, or Enhancement keeps the chest too long. Feral has no
weapon `dpsWeight`; the stun uses 14 (cat: 1 AP = 1/14 white dps) plus 1
point, so the full set still wins through 23. Do not drop that extra point.

The list tags these rows `(Set piece)`, the same way a proc row is tagged
`(Notable)`. The drop text names the bonuses and the level window for that
class. A druid in all five pieces turns into a serpent (race colors it;
Prowl and Stealth slither). That is flavor on the description, not a stat.

Do not promote a set until the Forever bonus text is known and this package
comparison wins. A single piece is still scored on its own stats. The
package only inserts pieces at rank 1 when the bonuses pay for the slots
you give up. Do not copy a set-bonus line (`+15 Attack Power against
Humanoids`) onto the item’s own stats. `wpnSkill` is 0 on every spec, so
`+1 Daggers` does not move a rank.

**Defias Leather (161),** Deadmines. Forever stats, not the Classic row:
chest is item level 22, requires 17, 89 armor, +4 Strength, +3 Agility,
+10 Stamina. Bonuses: +5 arcane resist, +15 attack power vs humanoids, a
5% behind-only bleed, +1 daggers. Those bonuses do not carry the weak
slots. For Combat, Assassination, and Subtlety, both factions: legs are a
hunt at 14–15, boots at 15–16, then the Fang pieces take those slots.
Chest, gloves, and belt stay off the top 3 even with all five.

**Chain of the Scarlet Crusade (163),** Scarlet Monastery mail. Bonuses:
+10 shadow resist, +30 attack power vs undead, Enraging Light (20 Holy on
melee, 60 vs undead), +1% hit at 5, and a 480 absorb at 20% health on a
4 minute cooldown at 6. Do not price that absorb as 48 permanent stamina.
Pieces that rank do it on their own stats:

- Retribution: belt 32–36, chest 34–39, legs at 39. Gauntlets are in the
  top 3 at 33–34.
- Arms and Fury: belt 32–39, chest 34–39, legs at 39. Gauntlets are in the
  top 3 around 33–34.
- Protection, paladin and warrior: boots 30–36, bracers 31–35, chest 34–39.

The list tags Defias and Scarlet rows `(Set piece)` on the classes above.

**Rotmender's Raiment (2133),** Ruins of Lordaeron cloth. Five pieces,
requires 17-19. Stats are the Forever tooltip (4 Oct 2026). The chest is
Rotmender's Garb, not Robes: +10 Intellect, healing 10 and damage 3.
Leggings are +5 Stamina and +4 mana per 5, not the old intellect and
spirit. Treads are +7 Stamina, healing 15 and damage 5. Gloves are +3
Intellect and +8 Spirit. Sash is +6 Stamina and +6 Intellect. Leggings
drop from The Abandoned, treads from Rath'mael, and the garb has no named
npc. Gloves drop from Stone Watcher. The sash drops from Shrieking Banshee.

`apply_rotmender_package` uses the item-set page. The leggings and treads
tooltips also print an older +10 Intellect at 2 pieces and 5% less threat
at 3. The set page, garb, gloves, and sash do not, so those two lines are
not scored. Bonuses:

- 2 pieces: +5 Shadow Resistance, at the resist weight
- 3 pieces: +10 Intellect
- 4 pieces: 200 mana when mana falls below 15%, once per 5 min. Priced
  like Embrace's 100 mana (the amount, not a permanent aura). The doubled
  restore in Haunted and Wasteland is not in the score
- 5 pieces: a chance to heal 40 every 3 sec for 15 sec. The chance is not
  stated, so one proc is priced as 200 health (20 stamina), not as +200
  healing power

Healer specs only: priest Holy and Discipline, druid Restoration, paladin
Holy, shaman Restoration. A piece is still scored alone. The package
promotes a 4- or 5-piece set only when the bonuses pay for the slots you
give up. Checked 4 Oct 2026, both factions:

- Holy and Discipline: at 18 the chest, sash, gloves, and leggings. At 19
  all five. From 20 the leggings fall off. Chest, sash, and gloves stay
  through 21. The treads stay in the top 3 into the high 20s.
- Restoration druid: all five at 19. On Horde the chest, sash, and gloves
  stay through 21. Treads stay through about 29.
- Restoration shaman: all five at 19. Treads stay through about 29.
- Holy paladin: the treads from 19 through 29. The other four do not beat
  mail and plate.

Smaller sets left on their own stats until the same check: Stormshroud
(rogue energy, about 50), Black Dragon Mail (1% hit at 2 pieces, 2% melee
crit at 3, about 53), Ironfeather (2 pieces, +20 spell power, about 49),
Green Dragon Mail (mana regen, about 47), Imperial Plate (defense, hit,
strength, about 47). Level-60 dungeon sets stay unscored for bonuses.

Set tooltips follow the Wowhead block: the set name and `(0/N)`, one line
per piece, then one line per bonus such as `(2) Set : +10 Intellect.`
The `+N` stays on that bonus line.


**Healing Done is a healer stat.** Holy paladin, Restoration druid, Restoration
shaman, and Holy or Discipline priest score it. Every other spec, including
Elemental, Balance, and Shadow, scores **+Damage Done** as spell power (one
point equals one point of generic spell power) and ignores Healing Done.
School-only damage stays on that school’s weight (Elemental nature is 0.8,
because frost and fire still exist in the kit). Do not add Damage Done and
Healing Done together, and do not count Damage Done twice.

**Three + one.** Top 3 unique names per slot. One notable beside them: a
proc the score cannot price, a leftover jackpot, or a tank-relevant extra
(defense on a caster piece). Notables are not rank 1–3.

**Warrior Protection is physical.** No spell power / healing weight. A glove
with +SP and +healing (Silvered Gauntlets) is not tank BiS even if the stam
is fat. If it also has +Defense, it is the Hands **notable**. Paladin
Protection still scores holy/spell threat; Ret and Enhance stay hybrids.

**Wolfsbane (267369)** is the Horde paladin two-hander from the Diplomatic Incident chain (Danitha Morr, Bandarion Keep, Tirisfal). The quest can be finished at level 20. Wowhead has no Requires Level; the stored level 26 was inferred from item level 31. `client_item_overrides.json` pins required level 20 and Classes: Paladin, so Alliance and other classes do not get it. 25.59 weapon damage is why it is rank 1 for Horde Retribution at 20.

**Enhancement intellect is 0.6 raw.** Mental Dexterity grants 1 attack power per intellect, and the scorer does not convert intellect into attack power on its own. Below 60 the endurance rule doubles intellect, so the lists use **1.2**, just above agility at 1.0. Level 60 keeps 0.6. Spell power stays 0.35 for Mental Quickness and Maelstrom. Enhancement Tank is unchanged and still stamina-first.

**Shaman Enhancement Tank is a hybrid**, like paladin Protection: 1h + shield,
stamina / armor / defense first, then Rockbiter melee threat, then Earth Shock /
Lightning Shield spell threat. Not dual-wield (Forever has no shaman DW).
`enhancement_tank` in `weights.json`. No combat log sim — EP only. Do not
retune tankier vs threatier unless asked.

Armor weight is **0.20** (0.40 below 60). A mail shaman has no plate multiplier, so the armor on the piece is a large part of staying alive while questing. One agility is also **2 armor**, **1% dodge per 20**, and **1% crit per 20**. That is added on top of the listed agility weight, using the same armor weight as armor on the item. Below 60, +6 stamina and +4 agility beats +7 stamina. A much larger stamina gap still wins, which is the early-leveling rule. At 60 the stamina tripling drops off, so agility's armor and dodge are a larger share.

**Mage Battle Mage is a caster who swings.** Three specs, same pillars as every
other class: damage, then survivability, then endurance. Stamina is only a
step above frost (`0.15` vs `0.1`) because the build is usually behind a tank.
`battlemage_frost` is the one scored as the hunt; fire and arcane are the same
skeleton with that school in front.

- Damage is frost / fire / arcane spell power, plus a small weapon DPS weight
  (`0.35`, so a swing is real and still loses to spell power).
- **Coldflame Saber** (276631) is mage-only. The hover is the Wowhead tip:
  17–32 damage, 12.2 DPS, +7 Intellect, requires level 21, Classes: Mage, and
  `Equip: Increases damage and healing done by magical spells and effects by
  up to 32.` That sentence is stored as heal 32 and damageDone 32, never as
  two green `+32 Spell Power` / `+32 Healing Done` lines. 98 Fire on melee
  against Frozen targets. Pinned in `client_item_overrides.json`. The 22 Sep
  nether tip (25–48 damage, 18.25 DPS, no spell bonus) was the stale one; the
  current page matches the client. Do not sync an older cached tip back over it.
- The 98 Fire line is every swing while Frozen, priced at 25% of swings for
  frost battle mage and 15% for fire and arcane (`FROZEN_MELEE_UPTIME`).
  Retune if a melee hit breaks the freeze.
- **Blade of Silverlaine** (273637) is the sword Imbue Blade consumes. Client:
  17–33 damage, 10.9 DPS, +6 Shadow Resistance, +28 spell power and healing.
  It is not mage-locked.
- The log shows the imbued saber. Intellect, spell power, and healing stay
  the normal colors. Only the effect the scroll adds is grey (98 Fire vs
  Frozen). Do not print that effect a second time. Under it:
  `Use: Combine the Blade of Silverlaine and Imbue Blade.`
  Same shape for any later imbue: `Use: Combine the <base weapon> and <scroll>.`
  Register the pair in `CLIENT_IMBUE` (`GearQuest/Data.lua`) and as
  `imbueBase` / `imbueScroll` on the client override. Hovering the grey
  effect still names the scroll.

These rules apply to **every class**. Re-score **one class at a time** after
a rule change. Do not `reemit_all.py` from stale JSON. After a tip sync or
rule change, run `python pipeline/scripts/rescore_hunter_shaman.py` (all nine
despite the name; `GQ_NO_GUIDES=1`). Pass a class name to do one.

**Class lock uses historical set names, then the tip.** Deathmist is warlock,
Virtuous is priest, even when Forever omits `Classes:`. Names only gate class;
stats always come from the Forever tip. `score.py` `family_class_lock` then
`TIP_CLASS_LOCK`.

## Item facts come from Wowhead Forever hunt tips

Ingest **never overwrites** an id that already exists in `items.json`. Classic
pieces that Forever remade (Serpent's Shoulders +9 Agi vs live +5, Marshal's
Chain Legguards +34 Agi and no AP, Jouster's Crest 1051+50 armor) keep stale
stats until you sync.

Scoring reads `items.json`. `foreverAudit.tip` is still stored for class
gates and the random-suffix rebuild. Hovers use that Wowhead Forever tip.
Do not replace it with the client tooltip, and do not paint "Not found in
the client" on the hover. If the client has no such item, the hunt
description may say `Not found in the client yet.` A random-suffix green
keeps the rebuilt jackpot tooltip. A fixed green, including a world drop
or a rare, takes the Forever tip, weapon damage included. An imbued weapon
still greys the scroll effect and adds `Use: Combine the <base> and <scroll>.`

**A tip sync that only walks the Forever index is not a tip sync.** Classic
hunt ids (Ghostly Mantle **3324**, Slime-encrusted Pads **6461**) are not in
`index.json`. `refresh_forever_tips.py` must take every hunt id from the
generated class files **and** the Forever index. Skipping an id because it
is below 200000 leaves the old rebuild hover (`+3 Damage Done` / `+9 Healing
Done` instead of the Equip sentence). Do not run `sync_forever_item_stats.py`
to invent green `+N Damage Done` lines from a rebuild string.

`emit_forever_audit.py` `keep_rebuilt_tip` copies the previous audit line for
a random enchant and Greater Magic Wand **11288**. Those hovers stay the
jackpot tooltip and the client **17.5** DPS wand. Everything else takes the
nether tip. A quality-2 world drop is not a reason to keep the old line.
Heavy Shortbow was still showing classic 17–33 (10.00 DPS) after Forever
had moved it to 10–20 (6.00 DPS). Daryl's Hunting Rifle **2904** is the
Forever gun: 11–21, 6.40 DPS. The classic 18–35 (10.60 DPS) line is a
different item (Blackrock Mace **1296**).

```powershell
python pipeline/scripts/refresh_forever_tips.py
python pipeline/scripts/emit_forever_audit.py
python pipeline/scripts/rescore_hunter_shaman.py
python pipeline/scripts/index_coordinates.py
.\scripts\sync-addon.ps1
```

`index_coordinates.py` is part of the scrape, not a later backfill. A new
hunt id is not finished until that script has stored the full coordinate
list for the item. An existing item is re-indexed only when its places
changed: new droppers, new sellers, a source that was empty, or a quest,
door, or object pin that moved. A stat change, a tooltip rewrite, or a
rename leaves the stored coordinates as they are. When coordinates are
indexed, that is every published camp the pattern under **Map tracking**
keeps, not one pin taken from the page. `NearestCoordinateSpot` then offers
the closest of those spots to wherever the player is standing.

`sync_forever_item_stats.py` dry-run first. `--apply` only when the parse of
known items is sane (Imperial Plate Helm **18/17** Str/Sta, not 38 from the
set bonus; Lionheart **+20 Hit**; Jouster's Crest **1101** armor).

### Client tooltip wins when Wowhead disagrees

A nether tip is not automatically the Forever client. Do not `--apply` a bulk
tip refresh over an id the client has already contradicted.

Pinned in `pipeline/data/client_item_overrides.json`. `sync_forever_item_stats.py`
and `ingest_forever_wowhead.py` skip these ids. `emit_forever_audit.py` paints
the client tip.

| Item | Wowhead nether | Forever client (22 Sep 2026) |
|------|----------------|------------------------------|
| Coldflame Saber (276631) | 25–48 damage, 18.25 DPS, +7 Int, no spell power, rlvl stored as 24 | 17–32 damage, 12.2 DPS, +7 Int, +32 spell power and healing, 98 Fire vs Frozen, requires 21, Classes: Mage. **30 Sep 2026:** Wowhead now serves the same numbers and prints `Equip: Increases damage and healing done by magical spells and effects by up to 32.` The hover uses that sentence. The hand-written `+32 Spell Power` / `+32 Healing Done` lines were wrong and are gone. |
| Blade of Silverlaine (273637) | 26–50 damage, 16.52 DPS, +6 Shadow Resistance, no spell power | 17–33 damage, 10.9 DPS, +6 Shadow Resistance, +28 spell power and healing, requires 21 |

Coldflame is mage-only. After the client stats, it is the mage main hand from
21 until the level-60 raid staves, and it leaves rogue, warrior, and paladin
lists. Silverlaine is not mage-locked; +28 spell power puts it on paladin Holy
and warlock main hands at 21.

**Imbue tooltip.** Printed stats stay the normal colors. Only the effect the
scroll adds is grey. Do not repeat that Equip line from `entry.proc`. Under it:

`Use: Combine the <base weapon> and <scroll>.`

Coldflame: `Use: Combine the Blade of Silverlaine and Imbue Blade.` Register
the next pair in `CLIENT_IMBUE` (`GearQuest/Data.lua`) and as `imbueBase` /
`imbueScroll` on the override. Hovering the grey effect still names the scroll.

**22 Sep index: 3,634.** One new piece ingested: Shapeshifting Sentinel's
Strides (284403), leather feet, level 24, 70 armor, +8 Agility, +16 Attack
Power. Rank 1 feet at 24 for hunter, rogue, feral, and enhancement. Still no
tooltip: Death Prophet Spine (274158), Corsepickers (282012), Slimy Sword
(284702).

**Login chat** is the two welcome lines only. Ring and specialization notices
print when the character crosses that level, then never again on `/reload`.

### Merchant's Favor camps

A lot of the crafted BiS (Brawler's leather, Trapper's leather, Veteran's silvered
mail, Shining / Flame cloth, the enchanting staves and off-hands, the engineering
goggles and belts) is bought as a recipe for Merchant's Favor, then crafted.

| | Horde | Alliance |
|---|---|---|
| Camp | Durotar Supply and Logistics, northwest of the Crossroads in The Barrens | Azeroth Commerce Authority, Three Corners in Redridge Mountains |
| Leatherworking | Pawani | Daniel Stitchsong |
| Blacksmithing | Gor'mak | Stondry Darkhammer |
| Tailoring | Jim'bek | Mivin Shadowweave |
| Enchanting | Beneris | Alynsia |
| Engineering | Fizzlefuse | Fritz Fizzle |

Alchemy (Horde: Apothecary Durelle, Alliance: Nina Surefire) and cooking
(Horde: Aza'bek, Alliance: Kalsey Sanden) stand in the same camps. They do not
make worn gear, so those recipes are not hunt text.

The hunt line is `Crafted with <profession>. You can buy the recipe from <Horde vendor> at <Horde camp>, or from <Alliance vendor> at <Alliance camp>.` The pattern and the crafted piece often use different slot words (Stormrider's Leather Armor and Tunic; Gilded Sandals and Gilded Slippers; Waistcord and Cord). Every piece of those named sets gets the camp sentence (`pipeline/scripts/commerce_camps.py`). Trainer recipes (linen, mageweave, mithril, scorpid, and the rest) stay on the short profession line.

The coordinate for a camp recipe is that vendor, not a capital-city trainer. Horde is The Barrens (map 1413), northwest of the Crossroads. Alliance is Redridge Mountains (map 1433), at Three Corners. The note is `(vendor that sells the recipe)`. One pin per faction.

| Profession | Horde | Alliance |
|---|---|---|
| Leatherworking | Pawani, 49.6, 29.6 | Daniel Stitchsong, 10.0, 72.4 |
| Blacksmithing | Gor'mak, 49.8, 29.6 | Stondry Darkhammer, 10.4, 74.4 |
| Tailoring | Jim'bek, 49.6, 29.4 | Mivin Shadowweave, 10.0, 72.2 |
| Enchanting | Beneris, 49.6, 29.8 | Alynsia, 11.2, 71.4 |
| Engineering | Fizzlefuse, 49.8, 29.6 | Fritz Fizzle, 10.4, 74.2 |

`camp_pins()` in `commerce_camps.py` is the test: the hunt sentence names the camp. A dye word is not enough (Black Mageweave and Golden Scale are trainer crafts). `index_coordinates.py` writes these pins. `enrich_coordinates.py` must not replace them with Stormwind or Orgrimmar.

Index listview rows are not item facts. Veldt is not item facts. A client
tooltip overrides a Forever tip only when it is pinned above. Otherwise the
client tooltip is the fallback when Forever has **no** tip.

### Tip parser pitfalls (nether text is mashed)

Wowhead Forever tips often have no spaces (`1051 Armor17 Block+9 Stamina+50 Bonus ArmorDurability`).

| Trap | Wrong | Right |
|------|--------|--------|
| Set listing / `(N) Set:` bonuses | Imperial Plate Helm 18+20 Str = 38 | `body_only()` cuts at the set header |
| `Restores +4 mana per 5` | miss mp5 | `Restores \+?N mana per 5` |
| `+N Bonus Armor` | 185 Feralheart, or **50** on a 1051 shield | base armor + bonus (185+140=325, 1051+50=1101) |
| `(\d+) Armor\b` | skips `1051 Armor17` (`1` is `\w`, no boundary) | no `\b`; do not take the Bonus Armor digit as base |
| `+20 Hit+28 Crit`, `+9 Defense+60`, `+6 DodgeClasses` | rating dropped | lookahead `+` / `Durability` / `Classes` |
| `re.I` + `(?![a-z])` | `HitDurability` fails (`D` matches `[a-z]`) | do not use case-insensitive letter lookahead |
| Listview armor vs tooltip | PvP 168 vs 128 | trust the hunt tip + bonus armor |
| `+N Damage Done` | ignored | store `damageDone`; `forever_stats()` folds it into SP |

Index listview rows are not item facts. Veldt is not item facts. Unless an id is pinned above, the client tooltip is the fallback only when Forever has **no** tip.

## Hunt tooltip (addon)

Players should see the Wowhead Forever tip, not the client's stale Equip
paragraph.

- **Quality** comes from Forever first (`GetItemQualityForDisplay`). Reinforced
  Woolen Shoulders is **green**, even if `items.json` still says quality 1.
- **Layout:** slot on the left, armor type on the right (`Shoulder | Leather`).
  Same for `Damage | Speed`.
- **Sets:** Wowhead order. Stats, durability, required level, then the set
  name with `(0/N)`, one line per piece, then one line per bonus:
  `(2) Set : +10 Intellect.` Do not tear `+N` onto the next line. The old
  hand-written Viper tip (`Embrace of the Viper(2) Set:` above the level
  requirement) was that bug. `FormatAuditTip` keeps the bonus on the set
  line. A stored tip with real newlines from the nether HTML is the source.
  Client set-bonus overlay only when the bonuses are usable
  (`GetClientSetBlock` / `ApplyClientSetBlock`).
- **No Forever tip** goes to `ShowClientItemTooltip` (`SetItemByID`), then
  `AppendScoredStatLines` from `GQ.Data.scoredStats` for any of armor, str,
  agi, sta, int, spi, sp, heal, ap still missing from that tip. The same
  lines are added to the fact fallback. **Belt of the Stars** (7107) has no
  Forever tip: 117 armor, +6 Strength, +6 Stamina.
  `Data.ScoredStats.generated.lua` must start with `local _, GQ = ...`
  (`GQ` is the addon table, not a global). It loads after ForeverAudit.
- A green random enchant completes on the **full name**, not the base item
  id. `EntrySuffixMatchesLink` compares that name (case-insensitive).
  `of the Bear` is not `of the Falcon`. An exact suffix id is only the
  fallback when the name is not ready. Do not treat a higher suffix id as
  this hunt. `ownedAtLogin` stores the lowercased full name when the link
  contains ` of `, otherwise the item id.
- Keep the Equip sentence `Increases damage and healing done by magical
  spells and effects by up to N`. That sentence **is** the spell power on a
  weapon. Do not strip it (`STALE_EQUIP` is gone). A green `+N Spell Power`
  line is generic spell power only. A party line (`of all party members`)
  is not personal spell power. Set bonuses start with `(N) Set`, not
  `Equip:`, and stay on the set block.

## GearQuest score (tooltip display)

The hunt order is still the stored `pipelineScore`. The number on a tooltip
is a display index only. Do not retune weights so the index and the rank
agree, and do not write the index back onto a pick.

`GearScoreIndex` maps the slot's raw scores onto **−100..+100**. The best
score in that comparison is **+100**. The worst is **−100**. One score in
the slot is **100**. The displayed index is clamped and rounded. The scale
is the live level's rank list (`GetSlotRankList`), the notables, and the
equipped piece's raw score (so a worn piece that has aged out of the band
still sits on the same line). Rank text uses `curatedRank`: **Rank #N for
your level**. A notable says **Notable for your level**.

The line is inside the item tooltip, after the stats, before any addon
source line. `AppendGearScoreLine` runs before `Show()`, so the dark
backdrop grows to include it. It is not a second tooltip. It is not drawn
on hunt-list rows. It is drawn on:

- the hunt hover
- each line of the (i) slot-rank tooltip (`GearScoreTrail`)
- the character panel, including the upgrade hover (above **World drop**
  and **Left-click to see more details.**)
- chat links and quest-log items (`GameTooltip` and `ItemRefTooltip`,
  plus `TooltipDataProcessor` for items)

Bags, quivers, and ammo are skipped. **General → GearQuest score on
tooltips** is on unless `settings.showGearScore` is false. Off hides the
line on item tooltips and the (i) list. The hunt order does not change.

Comparison is `index(hovered) − index(equipped)`, rounded. A positive delta
is the green `GQ-ArrowUp.png` and a green **+N**. A negative delta is the
red `GQ-ArrowDown.png` and a red **−N**. The Forever font has no arrows
(they render as `[]`), and `Interface\BUTTONS\Arrow-Up-Up` is a caret, so
the pictures ship with the addon. An empty slot shows the index only. The
same item, or a delta of 0, shows no arrow. Rings and trinkets compare to
the weaker equipped piece only when **both** slots are filled. A free slot
is a fill, not a replacement.

`EquippedPipelineScore` uses the current band first. If the worn piece has
aged out, it uses the nearest same-spec, same-faction band: the highest
`maxLevel` at or below the player, otherwise the soonest band above.
**Slick Deviate Leggings** (6480) last score for Enhancement Horde at 21–23
(7.11) still compare when worn at 27.

`EntryForItemLink` prefers the suffix, then filters to the active band
(exact min and max, not `LEVEL_GRACE`). A chat link then matches the hunt
list. **Kodohide Legguards** (285338) is rank 4 for Enhancement Horde at
25–27 (score 18.52). **Pathfinder Belt** (15347) is the unsuffixed base;
Enhancement ranks **Pathfinder Belt of the Falcon**.

When the hovered piece is gear and it is not the ranked row, say why
(`GearScoreMissText`) instead of leaving the tooltip blank:

- **Only &lt;Name of the Falcon&gt; is ranked for your level.** (one suffix)
- **Not this roll. Ranked for your level: …** (several)
- **Not ranked at your level. Ranked from N to M.** / **Ranked at level N.**
- **Not ranked for &lt;spec label&gt;.**
- **Not ranked for your class.** / **Not ranked for your faction.**
- **GearQuest has no score for this item.**

Simulation mode does not score. The line is **Turn off simulation mode to
see your GearQuest Score for this item.** The Simulator page button says
**Turn off simulation** (148px). The old preview dialog's Reset is unchanged.

A set piece that is `curatedRank` 1, with `setPiece`, whose own stored
score is below another piece in that slot, adds **Rank 1 when you wear
multiple pieces of this set.** Embrace of the Viper inserts each piece at
the front of the slot (`apply_embrace_package`): the score is the piece
plus an equal share of the set bonus, which does not always beat the next
individual piece. Enhancement Horde legs at 25–27: **Leggings of the Fang**
(10410) rank 1, score 20.87, index 94; **Triprunner Dungarees** (9624)
rank 2, score 21.56, index 100. Fang stays rank 1. Do not change the set
promotion or the weights to make those two numbers match.

## Log window

- **Side handles** are Log (gold exclamation), Simulator (gold question mark,
  stem clear of the dot), and Settings (gold gear). Files are
  `GearQuest/Art/GQ-Handle-Log.png`, `GQ-Handle-Simulator.png`, and
  `GQ-Handle-Settings.png`, 64×64, drawn at 36px in the 53px tab. Hover
  shows `GQ-Handle-InnerGlow.png`: a soft gold rim just inside the metal
  edge. It must not halo the icon. Unselected icons are dimmed
  (0.55, 0.50, 0.42).
- **Active, Completed, and Removed** take a faint gold wash on hover
  (0.90, 0.75, 0.28, alpha 0.14). The selected tab keeps the brighter label.
- The status line uses `GameFontNormalLarge`. **Simulation mode:** is
  `|cffe6bf47` (gold 0.90, 0.75, 0.28). The rest of that sentence,
  **Settings**, and **Viewing upgrades…** are solid `1, 0.97, 0.88` with a
  1px black shadow, so the sky art does not wash them out. The spec control
  on that row is larger: icon 22, arrow 30, label width 130.
- **Turn off simulation** on the Simulator page is enabled only while a
  simulation is applied. On your own character it stays grey. The hover says
  you are already seeing your character unsimulated. The button is 148px.
  The older preview dialog still says Reset.
- **Settings** pages are General, Hunts, GearQuest Commands, and Credits.
  Rows highlight on hover (0.62, 0.50, 0.18, 0.55). The selected row keeps
  its gold bar. The page heading is centered. The setting name is the large
  text; the note under it is smaller. Clicking the label toggles the
  checkbox. Hide minimap is `GearQuestForeverDB.settings.hideMinimapIcon`.
  **GearQuest score on tooltips** is on the General page, under the
  background-art row (`settings.showGearScore`, on when nil).
  **Hide upgrade arrows** is under Hunts
  (`settings.hideUpgradeArrows`). It removes the green arrow from the quest
  log, quest giver, loot, and vendors. **GearQuest Commands** lists each
  slash command with a 1px shadow and the explanation in plain text under it.
- The source **Filter** closes on a click outside the menu. The Profession
  flyout closes when the cursor leaves both the row and the flyout. Boss drop
  has the same flyout, but only for dungeons that have a boss-drop hunt in
  the current level window, including ranks below the top 3. Dungeon & Raid
  trash has the same flyout for trash hunts in that window, and those boxes
  are separate from Boss drop. Hall of Thanes,
  Ruins of Lordaeron, and Excavation Site are dungeons on that list. Other
  is bosses that are not in an instance. The flyouts do not scroll. A cleared box
  stays cleared. Select all / Deselect all on the filter menu covers the source
  list and the profession, boss, and trash sub-filters. Menu text uses the Filter button's font.
  Each main-list row draws the source icon after the checkbox and before
  the name, 18px, the same art as the world-map pin. Flyout rows keep the
  chevron and do not get an icon. The row's hit width includes the icon.
  Checking Profession, Boss drop, or Dungeon & Raid trash opens that flyout
  on the click. You do not have to leave the row and come back.
- **Play style** is the button at the bottom of the log
  (`GearQuestForeverDB.ui`). While any of the five is on, the button reads
  **Play style***. Five cards, three on the first row and two on
  the second. The name sits under the picture. **Get it now!** can be on
  with either dungeon card, and with **Don't look back** and **Buy it**.
  **No Dungeons!** and **Dungeon Enjoyer** turn each other off. A play
  style hides hunts across several sources. The filter still only chooses a source. Any of them widens the slot list the
  same way a filter does, so a later rank can show, and the rank box says why.
  The green arrow on the quest log, quest giver, loot, and vendors is on
  both lists. The unfiltered best pieces keep it when a filter or a play
  style hides them. Every hunt still on the list keeps it too, including a
  later rank, a notable, or a tracked hunt that the filter left showing.
  - **No Dungeons!** (`playNoDungeons`) hides a hunt that sends you into a
    dungeon or raid. Dungeon and raid trash always goes. A boss drop goes
    unless `BossDungeonKey` is **Other** (a world boss stays). A profession
    craft stays. A world drop stays, even when its zone is a dungeon or
    raid name or the pin is that entrance. **Melrache's Cape** drops from
    Captain Melrache in the outdoor graveyard, and the stored zone is
    Scarlet Monastery. A quest goes when its instructions or quest name contain a
    catalog dungeon, or when the pin note says `entrance to dungeon`. The
    match is the catalog spelling, case-sensitive: **Whelgar Excavation
    Site** is not **Excavation Site**. **the Deadmines** is not **The
    Deadmines**, so Underground Assault stays. **Ahn'Qiraj** is not **Ruins
    of Ahn'Qiraj** or **Temple of Ahn'Qiraj**, so Genesis Helm and Savior
    of Kalimdor stay.
  - **Dungeon Enjoyer** (`playDungeonEnjoyer`) is that same test, kept
    instead of hidden. The list is dungeon and raid bosses, trash, and
    quests that enter an instance. World bosses, crafts, vendors, and
    outdoor hunts stay off. The Deadmines and Ahn'Qiraj misses above stay
    off this list too, because they fail the same match.
  - **Get it now!** (`playGetItToday`) hides a hunt this character cannot
    get yet. Reputation uses the standing stored on that item (`reqRep`).
    A bind-on-pickup craft waits until the character has that profession
    and the recipe skill. A bind-on-equip craft stays, unless the item
    itself requires the profession to wear (`reqSkills`). Reaching the
    standing or the skill shows the hunt without turning the style off.
    If the reputation scan fails, reputation hunts stay. A bind type that
    is still unknown does not hide the craft.
  - **Don't look back** (`playDontLookBack`) hides a hunt whose `minLevel`
    would be a gray quest at the effective level. Green and yellow stay:
    hidden when `playerLevel - minLevel` is greater than the green range.
    The live character uses `GetQuestGreenRange()`. A simulated level uses
    the classic steps around the known samples (5 at level 9, 10 at 50,
    12 at 60). A level 18 hunt is still shown at 25 and drops at 26 on
    that scale. A missing `minLevel` stays.
  - **Buy it** (`playBuyIt`) keeps a vendor or auction hunt, and any item
    that is not bind on pickup or quest-bound (bind when equipped, bind
    when used, or no bind). Bind on pickup stays hidden unless a vendor
    sells it. An unknown bind stays. **Get it now!** still hides a vendor
    piece until the stored standing is met.
- **Rank on the parchment.** Above the item title, a black box reads
  `Rank #N` from the stored slot rank (`curatedRank`), so a filtered or
  play-style list still shows the real place. A notable with no stored
  rank uses the scored twin in that slot (same item and minimum level).
  Hovering the box says this is the best, 2nd, 3rd, or 4th in that slot
  for a hunt on the unfiltered, no-play-style list. A hunt that is not on
  that list uses the same line from `curatedRank`, then one sentence: a
  filter is on, a play style is on, or both. Rank 1 says **best**, not
  "1st best". Hunter and Enhancement two-hand say **Two-hand**. A hunter
  main-hand-only weapon says **Main hand**. The box watches the mouse
  itself. A frame inside the parchment scroll child often never receives
  OnEnter.
- Shift-click on a Blizzard map pin still inserts the chat link. Do not call
  `CopyToClipboard`. Open the map with `C_Map.OpenWorldMap`, not
  `ShowUIPanel` or `WorldMapFrame:SetMapID`. The close button is anchored
  `TOPRIGHT` **-6, 1**.
- **Scrollbars** on the hunt list and the parchment sit just outside the
  scroll frame, as children of it. `SetClipsChildren` on that frame hides
  them. Do not clip `GearQuestLogListScrollFrame` or
  `GearQuestLogDetailScrollFrame`. The ScrollFrame already clips its scroll
  child. The bar still hides when the content fits.
- **Remove background art** sits under Hide minimap icon.
  `GearQuestForeverDB.settings.hideLogArt`. Unchecked by default, so the
  class scene is on. Checked restores the plain brown log and the solid
  list fill.

### Class identity scenes

One backdrop per class, `GearQuest/Art/GQ-LogScene-<Class>.png`. `SetTexture`
must include `.png` (without the extension WoW looks for `.blp` / `.tga`).

Only the class you are playing or simulating is `SetTexture`'d
(`LOG_SCENE_TEXTURE` / `LogSceneTexture`). The other eight stay on disk.
Shared overlays, not per class: `GQ-LogScene-Vignette.png` (corner shadow)
and `GQ-ListShade.png` (list darker on the left). Parchment alpha is
**0.72** while a scene is showing.

Do not stretch a scene to the window. The log is 768×512 and the pictures
are wider. `ApplyLogSceneCrop` center-crops using `LOG_SCENE_SIZE` (the
file's real pixels) against the texture rect (frame size minus 2px). A
circle in the art stays a circle. Folder exports are **1024×572** except
**Rogue 1024×559**. Shaman stays the existing **1024×512** file. Do not
replace it with the folder `Shaman.jpg`. Export is color **0.58** and
brightness **0.90** on the native pixels. No non-uniform scale.

`ApplyBlackBackground` calls `SetColorTexture` on `listInset.blackBg`, which
is the same texture as the list shade. `UpdateLogScene` runs after that and
must `SetTexture` the shade again every time a scene is showing. A
"already loaded" flag leaves the list solid black.

### Simulator class rows

The nine class buttons fill `simClassInset`. That frame keeps the same
anchors as the parchment. No scroll. Rows share the inner width (10px pad,
1px gap). The "Classes" title is hidden.

Each row is a center horizontal band of that class's scene
(`ApplySimClassRowCrop`), full width of the picture, top and bottom cut so
the band matches the row. `GQ-ClassRowShade.png` darkens the left (about
the first two-thirds) so the class-colored name reads, and the right side
of the art stays clear. Names use `QuestFont_Super_Huge`.

Those nine files load only while the Simulator tab is open and
`hideLogArt` is off. Leaving the tab clears the textures.

**Do not scan the live client for new items.** `Collector.lua` is gone. Do not
hook `TRAINER_SHOW` / `TRAINER_UPDATE`, call `SetTrainerService`, rebuild the
BiS cache when speaking to a profession trainer, or walk every trainer recipe.
That path exceeded the Lua execution time limit (~90 times) and froze the
client. Item facts come from Wowhead ingest only. BiS arrows still paint on
loot, vendors, quests, and the player's own trade-skill window — not at a
trainer NPC.

## When you find a new or retuned item in Forever beta

Do not hand-edit generated Lua as the long-term fix. Do not hand-edit
`items.json` stats when a Forever hunt tip exists — sync from the tip, then
re-score the class, then copy Lua back.

1. **Item facts** — add or edit `pipeline/data/items.json` keyed by item id
   (string). Copy a nearby item of the same slot and fill:

   | Field | What it is |
   |---|---|
   | `id`, `name`, `slot`, `kind`, `inv` | Identity and inventory type |
   | `quality`, `ilvl`, `rlvl` | Quality, item level, required level |
   | `cls` / `sub` | Item class / subclass (armor, weapon, …) |
   | `allowClass`, `allowRace` | Bitmasks (`-1` = anyone) |
   | `stats` | Named stats the scorer weights (`str`, `agi`, `spFire`, …) |
   | `dps`, `speed` | Weapons only |
   | `effects`, `procs` | Tooltip lines; procs.py prices `Chance on hit` / `Use:` |
   | `randomEnchant` | `true` if it rolls a suffix |

2. **How to get it** — same id in `pipeline/data/sources.json`:

   ```json
   {
     "sourceType": "quest_reward",
     "instructions": "One or two sentences the log can show.",
     "zone": "The Barrens",
     "npc": null,
     "questName": "Quest title",
     "profession": null,
     "dropChance": null,
     "alts": [],
     "gateLevel": 18,
     "questClasses": 0,
     "questRaces": 0,
     "seasonal": false,
     "obtainable": true,
     "excludedBecause": null
   }
   ```

3. **Pool** — append the numeric id to `pipeline/data/classic_item_ids.json`.
   `score.py` only considers ids in that list (TBC/Outland stays out).

   Forever-only items (id ≥ 200000) come from Wowhead `/forever/items`:

   ```powershell
   node scripts/scrape-forever-wowhead-items.mjs
   python pipeline/scripts/ingest_forever_wowhead.py
   ```

4. **Random green?** — scrape Classic/Forever suffix tables, then convert:

   ```powershell
   node scripts/scrape-classic-random-enchants.mjs --ids 12345
   node scripts/convert-classic-random-to-pipeline.mjs
   ```

   Era fingerprint: Vice Grips **9640** must stay **+17 Strength @ 9%**.

5. **Re-score** with the Forever model. One class at a time. `GQ_NO_GUIDES=1`
   is set inside the script. It writes `pipeline/out/` and copies the Lua
   into `GearQuest/_generated/`.

   ```powershell
   python pipeline/scripts/rescore_hunter_shaman.py HUNTER
   .\scripts\sync-addon.ps1
   ```

   All nine classes is the same command with no class name. Do not
   `reemit_all.py` from stale `pipeline/out/*.json`. Do not run a bare
   `score.py` plus `payload.py` plus `emit_early.py` for a Forever list.

   After a Classic `score.py` regen, do **not** run `apply-classic-random-enchants.mjs`
   (that tool patches TBC-scored Lua). Suffixes already come from Classic
   `items_random.json`.

6. **Profession recipe skill.** Do this for every new hunt whose source is
   profession, and again whenever an existing indexed hunt with a profession
   source is updated. The old sentence `requires skill 1` is not a lookup.

   ForeverDB `https://foreverdb.net/data/crafting/{itemId % 64}.json` stores
   `made` as `[profession, spellId, skill, name, count]`. The Wowhead Forever
   item tooltip does not carry the recipe skill. The spell page does:
   `Requires Leatherworking (40)`. When Wowhead is up, confirm the stored
   skill against that line.

   ```powershell
   python pipeline/scripts/fetch_craft_skills.py
   ```

   That rewrites `GearQuest/_generated/CraftSkills.generated.lua` for every
   profession hunt. A skill of 1 is real when ForeverDB and the spell page
   say 1 (Linen Cloak, Copper Bracers, the first leather kits). Do not
   invent 1 when both are empty. Dress Shoes (6836) has no recipe, so the
   parchment line stays off.

Python 3.12 is installed on the authoring PC. A one-off curated row in
`GearQuest/Data.lua` is only for levels 1–9 Alliance bands (see
`docs/DATA_RULES.md`).

## Three picks per slot

Generated lists should **aim for three items in every slot at every level**. A rank 2 or 3 that is a lower-`rlvl` leftover is still a hunt — show it. Empty bands (Horde enhancement Trinket 20–27 before the WSG rune fix) mean the pool was gated out, not that the player should see a blank slot.

`score.py` already considers every eligible item with `rlvl` ≤ the character level. If a slot still has fewer than three picks, chase **source/faction/class gates** and **Wowhead coverage**, then re-score. Do not hand-edit generated Lua as the long-term fill.

## Shared-ID Warsong Gulch runes

`21565`/`21566` Rune of Perfection and `21567`/`21568` Rune of Duty are sold by **both** WSG quartermasters under the **same item IDs**. They are not Alliance-only.

In `pipeline/data/sources.json` those four rows must have `npc: null` and `zone: null`. Instructions name both vendors (Illiyana at Silverwing Grove, Kelm at Mor'shan Base Camp). If `npc` is Illiyana, `npc_ok` + `npc_faction.json` drops every Horde pick and the first Horde trinket becomes Defiler's Talisman **21120** at 28.

Forever nether tooltips have no class restriction — set `allowClass` to `-1`. (A leftover negative mask excluded shaman/druid from Duty.) Unique-Equipped: Rune of Battle (1): list both as alternatives.

After changing those sources, re-score **all nine classes**, not only shaman.

## Re-scrape Wowhead as Forever fills in

The Forever catalog is not finished. Plan **many** scrape → ingest → re-score passes over the coming months:

```powershell
node scripts/scrape-forever-wowhead-items.mjs
python pipeline/scripts/ingest_forever_wowhead.py
python pipeline/scripts/refresh_forever_tips.py
python pipeline/scripts/index_coordinates.py --ids pipeline/data/forever_wowhead/coord_needed.json
node scripts/diff-veldt-wowhead.mjs
```

Then `score.py` one class at a time (`GQ_NO_GUIDES=1`) and copy the emitted Lua into `GearQuest/_generated/`. Ingest does **not** overwrite a source that already names a quest, vendor, drop, or profession. A row whose text is still `Source not listed yet` is replaced when the new listview names one, and that id is written to `coord_needed.json` so the coordinate lookup runs for it. New Forever-only ids (≥ 200000) merge in the same way. Stats on those rows come from the refreshed nether tooltip, not the listview.

Every id that scrape adds is indexed in that same pass with `index_coordinates.py --ids`. An existing id is indexed only when its places changed (new droppers, new sellers, or a source that was empty). A stat change or a tooltip rewrite leaves the stored coordinates as they are. When the index does run, it stores the full camp list for that item, not one coordinate. A world drop keeps a published camp in each zone its creatures live in (up to three when they are far apart, plus a dungeon entrance when a dropper is inside). A vendor keeps every NPC who sells it. The log, the guide, and the map pin then use the spot closest to the character, so a player in any zone is sent to a nearby farm or seller.

Quest Side is the word after `Side:` (`Alliance`, `Horde`, or `Both`). Do not read the end-NPC icon. A both-faction quest gets one pin per faction (Friend of the Library: Garion Wendell in Stormwind for Alliance, Owen Thadd in Undercity for Horde). An Alliance-only quest never scores or displays for Horde, and the reverse. `index_coordinates.py --repair-quests` rewrites those pins and `quest_faction.json`.

`diff-veldt-wowhead.mjs` is **not** a second ingest. It diffs the Wowhead cache against [veldt1 wowf-items](https://veldt1.github.io/wowf-items/) (client `1.60.1` vs `1.15.9`) and writes `pipeline/data/forever_wowhead/veldt_wowhead_diff.json`. Use that to chase empty tooltips and missing Wowhead pages; do not copy veldt stats into `items.json`.

Hunt-id probe (`pipeline/scripts/probe_forever_hunt_tooltips.py`) labels 200 vs 404. Missing classic ids are pruned at runtime; existing items with no combat stats get the datamine notice.

**19 Sep 2026 scrape:** 3,245 → **3,586** Forever items. Ingest **+316** pool ids. All nine classes × every spec re-scored and copied into `GearQuest/_generated/`.

**20 Sep 2026 scrape (morning):** index still **3,586** listview rows. `diff_forever_index.py` found **25** ids in the index that were missing from `items.json` (ingest **+24**; Wildstalker's Helm **280898** 404). Mid-level rares that made a list after re-score: **Silvered Gauntlets** (270025), **Cultist's Armguards** (270032), **Dark Ritual Leggings** (270031). Ilvl-65 set pieces (Manaflare, Grimstitch, Wildstalker, Conviction, Spiritcaller) were scored and did not beat existing 60 lists. `clean_source_instructions.py` rewrote world / quest / vendor / drop copy (no “364 creature types”, zone/NPC live in fields). Hunt parchment no longer dumps the mashed Forever audit tooltip; `QuestFont` was eating spaces — body/title use Friz (`GameFontNormal`). **Source** always prints.

**20 Sep 2026 scrape (evening) + tip sync:** index **3,621** listview rows, **0** new Forever remakes vs the morning catalog. Scoring `items.json` was still Classic/TBC on ~640 hunt pieces. After parser fixes, `sync_forever_item_stats.py --apply` brought those in line (0 dry-run mismatches). Hunt list **3,876** unique ids: **3,858** Forever tips, **18** Classic 404s still on lists (Ten Storms shoulders, Drillborer Disk, Amberseal Keeper, Eskhandar's Left Claw, Will of Arlokk, Staff of the Ruins, The 1 Ring / Woven Copper Ring, and a few unnamed early whites). Historical audit cache still has ~1,500 old 404 rows; current hunt count is the one that matters. Enhancement Tank scored 1–60 with the other shaman specs.

**21 Sep 2026 scrape:** index **3,625** (+4 vs 20 Sep evening). New held-in-off-hand greens: Gnawed Bone (282654), Apothecary's Concoction (284668), Kobold Firestarter (285192), Bael'dun Tankard (286541). Mage / priest / warlock / druid / shaman / paladin re-scored; none beat existing offhand top 3 (mage 22 is already ~6.4 EP). Hunter / rogue / warrior skipped — held offhands are gated once they can dual wield. Live client: Collector removed; class-trainer hooks disabled after a freeze on `TRAINER_UPDATE`.

**23 Sep 2026 scrape:** index **3,637** (same count as 22 Sep; six ids rotated into the list). Ingest **+6** pool ids after fetching missing tooltips. **397** nether tooltips re-fetched where the listview armor/DPS no longer matched `items.json` (mostly PvP / rank-set pieces). Re-ingest merged stats; `client_item_overrides.json` pins untouched. All nine classes × every spec re-scored. New pick on lists: **Death Prophet Spine** (274158) Enhancement shaman MainHand @ 26. Other new ids (274042 belt, 282012 hands, 282019 neck, 282658 back, 284702 sword) scored but did not take top-3 yet.

**27 Sep 2026.** Spec picker is no longer session-only. A manual pick is stored on `GearQuestForeverCharDB.specPick` and survives `/reload`. Talent tree (most points) is used only when this character has not picked a spec. Simulation preview still has its own spec.

**Jewelry and held items with kind `?` do not score.** Wowhead Forever subclasses: neck `-3`, finger `-2`, trinket `-4`, cloak `-6`, held `-5`. `ARMOR_SUB` maps those to `Misc` for **new** rows. Ingest does **not** overwrite `kind` on an id already in `items.json` (`kind` is not in the update field list). Do not mass-edit the leftover `?` rows. Hand-patched only:

- **Snake Eye Kaleidoscope** (273088) neck, `kind` Misc, +1 str/agi/sta/int/spi and `resist` 5. Boss pin: Lady Anacondra, Wailing Caverns. On neck lists from req 17 (level 20 Enhancement Tank Horde: rank 2 behind Scout's Medallion).
- **Heart of Alterac** (283254) held, `kind` Misc. Limited top-3 only (Guardian around 34–39, Destruction and Arcane Battle Mage at 34). Source still unknown. Do not invent a drop.

**Boss pins** live in `pipeline/data/forever_boss_sources.json`. `apply_pinned_boss_sources` runs after `source_from_row`, which would otherwise clear zone and instructions on every id ≥ 200000. A later ingest must keep that call. Ruins of Lordaeron: Witherfang, The Baron, Viktor the Vile, The Abandoned, Bjork, Rath'Mael. Hall of Thanes: Faldrim Anvilmar, Magmatus, Plunder, Durgen Dirgehammer. Kaleidoscope is on the same pin list. Wowhead renamed **Rotmender's Leggings** (271207) and **Rotmender's Treads** (271214).

**Coldflame Saber (276631)** is on the same pin list: `boss_drop`, Baron Silverlaine, Shadowfang Keep. It was `world_drop` with "Source not listed yet" because the listview names no source. The Blade of Silverlaine it is made from drops there too. The log description adds `Use: Combine the Blade of Silverlaine and Imbue Blade.` The hover does not — it stays the Wowhead tip. A re-score reads the pin from `sources.json`, so the generated mage file does not need a hand edit after one.

**Faction zone pins** live in `pipeline/data/forever_faction_zones.json`. `apply_pinned_faction_zones` sets `zone` only. `zone_ok` is what gates the faction; quest text that names Stormwind does nothing if zone is null. Stormwind City and Teldrassil are Alliance. Thunder Bluff is Horde. Wailing Caverns is both.

- 279868 Duty Bound Leggings, 279869 Remembrance Armor → Stormwind City (Bloodied Insignia, General Marcus Jonathan). Horde must not see them.
- 281250 Forest Oracle's Cloak → Teldrassil. `kind` is `Misc`, so it can score.
- 270008 Heat Resistant Mitts, 270009 Safety Boots → Thunder Bluff (Serpentbloom, Apothecary Zamah). Alliance must not see them. Instructions may still mention Wailing Caverns; the displayed zone is what gates.

**Clicks.** Do not parent a fullscreen mouse catcher to `UIParent`. `GearQuestPopupDismiss` exists only under `CharacterFrame`, and hides when that frame hides. Log list and detail scrolls use `SetClipsChildren`. Scroll children are not mouse-enabled. Tracker and log rows outside the visible scroll have mouse off and a shrunk hit rect. Opening the profession book (`TRADE_SKILL_SHOW` / `CRAFT_SHOW`) drops the log from DIALOG to MEDIUM so the book receives clicks. Clicking the log calls `BringLogWindowToFront` and puts it back on DIALOG.

**Chat.** Some `CHAT_MSG_LOOT` / skill lines are secret strings during a boss pull. `ExtractItemIdFromChatMessage` returns before `:find` when `issecretvalue(msg)`.

**Completed tab.** Once `byId` exists, `GetEntryById` must not walk `self.entries` (~467k). A miss is a stale saved id. `CollectCompletedBySlot` walks obtained hunts once. `MarkEntryObtained` does not record every sibling band from `GetEntriesByItemId`.

**Worn gear beside the hunt tooltip.** After the hunt tooltip, `ShowEquippedCompare` fills `ShoppingTooltip1` / `2` from `GetInventorySlots`. Finger 11+12, Trinket 13+14, other slots one. Gold line `Currently equipped`. Empty slot shows nothing.

**Obtain toast is once per item.** `AnnounceObtained` runs only from `MarkEntryObtained`, and only when that item id was not already in `obtainedItems` and was not in `ownedAtLogin`. The first time it is in bags or equipped. Unequip and re-equip must not toast. `ToastReequippedUpgrades` is gone; do not toast from `PLAYER_EQUIPMENT_CHANGED`.

**Spec switch does not scan gear.** `SetSelectedSpec` refreshes the UI and does not call `CheckAutoCompletion`. Completion is by item id (`obtainedItems`). A hunt already completed on this character is completed on the new spec immediately (`IsEntryObtained` checks the item id) and does not toast. A piece you are wearing that was never recorded stays on Active until the next bag update, equip change, or login scan. That scan marks it completed. No toast if `ownedAtLogin` or `obtainedItems` already has the id. A random-enchant hunt still needs the matching suffix.

**Finger gap (Horde, levels 9–14):** curated level-9 rings are Alliance paladin/warrior only. Generated shaman Finger starts at 10 with **The 1 Ring (8350)**, which 404s on Forever and is pruned. Jewelcrafting is not in the Forever client. Woven Copper Ring and the rest of that catalog are not hunts. Horde enhancement rings that exist are Bounty Hunter's Ring (5351, Barrens) and Ring of Scorn (3235, Silverpine) around 15. Do not toast “ring slot eligible” unless `SlotHasHunts("Finger")`.

**28 Sep 2026 (v0.2.15-beta).**

- **Profession book performance.** Do not paint green BiS arrows on the trade skill or craft windows (recipe list or detail icon). Switching profession tabs or crafting used to call `RebuildCache()` on every `TRADE_SKILL_*` event and scan every recipe via `CacheTradeSkillRecipes()` — full-slot rescans on each tab change. Arrows stay on loot, vendors, quests, and loot rolls. `Indicator.lua` only hides profession overlays now; no cache rebuild on profession events.
- **Owned gear and the log.** If you already have a top upgrade in bags or equipped, it is hidden on the **Active** list (less clutter). Auto-complete still records it on **Completed** when you enter that level band or on login scan. Real **`PLAYER_LEVEL_UP`** invalidates bands and runs `CheckAutoCompletion`. Preview / simulator level changes do the same via `Preview:SetLevel` (they do not fire `PLAYER_LEVEL_UP`). Simulator: typing a level only updates the hint until you click **Simulate** (or Enter in the level box); that applies preview and refreshes hunts.
- **Snake Eye Kaleidoscope (273088).** In generated data for all classes/specs from character level 17 while it stays in the top three neck picks for that band; it is not shown below 17. If you are already wearing it, Active hides it; Completed should list it after auto-complete. Re-score is not required for the item itself; `items.json` kind is `Misc`.
- **Horde faction leaks (runtime).** Generated `itemFacts` are keyed by item id only, so Alliance Rune Broker libram copy could appear on Horde rows until the next re-emit. `Data.lua` `EntryMatchesPlayerFaction` hides Alliance-only broker relic ids on Horde (and the mirror on Alliance), denies one-faction **zones** on entries (e.g. Stormwind City on Horde), and tightens backfill / source-filter pools with `EntryMatchesPlayer`. `score.py` `RUNE_BROKER_ALLIANCE` / `RUNE_BROKER_HORDE` gates the next paladin (etc.) re-score so bad rows leave `_generated/`.

**27 Sep 2026 (v0.2.16-beta).**

- **Log header.** `GearQuestWindowTitle` in `Log.lua` is `GearQuest Forever v` plus `GQ.VERSION`. Every release bump of `GQ.VERSION` (and the TOC `## Version:`) updates the band. Do not hardcode a second version string in the title. See `RELEASE.md`.
- **Source filter must not duplicate Completed onto Active.** The same item can exist under several generated hunt ids (level band vs the wide filter pool). `IsItemIdObtained` is true if any hunt id for that item is in `obtained` or a completed hunt, or `obtainedItems`. `ShouldHideFromActiveList` also hides an item whose list key is already on **Completed** for that slot. With a filter on, Active starts from the normal top upgrades / notables / tracked hunts (source-gated), then backfills from `GetFilteredTopForSlot` only while the slot has fewer than 3 rows. Example: level 20 Beast Mastery, World drop unchecked, **Snake Eye Kaleidoscope** stays on Completed only.
- **Filter toggles stay cheap.** Do not bag-scan or walk every sibling hunt id per row in the wide pool. `EnsureActiveListCaches` builds completed keys, obtained item ids, and a bag/equip id set once per class/level/spec/faction. `GetFilteredTopForSlot` uses `EntryHiddenFromActiveFast` and caches per slot until `InvalidateSourceFilterCache`. Checkbox clicks call `ScheduleListRefresh` (debounced), not a synchronous `Refresh` plus a full indicator rebuild in the same frame. `InvalidateQueryCache` also drops the filtered-top cache.
- **`/gq wipe data` then sim up.** Wipe clears character progress, `GearQuestForeverDB.obtainedItems`, and `completedItemBackup`, and sets `completedWipeAt`. Account `obtainedItems` with a timestamp at or before that wipe must not count (`AccountObtainedItemCounts`). Otherwise auto-complete skips pieces the player still wears, and Completed stays empty for them. A jump from 10 to 20 does not pass through earlier bands, so wipe and `Preview:SetLevel` call `ScheduleAutoCompletionCheck(true)`. That path records owned hunts with `minLevel <=` effective level (class/spec/faction via `EntryMatchesTrackedHunt`) and **does not toast**. It looks up `GetEntriesByItemId` for items already in bags. It must not walk `GetClassSlotEntryList`.
- **Toasts are the current list only.** Bag, equip, loot, and a normal level-up call `CheckAutoCompletion()` with no reached-band scan. Complete and toast only top upgrades, the notable, and a tracked hunt that still `EntryMatchesPlayer`. A filter or a play style does not change that list. A rank 6 that is only showing because of a filter does not toast. Tracking it does. Hovering **Track** says so. A level 20 Enhancement shaman looting **Calico Cloak** (level 9 back) must not toast or complete it. Do not treat `GetCandidatesForSlot` as the list. The full catalog walk on `BAG_UPDATE` was the dungeon `Log.lua` "script ran too long" error.

**28 Sep 2026 (v0.2.17-beta).**

- **Spec weight tooltip.** Hover the spec name or icon. `GQ.Compare:ShowScoringWeightTooltip` reads `GQ.ScoringWeights` (pipeline `weights.json`) and applies `GQ.ScoringLeveling` when level &lt; 60. Do not show `GQ.StatWeights` (Compare.lua reorder table). Weapon `dpsWeight` / `dpsWeightRanged` are extra rows. Regenerate with `node scripts/generate-stat-weights-lua.mjs` after a weight edit. `sources.json` must stay ASCII JSON (`ensure_ascii=True`); `score.py` opens it with the Windows default encoding and rejects raw UTF-8.
- **Enhancement intellect.** `weights.json` Enhancement `int` is **0.6**. `weights_at_level` doubles intellect below 60, so those bands score it at **1.2**, above agility **1.0**. Level 60 stays 0.6. The scorer does not turn intellect into attack power; Mental Dexterity lives only in this weight. Enhancement Tank `int` stays 0.4. Shaman was re-scored and `Data.Shaman.generated.lua` plus the early 1–9 file were copied. Do not `reemit_all.py` for this.
- **Wolfsbane (267369).** Horde Retribution main hand rank 1 from level **20 through 26** (score 124 vs Hammerbone 103 at 20). Pin in `client_item_overrides.json`: `rlvl` 20, `tipClasses` Paladin, Holystorm proc text. Source is Diplomatic Incident, Danitha Morr, Bandarion Keep, Tirisfal Glades (`sources.json` `gateLevel` 20). Tirisfal is a Horde zone, so Alliance never sees it. Warrior was re-scored after the class lock so Arms/Fury/Protection no longer list it. Paladin files: `Data.Paladin.generated.lua` and `Data.Paladin.Horde.1to9.generated.lua`.
- **Memory.** Do not list class hunt files in `GearQuestForever.toc`, and do not put those class addons in `## OptionalDeps` (that loads every class before `Core.lua` sets `_G.GearQuest`, so each file errors and the hunt list stays empty). Each class is a load-on-demand addon `GearQuestForever_<CLASS>` (`scripts/stage-class-addons.py` copies the lua and writes `AuditTips.lua`). Login loads the player's class only. `Preview:SetClass` expands the simulated class. Your class and the class on screen keep their expanded rows. Switching to another sim class drops the previous one's expanded rows (`ReleaseIdleHuntClasses`). The addon stays in the memory list until `/reload` (WoW cannot unload it); pick arrays stay so switching back does not rerun the file. The main `foreverAudit` keeps `status` / `name` / `quality` for every item. The long Wowhead `tip` for a class item ships in that class's `AuditTips.lua` and is applied when the class loads, so hunt tooltips stay the Forever text. Curated Data.lua items that are not in a class file keep their tip on the main audit.

**28 Sep 2026 index: 3,693** (26 Sep was 3,678). Fifteen new listview ids. Ingest added the seven that had a nether tooltip: Needletooth's Needletooth (282703), Bloodstained Pants (282713), Denmother's Hide (283253), Arcane Charged Robes (284697), Still Water Band (284699), Wyvern Heart Band (285190), Winds of Tanaris (286556). Eight still 404 and are not in the pool: Wail of Death (281600), Fishscale Hauberk (281891), Unmovable Sabatons (284154), Eternally Frozen Band (284253), Budding Leaf Belt (284382), Faerie Dragon's Skin (284383), Ursol'lok's Paws (284573), Snapped Branch Wand (284574). All nine classes were re-scored. **Wyvern Heart Band** is rank 1 finger from 29 through 37 for Arms, Fury, Retribution, Combat, Subtlety, Survival, and Feral, and through 47 for Assassination. The other six did not take a top-3 slot.

A full ingest rewrites sources.json for every id >= 200000. That cleared 162 zones, including Wolfsbane (Tirisfal / Diplomatic Incident became Old Fire-Eye) and dropped Kaleidoscope's hand-patched resist 5. After ingest, restore every source key that already existed and only add new ids. Keep Kaleidoscope resist 5. Client pins stay skipped. Do not rescore from the wiped sources.

**7 Oct 2026 (v0.3.6-beta). Score the stored row only when it matches the tooltip.**

`refresh_forever_tips.py` is the refresh. It reads the nether Forever tooltip and writes `items.json`. A full ingest is not a refresh: ingest inserts new ids and must not rewrite existing facts from the tooltip cache (that reverted Erudite). Client pins and Greater Magic Wand **11288** stay skipped. On 7 Oct this pass updated **1186** items, then all nine classes were re-scored with `rescore_hunter_shaman.py`. Holy paladin and Beast Mastery / Marksmanship weights in this file are the weights that score used. Do not rescore from a stale row.

**Malignant Root (282283)** is a finger. Alliance Arms and Fury, rank 1 at level **27** only. Source is the rare **Nightveiled Rotheap** in the Wetlands (pins 21.2, 43.2 / 21.9, 43.3 / 23.0, 43.6). Rotheap Inards are party loot at 100%. Turn them in to Rethiel the Greenwarden. The Greenwarden is hostile to Horde, so `questRaces` 77 and `GQ.Data.questFaction[282283] = "Alliance"`. Do not pin the turn-in. The classic nether tooltip 404s, so the reward carries the New in Forever stamp.

**29 Sep 2026 (v0.2.19-beta). Score from the refreshed Wowhead Forever tooltip.**

`pipeline/scripts/refresh_forever_tips.py` re-fetches nether tips for **every
hunt id** (the generated class files) plus the Forever index. The index
alone is not enough: classic ids are absent from it, and that is how Ghostly
Mantle kept a rebuild tooltip. Do not pass a list that is only `index.json`.
`emit_forever_audit.py` runs **before** the re-score, and it keeps the
previous line for jackpot greens and the wand. Then
`rescore_hunter_shaman.py` with `GQ_NO_GUIDES=1` for all nine classes. Do
not `reemit_all.py` from stale JSON. Do not run a full ingest to refresh
tips: a full ingest replaces existing `sources.json` rows for id ≥ 200000.
Restore existing source keys and only append new ids. Re-apply boss pins,
faction zone pins, and `apply_named_drop_kinds` (dungeon bosses stay
`boss_drop`; "(rare spawn)" stays `rare_npc`). Wolfsbane's Tirisfal zone is
hand-maintained. Kaleidoscope (273088) resist 5 must survive a refresh
(`refresh_forever_tips.py` keeps resist when the new parse has none). Client
pins (Coldflame, Silverlaine, Wolfsbane rlvl 20) must not be overwritten by
the nether tip. Greater Magic Wand **11288** is not refreshed: nether still
prints 11.39 DPS. `sources.json` stays ASCII (`ensure_ascii=True`).

**Spell line → stats.** The equal sentence `Increases damage and healing
done by magical spells and effects by up to N` stores **both** `heal=N` and
`damageDone=N`. Do not collapse it to `sp` only. `forever_stats` folds
`damageDone` into `sp` and zeros `damageDone`, so it is not counted twice.
Holy weights: heal 1.0, sp 0.3, `sp_from_heal` 0.3. Mage heal weight is 0
and sp is 1.0, so a mage gets the damage half only. The unequal sentence
`Increases healing done by up to X and damage done by up to Y` is
`heal=X`, `damageDone=Y` (Staff of Westfall: heal 48, damage done 16, from
`rtg41=48` and `rtg42=16`). Nether HTML tags the equal sentence as
`<!--rtg41-->` only. Keep the heal and **add** `damageDone` for that amount.
Skip that special case when `rtg42` is also present, or when the line says
`party`. A green `+N Spell Power` line stays `sp` only. Do not remap every
Spell Power piece into heal.

Checked after the refresh:

| Item | Stored stats | Level |
|---|---|---|
| Staff of Westfall (2042) | int 5, spi 6, heal 48, damageDone 16, 15.17 dps | 14, quest The Defias Brotherhood |
| Golemheart Stave (270228) | sta 3, int 6, spi 5, heal 18, damageDone 18, 11.88 dps | 13, Plunder, Hall of Thanes |
| Fang of Magmatus (271095) | int 4, heal 18, damageDone 18, 7.94 dps | 13, Magmatus, Hall of Thanes |
| Royal Dagger (281297) | int 4, heal 18, damageDone 18, 8.53 dps | 20, Alliance, A Friend of the Family |
| Grave Shroud (279865) | 20 armor, str 3, agi 2, sta 5, kind Misc | 16, both faction quests |

Fang is **not** Holy rank 1. Horde Holy 13–17: Crescent Staff (6505, Leaders
of the Fang, requires 10) is rank 1, Trogg Scepter (272996) is rank 2, Staff
of Orgrimmar (15444) is rank 3. Fang is rank 8 there. Alliance Holy at 13:
Trogg Scepter, Golemheart, Fang. From 14, Staff of Westfall is rank 1.
Frost mage 13–18: Golemheart rank 1, Fang rank 2. Do not pin Fang over
Golemheart.

**Required level is the tooltip, never item level.** `build_item`: if the
tip states `Requires Level` greater than 1, that number is the equip level.
Fang's tip is `<!--rlvl-->13`. It was never gated at item level 18. It
ranked low because spell power was stored as 0. Do not lower a stated equip
level. A quest reward may still be raised when the quest itself opens later
than that line. The hunt level is the higher of the two.

**No required level means look the item up.** Every time an item has no
`Requires Level` (nothing on the tip, or Wowhead's stub of 1), assume it is
a quest reward, or some other source that has a level gate, and look it up
on Wowhead Forever. Do not leave it on the item-level floor (`ILVL_FLOOR`:
ilvl 18 → 13, ilvl 23 → 18, ilvl 24 → 19). That floor is only a stand-in
until the lookup has been done. Find the quest attached to the item. The
**minimum** level required to pick up that quest becomes the item's `rlvl`
and the source `gateLevel`. Several quests: take the lowest. A chain of at least five steps that must enter a dungeon uses that step's quest level when it is at least 8 levels above the pickup. Final Passage (Windstorm Hammer 6804, Dancing Flame 6806) is 36 because Test of Lore in Scarlet Monastery Library is level 36. Mage's Wand (Ragefire Wand 7513, Icefury Wand 7514, Nether Force Wand 11263) is 40 because Rituals of Power is level 40. Confront Yeh'kinya (Faded Hakkari Cloak 20218, Tattered Hakkari Cape 20219) is 58 because The Final Tablets in Blackrock Spire are level 58. Drakefire Amulet (16309) is 60 because General Drakkisath is level 60. Leaders of the Fang stays 10. The Defias Brotherhood stays 14. `eff_req` then
uses `rlvl` when it is &gt; 0.

The dungeon upgrade sets are level **60** quests. Classic **Feralheart**,
**Beastmaster**, **Heroism**, **The Five Thunders**, **Darkmantle**,
**Deathmist**, **Soulforge**, **Virtuous**, and **Sorcerer's** (72 pieces)
were raised from the 58 pickup to required level 60 and gate 60. The Forever
spec copies (144 pieces) are the same quests at 60, not world drops or
vendors, with `questRaces` 0 so both factions see them. Slot to quest:
wrists **An Earnest Proposition**; hands and waist **Just Compensation**;
feet, legs, and shoulders **Anthion's Parting Words**; head and chest
**Saving the Best for Last**. The pin is the start of that chain, An Earnest
Proposition, not the turn-in for the piece. The hunt text is
`Reward from the quest '{quest}'. The chain starts with An Earnest Proposition.`
Leave these out of that retag: the Beaststalker drop set, Beastmaster's
Girdle (5355), Darkmoon Card: Heroism, Uncle's Heroism, Violet Sorcerer's,
Ogre Sorcerer Belt, and Sorcerer Collar. A piece with no quest and item
level 15 or below, and no real Requires Level, is wearable at 1. A higher
item level with no quest stays on the lookup. Do not mark the dungeon sets
wearable at 1.

The item XML `https://www.wowhead.com/forever/item=ID&xml` first `<json>`
CDATA `reqlevel` matches the quest page `Requires level N`. `jsonEquip`
reqlevel is often the stub 1. Ignore it. Quest HTML `Requires level N` is
the pickup level. The scaling `minLevel` is the reward-scale level. Do not
use it. `sourcemore.ti` is the quest id (`t==5`, or source list contains 4).
If the page has no quest, use the real gate for whatever the source actually
is. Do not treat a drop's page level as a quest pickup. Staff of Nobles
(3902) is a drop (source `[2]`, reqlevel 15), not a quest.

`apply_quest_req_levels.py` writes through a `.json.tmp` then `Path.replace`
(`items.json` `write_text` raises `OSError` 22). Cache is
`pipeline/data/forever_wowhead/quest_req_cache.json`. Kris of Orgrimmar
(15443) and Staff of Orgrimmar (15444) are 9 (Hidden Enemies, 5730). Staff
of Westfall stays 14. Grave Shroud stays 16. Fang stays 13. Wolfsbane stays
the pinned 20. The first lookup used a browser user agent and cached HTTP
403 for most rows. Retry those with `wow-classic-data-research/1.0`. Do not
refetch a row that already has `reqlevel`. A cached 403 is not a level.

## Scraping Wowhead Forever

On 5 Oct 2026 the Forever listview and item XML on `www.wowhead.com`
returned HTTP 200 (`node scripts/scrape-forever-wowhead-items.mjs --index`,
then diff against `items.json`). Nether
(`https://nether.wowhead.com/forever/tooltip/item/{id}`) is still the
tooltip. When Nether 404s, the item page
`https://www.wowhead.com/forever/item={id}&xml` has `htmlTooltip`. A 403 is
not an empty source and is not cached as "no pin". ForeverDB
(`https://foreverdb.net`) is the fallback when neither has the fact. The
5 Oct pieces were not in ForeverDB.

Ingest **inserts new ids only**. An existing `items.json` row keeps its
facts. Refreshing every cached tooltip put Erudite's Amulet back to a stale
blue +4 Agility / +6 Stamina and dropped school damage. A source row is
replaced only when the old text is missing or still says
"Source not listed yet" **and** the new row names an npc, a quest, a
profession, or a source type other than world drop or unsourced. A real
boss pin, camp vendor, or hand edit stays.

**Then recheck every item that is still Unsourced.** If the new listview or
the tooltip now names a quest, a vendor, or `Dropped by`, fill that source
(`boss_drop` when the npc is in `dungeon_entrances.json` `bossNpcs`,
otherwise the specific type the page names) and run
`index_coordinates.py --ids` for those ids. On 5 Oct that pass filled 45
placeholder sources and turned tooltip-only droppers (Worgpelt Leggings /
Wolf Master Nandos, and the other named bosses in WC, SFK, RFK, Stockade,
and Scarlet Monastery) into real sources with entrance pins. Thirteen new
items stayed Unsourced because the tooltip named no dropper. Do not call
those world drops.

**Then check every newly indexed id for New in Forever.** Wowhead prints that badge when the id is absent from the classic item database. Probe `https://nether.wowhead.com/classic/tooltip/item/{id}`: HTTP 404 is the badge, HTTP 200 is a classic or Season of Discovery item and stays unstamped. `id >= 200000` is not the test. Privateer's Ornate Pistol (202256) is in that range and is not new. Run `python pipeline/scripts/build_forever_new.py`. It probes only ids missing from `pipeline/data/forever_wowhead/new_in_forever.json` and rewrites `GearQuest/_generated/Data.ForeverNew.generated.lua`. The log draws the burnt Forever mark beside the reward for those ids. Hovering it says "New in Forever".

Re-score with `python pipeline/scripts/rescore_hunter_shaman.py` after new
gear is actually ingested. One class name does one class. Do not
`reemit_all.py` from stale JSON.

`Requires Level` on the tooltip is the equip level. Item level is not.
ForeverDB field `rl` is that same required level. ForeverDB field `il` is
item level. Do not equip from `il`. A stated level greater than 1 is never
replaced. An item with no required level (or Wowhead's stub of 1) is still
looked up, and the hunt level is the source gate, not the item-level floor.

When Nether or www does not have the fact, ForeverDB
(`https://foreverdb.net`) is the source. The files are static. No key.

- `data/items.json` — name, class, subclass, inventory type, quality, `il`, `rl`, stats.
- `data/sources/{id % 64}.json` — drop, quest, and vendor rows.
- `data/questguides/index.json` — `min` is the pickup level. `lv` is the suggested level. Do not use `lv`.
- `data/questguides/{id % 64}.json` — quest giver, faction (`side`), and coordinates.
- `data/rares.json` — rare zone and spawns.
- `data/world.json` — map id to zone name. Type 3 is a zone. Type 2 is a continent.

The browsable lists are `https://foreverdb.net/items?cls=2` (weapons) and
`https://foreverdb.net/items?cls=4` (armor). A new equippable piece is built
from the Nether tooltip plus that ForeverDB row. An item with no inventory
slot (seals, toys, hidden placeholders, a deprecated name) is not hunt gear.

Quest pickup from ForeverDB: Arachnophobia (6284) is min 15 and lv 21. The
Tower of Althalaxx is min 13. A quest source row has `t` `quest` and quest
id `q`. Only fill an item whose `rlvl` is still 0 or 1. Do not lower a
level the tooltip already set.

The hunt zone is the zone, not a place inside it. Tower of Ilgalar is
Redridge Mountains. ForeverDB `data/world.json` pins name that parent, and
an existing coordinate row that sits entirely on one zone map wins over the
area name. An open-world rare stays on both factions' lists when that zone
is the other side's territory, and the rare pin ignores the faction map
deny. A world drop that was already listed under the area name stays listed
after the label becomes the parent zone (`zoneOpen`). Do not rename a
dungeon to the zone its entrance sits in. Do not turn Refuge Pointe or
Alliance. Through level 15 the log shows that faction's own farming pin
and leaves the other faction's zone off the parchment. Above 15 a
world drop stores a published camp in every zone a dropping creature
lives in, up to three spawns per zone when they are far apart, and the
log shows the camp closest to the character. A named creature in that zone stays on
that faction's list. A world drop that was already listed under the area
name stays listed after the label becomes the parent zone (`zoneOpen`).
Do not rename a
dungeon to the zone its entrance sits in. Do not turn Refuge Pointe or
Hammerfall into Arathi Highlands: that name is what keeps the other faction
off those vendors.

**Vendor reputation is a line of its own, just before Source.** A Forever tip
`Requires Booty Bay - Honored` is `reqRep`. The parchment reads
`Requires Honored with Booty Bay. Your standing is Friendly.` The standing
is green (`|cff0c4a1c`) when this character has met it and red
(`|cff6e1212`) when they are short or have not met the faction. The
instructions can still say `Bought from Gezzy Gunkgear. Requires Booty Bay - Honored.`
Souvenier Sea Shell **274749** is that neck. Darkspear Raiders is Horde, so
those pieces are not on the Alliance list. League of Arathor is Alliance.
The Defilers are Horde. Goblin towns (Booty Bay, Ratchet, Gadgetzan,
Everlook) stay on both lists, with the standing written out.

**Blank item kind.** Subclass −2 ring, −3 neck, −4 trinket, −5 held, −6
cloak must be `kind` `Misc` (`ARMOR_SUB`). `kind` `?` makes `eligible()`
reject the piece. A full ingest does not copy `kind` onto existing items.
`refresh_forever_tips.py` sets `kind` `?` to `Misc` for those subclasses.
Weapon subclass `?` (test spears and the like) stays. Grave Shroud was
`kind` `?` and `rlvl` 18 from the ilvl floor. It is now Misc, rlvl 16,
`gateLevel` 16, zone null, instructions naming Alliance **Abominable
Creatures** (95250) and Horde **Unending Torment** (97290). Horde and
Alliance Bear back: rank 1 at 16 (score ~21.15). Levels 19–22 Horde Bear:
rank 3 behind Sporid Cape (6629, 22.0) and Sentry Cloak (2059, 21.4).

**Weapon headers are display-only** (`Data.lua` `WeaponHeaderSuffix`). The
lists stay per slot. `pair_weapon_styles` in `score.py` runs when the slot
is MainHand and the style is `twohand_or_onehand`. Rank 1 stays the best
weapon. Rank 2 is the best weapon of the **other** hand style, so a staff
at rank 1 is followed by the one-hand that Off Hand rank 1 pairs with.
Rank 3+ keeps score order, so a second staff can sit at rank 3 with a
higher score than rank 2. That is intentional for casters. Off hand stays
score-sorted for them. `EntryOffWeaponRoute` is unused. Do not grey the off hand.

**Hunter and Enhancement weapon categories.** The log does not mix them
into one Main Hand list. **Two-hand** is its own block, the best two-handers
by themselves, and it is what the Main Hand paper-doll slot shows. Under it,
hunters get a **Main hand** block of main-hand-only weapons, then an
**Off Hand** slot. Main-hand weapons stay in that list. The Off Hand
character panel bar shows either-hand weapons only (InventoryType 13,
One-Hand), because a main-hand weapon cannot be equipped there. The Off
Hand paper-doll slot is that either-hand list. Enhancement shows the **Two-hand** block only. No one-hand list
and no off-hand list. Forever Enhancement does not dual wield.
Rogue **Main Hand** is tooltip Main Hand only. Rogue **Off Hand** is
One-Hand and Off Hand. An either-hand weapon does not sit under Main Hand.

| Who | Main Hand header | Off Hand header |
|---|---|---|
| Mage, priest, warlock | Staff or main hand | Off Hand |
| Druid, paladin/warrior levelling when a route exists | Two-hand or main hand | Off Hand |
| Enhancement | Two-hand | (no off-hand list) |
| Hunter | Two-hand, then a Main hand list of main-hand-only weapons | Off Hand is either-hand only, and that is the character panel bar. The ranged slot title is **Ranged** |
| Rogue (combat, assassination, subtlety) | Main Hand (tooltip Main Hand) | One-Hand and Off Hand |
| Warrior Fury | Dual wield | Off Hand |
| Paladin Retribution, Warrior Arms | Two-hand | Off Hand |
| Paladin Protection and Holy, Warrior Protection, Shaman Elemental, Restoration, Enhancement Tank | Main Hand | Shield |

Hunter ranged weapons are **Bow, Gun, and Crossbow** only. The slot title
is **Ranged**, the same word a warrior sees, because the list is not only
bows. A thrown weapon does not fire Auto Shot, so `HUNTER`
`_weaponSubclasses` does not include `Thrown`. Houndmaster Boomerang,
Quilrager Throwing Axe, Vicious Throwing Stars, and Assassin's Throwing Axe
are not hunter hunts. Rogue and warrior still list thrown weapons. Do not
put Thrown back on the hunter list.

Ranged DPS, damage, and speed are the Forever tooltip, not a stale stored
number. Beast Mastery and Marksmanship melee `dpsWeight` is **0.05** (they also
melee: Raptor Strike, Wing Clip, Mongoose Bite). Strength is **0** for Beast
Mastery and Marksmanship, and **0.7** for Survival. Levels 1–9 stay at **0.3**.
Their `dpsWeightRanged` is
**14**. Survival melee is **10** and ranged is **6**. Defense on every hunter
spec is **0.02**. A gun with defense and a
lower DPS loses to the higher-DPS bow, gun, or crossbow. Do not retune
defense to bury it. **Hi-tech Supergun** (9487) is not rank 1 at 26 for that
reason. After the 5 Oct 2026 fact pass, level 22 Beast Mastery Horde ranged
is **Alliance Outrunner Bow** (285347, 13.33 DPS, +4 Agility, +3 Spirit),
**Double-barreled Shotgun** (2098), and **Naga Heartpiercer** (3078, same
13.33 DPS; the wound proc is not in `items.json`, so it is not scored).
Notable is **Venomstrike** (6469). **Steelarrow Crossbow** (6315) is 10.88
DPS, 29–45, speed 3.40, +3 Agility, and is not in that top 3. Level 26 Beast
Mastery Horde is **Concealed Hand Crossbow** (273829), **Dun Garok Rifle**
(282710), and **Outrider's Bow** (212585).

Forever Enhancement has no dual wield. Do not label it Dual-wield.
Rogues cannot wear two-hand. Hunters: the bow is its own slot.

**Source filter.** `EntrySourceAllowed` used to return `not hidden[src]`.
A source type with no checkbox is never in `hidden`, so it showed on every
filtered list. The 1 Ring (8350), Steelscale Crushfish (6360), and Broken
Wine Bottle (6651) are `sourceType` `fishing` ("Fished up.") and leaked
onto a Boss drop only list. `GQ:NormalizeSourceType` maps `fishing` and
`skinning` to `profession`, `container` to `object_drop` (the Container
checkbox), and `mail` and `pickpocket` to `special`. While a filter is
active, a type that is still not a checkbox id is hidden. `unknown` stays
on the unfiltered list. `GetSourceLabel` prints Profession, not the raw
string `fishing`. `build_sources.py` stores new fishing and skinning rows
as `profession`. Instructions stay "Fished up." Do not add a Fishing
checkbox.

**Placeholder client names.** `GetItemInfo` returns `Item 23173` when the
Forever client has the id and not the name. `GetItemDisplayName` treats
`Item 23173`, `Item #23173`, and a bare id as missing, then uses the fact
name, then the audit name, then `PROFESSION_ITEM_NAMES`. 23173 is
Abomination Skin Leggings. 6750 is Snake Hoop. Every listed hunt already
has a real name in `items.json`. Do not display `Item` plus the id when
either of those names exists. `Indicator` must not cache the stub.

Set packages were not retuned by the tooltip refresh. Embrace of the
Viper, Defias Leather, and Chain of the Scarlet Crusade stay. Wolfsbane
stays Horde Retribution main hand rank 1 from 20 through 26. Snake Eye
Kaleidoscope keeps resist 5.

Eight Forever index items still have no tooltip and are not ingested:
281600 Wail of Death, 281891 Fishscale Hauberk, 284154 Unmovable Sabatons,
284253 Eternally Frozen Band, 284382 Budding Leaf Belt, 284383 Faerie
Dragon's Skin, 284573 Ursol'lok's Paws, 284574 Snapped Branch Wand. Do not
invent stats.

## Relic effect scoring

Totems/idols/librams often have **no flat stats** — only an Equip line. Without
effect text, `score.py` fell back to `ilvl × 0.01`, which wrongly ranked e.g.
**Totem of Ancestral Protection** above **Polished Driftwood Icon** for elemental.

1. `python pipeline/scripts/patch_relic_effects.py` — copies Equip/Engrave lines
   from `pipeline/data/forever_wowhead/tooltips.json` into `items.json` for
   relics missing `effects`.
2. `relic_score.py` — prices casting mana reg, “increases damage/healing of … by
   up to N”, grounding-totem CD trims (low for elemental), and spec-specific
   rune unlocks. Re-score shaman (or `score_all.py`) after changing weights or
   patterns.

Shaman **relic slot** is stored as pipeline slot **`Ranged`**; the log labels it
**Totem** via `Data.lua`.

## Pick quality checks

- **Forever 404:** `gq_paths.forever_missing_ids()` reads
  `Data.ForeverAudit.generated.lua`; `score.py` / `payload.py` skip those ids.
- **Same display name, different id:** `unique_name_rows` / `unique_picks` keep one
  id per name in the top 3 (PvP rank variants).
- **Audits:** `node scripts/audit-generated-slots.mjs` (overlap bands, short slots,
  duplicate names) and `node scripts/audit-unique-top3.mjs` after large regens.

## What is already wired

- Paths are repo-relative (`gq_paths.py`). No `/home/claude/gq/`.
- Scoring bands are **10–60** (not 69).
- `items_random.json` is converted Classic tables (TBC copy kept as
  `items_random.tbc.json`).
- `check_era.py` asserts Classic Vice Grips, not TBC.
- All nine classes have been re-scored into `GearQuest/_generated/`.

## Stat weights (Forever model)

`data/weights.json` is the Forever combat scale: no expertise / armour pen /
resilience, unified Hit/Crit/Haste, hunter 1 Agi = 1 RAP, 14 AP = 1 DPS, no
Steady Shot, shaman no dual wield. Level 60 is scored from the model
(`GQ_NO_GUIDES=1`); Classic Wowhead BiS guides stay out until we write
Forever ones.

`check_roles.py` enforces the role split: casters carry no str/ap/rap;
physical specs carry no sp/heal except Ret, Enhance, Enhancement Tank, and
Paladin Protection. Warrior Protection is physical (no SP/heal).

### Wand damage

Priest, mage, and warlock `dpsWeightRanged` is **7**, the same scale as a
warrior's melee weapon. These classes cast, then wand. A higher-DPS wand
is the ranged hunt. Greater Magic Wand is the client **17.5** DPS
(22–41 Arcane), not the older 11.39 Wowhead line.

### Warlock schools

Healing Done is not spell damage for Affliction, Demonology, or
Destruction. A line that is only healing scores as nothing. An unequal
"healing up to X and damage up to Y" scores the damage half.

`Increases damage done by Shadow/Fire/Frost/Nature/Arcane/Holy spells`
is that school's spell power. It has to be on the item stats, not only
in the effect sentence.

Affliction is shadow (`spShadow` 0.95, fire near 0). Spirit is raised
because Life Tap scales with it, and crit is real because DoTs can crit.
Demonology prefers generic spell power; shadow and fire are both partial.
Destruction prefers fire (`spFire` 0.95) over shadow (`spShadow` 0.2),
and crit is its highest of the three specs because of Ruin. Hit stays
above crit on all three.

### Holy paladin

Holy levels in melee, then wears mail and, from 40, plate. Shown below 60:
healing, spell power, and holy spell power **1.8**, intellect **1.2** (raw
0.60), spirit **1.5** (raw 0.75; Reverence keeps spirit regen while casting),
mana per 5 **2.2**, flat mana **0.08** (raw 0.04), crit **0.8**, armor
**0.15** (raw 0.075). A line that says `+N Holy Spell Damage` is holy spell
power only, and for this spec it is worth the same as generic spell power.
Cloth is `armorClass` 0.62, leather 0.82, mail 0.96, plate 1.0. A cloth piece
shows up only when its healing pays for the missing armor. Blacksmithing
healing mail and plate (Acolyte's, Prefect's, and the later plate sets)
outrank tailoring cloth of the same band.

### Hunt instructions

`sources.json` `instructions` are one short sentence. Zone, quest name, and
NPC live in their own fields — the log prints them once. World drops:
`World drop around level X-Y.` Quests: `Reward from the quest 'Name'.`
Vendors/bosses: `Bought from X.` / `Drops from X.` Auction House is a
separate BoE line, not repeated inside the sentence.

A crafted hunt states the Forever recipe skill on the line just before
Source: `Requires Leatherworking (155) to craft. Your Leatherworking is 157.`
or `You don't have Leatherworking.` That clause is green when the character's skill is at least the recipe, and red when it is short or the profession is missing. The description does not repeat that
skill. `Crafted with Leatherworking (requires skill 130).` is stripped.
In its place the description lists the recipe materials from the Wowhead
Forever spell tooltip, `Materials: Light Leather (8), Coarse Thread (4).`,
when that spell page has them. `fetch_craft_skills.py --reagents` writes
those onto `GQ.CraftSkills`. Look the skill up for every new
profession hunt, and again when an existing profession hunt is updated.
See step 6 under **When you find a new or retuned item**. The character's
rank is `GetProfessions` / `GetProfessionInfo`, then the skill-line list.
Do not print a stub skill of 1. Dress Shoes (6836) have no Forever recipe,
so that line stays off.

A named dungeon boss is `boss_drop`, even when the old sentence said
"(rare elite)". Mutanus the Devourer is Wailing Caverns, not a world drop.
A generic mob in a dungeon or raid is not a boss. **Druid of the Fang**
drops **Gloves of the Fang**, and that source is `raid_trash`. The log
labels `raid_trash` **Dungeon & Raid trash**, one filter for dungeon trash
and raid trash. Wowhead leaves the boss flag off real bosses (Edwin
VanCleef has none), so a missing flag does not make a boss into trash.
`bossNpcs` stays a boss. A rare that is not on that list is `rare_npc`.
`apply_named_drop_kinds` in the ingest promotes those from
`dungeon_entrances.json` `bossNpcs` and sets the zone to that dungeon.
"(rare spawn)" and a "(rare elite)" that is not one of those bosses is
`rare_npc` ("Rare NPC"). The pin is where that rare spawns. A rare inside a
dungeon uses the entrance. A green from a world drop or a rare keeps the
rebuilt jackpot tooltip. Do not replace that hover with the base Wowhead tip.

**Lookie's Spyglass** (273298) is `boss_drop`, "Drops from Cookie.", zone
The Deadmines, npc Cookie. Do not patch that by replacing the first shared
"Indexed from Wowhead Forever" sentence in a generated file. That sentence
belongs to other items. Patch the spyglass fact line, or re-score from
`sources.json`.

Wowhead HTML tooltips must replace `<br>` / `</div>` with newlines before
stripping tags (`probe_forever_hunt_tooltips.plain`). The log must not
paste `foreverAudit.tip` into the parchment (that is how
`ItemLevel27Bindswhenequipped` happened).

Full write-up: [../../docs/FOREVER-DATA-MIGRATION.md](../../docs/FOREVER-DATA-MIGRATION.md).

## Map tracking

### Coordinate line (built)

The log description prints one coordinate line **below** the Source line
when a pin exists. When a hunt has more than one spot this faction can
use, `NearestCoordinateSpot` picks the closest. The last shown spot stays
until another is at least 20 yards closer, so a camp of spawns does not
swap the line on every step. The guide aims at that same spot. Show on map
opens the zone. Hunt pins are on the world map only.

```
Coordinates: Elwynn Forest 48.2, 42.8 (beginning of the quest or chain)
Coordinates: Ashenvale 61.4, 83.8 more coordinates for this (vendor that sells this)
```

The zone name is part of the line because a dungeon door sits on a different
map than the dungeon. Faction is a filter: the viewer sees their faction
(or the simulated faction) plus neutral spots. "more coordinates for this"
means another valid spot exists for that faction, even when only the first
pin is stored.

`GQ.Data.coordinates` lives in
`GearQuest/_generated/Data.Coordinates.generated.lua`. `Data.lua`
`CoordinateLine` formats it. Rebuild with
`python pipeline/scripts/index_coordinates.py` (resume cache in
`pipeline/data/forever_wowhead/coord_cache.json`). Items with no pin are
listed in `pipeline/data/coordinate_gaps.json`.

Notes by source:

- Quest: where the first step of the chain begins. Walk the Wowhead series
  to that quest and pin its start. A later step's giver is where you
  continue, not the pin. If the first step starts inside a dungeon, pin
  that entrance. Heavehammer's chain starts at Lost Relic Carry (Alliance,
  quest 95810) and Elder Knowledge (Horde, quest 95664), both at the
  Excavation Site door in the Wetlands (47.8, 56.3), not at Whelgar or
  Bashana. Rage of the Storm (280604) and the other Tempest's Weapons
  rewards start at Call of Air: Alliance Ironforge 46.2, 13.0 (94789),
  Horde Orgrimmar 37.4, 37.2 (1531) and Thunder Bluff 24.2, 20.4 (1532).
  Wowhead's Horde series begins at Elemental Aid with Rau Cliffrunner;
  that giver is the next step. `(beginning of the quest or chain)`
- Boss and raid trash: the dungeon or raid entrance, not the boss room.
  `(entrance to dungeon or raid)`
- Vendor: every NPC who sells it. The line shows the seller closest to
  the character. `(vendor that sells this)`
- World drop: a published camp in every zone a dropping creature lives in,
  up to three when they are far apart, plus a dungeon entrance when a
  dropper is inside. The line shows the closest camp. `(a farming spot)`
- World boss with an outdoor pin: `(where this boss spawns)`

Classic dungeon doors are the pre-Cataclysm Questie entrance table (Forever
still uses classic geography). Forever doors with exact numbers: Hall of
Thanes 43.6, 51.7 in Ironforge, Ruins of Lordaeron 71.6, 11.4 in
Undercity, and Excavation Site 47.8, 56.3 in the Wetlands (Wowhead Forever
dungeon guide, zone 11 pin "Entrance to Excavation Site"). These six have a
description only, so nothing is pinned there: City of Dalaran (Alterac
Mountains boundary), The Drowned City (Gillijim's Isle), Krol'dok Stronghold
(Riverglades), Alcaz Prison (Alcaz Island), Blackmaw Hold (northern
Azshara), Shaper's Terrace (northern Un'Goro). Table:
`pipeline/data/dungeon_entrances.json`.

### What could not be indexed (2 Oct 2026)

Of 8,096 hunt items, **5,555** have a line and **2,541** do not. A second
pass filled gaps from the Questie location index
(`pipeline/scripts/enrich_coordinates.py`) and left every pin we already
had in place. That index is not loaded at runtime.

| Source | With a line | Without | Why the rest are missing |
|---|---:|---:|---|
| Boss drop | 663 | 0 | Classic entrance, or the two Forever doors above |
| Profession | 1,082 | 0 | Capital-city trainer for each faction |
| Quest reward | 1,501 | 103 | Starter has no outdoor pin in either index |
| Vendor | 768 | 661 | 257 unnamed; the rest have no outdoor pin |
| World drop | 1,521 | 1,757 | No named creature, and Questie has no classic-map spawn either |
| Object | 15 | 9 | Container was not a named object |
| Container / fishing / mail | 4 | 10 | The container, pool, or mailbox is still unnamed |
| Special | 1 | 1 | Sulfuras uses the Molten Core door; Ashbringer names no quest |

Do not invent a city pin for a battleground vendor, and do not invent
numbers for the six Forever doors above.

### Pins (built)

Tracking a gearquest puts one pin on the world map, the same spot the
coordinate line shows for the viewer's faction. The pin leaves when the
hunt is untracked. The minimap does not draw hunt pins.

`Pins.lua` `PIN_ICONS` is one texture per normalized source, drawn at 24px
on the map and 18px in the filter list. `ApplyIcon` sets the texture. It
does not clear the icon's anchors, so a filter icon keeps its own point.

| Source | Art |
|---|---|
| Boss drop | `Interface\TargetingFrame\UI-RaidTargetingIcon_8` (skull) |
| Container | `Interface\GossipFrame\BankerGossipIcon` (chest) |
| Dungeon & Raid trash | `Interface\TargetingFrame\UI-RaidTargetingIcon_7` (red raid mark) |
| Profession | `Interface\QuestFrame\UI-QuestLog-BookIcon` |
| Quest reward | `Interface\GossipFrame\AvailableQuestIcon` |
| Rare NPC | atlas `nameplates-icon-elite-silver`, else a crop of `UI-TargetingFrame-Rare` |
| Seasonal quest | `Interface\Icons\INV_Holiday_Christmas_Present_01` |
| Special | `Interface\TargetingFrame\UI-RaidTargetingIcon_1` (gold star) |
| Unsourced | `Interface\RaidFrame\ReadyCheck-NotReady` |
| Vendor | `Interface\Cursor\Buy` (the buy-cursor sack) |
| World drop | `GearQuest/Art/GQ-WorldDrop.png` (sunset over dark hills). `Interface\Icons\Spell_Nature_FarSight` is not in this client, so that path draws nothing. |

Fishing and skinning use the profession book. Mail and pickpocket use the
star. A container source uses the chest. `Interface\GossipFrame\VendorIcon`
is not on this client. The world-drop icon is not the micro-button globe:
that texture is a tall button, and a crop of it draws as a dash or as
nothing. It is also not `Spell_Nature_FarSight`: that file is not in this
client, and `SetTexture` on it leaves the pin blank. The sunset is
`GQ-WorldDrop.png` in the addon, and the path includes `.png`.

The guided pin gets a blue ring (`UI-Minimap-Ping-Center`). Other pins do
not. Left-click calls `GQ.Guide:ShowEntry`. Right-click calls
`GQ.Tracker:OpenHunt`, which opens the log on Active and selects that hunt.
The tooltip lines are exactly `Left-click to Guide` and
`Right click to open Hunt`.

The Filter menu draws the same icon after the checkbox and before the
label. Profession, Boss drop, and Dungeon & Raid trash flyout rows do not.
The row hit width includes the icon.

The pin table is ours. Questie is not required in game.

### Guide (built)

`Guide.lua` loads after `Tracker.lua`. One guided hunt per character,
`GearQuestForeverCharDB.guideEntryId`. `settings.hideGuideArrow` is
account-wide and hides the arrow without clearing the id. A logout
countdown (`PLAYER_CAMPING`, cleared again if the player cancels) clears
only `guideEntryId`. `/reload` keeps it. `ReloadUI` and `C_UI.Reload` are
not replaced: `C_UI.Reload` is protected, and a replacement makes the
AddOn List Reload button fail with `Interface action failed because of an AddOn`.
Tracked hunts are not cleared. An old account-wide `settings.guideEntryId`
is dropped on init.

The frame `GearQuestGuide` is anchored `BOTTOMLEFT` of the arrow to
`TOPLEFT` of the tracker, offset `0, 4`. Dragging the arrow calls
`StartMoving` on the tracker. The texture is
`Interface\AddOns\GearQuestForever\Art\GQ-GuideArrow3D.png`, 32 frames in
one horizontal strip. Display size is 110×110. Frame 0 is the tip pointing
forward. `SetTexCoord` selects the frame. `SetRotation` is never called.
Inside 12 yards (`HERE_YARDS`) the text is `Here` and the frame is 16,
which points back at the player.

Aim matches TomTom and HereBeDragons. `atan2(east, north)` is normalized so
0 is north and the angle grows counterclockwise, the same way
`GetPlayerFacing` works. The sprite frames then turn clockwise, so the
bearing is `facing - angle`. `angle - facing` points the wrong way,
including west. If facing is not a number, facing stays 0.

Yards come from `GetWorldPosFromMapPos`. `WorldBasis` samples a step east
and a step north on that map, because world x is not east on every map.
The player delta is projected onto those two axes.

A hunt on another continent aims at the nearest `CROSSINGS` dock on the
player's continent whose destination continent is the hunt's, for the real
`UnitFactionGroup`. The label is the dock, `Ship in Menethil Harbor` or
`Zeppelin in Durotar`, not the word alone. Inside 12 yards it still says
`Here`. The user waypoint
stays on the hunt (`PlaceForeverPin`). On arrival both are on one continent
and the arrow aims at the pin.

| Dock | Faction | Kind | Where |
|---|---|---|---|
| Durotar zeppelin | Horde | Zeppelin | 50.8, 13.6, to Tirisfal and Grom'gol |
| Tirisfal zeppelin | Horde | Zeppelin | 61.0, 59.0, to Durotar |
| Grom'gol | Horde | Zeppelin | Stranglethorn Vale 31.5, 29.6, to Durotar |
| Ratchet | Both | Ship | The Barrens 63.6, 38.7, to Booty Bay |
| Booty Bay | Both | Ship | Stranglethorn Vale 26.0, 73.2, to Ratchet |
| Auberdine | Alliance | Ship | Darkshore 32.7, 43.7, to Menethil north |
| Menethil north | Alliance | Ship | Wetlands 4.7, 57.0, to Auberdine |
| Menethil south | Alliance | Ship | Wetlands 5.0, 63.0, to Theramore |
| Theramore | Alliance | Ship | Dustwallow Marsh 71.0, 56.0, to Menethil south |

Do not invent Stormwind Harbor, Southshore, Steamwheedle, Powderfuse, or
Valanaar. Each tracker row has an **Enable Guide** checkbox. Checking it
calls `ShowEntry`. Clearing it calls `Dismiss`.

### Indexing a new or updated item

Every Wowhead Forever item-database scrape indexes coordinates for each
item it adds, in the same pass as the usual facts: tooltip stats, required
level, source, zone, npc, and quest. An existing item is indexed in that
pass only when its places changed: new droppers, new sellers, a source that
was empty, or a quest, door, or object pin that moved. A stat change, a
tooltip rewrite, or a rename leaves the stored coordinates as they are.
The lookup, when it runs, stores every real spot the pattern below keeps.
It does not store one pin chosen from the page. That list is what lets
`NearestCoordinateSpot` offer a nearby farm or seller to a player standing
anywhere. Also recheck items that are still Unsourced; if Wowhead now
names a source, index those ids the same way. Every new id is also checked
for New in Forever (`build_forever_new.py`) and stamped on the parchment
when the classic nether tooltip 404s. A profession source, new or already
indexed, is also checked for its recipe skill in that same pass
(`fetch_craft_skills.py`, ForeverDB `made`, confirmed on the Wowhead spell
page when it is up). Coordinates are patched with
`python pipeline/scripts/index_coordinates.py --ids <json list>`. A full
`emit()` rewrites every coordinate. The cache is
`pipeline/data/forever_wowhead/coord_cache.json` (gitignored). Use the
research user agent in that script. A Chrome user agent is rejected. An
HTTP 403 is not cached as "no pin"; the next run retries it.

The script writes `GearQuest/_generated/Data.Coordinates.generated.lua`
and `pipeline/data/coordinate_gaps.json`. The toc must keep loading
`Data.Coordinates.generated.lua`, `Map.lua`, and `Pins.lua`. An item that
lands in the gap file ships without a coordinate line. **Show on map**
stays disabled, and hovering it says we are missing exact coordinates.
Do not invent a pin so the button lights up.

What the lookup uses:

- Quest reward: where the first step of the chain begins. Walk the Wowhead
  series to that quest and pin its start. A later step's giver is where you
  continue, not the pin. If the first step starts inside a dungeon, pin
  that entrance. Heavehammer starts at Lost Relic Carry (Alliance) and
  Elder Knowledge (Horde), both at the Excavation Site door. Tempest's
  Weapons starts at Call of Air (Alliance Ironforge 46.2, 13.0; Horde
  Orgrimmar 37.4, 37.2 and Thunder Bluff 24.2, 20.4), not at Rau
  Cliffrunner. Note `(beginning of the quest or chain)`.
- Boss drop and raid trash: the dungeon or raid entrance in
  `pipeline/data/dungeon_entrances.json`, not the boss's room. Note
  `(entrance to dungeon or raid)`. Classic doors are the pre-Cataclysm
  entrance table. Forever doors with numbers are Hall of Thanes
  (Ironforge 43.6, 51.7), Ruins of Lordaeron (Undercity 71.6,
  11.4), and Excavation Site (Wetlands 47.8, 56.3). The other six Forever
  doors have a description and no numbers.
  Leave them unpinned until someone measures the door.
- Vendor: every NPC who sells it, from the Forever sold-by list. Note
  `(vendor that sells this)`. The log, the guide, and the map pin use the
  vendor closest to the character, and a faction-only vendor stays on
  that faction's list. A battleground quartermaster with no outdoor
  pin stays a gap.
- World drop: a published camp in every zone a dropping creature lives
  in, from the Forever dropped-by list. Up to three spawns per zone, and
  only when they sit far apart. A dropper inside a dungeon becomes that
  dungeon's entrance. Note `(a farming spot)`. The log, the guide, and
  the map pin use the camp closest to the character. Spots are not tagged
  by faction, so both sides can farm a contested zone. Through level 15,
  when Wowhead lists no dropper, give each faction one pin already
  published on a mob, not the quest hub (`GENERIC_LOW_FARM`): Kobold
  Vermin in Elwynn Forest 47.4, 35.0 and Mottled Boar in Durotar 41.2,
  64.4 for levels 1–7, Harvest Watcher in Westfall 36.4, 50.4 and
  Plainstrider in the Barrens 47.5, 26.8 for levels 8–15. Above 15, that
  same missing-dropper case uses one shared catalog spot. Do not invent a
  coordinate.
- Profession taught by a trainer: the trainer pin. Note
  `(the trainer that teaches this)`.
- Profession bought at a Merchant's Favor camp: the vendor pin in the camps
  table above, for every leatherworking, blacksmithing, tailoring,
  enchanting, and engineering piece whose hunt sentence names that camp.
  Note `(vendor that sells the recipe)`. Do not put these on Orgrimmar or
  Stormwind. Trainer recipes stay on the trainer pins.
- World boss with an outdoor pin: `(where this boss spawns)`.

Faction is a filter on spots that carry one. A world-drop camp has no
faction, so both sides can farm it. A vendor spot keeps the seller's
faction. Set `more=true` when more than one spot is stored. The log prints
`more coordinates for this` and shows the closest spot. The guide and the
world-map pin use that same closest spot. The other spots stay in the row
so the closest one can change as the character moves. Continent overview
maps (Eastern Kingdoms, Kalimdor, Azeroth, Outland) and an exact 50, 50
center are not coordinates.

`enrich_coordinates.py` only fills gaps. It must not replace a Wowhead pin
or a dungeon door. It does not run on the scrape. Unnamed world drops that
Questie also cannot place stay in `coordinate_gaps.json`.

Show on map opens that zone and sets the user waypoint. Tracked hunts draw
their own frames on the map canvas. They are not registered with the map's
pin pool, and they do not write `WorldMapFrame.pinPools`. Do not
`AddDataProvider`, and do not hook `WorldMapFrame` OnShow. The map's hide
must not run addon code: a data provider, or `Hide()` on a pin while the
map hides, calls `SetPreferredGamepadInteractTarget` and taints gamepad
focus, so jump and talking to an NPC stop working after the map closes.
Pins are placed from the addon's own update only while the map is shown.
The world-drop icon is the addon picture `GQ-WorldDrop.png`. The icon keeps
its size when the map zooms. The same pin is translated onto a continent
map. The minimap does not draw it. The guided pin has the blue ring.
Left-click guides. Right-click opens the hunt. Untrack removes the pin.
Track and Untrack are one button under the reward, beside Show on map.
Exit sits in the footer on the log, the simulator, and settings. The first
time that button is visible and enabled it pulses gold
(`GearQuestForeverDB.ui.trackSeen`), the same wash as Play Style. A greyed
or hidden button does not pulse. The first click sets `trackSeen`. Hover
text on Track is white: `Click to track this hunt. The Guide feature can be enabled.`
Show on map is white too: `See where you can find this on the world map, and let the guide show directions.`
Missing coordinates stay `We are missing exact coordinates for this item.`

The slot-rank list ("Ranked for your level") opens only from the 13×13 info
button on that header. The rest of the header still collapses the slot.
The open panel stays while the cursor is on that header or the panel.

Untrack removes the hunt immediately. There is no confirmation. A filtered
hunt, a hunt outside the top three, and a hunt tracked during a simulation
all untrack the same way.

A simulated character passes `CanPlayerEquip` after the required level.
Weapon skill and `IsEquippableItem` describe whoever is logged in, so a
level 2 would otherwise hide a level 15 hunt. The required level is still
enforced.
