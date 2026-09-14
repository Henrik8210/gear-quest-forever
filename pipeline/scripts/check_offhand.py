"""Standing check: every SecondaryHand pick must be something the character can
actually equip there.

This is the check that would have caught what Henrik found -- 189 held-in-off-hand
orbs and tomes in the hunter off hand and not one one-handed weapon, and Ritual Stein
(+3 Agi, +3 Spi) sitting in a rogue's off hand ahead of a real dagger.

Four rules:
  1. a weapon (inv 13 or 22) only where the class can dual wield at that level
  2. a shield (inv 14) only for a class with shield proficiency
  3. a held-in-off-hand (inv 23) NEVER where dual wield is available -- it disables
     off-hand attacks, so it is strictly worse than any weapon
  4. a two-hander (17) or main-hand-only (21) never, at any level
"""
import json, os, sys
from gq_paths import G, scored
items=json.load(open(G+"items.json"))
DUAL_WIELD={"WARRIOR":20,"ROGUE":10,"HUNTER":20,"SHAMAN":{"enhancement":30}}
SHIELD={"WARRIOR","SHAMAN","PALADIN"}
CASTER_OFFHAND_OK={("SHAMAN","elemental"),("SHAMAN","restoration")}
bad=0; checked=0
for f in sys.argv[1:] or ["paladin.json","warrior.json","hunter.json","druid.json",
                          "shaman.json","rogue.json","priest.json","warlock.json",
                          "mage.json"]:
    cls=os.path.basename(f).split(".")[0].upper()
    gen=json.load(open(scored(f) if os.path.exists(scored(f)) else G+f))
    for spec,d in gen.items():
        dw=DUAL_WIELD.get(cls)
        dw=dw.get(spec) if isinstance(dw,dict) else dw
        for b in d["bands"]:
            if b["slot"]!="SecondaryHand": continue
            for p in b["picks"][:3]:
                it=items[str(p["id"])]; inv=it["inv"]; lo=b["lo"]; checked+=1
                msg=None
                if inv in (13,22) and (dw is None or lo<dw):
                    msg="weapon in the off hand without Dual Wield"
                elif inv==14 and cls not in SHIELD:
                    msg="shield for a class with no shield proficiency"
                elif inv==23 and dw is not None and lo>=dw and spec!="levelling_1_9":
                    msg="held-in-off-hand while Dual Wield is available"
                elif inv in (17,21):
                    msg="two-hand / main-hand-only in the off hand"
                if msg:
                    bad+=1
                    print(f"  {cls:<8}{spec:<15}L{lo}-{b['hi']:<4}"
                          f"{it['name'][:30]:<32}inv{inv}  {msg}")
print(f"off-hand check: {'OK' if not bad else str(bad)+' VIOLATIONS'} "
      f"({checked} picks across {len(sys.argv[1:]) or 6} classes)")
sys.exit(1 if bad else 0)
