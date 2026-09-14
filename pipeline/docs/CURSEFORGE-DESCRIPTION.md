# GearQuest — CurseForge listing copy (rev 2)

Everything below is ready to paste. CurseForge has three separate fields; they're split out here so you can drop each one straight in.

Changes in rev 2, after Cursor's review: right-click is the correct paper-doll interaction, slot count corrected to 15, exact entry count replaced with "more than 68,000", toast wording tightened, weapon build labels added, level-70 spec footnote added.

---

## 1. Project summary (short description field, ~250 char limit)

**Use this one.** Benefit-first, and it doesn't read like a data dump:

> Best-in-slot gear for every class, spec and level 1–70. Right-click a slot, see the top three options with where to get them, pick one to hunt, and get a toast the moment it's yours.

Keep this in your back pocket if you later want the scale up front instead:

> More than 68,000 ranked gear options across all 9 classes, 28 specs and levels 1–70 — scored on your spec's actual stat priorities, not item level. Track a piece and GearQuest tells you when you get it.

---

## 2. Tagline / one-liner (for the header or Discord)

> Know what to wear. Know where it drops. Know the moment it's yours.

---

## 3. Full description (main body)

### GearQuest

**GearQuest answers one question, instantly, at any level: what is the best thing I could be wearing in this slot right now, and where do I get it?**

Open your character panel, right-click a slot, and GearQuest shows you the three best items for *your* class, *your* spec and *your* current level — with the stats, where each one comes from, and a one-click way to start hunting it. When you finally pick that item up, GearQuest marks it complete and congratulates you.

No spreadsheets. No alt-tabbing to a website. No guessing whether that quest reward is actually better than the blue you've been wearing since Hillsbrad.

---

### What makes it different

**It's ranked by your spec, not by item level.**

Every item in GearQuest is scored against a stat-weight profile built for one specific spec. A Fury warrior values hit and expertise very differently than an Arms warrior. A Balance druid wants Arcane and Nature spell damage — not Shadow damage, and not spirit. A Shadow priest doesn't care about the damage on a staff at all, because priests don't swing their staves. A Rogue wants stats on the ranged slot and nothing else; a Hunter wants the opposite. Every spec gets its own weighting, and it shows in the results.

**It knows about weapon rules.**

Whether a slot can even hold a weapon depends on your class and level. GearQuest knows when Dual Wield unlocks (and that Enhancement shamans get it from a talent), so a level 15 rogue sees off-hand items and a level 40 rogue sees one-handers. It knows the difference between a held-in-off-hand caster item and an actual off-hand weapon.

And where the choice is genuinely open — two-hander versus main-hand plus off-hand — GearQuest picks a side and tells you which. The weapon slot headers are labelled with the setup the list is built around: **Staff build**, **Two-hand build**, **Dual-wield build** or **One-hand + off-hand**. No more wondering whether the staff or the mace-and-tome is the play.

**Random enchantments are handled properly.**

"Of the Owl", "of Nature's Wrath", "of Fiery Wrath" — GearQuest doesn't just point at the base item and shrug. It names the exact suffix you want, the tier, and the stat range it rolls, so you know which version of that world drop you're actually looking for on the auction house.

**Levelling is a first-class citizen, not an afterthought.**

Most BiS lists start at 60. GearQuest covers **every level from 1 to 70**, with cumulative candidate pools — a level 34 character sees everything still available to them, not just level-34 items. Fresh alt, twink, or the awkward 50s, it has an answer.

**Faction-correct.**

Alliance and Horde get their own lists. No teasing you with a quest reward you can never take.

---

### Features

- **Top-3 per slot**, across all 15 gear lists — head through feet, rings and trinkets, both weapon slots, and the ranged/relic slot (with the right name for your class: bow, wand, libram, totem, idol)
- **All 9 classes and 28 specs** — including the odd ones out like Prot warrior, Holy paladin and Feral druid
- **Every level, 1 to 70**
- **Track a hunt** — pin one item as your goal and GearQuest keeps it in view
- **Toast on obtain** — when you pick up something GearQuest is recommending, or the piece you're tracking, it completes it and celebrates
- **The Log** — everything you've completed and everything you're still chasing, in one window. Left-click the minimap button to open it.
- **Paper-doll integration** — right-click any equipment slot in the character panel you already have open
- **Simulate panel** — right-click the minimap button to check what a different level, class or spec would want, for planning an alt or advising a guildmate
- **Where to get it** — every item carries a plain-language source: which quest, which boss and instance, which vendor, which zone for world drops, and whether the auction house is an option
- **Item lore and flavour** — over 3,600 items carry a line or two of story: what the quest was about, who the item is named after, or why the community remembers it. (Ask GearQuest about Edgemaster's Handguards.)
- **Notable extras** — items that don't crack the top three but are worth knowing about get their own shelf

---

### How the data was built

GearQuest's rankings are generated, then checked against the community's own conclusions.

The base data comes from the game client's own item tables — every item, every stat, every random-suffix allocation — filtered to what actually exists in TBC. Items are scored with per-spec stat weights, including proc and on-use effects valued in context (a proc on a weapon you never swing is worth nothing, and GearQuest knows it). The result is more than 68,000 ranked entries.

The generated lists were then compared, slot by slot, against the established level-60 best-in-slot guides for every spec:

| Class | Agreement |
|---|---|
| Druid | 57 / 57 |
| Warlock | 45 / 45 |
| Hunter | 45 / 45 |
| Shaman | 44 / 44 |
| Warrior | 44 / 44 |
| Priest | 43 / 43 |
| Rogue | 43 / 43 |
| Mage | 39 / 39 |
| Paladin | 40 / 41 |

Where a curated guide and the scorer disagree, the guide wins — hand-curated entries take priority in the display order, so you see the community's answer first and the raw score second. At level 70 the lists are curated from the current raid tiers, and a few specs with near-identical gear priorities share a pool.

**A deliberate omission:** GearQuest does not show drop chances. Sourcing accurate drop rates for tens of thousands of items isn't feasible to do honestly, and a wrong number is worse than no number. You get *where*, not *how likely*.

---

### Getting started

1. Install and reload.
2. **Right-click any equipment slot** in your character panel to see the top three for that slot.
3. Pick the upgrade you want to chase.
4. **Track it** if you want it pinned — then left-click the minimap button any time to open the Log and see everything you're chasing.

That's it. There's nothing to configure before it's useful.

---

### Compatibility

- **World of Warcraft: The Burning Crusade — Anniversary Edition** (Interface 20505)
- No dependencies, no external libraries required
- Data is read-only — GearQuest never equips, sells, or moves anything

---

### Feedback and requests

Bug reports, mis-ranked items and "why is X above Y for my spec" questions are all welcome — the last one especially. If a stat weight is wrong for a spec you play seriously, that's the kind of report that improves the addon for everybody. Please include your class, spec, level and the slot in question.

---

### On the roadmap

- **Filter by how you get it** — hide raid drops, dungeon drops or long quest chains so the list only shows gear you can realistically obtain solo or in a five-man
- Deeper level-70 raid progression tiers, and separate lists for the specs that currently share a pool
- Additional lore coverage for named items

---

## Notes for you (not part of the listing)

**Still to fix before the upload works:**

1. **`.toc`** still has `X-Curse-Project-ID: <YOUR_PROJECT_ID>` — CurseForge won't link the package until that's the real numeric project ID. (Confirmed still a placeholder in both your Projects and Desktop copies.)
2. **`Version: 0.1.0`** — worth bumping to `1.0.0` for the launch. Both copies still read 0.1.0.
3. **`.pkgmeta`** ships `GearQuest/_generated/` including the pipeline docs and JSON weights/guides that players don't need. Ignoring it keeps the download lean.

**On the entry count:** Cursor's verify says 68,520; my last measured build said 68,209. That's a real gap worth a glance — most likely a difference in what each side counts (notable-shelf rows, or the 1–9 band files) rather than missing data, but I haven't reconciled it. The copy says "more than 68,000", which is true either way, so it isn't blocking.

**Verified against your repo for this revision:** right-click on the paper doll (`PaperDoll.lua:36`), minimap left = Log / right = simulate (`Minimap.lua:79-86`), 15 slot categories with Finger and Trinket merged (`Data.lua:21150-21176`), build labels `Staff build` / `Two-hand build` / `Dual-wield build` / `One-hand + off-hand` (`Data.lua:22795`), and the toast firing off tracked hunts plus current top upgrades (`Log.lua:1231-1259`).
