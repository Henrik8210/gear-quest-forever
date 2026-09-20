"""Overwrite stale Classic/TBC stats on hunt items using Wowhead Forever tips.

Ingest never replaced existing ids, so re-itemized Classic pieces (Serpent's
Shoulders +9 Agi vs live +5) kept winning ranks. Reads
pipeline/data/forever_wowhead/hunt_tooltips.json (plain-text nether tips).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gq_paths import DATA

TIPS = Path(DATA) / "forever_wowhead" / "hunt_tooltips.json"
ITEMS = Path(DATA) / "items.json"
RAND = Path(DATA) / "items_random.json"

# Longer names first so "Healing Done" wins over "Healing".
PLUS = [
    (r"\+(\d+)\s+Ranged Attack Power", "rap"),
    (r"\+(\d+)\s+Attack Power", "ap"),
    (r"\+(\d+)\s+Critical Strike", "crit"),
    (r"\+(\d+)\s+Spell Power", "sp"),
    (r"\+(\d+)\s+Healing Done", "heal"),
    (r"\+(\d+)\s+Damage Done", "damageDone"),
    (r"\+(\d+)\s+Healing(?! Done)", "heal"),
    (r"\+(\d+)\s+Strength", "str"),
    (r"\+(\d+)\s+Agility", "agi"),
    (r"\+(\d+)\s+Stamina", "sta"),
    (r"\+(\d+)\s+Intellect", "int"),
    (r"\+(\d+)\s+Spirit", "spi"),
    # Mashed nether text: +20 Hit+28 Crit, +15 HitDurability, +6 DodgeClasses.
    (r"\+(\d+)\s+Hit(?=\+|Durability|Classes|\s|$)", "hit"),
    (r"\+(\d+)\s+Haste(?=\+|Durability|Classes|\s|$)", "haste"),
    (r"\+(\d+)\s+Defense(?=\+|Durability|Classes|\s|$)", "defense"),
    (r"\+(\d+)\s+Dodge(?=\+|Durability|Classes|\s|$)", "dodge"),
    (r"\+(\d+)\s+Parry(?=\+|Durability|Classes|\s|$)", "parry"),
]
PLUS = [(re.compile(p, re.I), k) for p, k in PLUS]

EQUIP = [
    (re.compile(r"Increases healing done by up to (\d+) and damage done by up to (\d+)", re.I), "heal_sp"),
    (re.compile(r"Increases damage and healing done by magical spells and effects by up to (\d+)", re.I), "sp"),
    (re.compile(r"Increases (?:your )?(?:melee and ranged )?attack power by (\d+)(?! when)", re.I), "ap"),
    (re.compile(r"Increases ranged attack power by (\d+)", re.I), "rap"),
    (re.compile(r"Restores \+?(\d+) mana per 5", re.I), "mp5"),
    (re.compile(r"Restores \+?(\d+) health per 5", re.I), "hp5"),
    (re.compile(r"Increases attack power by (\d+) in Cat, Bear", re.I), "feralAp"),
]
# Mashed "1051 Armor17 Block" / "9 BlockRestores" — no \b (digit and letter are \w).
ARMOR = re.compile(r"(?<![.\d])(\d+)\s*Armor")
BLOCK = re.compile(r"(?<![.\d])(\d+)\s*Block")
DPS = re.compile(r"\(([\d.]+)\s+damage per second\)", re.I)
SPEED = re.compile(r"Speed\s+([\d.]+)")
DMG = re.compile(r"(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s+Damage")

SCORE = (
    "str", "agi", "sta", "int", "spi", "ap", "rap", "sp", "heal", "sp_from_heal",
    "damageDone", "hit", "crit", "haste", "mp5", "hp5", "feralAp", "defense",
    "dodge", "parry", "blockValue", "armor",
)
BONUS_ARMOR = re.compile(r"\+(\d+)\s+Bonus Armor", re.I)
SET_CUT = re.compile(
    r"(?:Classes:\s*[A-Za-z, ]+)?[A-Z][A-Za-z' :-]{1,50}\(\d+/\d+\)"
)
DEAD = ("expertise", "armorPen", "resilience", "spellHit", "spellCrit", "spellHaste",
        "hitRanged", "critRanged")


def body_only(tip: str) -> str:
    """Drop the set listing and (N) Set bonuses so those stats are not on the piece."""
    m = SET_CUT.search(tip)
    if m:
        return tip[: m.start()]
    m = re.search(r"\(\d+\) Set\s*:", tip)
    if m:
        return tip[: m.start()]
    return tip


def parse_tip(tip: str) -> dict:
    st = {}
    if not tip:
        return st
    tip = body_only(tip)

    def add(k, v):
        if v:
            st[k] = st.get(k, 0) + int(v)

    for rx, key in PLUS:
        for m in rx.finditer(tip):
            add(key, int(m.group(1)))
    for rx, key in EQUIP:
        m = rx.search(tip)
        if not m:
            continue
        if key == "heal_sp":
            add("heal", int(m.group(1)))
            add("sp_from_heal", int(m.group(2)))
        else:
            add(key, int(m.group(1)))
    m = ARMOR.search(tip)
    if m:
        add("armor", int(m.group(1)))
    m = BONUS_ARMOR.search(tip)
    if m:
        add("armor", int(m.group(1)))
    m = BLOCK.search(tip)
    if m:
        st["block"] = int(m.group(1))
    m = DPS.search(tip)
    if m:
        st["_dps"] = float(m.group(1))
    m = SPEED.search(tip)
    if m:
        st["_speed"] = float(m.group(1))
    m = DMG.search(tip)
    if m:
        st["_dmgMin"] = float(m.group(1))
        st["_dmgMax"] = float(m.group(2))
    return st


def nz(st, keys=SCORE):
    return {k: int(st.get(k) or 0) for k in keys if (st.get(k) or 0)}


def main():
    apply = "--apply" in sys.argv
    tips = json.loads(TIPS.read_text(encoding="utf-8"))
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    rand = json.loads(RAND.read_text(encoding="utf-8"))

    diffs = []
    patched = 0
    for key, row in tips.items():
        if not isinstance(row, dict) or row.get("status") != "ok":
            continue
        iid = int(key)
        it = items.get(str(iid))
        if not it:
            continue
        parsed = parse_tip(row.get("tip") or "")
        old = it.get("stats") or {}
        random = bool(it.get("randomEnchant") or rand.get(str(iid)))

        new = dict(old)
        for k in DEAD:
            new.pop(k, None)
        greens = [k for k in SCORE if k != "armor" and parsed.get(k)]
        if parsed.get("armor"):
            new["armor"] = parsed["armor"]
        if not random:
            for k in greens:
                new[k] = parsed[k]
            # Forever printed some +stats: drop stale primaries the tip no longer has.
            if greens:
                for k in SCORE:
                    if k == "armor":
                        continue
                    if not parsed.get(k):
                        new.pop(k, None)

        dead_stripped = any(old.get(k) for k in DEAD)
        changed = nz(old) != nz(new) or dead_stripped
        weapon = False
        if parsed.get("_dps") and abs((it.get("dps") or 0) - parsed["_dps"]) >= 0.15:
            weapon = True
        if not changed and not weapon:
            continue
        diffs.append((iid, it.get("name"), nz(old), nz(new), weapon, parsed.get("_dps"), it.get("dps")))
        if apply:
            it["stats"] = new
            if parsed.get("_dps"):
                it["dps"] = parsed["_dps"]
            if parsed.get("_speed"):
                it["speed"] = parsed["_speed"]
                it["delay"] = int(round(parsed["_speed"] * 1000))
            if parsed.get("_dmgMin"):
                it["dmgMin"] = parsed["_dmgMin"]
                it["dmgMax"] = parsed["_dmgMax"]
            patched += 1

    diffs.sort(key=lambda r: r[0])
    print(f"mismatches {len(diffs)} (classic ids with Forever tip != items.json)")
    for iid, name, old, new, weapon, fdps, odps in diffs[:80]:
        extra = f" dps {odps}->{fdps}" if weapon else ""
        print(f"  {iid} {name}: {old} -> {new}{extra}")
    if len(diffs) > 80:
        print(f"  ... {len(diffs)-80} more")
    if apply:
        ITEMS.write_text(json.dumps(items, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")
        print(f"wrote {ITEMS} patched {patched}")
    else:
        print("dry run. pass --apply to write items.json")


if __name__ == "__main__":
    main()
