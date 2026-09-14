# GearQuest — school-specific random enchants scored zero (R36)

## What Henrik found

At level 11 a **fire mage** was told to take Willow Belt **"of Healing"** (+7-9 Healing
Spells, +3 Damage Spells) over the same belt **"of Fiery Wrath"** (+4-6 Fire Spell
Damage). For a mage the healing half is worth nothing, so the pick was resting on the
+3 spell damage that rides along with it, while a roll giving up to +6 *fire* spell
damage sat unused.

## The cause — a regression I introduced two changes ago

When the school-of-magic fix went in (R34), item stats stopped collapsing
*"+Fire damage"* and *"+Shadow damage"* into one `spSchool` key and started naming the
school: `spFire`, `spFrost`, `spArcane`, `spNature`, `spShadow`, `spHoly`. Every weight
block then set `spSchool` to 0, since a school-blind number cannot tell a fire mage's
+Fire from a +Shadow item.

That fix was applied to `build_items.py` — the **base-item** stats — and **not** to
`build_random_wh.py`, the random-suffix table. So the suffix table kept writing
`spSchool`, whose weight was now zero everywhere:

| suffix | variants | was worth |
|---|---|---|
| of Arcane Wrath | 478 | 0 |
| of Nature's Wrath | 324 | 0 |
| of Fiery Wrath | 214 | 0 |
| of Shadow Wrath | 171 | 0 |
| of Frozen Wrath | 149 | 0 |

**1,336 variants across 681 base items**, every one of them scoring nothing for the
casters they were made for.

## Why the standing check missed it

`check_school.py` had two rules: no weight block may use the blended `spSchool` key, and
no pick may owe its place to a school its spec does not cast. Both passed — because
neither looks at random-suffix **variant** stats. The check was auditing the base-item
table and the weights, and the bug was in the third place.

Two new rules close that:

* **A2** — no random-enchant variant may carry the school-blind `spSchool` key at all.
* **C** — for any pick that ships with a suffix, that suffix's own stats must name a
  school rather than the blended key.

## A second regression, caught on the way

Renaming the keys broke `build_suffix_ids.py`, which resolves each variant to its client
suffix id by **value-matching** the stats. Its own label map still produced `spSchool`,
so it stopped matching, and **777 school variants silently lost their `suffixId`** —
coverage fell from 99.0% to 94.6%. That is the shape of bug the addon needs the id for:
without it, a rolled item falls back to matching on the suffix *name*, and "of Fiery
Wrath" has many tiers. Fixed; coverage is back to 17,604 / 17,789 (99.0%), all values
verified against the client data.

## What moved

242 cells across the nine classes. Only specs that value a school changed, which is the
right blast radius:

| class | cells |
|---|---|
| warlock | 87 |
| mage | 75 |
| priest | 44 |
| shaman | 25 |
| druid | 11 |
| paladin, warrior, hunter, rogue | 0 |

Henrik's row now reads, level 11 Waist:

| spec | #1 | suffix |
|---|---|---|
| **fire** | Willow Belt | **of Fiery Wrath** |
| frost | Willow Belt | of Healing — correct: Willow Belt does not roll *of Frozen Wrath* |
| arcane | Kessel's Cinch Wrap | — |

The score shown is still the **expected value** across all rolls weighted by their
chance, not the jackpot; the suffix named is the roll to hunt. That is the R21 design and
it has not changed.

## What to import

**All 18 files.** The four classes with no cell changes still change on disk, because the
777 restored `suffixId` values appear in their emitted rows too — that is a real
improvement for every class, not churn.

`Data.Paladin.generated.lua` is the only file that is byte-identical to what you already
have.

**Re-run `scripts/fix-edgemaster-warrior.mjs`, `fix-bow-searing-arrows-warrior.mjs` and
`fix-rare-elite-sourcetype.mjs`** after dropping these in — warrior, hunter and rogue
carry your post-processing and this replaces the raw generator output underneath it.

## Verification

```
guide agreement, unchanged everywhere:
   mage    39/39   warlock 45/45   priest 43/43   paladin 40/41
   warrior 44/44   hunter  45/45   druid  57/57   shaman  44/44   rogue 43/43

luatest against your live DataAdapter.lua + the six new SOURCES rows:
   generated rows expanded: 67096
   total entries: 68272   malformed 0   duplicate ids 0   second call a no-op

suffixIds audited against the client data: 17604, value mismatches 0  (was 16827)
school check OK   (now includes the two new variant rules)
off-hand check OK (4688 picks, and its default file list now covers all nine classes,
                   not the original six -- it had been silently under-covering)
ranged check OK, caster-weapon check OK, role check OK, era check OK
picks offered before an item's RequiredLevel: 0
```
