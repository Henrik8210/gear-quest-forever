"""Classify Forever item ids as New in Forever.

Wowhead Forever prints that badge when the same id is absent from the classic
item database. flags2 and id >= 200000 both include Season of Discovery items
that Forever still lists and does not badge.
"""
import json
import os
import re
import socket
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

socket.setdefaulttimeout(20)
UA = "GearQuestForever-data/1.0"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INDEX = os.path.join(ROOT, "pipeline", "data", "forever_wowhead", "index.json")
CACHE = os.path.join(ROOT, "pipeline", "data", "forever_wowhead", "new_in_forever.json")
GEN = os.path.join(ROOT, "GearQuest", "_generated")
LUA = os.path.join(GEN, "Data.ForeverNew.generated.lua")

def load_ids():
    ids = set()
    if os.path.exists(INDEX):
        index = json.load(open(INDEX, encoding="utf-8"))
        for row in index.get("items") or []:
            iid = int(row["id"])
            if iid >= 200000:
                ids.add(iid)
    for name in os.listdir(GEN):
        if not name.startswith("Data.") or not name.endswith(".generated.lua"):
            continue
        if "Coordinates" in name or "QuestFaction" in name or "ForeverNew" in name:
            continue
        text = open(os.path.join(GEN, name), "rb").read().decode("latin-1", "replace")
        for match in re.finditer(r"\[(\d{6,})\]=", text):
            iid = int(match.group(1))
            if iid >= 200000:
                ids.add(iid)
    return sorted(ids)

def probe(iid, attempt=0):
    # Classic nether tooltip 404s for ids Wowhead Forever badges "New in Forever".
    url = f"https://nether.wowhead.com/classic/tooltip/item/{iid}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            resp.read(40)
            return False
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return True
        if exc.code in (403, 429) and attempt < 3:
            time.sleep(2 + attempt * 2)
            return probe(iid, attempt + 1)
        raise

def main():
    ids = load_ids()
    cache = {}
    if os.path.exists(CACHE):
        cache = {int(k): v for k, v in json.load(open(CACHE, encoding="utf-8")).items()}
    todo = [iid for iid in ids if iid not in cache]
    print(f"ids {len(ids)} cached {len(cache)} todo {len(todo)}", flush=True)
    done = 0
    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = {pool.submit(probe, iid): iid for iid in todo}
        for fut in as_completed(futures):
            iid = futures[fut]
            cache[iid] = bool(fut.result())
            done += 1
            if done % 50 == 0 or done == len(todo):
                tmp = CACHE + ".tmp"
                payload = {str(k): cache[k] for k in sorted(cache)}
                with open(tmp, "w", encoding="utf-8", newline="\n") as handle:
                    json.dump(payload, handle, ensure_ascii=True, separators=(",", ":"))
                os.replace(tmp, CACHE)
                print(f"  {done}/{len(todo)} new {sum(1 for v in cache.values() if v)}", flush=True)
    new_ids = sorted(iid for iid, flag in cache.items() if flag and iid in set(ids))
    lines = [f"    [{iid}] = true," for iid in new_ids]
    text = (
        "local _, GQ = ...\n"
        "GQ.Data = GQ.Data or {}\n"
        "\n"
        "-- Wowhead Forever \"New in Forever\": this id is not in the classic item database.\n"
        "GQ.Data.foreverNew = {\n"
        + "\n".join(lines)
        + "\n}\n"
    )
    with open(LUA, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    print(f"new in forever {len(new_ids)} wrote {LUA}", flush=True)

if __name__ == "__main__":
    main()
