"""Pin Forever-client item facts that Wowhead nether tips get wrong.

Wowhead overstates Coldflame Saber / Blade of Silverlaine white damage and
drops the spell power the client shows. Those ids live in
pipeline/data/client_item_overrides.json. sync and ingest must not copy the
nether tip back over them.

Also inserts Forever index ids that are new and have a fetched tooltip, without
rewriting any existing item.
"""
from __future__ import annotations

import json
from pathlib import Path

from gq_paths import DATA

ITEMS = Path(DATA) / "items.json"
POOL = Path(DATA) / "classic_item_ids.json"
SOURCES = Path(DATA) / "sources.json"
PINS = Path(DATA) / "client_item_overrides.json"
HUNT = Path(DATA) / "forever_wowhead" / "hunt_tooltips.json"

# Shapeshifting Sentinel's Strides. New on the 22 Sep index. Tooltip fetched
# once; not a rewrite of an existing row.
NEW_BOOTS_ID = 284403
NEW_BOOTS_TIP = (
    "Item Level 29\n"
    "Binds when picked up\n"
    "Feet Leather\n"
    "70 Armor\n"
    "+8 Agility\n"
    "+16 Attack Power\n"
    "Requires Level 24\n"
    "Sell Price: 17 88"
)


def load_pins() -> dict:
    if not PINS.exists():
        return {}
    return json.loads(PINS.read_text(encoding="utf-8"))


def pin_ids() -> set[str]:
    return set(load_pins())


def apply_pins(items: dict) -> list[str]:
    changed = []
    for key, pin in load_pins().items():
        it = items.get(key)
        if not it:
            print("pin missing from items.json", key)
            continue
        if "rlvl" in pin:
            it["rlvl"] = pin["rlvl"]
        if "dps" in pin:
            it["dps"] = pin["dps"]
            it["speed"] = pin["speed"]
            it["delay"] = int(round(pin["speed"] * 1000))
            it["dmgMin"] = pin["dmgMin"]
            it["dmgMax"] = pin["dmgMax"]
        if "stats" in pin:
            it["stats"] = dict(pin.get("stats") or {})
        if "tipClasses" in pin:
            it["tipClasses"] = list(pin.get("tipClasses") or [])
        if "procs" in pin:
            it["procs"] = list(pin.get("procs") or [])
        if "effects" in pin:
            it["effects"] = list(pin.get("effects") or [])
            it["effectDriven"] = False
        changed.append(f"{key} {it.get('name')}")
    return changed


def insert_boots(items: dict) -> bool:
    key = str(NEW_BOOTS_ID)
    if key in items:
        return False
    sub = 2
    index_path = Path(DATA) / "forever_wowhead" / "index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text(encoding="utf-8"))
        for row in index.get("items") or []:
            if row.get("id") == NEW_BOOTS_ID:
                sub = row.get("subclass") if row.get("subclass") is not None else sub
                break
    kind = {0: "Misc", 1: "Cloth", 2: "Leather", 3: "Mail", 4: "Plate"}.get(sub, "Leather")
    items[key] = {
        "id": NEW_BOOTS_ID,
        "name": "Shapeshifting Sentinel's Strides",
        "slot": "Feet",
        "quality": 3,
        "ilvl": 29,
        "rlvl": 24,
        "cls": 4,
        "sub": sub,
        "kind": kind,
        "inv": 8,
        "allowClass": -1,
        "allowRace": -1,
        "randProp": 0,
        "randSuffix": 0,
        "reqSkill": 0,
        "reqSkillRank": 0,
        "block": 0,
        "delay": 0,
        "itemset": 0,
        "bonding": 1,
        "stats": {"armor": 70, "agi": 8, "ap": 16},
        "dps": 0.0,
        "speed": 0.0,
        "dmgMin": 0.0,
        "dmgMax": 0.0,
        "sockets": [],
        "socketBonus": None,
        "phase": 1,
        "bind": "BoP",
        "droppedBy": None,
        "randomEnchant": False,
        "hasTip": True,
        "flags": [],
        "reqSkills": [],
        "reqRep": [],
        "temporary": False,
        "effects": [],
        "procs": [],
        "effectDriven": False,
        "tipClasses": [],
    }
    return True


def insert_pool_id() -> bool:
    text = POOL.read_text(encoding="utf-8")
    needle = str(NEW_BOOTS_ID)
    if needle in text:
        return False
    # Compact or pretty array of ints. Insert in numeric order without a full reformat.
    ids = [int(x) for x in json.loads(text)]
    ids.append(NEW_BOOTS_ID)
    ids = sorted(set(ids))
    # Preserve one-line compact form if that is what the file already is.
    if "\n" not in text.strip():
        POOL.write_text("[" + ",".join(str(i) for i in ids) + "]", encoding="utf-8")
    else:
        POOL.write_text(json.dumps(ids), encoding="utf-8")
    return True


def insert_source() -> bool:
    text = SOURCES.read_text(encoding="utf-8")
    key = f'"{NEW_BOOTS_ID}"'
    if key in text:
        return False
    block = """  "284403": {
    "sourceType": "world_drop",
    "instructions": "Indexed from Wowhead Forever. Source not listed yet.",
    "zone": null,
    "npc": null,
    "questName": null,
    "profession": null,
    "dropChance": null,
    "alts": [],
    "gateLevel": 24,
    "questClasses": 0,
    "questRaces": 0,
    "seasonal": false,
    "obtainable": true,
    "excludedBecause": null
  }"""
    stripped = text.rstrip()
    if not stripped.endswith("}"):
        raise SystemExit("sources.json does not end with }")
    head = stripped[: stripped.rfind("}")]
    head = head.rstrip()
    if head.endswith("}"):
        head = head[:-1].rstrip() + "},"
    else:
        raise SystemExit("could not find the last source object")
    SOURCES.write_text(head + "\n" + block + "\n}\n", encoding="utf-8")
    return True


def insert_hunt_tip() -> bool:
    if not HUNT.exists():
        print("no hunt_tooltips.json; skip boots tip")
        return False
    tips = json.loads(HUNT.read_text(encoding="utf-8"))
    key = str(NEW_BOOTS_ID)
    if key in tips and (tips[key].get("tip") or ""):
        return False
    tips[key] = {
        "status": "ok",
        "name": "Shapeshifting Sentinel's Strides",
        "quality": 3,
        "tip": "Shapeshifting Sentinel's Strides\n" + NEW_BOOTS_TIP,
    }
    HUNT.write_text(json.dumps(tips, ensure_ascii=False), encoding="utf-8")
    return True


def main():
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    pinned = apply_pins(items)
    boots = insert_boots(items)
    payload = json.dumps(items, separators=(",", ":"), ensure_ascii=False)
    tmp = ITEMS.with_suffix(".json.tmp")
    tmp.write_text(payload, encoding="utf-8")
    tmp.replace(ITEMS)
    print("pinned", ", ".join(pinned) or "(none)")
    print("boots inserted" if boots else "boots already present")
    print("pool", "inserted" if insert_pool_id() else "already present")
    print("source", "inserted" if insert_source() else "already present")
    print("hunt tip", "inserted" if insert_hunt_tip() else "already present")


if __name__ == "__main__":
    main()
