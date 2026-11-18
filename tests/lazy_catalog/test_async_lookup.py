from pathlib import Path
import sys,json
from support import ROOT
from support import Harness

snapshots=[]
for tree in ['source','optimized']:
    h=Harness(tree,'WARRIOR')
    h.module('GearQuestForever/Log.lua')
    h.lua.execute('''
        QUEUE={}
        C_Timer={After=function(_,fn)QUEUE[#QUEUE+1]=fn end}
        READY=0
        G.Log:EnsureLookupIndex('WARRIOR',function()READY=READY+1 end)
        assert(G.Log._lookupBuild,'not asynchronous')
        TEST_FACTION='Horde'
        assert(G.Data:ReleaseExpandedClass('WARRIOR'))
        assert(G.Data:EnsureClassLoaded('WARRIOR'))
        G.Data:BuildIndex()
        local turns=0
        while #QUEUE>0 do
            table.remove(QUEUE,1)();turns=turns+1
            assert(turns<10000,'lookup queue stuck')
        end
        assert(READY==1 and not G.Log._lookupBuild,'lookup callback/restart')
        SNAPSHOT={}
        for _,item in ipairs(G.Log._lookupIndex)do
            SNAPSHOT[#SNAPSHOT+1]=item.key..'|'..item.name
            for _,ref in ipairs(item.entries)do
                local e=G.Data.ResolveCatalogReference and G.Data:ResolveCatalogReference(ref) or ref
                SNAPSHOT[#SNAPSHOT+1]=e.id
                if e.factions and e.factions.Alliance then OTHER_ID=e.id end
            end
        end
        assert(OTHER_ID and G.Data:GetEntryById(OTHER_ID),'other-faction lookup ID')
    ''')
    snapshots.append(h.lua.eval('table.concat(SNAPSHOT,"\\n")'))
    h.lua.execute('''
        local old=OTHER_ID
        G.Log:ReleaseLookupIndex()
        assert(not G.Data:GetEntryById(old),'other-faction IDs survive close')
        G.Log:EnsureLookupIndex('WARRIOR')
        assert(G.Log._lookupBuild)
        G.Log:ReleaseLookupIndex()
        while #QUEUE>0 do table.remove(QUEUE,1)()end
        assert(not G.Log._lookupIndex and not G.Log._lookupBuild,'cancel resurrected index')
    ''')
assert snapshots[0]==snapshots[1],'lookup restart order differs'

h=Harness('optimized','WARRIOR')
h.module('GearQuestForever/Log.lua')
h.lua.execute('''
    G.Log:EnsureLookupIndex('WARRIOR')
    local item=G.Log._lookupIndex[1]
    G.Data:ReleaseExpandedClass('WARRIOR')
    G.Data:BuildIndex()
    assert(not G.Log:LookupDetailEntry(item),'stale selection retained')
    assert(#G.Log:LookupRankLines(item,'WARRIOR')==0,'stale rank rows retained')
    G.Log:ReleaseLookupIndex()
''')
result={'queued_lookup_generation_restart':'passed','restart_order_matches_official':'passed',
        'queued_lookup_cancellation':'passed','opposite_faction_saved_id_scope':'passed','released_class_selection_guard':'passed'}
(ROOT/'async-lookup-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
