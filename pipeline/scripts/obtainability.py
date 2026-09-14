"""
Obtainability audit -- v3.

An item is obtainable if its acquisition chain bottoms out in something real.
Cut content dead-ends: a crafted item whose pattern was never given a source, a
quest reward attached to a BETA/test quest, an item that appears in no table at all.

v1 required the source NPC to have a static spawn in `creature`. Wrong: most raid
bosses are script-spawned and carry no row there (Sapphiron: 0 spawns, 15 loot
rows), so it deleted King's Defender, Midnight Chestguard and Torch of the Damned.
Spawn status is no longer consulted.

v3 fixes the remaining false positives, all caused by treating absence of evidence
as evidence of absence. This world DB has real coverage gaps -- npc_vendor holds
only 6.4k rows, and npc_trainer only 388 -- so "no source found" cannot mean
"unobtainable". Two rules only, both requiring positive evidence of a dead end:

  1. CRAFT DEAD END -- a pattern/recipe ITEM exists for the spell, but that pattern
     has no source. This is exactly Onyxia Scale Breastplate: Pattern: Onyxia Scale
     Breastplate (15780) exists, requires Leatherworking 300, and drops from nothing.
     If no pattern item exists the recipe is trainer-taught, so it is fine -- that
     distinction is what previously deleted Linen Cloak and Rough Copper Vest.

  2. TEST QUEST -- the item's only source is a quest whose title is BETA/TEST/UNUSED.
     Quest-giver presence is deliberately NOT used: gameobject_questrelation is
     absent from this DB, so every "WANTED:" poster quest looks giverless.

Items with no source anywhere are FLAGGED for review, never deleted.
"""
import sqlite3, csv, json, collections, re

c=sqlite3.connect("tbc.db"); c.execute("PRAGMA cache_size=-200000")
Q=lambda s,*a: c.execute(s,*(a,) if a else ()).fetchall()
I=lambda x: int(x) if x not in (None,"") else 0
have=lambda t: bool(Q("SELECT name FROM sqlite_master WHERE type='table' AND name=?",t))

src=collections.defaultdict(set)

# ---- reference loot, resolved transitively -------------------------------
ref=collections.defaultdict(list)
for e,it,mc in Q("SELECT entry,item,mincountOrRef FROM reference_loot_template"):
    ref[I(e)].append((I(it),I(mc)))
def expand(r, depth=0, seen=None):
    seen = seen or set()
    if r in seen or depth>6: return
    seen.add(r)
    for it,mc in ref.get(r,()):
        if mc<0: yield from expand(-mc, depth+1, seen)
        elif it>0: yield it

# ---- every loot table, spawn status ignored ------------------------------
LOOT=["creature_loot_template","gameobject_loot_template","item_loot_template",
      "fishing_loot_template","skinning_loot_template","pickpocketing_loot_template",
      "mail_loot_template","prospecting_loot_template","disenchant_loot_template"]
for t in LOOT:
    if not have(t): continue
    kind=t.replace("_loot_template","")
    for e,it,mc in Q(f"SELECT entry,item,mincountOrRef FROM {t}"):
        it,mc=I(it),I(mc)
        if mc<0:
            for ri in expand(-mc): src[ri].add(kind)
        elif it>0: src[it].add(kind)
for e,it,mc in Q("SELECT entry,item,mincountOrRef FROM reference_loot_template"):
    if I(it)>0: src[I(it)].add("reference")

# ---- vendors (all of them; a vendor with no spawn is rare and harmless) --
for t in ("npc_vendor","npc_vendor_template"):
    for e,it in Q(f"SELECT entry,item FROM {t}"):
        if I(it)>0: src[I(it)].add("vendor")

# ---- quest rewards, minus obvious test content --------------------------
qcols=[r[1] for r in c.execute("PRAGMA table_info(quest_template)")]
rew=[x for x in qcols if x.startswith(("RewItemId","RewChoiceItemId"))]
TEST=re.compile(r"^\s*(BETA|TEST|UNUSED|DEPRECATED|\[?PH\]?)\b", re.I)
qdead={}
for row in Q(f"SELECT entry,Title,{','.join(rew)} FROM quest_template"):
    qid, title = I(row[0]), row[1] or ""
    is_test = bool(TEST.match(title))
    for v in row[2:]:
        if I(v):
            if not is_test: src[I(v)].add("quest")
            else: qdead.setdefault(I(v), f"only source is test quest {qid} '{title[:44]}'")

# ---- crafted: recipe must be learnable ----------------------------------
trainer={I(r[0]) for r in Q("SELECT spell FROM npc_trainer")} | \
        {I(r[0]) for r in Q("SELECT spell FROM npc_trainer_template")}
recipe_of=collections.defaultdict(list)
for e,s1,s2 in Q("SELECT entry,spellid_1,spellid_2 FROM item_template WHERE CAST(class AS INT)=9"):
    for s in (I(s1),I(s2)):
        if s: recipe_of[s].append(I(e))
crafted=collections.defaultdict(list)
for r in csv.DictReader(open("dbc/CraftedItems.tbc243.csv")):
    if r["category"]=="primary" and r["item_id"]:
        crafted[int(r["item_id"])].append((int(r["spell_id"]), r["profession"]))
cdead={}
for iid,recs in crafted.items():
    ok=False; why=None
    for spell,prof in recs:
        pats=recipe_of.get(spell,[])
        if not pats or spell in trainer:
            ok=True; break                      # trainer-taught (no pattern item exists)
        if any(src.get(p) for p in pats):
            ok=True; break                      # pattern itself is obtainable
        why=(f"{prof} spell {spell}: pattern "
             f"{pats[0]} exists but drops from nothing")
    if ok: src[iid].add("craft")
    elif why: cdead[iid]=why

allitems={I(r[0]) for r in Q("SELECT entry FROM item_template")}
nosource=sorted(i for i in allitems if i not in src and i not in cdead and i not in qdead)
json.dump({"sources":{str(k):sorted(v) for k,v in src.items() if v},
           "craftDeadEnd":{str(k):v for k,v in cdead.items() if k not in src},
           "questDeadEnd":{str(k):v for k,v in qdead.items() if k not in src},
           "noSourceFlagged":[str(i) for i in nosource]},
          open("obtainability.json","w"))
print(f"reachable: {len(src)}   EXCLUDE craft dead-end: {len([k for k in cdead if k not in src])}"
      f"   EXCLUDE test-quest-only: {len([k for k in qdead if k not in src])}"
      f"   FLAG no-source: {len(nosource)}")
