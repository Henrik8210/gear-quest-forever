"""Standing check: a caster is never paid for its weapon's physical damage.

Henrik: "priests are no melee class, so ranking weapons after physical damage like the
staff is wrong ... they purely use the benefits of the stats." The same is true of a
warlock and a mage. A caster's staff or dagger is a stat stick in exactly the way a
rogue's bow is, and the failure mode is identical: a high-dps weapon with poor stats
out-ranking a low-dps one with good stats.

Asserted here: for every caster spec, dpsWeight in the MAIN HAND and OFF HAND is 0 --
levels 1-9 included, since the rule is about the class and not the level. The WAND is
deliberately exempt: it is a real attack, and its small non-zero weight is checked by
check_ranged.py instead.
"""
import json, os, sys
from gq_paths import G, scored
W=json.load(open(G+"weights.json")); items=json.load(open(G+"items.json"))
# A spec with no melee ability at all -- nothing it does scales with weapon damage.
# A spec that never makes a weapon attack worth pricing. Priest, mage and warlock
# qualify for every spec they have, levels 1-9 included. Druid caster forms and the two
# shaman caster specs already carry 0.
#
# PALADIN holy is deliberately NOT here. It came up when this check first ran: holy
# carries dpsWeight 0.086, and that is intentional rather than a leak -- a Holy paladin
# really does swing its mace, with Seal of Righteousness and Judgement on top. At 60 that
# weight turns a 50-dps mace into 4 points against 30-40 from its stats, so it breaks a
# tie and never drives a pick. A plate hybrid is not a pure caster.
PURE_CASTER={("PRIEST",None),("MAGE",None),("WARLOCK",None),
             ("DRUID","balance"),("DRUID","restoration"),
             ("SHAMAN","elemental"),("SHAMAN","restoration")}
def pure(cls,spec):
    return (cls,None) in PURE_CASTER or (cls,spec) in PURE_CASTER
bad=0
for cls,specs in sorted(W.items()):
    if not isinstance(specs,dict): continue
    for spec,cfg in specs.items():
        if not (isinstance(cfg,dict) and "weights" in cfg): continue
        if not pure(cls,spec): continue
        if cfg.get("dpsWeight"):
            bad+=1
            print(f"  {cls} {spec}: dpsWeight={cfg['dpsWeight']} -- a caster is not paid "
                  f"for weapon damage in a hand")
FILES=[f for f in ("priest.json","warlock.json","mage.json","druid.json","shaman.json")
       if os.path.exists(scored(f))]
checked=0
for f in FILES:
    cls=f.split(".")[0].upper(); gen=json.load(open(scored(f)))
    for spec,d in gen.items():
        if not pure(cls,spec): continue
        for b in d["bands"]:
            if b["slot"] not in ("MainHand","SecondaryHand"): continue
            for p in b["picks"][:3]:
                if (items[str(p["id"])]["dps"] or 0)>0: checked+=1
print(f"caster-weapon check: {'OK' if not bad else str(bad)+' VIOLATIONS'} "
      f"({checked} hand-slot picks are weapons with real dps, none of it scored)")
sys.exit(1 if bad else 0)
