"""Derive which faction each PvP / battleground reward name family belongs to.

Two evidence rules, in order. Nothing here is asserted from memory:

  1. VENDOR   -- every quartermaster row for the prefix is on one side.
  2. MIRROR   -- the prefix has no vendor evidence, but its items are a slot+ilvl+
                 armour-class mirror of a prefix already gated to one side, in at
                 least MIRROR_MIN places. Battleground reward sets come in exactly
                 two versions, one per faction, itemised identically -- e.g.
                 Sentinel's Chain Leggings and Outrider's Chain Leggings are both
                 Legs / ilvl 65 / Mail. So a mirror of a Horde set is the Alliance
                 set.

A prefix that neither rule settles is left UNGATED and printed, not guessed.
"""
import json, collections

MIRROR_MIN = 3
items=json.load(open("items.json")); srcs=json.load(open("sources.json"))

# The only hand-verified input: which side each PvP quartermaster is on.
NPC_SIDE={
 "Sergeant Major Clate":"Alliance","Lieutenant Jackspring":"Alliance","Gaelden Hammersmith":"Alliance",
 "Captain Dirgehammer":"Alliance","Captain O'Neal":"Alliance","Master Sergeant Biggins":"Alliance",
 "First Sergeant Hola'mahi":"Horde","Stone Guard Zarg":"Horde","Grunnda Wolfheart":"Horde",
 "Kelm Hargunth":"Horde","Vrang Wildgore":"Horde","Sura Wildmane":"Horde",
 "Quartermaster Urgronn":"Horde","Blood Guard Porung":"Horde","Sergeant Thunderhorn":"Horde",
}
PREFIXES=["Private's","Corporal's","Sergeant's","Master Sergeant's","Sergeant Major's","Knight's",
 "Knight-Lieutenant's","Knight-Captain's","Knight-Champion's","Lieutenant Commander's","Commander's",
 "Marshal's","Field Marshal's","Grand Marshal's","Stormpike","Sentinel's","Protector's",
 "Scout's","Grunt's","Senior Sergeant's","First Sergeant's","Stone Guard's","Blood Guard's",
 "Legionnaire's","Centurion's","Champion's","Lieutenant General's","General's","Warlord's",
 "High Warlord's","Frostwolf","Outrider's","Advisor's","Marksman's","Bloodguard's"]
PREFIXES=sorted(set(PREFIXES),key=len,reverse=True)

def pref(name):
    for p in PREFIXES:
        if name.startswith(p): return p
    return None

fam=collections.defaultdict(set)          # prefix -> {(slot, ilvl, kind)}
vend=collections.defaultdict(collections.Counter)
count=collections.Counter()
for k,it in items.items():
    p=pref(it["name"])
    if not p: continue
    count[p]+=1
    fam[p].add((it["slot"],it["ilvl"],it["kind"]))
    npc=(srcs.get(k) or {}).get("npc") or ""
    if npc in NPC_SIDE: vend[p][NPC_SIDE[npc]]+=1

side={}; how={}
for p in count:
    e=vend[p]
    if e and len(e)==1:
        side[p]=list(e)[0]; how[p]="vendor(%d)"%sum(e.values())

OTHER={"Alliance":"Horde","Horde":"Alliance"}
for p in sorted(count):
    if p in side: continue
    best=None
    for q,s in list(side.items()):
        n=len(fam[p]&fam[q])
        if n>=MIRROR_MIN and (best is None or n>best[0]): best=(n,q,s)
    if best:
        side[p]=OTHER[best[2]]; how[p]="mirror of %s x%d"%(best[1],best[0])

print("%-24s %5s  %-9s %s"%("prefix","items","side","evidence"))
for p in sorted(count):
    print("%-24s %5d  %-9s %s"%(p,count[p],side.get(p,"-- UNGATED"),how.get(p,
          "ambiguous %s"%dict(vend[p]) if vend[p] else "no vendor row, no mirror")))
json.dump(side,open("pvp_prefix_faction.json","w"),indent=1,sort_keys=True)
print("\ngated: %d of %d prefixes"%(len(side),len(count)))
