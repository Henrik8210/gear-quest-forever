from pathlib import Path
import sys, json, time, re
from support import ROOT
from support import SETUP, FIELDS, CLASSES, BASES
from lupa.lua51 import LuaRuntime

FIELDS = set(FIELDS)
for p in (ROOT / 'source/GearQuestForever').glob('*.lua'):
    FIELDS.update(re.findall(r'\bentry\.([A-Za-z_]\w*)', p.read_text(encoding='utf-8-sig')))


def run(cls):
    started = time.perf_counter()
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(SETUP)
    lua.execute((Path(__file__).with_name('helpers.lua')).read_text())
    lua.globals().TEST_CLASS, lua.globals().FIELDS = cls, lua.table_from(sorted(FIELDS))
    lua.globals().BASE = BASES[cls]
    lua.execute('''
        function UnitFactionGroup()return 'Alliance'end
        function IsAddOnLoaded(name)return name~='GearQuestForever_ItemStats' or (GearQuest and GearQuest.Data.itemStats~=nil)end
        function LoadAddOn(name)return PY_LOAD(name)end
    ''')
    load = lua.eval('function(code,name,g)GearQuest=g;local f,e=loadstring(code,name);assert(f,e);return f("GearQuestForever",g)end')
    loaded = []
    active_tree = 'source'
    def module(tree, rel, g):
        p = ROOT / tree / rel
        load(p.read_text(encoding='utf-8-sig'), '@' + str(p), g)
    def addon(name):
        g = lua.globals().GearQuest
        for line in (ROOT / active_tree / name / (name + '.toc')).read_text().splitlines():
            if line.endswith('.lua'): module(active_tree, name + '/' + line, g)
        loaded.append(name)
        return True, None
    lua.globals().PY_LOAD = addon
    games = []
    for tree in ['source', 'optimized']:
        active_tree = tree
        g = lua.eval('NewGQ()')
        for line in (ROOT / tree / 'GearQuestForever/GearQuestForever.toc').read_text().splitlines():
            if line in ['Data.lua', 'DataAdapter.lua', 'Catalog.lua'] or line.startswith('_generated/'):
                module(tree, 'GearQuestForever/' + line, g)
        folder = 'GearQuestForever_' + cls
        for line in (ROOT / tree / folder / (folder + '.toc')).read_text().splitlines():
            if line.endswith('.lua'): module(tree, folder + '/' + line, g)
        g.Data.EnsureClassLoaded(g.Data, cls)
        g.Data.BuildIndex(g.Data)
        games.append(g)
    lua.globals().O, lua.globals().N = games
    print(cls,'loaded',file=sys.stderr,flush=True)
    if 'trace' in sys.argv:
        lua.globals().TRACE = lambda s: print(s,file=sys.stderr,flush=True)
        lua.execute('local ticks=0;debug.sethook(function()ticks=ticks+1;if ticks%20==0 then TRACE(debug.traceback())end;if ticks>100 then error("instruction limit")end end,"",1000000)')
    result = {'class': cls, 'factions': []}
    for faction in ['Alliance', 'Horde']:
        lua.globals().TEST_FACTION = faction
        lua.execute('''
            for _,g in ipairs({O,N})do
                if g.Data._expandedFaction[TEST_CLASS]~=TEST_FACTION then
                    assert(g.Data:ReleaseExpandedClass(TEST_CLASS))
                    assert(g.Data:EnsureClassLoaded(TEST_CLASS))
                    g.Data:BuildIndex()
                end
            end
            CheckAll()
            local virtual=LogicalEntries(N);for i,e in ipairs(O.Data.entries)do assert(O.Data:FileBlockKey(e)==N.Data:FileBlockKey(virtual[i]),'file block')end
        ''')
        row = {'faction': faction, 'entries': len(games[0].Data.entries), 'saved_ids': lua.globals().ID_COUNT, 'copies': lua.globals().COPY_COUNT}
        print(cls,faction,'entries passed',file=sys.stderr,flush=True)
        lua.execute('''
            CheckBands()
            TEST_FACTION=TEST_REPORT_FACTION
        '''.replace('TEST_REPORT_FACTION', repr(faction)))
        row['band_views'] = lua.globals().VIEW_COUNT
        print(cls,faction,'bands passed',file=sys.stderr,flush=True)
        # Compare all rows read in many differently sized asynchronous chunks.
        lua.execute('''
            local others={}
            for _,g in ipairs({O,N})do
                local out,read={},g.Data:OtherFactionReader(TEST_CLASS)
                local i,done=0,false
                while not done do
                    i=i+1;done=read(({1,17,2000})[i%3+1],out)
                    assert(i<10000,'reader stuck')
                end
                others[#others+1]=out
            end
            CheckEntries(others[1],others[2])
            for i,e in ipairs(others[1])do assert(O.Data:FileBlockKey(e)==N.Data:FileBlockKey(others[2][i]),'detached file block')end
            OTHER_COUNT=#others[1]
            local sampled={}
            for i=1,#others[1],37 do sampled[others[1][i].itemId]=true end
            for item in pairs(sampled)do
                CheckEntries(O.Data:UnexpandedItemEntries(item),N.Data:UnexpandedItemEntries(item))
                Same(O.Data:UnexpandedRowSpecs(item),N.Data:UnexpandedRowSpecs(item),'unexpanded specs')
            end
            for i,g in ipairs({O,N})do
                g.Data:HoldDetachedEntries(others[i])
                for j=1,#others[i],19 do
                    local e=others[i][j]
                    assert(g.Data:GetEntryById(e.id).id==e.id,'detached saved ID')
                    assert(g.Data:IsUnexpandedHuntId(e.id),'unexpanded saved hunt')
                end
                g.Data:ReleaseDetachedEntries()
            end
            for _,g in ipairs({O,N})do
                g.PublicText=function(t)return type(t)=='string' and t or nil end
                g.FoldText=string.lower
                function g:WithContextSnapshot(fn,...)return fn(...)end
                function g:WithoutItemPrime(fn,...)return fn(...)end
                g.Equip={LEVEL_GRACE=5}
                function g.Equip:WithoutItemPrime(fn,...)return fn(...)end
                function g.Equip:EntryWithinLevelBand(e)return TEST_LEVEL>=(e.minLevel or 1) and TEST_LEVEL<=(e.maxLevel or TEST_LEVEL)+self.LEVEL_GRACE end
                function g.Equip:EntryMatchesSpec(e)return not e.specs or e.specs[TEST_SPEC]end
                function g.Equip:EntryMatchesItemRules()return true end
                function g.Equip:EntryArmorIsWearable()return true end
            end
            TEST_SPEC=BASE;QUERIES=0
            for _,grace in ipairs({0,5})do
                O.Equip.LEVEL_GRACE=grace;N.Equip.LEVEL_GRACE=grace
                for _,level in ipairs({1,9,10,20,30,40,59,60})do
                    TEST_LEVEL=level
                    O.Data:InvalidateQueryCache();N.Data:InvalidateQueryCache()
                    for _,slot in ipairs(O.Data.PAPER_DOLL_SLOTS)do
                        CheckEntries(O.Data:BuildCandidatesForSlot(slot),N.Data:BuildCandidatesForSlot(slot))
                        QUERIES=QUERIES+1
                    end
                end
            end
        ''')
        row.update(other_entries=lua.globals().OTHER_COUNT, candidate_queries=lua.globals().QUERIES)
        print(cls,faction,'detached and candidates passed',file=sys.stderr,flush=True)
        assert not loaded, loaded
        for tree, g in zip(['source','optimized'],games): module(tree, 'GearQuestForever/Log.lua', g)
        lua.execute('''
            TEST_LEVEL=30;TEST_SPEC=BASE
            O.Log:EnsureLookupIndex(TEST_CLASS);N.Log:EnsureLookupIndex(TEST_CLASS)
            local a,b=O.Log._lookupIndex,N.Log._lookupIndex
            assert(#a==#b,'lookup count')
            for i=1,#a do
                for _,key in ipairs({'key','itemId','name','nameLower','englishLower'})do Same(a[i][key],b[i][key],'lookup field')end
                CheckEntries(a[i].entries,b[i].entries)
                if i%19==1 then
                    assert(O.Log:LookupDetailEntry(a[i]).id==N.Log:LookupDetailEntry(b[i]).id,'lookup detail')
                    Same(O.Log:LookupRankLines(a[i],TEST_CLASS),N.Log:LookupRankLines(b[i],TEST_CLASS),'lookup ranks')
                end
            end
            LOOKUP_COUNT=#a
            O.Log:ReleaseLookupIndex();N.Log:ReleaseLookupIndex()
            assert(not O.Data._detachedById and not N.Data._detachedById,'lookup retained detached rows')
        ''')
        row['lookup_groups'] = lua.globals().LOOKUP_COUNT
        print(cls,faction,'lookup passed',file=sys.stderr,flush=True)
        result['factions'].append(row)
    # The unchanged scorer consumes ordinary copies of compact entries.
    for tree, g in zip(['source','optimized'],games):
        active_tree = tree
        module(tree, 'GearQuestForever/CustomSpec.lua', g)
        lua.globals().GearQuest = g
        lua.globals().CURRENT_G = g
        lua.execute('''
            GearQuestForeverDB.customSpecs[TEST_CLASS]={{id='c:release-test',base=BASE,name='Release test',overrides={sta=1.3,ap=0.7,sp=1.9,dpsWeight=5}}}
            local job=CURRENT_G.Custom:Prepare(TEST_CLASS,'c:release-test')
            assert(job,'custom preparation')
            for i=1,job.count do CURRENT_G.Custom:Consume(job,job.catalogCursor and CURRENT_G.Data:GetCursorEntry(job.catalogCursor,i) or job.entries[i])end
            assert(CURRENT_G.Custom:Finish(job),'custom finish')
        ''')
    lua.execute('''
        local function custom(g)
            local out={}
            for _,e in ipairs(g.Data.entries)do if e.customSpec then out[#out+1]=e end end
            table.sort(out,function(a,b)return a.id<b.id end)
            return out
        end
        local a,b=custom(O),custom(N)
        CheckEntries(a,b)
        for _,e in ipairs(b)do assert(N.Data:GetEntryById(e.id).pipelineScore==e.pipelineScore,'custom ID')end
        CUSTOM_COUNT=#a
    ''')
    result.update(custom_entries=lua.globals().CUSTOM_COUNT, seconds=round(time.perf_counter()-started,2))
    return result


if __name__ == '__main__':
    results=[]
    for cls in sys.argv[1:] or CLASSES:
        r=run(cls);results.append(r);print(json.dumps(r),flush=True)
        (ROOT/'functional-results.json').write_text(json.dumps(results,indent=2))
