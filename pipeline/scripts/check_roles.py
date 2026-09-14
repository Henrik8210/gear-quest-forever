"""Standing check: a pure caster spec must carry no melee offence, and a pure
physical spec no spell offence. haste/crit/hit are the MELEE ratings; spellHaste/
spellCrit/spellHit are separate stats and neither substitutes for the other.

This is the check that would have caught Manual Crowd Pummeler -- "+500 haste rating",
a melee/ranged buff -- landing in the Balance and Restoration druid lists, which is
what Henrik found. It also catches the mirror error: spell power on a warrior.
"""
import json, sys
from gq_paths import G
W=json.load(open(G+"weights.json"))
MELEE_OFFENSE=["ap","rap","feralAp","crit","hit","haste","expertise","armorPen",
               "wpnDmg","wpnSkill","str"]
SPELL_OFFENSE=["sp","spSchool","spHoly","heal","sp_from_heal","spellCrit","spellHit",
               "spellHaste","spellPen"]
# Hybrid tanks swing AND their threat scales with spell power. Exempt on purpose.
HYBRID={("PALADIN","protection"),("WARRIOR","protection"),("PALADIN","retribution")}
CASTER_ANCHOR=0.5   # a spell weight this high means the spec is a caster
MELEE_ANCHOR=0.5

bad=[]
for cls,specs in W.items():
    if cls.startswith("_"): continue
    for spec,cfg in specs.items():
        if spec.startswith("_") or spec=="levelling_1_9": continue
        if (cls,spec) in HYBRID: continue
        w=cfg["weights"]
        spellMax=max(w.get(k,0) for k in SPELL_OFFENSE)
        meleeMax=max(w.get(k,0) for k in MELEE_OFFENSE)
        if spellMax>=CASTER_ANCHOR and meleeMax>0:
            bad+= [(cls,spec,"caster carries melee",k,w[k]) for k in MELEE_OFFENSE if w.get(k,0)]
        if meleeMax>=MELEE_ANCHOR and spellMax>0:
            bad+= [(cls,spec,"physical carries spell",k,w[k]) for k in SPELL_OFFENSE if w.get(k,0)]
if bad:
    print("FAIL -- %d role violations"%len(bad))
    for b in bad: print("   %-9s %-14s %-24s %-12s %.3f"%b)
    sys.exit(1)
n=sum(1 for c,s in W.items() if not c.startswith("_") for s in s if not s.startswith("_"))
print("role check: OK (%d specs, %d exempt hybrids)"%(n,len(HYBRID)))
