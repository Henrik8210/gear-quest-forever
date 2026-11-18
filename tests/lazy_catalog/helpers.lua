function LogicalEntries(g)
    if not g.Data.NewCatalogCursor then return g.Data.entries end
    local list={}
    local cursor=g.Data:NewCatalogCursor()
    for i=1,cursor.count do list[#list+1]=assert(g.Data:GetCursorEntry(cursor,i)) end
    return list
end

function CheckEntries(a,b)
    assert(#a==#b,'entry count '..#a..'/'..#b)
    for i=1,#a do
        local e=type(b[i])=='number' and N.Data:ResolveCatalogReference(b[i]) or b[i]
        for _,key in ipairs(FIELDS) do Same(a[i][key],e[key],'entry '..i..'.'..key) end
    end
end

function CheckAll()
    local virtual=LogicalEntries(N)
    CheckEntries(O.Data.entries,virtual)
    ID_COUNT=0
    for item,list in pairs(O.Data.byItemId) do
        CheckEntries(list,N.Data:GetEntriesByItemId(item))
    end
    for id,e in pairs(O.Data.byId) do
        local n=assert(N.Data:GetEntryById(id),'saved ID '..id)
        for _,key in ipairs(FIELDS) do Same(e[key],n[key],'saved ID field '..key) end
        ID_COUNT=ID_COUNT+1
    end
    for _,id in ipairs({'missing','gen:mage:0:Head:30:frost:Alliance',
        'gen:mage:6542:Back:999:frost:Alliance','gen:mage:06542:Back:10:frost:Alliance',
        'gen:warrior:1:Head:1:absent:absent:extra'}) do
        assert(N.Data:GetEntryById(id)==nil,'stale ID')
    end
    assert(N.Data:GetEntryById(nil)==nil and N.Data:GetEntryById(false)==nil,'invalid ID')
    local copied=0
    for i=1,#virtual,17 do
        local a,b=O.Data:CopyEntry(O.Data.entries[i]),N.Data:CopyEntry(virtual[i])
        Same(a,b,'copy')
        a.curatedRank=999;b.curatedRank=999
        a.pipelineScore=nil;b.pipelineScore=nil
        a.suffix='test';b.suffix='test'
        Same(a,b,'copy mutations')
        copied=copied+1
    end
    COPY_COUNT=copied
end
