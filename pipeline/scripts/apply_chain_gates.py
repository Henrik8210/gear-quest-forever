"""Raise quest rewards whose chain finishes in a much higher dungeon.

The pickup of the first step is not the level you can finish. Final Passage
is the tenth step of Test of Lore. The book is in Scarlet Monastery Library,
a level 36 quest, so the hammer was showing as BiS at 30.

Leaders of the Fang stays 10 and The Defias Brotherhood stays 14. Those
chains are already pinned to the first step.
"""
import json
from pathlib import Path

from gq_paths import DATA

ITEMS = Path(DATA) / "items.json"
SOURCES = Path(DATA) / "sources.json"

# item id -> (level, instruction)
RAISES = {
    6804: (
        36,
        "Reward from the quest 'Final Passage', the last of ten steps. "
        "The chain starts with Test of Faith in Thousand Needles. "
        "Bring Beginnings of the Undead Threat out of Scarlet Monastery Library. "
        "That step is level 36. Pick the hammer over the other reward.",
    ),
    6806: (
        36,
        "Reward from the quest 'Final Passage', the last of ten steps. "
        "The chain starts with Test of Faith in Thousand Needles. "
        "Bring Beginnings of the Undead Threat out of Scarlet Monastery Library. "
        "That step is level 36. Pick the wand over the other reward.",
    ),
    7513: (
        40,
        "Reward from the quest 'Mage's Wand'. Pick it over the other reward choices. "
        "The chain starts with Tabetha in Dustwallow Marsh. "
        "Rituals of Power sends you into Scarlet Monastery Library. That step is level 40.",
    ),
    7514: (
        40,
        "Reward from the quest 'Mage's Wand'. Pick it over the other reward choices. "
        "The chain starts with Tabetha in Dustwallow Marsh. "
        "Rituals of Power sends you into Scarlet Monastery Library. That step is level 40.",
    ),
    11263: (
        40,
        "Reward from the quest 'Mage's Wand'. Pick it over the other reward choices. "
        "The chain starts with Tabetha in Dustwallow Marsh. "
        "Rituals of Power sends you into Scarlet Monastery Library. That step is level 40.",
    ),
    20218: (
        58,
        "Reward from the quest 'Confront Yeh'kinya'. Pick it over the other reward choices. "
        "The chain starts with Prospector Ironboot in Tanaris. "
        "The Final Tablets are in Blackrock Spire. That step is level 58.",
    ),
    20219: (
        58,
        "Reward from the quest 'Confront Yeh'kinya'. Pick it over the other reward choices. "
        "The chain starts with Prospector Ironboot in Tanaris. "
        "The Final Tablets are in Blackrock Spire. That step is level 58.",
    ),
    16309: (
        60,
        "Reward from the quest 'Drakefire Amulet'. The chain starts with Haleh in Winterspring. "
        "Retrieve the Blood of the Black Dragon Champion from General Drakkisath in Blackrock Spire. "
        "That step is level 60.",
    ),
}


def main():
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    for iid, (level, text) in RAISES.items():
        key = str(iid)
        item = items[key]
        source = sources[key]
        old = item.get("rlvl")
        item["rlvl"] = level
        source["gateLevel"] = level
        source["instructions"] = text
        print(f"{iid} {item.get('name')}: {old} -> {level}")
    tmp_items = ITEMS.with_suffix(".json.tmp")
    tmp_src = SOURCES.with_suffix(".json.tmp")
    tmp_items.write_text(json.dumps(items, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")
    tmp_src.write_text(json.dumps(sources, separators=(",", ":"), ensure_ascii=True), encoding="utf-8")
    tmp_items.replace(ITEMS)
    tmp_src.replace(SOURCES)


if __name__ == "__main__":
    main()
