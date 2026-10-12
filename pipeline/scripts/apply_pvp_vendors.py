"""Point Forever PvP gear at the vendor, level, and rank Wowhead lists.

Sergeant's Cloak was stored as First Sergeant Hola'mahi and "costs tokens or
reputation." On Forever it is bought from Sergeant Ba'sha. The Alliance cape
is Officer Areyn. Premier pieces are included. A stated Requires Level above
1 replaces the stored level. The rank line is the tooltip "Requires ... (Rank
N)" when Wowhead prints one, otherwise the rank title in the item name.

  python pipeline/scripts/apply_pvp_vendors.py
"""
from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

os.chdir(Path(__file__).resolve().parents[1])
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gq_paths import DATA

ITEMS = Path(DATA) / "items.json"
SOURCES = Path(DATA) / "sources.json"
NPC_FACTION = Path(DATA) / "npc_faction.json"
CACHE = Path(DATA) / "forever_wowhead" / "pvp_vendor_cache.json"
UA = "GearQuestForever-data/1.0"
DELAY = float(os.environ.get("GQ_PVP_DELAY", "0.8"))

# Longest title first. The number is the Forever rank the title is.
RANK_TITLES = [
    ("Lieutenant Commander's", "Lieutenant Commander (Rank 10)"),
    ("Lieutenant General's", "Lieutenant General (Rank 11)"),
    ("Knight-Lieutenant's", "Knight-Lieutenant (Rank 7)"),
    ("Knight-Captain's", "Knight-Captain (Rank 8)"),
    ("Knight-Champion's", "Knight-Champion (Rank 9)"),
    ("Senior Sergeant's", "Senior Sergeant (Rank 4)"),
    ("Master Sergeant's", "Master Sergeant (Rank 4)"),
    ("Sergeant Major's", "Sergeant Major (Rank 5)"),
    ("First Sergeant's", "First Sergeant (Rank 5)"),
    ("Field Marshal's", "Field Marshal (Rank 13)"),
    ("Grand Marshal's", "Grand Marshal (Rank 14)"),
    ("Stone Guard's", "Stone Guard (Rank 6)"),
    ("High Warlord's", "High Warlord (Rank 14)"),
    ("Blood Guard's", "Blood Guard (Rank 7)"),
    ("Legionnaire's", "Legionnaire (Rank 8)"),
    ("Centurion's", "Centurion (Rank 9)"),
    ("Champion's", "Champion (Rank 10)"),
    ("Warlord's", "Warlord (Rank 13)"),
    ("Marshal's", "Marshal (Rank 12)"),
    ("Commander's", "Commander (Rank 11)"),
    ("General's", "General (Rank 12)"),
    ("Private's", "Private (Rank 1)"),
    ("Corporal's", "Corporal (Rank 2)"),
    ("Sergeant's", "Sergeant (Rank 3)"),
    ("Knight's", "Knight (Rank 6)"),
    ("Scout's", "Scout (Rank 1)"),
    ("Grunt's", "Grunt (Rank 2)"),
]

# Wowhead area ids seen on these vendors. Unknown ids are looked up once.
ZONES = {
    1519: "Stormwind City",
    1637: "Orgrimmar",
    1497: "Undercity",
    1537: "Ironforge",
    1638: "Thunder Bluff",
    1657: "Darnassus",
    2597: "Alterac Valley",
    3358: "Arathi Basin",
    3277: "Warsong Gulch",
    2677: "Blackrock Spire",
}

# Quartermasters already known to sell rank gear. A vendor Wowhead shows with
# at least three rank-named pieces is added to this set at apply time.
SEED_VENDORS = {
    "Brave Stonehide",
    "Blood Guard Porung",
    "Captain Dirgehammer",
    "Captain O'Neal",
    "Doris Volanthius",
    "First Sergeant Hola'mahi",
    "Gaelden Hammersmith",
    "Grunnda Wolfheart",
    "Illiyana Moonblaze",
    "Jekyll Flandring",
    "Kayri",
    "Kelm Hargunth",
    "Lady Palanseer",
    "Lieutenant Jackspring",
    "Lieutenant Tristia",
    "Master Sergeant Biggins",
    "Officer Areyn",
    "Rutherford Twing",
    "Samuel Hawke",
    "Sergeant Ba'sha",
    "Sergeant Major Clate",
    "Sergeant Thunderhorn",
    "Stone Guard Zarg",
    "Thanthaldis Snowgleam",
}

RANK_RE = re.compile(r"Requires ([^<]{1,80}?\(Rank \d+\))")
JSON_RE = re.compile(r"<json><!\[CDATA\[(.*?)\]\]></json>", re.S)


def fetch(url: str) -> str:
    delay = 15.0
    last = "fetch failed"
    for attempt in range(8):
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                return resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            last = f"http {e.code}"
            if e.code == 404:
                return ""
            if e.code in (403, 429) and attempt < 7:
                print(f"  {last} on {url} waiting {delay:.0f}s", flush=True)
                time.sleep(delay)
                delay = min(delay * 2, 90)
                continue
            raise
        except Exception as e:
            last = str(e)
            if attempt < 7:
                time.sleep(delay)
                delay = min(delay * 2, 45)
                continue
            raise RuntimeError(last)
    raise RuntimeError(last)


def _array_at(html: str, start: int):
    depth = 0
    in_str = False
    esc = False
    for i in range(start, min(len(html), start + 2_000_000)):
        ch = html[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(html[start : i + 1])
                except json.JSONDecodeError:
                    return None
    return None


def absorb_npc(npc_id: int, npc_name: str, cache: dict) -> None:
    """One quartermaster page lists every item they sell. Fill those rows."""
    stock = cache.setdefault("npcStock", {})
    key = str(npc_id)
    if key in stock:
        return
    time.sleep(DELAY)
    html = fetch(f"https://www.wowhead.com/forever/npc={npc_id}")
    if not html:
        return
    at = html.find("id: 'sells'")
    rows = None
    if at >= 0:
        data_at = html.find("data:", at)
        start = html.find("[", data_at) if data_at >= 0 else -1
        if start >= 0:
            rows = _array_at(html, start)
    if not isinstance(rows, list):
        return
    stock[key] = len(rows)
    for row in rows:
        if not isinstance(row, dict) or not row.get("id"):
            continue
        iid = str(row["id"])
        if iid in cache["xml"]:
            continue
        sellers = []
        for seller in row.get("sourcemore") or []:
            if isinstance(seller, dict) and seller.get("n") and seller.get("ti"):
                sellers.append(
                    {
                        "name": seller["n"],
                        "id": int(seller["ti"]),
                        "zone": int(seller["z"]) if seller.get("z") else None,
                    }
                )
        if not sellers:
            sellers = [{"name": npc_name, "id": npc_id, "zone": None}]
        side = row.get("side") if row.get("side") in (1, 2) else None
        req = int(row["reqlevel"]) if row.get("reqlevel") else None
        cache["xml"][iid] = {"req": req, "sellers": sellers, "side": side, "ok": True}
    save_cache(cache)
    print(f"  vendor {npc_name} sells {len(rows)}", flush=True)


def rank_from_name(name: str) -> str | None:
    bare = name[8:] if name.startswith("Premier ") else name
    for prefix, label in RANK_TITLES:
        if bare.startswith(prefix):
            return label
    if name.startswith("Insignia of the Horde"):
        return "Grunt (Rank 2)"
    if name.startswith("Insignia of the Alliance"):
        return "Corporal (Rank 2)"
    return None


def is_rank_named(name: str) -> bool:
    return rank_from_name(name) is not None or name.startswith("Premier ")


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {"xml": {}, "tip": {}, "zone": {}}


def save_cache(cache: dict) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(cache), encoding="utf-8")


def xml_fact(iid: int, cache: dict) -> dict:
    key = str(iid)
    if key in cache["xml"]:
        return cache["xml"][key]
    time.sleep(DELAY)
    body = fetch(f"https://www.wowhead.com/forever/item={iid}&xml")
    fact = {"req": None, "sellers": [], "side": None, "ok": bool(body)}
    if not body:
        return fact
    for block in JSON_RE.findall(body):
        text = block.strip()
        if text and not text.startswith("{") and not text.startswith("["):
            text = "{" + text + "}"
        try:
            row = json.loads(text)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict):
            continue
        if row.get("reqlevel") and not fact["req"]:
            fact["req"] = int(row["reqlevel"])
        if row.get("side") in (1, 2) and not fact["side"]:
            fact["side"] = int(row["side"])
        for seller in row.get("sourcemore") or []:
            if not isinstance(seller, dict):
                continue
            if seller.get("n") and seller.get("ti"):
                fact["sellers"].append(
                    {
                        "name": seller["n"],
                        "id": int(seller["ti"]),
                        "zone": int(seller["z"]) if seller.get("z") else None,
                    }
                )
    cache["xml"][key] = fact
    for seller in fact["sellers"]:
        absorb_npc(seller["id"], seller["name"], cache)
    return fact


def tip_rank(iid: int, cache: dict) -> str | None:
    key = str(iid)
    if key in cache["tip"]:
        return cache["tip"][key] or None
    time.sleep(DELAY)
    body = fetch(f"https://nether.wowhead.com/tooltip/item/{iid}?dataEnv=16")
    found = None
    if body:
        match = RANK_RE.search(body)
        if match:
            found = match.group(1).replace("\\/", "/")
    cache["tip"][key] = found or ""
    return found


def zone_name(zone_id: int, cache: dict) -> str | None:
    if zone_id in ZONES:
        return ZONES[zone_id]
    key = str(zone_id)
    if key in cache["zone"]:
        return cache["zone"][key] or None
    time.sleep(DELAY)
    body = fetch(f"https://nether.wowhead.com/tooltip/zone/{zone_id}?dataEnv=16")
    name = None
    if body:
        try:
            data = json.loads(body)
            name = data.get("name") or None
        except json.JSONDecodeError:
            name = None
    cache["zone"][key] = name or ""
    if name:
        ZONES[zone_id] = name
    return name


def candidates(items: dict, sources: dict) -> list[int]:
    out = []
    for key, it in items.items():
        name = it.get("name") or ""
        src = sources.get(key) or {}
        inst = src.get("instructions") or ""
        kind = src.get("sourceType") or ""
        premier = name.startswith("Premier ")
        if kind in ("quest_reward", "profession", "boss_drop", "container", "object_drop", "seasonal_quest") and not premier:
            if "costs tokens or reputation" not in inst:
                continue
        rl = it.get("rlvl") or 0
        if premier or "costs tokens or reputation" in inst or (
            is_rank_named(name) and kind in ("vendor", "unsourced", "unknown", "world_drop") and (rl <= 60 or int(key) >= 200000)
        ):
            out.append(int(key))
    return sorted(set(out))


def main() -> None:
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    npc_faction = json.loads(NPC_FACTION.read_text(encoding="utf-8"))
    cache = load_cache()
    dropped = [k for k, v in cache.get("xml", {}).items() if not v.get("sellers") and not v.get("req")]
    for k in dropped:
        del cache["xml"][k]
    if dropped:
        print(f"dropped {len(dropped)} empty xml rows", flush=True)
    seen_npc = set()
    for row in list(cache.get("xml", {}).values()):
        for seller in row.get("sellers") or []:
            npc_id = seller.get("id")
            if npc_id and npc_id not in seen_npc:
                seen_npc.add(npc_id)
                absorb_npc(npc_id, seller.get("name") or "", cache)
    ids = candidates(items, sources)
    print(f"candidates {len(ids)}", flush=True)

    parsed = {}
    for n, iid in enumerate(ids, 1):
        xml = xml_fact(iid, cache)
        name = items[str(iid)].get("name") or ""
        # The name already carries Sergeant, Warlord, and the rest. Premier
        # tooltips sometimes name both factions, so those still get a lookup.
        rank = None
        if name.startswith("Premier ") or not rank_from_name(name):
            rank = tip_rank(iid, cache)
        parsed[iid] = (xml, rank)
        if n % 25 == 0:
            save_cache(cache)
            print(f"  fetched {n}/{len(ids)}", flush=True)
    save_cache(cache)

    by_vendor = defaultdict(list)
    for iid, (xml, _rank) in parsed.items():
        name = items[str(iid)].get("name") or ""
        for seller in xml["sellers"]:
            by_vendor[seller["name"]].append(name)
    pvp_vendors = set(SEED_VENDORS)
    for npc, names in by_vendor.items():
        named = sum(1 for name in names if is_rank_named(name))
        if named >= 3:
            pvp_vendors.add(npc)

    vendor_sides = defaultdict(set)
    level_changes = []
    updated = []
    skipped_town = []
    no_seller = []

    # First pass records sellers so an unsourced twin can copy one.
    sold_key = {}

    def consider(iid: int, inherit: dict | None) -> None:
        key = str(iid)
        it = items[key]
        src = sources.get(key)
        if not src:
            return
        name = it.get("name") or ""
        xml, tip = parsed[iid]
        if not xml.get("ok", True):
            return
        sellers = list(xml["sellers"])
        if not sellers and inherit:
            sellers = inherit["sellers"]
        if not sellers:
            no_seller.append((iid, name))
            kind = src.get("sourceType") or ""
            # A named world drop is a creature, not a missing quartermaster.
            if kind == "world_drop" and src.get("npc"):
                return
            # No seller on Wowhead. Still record the rank and the currencies
            # for Premier and for unsourced rank pieces. Do not invent a vendor.
            if kind not in ("unsourced", "unknown", "vendor"):
                return
            # A town merchant who already sells the piece is not a rank vendor.
            if kind == "vendor" and src.get("npc") and src.get("npc") not in pvp_vendors:
                return
            if not (name.startswith("Premier ") or tip or rank_from_name(name)):
                return
        elif sellers[0]["name"] not in pvp_vendors:
            skipped_town.append((iid, name, sellers[0]["name"]))
            return

        req = xml["req"] if xml["req"] and xml["req"] > 1 else None
        old_rl = it.get("rlvl") or 0
        if req and req != old_rl:
            it["rlvl"] = req
            level_changes.append((iid, name, old_rl, req))

        rank = tip or rank_from_name(name)
        if sellers:
            npc = sellers[0]["name"]
            zone_id = sellers[0]["zone"]
            zone = zone_name(zone_id, cache) if zone_id else None
            where = f" in {zone}" if zone else ""
            extra = ""
            others = [s["name"] for s in sellers[1:] if s["name"] != npc]
            if others:
                extra = " Also sold by " + " and ".join(others) + "."
            instructions = (
                f"Bought from {npc}{where}. Costs Honor Points and tokens (Marks of Honor)."
                + extra
            )
            src["sourceType"] = "vendor"
            src["npc"] = npc
            src["zone"] = zone
            src["instructions"] = instructions
            src["alts"] = []
            src["questName"] = None
            src["profession"] = None
            src["obtainable"] = True
            src["excludedBecause"] = None
            if xml["side"] == 1:
                vendor_sides[npc].add("Alliance")
            elif xml["side"] == 2:
                vendor_sides[npc].add("Horde")
            sold_key[(name, it.get("ilvl"), it.get("rlvl"))] = {"sellers": sellers, "side": xml["side"]}
        else:
            if src.get("npc"):
                zone = src.get("zone")
                where = f" in {zone}" if zone else ""
                src["instructions"] = (
                    f"Bought from {src['npc']}{where}. Costs Honor Points and tokens (Marks of Honor)."
                )
            else:
                src["instructions"] = (
                    "Costs Honor Points and tokens (Marks of Honor). The seller is not listed on Wowhead yet."
                )
            src["obtainable"] = True
            src["excludedBecause"] = None
        if rank:
            src["pvpRank"] = rank
        else:
            src.pop("pvpRank", None)
        updated.append(iid)

    for iid in ids:
        consider(iid, None)

    # Unsourced Forever copies of a piece Wowhead sells under the classic id.
    twins = 0
    for iid in list(no_seller):
        item_id, name = iid
        it = items[str(item_id)]
        inherit = sold_key.get((name, it.get("ilvl"), it.get("rlvl")))
        if not inherit:
            continue
        # consider() already ran. Re-apply with the twin's seller.
        parsed_sellers = parsed[item_id][0]["sellers"]
        if parsed_sellers:
            continue
        parsed[item_id][0]["sellers"] = inherit["sellers"]
        if not parsed[item_id][0]["side"]:
            parsed[item_id][0]["side"] = inherit["side"]
        # Drop the earlier no-seller write by running consider again.
        consider(item_id, inherit)
        twins += 1

    for npc, sides in vendor_sides.items():
        if sides == {"Alliance"}:
            npc_faction[npc] = "Alliance"
        elif sides == {"Horde"}:
            npc_faction[npc] = "Horde"

    ITEMS.write_text(json.dumps(items, separators=(",", ":")), encoding="utf-8")
    SOURCES.write_text(json.dumps(sources, separators=(",", ":")), encoding="utf-8")
    NPC_FACTION.write_text(json.dumps(npc_faction, indent=1, sort_keys=True) + "\n", encoding="utf-8")

    id_path = Path(DATA) / "forever_wowhead" / "pvp_vendor_ids.json"
    id_path.write_text(json.dumps(sorted(set(updated))), encoding="utf-8")
    print(f"updated {len(set(updated))} twins {twins}", flush=True)
    print(f"level changes {len(level_changes)}", flush=True)
    for row in level_changes[:40]:
        print("  lvl", row, flush=True)
    print("vendors", flush=True)
    counts = Counter()
    for iid in set(updated):
        counts[sources[str(iid)].get("npc") or "(no npc)"] += 1
    for npc, n in counts.most_common():
        side = npc_faction.get(npc)
        print(f"  {n:4} {npc} {side or ''}", flush=True)
    print(f"town left alone {len(skipped_town)}", flush=True)
    for row in skipped_town[:15]:
        print("  town", row, flush=True)
    print(f"no seller {len(no_seller)}", flush=True)
    print("new pvp vendors", sorted(pvp_vendors - SEED_VENDORS), flush=True)


if __name__ == "__main__":
    main()
