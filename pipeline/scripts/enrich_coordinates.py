"""Fill coordinate gaps from the other developer's Questie location index.

Keeps every pin we already published. Only hunt items in
pipeline/data/coordinate_gaps.json are considered. A spot is used when his
index has a real coordinate on a named classic map. Zone-center 50,50 pins
and continent maps are skipped.

    python pipeline/scripts/enrich_coordinates.py
    python pipeline/scripts/enrich_coordinates.py --write
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commerce_camps import CAMP_NOTE, camp_pins

ROOT = Path(__file__).resolve().parents[2]
OURS = ROOT / "GearQuest" / "_generated" / "Data.Coordinates.generated.lua"
GAPS = ROOT / "pipeline" / "data" / "coordinate_gaps.json"
SOURCES = ROOT / "pipeline" / "data" / "sources.json"
THEIRS = Path(r"C:\Users\Henrik\AppData\Local\Temp\gq-eao-2026-10-02\GearQuestForever\_generated\Locations.generated.lua")

# Classic UiMapIDs. Names we are sure of; anything else stays a gap.
MAP_NAMES = {
    1411: "Durotar",
    1412: "Mulgore",
    1413: "The Barrens",
    1416: "Alterac Mountains",
    1417: "Arathi Highlands",
    1418: "Badlands",
    1419: "Blasted Lands",
    1420: "Tirisfal Glades",
    1421: "Silverpine Forest",
    1422: "Western Plaguelands",
    1423: "Eastern Plaguelands",
    1424: "Hillsbrad Foothills",
    1425: "The Hinterlands",
    1426: "Dun Morogh",
    1427: "Searing Gorge",
    1428: "Burning Steppes",
    1429: "Elwynn Forest",
    1430: "Deadwind Pass",
    1431: "Duskwood",
    1432: "Loch Modan",
    1433: "Redridge Mountains",
    1434: "Stranglethorn Vale",
    1435: "Swamp of Sorrows",
    1436: "Westfall",
    1437: "Wetlands",
    1438: "Teldrassil",
    1439: "Darkshore",
    1440: "Ashenvale",
    1441: "Thousand Needles",
    1442: "Stonetalon Mountains",
    1443: "Desolace",
    1444: "Feralas",
    1445: "Dustwallow Marsh",
    1446: "Tanaris",
    1447: "Azshara",
    1448: "Felwood",
    1449: "Un'Goro Crater",
    1450: "Moonglade",
    1451: "Silithus",
    1452: "Winterspring",
    1453: "Stormwind City",
    1454: "Orgrimmar",
    1455: "Ironforge",
    1456: "Thunder Bluff",
    1457: "Darnassus",
    1458: "Undercity",
    1459: "Alterac Valley",
    1460: "Warsong Gulch",
    1461: "Arathi Basin",
}

# Continent canvases are not a spot.
SKIP_MAPS = {1414, 1415}

GROUP_FOR = {
    "quest_reward": "q",
    "seasonal_quest": "q",
    "boss_drop": "b",
    "vendor": "v",
    "world_drop": "w",
    "rare_npc": "w",
}

NOTES = {
    "quest_reward": "beginning of the quest or chain",
    "seasonal_quest": "beginning of the quest or chain",
    "boss_drop": "entrance to dungeon or raid",
    "vendor": "vendor that sells this",
    "world_drop": "a farming spot",
    "rare_npc": "where this rare spawns",
    "profession": "the trainer that teaches this",
    "object_drop": "one of the spots to farm it",
    "container": "one of the spots to farm it",
    "fishing": "a farming spot",
    "mail": "a farming spot",
    "special": "a farming spot",
}

FALLBACK_GROUPS = ("w", "b", "q", "v")
FACTION = {"A": "Alliance", "H": "Horde"}
TUPLE_RE = re.compile(
    r"\{(\d+),(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?),\"([AHB])\"(?:,\{([^{}]*)\})?\}"
)


def brace_groups(body: str) -> dict[str, str]:
    groups = {}
    i = 0
    n = len(body)
    while i < n:
        if body[i] in "qbvwpz" and i + 1 < n and body[i + 1] == "=":
            key = body[i]
            i += 2
            if i >= n or body[i] != "{":
                continue
            depth = 0
            start = i
            while i < n:
                ch = body[i]
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            groups[key] = body[start:i]
            continue
        i += 1
    return groups


def points_of(group_body: str) -> list[tuple[int, float, float, str, int]]:
    """One display point per tuple, plus how many extra samples it stands for."""
    found = []
    for match in TUPLE_RE.finditer(group_body or ""):
        map_id = int(match.group(1))
        if map_id in SKIP_MAPS or map_id not in MAP_NAMES:
            continue
        x = float(match.group(2))
        y = float(match.group(3))
        fac = match.group(4)
        flat = match.group(5)
        extra = 0
        if flat:
            nums = [float(part) for part in flat.split(",") if part]
            pairs = list(zip(nums[0::2], nums[1::2]))
            real = [(px, py) for px, py in pairs if not (px == 50 and py == 50)]
            if real:
                x, y = real[0]
                extra = max(0, len(real) - 1)
            elif x == 50 and y == 50:
                continue
        elif x == 50 and y == 50:
            continue
        found.append((map_id, x, y, fac, extra))
    return found


def pick_spots(points: list[tuple[int, float, float, str, int]], keep_faction: bool = True) -> tuple[list[dict], bool]:
    if not points:
        return [], False
    buckets: dict[str, list] = {"A": [], "H": [], "B": []}
    for point in points:
        buckets[point[3]].append(point)
    chosen = []
    more = False
    if buckets["A"] or buckets["H"]:
        for fac in ("A", "H"):
            rows = buckets[fac]
            if not rows:
                continue
            chosen.append(rows[0])
            if len(rows) > 1 or rows[0][4] > 0:
                more = True
        if buckets["B"]:
            more = True
    else:
        chosen.append(buckets["B"][0])
        if len(buckets["B"]) > 1 or buckets["B"][0][4] > 0:
            more = True
    spots = []
    for map_id, x, y, fac, _extra in chosen:
        spot = {
            "map": MAP_NAMES[map_id],
            "mapId": map_id,
            "x": round(x, 1),
            "y": round(y, 1),
        }
        if keep_faction and fac in FACTION:
            spot["faction"] = FACTION[fac]
        spots.append(spot)
    return spots, more


def lua_spot(spot: dict) -> str:
    parts = [
        'map="%s"' % spot["map"].replace("\\", "").replace('"', ""),
        "mapId=%d" % spot["mapId"],
        "x=%.1f" % spot["x"],
        "y=%.1f" % spot["y"],
    ]
    if spot.get("faction"):
        parts.append('faction="%s"' % spot["faction"])
    return "{" + ",".join(parts) + "}"


def lua_row(item_id: int, note: str, spots: list[dict], more: bool) -> str:
    body = 'note="%s"' % note.replace('"', "")
    if more:
        body += ",more=true"
    body += ",spots={" + ",".join(lua_spot(spot) for spot in spots) + "}"
    return "    [%d]={%s}," % (item_id, body)


def load_locations(text: str) -> tuple[dict[int, dict[str, str]], dict[str, str]]:
    index_text, _, rest = text.partition("GQ.TrainerIndex")
    items = {}
    for line in index_text.splitlines():
        match = re.match(r"\[(\d+)\]=(.+)$", line.strip().rstrip(","))
        if not match:
            continue
        items[int(match.group(1))] = brace_groups(match.group(2))
    trainers = {}
    trainer_text = rest.partition("GQ.AreaMapIndex")[0]
    for line in trainer_text.splitlines():
        match = re.match(r'\["([^"]+)"\]=(.+)$', line.strip().rstrip(","))
        if match:
            trainers[match.group(1)] = match.group(2)
    return items, trainers


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    ours = OURS.read_text(encoding="utf-8")
    have = {int(item_id) for item_id in re.findall(r"\[(\d+)\]=\{note=", ours)}
    gaps_doc = json.loads(GAPS.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    items, trainers = load_locations(THEIRS.read_text(encoding="utf-8"))

    rows = []
    filled_ids = set()
    by_type = Counter()
    unknown_maps = Counter()
    no_profession = 0

    for gap in gaps_doc["gaps"]:
        item_id = int(gap["id"])
        if item_id in have:
            continue
        source_type = gap.get("sourceType") or ""
        if source_type == "profession":
            src = sources.get(str(item_id)) or {}
            pins = camp_pins(src.get("instructions") or "", src.get("profession"))
            if pins:
                spots, more = pins, False
                note = CAMP_NOTE
                rows.append((item_id, lua_row(item_id, note, spots, more)))
                filled_ids.add(item_id)
                by_type[source_type] += 1
                continue
            prof = src.get("profession") or ""
            prof = str(prof).strip().lower()
            body = trainers.get(prof)
            if not body:
                if not prof:
                    no_profession += 1
                continue
            spots, more = pick_spots(points_of(body), keep_faction=source_type not in ("world_drop", "rare_npc"))
        else:
            groups = items.get(item_id) or {}
            key = GROUP_FOR.get(source_type)
            body = groups.get(key) if key else None
            if not body:
                for fallback in FALLBACK_GROUPS:
                    if groups.get(fallback):
                        body = groups[fallback]
                        break
            spots, more = pick_spots(
                points_of(body or ""),
                keep_faction=source_type not in ("world_drop", "rare_npc"),
            )
            if not spots and body:
                for match in TUPLE_RE.finditer(body):
                    map_id = int(match.group(1))
                    if map_id not in MAP_NAMES and map_id not in SKIP_MAPS:
                        unknown_maps[map_id] += 1
        if not spots:
            continue
        note = NOTES.get(source_type, "a farming spot")
        rows.append((item_id, lua_row(item_id, note, spots, more)))
        filled_ids.add(item_id)
        by_type[source_type] += 1

    print("already indexed", len(have))
    print("filled", len(filled_ids))
    for key, count in sorted(by_type.items()):
        print(f"  {key}: {count}")
    print("profession gaps with no profession name", no_profession)
    print("top unknown map ids (left as gaps)")
    for map_id, count in unknown_maps.most_common(15):
        print(f"  {map_id}: {count}")

    if not args.write:
        print("dry run; pass --write to update the coordinate file")
        return

    rows.sort()
    block = "\n".join(line for _item_id, line in rows)
    if not ours.rstrip().endswith("}"):
        raise SystemExit("coordinate file does not end with a table close")
    head, _, _tail = ours.rstrip().rpartition("}")
    if not head.rstrip().endswith(","):
        head = head.rstrip() + ","
    updated = head.rstrip() + "\n" + block + "\n}\n"
    if "-- Questie location index" not in updated:
        updated = updated.replace(
            "-- spot exists, so the log says so. Faction spots are filtered in the log.\n",
            "-- spot exists, so the log says so. Faction spots are filtered in the log.\n"
            "-- Gaps filled from the Questie location index (enrich_coordinates.py).\n",
            1,
        )
    OURS.write_text(updated, encoding="utf-8")

    remaining = [gap for gap in gaps_doc["gaps"] if int(gap["id"]) not in filled_ids]
    summary: dict[str, dict[str, int]] = {}
    for gap in remaining:
        bucket = summary.setdefault(gap["sourceType"], {})
        bucket["gap"] = bucket.get("gap", 0) + 1
        reason = "gap:" + (gap.get("reason") or "no pin")
        bucket[reason] = bucket.get(reason, 0) + 1
    old = gaps_doc.get("summary") or {}
    for source_type, bucket in old.items():
        summary.setdefault(source_type, {})
        previous_ok = bucket.get("ok", 0)
        summary[source_type]["ok"] = previous_ok + by_type.get(source_type, 0)
        if "gap" not in summary[source_type]:
            summary[source_type]["gap"] = 0
    gaps_doc["summary"] = summary
    gaps_doc["gaps"] = remaining
    GAPS.write_text(json.dumps(gaps_doc, indent=2) + "\n", encoding="utf-8")
    print("wrote", OURS)
    print("remaining gaps", len(remaining))


if __name__ == "__main__":
    main()
