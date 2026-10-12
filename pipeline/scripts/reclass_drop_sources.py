"""Put rare and dungeon-trash drops back on the right source.

Wowhead's listview source is "drop" for a rare, a boss, and a normal mob.
The ingest stored all of those as world_drop. A drop from one rare is
rare_npc. A drop from dungeon or raid trash is raid_trash. A drop from
one named boss is boss_drop. A drop shared with outdoor creatures stays
a world drop.

NPC rank and zone come from the Forever tooltip:
https://nether.wowhead.com/tooltip/npc/{id}?dataEnv=16
"""
import json
import os
import re
import time
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "pipeline" / "data" / "sources.json"
DOORS = ROOT / "pipeline" / "data" / "dungeon_entrances.json"
LISTS = ROOT / "pipeline" / "data" / "forever_wowhead" / "coord_cache.json"
CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "npc_rank_cache.json"
GENERATED = ROOT / "GearQuest" / "_generated"
UA = "wow-classic-data-research/1.0 (+contact: local script)"
DELAY = 0.12
RANK = re.compile(r"\((Rare Elite|World Boss|Rare|Elite|Boss)\)")
ZONE_TYPE = re.compile(r"Type: ([^<]+)")

INSTANCE = {"Dungeon", "Raid"}
RARE = {"rare", "rareelite"}


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", "replace")


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {"npc": {}, "zone": {}}


def save_cache(cache: dict) -> None:
    tmp = CACHE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cache, ensure_ascii=True), encoding="utf-8")
    os.replace(tmp, CACHE)


def npc_record(npc_id: int) -> dict:
    raw = fetch(f"https://nether.wowhead.com/tooltip/npc/{npc_id}?dataEnv=16")
    data = json.loads(raw)
    tip = data.get("tooltip") or ""
    rank_m = RANK.search(tip)
    rank = (rank_m.group(1) if rank_m else "normal").replace(" ", "").lower()
    zone_id = ((data.get("map") or {}).get("zone"))
    coords = ((data.get("map") or {}).get("coords")) or {}
    has_coords = any(coords.values()) if isinstance(coords, dict) else bool(coords)
    return {
        "name": data.get("name") or "",
        "rank": rank,
        "zoneId": zone_id,
        "coords": bool(has_coords),
    }


def zone_record(zone_id: int) -> dict:
    raw = fetch(f"https://nether.wowhead.com/tooltip/zone/{zone_id}?dataEnv=16")
    data = json.loads(raw)
    tip = data.get("tooltip") or ""
    kind_m = ZONE_TYPE.search(tip)
    return {"name": data.get("name") or "", "kind": kind_m.group(1).strip() if kind_m else ""}


def ensure_facts(cache: dict, npc_ids: set[int]) -> None:
    pending = [n for n in sorted(npc_ids) if str(n) not in cache["npc"]]
    print(f"npc tooltips {len(npc_ids)} cached {len(npc_ids) - len(pending)} pending {len(pending)}", flush=True)
    for i, npc_id in enumerate(pending, 1):
        try:
            cache["npc"][str(npc_id)] = npc_record(npc_id)
        except Exception as exc:
            cache["npc"][str(npc_id)] = {"error": str(exc)}
            print("  npc fail", npc_id, exc, flush=True)
        if i % 40 == 0:
            save_cache(cache)
            print(f"  npc {i}/{len(pending)}", flush=True)
        time.sleep(DELAY)
    zones = set()
    for row in cache["npc"].values():
        if isinstance(row, dict) and row.get("zoneId"):
            zones.add(int(row["zoneId"]))
    pending_z = [z for z in sorted(zones) if str(z) not in cache["zone"]]
    print(f"zones {len(zones)} pending {len(pending_z)}", flush=True)
    for i, zone_id in enumerate(pending_z, 1):
        try:
            cache["zone"][str(zone_id)] = zone_record(zone_id)
        except Exception as exc:
            cache["zone"][str(zone_id)] = {"error": str(exc)}
            print("  zone fail", zone_id, exc, flush=True)
        if i % 20 == 0:
            save_cache(cache)
            print(f"  zone {i}/{len(pending_z)}", flush=True)
        time.sleep(DELAY)
    save_cache(cache)


def npc_points(npc_id: int, cache: dict) -> list[tuple[float, float]]:
    row = cache["npc"].setdefault(str(npc_id), {})
    if "points" in row:
        return [tuple(p) for p in row["points"]]
    try:
        raw = fetch(f"https://nether.wowhead.com/tooltip/npc/{npc_id}?dataEnv=16")
        data = json.loads(raw)
        coords = ((data.get("map") or {}).get("coords")) or {}
        points = []
        if isinstance(coords, dict):
            for batch in coords.values():
                for pair in batch or []:
                    if len(pair) >= 2:
                        points.append([float(pair[0]), float(pair[1])])
        row["points"] = points
    except Exception as exc:
        row["points"] = []
        print("  points fail", npc_id, exc, flush=True)
    time.sleep(DELAY)
    return [tuple(p) for p in row["points"]]


def near_entrance(points, entrances, zone_name: str) -> bool:
    zone_name = (zone_name or "").casefold()
    for spot in entrances:
        if zone_name and spot.get("map") and spot["map"].casefold() != zone_name:
            continue
        for x, y in points:
            if ((spot["x"] - x) ** 2 + (spot["y"] - y) ** 2) ** 0.5 <= 6:
                return True
    return False


def fold_entrance_mobs(views: list[dict], doors: dict, cache: dict) -> list[dict]:
    """Wowhead files some instance trash on the entrance zone, at the door.

    Scarlet Augur is Scarlet Monastery trash with a Tirisfal pin on the
    monastery. One outdoor pin must not turn the whole drop into a world drop.
    """
    inside = [d for d in views if d["instance"]]
    rest = [d for d in views if not d["instance"]]
    if not inside or not rest:
        return views
    counts = Counter(d["zone"] for d in inside if d["zone"])
    if not counts:
        return views
    top, n = counts.most_common(1)[0]
    if n < 3 or n / len(views) < 0.75:
        return views
    entrances = (doors.get("entrances") or {}).get(top) or []
    if not entrances:
        for key, spots in (doors.get("entrances") or {}).items():
            if key.casefold() in top.casefold() or top.casefold() in key.casefold():
                entrances = spots
                top = key
                break
    folded = list(inside)
    for d in rest:
        if d["rank"] in RARE or d["rank"] in ("boss", "worldboss") or d["boss"]:
            return views
        if not d["zone"]:
            copy = dict(d)
            copy["instance"] = True
            copy["zone"] = top
            folded.append(copy)
            continue
        points = npc_points(d["id"], cache)
        if points and near_entrance(points, entrances, d["zone"]):
            copy = dict(d)
            copy["instance"] = True
            copy["zone"] = top
            folded.append(copy)
            continue
        return views
    return folded


def dropper_view(npc_id: int, cache: dict, bosses: dict) -> dict | None:
    row = cache["npc"].get(str(npc_id)) or {}
    if not row or row.get("error") or not row.get("name"):
        return None
    zone = cache["zone"].get(str(row.get("zoneId"))) or {}
    if zone.get("error"):
        return None
    name = row["name"]
    kind = zone.get("kind") or ""
    return {
        "id": npc_id,
        "name": name,
        "rank": row.get("rank") or "normal",
        "zone": zone.get("name") or "",
        "instance": kind in INSTANCE,
        "boss": name in bosses or row.get("rank") in ("boss", "worldboss"),
    }


def choose(droppers: list[dict]) -> dict | None:
    if not droppers:
        return None
    outdoor = [d for d in droppers if not d["instance"]]
    inside = [d for d in droppers if d["instance"]]
    if outdoor:
        names = {d["name"] for d in outdoor}
        if inside or len(names) != 1:
            return None
        one = outdoor[0]
        if one["rank"] in ("boss", "worldboss") or one["boss"]:
            return {"sourceType": "boss_drop", "npc": one["name"], "zone": one["zone"], "zones": []}
        if one["rank"] not in RARE:
            return None
        return {"sourceType": "rare_npc", "npc": one["name"], "zone": one["zone"], "zones": []}
    names = []
    for d in inside:
        if d["name"] not in names:
            names.append(d["name"])
    zones = []
    for d in inside:
        if d["zone"] and d["zone"] not in zones:
            zones.append(d["zone"])
    bosses = [d for d in inside if d["boss"]]
    trash = [d for d in inside if not d["boss"]]
    rares = [d for d in inside if d["rank"] in RARE and not d["boss"]]
    if len(names) == 1 and bosses and not trash:
        one = bosses[0]
        return {"sourceType": "boss_drop", "npc": one["name"], "zone": one["zone"], "zones": zones}
    if rares and len({d["name"] for d in rares}) == 1 and not trash and not bosses:
        one = rares[0]
        return {"sourceType": "rare_npc", "npc": one["name"], "zone": one["zone"], "zones": zones}
    if not trash and bosses:
        one = bosses[0]
        return {"sourceType": "boss_drop", "npc": one["name"], "zone": one["zone"], "zones": zones}
    # A boss on a shared trash table is not the hunt. Name a generic mob.
    rep = next((d for d in trash if not d["boss"]), None)
    if rep is None:
        rep = trash[0] if trash else inside[0]
    return {
        "sourceType": "raid_trash",
        "npc": rep["name"],
        "zone": zones[0] if len(zones) == 1 else rep["zone"],
        "zones": zones,
    }


def simple_instruction(text: str) -> bool:
    text = text or ""
    if len(text) > 160:
        return False
    return text.startswith("World drop") or text.startswith("Drops from ") or text.startswith("Indexed from ")


def apply_sources() -> dict[str, dict]:
    cache = load_cache()
    doors = json.loads(DOORS.read_text(encoding="utf-8"))
    bosses = doors.get("bossNpcs") or {}
    lists = json.loads(LISTS.read_text(encoding="utf-8"))["itemLists"]
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    changed: dict[str, dict] = {}
    skipped = Counter()
    for key, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "world_drop":
            continue
        if src.get("obtainable") is False:
            continue
        ids = [row["id"] for row in ((lists.get(key) or {}).get("drop") or []) if row.get("id")]
        if not ids:
            skipped["no-drop-list"] += 1
            continue
        views = []
        bad = False
        for npc_id in ids:
            view = dropper_view(npc_id, cache, bosses)
            if not view:
                bad = True
                break
            views.append(view)
        if bad:
            skipped["incomplete-tooltip"] += 1
            continue
        views = fold_entrance_mobs(views, doors, cache)
        decision = choose(views)
        if not decision:
            skipped["stays-world"] += 1
            continue
        if decision["sourceType"] == "world_drop":
            continue
        old_text = src.get("instructions") or ""
        src["sourceType"] = decision["sourceType"]
        src["npc"] = decision["npc"]
        src["zone"] = decision["zone"] or src.get("zone")
        if len(decision["zones"]) > 1:
            src["zones"] = decision["zones"]
        if simple_instruction(old_text):
            src["instructions"] = f"Drops from {decision['npc']}."
        changed[key] = {
            "sourceType": src["sourceType"],
            "npc": src.get("npc"),
            "zone": src.get("zone"),
            "instructions": src.get("instructions"),
            "zones": src.get("zones") or [],
        }
    save_cache(cache)
    tmp = SOURCES.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(sources, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")
    os.replace(tmp, SOURCES)
    print("changed", len(changed), "skipped", dict(skipped), flush=True)
    print(Counter(row["sourceType"] for row in changed.values()), flush=True)
    for probe in ("285331", "7753"):
        row = sources.get(probe) or {}
        print(probe, row.get("sourceType"), row.get("zone"), row.get("npc"), (row.get("instructions") or "")[:80], flush=True)
    return changed


def lua_escape(text: str) -> str:
    return (
        str(text)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", " ")
    )


def upsert_quoted(line: str, key: str, value: str) -> str:
    esc = lua_escape(value)
    pat = rf'{key}="(?:\\.|[^"\\])*"'
    if re.search(pat, line):
        return re.sub(pat, f'{key}="{esc}"', line, count=1)
    brace = line.rfind("}")
    return line[:brace] + f',{key}="{esc}"' + line[brace:]


def patch_lua(changed: dict[str, dict]) -> None:
    files = 0
    hits = 0
    for path in GENERATED.glob("*.lua"):
        text = path.read_bytes().decode("latin-1")
        lines = text.splitlines(keepends=True)
        file_hits = 0
        for i, line in enumerate(lines):
            if not line.startswith("    [") or "sourceType=" not in line:
                continue
            bracket = line.find("]")
            iid = line[line.find("[") + 1 : bracket]
            row = changed.get(iid)
            if not row:
                continue
            updated = re.sub(
                r'sourceType="[^"]*"',
                f'sourceType="{row["sourceType"]}"',
                line,
                count=1,
            )
            if row.get("instructions"):
                updated = upsert_quoted(updated, "instructions", row["instructions"])
            if row.get("zone"):
                updated = upsert_quoted(updated, "zone", row["zone"])
            if row.get("npc"):
                updated = upsert_quoted(updated, "npc", row["npc"])
            if updated != line:
                lines[i] = updated
                file_hits += 1
        if file_hits:
            path.write_bytes("".join(lines).encode("latin-1"))
            files += 1
            hits += file_hits
            print(f"  {path.name} {file_hits}", flush=True)
    print(f"lua files {files} facts {hits}", flush=True)


def main() -> None:
    lists = json.loads(LISTS.read_text(encoding="utf-8"))["itemLists"]
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    npc_ids = set()
    for key, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "world_drop":
            continue
        for row in (lists.get(key) or {}).get("drop") or []:
            if row.get("id"):
                npc_ids.add(int(row["id"]))
    cache = load_cache()
    ensure_facts(cache, npc_ids)
    changed = apply_sources()
    patch_lua(changed)
    out = ROOT / "pipeline" / "data" / "forever_wowhead" / "reclass_ids.json"
    prior = []
    if out.exists():
        prior = json.loads(out.read_text(encoding="utf-8"))
    merged = sorted(set(prior) | {int(k) for k in changed})
    out.write_text(json.dumps(merged), encoding="utf-8")
    print("wrote", out, flush=True)


if __name__ == "__main__":
    main()
