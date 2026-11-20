"""Average open-world drop % for generic world-drop hunts.

Reads dropped-by rows from cached HTML when possible. Wowhead requests follow
the same rules as pipeline/scripts/index_coordinates.py and
pipeline/scripts/wowhead_random.py:

  - User-Agent: wow-classic-data-research/1.0 (+contact: local script)
  - classic/item={id}?power (not a spoofed browser UA)
  - HTTP 403 after index_coordinates backoff means stop; do not queue thousands of ids
  - Bulk item pages: **10-15s between requests** (GQ_COORD_DELAY=12). See
    pipeline/docs/WORLD-DROP-OPEN-CHANCE.md

By default this script does **not** call Wowhead. Pass --fetch only for a small
batch (use --ids and --limit). After a CloudFront block, wait hours or days
before trying again.

Usage:
  python pipeline/scripts/build_world_drop_open_chance.py --emit-only
  python pipeline/scripts/build_world_drop_open_chance.py
  python pipeline/scripts/build_world_drop_open_chance.py --fetch --ids 1981
  python pipeline/scripts/build_world_drop_open_chance.py --fetch --limit 25
  GQ_COORD_DELAY=12 python pipeline/scripts/build_world_drop_open_chance.py --fetch --all
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from index_coordinates import door_key, fetch as wowhead_fetch, listview_rows

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "pipeline" / "data" / "sources.json"
DOORS_PATH = ROOT / "pipeline" / "data" / "dungeon_entrances.json"
COORD_CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "coord_cache.json"
NPC_RANK = ROOT / "pipeline" / "data" / "forever_wowhead" / "npc_rank_cache.json"
OUT_JSON = ROOT / "pipeline" / "data" / "world_drop_open_chance.json"
DROP_CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "world_drop_dropped_by_cache.json"
GENERATED = ROOT / "GearQuest" / "_generated"
PACKED_LUA = GENERATED / "Data.WorldDropOpenChance.generated.lua"
ITEM_URL = "https://www.wowhead.com/classic/item={}?power"
GENERIC_PAT = re.compile(r"^World drop around level (\d+)-(\d+)\.")
HUNT_ROW = re.compile(r"\{(\d+),\"")
INSTANCE_KINDS = frozenset({"Dungeon", "Raid"})
# Default: no network. --fetch opts in to wowhead_fetch (index_coordinates rules).
FETCH = "--fetch" in sys.argv
FETCH_ALL = "--all" in sys.argv
# Bulk pass: 10-15s per Wowhead item page (pipeline/docs/WORLD-DROP-OPEN-CHANCE.md).
MIN_FULL_DELAY = 10.0
RECOMMENDED_FULL_DELAY = 12.0


class WowheadBlocked(Exception):
    """CloudFront 403/429 after index_coordinates backoff — stop the batch."""


def load_json(path: Path, fallback):
    if not path.exists():
        return fallback
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    body = json.dumps(obj, separators=(",", ":"), ensure_ascii=True)
    for attempt in range(8):
        tmp.write_text(body, encoding="utf-8")
        try:
            tmp.replace(path)
            return
        except PermissionError:
            if attempt == 7:
                raise
            time.sleep(0.25 * (attempt + 1))


def generic_world_item_ids(sources: dict) -> dict[int, tuple[int, int]]:
    out: dict[int, tuple[int, int]] = {}
    for raw_id, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "world_drop" or src.get("npc"):
            continue
        m = GENERIC_PAT.match((src.get("instructions") or "").strip())
        if not m:
            continue
        lo, hi = int(m.group(1)), int(m.group(2))
        if lo > hi:
            lo, hi = hi, lo
        out[int(raw_id)] = (lo, hi)
    return out


def hunted_ids() -> set[int]:
    found: set[int] = set()
    for path in GENERATED.glob("Data.*.generated.lua"):
        if "Audit" in path.name or "Scored" in path.name or "Stat" in path.name:
            continue
        found.update(int(n) for n in HUNT_ROW.findall(path.read_text(encoding="utf-8", errors="replace")))
    return found


def row_pct(row: dict) -> float:
    modes = row.get("modes")
    if isinstance(modes, dict):
        band = modes.get("0") or {}
        count, outof = band.get("count"), band.get("outof")
        if count and outof:
            return 100.0 * float(count) / float(outof)
    count, outof = row.get("count"), row.get("outof")
    if count and outof:
        return 100.0 * float(count) / float(outof)
    for key in ("pct", "percent", "chance"):
        val = row.get(key)
        if isinstance(val, (int, float)) and val > 0:
            return float(val)
        if isinstance(val, str) and val.strip().endswith("%"):
            try:
                return float(val.strip().rstrip("%"))
            except ValueError:
                pass
    return 0.0


def npc_dungeon_only(npc_id: int, coord_npc: dict) -> bool:
    rec = coord_npc.get(str(npc_id)) or {}
    spots = rec.get("spots") or []
    if not spots:
        return False
    for spot in spots:
        if not door_key(spot.get("map") or ""):
            return False
    return True


def dropper_outdoor(
    npc_id: int,
    name: str,
    bosses: set[str],
    rank_cache: dict,
    coord_npc: dict,
) -> bool:
    if name in bosses:
        return False
    if npc_dungeon_only(npc_id, coord_npc):
        return False
    npc = (rank_cache.get("npc") or {}).get(str(npc_id)) or {}
    if npc.get("error"):
        return True
    zone_id = npc.get("zoneId")
    if zone_id:
        zone = (rank_cache.get("zone") or {}).get(str(zone_id)) or {}
        if (zone.get("kind") or "") in INSTANCE_KINDS:
            return False
    return True


def fetch_item_html(item_id: int) -> str:
    if not FETCH:
        return ""
    try:
        return wowhead_fetch(ITEM_URL.format(item_id))
    except urllib.error.HTTPError as exc:
        if exc.code in (403, 429):
            raise WowheadBlocked(f"Wowhead blocked on item {item_id}: HTTP {exc.code}") from exc
        print(f"  item {item_id} HTTP {exc.code}", flush=True)
        return ""
    except Exception as exc:
        print(f"  item {item_id} fail {exc}", flush=True)
        return ""


def average_open_chance(
    item_id: int,
    bosses: set[str],
    rank_cache: dict,
    coord_npc: dict,
    drop_html_cache: dict,
) -> tuple[float, int] | None:
    key = str(item_id)
    cached = drop_html_cache.get(key)
    html = ""
    if isinstance(cached, dict) and cached.get("rows"):
        rows = cached["rows"]
    else:
        html = fetch_item_html(item_id)
        if not html and isinstance(cached, dict) and cached.get("html"):
            html = cached["html"]
        elif html:
            drop_html_cache[key] = {"html": html}
        if not html:
            return None
        rows = listview_rows(html, "dropped-by")
        if rows:
            drop_html_cache[key] = {"html": html, "rows": rows}
    if not rows:
        return None
    pcts: list[float] = []
    for row in rows:
        npc_id = row.get("id")
        if not isinstance(npc_id, int):
            continue
        pct = row_pct(row)
        if pct <= 0:
            continue
        name = (row.get("name") or row.get("displayName") or "").strip()
        if dropper_outdoor(npc_id, name, bosses, rank_cache, coord_npc):
            pcts.append(pct)
    if not pcts:
        return None
    return sum(pcts) / len(pcts), len(pcts)


def chance_literal(chance: float) -> str:
    if chance <= 0:
        return "0"
    rounded = round(chance, 2)
    if rounded == int(rounded):
        return str(int(rounded))
    return f"{rounded:.2f}".rstrip("0").rstrip(".")


def strip_open_chance_from_mobdrops() -> None:
    """Remove the legacy fat table from Data.MobDrops (chances live in packed file)."""
    mob_path = GENERATED / "Data.MobDrops.generated.lua"
    if not mob_path.exists():
        return
    lines = mob_path.read_text(encoding="utf-8").splitlines()
    start = None
    end = None
    for i, line in enumerate(lines):
        if line.startswith("GQ.Data.worldDropOpenChance"):
            start = i
        elif start is not None and line.startswith("-- Average open-world"):
            start = min(start, i)
        elif start is not None and line == "}" and end is None:
            end = i
            break
    if start is None or end is None:
        return
    while start > 0 and lines[start - 1].strip() == "":
        start -= 1
    mob_path.write_text("\n".join(lines[:start] + lines[end + 1 :]) + "\n", encoding="utf-8", newline="\n")


def emit_lua(items: dict[str, dict]) -> None:
    parts: list[str] = []
    count = 0
    for item_id in sorted(items, key=lambda x: int(x)):
        avg = float((items[item_id] or {}).get("avg") or 0)
        if avg <= 0:
            continue
        cent = int(round(avg * 100))
        parts.append(f"{item_id}:{cent}")
        count += 1
    packed = ",".join(parts)
    GENERATED.mkdir(parents=True, exist_ok=True)
    block = [
        "local _, GQ = ...",
        "GQ.Data = GQ.Data or {}",
        "-- id:hundredths of a percent (28 => 0.28%). Built once on first drop-% tooltip.",
        f'GQ.Data.worldDropOpenChancePacked = "{packed}"',
        "",
    ]
    PACKED_LUA.write_text("\n".join(block), encoding="utf-8", newline="\n")
    strip_open_chance_from_mobdrops()
    print(f"wrote {PACKED_LUA} ({count} entries, {len(packed)} chars)", flush=True)


def parse_args() -> tuple[set[int] | None, int | None]:
    only = None
    if "--ids" in sys.argv:
        pos = sys.argv.index("--ids") + 1
        if pos < len(sys.argv):
            only = {int(x) for x in sys.argv[pos].split(",") if x.strip()}
    limit = None
    if "--limit" in sys.argv:
        pos = sys.argv.index("--limit") + 1
        if pos < len(sys.argv):
            limit = int(sys.argv[pos])
    return only, limit


def main() -> None:
    if "--emit-only" in sys.argv:
        data = load_json(OUT_JSON, {"items": {}})
        emit_lua(data.get("items") or {})
        return

    if FETCH and not FETCH_ALL and "--limit" not in sys.argv and "--ids" not in sys.argv:
        print(
            "Refusing a full --fetch run. Use --fetch --all with GQ_COORD_DELAY>=10 "
            "(10-15s per page; try 12), or pass --ids / --limit.",
            flush=True,
        )
        sys.exit(2)
    if FETCH_ALL:
        delay = float(os.environ.get("GQ_COORD_DELAY", "0.7"))
        if delay < MIN_FULL_DELAY:
            print(
                f"Full pass needs GQ_COORD_DELAY>={MIN_FULL_DELAY} "
                f"(10-15s per page; try {RECOMMENDED_FULL_DELAY}). Now {delay}.",
                flush=True,
            )
            sys.exit(2)
        print(f"Full slow fetch; GQ_COORD_DELAY={delay}s", flush=True)

    sources = load_json(SOURCES, {})
    generic = generic_world_item_ids(sources)
    targets = sorted(generic.keys() & hunted_ids())
    only, limit = parse_args()
    if only is not None:
        targets = [i for i in targets if i in only]
    if limit is not None:
        targets = targets[:limit]

    doors = load_json(DOORS_PATH, {})
    bosses = set((doors.get("bossNpcs") or {}).keys())
    rank_cache = load_json(NPC_RANK, {"npc": {}, "zone": {}})
    coord = load_json(COORD_CACHE, {"npc": {}})
    coord_npc = coord.get("npc") if isinstance(coord.get("npc"), dict) else {}
    prior = load_json(OUT_JSON, {"items": {}}).get("items") or {}
    drop_html_cache = load_json(DROP_CACHE, {})
    refetch = "--refetch" in sys.argv

    items: dict[str, dict] = dict(prior)
    done = ok = skip = kept = 0
    mode = "fetch" if FETCH else "cache-only"
    print(f"generic hunted {len(targets)} mode={mode}", flush=True)
    try:
        for item_id in targets:
            key = str(item_id)
            if not refetch and key in items and float((items[key] or {}).get("avg") or 0) > 0:
                kept += 1
                done += 1
                ok += 1
                continue
            done += 1
            row = average_open_chance(item_id, bosses, rank_cache, coord_npc, drop_html_cache)
            if row is None:
                skip += 1
            else:
                avg, n = row
                items[key] = {"avg": round(avg, 4), "n": n}
                ok += 1
            if done % 50 == 0:
                dump_json(DROP_CACHE, drop_html_cache)
                dump_json(OUT_JSON, {"items": items})
                print(f"  {done}/{len(targets)} ok={ok} skip={skip}", flush=True)
    except WowheadBlocked as exc:
        dump_json(DROP_CACHE, drop_html_cache)
        dump_json(OUT_JSON, {"items": items})
        emit_lua(items)
        print(str(exc), flush=True)
        print("Saved progress. Wait for Wowhead to unblock before --fetch again.", flush=True)
        sys.exit(1)

    dump_json(DROP_CACHE, drop_html_cache)
    dump_json(OUT_JSON, {"items": items})
    emit_lua(items)
    print(f"done {done} with average {ok} kept {kept} skipped {skip}", flush=True)


if __name__ == "__main__":
    main()