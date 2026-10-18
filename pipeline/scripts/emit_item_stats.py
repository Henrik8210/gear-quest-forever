"""Compact stat rows for the in-game custom spec scorer.

One row per item the class hunts already list. Suffix rolls are the jackpot
(top of the range), the same numbers score.py ranks on.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT / "GearQuest" / "_generated"
ITEMS = ROOT / "pipeline" / "data" / "items.json"
ROLLS = ROOT / "pipeline" / "data" / "items_random.json"
OUT = GEN / "Data.ItemStats.generated.lua"

FACT_RE = re.compile(r"^\s*\[(\d+)\]=\{")
ROW_RE = re.compile(r"^\s*\{(\d+),")
SKIP = {
    "Data.ForeverAudit.generated.lua",
    "Data.ForeverNew.generated.lua",
    "Data.ScoredStats.generated.lua",
    "Data.HuntFacts.generated.lua",
    "Data.QuestFaction.generated.lua",
    "Data.Coordinates.generated.lua",
    "Data.ItemStats.generated.lua",
}
UNIFIED = {
    "spellHit": "hit",
    "hitRanged": "hit",
    "spellCrit": "crit",
    "critRanged": "crit",
    "spellHaste": "haste",
}
DEAD = ("expertise", "armorPen", "resilience")
ARMOR_KIND = {"Cloth", "Leather", "Mail", "Plate"}
RELIC_KIND = {"Totem", "Idol", "Libram"}
LABEL = {
    "sta": "Stamina",
    "int": "Intellect",
    "str": "Strength",
    "agi": "Agility",
    "spi": "Spirit",
    "ap": "Attack Power",
    "rap": "Ranged Attack Power",
    "feralAp": "Feral Attack Power",
    "heal": "Healing",
    "sp": "Spell Power",
    "spHoly": "Holy Spell Power",
    "spFire": "Fire Spell Power",
    "spFrost": "Frost Spell Power",
    "spNature": "Nature Spell Power",
    "spArcane": "Arcane Spell Power",
    "spShadow": "Shadow Spell Power",
    "crit": "Critical Strike",
    "hit": "Hit",
    "haste": "Haste",
    "defense": "Defense",
    "dodge": "Dodge",
    "parry": "Parry",
    "blockRating": "Block",
    "blockValue": "Block Value",
    "mp5": "Mana per 5",
    "hp5": "Health per 5",
    "health": "Health",
    "mana": "Mana",
    "resist": "Resistance",
    "sp_from_heal": "Healing as spell power",
}


def forever_stats(stats):
    out = dict(stats or {})
    for src, dst in UNIFIED.items():
        if src in out:
            out[dst] = out.get(dst, 0) + (out[src] or 0)
            out[src] = 0
    for key in DEAD:
        if key in out:
            out[key] = 0
    # Keep Damage Done off Spell Power. The custom scorer adds it to spell
    # power only when Healing is 0. A heal-only line still grants one third.
    damage = out.get("damageDone") or 0
    heal = out.get("heal") or 0
    explicit = out.get("sp") or 0
    if heal and not explicit and not damage:
        out["sp_from_heal"] = max(out.get("sp_from_heal") or 0, heal / 3.0)
    return out


def num(value):
    if isinstance(value, float) and abs(value - round(value)) < 1e-9:
        return str(int(round(value)))
    if isinstance(value, float):
        return f"{value:.4f}".rstrip("0").rstrip(".")
    return str(int(value) if isinstance(value, int) else value)


def lua_string(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


def fmt_range(lo, hi):
    parts = []
    for key, high in sorted(hi.items(), key=lambda kv: -(kv[1] or 0)):
        if not high:
            continue
        low = lo.get(key, high) or high
        label = LABEL.get(key, key)
        if abs(low - high) < 1e-9:
            parts.append("+%s %s" % (num(high), label))
        else:
            parts.append("+%s-%s %s" % (num(low), num(high), label))
    return ", ".join(parts)


def stat_body(stats, extra):
    parts = []
    for key in sorted(stats):
        value = stats[key]
        if not isinstance(value, (int, float)) or not value:
            continue
        parts.append("%s=%s" % (key, num(value)))
    for key, value in extra:
        parts.append("%s=%s" % (key, value))
    return ",".join(parts)


def main():
    ids = set()
    for path in GEN.glob("Data.*.generated.lua"):
        if path.name in SKIP:
            continue
        for line in path.read_text(encoding="latin-1").splitlines():
            found = FACT_RE.match(line) or ROW_RE.match(line)
            if found:
                ids.add(int(found.group(1)))

    raw_items = json.loads(ITEMS.read_text(encoding="utf-8"))
    if isinstance(raw_items, list):
        by_id = {it["id"]: it for it in raw_items}
    else:
        by_id = {int(it.get("id", key)): it for key, it in raw_items.items()}

    raw_rolls = json.loads(ROLLS.read_text(encoding="utf-8"))

    stat_lines = []
    roll_lines = []
    missing = 0
    for item_id in sorted(ids):
        it = by_id.get(item_id)
        if not it:
            missing += 1
            continue
        folded = forever_stats(it.get("stats") or {})
        extra = []
        if it.get("cls") == 2:
            if it.get("dps"):
                extra.append(("dps", num(it["dps"])))
            if it.get("speed"):
                extra.append(("spd", num(it["speed"])))
        kind = it.get("kind") or ""
        if kind in ARMOR_KIND or kind in RELIC_KIND:
            extra.append(("kind", lua_string(kind)))
        if it.get("ilvl"):
            extra.append(("ilvl", num(it["ilvl"])))
        stat_lines.append("[%s]={%s}" % (item_id, stat_body(folded, extra)))

        variants = raw_rolls.get(str(item_id)) or []
        rolls = []
        for variant in variants:
            hi = variant.get("stats") or {}
            hi = {k: v for k, v in hi.items() if isinstance(v, (int, float)) and v}
            if not hi:
                continue
            lo = variant.get("statsMin") or variant.get("stats") or {}
            chance = variant.get("chance")
            if chance is None:
                chance = variant.get("chanceAny")
            piece = ["n=" + lua_string(variant.get("suffix") or "")]
            if chance:
                piece.append("c=" + num(chance))
            if variant.get("suffixId"):
                piece.append("id=" + num(variant["suffixId"]))
            text = fmt_range(lo, hi)
            if text:
                piece.append("r=" + lua_string(text))
            piece.append(stat_body(hi, []))
            rolls.append("{" + ",".join(p for p in piece if p) + "}")
        if rolls:
            roll_lines.append("[%s]={%s}" % (item_id, ",".join(rolls)))

    body = [
        "-- AUTO-GENERATED by pipeline/scripts/emit_item_stats.py — do not edit.",
        "-- Stat rows for items the class hunts already list. Custom specs score these.",
        "local _, GQ = ...",
        "GQ.Data = GQ.Data or {}",
        "GQ.Data.itemStats = {",
        *("    %s," % line for line in stat_lines),
        "}",
        "GQ.Data.itemRolls = {",
        *("    %s," % line for line in roll_lines),
        "}",
        "",
    ]
    OUT.write_text("\n".join(body), encoding="utf-8", newline="\n")
    print("items", len(stat_lines), "rolls", len(roll_lines), "missing", missing, "bytes", OUT.stat().st_size)


if __name__ == "__main__":
    main()
