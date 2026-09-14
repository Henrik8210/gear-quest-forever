import re,json,collections
raw=open("/mnt/user-data/uploads/GearQuest/Data.lua",encoding="utf-8").read()
consts=dict(re.findall(r"^local ([A-Z0-9_]+) = (\d+)$",raw,re.M))
def num(v):
    v=(v or "").strip()
    return int(consts[v]) if v in consts else (int(v) if v.isdigit() else None)

entries=[]
for eid,body in re.findall(r"\{\s*\n\s*id = \"(.*?)\",(.*?)\n    \},", raw, re.S):
    def g(k):
        m=re.search(rf"\b{k} = (.+?),?\n",body)
        return m.group(1).strip().rstrip(",") if m else None
    entries.append({"id":eid,"itemId":num(g("itemId")),"slot":(g("slot") or "").strip('"'),
        "minLevel":num(g("minLevel")),"maxLevel":num(g("maxLevel")),"rank":num(g("curatedRank")),
        "classes":g("classes"),"specs":g("specs"),"sourceType":(g("sourceType") or "").strip('"')})

# his level-70 PALADIN entries, split by spec
SPECMAP={"SPEC_RETRIBUTION":"retribution","SPEC_PROTECTION":"protection","SPEC_HOLY":"holy",
         "SPEC_RET":"retribution","SPEC_PROT":"protection"}
his=collections.defaultdict(lambda: collections.defaultdict(list))
for e in entries:
    if e["minLevel"]!=70: continue
    if e["classes"] not in ("PALADIN",): continue
    sp=SPECMAP.get(e["specs"] or "")
    if not sp: continue
    his[sp][e["slot"]].append((e["rank"],e["itemId"]))

gen=json.load(open("paladin.json")); items=json.load(open("items.json"))
def nm(i): return items.get(str(i),{}).get("name",f"?{i}")

mine=collections.defaultdict(dict)
for sp,d in gen.items():
    if sp=="levelling_1_9": continue
    for b in d["bands"]:
        if b["hi"]>=70 and b["lo"]<=70 and b["faction"] in ("Alliance","Any"):
            mine[sp][b["slot"]]=[p["id"] for p in b["picks"][:3]]

tot=exact=0; ov=0
print(f"{'SPEC':<13}{'SLOT':<15}{'HENRIK CURATED (1,2,3)':<58}MINE (1,2,3)")
print("-"*160)
for sp in ("retribution","protection","holy"):
    for slot in sorted(his[sp]):
        h=[i for _,i in sorted(his[sp][slot])][:3]
        m=mine[sp].get(slot,[])[:3]
        if not h: continue
        tot+=1
        ov+=len(set(h)&set(m))
        mark="=" if h==m else ("~" if set(h)&set(m) else "X")
        if h==m: exact+=1
        print(f"{sp:<13}{slot:<15}{' | '.join(nm(i) for i in h)[:56]:<58}{mark} {' | '.join(nm(i) for i in m)[:60]}")
print("-"*160)
print(f"slots compared: {tot}   exact top-3 match: {exact}   avg overlap: {ov/max(tot,1):.2f}/3")
