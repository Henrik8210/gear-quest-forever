"""Write camp-vendor instructions onto confirmed Merchant's Favor crafts.

Patches sources.json in place (no reformat) and the generated hunt Lua the
addon already loads. Re-running is safe.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commerce_camps import camp_instructions
from gq_paths import ADDON_GEN, G

SOURCES = os.path.join(G, "sources.json")
ITEMS = os.path.join(G, "items.json")
GENERATED = ADDON_GEN


def patch_sources(text, updates):
    changed = 0
    for iid, new in updates.items():
        key = f'\n  "{iid}": {{'
        i = text.find(key)
        if i < 0:
            raise SystemExit(f"sources missing {iid}")
        j = text.find("\n  }", i)
        if j < 0:
            raise SystemExit(f"sources block broken {iid}")
        block = text[i:j]
        mark = '"instructions": "'
        a = block.find(mark)
        if a < 0:
            raise SystemExit(f"no instructions for {iid}")
        start = a + len(mark)
        end = block.find('"', start)
        if end < 0:
            raise SystemExit(f"unclosed instructions for {iid}")
        if block[start:end] == new:
            continue
        block = block[:start] + new + block[end:]
        text = text[:i] + block + text[j:]
        changed += 1
    return text, changed


def patch_lua(path, updates):
    with open(path, encoding="utf-8", errors="surrogateescape", newline="") as handle:
        lines = handle.read().splitlines(keepends=True)
    changed = 0
    out = []
    for line in lines:
        m = re.match(r"\s*\[(\d+)\]=\{", line)
        if m and m.group(1) in updates:
            new = updates[m.group(1)]
            line2, n = re.subn(
                r'(instructions=")([^"]*)(")',
                lambda mo, new=new: mo.group(1) + new + mo.group(3),
                line,
                count=1,
            )
            if n and line2 != line:
                changed += 1
                line = line2
        out.append(line)
    if changed:
        with open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as handle:
            handle.write("".join(out))
    return changed


def main():
    items = json.load(open(ITEMS, encoding="utf-8"))
    sources = json.load(open(SOURCES, encoding="utf-8"))
    updates = {}
    for iid, src in sources.items():
        if src.get("sourceType") != "profession" or int(iid) < 200000:
            continue
        name = (items.get(iid) or {}).get("name") or ""
        text = camp_instructions(name, src.get("profession"))
        if text:
            updates[iid] = text
    print(f"camp recipes to describe: {len(updates)}")
    raw = open(SOURCES, encoding="utf-8", newline="").read()
    raw, n_src = patch_sources(raw, updates)
    open(SOURCES, "w", encoding="utf-8", newline="").write(raw)
    print(f"sources.json instructions updated: {n_src}")
    lua_n = 0
    for name in sorted(os.listdir(GENERATED)):
        if not name.endswith(".lua"):
            continue
        n = patch_lua(Path(GENERATED) / name, updates)
        if n:
            print(f"  {name}: {n}")
            lua_n += n
    print(f"generated instruction lines updated: {lua_n}")


if __name__ == "__main__":
    main()
