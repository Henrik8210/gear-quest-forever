"""Slow live Forever pass. One Wowhead client at a time.

Resume-safe: the tooltip step skips ids already in refresh_cache_env16.json.

  python -u pipeline/scripts/forever_live_pass.py

Order:
  1. Listview index of Forever gear (id >= 200000).
  2. dataEnv=16 tooltip refresh of every hunt id and index id.
  3. Ingest new ids and listview place changes. Stats stay as the refresh wrote them.
  4. Quest pickup level for items whose tooltip states no Requires Level.
  5. Coordinates for those new and moved ids.
  6. New in Forever probe for ids not already cached.
  7. Tooltip audit, then rescore all nine classes.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PY = sys.executable


def main() -> None:
    env = os.environ.copy()
    env.setdefault("GQ_SCRAPE_DELAY_MS", "2000")
    env.setdefault("GQ_TIP_DELAY", "1.5")
    env.setdefault("GQ_COORD_DELAY", "1.5")
    env["GQ_NO_GUIDES"] = "1"
    env["PYTHONUNBUFFERED"] = "1"

    def run(cmd: list[str]) -> None:
        print(">> " + " ".join(cmd), flush=True)
        subprocess.check_call(cmd, cwd=str(ROOT), env=env)

    run(["node", "scripts/scrape-forever-wowhead-items.mjs", "--index"])
    run([PY, "-u", "pipeline/scripts/refresh_forever_tips.py"])
    run([PY, "-u", "pipeline/scripts/ingest_forever_wowhead.py"])
    # A tooltip with no Requires Level is not left on item level. The quest
    # that gates the item sets the required level. Chain pins run after, so a
    # dungeon step is not lowered back to the first pickup.
    env.setdefault("GQ_QUEST_DELAY", "1.5")
    run([PY, "-u", "pipeline/scripts/apply_quest_req_levels.py"])
    run([PY, "-u", "pipeline/scripts/apply_chain_gates.py"])

    need = ROOT / "pipeline" / "data" / "forever_wowhead" / "coord_needed.json"
    ids = json.loads(need.read_text(encoding="utf-8")) if need.exists() else []
    if ids:
        print(f"coordinates for {len(ids)} ids", flush=True)
        run([PY, "-u", "pipeline/scripts/index_coordinates.py", "--ids", str(need)])
    else:
        print("no coordinate changes", flush=True)

    run([PY, "-u", "pipeline/scripts/build_forever_new.py"])
    run([PY, "-u", "pipeline/scripts/emit_forever_audit.py"])
    run([PY, "-u", "pipeline/scripts/rescore_hunter_shaman.py"])
    run(["powershell", "-NoProfile", "-File", r".\scripts\sync-addon.ps1"])
    print("LIVE PASS DONE", flush=True)


if __name__ == "__main__":
    main()
