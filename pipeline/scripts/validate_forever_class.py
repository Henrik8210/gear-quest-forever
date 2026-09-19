"""Validate one class hunt IDs: Wowhead Forever only, no TBC/Outland."""
from __future__ import annotations

import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT / "GearQuest" / "_generated"
DATA = ROOT / "pipeline" / "data"
CACHE = DATA / "forever_wowhead"

TBC_IDS = set(json.loads((GEN / "data" / "tbc_only_item_ids.json").read_text(encoding="utf-8")).get("ids") or [])
AUDIT_TEXT = (GEN / "Data.ForeverAudit.generated.lua").read_text(encoding="utf-8")
AUDIT = {
    int(m.group(1)): m.group(2)
    for m in re.finditer(r'\[(\d+)\]=\{status="(ok|missing)"', AUDIT_TEXT)
}
POOL = set(json.loads((DATA / "classic_item_ids.json").read_text(encoding="utf-8")))
ITEMS = json.loads((DATA / "items.json").read_text(encoding="utf-8"))
SOURCES = json.loads((DATA / "sources.json").read_text(encoding="utf-8"))
HUNT_TIPS = {}
if (CACHE / "hunt_tooltips.json").exists():
    HUNT_TIPS = json.loads((CACHE / "hunt_tooltips.json").read_text(encoding="utf-8"))

OUTLAND_HINTS = re.compile(
    r"outland|hellfire|zangarmarsh|terokkar|nagrand|netherstorm|shadowmoon|"
    r"shattrath|karazhan|black temple|serpentshrine|tempest keep|"
    r"magtheridon|gruul|sunwell|quel.?danas|blade'?s edge|coilfang|"
    r"auchindoun|mana-tombs|sethekk|arcatraz|mechanar|botanica",
    re.I,
)
OUTLAND_ZONES = {
    "outland", "hellfire peninsula", "hellfire ramparts", "blood furnace",
    "shattered halls", "zangarmarsh", "coilfang", "slave pens", "underbog",
    "steamvault", "terokkar forest", "auchindoun", "mana-tombs",
    "auchenai crypts", "sethekk halls", "shadow labyrinth", "nagrand",
    "blade's edge mountains", "netherstorm", "tempest keep", "the mechanar",
    "the botanica", "the arcatraz", "shadowmoon valley", "black temple",
    "isle of quel'danas", "magister's terrace", "sunwell plateau", "karazhan",
    "gruul's lair", "magtheridon's lair", "serpentshrine cavern", "the eye",
    "shattrath", "shattrath city",
}

PICK_RE = re.compile(
    r"\{\s*(\d+)\s*,\"([^\"]+)\"\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\"([^\"]+)\"\s*,\"([^\"]+)\""
)
NOTE_RE = re.compile(
    r"\{(\d+),\"([^\"]+)\",(\d+),(\d+),\"([^\"]+)\",\"([^\"]+)\""
)

EARLY_FILES = {
    "PALADIN": "Data.Paladin.Horde.1to9.generated.lua",
    "WARRIOR": "Data.Warrior.Horde.1to9.generated.lua",
    "HUNTER": "Data.Hunter.Early.1to9.generated.lua",
    "DRUID": "Data.Druid.Early.1to9.generated.lua",
    "SHAMAN": "Data.Shaman.Early.1to9.generated.lua",
    "ROGUE": "Data.Rogue.Early.1to9.generated.lua",
    "PRIEST": "Data.Priest.Early.1to9.generated.lua",
    "WARLOCK": "Data.Warlock.Early.1to9.generated.lua",
    "MAGE": "Data.Mage.Early.1to9.generated.lua",
}


def name_of(iid: int) -> str:
    return (ITEMS.get(str(iid)) or {}).get("name") or f"item {iid}"


def is_outland(iid: int) -> bool:
    src = SOURCES.get(str(iid)) or {}
    zone = (src.get("zone") or "").strip().lower()
    if zone in OUTLAND_ZONES:
        return True
    blob = zone + " " + (src.get("instructions") or "")
    return bool(OUTLAND_HINTS.search(blob))


def classify(iid: int) -> str:
    if iid in TBC_IDS or is_outland(iid):
        return "tbc_only"
    if iid >= 200000:
        return "forever_new"
    st = AUDIT.get(iid)
    tip = (HUNT_TIPS.get(str(iid)) or {}).get("status")
    if st == "ok" or tip == "ok":
        return "forever_classic_ok"
    if st == "missing" or tip == "missing":
        return "forever_404"
    return "unverified"


def extract_table(text: str, name: str) -> str:
    m = re.search(rf"GQ\.Data\.{name}\s*=\s*\{{", text)
    if not m:
        return ""
    start = m.end() - 1
    depth = 0
    for i, ch in enumerate(text[start:], start):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    return text[start:]


def mid_unverified_ids(cls: str) -> list[int]:
    title = cls.title()
    lc = cls.lower()
    mid_file = (GEN / f"Data.{title}.generated.lua").read_text(encoding="utf-8")
    picks_text = extract_table(mid_file, f"{lc}Picks")
    mid = {int(m.group(1)) for m in PICK_RE.finditer(picks_text) if int(m.group(3)) >= 10}
    return sorted(i for i in mid if classify(i) in ("unverified", "forever_404"))


def main() -> None:
    cls = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GQ_CLASS") or "HUNTER").upper()
    title = cls.title()
    lc = cls.lower()
    mid_path = GEN / f"Data.{title}.generated.lua"
    early_name = EARLY_FILES.get(cls)
    mid_file = mid_path.read_text(encoding="utf-8")
    early_file = (GEN / early_name).read_text(encoding="utf-8") if early_name and (GEN / early_name).exists() else ""

    picks_text = (
        extract_table(mid_file, f"{lc}Picks")
        + extract_table(early_file, f"{lc}Early1to9Picks")
        + extract_table(early_file, f"{lc}Early1to9")
        + extract_table(early_file, f"{lc}Horde1to9")
    )
    notes_text = (
        extract_table(mid_file, f"{lc}Notable")
        + extract_table(early_file, f"{lc}Early1to9Notable")
    )

    picks = []
    for m in PICK_RE.finditer(picks_text):
        picks.append(
            {
                "id": int(m.group(1)),
                "slot": m.group(2),
                "lo": int(m.group(3)),
                "hi": int(m.group(4)),
                "rank": int(m.group(5)),
                "spec": m.group(6),
                "faction": m.group(7),
            }
        )
    notes = [int(m.group(1)) for m in NOTE_RE.finditer(notes_text)]

    data_lua = (ROOT / "GearQuest" / "Data.lua").read_text(encoding="utf-8")
    curated = {
        int(m.group(1))
        for m in re.finditer(
            rf"itemId\s*=\s*(\d+)[\s\S]{{0,500}}?classes\s*=\s*{cls}_CLASS",
            data_lua,
        )
    }

    mid = {p["id"] for p in picks if p["lo"] >= 10}
    early = {p["id"] for p in picks if p["hi"] <= 9}
    note_ids = set(notes)
    all_ids = mid | early | note_ids | curated
    buckets = Counter(classify(i) for i in all_ids)

    print(f"=== {title} hunt ID validation (Wowhead Forever vs TBC) ===")
    print(f"picks 10-60 unique ids: {len(mid)}")
    print(f"picks 1-9 unique ids:   {len(early)}")
    print(f"notable ids:            {len(note_ids)}")
    print(f"Data.lua curated:       {len(curated)}")
    print(f"union:                  {len(all_ids)}")
    print("by status:")
    for k in ("forever_classic_ok", "forever_new", "forever_404", "tbc_only", "unverified"):
        print(f"  {k:22} {buckets[k]}")

    tbc_hits = sorted(i for i in all_ids if classify(i) == "tbc_only")
    missing_mid = sorted(i for i in mid if classify(i) == "forever_404")
    unverified = sorted(i for i in all_ids if classify(i) == "unverified")
    mid_unverified = [i for i in unverified if i in mid]
    pool_tbc = [i for i in POOL if i in TBC_IDS]

    print(f"\nscoring pool intersect tbc_only: {len(pool_tbc)}")
    if tbc_hits:
        print(f"\nTBC/Outland ids still in {lc} hunts:")
        for i in tbc_hits:
            print(f"  {i} {name_of(i)}  zone={(SOURCES.get(str(i)) or {}).get('zone')}")
    else:
        print(f"\nNo TBC/Outland ids in {lc} hunts.")

    print(f"\nForever 404 still in {lc} 10-60 picks: {len(missing_mid)}")
    for i in missing_mid[:25]:
        print(f"  {i} {name_of(i)}")

    print(f"\nunverified: {len(unverified)}  (10-60 picks: {len(mid_unverified)})")
    for i in mid_unverified[:30]:
        print(f"  {i} {name_of(i)}")
    if len(mid_unverified) > 30:
        print(f"  ... {len(mid_unverified) - 30} more")

    print("\n=== 10-60 pick rows by spec ===")
    for key, n in sorted(Counter((p["spec"], p["faction"]) for p in picks if p["lo"] >= 10).items()):
        print(f"  {key[0]:16} {key[1]:9} {n}")

    ranks = {}
    for p in picks:
        if p["lo"] < 10:
            continue
        key = (p["spec"], p["faction"], p["slot"], p["lo"], p["hi"])
        ranks.setdefault(key, set()).add(p["rank"])
    short = [(k, sorted(v)) for k, v in ranks.items() if max(v or [0]) < 3]
    print(f"\nbands with max rank < 3: {len(short)}")
    for k, r in short[:12]:
        print(f"  {k} ranks={r}")

    print("\nPOOL_TBC_CLEAN" if not pool_tbc else "\nPOOL_HAS_TBC")
    print(f"{cls}_HUNTS_TBC_CLEAN" if not tbc_hits else f"{cls}_HUNTS_HAVE_TBC")
    raise SystemExit(0 if not tbc_hits and not pool_tbc else 2)


if __name__ == "__main__":
    main()
