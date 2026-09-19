"""Normalize hunt instructions: drop repeated zone/AH/creature-count filler."""
import json
import re

from gq_paths import G

WORLD = re.compile(
    r"^World drop\s+[—\-]\s+drops from \d+ creature types"
    r"(?: around level (\d+)-(\d+))?\. Also found on the auction house\.$",
    re.I,
)
QUEST = re.compile(
    r"^Reward from the quest '(.+?)'"
    r"(?: - pick it over the other choices)?\."
    r"(?: In ([^.]+)\.)?$",
    re.I,
)
DROPS = re.compile(r"^Drops from (.+?) in ([^.]+)\.$")
BOUGHT = re.compile(r"^Bought from (.+?) in ([^.]+)\.(.*)$")
MULTI_SPACE = re.compile(r" {2,}")


def clean_one(rec):
    text = rec.get("instructions") or ""
    text = (
        text.replace("\u201c", "'")
        .replace("\u201d", "'")
        .replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u2014", "-")
        .replace("\u2013", "-")
        .replace("\u00a0", " ")
    )
    text = MULTI_SPACE.sub(" ", text).strip()

    m = WORLD.match(text)
    if m:
        lo, hi = m.group(1), m.group(2)
        if lo and hi:
            rec["instructions"] = f"World drop around level {lo}-{hi}."
        else:
            rec["instructions"] = "World drop."
        return "world"

    m = QUEST.match(text)
    if m:
        name, zone = m.group(1), m.group(2)
        extra = ""
        if "pick it over the other" in text.lower():
            extra = " Pick it over the other reward choices."
        rec["instructions"] = f"Reward from the quest '{name}'.{extra}"
        if zone and not rec.get("zone"):
            rec["zone"] = zone
        return "quest"

    m = DROPS.match(text)
    if m:
        npc, zone = m.group(1), m.group(2)
        rec["instructions"] = f"Drops from {npc}."
        if not rec.get("npc"):
            rec["npc"] = npc
        if zone and not rec.get("zone"):
            rec["zone"] = zone
        return "drop"

    m = BOUGHT.match(text)
    if m:
        npc, zone, rest = m.group(1), m.group(2), (m.group(3) or "").strip()
        rec["instructions"] = f"Bought from {npc}." + ((" " + rest) if rest else "")
        if not rec.get("npc"):
            rec["npc"] = npc
        if zone and not rec.get("zone"):
            rec["zone"] = zone
        return "vendor"

    rec["instructions"] = text
    return None


def main():
    sources = json.load(open(G + "sources.json", encoding="utf-8"))
    counts = {}
    for rec in sources.values():
        kind = clean_one(rec)
        if kind:
            counts[kind] = counts.get(kind, 0) + 1
    json.dump(sources, open(G + "sources.json", "w", encoding="utf-8"), indent=2)
    print("cleaned", counts, "of", len(sources))


if __name__ == "__main__":
    main()
