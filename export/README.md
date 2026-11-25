# GearQuest Forever rankings

`gearquest-forever.json` is the ranked gear the addon ships. It is for Dreamer's WoW Forever Guild Tracker and anyone else Henrik has allowed to show these lists. It is not part of the CurseForge package.

Regenerate it before every commit and push, and include the file in that commit when it changes. A push has to leave this file identical to the addon lists. CI runs `python pipeline/scripts/export_bot_json.py --check` and fails when the rankings, item facts, or level-60 pages differ. The generated time and the commit hash are not part of that check.

```
python pipeline/scripts/export_bot_json.py
```

Credit GearQuest Forever wherever a rank is shown, and link the addon. Do not republish the file itself. An item that is missing from a list was not ranked for that class, spec, faction, and level. It is not a bad item. Rankings move when weights or item facts change, so refresh from this file rather than caching a copy for a patch.

`addonVersion` is the addon version the lists were built from. `generated` is when this file was written. `commit` is the git revision at that moment. `tree` is `uncommitted` while the lists include work that is not on that revision yet.

## Shape

`items` is one record per item id: `name`, `quality`, `ilvl`, `req`, `source`, and whichever of `zone`, `npc`, `quest`, and `profession` apply. The parchment paragraphs stay in the addon.

`classes` holds every class. Each class is a list of bands:

`[spec, faction, slot, minLevel, maxLevel, picks]`

A pick is `[itemId, rank, score]` or `[itemId, rank, score, extras]`.

Rank 1 is the best piece on that list. `reserve: true` means the row is past the three hunts the log shows first. It is still that rank. A random enchant is ranked on its best suffix. Match `suffixId`, not the suffix name. `hand` and `route` say which weapon hand the row belongs to. `healOnly` is a healing weapon on a spec that also carries a damaging one.

Level 60 stays in score order. `origin: "guide"` and `guidePlace` mark a Wowhead Forever page piece, and `guidePlace` is its number on that page. Do not sort a band by `guidePlace`, and do not treat page place 1 as a score of 100. `level60Guides` is the page itself, in page order, with the Wowhead URL. Only Guide Gear, inside the addon, is what shows the page alone. The unprefixed Season 1 epic PvP titles are not in these lists. The Premier copies are.
