"""Keep content players cannot reach yet out of the hunt lists.

The Forever client has item rows for every Classic raid, but only the raids
in `openRaids` are in the game. `pipeline/data/forever_absent.json` lists:

- absentRaids: a boss drop, trash, rare, vendor, or quest reward filed in
  one of these (by zone, or by a boss in `dungeon_entrances.json`
  bossNpcs) gets obtainable false. A world drop keeps its row, because a
  misfiled zone on an outdoor mob (Onyx Shredder Plate) is not a raid.
- absentFactions: a reputation requirement on one of these does the same.
- items: single ids with the reason (a quest Forever does not offer, a
  plan that only drops in those raids, a test item).

Each row is marked with `absentRaid` (the reason key), so removing a raid
from absentRaids, or an id from items, makes the row obtainable again.
A row already excluded for another reason is left alone.

Run before the rescore. The rescore drops the excluded rows and the ranks
close up.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import DATA  # noqa: E402

CFG = Path(DATA) / "forever_absent.json"
SOURCES = Path(DATA) / "sources.json"
ITEMS = Path(DATA) / "items.json"
ENTRANCES = Path(DATA) / "dungeon_entrances.json"

EXCLUDE_TYPES = {"boss_drop", "raid_trash", "rare_npc", "vendor", "quest_reward", "object_drop", "unsourced"}


def raid_of(src: dict, raids: set[str], boss: dict) -> str | None:
    zone = src.get("zone") or ""
    if zone in raids:
        return zone
    for npc in [src.get("npc")] + [a.get("npc") for a in src.get("alts") or [] if isinstance(a, dict)]:
        if npc and boss.get(npc) in raids:
            return boss[npc]
    return None


def main() -> None:
    cfg = json.loads(CFG.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    boss = json.loads(ENTRANCES.read_text(encoding="utf-8")).get("bossNpcs") or {}
    absent = set(cfg["absentRaids"])
    factions = set(cfg["absentFactions"])
    single = cfg["items"]

    excluded = restored = 0
    for key, src in sources.items():
        if not isinstance(src, dict):
            continue
        reason_key = reason = None
        if key in single:
            reason_key, reason = "item", single[key]
        elif src.get("sourceType") in EXCLUDE_TYPES or src.get("unconfirmedFrom") in EXCLUDE_TYPES:
            raid = raid_of(src, absent, boss)
            if raid:
                reason_key, reason = raid, f"{raid} is not in WoW: Forever yet."
        if not reason_key:
            reps = (items.get(key) or {}).get("reqRep") or []
            hit = next((r[0] for r in reps if r and r[0] in factions), None)
            if hit:
                reason_key, reason = hit, f"{hit} reputation is not in WoW: Forever yet."

        marked = src.get("absentRaid")
        if reason_key:
            if src.get("obtainable") is False and not marked:
                continue
            if not marked:
                excluded += 1
            src["obtainable"] = False
            src["excludedBecause"] = reason
            src["absentRaid"] = reason_key
            continue
        if marked:
            src["obtainable"] = True
            src["excludedBecause"] = None
            del src["absentRaid"]
            restored += 1

    tmp = SOURCES.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(sources, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")
    tmp.replace(SOURCES)
    print(f"excluded {excluded} restored {restored}")


if __name__ == "__main__":
    main()
