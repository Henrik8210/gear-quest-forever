"""Validate shaman hunt IDs: Wowhead Forever only, no TBC/Outland items."""
from __future__ import annotations

import json
import re
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

OUTLAND_ZONES = {
    "outland",
    "hellfire peninsula",
    "hellfire ramparts",
    "blood furnace",
    "shattered halls",
    "zangarmarsh",
    "coilfang",
    "slave pens",
    "underbog",
    "steamvault",
    "terokkar forest",
    "auchindoun",
    "mana-tombs",
    "auchenai crypts",
    "sethekk halls",
    "shadow labyrinth",
    "nagrand",
    "blade's edge mountains",
    "grulloc",
    "netherstorm",
    "tempest keep",
    "the mechanar",
    "the botanica",
    "the arcatraz",
    "shadowmoon valley",
    "black temple",
    "isle of quel'danas",
    "magister's terrace",
    "sunwell plateau",
    "karazhan",
    "gruul's lair",
    "magtheridon's lair",
    "serpentshrine cavern",
    "the eye",
    "shattrath",
    "shattrath city",
    "deadwind pass",  # Karazhan attunement; vanilla zone but TBC raid
}

# Deadwind Pass is vanilla; Karazhan is TBC. Only flag if instructions mention TBC raid.
OUTLAND_HINTS = re.compile(
    r"outland|hellfire|zangarmarsh|terokkar|nagrand|netherstorm|shadowmoon|"
    r"shattrath|karazhan|black temple|serpentshrine|tempest keep|"
    r"magtheridon|gruul|sunwell|quel.?danas|blade'?s edge|coilfang|"
    r"auchindoun|mana-tombs|sethekk|arcatraz|mechanar|botanica",
    re.I,
)

PICK_RE = re.compile(
    r"\{\s*(\d+)\s*,\"([^\"]+)\"\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\"([^\"]+)\"\s*,\"([^\"]+)\""
)
NOTE_RE = re.compile(
    r"\{(\d+),\"([^\"]+)\",(\d+),(\d+),\"([^\"]+)\",\"([^\"]+)\""
)
CURATED_RE = re.compile(r"itemId\s*=\s*(\d+)")


def name_of(iid: int) -> str:
    it = ITEMS.get(str(iid)) or {}
    return it.get("name") or f"item {iid}"


def source_zone(iid: int) -> str:
    src = SOURCES.get(str(iid)) or {}
    return (src.get("zone") or "") + " " + (src.get("instructions") or "")


def is_outland(iid: int) -> bool:
    blob = source_zone(iid).lower()
    if not blob.strip():
        return False
    zone = (SOURCES.get(str(iid)) or {}).get("zone") or ""
    if zone.strip().lower() in OUTLAND_ZONES and zone.strip().lower() != "deadwind pass":
        return True
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


def main() -> None:
    mid_file = (GEN / "Data.Shaman.generated.lua").read_text(encoding="utf-8")
    early_file = (GEN / "Data.Shaman.Early.1to9.generated.lua").read_text(encoding="utf-8")
    picks_text = extract_table(mid_file, "shamanPicks") + extract_table(early_file, "shamanEarly1to9Picks")
    notes_text = extract_table(mid_file, "shamanNotable") + extract_table(early_file, "shamanEarly1to9Notable")

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
    notes = []
    for m in NOTE_RE.finditer(notes_text):
        notes.append(
            {
                "id": int(m.group(1)),
                "slot": m.group(2),
                "lo": int(m.group(3)),
                "hi": int(m.group(4)),
                "spec": m.group(5),
                "faction": m.group(6),
            }
        )

    data_lua = (ROOT / "GearQuest" / "Data.lua").read_text(encoding="utf-8")
    curated = set()
    # Only the forever_horde_shaman / shaman curated block itemIds near SHAMAN_CLASS
    for m in re.finditer(
        r"itemId\s*=\s*(\d+)[\s\S]{0,500}?classes\s*=\s*SHAMAN_CLASS",
        data_lua,
    ):
        curated.add(int(m.group(1)))

    mid = {p["id"] for p in picks if p["lo"] >= 10}
    early = {p["id"] for p in picks if p["hi"] <= 9}
    note_ids = {n["id"] for n in notes}
    all_ids = mid | early | note_ids | curated

    buckets = Counter(classify(i) for i in all_ids)
    print("=== Shaman hunt ID validation (Wowhead Forever vs TBC) ===")
    print(f"picks 10-60 unique ids: {len(mid)}")
    print(f"picks 1-9 unique ids:   {len(early)}")
    print(f"notable ids:            {len(note_ids)}")
    print(f"Data.lua shaman curated:{len(curated)}")
    print(f"union:                  {len(all_ids)}")
    print("by status:")
    for k in (
        "forever_classic_ok",
        "forever_new",
        "forever_404",
        "tbc_only",
        "unverified",
    ):
        print(f"  {k:22} {buckets[k]}")

    tbc_hits = sorted(i for i in all_ids if classify(i) == "tbc_only")
    missing_mid = sorted(i for i in mid if classify(i) == "forever_404")
    unverified = sorted(i for i in all_ids if classify(i) == "unverified")
    pool_tbc = sorted(i for i in POOL if i in TBC_IDS)
    pool_outland = sorted(i for i in POOL if is_outland(i))

    print(f"\nscoring pool intersect tbc_only: {len(pool_tbc)}")
    print(f"scoring pool Outland-sourced:     {len(pool_outland)}")
    if tbc_hits:
        print("\nTBC/Outland ids still in shaman hunts:")
        for i in tbc_hits:
            z = (SOURCES.get(str(i)) or {}).get("zone")
            print(f"  {i} {name_of(i)}  zone={z}")
    else:
        print("\nNo TBC/Outland ids in shaman hunts.")

    print(f"\nForever 404 still in shaman 10-60 picks: {len(missing_mid)}")
    for i in missing_mid[:25]:
        print(f"  {i} {name_of(i)}")

    print(f"\nunverified (no Forever audit/tooltip): {len(unverified)}")
    mid_unverified = [i for i in unverified if i in mid]
    print(f"  of which in 10-60 picks: {len(mid_unverified)}")
    for i in mid_unverified[:30]:
        print(f"  {i} {name_of(i)}")
    if len(mid_unverified) > 30:
        print(f"  ... {len(mid_unverified) - 30} more")

    print("\n=== 10-60 pick rows by spec ===")
    c = Counter((p["spec"], p["faction"]) for p in picks if p["lo"] >= 10)
    for key, n in sorted(c.items()):
        print(f"  {key[0]:16} {key[1]:9} {n}")

    # Coverage: every spec/faction/slot should have ranks 1-3 somewhere in 10-60
    print("\n=== slots with fewer than 3 ranks at any 10-60 band ===")
    bands = Counter()
    ranks = {}
    for p in picks:
        if p["lo"] < 10:
            continue
        key = (p["spec"], p["faction"], p["slot"], p["lo"], p["hi"])
        ranks.setdefault(key, set()).add(p["rank"])
    short = [(k, sorted(v)) for k, v in ranks.items() if max(v or [0]) < 3]
    print(f"bands with max rank < 3: {len(short)}")
    for k, r in short[:15]:
        print(f"  {k} ranks={r}")

    ok = not tbc_hits and not pool_tbc
    print("\nPOOL_TBC_CLEAN" if not pool_tbc else "\nPOOL_HAS_TBC")
    print("SHAMAN_HUNTS_TBC_CLEAN" if not tbc_hits else "SHAMAN_HUNTS_HAVE_TBC")
    raise SystemExit(0 if ok else 2)


if __name__ == "__main__":
    main()
