"""Put crafted hunts back on both factions.

v1.1.4 marked recipes Unsourced. v1.1.5 copied the pattern's seller or
dropper onto the finished piece and, for the camp recipes, stored the
Horde stall as the zone. The Barrens is a Horde zone, so Alliance lists
lost the piece and a worn one scores 0.

The finished piece stays a profession. The Wowhead Forever plan page
supplies the seller or the dropper. A seller on both sides does not set
zone or npc, so neither faction is gated.
"""
import json
import os
import subprocess

from commerce_camps import ALLIANCE_WHERE, HORDE_WHERE, VENDORS

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
WH = os.path.join(DATA, "forever_wowhead")

CAMP_PAIRS = {frozenset(pair) for pair in VENDORS.values()}


def names_of(field):
    found = []
    for item in field or []:
        if isinstance(item, str) and item.strip():
            name = item.strip()
        elif isinstance(item, dict) and item.get("n"):
            name = str(item["n"]).strip()
        else:
            continue
        if name and name not in found:
            found.append(name)
    return found


def join_names(names):
    if len(names) == 1:
        return names[0]
    if len(names) == 2:
        return "%s and %s" % (names[0], names[1])
    return "%s, and %s" % (", ".join(names[:-1]), names[-1])


def camp_sentence(sellers):
    if frozenset(sellers) not in CAMP_PAIRS:
        return None
    for horde, alliance in VENDORS.values():
        if frozenset((horde, alliance)) == frozenset(sellers):
            return (
                "You can buy the recipe from %s at %s, or from %s at %s."
                % (horde, HORDE_WHERE, alliance, ALLIANCE_WHERE)
            )
    return None


def main():
    sources = json.load(open(os.path.join(DATA, "sources.json"), encoding="utf-8"))
    old = json.loads(subprocess.check_output(
        ["git", "show", "v1.1.3:pipeline/data/sources.json"], encoding="utf-8"))
    head = json.loads(subprocess.check_output(
        ["git", "show", "HEAD:pipeline/data/sources.json"], encoding="utf-8"))
    skills = json.load(open(os.path.join(WH, "craft_skills.json"), encoding="utf-8"))
    plans = {
        row["crafted"]: row
        for row in json.load(open(os.path.join(WH, "_unsourced_crafts.json"), encoding="utf-8"))
    }
    pages = {
        row["id"]: row
        for row in json.load(open(os.path.join(WH, "_plan_scrape_compact.json"), encoding="utf-8"))
    }

    restored = 0
    with_seller = 0
    with_drop = 0
    skill_only = 0
    for key, was in old.items():
        if was.get("sourceType") != "profession":
            continue
        src = sources.get(key)
        head_row = head.get(key) or {}
        if not src:
            continue
        # Already a craft in the released data. Leave that row alone.
        if head_row.get("sourceType") == "profession":
            continue
        skill = skills.get(key) or {}
        plan = plans.get(int(key)) or {}
        prof = skill.get("profession") or (plan.get("prof") or "").title() or was.get("profession")
        if not prof:
            continue
        rank = skill.get("skill")
        if rank and int(rank) > 1:
            craft = "Crafted with %s (requires skill %d)." % (prof, int(rank))
        else:
            craft = "Crafted with %s." % prof
        page = None
        for plan_id in plan.get("plans") or []:
            page = pages.get(plan_id)
            if page and not page.get("missing"):
                break
            page = pages.get(plan_id) or page
        extra = None
        sellers = names_of((page or {}).get("sell"))
        bosses = names_of((page or {}).get("bosses"))
        camp = camp_sentence(sellers)
        if camp:
            extra = camp
            with_seller += 1
        elif sellers and len(sellers) <= 8:
            extra = "Bought from %s." % join_names(sellers)
            with_seller += 1
        elif bosses and len(bosses) <= 3:
            extra = "The %s pattern drops from %s." % (prof, join_names(bosses))
            with_drop += 1
        else:
            # The plan page names a long drop or seller list. Keep that
            # Wowhead sentence, worded as the pattern, and do not keep the
            # faction zone that was stored with it.
            prev = (head.get(key) or {}).get("instructions") or ""
            if prev.startswith("You can buy the recipe from ") or prev.startswith("Bought from "):
                extra = prev
                with_seller += 1
            elif prev.startswith("Drops from "):
                extra = "The %s pattern drops from %s" % (prof, prev[len("Drops from "):])
                if not extra.endswith("."):
                    extra += "."
                with_drop += 1
            else:
                skill_only += 1
        src["sourceType"] = "profession"
        src["profession"] = prof
        src["instructions"] = craft if not extra else craft + " " + extra
        src["zone"] = None
        src["npc"] = None
        src["questName"] = None
        src["alts"] = []
        if "zones" in src:
            src["zones"] = None
        restored += 1

    path = os.path.join(DATA, "sources.json")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(sources, handle, ensure_ascii=True, separators=(",", ":"))
    os.replace(tmp, path)
    print("restored", restored)
    print("named seller", with_seller)
    print("named pattern drop", with_drop)
    print("craft skill only", skill_only)


if __name__ == "__main__":
    main()
