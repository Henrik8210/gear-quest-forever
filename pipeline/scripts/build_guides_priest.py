"""guides_priest.json from the two Wowhead Classic priest guides.

Two pages, three specs:
  * the HEALING guide covers holy AND discipline -- Henrik gave one URL for both, and
    that is right: Spiritual Guidance and Meditation pull in different directions but
    the gear is the same gear. Both specs get the same list.
  * the SHADOW DPS guide is its own list.

New rank labels these pages use, and what each does to the tier:

  "Best - 8/8 T2" / "Best - Offset"   Two ways to be best -- with the full tier 2 set
                                      bonus, or without it. Both are genuinely the
                                      answer in their own configuration, so both demote
                                      one tier together and keep their order above
                                      "Great". Same treatment as "Best Mitigation" on
                                      the warrior tank list.
  "Best - Throughput" (trinkets)      The primary axis for a healer. No demotion.
  "Best - Sustain" (trinkets)         A mana trinket is not the throughput answer, so it
                                      sits one tier below the throughput pick. Same for
                                      "Great - Sustain" and "Good - Sustain".
  "Best - Undead" (shadow trinket)    Conditional on the target, exactly like the +60 AP
                                      vs Undead stats -- demoted.
  "Best - Legendary" (Atiesh)         NOT demoted. Ranking is pure stat score regardless
                                      of obtainability, and Atiesh really is the best
                                      staff; "Legendary" describes where it comes from.
  "Great - PVP" / "Great - PvP"       PvP is a source, not a downgrade. Stays at Great.
  "Optional"                          Already in the shared table at tier 5.

The healing guide has NO wand section, so holy and discipline have no guide answer for
the Ranged slot and the model decides it. That is not a gap to paper over -- the guide
genuinely does not cover it, so their denominator is one slot smaller.
"""
import json, re

items=json.load(open("items.json")); NAMES={it["name"] for it in items.values()}
rand=json.load(open("items_random.json"))
BYNAME={}
for _k,_v in items.items(): BYNAME.setdefault(_v["name"],_k)

def resolve(name):
    """A guide row can name a ROLLED item -- "Archivist Cape of Healing" is the base
    item Archivist Cape with the random suffix "of Healing" on it. The base name is
    what the item table knows, so strip a trailing " of X" and check that X really is
    one of that item's possible rolls before accepting it. All six such rows on these
    two pages verify: Archivist Cape, Drakestone, Flameweave Cuffs and Tearfall
    Bracers each genuinely roll the named suffix.
    """
    if name in NAMES: return name, None
    for i in range(len(name)):
        if not name[i:].startswith(" of "): continue
        base, suf = name[:i], name[i+1:]
        if base not in NAMES: continue
        pool=[x["suffix"] for x in rand.get(BYNAME[base], [])]
        if suf in pool: return base, suf
    return None, None
BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"optional":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"hit option":6,"situational":7}
# Qualifiers that describe a CONFIGURATION or a CONDITION -> one tier down.
DEMOTE=re.compile(r"\b(8/8 t2|offset|sustain|undead|human|non-human|orc|dwarf|troll"
                  r"|tauren|undead|gnome|night ?elf|draenei|blood ?elf)\b")
# Qualifiers that describe only WHERE the item comes from, or its rarity -> no change.
NEUTRAL=re.compile(r"\b(pvp|throughput|legendary)\b")

def tier(rank):
    l=re.sub(r"\s+"," ",rank.strip().lower())
    demote=1 if DEMOTE.search(l) else 0
    core=NEUTRAL.sub("",DEMOTE.sub("",l)).strip(" -")
    core=re.sub(r"\s+"," ",core).strip(" -")
    if core not in BASE: raise SystemExit("unknown rank: %r (core %r)"%(rank,core))
    return BASE[core]+demote

SLOT={"head":"Head","neck":"Neck","shoulders":"Shoulder","back":"Back","chest":"Chest",
 "wrist":"Wrist","hands":"Hands","waist":"Waist","legs":"Legs","feet":"Feet",
 "ring":"Finger","trinket":"Trinket","wand":"Ranged",
 "main hand":"MainHand","off hand":"SecondaryHand",
 "two hand":"MainHand","two-hand":"MainHand"}

def read(fn, specs):
    rows=[]
    for line in open(fn,encoding="utf-8").read().strip().splitlines():
        slot,rank,name=[x.strip() for x in line.split("|",2)]
        rows.append((SLOT[slot.lower()], tier(rank), name))
    return rows

out={s:{} for s in ("holy","discipline","shadow")}
unmatched=[]; rolled=[]
for fn,specs in (("priest_heal_raw.txt",("holy","discipline")),
                 ("priest_shadow_raw.txt",("shadow",))):
    for sl,t,nm in read(fn,specs):
        nm, roll = resolve(nm)
        if nm is None: unmatched.append(nm); continue
        if roll: rolled.append((nm,roll))
        for spec in specs:
            cur=out[spec].setdefault(sl,[])
            prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
            if prev:
                if t<cur[prev[0]][0]: cur[prev[0]]=(t,nm)
            else: cur.append((t,nm))
# Sort each slot by tier so the guide's own answer leads, keeping the page's order
# within a tier -- that order carries information the label does not.
for spec in out:
    for sl in out[spec]:
        out[spec][sl]=sorted(out[spec][sl], key=lambda x:x[0])
json.dump({s:{sl:[[t,n] for t,n in v] for sl,v in d.items()} for s,d in out.items()},
          open("guides_priest.json","w"),indent=1,ensure_ascii=False)
for s,d in out.items():
    print("== %-12s %3d entries, %2d slots   (Ranged/wand: %s)"%(
        s,sum(len(v) for v in d.values()),len(d),len(d.get("Ranged",[])) or "none"))
print("rolled names resolved to their base item:", rolled or "none")
print("UNMATCHED:",unmatched or "none")
if unmatched: raise SystemExit("a guide row names an item the table does not have")
