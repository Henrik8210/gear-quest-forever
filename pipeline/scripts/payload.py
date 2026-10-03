"""Interned review payload + interned Data.lua (item facts stored once, not per band)."""
import json, re, collections, unicodedata, os
from gq_paths import G, OUT, forever_missing_ids
FOREVER_MISSING = forever_missing_ids()
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

# Embrace of the Viper. The drop line stays on the source. The rest is the
# package result for this class: when 4 pieces are the hunt, when 5 are,
# and which pieces are only there because of the set. Verified 27 Sep 2026
# on both factions. A piece that wins on its own stats still says so.
VIPER_IDS = {6473, 10410, 10411, 10412, 10413}
_VIPER_BONUS = (
    "Set piece of Embrace of the Viper (Wailing Caverns). "
    "(2) +10 Intellect. (3) +10 Attack Power. "
    "(4) At 25% health, restore 100 health and mana over 5 sec, once every 5 min. "
    "(5) Melee attacks can inflict Dream Venom and stun for 1 sec. "
)
VIPER_WHY = {
    "HUNTER": _VIPER_BONUS + (
        "Beast Mastery and Marksmanship: all five pieces are BiS together from 18 to 21. "
        "From 22 the chest falls off and the other four stay through about 24. "
        "Survival keeps all five through 23, and at 24 the legs are what remain. "
        "Collect 4 pieces for the heal and mana, and all 5 for Dream Venom. "
        "The chest and the belt become BiS with the set. Gloves are a hunt from 14 on their own, and the legs from 17. "
        "A druid in all five turns into a serpent. The color follows your race, and Prowl or Stealth slithers."
    ),
    "ROGUE": _VIPER_BONUS + (
        "Combat, Assassination and Subtlety: all five pieces are BiS together from 18 through 23. "
        "Collect 4 pieces for the heal and mana, and all 5 for Dream Venom. "
        "The chest and the belt become BiS with the set. Gloves are a hunt from 14 on their own, and the legs from 17. "
        "A druid in all five turns into a serpent. The color follows your race, and Prowl or Stealth slithers."
    ),
    "SHAMAN": _VIPER_BONUS + (
        "Enhancement: all five pieces are BiS together from 18 through 28. "
        "At 29 the chest falls off and the other four remain. "
        "Collect 4 pieces for the heal and mana, and all 5 for Dream Venom. "
        "The 2-piece intellect is a large part of why the set lasts into the high 20s. "
        "The chest and the belt become BiS with the set. "
        "A druid in all five turns into a serpent. The color follows your race, and Prowl or Stealth slithers."
    ),
    "DRUID": _VIPER_BONUS + (
        "Feral: all five pieces are BiS together from 18 through 23. "
        "Collect 4 pieces for the heal and mana, and all 5 for Dream Venom. "
        "The legs and gloves are strong before the set is finished. The chest becomes BiS with the set. "
        "Wearing all five pieces transforms you into a serpent. The color depends on your race, "
        "and Prowl or Stealth uses a unique slithering animation."
    ),
}

def _drop_plus(src, why):
    raw = (src.get("instructions") or "").strip()
    if not why:
        return raw
    drop = raw.split(". ")[0].strip()
    if drop and not drop.endswith("."):
        drop += "."
    return (drop + " " + why).strip()

def viper_instructions(src):
    """Drop sentence from the source, then the class-verified set note."""
    return _drop_plus(src, VIPER_WHY.get(CLS))

# Defias Leather (Forever set 161) and Chain of the Scarlet Crusade (163).
# Package check 27 Sep 2026: the bonuses are real, and they do not pay for
# the weak slots. Pieces that win do it on their own stats.
DEFIAS_IDS = {10399, 10400, 10401, 10402, 10403}
SCARLET_IDS = {10328, 10329, 10330, 10331, 10332, 10333}
_DEFIAS_BONUS = (
    "Set piece of Defias Leather (The Deadmines). "
    "(2) +5 Arcane Resistance. (3) +15 Attack Power against Humanoids. "
    "(4) Melee attacks from behind have a 5% chance to bleed the target for 68 to 83 damage over 5 sec. "
    "(5) +1 Daggers. "
)
_SCARLET_BONUS = (
    "Set piece of Chain of the Scarlet Crusade (Scarlet Monastery). "
    "(2) +10 Shadow Resistance. (3) +30 Attack Power against Undead. "
    "(4) Taking damage can grant Enraging Light for 10 sec, adding 20 Holy to each melee attack, 60 against Undead. "
    "(5) +1% hit. (6) At 20% health, absorb 480 damage for 10 sec, once every 4 min. "
)
DEFIAS_WHY = {
    "ROGUE": _DEFIAS_BONUS + (
        "Checked for Combat, Assassination and Subtlety. "
        "The legs are a hunt at 14 and 15, and the boots at 15 and 16, until the Fang pieces take those slots. "
        "The chest, gloves and belt stay behind stronger leather even with all five pieces."
    ),
}
SCARLET_WHY = {
    "PALADIN": _SCARLET_BONUS + (
        "For Retribution, the belt is a hunt from 32 to 36, the chest from 34 to 39, and the legs at 39. "
        "The gauntlets sit in the top 3 at 33 and 34. "
        "For Protection, the boots are a hunt from 30 to 36, the bracers from 31 to 35, and the chest from 34 to 39."
    ),
    "WARRIOR": _SCARLET_BONUS + (
        "For Arms and Fury, the belt is a hunt from 32 to 39, the chest from 34 to 39, and the legs at 39. "
        "The gauntlets sit in the top 3 around 33 to 34. "
        "For Protection, the boots are a hunt from 30 to 36, the bracers from 31 to 35, and the chest from 34 to 39."
    ),
}

def set_piece_instructions(iid, src):
    if iid in VIPER_IDS:
        return viper_instructions(src)
    if iid in DEFIAS_IDS:
        return _drop_plus(src, DEFIAS_WHY.get(CLS))
    if iid in SCARLET_IDS:
        return _drop_plus(src, SCARLET_WHY.get(CLS))
    return src["instructions"]

def is_labeled_set_piece(iid):
    if iid in VIPER_IDS and CLS in VIPER_WHY:
        return True
    if iid in DEFIAS_IDS and CLS in DEFIAS_WHY:
        return True
    if iid in SCARLET_IDS and CLS in SCARLET_WHY:
        return True
    return False


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
    s=str(v).replace("\\","\\\\").replace('"','\\"').replace("\n"," ")
    for a,b in (("\u201c","'"),("\u201d","'"),("\u2018","'"),("\u2019","'"),
                ("\u2014","-"),("\u2013","-"),("\u2026","..."),("\u00a0"," "),
                ("\ufffd","'")):
        s=s.replace(a,b)
    return '"'+s+'"'

def unique_picks(picks, n=3):
    seen=set(); out=[]
    for p in picks:
        if p.get("id") in FOREVER_MISSING:
            continue
        name=p.get("name")
        lname=(name or "").lower()
        if "test copy" in lname or "animation as" in lname:
            continue
        if name in seen:
            continue
        seen.add(name)
        out.append(p)
        if len(out)>=n:
            break
    return out

def build_facts(used):
    out=[]
    for iid in sorted(used):
        s=srcs[str(iid)]; it=items[str(iid)]
        st = s["sourceType"]
        if st == "quest_reward" and s.get("seasonal"):
            st = "seasonal_quest"
        instructions = set_piece_instructions(iid, s)
        kv=[f'sourceType={lua(st)}',f'instructions={lua(instructions)}']
        if is_labeled_set_piece(iid):
            kv.append("setPiece=true")
        for k,val in (("zone",s.get("zone")),("npc",s.get("npc")),
                      ("questName",s.get("questName")),("profession",s.get("profession"))):
            if val: kv.append(f'{k}={lua(val)}')
        if s.get("seasonal"): kv.append("seasonal=true")
        if s.get("zoneOpen"): kv.append("zoneOpen=true")
        if LORE.get(str(iid)): kv.append(f'lore={lua(LORE[str(iid)])}')
        pr=(it.get("procs") or [])
        if pr: kv.append(f'proc={lua(pr[0][:180])}')
        extra=[]
        if it.get("quality") is not None: extra.append(f'quality={int(it["quality"])}')
        if it.get("ilvl"): extra.append(f'ilvl={int(it["ilvl"])}')
        if it.get("rlvl"): extra.append(f'reqLevel={int(it["rlvl"])}')
        out.append(f'    [{iid}]={{name={lua(it["name"])},{",".join(extra+kv)}}},')
    return out

allused=set()
rows=[]
# Identity map over whatever specs this class actually has. It used to be a
# hardcoded paladin dict, so for Warrior both "arms" and "fury" looked up as None
# and emitted spec=nil -- which collapsed two specs into 2,400 duplicate rows.
SPEC={k:k for k in gen if k!="levelling_1_9"}
for sp,blob in gen.items():
    spec=SPEC.get(sp)
    for b in blob["bands"]:
        # Alliance 1-9 is Henrik's hand-made data, Horde 1-9 ships as its own file.
        # This file is levels 10-60. Per-spec 1-9 ships in the Early/Horde 1-9 file.
        if sp=="levelling_1_9": continue
        if b.get("hi", 60) <= 9: continue
        primary=unique_picks([p for p in b["picks"] if not p.get("alt")], 3)
        band_picks=primary
        shown_names={p.get("name") for p in band_picks}
        cut=(band_picks[-1].get("score") or 0) if band_picks else 0
        nbs=[nb for nb in (b.get("notableEffects") or [])
             if nb.get("id") not in FOREVER_MISSING
             and nb.get("name") not in shown_names
             and (nb.get("score") is None or nb.get("score") < cut)]
        forever_nb=None
        if band_picks and cut:
            shown_ids={p["id"] for p in band_picks}
            for p in b["picks"]:
                if p.get("alt") or p["id"] in FOREVER_MISSING:
                    continue
                if p["id"] in shown_ids or p.get("name") in shown_names:
                    continue
                sc=p.get("score") or 0
                # Near-miss Forever item: notice-only, never equal/above BiS #3.
                if p["id"]>=200000 and cut*0.98 <= sc < cut:
                    forever_nb=p
                    shown_names.add(p.get("name"))
                    break
        if forever_nb:
            nbs=[forever_nb]+[nb for nb in nbs if nb.get("name")!=forever_nb.get("name")]
        if nbs:
            b["notableEffects"]=nbs[:2]
        seen_ids={p["id"] for p in band_picks}
        seen_names={p.get("name") for p in band_picks}
        for p in b["picks"]:
            if p["id"] in FOREVER_MISSING or p["id"] in seen_ids or p.get("name") in seen_names:
                continue
            seen_ids.add(p["id"]); seen_names.add(p.get("name"))
            band_picks.append(p)
        for p in band_picks:
            allused.add(p["id"])
        for rank,p in enumerate(band_picks,1):
            extra=""
            if p.get("suffix"):
                extra=f',suffix={lua(p["suffix"])}'
                if p.get("chanceAny"):
                    extra+=f',suffixChance={p.get("chanceAny")}'
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
            if p.get("healOnly"):
                extra+=",healOnly=true"
            if p not in primary:
                extra+=",reserve=true"
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
                extra=',suffix=%s'%lua(nb["suffix"])
                if nb.get("chanceAny"):
                    extra+=',suffixChance=%s'%nb.get("chanceAny")
                if nb.get("suffixId"):    extra+=',suffixId=%d'%nb["suffixId"]
                if nb.get("suffixRange"): extra+=',suffixRange=%s'%lua(nb["suffixRange"])
            notable.append('    {%d,%s,%d,%d,%s,%s%s},'%(
                nb["id"], lua(b["slot"]), b["lo"], b["hi"], lua(SPEC.get(sp)), lua(b["faction"]), extra))

facts=build_facts(allused)
open(os.path.join(OUT,"Data.%s.generated.lua"%CLS.title()),"w").write(
"""local GQ = _G.GearQuest
if not GQ then
    error("GearQuest Forever class data loaded without the main addon")
end
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
--             `score` is the JACKPOT roll (top of the suffix range). suffixChance
--             is the odds of any roll of that suffix -- slim, but if it lands it
--             is BiS. suffixRange is the printable span, e.g.
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
