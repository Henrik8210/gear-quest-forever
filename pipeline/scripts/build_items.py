"""Parse wowhead TBC tooltips + cmangos item_template into one normalized item table."""
import json, re, html, sqlite3, sys, os

TIP="/tmp/wowsims-tbc/assets/item_data/all_item_tooltips.csv"
DB ="/home/claude/gq/tbc.db"
OUT="/home/claude/gq/items.json"

# ---- ITEM_MOD ids (2.4.3) -> normalized stat keys -------------------------
MOD={0:"mana",1:"health",3:"agi",4:"str",5:"int",6:"spi",7:"sta",
     12:"defense",13:"dodge",14:"parry",15:"blockRating",
     16:"hit",17:"hitRanged",18:"spellHit",19:"crit",20:"critRanged",21:"spellCrit",
     28:"haste",29:"hasteRanged",30:"spellHaste",
     31:"hit",32:"crit",33:"hitTaken",34:"critTaken",35:"resilience",36:"haste",37:"expertise"}

# ---- InventoryType -> GearQuest slot -------------------------------------
INV={1:"Head",2:"Neck",3:"Shoulder",5:"Chest",20:"Chest",6:"Waist",7:"Legs",8:"Feet",
     9:"Wrist",10:"Hands",11:"Finger",12:"Trinket",16:"Back",14:"Shield",
     13:"OneHand",17:"TwoHand",21:"MainHand",22:"OffHand",23:"Held",
     15:"Ranged",26:"Ranged",25:"Thrown",28:"Relic",4:"Shirt",19:"Tabard"}
ARMOR_SUB={0:"Misc",1:"Cloth",2:"Leather",3:"Mail",4:"Plate",5:"Buckler",6:"Shield",
           7:"Libram",8:"Idol",9:"Totem",10:"Sigil"}
WEAP_SUB={0:"Axe1H",1:"Axe2H",2:"Bow",3:"Gun",4:"Mace1H",5:"Mace2H",6:"Polearm",7:"Sword1H",
          8:"Sword2H",10:"Staff",13:"Fist",14:"MiscWeapon",15:"Dagger",16:"Thrown",
          18:"Crossbow",19:"Wand",20:"FishingPole"}

# ---- text patterns for spell-driven equip effects ------------------------
PATS=[
 (r"Increases damage and healing done by magical spells and effects by up to (\d+)","sp"),
 (r"Increases healing done by up to (\d+) and damage done by up to (\d+) for all magical spells","heal_sp"),
 (r"Increases attack power by (\d+) in Cat, Bear, Dire Bear, and Moonkin forms only","feralAp"),
 # "melee and ranged attack power" is a distinct wording the plain "attack power"
 # pattern never matched, so items using it scored zero for it -- Andonisus, Reaper
 # of Souls carried +600 attack power as an unscored line.
 (r"Increases melee and ranged attack power by (\d+)","ap"),
 (r"Increases your melee and ranged attack power by (\d+)","ap"),
 # Conditional on creature type. The generic AP pattern below matched these too, so
 # "Increases attack power by 60 when fighting Undead" was scored as a flat +60 AP --
 # which made Gauntlets of Undead Slaying rank 1 on Hands at level 59 for both DPS
 # warrior specs, ahead of a guaranteed epic. 41 items carry one of these.
 (r"Increases attack power by (\d+) when fighting \w+","apVs"),
 (r"Increases attack power by (\d+)","ap"),
 (r"Increases ranged attack power by (\d+)","rap"),
 (r"Restores (\d+) mana per 5 sec","mp5"),
 # The SCHOOL matters, so it is captured rather than collapsed. "+Fire damage" is
 # worth full value to a fire mage and exactly nothing to a shadow priest, and the
 # old spSchool key -- one number for all six schools -- could not tell them apart.
 # This is the same class of error as pricing melee haste for a Balance druid.
 # spSchool is still emitted alongside, so nothing that reads it breaks.
 (r"Increases damage done by (Shadow|Fire|Frost|Nature|Arcane|Holy) spells and effects by up to (\d+)","spSchoolNamed"),
 (r"Increases the block value of your shield by (\d+)","blockValue"),
 (r"Your attacks ignore (\d+) of your opponent's armor","armorPen"),
 (r"Increases your spell penetration by (\d+)","spellPen"),
 (r"Restores (\d+) health per 5 sec","hp5"),
 (r"^\+(\d+) Armor","armor"),
 (r"^\+(\d+) (?:Nature|Arcane|Frost|Fire|Shadow|Holy) Resistance","resist"),
 (r"Improves critical strike rating by (\d+)","crit"),
 (r"Increases your critical strike rating by (\d+)","crit"),
 (r"Improves spell critical strike rating by (\d+)","spellCrit"),
 (r"Increases your spell critical strike rating by (\d+)","spellCrit"),
 (r"Improves hit rating by (\d+)","hit"),
 (r"Increases your hit rating by (\d+)","hit"),
 (r"Improves spell hit rating by (\d+)","spellHit"),
 (r"Increases your spell hit rating by (\d+)","spellHit"),
 (r"Increases defense rating by (\d+)","defense"),
 (r"Increases your dodge rating by (\d+)","dodge"),
 (r"Increases your parry rating by (\d+)","parry"),
 (r"Increases your shield block rating by (\d+)","blockRating"),
 (r"Increases your block rating by (\d+)","blockRating"),
 (r"Improves haste rating by (\d+)","haste"),
 (r"Improves spell haste rating by (\d+)","spellHaste"),
 (r"Increases your expertise rating by (\d+)","expertise"),
 (r"Improves your resilience rating by (\d+)","resilience"),
]
PATS=[(re.compile(p),k) for p,k in PATS]
rx_tag=re.compile(r"<[^>]+>")
def plain(s):
    s=re.sub(r"<!--[^>]*?-->","",s)
    return html.unescape(rx_tag.sub("",s))

def parse_tooltip(t):
    o={"stats":{}, "flags":[]}
    def add(k,v):
        o["stats"][k]=o["stats"].get(k,0)+v
    m=re.search(r"<!--ilvl-->(\d+)",t);  o["ilvl"]=int(m.group(1)) if m else 0
    m=re.search(r"<!--rlvl-->(\d+)",t);  o["rlvl"]=int(m.group(1)) if m else 0
    m=re.search(r"<!--amr-->(\d+)",t)
    if m: add("armor",int(m.group(1)))
    m=re.search(r"<!--dmg-->([\d.]+) - ([\d.]+)",t)
    if m: o["dmgMin"],o["dmgMax"]=float(m.group(1)),float(m.group(2))
    m=re.search(r"<!--spd-->([\d.]+)",t)
    if m: o["speed"]=float(m.group(1))
    m=re.search(r"<!--dps-->\(([\d.]+)",t)
    if m: o["dps"]=float(m.group(1))
    m=re.search(r'whtt-extra">Phase (\d+)',t)
    if m: o["phase"]=int(m.group(1))
    # explicit stat / rating markers
    for sid,val in re.findall(r"<!--stat(\d+)-->\+?(-?\d+)",t):
        k=MOD.get(int(sid))
        if k: add(k,int(val))
    for sid,val in re.findall(r"<!--rtg(\d+)-->\+?(-?\d+)",t):
        k=MOD.get(int(sid))
        if k: add(k,int(val))
    # spell-driven equip effects (skip Use:, those are on-use procs)
    for m in re.finditer(r'<span class="q2">Equip:(.*?)</span>',t,re.S):
        raw=m.group(1)
        if "<!--rtg" in raw:      # already captured by the rtg marker scan
            continue
        line=plain(raw).strip()
        for rx,key in PATS:
            mm=rx.search(line)
            if not mm: continue
            if key=="heal_sp":
                add("heal",int(mm.group(1))); add("sp_from_heal",int(mm.group(2)))
            elif key=="spSchoolNamed":
                school,amt=mm.group(1),int(mm.group(2))
                add("spSchool",amt)                 # blended key, kept for compatibility
                add("sp"+school,amt)                # spShadow / spFire / spFrost / ...
            else:
                add(key,int(mm.group(1)))
            break
        else:
            o["flags"].append("unscored:"+line[:70])
    # Effect text. Every Equip / Use / Chance-on-hit line is kept verbatim, whether
    # or not the scorer can price it. Two reasons. The addon should be able to tell
    # the player WHY an item is good. And some items are worth having for an effect
    # alone: Thunderfury's printed stats are 5 Agility and 8 Stamina, Flurry Axe has
    # none at all, yet Wowhead's tank guide ranks Thunderfury first in the slot on
    # the strength of its proc. A stat-weight model cannot see that, so at minimum it
    # must not hide it.
    eff=[]
    for m in re.finditer(r'<span class="q2">((?:Equip|Use|Chance on hit):.*?)</span>',t,re.S):
        line=plain(m.group(1)).strip()
        if line: eff.append(line[:400])
    if eff: o["effects"]=eff
    # An item whose value is almost entirely an unpriceable effect: real effect text,
    # negligible scoreable stats. Flagged so the review page and the addon can show
    # it beside the top 3 rather than letting the score bury it.
    PROCLIKE=re.compile(r"Chance on hit|^Use:|chance to|Equip: Chance", re.I)
    procs=[e for e in eff if PROCLIKE.search(e)]
    o["procs"]=procs
    o["_effectDriven"]=bool(procs) and sum(
        v for k,v in o["stats"].items() if k not in ("armor","block")) <= 40

    # sockets
    socks=re.findall(r'class="socket-(red|yellow|blue|meta) q0"',t)
    if socks: o["sockets"]=socks
    m=re.search(r'Socket Bonus: (?:<a[^>]*>)?([^<]+)',t)
    if m: o["socketBonus"]=m.group(1).strip()
    # Conjured / duration-limited items are not gear. Andonisus, Reaper of Souls
    # exists for 5 real-time minutes during the Atiesh encounter and drains 5% of
    # your health per second; it has no business in a BiS list.
    if "Conjured Item" in t or re.search(r"Duration: \d+ (?:min|sec|hour)", t):
        o["temporary"]=True
    if "&lt;Random enchantment&gt;" in t: o["randomEnchant"]=True
    if "Binds when picked up" in t: o["bind"]="BoP"
    elif "Binds when equipped" in t: o["bind"]="BoE"
    m=re.search(r'whtt-droppedby">Dropped by: ([^<]+)',t)
    if m: o["droppedBy"]=html.unescape(m.group(1)).strip()
    cl=re.findall(r'wowhead-tooltip-item-classes">Classes: (.*?)</div>',t,re.S)
    if cl: o["tipClasses"]=[html.unescape(x) for x in re.findall(r'class="c\d+">([^<]+)<',cl[0])]
    # non-level gates that wowhead states explicitly
    ms=re.findall(r"Requires <a[^>]*>([^<]+)</a> \((\d+)\)",t)
    if ms: o["reqSkills"]=[[a,int(b)] for a,b in ms]
    mr=re.findall(r"Requires <a[^>]*>([^<]+)</a> - (Friendly|Honored|Revered|Exalted)",t)
    if mr: o["reqRep"]=[[a,b] for a,b in mr]
    m=re.search(r'<!--scstart(\d+):(\d+)-->',t)
    if m: o["tipClass"],o["tipSub"]=int(m.group(1)),int(m.group(2))
    return o

# ---------------- load tooltips -------------------------------------------
tips={}
with open(TIP,encoding="utf-8") as f:
    next(f)
    for line in f:
        a=line.split(",",2)
        if len(a)<3: continue
        try:
            iid=int(a[0]); d=json.loads(a[2].strip())
        except Exception: continue
        p=parse_tooltip(d.get("tooltip",""))
        p["name"]=d.get("name"); p["quality"]=d.get("quality",0); p["icon"]=d.get("icon")
        tips[iid]=p
print(f"tooltips parsed: {len(tips)}",file=sys.stderr)

# ---------------- join item_template -------------------------------------
con=sqlite3.connect(DB); con.row_factory=sqlite3.Row
q="""SELECT CAST(entry AS INT) entry, name, CAST(class AS INT) cls, CAST(subclass AS INT) sub,
     CAST(Quality AS INT) qual, CAST(InventoryType AS INT) inv, CAST(AllowableClass AS INT) acl,
     CAST(AllowableRace AS INT) arace, CAST(ItemLevel AS INT) ilvl, CAST(RequiredLevel AS INT) rlvl,
     CAST(RandomProperty AS INT) rprop, CAST(RandomSuffix AS INT) rsuf,
     CAST(RequiredSkill AS INT) rskill, CAST(RequiredSkillRank AS INT) rskillrank, CAST(armor AS INT) armor, CAST(block AS INT) block,
     CAST(delay AS INT) delay, CAST(itemset AS INT) iset, CAST(Flags AS INT) flags,
     CAST(bonding AS INT) bonding
     FROM item_template"""
items={}
for r in con.execute(q):
    iid=r["entry"]
    slot=INV.get(r["inv"])
    if slot is None or slot in ("Shirt","Tabard"): continue
    if r["cls"] not in (2,4): continue          # 2=Weapon 4=Armor
    t=tips.get(iid,{})
    kind = ARMOR_SUB.get(r["sub"],"?") if r["cls"]==4 else WEAP_SUB.get(r["sub"],"?")
    items[iid]={
      "id":iid, "name":t.get("name") or r["name"], "slot":slot,
      "quality":r["qual"], "ilvl":r["ilvl"] or t.get("ilvl",0),
      "rlvl":r["rlvl"] or t.get("rlvl",0),
      "cls":r["cls"], "sub":r["sub"], "kind":kind, "inv":r["inv"],
      "allowClass":r["acl"], "allowRace":r["arace"],
      "randProp":r["rprop"], "randSuffix":r["rsuf"], "reqSkill":r["rskill"], "reqSkillRank":r["rskillrank"],
      "block":r["block"], "delay":r["delay"], "itemset":r["iset"], "bonding":r["bonding"],
      "stats":t.get("stats",{}), "dps":t.get("dps",0.0), "speed":t.get("speed",0.0),
      "dmgMin":t.get("dmgMin",0.0),"dmgMax":t.get("dmgMax",0.0),
      "sockets":t.get("sockets",[]), "socketBonus":t.get("socketBonus"),
      "phase":t.get("phase"), "bind":t.get("bind"), "droppedBy":t.get("droppedBy"),
      "randomEnchant":t.get("randomEnchant",False),
      "hasTip":iid in tips, "flags":t.get("flags",[]),
      "reqSkills":t.get("reqSkills",[]), "reqRep":t.get("reqRep",[]),
      "temporary":t.get("temporary",False),
      "effects":t.get("effects",[]), "procs":t.get("procs",[]),
      "effectDriven":t.get("_effectDriven",False),
      "tipClasses":t.get("tipClasses",[]),
    }
print(f"gear+weapon items: {len(items)}",file=sys.stderr)
missing=[i for i,v in items.items() if not v["hasTip"]]
print(f"  without tooltip: {len(missing)}",file=sys.stderr)
json.dump(items,open(OUT,"w"))
print(f"wrote {OUT}",file=sys.stderr)

# quick sanity
for iid in (15487,2965,28749,29081,2109,23323):
    v=items.get(iid)
    if v: print(f"  {iid:>6} {v['name'][:32]:<32} {v['slot']:<10} {v['kind']:<8} rlvl{v['rlvl']:<3} ilvl{v['ilvl']:<4} {v['stats']}",file=sys.stderr)
