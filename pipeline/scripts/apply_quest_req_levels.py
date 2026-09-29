"""Items with no Requires Level take the lowest Forever quest pickup level.

A stated Requires Level on the tooltip is left alone. Drops, vendors, and
crafted pieces are left alone. Wowhead's item record stores that pickup
level as reqlevel when source is a quest.
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import DATA

ITEMS = Path(DATA) / "items.json"
SOURCES = Path(DATA) / "sources.json"
CACHE_TIPS = Path(DATA) / "forever_wowhead" / "refresh_cache.json"
CACHE_XML = Path(DATA) / "forever_wowhead" / "quest_req_cache.json"
PINS = Path(DATA) / "client_item_overrides.json"
UA = "Mozilla/5.0"
WORKERS = 8
JSON_BLOCK = re.compile(r"<json><!\[CDATA\[(.*?)\]\]></json>", re.S)
QUEST_REQ = re.compile(r"Requires level (\d+)", re.I)


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", "replace")


def parse_item_xml(body: str):
    m = JSON_BLOCK.search(body or "")
    if not m:
        return None
    blob = m.group(1).strip()
    if not blob.startswith("{"):
        blob = "{" + blob
    if not blob.endswith("}"):
        blob = blob + "}"
    try:
        return json.loads(blob)
    except json.JSONDecodeError:
        return None


def tooltip_states_level(raw: dict) -> bool:
    html = (raw or {}).get("tooltip") or ""
    if not html or raw.get("error"):
        return False
    return "Requires Level" in html or "<!--rlvl-->" in html


def main():
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    tips = json.loads(CACHE_TIPS.read_text(encoding="utf-8")) if CACHE_TIPS.exists() else {}
    pins = set(json.loads(PINS.read_text(encoding="utf-8"))) if PINS.exists() else set()
    xml_cache = json.loads(CACHE_XML.read_text(encoding="utf-8")) if CACHE_XML.exists() else {}

    candidates = []
    for iid, it in items.items():
        if iid in pins:
            continue
        raw = tips.get(iid)
        if raw and tooltip_states_level(raw):
            continue
        if raw and not raw.get("error"):
            candidates.append(int(iid))
        elif (it.get("rlvl") or 0) <= 1:
            candidates.append(int(iid))

    pending = [] if "--apply-only" in sys.argv else [
        i for i in candidates if str(i) not in xml_cache or xml_cache[str(i)].get("error")
    ]
    print(f"candidates {len(candidates)}; fetch {len(pending)}", flush=True)

    done = ok = err = 0

    def one(iid):
        try:
            body = fetch(f"https://www.wowhead.com/forever/item={iid}&xml")
            parsed = parse_item_xml(body)
            if not parsed:
                return iid, {"error": "no json"}
            return iid, parsed
        except Exception as e:
            return iid, {"error": str(e)}

    if pending:
        with ThreadPoolExecutor(max_workers=WORKERS) as pool:
            futs = [pool.submit(one, iid) for iid in pending]
            for fut in as_completed(futs):
                iid, row = fut.result()
                xml_cache[str(iid)] = row
                done += 1
                if row.get("error"):
                    err += 1
                else:
                    ok += 1
                if done % 250 == 0 or done == len(pending):
                    CACHE_XML.write_text(json.dumps(xml_cache), encoding="utf-8")
                    print(f"  {done}/{len(pending)} ok={ok} err={err}", flush=True)
        CACHE_XML.write_text(json.dumps(xml_cache), encoding="utf-8")

    # Quest pages only when one item lists more than one quest.
    quest_level = {}
    need_quests = []
    for iid in candidates:
        row = xml_cache.get(str(iid)) or {}
        if row.get("error"):
            continue
        more = [e for e in (row.get("sourcemore") or []) if e.get("t") == 5 and e.get("ti")]
        if len(more) > 1:
            for e in more:
                qid = int(e["ti"])
                if qid not in quest_level:
                    need_quests.append(qid)

    print(f"multi-quest lookups {len(need_quests)}", flush=True)

    def quest_one(qid):
        try:
            body = fetch(f"https://www.wowhead.com/forever/quest={qid}")
            levels = [int(n) for n in QUEST_REQ.findall(body)]
            if not levels:
                return qid, None
            return qid, min(levels)
        except Exception:
            return qid, None

    if need_quests:
        with ThreadPoolExecutor(max_workers=WORKERS) as pool:
            for fut in as_completed([pool.submit(quest_one, q) for q in need_quests]):
                qid, level = fut.result()
                quest_level[qid] = level

    changed = []
    for iid in candidates:
        row = xml_cache.get(str(iid)) or {}
        if row.get("error"):
            continue
        source = row.get("source") or []
        more = [e for e in (row.get("sourcemore") or []) if e.get("t") == 5 and e.get("ti")]
        if 4 not in source and not more:
            continue
        levels = []
        if len(more) > 1:
            for e in more:
                lv = quest_level.get(int(e["ti"]))
                if lv:
                    levels.append(lv)
        if not levels and row.get("reqlevel"):
            levels.append(int(row["reqlevel"]))
        if not levels:
            continue
        level = min(levels)
        if level <= 0:
            continue
        it = items[str(iid)]
        old = it.get("rlvl") or 0
        if old == level:
            continue
        it["rlvl"] = level
        src = sources.get(str(iid))
        if src is not None:
            src["gateLevel"] = level
        changed.append((iid, it.get("name"), old, level, [e.get("n") for e in more]))

    tmp_items = ITEMS.with_suffix(".json.tmp")
    tmp_src = SOURCES.with_suffix(".json.tmp")
    tmp_items.write_text(json.dumps(items, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")
    tmp_src.write_text(json.dumps(sources, separators=(",", ":"), ensure_ascii=True), encoding="utf-8")
    tmp_items.replace(ITEMS)
    tmp_src.replace(SOURCES)
    changed.sort(key=lambda r: int(r[0]))
    print(f"quest level applied {len(changed)}")
    for row in changed:
        if int(row[0]) in (2042, 15443, 15444, 279865, 3902) or len(changed) <= 25:
            print(f"  {row[0]} {row[1]}: {row[2]} -> {row[3]} quests={row[4]}")
    if len(changed) > 25:
        print(f"  ... {len(changed) - 25} more")


if __name__ == "__main__":
    main()
