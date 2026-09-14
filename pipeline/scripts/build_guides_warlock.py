"""guides_warlock.json from the one Wowhead Classic warlock DPS guide.

The page is a SINGLE list covering every warlock DPS build -- it does not split
Affliction / Demonology / Destruction -- so all three specs share it, the same way the
one hunter DPS guide serves all three hunter specs. Where the specs differ is in the
weights, not the item list: Affliction values spell crit least (a DoT cannot crit in
this era, so Corruption, Curse of Agony and Siphon Life get nothing from it) and
Destruction most (Ruin doubles crit damage on Shadow Bolt), and the shadow/fire split
differs -- Affliction is almost pure Shadow, Destruction splits with Immolate,
Conflagrate and Searing Pain.

Rank labels on this page and what each does to the tier:
  "Good - 2 Set Bonus"  qualified on wearing the other half of a PvP set -> demoted
  "Best - Undead"       conditional on the target, like the +60 AP vs Undead stats,
                        and the same treatment the shadow priest trinket got -> demoted
  "Good - Undead"       same, demoted
  "Okay" / "Mediocre"   already in the shared table at 5 and 6

TWO ROWS ARE DELIBERATELY DROPPED. The guide lists "Random of Shadow Wrath Bind on
Equip" for Head and "Random of Shadow Wrath" for Wand. Those are not item names -- they
mean "any BoE that happens to roll the of Shadow Wrath suffix", a whole family rather
than a pick. There is nothing to match them to, and inventing one would be worse than
leaving the slot to the model, which already ranks every rolled variant on its own.
"""
import json, re, difflib

items=json.load(open("items.json")); NAMES={it["name"] for it in items.values()}
rand=json.load(open("items_random.json"))
BYNAME={}
for _k,_v in items.items(): BYNAME.setdefault(_v["name"],_k)

def resolve(name):
    """Accept a ROLLED item name by stripping a trailing " of X" and confirming X is
    genuinely one of that base item's possible rolls."""
    if name in NAMES: return name, None
    for i in range(len(name)):
        if not name[i:].startswith(" of "): continue
        base, suf = name[:i], name[i+1:]
        if base not in NAMES: continue
        if suf in [x["suffix"] for x in rand.get(BYNAME[base], [])]: return base, suf
    # Last resort: a spelling slip in the guide text. This page says "Cloak of the
    # Hakkari Worshipers"; the item is "Cloak of the Hakkari Worshippers", with two Ps.
    # Accepted only when a single candidate is that close, and always reported -- a
    # near-miss that silently resolved to the wrong item would be worse than a failure.
    near=difflib.get_close_matches(name, NAMES, n=2, cutoff=0.93)
    if len(near)==1: return near[0], "~"
    return None, None

BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"optional":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"hit option":6,"situational":7}
DEMOTE=re.compile(r"\b(2 set bonus|8/8 t2|offset|sustain|undead)\b")
NEUTRAL=re.compile(r"\b(pvp|throughput|legendary)\b")
def tier(rank):
    l=re.sub(r"\s+"," ",rank.strip().lower())
    demote=1 if DEMOTE.search(l) else 0
    core=re.sub(r"\s+"," ",NEUTRAL.sub("",DEMOTE.sub("",l))).strip(" -")
    if core not in BASE: raise SystemExit("unknown rank: %r (core %r)"%(rank,core))
    return BASE[core]+demote

SLOT={"head":"Head","neck":"Neck","shoulders":"Shoulder","back":"Back","chest":"Chest",
 "wrists":"Wrist","wrist":"Wrist","hands":"Hands","waist":"Waist","legs":"Legs",
 "feet":"Feet","ring":"Finger","trinket":"Trinket","wand":"Ranged",
 "main hand":"MainHand","off hand":"SecondaryHand","two hand":"MainHand","two-hand":"MainHand"}
SPECS=("affliction","demonology","destruction")

out={s:{} for s in SPECS}; unmatched=[]; rolled=[]; nearmiss=[]
for line in open("warlock_raw.txt",encoding="utf-8").read().strip().splitlines():
    slot,rank,name=[x.strip() for x in line.split("|",2)]
    sl=SLOT[slot.lower()]; t=tier(rank)
    nm,roll=resolve(name)
    if nm is None: unmatched.append(name); continue
    if roll=="~": nearmiss.append((name,nm))
    elif roll: rolled.append((nm,roll))
    for spec in SPECS:
        cur=out[spec].setdefault(sl,[])
        prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
        if prev:
            if t<cur[prev[0]][0]: cur[prev[0]]=(t,nm)
        else: cur.append((t,nm))
for spec in out:
    for sl in out[spec]: out[spec][sl]=sorted(out[spec][sl], key=lambda x:x[0])
json.dump({s:{sl:[[t,n] for t,n in v] for sl,v in d.items()} for s,d in out.items()},
          open("guides_warlock.json","w"),indent=1,ensure_ascii=False)
for s,d in out.items():
    print("== %-12s %3d entries, %2d slots"%(s,sum(len(v) for v in d.values()),len(d)))
print("rolled names resolved:", rolled or "none")
for a,b in nearmiss: print(f"  NEAR MISS: guide says {a!r} -> matched {b!r}")
print("UNMATCHED:", unmatched or "none")
if unmatched: raise SystemExit("a guide row names an item the table does not have")
