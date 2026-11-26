"""Keep content players cannot reach yet out of the hunt lists.

The Forever client has item rows for every Classic raid, but only the raids
in `openRaids` are in the game. `pipeline/data/forever_absent.json` lists:

- absentRaids: a boss drop, trash, rare, vendor, or quest reward filed
  in one of these gets obtainable false. Zul'Gurub is not open. A world
  drop keeps its row. Onyx Shredder Plate, Drake-scale Vest, and Gutrender
  are not Zul'Gurub mobs. The zone is Stranglethorn Vale, and that zone
  is locked. Wowhead files it as Zul'Gurub.
- worldBosses and absentBosses: a boss drop or rare from one of these
  names is the Boss drop flyout's Other bucket. That boss is not in a
  dungeon or raid that is in the game yet.
- knownBossDungeons: a boss drop with no zone is filed under that dungeon
  and stays. Antu'sul is Zul'Farrak, not Other.
- absentFactions: a reputation requirement on one of these does the same.
- items: single ids with the reason (a quest Forever does not offer, a
  plan that only drops in those raids, a test item).
- unreleasedNames: the whole item name. Signet Ring of the Bronze
  Dragonflight is the Ahn'Qiraj quest reward. Every rank of that ring
  stays out until Ahn'Qiraj is open.
- unreleasedNameParts: a piece of the name. Inquisition, Fireleaf, and
  Waywatcher are the Scarlet Enclave token sets. The client already has
  some Inquisition pieces, and those still stay out.

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
    outdoors = set(cfg.get("worldBosses") or []) | set(cfg.get("absentBosses") or [])
    known = cfg.get("knownBossDungeons") or {}

    excluded = restored = 0
    for key, src in sources.items():
        if not isinstance(src, dict):
            continue
        if src.get("sourceType") == "boss_drop" and not (src.get("zone") or ""):
            npc = src.get("npc") or ""
            if npc in known:
                src["zone"] = known[npc]
        names = [src.get("npc")] + [a.get("npc") for a in src.get("alts") or [] if isinstance(a, dict)]
        reason_key = reason = None
        if key in single:
            reason_key, reason = "item", single[key]
        elif src.get("sourceType") in EXCLUDE_TYPES or src.get("unconfirmedFrom") in EXCLUDE_TYPES:
            raid = raid_of(src, absent, boss)
            if raid:
                reason_key, reason = raid, f"{raid} is not in WoW: Forever yet."
        if not reason_key and src.get("sourceType") in {"boss_drop", "rare_npc"}:
            hit = next((npc for npc in names if npc and npc in outdoors), None)
            if hit:
                reason_key, reason = hit, f"{hit} is not in a dungeon or raid that is in the game yet."
        if not reason_key:
            # Season 1 sells the Premier epic. The unprefixed Field Marshal,
            # Warlord, Marshal, General, Grand Marshal, and High Warlord
            # pieces are in the client for a later season.
            item = items.get(key) or {}
            name = item.get("name") or ""
            if item.get("quality") == 4 and not name.startswith("Premier "):
                for title in cfg.get("season1LockedEpicTitles") or []:
                    if name.startswith(title):
                        reason_key = "season1-pvp"
                        reason = (
                            "Season 1 sells the Premier epic. "
                            "This unprefixed rank piece is not sold yet."
                        )
                        break
        if not reason_key:
            reps = (items.get(key) or {}).get("reqRep") or []
            hit = next((r[0] for r in reps if r and r[0] in factions), None)
            if hit:
                reason_key, reason = hit, f"{hit} reputation is not in WoW: Forever yet."
        if not reason_key:
            # The client already has some of these rows. A missing-item
            # refresh must not put the Scarlet Enclave sets or the Ahn'Qiraj
            # signet rings back on a hunt list.
            item = items.get(key) or {}
            name = item.get("name") or ""
            if name in set(cfg.get("unreleasedNames") or []):
                reason_key = "unreleased"
                reason = (
                    "The Path of the Protector, the Path of the Conqueror, and "
                    "the Path of the Invoker need Ahn'Qiraj. That raid is not open yet."
                )
            elif any(part in name for part in (cfg.get("unreleasedNameParts") or [])):
                reason_key = "unreleased"
                reason = (
                    "The Scarlet Enclave is not open yet. "
                    "These token sets stay out until it is."
                )

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
