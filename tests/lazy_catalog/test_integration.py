import json,time,sys
from pathlib import Path
from support import Harness,ROOT

def init(tree):
    h=Harness(('source' if tree=='source' else 'optimized'),'MAGE')
    h.lua.execute("function IsAddOnLoaded(name)return name~='GearQuestForever_ItemStats' or G.Data.itemStats~=nil end;function G:CollectGarbageSoon()end")
    h.module('GearQuestForever/Log.lua')
    h.module('GearQuestForever/CustomSpec.lua')
    h.lua.execute('''
        function BeginCustom(class,base,id)
            GearQuestForeverDB.customSpecs[class]=GearQuestForeverDB.customSpecs[class] or {}
            local list=GearQuestForeverDB.customSpecs[class]
            list[#list+1]={id=id,base=base,name=id,overrides={sta=1.3,ap=0.7,sp=1.9,dpsWeight=5}}
            local job=G.Custom:Prepare(class,id)
            assert(job,'custom preparation')
            job.i=1
            job.onDone=function(ok,err)assert(ok,tostring(err));CUSTOM_DONE=(CUSTOM_DONE or 0)+1 end
            G.Custom._job=job
            return job
        end
        function FinishCustom()
            local turns=0
            while G.Custom._job do
                G.Custom:Pump()
                turns=turns+1
                assert(turns<10000,'custom worker stuck')
            end
            return turns
        end
        function AllSnapshot()
            local lines={}
            local function add(e)
                lines[#lines+1]=e.id..'|'..tostring(e.pipelineScore)..'|'..tostring(e.curatedRank)..'|'..tostring(e.suffixId)
            end
            if G.Data.IterCatalog then
                for _,e in G.Data:IterCatalog()do add(e)end
            else for _,e in ipairs(G.Data.entries)do add(e)end end
            return table.concat(lines,'\\n')
        end
        function LookupSnapshot(class)
            G.Log:ReleaseLookupIndex()
            G.Log:EnsureLookupIndex(class)
            local rows={}
            for _,item in ipairs(G.Log._lookupIndex)do
                rows[#rows+1]=item.key..'|'..item.name
                for _,reference in ipairs(item.entries)do
                    local e=G.Data.ResolveCatalogReference and G.Data:ResolveCatalogReference(reference) or reference
                    rows[#rows+1]=e.id
                end
            end
            G.Log:ReleaseLookupIndex()
            return table.concat(rows,'\\n')
        end
    ''')
    return h

def same(hs,expression):
    a,b=[h.lua.eval(expression) for h in hs]
    assert a==b,'Mismatch in '+expression
    return len(a) if isinstance(a,str) else a

started=time.perf_counter()
hs=[init('source'),init('optimized')]
for h in hs:
    h.lua.execute("BeginCustom('MAGE','frost','c:mage-memory2');FinishCustom()")
same(hs,'AllSnapshot()')
for h in hs:
    h.class_files('WARRIOR')
    h.lua.execute("TEST_VIEW_CLASS='WARRIOR';TEST_SPEC='fury';assert(G.Data:EnsureClassLoaded('WARRIOR'));G.Data:BuildIndex()")
same(hs,'AllSnapshot()')
same(hs,"LookupSnapshot('WARRIOR')")
for h in hs:h.lua.execute("BeginCustom('WARRIOR','fury','c:warrior-memory2');FinishCustom()")
same(hs,'AllSnapshot()')
for h in hs:
    h.lua.execute("TEST_VIEW_CLASS='MAGE';TEST_SPEC='frost';assert(G.Data:ReleaseIdleHuntClasses());G.Data:BuildIndex()")
same(hs,'AllSnapshot()')
same(hs,"LookupSnapshot('MAGE')")
for h in hs:
    h.lua.execute("TEST_VIEW_CLASS='WARRIOR';TEST_SPEC='fury';assert(G.Data:EnsureClassLoaded('WARRIOR'));G.Data:BuildIndex()")
same(hs,'AllSnapshot()')
same(hs,"LookupSnapshot('WARRIOR')")

# Loading another catalog during a custom scoring job must not lose or double
# score entries when the job resumes from its worker cursor.
for h in hs:
    h.lua.execute("TEST_VIEW_CLASS='MAGE';TEST_SPEC='frost';BeginCustom('MAGE','frost','c:restart-memory2');G.Custom:Pump();assert(G.Custom._job)")
    h.class_files('ROGUE')
    h.lua.execute("assert(G.Data:EnsureClassLoaded('ROGUE'));G.Data:BuildIndex();FinishCustom()")
same(hs,'AllSnapshot()')
for h in hs:
    h.lua.execute("BeginCustom('WARRIOR','fury','c:cancel-memory2');G.Custom:Pump();assert(G.Custom._job);G.Data:ReleaseIdleHuntClasses();G.Data:BuildIndex();assert(not G.Custom._job)")
same(hs,'AllSnapshot()')

for h in hs:
    h.lua.execute("TEST_VIEW_CLASS='WARRIOR';TEST_SPEC='protection';TEST_FACTION='Horde';G.Data._huntDataReady=true;assert(G.Data:SyncEffectiveHuntData())")
same(hs,'AllSnapshot()')
same(hs,"LookupSnapshot('WARRIOR')")
for h in hs:
    h.lua.execute("TEST_FACTION='Alliance';assert(G.Data:SyncEffectiveHuntData())")
same(hs,'AllSnapshot()')
for h in hs:
    h.lua.execute("TEST_VIEW_CLASS='MAGE';TEST_SPEC='frost';assert(G.Data:SyncEffectiveHuntData())")
same(hs,'AllSnapshot()')

result={'custom_worker':'passed','custom_then_simulation_order':'passed','simulator_faction_and_return_sync':'passed',
    'simulation_release_and_reopen':'passed','lookup_after_custom_and_simulation':'passed',
    'catalog_change_during_custom_worker':'passed','release_cancels_custom_worker':'passed',
    'seconds':round(time.perf_counter()-started,2)}
(ROOT/'integration-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
