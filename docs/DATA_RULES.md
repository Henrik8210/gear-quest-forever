# GearQuest data rules

Rules for adding, importing, and maintaining gear quest entries in `GearQuest/Data.lua`. Follow these when curating data from Wowhead, in-game research, or leveling guides.

**GearQuest Forever — target vs today:** Forever’s **target** is Classic 1–60 (+ Forever deltas). **Today**, all nine classes are on the Forever scoring model (jackpot suffixes, leveling survivability + endurance, no TBC guide pin). See [FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md).

## Data sources (read this first)

GearQuest uses **two different pipelines**. Do not apply one pipeline’s rules to the other.

| Source | Levels | Classes | How it gets in | Authoritative doc |
|--------|--------|---------|----------------|-------------------|
| **Curated** (`Data.lua`) | 1–9 Alliance bands, seasonal/event items, hand-picked Paladin quest chains | Early Alliance mail melee; not full-class 1–60 yet | Manual curation | This file (§ Curation workflow) |
| **Generated** (`_generated/*.lua` → `DataAdapter.lua`) | **1–9 generated** (except Alliance paladin/warrior curated) **and 10–60** | **Nine classes** | Forever `score.py` (`pipeline/`); damage then survivability then endurance | [`pipeline/docs/FOREVER-SCORING.md`](../pipeline/docs/FOREVER-SCORING.md) |

**Forever max level is 60** (`GQ.MAX_PLAYER_LEVEL` in `Core.lua`). TBC **level 70** curated data was removed; do not re-import Phase 3 AtlasLoot into this repo. Generated bands are capped at **60**. Migration phases: [FOREVER-DATA-MIGRATION.md](./FOREVER-DATA-MIGRATION.md).

**Paladin 10–60** comes from the generated pipeline (`paladinPicks` + `paladinHorde1to9`). All seven classes merge into `GQ.Data.entries` at load time via `DataAdapter.lua`. Sanity check:

```powershell
node scripts/verify-generated-bis.mjs
```

Always use `node scripts/verify-generated-bis.mjs` for the live entry count, not a stale figure. All nine classes are Forever `score.py` regens with the Wowhead Forever pool (id ≥ 200000) merged in. Levels 1–9 are scored **per spec** (Alliance paladin/warrior 1–9 stay curated). Horde Forever deltas in `Data.lua` use `foreverDelta = true` so they compete across generated per-level bands; Compare still shows the top 3.

### Ranking philosophy by source

| Source | What “top 3” means |
|--------|---------------------|
| **Curated (early bands)** | Human judgment: realistic upgrades for that level band, correct armor tier, obtainability considered when hand-picking. |
| **Generated (all classes 1–60)** | **Combat value** in this order: **damage** (spec primary) first, then **survivability** below 60 (sta / health / hp5 ×3, armor ×2), then **endurance** (int / spirit / mp5 / mana ×2, less than stam). Random-enchant greens rank on the **jackpot** (top of the suffix range) — a 9.5% +7 Agi roll that would be #1 must appear as BiS #1. Warrior Protection does not score spell power; defense on a caster piece is a notable, not rank 1. Shaman **Enhancement Tank** is a hybrid (1h + shield, like paladin Protection). Max **3 unique names + 1 notable** per slot. Level 60 uses raw raid-scale weights (`GQ_NO_GUIDES=1`). Item facts for scoring come from Forever hunt tips (`sync_forever_item_stats.py`), not stale Classic `items.json`. |

At **runtime**, `Compare.lua` ranks most generated candidates by item level vs equipped, armor-tier penalties, and small source bonuses — it does **not** re-run the full stat-weight model. Generated rows arrive with `curatedRank` from the pipeline; hand-curated rows keep author rank. **Exceptions:** (1) bands with `origin="guide"` (level-60 guide tiers) **must never be re-sorted by score**; (2) **Priest, Mage, and Warlock** always keep pipeline `curatedRank` (weapon pairing — staff vs 1H+off-hand). **`Compare.lua`’s ≥8 ilvl lower-tier armor rule applies to runtime re-ranking only**, not to how generated picks were chosen (those used armour multipliers in the pipeline).

**Faction gating (pipeline):** wrong-faction rows are stripped at emit time using vendor stock analysis (`npc_faction.json`), PvP prefix rules (`pvp_prefix_faction.json`), reputation exclusivity (mirror pairs + hand-verified names like Tranquillien), and quest/class locks on adjacent rows — **not** sub-zone lists alone (shared camps can host both factions’ vendors).

**Shared-ID PvP (do not pin one quartermaster):** Warsong Gulch **Rune of Duty** (21567/21568) and **Rune of Perfection** (21565/21566) are the **same item IDs** for both factions. Alliance buys them from Illiyana Moonblaze (Silverwing Grove); Horde from Kelm Hargunth (Mor'shan Base Camp). `sources.json` must keep `npc`/`zone` unset and put both vendors in `instructions`. Pinning Illiyana made `npc_ok` treat them as Alliance-only and left **Horde with no trinket hunts from 20–27** (first pick was Defiler's Talisman at 28). Forever tooltips have no `Classes:` line — `allowClass` is `-1`. Both runes are Unique-Equipped: Rune of Battle (1), so they are alternatives, not a pair. Details: [`pipeline/docs/FOREVER-SCORING.md`](../pipeline/docs/FOREVER-SCORING.md).

---

## Goal

Show **three hunts per slot** for the player’s **class, faction, spec, and level** — nothing they cannot equip. Empty slots are a data bug to chase, not an acceptable “nothing drops here” answer.

**Always strive for 3 items per slot per level.** Rank 2 and 3 may be a lower required-level piece the player can still wear (a level-20 Warsong Gulch rune at 22, a quest green from last zone). That is okay. Do not leave a slot blank because the only remaining candidates are “old.” An empty Trinket at 22 usually means a faction/vendor/class gate stripped the pool, not that Classic has no trinkets.

**How** the three are chosen depends on the source: curated bands favour realistic, level-appropriate picks; generated 10–60 favours stat score (with pipeline faction/rep/vendor gates). Compare still displays the top 3.

### Forever catalog is incomplete — keep re-indexing

Wowhead’s Forever item list and tooltips are still filling in. GearQuest will **scrape and ingest Wowhead many times over the coming months** (`scripts/scrape-forever-wowhead-items.mjs` → `pipeline/scripts/ingest_forever_wowhead.py` → re-score → copy `_generated/`). Each pass should add missing ids, retuned stats, and replacements for classic ids that 404 on `nether.wowhead.com/forever/tooltip/item/{id}`. Do not treat one ingest as finished product.

After a Wowhead scrape, run `node scripts/diff-veldt-wowhead.mjs` as an extra check against [veldt1’s Forever Item Explorer](https://veldt1.github.io/wowf-items/) (beta client diff + computed stats). Wowhead stays authoritative for ingest; veldt only flags gaps (ids not on the Wowhead index, or empty Wowhead tooltips where veldt already has stat/effect text).

**19 Sep 2026:** 3,245 → **3,586** Wowhead Forever items. Ingest added **316** new pool ids (25 list rows had no tooltip; 74 skipped). All nine classes × every spec were re-scored and emitted into `GearQuest/_generated/`. Classic rings **The 1 Ring (8350)** and **Woven Copper Ring (21931)** still 404 — Horde shaman Finger hunts start ~15, not at the level-9 Alliance paladin toast.

**20 Sep 2026 (morning):** index still 3,586 rows; **24** missing ids ingested (Silvered Gauntlets, Cultist's Armguards, Dark Ritual Leggings, plus ilvl-65 sets that did not crack 60 BiS). Hunt instructions cleaned; parchment no longer dumps mashed tooltips or eats spaces. Warrior prot spell-power weight removed — Silvered Gauntlets is a Hands notable for +3 Defense.

**21 Sep 2026:** index **3,625** (+4 held-in-off-hand greens). Re-scored mage/priest/warlock/druid/shaman/paladin; none made top 3. **Do not scan profession trainers in-game** — Collector is deleted; trainer hooks froze the client (`Script exceeded its execution time limit`). Details: [`FOREVER-SCORING.md`](../pipeline/docs/FOREVER-SCORING.md).

Classic ids that 404 are pruned from hunts at load (`GQ.Data:PruneMissingForever`, fed by `_generated/Data.ForeverAudit.generated.lua`). Items that exist but have no combat stats, suffixes, or effect lines show **Has not been datamined yet** — hunt source text is not a tooltip.

**Relics:** do not rank Totem/Idol/Libram by item level alone. Run `python pipeline/scripts/patch_relic_effects.py` after ingest so Equip lines land in `items.json`, then `relic_score.py` inside `score.py` prices casting mana reg, spell-line buffs, and small utility CD trims per spec.

**Local WoW install:** after changing addon Lua or `_generated/`, always run `scripts/sync-addon.ps1` from repo root (see [README.md](../README.md)). Editing only the git tree does not update `Interface/AddOns/GearQuestForever`.

**Log — simulation banner:** when preview/simulation is on, the log header shows level, spec, class, and faction; when off, it tells the player they are viewing their character and can use the spec picker.

## Curation workflow (primary)

**You** define the BiS list: top 3 items per slot per level band per class (and faction/spec when relevant). **GearQuest** adds them to `Data.lua`, verifies item IDs, and flags problems.

When you send a batch, include for each item:

| Field | Example |
|-------|---------|
| Class + level band | Alliance Paladin, level 4 |
| Slot | Back |
| Rank | 1, 2, or 3 |
| Item | name + Wowhead/item ID |
| Source | vendor / quest / seasonal quest / drop / profession / event |
| How to get | 1–2 sentences |

When curating level bands, set **`minLevel`** to the level that band starts (e.g. `1` for level 1–4, `5` for level 5–10). At each player level, GearQuest shows only entries from the **highest `minLevel` band** that the player has reached for that slot — so level 5 lists replace level 4 lists automatically.

On import, the assistant will:

1. **Verify** item ID, slot, required level, class/faction, and armor tier rules.
2. **Compare** against existing entries for the same class + slot + level band — and warn if new gear is **worse** than something already indexed (lower item level, less armor on cloaks, grey vendor vs green stat item, wrong armor tier without a stat exception, etc.).
3. **Warn** on duplicates, wrong IDs, or items that outrank existing #1–#3 without you intending a reshuffle.
4. **Write** the entries with consistent `minLevel` / `maxLevel`, `sourceType`, and instructions.

Optional: note if an item is **seasonal** (e.g. Midsummer crown) or **spec-specific** so we set `specs` or realistic `maxLevel` bands correctly.

---

## 1. Source research (Wowhead and others)

Before adding an entry, verify **all** of the following on the item's Wowhead (or in-game) page:

| Check | Rule |
|-------|------|
| **Required level** | Must be ≤ the `maxLevel` band you assign. Never tag a level-19 item for a level-4 band. |
| **Item ID** | Confirm on [Wowhead Classic](https://www.wowhead.com/classic) or classicdb.ch — wrong IDs silently show the wrong item in-game. |
| **Class / armor type** | Confirm the class can wear it at that level (e.g. Paladins cannot use daggers; plate unlocks at 40). |
| **Faction** | Set `factions = { Alliance = true }` or `{ Horde = true }` when the source is faction-locked. |
| **Spec** (level 10+) | After talents unlock, note whether the item suits Holy / Protection / Retribution (etc.). Use optional `specs` on the entry when an item is spec-specific. |
| **Slot** | Item equip slot must match the entry `slot` (MainHand, SecondaryHand, Chest, …). |
| **Source type** | One of: `world_drop`, `boss_drop`, `raid_trash`, `quest_reward`, `seasonal_quest`, `vendor`, `profession`, `auction_house`. |
| **Instructions** | 1–3 sentences: where to go, what to kill, which vendor, or how to craft — written for a player at that level. |

### Check every source category

When curating a level band, **search all obtainable categories** before moving on:

| # | Source type | What to look for |
|---|-------------|------------------|
| 1 | **Vendor** | Starter-zone armorers, weapon smiths, and general goods sellers. |
| 2 | **Quest reward** | Quests reachable at that level. Verify reward item IDs on Wowhead Classic (not wiki summaries alone). |
| 3 | **World drop** | Grey and green BoE from zone mobs. |
| 4 | **Boss drop** | Dungeon and world bosses reachable at that level. |
| 5 | **Profession** | Crafted gear the class can wear at that level (Blacksmithing mail for paladins, Tailoring cloaks, etc.). |

You do not need all five in every slot, but do not stop after vendors alone if another category has a valid item.

For **profession** entries, also set optional `profession = "Blacksmithing"` (or Tailoring, Leatherworking, …) and mention the trainer, recipe, and where to craft in `instructions`. The hunt completes only when the player **crafts** the output item (`itemId`), not when they learn the recipe alone.

Forever camp crafts (Brawler's and Stormrider's leather, including Armor as well as Tunic, Veteran's mail, Shining cloth, and the other sets sold for Merchant's Favor) name both vendors in `instructions`: Horde buys from the profession vendor at the Durotar Supply and Logistics camp northwest of the Crossroads in The Barrens; Alliance buys from the matching vendor at the Azeroth Commerce Authority camp at Three Corners in Redridge Mountains. The list of sold outputs and the sentence live in `pipeline/scripts/commerce_camps.py`. Classic trainer recipes stay on the short "Crafted with …" line. A known craft skill is inserted into the first sentence and does not drop the vendor sentence.

**Profession learnable upgrades — green arrows (automatic):** Any entry with `sourceType = "profession"` whose output is a **top-3 upgrade** for the player’s class/level automatically gets the green ↑ in **both** places below. No extra flags or per-entry UI config — only correct `itemId`, ranking, and (for new recipes) a row in `PROFESSION_ITEM_NAMES` if name lookup is needed before `GetItemInfo` caches.

| Where | When |
|-------|------|
| **Profession trainer** (e.g. Smith Argus) | Player selects the recipe that teaches/crafts that item — arrow on the **bottom inset icon** (`ClassTrainerSkillIcon`). Works **before** the player learns the profession or recipe (name/tooltip match on the crafted item). |
| **Character’s Trade Skill window** | Player has that profession and selects the recipe — arrow on the **bottom inset icon** (`TradeSkillSkillIcon`). Same crafted `itemId` as the hunt entry. |

Applies to every crafting profession GearQuest indexes (Blacksmithing, Tailoring, Leatherworking, etc.) for any recipe whose **output item** is in the current top 3. The addon matches by **item name / item ID**, not by trainer NPC — any trainer that lists that recipe name gets the arrow when it is selected.

### Armor type (class best tier)

Prefer the **highest armor tier the class can wear** at that level:

| Class | Below 40 | Level 40+ |
|-------|----------|-----------|
| Paladin, Warrior | **Mail** | **Plate** |
| Hunter, Shaman | **Leather** | **Mail** |
| Druid, Rogue | **Leather** | **Leather** |
| Priest, Mage, Warlock | **Cloth** | **Cloth** |

**Data rule:** entries for a class/level band should use that class's best tier (mail for a level-4 paladin). Do not add cloth/leather filler unless the item is a genuine stat exception (see below).

**Ranking rule (runtime):** `Compare.lua` heavily penalizes lower-tier armor in Head/Chest/Legs/Feet/Hands/Wrist/Waist/Shoulder slots when re-sorting candidates. A cloth or leather piece only appears in the top 3 if its item level is **≥ 8 above** the best preferred-tier option for that slot. Cloaks (`Back`) and non-armor slots are exempt. **This is not how generated Paladin picks were selected** — see [GEARQUEST-BIS-PIPELINE.md](../GearQuest/_generated/GEARQUEST-BIS-PIPELINE.md) for armour multipliers and stat weights.

When **hand-curating** early bands, prefer items that are **actually obtainable** at the target level (quest available, vendor visited, dungeon reachable). That preference does **not** apply to generated 10–69 data.

### Class armor profiles (can wear vs should wear)

Every class can **equip** any armor tier at any level (subject to required level). What matters for GearQuest is what they **should** hunt for at each level band.

| Class | Can equip (always) | Preferred tier | Tier change |
|-------|-------------------|----------------|-------------|
| **Paladin** | Cloth, leather, mail, plate | Mail | Plate at **40** |
| **Warrior** | Cloth, leather, mail, plate | Mail | Plate at **40** |
| **Hunter** | Cloth, leather, mail | Leather | Mail at **40** |
| **Shaman** | Cloth, leather, mail | Leather | Mail at **40** |
| **Druid** | Cloth, leather | Leather | — |
| **Rogue** | Cloth, leather | Leather | — |
| **Priest, Mage, Warlock** | Cloth | Cloth | — |

**Slots outside armor-subclass rules:** weapons, shields, cloaks (`Back`), neck, rings, trinkets. Cloaks are **always cloth** for every class — rank them by item level (higher ilvl ≈ more armor on cloaks at low levels), not by mail/leather/plate preference.

**Import default:** for Head/Chest/Legs/Feet/Hands/Wrist/Waist/Shoulder, add the class's **preferred tier** for that level. Do not fill slots with lower-tier vendor greys when preferred-tier options exist at the same required level.

### When lower-tier armor is still a valid upgrade

The addon does not parse every stat line yet. It approximates “this green leather chest is worth wearing on a mail paladin” with an **item-level margin**: lower-tier armor is penalized unless its ilvl is **≥ 8 above** the best preferred-tier option in that slot (`Compare.lua`).

When **curating** data by hand, use the item tooltip on Wowhead Classic and ask: *would a player realistically equip this over grey mail/leather at the same level?*

| Situation | Include lower tier? | Example (verified on Wowhead Classic) |
|-----------|---------------------|----------------------------------------|
| Grey lower tier, no stats | **No** | White [Flimsy Chain Cloak (2652)](https://www.wowhead.com/classic/item/2652) — 5 armor, ilvl 5 — when [Battle Chain Cloak (4668)](https://www.wowhead.com/classic/item/4668) — 8 armor, ilvl 9, req 4 — exists |
| Same preferred tier, but **+stats** | **Yes** (preferred tier) | [Copper Chain Vest (3471)](https://www.wowhead.com/classic/item/3471) — mail, **+1 Strength**, ilvl 10 — beats grey [Tarnished Chain Vest (2379)](https://www.wowhead.com/classic/item/2379) with no stats |
| Green preferred tier with random stats | **Yes** | Green [Loose Chain Cloak (2644)](https://www.wowhead.com/classic/item/2644) uncommon drops can roll stats; still below the ilvl-9 / 8-armor cloak band at req 4 |
| Green **lower** tier with strong stat budget | **Rare — check ilvl + stats** | [Deviate Scale Belt (6468)](https://www.wowhead.com/classic/item/6468) — **leather**, +6 Sta / +5 Agi / +3 Spi, ilvl 23 — clearly beats grey mail belts for **Hunter** (preferred leather). A **Paladin** would only hunt leather if it massively outclasses mail (high ilvl + combat stats for Retribution, or +Int/+Spi for Holy) |
| Situational resist / spell gear | **Yes, spec-specific** | Use `specs = { holy = true }` when the item is cloth with +Int/+Spi and ilvl justifies it for healing |

**Why leather can beat mail (concept):** armor subclass gives more base armor per ilvl on higher tiers, but **green and blue items spend part of their budget on primary stats** (+Strength, +Stamina, +Agility, +Intellect, +Spirit). A white mail piece with armor only often loses to a green leather piece with several stat lines — especially for DPS specs. GearQuest's +8 ilvl margin is a stand-in until full stat weighting exists; when importing, prefer Wowhead stat blocks over name or grey quality alone.

**Back slot example (level 4 Alliance Paladin):** Wowhead TBC filter [`slot:16`, req 1–4](https://www.wowhead.com/tbc/items/min-req-level:1/max-req-level:4/side:1/class:2/slot:16) lists **8-armor** green cloaks at req 4 (Battle Chain, Ancestral, Tribal). A crafted [Linen Cloak (2570)](https://www.wowhead.com/classic/item/2570) only has **6 armor** (ilvl 6) — fine as a profession fallback, not as the top recommendation once the player hits level 4.

### Wowhead TBC item search (research workflow)

Use [Wowhead TBC items](https://www.wowhead.com/tbc/items) with filters, then narrow to what your class can **equip and obtain** at that level.

**Example — Alliance Paladin main-hand weapons, req level 1–4:**

```
https://www.wowhead.com/tbc/items/min-req-level:1/max-req-level:4/side:1/class:2/slot:21:13:17
```

| Filter | Meaning |
|--------|---------|
| `min-req-level` / `max-req-level` | Item required level band |
| `side:1` | Alliance |
| `class:2` | Paladin (Wowhead class id) |
| `slot:21:13:17` | Main Hand, One-Hand, Two-Hand |

From the results:

1. Drop items your class **cannot use** (daggers, axes/swords before skill training, etc.).
2. Confirm **vendor NPC** and zone on the item page (Janos ≠ Corina Steele — check “Sold by”).
3. For crafts, confirm **profession**, recipe source, and **required level** on the item tooltip.
4. Match **item ID**, **name**, and **instructions** exactly in `Data.lua`.
5. At level 4, Human Paladins start with **mace** skill only — swords need a weapon master first.

Work **one slot per level band** (e.g. Main Hand at 4, Chest at 4, …) before expanding.

**Example — Alliance Paladin cloaks, req level 1–4:**

```
https://www.wowhead.com/tbc/items/min-req-level:1/max-req-level:4/side:1/class:2/slot:16
```

At req 4, prefer the **8-armor** green world drops (item level 9) over grey 5–6 armor cloaks or the 6-armor Linen Cloak craft.

Each slot should have **at least three entries** in `Data.lua` for that level band so the popup and log can always show three choices. Ranking picks the best three by score; they stay visible even if one is already equipped.

---

## 2. Never import unusable items

**Do not add** an entry if the character cannot equip the item:

- Wrong weapon type (e.g. dagger, bow, wand for Paladin)
- Armor tier not yet available (e.g. plate on a low-level Paladin before 40)
- Required level above the entry's intended band
- Wrong faction or class-only gear for other classes
- Wrong item ID (always verify — many numeric IDs map to unrelated items)

The addon validates at runtime with `IsEquippableItem` and required level from `GetItemInfo`. Bad data should still be caught in review using this checklist.

### Hunter-only ranged weapons

Some bows, guns, and crossbows have **ranged DPS procs** (e.g. “Chance to strike your ranged target…”) that only benefit **Hunter** — other classes use the Ranged slot for pull tagging, not damage. Do **not** add these to Warrior, Rogue, or other non-Hunter generated/curated lists.

Runtime filter: `GQ.Data.HUNTER_ONLY_RANGED_ITEMS` in `Data.lua` (`ShouldShowEntry`). When the pipeline surfaces a similar item for the wrong class, add its item ID there and strip it from that class’s generated file.

| Item ID | Name |
|---------|------|
| 2825 | Bow of Searing Arrows |

### Excluded items (novelty / non-upgrade procs)

Some trinkets and on-use items score in the pipeline but are not meaningful leveling upgrades (AOE novelty effects, etc.). Strip them from generated files and add the item ID to `GQ.Data.EXCLUDED_ITEMS` in `Data.lua` (`ShouldShowEntry` / notable build).

| Item ID | Name |
|---------|------|
| 13515 | Ramstein's Lightning Bolts |

Post-import script: `scripts/fix-ramstein-lightning-bolts.mjs`

---

## 3. Level bands and visibility

Each entry has:

```lua
minLevel = 4,   -- first level this hunt is relevant
maxLevel = 12,  -- last level it is normally shown
```

**While leveling:**

- New entries appear when the player reaches `minLevel` and can equip the item (`required level ≤ player level`).
- Entries **stop appearing** in the top-3 popup when the player is more than **5 levels above** `maxLevel` (`LEVEL_GRACE` in `Equip.lua`).
- Between `maxLevel + 1` and `maxLevel + 5`, an entry may **remain** only if it still ranks in the **top 3** for that slot (still a meaningful upgrade).
- Tracked/completed hunts follow the same level band rules in the log.

**Ranking** uses item level vs equipped item level, class-appropriate armor tier (`Equip.lua` + `Compare.lua`), and small bonuses for quest/boss/vendor/profession sources — not full sims.

---

## 4. Spec (talents, level 10+)

- **Below level 10:** no spec filter; all class-valid entries compete.
- **Level 10+:** GearQuest filters entries by the player's **active specialization** (Paladin: Holy, Protection, Retribution).
- **Default:** Retribution — the baseline leveling BiS path. Mail Strength/Stamina gear and melee weapons are tagged for Retribution + Protection unless noted otherwise.
- **Holy layer:** cloth/leather +Intellect/+Spirit quest alternatives get `specs = { holy = true }` (e.g. Minor Channeling Ring, Ridgeback Bracers, Wayfaring Gloves).
- **Protection-only:** tank-focused shields get `specs = { protection = true }` when they should not appear for Ret.
- **All specs:** omit `specs` on universal items (cloaks, seasonal head, etc.).

### Availability (Paladin, current)

| Spec | Selectable | Notes |
|------|------------|--------|
| **Retribution** | Yes | Default at level 10+ |
| **Holy** | Yes | Generated + curated data per spec |
| **Protection** | Yes | Generated + curated data per spec |

Other classes: all specs in `CLASS_SPECS` are selectable when data exists; `comingLater` is only used while a spec truly has no backing data.

### Preview / simulate (class, level, spec)

Players can browse another class/level/spec without changing their character:

| Method | Action |
|--------|--------|
| **Minimap** | Any click opens GearQuest. Simulator is the **Simulator** handle tab (class, faction, specialization, level 1–60). **Reset** = `/gq set me`. |
| **Chat** | `/gq class hunter`, `/gq level 37`, `/gq spec holy`, `/gq set on` / `/gq set off`, `/gq set me` |

Preview state lives in `GearQuestForeverDB.settings.preview` (class, level, faction, `specByClass`). Spec choice in preview does not overwrite the live character’s saved spec. Simulator spec is stored there and overrides the log spec until Reset.

**Character login:** preview is account-wide. On `PLAYER_LOGIN`, if the character GUID differs from `settings.preview.loginCharacterKey`, preview mode turns off and class/level/faction sync to the new toon. Same-character `/reload` does not reset an active simulation.

### Player controls

- **Log UI:** two columns — hunt list left, parchment right. **GearQuest Log** / **Simulator** are square handle tabs on the right of the frame (active handle shares the frame edge; inactive sits behind and darkened). **Active** / **Completed** sit on the quest-list gold border (selected toggle shares that edge).
- **Spec picker:** above the parchment, far right — current spec **icon** plus a **dropdown arrow**. Only the arrow opens the picker. Uses `GetDisplaySpec()` so the chosen spec icon shows even below talent level 10. The Simulator tab has the same control; simulation spec overrides the log spec until Reset.
- **Spec picker chrome:** same metal border + black background as the quest log list panel. Unavailable specs are greyed, labelled `(coming later)`, and not clickable.
- **Chat:** `/gq spec ret` (aliases: `spec`, `specialization`, `talent`). Only selectable specs work; others return *"… is coming later."*
- **Persistence:** choice is saved per class in `GearQuestForeverDB.settings.specByClass`. In **preview mode** (`/gq set on` or Simulator), spec choice is stored in `settings.preview.specByClass` so preview browsing does not overwrite your real character’s saved spec.
- **Icons:** spec picker uses curated icons from `CLASS_SPECS` in `Spec.lua` (do not read `GetTalentTabInfo` for icons — it reflects the **live player’s** talent trees, not the preview/effective class). Texture paths must use `ADDON_NAME` (`GearQuestForever`), not a hard-coded `GearQuest` folder.
- **Talent detection:** `DetectSpecFromTalents` reads `pointsSpent` from `GetTalentTabInfo` — **5th return** on TBC Anniversary / modern Classic (`id, name, description, icon, pointsSpent, …`); legacy clients use the 3rd return. Always `tonumber()` before comparing.
- **Live characters:** if no saved choice, GearQuest infers spec from talent points **when that spec is selectable**; otherwise defaults to the class default.

### Entry field

```lua
local SPEC_MELEE = { retribution = true, protection = true }
local SPEC_HOLY = { holy = true }
local SPEC_PROT = { protection = true }

specs = SPEC_HOLY,  -- omit = all specs
```

### Spec definition (`Spec.lua`)

```lua
{ id = "holy", label = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", comingLater = true },
```

- `comingLater = true` — listed in the picker but not selectable; `SetSelectedSpec` rejects it.
- `default = true` — used when no saved/talent spec applies (Retribution for Paladin).

### Level-up message

At level 10, a one-time chat message (milestone key `specSwitch` in `Core.lua`):

> Congratulations — you've reached level 10! Specializations are now available in GearQuest. Open `/gq log` to browse spec-specific upgrades; **Retribution** is selected by default.

Do **not** mention Holy/Protection availability in the message — the picker already shows `(coming later)`.

---

## 5. Entry template

```lua
{
    id = "unique_snake_case_id",
    itemId = 12345,
    slot = "MainHand",
    minLevel = 4,
    maxLevel = 12,
    classes = { PALADIN = true },           -- omit if any class can use
    factions = { Alliance = true },         -- omit if both factions
    specs = { retribution = true },         -- omit if not spec-specific
    sourceType = "quest_reward",            -- or vendor, world_drop, boss_drop, seasonal_quest, profession, auction_house
    curatedRank = 1,                        -- optional; 1 = best in slot for this band (preserves your order)
    profession = "Blacksmithing",           -- optional; use with sourceType = "profession"
    suffix = "of Strength",                 -- required on random-enchant greens; omit on whites/quest-fixed
    suffixChance = 9.8,                     -- from pipeline/data/items_random.json
    suffixId = 97,                          -- Classic ItemRandomProperties id when present
    suffixRange = "+3-4 Strength",
    instructions = "Short how-to for the player.",
    zone = "Elwynn Forest",
    npc = "Optional NPC name",
    questName = "Optional quest name",          -- use the in-game quest title, never quest ID in the log
},
```

---

## 6. Review checklist (before commit)

- [ ] Item ID opens the correct item in Wowhead Classic
- [ ] In-game item name matches the entry instructions (same weapon/armor name throughout)
- [ ] Required level fits the `minLevel`–`maxLevel` band
- [ ] Class can equip weapon/armor type at that level
- [ ] Armor entries use the class's best tier (mail for paladin/warrior below 40, etc.)
- [ ] Lower-tier armor included only with a genuine stat/ilvl reason (see Class armor profiles)
- [ ] Back slot: highest armor / ilvl at that req level (cloaks are always cloth)
- [ ] Checked vendor, quest, world drop, boss, and profession sources where items exist
- [ ] Faction and spec filters are correct or omitted
- [ ] If a spec is not yet selectable, `comingLater = true` is set in `Spec.lua` (not just missing data)
- [ ] Instructions match the source type and zone
- [ ] Random-enchant greens have `suffix` / `suffixChance` / `suffixRange` (and `suffixId` when Classic data has one) — otherwise the log shows the base name with no roll. Forever item tooltips must still show that roll (`TooltipShowsEntrySuffix` / `ShowSuffixFallbackTooltip`) even when the client paints the unsuffixed base item.
- [ ] `instructions` use ASCII hyphen/quotes only — WoW fonts draw em-dash/middle-dot as boxes or stray periods (`Data:SanitizeText` is the runtime backstop)
- [ ] Test in-game at `/gq preview set class paladin level N` (or on a real character) and confirm top 3 look sane

---

## Related code

| File | Role |
|------|------|
| `GearQuest/Data.lua` | Curated entries |
| `GearQuest/DataAdapter.lua` | Merges generated class tables into `entries` at load; suffix lookup/enrichment |
| `GearQuest/_generated/*.generated.lua` | Generated picks + item facts + notables (10–69, seven classes) |
| `GearQuest/_generated/GEARQUEST-BIS-PIPELINE.md` | Generated pipeline rules (stat weights, R1–R9) |
| `docs/SUFFIX-RANDOM-ENCHANT.md` | **Random enchant addon rules** — suffixId matching, negative ids, notables, tooltips |
| `scripts/clone-level70-specs.mjs` | Stand-in level-70 curated copies for specs that share gear pools |
| `scripts/verify-generated-bis.mjs` | Post-merge entry count + suffixId spot checks (all seven classes) |
| `GearQuest/Spec.lua` | Spec definitions, icons, `comingLater`, saved choice, picker filtering |
| `GearQuest/Log.lua` | Spec icon + arrow UI, spec picker chrome |
| `GearQuest/Equip.lua` | Equippability, required level, armor tier, spec, level grace |
| `GearQuest/Compare.lua` | Top-3 ranking vs equipped item |
| `GearQuest/Preview.lua` | Effective class / level / faction (and spec) |
| `GearQuest/Core.lua` | Source type labels and colors |

See also [PROJECT_BRIEF.md](./PROJECT_BRIEF.md).

---

## 7. UI behavior authors should know (log, tracker, popup)

When adding quests, these player-facing rules explain **what shows up where** and **how labels behave**. Use them so new data matches what players see in-game.

### Level bands in the log vs tracked hunts

| Behavior | Rule |
|----------|------|
| **Active band** | At player level N, the log and popup only rank entries whose `minLevel` equals the **highest band reached** (`FilterToActiveBand` in `Data.lua`). Level 6 entries replace level 5 entries once the player hits 6. |
| **"New" label** | On the **Active** tab, items from the current band show a gold **New** tag after the item name. Older-band items still visible (e.g. a tracked level-5 hunt after leveling to 6) do **not** get **New**. |
| **Tracked persistence** | A tracked hunt stays on the **Active** tab even if it falls out of the top 3 after leveling, as long as class/faction still match. It is appended below the current top 3 for that slot. |
| **Untrack** | Untracking normally keeps the detail panel open on the same item. If the hunt would **vanish from the log** (tracked but not in current top 3), the player gets a confirmation: *"It will become unavailable once you do"*. |

### Popup (right-click character slot)

- Every slot in `PaperDoll.lua` `SUPPORTED_SLOTS` must be wired, or right-click does nothing — include **Neck**, **Head**, **Shoulder**, etc.
- If there are no upgrades for a slot at the current level, print: `No upgrade hunts found for <Slot>.` (same as shoulder with no entries).
- Popup shows top **3** from the **active band only** (`GetCandidatesForSlot` → `FilterToActiveBand`).

### Detail panel (parchment)

| Field | Display rule |
|-------|----------------|
| Item title | Item name (uppercase), not quest ID |
| Description | `instructions` + zone / quest / **NPC:** / source |
| **REWARD** | Always show reward block: item icon + dark name strip; hover = item tooltip; Shift+click = chat link |
| BoE world drops | Detail text may note Auction House when bind-on-equip |
| Fonts | Use vanilla quest-log fonts (`QuestFont`, `QuestFont_Large`). Do **not** add outline/heavy post-processing on parchment body text. Run `instructions` through `Data:SanitizeText` — em-dash becomes `[]` and middle-dot wraps like a stray period. |

### List row labels

Example at level 6 with a tracked level-5 item still showing:

```
Charger's Armor New          ← current band, not tracked
Warrior's Tunic (Tracked)    ← older band, still tracked
```

Order within a slot: top 3 by `curatedRank` / score first, then extra tracked hunts.

### Floating tracker

- Shows all **tracked** hunts (not completed).
- Description length scales with tracker width (10–30 words).
- No chat message on Track/Untrack (keep chat quiet).
- Tracker is resizable; position and size persist in `GearQuestDB.settings`.

### Slots often skipped at low levels

Document in the batch when a slot has **no entries** on purpose:

| Slot | Typical low-level rule |
|------|------------------------|
| **Shoulder** | Skip until a meaningful upgrade exists (e.g. level 9+). Hide from log via `SLOT_UNLOCK_LEVEL` until then. |
| **Finger** | Skip until the first curated ring hunt exists (level 9 band). See **Slot unlock & level-up messages** below. |
| **Trinket** | Skip until the first curated trinket hunt exists; same unlock/milestone pattern as rings when added. |
| **Neck** | Add when valid neck items exist for the band; otherwise popup correctly reports no hunts. |
| **Head** | Often covered from level 1 (seasonal crown). Defer only if you intentionally have no head entries in early bands. |

When adding a new band (e.g. `early6_*`), copy the slot coverage pattern from the previous band and adjust — do not assume shoulder/neck carry over.

### Slot unlock & level-up messages

Some equipment slots are **hidden from `/gq log` and upgrade lists** until the player reaches a configured level, even though the character panel may show the slot earlier. Others stay visible but have **no entries** until you add data for a band.

This keeps low-level logs focused and avoids empty categories. When a slot **first becomes relevant**, the player gets a **one-time chat message** (saved in `GearQuestDB.settings.milestones`).

#### Two mechanisms (keep both in sync when curating)

| Mechanism | Where | What it does |
|-----------|--------|----------------|
| **Slot unlock level** | `GQ.Data.SLOT_UNLOCK_LEVEL` in `Data.lua` | Slot category omitted from log/popup/indicators until `GetEffectiveLevel()` ≥ unlock level. |
| **Level-up milestone** | `GQ:CheckLevelMilestones` in `Core.lua` | One-time chat print when the player **crosses** the level where new slot content applies. Fires on a real level-up and `/gq level N`. Login and `/reload` do not print it; they only mark milestones this character has already passed. |

#### Message wording (principle)

Match the message to **how many upgrades exist for that slot at that level**, not WoW’s raw equip rules:

| Situation | Message intent | Example (rings) |
|-----------|----------------|-----------------|
| **First hunt for a dual-slot category** | One of the two slots can now be filled | *“One of your ring slots is now eligible for an upgrade!”* |
| **Second hunt for a dual-slot category** (later band) | The other slot can now be filled | *“Your other ring slot is now eligible for an upgrade!”* |
| **First hunt for a single-slot category** | That slot category is now in the log | *“Shoulder upgrades are now available!”* (word similarly for head/neck when you add them) |

**Dual-slot categories in WoW:** `Finger` (two rings), `Trinket` (two trinkets). GearQuest merges each pair into one log section (`Finger`, `Trinket`) but milestone copy should reflect that the player fills **one slot at a time** as curated hunts appear — not “both slots unlocked” on day one unless you actually add two ranked rings/trinkets in the same band.

**Single-slot categories** often deferred: **Shoulder**, sometimes **Neck** / **Head** if you skip early bands. Use unlock level + a milestone when the **first** entry appears in data.

#### Author checklist when adding deferred slots

1. Set `SLOT_UNLOCK_LEVEL.<Slot>` to the band’s `minLevel` when the slot first appears in `Data.lua`.
2. Add at least one `Finger` / `Trinket` / `Shoulder` / … entry at that band with `curatedRank = 1`.
3. Wire a milestone in `Core.lua` (`NotifyMilestoneOnce`) when the player crosses that level — or set `GQ.Data.RING_SLOT_2_MILESTONE_LEVEL` (and future constants) for the **second** ring/trinket hunt at a later band.
4. Use milestone keys like `ringSlot1`, `ringSlot2`, `trinketSlot1`, `shoulderSlot1` — one key per message, never repeat after first show.
5. Point players to `/gq log` in the message; keep tone short and factual.

#### Current implementation (reference)

| Level | Slot | Unlock | Milestone key | Notes |
|-------|------|--------|---------------|--------|
| 9 | Finger | yes | `ringSlot1` | Alliance paladin/warrior curated rings only. Milestone fires only if **this character** has Finger hunts; Horde shaman has none until ~15 (The 1 Ring 8350 is missing on Forever). |
| 9 | Shoulder | yes | — | No separate milestone yet; shoulder shares level 9 band with ring. Add a `shoulderSlot1` message if you want an explicit shoulder callout. |
| TBD | Finger #2 | — | `ringSlot2` | Set `GQ.Data.RING_SLOT_2_MILESTONE_LEVEL` when second `Finger` entry is added. |
| TBD | Trinket | — | `trinketSlot1` / `trinketSlot2` | Same pattern as rings when trinket data is curated. |

Triggers: `PLAYER_LEVEL_UP`, preview `/gq level N` (`Preview.lua`), and `PLAYER_LOGIN` (catch-up if already at level).

### Level 6 band constants (example)

```lua
local LEVEL6_MIN = 6
local LEVEL6_MAX = 12
```

Use `id` prefix `early6_<slot>_<snake_name>`. Order legs (and similar) by **real stat value**, not alphabetically — set `curatedRank = 1` for the best piece in that slot/band.

### Copy & instructions checklist (player-facing)

- [ ] `questName` = in-game quest title (never show quest ID in UI)
- [ ] `npc` = vendor/quest giver name (log shows **NPC:** label)
- [ ] `instructions` = 1–3 sentences a level-N player can follow immediately
- [ ] Each slot in the band has up to **3** ranked entries (`curatedRank` 1 = best) where items exist
- [ ] Verify right-click popup and log **Active** tab both show the new band after `/gq preview set level N`
- [ ] Confirm **New** appears on band entries and disappears on older tracked hunts for the same slot

### Related UI code (2026-03)

| File | Role |
|------|------|
| `GearQuest/Log.lua` | Quest log, Active/Completed tabs, reward row, **New** label, untrack confirm |
| `GearQuest/Tracker.lua` | Floating tracked-hunt panel |
| `GearQuest/Popup.lua` | Character-slot upgrade bar |
| `GearQuest/PaperDoll.lua` | Right-click slot hooks (`SUPPORTED_SLOTS`) |
| `GearQuest/Indicator.lua` | Green ↑ on BiS items in loot/quest/profession UI |
| `GearQuest/Toast.lua` | “BiS upgrade obtained!” celebration toast |
| `GearQuest/Data.lua` | `GetActiveBandMinLevel`, `IsEntryNewForPlayer`, `SLOT_UNLOCK_LEVEL`, `RING_SLOT_2_MILESTONE_LEVEL` |
| `GearQuest/Core.lua` | `CheckLevelMilestones`, `NotifyMilestoneOnce` — slot unlock chat messages |

### Upgrade indicators (`Indicator.lua`)

GearQuest shows a **green ↑** on item icons when that item is one of your current **top-3 upgrades** for its slot (ranked by `Compare.lua` for your preview class/level/faction). The arrow uses the crafted **output item** for profession recipes, not the recipe spell itself.

| UI | When the arrow appears |
|----|------------------------|
| **Loot window** | Lootable BiS upgrade drops |
| **Need/Greed roll frames** | Group loot rolls on BiS upgrades |
| **Quest log reward choices** | Quest rewards that match a top-3 hunt |
| **Vendor window** | Items the merchant sells that are BiS upgrades |
| **Trainer window** | **Removed (v0.2.7).** Scanning trainer recipes on `TRAINER_UPDATE` froze the client. Do not re-hook class trainers. |
| **Trade Skill window** | **Detail inset icon only** — large icon at bottom when a recipe is selected (e.g. Rough Copper Vest in Blacksmithing) |
| **Craft window** | Detail icon when the recipe produces an equippable BiS item (First Aid, etc.) |

**Icons only, never list text:** In trainer and tradeskill windows, recipe **list rows are text buttons** (no item icon). The arrow must **not** appear next to recipe names in the scroll list — only on the **bottom detail/inset icon** (`ClassTrainerSkillIcon`, `TradeSkillSkillIcon`). List-row overlays are explicitly cleared on every refresh.

#### Trainer window (Class Trainer / profession trainers)

**Removed in v0.2.7.** Do not register `TRAINER_SHOW` / `TRAINER_UPDATE`, hook `ClassTrainerFrame_*`, or call `GameTooltip:SetTrainerService`. That scrape exceeded the Lua time cap and froze the client. New items come from Wowhead ingest only. Green arrows still apply on the player's **Trade Skill** window.

#### Trade Skill window (your profession UI)

| Topic | Detail |
|-------|--------|
| **Detail icon frame** | `TradeSkillSkillIcon` on classic clients (not `TradeSkillDetailIcon`). |
| **Hooks** | `TradeSkillFrame_Update`, `TradeSkillFrame_SetSelection` — register on `TRADE_SKILL_SHOW` / `ADDON_LOADED` if needed. |
| **Output link** | `GetTradeSkillItemLink(index)` when available; else tooltip `SetTradeSkillItem`. |

#### After obtain / profession completion

| Behavior | Rule |
|----------|------|
| **Arrow removal** | Once an item is obtained (`GearQuestDB.obtained`), its `itemId` is excluded from the indicator cache — arrows disappear on vendors, loot, recipes, and trainer UIs. Checkmarks on the character upgrade bar remain. |
| **Celebration toast** | `Toast.lua` shows “BiS upgrade obtained!” when a top-3 item is obtained or a tracked hunt completes. Click opens log on **Completed** tab. |
| **Profession hunts** | `sourceType = "profession"` completes only when the player **crafts** the item (`CHAT_MSG_SKILL` / `CHAT_MSG_LOOT`: “You create …”). Learning the recipe, buying, or looting the same item does **not** complete the hunt. **Party loot chat must be ignored** — only lines containing `You create`, `You receive loot`, or `You loot` may set `GearQuestDB.crafted[itemId]`. `GearQuestDB.crafted[itemId]` tracks craft completion; `obtained` persists if the item is sold. |

#### Data requirements for profession indicators

- `sourceType = "profession"`, valid crafted `itemId`, entry ranks in top 3 for the slot at the target level band.
- Add crafted output names to `PROFESSION_ITEM_NAMES` in `Data.lua` when trainer name-matching must work before `GetItemInfo` caches the item (new profession recipes).
- Optional `profession = "Blacksmithing"` (etc.) for labels; not used for arrow placement.

#### Maintainer checklist (trainer / tradeskill regressions)

- [ ] After `/reload`, open trainer **without** clicking the list — arrow on detail icon within ~1 s
- [ ] Arrow on **inset icon**, not on recipe name in scroll list
- [ ] Works **before** learning the profession (name / tooltip fallback)
- [ ] Blacksmithing window: arrow on `TradeSkillSkillIcon` when recipe selected
- [ ] Arrow gone after item obtained / hunt completed
- [ ] Profession hunt completes on **craft**, not on learning recipe at trainer

#### Related indicator code

| File / symbol | Role |
|---------------|------|
| `GearQuest/Indicator.lua` | `EnsureTrainerHooks`, `OnTrainerOpen`, `UpdateTrainerDetailIcon`, `UpdateTradeSkillDetailIcon`, `IsProfessionListRow`, `PROFESSION_ITEM_NAMES` via `Data:GetItemDisplayName` |
| `GearQuest/Data.lua` | `PROFESSION_ITEM_NAMES`, `GetItemDisplayName` |
| `GearQuest/Toast.lua` | Obtain celebration toast |
| `GearQuest/Log.lua` | Obtain detection, craft-only profession completion, Completed tab |
| `GearQuest/Popup.lua` | Green checkmarks on obtained upgrade bar icons |

---

## TBC endgame (level 70) — legacy (Forever)

**Not used in GearQuest Forever.** The section below documents the parent TBC Anniversary addon import workflow. Level 70 curated data was removed in migration phase 1.

## TBC endgame (level 70) — token vendors and drop descriptions (reference only)

When adding **Tier 5 / Tier 6 vendor pieces**, the `instructions` field must name the **actual item** and the **token boss** (not a random BT boss). Shaman uses **Defender** tokens (T5) and **Protector** tokens (T6).

### T6 token bosses (Protector — Warrior, Hunter, Shaman)

| Slot | Token | Boss | Zone |
|------|-------|------|------|
| Head | Helm of the Forgotten Protector | Archimonde | Hyjal Summit |
| Shoulder | Pauldrons of the Forgotten Protector | Mother Shahraz | Black Temple |
| Chest | Chestguard of the Forgotten Protector | Illidan Stormrage | Black Temple |
| Hands | Gloves of the Forgotten Protector | Azgalor | Hyjal Summit |
| Legs | Leggings of the Forgotten Protector | Illidari Council | Black Temple |

Vendor: **Tydormu** at Hyjal Summit. Set `sourceType = "vendor"`, `zone = "Hyjal Summit"`, `npc = "Tydormu"`.

### T5 token bosses (Defender — Warrior, Hunter, Shaman)

| Slot | Token | Boss | Zone |
|------|-------|------|------|
| Head | Helm of the Vanquished Defender | Lady Vashj | Serpentshrine Cavern |
| Shoulder | Pauldrons of the Vanquished Defender | Void Reaver | Tempest Keep (The Eye) |
| Chest | Chestguard of the Vanquished Defender | Kael'thas Sunstrider | Tempest Keep (The Eye) |
| Hands | Gloves of the Vanquished Defender | Leotheras the Blind | Serpentshrine Cavern |
| Legs | Leggings of the Vanquished Defender | Fathom-Lord Karathress | Serpentshrine Cavern |

Vendor: **Arodis Sunblade** in Shattrath. Set `sourceType = "vendor"`, `zone = "Shattrath City"`, `npc = "Arodis Sunblade"`.

### Special sources (not direct boss drops)

| Item | Correct description |
|------|-------------------|
| **The Sun King's Talisman** | `quest_reward` — Verdant Sphere from Kael'thas → quest *Kael'thas and the Verdant Sphere* with A'dal in Shattrath |
| **Totem of the Void** | Cache of the Legion in The Mechanar — combine crystals from Gatewatcher Gyro-Kill and Gatewatcher Iron-Hand |
| **Ring of Ancient Knowledge**, **Chestguard of Relentless Storms** | `raid_trash` — trash mobs in Black Temple (chest also drops Hyjal trash) |

### QA after endgame imports

```powershell
node scripts/import-atlasloot-p3-bis.mjs              # all Phase 3 spec lists → scripts/output/
node scripts/import-atlasloot-p3-bis.mjs ShamanElemental_P3   # single list
node scripts/qa-level70-drops.mjs
node scripts/qa-level70-verify-bosses.mjs
```

### AtlasLoot Phase 3 import (BT/Hyjal)

GearQuest can draft level-70 entries from **AtlasLootClassic_TBC_Phase_3_BT_Hyjal** (sliccer BiS lists in your WoW AddOns folder):

1. **`import-atlasloot-p3-bis.mjs`** reads ranked item IDs per class/spec/slot (top 3 by default).
2. **Wowhead TBC tooltip API** fills boss drops where available.
3. **Curated rules** handle T5/T6 token vendors, professions, PvP/badge vendors, quest rewards, raid trash, and Mechanar cache totem.

Output: `scripts/output/p3-bis-import.lua` + `.json` (review `needsReview` items before merging).

Requires AtlasLoot installed at  
`World of Warcraft\_anniversary_\Interface\AddOns\AtlasLootClassic_TBC_Phase_3_BT_Hyjal\phasethreeDB.lua`.

**Merge into Data.lua:**

```powershell
node scripts/import-atlasloot-p3-bis.mjs
node scripts/merge-all-p3-into-data.mjs
```

`merge-all-p3-into-data.mjs` replaces the entire `-- Level 70 band` section, injects class/spec constants, updates `CLASS_RANGED`, and **must** append the closing `}` for `GQ.Data.entries` (the import fragment is not a complete table).

Re-run after any `instructions` / `npc` / token-boss edits. Wowhead tooltip API is the primary check; token item IDs (e.g. 31095 Helm of the Forgotten Protector) confirm T6 boss assignments when vendor gear has no drop line.

---

## Data coverage (current)

| Band | Status |
|------|--------|
| **Level 1–9 Alliance** | Curated Warrior & Paladin; early generated bands for Hunter, Druid, Shaman, Rogue (`*Early1to9`) |
| **Level 1–9 Horde** | Generated Horde bands: Paladin (`paladinHorde1to9`), Warrior (`warriorHorde1to9`); early 1–9 for Hunter/Druid/Shaman/Rogue |
| **Level 10–69 all seven classes** | Generated (`*Picks`) — all specs per class, faction-gated rows in pipeline (TBC-era pool until Classic/Forever regen) |
| **Level 60 cap** | Addon and preview simulate **1–60** only |
| **Total** | **67,320** entries (287 curated + 67,033 generated) — `node scripts/verify-generated-bis.mjs` |

Empty Neck / Trinket / Head slots while leveling usually mean **missing data** for that class/band, not a broken addon.

**Open (addon UI):** Hunter/enhancement shaman can show a two-hander as #1 MainHand and dual-wield off-hand picks at the same time — the guide lists both routes; the addon should label or grey incompatible pairs (see weapon-slots note).

---

## External BiS data sources

| Source | Git / install | BiS lists? | Notes |
|--------|---------------|------------|-------|
| **[Hoizame/AtlasLootClassic](https://github.com/Hoizame/AtlasLootClassic)** | CurseForge “Source” link; `AtlasLootClassic-v3.2.0.zip` | **No** | Boss loot, crafting, factions, collections. **No** class/spec Phase 6 (Classic) or curated BiS sets in the official repo. |
| **AtlasLootClassic_TBC_Phase_* (Sliccer)** | Bundled with [AtlasLoot TBC 2026 Anniversary](https://www.curseforge.com/wow/addons/atlasloot-tbc-2026-anniversary); **no public Git** found | **Yes (TBC)** | `Phase_0` … `Phase_3` LoadOnDemand modules. GearQuest imports **Phase 3** (`phasethreeDB.lua`). |
| **[Warkdev/BestInSlotClassic](https://github.com/Warkdev/BestInSlotClassic)** | Abandoned ~2021 | **Yes (Classic 1–60)** | 34 specs, phases 1–6 for most classes. Different Lua format (`BIS_LINKS`). Best candidate if we add **level 60 Naxx** later — not AtlasLoot-shaped. |

Classic **Phase 6 (Naxx)** BiS is **not** in the Hoizame AtlasLoot zip. AtlasLoot **Favourites** can import item-ID lists from community gists; that is manual, not structured per slot.

---

## Known implementation notes (2026-08)

### Fixed

| Area | Issue | Fix |
|------|-------|-----|
| `Log.lua` | Any chat line with `item:` (including party loot) wrote `crafted` | Only `You create` / `You receive loot` / `You loot` |
| `Spec.lua` | Spec icons showed wrong class (talent-tab lookup on live player) | Curated icons from `CLASS_SPECS` only |
| `Spec.lua` | Preview spec choice overwrote real `specByClass` | `settings.preview.specByClass` when preview on |
| `Equip.lua` | Hunter/Shaman preferred Plate at 40 | `unlockMail = 40` → Mail |
| `Log.lua` | `arrowBtn` undefined → duplicate spec arrow | Removed bad assignment |
| Pipeline | Faction/rep leaks in generated 10–69 (BG sets, Tranquillien, mirrored reps) | Vendor/rep emit gates; `npc_faction.json` |
| `Compare.lua` | Level-60 guide bands re-sorted by runtime score | `origin="guide"` keeps pipeline `curatedRank` |
| `Compare.lua` | Priest staff lost to ilvl vs 1H+off-hand | Pipeline rank preserved for Priest/Mage/Warlock |
| `Data.lua` | Rogue item facts missing from `GetItemFact` | Added `rogueItemFacts` / `rogueEarly1to9Facts` |
| `Preview.lua` / `Minimap.lua` | Preview only via slash commands | Simulator handle tab (class/faction/spec/level); minimap any-click opens GearQuest |
| `Preview.lua` / `Core.lua` | Preview persisted across character logins | Reset preview on new character GUID at login |
| `Spec.lua` | `GetTalentTabInfo` 3rd return treated as points | Read 5th return on Anniversary; `tonumber` guard |

### Open (not yet addressed)

- Hunt state is **account-wide** (`SavedVariables`, not per-character) — `/gq wipe data` wording may mislead
- Tracker shows tracked hunts without re-checking current class/faction (cross-class hunts can linger)
- Hunter/enhancement shaman may show unequippable two-hand + off-hand weapon pairs at level 60 (data keeps both guide routes; needs UI labelling)
- `GET_ITEM_INFO_RECEIVED` registered on multiple frames without central debouncing (login/zoning cost)
- Quest-log reward arrows use retail frame names (likely inert on TBC 2.5)
- `Indicator.lua` `GetChildren()` unpacking; trainer frame allocation churn
- Repo root `_paladin-bis-extract/` is a superseded merge bundle — safe to delete; canonical files live under `GearQuest/_generated/`

### Code review reference

Internal review (Aug 2026) covered static analysis + coverage harness. Prioritize loot-handler and SavedVariables semantics before wide release; performance consolidation second; data breadth third.

