"""List Forever-ok trinkets a shaman can wear by level 22."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
G = ROOT / "pipeline" / "data"
items = json.loads((G / "items.json").read_text(encoding="utf-8"))
srcs = json.loads((G / "sources.json").read_text(encoding="utf-8"))
audit = json.loads((ROOT / "GearQuest" / "_generated" / "Data.ForeverAudit.generated.lua").read_text(encoding="utf-8")) if False else {}
tips = json.loads((G / "forever_wowhead" / "hunt_tooltips.json").read_text(encoding="utf-8"))
# also full index for trinkets not in hunts
idx = json.loads((G / "forever_wowhead" / "index.json").read_text(encoding="utf-8"))

SHAMAN = 64
HORDE = 690  # typical classic horde race mask? we'll print allowRace

rows = []
for iid, it in items.items():
    if it.get("slot") != "Trinket":
        continue
    rlvl = it.get("rlvl") or 0
    ilvl = it.get("ilvl") or 0
    if rlvl > 22 and ilvl > 30:
        continue
    ac = it.get("allowClass", -1)
    if ac not in (-1, 0) and not (ac & SHAMAN):
        continue
    st = (tips.get(str(it["id"])) or tips.get(iid) or {}).get("status")
    src = srcs.get(str(it["id"])) or srcs.get(iid) or {}
    rows.append((rlvl, ilvl, it["id"], it.get("name"), it.get("quality"), st, src.get("sourceType"), src.get("zone"), it.get("stats"), (it.get("effects") or it.get("procs") or [])[:1], src.get("obtainable")))

rows.sort()
print(f"{'id':6} {'rl':3} {'il':3} {'q':1} {'st':8} obtainable name")
for rlvl, ilvl, iid, name, q, st, stype, zone, stats, fx, obt in rows:
    if rlvl > 22:
        continue
    print(f"{iid:6} {rlvl:3} {ilvl:3} {q} {str(st):8} {obt} {name} | {stype} {zone} | stats={stats} fx={fx}")

print("\n--- forever index trinkets rlvl<=22 ---")
n = 0
for it in idx.get("items") or []:
    if it.get("slot") != "Trinket" and it.get("slotId") != 12:
        continue
    if (it.get("rlvl") or 0) > 22:
        continue
    n += 1
    if n <= 40:
        print(it.get("id"), it.get("name"), "ilvl", it.get("ilvl"), "rlvl", it.get("rlvl"), "q", it.get("quality"))
print("count", n)
