"""Pull the Wowhead Forever level-60 BiS pages into pipeline/guides/forever_bis.json.

Only pages whose final URL stays on /forever/ and whose title says WoW: Forever.
A retail redirect (feral, guardian) is not a Forever list and is left out.
The scorer reads this file at level 60. Classic guides_*.json stay unused.

An id on a page whose Forever tooltip (dataEnv=16) is a 404 is left out and
written to pipeline/guides/forever_bis_skipped.json. The next import reads
that list and asks Wowhead again.
"""
from __future__ import annotations

import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import DATA, GUIDES_DIR, ADDON_GEN, forever_beta_copy_ids

UA = "GearQuestForever-data/1.0"
BASE = "https://www.wowhead.com/forever/guide/classes/%s/bis-gear"

# Addon spec key, Wowhead slug. Specs with no Forever page are omitted on purpose
# (feral, battle mage, shockadin, enhancement tank) so level 60 stays scored.
PAGES = [
    ("MAGE", "arcane", "mage/arcane"),
    ("MAGE", "fire", "mage/fire"),
    ("MAGE", "frost", "mage/frost"),
    ("PRIEST", "discipline", "priest/discipline"),
    ("PRIEST", "holy", "priest/holy"),
    ("PRIEST", "shadow", "priest/shadow"),
    ("WARLOCK", "affliction", "warlock/affliction"),
    ("WARLOCK", "demonology", "warlock/demonology"),
    ("WARLOCK", "destruction", "warlock/destruction"),
    ("DRUID", "balance", "druid/balance"),
    ("DRUID", "restoration", "druid/restoration"),
    ("HUNTER", "beast_mastery", "hunter/beast-mastery"),
    ("HUNTER", "marksmanship", "hunter/marksmanship"),
    ("HUNTER", "survival", "hunter/survival"),
    ("ROGUE", "assassination", "rogue/assassination"),
    ("ROGUE", "combat", "rogue/combat"),
    ("ROGUE", "subtlety", "rogue/subtlety"),
    ("SHAMAN", "elemental", "shaman/elemental"),
    ("SHAMAN", "enhancement", "shaman/enhancement"),
    ("SHAMAN", "restoration", "shaman/restoration"),
    ("WARRIOR", "arms", "warrior/arms"),
    ("WARRIOR", "fury", "warrior/fury"),
    ("WARRIOR", "protection", "warrior/protection"),
    ("PALADIN", "holy", "paladin/holy"),
    ("PALADIN", "protection", "paladin/protection"),
    ("PALADIN", "retribution", "paladin/retribution"),
]

# Longest name wins, so "ranged weapons" is not the generic Weapons slot
# and "offhand" is not Hands.
SLOT_NAMES = [
    ("one-handed weapons", "MainHand"),
    ("two-handed weapons", "MainHand"),
    ("one-handed weapon", "MainHand"),
    ("two-handed weapon", "MainHand"),
    ("held in off-hand", "SecondaryHand"),
    ("ranged weapons", "Ranged"),
    ("ranged weapon", "Ranged"),
    ("ranged", "Ranged"),
    ("off-hand", "SecondaryHand"),
    ("off hand", "SecondaryHand"),
    ("main hand", "MainHand"),
    ("main-hand", "MainHand"),
    ("one-handed", "MainHand"),
    ("two-handed", "MainHand"),
    ("shoulders", "Shoulder"),
    ("shoulder", "Shoulder"),
    ("trinkets", "Trinket"),
    ("trinket", "Trinket"),
    ("offhands", "SecondaryHand"),
    ("offhand", "SecondaryHand"),
    ("shields", "SecondaryHand"),
    ("shield", "SecondaryHand"),
    ("weapons", "MainHand"),
    ("librams", "Ranged"),
    ("libram", "Ranged"),
    ("relics", "Ranged"),
    ("relic", "Ranged"),
    ("totems", "Ranged"),
    ("totem", "Ranged"),
    ("idols", "Ranged"),
    ("idol", "Ranged"),
    ("wands", "Ranged"),
    ("wand", "Ranged"),
    ("thrown", "Ranged"),
    ("crossbow", "Ranged"),
    ("crossbows", "Ranged"),
    ("rings", "Finger"),
    ("ring", "Finger"),
    ("finger", "Finger"),
    ("bracers", "Wrist"),
    ("wrists", "Wrist"),
    ("wrist", "Wrist"),
    ("gloves", "Hands"),
    ("hands", "Hands"),
    ("boots", "Feet"),
    ("chest", "Chest"),
    ("cloak", "Back"),
    ("back", "Back"),
    ("waist", "Waist"),
    ("belt", "Waist"),
    ("head", "Head"),
    ("neck", "Neck"),
    ("legs", "Legs"),
    ("feet", "Feet"),
    ("guns", "Ranged"),
    ("gun", "Ranged"),
    ("bows", "Ranged"),
    ("bow", "Ranged"),
    ("hand", "Hands"),
    ("leg", "Legs"),
]
SLOT_NAMES.sort(key=lambda pair: len(pair[0]), reverse=True)

TIER = re.compile(r"(?:\[td\]|<td[^>]*>)\s*(BiS|Great|Good|Option)\s*(?:\[/td\]|</td>)", re.I)
ITEM_BB = re.compile(r"\[item=(\d+)")
ITEM_HREF = re.compile(r"item=(\d+)")
ROW_BB = re.compile(r"\[tr\](.*?)\[/tr\]", re.S | re.I)
ROW_HTML = re.compile(r"<tr\b[^>]*>(.*?)</tr>", re.S | re.I)
H3 = re.compile(r"\[h3\b([^\]]*)\](.*?)(?=\[h3\b|\[/guide\]|\Z)", re.S | re.I)
TOC = re.compile(r'toc="([^"]+)"', re.I)
TEST_IDS = {280304, 24358, 19503, 19504}


def slot_of(toc: str):
    key = re.sub(r"\s+", " ", (toc or "").strip().lower())
    key = key.replace("–", "-").replace("—", "-")
    for name, slot in SLOT_NAMES:
        if key == name or key.endswith(" " + name) or key.endswith("- " + name):
            return slot
    return None


def banned_ids():
    out = set(TEST_IDS)
    out |= set(forever_beta_copy_ids())
    for name in ("forever_absent.json", "client_missing.json"):
        path = os.path.join(DATA, name)
        if not os.path.exists(path):
            continue
        raw = json.load(open(path, encoding="utf-8"))
        if isinstance(raw, dict):
            out |= {int(k) for k in raw if str(k).isdigit()}
        elif isinstance(raw, list):
            out |= {int(x) for x in raw}
    return out


def fetch(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=40) as resp:
        body = resp.read().decode("utf-8", "replace")
        return resp.geturl(), body


def markup(page: str) -> str:
    text = html.unescape(page)
    text = text.replace("\\/", "/")
    text = text.replace("\\[", "[").replace("\\]", "]")
    text = text.replace('\\"', '"')
    return text


CELL_BB = re.compile(r"\[td(?:\s[^\]]*)?\](.*?)\[/td\]", re.S | re.I)
CELL_HTML = re.compile(r"<td\b[^>]*>(.*?)</td>", re.S | re.I)


def rows_in(section: str):
    """The item column only. The source column lists reagents as item links."""
    rows = ROW_BB.findall(section)
    cell = CELL_BB
    if not rows:
        rows = ROW_HTML.findall(section)
        cell = CELL_HTML
    found = []
    for row in rows:
        cells = cell.findall(row)
        label = re.sub(r"\s+", " ", cells[0]).strip() if cells else ""
        if len(cells) < 2 or label not in ("BiS", "Great", "Good", "Option"):
            continue
        ids = [int(n) for n in ITEM_BB.findall(cells[1])]
        if not ids:
            ids = [int(n) for n in ITEM_HREF.findall(cells[1])]
        for iid in ids:
            found.append(iid)
    return found


def parse_page(page: str):
    text = markup(page)
    slots = {}
    unknown = []
    order = []
    for attrs, body in H3.findall(text):
        toc_m = TOC.search(attrs)
        toc = toc_m.group(1) if toc_m else ""
        slot = slot_of(toc)
        ids = rows_in(body)
        if slot is None:
            if ids:
                unknown.append(toc or attrs[:40])
            continue
        if slot not in slots:
            slots[slot] = []
            order.append(slot)
        slots[slot].extend(ids)
    for slot in slots:
        seen = set()
        kept = []
        for iid in slots[slot]:
            if iid in seen:
                continue
            seen.add(iid)
            kept.append(iid)
        slots[slot] = kept
    return slots, unknown


def write_lua(tree: dict):
    lines = [
        "local _, GQ = ...",
        "GQ.Data = GQ.Data or {}",
        "",
        "-- Level 60 (i) link. Specs with no Forever page are absent, so the scored list stays.",
        "GQ.Data.ForeverBisUrl = {",
    ]
    for cls in (
        "MAGE", "PRIEST", "WARLOCK", "DRUID", "HUNTER",
        "ROGUE", "SHAMAN", "WARRIOR", "PALADIN",
    ):
        specs = tree.get(cls) or {}
        filled = [(spec, page) for spec, page in specs.items() if page.get("slots")]
        if not filled:
            continue
        lines.append(f"    {cls} = {{")
        for spec, page in filled:
            url = page["url"].replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'        {spec} = "{url}",')
        lines.append("    },")
    lines.append("}")
    lines.append("")
    path = os.path.join(ADDON_GEN, "Data.ForeverBis.generated.lua")
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines))
    print("wrote", path)


_TIP_404 = {}


def tooltip_missing(iid: int) -> bool:
    """A dataEnv=16 404 is not a Forever item. Do not put it on a hunt."""
    if iid in _TIP_404:
        return _TIP_404[iid]
    url = f"https://nether.wowhead.com/tooltip/item/{iid}?dataEnv=16"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            missing = resp.status == 404
    except urllib.error.HTTPError as err:
        missing = err.code == 404
    except Exception:
        missing = False
    _TIP_404[iid] = missing
    return missing


def main():
    skip = banned_ids()
    items = json.load(open(os.path.join(DATA, "items.json"), encoding="utf-8"))
    known = {int(k) for k in items}
    tree = {}
    missing = []
    skipped = []
    tooltip_404 = []
    for cls, spec, slug in PAGES:
        url = BASE % slug
        final, page = fetch(url)
        title_m = re.search(r"<title>(.*?)</title>", page, re.I | re.S)
        title = html.unescape(title_m.group(1)) if title_m else ""
        if "/forever/" not in final or "WoW: Forever" not in title:
            print(f"SKIP {cls} {spec} -> {final} | {title[:80]}")
            continue
        slots, unknown = parse_page(page)
        clean = {}
        for slot, ids in slots.items():
            kept = []
            for iid in ids:
                if iid in skip:
                    skipped.append((cls, spec, slot, iid))
                    continue
                if iid not in known and tooltip_missing(iid):
                    tooltip_404.append((cls, spec, slot, iid))
                    continue
                kept.append(iid)
                if iid not in known:
                    missing.append(iid)
            if kept:
                clean[slot] = kept
        count = sum(len(v) for v in clean.values())
        print(f"{cls} {spec}: {count} items, slots {', '.join(clean) or '-'}")
        if unknown:
            print("  unknown headings:", ", ".join(unknown))
        if count == 0:
            at = markup(page).find("BiS")
            print("  no rows; snippet:", markup(page)[max(0, at - 80):at + 180].replace("\n", " ")[:240])
        tree.setdefault(cls, {})[spec] = {"url": url, "slots": clean}
        time.sleep(0.4)

    out = os.path.join(GUIDES_DIR, "forever_bis.json")
    with open(out, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(tree, handle, indent=2)
        handle.write("\n")
    uniq = sorted(set(missing))
    miss_path = os.path.join(GUIDES_DIR, "forever_bis_missing.json")
    with open(miss_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(uniq, handle)
        handle.write("\n")
    # Ids the page names that Forever's own tooltip does not have yet.
    # The next run of this script probes each one again.
    skipped_note = {
        "note": (
            "These ids are on a Wowhead Forever BiS page, but "
            "https://nether.wowhead.com/tooltip/item/{id}?dataEnv=16 returned 404, "
            "so they were not indexed. Recheck them on the next import. "
            "When the tooltip exists, index the item with the same source, "
            "quest chain, and description as any other hunt, then put it back "
            "on the level-60 list."
        ),
        "checked": "2026-11-22",
        "items": [
            {
                "id": iid,
                "class": cls,
                "spec": spec,
                "slot": slot,
                "reason": "Forever tooltip dataEnv=16 returned 404",
            }
            for cls, spec, slot, iid in tooltip_404
        ],
    }
    skip_path = os.path.join(GUIDES_DIR, "forever_bis_skipped.json")
    with open(skip_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(skipped_note, handle, indent=2)
        handle.write("\n")
    write_lua(tree)
    print(
        f"pages {sum(len(v) for v in tree.values())} missing {len(uniq)} "
        f"tooltip-404 {len(tooltip_404)} skipped-banned {len(skipped)}"
    )
    if tooltip_404:
        print("tooltip 404, left for the next import:", ", ".join(str(row[3]) for row in tooltip_404))
    if skipped:
        print("banned left out:", ", ".join(str(row[3]) for row in skipped[:40]))


if __name__ == "__main__":
    main()
