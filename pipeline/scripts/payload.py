"""Interned review payload + interned Data.lua (item facts stored once, not per band)."""
import json, re, collections, unicodedata, os
from gq_paths import G, OUT
CLS=os.environ.get("GQ_CLASS","PALADIN"); LC=CLS.lower()
# The paladin file shipped before the facts table was renamed, and Henrik's merged
# DataAdapter reads GQ.Data.itemFacts for it. Keep that name so a corrected paladin
# file is a drop-in replacement; every later class uses <class>ItemFacts.
FACTS = "itemFacts" if CLS=="PALADIN" else LC+"ItemFacts"
SHORT={"levelling_1_9":"Levels 1\u20139","retribution":"Retribution","protection":"Protection",
       "holy":"Holy","arms":"Arms","fury":"Fury"}
import procs as PROCS
gen=json.load(open(os.path.join(OUT, os.environ.get("GQ_OUT","paladin.json")))); items=json.load(open(G+"items.json"))
rand=json.load(open(G+"items_random.json")); W=json.load(open(G+"weights.json"))
srcs=json.load(open(G+"sources.json"))
LORE=json.load(open(G+"lore.json"))


KEEP=set()
for sp in gen: KEEP|=set(W[CLS][sp]["weights"])
def trim(st): return {k:round(v,2) for k,v in st.items() if k in KEEP and v}

# ---------- 1. interned item dictionary --------------------------------
used=set()
for sp,blob in gen.items():
    for b in blob["bands"]:
        for p in b["picks"][:6]: used.add(p["id"])
        for p in b.get("notableEffects") or []: used.add(p["id"])
ITEM={}
for iid in used:
    it=items[str(iid)]; s=srcs[str(iid)]; v=rand.get(str(iid)) or []
    ITEM[iid]={"n":it["name"],"q":it["quality"],"il":it["ilvl"],"k":it["kind"],
      "dps":round(it["dps"] or 0,1),"sp":round(it["speed"] or 0,2),
      "b":trim(it["stats"]),
      "v":[{"s":x["suffix"],"c":x["chance"],"ca":x.get("chanceAny"),"t":trim(x["stats"])} for x in v],
      "src":s["sourceType"],"ins":s["instructions"],"z":s.get("zone"),"npc":s.get("npc"),
      "qn":s.get("questName"),"pr":s.get("profession"),"sea":s.get("seasonal",False),
      "gs":it.get("reqSkills") or [],"gr":it.get("reqRep") or [],
      # Proc points, precomputed per spec at level 60. The page can then show a score
      # that matches the pipeline instead of the stat-only figure -- Thunderfury read
      # 30.9 on screen against 79 in the generator. These do NOT recompute when the
      # weights are edited live, so they are labelled as fixed in the UI.
      # Proc points come in three flavours because their worth depends on the SLOT,
      # not just the spec: pp for a hand the character swings, ppr for a ranged weapon
      # it actually fires, and ppu for a slot it never attacks with -- where only a
      # "Use:" line can fire at all. Handing the melee weight to a ranged item is what
      # priced Venomstrike's ranged proc at a rogue's 15.0 melee weight (and, in the
      # mirror, gave a hunter zero for the same proc on the weapon it lives by).
      "pp":{sp:round(PROCS.value(it.get("procs") or [], it, sp,
              W[CLS][sp]["weights"], W[CLS][sp].get("dpsWeight",0), 60)[0],1)
            for sp in gen} if it.get("procs") else 0,
      "ppr":{sp:round(PROCS.value(it.get("procs") or [], it, sp,
              W[CLS][sp]["weights"], W[CLS][sp].get("dpsWeightRanged",0), 60)[0],1)
            for sp in gen} if it.get("procs") else 0,
      "ppu":{sp:round(PROCS.value(it.get("procs") or [], it, sp,
              W[CLS][sp]["weights"], 0.0, 60, onUseOnly=True)[0],1)
            for sp in gen} if it.get("procs") else 0,
      "pw":[e[:150] for e in (it.get("procs") or [])[:2]]}

rev={"meta":W["_meta"],"items":ITEM,"specs":{}}
for sp,blob in gen.items():
    cfg=W[CLS][sp]
    bands=[[b["slot"],b["lo"],b["hi"],[[p["id"],p["req"]] for p in b["picks"][:6]],
            [[p["id"],(p["effects"] or [""])[0][:150]] for p in (b.get("notableEffects") or [])],
            b.get("origins") or 0]
           for b in blob["bands"] if b["faction"]=="Alliance"]
    rev["specs"][sp]={"label":cfg["label"],"short":SHORT.get(sp, cfg["label"]),"primary":cfg.get("primary"),
      "weaponStyle":cfg["weaponStyle"],"dpsWeight":cfg.get("dpsWeight",0),
      "dpsWeightRanged":cfg.get("dpsWeightRanged",0.0),
      "weights":cfg["weights"],"bands":bands}
json.dump(rev,open(os.path.join(OUT,"%s.review.json"%LC),"w"),separators=(",",":"))
print("review.json %.2f MB (items interned: %d)"%(os.path.getsize(os.path.join(OUT,"%s.review.json"%LC))/1e6,len(ITEM)))

# ---------- 2. interned Data.lua ---------------------------------------
def lua(v):
    if v is None: return "nil"
    if isinstance(v,bool): return "true" if v else "false"
    if isinstance(v,(int,float)): return repr(v)
    return '"'+str(v).replace("\\","\\\\").replace('"','\\"').replace("\n"," ")+'"'

facts=[]
allused=set()
for sp,blob in gen.items():
    for b in blob["bands"]:
        for p in b["picks"][:3]: allused.add(p["id"])
for iid in sorted(allused):
    s=srcs[str(iid)]; it=items[str(iid)]
    kv=[f'sourceType={lua(s["sourceType"])}',f'instructions={lua(s["instructions"])}']
    for k,val in (("zone",s.get("zone")),("npc",s.get("npc")),
                  ("questName",s.get("questName")),("profession",s.get("profession"))):
        if val: kv.append(f'{k}={lua(val)}')
    if s.get("seasonal"): kv.append("seasonal=true")
    # A short piece of flavour shown under the item's name. Canonical in-game quest text
    # for a quest reward, a note about the boss for a drop, hand-written for the
    # legendaries -- see build_lore.py. Absent for anything with no real story, which is
    # most world drops.
    if LORE.get(str(iid)): kv.append(f'lore={lua(LORE[str(iid)])}')
    pr=(it.get("procs") or [])
    if pr: kv.append(f'proc={lua(pr[0][:180])}')
    facts.append(f'    [{iid}]={{name={lua(it["name"])},{",".join(kv)}}},')

rows=[]
# Identity map over whatever specs this class actually has. It used to be a
# hardcoded paladin dict, so for Warrior both "arms" and "fury" looked up as None
# and emitted spec=nil -- which collapsed two specs into 2,400 duplicate rows.
SPEC={k:k for k in gen if k!="levelling_1_9"}
for sp,blob in gen.items():
    spec=SPEC.get(sp)
    for b in blob["bands"]:
        # Levels 1-9 are handled outside this file entirely, so nothing overlaps:
        # Alliance 1-9 is Henrik's hand-made data, Horde 1-9 ships as its own file.
        # This file is levels 10-60.
        if sp=="levelling_1_9": continue
        for rank,p in enumerate(b["picks"][:3],1):
            extra=""
            if p.get("suffix"):
                extra=f',suffix={lua(p["suffix"])},suffixChance={p.get("chanceAny") or 0}'
                if p.get("suffixId"):
                    extra+=f',suffixId={p["suffixId"]}'
                if p.get("suffixRange"):
                    extra+=f',suffixRange={lua(p["suffixRange"])}'
            org=(b.get("origins") or [None]*3)
            if rank<=len(org) and org[rank-1]=="guide": extra+=',origin="guide"'
            # Two-hander or one-hander + off-hand? Only present on specs that can
            # legally do both, and only on the two weapon slots. The addon uses it to
            # grey the row that does not apply, so a staff and an off-hand item are never
            # both presented as the answer.
            if b.get("route"):
                extra+=f',route={lua(b["route"])}'
            rows.append('    {%d,%s,%d,%d,%d,%s,%s,%s%s},'%(
                p["id"], lua(b["slot"]), b["lo"], b["hi"], rank,
                lua(spec), lua(b["faction"]), p["score"], extra))

notable=[]
for sp,blob in gen.items():
    for b in blob["bands"]:
        for nb in (b.get("notableEffects") or []):
            allused.add(nb["id"])
            extra=""
            if nb.get("suffix"):
                extra=',suffix=%s,suffixChance=%s'%(lua(nb["suffix"]), nb.get("chanceAny") or 0)
                if nb.get("suffixId"):    extra+=',suffixId=%d'%nb["suffixId"]
                if nb.get("suffixRange"): extra+=',suffixRange=%s'%lua(nb["suffixRange"])
            notable.append('    {%d,%s,%d,%d,%s,%s%s},'%(
                nb["id"], lua(b["slot"]), b["lo"], b["hi"], lua(SPEC.get(sp)), lua(b["faction"]), extra))

open(os.path.join(OUT,"Data.%s.generated.lua"%CLS.title()),"w").write(
"""local _, GQ = ...
GQ.Data = GQ.Data or {}

-- GENERATED by the GearQuest BiS pipeline -- """+CLS.title()+""", levels 10-60, all three
-- specs, both factions. Level 70 is deliberately absent: the hand-curated
-- AtlasLoot Phase 3 data already in Data.lua is better than anything this model
-- produces there, and the two must not compete.
--
-- Ranking is pure stat weight (weights.json), plus proc value (procs.py), plus an
-- armour-class multiplier per spec. Random-enchantment items are scored on their
-- BEST roll; suffixChance is the odds of getting any roll of that suffix, and
-- suffixRange is what the roll can actually come out as ("+11-13 Healing, +4-5 Spell
-- Damage"). Show the RANGE in a tooltip, not the top of it: one suffix spans an
-- item-level band, so a looted Shimmering Sash of Healing can read +11 and still be
-- the right item.
--
-- LEVELS 1-9 ARE NOT IN THIS FILE AT ALL, so the three sources never overlap:
--   Alliance 1-9  -> Henrik's hand-made entries in Data.lua
--   Horde 1-9     -> Data."""+CLS.title()+""".Horde.1to9.generated.lua
--   levels 10-60  -> this file
--   level 70      -> Henrik's curated AtlasLoot Phase 3 entries in Data.lua
--
-- At exactly level 60 the picks come from Wowhead's Classic BiS guides for all
-- three specs, not from the model. A TBC item may displace a guide entry only if
-- it beats the guide's own top pick by 20% -- rows carrying origin="guide" are the
-- guide's, the rest are the model's.
--
-- Two tables instead of one, on purpose: everything that is a fact about an
-- ITEM (its name, where it comes from, what to do to get it) is stored once in
-- GQ.Data.<class>ItemFacts. GQ.Data.<class>Picks then holds only the thin per-band
-- rows. The same item shows up in dozens of level bands, so storing the
-- instruction text per row would multiply the file size by roughly 6x.
--
-- <class>Picks row = { itemId, slot, minLevel, maxLevel, rank, spec, faction, score }
--   spec     is always one of "retribution" / "protection" / "holy"
--   faction  is "Alliance" or "Horde"
--   optional: suffix, suffixChance, suffixRange  (random-enchantment items --
--             `score` is the EXPECTED roll, suffixChance the odds of any roll of that
--             suffix, and suffixRange the printable span, e.g.
--             "+11-13 Healing, +4-5 Spell Damage"), and suffixId -- the CLIENT id of
--             the exact tier. MATCH ON suffixId, NEVER ON THE NAME: ItemRandomProperties
--             has 2,012 rows sharing only 45 names, up to 85 tiers called the same
--             thing. "of Healing" alone spans +2/+1 to +84/+28.
--   optional: origin="guide"  (level 60, taken from the Classic BiS guide)

GQ.Data."""+FACTS+""" = {
"""+"\n".join(facts)+"""
}

GQ.Data."""+LC+"""Picks = {
"""+"\n".join(rows)+"""
}

-- Items whose value is a proc the score cannot price -- Thunderfury prints 5 Agility
-- and 8 Stamina. Not part of the top 3; show them alongside it.
-- row = { itemId, slot, minLevel, maxLevel, spec, faction }
GQ.Data."""+LC+"""Notable = {
"""+"\n".join(notable)+"""
}
""")
print("Data.%s.generated.lua %.2f MB, %d picks, %d interned items"%(CLS.title(),
    os.path.getsize(os.path.join(OUT,"Data.%s.generated.lua"%CLS.title()))/1e6,len(rows),len(facts)))

# ---------- 3. comparison against Henrik's hand-curated 1-10 -------------
# Paladin only: that is the class whose early data he made by hand and which we
# therefore have something to compare against.
import sys
if CLS!="PALADIN" or not os.path.exists("/mnt/user-data/uploads/GearQuest/Data.lua"):
    sys.exit(0)
raw=open("/mnt/user-data/uploads/GearQuest/Data.lua",encoding="utf-8").read()
consts=dict(re.findall(r"^local ([A-Z0-9_]+) = (\d+)$",raw,re.M))
def num(v):
    v=(v or "").strip()
    return int(consts[v]) if v in consts else (int(v) if v.isdigit() else None)
his=collections.defaultdict(lambda: collections.defaultdict(list))
for eid,body in re.findall(r"\{\s*\n\s*id = \"(.*?)\",(.*?)\n    \},",raw,re.S):
    def g(k):
        m=re.search(rf"\b{k} = (.+?),?\n",body); return m.group(1).strip().rstrip(",") if m else None
    lo,hi,rk=num(g("minLevel")),num(g("maxLevel")),num(g("curatedRank"))
    slot=(g("slot") or "").strip('"'); iid=num(g("itemId"))
    if not(lo and rk and slot and iid) or lo>9: continue
    for lv in range(lo,min(9,hi or lo)+1): his[slot][lv].append((rk,iid))
mine=collections.defaultdict(dict)
for b in gen["levelling_1_9"]["bands"]:
    if b["faction"]!="Alliance": continue
    for lv in range(b["lo"],b["hi"]+1): mine[b["slot"]][lv]=[p["id"] for p in b["picks"][:3]]
comp=[]
names={}
for slot in sorted(his):
    for lv in sorted(his[slot]):
        h=[i for _,i in sorted(his[slot][lv])][:3]; m=mine.get(slot,{}).get(lv,[])
        if not h or not m: continue
        for i in h+m: names[i]=items.get(str(i),{}).get("name","item %d"%i)
        comp.append({"sl":slot,"lv":lv,"h":h,"m":m,"ov":len(set(h)&set(m))})
rev["compare"]={"rows":comp,"names":names}
json.dump(rev,open(G+"%s.review.json"%LC,"w"),separators=(",",":"))
print("comparison rows:",len(comp),"| review.json %.2f MB"%(os.path.getsize(G+"%s.review.json"%LC)/1e6))
