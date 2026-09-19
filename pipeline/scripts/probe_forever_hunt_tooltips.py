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


def plain(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"<br\s*/?>", "\n", text, flags=re.I)
    text = re.sub(r"</(?:div|tr|p|li|h\d)>", "\n", text, flags=re.I)
    text = html.unescape(TAG.sub("", text))
    text = text.replace("\xa0", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


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
