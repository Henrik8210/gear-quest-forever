# Scoring Forever / Classic items

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
- **Coldflame Saber** (276631) is mage-only. Client tooltip, not the Wowhead
  nether tip: 17–32 damage, 12.2 DPS, +7 Intellect, +32 spell power and
  healing, 98 Fire on melee against Frozen targets, requires level 21.
  Pinned in `client_item_overrides.json`. Wowhead’s higher white damage and
  missing spell power must not be synced back.
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

Display already paints `foreverAudit.tip`. Scoring reads `items.json`. Those
must match.

```powershell
python pipeline/scripts/inventory_hunt_ids.py
python pipeline/scripts/probe_forever_hunt_tooltips.py
python pipeline/scripts/sync_forever_item_stats.py --apply
python pipeline/scripts/rescore_hunter_shaman.py
python pipeline/scripts/emit_forever_audit.py
.\scripts\sync-addon.ps1
```

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
| Coldflame Saber (276631) | 25–48 damage, 18.25 DPS, +7 Int, no spell power, rlvl stored as 24 | 17–32 damage, 12.2 DPS, +7 Int, +32 spell power and healing, 98 Fire vs Frozen, requires 21, Classes: Mage |
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
- **No Forever tip** goes to `ShowClientItemTooltip` (`SetItemByID`).
- Green `+N Spell Power` / Damage Done / Healing Done, not the old Equip
  sentence that says increases damage and healing by up to N.

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
node scripts/diff-veldt-wowhead.mjs
```

Then `score.py` / `reemit_all.py` and copy `pipeline/out/Data.*.generated.lua` into `GearQuest/_generated/`. Ingest does **not** overwrite existing classic ids in `items.json` / `sources.json` (so the WSG rune vendor fix survives a re-ingest). New Forever-only ids (≥ 200000) merge in as Wowhead grows.

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

### Hunt instructions

`sources.json` `instructions` are one short sentence. Zone, quest name, and
NPC live in their own fields — the log prints them once. World drops:
`World drop around level X-Y.` Quests: `Reward from the quest 'Name'.`
Vendors/bosses: `Bought from X.` / `Drops from X.` Auction House is a
separate BoE line, not repeated inside the sentence.

Wowhead HTML tooltips must replace `<br>` / `</div>` with newlines before
stripping tags (`probe_forever_hunt_tooltips.plain`). The log must not
paste `foreverAudit.tip` into the parchment (that is how
`ItemLevel27Bindswhenequipped` happened).

Full write-up: [../../docs/FOREVER-DATA-MIGRATION.md](../../docs/FOREVER-DATA-MIGRATION.md).
