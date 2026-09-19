import re

p = r"C:\Users\Henrik\Projects\GearQuest\GearQuest\_generated\Data.Warrior.generated.lua"
text = open(p, encoding="utf-8").read()
names = {}
for m in re.finditer(r'\[(\d+)\]=\{name="([^"]+)"', text):
    names[int(m.group(1))] = m.group(2)
rows = []
for m in re.finditer(r'\{(\d+),"([^"]+)",(\d+),(\d+),(\d+),"([^"]+)","([^"]+)"', text):
    rows.append(
        {
            "id": int(m.group(1)),
            "slot": m.group(2),
            "lo": int(m.group(3)),
            "hi": int(m.group(4)),
            "rank": int(m.group(5)),
            "spec": m.group(6),
            "faction": m.group(7),
        }
    )
print("picks", len(rows), "260210 in facts", 260210 in names)
for spec in ("arms", "fury", "protection"):
    print("====", spec)
    for slot in ("Wrist", "Ranged", "Trinket", "SecondaryHand", "Head", "Hands"):
        hit = [
            r
            for r in rows
            if r["spec"] == spec
            and r["faction"] == "Alliance"
            and r["slot"] == slot
            and r["lo"] <= 51 <= r["hi"]
        ]
        hit.sort(key=lambda x: x["rank"])
        label = [f"{names.get(r['id'], r['id'])}#{r['id']}" for r in hit]
        print(f"  {slot:14} {label}")
print("bigger rows", [r for r in rows if r["id"] == 260210][:12])
