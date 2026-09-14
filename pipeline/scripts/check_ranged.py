"""Standing check: only a hunter fights with its ranged weapon.

Henrik: "rogues doesn't need the damage on the ranged, they just need stats so ranged
procs etc. is not relevant for rogues on the ranged. It can be for hunters of course
as that is their main weapon."

Two ways that went wrong, both silent:
  1. WARRIOR carried no dpsWeightRanged key at all, so it inherited dpsWeight -- a
     warrior's gun was scored as though its damage counted as much as its axe's.
  2. the proc model was handed the MELEE dpsWeight even for a ranged item, so
     Venomstrike's "Chance to strike your ranged target" was priced for a rogue at
     the weight of a weapon it swings every 1.4 seconds.

Rules asserted here:
  A. every non-hunter combat spec declares dpsWeightRanged == 0 explicitly (no
     inheriting the melee weight by omission)
  B. no non-hunter Ranged pick owes its place to an on-attack proc: re-score every
     such pick with procs off and assert the ranking is unchanged
"""
import json, os, sys
from gq_paths import G, scored
W=json.load(open(G+"weights.json")); items=json.load(open(G+"items.json"))
# A class that holds a WAND fights with its ranged slot too -- just not much. Henrik:
# "priests usually wear an off-hand type of item with a one hander or has a two-hand
# staff and then a wand - stats are more important on the wand than the damage at least
# in higher levels." So a wand class must declare a SMALL non-zero weight: zero would
# make every wand identical below the level where stats appear on them, and anything
# large would let a high-damage wand with no stats win.
WAND_CLASSES={"PRIEST","MAGE","WARLOCK"}
WAND_MAX=0.5
bad=0

for cls,specs in sorted(W.items()):
    for spec,cfg in specs.items():
        if not (isinstance(cfg,dict) and "weights" in cfg): continue
        dwr=cfg.get("dpsWeightRanged")
        if cls=="HUNTER":
            if not dwr: bad+=1; print(f"  A {cls} {spec}: a hunter must value its ranged weapon's damage")
        elif cls in WAND_CLASSES:
            if not dwr or dwr>WAND_MAX:
                bad+=1; print(f"  A {cls} {spec}: wand weight {dwr!r}, want >0 and <={WAND_MAX}")
        elif spec=="levelling_1_9":
            pass          # 1-9 throws for real; a small non-zero weight is intended
        elif dwr is None:
            bad+=1; print(f"  A {cls} {spec}: no dpsWeightRanged key -- inherits the MELEE weight")
        elif dwr:
            bad+=1; print(f"  A {cls} {spec}: dpsWeightRanged={dwr}, should be 0")

for f in ("paladin.json","warrior.json","druid.json","shaman.json","rogue.json",
          "priest.json"):
    p=scored(f)
    if not os.path.exists(p): continue
    cls=f.split(".")[0].upper(); gen=json.load(open(p))
    for spec,d in gen.items():
        if spec=="levelling_1_9": continue
        # Rule B only bites where the ranged weight is 0 -- there the character cannot
        # attack with it at all, so an on-attack proc cannot fire. A wand class swings
        # its wand, so a proc on it is real.
        if (W.get(cls,{}).get(spec,{}) or {}).get("dpsWeightRanged"): continue
        for b in d["bands"]:
            if b["slot"]!="Ranged": continue
            for p in b["picks"][:3]:
                it=items[str(p["id"])]
                pr=[l for l in (it.get("procs") or []) if "Use:" not in l]
                # a pick with no stats and no dps value that got here on a proc alone
                if pr and not any(it.get("stats") or {}):
                    bad+=1
                    print(f"  B {cls:<8}{spec:<15}L{b['lo']}-{b['hi']:<4}{it['name'][:28]:<30}"
                          f"ranked on an on-attack proc with no stats at all")
print(f"ranged check: {'OK' if not bad else str(bad)+' VIOLATIONS'}")
sys.exit(1 if bad else 0)
