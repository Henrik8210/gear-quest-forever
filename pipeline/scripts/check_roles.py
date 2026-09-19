"""Standing check: Forever unifies hit/crit/haste. Those keys are legal on
every role. Pure casters still carry no physical-damage stats (str/ap/rap/…);
pure physical specs still carry no spell power / healing.

Enhancement shaman, Ret, and Paladin Protection are hybrids on purpose.
Warrior Protection is a physical tank -- no spell-power weight.
"""
import json, sys
from gq_paths import G
W=json.load(open(G+"weights.json"))
# hit/crit/haste are shared Forever stats -- not role-locked.
MELEE_OFFENSE=["ap","rap","feralAp","expertise","armorPen","wpnDmg","wpnSkill","str"]
SPELL_OFFENSE=["sp","spSchool","spHoly","heal","sp_from_heal","spellPen",
               "spShadow","spFire","spFrost","spNature","spArcane"]
DEAD=["expertise","armorPen","resilience","wpnSkill","spellHit","spellCrit","spellHaste"]
# Hybrids swing AND cast (or tank with holy/spell threat).
HYBRID={("PALADIN","protection"),
        ("PALADIN","retribution"),("SHAMAN","enhancement")}
CASTER_ANCHOR=0.5
MELEE_ANCHOR=0.5

bad=[]
for cls,specs in W.items():
    if cls.startswith("_"): continue
    for spec,cfg in specs.items():
        if spec.startswith("_") or spec=="levelling_1_9": continue
        if not isinstance(cfg, dict) or "weights" not in cfg: continue
        w=cfg["weights"]
        for k in DEAD:
            if w.get(k,0):
                bad.append((cls,spec,"dead Forever stat",k,w[k]))
        if (cls,spec) in HYBRID: continue
        spellMax=max((w.get(k,0) for k in SPELL_OFFENSE), default=0)
        meleeMax=max((w.get(k,0) for k in MELEE_OFFENSE), default=0)
        if spellMax>=CASTER_ANCHOR and meleeMax>0:
            bad+= [(cls,spec,"caster carries melee",k,w[k]) for k in MELEE_OFFENSE if w.get(k,0)]
        if meleeMax>=MELEE_ANCHOR and spellMax>0:
            bad+= [(cls,spec,"physical carries spell",k,w[k]) for k in SPELL_OFFENSE if w.get(k,0)]
if bad:
    print("FAIL -- %d role violations"%len(bad))
    for b in bad: print("   %-9s %-14s %-24s %-12s %.3f"%b)
    sys.exit(1)
n=sum(1 for c,s in W.items() if not c.startswith("_")
      for spec,cfg in s.items() if not spec.startswith("_") and isinstance(cfg,dict) and "weights" in cfg)
print("role check: OK (%d specs, %d exempt hybrids)"%(n,len(HYBRID)))
