"""Classify instance boss_drop rows with Wowhead's boss flag.

A creature Wowhead marks boss stays a boss drop. A rare stays Rare NPC.
Everyone else inside a known dungeon or raid becomes raid_trash, which the
log labels Dungeon & Raid trash.
"""
import gzip
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "pipeline" / "data"
SOURCES = DATA / "sources.json"
DOORS = DATA / "dungeon_entrances.json"
FLAGS = DATA / "npc_boss_flags.json"
UA = "wow-classic-data-research/1.0 (+contact: local script)"
DELAY = 0.35

def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, timeout=40) as resp:
        raw = resp.read()
        if resp.headers.get("Content-Encoding") == "gzip":
            raw = gzip.decompress(raw)
        return raw.decode("utf-8", "replace")

def lookup(name: str) -> dict:
    url = "https://www.wowhead.com/forever/search?q=" + urllib.parse.quote(name)
    html = fetch(url)
    marker = html.find('id="data.wowhead')
    if marker < 0:
        return {"status": "no-json"}
    start = html.find(">", marker)
    end = html.find("</script>", start)
    try:
        data = json.loads(html[start + 1 : end])
    except json.JSONDecodeError:
        return {"status": "bad-json"}
    want = name.casefold()
    rows = [
        r for r in data
        if isinstance(r, dict) and (r.get("displayName") or "").casefold() == want
    ]
    if not rows:
        return {"status": "no-match"}
    row = rows[0]
    return {
        "status": "ok",
        "id": row.get("id"),
        "boss": 1 if row.get("boss") else 0,
        "classification": row.get("classification"),
    }

def main() -> None:
    doors = json.loads(DOORS.read_text(encoding="utf-8"))
    zones = set(doors["entrances"])
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    flags = json.loads(FLAGS.read_text(encoding="utf-8")) if FLAGS.exists() else {}
    names = set()
    for src in sources.values():
        if not isinstance(src, dict) or src.get("sourceType") != "boss_drop":
            continue
        if (src.get("zone") or "") not in zones:
            continue
        npc = (src.get("npc") or "").strip()
        if npc:
            names.add(npc)
    pending = sorted(n for n in names if n not in flags)
    print(f"instance boss_drop names {len(names)} cached {len(names)-len(pending)} pending {len(pending)}", flush=True)
    for i, name in enumerate(pending, 1):
        try:
            flags[name] = lookup(name)
        except Exception as e:
            flags[name] = {"status": "error", "error": str(e)}
            print("  fail", name, e, flush=True)
        if i % 20 == 0:
            FLAGS.write_text(json.dumps(flags, ensure_ascii=True, indent=1), encoding="utf-8")
            print(f"  {i}/{len(pending)}", flush=True)
        time.sleep(DELAY)
    FLAGS.write_text(json.dumps(flags, ensure_ascii=True, indent=1), encoding="utf-8")
    print("wrote", FLAGS, flush=True)

if __name__ == "__main__":
    main()
