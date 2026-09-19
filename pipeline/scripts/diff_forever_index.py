"""Compare the latest Wowhead Forever index to items.json."""
import json
import os
from gq_paths import G, DATA

index = json.load(open(os.path.join(DATA, "forever_wowhead", "index.json"), encoding="utf-8"))
items = json.load(open(G + "items.json", encoding="utf-8"))
pool = set(json.load(open(G + "classic_item_ids.json", encoding="utf-8")))

new_ids = []
changed = []
for row in index["items"]:
    iid = row["id"]
    key = str(iid)
    it = items.get(key)
    if not it:
        new_ids.append((iid, row.get("name"), row.get("slot"), row.get("ilvl")))
        continue
    diffs = []
    if (row.get("name") or "") and row["name"] != it.get("name"):
        diffs.append(f"name {it.get('name')!r}->{row['name']!r}")
    if row.get("ilvl") and row["ilvl"] != it.get("ilvl"):
        diffs.append(f"ilvl {it.get('ilvl')}->{row['ilvl']}")
    r_armor = row.get("armor") or 0
    i_armor = (it.get("stats") or {}).get("armor") or 0
    if r_armor and abs(r_armor - i_armor) >= 2:
        diffs.append(f"armor {i_armor}->{r_armor}")
    r_dps = row.get("dps") or 0
    i_dps = it.get("dps") or 0
    if r_dps and i_dps and abs(r_dps - i_dps) >= 0.4:
        diffs.append(f"dps {i_dps}->{r_dps}")
    if diffs:
        changed.append((iid, it.get("name"), ", ".join(diffs)))

missing_pool = [iid for iid, *_ in new_ids if iid not in pool]
print(f"index {index.get('count')} scraped {index.get('scrapedAt')}")
print(f"new ids not in items.json: {len(new_ids)}")
for row in new_ids[:40]:
    print("  +", *row)
print(f"changed vs items.json: {len(changed)}")
for row in changed[:60]:
    print("  ~", *row)
print(f"new ids not in pool: {len(missing_pool)}")
