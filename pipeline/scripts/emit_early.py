"""Standalone emitter: Horde-only levels 1-9. Henrik keeps his hand-made Alliance
1-9 data, so this file must contain nothing else -- no Alliance rows, no level 10+."""
import json, os
from gq_paths import G, OUT
CLS=os.environ.get("GQ_CLASS","PALADIN"); LC=CLS.lower()
gen=json.load(open(os.path.join(OUT, os.environ.get("GQ_OUT","paladin.json")))); items=json.load(open(G+"items.json"))
srcs=json.load(open(G+"sources.json"))
LORE=json.load(open(G+"lore.json"))

def lua(v):
    if v is None: return "nil"
    if isinstance(v,bool): return "true" if v else "false"
    if isinstance(v,(int,float)): return repr(v)
    return '"'+str(v).replace("\\","\\\\").replace('"','\\"').replace("\n"," ")+'"'

# Which factions this class needs a 1-9 file for. Paladin and warrior are Horde-only
# because Henrik's curated Data.lua covers Alliance for both by hand (ALLIANCE_MAIL /
# MAIL_MELEE). Hunter is in neither table, so it has no curated early data at all and
# needs BOTH factions.
FACTIONS=[f.strip() for f in os.environ.get("GQ_FACTIONS","Horde").split(",")]
bands=[b for b in gen["levelling_1_9"]["bands"] if b["faction"] in FACTIONS]
assert bands and all(b["hi"]<=9 for b in bands), "band range guard"
used=set()
rows=[]
for b in bands:
    for rank,p in enumerate(b["picks"][:3],1):
        used.add(p["id"])
        extra=""
        if p.get("suffix"):
            # suffixId and suffixRange are what let the addon print the actual numbers
            # instead of just the suffix name. payload.py has emitted them since the
            # random-enchant fix; these two 1-9 emitters were missed, so EVERY random
            # enchant below level 10 -- 137 rows across the nine files -- shipped with
            # no id and no range, and the tooltip could only say "of Strength ~10% on
            # drop" with no stats. Henrik found it on a level 6 paladin.
            extra=(f',suffix={lua(p["suffix"])},suffixChance={p.get("chanceAny") or 0}')
            if p.get("suffixId"):    extra+=f',suffixId={p["suffixId"]}'
            if p.get("suffixRange"): extra+=f',suffixRange={lua(p["suffixRange"])}'
        if b.get("route"):
            extra+=f',route={lua(b["route"])}'
        fac = "" if len(FACTIONS)==1 else ',faction=%s'%lua(b["faction"])
        rows.append('    {%d,%s,%d,%d,%d,%s%s%s},'%(p["id"],lua(b["slot"]),b["lo"],b["hi"],rank,
                                                  lua(p["score"]),fac,extra))
facts=[]
for iid in sorted(used):
    s=srcs[str(iid)]; it=items[str(iid)]
    kv=[f'sourceType={lua(s["sourceType"])}',f'instructions={lua(s["instructions"])}']
    for k,val in (("zone",s.get("zone")),("npc",s.get("npc")),
                  ("questName",s.get("questName")),("profession",s.get("profession"))):
        if val: kv.append(f'{k}={lua(val)}')
    # Flavour shown under the item's name -- canonical quest text, a note about the boss,
    # or hand-written for a legendary. See build_lore.py. Absent where there is no story.
    if LORE.get(str(iid)): kv.append(f'lore={lua(LORE[str(iid)])}')
    facts.append(f'    [{iid}]={{name={lua(it["name"])},{",".join(kv)}}},')

TAG = FACTIONS[0] if len(FACTIONS)==1 else "Early"
out=os.path.join(OUT,"Data.%s.%s.1to9.generated.lua"%(CLS.title(),TAG))
open(out,"w").write("""local _, GQ = ...
GQ.Data = GQ.Data or {}

-- GENERATED -- """+CLS.title()+""", """+(", ".join(FACTIONS).upper())+""", levels 1-9. Nothing else is in this file:
-- no Alliance rows and no level 10 or above, so it can sit next to the
-- hand-made Alliance 1-9 data without either overwriting the other.
--
-- The race filter is the class's own playable races for that faction, not the whole
-- faction: a Horde warrior can be Orc, Undead, Tauren or Troll but never a Blood Elf,
-- so Blood Elf starting quests are gated out. Quests are gated on quest_template.RequiredRaces, and
-- faction-exclusive zones are gated by name -- a vendor standing in Darnassus is
-- not race-restricted, the city is.
--
-- No spec column. """+CLS.title()+"""s have no talents before level 10, so one list serves all
-- three specs across this range.
--
-- row = { itemId, slot, minLevel, maxLevel, rank, score }
--   optional: suffix, suffixChance  (random-enchantment items -- score assumes the
--   best roll, and suffixChance is the odds of getting any roll of that suffix)

GQ.Data."""+LC+TAG+"""1to9Facts = {
"""+"\n".join(facts)+"""
}

GQ.Data."""+LC+TAG+"""1to9 = {
"""+"\n".join(rows)+"""
}
""")
print(f"{os.path.basename(out)}  {os.path.getsize(out)/1024:.0f} KB  {len(rows)} picks, {len(facts)} items")
slots=sorted({b["slot"] for b in bands})
print("slots:", ", ".join(slots))
