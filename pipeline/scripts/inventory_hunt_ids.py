"""Inventory unique GearQuest hunt item IDs (generated + curated)."""
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT / "GearQuest" / "_generated"
DATA_LUA = ROOT / "GearQuest" / "Data.lua"

FACT_RE = re.compile(r"\[(\d+)\]=\{name=\"((?:\\.|[^\"])*)\"")
# {id,"slot",lo,hi,rank,"spec","faction",score
PICK_RE = re.compile(
    r"\{\s*(\d+)\s*,\"([^\"]+)\"\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*\d+\s*,\"([^\"]+)\"\s*,\"([^\"]+)\""
)


def class_from_filename(name: str) -> str:
    parts = name.split(".")
    return parts[1].lower() if len(parts) > 1 else name


def main():
    by_class = defaultdict(set)
    facts = {}
    picks = []  # dicts
    for path in sorted(GEN.glob("Data.*.generated.lua")):
        if "StatWeights" in path.name or "CraftSkills" in path.name:
            continue
        text = path.read_text(encoding="utf-8")
        cls = class_from_filename(path.name)
        for m in FACT_RE.finditer(text):
            iid = int(m.group(1))
            by_class[cls].add(iid)
            facts[iid] = m.group(2)
        for m in PICK_RE.finditer(text):
            iid = int(m.group(1))
            by_class[cls].add(iid)
            picks.append(
                {
                    "id": iid,
                    "class": cls,
                    "slot": m.group(2),
                    "lo": int(m.group(3)),
                    "hi": int(m.group(4)),
                    "spec": m.group(5),
                    "faction": m.group(6),
                    "file": path.name,
                }
            )
        print(f"{path.name}: facts={len(FACT_RE.findall(text))} picks={len(PICK_RE.findall(text))}")

    data = DATA_LUA.read_text(encoding="utf-8")
    curated = {int(x) for x in re.findall(r"itemId\s*=\s*(\d+)", data)}
    print(f"Data.lua curated itemIds={len(curated)}")
    all_ids = set(facts) | curated | {p["id"] for p in picks}
    print(f"unique ids={len(all_ids)}")
    print(f"classic <200000={sum(1 for i in all_ids if i < 200000)}")
    print(f"forever >=200000={sum(1 for i in all_ids if i >= 200000)}")
    for cls in sorted(by_class):
        print(f"  {cls}: {len(by_class[cls])}")
    out = ROOT / "pipeline" / "data" / "forever_wowhead" / "hunt_ids.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    import json

    json.dump(
        {
            "ids": sorted(all_ids),
            "curated": sorted(curated),
            "byClass": {k: sorted(v) for k, v in sorted(by_class.items())},
            "picks": picks,
            "names": {str(k): v for k, v in facts.items()},
        },
        out.open("w", encoding="utf-8"),
    )
    print("wrote", out)


if __name__ == "__main__":
    main()
