"""Move dungeon and raid trash off the boss-drop source.

Wowhead's boss flag is missing on real bosses (Edwin VanCleef has none), so a
missing flag is not trash. A creature stays a boss when it is in
dungeon_entrances.json bossNpcs, or when Wowhead did set boss. A rare that is
not on that list becomes Rare NPC. A normal mob, or a name in TRASH below,
becomes raid_trash. The log calls that source Dungeon & Raid trash.
"""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "pipeline" / "data" / "sources.json"
DOORS = ROOT / "pipeline" / "data" / "dungeon_entrances.json"
FLAGS = ROOT / "pipeline" / "data" / "npc_boss_flags.json"
GENERATED = ROOT / "GearQuest" / "_generated"

# Generic instance mobs. Unique boss names stay boss_drop even when Wowhead
# forgot the boss flag.
TRASH = {
    "Anubisath Warder",
    "Arcane Aberration",
    "Arcane Torrent",
    "Blackhand Assassin",
    "Blackhand Iron Guard",
    "Blackhand Summoner",
    "Blackwing Warlock",
    "Crimson Battle Mage",
    "Crimson Gallant",
    "Crimson Inquisitor",
    "Crimson Monk",
    "Crimson Priest",
    "Death Talon Captain",
    "Death Talon Wyrmguard",
    "Death Talon Wyrmkin",
    "Death's Head Priest",
    "Defias Blackguard",
    "Defias Miner",
    "Defias Overseer",
    "Defias Prisoner",
    "Defias Squallshaper",
    "Defias Strip Miner",
    "Defias Watchman",
    "Defias Wizard",
    "Druid of the Fang",
    "Eldreth Apparition",
    "Eldreth Spectre",
    "Fel Steed",
    "Goblin Craftsman",
    "Goblin Engineer",
    "Goblin Shipbuilder",
    "Goblin Woodcarver",
    "Gordok Mastiff",
    "Ironbark Protector",
    "Obsidian Nullifier",
    "Petrified Treant",
    "Phase Lasher",
    "Rage Talon Dragonspawn",
    "Rage Talon Fire Tongue",
    "Rage Talon Flamescale",
    "Razorfen Spearhide",
    "Saturated Ooze",
    "Scarlet Centurion",
    "Scarlet Champion",
    "Scarlet Myrmidon",
    "Scarlet Protector",
    "Scholomance Necromancer",
    "Smolderthorn Headhunter",
    "Smolderthorn Witch Doctor",
    "Spire Spider",
    "Splintered Skeleton",
    "Twilight Acolyte",
    "Warpwood Guardian",
    "Wildspawn Satyr",
}


def kind_for(npc: str, bosses: set[str], flags: dict) -> str | None:
    if not npc or npc in bosses:
        return None
    if npc in TRASH:
        return "raid_trash"
    row = flags.get(npc) or {}
    if row.get("status") != "ok" or row.get("boss"):
        return None
    if row.get("classification") in (2, 4):
        return "rare_npc"
    if row.get("classification") == 0:
        return "raid_trash"
    return None


def main() -> None:
    doors = json.loads(DOORS.read_text(encoding="utf-8"))
    zones = set(doors["entrances"])
    bosses = set(doors["bossNpcs"])
    flags = json.loads(FLAGS.read_text(encoding="utf-8")) if FLAGS.exists() else {}
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    changed: dict[str, str] = {}
    for key, src in sources.items():
        if not isinstance(src, dict) or src.get("sourceType") != "boss_drop":
            continue
        if (src.get("zone") or "") not in zones:
            continue
        new = kind_for(src.get("npc") or "", bosses, flags)
        if not new:
            continue
        src["sourceType"] = new
        changed[key] = new
    tmp = SOURCES.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(sources, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")
    os.replace(tmp, SOURCES)
    print(f"sources {len(changed)}")
    from collections import Counter
    print(Counter(changed.values()))

    ids_by_kind = {iid: kind for iid, kind in changed.items()}
    files = 0
    hits = 0
    for path in GENERATED.glob("Data.*.generated.lua"):
        text = path.read_bytes().decode("latin-1")
        lines = text.splitlines(keepends=True)
        file_hits = 0
        for i, line in enumerate(lines):
            if 'sourceType="boss_drop"' not in line or not line.startswith("    ["):
                continue
            bracket = line.find("]")
            iid = line[line.find("[") + 1 : bracket]
            kind = ids_by_kind.get(iid)
            if not kind:
                continue
            lines[i] = line.replace('sourceType="boss_drop"', f'sourceType="{kind}"', 1)
            file_hits += 1
        if file_hits:
            path.write_bytes("".join(lines).encode("latin-1"))
            files += 1
            hits += file_hits
            print(f"  {path.name} {file_hits}")
    print(f"lua files {files} facts {hits}")
    fang = sources.get("10413") or {}
    print("10413", fang.get("sourceType"), fang.get("npc"))


if __name__ == "__main__":
    main()
