#!/usr/bin/env python3
"""The sheet number is the score. A level must not multiply it.

Fails when weights_at_level changes stamina, armor, intellect, or mana,
when GQ.ScoringLeveling is not 1, when hunt or enchant code multiplies by
that table, or when a live doc tells the scorer to put the old triple or
double back.

Usage: python scripts/ci/check_no_leveling_multipliers.py
"""
from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCORE_PY = REPO / "pipeline" / "scripts" / "score.py"
SCORING_LUA = REPO / "GearQuest" / "_generated" / "ScoringWeights.generated.lua"

SHEET = {
    "sta": 1.0,
    "health": 0.1,
    "hp5": 0.5,
    "armor": 0.01,
    "int": 0.4,
    "spi": 0.2,
    "mp5": 0.3,
    "mana": 0.02,
    "agi": 1.0,
    "hit": 2.0,
}

# Phrases that tell a later change to multiply the sheet again.
BANNED = (
    "hp5 ×3",
    "hp5 x3",
    "armor ×2",
    "armor x2",
    "mana ×2",
    "mana x2",
    "0.40 below 60",
    "×2 in the scorer",
    "x2 in the scorer",
    "doubles intellect",
    "endurance double",
    "The tripling",
    "LEVELING_STA_MULT",
    "LEVELING_ARMOR_MULT",
    "LEVELING_ENDURANCE_MULT",
    "weight * mult",
    "raw * mult",
    "weights[key] * mult",
    "leveling[key]",
)

LIVE_DOCS = (
    REPO / ".cursor" / "rules" / "forever-scoring.mdc",
    REPO / "docs" / "DATA_RULES.md",
    REPO / "docs" / "FOREVER-DATA-MIGRATION.md",
    REPO / "pipeline" / "docs" / "FOREVER-SCORING.md",
    REPO / "pipeline" / "docs" / "CURSOR-NOTE-PLAYER-WEIGHTS.md",
    REPO / "pipeline" / "data" / "weights.json",
    REPO / "RELEASE.md",
    REPO / "pipeline" / "scripts" / "score.py",
    REPO / "pipeline" / "scripts" / "relic_score.py",
    REPO / "GearQuest" / "Compare.lua",
    REPO / "GearQuest" / "Enchant.lua",
    REPO / "GearQuest" / "CustomSpec.lua",
    REPO / "scripts" / "generate-stat-weights-lua.mjs",
    SCORING_LUA,
)


def load_score():
    scripts = str(REPO / "pipeline" / "scripts")
    if scripts not in sys.path:
        sys.path.insert(0, scripts)
    spec = importlib.util.spec_from_file_location("gq_score_guard", SCORE_PY)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    failures: list[str] = []
    score = load_score()
    for level in (1, 22, 30, 60, 70):
        got = score.weights_at_level(dict(SHEET), level)
        for key, raw in SHEET.items():
            if got.get(key) != raw:
                failures.append(f"weights_at_level L{level} {key}: sheet={raw} got={got.get(key)}")
        if got is SHEET:
            failures.append("weights_at_level must copy the row")

    text = SCORING_LUA.read_text(encoding="utf-8")
    block = re.search(r"GQ\.ScoringLeveling = \{([^}]+)\}", text)
    if not block:
        failures.append("GQ.ScoringLeveling is missing")
    else:
        for key, value in re.findall(r"(\w+)\s*=\s*([0-9.]+)", block.group(1)):
            if key == "untilLevel":
                continue
            if float(value) != 1.0:
                failures.append(f"GQ.ScoringLeveling.{key} is {value}, must stay 1")

    for path in LIVE_DOCS:
        body = path.read_text(encoding="utf-8")
        for phrase in BANNED:
            if phrase in body:
                failures.append(f"{path.relative_to(REPO)} still says {phrase!r}")

    if failures:
        print(f"FAIL {len(failures)} leveling multiplier(s) came back:")
        for line in failures:
            print(f"  {line}")
        return 1
    print("OK: the sheet number is the score. No level multiplier.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
