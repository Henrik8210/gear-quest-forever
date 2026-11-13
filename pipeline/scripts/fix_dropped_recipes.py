"""Point crafted hunts at the Forever recipe drop, not a city trainer.

Which crafts are a dropped pattern, rather than a trainer recipe, is read
from the local profession notes. The drop, the seller, and the quest come
from the Wowhead Forever item page. The recipe skill does not come from
ForeverDB. A recipe whose source is an item, and whose trainer has not been
seen in Forever, is not taught by the trainer the coordinate file names.

Where that item drops or who sells it comes from the Wowhead Forever item
page (dataEnv 16 listviews), saved as
pipeline/data/forever_wowhead/recipe_lists/{itemId}.json
Those pages are fetched in a browser because the HTML endpoint answers
403 to this script. NPC camps come from the coordinate cache already
built off Forever npc pages. A dungeon named on that page uses the
entrance we already store. Classic and TBC loot tables are not read.

    python pipeline/scripts/fix_dropped_recipes.py --missing
    python pipeline/scripts/fix_dropped_recipes.py
    python pipeline/scripts/fix_dropped_recipes.py --write
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import index_coordinates as ic

ROOT = Path(__file__).resolve().parents[2]
PROF_DIR = Path(ic.DATA) / "forever_wowhead" / "professions"
LIST_DIR = Path(ic.DATA) / "forever_wowhead" / "recipe_lists"
ZONE_PATH = Path(ic.DATA) / "forever_wowhead" / "zone_names.json"
UA = {"User-Agent": "Mozilla/5.0"}

# A live Wowhead fetch from this process sleeps for minutes on 403.
# Every npc used here is already in the coordinate cache, or it is skipped.
def _no_fetch(url: str) -> str:
    raise RuntimeError("coordinate cache miss, not a live fetch: " + url)


ic.fetch = _no_fetch


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def profession_rows() -> list[dict]:
    rows = []
    for path in sorted(PROF_DIR.glob("*.json")):
        data = load_json(path)
        slug = path.stem
        for row in data.get("recipes") or []:
            row["_prof"] = slug
            rows.append(row)
    if not rows:
        raise SystemExit("no profession shards in " + str(PROF_DIR))
    return rows


def trainer_pin_ids() -> set[int]:
    text = ic.LUA_PATH.read_text(encoding="utf-8")
    found = set()
    for match in re.finditer(r"\[(\d+)\]=\{note=\"the trainer that teaches this\"", text):
        found.add(int(match.group(1)))
    return found


def work_lists(rows: list[dict], trainer_ids: set[int]) -> tuple[list[dict], list[int]]:
    """Crafts to repin, and crafted ids whose Forever source is automatic."""
    crafts = []
    automatic = []
    for row in rows:
        make = row.get("make") or []
        if not make or not isinstance(make[0], int):
            continue
        crafted = make[0]
        if crafted not in trainer_ids:
            continue
        src = row.get("src") or {}
        trainer = src.get("trainer") or {}
        seen = bool(trainer.get("fv")) or bool(src.get("fv"))
        if seen:
            continue
        recipes = []
        for key in ("items", "hidden"):
            for item_id in src.get(key) or []:
                if isinstance(item_id, int) and item_id not in recipes:
                    recipes.append(item_id)
        if recipes:
            crafts.append(
                {
                    "crafted": crafted,
                    "name": row.get("n") or "",
                    "prof": row.get("_prof") or "",
                    "recipes": recipes,
                }
            )
        elif src.get("auto") and "items" not in src and "hidden" not in src:
            automatic.append(crafted)
    return crafts, automatic


def load_lists(recipe_ids: list[int]) -> dict | None:
    merged = {"drop": [], "sell": [], "obj": [], "quest": [], "quests": 0, "views": {}}
    for recipe_id in recipe_ids:
        path = LIST_DIR / f"{recipe_id}.json"
        if not path.exists():
            return None
        data = load_json(path)
        if data.get("error"):
            return None
        merged["drop"].extend(data.get("drop") or [])
        merged["drop"].extend(data.get("pocket") or [])
        merged["sell"].extend(data.get("sell") or [])
        merged["obj"].extend(data.get("obj") or [])
        merged["quest"] = merged.get("quest") or []
        merged["quest"].extend(data.get("quest") or [])
        merged["quests"] += int(data.get("quests") or 0) + len(data.get("quest") or [])
        for key, count in (data.get("views") or {}).items():
            merged["views"][key] = merged["views"].get(key, 0) + int(count)
    return merged


def zone_table() -> dict[str, dict]:
    if ZONE_PATH.exists():
        return load_json(ZONE_PATH)
    return {}


def save_zones(zones: dict[str, dict]) -> None:
    ZONE_PATH.parent.mkdir(parents=True, exist_ok=True)
    ZONE_PATH.write_text(json.dumps(zones, indent=2, sort_keys=True), encoding="utf-8")


def ensure_zones(zones: dict[str, dict], locs: set[int]) -> None:
    pending = [loc for loc in sorted(locs) if loc > 0 and str(loc) not in zones]
    for index, loc in enumerate(pending, 1):
        url = f"https://nether.wowhead.com/tooltip/zone/{loc}?dataEnv=16"
        req = urllib.request.Request(url, headers=UA)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8", "replace"))
            tip = data.get("tooltip") or ""
            zones[str(loc)] = {
                "name": data.get("name") or "",
                "dungeon": ("Type: Dungeon" in tip) or ("Type: Raid" in tip),
            }
        except Exception as exc:
            zones[str(loc)] = {"name": "", "error": type(exc).__name__}
        if index % 25 == 0:
            print("  zones", index, "/", len(pending), flush=True)
            save_zones(zones)
        time.sleep(0.35)
    if pending:
        save_zones(zones)


def stamp(spot: dict) -> dict:
    if not spot.get("mapId") and spot.get("map") in ic.MAP_IDS:
        spot["mapId"] = ic.MAP_IDS[spot["map"]]
    return spot


def add_spot(chosen: list[dict], seen: set, spot: dict) -> None:
    spot = stamp(spot)
    key = (spot.get("map"), round(float(spot.get("x") or 0), 1), round(float(spot.get("y") or 0), 1), spot.get("faction"))
    if key in seen or not spot.get("map"):
        return
    seen.add(key)
    chosen.append(spot)


def door_points() -> set[tuple]:
    found = set()
    for spots in ic.DOORS["entrances"].values():
        for spot in spots:
            found.add((spot.get("map"), round(float(spot["x"]), 1), round(float(spot["y"]), 1)))
    return found


def spots_for(lists: dict, cache: dict, zones: dict[str, dict]) -> tuple[list[dict], str | None]:
    drop_npcs = []
    seen_npc = set()
    locs = set()
    for row in lists["drop"]:
        npc_id = row.get("id")
        if not isinstance(npc_id, int) or npc_id in seen_npc:
            continue
        seen_npc.add(npc_id)
        locs.update(locs_of(row))
        if str(npc_id) not in cache["npc"]:
            continue
        drop_npcs.append({"id": npc_id, "name": row.get("n") or "", "react": row.get("react")})
    spots = [stamp(spot) for spot in ic.camps_from_npcs(drop_npcs, cache, False)]
    seen = set()
    chosen = []
    for spot in spots:
        add_spot(chosen, seen, spot)
    for row in lists["obj"]:
        rec = (cache.get("object") or {}).get(str(row.get("id"))) or {}
        for spot in rec.get("spots") or []:
            if ic.is_capital_farm(spot):
                continue
            door = ic.door_key(spot.get("map") or "")
            if door:
                for entrance in ic.entrance_spots(door):
                    add_spot(chosen, seen, entrance)
                continue
            add_spot(chosen, seen, dict(spot))
    seen_door = set()
    for loc in locs:
        info = zones.get(str(loc)) or {}
        if not info.get("dungeon"):
            continue
        door = ic.door_key(info.get("name") or "")
        if not door or door in seen_door:
            continue
        seen_door.add(door)
        for entrance in ic.entrance_spots(door):
            add_spot(chosen, seen, entrance)
    if chosen:
        doors = door_points()
        only_doors = all(
            (spot.get("map"), round(float(spot.get("x") or 0), 1), round(float(spot.get("y") or 0), 1)) in doors
            for spot in chosen
        )
        note = ic.NOTE_DOOR if only_doors else "where the recipe drops"
        return chosen, note
    sellers = []
    seen_seller = set()
    for row in lists["sell"]:
        npc_id = row.get("id")
        if not isinstance(npc_id, int) or npc_id in seen_seller:
            continue
        seen_seller.add(npc_id)
        if str(npc_id) not in cache["npc"]:
            continue
        sellers.append({"id": npc_id, "name": row.get("n") or "", "react": row.get("react")})
    vendor_spots = [stamp(spot) for spot in ic.camps_from_npcs(sellers, cache, True)]
    if vendor_spots:
        return vendor_spots, "vendor that sells the recipe"
    quest_spots = []
    seen_quest = set()
    for quest in lists.get("quest") or []:
        quest_id = quest.get("id")
        if not isinstance(quest_id, int):
            continue
        row = ic.quest_record(quest_id, cache)
        guard = 0
        while row.get("earlier") and guard < 12:
            parent = ic.quest_record(int(row["earlier"]), cache)
            if not parent.get("places") and not parent.get("earlier"):
                break
            row = parent
            guard += 1
        side = {1: "Alliance", 2: "Horde"}.get(quest.get("side"))
        for place in ic.choose_quest_places(row.get("places") or [], side):
            add_spot(quest_spots, seen_quest, place)
    if quest_spots:
        return quest_spots, ic.NOTE_QUEST
    return [], None


def locs_of(row: dict) -> list[int]:
    loc = row.get("loc")
    if isinstance(loc, list):
        return [n for n in loc if isinstance(n, int) and n > 0]
    if isinstance(loc, int) and loc > 0:
        return [loc]
    return []


def collect_locs(crafts: list[dict]) -> set[int]:
    locs = set()
    for craft in crafts:
        lists = load_lists(craft["recipes"])
        if not lists:
            continue
        for row in lists["drop"]:
            locs.update(locs_of(row))
    return locs


def apply_file(updates: dict[int, str], deletes: set[int]) -> None:
    text = ic.LUA_PATH.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    out = []
    seen = set()
    for line in text.splitlines():
        match = re.match(r"    \[(\d+)\]=\{", line)
        if not match:
            out.append(line)
            continue
        item_id = int(match.group(1))
        if item_id in updates:
            if item_id not in seen:
                out.append(updates[item_id])
                seen.add(item_id)
            continue
        if item_id in deletes:
            continue
        out.append(line)
    tmp = ic.LUA_PATH.with_suffix(".lua.tmp")
    tmp.write_text(nl.join(out) + nl, encoding="utf-8", newline="")
    tmp.replace(ic.LUA_PATH)


def main() -> None:
    write = "--write" in sys.argv
    missing_only = "--missing" in sys.argv
    rows = profession_rows()
    trainer_ids = trainer_pin_ids()
    crafts, automatic = work_lists(rows, trainer_ids)
    need = []
    for craft in crafts:
        for recipe_id in craft["recipes"]:
            if not (LIST_DIR / f"{recipe_id}.json").exists():
                need.append(recipe_id)
    need = sorted(set(need))
    print("crafts", len(crafts), "automatic", len(automatic), "recipe pages still needed", len(need))
    if "--batches" in sys.argv:
        batch_dir = LIST_DIR / "_batches"
        batch_dir.mkdir(parents=True, exist_ok=True)
        for old in batch_dir.glob("*.json"):
            old.unlink()
        for index in range(0, len(need), 40):
            chunk = need[index:index + 40]
            (batch_dir / f"{index // 40:02d}.json").write_text(json.dumps(chunk), encoding="utf-8")
        print("batches", (len(need) + 39) // 40)
        return
    if missing_only:
        print(" ".join(str(n) for n in need))
        return
    zones = zone_table()
    if write or "--zones" in sys.argv:
        ensure_zones(zones, collect_locs(crafts))
    cache = ic.load_cache()
    updates = {}
    deletes = set(automatic)
    skipped = 0
    quests = 0
    quest_left = 0
    no_place = 0
    farm = 0
    door = 0
    vendor = 0
    sample = None
    for craft in crafts:
        lists = load_lists(craft["recipes"])
        if lists is None:
            skipped += 1
            continue
        spots, note = spots_for(lists, cache, zones)
        if spots and note:
            row = {"note": note, "spots": spots, "more": len(spots) > 1}
            updates[craft["crafted"]] = ic.lua_row(craft["crafted"], row)
            if note == ic.NOTE_DOOR:
                door += 1
            elif note == "where the recipe drops":
                farm += 1
            elif note == ic.NOTE_QUEST:
                quests += 1
            else:
                vendor += 1
            if craft["crafted"] == 2864:
                sample = (note, spots)
        elif lists["quest"] or lists["quests"] or lists["drop"] or lists["sell"] or lists["obj"]:
            quest_left += 1
        else:
            deletes.add(craft["crafted"])
            no_place += 1
    print(
        "repin", len(updates),
        "farm", farm,
        "door", door,
        "vendor", vendor,
        "no place", no_place,
        "quest pins", quests,
        "left on trainer", quest_left,
        "waiting on pages", skipped,
        "delete", len(deletes),
    )
    if sample:
        print("2864", sample[0])
        for spot in sample[1][:12]:
            print(" ", spot)
        print("  spots", len(sample[1]))
    if not write:
        print("dry run")
        return
    apply_file(updates, deletes)
    print("wrote", ic.LUA_PATH)


if __name__ == "__main__":
    main()
