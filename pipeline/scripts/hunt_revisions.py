"""Feedback revisions a Wowhead scrape must not undo.

pipeline/data/hunt_revisions.json is the log. A locked required level wins
over the tooltip and over the quest pickup. A locked quest side is written
back when the faction file is rebuilt.
"""
from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

from gq_paths import DATA

PATH = Path(DATA) / "hunt_revisions.json"


@lru_cache(maxsize=1)
def items() -> dict:
    if not PATH.exists():
        return {}
    raw = json.loads(PATH.read_text(encoding="utf-8"))
    rows = raw.get("items") if isinstance(raw, dict) else None
    return rows if isinstance(rows, dict) else {}


def lock(iid: int) -> dict:
    row = items().get(str(iid)) or {}
    locked = row.get("lock") or {}
    return locked if isinstance(locked, dict) else {}


def locked_rlvl(iid: int) -> int | None:
    level = lock(iid).get("rlvl")
    if level is None:
        return None
    return int(level)


def locked_levels() -> dict[int, int]:
    out = {}
    for key in items():
        level = locked_rlvl(int(key))
        if level:
            out[int(key)] = level
    return out


def locked_quest_factions() -> dict[int, str]:
    out = {}
    for key, row in items().items():
        side = (row.get("lock") or {}).get("questFaction")
        if side in ("Alliance", "Horde"):
            out[int(key)] = side
    return out
