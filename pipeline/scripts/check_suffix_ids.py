"""Audit EVERY resolved suffixId against the client data, so nobody has to find these
one item at a time.

For each variant that carries a suffixId, recompute what that id actually grants --
from ItemRandomProperties + SpellItemEnchantment for positive ids, and from
ItemRandomSuffix x RandPropPoints for negative ones -- and assert it equals the stored
stats. A mismatch means the id points at the wrong tier, which is the exact class of
bug that produced "+29 Agility" on an item that rolls +8.
"""
import csv, json, collections, sys, re
DBC="/home/claude/gq/dbc/"
se={r["ID"]:r["Name_lang"] for r in csv.DictReader(open(DBC+"SpellItemEnchantment.2.5.4.csv"))}
LABEL={"Healing Spells":"heal","Damage Spells":"sp_from_heal","Healing":"heal",
 "Stamina":"sta","Intellect":"int","Strength":"str","Agility":"agi","Spirit":"spi",
 "Attack Power":"ap","Defense Rating":"defense","Dodge Rating":"dodge",
 "Block Rating":"blockRating","Critical Strike Rating":"crit","Haste Rating":"haste",
 "Spell Critical Strike Rating":"spellCrit","Spell Damage and Healing":"sp",
 "Damage and Healing Spells":"sp","Arcane Resistance":"resArcane",
 "Nature Resistance":"resNature","Fire Resistance":"resFire","Frost Resistance":"resFrost",
 "Shadow Resistance":"resShadow",
 # Named per school, matching build_items.py and build_random_wh.py. The blended
 # spSchool key is gone: it could not tell a fire mage's +Fire from a +Shadow item.
 "Arcane Spell Damage":"spArcane","Fire Spell Damage":"spFire",
 "Frost Spell Damage":"spFrost","Nature Spell Damage":"spNature",
 "Shadow Spell Damage":"spShadow","Holy Spell Damage":"spHoly","mana every 5 sec.":"mp5","mana every 5 sec":"mp5"}
FRAG=re.compile(r"\+(\d+)\s+([A-Za-z'. ]+?)(?=\s+and\s+\+|\s*$)")
def stats_of(t):
    out={}
    for m in FRAG.finditer(t or ""):
        k=LABEL.get(m.group(2).strip())
        if k: out[k]=out.get(k,0)+int(m.group(1))
    return out

PROP={}
for r in csv.DictReader(open(DBC+"ItemRandomProperties.2.5.4.csv")):
    st={}
    for k in r:
        if k.startswith("Enchantment") and r[k] not in ("0",""): st.update(stats_of(se.get(r[k],"")))
    if st: PROP[int(r["ID"])]=(r["Name_lang"].strip(), st)
SUF={}
for r in csv.DictReader(open(DBC+"ItemRandomSuffix.2.5.4.csv")):
    SUF[int(r["ID"])]=(r.get("Name_lang","").strip(),
                       [int(r["AllocationPct_%d"%i] or 0) for i in range(5)],
                       [r["Enchantment_%d"%i] for i in range(5)])
RPP={int(r["ID"]):r for r in csv.DictReader(open(DBC+"RandPropPoints.2.5.4.csv"))}
QCOL={4:"Epic",3:"Superior"}
BUCKET={1:0,5:0,7:0,17:0,3:1,6:1,8:1,10:1,2:2,9:2,11:2,14:2,16:2,12:2,4:2,19:2,20:0,
        21:3,13:3,22:3,23:3,15:3,25:3,26:3,28:3}

items=json.load(open("/home/claude/gq/items.json"))
rand=json.load(open("/home/claude/gq/items_random.json"))
checked=ok=0
bad=[]; nameBad=[]
for iid,vs in rand.items():
    it=items[iid]
    for v in vs:
        sid=v.get("suffixId")
        if not sid: continue
        checked+=1
        if sid>0:
            e=PROP.get(sid)
            if not e: bad.append((iid,it["name"],v["suffix"],sid,"id not in ItemRandomProperties",None)); continue
            nm,st=e
            if nm!=v["suffix"]: nameBad.append((iid,it["name"],v["suffix"],sid,nm))
            if st!={k:int(x) for k,x in v["stats"].items()}:
                bad.append((iid,it["name"],v["suffix"],sid,st,v["stats"])); continue
        else:
            nm,allocs,_=SUF.get(-sid,(None,None,None))
            if nm is None: bad.append((iid,it["name"],v["suffix"],sid,"id not in ItemRandomSuffix",None)); continue
            if nm!=v["suffix"]: nameBad.append((iid,it["name"],v["suffix"],sid,nm))
            lv=it["ilvl"]; c=BUCKET.get(it["inv"])
            if lv not in RPP or c is None: continue
            pts=int(RPP[lv]["%s_%d"%(QCOL.get(it["quality"],"Good"),c)] or 0)
            got=sum(int(pts*a/10000) for a in allocs if a)
            want=sum(int(x) for x in v["stats"].values())
            if got!=want:
                bad.append((iid,it["name"],v["suffix"],sid,"recomputed %d"%got,"stored %d"%want)); continue
        ok+=1
print("suffixIds audited against the client data: %d"%checked)
print("  values agree: %d (%.2f%%)"%(ok,ok/max(checked,1)*100))
print("  name mismatches (id belongs to a different suffix family): %d"%len(nameBad))
print("  VALUE mismatches: %d"%len(bad))
for b in bad[:15]: print("     %s %s / %s  id=%s  %s vs %s"%b)
tot=sum(len(v) for v in rand.values())
print("  variants with no id at all (fall back to the name): %d of %d (%.1f%%)"%(tot-checked,tot,(tot-checked)/tot*100))
# Per-FILE coverage, not just the global figure. The global number is what let R37
# through: 137 rows with no suffixId out of 13,870 reads as a 1% dip, indistinguishable
# from the known unresolvable tail -- while in fact it was 100% of one whole file group.
# Any emitted file whose suffix rows are less than 90% resolved is a bug in that emitter.
import glob as _glob, re as _re
print("\nper-file suffixId coverage in the emitted Lua:")
_bad=0
for _f in sorted(_glob.glob("/home/claude/gq/Data.*.generated.lua")):
    _s=open(_f,encoding="utf-8").read()
    _rows=_re.findall(r'suffix="[^"]*"[^}]*', _s)
    if not _rows: continue
    _with=sum(1 for r in _rows if "suffixId" in r)
    _pct=_with/len(_rows)*100
    _flag = "" if _pct>=90 else "   <-- EMITTER BUG: this file group is not writing suffixId"
    if _pct<90: _bad+=1
    print(f"   {_f.split('/')[-1]:<44}{_with:>5}/{len(_rows):<5} {_pct:5.1f}%{_flag}")

sys.exit(1 if (bad or nameBad or _bad) else 0)
