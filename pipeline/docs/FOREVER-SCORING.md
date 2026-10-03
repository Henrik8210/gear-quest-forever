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

Verified windows, both factions (27 Sep 2026):

- Beast Mastery and Marksmanship: all five together from 18 to 21. From 22
  the chest falls off and the other four stay through about 24.
- Survival: all five through 23. At 24 the legs are what remain.
- Combat, Assassination, Subtlety: all five from 18 through 23.
- Enhancement: all five from 18 through 28. At 29 the chest falls off and
  the other four remain. The 2-piece intellect is why it lasts.
- Feral: all five from 18 through 23.

The chest and the belt become BiS with the set. Gloves (from 14) and legs
(from 17) are already hunts on their own stats. Dream Venom is priced at
item level 22, not the wearer’s level, or Enhancement keeps the chest too
long. Feral has no weapon `dpsWeight`; the stun uses 14 (cat: 1 AP = 1/14
white dps).

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
`enhancement_tank` in `weights.json`. No combat log sim — EP only; retune
tankier vs threatier in the weights if play disagrees.

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
gates and the random-suffix rebuild. Every hover except a green world drop
or a green rare uses that Wowhead tip. Do not replace it with the client
tooltip, and do not paint "Not found in the client" on the hover. If the
client has no such item, the hunt description may say `Not found in the
client yet.` Green world drops and green rares keep the rebuilt jackpot
tooltip. An imbued weapon still greys the scroll effect and adds
`Use: Combine the <base> and <scroll>.`

**A tip sync that only walks the Forever index is not a tip sync.** Classic
hunt ids (Ghostly Mantle **3324**, Slime-encrusted Pads **6461**) are not in
`index.json`. `refresh_forever_tips.py` must take every hunt id from the
generated class files **and** the Forever index. Skipping an id because it
is below 200000 leaves the old rebuild hover (`+3 Damage Done` / `+9 Healing
Done` instead of the Equip sentence). Do not run `sync_forever_item_stats.py`
to invent green `+N Damage Done` lines from a rebuild string.

`emit_forever_audit.py` `keep_rebuilt_tip` copies the previous audit line for
a random enchant, a quality-2 world drop, a quality-2 rare, and Greater
Magic Wand **11288**. Those hovers stay the jackpot tooltip and the client
**17.5** DPS wand. Everything else takes the nether tip.

```powershell
python pipeline/scripts/refresh_forever_tips.py
python pipeline/scripts/emit_forever_audit.py
python pipeline/scripts/rescore_hunter_shaman.py
python pipeline/scripts/index_coordinates.py
.\scripts\sync-addon.ps1
```

`index_coordinates.py` is part of the scrape, not a later backfill. A new or
updated hunt id is not finished until that script has looked for its
coordinate. The rules are under **Map tracking** below.

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

## Log window

- **Settings** is the third side handle (cog, `Interface\Icons\Trade_Engineering`).
  Simulator stays the red question mark. The page heading is centered. The
  setting name is the large text; the note under it is smaller and not bold.
  Clicking the label toggles the checkbox. Hide minimap is
  `GearQuestForeverDB.settings.hideMinimapIcon`.
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

5. **Re-score** (needs Python 3, run from `pipeline/scripts`):

   ```powershell
   $env:GQ_CLASS = "HUNTER"
   $env:GQ_GUIDES = "guides_hunter.json"
   $env:GQ_OUT = "hunter.json"
   python score.py
   python payload.py
   python emit_early.py
   ```

   Copy the emitted Lua into `GearQuest/_generated/` (`python reemit_all.py` copies
   `pipeline/out/` → `GearQuest/_generated/`), then sync the game folder:

   ```powershell
   node scripts/verify-generated-bis.mjs
   .\scripts\sync-addon.ps1
   ```

   All nine classes at once (Forever model, `GQ_NO_GUIDES=1`):

   ```powershell
   python pipeline/scripts/rescore_hunter_shaman.py
   .\scripts\sync-addon.ps1
   ```

   One class: `python pipeline/scripts/rescore_hunter_shaman.py SHAMAN`.
   Do not `reemit_all.py` from stale `pipeline/out/*.json` after a tip sync.

   After a Classic `score.py` regen, do **not** run `apply-classic-random-enchants.mjs`
   (that tool patches TBC-scored Lua). Suffixes already come from Classic
   `items_random.json`.

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
- 281250 Forest Oracle's Cloak → Teldrassil. Still `kind` `?`, so it does not score until that is patched on purpose.
- 270008 Heat Resistant Mitts, 270009 Safety Boots → Thunder Bluff (Serpentbloom, Apothecary Zamah). Alliance must not see them. Instructions may still mention Wailing Caverns; the displayed zone is what gates.

**Clicks.** Do not parent a fullscreen mouse catcher to `UIParent`. `GearQuestPopupDismiss` exists only under `CharacterFrame`, and hides when that frame hides. Log list and detail scrolls use `SetClipsChildren`. Scroll children are not mouse-enabled. Tracker and log rows outside the visible scroll have mouse off and a shrunk hit rect. Opening the profession book (`TRADE_SKILL_SHOW` / `CRAFT_SHOW`) drops the log from DIALOG to MEDIUM so the book receives clicks. Clicking the log calls `BringLogWindowToFront` and puts it back on DIALOG.

**Chat.** Some `CHAT_MSG_LOOT` / skill lines are secret strings during a boss pull. `ExtractItemIdFromChatMessage` returns before `:find` when `issecretvalue(msg)`.

**Completed tab.** Once `byId` exists, `GetEntryById` must not walk `self.entries` (~467k). A miss is a stale saved id. `CollectCompletedBySlot` walks obtained hunts once. `MarkEntryObtained` does not record every sibling band from `GetEntriesByItemId`.

**Worn gear beside the hunt tooltip.** After the hunt tooltip, `ShowEquippedCompare` fills `ShoppingTooltip1` / `2` from `GetInventorySlots`. Finger 11+12, Trinket 13+14, other slots one. Gold line `Currently equipped`. Empty slot shows nothing.

**Obtain toast is once per item.** `AnnounceObtained` runs only from `MarkEntryObtained`, and only when that item id was not already in `obtainedItems` and was not in `ownedAtLogin`. The first time it is in bags or equipped. Unequip and re-equip must not toast. `ToastReequippedUpgrades` is gone; do not toast from `PLAYER_EQUIPMENT_CHANGED`.

**Spec switch does not scan gear.** `SetSelectedSpec` refreshes the UI and does not call `CheckAutoCompletion`. Completion is by item id (`obtainedItems`). A hunt already completed on this character is completed on the new spec immediately (`IsEntryObtained` checks the item id) and does not toast. A piece you are wearing that was never recorded stays on Active until the next bag update, equip change, or login scan. That scan marks it completed. No toast if `ownedAtLogin` or `obtainedItems` already has the id. A random-enchant hunt still needs the matching suffix.

**Finger gap (Horde, levels 9–14):** curated level-9 rings are Alliance paladin/warrior only. Generated shaman Finger starts at 10 with **The 1 Ring (8350)**, which 404s on Forever and is pruned. **Woven Copper Ring (21931)** also 404s. Horde enhancement rings that exist are Bounty Hunter's Ring (5351, Barrens) and Ring of Scorn (3235, Silverpine) around 15. Do not toast “ring slot eligible” unless `SlotHasHunts("Finger")`.

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
- **Toasts are the current list only.** Bag, equip, loot, and a normal level-up call `CheckAutoCompletion()` with no reached-band scan. Complete and toast only top upgrades, the notable, and a tracked hunt that still `EntryMatchesPlayer`. A level 20 Enhancement shaman looting **Calico Cloak** (level 9 back) must not toast or complete it. Do not treat `GetCandidatesForSlot` as the list. The full catalog walk on `BAG_UPDATE` was the dungeon `Log.lua` "script ran too long" error.

**28 Sep 2026 (v0.2.17-beta).**

- **Spec weight tooltip.** Hover the spec name or icon. `GQ.Compare:ShowScoringWeightTooltip` reads `GQ.ScoringWeights` (pipeline `weights.json`) and applies `GQ.ScoringLeveling` when level &lt; 60. Do not show `GQ.StatWeights` (Compare.lua reorder table). Weapon `dpsWeight` / `dpsWeightRanged` are extra rows. Regenerate with `node scripts/generate-stat-weights-lua.mjs` after a weight edit. `sources.json` must stay ASCII JSON (`ensure_ascii=True`); `score.py` opens it with the Windows default encoding and rejects raw UTF-8.
- **Enhancement intellect.** `weights.json` Enhancement `int` is **0.6**. `weights_at_level` doubles intellect below 60, so those bands score it at **1.2**, above agility **1.0**. Level 60 stays 0.6. The scorer does not turn intellect into attack power; Mental Dexterity lives only in this weight. Enhancement Tank `int` stays 0.4. Shaman was re-scored and `Data.Shaman.generated.lua` plus the early 1–9 file were copied. Do not `reemit_all.py` for this.
- **Wolfsbane (267369).** Horde Retribution main hand rank 1 from level **20 through 26** (score 124 vs Hammerbone 103 at 20). Pin in `client_item_overrides.json`: `rlvl` 20, `tipClasses` Paladin, Holystorm proc text. Source is Diplomatic Incident, Danitha Morr, Bandarion Keep, Tirisfal Glades (`sources.json` `gateLevel` 20). Tirisfal is a Horde zone, so Alliance never sees it. Warrior was re-scored after the class lock so Arms/Fury/Protection no longer list it. Paladin files: `Data.Paladin.generated.lua` and `Data.Paladin.Horde.1to9.generated.lua`.
- **Memory.** Do not list class hunt files in `GearQuestForever.toc`, and do not put those class addons in `## OptionalDeps` (that loads every class before `Core.lua` sets `_G.GearQuest`, so each file errors and the hunt list stays empty). Each class is a load-on-demand addon `GearQuestForever_<CLASS>` (`scripts/stage-class-addons.py` copies the lua and writes `AuditTips.lua`). Login loads the player's class only. `Preview:SetClass` expands the simulated class. Your class and the class on screen keep their expanded rows. Switching to another sim class drops the previous one's expanded rows (`ReleaseIdleHuntClasses`). The addon stays in the memory list until `/reload` (WoW cannot unload it); pick arrays stay so switching back does not rerun the file. The main `foreverAudit` keeps `status` / `name` / `quality` for every item. The long Wowhead `tip` for a class item ships in that class's `AuditTips.lua` and is applied when the class loads, so hunt tooltips stay the Forever text. Curated Data.lua items that are not in a class file keep their tip on the main audit.

**28 Sep 2026 index: 3,693** (26 Sep was 3,678). Fifteen new listview ids. Ingest added the seven that had a nether tooltip: Needletooth's Needletooth (282703), Bloodstained Pants (282713), Denmother's Hide (283253), Arcane Charged Robes (284697), Still Water Band (284699), Wyvern Heart Band (285190), Winds of Tanaris (286556). Eight still 404 and are not in the pool: Wail of Death (281600), Fishscale Hauberk (281891), Unmovable Sabatons (284154), Eternally Frozen Band (284253), Budding Leaf Belt (284382), Faerie Dragon's Skin (284383), Ursol'lok's Paws (284573), Snapped Branch Wand (284574). All nine classes were re-scored. **Wyvern Heart Band** is rank 1 finger from 29 through 37 for Arms, Fury, Retribution, Combat, Subtlety, Survival, and Feral, and through 47 for Assassination. The other six did not take a top-3 slot.

A full ingest rewrites sources.json for every id >= 200000. That cleared 162 zones, including Wolfsbane (Tirisfal / Diplomatic Incident became Old Fire-Eye) and dropped Kaleidoscope's hand-patched resist 5. After ingest, restore every source key that already existed and only add new ids. Keep Kaleidoscope resist 5. Client pins stay skipped. Do not rescore from the wiped sources.

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
tip states `Requires Level` greater than 1, that number is `rlvl`. A stated
level is never replaced. Fang's tip is `<!--rlvl-->13`. It was never gated
at item level 18. It ranked low because spell power was stored as 0.

**No required level means look the item up.** Every time an item has no
`Requires Level` (nothing on the tip, or Wowhead's stub of 1), assume it is
a quest reward, or some other source that has a level gate, and look it up
on Wowhead Forever. Do not leave it on the item-level floor (`ILVL_FLOOR`:
ilvl 18 → 13, ilvl 23 → 18, ilvl 24 → 19). That floor is only a stand-in
until the lookup has been done. Find the quest attached to the item. The
**minimum** level required to pick up that quest becomes the item's `rlvl`
and the source `gateLevel`. Several quests: take the lowest. `eff_req` then
uses `rlvl` when it is &gt; 0.

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
`pipeline/data/forever_wowhead/quest_req_cache.json`. 686 quest levels were
applied, including Kris of Orgrimmar (15443) and Staff of Orgrimmar (15444)
at 9 (Hidden Enemies, 5730). Staff of Westfall stays 14. Grave Shroud stays
16. Fang stays 13. Wowhead returned HTTP 403 after ~914 lookups. The items
still sitting on no required level still need this lookup. Resume with
`--apply-only` for successes already in the cache, and retry only rows whose
error starts with `HTTP Error 403`. Do not refetch the good rows.

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
higher score than rank 2. That is intentional. Off hand stays score-sorted.
`EntryOffWeaponRoute` is unused. Do not grey the off hand.

| Who | Main Hand header | Off Hand header |
|---|---|---|
| Mage, priest, warlock | Staff or main hand | Off Hand |
| Druid, Enhancement, paladin/warrior levelling when a route exists | Two-hand or main hand | Off Hand |
| Hunter | Two-hand or dual wield | Off Hand. Ranged label is **Bow** |
| Rogue (combat, assassination, subtlety), Warrior Fury | Dual wield | Off Hand |
| Paladin Retribution, Warrior Arms | Two-hand | Off Hand |
| Paladin Protection and Holy, Warrior Protection, Shaman Elemental, Restoration, Enhancement Tank | Main Hand | Shield |

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

Priest, mage, and warlock `dpsWeightRanged` is **0.25** from level 10
(levels 1–9 stay 0.5). Wand damage is part of the score. A large DPS gap
beats a small intellect or spirit roll. A wand that also has real stats
still leads at 60. Greater Magic Wand is the client **17.5** DPS
(22–41 Arcane), not the older 11.39 Wowhead line.

### Hunt instructions

`sources.json` `instructions` are one short sentence. Zone, quest name, and
NPC live in their own fields — the log prints them once. World drops:
`World drop around level X-Y.` Quests: `Reward from the quest 'Name'.`
Vendors/bosses: `Bought from X.` / `Drops from X.` Auction House is a
separate BoE line, not repeated inside the sentence.

A named dungeon boss is `boss_drop`, even when the old sentence said
"(rare elite)". Mutanus the Devourer is Wailing Caverns, not a world drop.
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
when a pin exists. Tracked hunts also pin that spot on the world map and,
when you are close enough, on the minimap. Clicking a pin toggles a blue
circle. Show on map opens that zone.

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

- Quest: the giver that starts the quest, or the first step of its Wowhead
  series. `(beginning of the quest or chain)`
- Boss and raid trash: the dungeon or raid entrance, not the boss room.
  `(entrance to dungeon or raid)`
- Vendor: the NPC that sells it, one pin, faction filtered.
  `(vendor that sells this)`
- World drop: the first spawn Wowhead lists for the named creature.
  `(a farming spot)`
- World boss with an outdoor pin: `(where this boss spawns)`

Classic dungeon doors are the pre-Cataclysm Questie entrance table (Forever
still uses classic geography). Forever doors with exact numbers: Hall of
Thanes 43.6, 51.7 in Ironforge, and Ruins of Lordaeron 71.6, 11.4 in
Tirisfal Glades. These seven have a description only, so nothing is pinned
there: Excavation Site (southern Wetlands), City of Dalaran (Alterac
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
numbers for the seven Forever doors above.

### Pins (built)

Tracking a gearquest puts one pin on the world map, the same spot the
coordinate line shows for the viewer's faction. The pin leaves when the
hunt is untracked. The icon follows the source: quest, boss, profession,
vendor, world drop. Clicking the pin toggles a blue circle. The same pin
shows on the minimap while you are in that zone and close enough. Show on
map opens the zone and sets the user waypoint.

The pin table is ours. Questie is not required in game.

### Indexing a new or updated item

A Wowhead Forever scrape that adds or changes a hunt item looks up the
coordinate in the same pass as the usual facts: tooltip stats, required
level, source, zone, npc, and quest. Run
`python pipeline/scripts/index_coordinates.py` before syncing the addon.
It is resume-safe. The cache is
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

- Quest reward: the giver that starts the quest, or the first step of its
  Wowhead series. Note `(beginning of the quest or chain)`.
- Boss drop and raid trash: the dungeon or raid entrance in
  `pipeline/data/dungeon_entrances.json`, not the boss's room. Note
  `(entrance to dungeon or raid)`. Classic doors are the pre-Cataclysm
  entrance table. Forever doors with numbers are Hall of Thanes
  (Ironforge 43.6, 51.7) and Ruins of Lordaeron (Tirisfal Glades 71.6,
  11.4). The other seven Forever doors have a description and no numbers.
  Leave them unpinned until someone measures the door.
- Vendor: the NPC that sells it, one pin per faction. Note
  `(vendor that sells this)`. A battleground quartermaster with no outdoor
  pin stays a gap.
- Named world drop: the first spawn Wowhead lists for that creature. Note
  `(a farming spot)`. A line that only says "World drop around level X–Y"
  names no creature, so it stays a gap. Do not use the center of the zone.
- Profession taught by a trainer: Wowhead spell pages do not list the
  trainer. The capital-city trainer pins already in the file came from a
  one-time Questie gap fill (`pipeline/scripts/enrich_coordinates.py`). A
  later Wowhead scrape will not discover a new trainer. Do not guess a city.
  Note `(the trainer that teaches this)`.
- Profession bought at a Merchant's Favor camp: the vendor pin in the camps
  table above, for every leatherworking, blacksmithing, tailoring,
  enchanting, and engineering piece whose hunt sentence names that camp.
  Note `(vendor that sells the recipe)`. Do not put these on Orgrimmar or
  Stormwind. Trainer recipes stay on the trainer pins.
- World boss with an outdoor pin: `(where this boss spawns)`.

Faction is a filter. Neutral spots show for both. Store one spot per
faction and set `more=true` when another valid spot exists. The log prints
`more coordinates for this`. The map pin is that same first spot, not every
spawn. Continent maps and a 50, 50 zone center are not coordinates.

`enrich_coordinates.py` only fills gaps. It must not replace a Wowhead pin
or a dungeon door. It does not run on the scrape. Unnamed world drops that
Questie also cannot place stay in `coordinate_gaps.json`.

Show on map opens that zone and sets the user waypoint. Tracked hunts draw
one world-map pin and a minimap pin when the player is close. Clicking the
pin toggles a blue circle. Untrack removes the pin. Track and Untrack are
one button under the reward, beside Show on map. Exit sits in the footer
on the log, the simulator, and settings.
