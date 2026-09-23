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
- **Sets:** blank line before the set header, indented piece names, blank
  before Sell Price. Forever stats stay; client set-bonus overlay only when
  the bonuses are usable (`GetClientSetBlock` / `ApplyClientSetBlock`).
- **No Forever tip** → `ShowClientItemTooltip` (`SetItemByID`).
- Green `+N Spell Power` / Damage Done / Healing Done, not the old Equip
  “increases damage and healing by up to N” sentence.

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

**23 Sep 2026 scrape:** index **3,637** (same count as 22 Sep; six ids rotated into the list). Ingest **+6** pool ids after fetching missing tooltips. **397** nether tooltips re-fetched where the listview armor/DPS no longer matched `items.json` (mostly PvP / rank-set pieces). Re-ingest merged stats; `client_item_overrides.json` pins untouched. All nine classes × every spec re-scored. New pick on lists: **Death Prophet Spine** (274158) Enhancement shaman MainHand @ 26. Other new ids (274042 belt, 282012 hands, 282019 neck, 282658 back, 284702 sword) scored but did not take top-3 yet. Addon: spec choice is session-only in the log; after `/reload`, hunts follow the talent tree (most points) unless simulation preview is on.

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
