"""
Rebuild items_random.json from Wowhead's own random-enchantment tables.

Replaces the previous source, cmangos `item_enchantment_template`, which is a
community reconstruction of server-side roll tables and is wrong in both
directions: for Murphstar's group it listed 32 suffixes summing to 128.48%
against Wowhead's 11 summing to 99.8%, put "of Intellect" at 0.1% instead of
7.3%, invented two extra "of Healing" tiers, and on a 66-item sample was MISSING
suffixes Wowhead lists on 44 of them. cmangos TBC, cmangos vanilla and
AzerothCore all ship byte-identical rows, so no emulator DB is usable here, and
no client DBC carries the group mapping at all.

Fetched via wowhead_random.py, keyed by enchant group: one request per
RandomProperty group (stat values are group-constant), one per RandomSuffix item
(values scale with item level, quality and slot -- Wowhead pre-applies that).
589 requests, 0 failures, every group's chances summing to 99-101.5%.
"""
import json, re, sqlite3, collections

wh=json.load(open("wowhead_random.json"))
plan=json.load(open("fetch_plan.json"))
items=json.load(open("items.json"))

# ---- stat-string parser, built from all 62 shapes actually present ---------
SIMPLE={
 "Stamina":"sta","Intellect":"int","Strength":"str","Agility":"agi","Spirit":"spi",
 "Attack Power":"ap","Defense Rating":"defense","Dodge Rating":"dodge",
 "Block Rating":"blockRating","Critical Strike Rating":"crit",
 "Spell Critical Strike Rating":"spellCrit","Healing":"heal",
 "Spell Damage and Healing":"sp","Damage and Healing Spells":"sp",
 "Haste":"haste","Arcane Resistance":"resArcane","Nature Resistance":"resNature","Fire Resistance":"resFire",
 "Frost Resistance":"resFrost","Shadow Resistance":"resShadow","Resist Shadow":"resShadow",
}
# school-locked spell damage: useless outside that school, kept separate so the
# weights can price it apart from generic spell damage
SCHOOL=re.compile(r"^(Arcane|Nature|Fire|Frost|Shadow|Holy)\s+(?:Spell\s+)?Damage$")
NUM=r"\+\(?(\d+)\s*(?:-\s*(\d+))?\)?"
RX=re.compile(NUM+r"\s+(.*)$")
HEALSP=re.compile(r"\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+Healing Spells and \+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+Damage Spells$")
MP5=re.compile(r"\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+[Mm]ana (?:Per|every) (\d+) sec\.?$")
HP5=re.compile(r"\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+[Hh]ealth (?:per|every) (\d+) sec\.?$")

# Every Wowhead suffix line is a RANGE -- "+(11 - 13) Healing Spells and +(4 - 5)
# Damage Spells" -- because one suffix spans an item-level band. Collapsing it to the
# top made the score assume a best-case roll INSIDE the suffix as well as across
# suffixes, and made the addon imply 13 when Henrik's looted Shimmering Sash of
# Healing shows 11. Both ends are kept now: LO for the honest floor, HI for the hunt.
_END=["hi"]
def top(a,b):
    return (int(b) if b else int(a)) if _END[0]=="hi" else int(a)

def parse(s):
    """-> dict of statKey -> best-case value, or None if unparseable."""
    s=s.strip()
    if "$i" in s: return {}                       # Blizzard placeholder text
    m=HEALSP.match(s)
    if m: return {"heal":top(m.group(1),m.group(2)), "sp_from_heal":top(m.group(3),m.group(4))}
    m=MP5.match(s)
    if m:
        v=top(m.group(1),m.group(2)); per=int(m.group(3))
        return {"mp5": round(v*5/per,2)}
    m=HP5.match(s)
    if m: return {}                               # health regen: no combat value
    m=RX.match(s)
    if not m: return None
    v=top(m.group(1),m.group(2)); label=m.group(3).strip()
    if label in SIMPLE: return {SIMPLE[label]: v}
    sm=SCHOOL.match(label)
    if sm:
        # Name the SCHOOL, exactly as build_items.py does for base-item stats. This was
        # the half of the school fix I missed: base items moved to spFire/spShadow/... but
        # the random-suffix table kept writing the school-blind spSchool, and every weight
        # block had just set spSchool to 0 -- so "of Fiery Wrath" (+4-6 Fire Spell Damage)
        # scored ZERO for a fire mage and lost to "of Healing", whose only value to a mage
        # is the +3 spell damage riding along with the healing. Henrik caught it on Willow
        # Belt at level 11. 1,336 variants across 681 base items were affected.
        return {"sp"+sm.group(1): v}
    return None

# ---- map every random-enchant item to its group's fetched table ------------
con=sqlite3.connect("tbc.db")
grp={}
for e,rp,rs in con.execute("SELECT entry,RandomProperty,RandomSuffix FROM item_template"):
    e,rp,rs=int(e),int(rp or 0),int(rs or 0)
    if rp or rs: grp[e]=("P",rp) if rp else ("S",rs)
rep={}                                            # (mech,group) -> representative itemId fetched
for key,members in plan["groups"].items():
    mech,g=key[0],int(key[1:])
    if mech=="P": rep[(mech,g)]=min(members)

out={}; unparsed=collections.Counter(); dropped=0
for iid_s in list(items):
    iid=int(iid_s); g=grp.get(iid)
    if not g: continue
    src = iid if (g[0]=="S" or rep.get(g)==iid) else rep.get(g)
    if src is None or str(src) not in wh: continue
    rows=wh[str(src)]
    if not rows: continue
    vs=[]
    for r in rows:
        st={}
        ok=True
        for frag in r["stats"]:
            p=parse(frag)
            if p is None: unparsed[frag]+=1; ok=False; break
            st.update(p)
        if not ok or not st: continue
        _END[0]="lo"; stLo={}
        for frag in r["stats"]:
            p=parse(frag)
            if p: stLo.update(p)
        _END[0]="hi"
        vs.append({"suffix":r["suffix"] if r["suffix"].startswith("of") else "of "+r["suffix"].lstrip(". "),
                   "chance":r["chance"], "chanceAny":r["chance"],
                   "stats":st,                       # top of the range -- the hunt target
                   "statsMin":stLo})                 # bottom -- what a bad roll gives
    if vs: out[iid_s]=vs
    else: dropped+=1

json.dump(out,open("items_random.json","w"))
print(f"items with rolls: {len(out)}   items whose rolls all dropped: {dropped}")
if unparsed:
    print(f"UNPARSED fragments ({len(unparsed)} shapes):")
    for s,c in unparsed.most_common(12): print(f"   {c:>5}  {s}")
else: print("every stat fragment parsed")
