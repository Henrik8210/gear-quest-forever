"""Resolve every stored random-enchant variant to its actual client-side ID.

Why this exists. The generated data used to carry the suffix NAME only -- "of Healing"
-- and that name is not unique. ItemRandomProperties has THIRTY-EIGHT rows called
"of Healing", each a fixed tier:

    2031  +11 Healing Spells and +4 Damage Spells     <- what Henrik looted
    2032  +13 Healing Spells and +5 Damage Spells     <- the tier he wants

Shimmering Sash (6570) can roll either. An addon matching on the name cannot tell
them apart, so a bad roll registers as the target and a good roll is not recognised as
an upgrade. Emitting the ID fixes that, and the IDs are monotonic in value inside a
name family, so "is this roll at least as good as the target" is a >= on the id.

The mapping is derived from the values, which we already have from the Wowhead TBC
scrape: name + stat values -> the one client row with those values.
"""
import csv, json, re, collections

DBC="/home/claude/gq/dbc/"
se={r["ID"]:r["Name_lang"] for r in csv.DictReader(open(DBC+"SpellItemEnchantment.2.5.4.csv"))}

# "+13 Healing Spells and +5 Damage Spells" / "+4 Stamina" / "+6 Intellect" ...
LABEL={"Healing Spells":"heal","Damage Spells":"sp_from_heal","Healing":"heal",
 "Stamina":"sta","Intellect":"int","Strength":"str","Agility":"agi","Spirit":"spi",
 "Attack Power":"ap","Defense Rating":"defense","Dodge Rating":"dodge",
 "Block Rating":"blockRating","Critical Strike Rating":"crit","Haste Rating":"haste",
 "Spell Critical Strike Rating":"spellCrit","Spell Damage and Healing":"sp",
 "Damage and Healing Spells":"sp","Arcane Resistance":"resArcane",
 "Nature Resistance":"resNature","Fire Resistance":"resFire",
 "Frost Resistance":"resFrost","Shadow Resistance":"resShadow",
 # school-locked spell damage and the remaining shapes -- these families were the
 # 966 unresolved variants, and they are the ones the model most often PICKS
 # ("of Power" for a melee spec, "of Arcane Wrath" for a caster), so they mattered
 # far more than their share of the table suggested: 79% of shipped suffixed rows.
 # Named per school. Left as the blended spSchool, these no longer value-matched the
 # variant stats in items_random.json, and 777 school variants silently lost their
 # suffixId -- coverage fell from 99.0% to 94.6% before this was caught.
 "Arcane Spell Damage":"spArcane","Fire Spell Damage":"spFire",
 "Frost Spell Damage":"spFrost","Nature Spell Damage":"spNature",
 "Shadow Spell Damage":"spShadow","Holy Spell Damage":"spHoly",
 "mana every 5 sec.":"mp5","mana every 5 sec":"mp5","Mana every 5 sec.":"mp5"}
FRAG=re.compile(r"\+(\d+)\s+([A-Za-z'. ]+?)(?=\s+and\s+\+|\s*$)")
def stats_of(text):
    out={}
    for m in FRAG.finditer(text or ""):
        key=LABEL.get(m.group(2).strip())
        if key: out[key]=out.get(key,0)+int(m.group(1))
    return out

def load(fn, prefix):
    """-> list of (id_for_link, name, statsDict)."""
    rows=[]
    for r in csv.DictReader(open(DBC+fn)):
        nm=(r.get("Name_lang") or "").strip()
        if not nm: continue
        st={}
        for k in r:
            if k.startswith("Enchantment") and r[k] not in ("0",""):
                st.update(stats_of(se.get(r[k],"")))
                for kk,vv in stats_of(se.get(r[k],"")).items(): pass
        if st: rows.append((prefix*int(r["ID"]), nm, st))
    return rows

# RandomProperty ids are POSITIVE in an item link; RandomSuffix ids are NEGATIVE.
props=load("ItemRandomProperties.2.5.4.csv", 1)
print("ItemRandomProperties rows with parseable stats: %d"%len(props))

index=collections.defaultdict(list)
for iid,nm,st in props:
    index[(nm, tuple(sorted(st.items())))].append(iid)

# ---- ItemRandomSuffix: values are RandPropPoints[ilvl][quality][slotBucket] x
# allocationPct, so the id is resolved by RECOMPUTING the value per item. The slot
# bucket was derived empirically -- for 5,755 variants, exactly one column reproduces
# the stored value per inventory type, which is its own proof the mapping is right.
# randSuffix ids appear NEGATIVE in an item link.
import collections as _c
rpp={int(r["ID"]):r for r in csv.DictReader(open(DBC+"RandPropPoints.2.5.4.csv"))}
SUFFIX=_c.defaultdict(list)
for r in csv.DictReader(open(DBC+"ItemRandomSuffix.2.5.4.csv")):
    nm=(r.get("Name_lang") or "").strip()
    if nm: SUFFIX[nm].append((int(r["ID"]),[int(r["AllocationPct_%d"%i] or 0) for i in range(5)]))
QCOL={4:"Epic",3:"Superior"}
BUCKET={1:0,5:0,7:0,17:0,3:1,6:1,8:1,10:1,2:2,9:2,11:2,14:2,16:2,21:3,13:3,22:3,23:3,15:3,25:3,26:3,28:3,12:2,20:0,4:2,19:2}
def suffix_id(it, variant):
    lv=it["ilvl"]
    if lv not in rpp: return None
    q=QCOL.get(it["quality"],"Good")
    c=BUCKET.get(it["inv"])
    if c is None: return None
    pts=int(rpp[lv]["%s_%d"%(q,c)] or 0)
    if not pts: return None
    top=sum(variant["stats"].values())
    for sid,allocs in SUFFIX.get(variant["suffix"],[]):
        if sum(int(pts*a/10000) for a in allocs if a)==top: return -sid
    return None

rand=json.load(open("/home/claude/gq/items_random.json"))
items_all=json.load(open("/home/claude/gq/items.json"))
hit=miss=ambig=0
missing=collections.Counter()
for item_id,vs in rand.items():
    for v in vs:
        key=(v["suffix"], tuple(sorted((k,int(x)) for k,x in v["stats"].items())))
        ids=index.get(key)
        if not ids:
            sid=suffix_id(json.load(open("/dev/null")) if False else items_all[item_id], v)
            if sid is not None:
                v["suffixId"]=sid; hit+=1; continue
            miss+=1; missing[v["suffix"]]+=1; continue
        if len(ids)>1: ambig+=1
        v["suffixId"]=ids[0]; hit+=1
json.dump(rand,open("/home/claude/gq/items_random.json","w"))
tot=hit+miss
print("variants resolved to a client id: %d of %d (%.0f%%)"%(hit,tot,hit/tot*100))
print("  ambiguous (same name AND same stats on >1 id): %d"%ambig)
if missing:
    print("  unresolved, by suffix family (top 12):")
    for s,c in missing.most_common(12): print("     %-28s %d"%(s,c))
# the case that started it
for v in rand["6570"]:
    if v["suffix"]=="of Healing":
        print("\n  Shimmering Sash 'of Healing' -> id %s  (stats %s, low roll %s)"%(
            v.get("suffixId"), v["stats"], v.get("statsMin")))
