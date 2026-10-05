"""Probe Wowhead Forever tooltips for every GearQuest hunt item ID.

Cache: pipeline/data/forever_wowhead/hunt_tooltips.json
Resume-safe. 404 => missing. Named tooltip => ok. Other errors => unknown.
"""
from __future__ import annotations

import html
import json
import os
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE_DIR = ROOT / "pipeline" / "data" / "forever_wowhead"
HUNT_IDS = CACHE_DIR / "hunt_ids.json"
OUT = CACHE_DIR / "hunt_tooltips.json"
INDEX = CACHE_DIR / "index.json"
TIPS = CACHE_DIR / "tooltips.json"

UA = "GearQuestForever-data/1.0"
DELAY = float(os.environ.get("GQ_TOOLTIP_DELAY_MS", "120")) / 1000.0
URL = "https://nether.wowhead.com/forever/tooltip/item/{}"
TAG = re.compile(r"<[^>]+>")


WIDTH_TABLE = re.compile(r"<table\b[^>]*\bwidth\s*=\s*[\"']100%[\"'][^>]*>.*?</table>", re.I | re.S)
CELL = re.compile(r"<t[dh]\b[^>]*>(.*?)</t[dh]>", re.I | re.S)


def _cell_text(fragment: str) -> str:
    fragment = re.sub(r"<br\s*/?>", " ", fragment, flags=re.I)
    fragment = html.unescape(TAG.sub("", fragment))
    fragment = fragment.replace("\xa0", " ")
    return re.sub(r"\s+", " ", fragment).strip()


def plain(text: str) -> str:
    """Wowhead tooltip HTML as the lines the hover should show.

    Slot and weapon-speed sit in a 100% width table, one cell per side.
    Those become their own lines. A later pass pairs them. Drop chance
    stays on the line Wowhead gave it.
    """
    if not text:
        return ""
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)

    def cells(match: re.Match) -> str:
        parts = [_cell_text(cell) for cell in CELL.findall(match.group(0))]
        parts = [part for part in parts if part]
        if not parts:
            return "\n"
        return "\n" + "\n".join(parts) + "\n"

    text = WIDTH_TABLE.sub(cells, text)
    text = re.sub(r"<div\b", "\n<div", text, flags=re.I)
    text = re.sub(r"<br\s*/?>", "\n", text, flags=re.I)
    text = re.sub(r"</(?:div|tr|p|li|h\d)>", "\n", text, flags=re.I)
    text = html.unescape(TAG.sub("", text))
    text = text.replace("\xa0", " ")
    lines = []
    for raw in text.split("\n"):
        line = re.sub(r"[ \t]+", " ", raw).strip()
        line = re.sub(r"(\(\d+/\d+\))(?=\S)", r"\1\n", line)
        for piece in line.split("\n"):
            piece = piece.strip()
            if piece:
                lines.append(piece)
    if len(lines) >= 2 and lines[1].startswith("Item Level ") and not lines[0].startswith("Item Level "):
        lines = lines[1:]
    return "\n".join(lines).strip()


def load_json(path: Path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def seed_from_existing(cache: dict, ids: list[int]) -> None:
    index = load_json(INDEX, {})
    forever_ids = {int(it["id"]) for it in index.get("items") or [] if it.get("id")}
    tips = load_json(TIPS, {})
    for iid in ids:
        key = str(iid)
        if key in cache:
            continue
        raw = tips.get(key) or tips.get(iid)
        if isinstance(raw, dict) and raw.get("name") and not raw.get("error"):
            cache[key] = {
                "status": "ok",
                "name": raw.get("name"),
                "quality": raw.get("quality"),
                "icon": raw.get("icon"),
                "tip": plain(raw.get("tooltip") or ""),
                "source": "forever_index",
            }
        elif iid in forever_ids:
            cache[key] = {
                "status": "unknown",
                "name": None,
                "reason": "in forever index but tooltip missing",
                "source": "forever_index",
            }


def fetch_one(iid: int) -> dict:
    req = urllib.request.Request(URL.format(iid), headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            data = json.loads(body)
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return {"status": "missing", "reason": "http 404", "source": "nether"}
        return {"status": "unknown", "reason": f"http {err.code}", "source": "nether"}
    except Exception as err:
        return {"status": "unknown", "reason": str(err), "source": "nether"}

    if not isinstance(data, dict):
        return {"status": "unknown", "reason": "non-object tooltip", "source": "nether"}
    if data.get("error"):
        return {"status": "unknown", "reason": str(data.get("error")), "source": "nether"}
    name = data.get("name")
    tip = plain(data.get("tooltip") or "")
    if not name:
        return {"status": "unknown", "reason": "empty name", "source": "nether", "raw": data}
    if not tip:
        return {
            "status": "ok",
            "name": name,
            "quality": data.get("quality"),
            "icon": data.get("icon"),
            "tip": "",
            "reason": "no tooltip html",
            "source": "nether",
        }
    return {
        "status": "ok",
        "name": name,
        "quality": data.get("quality"),
        "icon": data.get("icon"),
        "tip": tip,
        "source": "nether",
    }


def main():
    hunt = load_json(HUNT_IDS, {})
    ids = [int(x) for x in hunt.get("ids") or []]
    if not ids:
        raise SystemExit("run inventory_hunt_ids.py first")

    cache = load_json(OUT, {})
    seed_from_existing(cache, ids)

    pending = [iid for iid in ids if str(iid) not in cache]
    print(f"cached {len(cache)} pending {len(pending)} total {len(ids)}")

    for i, iid in enumerate(pending, 1):
        cache[str(iid)] = fetch_one(iid)
        if i % 25 == 0 or i == len(pending):
            OUT.write_text(json.dumps(cache), encoding="utf-8")
            ok = sum(1 for v in cache.values() if v.get("status") == "ok")
            miss = sum(1 for v in cache.values() if v.get("status") == "missing")
            unk = sum(1 for v in cache.values() if v.get("status") == "unknown")
            print(f"  {i}/{len(pending)}  ok={ok} missing={miss} unknown={unk}")
        time.sleep(DELAY)

    OUT.write_text(json.dumps(cache), encoding="utf-8")
    ok = [k for k, v in cache.items() if v.get("status") == "ok"]
    miss = [k for k, v in cache.items() if v.get("status") == "missing"]
    unk = [k for k, v in cache.items() if v.get("status") == "unknown"]
    empty_tip = [k for k, v in cache.items() if v.get("status") == "ok" and not v.get("tip")]
    print(f"done ok={len(ok)} missing={len(miss)} unknown={len(unk)} ok-without-tip={len(empty_tip)}")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
