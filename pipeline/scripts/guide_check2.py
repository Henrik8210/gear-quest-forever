import json,sys,os
from gq_paths import G, GUIDES_DIR, scored
gen=json.load(open(scored(os.environ.get("GQ_OUT","paladin.json"))))
items=json.load(open(G+"items.json"))
GD=json.load(open(os.path.join(GUIDES_DIR, os.environ.get("GQ_GUIDES","guides.json"))))
def names_of(gl):
    if gl and isinstance(gl[0],(list,tuple)): return [n for _,n in gl]
    return list(gl)
def best_tier(gl):
    """The items the guide itself calls best. Positional format -> just the first."""
    if gl and isinstance(gl[0],(list,tuple)):
        t=min(t for t,_ in gl); return [n for tt,n in gl if tt==t]
    return [gl[0]]
def top(spec,sl,lv=60):
    for b in gen[spec]["bands"]:
        if b["slot"]==sl and b["faction"]=="Alliance" and b["lo"]<=lv<=b["hi"]:
            return [items[str(p["id"])]["name"] for p in b["picks"][:3]]
    return []
TA=TB=TN=0
for spec,slots in GD.items():
    a=b=n=0; miss=[]
    for sl,gl in slots.items():
        m=top(spec,sl)
        if not m: continue
        names=names_of(gl); bt=best_tier(gl)
        n+=1
        if any(x in m for x in bt): a+=1
        else: miss.append((sl,"/".join(bt)[:30],m[0]))
        if m[0] in set(names): b+=1
    TA+=a;TB+=b;TN+=n
    print(f"  {spec:<12} guideBest-in-top3 {a}/{n} ({a/max(n,1)*100:3.0f}%)   my#1-endorsed {b}/{n} ({b/max(n,1)*100:3.0f}%)")
    for sl,want,got in miss[:4]: print(f"       miss {sl:<14} want {want[:30]:<30} got {got[:30]}")
print(f"  {'ALL':<12} guideBest-in-top3 {TA}/{TN} ({TA/max(TN,1)*100:3.0f}%)   my#1-endorsed {TB}/{TN} ({TB/max(TN,1)*100:3.0f}%)")
