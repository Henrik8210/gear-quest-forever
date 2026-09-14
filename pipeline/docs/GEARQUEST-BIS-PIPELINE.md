# GearQuest BiS pipeline — ruleset and playbook

How the generated BiS lists are built, every rule that was arrived at the hard
way, and what to do when the next class comes along. Written after Paladin, which
was the first class through and therefore paid for all the mistakes.

**Read the "Rules" section before touching weights.** Most of it exists because a
plausible-looking shortcut produced wrong data and Henrik caught it.

---

## 1. What this produces

Three top-ranked items per gear slot, per level, per spec, per faction, for
levels **1–69**. Level 70 is out of scope on purpose (§Rules R1).

| output | contents |
|---|---|
| `Data.Paladin.generated.lua` | 9,622 picks, levels 1–69, 3 specs, both factions |
| `Data.Paladin.Horde.1to9.generated.lua` | 221 picks, Horde only, levels 1–9 |

Levels collapse into bands: adjacent levels whose top three are byte-identical
merge into one `minLevel`/`maxLevel` row. Computed per level, emitted per band —
so the candidate pool at level 18 is everything with required level ≤ 18, and a
level-15 item still competes and can sit at rank 3.

---

## 2. Data sources, and which to trust

| source | used for | trust |
|---|---|---|
| **Wowhead tooltip dump** (`wowsims/tbc`, 30,005 items, cached from tbc.wowhead.com) | stats, item level, required level, slot, armour type, weapon damage/speed, sockets, phase, class restrictions, **effect and proc text** | **High.** This is what the player sees. |
| **cmangos tbc-db 1.11** (2.4.3 world DB) | item_template joins, loot tables, quests, vendors, professions, `AllowableClass`/`AllowableRace`, `RandomProperty`/`RandomSuffix`, **`quest_template.RequiredClasses` / `RequiredRaces`** | **Mixed.** Structural data good. Roll tables and some restrictions wrong — see R4, R7. |
| **wago.tools DB2 export**, build 2.5.4.44833 | `RandPropPoints`, `SpellItemEnchantment`, `SkillLineAbility` → crafted-item map | High. Diffed against 2.5.1: 1 row of 75 differed. |
| **Wowhead item pages**, scraped per enchant group | random-enchantment tables (589 requests, 0 failures) | **Authoritative.** Replaced the emulator data entirely. |
| **cmangos classic-db 1.12** | the set of 17,718 item IDs that existed in Classic | High. Used only to answer "is this a TBC item?" |
| **Wowhead Classic BiS guides** (3, one per spec) | the level-60 answer | Authoritative *for level 60*. Wrong era for anything else — see R9. |
| Henrik's curated level-70 AtlasLoot Phase 3 data | level 70 | Authoritative. Do not generate over it. |

### Scraping Wowhead random enchantments

Two non-obvious requirements, both essential:

1. The canonical item URL **403s from a datacenter IP**. Appending `?power`
   returns the same full HTML and is not blocked.
2. **Do not send a realistic Chrome User-Agent** — CloudFront blocks it. A plain
   honest UA passes.

```bash
curl -sSL --compressed -A 'wow-tbc-data-research/1.0' \
  'https://www.wowhead.com/tbc/item=1207?power'
```

Key by **enchant group**, not by item: chances and (for `RandomProperty` items)
stat values are group-constant, so one request per group covers every item in it.
`RandomSuffix` items scale with item level, quality and slot, so those need one
request each. For Paladin that was 589 requests instead of 887 items, ~15 minutes.

---

## 3. Rules

### R1 — Do not generate level 70
Measured: 0/44 exact match against Henrik's curated AtlasLoot data, 0.55/3
overlap. Phase-gating alone tripled overlap (158 of 252 picks were Sunwell items
in a Phase 3 list), and crediting sockets and penalising PvP gear still left
0/41 exact. It is structural, not tuning: at 70, BiS turns on **gem sockets, tier
set bonuses, libram/relic effects, weapon speed breakpoints, phase tier and
PvE-vs-PvP intent**. All 34 librams have empty stat blocks — their entire value
is spell effects. None of that exists below 60, which is why the model is
credible there and not here.

### R2 — A stated RequiredLevel is authoritative
Nothing may delay an item past its own required level. An earlier version added
an obtainability gate — for BoP items, the level of the creature that drops it,
minus two — which pushed **3,748 items** later than Wowhead says they are usable.
Might of Menethil (*Requires Level 60*, dropped by a level-63 Kel'Thuzad)
vanished from 60 and reappeared at 61.

The narrow exception: **1,369 items of item level 60+ genuinely state no required
level.** Taking that at face value put an item-level-55 chest at rank 1 for level
1. For those only, fall back to the source gate, backstopped by the median
required level of items at that item level (measured over the ~28,500 that state
one). Never for items that state one.

### R3 — Ranking is pure stat score, regardless of obtainability
Henrik's call: always show the genuinely best options; at least one of three is
usually gettable, and the auction house covers the rest. Random-enchantment items
are scored on their **best roll**, with the roll chance surfaced.

Consequence to accept: a level-60 player's BiS chest is legitimately a
Naxxramas drop. 542 picks (5.9%) come from vanilla 60-raid content. Naxxramas is
not removed until WotLK and Zul'Gurub not until Cataclysm, so they are live on
TBC realms — verified, not assumed.

### R4 — Random enchantments come from Wowhead, never from an emulator DB
`item_enchantment_template` is a community reconstruction and it is wrong in both
directions. For Murphstar's group it listed **32 suffixes summing to 128.48%**
against Wowhead's **11 summing to 99.8%**, put *of Intellect* at 0.1% instead of
7.3%, and invented two extra *of Healing* tiers. On a 66-item sample it was
*missing* suffixes Wowhead lists on 44 of them.

cmangos TBC, cmangos Classic and AzerothCore ship **byte-identical** rows, so no
emulator DB helps, and no client DBC carries the group mapping at all — which is
why every emulator hand-reconstructed it and they all share the errors. A
probability distribution cannot sum to 128%; that is the tell.

Also: 178 of 824 groups exceed 100%, and because cmangos truncates at 100% with
no `ORDER BY`, 30 of one group's 82 rows are unreachable on a live server. The
table does not even describe its own server's behaviour.

### R5 — Weights are ordinal-derived from TBC sources, adapted for levelling
TBC rewrote the mechanics the Classic weights were built on. Classic Seal of
Righteousness scaled off spell damage (`0.044/SP` per swing); TBC Retribution
uses **Seal of Blood** ("35% of your weapon damage") or **Seal of Command**, plus
**Crusader Strike** ("110% of weapon damage") — all weapon damage, none spell
damage. A spell-damage weight of 0.30 for Ret was an artefact of the wrong
expansion.

| spec | TBC priority (Icy Veins) |
|---|---|
| Retribution | hit → expertise → str → AP → haste → armour pen |
| Protection | defense (490 cap) → avoidance, **block > dodge > parry** → sta → **spell damage** → hit |
| Holy | healing → mp5 → spell crit → int → spell haste |

**Adapt, don't copy.** Those are level-70 raid priorities. Hit-to-cap, expertise
and armour penetration dominate a raid parse but barely appear on levelling gear,
and a linear weight cannot model a cap. Strength and weapon damage stay ahead of
them for 1–69.

### R6 — Weapon DPS is derived, not guessed
For a paladin: 1 Strength = 2 attack power, which buys `2/14` = 0.143 white dps,
`0.022 × 2` = 0.044 seal dps, and `0.225 × 2 / 10` = 0.045 judgement dps —
**0.232 dps per Strength**. So **1 weapon dps = 4.31 Strength**, independent of
weapon speed. Set `dpsWeight = str_weight × 4.31`.

**Protection is the exception.** The same derivation gave 2.37, which put pure-DPS
Naxxramas one-handers at the top of the *tank* weapon list. A tank's threat comes
from Holy damage — Seal and Judgement of Righteousness, Consecration, Holy Shield
— which scales off spell power and attack power, not weapon swings. Set to 0.5.

### R7 — Armour class is a multiplier, never a filter
Prot heavily favours plate, Ret mildly, Holy is near-indifferent and will take
cloth when the stats are better. Without this, Hunter and Rogue tier 3 outranked
Paladin tier 2 — plate versus leather at level 60 is ~200 armour, worth 3 points
to Ret, nothing against a tier set's stat budget.

| | Plate | Mail | Leather | Cloth |
|---|---|---|---|---|
| Retribution | 1.00 | 0.86 | 0.72 | 0.55 |
| Protection | 1.00 | 0.55 | 0.35 | 0.18 |
| Holy | 1.00 | 0.99 | 0.97 | 0.95 |

Holy's near-indifference is validated: 100% of its level-60 top picks are
endorsed by the Classic healing guide.

**The multiplier applies to the eight slots that actually have an armour class**
— Head, Shoulder, Chest, Wrist, Hands, Waist, Legs, Feet. Back, Neck, Finger,
Trinket and Ranged have none: every class wears the same cloth cloak. Applying
the Cloth figure to a cloak was ranking-neutral (a uniform factor inside one
slot, and Back is the only non-armour slot whose `kind` is in the table) but it
printed cloak scores five times smaller than they are, which makes the review
page unreadable. Proven neutral before changing it: 3,230 paladin bands, same
boundaries, **zero** changed top-3.

### R8 — Class and race gates live on the quest, not always on the item
Vanilla tier-3 pieces carry `AllowableClass = 32767` ("anyone"), so nothing on
the item stops a paladin list picking Warrior, Druid, Hunter, Rogue, Priest and
Shaman tier 3. The real gate is `quest_template.RequiredClasses` on the quest that
hands the piece over — 1 / 1024 / 4 / 8 / 16 / 64 respectively, and **2** for
Redemption, the paladin set. 969 quests carry a class lock; 422 items affected.
Fixing this took Holy from 62% to 81% agreement in one step.

Three more gates, all of which leaked at first:

- **`quest_template.RequiredRaces`** — captured for a long time and never used.
- **Class race sets are narrower than faction sets.** A Horde paladin is a Blood
  Elf and nothing else, so Orc, Tauren, Troll and Undead starting quests are as
  unreachable as Alliance ones. Using the blanket faction mask put Durotar and
  Mulgore gear in a Blood Elf's list. Same shape for Alliance Shaman (Draenei
  only) and Horde Druid (Tauren only).
- **Faction-exclusive zones.** A vendor standing in Darnassus is not
  race-restricted — the city is. Gate by zone name; only genuinely one-faction
  zones, since contested and Outland zones are reachable by both.

**Do not tighten this further, and do not loosen it.** Same-faction cross-race
travel is legitimate and must keep working: a Blood Elf can quest in Mulgore or
Tirisfal, a Draenei in Teldrassil. In the Blood Elf paladin 1–9 list, **46 of 69
zone-attributed picks come from other Horde races' zones** against 23 from its
own — that ratio is the check that the gate is not over-tight.

The reason it works: `RequiredRaces` is almost never race-narrow. 17,540 items
have mask `0` (no restriction), 498 have `1101` (all Alliance), 475 have `690`
(all Horde), 295 have `1791` (everyone). Genuinely race-narrow masks cover a few
dozen items in total.

Those few are real and must stay excluded — only 15 items for a Blood Elf and 7
for a Draenei:

- mask `16` / `32` — Undead-only quests in Deathknell, Tauren-only quests in
  Mulgore (*Ceremonial Tomahawk*, *Thunderhorn Cloak*).
- mask `178` (Horde minus Blood Elf) — the Valley of Trials racial intro chain.
- **Per-race reward variants of one quest.** *Umbral Axe/Dagger/Mace/Sword* are
  mask `68` (Dwarf|Gnome), *Moon Robes of Elune* mask `8` (Night Elf). A Draenei
  doing that quest receives the Draenei version. Dropping the race gate here
  would put four duplicate weapons in the same slot.

### R9 — Never calibrate against a Classic-era guide
The three Classic BiS guides are excellent *for level 60* and misleading anywhere
else. Agreement going **down** can mean the model got more TBC-correct: cutting
Ret's Classic spell-damage scaling dropped guide agreement from 77% to 54%, and
every one of the remaining misses was the guide buying an Avenger's **set bonus**
or an invisible **proc**, not a spell-damage item.

A calibration was run against these guides once — a Prot `dpsWeight` sweep. Wrong
method. The conclusion survived on independent TBC evidence, but the evidence
cited was the wrong kind.

**Measure precision fairly.** Raw hit-rate made Ret look terrible (36%) purely
because that guide lists ~1.7 items per slot while Holy's lists ~9.6 — three
picks cannot score against a one-item list. Use *"is the guide's BiS in my top
3"* and *"is my #1 anywhere in the guide's list"*.

### R10 — Level 60 comes from the guides, not the model
At exactly 60, the guide's order wins. A non-guide item may displace an entry
only if it beats the **best-scoring item the guide lists in that slot** by 20%
**and did not exist in Classic**.

*Best-scoring, not first-ranked.* Measuring against the guide's rank-1 pick makes
the test trivially easy whenever that pick is an item the model underprices.
*Kiss of the Spider* is the tank guide's #1 trinket and its entire value is a
20%-attack-speed on-use, which scores **12.2** for Protection — so a 20% margin
over *that* let TBC items in even though *Mark of the Champion*, on the same guide
list, scores **82.5**. Fixing the bar removed every warrior displacement and took
level-60 agreement to **44/44 on both metrics**; on paladin it changed 6 of 14,832
picks and removed the one displacement that was wrong (*Witching Band*).

That last clause is the crux. A first pass allowed 8 displacements and every one
was a Classic Naxxramas item — *Plated Abomination Ribcage*, *Mark of the
Champion*, *Wraith Blade*. The guide authors saw the whole of Classic itemisation
and ranked those below anyway, buying set bonuses the model cannot see. That is a
considered judgement and it stands. A TBC item is different: they never saw it.
Membership from the Classic 1.12 ID set.

Result: **41/41** guide BiS picks present for paladin, **44/44** for warrior.

Warrior's two displacements are both Protection, both TBC, and both worth reading
before accepting:

- **Trinket — Gnomish Poultryizer (45.0) over Drake Fang Talisman (24.5).** A TBC
  engineering trinket with a flat **+45 Stamina**, which is 450 health in a slot
  where Classic offered 56 attack power. It requires Engineering 340 *and* the
  Gnomish specialisation — but obtainability is not a ranking criterion (R3), and
  the requirement is in the instruction text.
- **Back — Scavenger's Cloak "of Stamina" (37.4) over Cloak of the Fallen God
  (30.1).** An ilvl-90 TBC green with a random enchantment. Under `bestRoll` a
  green's suffix budget beats an AQ40 epic whose budget is mostly agility, for a
  spec that values stamina at 1.00. The winning roll is 3.2% of drops, and the
  score column says so.

### R11 — Procs get a number, routed through existing currency
See `procs.py`. Damage → dps → × `dpsWeight`. Stat buff → stat × uptime × that
stat's weight. Mitigation → effective HP → × stamina weight ÷ 10 HP per point.
Nothing invents a new scale; a proc is priced against the same yardstick as a
point of Strength.

Proc rate uses the real TBC mechanic: **`chance = PPM × speed / 60`**, so
procs-per-minute is speed-independent and is the right unit. (The commonly cited
write-up prints this formula inverted; its own 44% worked example confirms the
form above.)

Every assumption is a named constant at the top of that file — `PPM_DEFAULT`,
`FIGHT_SECONDS`, `MELEE_SHARE`, `MIT_RELEVANCE`, `AOE_TARGETS`. They are
estimates, not sim output. **Amortise cooldowns**: a `max(1.0, …)` floor once
cancelled the divisor entirely and priced a 15-minute absorb as permanently up,
at 107.8 points — enough to displace the guide's tank trinket. And scale AoE off
the line's own damage; a flat bonus scored a 25-damage tick the same as
Thunderfury's 300-damage chain.

**Known limit:** the proc strip is itself ordered by printed stats, so it cannot
tell a world-class proc from a mediocre one. Thunderfury reaches 78.9 from 30.9
but still does not beat a 95-spell-power sword on the model alone. That is why
R10 exists.

### R12 — Exclude on evidence, never on absence of it
Two exclusion rules only, both requiring positive evidence of a dead end:

1. **Craft dead end** — a pattern/recipe *item* exists for the spell but has no
   source. *Plans: Onyxia Scale Breastplate* exists, requires Leatherworking 300,
   and drops from nothing. If **no** pattern item exists the recipe is
   trainer-taught and fine — that distinction is what wrongly deleted *Linen
   Cloak* and *Rough Copper Vest*.
2. **Test quest** — the only source is a quest titled `BETA…`/`TEST…`. Three
   rings worth 144 picks came from *"BETA Provoking the Warboss"*.

Plus a flat filter for **conjured/duration-limited items** — *Andonisus, Reaper
of Souls* exists for 5 real-time minutes and drains 5% health per second.

Items with no source anywhere are **flagged, never deleted**: `npc_vendor` holds
only 6.4k rows and `npc_trainer` only 388, so absence proves nothing.

The unresolved-source set is ~4,400 items and mostly developer junk (`Paladin 150
Epic Test Chest`, `Tom's Legs 3`, `Indalamar's Ring of 200 Crit`, `zzold`), so
excluding it by default is right. A **hand-verified allowlist** is the escape
hatch for real items whose chain the DB cannot express — legendary craft chains
like Sulfuras (Eye of Sulfuras + Sulfuron Hammer, not a `SkillLineAbility`
recipe). **Verify every ID against `item_template` by name before adding it.** An
ID went into that list labelled "Ashbringer" that was actually Andonisus.

### R13 — Do not put drop chances in the instruction text
The loot-table percentages are per-row group weights, not the drop rate a player
sees. Kel'Thuzad's Might of Menethil came out as "~100.0%" against Wowhead's
~14%. Name the source and stop there.

### R18 — A stun is worth zero. So is any PvP-only effect

Bosses and most elites are **stun-immune**, and *Tidal Charm*'s own tooltip says
"increased chance to be resisted when used against targets over level 60". It is a
PvP trinket. Priced as damage avoidance it earned 19.7 points — which was the
*entire* score of an item that has no stats at all — and put it in the top 3 for
64 per-level slots per class. *Dark Iron Pulverizer*'s 8-second stun earned 49.2.

The stun channel now returns zero and says why in the explanation line, so an
item whose only effect is a stun scores 0 and drops out entirely. At levels 36–39
that band went from *Tidal Charm* at 1.4 points to *Philosopher's Stone* (five
stats) at 8.3.

An attack-speed **slow** is different and keeps its value: it works on bosses, and
it is most of why Thunderfury is a tank weapon.

The general test for a proc channel: **would this fire, and matter, on a raid
boss?** Stun, fear, polymorph, disarm and "increased resilience" fail it. Damage,
absorbs, attack-speed slows, extra attacks and stat buffs pass.

### R19 — Keep the guide's Rank column. It is half the information

The first two warrior passes read the item names out of Wowhead's tables and threw
away the **Rank** column, leaving list position as the only signal. Wowhead ranks
rows *Insane / Best / Close Second / Best Mitigation / Great / Good / Hit
Alternative / Situational* — and inside a rank it is not claiming an order.

That is how **Thunderfury** ended up rank 2. The tank guide lists it and *The
Hungering Cold* both as **Best** main-hand swords; taking them in printed order put
Thunderfury second, even though the model scores it 180.8 against 157.8 and a second
Wowhead tank guide names it the outright best. Reading position as ranking invents a
judgement the guide declined to make, then defers to it.

Guide lists are stored as `[tier, name]` pairs and sorted by **(tier, −score)**: the
guide decides the tier, the model breaks the tie it never made.

```
0  Insane
1  Best                                            <- unqualified: the primary pick
2  Close Second / Alternative Best / Best Mitigation
3  Great
4  Good
5  Hit Alternative / Mitigation Alternative
6  Situational
```

A **qualified** best is not a plain best. Putting "Best Mitigation" level with "Best"
and letting the score decide pushed *Cryptfiend Silk Cloak* above *Cloak of the
Fallen God* for Protection — a stamina-weighted model always prefers the mitigation
piece, so tier 1 got overruled by the very thing the tier was there to constrain. A
**race** qualifier ("Best (Human)", "Best (Contested)") is not a downgrade.

`guide_tiers()` accepts both shapes, so a guide list of bare strings keeps the old
positional behaviour. Paladin is still on that format.

The metric changed with it: `guideBest-in-top3` asks whether **any tier-0/1 item** is
in the top 3, not whether one particular row is.

### R20 — PvP rank rewards are faction-exclusive, and the item does not say so

Every Classic PvP rank reward carries `AllowableRace = -1`. The gate is the
**quartermaster**, one join away from the item row — exactly the shape of R8, where
the class lock lives on the quest. So *Field Marshal's Plate Helm* and *Warlord's
Plate Headpiece* both sat in **both** factions' level-60 lists, along with
*Grand Marshal's Aegis* / *High Warlord's Shield Wall* and every Marshal's /
General's pair. 14 name families were leaking.

The side of each name family is **derived, not remembered**: for every rank-set
prefix, ask the world DB which quartermaster sells items with that prefix, and gate
the prefix only when every vendor row for it is on one side.

| gated | Alliance | Field Marshal's, Grand Marshal's, Knight-Captain's, Knight-Lieutenant's, Lieutenant Commander's, Marshal's, Master Sergeant's, Sergeant Major's, Stormpike |
|---|---|---|
| | Horde | Blood Guard's, Champion's, First Sergeant's, Frostwolf, General's, Grunt's, High Warlord's, Legionnaire's, Outrider's, Scout's, Warlord's |
| **not** gated | ambiguous | *Sergeant's* — the dataset has items sold by both sides' quartermasters |
| | no evidence | *Knight's*, *Commander's*, *Corporal's*, *Senior Sergeant's* — no vendor row at all |

Deriving it mattered: I would have gated "Sergeant's" to Alliance from memory, and
"Scout's" and "Grunt's" would have looked too generic to gate at all. The table lives
in `pvp_prefix_faction.json` and is regenerated, not edited.

Effect: faction-specific cells rose from 18% to **25%** of all spec/slot/level cells
for warrior. Paladin moved 252 cells (1.70%), 13 of them at level 60.

### R34 — The random-suffix tables are era-specific, and now checked, not remembered

Henrik: *"remember that those random stats/enchants items must be from tbc, not
classic"*. They are — the scraper reads `www.wowhead.com/tbc/item={id}?power` — but
nothing enforced it, so `check_era.py` now does.

The two eras really do differ, verified live on both namespaces for one item:

| Vice Grips (9640) | TBC — what we store | Classic |
|---|---|---|
| of Strength | **+20 Str @ 7.9%** | +17 Str @ 9.0% |
| of the Bear | 40.1% | 41.0% |
| of the Whale | +13/+13 @ 10.0% | +11–12 @ 9.2% |
| of the Gorilla | +13/+13 @ 4.8% | +11–12 @ 3.9% |
| of Healing | +37 healing **+13 spell damage** @ 1.3% | +37 healing only @ 2.0% |
| of Intellect | present @ 0.5% | **absent entirely** |
| resistances | 20 / 17 split | all 17 |

Six of sixteen suffixes differ, so a single item is a complete era fingerprint. The
stored data matches TBC on every one, including the two hardest to get right by
accident: the extra spell-damage component on "of Healing" and the existence of "of
Intellect" at all.

`check_era.py` asserts four things: the scraper URL is the `/tbc/` namespace, the Vice
Grips fingerprint matches TBC and not Classic, at least 20 random-enchant items sit at
ilvl ≥ 100 (a Classic-era scrape tops out near 90 — the real figure is 64, including
ilvl-117 Hellfire Peninsula gear), and `build_items.py` is reading the wowsims-**tbc**
tooltip set.

**One data source is Classic on purpose.** `classic_item_ids.json` (17,718 ids) answers
"did this item exist in Classic" for the level-60 displacement rule (R10): a TBC-only
item may displace a guide pick, a Classic-era one may not, because the guide authors saw
Classic itemisation and ranked it below anyway. That file must stay Classic, and the
check says so, so nobody "fixes" it later.

### R14 — Validate against something, and say what
Standing checks, all runnable per class:

| script | asserts |
|---|---|
| `check_levels.py` | no pick offered before its required level; lists anything first offered later |
| `guide_check.py` | agreement with per-spec BiS guides, both fair metrics |
| `compare.py` | generated vs Henrik's hand-curated data |
| `obtainability.py` | acquisition-chain audit, with false-positive controls |
| `out/verify.py` | renders the review page headless, both themes, asserts no console errors and no horizontal overflow |

Control sets matter more than scores. Every rule change is checked against
Henrik's 453 curated level-70 items and 184 curated 1–69 items; a change that
deletes any of them is wrong regardless of how good its reasoning sounds.

---

### R15 — A one-hander is a candidate for *both* hands

`slot_for()` returns one slot per item, so every `InventoryType 13` weapon
("Weapon", either hand) was **MainHand-only** and the off-hand pool was limited
to the handful of items flagged off-hand-only (`InventoryType 22`). For a
dual-wielding spec that is almost the entire candidate pool missing: the fury
guide's own off-hand list is inv-13 swords and axes — *The Hungering Cold*, *The
Castigator*, *Iblis*, *Maladath*. Fury off-hand agreement was 14/15 for exactly
this reason, and the one miss was the guide's #1.

The off hand gets its own copy of every one-hander, with the **weapon-damage
contribution halved** (Dual Wield's off-hand penalty). Stats and procs are worth
the same in either hand — only the swing damage is halved.

### R16 — Equipping an off-hand weapon requires Dual Wield

Dual Wield is a **learned skill at a specific level**, not a property of the item:
warriors and hunters at 20, rogues at 10, everyone else never. Without that gate,
*Left-Handed Brass Knuckles* (`RequiredLevel 10`, `InventoryType 22`) sat at rank 1
in a level-10 warrior's off hand — ten levels before the character can hold it.
And a fury-spec warrior below 20 still holds a **shield**, so excluding shields
from `onehand_dual` at all levels left that slot to caster held-in-off-hand junk
(*Buccaneer's Orb*, *Ritual Stein*) scoring 1.4 against a shield's 20.

```python
DUAL_WIELD_LEVEL = {"WARRIOR": 20, "ROGUE": 10, "HUNTER": 20}   # None = never
```

Paladin was clean by luck: it never had a dual-wield spec, so its off-hand lists
were shields and held-in-off-hand items only.

### R17 — An on-use effect fires on its cooldown, not at PPM_DEFAULT

`procs.py` charged every damage line at `PPM_DEFAULT` (2 procs/minute) when no
proc chance was stated. That is right for an on-hit proc and badly wrong for a
`Use:` effect, which fires **once per cooldown**:

| item | real cooldown | priced at | should be |
|---|---|---|---|
| Electromagnetic Gigaflux Reactivator | 30 min | 49.1 pts (98% of its score) | 0.8 |
| Goblin Bomb Dispenser | 10 min | inflated | ~0 |
| Thunderbrew's Boot Flask | 30 min | inflated | 0.2 |

With no cooldown stated, an on-use effect is assumed **once per engagement**.
On-hit procs are untouched — Thunderfury 92.6, Hand of Justice 25.5, Flurry Axe
12.4 all unchanged.

**And a quest-scripted effect is worth nothing at all.** *Sunwell Orb* reads
"Use: **Use on** Dar'Khan Drathir … causing 500 Arcane damage" — it only fires on
one quest NPC. The damage parser read it as a general nuke and priced it at 116
points, putting a green +3 Intellect off-hand at **rank 1 for every level from 1
to 19** in the Horde list. Any proc line matching `^use:\s*use\b` returns no
value. Only three items in the whole dataset match, and all three are quest items.

## 4. Doing the next class

1. **`ARMOR_PROF`** — add the class's armour proficiencies and the level the
   heaviest unlocks. Paladin/Warrior get plate at 40, Hunter/Shaman mail at 40.
2. **`CLASS_RACES`** — already filled in for all nine classes. Sanity-check the
   pair you are about to use.
3. **`_weaponSubclasses`** and `weaponStyle` per spec — `twohand`,
   `onehand_shield`, `onehand_dual`, etc.
4. **Weights per spec.** Find that class's TBC stat-priority pages first, then
   adapt for levelling per R5. Derive `dpsWeight` per R6, and check whether the
   spec is a threat/healing exception like Prot.
5. **`armorClass` multipliers** per spec (R7). A healer is near-indifferent; a
   tank is not.
6. **Find per-spec BiS guides for level 60** and add them to `guides.json` in
   rank order. Without them, level 60 falls back to the model, which R1's
   reasoning says is the weakest point in the range.
7. **Run the checks in R14** and read the displacement log — it is the most
   informative single output in the pipeline.
8. **Spot-check 10 items against Wowhead by hand.** Every serious bug in this
   project was found that way, not by a passing test.

### Class-specific traps to expect
- **Relics** — librams, idols, totems all have empty stat blocks. Whatever
  happened to Paladin librams at 70 will happen to Druid idols and Shaman totems.
- **Feral attack power** parses as a stat but is Druid-only; make sure no other
  class scores it.
- **Hunter** needs ranged weapon DPS as the primary weapon channel, not melee.
- **Dual-wield specs** need main-hand and off-hand handled as distinct slots with
  different weapon-damage value.
- **Spell-school-locked damage** (`spSchool`) is worthless outside that school —
  keep it separate from generic spell damage.

---

## 5. Honest state of it

**Solid:** item stats, required levels, sources, obtainability, class/race/faction
gating, random enchantments, the level-60 lists.

**Modelled, arguable:** every stat weight; every constant in `procs.py`; the
armour-class multipliers.

**Known blind:** tier set bonuses, gem sockets, relative proc quality, stat caps
(hit, defense, uncrushable), on-use cooldown stacking, weapon speed breakpoints.

**Unvalidated:** levels 1–59 and 61–69 for every spec. There is no professional
BiS list for TBC levelling — which is the whole reason this addon has a reason to
exist, and equally the reason nothing in that range has been checked by anyone
but Henrik.

---

## 6. Warrior — what the second class actually cost

Paladin paid for the rules above. Warrior was the first test of whether they
transfer. They mostly did: from a standing start the level-60 lists hit **43/44
(98%)** against the three Classic guides, and **42/44 (95%)** of the model's own
top picks were guide-endorsed. But five things needed real thought or were
outright bugs, and every one of them will recur.

### 6.1 The dpsWeight derivation does NOT transfer between classes

R6 gives 1 weapon dps = 4.31 Strength **for a paladin**. That number encodes
paladin mechanics — seals and judgements give Strength attack-power-only value a
warrior has no equivalent for. Redo the arithmetic per class:

| spec | derivation | result |
|---|---|---|
| **Arms** | 1 Str = 2 AP = `2/14` = 0.143 white dps. Mortal Strike, Whirlwind and Heroic Strike are all weapon-damage based and reach attack power through the same weapon-damage formula, so weapon dps and Strength scale them in step. | **7.00** |
| **Fury** | Bloodthirst is 45% of attack power with **no** weapon-damage component, on a 6s cooldown, so Strength buys `0.143 + 0.45*2/6` = 0.293 dps while a point of weapon dps still buys 1.0. | **3.41** |
| **Protection** | Threat is ability damage; Icy Veins puts Strength/AP **last** ("poor scaling"). | **1.75** |

Arms at 7.00 is **higher** than any paladin spec. Fury is less than half of Arms,
in the same class, because one ability scales off attack power instead of the
weapon. Copying a sibling spec's number would have been wrong by 2x.

### 6.2 Every class has a stat that is secretly a threat stat

Prot paladin's was spell damage. **Prot warrior's is block value**: one point of
block value is one point of Shield Slam damage. It is weighted 0.70 here, far
above what pure mitigation would justify. Look for this stat in every tank spec
before setting weights — it is never in the "defensive stats" list where you would
look for it.

### 6.3 New weapon style: `onehand_dual`

Fury dual-wields. Without a style that says so, the off-hand list fills with
shields, which a Fury warrior would never equip. `score.py` now supports
`twohand`, `onehand_shield` and `onehand_dual`; the last excludes shields from
`SecondaryHand` and two-handers from `MainHand`.

Verify after generating — this is a cheap check that catches a whole class of error:

```
arms         MainHand {'2H': 218, '1H': 4}   SecondaryHand {'weapon/held': 18, 'Shield': 36}
fury         MainHand {'1H': 273}            SecondaryHand {'weapon/held': 93}
protection   MainHand {'1H': 258}            SecondaryHand {'Shield': 232, 'weapon/held': 5}
```

(The Arms 1H and shield entries are all below level 20, where the style filter is
deliberately off because a low-level warrior may not have a two-hander yet.)

### 6.4 The Ranged slot is real for most classes

Paladin's `Ranged` slot holds a relic with no stats. Warrior's holds **bows, guns,
crossbows and thrown**, all with real weapon DPS. `_weaponSubclasses` must list
them or the slot comes out empty. Hunter will need this even more.

### 6.5 Bugs the paladin path was hiding

Three pieces of infrastructure were silently paladin-specific. All three produced
plausible-looking output rather than an error, which is what makes them dangerous:

- **`payload.py` had a hardcoded spec map.** `SPEC={"retribution":...,"protection":...,"holy":...}`
  meant `arms` and `fury` both looked up as `None` and emitted `spec=nil`, which
  collapsed two specs into **2,400 duplicate rows**. Now `{k:k for k in gen}`.
- **`shell.html` had a hardcoded `SPEC_ORDER`** and a default `state.spec` of
  `"retribution"`, so the Warrior review page rendered two specs and threw on load.
  Now derived from the data.
- **The `renderCheck` tab assumed a `compare` block existed.** Only Paladin has
  hand-curated 1-9 data to diff against; other classes ship without it.
- **The off-hand slot only ever held shields.** Paladin cannot dual wield, so
  `slot_for()` returning a single slot per item and the missing Dual Wield gate
  were both invisible. See R15 and R16 — the second class is where a class with
  two weapons finds them.
- **On-use effects were priced as if they had no cooldown.** Paladin has few
  gadget items in its top 3, so a 30-minute nuke charged at 2 procs/minute never
  surfaced loudly. Warrior's arms list put an engineering *helm* at rank 1 for
  its on-use lightning bolt. See R17.

### 6.6 Table naming and entry ids across classes

Paladin was first and its generated tables are **unprefixed** — `GQ.Data.itemFacts`,
`GQ.Data.paladinPicks`. Every class after it is **prefixed** — `warriorItemFacts`,
`warriorPicks`, `warriorNotable`. Nothing collides, so the shipped paladin file is
left alone rather than regenerated for cosmetics.

**The entry id must include the class.** Without it, a Paladin and a Warrior
Horde 1-9 row for the same item, slot and level collide, because both carry
`spec = nil`. Ids are now `gen:<class>:<itemId>:<slot>:<minLevel>:<spec>:<faction>`.

### 6.7 A guide "miss" is sometimes the data being more correct

Paladin Retribution Neck reads as a miss against the guide: the guide's BiS is
**Onyxia Tooth Pendant**, which the model does not pick for Alliance. It is a
quest reward in **Orgrimmar** — and it *is* the Horde pick. The Classic guides are
faction-agnostic; the generated data is not. Check the other faction before
treating a miss as an error.

---

## 7. Warrior, second pass — Henrik's own guide URLs and 1–9

### 7.1 Guide item names are split on commas and must be rejoined

The guide tables were parsed by splitting on `, `, which silently cut every item
whose name contains a comma into two unmatchable fragments:

| in the guide | stored as |
|---|---|
| Gressil, Dawn of Ruin | `Gressil` + `Dawn of Ruin` |
| Thunderfury, Blessed Blade of the Windseeker | `Thunderfury` + `Blessed Blade…` |
| Iblis, Blade of the Fallen Seraph | `Iblis` + `Blade of the Fallen Seraph` |
| Crul'shorukh, Edge of Chaos | `Crul'shorukh` + `Edge of Chaos` |
| Maladath, Runed Blade of the Black Flight | `Maladath` + `Runed Blade…` |

Neither fragment matches a real item name, so the guide override could not find
those items and the agreement metric was measuring against a list with holes in
it. `merge_guides.py` rejoins greedily against the real name set: if a fragment
does not match an item, try joining it with the next one or two.

**Every guide list must round-trip to zero unmatched names before it is used.**
After the merge: 373 names across three specs, 0 unmatched — which also validates
that Wowhead and this dataset agree on spelling.

### 7.2 Arms keeps its own weapon list; everything else is shared with fury

Henrik: *"Arms: cannot find, maybe use same as fury if it makes sense."*

For the twelve armour slots plus Ranged, yes — merged verbatim, they are the same
list. For **weapons, no**: the fury guide's Main Hand and Off Hand sections are
one-handers, and arms is a two-hand spec. Handing arms a one-hander list would
let it "hit" on items it can never equip and inflate the agreement number
against nothing. Arms `MainHand` stays the DPS guide's **Two-Hand** section.

### 7.3 Levels 1–9: Horde only, and that is complete

The rule from the paladin pass holds. Alliance 1–9 is hand-curated in
`Data.lua`, and for warrior it already exists — `ALLIANCE_MAIL = { WARRIOR = true,
PALADIN = true }` covers levels 1–4 and `MAIL_MELEE` (the same table) covers 5–14.
That is **252 curated rows a warrior can see below level 10**. Generating an
Alliance file would fight it for the same bands.

So the generated 1–9 file is Horde-only, gated on the class's own playable Horde
races (Orc, Undead, Tauren, Troll — never Blood Elf, who cannot be warriors) plus
the faction-exclusive-zone name gate. Coverage matches paladin's and adds Ranged:

| | paladin | warrior |
|---|---|---|
| picks | 221 | 248 |
| slots | 11 | 12 (adds Ranged) |
| levels per slot | 1–9 complete | 1–9 complete |
| bands with fewer than 3 picks | 2 (Head, Shoulder) | 2 (Head, Shoulder) |

Head and Shoulder are thin for both because below level 10 the only option either
faction has in those slots is the Midsummer Fire Festival crown and mantle.

No Finger or Trinket at 1–9: the earliest ring is *Woven Copper Ring* at
RequiredLevel 10. Henrik's curated data offers rings from 9 — a slightly more
generous read that the generated file does not contend with, since it stops at 9.

### 7.4 The paladin file needed a fix-only revision

R17 changed already-shipped data. Measured precisely rather than asserted:

- 14,832 per-level pick slots; **423 changed (2.85%)**
- **0 changes at level 60** — the guide-anchored data is untouched
- Guide agreement unchanged: **40/41**
- Out: *Electromagnetic Gigaflux Reactivator* (62), *Goblin Bomb Dispenser* (52),
  *Sunwell Blade* (22), *Sunwell Orb* (19), *Goblin Dragon Gun* (16),
  *Thunderbrew's Boot Flask* (13) — every one an on-use or quest-scripted effect
- In: *Philosopher's Stone* (5 stats), *Figurine – Truesilver Boar*, *Hand of
  Justice*, *Drake Fang Talisman* — ordinary stat items that were being outbid by
  a mispriced gadget

The facts table keeps its shipped name. `payload.py` emits `GQ.Data.itemFacts`
for paladin and `GQ.Data.<class>ItemFacts` for everything after it, so the
corrected paladin file is a drop-in replacement for the merged one.

### 7.5 Open calibration question — Manual Crowd Pummeler

*Manual Crowd Pummeler* (Uldaman, RequiredLevel 28, two-hand mace) scores 133
points of proc value from "Use: Increases your haste rating by 500 for 30 sec",
which is over half its total score and makes it rank 1 for arms from 28 to ~32.

Arguments it is right: it is the single most famous levelling weapon in the game
and every levelling guide ever written puts it first.

Arguments it is too high: the item has **3 charges** and is consumed, which the
tooltip text does not carry, and 500 haste *rating* at level 28 is being valued
with a weight derived at level 60–70.

Left as-is and flagged rather than quietly damped. Henrik's call.

### 7.6 Guide precedence: the guide *Henrik* supplied leads the order

The first warrior pass used a tank guide a subagent found; Henrik then supplied a
different one. Merging appended his list at the **tail**, which quietly left the
older guide's ranking in charge. Consequence: Protection Trinket read
*Drake Fang Talisman, Kiss of the Spider, Lifegiving Gem, Styleen's…* — the old
list's order — so **Mark of the Champion sat 7th and never reached the top 3**,
even though the supplied guide ranks it "Best" and dedicates a paragraph to it.

Rule: **the guide the user names is the authority**, and the fix that stuck was to
rebuild `guides_warrior.json` from his two URLs alone rather than merging orders at
all — see R19, which replaced position with the guide's own Rank column. Mark of the
Champion is rank 2 at level 60 for all three specs.

This is the same failure as the comma-splitting bug in 7.1: the override was
working exactly as designed, on a list that had been silently corrupted upstream.
Check the merged list itself, not just the agreement number — the agreement number
was 44/44 in both cases.

### 7.7 Final numbers

| | paladin | warrior |
|---|---|---|
| picks, levels 10–69 | 9,180 | 9,582 |
| picks, levels 1–9 (Horde) | 221 | 248 |
| level-60 guide BiS present | 40/41 | **44/44** |
| level-60 model #1 guide-endorsed | 39/41 | **43/44** |
| level-60 displacements | 3 | 1 (Prot Trinket) |
| picks offered below their RequiredLevel | 0 | 0 |
| duplicate entry ids | 0 | 0 |

Generated total 19,231. With 1,179 curated entries, `#GQ.Data.entries` is **20,410**.

Paladin's three remaining displacements are all real: *Garrote-String Necklace*
(TBC, Horde Retribution Neck) and *Bloodscale Bracers* over *Icebane Bracers*
(Protection Wrist, both factions).

### 7.8 What the level-60 Protection list looks like now

Worth reading as the end state of R10, R18 and R19 together — every row is a guide
row except one, and the order matches the guide's own tiering:

| slot | 1 | 2 | 3 |
|---|---|---|---|
| Head | Conqueror's Crown | Dreadnaught Helmet | Field Marshal's Plate Helm |
| Neck | Sadist's Collar | Stormrage's Talisman of Seething | Mark of C'Thun |
| Back | Cloak of the Fallen God | Cryptfiend Silk Cloak | Elementium Threaded Cloak |
| MainHand | **Thunderfury** | The Hungering Cold | Kingsfall |
| SecondaryHand | The Face of Death | The Plague Bearer | Grand Marshal's Aegis |
| Trinket | *Gnomish Poultryizer* | Mark of the Champion | Kiss of the Spider |

Note that the score column is *not* monotonic down these lists, and that is correct:
*Dreadnaught Helmet* scores 130.7 against Conqueror's Crown's 104.9 but the guide
calls the Crown the plain Best and the Helmet the Best Mitigation. Do not re-sort a
`origin="guide"` band by score.

The one exception is Protection Trinket. *Gnomish Poultryizer* is +45 Stamina flat;
the best-scoring trinket on the guide list for Protection weights is *Drake Fang
Talisman* at 24.5, and 45 clears the 20% bar. It stands under R10 as written, but it
is the one level-60 warrior pick that is the model's opinion rather than a
professional's.

---

## 8. Two more, found by Henrik pointing at one item

Henrik said Edgemaster's Handguards is BiS for warriors from 44 to 60. The model had
it at rank 2. Chasing that one disagreement found two scoring errors, both general.

### R21 — Rank on the expected roll; hunt the jackpot

`bestRoll` valued every random-enchantment item at its luckiest possible suffix while
fixed items competed at their actual stats. *Vice Grips* — a blue with sixteen
suffixes — scored 33.4 as "**of Strength**", a **7.9%** roll, and beat *Edgemaster's
Handguards*, a guaranteed epic with 19 hit and 17 expertise, on Hands for every level
from 44 to 55.

Henrik's rule is that ranking ignores **obtainability**, not that it assumes **luck**.
The stat score of a random-enchant item is what you get on average. Ranking moved to
the expected roll (chances sum to a median of exactly 100% in the Wowhead scrape, so
the expectation is well defined; where they fall short the missing mass is treated as
the plain item, which is conservative).

But the jackpot is the whole point of the hunt feature, and averaging alone deleted
Henrik's original example: *War Torn Tunic "of Strength"* at 9.5% went from rank 1 at
level 13 to invisible. So both numbers ship:

- **`score` and `rank`** — the expected roll. What to wear.
- **the notable shelf** — the item whose *jackpot* would have made the top 3, with its
  suffix and `suffixChance`. What to chase.

Level 13 Retribution chest now reads: wear *Runed Copper Breastplate* (6.2); hunt
*War Torn Tunic "of Strength"* — 4.7 expected, **6.5** if it lands, 9.5% of drops.

Side effects, all in the right direction: two level-60 paladin displacements
disappeared (they were jackpot-driven), model-#1-endorsed went 39/41 → **40/41**, and
band counts fell by about 15% because a lot of one-level flicker was roll noise rather
than real change.

**The notable shelf had a second bug hiding in it.** "Already shown" was tested
against all **eight** rows kept for review, but only **three** reach the addon — so
every notable item the model ranked 4th to 8th was silently swallowed, which is
exactly where a hunt target sits. Both of Henrik's original examples were in that gap.

### R22 — A stat conditional on creature type is not that stat

`Increases attack power by 60 when fighting Undead` was parsed by the generic AP
pattern and scored as a flat +60 attack power. *Gauntlets of Undead Slaying* took rank
1 on Hands at level 59 for both DPS specs, ahead of a guaranteed epic, on a bonus that
is zero against most of what you fight while levelling.

Conditional AP is now its own stat (`apVs`), weighted at **one third** of the spec's
AP weight, with the condition left in the instruction text. 41 items carry one —
Undead 15, Beasts 12, Demons 11, Dragonkin 2, Elementals 1. Nothing else moved:
exactly those 41 items changed in `items.json`.

### Where Edgemaster's landed

Rank 1 for arms and fury at 44–54, rank 2–3 at 55–58 behind *Backusarian Gauntlets*
(ilvl 60 plate, 15 str / 15 sta / 9 hit), out of the top 3 at 59, back at rank 2 at 60
where the guide places it. Henrik's repo carries a `fix-edgemaster-warrior.mjs` that
pins it to rank 1 through 59 — that is now a judgement call about a close race rather
than a correction of a bug.

---

## 9. Hunter — the third class, and the first with two weapon weights

### 9.1 R23 — dpsWeight is per-slot, not per-spec

Every class so far had one weapon and one `dpsWeight`. A hunter has two weapons that
could not matter more differently:

- The **ranged** weapon *is* the weapon. Auto Shot deals its damage directly, and in
  TBC Steady Shot also scales off weapon damage.
- The **melee** weapon is a stat stick. Its damage is never dealt — from the moment
  you have a pet and Auto Shot you are not swinging it.

One number for both would price a bow like a sword or a sword like a bow. So
`dpsWeightRanged` was added, defaulting to `dpsWeight` so no other class is affected.

`dpsWeightRanged = 23.8`, derived rather than guessed, in Agility:

```
1 Agi  -> 1 ranged attack power -> 1/14 = 0.0714 Auto Shot dps
1 ranged weapon dps -> 1.00 Auto Shot dps,
    x ~1.7 because TBC Steady Shot scales off weapon damage too, on a ~1.5s
      cadence against Auto Shot's ~3s
=>  1 ranged weapon dps = 1.70 / 0.0714 = 23.8 Agility
```

That is more than three times a warrior's 7.0, and it should be: the bow is the
single biggest item in a hunter's list. It shows in the scores — the level-60 Ranged
picks score 1,400–1,620 against 20–80 for everything else. Melee `dpsWeight` is
**0.0** from level 10 up; `levelling_1_9` keeps a real melee weight, because a hunter
under 10 genuinely does swing it.

Confirmation that it works: level-60 main hand comes out *The Eye of Nerub*,
*Kingsfall*, *Harbinger of Doom* — ordered by their stats, not their 85 / 73 / 65 dps.

### 9.2 R24 — Mirror pairs settle a faction when no vendor row does

R20 gated PvP name families by which quartermaster sells them, and left five
unsettled. That was about to cost something visible: the hunter guide's level-60 Legs
row is *Sentinel's Chain Leggings* (Alliance) beside *Outrider's Chain Leggings*
(Horde). *Outrider's* was gated Horde by 12 vendor rows; *Sentinel's* had **no vendor
row at all**, so it would have shown to both factions.

A second derivation rule closes it. Battleground reward sets come in exactly two
versions, one per faction, itemised identically — so a family that mirrors a gated
family on (slot, item level, armour class) in at least three places is the other side:

| ungated family | mirrors | on | verdict |
|---|---|---|---|
| Sentinel's | Scout's (Horde) | 10 keys | **Alliance** |
| Protector's | Legionnaire's (Horde) | 10 keys | **Alliance** |
| Senior Sergeant's | Master Sergeant's (Alliance) | 3 keys | **Horde** |

*Sentinel's Chain Leggings* and *Outrider's Chain Leggings* are both Legs / ilvl 65 /
Mail; *Protector's Band* and *Advisor's Ring* are both Finger at ilvl 23, 33, 43, 53
and 63. Nothing here is recalled — `build_pvp_factions.py` regenerates the table and
prints its evidence per family. 25 of 30 families are now gated; *Sergeant's* (items
on both sides), *Knight's*, *Commander's*, *Corporal's* and *Bloodguard's* remain
ungated and are printed rather than guessed.

### 9.3 Hunter setup

| | |
|---|---|
| specs | beast_mastery, marksmanship, survival — all three, though `Spec.lua` currently marks Marksmanship `comingLater = true` |
| armour | Mail from 40. **No plate, no shields.** `armorClass` is mild — Mail 1.00, Leather 0.95, Cloth 0.85 — because a hunter wants stats, not armour |
| weapons | Axe, Sword, Dagger, Fist, Polearm, Staff (melee); Bow, Gun, Crossbow, Thrown (ranged). **No maces** |
| primary stat | Agility at 1.00. `rap` 0.45 — 1 Agi gives 1 RAP *plus* crit, so it is worth about twice raw RAP. `hit` **2.20**, by far the highest of any spec so far: hit is king below the cap for a shot-based class. `str` 0.05, melee-only and near worthless |
| dual wield | level 20, same gate as warrior (R16) |
| verified | 0 plate / shield / mace picks; Ranged covered at every level 1–69; 45/45 guide agreement |

### 9.4 Levels 1–9: both factions, unlike the first two classes

Warrior and paladin ship a Horde-only early file because `ALLIANCE_MAIL` /
`MAIL_MELEE` in `Data.lua` covers those two classes by hand. **Hunter is in neither
table** — it has no curated early data on either side — so it ships one file carrying
**both** factions, 427 picks, and each row names its own faction. The adapter reads it
with `factionInRow = true`; without that flag every row would fall back to the
source's fixed faction, which is nil for this file.

### 9.5 Result

| | paladin | warrior | hunter |
|---|---|---|---|
| picks 10–69 | 9,183 | 8,094 | 7,233 |
| picks 1–9 | 221 (Horde) | 248 (Horde) | **427 (both)** |
| level-60 guide Best in top 3 | 40/41 | 44/44 | **45/45** |
| level-60 model #1 guide-endorsed | 40/41 | 43/44 | **45/45** |
| level-60 displacements | 1 | 1 | **0** |
| picks below their RequiredLevel | 0 | 0 | 0 |

Hunter is the first class where the model and the guide agree on every slot with no
displacement at all — which is what you would expect from a class whose best item in
each slot is decided by two stats and a weapon dps number.

---

## 10. Druid — the class where weapon damage is worth nothing

### 10.1 R25 — In Cat or Bear form the weapon's damage is never used

This is the biggest single class-specific trap so far, and it is not a subtlety: a
druid in form does not swing the weapon. Attack power in form comes from the weapon's
`+N attack power in Cat, Bear, Dire Bear and Moonkin forms only` line — the `feralAp`
stat, which 72 items carry — and from the druid's own stats. Weapon dps is inert.

So `dpsWeight = 0.0` for **all four** specs, and `feralAp` carries the same weight as
plain `ap`, because in form it *is* plain attack power. Only `levelling_1_9` keeps a
real weapon weight: Bear form is not learned until level 10, so before that a druid
genuinely does hit things with the stick.

The level-60 output is the proof, and it is why the guides' feral weapon lists look
deranged out of context:

| spec | rank 1 | dps | feral AP |
|---|---|---|---|
| feral | Manual Crowd Pummeler | 29.0 | none — it is there for the haste on-use |
| feral | Atiesh, Greatstaff of the Guardian | 64.3 | **592** |
| feral | Ursol's Claw | 57.5 | 197 |
| bear | Blessed Qiraji War Hammer | 60.7 | 337 |

A 29-dps mace beating a 64-dps staff is correct here. Had `dpsWeight` been anything
other than zero, the list would have sorted by a number the game does not read.

Druids also wear **leather and cloth only** — no mail, plate or shields — and use
Staff, Mace, Dagger, Fist and Polearm: no swords, no axes, and no ranged weapon at
all. The Ranged slot holds an **Idol**. Verified: 0 illegal picks across all 8,341.

### 10.2 R26 — A guide can print a rolled name that no item has

Three restoration rows named items that do not exist: *Archivist Cape of Healing*,
*Atal'ai Gloves of Healing*, *Drakestone of Healing*. Those are **random-suffix**
items and the guide printed the rolled name. The real items are *Archivist Cape* (16
possible suffixes), *Atal'ai Gloves* (14) and *Drakestone* (17), one of which is "of
Healing" in each case.

Guide lists store the **base** name, which is what the scorer matches. Which roll to
chase is the notable shelf's job (R21). This is why R19's "every guide list must
round-trip to zero unmatched names" matters as a hard gate — three silent holes in the
restoration list would have cost three guide matches and nobody would have noticed.

### 10.3 Four specs, four different anchors

| spec | anchor | notes |
|---|---|---|
| bear | `sta` 1.00 | `armor` **0.10** against a protection warrior's 0.06 on the same scale, because Bear form multiplies leather armour roughly 4.5x. `dodge` 0.70, `defense` 0.85 |
| feral | `agi` 1.00 | `str` 0.70 against `ap` 0.35 — 1 Str is 2 AP, 1 Agi is 1 AP plus crit plus dodge. `hit` 1.30 |
| balance | `sp` 1.00 | `feralAp` 0.02: nominally live in Moonkin form, but a boomkin never swings |
| restoration | `heal` 1.00 | `mp5` **2.20**, the highest weight of any stat in any spec so far |

`armorClass` splits hardest here: bear Cloth **0.30**, feral 0.55, balance and
restoration 0.98. A bear in a cloth chest is throwing away the thing bear form exists
to multiply; a boomkin does not care what the robe is made of.

### 10.4 Result

| | paladin | warrior | hunter | druid |
|---|---|---|---|---|
| specs | 3 | 3 | 3 | **4** |
| picks 10–69 | 9,183 | 8,094 | 7,233 | 8,341 |
| picks 1–9 | 221 (Horde) | 248 (Horde) | 427 (both) | **388 (both)** |
| guide Best in top 3 at 60 | 40/41 | 44/44 | 45/45 | **54/54** |
| model #1 guide-endorsed | 40/41 | 43/44 | 45/45 | 52/54 |
| displacements | 1 | 1 | 0 | 2 (both bear) |
| illegal gear picks | 0 | 0 | 0 | 0 |

**54/54** — the largest guide set so far (four separate guides, 296 tiered entries) and
every one of their top-tier picks is present. The two bear displacements are both
TBC-over-Classic: *Mok'Nathal Clan Ring* over *Band of Accuria*, and *Gnomish
Poultryizer* over *Drake Fang Talisman* — the same +45 Stamina engineering trinket that
displaces for protection warrior, which is at least consistent.

Druid, like hunter, is in neither `ALLIANCE_MAIL` nor `MAIL_MELEE`, so it ships both
factions in its 1–9 file. Its race gate is the narrowest of any class — Night Elf on
Alliance, Tauren on Horde, nothing else — so those two lists diverge more than any
other class's.

### 10.5 R27 — `haste` is not `spellHaste`. Neither substitutes for the other

Henrik: *"haste is not spell haste so the manual crowd pummeler doesn't work for
balance and resto"*. Correct, and it was worse than one item.

`haste`, `crit` and `hit` are the **melee and ranged** ratings. `spellHaste`,
`spellCrit` and `spellHit` are different stats. The weight tables carried small
nonzero melee weights on caster specs — Balance and Restoration both had
`haste = 0.05` — which is enough to matter when an item hands over a big number:
*Manual Crowd Pummeler*'s "+500 haste rating" scored 500 x 0.67 uptime x 0.05 = **16.7
points** for a druid who cannot use a single point of it. It held 12 Balance picks and
4 Restoration picks.

The fix is a rule, not a patch. A **pure caster** spec carries **zero** melee offence:

```
ap  rap  feralAp  crit  hit  haste  expertise  armorPen  wpnDmg  wpnSkill  str
```

and a **pure physical** spec carries **zero** spell offence:

```
sp  spSchool  spHoly  heal  sp_from_heal  spellCrit  spellHit  spellHaste  spellPen
```

31 weights were zeroed across five specs. Small **defensive** weights stay — agility,
dodge, parry, block — because those are real for anyone. **Hybrid tanks are exempt on
purpose**: paladin protection and warrior protection genuinely swing *and* have threat
abilities that scale with spell power, so they keep both sides.

`check_roles.py` now enforces the invariant and runs with the other standing checks.
Without it the same error will arrive with priest, mage, warlock and shaman.

What it moved, and it was not only the Pummeler — melee-stat staves were winning
caster weapon slots too:

| class | cells changed | at level 60 | what left |
|---|---|---|---|
| druid | 92 of 19,973 (0.46%) | **0** | Manual Crowd Pummeler (47), Kam's Walking Stick (16), Advisor's Gnarled Staff, Lorekeeper's Staff |
| paladin | 6 of 14,832 (0.04%) | 2 | Scrolls of Blinding Light, Ironpatch Blade |
| warrior | 7 of 15,966 (0.04%) | 0 | spell-power chests on Arms — the mirror error |

Guide agreement unchanged: druid 54/54, warrior 44/44, paladin 40/41.

---

## 11. Shaman — and the empty slot three classes had been shipping

### 11.1 R28 — Relics score zero on stats, and `if s<=0: continue` deleted the slot

108 relics in the dataset — Libram, Idol, Totem — and **only two carry a single
stat**. Their entire value is an effect line: *"Increases healing done by Lesser
Healing Wave by up to 80"*. A stat-weight model scores that at exactly 0, and the
`if s<=0: continue` guard then discarded every one of them.

**Paladin, druid and shaman were all shipping with an empty relic slot.** Nothing
caught it, because the guide-agreement denominator only counts slots that produced a
band — so paladin read 41/41 and druid 54/54 while both were silently missing a slot
the guide had an entry for. The metric was measuring 14 slots and calling it all of
them.

Two fixes together:

**Ordering.** Relics improve strictly within a spell line, so **item level** is a
genuinely good ranking for them, and at 60 the guide decides anyway. The score is set
to `ilvl x 0.01` — an ordering key, not a value — which is safe because scores are only
ever compared inside one slot.

**Spec relevance.** ilvl alone gave every paladin spec the same three *healing*
librams and handed a Balance druid healing idols. A relic's effect names the **ability**
it buffs, and abilities belong to specs, so the keywords are read straight off the
effect text — *"Flash of Light"*, *"Claw and Rake"*, *"Stormstrike"*. A relic naming an
ability the spec does not have is not eligible for it; one naming nothing recognised is
kept, which is the conservative direction.

Before and after, at level 60:

| spec | ilvl order alone | with the ability filter |
|---|---|---|
| paladin retribution | Libram of Light, Grace, Divinity *(all healing)* | **Libram of Fervor**, Libram of Hope |
| paladin protection | Libram of Light, Grace, Divinity | **Libram of Fervor**, Libram of Truth |
| druid balance | Idol of Longevity, Health, the Moon *(two healing)* | **Idol of the Moon** |
| shaman elemental | — | **Totem of the Storm** |
| shaman enhancement | — | **Totem of Rage** |

Denominators corrected: paladin 40/41 (was measured over 41 of a real 41 — unchanged),
druid **57/57** (was 54/54 over 14 slots), shaman **44/44** over the full 15.

### 11.2 R29 — Dual Wield can be a talent, not a class skill

For a shaman, Dual Wield is an **Enhancement talent**. Elemental and Restoration can
never hold a weapon in the off hand at any level, and Enhancement not before ~30 (when
20 points of the tree is reachable). `DUAL_WIELD_LEVEL` now accepts a per-spec dict:

```python
DUAL_WIELD_LEVEL={"WARRIOR":20,"ROGUE":10,"HUNTER":20,
                  "SHAMAN":{"enhancement":30}}
```

Verified: 59 off-hand weapon picks for enhancement, earliest at level **30**; **zero**
for elemental and restoration, whose off hand is shields and held items throughout.

### 11.3 Shaman setup

| | |
|---|---|
| specs | elemental, enhancement, restoration |
| armour | Mail from 40, plus shields. Elemental and Restoration carry **no armour-class preference at all** — their guide BiS lists are largely cloth (Mish'undare, Bloodvine, Crystal Webbed Robe), so a mail preference would fight the professionals |
| weapons | Axe (1H/2H), Mace (1H/2H), Staff, Dagger, Fist. **No swords, no polearms** |
| enhancement dpsWeight | **18.0** in Agility — 1 Agi = 1 AP = 1/14 white dps plus crit ≈ 0.089; 1 weapon dps = 1.0 x ~1.6 for Windfury and Stormstrike both scaling off weapon damage. The least certain of the three weapon derivations: the 1.6 is a judgement about how much of enhancement rides on weapon damage |
| verified | 0 illegal picks; level-60 enhancement main hand is three two-handers (Might of Menethil 95.3 dps, Dark Edge of Insanity 86.6, Severance 81.8), matching the Classic guide, which lists only two-handers |

### 11.4 R30 — The unmatched-name gate also catches a bad *fetch*

The enhancement guide's head row came back from the page fetch as *"Face of The Five
Thunders"*. No such item exists — the tier-1 shaman head is **Coif of The Five
Thunders**. That was the summariser mangling a name, not a random-suffix roll (R26) and
not a comma split (7.1). Three different failure modes, all caught by the same rule:
**every guide list must round-trip to zero unmatched names before it is used.**

### 11.5 Result

| | paladin | warrior | hunter | druid | shaman |
|---|---|---|---|---|---|
| specs | 3 | 3 | 3 | 4 | 3 |
| picks 10–69 | 7,092 | 8,106 | 7,233 | 8,398 | 6,379 |
| picks 1–9 | 221 | 248 | 427 | 388 | 433 |
| guide Best in top 3 | 40/41 | 44/44 | 45/45 | **57/57** | **44/44** |
| model #1 endorsed | 40/41 | 43/44 | 45/45 | 55/57 | **44/44** |
| illegal gear picks | 0 | 0 | 0 | 0 | 0 |

Generated total **38,925**; with 1,177 curated, `#GQ.Data.entries` is **40,102**.
Five classes done. Remaining: rogue, priest, mage, warlock.

---

## 12. Rogue — the hunter mirrored, and an off-hand penalty that was half missing

### 12.1 R31 — Dual Wield halves off-hand damage for EVERY off-hand weapon

R15 gave the off hand its own copy of each one-hander with the weapon-damage half of
its score halved, for the Dual Wield penalty. That was right and incomplete: it applied
only to the **duplicated** items. An `InventoryType 22` weapon — off-hand *only* —
reaches the slot through `slot_for` on the normal path, and was being paid **full**
weapon dps for a swing that lands at half.

*Shekketh Talons* is a TBC fist weapon with **47.9 dps and no stats at all**. At full
weight it scored 718 and displaced *The Hungering Cold* (73.0 dps, 14 stamina, 14
expertise) from the off hand of **all three rogue specs**. The number was arithmetically
impossible on the face of it — a weapon with fewer stats and less damage cannot score
higher — which is what made it findable.

The halving now applies to any weapon in `SecondaryHand`, whichever route it took:

```python
dw = dpsWRanged if sl=="Ranged" else dpsW
if sl=="SecondaryHand": dw *= 0.5
```

It moved fury warrior too, which had been carrying the same inflation since R15:
**207 cells (1.30%), every one of them fury `SecondaryHand`, none at level 60** —
*Claw of Celebras*, *Left-Handed Blades*, *High Warlord's Left Claw* and other inv-22
weapons dropping back to their real value.

### 12.2 R32 — A spec can be weapon-type LOCKED, and that is a filter

Armour class is a multiplier, never a filter (R7). Weapon *type* sometimes is. Backstab,
Ambush and Mutilate do not fire with a sword — an Assassination or Subtlety rogue
holding one loses its rotation, which is a hard mechanical gate like plate proficiency,
not a preference. So specs may declare `mainHandKinds`:

```python
"assassination": {..., "mainHandKinds":["Dagger"]},
"subtlety":      {..., "mainHandKinds":["Dagger"]},
"combat":        {...},                    # Henrik: "both combat with sword or dagger"
```

Verified: assassination and subtlety are **228/228 Dagger** in the main hand; combat
takes swords, daggers, maces and fists.

### 12.3 R33 — One guide page, three spec lists, and a slot the guide does not cover

The rogue guide is a single page covering two builds, and Henrik flagged it: *"There's
both combat with sword or dagger"*. The three spec lists are **derived** from it rather
than copied three times:

- `Main Hand (Swords)` and `Off Hand (Swords)` → **combat only**. A sword list is not a
  dagger-locked spec's list.
- `Off Hand (Daggers)` → all three.
- Rows the guide labels **"Swords Best"** → tier 1 for combat, one tier lower for the
  two dagger specs. **"Daggers Best"** → tier 1 for all three, because combat-daggers is
  a real build.
- `"Human Best"` / `"Non-Human Best"` → race qualifier, demoted one tier (R19).

**There is no dagger main-hand table on the page.** Verified by a second targeted fetch:
*"There is no separate Main Hand section for daggers on this page."* So assassination and
subtlety have **no guide main hand at all** and the model decides it, dagger-restricted.
Their denominator is one slot smaller than combat's — 14 against 15 — and that is
correct: the guide does not cover it, so there is nothing to agree with. Do not pad a
denominator to make three specs look symmetrical.

### 12.4 Rogue setup — the hunter, inverted

| | |
|---|---|
| specs | combat, assassination, subtlety — `Spec.lua` marks the latter two `comingLater = true`; there is data for them now |
| armour | **Leather and cloth only.** No mail, no plate, no shields |
| weapons | Dagger, Sword (1H), Mace (1H), Fist; Bow, Gun, Crossbow, Thrown. **No axes, nothing two-handed** |
| `dpsWeight` | **15.0** melee — 1 Agi = 1 AP = 1/14 white dps plus crit ≈ 0.095; 1 weapon dps = 1.0 × ~1.5 for Sinister Strike, Backstab and Eviscerate riding on weapon damage |
| `dpsWeightRanged` | **0.0** — the exact inverse of the hunter. A rogue never fires the bow; it is a stat stick. Level-60 Ranged comes out *Crossbow of Imminent Doom* (50.8 dps) and *Striker's Mark* (48.4) **above** *Nerubian Slavemaker* (67.5), ranked purely on stats |
| `hit` | **1.90–2.00**, the highest physical hit weight in the project. The dual-wield miss penalty punishes being under the cap harder than for any other class |
| Strength | 1 AP per point, not 2 — that is warriors and paladins only |
| verified | 0 illegal picks; 0 two-handers; dagger lock 228/228 |

### 12.5 Result

| | paladin | warrior | hunter | druid | shaman | rogue |
|---|---|---|---|---|---|---|
| picks 10–69 | 7,092 | 8,136 | 7,233 | 8,398 | 6,379 | 7,314 |
| picks 1–9 | 221 | 248 | 427 | 388 | 433 | 429 |
| guide Best in top 3 | 40/41 | 44/44 | 45/45 | 57/57 | 44/44 | **43/43** |
| model #1 endorsed | 40/41 | 43/44 | 45/45 | 55/57 | 44/44 | **43/43** |
| displacements | 1 | 1 | 0 | 2 | 0 | **0** |
| illegal gear picks | 0 | 0 | 0 | 0 | 0 | 0 |

Generated total **46,698**; with 1,177 curated, `#GQ.Data.entries` is **47,875**.
Six classes done. Remaining: priest, mage, warlock — all three casters, which is where
`check_roles.py` (R27) earns its keep.
