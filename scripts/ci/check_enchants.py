#!/usr/bin/env python3
"""Every hunt row on an enchantable slot must have a recommended enchant at that level.

Mirrors GearQuest/Enchant.lua ROWS, Usable, and Fits. Shoulder, waist, finger,
trinket, relic, wand, thrown, and fishing pole hunts are skipped.

After new gear is indexed or rescored, CI must pass. Run locally:

  python scripts/ci/check_enchants.py

Usage: python scripts/ci/check_enchants.py
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_gear import CLASSES, Catalog, TEST_ITEMS  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
ENCHANT = REPO / "GearQuest" / "Enchant.lua"
ITEMS = REPO / "pipeline" / "data" / "items.json"

SKIP_SLOTS = {
    "Shoulder",
    "Waist",
    "Finger0",
    "Finger1",
    "Trinket0",
    "Trinket1",
    "Relic",
}
BANNED_KINDS = {"Fishing Pole", "Wand", "Thrown", "Libram", "Idol", "Totem"}


def skill_cap(level: int) -> int:
    if level < 10:
        return 75
    if level < 20:
        return 150
    if level < 35:
        return 225
    return 300


def skill_need(skill: int) -> int:
    return 300 if skill > 300 else skill


def parse_rows(text: str) -> list[dict]:
    rows: list[dict] = []
    for chunk in re.findall(r"\{ slots = [^\n]+\}", text):
        m_slots = re.search(r"slots = (\{[^}]+\}|\"[^\"]+\")", chunk)
        if not m_slots:
            continue
        slots_raw = m_slots.group(1).strip()
        slots: str | list[str]
        if slots_raw.startswith("{"):
            slots = re.findall(r'"(\w+)"', slots_raw)
        else:
            slots = slots_raw.strip('"')
        skill = int(re.search(r"skill = (\d+)", chunk).group(1)) if re.search(r"skill = (\d+)", chunk) else 1
        level = int(re.search(r"level = (\d+)", chunk).group(1)) if re.search(r"level = (\d+)", chunk) else None
        min_ilvl = int(re.search(r"minIlvl = (\d+)", chunk).group(1)) if re.search(r"minIlvl = (\d+)", chunk) else None
        also_two = "alsoTwo = true" in chunk
        name_m = re.search(r'name = "([^"]+)"', chunk)
        rows.append(
            {
                "slots": slots,
                "skill": skill,
                "level": level,
                "minIlvl": min_ilvl,
                "alsoTwo": also_two,
                "name": name_m.group(1) if name_m else "?",
            }
        )
    return rows


def fits(row: dict, slot_key: str) -> bool:
    slots = row["slots"]
    if slots == slot_key:
        return True
    if isinstance(slots, list) and slot_key in slots:
        return True
    if slot_key == "two" and slots == "weapon" and row.get("alsoTwo"):
        return True
    return False


def usable(row: dict, level: int, ilvl: int | None) -> bool:
    if row.get("level") and level < row["level"]:
        return False
    if row.get("minIlvl") and (not ilvl or ilvl < row["minIlvl"]):
        return False
    return skill_need(row["skill"]) <= skill_cap(level)


def slot_key(slot: str, kind: str | None, hand: str | None) -> str | None:
    if slot == "Head":
        return "head"
    if slot == "Wrist":
        return "wrist"
    if slot == "Chest":
        return "chest"
    if slot == "Hands":
        return "hands"
    if slot == "Feet":
        return "feet"
    if slot == "Legs":
        return "legs"
    if slot == "Back":
        return "cloak"
    if slot == "Neck":
        return "neck"
    if slot == "TwoHand" or hand == "two":
        return "two"
    if slot == "MainHand":
        return "weapon"
    if slot == "SecondaryHand" or slot == "OffHand":
        if kind in ("Shield", "Buckler"):
            return "shield"
        if hand in ("off", "one") or kind in ("Dagger", "Sword1H", "Mace1H", "Axe1H", "Fist"):
            return "weapon"
        return "offhand"
    if slot == "Ranged":
        if kind in ("Bow", "Gun", "Crossbow"):
            return "ranged"
        return None
    return None


def enchant_reachable(rows: list[dict], slot_key: str, level: int) -> bool:
    cap = skill_cap(level)
    for row in rows:
        if not fits(row, slot_key):
            continue
        if skill_need(row["skill"]) > cap:
            continue
        if row.get("level") and level < row["level"]:
            continue
        return True
    return False


def best_row(rows: list[dict], slot_key: str, level: int, ilvl: int | None) -> dict | None:
    best = None
    for row in rows:
        if fits(row, slot_key) and usable(row, level, ilvl):
            if best is None or row["skill"] > best["skill"]:
                best = row
    return best


def main() -> int:
    if not ENCHANT.is_file():
        print(f"FAIL missing {ENCHANT}")
        return 1
    rows = parse_rows(ENCHANT.read_text(encoding="utf-8-sig"))
    if not rows:
        print("FAIL could not parse Enchant.lua ROWS")
        return 1
    item_meta: dict[int, dict] = {}
    raw_items = json.loads(ITEMS.read_text(encoding="utf-8"))
    for key, it in raw_items.items():
        try:
            iid = int(key)
        except ValueError:
            continue
        item_meta[iid] = {
            "ilvl": int(it.get("ilvl") or 0) or None,
            "kind": it.get("kind"),
            "inv": it.get("inv"),
        }

    cat = Catalog()
    cat.load_tips()
    for cls in CLASSES:
        cat.load(cls)

    failures: list[str] = []
    seen: set[tuple[int, str]] = set()
    for cls in CLASSES:
        for item, slot, lo, hi, _rank, _spec, _faction, _score in cat.rows[cls]:
            if item in TEST_ITEMS:
                continue
            fact = cat.item[cls].get(item)
            if not fact or fact[1] in ("unobtainable", "unsourced"):
                continue
            if slot in SKIP_SLOTS:
                continue
            key = (item, slot)
            if key in seen:
                continue
            seen.add(key)
            meta = item_meta.get(item, {})
            kind = meta.get("kind")
            if kind in BANNED_KINDS:
                continue
            if slot in ("SecondaryHand", "OffHand") and kind not in ("Shield", "Buckler"):
                continue
            sk = slot_key(slot, kind, None)
            if not sk:
                continue
            req = fact[3] or lo or 1
            level = min(60, max(req, lo, hi))
            ilvl = meta.get("ilvl") or req
            if not enchant_reachable(rows, sk, level):
                continue
            if not best_row(rows, sk, level, ilvl):
                name = fact[0] or f"item {item}"
                failures.append(f"{cls} {item} {name} slot {slot} level {lo}-{hi}: no Enchant.lua row")

    if failures:
        print(f"FAIL {len(failures)} hunt items lack a recommended enchant")
        for line in failures[:40]:
            print(" ", line)
        if len(failures) > 40:
            print(f" ... and {len(failures) - 40} more")
        return 1

    print(f"OK {len(seen)} enchantable hunt rows have a formula in Enchant.lua")
    return 0


if __name__ == "__main__":
    sys.exit(main())