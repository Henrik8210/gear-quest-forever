import re,json,collections
raw=open("/mnt/user-data/uploads/GearQuest/Data.lua",encoding="utf-8").read()
consts=dict(re.findall(r"^local ([A-Z0-9_]+) = (\d+)$",raw,re.M))
def num(v):
    v=v.strip()
    return int(consts[v]) if v in consts else (int(v) if v.isdigit() else None)

entries=[]
for blk in re.findall(r"\{\s*\n\s*id = \"(.*?)\",(.*?)\n    \},", raw, re.S):
    eid, body = blk
    def g(k):
        m=re.search(rf"\b{k} = (.+?),?\n",body)
        return m.group(1).strip().rstrip(",") if m else None
    e={"id":eid,"itemId":num(g("itemId") or ""),"slot":(g("slot") or "").strip('"'),
       "minLevel":num(g("minLevel") or ""),"maxLevel":num(g("maxLevel") or ""),
       "rank":num(g("curatedRank") or ""),"classes":g("classes"),"specs":g("specs"),
       "factions":g("factions"),"sourceType":(g("sourceType") or "").strip('"')}
    entries.append(e)
print("parsed entries:",len(entries))
early=[e for e in entries if e["minLevel"] is not None and e["minLevel"]<=9 and (e["maxLevel"] or 99)<=16]
print("early (<=lvl9 start) entries:",len(early))

gen=json.load(open("paladin.json"))
items=json.load(open("items.json"))
# my level 1-9 picks, Alliance
mine=collections.defaultdict(dict)   # slot -> level -> [ids]
for b in gen["levelling_1_9"]["bands"]:
    if b["faction"]!="Alliance": continue
    for lv in range(b["lo"],b["hi"]+1):
        mine[b["slot"]][lv]=[p["id"] for p in b["picks"][:3]]

his=collections.defaultdict(lambda: collections.defaultdict(list))
for e in early:
    if e["slot"] and e["minLevel"] and e["rank"]:
        for lv in range(e["minLevel"], (e["maxLevel"] or e["minLevel"])+1):
            if lv<=9: his[e["slot"]][lv].append((e["rank"],e["itemId"]))

print("\n%-14s %-4s %-46s %s"%("SLOT","LVL","HENRIK'S CURATED TOP3","MY GENERATED TOP3"))
print("-"*140)
agree=tot=0; overlap=0
for slot in sorted(his):
    for lv in sorted(his[slot]):
        h=[i for _,i in sorted(his[slot][lv])][:3]
        m=mine.get(slot,{}).get(lv,[])
        if not h or not m: continue
        tot+=1
        if h==m: agree+=1
        overlap+=len(set(h)&set(m))
        nm=lambda ids:", ".join((items.get(str(i),{}).get("name","?")[:14]) for i in ids)
        flag="=" if h==m else ("~" if set(h)&set(m) else "X")
        print(f"{slot:<14} {lv:<4} {nm(h):<46} {flag} {nm(m)}")
print(f"\nexact top-3 match: {agree}/{tot}   avg overlap: {overlap/max(1,tot):.2f}/3")
