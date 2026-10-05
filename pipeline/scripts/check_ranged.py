"""Standing check: ranged damage weights match the Forever model.

A hunter fights with a bow, gun, or crossbow, so ranged damage is a real
weight. Priest, mage, and warlock cast, then wand, so their ranged weight is
7, the same scale as a warrior melee weapon. Every other combat spec declares
0 explicitly. A missing key used to inherit the melee weight, and a warrior's
gun was scored like an axe.

Rules asserted here:
  A. HUNTER dpsWeightRanged > 0. PRIEST, MAGE, and WARLOCK are exactly 7.
     Every other spec declares 0, except levelling_1_9.
  B. Where the ranged weight is 0, a Ranged pick with no stats must not owe
     its place to an on-attack proc.
"""
import json, os, sys
from gq_paths import G, scored
W=json.load(open(G+"weights.json")); items=json.load(open(G+"items.json"))
# Priest, mage, and warlock dpsWeightRanged is 7. White Obsidian Wand ranking
# first is that weight. Do not cap it, and do not require it to be small.
WAND_CLASSES={"PRIEST","MAGE","WARLOCK"}
WAND_WEIGHT=7.0
bad=0

for cls,specs in sorted(W.items()):
    for spec,cfg in specs.items():
        if not (isinstance(cfg,dict) and "weights" in cfg): continue
        dwr=cfg.get("dpsWeightRanged")
        if cls=="HUNTER":
            if not dwr: bad+=1; print(f"  A {cls} {spec}: a hunter must value its ranged weapon's damage")
        elif cls in WAND_CLASSES:
            if dwr != WAND_WEIGHT:
                bad+=1; print(f"  A {cls} {spec}: wand weight {dwr!r}, want {WAND_WEIGHT}")
        elif spec=="levelling_1_9":
            pass
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
