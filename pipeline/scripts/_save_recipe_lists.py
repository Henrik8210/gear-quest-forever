"""Write Wowhead Forever recipe listviews from a CDP evaluate result."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "pipeline" / "data" / "forever_wowhead" / "recipe_lists"
OUT.mkdir(parents=True, exist_ok=True)

raw = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
value = raw
if isinstance(raw, dict) and "result" in raw:
    value = raw["result"].get("value", raw["result"])
if isinstance(value, dict) and "rows" in value:
    value = value["rows"]
if not isinstance(value, list):
    raise SystemExit("unexpected payload")
for row in value:
    item_id = row.get("id")
    if not isinstance(item_id, int):
        continue
    (OUT / f"{item_id}.json").write_text(json.dumps(row, separators=(",", ":")), encoding="utf-8")
print("saved", len(value))
