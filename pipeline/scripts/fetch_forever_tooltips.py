"""Fetch Forever nether tooltips for a list of item ids."""
import json
import os
import sys
import time
import urllib.request

from gq_paths import DATA

TIPS = os.path.join(DATA, "forever_wowhead", "tooltips.json")
UA = "GearQuestForever-data/1.0"
DELAY = 0.25

ids = [int(x) for x in sys.argv[1:]]
if not ids:
    sys.exit("usage: fetch_forever_tooltips.py ID [ID ...]")

cache = {}
if os.path.exists(TIPS):
    cache = json.load(open(TIPS, encoding="utf-8"))

ok = err = 0
for i, iid in enumerate(ids):
    url = f"https://nether.wowhead.com/forever/tooltip/item/{iid}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            cache[str(iid)] = json.loads(r.read().decode("utf-8"))
        ok += 1
    except Exception as e:
        cache[str(iid)] = {"error": str(e)}
        err += 1
        print("fail", iid, e)
    if (i + 1) % 20 == 0 or i == len(ids) - 1:
        json.dump(cache, open(TIPS, "w", encoding="utf-8"))
        print(f"  {i + 1}/{len(ids)}")
    time.sleep(DELAY)

json.dump(cache, open(TIPS, "w", encoding="utf-8"))
print(f"fetched ok={ok} err={err}")
