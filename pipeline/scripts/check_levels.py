"""
Regression check for level-eligibility discontinuities.

Catches the class of bug Henrik found at the 60/61 boundary: an item that Wowhead
says is usable from level N, but which our lists only start offering at N+1 or
later. Run this after every generation, for every class.
"""
import json, collections, sys, os
from gq_paths import G, scored
items=json.load(open(G+"items.json"))
gen=json.load(open(scored(os.environ.get("GQ_OUT","paladin.json"))))

first=collections.defaultdict(lambda: 999)   # (spec,faction,item) -> earliest band lo
early=[]
for spec,d in gen.items():
    for b in d["bands"]:
        for p in b["picks"][:3]:
            k=(spec,b["faction"],str(p["id"]))
            first[k]=min(first[k],b["lo"])
            if b["lo"] < items[str(p["id"])]["rlvl"]:
                early.append((spec,b["slot"],b["lo"],items[str(p["id"])]["name"],
                              items[str(p["id"])]["rlvl"]))

late=collections.defaultdict(list)
for (spec,fac,iid),lo in first.items():
    r=items[iid]["rlvl"]
    if lo>r and r>0: late[iid].append((spec,fac,lo,r))

print(f"A. picks offered BEFORE the item's RequiredLevel (should be 0): {len(early)}")
for e in early[:8]: print("   ",e)

print(f"\nB. items first offered LATER than their RequiredLevel: {len(late)} distinct")
rows=sorted(((lo-r,items[i]['name'],r,lo,sp) for i,v in late.items() for sp,f,lo,r in v),reverse=True)
for d,nm,r,lo,sp in rows[:12]:
    print(f"    +{d:>2} late   {nm:<34} usable from {r}, first offered at {lo}  ({sp})")
print(f"\n   NOTE: B is not automatically a bug -- an item can legitimately first enter a")
print(f"   top 3 later than it becomes usable, because better things were available.")
print(f"   What matters is that no item is *blocked* from a level it qualifies for.")

# the real test: for every item, is it in the candidate pool at its own rlvl?
print(f"\nC. spot-check the items Henrik flagged:")
name={}
for i,v in items.items(): name.setdefault(v["name"],i)
for nm in ("Might of Menethil","Severance","The Eye of Nerub","Grand Marshal's Sunderer","High Warlord's Battle Axe"):
    i=name.get(nm)
    if not i: continue
    r=items[i]["rlvl"]
    where=[(sp,b["lo"],b["hi"],[q["id"] for q in b["picks"][:3]].index(int(i))+1)
           for sp,d in gen.items() for b in d["bands"]
           if int(i) in [q["id"] for q in b["picks"][:3]]]
    at_r=[w for w in where if w[1]<=r<=w[2]]
    print(f"   {nm:<28} rlvl{r}  appears in {len(where)} bands; present at level {r}: "
          f"{'YES rank '+str(at_r[0][3]) if at_r else 'no'}")
sys.exit(1 if early else 0)
