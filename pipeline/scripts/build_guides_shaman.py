"""guides_shaman.json from Henrik's three Wowhead Classic shaman guides, keeping the
Rank column (R19). Three guides, one per spec.

Two guide entries were random-suffix items printed under their rolled name, the same
trap as the druid restoration list (R26): "Archivist Cape of Healing" and "Drakestone
of Healing" are stored as their base items, "Archivist Cape" and "Drakestone".
"""
import json, re, collections
items=json.load(open("items.json")); NAMES={it["name"] for it in items.values()}
BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"optional":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"hit option":6,"optional hit":6,
      "mitigation alternative":6,"mit skewed alternative":6,"situational":7}
RESTRICT=re.compile(r"\b(pvp|dps|hit|mit|mitigation|t1|t2\.5|t2|t3|\d/\d|\d ?set|set bonus|"
                    r"\dp|pet damage|orc|human|dwarf|troll|tauren|undead|gnome|night ?elf|"
                    r"draenei|blood ?elf|dragonkin|beast|demon)\b")
NEUTRAL=re.compile(r"\b(legendary|contested)\b")
def tier(label):
    l=re.sub(r"\s+"," ",label.strip().lower())
    l=NEUTRAL.sub("",l).strip(" -&|")
    demote=1 if RESTRICT.search(l) else 0
    core=re.split(r"\s*[-(&|+]\s*",l)[0].strip()
    core=RESTRICT.sub("",core).strip(" -&+|")
    core=re.sub(r"\s+"," ",core)
    if core in BASE: return BASE[core]+demote
    if l in BASE: return BASE[l]+demote
    raise SystemExit("unknown rank label: %r (core %r)"%(label,core))
SLOT={"head":"Head","shoulder":"Shoulder","shoulders":"Shoulder","back":"Back","chest":"Chest",
 "wrist":"Wrist","hands":"Hands","waist":"Waist","legs":"Legs","feet":"Feet","neck":"Neck",
 "ring":"Finger","rings":"Finger","trinket":"Trinket","trinkets":"Trinket",
 "totem":"Ranged","totem/relic":"Ranged","main hand":"MainHand","two-hand":"MainHand",
 "two hand":"MainHand","off hand":"SecondaryHand","off-hand":"SecondaryHand"}
RAW=json.load(open("shaman_raw.json"))
out={}; unmatched=collections.defaultdict(list)
for spec,lines in RAW.items():
    d={}
    for line in lines:
        slot,rank,names=[x.strip() for x in line.split("|",2)]
        sl=SLOT[slot.lower()]; t=tier(rank)
        for nm in [x.strip() for x in names.split(" / ")]:
            if nm not in NAMES: unmatched[spec].append(nm); continue
            cur=d.setdefault(sl,[])
            prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
            if prev:
                if t<cur[prev[0]][0]: cur[prev[0]]=(t,nm)
            else: cur.append((t,nm))
    out[spec]={sl:[[t,n] for t,n in v] for sl,v in d.items()}
json.dump(out,open("guides_shaman.json","w"),indent=1,ensure_ascii=False)
for s,d in out.items(): print("== %-12s %3d entries, %2d slots"%(s,sum(len(v) for v in d.values()),len(d)))
if unmatched:
    for s,v in unmatched.items(): print("UNMATCHED %s (%d): %s"%(s,len(v),v))
else: print("all guide names matched")
