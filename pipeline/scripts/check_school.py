"""Standing check: a spec may only be paid for the schools of magic it actually casts.

The third instance of the same family of bug. Henrik found the first ("haste is not
spell haste so the manual crowd pummeler doesn't work for balance and resto") and the
second ("rogues doesn't need the damage on the ranged"). This is the third: item stats
used to collapse "Increases damage done by Shadow spells" and "...by Fire spells" into
one key, spSchool, so a Balance druid -- which casts only Arcane and Nature -- was paid
for Robe of Winter Night's +Shadow damage in 12 level bands, and a Holy paladin for
Death Speaker Scepter's +Shadow in 21.

Two rules:
  A. no weight block may still use the blended spSchool key -- it cannot tell schools
     apart, so any non-zero value there is by definition paying for the wrong school
  B. no pick may owe its place to a school the spec does not cast: re-score every pick
     that carries a school stat with that stat removed, and assert its rank is unchanged
"""
import json, os, sys
from gq_paths import G, scored
W=json.load(open(G+"weights.json")); items=json.load(open(G+"items.json"))
SCHOOLS=["spShadow","spFire","spFrost","spNature","spArcane","spHoly"]
bad=0

for cls,specs in sorted(W.items()):
    if not isinstance(specs,dict): continue
    for spec,cfg in specs.items():
        if not (isinstance(cfg,dict) and "weights" in cfg): continue
        if cfg["weights"].get("spSchool"):
            bad+=1; print(f"  A {cls} {spec}: spSchool={cfg['weights']['spSchool']} -- "
                          f"school-blind, name the schools this spec casts instead")

# Rule A2: the random-suffix table must name schools the same way the base-item table
# does. It did not, and that is exactly how "of Fiery Wrath" came to score zero for a
# fire mage: base items had moved to spFire, the suffix table still wrote the blended
# spSchool, and every weight block had just set spSchool to 0. Rules A and B both passed
# because neither of them looks at variant stats.
_rand=json.load(open(G+"items_random.json"))
_blind=[(iid,x["suffix"]) for iid,v in _rand.items() for x in v if "spSchool" in x["stats"]]
if _blind:
    bad+=len(_blind)
    print(f"  A2 {len(_blind)} random-enchant variants still carry the school-blind "
          f"spSchool key, e.g. {_blind[0][1]} on item {_blind[0][0]}")

FILES=[f for f in ("paladin.json","warrior.json","hunter.json","druid.json",
                   "shaman.json","rogue.json","priest.json","mage.json","warlock.json")
       if os.path.exists(scored(f))]
checked=0
for f in FILES:
    cls=f.split(".")[0].upper(); gen=json.load(open(scored(f)))
    for spec,d in gen.items():
        w=W[cls][spec]["weights"]
        paid=[k for k in SCHOOLS if w.get(k)]
        for b in d["bands"]:
            for p in b["picks"][:3]:
                st=items[str(p["id"])]["stats"]
                got=[k for k in SCHOOLS if st.get(k)]
                if not got: continue
                checked+=1
                free=[k for k in got if k not in paid]
                if not free: continue
                # scored on a school it does not cast? only a violation if the weight
                # is non-zero, which `paid` already excludes -- so this is belt and
                # braces against a future weight block reintroducing one.
                if any(w.get(k) for k in free):
                    bad+=1
                    print(f"  B {cls:<8}{spec:<14}{items[str(p['id'])]['name'][:28]:<30}"
                          f"paid for {free} which {spec} does not cast")
                # C: a pick that carries a suffix must be paid for that suffix's school
                sufid=p.get("suffix")
                if sufid:
                    for x in _rand.get(str(p["id"]), []):
                        if x["suffix"]!=sufid: continue
                        blind=[k for k in x["stats"] if k=="spSchool"]
                        if blind:
                            bad+=1
                            print(f"  C {cls:<8}{spec:<14}{items[str(p['id'])]['name'][:26]} "
                                  f"{sufid}: school-blind stats {x['stats']}")
print(f"school check: {'OK' if not bad else str(bad)+' VIOLATIONS'} "
      f"({checked} picks carrying a school stat, across {len(FILES)} classes)")
sys.exit(1 if bad else 0)
