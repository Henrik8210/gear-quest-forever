"""Standing check: random-suffix tables are Classic, not TBC.

Forever scores Classic 1-60. The TBC tables genuinely differ -- verified on
Wowhead for Vice Grips (item 9640):

    suffix               Classic                 TBC
    of Strength          +17 Str  @ 9.0%         +20 Str  @ 7.9%
    of the Bear          41.0%                   40.1%
    of the Whale         +11-12   @ 9.2%         +13/+13  @ 10.0%
    of Intellect         ABSENT                  present @ 0.5%

If this check fails, items_random.json was rebuilt against the TBC namespace.
Rebuild with: node scripts/convert-classic-random-to-pipeline.mjs
"""
import json, os, sys
from gq_paths import G, ROOT

FAIL=[]

# 1. stored data carries the Classic fingerprint
rand=json.load(open(G+"items_random.json"))
vs=rand.get("9640")
if not vs:
    FAIL.append("Vice Grips (9640) missing from items_random.json -- cannot verify era")
else:
    by={v["suffix"]:v for v in vs}
    def want(suffix, stat, value, chance):
        v=by.get(suffix)
        if not v: return FAIL.append("Vice Grips: %r missing"%suffix)
        got=v["stats"].get(stat)
        if got!=value: FAIL.append("Vice Grips %s: %s=%s, Classic is %s (TBC is the other value)"%(suffix,stat,got,value))
        if abs((v.get("chanceAny") or v.get("chance") or 0)-chance)>0.15:
            FAIL.append("Vice Grips %s: chance %.1f%%, Classic is %.1f%%"%(suffix,v.get("chanceAny") or 0,chance))
    want("of Strength","str",17,9.0)          # TBC: 20 @ 7.9
    want("of the Whale","sta",12,9.2)         # TBC: 13 @ 10.0; Classic range 11-12, hi=12
    if "of Intellect" in by:
        FAIL.append("Vice Grips lists 'of Intellect' -- that suffix is TBC-only")
    if "sp_from_heal" in (by.get("of Healing") or {}).get("stats",{}):
        FAIL.append("Vice Grips 'of Healing' has a spell-damage component -- that is the TBC version")

# 2. TBC-only high-ilvl random greens should not dominate a Classic scrape
items=json.load(open(G+"items.json"))
hi=[i for i in rand if items.get(i) and items[i]["ilvl"]>=100]
if len(hi)>=20:
    FAIL.append("%d random-enchant items at ilvl>=100 -- Classic tables top out near 90"%len(hi))

# 3. Wowhead scraper in this tree must not silently point at /tbc/
wh=os.path.join(os.path.dirname(__file__), "wowhead_random.py")
if os.path.exists(wh):
    src=open(wh, encoding="utf-8").read()
    if "/tbc/" in src and "/classic/" not in src:
        FAIL.append("wowhead_random.py still uses the /tbc/ namespace")

if FAIL:
    print("FAIL -- %d era problem(s):"%len(FAIL))
    for f in FAIL: print("   "+f)
    sys.exit(1)
print("era check: OK  (random suffixes Classic-valued, %d items at ilvl>=100)"%len(hi))
print("            pool filter: classic_item_ids.json; outputs: %s/out/"%ROOT)
