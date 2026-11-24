#!/usr/bin/env python3
"""Write the ranked lists Dreamer's guild bot reads.

The file is the addon catalogs (levels 1-60, every class and spec, both
factions), not the raw Wowhead scrape. An item that never scored onto a list
is absent on purpose. Level 60 stays score order. A page piece carries
guidePlace, and level60Guides is the Wowhead Forever page in page order.

    python pipeline/scripts/export_bot_json.py
    python pipeline/scripts/export_bot_json.py --check

Output: export/gearquest-forever.json
That folder is not in the CurseForge package. Run the writer before a commit
and push whenever the addon lists changed. --check fails when the file
disagrees with those lists. The generated time and the commit hash are not
compared.
"""
from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT / "GearQuest" / "_generated"
OUT = ROOT / "export" / "gearquest-forever.json"
GUIDES = ROOT / "pipeline" / "guides" / "forever_bis.json"
TOC = ROOT / "GearQuest" / "GearQuestForever.toc"

CLASSES = (
    "Druid", "Hunter", "Mage", "Paladin", "Priest",
    "Rogue", "Shaman", "Warlock", "Warrior",
)

PICK_RE = re.compile(
    r'^\s*\{(\d+),"([^"]+)",(\d+),(\d+),(\d+),"([^"]+)","([^"]+)",([0-9.]+)(.*)\}\s*,?\s*$'
)
FACT_RE = re.compile(r"^\s*\[(\d+)\]=\{(.*)\}\s*,?\s*$")

ITEM_KEYS = {
    "name": "name",
    "quality": "quality",
    "ilvl": "ilvl",
    "reqLevel": "req",
    "sourceType": "source",
    "zone": "zone",
    "npc": "npc",
    "questName": "quest",
    "profession": "profession",
}
EXTRA_KEYS = (
    "suffix", "suffixChance", "suffixId", "suffixRange",
    "origin", "guidePlace", "hand", "route", "healOnly", "reserve",
)


def addon_version() -> str:
    text = TOC.read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*(\S+)", text, re.M)
    return match.group(1) if match else ""


def git_commit() -> tuple[str, bool]:
    try:
        head = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()
        dirty = subprocess.call(
            ["git", "diff", "--quiet", "HEAD"], cwd=ROOT
        ) != 0
        return head, dirty
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "", True


def parse_fields(body: str) -> dict:
    fields: dict = {}
    i = 0
    n = len(body)
    while i < n:
        while i < n and body[i] in " ,":
            i += 1
        if i >= n:
            break
        eq = body.find("=", i)
        if eq < 0:
            break
        key = body[i:eq].strip()
        i = eq + 1
        if i < n and body[i] == '"':
            i += 1
            chars: list[str] = []
            while i < n:
                ch = body[i]
                if ch == "\\":
                    if i + 1 < n:
                        chars.append(body[i + 1])
                    i += 2
                    continue
                if ch == '"':
                    i += 1
                    break
                chars.append(ch)
                i += 1
            fields[key] = "".join(chars)
            continue
        end = i
        while end < n and body[end] != ",":
            end += 1
        raw = body[i:end].strip()
        i = end
        if raw == "true":
            fields[key] = True
        elif raw == "false":
            fields[key] = False
        else:
            try:
                fields[key] = float(raw) if "." in raw else int(raw)
            except ValueError:
                fields[key] = raw
    return fields


def read_tables(path: Path) -> tuple[dict[int, dict], list[dict]]:
    items: dict[int, dict] = {}
    bands: list[dict] = []
    mode = None
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("GQ.Data.") and line.rstrip().endswith("= {"):
            name = line.split(".", 2)[-1].split(" ", 1)[0]
            if name.endswith("Facts"):
                mode = "facts"
            else:
                mode = "picks"
            current = None
            continue
        if line == "}":
            if current is not None:
                bands.append(current)
                current = None
            mode = None
            continue
        if mode == "facts":
            match = FACT_RE.match(line)
            if not match:
                continue
            fields = parse_fields(match.group(2))
            item = {}
            for src, dst in ITEM_KEYS.items():
                if src in fields and fields[src] not in ("", None):
                    item[dst] = fields[src]
            items[int(match.group(1))] = item
            continue
        if mode != "picks":
            continue
        match = PICK_RE.match(line)
        if not match:
            continue
        item_id = int(match.group(1))
        slot = match.group(2)
        lo = int(match.group(3))
        hi = int(match.group(4))
        rank = int(match.group(5))
        spec = match.group(6)
        faction = match.group(7)
        score = float(match.group(8))
        if score == int(score):
            score = int(score)
        extras = parse_fields(match.group(9).lstrip(","))
        pick: list = [item_id, rank, score]
        extra = {key: extras[key] for key in EXTRA_KEYS if key in extras}
        if extra:
            pick.append(extra)
        key = (spec, faction, slot, lo, hi)
        if current is None or current["key"] != key:
            if current is not None:
                bands.append(current)
            current = {"key": key, "picks": [pick]}
        else:
            current["picks"].append(pick)
    return items, bands


DATA_KEYS = (
    "addonVersion", "credit", "about", "bands",
    "items", "level60Guides", "classes",
)


def build() -> tuple[dict, int, int]:
    items: dict[str, dict] = {}
    classes: dict[str, list] = {}
    used: set[int] = set()
    band_count = 0
    pick_count = 0
    for cls in CLASSES:
        lc = cls.lower()
        merged: dict[int, dict] = {}
        class_bands: list = []
        for path in (
            GEN / f"Data.{cls}.Early.1to9.generated.lua",
            GEN / f"Data.{cls}.generated.lua",
        ):
            facts, bands = read_tables(path)
            merged.update(facts)
            for band in bands:
                spec, faction, slot, lo, hi = band["key"]
                class_bands.append([spec, faction, slot, lo, hi, band["picks"]])
                band_count += 1
                pick_count += len(band["picks"])
                for pick in band["picks"]:
                    used.add(pick[0])
        classes[cls.upper()] = class_bands
        for item_id, fact in merged.items():
            if item_id in used:
                items[str(item_id)] = fact
        print(f"{cls}: {len(class_bands)} bands", flush=True)

    guides = json.loads(GUIDES.read_text(encoding="utf-8"))
    commit, dirty = git_commit()
    payload = {
        "addonVersion": addon_version(),
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "commit": commit,
        "tree": "uncommitted" if dirty else "clean",
        "credit": "GearQuest Forever",
        "about": (
            "Ranked gear from the GearQuest Forever addon, levels 1 through 60, "
            "every class and spec, Alliance and Horde. Rank 1 is the best piece "
            "on that list. A row with reserve true is kept for filters and is "
            "past the three hunts the log shows first. The same item is stored "
            "once under items. A random enchant is ranked on its best suffix. "
            "Match suffixId, not the suffix name. Level 60 stays in score order. "
            "guidePlace is that item's number on the Wowhead Forever page, and "
            "level60Guides is the page itself. An item that is missing was not "
            "ranked for that class, spec, faction, and level. It is not a bad item. "
            "Show GearQuest Forever as the source, and do not republish this file."
        ),
        "bands": (
            "Each class is a list of [spec, faction, slot, minLevel, maxLevel, picks]. "
            "A pick is [itemId, rank, score] or [itemId, rank, score, extras]. "
            "extras may hold suffix, suffixChance, suffixId, suffixRange, origin, "
            "guidePlace, hand, route, healOnly, and reserve."
        ),
        "items": dict(sorted(items.items(), key=lambda pair: int(pair[0]))),
        "level60Guides": guides,
        "classes": classes,
    }
    return payload, band_count, pick_count


def check() -> int:
    if not OUT.exists():
        print("FAIL export/gearquest-forever.json is missing. Run export_bot_json.py.")
        return 1
    fresh, band_count, pick_count = build()
    committed = json.loads(OUT.read_text(encoding="utf-8"))
    failed = False
    for key in DATA_KEYS:
        if committed.get(key) != fresh[key]:
            print(f"FAIL export/gearquest-forever.json {key} is not the addon lists")
            failed = True
    if failed:
        print("Run: python pipeline/scripts/export_bot_json.py")
        return 1
    print(f"export matches the addon lists, {band_count} bands, {pick_count} picks")
    return 0


def main() -> None:
    payload, band_count, pick_count = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(".json.new")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    tmp.replace(OUT)
    size = OUT.stat().st_size
    print(f"wrote {OUT} {size/1e6:.1f} MB, {band_count} bands, {pick_count} picks, {len(payload['items'])} items")


if __name__ == "__main__":
    import sys
    if "--check" in sys.argv:
        sys.exit(check())
    main()
