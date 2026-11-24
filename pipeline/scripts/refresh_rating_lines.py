"""Replace stored "rating by N" lines with the live Forever tooltip.

Forever prints "by 1%". The number we stored (14 crit, 10 hit, 12 dodge) is
the old rating scale. A line the live tooltip no longer has is removed, and
so is the rating number that went with it. A 404 is not in Forever: the
rating sentence and its number come off, and the rest of the row stays.

One request at a time. Cache: pipeline/data/forever_wowhead/rating_refresh_cache.json
Resume-safe. Does not rewrite items.json until every id has been fetched.
"""
from __future__ import annotations

import json
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ITEMS = ROOT / "pipeline" / "data" / "items.json"
CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "rating_refresh_cache.json"
URL = "https://nether.wowhead.com/tooltip/item/{}?dataEnv=16"
UA = "GearQuestForever-data/1.0"
DELAY = 0.28

TAG = re.compile(r"<[^>]+>")
RATING_WORD = re.compile(r"\brating\b", re.I)
RATING_NUM = re.compile(r"rating by (\d+)", re.I)
SPAN = re.compile(
    r'<span[^>]*class="q2"[^>]*>((?:Equip|Use|Chance on hit):.*?)</span>',
    re.S,
)
PASSIVE = (
    ("hit", re.compile(r"improves your chance to hit(?: with ranged weapons)? by ([\d.]+)%", re.I)),
    ("crit", re.compile(r"improves your chance to get a critical strike(?: with [a-z ,]+)? by ([\d.]+)%", re.I)),
    ("dodge", re.compile(r"increases your chance to dodge an attack by ([\d.]+)%", re.I)),
    ("parry", re.compile(r"increases your chance to parry an attack by ([\d.]+)%", re.I)),
    ("haste", re.compile(r"increases your attack speed and casting speed by ([\d.]+)%", re.I)),
    ("blockRating", re.compile(r"increases your chance to block attacks with a shield by ([\d.]+)%", re.I)),
    ("expertise", re.compile(r"reduces chance to be dodged or parried by ([\d.]+)%", re.I)),
    ("defense", re.compile(r"increased defense \+(\d+)", re.I)),
)
FOLD = {
    "spellHit": "hit",
    "hitRanged": "hit",
    "spellCrit": "crit",
    "critRanged": "crit",
    "spellHaste": "haste",
}


def plain(html: str) -> str:
    text = TAG.sub(" ", html or "")
    text = text.replace("&nbsp;", " ").replace("&#160;", " ")
    return re.sub(r"\s+", " ", text).strip()


def rating_key(line: str):
    low = line.lower()
    if "spell hit" in low or "hit rating" in low:
        return "spellHit" if "spell hit" in low else "hit"
    if "spell critical" in low or "spell crit" in low:
        return "spellCrit"
    if "ranged critical" in low:
        return "critRanged"
    if "critical strike" in low or "crit rating" in low:
        return "crit"
    if "spell haste" in low:
        return "spellHaste"
    if "haste" in low:
        return "haste"
    if "dodge" in low:
        return "dodge"
    if "parry" in low:
        return "parry"
    if "expertise" in low:
        return "expertise"
    if "block" in low:
        return "blockRating"
    if "defense" in low:
        return "defense"
    if "resilience" in low:
        return "resilience"
    return None


def fetch(iid: int):
    delay = 2.0
    last = "error"
    for attempt in range(6):
        req = urllib.request.Request(URL.format(iid), headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            tip = data.get("tooltip") or ""
            lines = []
            for match in SPAN.finditer(tip):
                line = plain(match.group(1))
                if line:
                    lines.append(line[:400])
            return {"lines": lines}
        except urllib.error.HTTPError as err:
            last = f"http {err.code}"
            if err.code == 404:
                return {"error": "404"}
            if err.code in (403, 429) and attempt < 5:
                time.sleep(delay)
                delay = min(delay * 2, 60)
                continue
            return {"error": last}
        except Exception as err:
            last = str(err)
            if attempt < 2:
                time.sleep(delay)
                continue
            return {"error": last}
    return {"error": last}


def num(value: float):
    if abs(value - round(value)) < 1e-6:
        return int(round(value))
    return value


def apply(item: dict, row: dict) -> bool:
    effects = list(item.get("effects") or [])
    stats = dict(item.get("stats") or {})
    changed = False
    kept = []
    for line in effects:
        if not RATING_WORD.search(line):
            kept.append(line)
            continue
        changed = True
        key = rating_key(line)
        match = RATING_NUM.search(line)
        if key and match:
            left = (stats.get(key) or 0) - int(match.group(1))
            if left > 0:
                stats[key] = left
            else:
                stats.pop(key, None)
    if not changed:
        return False
    live = row.get("lines") or []
    have = {line.lower() for line in kept}
    percents = {}
    for line in live:
        low = line.lower()
        if low.startswith("equip:"):
            for key, rx in PASSIVE:
                match = rx.search(line)
                if match:
                    percents[key] = percents.get(key, 0) + float(match.group(1))
                    break
        if low in have:
            continue
        if RATING_WORD.search(line):
            kept.append(line)
            have.add(low)
            continue
        # Bring back the line that replaced a rating sentence.
        if any(rx.search(line) for _key, rx in PASSIVE) or low.startswith(("equip:", "use:", "chance on hit:")):
            # Only the lines that name a combat stat we just removed, or a percent.
            interesting = any(rx.search(line) for _key, rx in PASSIVE) or any(
                word in low for word in ("hit", "critical", "dodge", "parry", "haste", "defense", "block", "expertise")
            )
            if not interesting:
                continue
            kept.append(line)
            have.add(low)
    for key, pct in percents.items():
        stats[key] = num(pct)
        for src, dst in FOLD.items():
            if dst == key and src in stats:
                stats.pop(src, None)
    item["effects"] = kept
    item["stats"] = stats
    return True


def main():
    raw = json.loads(ITEMS.read_text(encoding="utf-8"))
    items = raw if isinstance(raw, list) else raw
    cache = {}
    if CACHE.exists():
        cache = json.loads(CACHE.read_text(encoding="utf-8"))
    todo = []
    for key, item in (items.items() if isinstance(items, dict) else enumerate(items)):
        if not isinstance(item, dict):
            continue
        if any(RATING_WORD.search(line) for line in (item.get("effects") or [])):
            todo.append(str(item.get("id") or key))
    print("rating items", len(todo), "cached", sum(1 for iid in todo if iid in cache), flush=True)
    fetched = 0
    for index, iid in enumerate(todo):
        if iid in cache:
            continue
        cache[iid] = fetch(int(iid))
        fetched += 1
        if fetched % 25 == 0:
            CACHE.write_text(json.dumps(cache), encoding="utf-8")
            print("fetched", fetched, "of", len(todo) - (len(todo) - index), "last", iid, cache[iid].get("error") or "ok", flush=True)
        time.sleep(DELAY)
    CACHE.write_text(json.dumps(cache), encoding="utf-8")
    changed = 0
    still = 0
    missing = 0
    for key, item in (items.items() if isinstance(items, dict) else enumerate(items)):
        if not isinstance(item, dict):
            continue
        iid = str(item.get("id") or key)
        row = cache.get(iid)
        if not row:
            continue
        if row.get("error") == "404":
            missing += 1
        if apply(item, row):
            changed += 1
            if any(RATING_WORD.search(line) for line in (item.get("effects") or [])):
                still += 1
    print("changed", changed, "still rating", still, "404", missing, flush=True)
    text = json.dumps(raw, ensure_ascii=False, separators=(",", ":"))
    tmp = ITEMS.with_suffix(".json.new")
    tmp.write_text(text, encoding="utf-8")
    tmp.replace(ITEMS)
    print("wrote", ITEMS, flush=True)


if __name__ == "__main__":
    main()
