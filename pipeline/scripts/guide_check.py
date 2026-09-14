"""
Validate generated level-60 picks against Wowhead's Classic-era Naxxramas BiS
guides for all three paladin specs. The guides list BiS plus a long tail of
alternatives, so the right test is precision, not exact match: does each of my
top 3 appear ANYWHERE in the guide's list for that slot? If it does not, the
model is picking something the guide's authors did not consider good at all.
"""
import json,sys
items=json.load(open("items.json")); gen=json.load(open("paladin.json"))
byname={}
for i,v in items.items(): byname.setdefault(v["name"],i)

GUIDES=json.load(open("guides.json"))
def top(spec,lv,sl):
    for b in gen[spec]["bands"]:
        if b["slot"]==sl and b["faction"]=="Alliance" and b["lo"]<=lv<=b["hi"]:
            return [items[str(p["id"])] for p in b["picks"][:3]]
    return []

grand_hit=grand_tot=0
for spec,slots in GUIDES.items():
    print(f"\n{'='*100}\n{spec.upper()}\n{'='*100}")
    hit=tot=0; missing=[]
    for sl,names in slots.items():
        want={n for n in names}
        mine=top(spec,60,sl)
        if not mine: print(f"  {sl:<14} (no band at 60)"); continue
        got=[m["name"] in want for m in mine]
        hit+=sum(got); tot+=len(got)
        flag="".join("+" if g else "." for g in got)
        print(f"  {flag:<4} {sl:<14} "+" | ".join(
            f"{m['name']}[{m['kind'][:2]}]"+("" if g else " <-NOT IN GUIDE")
            for m,g in zip(mine,got)))
        missing += [m["name"] for m,g in zip(mine,got) if not g]
    print(f"\n  precision: {hit}/{tot} of my picks appear in the guide ({hit/max(tot,1)*100:.0f}%)")
    grand_hit+=hit; grand_tot+=tot
    if missing: print(f"  not in guide: {missing}")
print(f"\n{'='*100}\nOVERALL: {grand_hit}/{grand_tot} = {grand_hit/max(grand_tot,1)*100:.0f}% precision against the three guides")
