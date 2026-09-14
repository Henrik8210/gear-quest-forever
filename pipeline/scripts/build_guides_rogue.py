"""guides_rogue.json from the one Wowhead Classic rogue DPS guide.

The guide is ONE page covering two builds, and Henrik flagged it: "There's both
combat with sword or dagger". So the three spec lists are derived from it, not copied:

  * "Main Hand (Swords)" and "Off Hand (Swords)" -> COMBAT only. Assassination and
    Subtlety are dagger-locked (Backstab / Ambush / Mutilate do not fire with a
    sword), so a sword list is not their list.
  * "Off Hand (Daggers)" -> all three.
  * Rows labelled "Swords Best" -> tier 1 for combat, one tier lower for the two
    dagger specs. "Daggers Best" -> tier 1 for all three, since combat-daggers is a
    real build.
  * THERE IS NO DAGGER MAIN-HAND TABLE ON THE PAGE. Verified by a second fetch:
    "There is no separate Main Hand section for daggers on this page." So
    assassination and subtlety have no guide main hand at all and the model decides
    it, restricted to daggers. Their guide denominator is one slot smaller, which is
    correct -- the guide does not cover it.
"""
import json, re, collections
items=json.load(open("items.json")); NAMES={it["name"] for it in items.values()}
BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"optional":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"hit option":6,"situational":7}
RACE=re.compile(r"\b(human|non-human|orc|dwarf|troll|tauren|undead|gnome|night ?elf|draenei|blood ?elf)\b")
def base_tier(rank):
    l=re.sub(r"\s+"," ",rank.strip().lower())
    demote=1 if RACE.search(l) else 0
    core=RACE.sub("",l).replace("swords","").replace("daggers","").strip(" -")
    core=re.sub(r"\s+"," ",core)
    if core not in BASE: raise SystemExit("unknown rank: %r (core %r)"%(rank,core))
    return BASE[core]+demote, ("swords" if "swords" in l else "daggers" if "daggers" in l else None)

SLOT={"head":"Head","neck":"Neck","shoulder":"Shoulder","back":"Back","chest":"Chest",
 "wrist":"Wrist","hands":"Hands","waist":"Waist","legs":"Legs","feet":"Feet",
 "ring 1":"Finger","trinket 1":"Trinket","ranged":"Ranged",
 "main hand (swords)":"MainHand","off hand (swords)":"SecondaryHand",
 "off hand (daggers)":"SecondaryHand"}
SWORD_ONLY={"main hand (swords)","off hand (swords)"}

RAW=open("rogue_raw.txt",encoding="utf-8").read().strip().splitlines()
SPECS=("combat","assassination","subtlety")
out={s:{} for s in SPECS}
unmatched=[]
for line in RAW:
    slot,rank,names=[x.strip() for x in line.split("|",2)]
    key=slot.lower()
    sl=SLOT[key]
    t,build=base_tier(rank)
    swordSection = key in SWORD_ONLY
    for nm in [x.strip() for x in names.split(" / ")]:
        if nm not in NAMES: unmatched.append(nm); continue
        for spec in SPECS:
            if swordSection and spec!="combat": continue
            tt=t
            if build=="swords" and spec!="combat": tt=t+1     # not this build's pick
            cur=out[spec].setdefault(sl,[])
            prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
            if prev:
                if tt<cur[prev[0]][0]: cur[prev[0]]=(tt,nm)
            else: cur.append((tt,nm))
json.dump({s:{sl:[[t,n] for t,n in v] for sl,v in d.items()} for s,d in out.items()},
          open("guides_rogue.json","w"),indent=1,ensure_ascii=False)
for s,d in out.items(): print("== %-14s %3d entries, %2d slots  (MainHand: %s)"%(
    s,sum(len(v) for v in d.values()),len(d),len(d.get("MainHand",[])) or "none"))
print("UNMATCHED:",unmatched or "none")
