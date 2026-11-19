from pathlib import Path
import sys,json
from support import ROOT
from support import Harness
from support import CLASSES

slot_checks=item_checks=0
for cls in CLASSES:
    games=[Harness(t,cls) for t in ['source','optimized']]
    for side in ['Alliance','Horde']:
        snapshots=[]
        for h in games:
            h.lua.globals().TEST_FACTION=side
            h.lua.execute('''
                function G.Equip:WithoutItemPrime(fn,...)return fn(...)end
                if G.Data._expandedFaction[TEST_CLASS]~=TEST_FACTION then
                    G.Data:ReleaseExpandedClass(TEST_CLASS);assert(G.Data:EnsureClassLoaded(TEST_CLASS));G.Data:BuildIndex()
                end
                function ItemIds()
                    local ids={}
                    if G.Data.IterCatalogItemIds then
                        for id in G.Data:IterCatalogItemIds()do ids[#ids+1]=id end
                    else for id in pairs(G.Data.byItemId)do ids[#ids+1]=id end end
                    table.sort(ids)
                    return table.concat(ids,',')
                end
            ''')
            snapshots.append(h.lua.eval('ItemIds()'))
        assert snapshots[0]==snapshots[1],('item enumeration',cls,side)
        item_checks+=1
        for level in [1,9,10,20,30,40,59,60]:
            values=[]
            for h in games:
                h.lua.globals().TEST_LEVEL=level
                h.lua.execute('G.Data:InvalidateQueryCache()')
                values.append(h.lua.eval('table.concat(G.Data:GetSlotsForClass(TEST_CLASS),",")'))
            assert values[0]==values[1],('visible slots',cls,side,level,values)
            slot_checks+=1
    for h in games:
        h.module('GearQuestForever/MobDrop.lua')
        h.lua.execute('''
            function WorldSnapshot()
                local fn=G.Data.TopWorldDrops
                for i=1,30 do
                    local name,value=debug.getupvalue(fn,i)
                    if not name then break end
                    if name=='WorldDropRanges' then
                        local result=value(G.Data)
                        local ids={}
                        for item,range in pairs(result.ranges)do ids[#ids+1]=item..':'..range[1]..':'..range[2]end
                        table.sort(ids)
                        return table.concat(ids,'|')
                    end
                end
                error('world-drop cache function not found')
            end
        ''')
    assert games[0].lua.eval('WorldSnapshot()')==games[1].lua.eval('WorldSnapshot()'),('world drops',cls)

# No detailed generated entries should be allocated just to build Lookup.
h=Harness('optimized','WARRIOR')
h.lua.execute('''
    local original=G.Data.MakeCatalogEntry
    DECODE_COUNT=0
    function G.Data:MakeCatalogEntry(...)DECODE_COUNT=DECODE_COUNT+1;return original(self,...)end
''')
h.module('GearQuestForever/Log.lua')
h.g.Log.EnsureLookupIndex(h.g.Log,'WARRIOR')
assert h.lua.globals().DECODE_COUNT==0
h.lua.execute('''
    local sample=G.Log._lookupIndex[1].entries[1]
    assert(type(sample)=='number','lookup holds detailed entries')
    local e=G.Data:ResolveCatalogReference(sample)
    assert(e and G.Data:GetEntryById(e.id),'lookup selected ID')
    G.Log:ReleaseLookupIndex()
    assert(not G.Data._catalogLookupClass,'lookup scope retained')
    assert(#G.Data.entries==58,'generated entries retained at startup')
''')

# A disabled optional class reports the original localized failure once.
h.lua.execute('''
    FAIL_MESSAGES=0
    function G:Chat()FAIL_MESSAGES=FAIL_MESSAGES+1 end
    function LoadAddOn()return false,'DISABLED'end
    assert(not G.Data:EnsureClassLoaded('MAGE'))
    assert(not G.Data:EnsureClassLoaded('MAGE'))
    assert(FAIL_MESSAGES==1,'repeated class-load messages')
''')
result={'slot_layout_contexts':slot_checks,'item_enumeration_contexts':item_checks,'world_drop_range_classes':9,
        'lookup_builder_creates_zero_detailed_entries':'passed','disabled_class_failure_once':'passed'}
(ROOT/'context-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
