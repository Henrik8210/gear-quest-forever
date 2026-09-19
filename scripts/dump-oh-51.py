import re

p = r"C:\Users\Henrik\Projects\GearQuest\GearQuest\_generated\Data.Warrior.generated.lua"
text = open(p, encoding="utf-8").read()
names = {int(m.group(1)): m.group(2) for m in re.finditer(r'\[(\d+)\]=\{name="([^"]+)"', text)}
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

for spec in ("protection", "arms", "fury"):
    for faction in ("Alliance", "Horde"):
        hit = [
            r
            for r in rows
            if r["spec"] == spec
            and r["faction"] == faction
            and r["slot"] == "SecondaryHand"
            and r["lo"] <= 51 <= r["hi"]
        ]
        hit.sort(key=lambda x: x["rank"])
        print(spec, faction, [f"{names.get(r['id'])}#{r['id']}" for r in hit])
print("260210 facts", 260210 in names)
