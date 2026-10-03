"""Refresh Forever nether tooltips onto items we already score.

The id list is every hunt id in the generated class files plus the Forever
index. Classic pieces are not in the index. Leaving them out keeps the old
rebuild hover. Do not shrink this list back to index.json.

Does not replace sources.json, except Grave Shroud's quest text and level.
Does not touch client-pinned items or Greater Magic Wand 11288. A stated
Requires Level wins over item level.
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import DATA
from ingest_forever_wowhead import ARMOR_SUB, parse_tooltip
from probe_forever_hunt_tooltips import plain as plain_tip

ITEMS = Path(DATA) / "items.json"
SOURCES = Path(DATA) / "sources.json"
HUNT = Path(DATA) / "forever_wowhead" / "hunt_tooltips.json"
INDEX = Path(DATA) / "forever_wowhead" / "index.json"
PINS = Path(DATA) / "client_item_overrides.json"
CACHE = Path(DATA) / "forever_wowhead" / "refresh_cache.json"
URL = "https://nether.wowhead.com/forever/tooltip/item/{}"
UA = "GearQuestForever-data/1.0"
WORKERS = 4
# Client wand. Nether still prints the old 11.39 DPS line. Do not refresh it.
WAND = 11288

GRAVE = "279865"


def fetch(iid: int):
    delay = 4.0
    last = None
    for attempt in range(6):
        req = urllib.request.Request(URL.format(iid), headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if not data.get("tooltip"):
                return iid, {"error": "no tooltip"}
            return iid, data
        except urllib.error.HTTPError as e:
            last = f"http {e.code}"
            if e.code in (403, 429) and attempt < 5:
                time.sleep(delay)
                delay = min(delay * 2, 60)
                continue
            return iid, {"error": last}
        except Exception as e:
            last = str(e)
            if attempt < 2:
                time.sleep(delay)
                delay = min(delay * 2, 30)
                continue
            return iid, {"error": last}
    return iid, {"error": last or "fetch failed"}


def hunt_ids_from_addon() -> list[int]:
    root = Path(__file__).resolve().parents[2] / "GearQuest" / "_generated"
    ids = set()
    for path in root.glob("Data.*.generated.lua"):
        if any(x in path.name for x in ("Audit", "Scored", "Stat", "Coordinates", "QuestFaction")):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        ids.update(int(n) for n in re.findall(r"\[(\d+)\]=\{name=", text))
    return sorted(ids)


def apply_row(item: dict, raw: dict) -> bool:
    html = raw.get("tooltip") or ""
    if not html:
        return False
    parsed = parse_tooltip(html)
    old = item.get("stats") or {}
    stats = dict(parsed.get("stats") or {})
    if old.get("resist") and not stats.get("resist"):
        stats["resist"] = old["resist"]
    if stats:
        item["stats"] = stats
    stated = int(parsed.get("rlvl") or 0)
    if stated > 1:
        item["rlvl"] = stated
    if parsed.get("dps"):
        item["dps"] = parsed["dps"]
    if parsed.get("speed"):
        item["speed"] = parsed["speed"]
        item["delay"] = int(round(parsed["speed"] * 1000))
    if parsed.get("dmgMin"):
        item["dmgMin"] = parsed["dmgMin"]
        item["dmgMax"] = parsed["dmgMax"]
    if parsed.get("ilvl"):
        item["ilvl"] = parsed["ilvl"]
    if parsed.get("effects") is not None:
        item["effects"] = parsed.get("effects") or []
    if parsed.get("procs") is not None:
        item["procs"] = parsed.get("procs") or []
    if parsed.get("randomEnchant"):
        item["randomEnchant"] = True
    item["hasTip"] = True
    sub = item.get("sub")
    if item.get("kind") == "?" and sub in ARMOR_SUB:
        item["kind"] = ARMOR_SUB[sub]
    return True


def hunt_row(iid: int, raw: dict, item: dict) -> dict:
    name = raw.get("name") or item.get("name")
    tip = plain_tip(raw.get("tooltip") or "")
    if name and tip.lower().startswith(name.lower()):
        tip = tip[len(name):].lstrip(" -:\n")
    row = {
        "status": "ok",
        "name": name,
        "quality": raw.get("quality", item.get("quality")),
        "tip": tip.strip(),
        "source": "nether",
    }
    if raw.get("icon"):
        row["icon"] = raw["icon"]
    return row


def missing_ids():
    import re
    root = Path(__file__).resolve().parents[2]
    text = (root / "GearQuest" / "_generated" / "Data.ForeverAudit.generated.lua").read_text(encoding="utf-8")
    return [int(m.group(1)) for m in re.finditer(r'\[(\d+)\]=\{status="missing"', text)]


def main():
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    hunt = json.loads(HUNT.read_text(encoding="utf-8")) if HUNT.exists() else {}
    index = json.loads(INDEX.read_text(encoding="utf-8"))
    pins = set(json.loads(PINS.read_text(encoding="utf-8"))) if PINS.exists() else set()
    cache = json.loads(CACHE.read_text(encoding="utf-8")) if CACHE.exists() else {}

    fixed_kind = 0
    for it in items.values():
        sub = it.get("sub")
        if it.get("kind") == "?" and sub in ARMOR_SUB:
            it["kind"] = ARMOR_SUB[sub]
            fixed_kind += 1

    if "--missing" in sys.argv:
        ids = [i for i in missing_ids() if str(i) in items and str(i) not in pins and i != WAND]
    else:
        # Forever index plus every hunt id. Classic pieces such as Ghostly
        # Mantle are not in the Forever index, so a cache hit there left the
        # rebuild tooltip in place.
        ids = set()
        for row in index["items"]:
            iid = int(row["id"])
            if str(iid) in pins or str(iid) not in items or iid == WAND:
                continue
            ids.add(iid)
        for iid in hunt_ids_from_addon():
            if str(iid) in pins or str(iid) not in items or iid == WAND:
                continue
            ids.add(iid)
        ids = sorted(ids)
    def retryable(raw: dict) -> bool:
        err = raw.get("error") or ""
        # 404 is a real miss. Do not hammer Wowhead for it again.
        return bool(err) and "404" not in err

    pending = [i for i in ids if str(i) not in cache or retryable(cache[str(i)])]
    print(f"kind fixes {fixed_kind}; refresh {len(pending)} of {len(ids)}")

    done = 0
    ok = err = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = [pool.submit(fetch, iid) for iid in pending]
        for fut in as_completed(futures):
            iid, raw = fut.result()
            cache[str(iid)] = raw
            done += 1
            if raw.get("error"):
                err += 1
            else:
                ok += 1
            if done % 200 == 0 or done == len(pending):
                CACHE.write_text(json.dumps(cache), encoding="utf-8")
                print(f"  {done}/{len(pending)} ok={ok} err={err}", flush=True)
    if pending:
        CACHE.write_text(json.dumps(cache), encoding="utf-8")

    changed = 0
    spell = []
    for iid in ids:
        raw = cache.get(str(iid)) or {}
        if raw.get("error") or not raw.get("tooltip"):
            continue
        item = items[str(iid)]
        before = (
            dict(item.get("stats") or {}),
            item.get("dps"),
            item.get("rlvl"),
            item.get("kind"),
        )
        apply_row(item, raw)
        after = (
            dict(item.get("stats") or {}),
            item.get("dps"),
            item.get("rlvl"),
            item.get("kind"),
        )
        hunt[str(iid)] = hunt_row(iid, raw, item)
        if before != after:
            changed += 1
            st = item.get("stats") or {}
            if st.get("heal") or st.get("damageDone") or st.get("sp") or st.get("sp_from_heal"):
                if before[0] != st:
                    spell.append((iid, item.get("name"), before[0], st, before[2], item.get("rlvl")))

    grave = items.get(GRAVE)
    if grave:
        grave["rlvl"] = 16
        grave["kind"] = "Misc"
        src = sources.get(GRAVE) or {}
        src.update({
            "sourceType": "quest_reward",
            "instructions": (
                "Reward from Abominable Creatures (Alliance) or Unending Torment (Horde). "
                "The quest requires level 16."
            ),
            "zone": None,
            "npc": None,
            "questName": None,
            "profession": None,
            "dropChance": None,
            "alts": src.get("alts") or [],
            "gateLevel": 16,
            "questClasses": 0,
            "questRaces": 0,
            "seasonal": False,
            "obtainable": True,
            "excludedBecause": None,
        })
        sources[GRAVE] = src

    def dump(path: Path, obj, **kwargs) -> None:
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(json.dumps(obj, **kwargs), encoding="utf-8")
        tmp.replace(path)

    dump(ITEMS, items, separators=(",", ":"), ensure_ascii=False)
    dump(SOURCES, sources, separators=(",", ":"), ensure_ascii=True)
    dump(HUNT, hunt, ensure_ascii=False)
    spell.sort()
    print(f"updated {changed} items; spell-line changes {len(spell)}")
    for row in spell:
        if row[0] in (2042, 270228, 271095, 281297, 279865) or len(spell) <= 30:
            print(f"  {row[0]} {row[1]}: {row[2]} -> {row[3]} rlvl {row[4]}->{row[5]}")
    focus = [2042, 270228, 271095, 281297, 279865, 3324, 6461, 11288]
    print("--- focus ---")
    for iid in focus:
        it = items.get(str(iid)) or {}
        print(iid, it.get("name"), "rlvl", it.get("rlvl"), "kind", it.get("kind"), "stats", it.get("stats"), "dps", it.get("dps"))


if __name__ == "__main__":
    main()
