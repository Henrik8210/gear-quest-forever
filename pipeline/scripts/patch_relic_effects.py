"""Backfill relic effect lines from Forever Wowhead tooltips into items.json."""
import html
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import G

TIPS = os.path.join(G, "forever_wowhead", "tooltips.json")
ITEMS = os.path.join(G, "items.json")

rx_tag = re.compile(r"<[^>]+>")


def plain(s):
    return html.unescape(rx_tag.sub("", s or ""))


def lines_from_tooltip(html_tip):
    text = plain(html_tip)
    out = []
    m = re.search(r"Equip:\s*(.+?)(?:Sell Price:|Requires Level:|Classes:|Unique|$)", text, re.I)
    if m:
        line = m.group(1).strip().rstrip(".")
        if line:
            out.append("Equip: " + line)
    if re.search(r"engrave", text, re.I):
        m = re.search(r"(Engrave[^\"]+)", text, re.I)
        if m:
            out.append(m.group(1).strip())
    return out


def main():
    items = json.load(open(ITEMS, encoding="utf-8"))
    tips = json.load(open(TIPS, encoding="utf-8"))
    patched = 0
    for iid, it in items.items():
        if it.get("kind") not in ("Totem", "Idol", "Libram"):
            continue
        if it.get("effects"):
            continue
        tip = tips.get(str(it["id"])) or tips.get(it["id"])
        if not tip or not tip.get("tooltip"):
            continue
        eff = lines_from_tooltip(tip["tooltip"])
        if not eff:
            continue
        it["effects"] = eff
        proclike = re.compile(r"Chance on hit|^Use:|chance to|Equip: Chance", re.I)
        it["procs"] = [e for e in eff if proclike.search(e)]
        it["effectDriven"] = bool(it["procs"]) and not it.get("stats")
        patched += 1
    json.dump(items, open(ITEMS, "w", encoding="utf-8"), separators=(",", ":"))
    print(f"patched relic effects on {patched} items")


if __name__ == "__main__":
    main()
