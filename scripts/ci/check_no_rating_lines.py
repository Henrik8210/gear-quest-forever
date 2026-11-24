#!/usr/bin/env python3
"""Forever prints a percent, not a rating.

"Improves your chance to get a critical strike by 1%" is Critical strike 1.
The old "critical strike rating by 14" is that same 1%. A stored effect that
still says rating is the mistake that scored 14 against a 0.5% wand.

A live tooltip that still says rating is listed in rating_line_allow.txt,
one item id per line. Anything else fails.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ITEMS = ROOT / "pipeline" / "data" / "items.json"
ALLOW = Path(__file__).with_name("rating_line_allow.txt")
RATING = re.compile(
    r"\b(?:hit|critical strike|crit|dodge|parry|haste|defense|block|expertise|resilience) rating\b",
    re.I,
)


def allowed():
    if not ALLOW.exists():
        return set()
    out = set()
    for line in ALLOW.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            out.add(int(line))
    return out


def main():
    raw = json.loads(ITEMS.read_text(encoding="utf-8"))
    items = raw.values() if isinstance(raw, dict) else raw
    keep = allowed()
    bad = []
    for item in items:
        if not isinstance(item, dict):
            continue
        iid = int(item.get("id") or 0)
        if iid in keep:
            continue
        for line in item.get("effects") or []:
            if RATING.search(line):
                bad.append(f"{iid} {item.get('name')}: {line}")
                break
    if bad:
        print(f"{len(bad)} items still say rating", file=sys.stderr)
        for line in bad[:40]:
            print(line, file=sys.stderr)
        return 1
    print("no rating lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
