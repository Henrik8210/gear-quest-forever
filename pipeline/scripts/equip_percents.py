"""Equip chance lines scored as the percent they name.

"Improves your chance to hit by 2%" is Hit 2. Forever no longer prints a
rating. A stored 14 beside "by 1%" is the old scale (10 per 1% hit, 14 per 1%
crit, 12 per 1% dodge, 15 per 1% parry), so the percent replaces whatever
number was stored. A Chance on hit, a spell-specific crit, and a per-piece
set line are not these stats.
"""

from __future__ import annotations

import re

# Points the old tooltip parser stored per 1% of the line.
CONVERSION = {"hit": 10.0, "crit": 14.0, "dodge": 12.0, "parry": 15.0}

_LINES = (
    ("hit", re.compile(r"^equip: improves your chance to hit by ([\d.]+)%\.?$")),
    ("hit", re.compile(r"^equip: improves your chance to hit with ranged weapons by ([\d.]+)%\.?$")),
    (
        "crit",
        re.compile(
            r"^equip: improves your chance to get a critical strike(?: with [a-z ,]+)? by ([\d.]+)%\.?$"
        ),
    ),
    ("dodge", re.compile(r"^equip: increases your chance to dodge an attack by ([\d.]+)%\.?$")),
    ("parry", re.compile(r"^equip: increases your chance to parry an attack by ([\d.]+)%\.?$")),
    ("haste", re.compile(r"^equip: increases your attack speed and casting speed by ([\d.]+)%\.?$")),
    ("expertise", re.compile(r"^equip: reduces chance to be dodged or parried by ([\d.]+)%\.?$")),
    (
        "blockRating",
        re.compile(r"^equip: increases your chance to block attacks with a shield by ([\d.]+)%\.?$"),
    ),
)


def percent_amounts(effects):
    """{stat: percent} from the Equip lines above. 2% hit -> {"hit": 2}."""
    found = {}
    for line in effects or []:
        low = str(line).strip().lower()
        for key, pattern in _LINES:
            match = pattern.match(low)
            if not match:
                continue
            found[key] = found.get(key, 0.0) + float(match.group(1))
            break
    return found


def merge_equip_percents(stats, effects):
    """Write the percent onto stats. A converted rating of that same line is replaced."""
    amounts = percent_amounts(effects)
    # The visible "by N%" line is the stat. A stored 14 beside "by 1%" is the
    # old rating scale, not a second bonus, so the percent replaces it.
    for key, pct in amounts.items():
        if pct:
            stats[key] = pct
    return stats
