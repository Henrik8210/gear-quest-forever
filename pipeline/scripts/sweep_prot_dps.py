import json,subprocess,sys
base=json.load(open("weights.json"))
orig=base["PALADIN"]["protection"]["dpsWeight"]
rows=[]
for dw in (0.0,0.5,1.0,1.5,2.37):
    W=json.load(open("weights.json"))
    W["PALADIN"]["protection"]["dpsWeight"]=dw
    json.dump(W,open("weights.json","w"),indent=1)
    subprocess.run([sys.executable,"score.py"],capture_output=True)
    gen=json.load(open("paladin.json")); items=json.load(open("items.json"))
    G=json.load(open("guides.json"))["protection"]
    def top(sl):
        for b in gen["protection"]["bands"]:
            if b["slot"]==sl and b["faction"]=="Alliance" and b["lo"]<=60<=b["hi"]:
                return [items[str(p["id"])]["name"] for b2 in [b] for p in b["picks"][:3]]
        return []
    a=b=n=0
    for sl,names in G.items():
        m=top(sl)
        if not m: continue
        n+=1
        if names[0] in m: a+=1
        if m[0] in set(names): b+=1
    mh=top("MainHand")
    rows.append((dw,a,b,n,mh))
    print(f"  dpsWeight {dw:<5} guideBiS-in-top3 {a}/{n}  my#1-in-guide {b}/{n}   MainHand: {' | '.join(mh)}")
W=json.load(open("weights.json")); W["PALADIN"]["protection"]["dpsWeight"]=orig
json.dump(W,open("weights.json","w"),indent=1)
best=max(rows,key=lambda r:(r[1]+r[2]))
print(f"\n  best by combined agreement: dpsWeight {best[0]}  ({best[1]}+{best[2]} of {best[3]*2})")
