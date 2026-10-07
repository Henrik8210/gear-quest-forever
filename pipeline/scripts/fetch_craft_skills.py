"""Fill CraftSkills.generated.lua from ForeverDB recipe shards.

https://foreverdb.net/data/crafting/{itemId % 64}.json
Each row is made: [[profession, spellId, skill, name, count], ...]

Reagents come from the Wowhead Forever spell tooltip
(https://nether.wowhead.com/forever/tooltip/spell/{spellId}).
Run `python pipeline/scripts/fetch_craft_skills.py --reagents` to fill them
without re-downloading the crafting shards.
"""
import html
import json
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEN = ROOT / "GearQuest" / "_generated"
CACHE = ROOT / "pipeline" / "data" / "forever_wowhead" / "craft_skills.json"
OUT = GEN / "CraftSkills.generated.lua"
UA = "wow-classic-data-research/1.0"

ITEM_RE = re.compile(
    r'\[(\d+)\]=\{[^\n]*sourceType="profession"[^\n]*profession="([^"]+)"'
)

SLUGS = {
    "alchemy": "Alchemy",
    "blacksmithing": "Blacksmithing",
    "cooking": "Cooking",
    "enchanting": "Enchanting",
    "engineering": "Engineering",
    "firstaid": "First Aid",
    "first-aid": "First Aid",
    "fishing": "Fishing",
    "herbalism": "Herbalism",
    "leatherworking": "Leatherworking",
    "mining": "Mining",
    "skinning": "Skinning",
    "tailoring": "Tailoring",
}


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=40) as resp:
        return json.load(resp)


def load_hunts():
    items = {}
    for path in GEN.glob("Data.*.generated.lua"):
        text = path.read_text(encoding="latin-1")
        for match in ITEM_RE.finditer(text):
            items.setdefault(int(match.group(1)), match.group(2))
    return items


def pick(made, profession):
    rows = []
    for entry in made or []:
        if len(entry) < 3:
            continue
        slug, spell_id, skill = entry[0], entry[1], entry[2]
        if not isinstance(skill, int) or skill <= 0:
            continue
        name = SLUGS.get(slug, profession)
        rows.append((name, int(skill), int(spell_id), slug))
    if not rows:
        return None
    wanted = (profession or "").lower().replace(" ", "")
    matched = [row for row in rows if row[3].replace("-", "") == wanted or row[0].lower() == (profession or "").lower()]
    pool = matched or rows
    pool.sort(key=lambda row: row[1])
    name, skill, spell_id, _slug = pool[0]
    return {"profession": profession or name, "skill": skill, "spellId": spell_id}


def main():
ROW_RE = re.compile(
    r'^GQ\.CraftSkills\[(\d+)\] = \{ profession = "((?:\\.|[^"\\])*)", skill = (\d+), spellId = (\d+)'
)
REAGENT_BLOCK_RE = re.compile(
    r"Reagents?:(?:<br\s*/?>)+\s*<div class=\"indent[^\"]*\">(.*?)</div>",
    re.I | re.S,
)
OPTIONAL_BLOCK_RE = re.compile(
    r"Optional Reagents?:(?:<br\s*/?>)+\s*<div class=\"indent[^\"]*\">(.*?)</div>",
    re.I | re.S,
)
ITEM_RE = re.compile(
    r"item=(\d+)/[^\"]*\">([^<]+)</a>(?:&nbsp;|\s)*(?:\((\d+)\))?"
)


def lua_escape(text):
    return (text or "").replace("\\", "\\\\").replace('"', '\\"')


def reagent_lua(rows):
    if not rows:
        return ""
    parts = []
    for item_id, count, name in rows:
        parts.append('{%d,%d,"%s"}' % (int(item_id), int(count), lua_escape(name)))
    return "{" + ",".join(parts) + "}"


def format_row(item_id, row, reagents=None):
    prof = lua_escape(row["profession"])
    line = 'GQ.CraftSkills[%d] = { profession = "%s", skill = %d, spellId = %d' % (
        item_id,
        prof,
        row["skill"],
        row["spellId"],
    )
    if reagents:
        required = reagents.get("reagents") or []
        optional = reagents.get("optional") or []
        if required:
            line += ", reagents = " + reagent_lua(required)
        if optional:
            line += ", optional = " + reagent_lua(optional)
    line += " }"
    return line


def load_reagent_cache():
    if not REAGENT_CACHE.exists():
        return {}
    return json.loads(REAGENT_CACHE.read_text(encoding="utf-8"))


def parse_reagent_block(block):
    rows = []
    for item_id, name, count in ITEM_RE.findall(block or ""):
        name = html.unescape(name).replace("\xa0", " ").strip()
        if not name:
            continue
        rows.append([int(item_id), int(count) if count else 1, name])
    return rows


def parse_spell_reagents(tooltip):
    if not tooltip:
        return {"reagents": [], "optional": []}
    required = REAGENT_BLOCK_RE.search(tooltip)
    optional = OPTIONAL_BLOCK_RE.search(tooltip)
    return {
        "reagents": parse_reagent_block(required.group(1) if required else ""),
        "optional": parse_reagent_block(optional.group(1) if optional else ""),
    }


def fetch_spell_reagents(spell_id):
    url = "https://nether.wowhead.com/forever/tooltip/spell/%d" % spell_id
    last_error = "error"
    for _attempt in range(3):
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.load(resp)
            return spell_id, parse_spell_reagents(data.get("tooltip") or "")
        except Exception as exc:
            last_error = type(exc).__name__
    return spell_id, {"error": last_error}


def load_existing_rows():
    rows = {}
    for line in OUT.read_text(encoding="utf-8").splitlines():
        match = ROW_RE.match(line)
        if not match:
            continue
        item_id = int(match.group(1))
        profession = match.group(2).replace('\\"', '"').replace("\\\\", "\\")
        rows[item_id] = {
            "profession": profession,
            "skill": int(match.group(3)),
            "spellId": int(match.group(4)),
        }
    return rows


def write_craft_skills(rows, missing=None):
    reagents = load_reagent_cache()
    lines = [
        "-- AUTO-GENERATED by pipeline/scripts/fetch_craft_skills.py — do not edit.",
        "-- Source: ForeverDB crafting shards (recipe skill from the Forever client).",
        "-- Reagents: Wowhead Forever spell tooltips.",
        "",
        "local _, GQ = ...",
        "GQ.CraftSkills = GQ.CraftSkills or {}",
        "",
    ]
    with_reagents = 0
    for item_id in sorted(rows):
        row = rows[item_id]
        known = reagents.get(str(row["spellId"]))
        if known and known.get("reagents"):
            with_reagents += 1
        lines.append(format_row(item_id, row, known))
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(
        "Wrote %s (%d items, %d with reagents)"
        % (OUT, len(rows), with_reagents),
        flush=True,
    )
    if missing:
        print("missing", " ".join(str(n) for n in missing[:40]), flush=True)


def fill_reagents():
    rows = load_existing_rows()
    cache = load_reagent_cache()
    spells = sorted({row["spellId"] for row in rows.values()})
    pending = [spell_id for spell_id in spells if str(spell_id) not in cache]
    print("spells %d cached %d to fetch %d" % (len(spells), len(spells) - len(pending), len(pending)), flush=True)
    done = 0
    errors = 0
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = [pool.submit(fetch_spell_reagents, spell_id) for spell_id in pending]
        for future in as_completed(futures):
            spell_id, result = future.result()
            done += 1
            if result.get("error"):
                errors += 1
            else:
                cache[str(spell_id)] = result
            if done % 50 == 0 or done == len(pending):
                REAGENT_CACHE.parent.mkdir(parents=True, exist_ok=True)
                REAGENT_CACHE.write_text(json.dumps(cache), encoding="utf-8")
                print("fetched %d/%d errors %d" % (done, len(pending), errors), flush=True)
    REAGENT_CACHE.write_text(json.dumps(cache), encoding="utf-8")
    write_craft_skills(rows)
    empty = sum(1 for row in rows.values() if not (cache.get(str(row["spellId"])) or {}).get("reagents"))
    print("no reagents %d" % empty, flush=True)


    hunts = load_hunts()
    shards = {}
    for shard in range(64):
        data = fetch_json(f"https://foreverdb.net/data/crafting/{shard}.json")
        shards[shard] = data
        print(f"shard {shard} {len(data)}", flush=True)

    rows = {}
    missing = []
    for item_id, profession in hunts.items():
        row = pick((shards[item_id % 64].get(str(item_id)) or {}).get("made"), profession)
        if row:
            rows[item_id] = row
        else:
            missing.append(item_id)

    CACHE.write_text(json.dumps({str(k): v for k, v in rows.items()}), encoding="utf-8")
    lines = [
    write_craft_skills(rows, missing)


if __name__ == "__main__":
    if "--reagents" in sys.argv:
        fill_reagents()
    else:
        main()