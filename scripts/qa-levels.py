import re
from collections import defaultdict

path = r"C:\Users\Henrik\Projects\GearQuest\GearQuest\Data.lua"
text = open(path, encoding="utf-8").read()

consts = {}
for m in re.finditer(r"local (LEVEL\d+_(?:MIN|MAX)|EARLY4_MAX|EARLY_MIN|EARLY_MAX) = (\d+)", text):
    consts[m.group(1)] = int(m.group(2))


def resolve(val):
    val = val.strip()
    if val.isdigit():
        return int(val)
    return consts.get(val, val)


entry_re = re.compile(
    r'\{\s*\n\s*id = "([^"]+)",\s*\n\s*itemId = (\d+),\s*\n\s*slot = "([^"]+)",\s*\n\s*minLevel = ([^,]+),\s*\n\s*maxLevel = ([^,]+),',
    re.MULTILINE,
)

entries = []
for m in entry_re.finditer(text):
    start = m.start()
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
        i += 1
    else:
        continue
    block = text[start:end]
    e = {
        "id": m.group(1),
        "itemId": int(m.group(2)),
        "slot": m.group(3),
        "minLevel": resolve(m.group(4)),
        "maxLevel": resolve(m.group(5)),
    }
    for field in [
        "classes",
        "factions",
        "curatedRank",
        "sourceType",
        "zone",
        "npc",
        "questName",
        "profession",
        "specs",
        "instructions",
    ]:
        fm = re.search(rf"{field} = ([^\n]+)", block)
        if fm:
            e[field] = fm.group(1).strip().strip(",")
    entries.append(e)

print(f"Parsed {len(entries)} entries")


def select_band(player_level):
    best = None
    for e in entries:
        mn, mx = e["minLevel"], e["maxLevel"]
        if not isinstance(mn, int) or not isinstance(mx, int):
            continue
        if player_level >= mn and player_level <= mx:
            if best is None or mn > best[0] or (mn == best[0] and mx < best[1]):
                best = (mn, mx)
    if best is None:
        for e in entries:
            mn = e["minLevel"]
            if not isinstance(mn, int):
                continue
            if player_level >= mn:
                if best is None or mn > best[0]:
                    best = (mn, None)
    return best


BODY_SLOTS = [
    "Back",
    "Chest",
    "Wrist",
    "MainHand",
    "SecondaryHand",
    "Feet",
    "Legs",
    "Waist",
    "Hands",
]

HORDE_ZONES = {
    "Durotar",
    "Tirisfal Glades",
    "Mulgore",
    "Eversong Woods",
    "Ghostlands",
    "Silvermoon City",
    "Undercity",
    "Orgrimmar",
    "Thunder Bluff",
}

HORDE_NPCS = {
    "Faraden Thelryn",
}

issues = []

for lvl in range(1, 11):
    band = select_band(lvl)
    active = [
        e
        for e in entries
        if e["minLevel"] == band[0] and (band[1] is None or e["maxLevel"] == band[1])
    ]
    by_slot = defaultdict(list)
    for e in active:
        if "classes" not in e:
            continue
        if "WARRIOR" not in e.get("classes", "") and "PALADIN" not in e.get("classes", ""):
            continue
        by_slot[e["slot"]].append(e)

    for slot in BODY_SLOTS:
        items = by_slot.get(slot, [])
        if len(items) != 3:
            issues.append(
                f"L{lvl} {slot}: {len(items)} mail-melee items (band {band}, expected 3)"
            )
        ranks = sorted(int(i.get("curatedRank", 0)) for i in items if i.get("curatedRank"))
        if items and ranks != [1, 2, 3]:
            issues.append(f"L{lvl} {slot}: ranks {ranks} (expected [1,2,3])")

        for i in items:
            zone = i.get("zone", "").strip('"')
            npc = i.get("npc", "").strip('"')
            st = i.get("sourceType", "").strip('"')
            if "factions" in i and "Alliance" not in i.get("factions", ""):
                issues.append(f"L{lvl} {i['id']}: no Alliance faction filter")
            if zone in HORDE_ZONES:
                sev = "HORDE_ZONE"
                if st == "vendor":
                    sev = "HORDE_VENDOR_ZONE"
                elif st == "quest_reward":
                    sev = "HORDE_QUEST_ZONE"
                issues.append(
                    f"{sev} L{lvl} rank{i.get('curatedRank')} {i['id']} item={i['itemId']} zone={zone} npc={npc} type={st}"
                )
            if npc in HORDE_NPCS:
                issues.append(
                    f"HORDE_NPC L{lvl} {i['id']} item={i['itemId']} vendor {npc}"
                )
            if st == "boss_drop" and "Grik" in i.get("npc", ""):
                issues.append(f"MISLABEL L{lvl} {i['id']}: boss_drop for Grik'nir (should be world_drop)")

# Global scans
for e in entries:
    if "WARRIOR" not in e.get("classes", "") and "PALADIN" not in e.get("classes", ""):
        continue
    inst = e.get("instructions", "")
    if "Sunstrider Isle" in inst and "Proenitus" in e.get("npc", ""):
        issues.append(
            f"QUEST_TEXT L{e['id']}: says Sunstrider Isle but Proenitus is on Azuremyst Isle (Draenei)"
        )

print("\n=== Active band per level ===")
for lvl in range(1, 11):
    band = select_band(lvl)
    active = [
        e
        for e in entries
        if e["minLevel"] == band[0]
        and (band[1] is None or e["maxLevel"] == band[1])
        and "classes" in e
        and ("WARRIOR" in e["classes"] or "PALADIN" in e["classes"])
    ]
    slots = defaultdict(int)
    for e in active:
        slots[e["slot"]] += 1
    print(f"  L{lvl}: band {band} -> {dict(sorted(slots.items()))}")

print(f"\n=== ISSUES ({len(issues)}) ===")
for i in sorted(set(issues)):
    print(i)

print("\n=== Vendor NPCs in L1-10 active bands ===")
seen = set()
for lvl in range(1, 11):
    band = select_band(lvl)
    for e in entries:
        if e["minLevel"] != band[0] or (band[1] is not None and e["maxLevel"] != band[1]):
            continue
        if e.get("sourceType", "").strip('"') != "vendor":
            continue
        if "classes" not in e:
            continue
        key = (e["itemId"], e.get("npc", "").strip('"'))
        if key not in seen:
            seen.add(key)
            print(
                f"  item={e['itemId']} npc={e.get('npc','').strip(chr(34))} zone={e.get('zone','').strip(chr(34))} id={e['id']}"
            )
