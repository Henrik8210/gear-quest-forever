# GearQuest — add PRIEST (holy, discipline, shadow), levels 1–69

Sixth generated class. Same shape as the five already in, so this is an additive
change: two new data files, two `.toc` lines, two `SOURCES` rows. Nothing existing
needs restructuring.

## 1. Drop in the two new files

```
GearQuest/_generated/Data.Priest.generated.lua          (0.76 MB, 6663 picks)
GearQuest/_generated/Data.Priest.Early.1to9.generated.lua   (56 KB, 415 picks)
```

Tables they define: `priestItemFacts`, `priestPicks`, `priestNotable`,
`priestEarly1to9Facts`, `priestEarly1to9`.

## 2. Two lines in `GearQuest.toc`, after the rogue pair (currently lines 24–25)

```
_generated\Data.Priest.generated.lua
_generated\Data.Priest.Early.1to9.generated.lua
```

## 3. Two rows in `DataAdapter.lua`, appended to `SOURCES` after the rogue pair

```lua
  { class = "PRIEST",  picks = "priestPicks",      facts = "priestItemFacts",
    hasSpec = true,
    specs = { holy       = { holy       = true },
              discipline = { discipline = true },
              shadow     = { shadow     = true } } },
  -- Priest is in neither ALLIANCE_MAIL nor MAIL_MELEE, so it has no curated early
  -- data on either side and ships both factions in one file, each row naming its own.
  { class = "PRIEST",  picks = "priestEarly1to9",  facts = "priestEarly1to9Facts",
    hasSpec = false, factionInRow = true },
```

This has been tested: `luatest` loads all fourteen generated files plus Henrik's live
`DataAdapter.lua` with exactly these two rows added, and the expansion is clean.

## 4. `Spec.lua`

Priest needs its three specs registered: `holy`, `discipline`, `shadow`. Note the
generated data has all three at full coverage 10–69, so none of them should carry
`comingLater = true`.

---

# The priest-specific mechanics, and how each is modelled

Henrik: *"priests usually wear an off-hand type of item with a one hander or has a
two-hand staff and then a wand — stats are more important on the wand than the damage
at least in higher levels."*

**Proficiencies.** One-handed maces, daggers, staves and wands. No swords, no axes, no
fist weapons, **no shield**. Verified in the output: across all four spec blocks the
main-hand picks are only Mace1H, Dagger and Staff, and the off hand is 100%
held-in-off-hand items (orbs, tomes, stones) — never a shield, never a second weapon,
because a priest cannot dual wield.

**The wand.** The Ranged slot is wands and nothing else — 220 wands in the data, all of
them `InventoryType 26`. Wand damage is real but secondary, so the ranged dps weight is
small and non-zero rather than zero: enough to separate two wands with similar stats,
nowhere near enough to let a high-damage wand with no stats win. Shadow gets the larger
weight (0.15) because it actually wand-weaves; holy and discipline get 0.05. The result
is exactly the behaviour Henrik described — damage decides while nothing has stats,
stats take over completely once they appear:

| spec | level | #1 wand | from stats | from damage |
|---|---|---|---|---|
| shadow | 20 | Cookie's Stirring Rod | 0.0 | 3.3 |
| shadow | 40 | Lady Falther'ess' Finger | 9.5 | 5.7 |
| shadow | 60 | Wand of Qiraji Nobility | 19.5 | 15.3 |
| holy | 40 | Jaina's Firestarter | 5.2 | 2.0 |
| holy | 60 | Wand of the Whispering Dead | 35.8 | 5.7 |
| holy | 69 | Rejuvenating Scepter | 38.7 | 5.1 |

**Spirit.** Holy carries the highest spirit weight in the whole file (0.65). That is
Spiritual Guidance: 25% of Spirit becomes spell and healing power, on top of Spirit's
own regen. Discipline gets 0.55 — no Spiritual Guidance, but Meditation makes the regen
half worth more. This is the one real gear difference between the two healing specs, and
it is why they are separate spec blocks rather than one.

**Two guides, three specs.** The healing guide covers holy and discipline together, so
both specs share that list. Shadow has its own. The healing guide has **no wand
section**, so holy and discipline have no guide answer for the Ranged slot and the
model decides it — their guide denominator is legitimately one slot smaller (14 slots
against shadow's 15).

---

# Also in this bundle: the school-of-magic fix (R34)

Found while setting up shadow priest, and it changes four existing classes.

Item stats collapsed *"Increases damage done by Shadow spells"* and *"...by Fire
spells"* into a single key, `spSchool` — one number for all six schools. So a spec was
paid for schools it never casts:

* **Balance druid** (Arcane and Nature only) was paid for Robe of Winter Night's
  +Shadow damage in 12 level bands, Azure Silk Cloak's +Frost in 11, and Pulsating
  Hydra Heart's +Fire in 11.
* **Elemental shaman** (mostly Nature) was paid for Robe of Winter Night's +Shadow in 9.
* **Holy paladin** (Holy only) was paid for Death Speaker Scepter's +Shadow in 21 bands
  and Verdant Footpads' +Nature in 21.

The school is now captured per item — `spShadow`, `spFire`, `spFrost`, `spNature`,
`spArcane`, `spHoly` (93/82/79/22/13/2 items respectively) — and each spec names only
the schools it casts, weighted by how much of its damage that school is:

| spec | schools it is paid for |
|---|---|
| druid balance | Arcane 0.45, Nature 0.50 |
| shaman elemental | Nature 0.80, Fire 0.08, Frost 0.05 |
| paladin holy / prot / ret | Holy 0.15 / 0.05 / 0.02 |
| priest shadow | Shadow 0.95, Holy 0.03 |
| everyone else | none |

A second, smaller error came out of the same pass: `sp_from_heal` — the spell-damage
half of a *"+486 Healing and +162 Damage"* line — was weighted **zero** for Balance
druid and Elemental shaman. That 162 is ordinary spell damage. 1,178 items carry such a
line, and it is now worth full value to a caster DPS. This is what brought Wildfeather
Leggings and Battle Healer's Cloak into those lists.

### What moved

| class | cells changed | nature of it |
|---|---|---|
| druid | 270 | balance only — wrong-school items out, healing/damage items in |
| shaman | 304 | elemental only, same |
| paladin | 31 | holy and protection, small |
| warrior | 0 | scores shift by ~0.1 where a caster stat was on the item; **no reordering** |
| hunter, rogue | 0 | untouched |

Warrior's file is included only because the displayed score numbers move slightly. If
you would rather not re-run the two post-processing scripts for a cosmetic change, skip
it — no pick changes.

**Re-run `scripts/fix-edgemaster-warrior.mjs` and `scripts/fix-rare-elite-sourcetype.mjs`
if you do take the warrior file.**

---

# Verification

```
guide agreement (guide's best pick inside my top 3):
   priest  43/43   paladin 40/41   warrior 44/44   hunter 45/45
   druid   57/57   shaman  44/44   rogue   43/43
priest guide match was 43/43 on the first generation, no tuning

luatest, against Henrik's live DataAdapter.lua + the two PRIEST rows:
   generated rows expanded: 53895
   total entries: 55071  (1176 curated placeholders + 53895 generated)
   malformed generated entries: 0
   duplicate ids: 0
   second call is a no-op: OK

picks offered before an item's RequiredLevel: 0 (all seven classes)
suffixIds audited against the client data: 17604, value mismatches 0
role check OK, era check OK, off-hand check OK (3914 picks), ranged check OK
school check OK (474 picks carrying a school stat, 7 classes)
zero unmatched guide item names -- including six ROLLED names
   ("Archivist Cape of Healing", "Tearfall Bracers of Shadow Wrath" and four more),
   each resolved to its base item after confirming the base really rolls that suffix
```

New standing check: `check_school.py` — no weight block may use the school-blind
`spSchool` key, and no pick may owe its place to a school its spec does not cast.

---

# One thing for the UI, not the data

A priest's real choice is **a two-hand staff, or a one-hander plus an off-hand item**,
and the model ranks all of them in their own slots — so it can show a staff as the #1
main hand *and* an off-hand item as the #1 off hand, which you cannot equip together.
Same situation as the hunter two-hand/dual-wield pairing, but far more common here:
133 of 162 holy main-hand picks are staves.

The data does know which route actually wins, if the UI wants to say so. Best staff
against best one-hander + best off-hand, by level:

| spec | staff wins | 1H + off-hand wins |
|---|---|---|
| holy | 11–32, 54, 56 | 10, 33–53, 55, **57–69** |
| shadow | 17–22, **35–67** | 10–16, 23–34, 68–69 |

Happy to add a per-band `route = "staff"` / `"pair"` field so the addon can label it or
grey the row that does not apply — say the word and it is a regeneration, not a redesign.
