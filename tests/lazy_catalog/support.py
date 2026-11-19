"""Lua 5.1 fixtures with deterministic WoW API stubs (no UI emulation)."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime
ROOT = Path(os.environ["GQ_LAZY_TEST_ROOT"])
CLASSES = ['MAGE','WARRIOR','ROGUE','PRIEST','HUNTER','DRUID','PALADIN','SHAMAN','WARLOCK']
BASES = dict(MAGE='frost',WARRIOR='fury',ROGUE='combat',PRIEST='holy',HUNTER='beast_mastery',DRUID='feral',PALADIN='retribution',SHAMAN='enhancement',WARLOCK='affliction')
FIELDS = set('id itemId slot minLevel maxLevel curatedRank pipelineScore specs factions classes generated sourceType instructions setPiece lore zone npc questName profession reqRep reqSkills proc suffix suffixChance suffixId suffixRange route hand origin reserve healOnly name quality ilvl reqLevel customSpec'.split())
SETUP='''
    function UnitClass() return TEST_CLASS, TEST_CLASS end
    function IsAddOnLoaded() return true end
    function strtrim(s) return s:match('^%s*(.-)%s*$') end
    GearQuestForeverDB={customSpecs={}}
    function NewGQ()
        local g={Data={},L=setmetatable({},{__index=function(_,k)return k end})}
        function g.LocaleTable(t)return t end
        function g.TN(kind,text)return text end
        function g.TL(text)return text end
        function g.TX(text)return text end
        function g:Chat(s)error(s)end
        function g:GetEffectiveClass()return TEST_CLASS end
        function g:GetEffectiveLevel()return TEST_LEVEL or 30 end
        function g:GetEffectiveFaction()return TEST_FACTION or 'Alliance' end
        function g:GetEffectiveSpec()return TEST_SPEC end
        return g
    end
    function Same(a,b,path)
        if type(a)~=type(b) then error(path..': type mismatch '..type(a)..'/'..type(b)) end
        if type(a)~='table' then
            if a~=b then error(path..': '..tostring(a)..' ~= '..tostring(b)) end
            return
        end
        for k,v in pairs(a) do Same(v,b[k],path..'.'..tostring(k)) end
        for k in pairs(b) do if a[k]==nil then error(path..': extra key '..tostring(k)) end end
    end
    function CheckEntries(a,b)
        assert(#a==#b,'entry count')
        for i=1,#a do
            for _,key in ipairs(FIELDS) do Same(a[i][key],b[i][key],'entry '..i..'.'..key) end
        end
    end
    function CheckBands()
        local views=0
        for class,slots in pairs(O.Data.byClassSlotSpec) do
            if class==TEST_CLASS then
                for slot,specs in pairs(slots) do
                    local specNames={}
                    for spec in pairs(specs) do specNames[#specNames+1]=spec end
                    table.sort(specNames)
                    for _,spec in ipairs(specNames) do
                        if spec~='_any' and spec~='_lookup' and spec~='_lookupKey' then
                            TEST_SPEC=spec
                            local ol=O.Data:GetClassSlotEntryList(slot)
                            local nl=N.Data:GetClassSlotEntryList(slot)
                            for level=1,60 do
                                TEST_LEVEL=level
                                local omin,omax=O.Data:SelectActiveBand(ol,level)
                                local nmin,nmax=N.Data:SelectActiveBand(nl,level)
                                assert(omin==nmin and omax==nmax,'band bounds')
                                for _,faction in ipairs({'Alliance','Horde'}) do
                                    TEST_FACTION=faction
                                    local function candidates(g,list)
                                        local pool={}
                                        for _,e in ipairs(list) do
                                            if not e.factions or e.factions[faction] then pool[#pool+1]=e end
                                        end
                                        return g.Data:DeduplicateEntriesByItem(g.Data:FilterToActiveBand(pool))
                                    end
                                    local a,b=candidates(O,ol),candidates(N,nl)
                                    assert(#a==#b,'band candidates')
                                    for i=1,#a do assert(a[i].id==b[i].id,'band ranking/ordering') end
                                    views=views+1
                                end
                            end
                        end
                    end
                end
            end
        end
        VIEW_COUNT=views
    end
'''

class Harness:
    def __init__(self,tree,cls,cache_lua=None,before_activation_lua=None,metadata_overrides=None):
        self.tree,self.cls=tree,cls
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(SETUP.replace('function g:GetEffectiveClass()return TEST_CLASS end','function g:GetEffectiveClass()return TEST_VIEW_CLASS or TEST_CLASS end'))
        self.lua.globals().TEST_CLASS=cls
        self.lua.globals().TEST_SPEC=BASES[cls]
        self.lua.globals().TEST_LEVEL=30
        self.g=self.lua.eval('NewGQ()')
        self.g.VERSION='test'
        self.loader=self.lua.eval('function(code,name,g)GearQuest=g;local f,e=loadstring(code,name);assert(f,e);return f("GearQuestForever",g)end')
        self.loaded=[]
        self.lua.globals().PY_LOAD=self.load_addon
        self.metadata_overrides=metadata_overrides or {}
        self.lua.globals().GetAddOnMetadata=self.metadata
        self.lua.execute('function LoadAddOn(name)return PY_LOAD(name)end')
        self.base=self.mark()
        for line in (ROOT/tree/'GearQuestForever/GearQuestForever.toc').read_text().splitlines():
            if line in ['Data.lua','DataAdapter.lua','Catalog.lua'] or (line.startswith('_generated/') and line.endswith('.lua')):self.module('GearQuestForever/'+line)
        self.class_files(cls)
        if cache_lua:self.lua.execute(cache_lua)
        if before_activation_lua:self.lua.execute(before_activation_lua)
        self.g.Data.EnsureClassLoaded(self.g.Data,cls)
        self.g.Data.BuildIndex(self.g.Data)
        self.lua.execute('''
            G=GearQuest
            G.PublicText=function(text)return type(text)=='string' and text or nil end
            G.FoldText=string.lower
            function G:WithContextSnapshot(fn,...)return fn(...)end
            G.Equip={LEVEL_GRACE=5}
            function G.Equip:EntryWithinLevelBand(e)return TEST_LEVEL>=(e.minLevel or 1) and TEST_LEVEL<=(e.maxLevel or TEST_LEVEL)+self.LEVEL_GRACE end
            function G.Equip:EntryMatchesSpec(e)return not e.specs or e.specs[TEST_SPEC]end
            function G.Equip:EntryMatchesItemRules()return true end
            function G.Equip:EntryArmorIsWearable()return true end
            function QueryCycle()
                G.Data:InvalidateQueryCache()
                local n=0
                for _,slot in ipairs(G.Data.BASE_SLOTS) do n=n+#G.Data:BuildCandidatesForSlot(slot)end
                n=n+#G.Data:BuildCandidatesForSlot('Ranged')
                return n
            end
        ''')
    def module(self,path):
        p=ROOT/self.tree/path
        self.loader(p.read_text(encoding='utf-8-sig'),'@'+str(p),self.g)
    def metadata(self,addon,key):
        if (addon,key) in self.metadata_overrides:return self.metadata_overrides[(addon,key)]
        toc=ROOT/self.tree/addon/(addon+'.toc')
        if not toc.exists():return None
        prefix='## '+key+':'
        for line in toc.read_text(encoding='utf-8-sig').splitlines():
            if line.startswith(prefix):return line[len(prefix):].strip()
        return None
    def class_files(self,cls):
        folder='GearQuestForever_'+cls
        for line in (ROOT/self.tree/folder/(folder+'.toc')).read_text().splitlines():
            if line.endswith('.lua'):self.module(folder+'/'+line)
    def load_addon(self,name):
        for line in (ROOT/self.tree/name/(name+'.toc')).read_text().splitlines():
            if line.endswith('.lua'):self.module(name+'/'+line)
        self.loaded.append(name)
        return True,None
    def mark(self):
        self.lua.execute('collectgarbage("collect");collectgarbage("collect")')
        return self.lua.eval('collectgarbage("count")')/1024
    def memory(self):return round(self.mark()-self.base,3)
