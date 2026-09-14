"""Expand random-suffix / random-property items into concrete stat variants."""
import csv, json, re, sqlite3, collections
D="/home/claude/gq/dbc/"
def rd(fn): return list(csv.DictReader(open(D+fn, encoding="utf-8-sig")))

suffix={int(r["id"]):r for r in rd("ItemRandomSuffix.tbc243.csv")}
prop  ={int(r["id"]):r for r in rd("ItemRandomProperties.tbc243.csv")}
ench  ={int(r["id"]):r for r in rd("SpellItemEnchantment.tbc243.csv")}
randpp={int(r["item_level"]):r for r in rd("RandPropPoints.tbc243.csv")}

MOD={0:"mana",1:"health",3:"agi",4:"str",5:"int",6:"spi",7:"sta",12:"defense",13:"dodge",
     14:"parry",15:"blockRating",16:"hit",17:"hitRanged",18:"spellHit",19:"crit",
     20:"critRanged",21:"spellCrit",28:"haste",29:"hasteRanged",30:"spellHaste",
     31:"hit",32:"crit",35:"resilience",36:"haste",37:"expertise"}
SLOT_IDX={1:0,5:0,7:0,17:0,20:0,4:0, 3:1,6:1,8:1,10:1,12:1,
          2:2,9:2,11:2,14:2,16:2,23:2, 13:3,21:3,22:3, 15:4,25:4,26:4}
BAND={2:"uncommon",3:"rare",4:"epic",5:"epic"}

# ---- parse the human-readable SpellItemEnchantment name (type 3 / classic) ----
NAME_RX=[
 (r"^\+(\d+) Strength$","str"), (r"^\+(\d+) Stamina$","sta"), (r"^\+(\d+) Agility$","agi"),
 (r"^\+(\d+) Intellect$","int"), (r"^\+(\d+) Spirit$","spi"), (r"^\+(\d+) Armor$","armor"),
 (r"^\+(\d+) Attack Power$","ap"), (r"^\+(\d+) Ranged Attack Power$","rap"),
 (r"^\+(\d+) Defense Rating$","defense"), (r"^\+(\d+) Critical Strike Rating$","crit"),
 (r"^\+(\d+) Block Rating$","blockRating"), (r"^\+(\d+) Dodge Rating$","dodge"),
 (r"^\+(\d+) Damage and Healing Spells$","sp"),
 (r"^\+(\d+) (?:Arcane|Shadow|Fire|Frost|Nature|Holy) Spell Damage$","spSchool"),
 (r"^\+(\d+) mana every 5 sec\.$","mp5"),
 (r"^\+(\d+) health every 5 sec\.$","hp5"),
 (r"^\+(\d+) Damage$","wpnDmg"),
 (r"^\+(\d+) (?:Arcane|Shadow|Fire|Frost|Nature) Resistance$","resist"),
 (r"^\+(\d+) Resist Shadow$","resist"),
 (r"^\+(\d+) (?:Two-Handed )?(?:Sword|Mace|Axe|Ase|Dagger|Gun|Bow) Skill$","wpnSkill"),
 (r"^\+(\d+) Beast Slaying$","beastSlaying"),
]
NAME_RX=[(re.compile(p),k) for p,k in NAME_RX]
HEAL_RX=re.compile(r"^\+(\d+) Healing Spells and \+(\d+) Damage Spells$")

def from_name(nm):
    m=HEAL_RX.match(nm)
    if m: return {"heal":int(m.group(1)),"sp_from_heal":int(m.group(2))},None
    for rx,k in NAME_RX:
        mm=rx.match(nm)
        if mm: return {k:int(mm.group(1))},None
    return {},nm

def suffix_factor(ilvl,quality,inv):
    si=SLOT_IDX.get(inv); band=BAND.get(quality)
    if si is None or band is None: return 0
    row=randpp.get(ilvl)
    return int(float(row[f"{band}_{si}"])) if row else 0

def resolve(eid,alloc,factor):
    e=ench.get(eid)
    if not e: return {},["missing:%d"%eid]
    out={}; unk=[]
    for k in range(3):
        typ=int(e[f"type_{k}"] or 0)
        if typ==0: continue
        amt=int(e[f"amount_{k}"] or 0); arg=int(e[f"spellid_{k}"] or 0)
        if typ==5:                              # scaled STAT (TBC suffixes)
            val=(alloc*factor)//10000 if alloc else amt
            key=MOD.get(arg)
            if key and val: out[key]=out.get(key,0)+val
        elif typ in (2,3,4):
            nm=e["name"]
            if "$" in nm:                       # TBC scaled suffix, value from allocation
                val=(alloc*factor)//10000
                key=None
                if   "Spell Damage and Healing" in nm: key="sp"
                elif re.search(r"\$i (?:Arcane|Fire|Nature|Frost|Shadow|Holy) Damage",nm): key="spSchool"
                elif "Healing" in nm:            key="heal"
                elif "Mana Per 5" in nm:         key="mp5"
                elif "Health per 5" in nm:       key="hp5"
                elif "Resistance" in nm:         key="resist"
                elif "Intellect" in nm:          key="int"
                elif "Armor" in nm:              key="armor"
                if key and val: out[key]=out.get(key,0)+val
                elif not key: unk.append(nm)
            else:                               # classic: value is in the name
                s,u=from_name(nm)
                for kk,vv in s.items(): out[kk]=out.get(kk,0)+vv
                if u: unk.append(u)
            break
    return out,unk

con=sqlite3.connect("/home/claude/gq/tbc.db")
groups=collections.defaultdict(list)
for entry,e,ch in con.execute("SELECT CAST(entry AS INT),CAST(ench AS INT),CAST(chance AS REAL) FROM item_enchantment_template"):
    groups[entry].append((e,ch))

items=json.load(open("/home/claude/gq/items.json"))
out={}; unknown=collections.Counter()
for iid,it in items.items():
    variants=[]
    for kind,gid in (("suffix",it["randSuffix"]),("prop",it["randProp"])):
        if not gid or gid not in groups: continue
        fac=suffix_factor(it["ilvl"],it["quality"],it["inv"]) if kind=="suffix" else 0
        for eid,chance in groups[gid]:
            src=suffix.get(eid) if kind=="suffix" else prop.get(eid)
            if not src: continue
            tot={}; unk=[]
            for k in range(3):
                ee=int(src.get(f"enchant_id_{k}") or 0)
                if not ee: continue
                al=int(src.get(f"allocation_pct_{k}") or 0) if kind=="suffix" else 0
                s,u=resolve(ee,al,fac)
                for kk,vv in s.items(): tot[kk]=tot.get(kk,0)+vv
                unk+=u
            for u in unk: unknown[u]+=1
            if tot:
                variants.append({"suffix":src["name"],"chance":round(chance,2),
                                 "stats":tot,"kind":kind})
    if variants:
        agg=collections.defaultdict(float)
        for v in variants: agg[v["suffix"]]+=v["chance"]
        for v in variants: v["chanceAny"]=round(agg[v["suffix"]],2)
        out[iid]=variants
json.dump(out,open("/home/claude/gq/items_random.json","w"))
print(f"items with random variants: {len(out)}")
print(f"unresolved enchant names: {len(unknown)} -> {unknown.most_common(6)}")
for probe,label in (("15487","War Torn Tunic"),("24685","Elementalist Belt")):
    if probe in out:
        it=items[probe]
        print(f"\n{label} (ilvl {it['ilvl']} q{it['quality']}) base={it['stats']}")
        agg=collections.defaultdict(float)
        for v in out[probe]: agg[v["suffix"]]+=v["chance"]
        top=sorted(out[probe],key=lambda v:-sum(v["stats"].values()))[:6]
        for v in top:
            print(f"   {v['chance']:>5}% (all '{v['suffix']}' rolls {agg[v['suffix']]:.2f}%)  {v['suffix']:<20} {v['stats']}")
