"""Build the unit-tooltip index: creature or NPC name -> hunt items.

Drops come from sources.json (boss, rare, world drop, dungeon and raid trash),
including alternate droppers and a stored percent. Chance 0 means no percent
was stored.

Vendors, recipe sellers, and quest givers come from the coordinate pins, the
vendor price table, and the Wowhead coord cache when a pin stored no name.
A recipe seller is indexed by the pieces that person sells. A profession
trainer who does not sell the recipe is indexed by name to that profession.
The tooltip then uses the crafted hunts of that profession. The trainer
window is never opened.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "pipeline" / "data" / "sources.json"
COORDS = ROOT / "GearQuest" / "_generated" / "Data.Coordinates.generated.lua"
FACTS = ROOT / "GearQuest" / "_generated" / "Data.HuntFacts.generated.lua"
CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "coord_cache.json"
PROF_DIR = ROOT / "pipeline" / "data" / "forever_wowhead" / "professions"
GENERATED = ROOT / "GearQuest" / "_generated"
OUT = ROOT / "GearQuest" / "_generated" / "Data.MobDrops.generated.lua"
CLASS_FILES = {
    "Hunter",
    "Mage",
    "Priest",
    "Rogue",
    "Druid",
    "Warrior",
    "Paladin",
    "Shaman",
    "Warlock",
}
# These are the professions that produce worn gear. A city trainer teaches
# the skill. The camp vendor sells some of the recipes. Both should answer.
GEAR_PROFESSIONS = {
    "alchemy.json": "Alchemy",
    "blacksmithing.json": "Blacksmithing",
    "enchanting.json": "Enchanting",
    "engineering.json": "Engineering",
    "leatherworking.json": "Leatherworking",
    "tailoring.json": "Tailoring",
}
HUNT_ROW = re.compile(r"\{(\d+),\"")

DROP_KINDS = {
    "boss_drop": "b",
    "rare_npc": "r",
    "world_drop": "w",
    "raid_trash": "t",
}
NOTE_KINDS = {
    "vendor that sells this": "v",
    "vendor that sells the recipe": "p",
    "beginning of the quest or chain": "q",
}
SKIP_NAMES = {
    "",
    "unknown",
    "unused",
    "placeholder",
    "(dnt)",
    "a vendor",
    "a container",
    "a chest",
}
BOUGHT = re.compile(r"Bought from ([^.]+)\.")
SPOT = re.compile(r"\{[^{}]*\}")
LINE = re.compile(r"\[(\d+)\]=\{note=\"([^\"]+)\"")
SELLER = re.compile(r"vendorCost\[(\d+)\].*?sellers = \{([^}]*)\}")
SELLER_NAME = re.compile(r"\[\"([^\"]+)\"\]")


def norm(name: str) -> str | None:
    if not isinstance(name, str):
        return None
    key = " ".join(name.split()).lower()
    if key in SKIP_NAMES or key.isdigit() or len(key) < 2:
        return None
    return key


def lua_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def as_chance(value) -> float:
    if value is None or value == "":
        return 0.0
    try:
        chance = float(value)
    except (TypeError, ValueError):
        return 0.0
    if chance < 0:
        return 0.0
    return chance


def chance_literal(chance: float) -> str:
    if chance <= 0:
        return "0"
    rounded = round(chance, 2)
    if rounded == int(rounded):
        return str(int(rounded))
    return f"{rounded:.2f}".rstrip("0").rstrip(".")


def faction_code(value) -> int:
    if value == "Alliance" or value == 1:
        return 1
    if value == "Horde" or value == 2:
        return 2
    return 0


def split_names(text: str) -> list[str]:
    text = text.replace(" and ", ", ")
    names = []
    for part in text.split(","):
        name = " ".join(part.split()).strip()
        if norm(name):
            names.append(name)
    return names


class Index:
    def __init__(self) -> None:
        self.rows: dict[str, dict[int, list]] = {}

    def put(self, name: str, item_id: int, chance: float, kind: str, faction: int) -> None:
        key = norm(name)
        if not key or not isinstance(item_id, int):
            return
        bucket = self.rows.setdefault(key, {})
        prev = bucket.get(item_id)
        if prev is None:
            bucket[item_id] = [chance, kind, faction]
            return
        if chance > prev[0]:
            prev[0] = chance
        prev_drop = prev[1] in DROP_KINDS.values()
        new_drop = kind in DROP_KINDS.values()
        if new_drop and not prev_drop:
            prev[1] = kind
        elif not prev_drop and not new_drop and kind == "p" and prev[1] == "v":
            prev[1] = "p"
        if prev_drop or new_drop:
            prev[2] = 0
        elif prev[2] and faction and prev[2] != faction:
            prev[2] = 0
        elif not prev[2] and faction:
            prev[2] = faction

    def has_kind(self, item_id: int, kind: str) -> bool:
        for bucket in self.rows.values():
            row = bucket.get(item_id)
            if row and row[1] == kind:
                return True
        return False


def add_npc(index: Index, npc, item_id: int, chance, kind: str, faction: int = 0) -> None:
    if isinstance(npc, list):
        for one in npc:
            add_npc(index, one, item_id, chance, kind, faction)
        return
    if isinstance(npc, str):
        index.put(npc, item_id, as_chance(chance), kind, faction)


def add_sources(index: Index, sources: dict) -> None:
    for raw_id, src in sources.items():
        if not isinstance(src, dict):
            continue
        kind = DROP_KINDS.get(src.get("sourceType"))
        if not kind:
            if src.get("sourceType") == "vendor":
                add_npc(index, src.get("npc"), _item_id(raw_id), 0, "v")
            elif src.get("sourceType") == "profession":
                match = BOUGHT.search(src.get("instructions") or "")
                if match:
                    for name in split_names(match.group(1)):
                        index.put(name, _item_id(raw_id), 0, "p", 0)
            elif src.get("sourceType") == "quest_reward":
                add_npc(index, src.get("npc"), _item_id(raw_id), 0, "q")
            continue
        item_id = _item_id(raw_id)
        if item_id is None:
            continue
        add_npc(index, src.get("npc"), item_id, src.get("dropChance"), kind)
        for alt in src.get("alts") or []:
            if isinstance(alt, dict):
                add_npc(index, alt.get("npc"), item_id, alt.get("chance"), kind)


def _item_id(raw) -> int | None:
    try:
        return int(raw)
    except (TypeError, ValueError):
        return None


def add_coordinates(index: Index) -> None:
    if not COORDS.exists():
        return
    for line in COORDS.read_text(encoding="utf-8").splitlines():
        head = LINE.search(line)
        if not head:
            continue
        kind = NOTE_KINDS.get(head.group(2))
        if not kind:
            continue
        item_id = int(head.group(1))
        for spot in SPOT.findall(line):
            npc = re.search(r'npc="([^"]+)"', spot)
            if not npc:
                continue
            fac = re.search(r'faction="(Alliance|Horde)"', spot)
            index.put(npc.group(1), item_id, 0, kind, faction_code(fac.group(1) if fac else None))


def add_vendor_costs(index: Index) -> None:
    if not FACTS.exists():
        return
    text = FACTS.read_text(encoding="utf-8")
    for item_id, body in SELLER.findall(text):
        for name in SELLER_NAME.findall(body):
            index.put(name, int(item_id), 0, "v", 0)


def npc_names(cache: dict) -> dict[int, str]:
    found: dict[int, str] = {}
    for key, rows in (cache.get("search") or {}).items():
        if not isinstance(key, str) or not key.startswith("npc\n"):
            continue
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, dict) or not row.get("id"):
                continue
            name = row.get("name") or key.split("\n", 1)[1]
            if not isinstance(name, str):
                continue
            name = " ".join(name.split())
            if not norm(name):
                continue
            npc_id = int(row["id"])
            old = found.get(npc_id)
            if old is None or (old.islower() and not name.islower()):
                found[npc_id] = name
    return found


def root_quest(qid: int, quests: dict, depth: int = 0) -> int:
    row = quests.get(str(qid)) or {}
    earlier = row.get("earlier")
    try:
        earlier = int(earlier) if earlier else None
    except (TypeError, ValueError):
        earlier = None
    if earlier and earlier != qid and depth < 12:
        return root_quest(earlier, quests, depth + 1)
    return qid


def add_quest_cache(index: Index, sources: dict) -> int:
    if not CACHE.exists():
        print("coord cache missing; quest givers are the named pins only")
        return 0
    cache = json.loads(CACHE.read_text(encoding="utf-8"))
    names = npc_names(cache)
    quests = cache.get("quest") or {}
    item_quest = cache.get("itemQuest") or {}
    added = 0
    for raw_id, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "quest_reward":
            continue
        item_id = _item_id(raw_id)
        if item_id is None:
            continue
        qids = item_quest.get(str(item_id)) or item_quest.get(item_id) or []
        if not isinstance(qids, list):
            continue
        seen = set()
        for qid in qids:
            try:
                root = root_quest(int(qid), quests)
            except (TypeError, ValueError):
                continue
            if root in seen:
                continue
            seen.add(root)
            row = quests.get(str(root)) or {}
            fac = faction_code(row.get("faction"))
            npc_ids = []
            for npc_id in row.get("startNpcs") or []:
                npc_ids.append(npc_id)
            for place in row.get("places") or []:
                if not isinstance(place, dict):
                    continue
                if place.get("point") not in ("start", None, ""):
                    continue
                if place.get("point") == "" and row.get("startNpcs"):
                    continue
                if isinstance(place.get("npc"), int):
                    npc_ids.append(place["npc"])
            for npc_id in npc_ids:
                try:
                    name = names.get(int(npc_id))
                except (TypeError, ValueError):
                    name = None
                if not name:
                    continue
                before = index.rows.get(norm(name) or "", {}).get(item_id)
                index.put(name, item_id, 0, "q", fac if place_faction(row, npc_id) == 0 else place_faction(row, npc_id))
                after = index.rows.get(norm(name) or "", {}).get(item_id)
                if before is None and after is not None:
                    added += 1
    return added


def place_faction(row: dict, npc_id: int) -> int:
    for place in row.get("places") or []:
        if isinstance(place, dict) and place.get("npc") == npc_id:
            code = faction_code(place.get("faction"))
            if code:
                return code
    return faction_code(row.get("faction"))


def hunt_item_ids() -> set[int]:
    found: set[int] = set()
    for path in GENERATED.glob("Data.*.generated.lua"):
        parts = path.name.split(".")
        if len(parts) < 2 or parts[1] not in CLASS_FILES:
            continue
        text = path.read_text(encoding="utf-8")
        for item_id in HUNT_ROW.findall(text):
            found.add(int(item_id))
    return found


def profession_tables(sources: dict) -> tuple[dict[str, list[int]], dict[str, list]]:
    hunted = hunt_item_ids()
    gear: dict[str, list[int]] = {name: [] for name in GEAR_PROFESSIONS.values()}
    for raw_id, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "profession":
            continue
        profession = src.get("profession")
        item_id = _item_id(raw_id)
        if item_id is None or profession not in gear or item_id not in hunted:
            continue
        gear[profession].append(item_id)
    for profession in gear:
        gear[profession] = sorted(set(gear[profession]))
    trainers: dict[str, list] = {}
    for filename, profession in GEAR_PROFESSIONS.items():
        path = PROF_DIR / filename
        if not path.exists() or not gear.get(profession):
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for row in data.get("trainers") or []:
            if not isinstance(row, dict):
                continue
            name = row.get("n")
            key = norm(name) if isinstance(name, str) else None
            if not key:
                continue
            faction = faction_code(row.get("side") or None)
            prev = trainers.get(key)
            if prev is None:
                trainers[key] = [profession, faction, name.strip()]
                continue
            if prev[0] != profession:
                continue
            if prev[1] and faction and prev[1] != faction:
                prev[1] = 0
            elif not prev[1] and faction:
                prev[1] = faction
    return gear, trainers


def main() -> None:
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    index = Index()
    add_sources(index, sources)
    add_coordinates(index)
    add_vendor_costs(index)
    quest_names = add_quest_cache(index, sources)
    gear, trainers = profession_tables(sources)
    lines = [
        "local _, GQ = ...",
        "GQ.Data = GQ.Data or {}",
        "-- Name (lowercase) -> { itemId, chance, kind, faction }.",
        "-- Chance 0 means no stored percent. Kind is b r w t v p q.",
        "-- Faction 0 is both, 1 Alliance, 2 Horde.",
        "GQ.Data.mobDrops = {",
    ]
    named = 0
    rows = 0
    with_chance = 0
    kinds = {k: 0 for k in "brwtvpq"}
    for name in sorted(index.rows):
        items = index.rows[name]
        if not items:
            continue
        named += 1
        parts = []
        for item_id in sorted(items):
            chance, kind, faction = items[item_id]
            rows += 1
            kinds[kind] = kinds.get(kind, 0) + 1
            if chance > 0:
                with_chance += 1
            parts.append(
                "{"
                + str(item_id)
                + ","
                + chance_literal(chance)
                + ',"'
                + kind
                + '",'
                + str(faction)
                + "}"
            )
        lines.append("[" + lua_string(name) + "]={" + ",".join(parts) + "},")
    lines.append("}")
    lines.append("GQ.Data.professionGear = {")
    for profession in sorted(gear):
        ids = gear[profession]
        if not ids:
            continue
        lines.append("[" + lua_string(profession) + "]={" + ",".join(str(item_id) for item_id in ids) + "},")
    lines.append("}")
    lines.append("GQ.Data.professionTrainers = {")
    for key in sorted(trainers):
        profession, faction, _display = trainers[key]
        lines.append("[" + lua_string(key) + "]={" + lua_string(profession) + "," + str(faction) + "},")
    lines.append("}")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(
        f"names {named} rows {rows} with chance {with_chance} "
        f"quest names added {quest_names} kinds {kinds} "
        f"trainers {len(trainers)} gear "
        + " ".join(f"{name}:{len(ids)}" for name, ids in sorted(gear.items()))
        + f" -> {OUT}"
    )


if __name__ == "__main__":
    main()
