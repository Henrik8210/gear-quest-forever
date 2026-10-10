"""Ingest Wowhead Forever item index + tooltips into the pipeline pool.

Reads pipeline/data/forever_wowhead/{index,tooltips}.json written by
scripts/scrape-forever-wowhead-items.mjs and merges new ids into:

  pipeline/data/items.json
  pipeline/data/sources.json
  pipeline/data/classic_item_ids.json

New Forever-only ids are inserted. An id already in items.json keeps its
facts. Re-score after this:

  $env:GQ_CLASS="SHAMAN"; $env:GQ_GUIDES="guides_shaman.json"; $env:GQ_OUT="shaman.json"
  python pipeline/scripts/score.py
  python pipeline/scripts/payload.py
  python pipeline/scripts/emit_early.py
"""
from __future__ import annotations

import html
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commerce_camps import camp_instructions
from gq_paths import G, DATA

def _client_pins():
    path = os.path.join(G, "client_item_overrides.json")
    if not os.path.exists(path):
        return set()
    return set(json.load(open(path, encoding="utf-8")))


INDEX = os.path.join(DATA, "forever_wowhead", "index.json")
TIPS = os.path.join(DATA, "forever_wowhead", "tooltips.json")
ILVL_FLOOR = json.load(open(os.path.join(DATA, "ilvl_floor.json"), encoding="utf-8"))

MOD = {
    0: "mana", 1: "health", 3: "agi", 4: "str", 5: "int", 6: "spi", 7: "sta",
    12: "defense", 13: "dodge", 14: "parry", 15: "blockRating",
    16: "hit", 17: "hitRanged", 18: "spellHit", 19: "crit", 20: "critRanged",
    21: "spellCrit", 28: "haste", 29: "hasteRanged", 30: "spellHaste",
    31: "hit", 32: "crit", 33: "hitTaken", 34: "critTaken", 35: "resilience",
    36: "haste", 37: "expertise",
    # Forever nether tooltip rating ids.
    38: "ap", 39: "rap", 41: "heal", 42: "damageDone", 43: "mp5", 44: "armorPen",
    45: "sp", 46: "hp5", 47: "spellPen", 48: "blockValue", 50: "armor",
}

INV = {
    1: "Head", 2: "Neck", 3: "Shoulder", 5: "Chest", 20: "Chest", 6: "Waist",
    7: "Legs", 8: "Feet", 9: "Wrist", 10: "Hands", 11: "Finger", 12: "Trinket",
    16: "Back", 14: "Shield", 13: "OneHand", 17: "TwoHand", 21: "MainHand",
    22: "OffHand", 23: "Held", 15: "Ranged", 26: "Ranged", 25: "Thrown",
    28: "Relic",
}
ARMOR_SUB = {
    0: "Misc", 1: "Cloth", 2: "Leather", 3: "Mail", 4: "Plate", 5: "Buckler",
    6: "Shield", 7: "Libram", 8: "Idol", 9: "Totem", 10: "Sigil",
    # Wowhead Forever uses negative subclasses for slots that are not armor:
    # neck -3, finger -2, trinket -4, cloak -6, held -5. Those are Misc, same
    # as classic necks and rings. Left as "?" they never become eligible.
    -2: "Misc", -3: "Misc", -4: "Misc", -5: "Misc", -6: "Misc",
}
WEAP_SUB = {
    0: "Axe1H", 1: "Axe2H", 2: "Bow", 3: "Gun", 4: "Mace1H", 5: "Mace2H",
    6: "Polearm", 7: "Sword1H", 8: "Sword2H", 10: "Staff", 13: "Fist",
    14: "MiscWeapon", 15: "Dagger", 16: "Thrown", 18: "Crossbow", 19: "Wand",
    20: "FishingPole",
}
SKILL = {
    129: "First Aid", 164: "Blacksmithing", 165: "Leatherworking",
    171: "Alchemy", 182: "Herbalism", 185: "Cooking", 186: "Mining",
    197: "Tailoring", 202: "Engineering", 333: "Enchanting",
    356: "Fishing", 393: "Skinning",
}
# Wowhead sourcemore.t
SRC_T = {
    1: "world_drop",
    2: "world_drop",
    4: "quest_reward",
    5: "vendor",
    6: "profession",
}

PATS = [
    # Both halves. Healers score the healing; damage casters score the damage.
    # Do not collapse this sentence into spell power alone.
    (r"Increases damage and healing done by magical spells and effects by up to (\d+)", "both"),
    (r"Increases healing done by up to (\d+) and damage done by up to (\d+) for all magical spells", "heal_sp"),
    (r"Increases attack power by (\d+) in Cat, Bear, Dire Bear, and Moonkin forms only", "feralAp"),
    (r"Increases melee and ranged attack power by (\d+)", "ap"),
    (r"Increases your melee and ranged attack power by (\d+)", "ap"),
    (r"Increases attack power by (\d+) when fighting \w+", "apVs"),
    (r"Increases attack power by (\d+)", "ap"),
    (r"Increases ranged attack power by (\d+)", "rap"),
    (r"Restores (\d+) mana per 5 sec", "mp5"),
    (r"Increases damage done by (Shadow|Fire|Frost|Nature|Arcane|Holy) spells and effects by up to (\d+)", "spSchoolNamed"),
    (r"Increases the block value of your shield by (\d+)", "blockValue"),
    (r"Your attacks ignore (\d+) of your opponent's armor", "armorPen"),
    (r"Increases your spell penetration by (\d+)", "spellPen"),
    (r"Restores (\d+) health per 5 sec", "hp5"),
    (r"Increased Defense \+(\d+)", "defense"),
    (r"Increases (?:your )?defense(?: skill)? by (\d+)", "defense"),
]
PATS = [(re.compile(p), k) for p, k in PATS]
rx_tag = re.compile(r"<[^>]+>")
SKIP_NAME = re.compile(r"\(DNT\)|\AHidden |\AMonster ", re.I)
# Not hunt gear. The chisel is a Jewelcrafting tool. The shield is a creature model.
SKIP_IDS = {271965, 286140}
UNKNOWN_RTG = {}


def plain(s):
    s = re.sub(r"<!--[^>]*?-->", "", s)
    return html.unescape(rx_tag.sub("", s))


def parse_tooltip(t):
    o = {"stats": {}, "flags": []}

    def add(k, v):
        o["stats"][k] = o["stats"].get(k, 0) + v

    m = re.search(r"<!--ilvl-->(\d+)", t)
    o["ilvl"] = int(m.group(1)) if m else 0
    m = re.search(r"<!--rlvl-->(\d+)", t)
    o["rlvl"] = int(m.group(1)) if m else 0
    m = re.search(r"<!--amr-->(\d+)", t)
    if m:
        add("armor", int(m.group(1)))
    m = re.search(r"(\d+)\s+Block\b", plain(t))
    if m:
        o["block"] = int(m.group(1))
    m = re.search(r"<!--dmg-->([\d.]+) - ([\d.]+)", t)
    if m:
        o["dmgMin"], o["dmgMax"] = float(m.group(1)), float(m.group(2))
    m = re.search(r"<!--spd-->([\d.]+)", t)
    if m:
        o["speed"] = float(m.group(1))
    m = re.search(r"<!--dps-->\(([\d.]+)", t)
    if m:
        o["dps"] = float(m.group(1))
    m = re.search(r"<!--scstart(\d+):(\d+)-->", t)
    if m:
        o["tipClass"], o["tipSub"] = int(m.group(1)), int(m.group(2))

    for sid, val in re.findall(r"<!--stat(\d+)-->\+?(-?\d+)", t):
        k = MOD.get(int(sid))
        if k:
            add(k, int(val))
    for sid, val in re.findall(r"<!--rtg(\d+)-->\+?(-?\d+)", t):
        sid = int(sid)
        k = MOD.get(sid)
        if k:
            add(k, int(val))
        else:
            UNKNOWN_RTG[sid] = UNKNOWN_RTG.get(sid, 0) + 1

    for m in re.finditer(r'<span class="q2">Equip:(.*?)</span>', t, re.S):
        raw = m.group(1)
        if "<!--rtg" in raw:
            # rtg41 already counted the number as healing. The sentence is
            # healing and spell damage. A split line (rtg41 and rtg42) already
            # has both. A party aura is not personal spell power.
            text = plain(raw)
            if ("damage and healing" in text and "party" not in text
                    and "<!--rtg41-->" in raw and "<!--rtg42-->" not in raw):
                mm = re.search(r"<!--rtg41-->(\d+)", raw)
                if mm:
                    add("damageDone", int(mm.group(1)))
            continue
        line = plain(raw).strip()
        for rx, key in PATS:
            mm = rx.search(line)
            if not mm:
                continue
            if key == "heal_sp":
                add("heal", int(mm.group(1)))
                add("sp_from_heal", int(mm.group(2)))
            elif key == "both":
                add("heal", int(mm.group(1)))
                add("damageDone", int(mm.group(1)))
            elif key == "spSchoolNamed":
                school, amt = mm.group(1), int(mm.group(2))
                add("spSchool", amt)
                add("sp" + school, amt)
            else:
                add(key, int(mm.group(1)))
            break
        else:
            o["flags"].append("unscored:" + line[:70])

    # Forever green stats: Spell Power (both), Damage Done (spell dmg only),
    # Healing Done (heal only). Rating comments are preferred; text is fallback.
    text = plain(t)
    for amt in re.findall(r"\+(\d+) Spell Power", text):
        if "sp" not in o["stats"]:
            add("sp", int(amt))
    for amt in re.findall(r"\+(\d+) Damage Done", text):
        if "damageDone" not in o["stats"] and "sp" not in o["stats"]:
            add("damageDone", int(amt))
    for amt in re.findall(r"\+(\d+) Healing Done", text):
        if "heal" not in o["stats"]:
            add("heal", int(amt))
    for amt in re.findall(r"\+(\d+) Healing(?! Done)", text):
        if "heal" not in o["stats"]:
            add("heal", int(amt))
    for amt in re.findall(r"Restores \+(\d+) mana per 5", text, re.I):
        if "mp5" not in o["stats"]:
            add("mp5", int(amt))
    for school, amt in re.findall(
        r"Increases damage done by (Shadow|Fire|Frost|Nature|Arcane|Holy) spells and effects by up to (\d+)",
        text,
    ):
        if f"sp{school}" not in o["stats"]:
            add("spSchool", int(amt))
            add("sp" + school, int(amt))
    for amt in re.findall(r"\+(\d+) Attack Power against Humanoids", text):
        if "apVs" not in o["stats"]:
            add("apVs", int(amt))
    for amt in re.findall(r"\+(\d+) (?:Arcane|Fire|Frost|Nature|Shadow) Resistance", text):
        if "resist" not in o["stats"]:
            add("resist", int(amt))
    for prof, rank in re.findall(
        r"Requires (Alchemy|Blacksmithing|Engineering|Enchanting|Tailoring|Leatherworking) \((\d+)\)",
        text,
    ):
        o.setdefault("reqSkills", []).append([prof, int(rank)])

    eff = []
    for m in re.finditer(r'<span class="q2">((?:Equip|Use|Chance on hit):.*?)</span>', t, re.S):
        line = plain(m.group(1)).strip()
        if line:
            eff.append(line[:400])
    if eff:
        o["effects"] = eff
    proclike = re.compile(r"Chance on hit|^Use:|chance to|Equip: Chance", re.I)
    o["procs"] = [e for e in eff if proclike.search(e)]
    o["_effectDriven"] = bool(o["procs"]) and sum(
        v for k, v in o["stats"].items() if k not in ("armor", "block")
    ) <= 40

    if "Conjured Item" in t or re.search(r"Duration: \d+ (?:min|sec|hour|day)", t):
        o["temporary"] = True
    if "&lt;Random enchantment&gt;" in t or "Random enchantment" in text:
        o["randomEnchant"] = True
    reps = []
    seen_rep = set()
    for fac, standing in re.findall(
        r"Requires\s+([A-Za-z][A-Za-z' ]{1,40}?)\s+-\s+(Friendly|Honored|Revered|Exalted)",
        text,
    ):
        fac = re.sub(r"\s+", " ", fac).strip()
        standing = standing.title()
        key = (fac, standing)
        if not fac or key in seen_rep:
            continue
        seen_rep.add(key)
        reps.append([fac, standing])
    if reps:
        o["reqRep"] = reps
    idx = text.find("Classes:")
    if idx >= 0:
        after = text[idx + 8:].lstrip()
        class_names = (
            "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
            "Shaman", "Mage", "Warlock", "Druid",
        )
        names = []
        while after:
            hit = None
            for title in sorted(class_names, key=len, reverse=True):
                if after.startswith(title):
                    rest = after[len(title):]
                    if rest == "" or rest[0] in ", " or rest[0].isupper():
                        names.append(title)
                        after = rest.lstrip(" ,")
                        hit = True
                        break
            if not hit:
                break
        if names:
            o["tipClasses"] = names
    if "Binds when picked up" in t:
        o["bind"] = "BoP"
    elif "Binds when equipped" in t:
        o["bind"] = "BoE"
    m = re.search(r'whtt-droppedby">Dropped by: ([^<]+)', t)
    if not m:
        m = re.search(r"Dropped by: ([^\n<]+)", t)
    if m:
        o["droppedBy"] = html.unescape(m.group(1)).strip()
    return o


# Rune Brokers sell these relics. Wowhead also lists a creature drop first.
# Horde npc 233428, Alliance npc 233335. They do not stock the same relics.
HORDE_BROKER = (
    "Bought from Rune Broker in Orgrimmar, Thunder Bluff, Undercity, "
    "Durotar, Mulgore, and Tirisfal Glades."
)
ALLIANCE_BROKER = (
    "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, "
    "Elwynn Forest, Dun Morogh, and Teldrassil."
)
BOTH_BROKERS = (
    "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, Elwynn Forest, "
    "Dun Morogh, and Teldrassil, and in Orgrimmar, Thunder Bluff, Undercity, "
    "Durotar, Mulgore, and Tirisfal Glades."
)
RUNE_BROKER_HORDE = {
    206381,  # Dyadic Icon
    206382,  # Tempest Icon
    206386,  # Galvanic Icon
    206387,  # Kajaric Icon
    206388,  # Sulfurous Icon
    225838,  # Voltaic Icon
}
RUNE_BROKER_ALLIANCE = {
    205420,  # Libram of Judgement
    208849,  # Libram of Blessings
    208851,  # Libram of Justice
    211472,  # Libram of Banishment
}
RUNE_BROKER_BOTH = {
    206954,  # Idol of Ursine Rage
    208414,  # Lunar Idol
    208689,  # Ferocious Idol
    210534,  # Idol of the Wild
    220915,  # Idol of the Raging Shambler
    227444,  # Idol of the Huntress
}
RUNE_BROKER_RELICS = RUNE_BROKER_HORDE | RUNE_BROKER_ALLIANCE | RUNE_BROKER_BOTH


def _rune_broker_source(parsed, row):
    iid = row.get("id")
    if iid in RUNE_BROKER_ALLIANCE:
        instructions = ALLIANCE_BROKER
    elif iid in RUNE_BROKER_BOTH:
        instructions = BOTH_BROKERS
    else:
        instructions = HORDE_BROKER
    return {
        "sourceType": "vendor",
        "instructions": instructions,
        "zone": None,
        "npc": "Rune Broker",
        "questName": None,
        "profession": None,
        "dropChance": None,
        "alts": [],
        "gateLevel": parsed.get("rlvl") or row.get("rlvl") or 0,
        "questClasses": 0,
        "questRaces": 0,
        "seasonal": False,
        "obtainable": True,
        "excludedBecause": None,
    }


def source_from_row(row, parsed, name):
    more_list = [e for e in (row.get("sourcemore") or []) if e]
    broker = next((e for e in more_list if e.get("n") == "Rune Broker"), None)
    relic = row.get("slot") == "Relic" or row.get("slotId") == 28
    if row.get("id") in RUNE_BROKER_RELICS or (relic and broker):
        return _rune_broker_source(parsed, row)
    more = more_list[0] if more_list else {}
    kinds = set(row.get("source") or [])
    # Forever listview source 4 is a quest. sourcemore.t is no longer that enum
    # (quests come through as t=5, which used to mean vendor).
    if 4 in kinds and 5 not in kinds:
        qn = more.get("n")
        return {
            "sourceType": "quest_reward",
            "instructions": f"Reward from the quest “{qn}”." if qn else "Quest reward.",
            "zone": None,
            "npc": None,
            "questName": qn,
            "profession": None,
            "dropChance": None,
            "alts": [],
            "gateLevel": parsed.get("rlvl") or row.get("rlvl") or 0,
            "questClasses": 0,
            "questRaces": 0,
            "seasonal": False,
            "obtainable": True,
            "excludedBecause": None,
        }
    # source 5 is a vendor. sourcemore.t=1 is the creature NPC, not a drop.
    # A vendor-only row must not be labeled "Drops from".
    if 5 in kinds and 2 not in kinds:
        npc = more.get("n")
        return {
            "sourceType": "vendor",
            "instructions": f"Bought from {npc}." if npc else "Bought from a vendor.",
            "zone": None,
            "npc": npc,
            "questName": None,
            "profession": None,
            "dropChance": None,
            "alts": [],
            "gateLevel": parsed.get("rlvl") or row.get("rlvl") or 0,
            "questClasses": 0,
            "questRaces": 0,
            "seasonal": False,
            "obtainable": True,
            "excludedBecause": None,
        }
    t = more.get("t")
    source_type = SRC_T.get(t, "world_drop")
    profession = SKILL.get(more.get("s")) if source_type == "profession" else None
    npc = more.get("n") if source_type in ("world_drop", "vendor") else None
    if source_type == "profession" and more.get("n") == name:
        npc = None
    if source_type == "profession":
        skill = profession or "a profession"
        instructions = camp_instructions(name, profession) or f"Crafted with {skill}."
    elif source_type == "vendor" and npc:
        instructions = f"Bought from {npc}."
    elif source_type == "quest_reward":
        qn = more.get("n")
        instructions = f'Reward from the quest “{qn}”.' if qn else "Quest reward."
    elif npc:
        instructions = f"Drops from {npc}."
    else:
        dropped = (parsed.get("droppedBy") or "").strip()
        if dropped:
            # The listview named no source, but the tooltip names the dropper.
            instructions = f"Drops from {dropped}."
            npc = dropped
            source_type = "world_drop"
        else:
            # No creature, quest, vendor, or profession. Not a world drop.
            instructions = "Indexed from Wowhead Forever. Source not listed yet."
            source_type = "unsourced"
    return {
        "sourceType": source_type,
        "instructions": instructions,
        "zone": None,
        "npc": npc if source_type != "profession" else None,
        "questName": more.get("n") if source_type == "quest_reward" else None,
        "profession": profession,
        "dropChance": None,
        "alts": [],
        "gateLevel": parsed.get("rlvl") or row.get("rlvl") or 0,
        "questClasses": 0,
        "questRaces": 0,
        "seasonal": False,
        "obtainable": True,
        "excludedBecause": None,
    }


def apply_pinned_boss_sources(sources):
    """Dungeon bosses the Wowhead listview still leaves unsourced.

    The loot tables name the boss. A later ingest must not put these back to
    "Source not listed yet."
    """
    path = os.path.join(G, "forever_boss_sources.json")
    if not os.path.exists(path):
        return 0
    pins = json.load(open(path, encoding="utf-8"))
    n = 0
    for row in pins:
        key = str(row["id"])
        src = sources.get(key)
        if not src:
            continue
        npc = row["npc"]
        src["sourceType"] = "boss_drop"
        src["npc"] = npc
        src["zone"] = row["zone"]
        src["profession"] = None
        if row.get("zones"):
            src["zones"] = list(row["zones"])
        src["instructions"] = row.get("instructions") or f"Drops from {npc}."
        src["obtainable"] = True
        src["excludedBecause"] = None
        n += 1
    return n


def apply_named_drop_kinds(sources):
    """A named dungeon boss is a boss drop. A rare is a Rare NPC.

    Wowhead's listview calls both a drop, and the old creature ranks stored
    dungeon bosses as "(rare elite)". Bosses listed in dungeon_entrances.json
    stay boss drops. "(rare spawn)" and any other "(rare elite)" is the rare.
    """
    path = os.path.join(G, "dungeon_entrances.json")
    bosses = {}
    if os.path.exists(path):
        bosses = json.load(open(path, encoding="utf-8")).get("bossNpcs") or {}
    # Rares that only exist inside an instance. The pin is that entrance.
    rare_dungeon = {
        "Eviscerator": "Blackrock Depths",
        "Balzaphon": "Stratholme",
        "Revanchion": "Dire Maul",
        "Scorn": "Scarlet Monastery",
        "Sever": "Shadowfang Keep",
    }
    bosses_n = rares_n = 0
    for src in sources.values():
        if not isinstance(src, dict):
            continue
        npc = src.get("npc") or ""
        if src.get("sourceType") == "rare_npc" and npc in rare_dungeon and not src.get("zone"):
            src["zone"] = rare_dungeon[npc]
            continue
        if src.get("sourceType") != "world_drop":
            continue
        text = src.get("instructions") or ""
        if npc and npc in bosses:
            src["sourceType"] = "boss_drop"
            src["zone"] = bosses[npc]
            src["instructions"] = f"Drops from {npc}."
            bosses_n += 1
            continue
        if "(rare spawn)" in text or "(rare elite)" in text:
            src["sourceType"] = "rare_npc"
            src["instructions"] = f"Drops from {npc}." if npc else "Drops from a rare."
            if npc in rare_dungeon:
                src["zone"] = rare_dungeon[npc]
            rares_n += 1
    return bosses_n, rares_n


def apply_pinned_faction_zones(sources):
    """Forever quests whose turn-in city is one faction.

    The listview leaves zone empty, so a Stormwind turn-in was scoring for
    Horde. A later ingest must not clear these.
    """
    path = os.path.join(G, "forever_faction_zones.json")
    if not os.path.exists(path):
        return 0
    pins = json.load(open(path, encoding="utf-8"))
    n = 0
    for row in pins:
        src = sources.get(str(row["id"]))
        if not src or not row.get("zone"):
            continue
        src["zone"] = row["zone"]
        n += 1
    return n


def build_item(row, tip):
    html_tip = (tip or {}).get("tooltip") or ""
    parsed = parse_tooltip(html_tip) if html_tip else {"stats": {}, "flags": []}
    cls = parsed.get("tipClass") or row.get("classs")
    sub = parsed.get("tipSub") if parsed.get("tipSub") is not None else row.get("subclass")
    slot = row.get("slot") or INV.get(row.get("slotId"))
    if not slot:
        return None, None
    kind = ARMOR_SUB.get(sub, "?") if cls == 4 else WEAP_SUB.get(sub, "?")
    stats = parsed.get("stats") or {}
    if row.get("armor") and "armor" not in stats:
        stats["armor"] = row["armor"]
    item = {
        "id": row["id"],
        "name": (tip or {}).get("name") or row["name"],
        "slot": slot,
        "quality": (tip or {}).get("quality") if (tip or {}).get("quality") is not None else row.get("quality", 0),
        "ilvl": parsed.get("ilvl") or row.get("ilvl") or 0,
        "rlvl": parsed.get("rlvl") or row.get("rlvl") or 0,
        "cls": cls,
        "sub": sub,
        "kind": kind,
        "inv": row.get("slotId") or 0,
        "allowClass": -1,
        "allowRace": -1,
        "randProp": 0,
        "randSuffix": 0,
        "reqSkill": 0,
        "reqSkillRank": 0,
        "block": parsed.get("block") or 0,
        "delay": int(round((parsed.get("speed") or 0) * 1000)) if parsed.get("speed") else 0,
        "itemset": 0,
        "bonding": 1 if parsed.get("bind") == "BoP" else 2 if parsed.get("bind") == "BoE" else 0,
        "stats": stats,
        "dps": parsed.get("dps") or row.get("dps") or 0.0,
        "speed": parsed.get("speed") or row.get("speed") or 0.0,
        "dmgMin": parsed.get("dmgMin") or 0.0,
        "dmgMax": parsed.get("dmgMax") or 0.0,
        "sockets": parsed.get("sockets") or [],
        "socketBonus": parsed.get("socketBonus"),
        "phase": 1,
        "bind": parsed.get("bind"),
        "droppedBy": parsed.get("droppedBy"),
        "randomEnchant": parsed.get("randomEnchant", False),
        "hasTip": bool(html_tip),
        "flags": parsed.get("flags") or [],
        "reqSkills": parsed.get("reqSkills") or [],
        "reqRep": parsed.get("reqRep") or [],
        "temporary": parsed.get("temporary", False),
        "effects": parsed.get("effects") or [],
        "procs": parsed.get("procs") or [],
        "effectDriven": parsed.get("_effectDriven", False),
        "tipClasses": parsed.get("tipClasses") or [],
    }
    # A stated Requires Level is the equip level. Item level is not a
    # requirement. The floor is only for a missing line (0 or the Wowhead
    # stub of 1), so an unstated ilvl-48 axe cannot rank at level 1.
    stated = int(parsed.get("rlvl") or 0)
    floor = int(ILVL_FLOOR.get(str(item["ilvl"]), 0) or 0)
    if stated > 1:
        item["rlvl"] = stated
    elif item["id"] >= 200000 and item["rlvl"] < floor:
        item["rlvl"] = floor
    # Grave Shroud has no Requires Level. The quests require 16, which is
    # earlier than the item-level floor of 18.
    if item["id"] == 279865:
        item["rlvl"] = 16
    # Leafre's Ring requires level 60. The nether tooltip omits that line.
    if item["id"] == 276765:
        item["rlvl"] = 60
    parsed["rlvl"] = item["rlvl"]
    return item, parsed


def main():
    if not os.path.exists(INDEX):
        sys.exit(f"missing {INDEX} — run node scripts/scrape-forever-wowhead-items.mjs --index")
    if not os.path.exists(TIPS):
        sys.exit(f"missing {TIPS} — run node scripts/scrape-forever-wowhead-items.mjs --tooltips")

    index = json.load(open(INDEX, encoding="utf-8"))
    tips = json.load(open(TIPS, encoding="utf-8"))
    items = json.load(open(G + "items.json", encoding="utf-8"))
    sources = json.load(open(G + "sources.json", encoding="utf-8"))
    pool = json.load(open(G + "classic_item_ids.json", encoding="utf-8"))
    pool_set = set(pool)

    added_items = 0
    added_sources = 0
    filled_sources = 0
    added_pool = 0
    skipped = 0
    no_tip = 0
    coord_ids = []

    for row in index["items"]:
        iid = row["id"]
        key = str(iid)
        tip = tips.get(key) or tips.get(iid)
        if not tip or tip.get("error"):
            no_tip += 1
            continue
        item, parsed = build_item(row, tip)
        if not item:
            skipped += 1
            continue
        if iid in SKIP_IDS or SKIP_NAME.search(item["name"] or ""):
            skipped += 1
            continue
        if key not in items:
            items[key] = item
            added_items += 1
        # An existing row keeps its facts. Refreshing every cached tooltip
        # put Erudite's Amulet back to the stale blue +4/+6 and dropped
        # school damage the parser does not store. New ids are the ingest.
        new_src = source_from_row(row, parsed, item["name"])
        old_src = sources.get(key)
        old_text = (old_src or {}).get("instructions") or ""
        new_text = new_src.get("instructions") or ""
        placeholder = "Source not listed yet" in old_text or old_src is None
        specific = (
            "Source not listed yet" not in new_text
            and (
                new_src.get("npc")
                or new_src.get("questName")
                or new_src.get("profession")
                or new_src.get("sourceType") not in (None, "", "world_drop", "unsourced")
            )
        )
        if old_src is None:
            sources[key] = new_src
            added_sources += 1
            coord_ids.append(iid)
        elif placeholder and specific:
            # Wowhead listed a source that used to be empty. Keep a real source
            # that is already on the row (boss pin, camp vendor, hand edit).
            sources[key] = new_src
            filled_sources += 1
            coord_ids.append(iid)
        if iid not in pool_set:
            pool.append(iid)
            pool_set.add(iid)
            added_pool += 1

    pool.sort()
    # Keep DNT/hidden names out of the scoring pool even if they were ingested earlier.
    cleaned = []
    for iid in pool:
        name = (items.get(str(iid)) or {}).get("name") or ""
        if int(iid) >= 200000 and SKIP_NAME.search(name):
            if str(iid) in sources:
                sources[str(iid)]["obtainable"] = False
            continue
        cleaned.append(iid)
    pool = cleaned
    apply_pinned_boss_sources(sources)
    apply_pinned_faction_zones(sources)
    apply_named_drop_kinds(sources)
    def dump_json(path, obj):
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(obj, handle, ensure_ascii=True, separators=(",", ":"))
        try:
            os.chmod(path, 0o666)
        except OSError:
            pass
        os.replace(tmp, path)

    dump_json(G + "items.json", items)
    dump_json(G + "sources.json", sources)
    dump_json(G + "classic_item_ids.json", pool)
    need = os.path.join(os.path.dirname(INDEX), "coord_needed.json")
    json.dump(sorted(set(coord_ids)), open(need, "w", encoding="utf-8"))
    print(
        f"merged Forever Wowhead: +{added_items} items, +{added_sources} sources, "
        f"{filled_sources} empty sources filled, +{added_pool} pool ids; "
        f"skipped {skipped}, no tooltip {no_tip}"
    )
    if added_items:
        print("New ids need a New in Forever check: python pipeline/scripts/build_forever_new.py")
    if UNKNOWN_RTG:
        print("unmapped tooltip rtg ids (count):", dict(sorted(UNKNOWN_RTG.items())))


if __name__ == "__main__":
    main()
