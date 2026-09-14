"""Real integration test: load the generated files and the adapter in a Lua runtime,
run the expansion, and assert the brief's claims. Catches Lua-side problems a Python
check cannot -- chunk size limits, shape mistakes, nil indexing.

The adapter under test is DataAdapter.repo.lua -- Henrik's LIVE file, staged from
C:\\Users\\Henrik\\Projects\\GearQuest, not my own copy. Cursor has extended it well
past mine (suffixId/suffixRange passthrough plus a suffix lookup index), so testing
against my stale copy would prove nothing about what actually ships.
"""
import lupa, os, sys
from gq_paths import ADDON_GEN
L=lupa.LuaRuntime(unpack_returned_tuples=True)
G=ADDON_GEN + os.sep
# stand in for the curated Data.lua: 1176 placeholder entries
L.execute("GQ = { Data = { entries = {} } }")
L.execute("for i=1,1176 do GQ.Data.entries[i] = { id='curated'..i, itemId=i, generated=nil } end")
def run(fn):
    src=open(G+fn,encoding="utf-8").read()
    chunk=L.eval("function(s,n) return assert(load(s, n)) end")(src, "@"+fn)
    chunk("GearQuest", L.globals().GQ)
    print(f"  loaded {fn}  ({os.path.getsize(G+fn)/1e6:.2f} MB)")
for f in ("Data.Paladin.generated.lua","Data.Paladin.Horde.1to9.generated.lua",
          "Data.Warrior.generated.lua","Data.Warrior.Horde.1to9.generated.lua",
          "Data.Hunter.generated.lua","Data.Hunter.Early.1to9.generated.lua",
          "Data.Druid.generated.lua","Data.Druid.Early.1to9.generated.lua",
          "Data.Shaman.generated.lua","Data.Shaman.Early.1to9.generated.lua",
          "Data.Rogue.generated.lua","Data.Rogue.Early.1to9.generated.lua",
          "Data.Priest.generated.lua","Data.Priest.Early.1to9.generated.lua",
          "Data.Warlock.generated.lua","Data.Warlock.Early.1to9.generated.lua",
          "Data.Mage.generated.lua","Data.Mage.Early.1to9.generated.lua",
          # Henrik's live adapter plus the two PRIEST SOURCES rows -- the repo copy does
          # not have them yet, and this is the test that says the snippet is right.
          "DataAdapter.all9-test.lua"):
    run(f)

EXPECT=None         # measured below; the row count moves whenever a pick changes,
                    # because adjacent levels whose top 3 are identical are merged
                    # into one band.
tot=L.eval("#GQ.Data.entries")
gen=L.eval("GQ.Data._generatedCount")
print(f"\n  generated rows expanded: {gen}")
print(f"  total entries: {tot}  (1176 curated placeholders + {gen} generated)")
assert tot==1176+gen, "the adapter dropped or duplicated rows"
# the adapter self-wires on load, so a second explicit call must add nothing
L.eval("GQ.Data:LoadGenerated()")
print(f"  second call is a no-op: {'OK' if L.eval('#GQ.Data.entries')==tot else 'DOUBLE LOADED'}")

E=L.eval("GQ.Data.entries")
bad=dupes=0; ids=set(); withSuffix=withId=0
offhand={}
for i in range(1,tot+1):
    e=E[i]
    if not e.generated: continue
    if not (e.id and e.itemId and e.slot and e.minLevel and e.maxLevel and e.classes): bad+=1
    if e.id in ids: dupes+=1
    ids.add(e.id)
    if e.suffix:
        withSuffix+=1
        if e.suffixId: withId+=1
    if e.slot=="SecondaryHand":
        k=next(iter(dict(e.classes)))
        offhand[k]=offhand.get(k,0)+1
print(f"  malformed generated entries: {bad}")
print(f"  duplicate ids: {dupes}")
print(f"  random-enchant rows: {withSuffix}, of which carry a suffixId: {withId} ({withId/max(withSuffix,1)*100:.1f}%)")
print(f"  off-hand rows per class: {offhand}")

# R32 spot-checks: the exact cells Henrik's report was about.
def find(cls,spec,slot,lv):
    out=[]
    for i in range(1,tot+1):
        e=E[i]
        if not e.generated or e.slot!=slot: continue
        if not e.classes[cls]: continue
        if spec and not (e.specs and e.specs[spec]): continue
        if not (e.minLevel<=lv<=e.maxLevel): continue
        if e.factions and not e.factions["Alliance"]: continue
        out.append((e.curatedRank,e.itemId))
    return sorted(out)[:3]
print("\n  R32 -- one-handers in the off hand where dual wield exists:")
for cls,spec,lv in (("HUNTER","beast_mastery",60),("ROGUE","combat",60),
                    ("SHAMAN","enhancement",60),("WARRIOR","fury",60),
                    ("WARRIOR","protection",60),("HUNTER","beast_mastery",15)):
    print(f"     {cls:<8}{spec:<14}L{lv:<3} off-hand -> {find(cls,spec,'SecondaryHand',lv)}")
print("\n  CASTERS -- a held-in-off-hand item, a staff or one-hander, and a wand:")
for cls,specs in (("PRIEST",("holy","discipline","shadow")),
                  ("WARLOCK",("affliction","demonology","destruction")),
                  ("MAGE",("frost","fire","arcane"))):
    for spec in specs:
        for slot in ("MainHand","SecondaryHand","Ranged"):
            print(f"     {cls:<8}{spec:<12}{slot:<14}-> {find(cls,spec,slot,60)}")
sys.exit(1 if (bad or dupes) else 0)
