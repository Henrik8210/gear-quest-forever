#!/usr/bin/env python3
"""The generated hunt lists keep the gear rules.

Reads every class catalog (`Data.<Class>.generated.lua`, levels 10-60, and
`Data.<Class>.Early.1to9.generated.lua`) in Lua 5.1, the same tables the addon
loads. A pick row is { itemId, slot, minLevel, maxLevel, rank, spec, faction,
score, suffix=... }.

Structure
- Ranks close up: each spec, faction, slot and level band is ranked 1..N.
- Level bands are 1 <= min <= max <= 60, and bands of one spec, faction and
  slot do not overlap.
- Every row's item has a facts row with a name and a known source type.
Order
- Outside MainHand and SecondaryHand, a higher rank never has a lower score,
  except a set piece, which may lead for its set bonus, and a level-60
  Wowhead Forever list (origin="guide"), which keeps the page's order. The weapon slots rank
  a one-hander with its off-hand partner, so their order is not the stored
  score.
Banned
- The level-30 beta copies (pipeline/data/forever_beta_copies.json), the test
  items, UNUSED / (DNT) / Placeholder records, and the pieces the rules keep
  out are never a hunt.
- Paladin and warrior have no Horde 1-9 list: both factions are in the Early
  file.
Tooltips (the Wowhead Forever tip in Data.ForeverAudit)
- No Fishing Pole type is a hunt. The name is not the test: Primitive Fishing
  Pole is a polearm and Dwarven Fishing Pole is a gun in Forever.
- Hunter ranged is Bow, Gun and Crossbow.
- A main-hand row has DPS, and never says Off Hand or Held In Off-hand.
- A main-hand-only weapon stored on an off-hand list is a warning, because
  EntryIsMainHandOnly hides it in game.
Faction locks
- An item in quest_faction.json, vendor_side.json or drop_faction.json is only
  on that faction's list.
Known answers
- gear_expectations.json: ranks and facts the rules state. A deliberate
  rescore that moves one updates that file in the same change. An entry with
  "knownIssue" is reported and does not fail; it fails once it passes, so the
  note gets removed.

Usage: python scripts/ci/check_gear.py
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

from lupa.lua51 import LuaRuntime

REPO = Path(__file__).resolve().parents[2]
GENERATED = REPO / "GearQuest" / "_generated"
DATA = REPO / "pipeline" / "data"
CLASSES = ["Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"]
WEAPON_PAIR_SLOTS = {"MainHand", "SecondaryHand"}
SOURCE_TYPES = {
    "boss_drop", "container", "crafted", "event", "fishing", "object_drop",
    "profession", "pvp", "quest_reward", "raid_trash", "rare_npc", "reputation",
    "unobtainable", "unsourced", "vendor", "world_boss", "world_drop",
}
TEST_ITEMS = {280304: "Invisible Dagger", 24358: "QATest +1000 Spell Dmg Ring",
              19503: "2200 Test sword", 19504: "2200 Test sword"}
BANNED_NAMES = {"Ice Barbed Spear", "Bloodseeker", "Wand of Biting Cold"}
RECORD_NAME = re.compile(r"UNUSED|\(DNT\)|Placeholder", re.I)
# Tooltips glue the slot onto the type ("Main HandAxe", "Binds when
# equippedRangedBow"), or put the type on the next line.
TIP_SLOT = re.compile(r"(Two-Hand|One-Hand|Main Hand|Off Hand|Held In Off-hand|Ranged|Thrown|Relic)"
                      r"[ \t]*(\n[ \t]*)?([A-Z][A-Za-z ]*)?")
HUNTER_RANGED = {"Bow", "Gun", "Crossbow"}

DUMP = """
function(t)
    local out = {}
    for i = 1, #t do
        local r = t[i]
        out[i] = { r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8] or 0, r.origin or false }
    end
    return out
end
"""
FACTS = """
function(t)
    local out = {}
    for id, f in pairs(t) do
        out[id] = { f.name or false, f.sourceType or false, f.setPiece and true or false,
                    f.reqLevel or false, f.quality or false }
    end
    return out
end
"""


class Catalog:
    def __init__(self) -> None:
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.dump = self.lua.eval(DUMP)
        self.facts = self.lua.eval(FACTS)
        self.run = self.lua.eval("function(c, n) local f, e = loadstring(c, n); assert(f, e); f() end")
        # rows[cls] = list of (item, slot, lo, hi, rank, spec, faction, score)
        self.rows: dict[str, list[tuple]] = {}
        # facts[cls][item] = (name, sourceType, setPiece, reqLevel, quality)
        self.item: dict[str, dict[int, tuple]] = {}
        self.tips: dict[int, str] = {}

    def load_tips(self) -> None:
        text = (GENERATED / "Data.ForeverAudit.generated.lua").read_text(encoding="utf-8-sig")
        self.lua.execute("GearQuest = { Data = {} }")
        self.lua.eval("function(c, n) local f, e = loadstring(c, n); assert(f, e); f('GearQuestForever', GearQuest) end")(
            text, "@Data.ForeverAudit.generated.lua")
        tips = self.lua.eval("""function()
            local out = {}
            for id, row in pairs(GearQuest.Data.foreverAudit) do
                if row.status == "ok" and row.tip then out[id] = row.tip end
            end
            return out
        end""")()
        self.tips = {int(k): v for k, v in tips.items()}
        self.lua.execute("GearQuest = nil")

    def load(self, cls: str) -> None:
        rows: list[tuple] = []
        facts: dict[int, tuple] = {}
        for name in [f"Data.{cls}.generated.lua", f"Data.{cls}.Early.1to9.generated.lua"]:
            text = (GENERATED / name).read_text(encoding="utf-8-sig")
            tables = re.findall(r"^GQ\.Data\.(\w+)\s*=", text, re.M)
            facts_name = next(t for t in tables if t.endswith("Facts"))
            picks_name = next(t for t in tables if not t.endswith("Facts"))
            self.lua.execute("GearQuest = { Data = {} }")
            self.run(text, "@" + name)
            data = self.lua.globals().GearQuest.Data
            rows.extend(tuple(r.values()) for r in self.dump(data[picks_name]).values())
            for item, f in self.facts(data[facts_name]).items():
                facts.setdefault(item, tuple(v if v is not False else None for v in f.values()))
        self.lua.execute("GearQuest = nil")
        self.rows[cls], self.item[cls] = rows, facts


def check_structure(cat: Catalog, fail) -> None:
    unknown_sources: dict[str, int] = defaultdict(int)
    for cls in CLASSES:
        facts = cat.item[cls]
        groups: dict[tuple, list[tuple]] = defaultdict(list)
        bands: dict[tuple, set] = defaultdict(set)
        for row in cat.rows[cls]:
            item, slot, lo, hi, rank, spec, faction, score = row[:8]
            groups[(spec, faction, slot, lo, hi)].append(row)
            bands[(spec, faction, slot)].add((lo, hi))
            if not (1 <= lo <= hi <= 60):
                fail(f"{cls} {spec} {faction} {slot}: item {item} has level band {lo}-{hi}")
            fact = facts.get(item)
            if not fact or not fact[0]:
                fail(f"{cls}: item {item} is on the {spec} {slot} list with no facts row")
            elif fact[1] not in SOURCE_TYPES:
                unknown_sources[fact[1]] += 1
        for (spec, faction, slot, lo, hi), group in groups.items():
            ranks = sorted(r[4] for r in group)
            if ranks != list(range(1, len(ranks) + 1)):
                fail(f"{cls} {spec} {faction} {slot} {lo}-{hi}: ranks {ranks[:15]} do not close up")
            # A Wowhead Forever list keeps the page's order. Rank 1 can score
            # below a later option. The model still has to rank by score.
            guided = any(len(r) > 8 and r[8] == "guide" for r in group)
            if slot in WEAPON_PAIR_SLOTS or guided:
                continue
            ordered = sorted(group, key=lambda r: r[4])
            for a, b in zip(ordered, ordered[1:]):
                if a[7] < b[7] - 1e-9 and not facts.get(a[0], (None, None, False))[2]:
                    fail(f"{cls} {spec} {faction} {slot} {lo}-{hi}: rank {a[4]} {facts[a[0]][0]} "
                         f"scores {a[7]}, below rank {b[4]} {facts[b[0]][0]} at {b[7]}")
        for (spec, faction, slot), spans in bands.items():
            spans = sorted(spans)
            for a, b in zip(spans, spans[1:]):
                if b[0] <= a[1]:
                    fail(f"{cls} {spec} {faction} {slot}: bands {a[0]}-{a[1]} and {b[0]}-{b[1]} overlap")
    for source, count in unknown_sources.items():
        fail(f"{count} facts rows have source type {source!r}, not one the log knows")


def check_banned(cat: Catalog, fail) -> None:
    beta = set(json.loads((DATA / "forever_beta_copies.json").read_text(encoding="utf-8"))["ids"])
    for cls in CLASSES:
        facts = cat.item[cls]
        seen: set[int] = set()
        for row in cat.rows[cls]:
            item = row[0]
            if item in seen:
                continue
            seen.add(item)
            name = (facts.get(item) or (None,))[0] or ""
            if item in beta:
                fail(f"{cls}: {item} {name} is a level-30 beta copy and must not be a hunt")
            if item in TEST_ITEMS:
                fail(f"{cls}: {item} {TEST_ITEMS[item]} is a test item and must not be a hunt")
            if RECORD_NAME.search(name):
                fail(f"{cls}: {item} {name} is a placeholder record and must not be a hunt")
            if name in BANNED_NAMES:
                fail(f"{cls}: {item} {name} is kept out by the rules (Korrak / AV reputation)")
    for path in GENERATED.glob("Data.*.generated.lua"):
        if re.match(r"Data\.(Paladin|Warrior)\.Horde\.1to9", path.name):
            fail(f"{path.name} must not exist: paladin and warrior 1-9 is the Early file")
    data_lua = (REPO / "GearQuest" / "Data.lua").read_text(encoding="utf-8-sig")
    for table in ("paladinHorde1to9", "warriorHorde1to9"):
        if re.search(rf"\bData\.{table}\s*=", data_lua):
            fail(f"Data.lua defines {table}; paladin and warrior 1-9 is the Early file")


def tip_slot(tip: str) -> tuple[str | None, str | None]:
    match = TIP_SLOT.search(tip)
    if not match:
        return None, None
    kind = (match.group(3) or "").strip() or None
    return match.group(1), kind


def check_tooltips(cat: Catalog, fail, warn) -> None:
    leftovers: dict[str, set[int]] = defaultdict(set)
    for cls in CLASSES:
        reported: set[tuple] = set()
        for item, slot, lo, hi, rank, spec, faction, score, *_ in cat.rows[cls]:
            tip = cat.tips.get(item)
            if not tip or (item, slot) in reported:
                continue
            hand, kind = tip_slot(tip)
            name = (cat.item[cls].get(item) or (None,))[0]
            problem = None
            if kind == "Fishing Pole":
                problem = "is a fishing pole and must not be a hunt"
            elif cls == "Hunter" and slot == "Ranged" and kind not in HUNTER_RANGED:
                problem = f"is a {kind or 'ranged item of unknown type'}; hunter ranged is Bow, Gun and Crossbow"
            elif slot == "MainHand" and "damage per second" not in tip:
                problem = "has no DPS and is not a weapon"
            elif slot == "MainHand" and hand in ("Off Hand", "Held In Off-hand"):
                problem = f"says {hand} and must stay out of the main hand"
            elif slot == "SecondaryHand" and hand == "Main Hand":
                leftovers[cls].add(item)
            if problem:
                reported.add((item, slot))
                fail(f"{cls}: {item} {name} on the {spec} {slot} list {problem}")
    for cls, items in sorted(leftovers.items()):
        warn(f"{cls}: {len(items)} main-hand-only weapons are stored on off-hand lists; "
             f"EntryIsMainHandOnly hides them in game (e.g. {sorted(items)[:5]})")


def check_factions(cat: Catalog, fail) -> None:
    locks: dict[int, tuple[str, str]] = {}
    for name in ("quest_faction.json", "vendor_side.json", "drop_faction.json"):
        for item, side in json.loads((DATA / name).read_text(encoding="utf-8")).items():
            locks.setdefault(int(item), (side, name))
    for cls in CLASSES:
        reported: set[tuple] = set()
        for item, slot, lo, hi, rank, spec, faction, score, *_ in cat.rows[cls]:
            lock = locks.get(item)
            if lock and faction and faction != lock[0] and (item, faction) not in reported:
                reported.add((item, faction))
                name = (cat.item[cls].get(item) or (None,))[0]
                fail(f"{cls}: {item} {name} is {lock[0]} only ({lock[1]}) and is on the {faction} list")


def rank_at(cat: Catalog, cls: str, spec: str, faction: str, slot: str, level: int, item: int):
    for row in cat.rows[cls]:
        if (row[0] == item and row[5] == spec and row[6] == faction and row[1] == slot
                and row[2] <= level <= row[3]):
            return row[4]
    return None


def check_expectations(cat: Catalog, fail, warn) -> None:
    spec_file = json.loads(Path(__file__).with_name("gear_expectations.json").read_text(encoding="utf-8"))
    for exp in spec_file["ranks"]:
        cls, slot, item = exp["class"], exp["slot"], exp["item"]
        specs = exp["specs"] if isinstance(exp["specs"], list) else sorted(
            {r[5] for r in cat.rows[cls] if r[1] == slot})
        factions = exp.get("factions", ["Alliance", "Horde"])
        problems = []
        for spec in specs:
            for faction in factions:
                for level in exp["levels"]:
                    got = rank_at(cat, cls, spec, faction, slot, level, item)
                    where = f"{cls} {spec} {faction} {slot} @{level}"
                    if "rank" in exp and got != exp["rank"]:
                        problems.append(f"{where}: {exp['name']} is rank {got}, expected {exp['rank']}")
                    if exp.get("absent") and got is not None:
                        problems.append(f"{where}: {exp['name']} is rank {got}, expected off the list")
                    if "minRank" in exp and got is not None and got < exp["minRank"]:
                        problems.append(f"{where}: {exp['name']} is rank {got}, expected {exp['minRank']} or lower")
        report(exp, problems, fail, warn)

    for exp in spec_file["facts"]:
        item, problems, found = exp["item"], [], False
        for cls in CLASSES:
            fact = cat.item[cls].get(item)
            if not fact:
                continue
            found = True
            if "reqLevel" in exp and fact[3] != exp["reqLevel"]:
                problems.append(f"{cls}: {exp['name']} ({item}) requires level {fact[3]}, expected {exp['reqLevel']}")
            if "quality" in exp and fact[4] != exp["quality"]:
                problems.append(f"{cls}: {exp['name']} ({item}) has quality {fact[4]}, expected {exp['quality']}")
        if exp.get("absent"):
            on_list = [cls for cls in CLASSES if any(r[0] == item for r in cat.rows[cls])]
            if on_list:
                problems.append(f"{exp['name']} ({item}) is on the {', '.join(on_list)} lists, expected off every list")
        elif not found:
            problems.append(f"{exp['name']} ({item}) is in no class catalog")
        report(exp, problems, fail, warn)


def report(exp: dict, problems: list[str], fail, warn) -> None:
    if exp.get("knownIssue"):
        if problems:
            warn(f"known issue, not failing: {exp['knownIssue']}")
        else:
            fail(f"'{exp['name']}' passes now; remove its knownIssue note from gear_expectations.json")
        return
    for problem in problems:
        fail(f"{problem} ({exp.get('why', 'gear_expectations.json')})")


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []
    cat = Catalog()
    cat.load_tips()
    for cls in CLASSES:
        cat.load(cls)
    check_structure(cat, failures.append)
    check_banned(cat, failures.append)
    check_tooltips(cat, failures.append, warnings.append)
    check_factions(cat, failures.append)
    check_expectations(cat, failures.append, warnings.append)
    for line in failures[:200]:
        print(f"FAIL {line}")
    if len(failures) > 200:
        print(f"... and {len(failures) - 200} more")
    for line in warnings:
        print(f"WARN {line}")
    total = sum(len(r) for r in cat.rows.values())
    print(f"Checked {total} hunt rows in {len(CLASSES)} classes, {len(failures)} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
