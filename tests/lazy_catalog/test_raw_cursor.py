"""Readable-data cursors include curated rows; Lookup retains legacy spans."""
from support import Harness

h = Harness("optimized", "WARRIOR")
h.module("GearQuestForever/Log.lua")
h.lua.execute('''
    assert(G.Data._rawCatalogClasses.WARRIOR, 'expected readable row data')
    -- Warrior has no curated rows in the shipped data. Add a fixture copied
    -- from a real entry so the cursor's regular-entry path is exercised.
    local first=G.Data._classEntrySpan.WARRIOR[1]
    local curated=G.Data:CopyEntry(G.Data.entries[first])
    curated.id,curated.generated='test:curated',false
    G.Data.entries[#G.Data.entries+1]=curated
    G.Data:BuildIndex()
    local expected=0
    for _,e in ipairs(G.Data.entries)do
        if e.classes and e.classes.WARRIOR then expected=expected+1 end
    end
    assert(G.Data:NewCatalogCursor('WARRIOR').count==expected,
        'class cursor omitted curated rows')
    G.Log:EnsureLookupIndex('WARRIOR')
    local own=G.Data:NewCatalogCursor('WARRIOR',nil,true)
    local span=G.Data._classEntrySpan.WARRIOR
    assert(own.count==span[2]-span[1]+1, 'Lookup span includes curated rows')
    G.Log:ReleaseLookupIndex()
    G.Data:ReleaseExpandedClass('WARRIOR')
    G.Data:BuildIndex()
    assert(G.Data:NewCatalogCursor('WARRIOR').count>0, 'curated rows released')
    assert(G.Data:EnsureClassLoaded('WARRIOR'))
    G.Data:BuildIndex()
    assert(G.Data:NewCatalogCursor('WARRIOR').count==expected, 'reactivation drift')
''')
print("Readable-data class cursors, Lookup spans, and reactivation passed")
