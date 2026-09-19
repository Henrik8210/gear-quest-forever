import json

w = json.load(open(r"C:\Users\Henrik\Projects\GearQuestForever\pipeline\out\warrior.json", encoding="utf-8"))
for spec in ("arms", "fury", "protection"):
    print("====", spec)
    for slot in (
        "Wrist",
        "Ranged",
        "Trinket",
        "SecondaryHand",
        "Head",
        "Back",
        "Feet",
        "Finger",
        "Chest",
        "Hands",
    ):
        found = False
        for b in w[spec]["bands"]:
            if b.get("faction") != "Alliance":
                continue
            if b["lo"] <= 51 <= b["hi"] and b["slot"] == slot:
                names = [f"{p['name']}#{p['id']}" for p in b["picks"][:8]]
                print(f"  {slot:14} {b['lo']}-{b['hi']} n={len(b['picks'])} {names}")
                found = True
        if not found:
            print(f"  {slot:14} MISSING")
