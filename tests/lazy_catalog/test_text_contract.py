from pathlib import Path
import sys,json
from support import ROOT
from support import Harness

snap='''ORIGINAL_ROWS={};for key,value in pairs(GearQuest.Data)do
    if type(value)=='table' and value.rows and value.slots and value.specs then
        ORIGINAL_ROWS[key]={}
        for side,text in pairs(value.rows)do ORIGINAL_ROWS[key][side]=text end
    end
end'''
h=Harness('optimized','WARRIOR',before_activation_lua=snap)
h.lua.execute('''
    for name,rows in pairs(ORIGINAL_ROWS)do
        assert(not G.Data[name].format,'gear format changed')
        for side,text in pairs(rows)do assert(G.Data[name].rows[side]==text,'row text changed')end
    end
    for _,src in ipairs(G.Data.catalogSources)do
        local c=G.Data.packedCatalogs[src.picks]
        if c then assert(rawequal(c.original,G.Data[src.picks..'Packed']),'source replaced')end
    end
''')

# Official text permits a score token whose tonumber result is nil. The
# index must leave rank/score interpretation to the same requested-row reader.
alter='''local p=GearQuest.Data.warriorPicksPacked
p.rows.Alliance=p.rows.Alliance:gsub('^(%d+ %d+ %d+ %d+ %d+ %d+) %S+ ','%1 ? ',1)'''
games=[Harness(t,'WARRIOR',before_activation_lua=alter) for t in ['source','optimized']]
rows=[]
for g in games:
    rows.append(g.lua.eval('''function()
        local list=G.Data.NewCatalogCursor and nil or G.Data.entries
        local e=list and list[59] or G.Data:GetCursorEntry(G.Data:NewCatalogCursor(),59)
        assert(e.pipelineScore==nil,'score prematurely normalized')
        return e.id
    end''')())
assert rows[0]==rows[1]

invalid='''function GearQuest:Chat(message)INDEX_FAILURE=message;MESSAGES=(MESSAGES or 0)+1 end
GearQuest.Data.warriorPicksPacked.rows.Alliance='malformed\\n' '''
h=Harness('optimized','WARRIOR',before_activation_lua=invalid)
h.module('GearQuestForever/Log.lua')
h.lua.execute('''
    assert(G.Data._textIndexErrors.WARRIOR and not G.Data:IsClassExpanded('WARRIOR'),'bad index activated')
    assert(not G.Data:EnsureClassLoaded('WARRIOR') and MESSAGES==1,'failure repeated')
    GearQuestForeverCharDB={obtained={saved=1},hunts={saved={status='completed'}}}
    G.Log:CollectCompletedBySlot()
    assert(GearQuestForeverCharDB.obtained.saved==1,'saved completion pruned')
    assert(GearQuestForeverCharDB.hunts.saved.status=='completed','saved hunt pruned')
    assert(not G.Log._prunedStaleObtained,'stale pruning ran without class data')
''')
result={'official_text_remains_authoritative':'passed','no_score_conversion_during_indexing':'passed',
        'index_failure_reported_once':'passed','index_failure_preserves_saved_progress':'passed'}
(ROOT/'text-contract-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
