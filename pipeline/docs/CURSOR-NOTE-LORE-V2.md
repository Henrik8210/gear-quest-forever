# GearQuest — lore, second pass (R42)

Data only. No `DataAdapter.lua` or UI change from R40/R41; the `lore` and `route` fields
are unchanged in shape.

## What Henrik asked for

> "for gear I mean you had to explain some facts/story of the gear, fx. take bits of the
> quest input, but if it is not relevant in explaining the item's story just have the quest
> description as fallback. Example ... Might of Menethil, must have a story or at least
> King Menethil has, give some of that background rather than explain who Kel'Thuzad is —
> we have in descriptions who the boss is in those cases. And for the infamous Edgemaster's
> gloves we have no cool info — there must be a lot of community stories."

Three changes, in order of how much they matter.

## 1. Boss lore is now the LAST fallback, not the first

This was the real mistake. Might of Menethil shipped as:

```
instructions  Drops from Kel'Thuzad in Naxxramas.
lore          Once an archmage of the Kirin Tor, he left Dalaran to found the Cult of…
```

The description already names the boss, so the one interesting line was spent on
something already on screen. Priority is now **item's own story → the quest it came from →
the boss**. It reads:

```
instructions  Drops from Kel'Thuzad in Naxxramas.
lore          Menethil was the royal line of Lordaeron -- King Terenas, and his son
              Arthas, who became the Lich King. A warhammer carrying that name, guarded
              by the lich who served Arthas, is not an accident.
```

Boss lore still covers 619 items where the item itself has no story — better than blank,
and it no longer displaces anything.

## 2. Item-specific lore expanded from 9 entries to 45

Written where I can state something real, in three flavours:

**Named for someone.** Might of Menethil, Robes and Belt of Arugal (the archmage who
called the worgen to Silverpine and lost control of them), Galgann's Firehammer, Revelosh's
Spaulders, Ghamoo-ra's Bind, Bands of Serra'kis, Gloves of the Fang, Dal'Rend's pair,
Hand of Edward the Odd.

**Remembered for what they did.** This is the community-knowledge tier Henrik asked for.
Hand of Justice ("prints five Strength and eight Stamina and is worth vastly more than
that"), Manual Crowd Pummeler and why feral druids kept it, Flurry Axe, Vice Grips and its
7.9% of Strength roll, Lionheart Helm, Teebu's Blazing Longsword.

**The great named blades.** Corrupted Ashbringer, Anathema, Ashkandi, Bonereaver's Edge,
Perdition's Blade, Chromatically Tempered Sword, Maladath, Mark of the Champion, Onyxia
Tooth Pendant, Drake Fang Talisman, Zandalarian Hero Charm.

### Edgemaster's Handguards specifically

Henrik asked for this one by name, so I looked it up rather than writing from memory:

> Famous long before anyone worked out why. In Classic these carried +7 to axes, daggers
> and swords, and weapon skill quietly cut miss, dodge and parry AND the glancing-blow
> penalty — worth around 10% more damage to a dual-wielding warrior, and more still to
> anyone without a racial weapon bonus. Players dismissed them as junk mail until the maths
> got out, and the auction price went from a few gold to well past a hundred. In Burning
> Crusade the weapon skills are gone, replaced by +19 hit and +17 expertise — still
> excellent, no longer legendary.

The "dismissed as junk until the maths got out" and the price history are from the item's
own page, not invented. The Classic-to-TBC change is the one Henrik found himself.

## 3. Quest text now looks for the sentence about the item

It used to take the opening of the quest regardless. Now it finds the sentence that
actually names the item and uses that, falling back to the opening only when no sentence
mentions it. So a pair of gloves gets the line about gloves:

| item | before | after |
|---|---|---|
| Rabbit Handler Gloves | "What do we have here?" | "You look as though you might need something to keep your hands warm… a pair of nice, warm gloves." |
| Red Linen Sash | "The Defias gang in Northshire wears burlap masks…" | "…the Defias in Elwynn wear linen which I can use to make fine linen goods." |
| Totem of Infliction | "As the mystical taint creeps through the forest…" | "For you I shall enchant a Totem of Infliction which will harm those who attempt violence upon you." |

## What is still deliberately blank

Generic world-drop and crafted epics — Robes of Insight, Cloak of Fire, Gauntlets of the
Sea, Helm of Fire. They have no story, and 743 named items fall in that bucket. Inventing
something for them would undermine the 45 entries that are real. If you want any of them
filled, name the item and I will look it up properly rather than guess.

## Verification

```
18/18 generated files compile
luatest: total entries 68209, malformed 0, duplicate ids 0
lore rows: 3657   (was 3603)
   by source: item 45, quest 2627, boss 619
route rows: 5563  (unchanged)
```

Spot-check in-game: **Might of Menethil** (item story replacing boss lore), **Edgemaster's
Handguards** (was blank, now the community history), **Rabbit Handler Gloves** (quest text
now on-topic), and any Naxxramas epic without its own entry — that should still show the
boss note, which is the intended fallback.
