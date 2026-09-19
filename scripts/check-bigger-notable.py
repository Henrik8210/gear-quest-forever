import json

w = json.load(open(r"C:\Users\Henrik\Projects\GearQuestForever\pipeline\out\warrior.json", encoding="utf-8"))
for b in w["protection"]["bands"]:
    if b.get("faction") != "Alliance":
        continue
    if b["slot"] != "SecondaryHand":
        continue
    if not (b["lo"] <= 51 <= b["hi"]):
        continue
    print("band", b["lo"], b["hi"])
    print("picks", [(p["id"], p["name"], p["score"]) for p in b["picks"][:8]])
    print("notables", [(p["id"], p["name"], p.get("score")) for p in (b.get("notableEffects") or [])])
