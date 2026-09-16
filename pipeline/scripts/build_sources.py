"""
Drop chances are deliberately NOT recorded or shown. The loot-table percentages in
this world DB are per-row group weights, not the "chance this boss drops this item"
figure a player sees on Wowhead -- Kel'Thuzad's Might of Menethil came out as
"~100.0%" where Wowhead says ~14%. Verifying a real drop rate per item is not
feasible across every item we index, so the text now names the source and stops
there.
Resolve every gear item to how you obtain it, with a human-readable instruction."""
import json, sqlite3, collections, csv, re

DB="/home/claude/gq/tbc.db"
con=sqlite3.connect(DB); con.row_factory=sqlite3.Row
items=json.load(open("/home/claude/gq/items.json"))
GEAR=set(int(k) for k in items)

# ---------- zones: AreaTable gives real names ----------------------------
area={}; zbyslug={}
for r in csv.DictReader(open("/home/claude/gq/dbc/AreaTable.2.5.4.csv",encoding="utf-8-sig")):
    aid=int(r["ID"]); nm=r["AreaName_lang"].strip()
    if not nm: continue
    area[aid]={"name":nm,"parent":int(r["ParentAreaID"] or 0),"cont":int(r["ContinentID"] or 0)}
    slug=re.sub(r"[^a-z0-9]","",(r["ZoneName"] or nm).lower())
    zbyslug.setdefault(slug,nm)
def top_zone(aid):
    seen=0
    while aid in area and area[aid]["parent"] and seen<6:
        aid=area[aid]["parent"]; seen+=1
    return area.get(aid,{}).get("name")

MAPS={0:"Eastern Kingdoms",1:"Kalimdor",530:"Outland",
 33:"Shadowfang Keep",34:"The Stockade",36:"The Deadmines",43:"Wailing Caverns",
 47:"Razorfen Kraul",48:"Blackfathom Deeps",70:"Uldaman",90:"Gnomeregan",
 109:"Sunken Temple",129:"Razorfen Downs",189:"Scarlet Monastery",209:"Zul'Farrak",
 229:"Blackrock Spire",230:"Blackrock Depths",249:"Onyxia's Lair",269:"The Black Morass",
 289:"Scholomance",309:"Zul'Gurub",329:"Stratholme",349:"Maraudon",389:"Ragefire Chasm",
 409:"Molten Core",429:"Dire Maul",469:"Blackwing Lair",509:"Ruins of Ahn'Qiraj",
 531:"Temple of Ahn'Qiraj",533:"Naxxramas",534:"Hyjal Summit",540:"The Shattered Halls",
 542:"The Blood Furnace",543:"Hellfire Ramparts",544:"Magtheridon's Lair",
 545:"The Steamvault",546:"The Underbog",547:"The Slave Pens",548:"Serpentshrine Cavern",
 550:"Tempest Keep",552:"The Arcatraz",553:"The Botanica",554:"The Mechanar",
 555:"Shadow Labyrinth",556:"Sethekk Halls",557:"Mana-Tombs",558:"Auchenai Crypts",
 560:"Old Hillsbrad Foothills",564:"Black Temple",565:"Gruul's Lair",568:"Zul'Aman",
 580:"Sunwell Plateau",585:"Magisters' Terrace",
 30:"Alterac Valley",489:"Warsong Gulch",529:"Arathi Basin",566:"Eye of the Storm"}
OPEN={0,1,530}
INSTANCE=set(MAPS)-OPEN

tele=collections.defaultdict(list)
for r in con.execute("SELECT name,CAST(map AS INT) m,CAST(position_x AS REAL) x,CAST(position_y AS REAL) y FROM game_tele"):
    slug=re.sub(r"[^a-z0-9]","",r["name"].lower())
    tele[r["m"]].append((zbyslug.get(slug), r["x"], r["y"]))

spawn={}
for r in con.execute("""SELECT CAST(id AS INT) id, CAST(map AS INT) m, AVG(CAST(position_x AS REAL)) x,
        AVG(CAST(position_y AS REAL)) y, COUNT(*) n FROM creature GROUP BY id,m"""):
    p=spawn.get(r["id"])
    if p is None or r["n"]>p[3]: spawn[r["id"]]=(r["m"],r["x"],r["y"],r["n"])

def creature_place(cid):
    """-> (zone, is_instance)"""
    s=spawn.get(cid)
    if not s: return None,False
    m,x,y,_=s
    if m in INSTANCE: return MAPS[m],True
    best=None;bd=1e18
    for nm,tx,ty in tele.get(m,[]):
        if not nm: continue
        d=(tx-x)**2+(ty-y)**2
        if d<bd: bd=d;best=nm
    return (best if bd<600**2 else MAPS.get(m)), False

cre={r["e"]:dict(r) for r in con.execute("""SELECT CAST(Entry AS INT) e, Name, SubName,
     CAST(MinLevel AS INT) lo, CAST(MaxLevel AS INT) hi, CAST(Rank AS INT) rank,
     CAST(LootId AS INT) loot, CAST(VendorTemplateId AS INT) vt FROM creature_template""")}
lootid2cre=collections.defaultdict(list)
for e,c in cre.items(): lootid2cre[c["loot"] or e].append(e)

# ---------- loot: reference expansion with equal-chance groups -----------
def load_loot(tbl):
    g=collections.defaultdict(list)
    for r in con.execute(f"SELECT CAST(entry AS INT) e,CAST(item AS INT) i,CAST(ChanceOrQuestChance AS REAL) c,CAST(groupid AS INT) gp,CAST(mincountOrRef AS INT) mr FROM {tbl}"):
        g[r["e"]].append((r["i"],r["c"],r["gp"],r["mr"]))
    return g
refs=load_loot("reference_loot_template")
def group_chances(rows):
    """assign each row an effective % (equal split for chance==0 within a groupid)"""
    byg=collections.defaultdict(list)
    for row in rows: byg[row[2]].append(row)
    out=[]
    for gp,rs in byg.items():
        zero=[r for r in rs if not r[1]]
        explicit=sum(abs(r[1]) for r in rs if r[1])
        share=max(0.0,100.0-explicit)/len(zero) if zero else 0.0
        for r in rs: out.append((r, abs(r[1]) if r[1] else share))
    return out
def expand(entry, mult, depth=0):
    """-> [(item, pct)]"""
    if depth>3 or entry not in refs: return []
    res=[]
    for row,pct in group_chances(refs[entry]):
        i,c,gp,mr=row
        if mr<0: res+=expand(-mr, mult*pct/100.0, depth+1)
        elif i in GEAR: res.append((i, mult*pct/100.0))
    return res

drops=collections.defaultdict(list)
for r in con.execute("SELECT CAST(entry AS INT) e,CAST(item AS INT) i,CAST(ChanceOrQuestChance AS REAL) c,CAST(groupid AS INT) gp,CAST(mincountOrRef AS INT) mr FROM creature_loot_template"):
    if r["mr"]<0: tg=expand(-r["mr"], abs(r["c"]) if r["c"] else 100.0)
    elif r["i"] in GEAR: tg=[(r["i"], abs(r["c"]) if r["c"] else 100.0)]
    else: continue
    if not tg: continue
    for cid in lootid2cre.get(r["e"],[]):
        for i,p in tg: drops[i].append((cid,p))

gobj=collections.defaultdict(list)
gnames={int(r["entry"]):r["name"] for r in con.execute("SELECT entry,name FROM gameobject_template")}
gplace={}
for r in con.execute("SELECT CAST(id AS INT) id, CAST(map AS INT) m, COUNT(*) n FROM gameobject GROUP BY id,m"):
    p=gplace.get(r["id"])
    if p is None or r["n"]>p[1]: gplace[r["id"]]=(r["m"],r["n"])
for r in con.execute("SELECT CAST(entry AS INT) e,CAST(item AS INT) i,CAST(ChanceOrQuestChance AS REAL) c,CAST(groupid AS INT) gp,CAST(mincountOrRef AS INT) mr FROM gameobject_loot_template"):
    if r["mr"]<0: tg=expand(-r["mr"], abs(r["c"]) if r["c"] else 100.0)
    elif r["i"] in GEAR: tg=[(r["i"], abs(r["c"]) if r["c"] else 100.0)]
    else: continue
    for i,p in tg: gobj[i].append((r["e"],p))

# ---------- quests ------------------------------------------------------
qcols=[f"RewChoiceItemId{i}" for i in range(1,7)]+[f"RewItemId{i}" for i in range(1,5)]
sel=",".join(f"CAST({c} AS INT) {c}" for c in qcols)
quest_src=collections.defaultdict(list)
for r in con.execute(f"SELECT CAST(entry AS INT) entry,Title,CAST(ZoneOrSort AS INT) zs,CAST(QuestLevel AS INT) ql,CAST(MinLevel AS INT) qmin,CAST(RequiredSkillValue AS INT) qskill,CAST(RequiredClasses AS INT) rc,CAST(RequiredRaces AS INT) rr,{sel} FROM quest_template"):
    for c in qcols:
        if r[c] and r[c] in GEAR:
            zs=r["zs"]
            quest_src[r[c]].append({"quest":r["Title"],"choice":c.startswith("RewChoice"),
                "qlevel":r["ql"],"qmin":r["qmin"],"qskill":r["qskill"] or 0,"reqClass":r["rc"],"reqRace":r["rr"],
                "zone": area.get(zs,{}).get("name") if zs and zs>0 else None})

# ---------- vendors / crafts -------------------------------------------
vend=collections.defaultdict(list); vt2cre=collections.defaultdict(list)
for e,c in cre.items():
    if c["vt"]: vt2cre[c["vt"]].append(e)
for tbl,mapper in (("npc_vendor",lambda e:[e]),("npc_vendor_template",lambda e:vt2cre.get(e,[]))):
    for r in con.execute(f"SELECT CAST(entry AS INT) e,CAST(item AS INT) i,CAST(ExtendedCost AS INT) xc FROM {tbl}"):
        if r["i"] in GEAR:
            for cid in mapper(r["e"]):
                if cid in spawn:            # ignore unspawned test/placeholder vendors
                    vend[r["i"]].append((cid,r["xc"]))

misc=collections.defaultdict(list)
MISC=[("fishing_loot_template","fishing","Fished up"),
      ("pickpocketing_loot_template","pickpocket","Pickpocketed from a humanoid"),
      ("skinning_loot_template","skinning","Skinned from a beast"),
      ("item_loot_template","container","Found inside another item"),
      ("mail_loot_template","mail","Delivered by in-game mail")]
for tbl,kind,txt in MISC:
    for r in con.execute(f"SELECT CAST(item AS INT) i,CAST(ChanceOrQuestChance AS REAL) c,CAST(mincountOrRef AS INT) mr FROM {tbl}"):
        if r["mr"]<0:
            for i,p in expand(-r["mr"], abs(r["c"]) if r["c"] else 100.0): misc[i].append((kind,txt,p))
        elif r["i"] in GEAR: misc[r["i"]].append((kind,txt,abs(r["c"]) if r["c"] else 100.0))

craft={}
for r in csv.DictReader(open("/home/claude/gq/dbc/CraftedItems.tbc243.csv",encoding="utf-8-sig")):
    if r["category"]!="primary" or not r["item_name"]: continue
    try: iid=int(r["item_id"])
    except: continue
    if iid in GEAR: craft[iid]={"profession":r["profession"],"rank":r["min_skill_rank"]}

RANKTXT={1:" (rare elite)",2:" (rare spawn)",3:"",4:" (rare spawn)"}
out={}
for k,it in items.items():
    iid=int(k)
    q=quest_src.get(iid); d=drops.get(iid); v=vend.get(iid); g=gobj.get(iid); c=craft.get(iid)
    ncre=len({x[0] for x in d}) if d else 0
    rec=dict(sourceType=None,instructions=None,zone=None,npc=None,questName=None,
             profession=None,dropChance=None,alts=[],gateLevel=0,questClasses=0,questRaces=0)

    inst_chest=None
    if g:
        for gid,p in sorted(g,key=lambda x:-x[1]):
            mp=gplace.get(gid,(None,0))[0]
            if mp in INSTANCE: inst_chest=(gid,p,MAPS[mp]); break

    named_drop=None
    if d and ncre<=8:
        cid,p=max(d,key=lambda x:x[1]); z,inst=creature_place(cid)
        named_drop=(cid,p,z,inst)

    if named_drop and (named_drop[3] or cre.get(named_drop[0],{}).get("rank")==3):
        cid,p,z,inst=named_drop; cc=cre[cid]
        rec.update(sourceType="boss_drop",npc=cc["Name"],zone=z,dropChance=None,
          instructions="Drops from %s%s."%(cc["Name"]," in %s"%z if z else ""))
        rec["gateLevel"]=min(70,max(1,cc["lo"]-2))
    elif inst_chest:
        gid,p,z=inst_chest
        rec["gateLevel"]=58 if z in ("Black Temple","Sunwell Plateau","Serpentshrine Cavern","Tempest Keep","Hyjal Summit","Gruul's Lair","Magtheridon's Lair","Zul'Aman") else 0
        rec.update(sourceType="boss_drop",npc=gnames.get(gid),zone=z,dropChance=None,
          instructions="Looted from %s in %s."%(gnames.get(gid,"a chest"),z))
    elif q:
        best=min(q,key=lambda x:(x["qmin"] or x["qlevel"] or 0))
        rec["gateLevel"]=min(max(x["qmin"] or x["qlevel"] or 0, -(-(x["qskill"] or 0)//5)) for x in q)
        # Class/race lock. Vanilla tier-3 sets carry no AllowableClass flag on the
        # item, so nothing stopped a paladin's list from picking Dreadnaught
        # (Warrior), Dreamwalker (Druid), Cryptstalker (Hunter) or Circlet of Faith
        # (Priest). The real gate is the quest that hands the piece over:
        # quest_template.RequiredClasses is 1 / 1024 / 4 / 16 for those, and 2 for
        # Redemption, the paladin set. 969 quests carry such a lock. If ANY quest
        # granting the item is unrestricted the item is unrestricted; otherwise the
        # union of the locks is the restriction.
        if any(not x.get("reqClass") for x in q): rec["questClasses"]=0
        else:
            m=0
            for x in q: m |= x["reqClass"] or 0
            rec["questClasses"]=m
        if any(not x.get("reqRace") for x in q): rec["questRaces"]=0
        else:
            m=0
            for x in q: m |= x["reqRace"] or 0
            rec["questRaces"]=m
        rec.update(sourceType="quest_reward",questName=best["quest"],zone=best["zone"],
          instructions="Reward from the quest “%s”%s.%s"%(best["quest"],
            " — pick it over the other choices" if best["choice"] else "",
            " In %s."%best["zone"] if best["zone"] else ""))
    elif c:
        try: rec["gateLevel"]=min(70,max(1,-(-int(c["rank"])//5)))
        except Exception: pass
        rec.update(sourceType="profession",profession=c["profession"],
          instructions="Crafted with %s (requires skill %s)."%(c["profession"],c["rank"]))
    elif named_drop:
        cid,p,z,inst=named_drop; cc=cre[cid]
        rec["gateLevel"]=min(70,max(1,cc["lo"]-4))
        rec.update(sourceType="world_drop",npc=cc["Name"],zone=z,dropChance=None,
          instructions="Drops from %s%s%s."%(cc["Name"],RANKTXT.get(cc["rank"],""),
          " in %s"%z if z else ""))
        rec["alts"]=[{"npc":cre.get(x[0],{}).get("Name"),"chance":round(x[1],2)} for x in sorted(d,key=lambda x:-x[1])[:5]]
    elif v:
        cid,xc=v[0]; z,_=creature_place(cid); cc=cre.get(cid,{})
        rec.update(sourceType="vendor",npc=cc.get("Name"),zone=z,
          instructions="Bought from %s%s%s."%(cc.get("Name","a vendor")," in %s"%z if z else "",
            " — costs tokens or reputation" if xc else ""))
    elif d:
        p=max(x[1] for x in d)
        lv=[cre[x[0]]["lo"] for x in d if x[0] in cre]
        if lv: rec["gateLevel"]=max(1,min(lv)-4)
        rec.update(sourceType="world_drop",dropChance=None,
          # Henrik: "do not call the AH cheapest option, just state that it is available
          # there if that is part of it." Claiming it is cheapest is a claim about a live
          # market this addon cannot see -- on a quiet realm a world drop can be absent
          # from the auction house entirely, or priced above what it is worth. Stating
          # availability is true; stating it is cheapest is a guess dressed as advice.
          instructions="World drop - drops from %d creature types%s. Also found on the auction house."%(
            ncre," around level %d-%d"%(min(lv),max(lv)) if lv else ""))
    elif g:
        gid,p=max(g,key=lambda x:x[1]); nm=gnames.get(gid,"a container")
        rec.update(sourceType="object_drop",npc=nm,dropChance=None,
          instructions="Found in %s."%(nm,))
    elif misc.get(iid):
        kind,txt,p=max(misc[iid],key=lambda x:x[2])
        rec.update(sourceType=kind,dropChance=None,instructions="%s."%(txt,))
    else:
        rec.update(sourceType="unknown",instructions="Source not resolved from the world database.")
    out[k]=rec

SEASONAL=re.compile(r"(?i)(winter veil|winter hat|midsummer|fire festival|lunar festival|hallow'?s end|noblegarden|brewfest|children'?s week|love is in the air|valentine|elders|coin of ancestry|pilgrim)")
for k,rec in out.items():
    blob=" ".join(str(x) for x in (items[k]["name"],rec.get("questName"),rec.get("instructions")))
    rec["seasonal"]=bool(SEASONAL.search(blob))

BAD=re.compile(r"(?i)(deprecated|\btest\b|^monster\s*-|unused|\bOLD\b|\bQA\b|gamemaster|\[PH\]|placeholder|^item\b.*\btest)")
# Hand-verified allowlist: real, obtainable items whose acquisition chain this
# world DB cannot express, so source resolution returns "unknown" and the
# unknown-source rule would drop them. All are legendary craft/turn-in chains --
# Sulfuras is Eye of Sulfuras + Sulfuron Hammer, which is not a SkillLineAbility
# recipe and so is absent from the crafted-items map too. Verified individually;
# add nothing here without checking Wowhead first.
HAND_OBTAINABLE={
 17182: "Sulfuras, Hand of Ragnaros — Eye of Sulfuras (Ragnaros) + Sulfuron Hammer",
 19019: "Thunderfury — Bindings of the Windseeker + Elementium",
 17193: "Sulfuron Hammer — Blacksmithing plan from Molten Core",
 13262: "Ashbringer — quest chain",
 # 22736 was in this list labelled "Ashbringer". It is Andonisus, Reaper of Souls:
 # a conjured 5-minute item from the Atiesh encounter that drains 5% health per
 # second. I put an ID here I had not actually verified, in the same block whose
 # comment says not to. Every ID above has now been checked against item_template
 # by name and against Wowhead.
 17204: "Eye of Sulfuras — drops from Ragnaros",
}

DEVQUEST=re.compile(r"(?i)(ultimate test quest|of doom!|\(test\)|\btesting\b|do not use|\bdeprecated\b|^gm |lee's)")
for k,rec in out.items():
    it=items[k]; why=None
    if BAD.search(it["name"] or ""): why="name marks it as unused/deprecated content"
    elif rec.get("questName") and DEVQUEST.search(rec["questName"]): why="only obtainable from a developer test quest"
    elif it["quality"]>=6: why="artifact/GM-only quality"
    elif int(k) in HAND_OBTAINABLE:
        why=None                                    # verified real; chain not in this DB
        if rec["sourceType"]=="unknown":
            rec["sourceType"]="special"
            rec["instructions"]=HAND_OBTAINABLE[int(k)]+"."
    elif rec["sourceType"]=="unknown": why="no obtain path found in the world database"
    rec["obtainable"]= why is None
    rec["excludedBecause"]=why
json.dump(out,open("/home/claude/gq/sources.json","w"))
print("obtainable:",sum(1 for v in out.values() if v["obtainable"]),"/ excluded:",sum(1 for v in out.values() if not v["obtainable"]))
print("source resolution:",dict(collections.Counter(v["sourceType"] for v in out.values())))
print()
for probe in (15487,2109,2965,3471,28749,23323,29081,5320,3283,6085,2392,3008):
    s=out.get(str(probe))
    if s: print(f"  {probe:>6} {items[str(probe)]['name'][:28]:<28} {s['sourceType']:<13} {s['instructions'][:100]}")
