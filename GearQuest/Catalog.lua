local _, GQ = ...
local Data = GQ.Data
local floor, byte = math.floor, string.byte
local REF_BASE = 1000000
local SIDES = { "Alliance", "Horde" }
local LOOKUP_FACTIONS = { { Alliance = true }, { Horde = true } }

-- Original staged text and compact position/selection indexes are permanent.
-- Ordinary Lua entry objects are materialized for queries, saved hunts, or UI.
Data.packedCatalogs = Data.packedCatalogs or {}
Data._catalogByCode = {}
Data._catalogClassOrder = {}
Data._lookupHasSpan = {}

local function NewCache()
    return { values = {}, keys = {}, next = 1 }
end

local function Remember(cache, key, value, limit)
    local pos = cache.next
    local previous = cache.keys[pos]
    if previous ~= nil then
        cache.values[previous] = nil
    end
    cache.keys[pos] = key
    cache.values[key] = value
    cache.next = pos % limit + 1
    return value
end

local function LoadAddon(name)
    if C_AddOns and C_AddOns.LoadAddOn then
        return C_AddOns.LoadAddOn(name)
    end
    if LoadAddOn then
        return LoadAddOn(name)
    end
    return false, "LoadAddOn unavailable"
end

function Data:CoordinateAllowsFaction(itemId, faction)
    local row = self.coordinates[itemId]
    if not row or not row.spots or #row.spots == 0 then
        return true
    end
    for _, spot in ipairs(row.spots) do
        if self:SpotVisible(spot, faction) then
            return true
        end
    end
    return false
end

local function Ordinal(indices, pos)
    local a, b, c = byte(indices, pos, pos + 2)
    return a + b * 256 + c * 65536
end

local ROW_PATTERN = "^(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%d+)\n"
local INDEX_PATTERN = "^(%d+) (%d+) (%d+) (%d+) %d+ (%d+) %S+ (%d+)\n"
local SIDE_KEYS = { "Alliance", "Horde" }
SIDE_KEYS[0] = "_"
local SIDE_IDS = { Alliance = 1, Horde = 2, ["_"] = 0 }
local char, concat, find, num = string.char, table.concat, string.find, tonumber

local function AddIndex(map, key, ref)
    local list = map[key]
    if not list then
        list = {}
        map[key] = list
    end
    list[#list + 1] = ref
end

local function ReadMeta(c, row)
    local off = (row - 1) * 10 + 1
    local a, b, d, e, x, y, slot, lo, hi, spec = byte(c.meta, off, off + 9)
    return a + b * 256 + d * 65536 + e * 16777216,
        x + y * 256,
        slot,
        lo,
        hi,
        spec,
        byte(c.locations, (row - 1) * 5 + 5)
end

local function ReadTextRecord(c, row)
    local off = (row - 1) * 5 + 1
    local a, b, d, e, side = byte(c.locations, off, off + 4)
    local pos = a + b * 256 + d * 65536 + e * 16777216
    local text = c.original.rows[SIDE_KEYS[side]]
    local _, last, item, slot, lo, hi, rank, spec, score, extra = find(text, ROW_PATTERN, pos)
    assert(last, "GearQuest row text changed after indexing")
    item, slot, lo, hi, rank, spec, score, extra =
        num(item), num(slot), num(lo), num(hi), num(rank), num(spec), num(score), num(extra)
    local key = item .. ":" .. extra
    local variant = c.variants[key]
    if not variant then
        variant = { item }
        for k, v in pairs(c.original.extras[extra] or {}) do
            variant[k] = v
        end
        c.variants[key] = variant
    end
    return item, c.slots[slot], lo, hi, rank, c.specNames[spec], SIDES[side], score, variant
end

local function BuildTextIndex(src, code)
    local started = debugprofilestop and debugprofilestop()
    local original = assert(Data[src.picks .. "Packed"], "Missing official packed text")
    assert(
        not original.format
            and type(original.rows) == "table"
            and type(original.slots) == "table"
            and type(original.specs) == "table"
            and type(original.extras) == "table",
        "Unsupported staged gear format"
    )
    local c = {
        code = code,
        count = 0,
        original = original,
        source = src,
        slots = original.slots,
        specNames = original.specs,
        variants = {},
        itemRows = {},
        slotSpecRows = {},
        specFactionRows = {},
        rows = {},
    }
    local locations, meta = {}, {}
    local facts = assert(Data[src.facts], "Missing item facts")
    local validItems, normalizedSlots, slotLists = {}, {}, {}
    for id, slot in pairs(original.slots) do
        normalizedSlots[id] = Data:NormalizeSlotName(slot)
    end
    local sides = {}
    for side in pairs(original.rows) do
        assert(SIDE_IDS[side] ~= nil, "Unsupported faction")
        sides[#sides + 1] = side
    end
    table.sort(sides)
    for _, side in ipairs(sides) do
        local text = original.rows[side]
        assert(type(text) == "string" and #text < 4294967296, "Unsupported row text")
        local group = { first = c.count + 1, count = 0 }
        c.rows[side] = group
        local specRuns = {}
        local pos = 1
        while pos <= #text do
            local _, last, item, slot, lo, hi, spec, extra = find(text, INDEX_PATTERN, pos)
            assert(last, "Unsupported staged row at " .. pos)
            item, slot, lo, hi, spec, extra = num(item), num(slot), num(lo), num(hi), num(spec), num(extra)
            assert(
                original.slots[slot] and original.specs[spec] and (extra == 0 or original.extras[extra]),
                "Invalid row codes"
            )
            local allowed = validItems[item]
            if allowed == nil then
                assert(item < 4294967296, "Item ID exceeds index range")
                allowed = facts[item] and not Data:IsForeverMissing(item) or false
                validItems[item] = allowed
            end
            if allowed then
                c.count = c.count + 1
                assert(
                    c.count < REF_BASE
                        and slot <= 255
                        and lo >= 0
                        and hi <= 255
                        and spec <= 255
                        and extra < 65536,
                    "Text index limit exceeded"
                )
                locations[#locations + 1] = char(
                    pos % 256,
                    floor(pos / 256) % 256,
                    floor(pos / 65536) % 256,
                    floor(pos / 16777216),
                    SIDE_IDS[side]
                )
                -- Covering-index columns support eligibility and Lookup without
                -- parsing rank/score or creating a detailed gear entry.
                meta[#meta + 1] = char(
                    item % 256,
                    floor(item / 256) % 256,
                    floor(item / 65536) % 256,
                    floor(item / 16777216),
                    extra % 256,
                    floor(extra / 256),
                    slot,
                    lo,
                    hi,
                    spec
                )
                local ref = char(c.count % 256, floor(c.count / 256) % 256, floor(c.count / 65536))
                AddIndex(c.itemRows, item, ref)
                local bySpec = slotLists[slot]
                if not bySpec then
                    bySpec = {}
                    slotLists[slot] = bySpec
                end
                local list = bySpec[spec]
                if not list then
                    local key = normalizedSlots[slot] .. "|" .. original.specs[spec]
                    list = c.slotSpecRows[key] or {}
                    c.slotSpecRows[key], bySpec[spec] = list, list
                end
                list[#list + 1] = ref
                group.count = group.count + 1
                local runs = specRuns[spec]
                if not runs then
                    runs = {}
                    specRuns[spec] = runs
                    c.specFactionRows[original.specs[spec] .. "|" .. side] = runs
                end
                local lastRun = runs[#runs]
                if lastRun and lastRun.first + lastRun.count == c.count then
                    lastRun.count = lastRun.count + 1
                else
                    runs[#runs + 1] = { first = c.count, count = 1 }
                end
            end
            pos = last + 1
        end
    end
    c.locations, c.meta = concat(locations), concat(meta)
    for _, map in ipairs({ c.itemRows, c.slotSpecRows }) do
        for key, list in pairs(map) do
            map[key] = concat(list)
        end
    end
    if started then
        c.indexMS = debugprofilestop() - started
    end
    return c
end

function Data:SyncCatalogOrder()
    self._catalogNextEpoch = self._catalogNextEpoch or 0
    for _, entry in ipairs(self.entries or {}) do
        if not rawget(entry, "_gqCatalogOrder") then
            self._catalogNextEpoch = self._catalogNextEpoch + 1
            rawset(entry, "_gqCatalogOrder", self._catalogNextEpoch * REF_BASE)
        end
    end
end

local function OriginalOrder(a, b)
    return a._gqCatalogOrder < b._gqCatalogOrder
end

function Data:ResolveCatalogReference(reference)
    if type(reference) ~= "number" then
        return reference
    end
    local c = self._catalogByCode[floor(reference / REF_BASE)]
    local row = reference % REF_BASE
    if not c or not c.active or row < 1 or row > c.count then
        return nil
    end
    self._catalogObjects = self._catalogObjects or NewCache()
    local cached = self._catalogObjects.values[reference]
    if cached then
        return cached
    end
    local item, slot, lo, hi, rank, spec, side, score, variant = ReadTextRecord(c, row)
    local entry = self:MakeCatalogEntry(c.source, variant, slot, lo, hi, rank, spec, side, score)
    if entry then
        rawset(entry, "_gqCatalogOrder", c.order + row)
        Remember(self._catalogObjects, reference, entry, 1024)
    end
    return entry
end

-- Unstaged development copies keep the adapter's row-array implementation.
-- Release staging still supplies the existing text format; no build changes.
local OriginalEnsureClassLoaded = Data.EnsureClassLoaded
local OriginalReleaseExpandedClass = Data.ReleaseExpandedClass
function Data:EnsureClassLoaded(classFile)
    if not classFile then
        return false
    end
    classFile = string.upper(classFile)
    self._loadedClasses = self._loadedClasses or {}
    self._expandedClasses = self._expandedClasses or {}
    if self._expandedClasses[classFile] then
        return true
    end
    if self._textIndexErrors and self._textIndexErrors[classFile] then
        return false
    end
    local addon = self.catalogClassAddons[classFile]
    if not addon then
        return false
    end
    local found = false
    for _, src in ipairs(self.catalogSources) do
        if src.class == classFile and (self[src.picks .. "Packed"] or self[src.picks]) then
            found = true
        end
    end
    if not found then
        local ok, reason = LoadAddon(addon)
        if not ok then
            self._classLoadFailed = self._classLoadFailed or {}
            if not self._classLoadFailed[classFile] then
                self._classLoadFailed[classFile] = true
                local label = classFile:sub(1, 1) .. classFile:sub(2):lower()
                GQ:Chat(
                    "|cffff0000GearQuest|r: "
                        .. string.format(
                            GQ.L["could not load %s hunt data (%s). Enable |cff00ff00GearQuest Forever: %s|r in the addon list, then /reload."],
                            label,
                            tostring(reason),
                            label
                        )
                )
            end
            return false
        end
    end
    for _, src in ipairs(self.catalogSources) do
        if src.class == classFile and self[src.picks] and not self[src.picks .. "Packed"] then
            self._rawCatalogClasses = self._rawCatalogClasses or {}
            self._rawCatalogClasses[classFile] = true
            local ok = OriginalEnsureClassLoaded(self, classFile)
            self._lookupHasSpan[classFile] = ok
                    and self._classEntrySpan
                    and self._classEntrySpan[classFile] ~= nil
                or nil
            self:SyncCatalogOrder()
            return ok
        end
    end
    -- Only position/selection indexes are built. The original row text stays
    -- authoritative; no second gear catalog or saved conversion cache exists.
    for code, src in ipairs(self.catalogSources) do
        if src.class == classFile and not self.packedCatalogs[src.picks] then
            local ok, result = pcall(BuildTextIndex, src, code)
            if not ok then
                self._textIndexErrors = self._textIndexErrors or {}
                if not self._textIndexErrors[classFile] then
                    self._textIndexErrors[classFile] = true
                    GQ:Chat(
                        "|cffff0000GearQuest|r: "
                            .. string.format(
                                GQ.L["could not index %s hunt data (%s). Please /reload."],
                                classFile,
                                tostring(result)
                            )
                    )
                end
                return false
            end
            self.packedCatalogs[src.picks] = result
        end
    end
    self:SyncCatalogOrder()
    self._expandedFaction = self._expandedFaction or {}
    self._expandedFaction[classFile] = self:HuntFactionFor(classFile)
    local count = 0
    for _, src in ipairs(self.catalogSources) do
        if src.class == classFile then
            local c = self.packedCatalogs[src.picks]
            if c then
                self._catalogNextEpoch = self._catalogNextEpoch + 1
                c.order = self._catalogNextEpoch * REF_BASE
                c.source, c.active = src, true
                self._catalogByCode[c.code] = c
                count = count
                    + (c.rows[self._expandedFaction[classFile]] and c.rows[self._expandedFaction[classFile]].count or 0)
                    + (c.rows._ and c.rows._.count or 0)
            end
        end
    end
    if count == 0 then
        return false
    end
    self._catalogClassOrder[#self._catalogClassOrder + 1] = classFile
    self._lookupHasSpan[classFile] = true
    self._loadedClasses[classFile], self._expandedClasses[classFile] = true, true
    self._generatedCount = (self._generatedCount or 0) + count
    self._entryGeneration = (self._entryGeneration or 0) + 1
    self._showEntryMemo, self._catalogSlots = nil, nil
    self:BuildSuffixLookup(classFile)
    if GQ.Custom and GQ.Custom.OnClassExpanded then
        GQ.Custom:OnClassExpanded(classFile)
    end
    return true
end

function Data:ReleaseExpandedClass(classFile)
    classFile = classFile and string.upper(classFile)
    if self._rawCatalogClasses and self._rawCatalogClasses[classFile] then
        self._catalogObjects, self._catalogSlots = nil, nil
        self._lookupHasSpan = {}
        return OriginalReleaseExpandedClass(self, classFile)
    end
    if not (self._expandedClasses and self._expandedClasses[classFile]) then
        return false
    end
    for _, c in pairs(self.packedCatalogs) do
        if c.source and c.source.class == classFile then
            c.active = false
        end
    end
    for i = #self._catalogClassOrder, 1, -1 do
        if self._catalogClassOrder[i] == classFile then
            table.remove(self._catalogClassOrder, i)
        end
    end
    -- Custom entries for a released simulated class follow upstream cleanup.
    local kept = {}
    for _, e in ipairs(self.entries) do
        if not (e.generated and e.classes and e.classes[classFile]) then
            kept[#kept + 1] = e
        end
    end
    self.entries = kept
    self._expandedClasses[classFile] = nil
    self._expandedFaction[classFile] = nil
    self._classEntrySpan = nil
    self._lookupHasSpan = {}
    self._catalogObjects, self._catalogSlots = nil, nil
    self._entryGeneration = (self._entryGeneration or 0) + 1
    if GQ.Custom and GQ.Custom.OnClassReleased then
        GQ.Custom:OnClassReleased(classFile)
    end
    return true
end

local function ActiveCatalogs(data, classFile)
    local out = {}
    for _, class in ipairs(data._catalogClassOrder) do
        if not classFile or class == classFile then
            for _, src in ipairs(data.catalogSources) do
                local c = data.packedCatalogs[src.picks]
                if src.class == class and c and c.active then
                    out[#out + 1] = c
                end
            end
        end
    end
    return out
end

function Data:NewCatalogCursor(classFile, baseSpec, generatedOnly, otherFactions)
    self:SyncCatalogOrder()
    local cursor = { segments = {}, count = 0 }
    local raw = self._rawCatalogClasses and self._rawCatalogClasses[classFile]
    if raw and otherFactions then
        -- Lookup steps this legacy reader before merging; only unstaged
        -- copies need detailed other-faction objects.
        cursor.reader = self:OtherFactionReader(classFile)
        cursor.rawEntries = {}
        return cursor
    end
    if (not generatedOnly or raw) and not otherFactions then
        local run, previous
        local span = raw
            and generatedOnly
            and not baseSpec
            and self._classEntrySpan
            and self._classEntrySpan[classFile]
        local entries = self.entries or {}
        for i = span and span[1] or 1, span and span[2] or #entries do
            local e = entries[i]
            if
                (not baseSpec or not e.customSpec) and (not classFile or (e.classes and e.classes[classFile]))
            then
                if not run or e._gqCatalogOrder ~= previous + REF_BASE then
                    run = { regular = {}, count = 0, order = e._gqCatalogOrder }
                    cursor.segments[#cursor.segments + 1] = run
                end
                run.regular[#run.regular + 1] = e
                run.count = run.count + 1
                cursor.count = cursor.count + 1
                previous = e._gqCatalogOrder
            end
        end
    end
    for _, c in ipairs(ActiveCatalogs(self, classFile)) do
        local side = self._expandedFaction[c.source.class]
        local sides = {}
        if otherFactions then
            for faction in pairs(c.rows) do
                if faction ~= side and faction ~= "_" then
                    sides[#sides + 1] = faction
                end
            end
            table.sort(sides)
        else
            sides = { side, "_" }
        end
        for group, faction in ipairs(sides) do
            local ranges = baseSpec and c.specFactionRows[baseSpec .. "|" .. faction]
                or (not baseSpec and { c.rows[faction] })
            for _, range in ipairs(ranges or {}) do
                if range and range.count > 0 then
                    cursor.segments[#cursor.segments + 1] = {
                        catalog = c,
                        first = range.first,
                        count = range.count,
                        order = c.order + range.first,
                    }
                    cursor.count = cursor.count + range.count
                end
            end
        end
    end
    table.sort(cursor.segments, function(a, b)
        return a.order < b.order
    end)
    return cursor
end

local function CursorLocation(cursor, index)
    for _, source in ipairs(cursor.segments) do
        if index <= source.count then
            if source.regular then
                return source.regular[index]
            end
            local row = source.first and source.first + index - 1 or index
            return nil, source.catalog, row
        end
        index = index - source.count
    end
end

function Data:GetCursorEntry(cursor, index)
    local regular, catalog, row = CursorLocation(cursor, index)
    if regular then
        return regular
    end
    if catalog then
        local reference = catalog.code * REF_BASE + row
        return self:ResolveCatalogReference(reference), reference
    end
end

function Data:GetCursorLookupEntry(cursor, index)
    local regular, c, row = CursorLocation(cursor, index)
    if regular then
        return regular
    end
    if not c then
        return nil
    end
    local item, extra, _, _, _, spec, side = ReadMeta(c, row)
    local variant = c.original.extras[extra]
    cursor.lookupStub = cursor.lookupStub or {}
    local stub = cursor.lookupStub
    self._catalogClassFlags = self._catalogClassFlags or {}
    local class = c.source.class
    self._catalogClassFlags[class] = self._catalogClassFlags[class] or { [class] = true }
    stub.itemId, stub.suffix, stub.classes = item, variant and variant.suffix, self._catalogClassFlags[class]
    stub.specs = c.source.specs[c.specNames[spec]]
    stub.factions = LOOKUP_FACTIONS[side]
    cursor.lookupMetas = cursor.lookupMetas or {}
    cursor.lookupMetas[c.code] = cursor.lookupMetas[c.code] or { __gqSource = c.source.ix }
    setmetatable(stub, cursor.lookupMetas[c.code])
    return stub, c.code * REF_BASE + row
end

function Data:IterCatalog(classFile)
    local cursor, index = self:NewCatalogCursor(classFile), 0
    return function()
        index = index + 1
        if index > cursor.count then
            return nil
        end
        local entry, reference = self:GetCursorEntry(cursor, index)
        return index, entry, reference
    end
end

function Data:IngestPackedSuffixes(classFile, ingest, ingestRange)
    for _, c in ipairs(ActiveCatalogs(self, classFile)) do
        for item, lo, extra in string.gmatch(c.original.suffixRows or "", "(%d+) (%d+) (%d+)\n") do
            local x = c.original.extras[tonumber(extra)]
            if x then
                ingest(tonumber(item), x.suffix, tonumber(lo), x.suffixId, x.suffixRange)
                ingestRange(tonumber(item), x.suffix, tonumber(lo), x.suffixRange)
            end
        end
    end
end

local OriginalBuildIndex = Data.BuildIndex
function Data:BuildIndex()
    self:SyncCatalogOrder()
    OriginalBuildIndex(self)
    self._catalogSlots = nil
    self._catalogItemCache = NewCache()
    local regularItems = self.byItemId
    self.byItemId = setmetatable({}, {
        __index = function(index, itemId)
            local list = {}
            local regular = regularItems[itemId] or {}
            for _, e in ipairs(regular) do
                list[#list + 1] = e
            end
            for _, c in ipairs(ActiveCatalogs(self)) do
                local rows = c.itemRows[itemId]
                if rows then
                    for pos = 1, #rows, 3 do
                        local row = Ordinal(rows, pos)
                        if self:CatalogRowVisible(c, row) then
                            local e = self:ResolveCatalogReference(c.code * REF_BASE + row)
                            if e then
                                list[#list + 1] = e
                            end
                        end
                    end
                end
            end
            table.sort(list, OriginalOrder)
            -- Cache a bounded number of full item histories, not every item
            -- visited by a tooltip/Lookup session.
            local cache = self._catalogItemCache
            local old = cache.keys[cache.next]
            if old ~= nil then
                rawset(index, old, nil)
            end
            Remember(cache, itemId, list, 64)
            rawset(index, itemId, list)
            return list
        end,
    })
    local idCache = NewCache()
    self._catalogIdCache = idCache
    setmetatable(self.byId, {
        __index = function(index, id)
            local e = self:ResolveGeneratedEntryId(id)
            if e then
                local old = idCache.keys[idCache.next]
                if old ~= nil then
                    rawset(index, old, nil)
                end
                Remember(idCache, id, e, 512)
                rawset(index, id, e)
            end
            return e
        end,
    })
end

function Data:GetClassSlotEntryList(slotName, activeOnly)
    -- History/removal tools retain the full-level API. Normal hunt and rank
    -- queries request activeOnly and reject irrelevant packed rows before
    -- allocating entries. The same five-level grace still comes from Equip.
    slotName = self:NormalizeSlotName(slotName)
    local class = GQ:GetEffectiveClass()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or ""
    local grace = GQ.Equip and GQ.Equip.LEVEL_GRACE or 0
    -- Other-spec tooltip ranks probe every spec of the class in turn, so each
    -- spec keeps its own lists instead of evicting the active spec's.
    local key = table.concat({
        class or "",
        tostring(level),
        faction,
        tostring(grace),
        tostring(self._entryGeneration),
    }, ":")
    if not self._catalogSlots or self._catalogSlots.key ~= key then
        self._catalogSlots = { key = key, specs = {} }
    end
    local specKey = tostring(spec)
    local slots = self._catalogSlots.specs[specKey]
    if not slots then
        slots = { full = NewCache(), active = NewCache() }
        self._catalogSlots.specs[specKey] = slots
    end
    local cache = activeOnly and slots.active or slots.full
    if cache.values[slotName] then
        return cache.values[slotName]
    end
    local list = {}
    local map = self.byClassSlotSpec and self.byClassSlotSpec[class] and self.byClassSlotSpec[class][slotName]
    local regular = map and spec and map[spec] or {}
    local any = map and map._any or {}
    local function keep(e)
        return not activeOnly
            or (
                level >= (e.minLevel or 1)
                and level <= (e.maxLevel or level) + grace
                and (not e.factions or e.factions[faction])
            )
    end
    for _, e in ipairs(regular) do
        if keep(e) then
            list[#list + 1] = e
        end
    end
    if spec then
        for _, c in ipairs(ActiveCatalogs(self, class)) do
            local rows = c.slotSpecRows[slotName .. "|" .. spec]
            if rows then
                for pos = 1, #rows, 3 do
                    local row = Ordinal(rows, pos)
                    local eligible = self:CatalogRowVisible(c, row)
                    if eligible and activeOnly then
                        local offset = (row - 1) * 10
                        local lo, hi = byte(c.meta, offset + 8, offset + 9)
                        local side = byte(c.locations, (row - 1) * 5 + 5)
                        eligible = level >= lo
                            and level <= hi + grace
                            and (side == 0 or SIDES[side] == faction)
                    end
                    if eligible then
                        local e = self:ResolveCatalogReference(c.code * REF_BASE + row)
                        if e then
                            list[#list + 1] = e
                        end
                    end
                end
            end
        end
    end
    table.sort(list, OriginalOrder)
    for _, e in ipairs(any) do
        if keep(e) then
            list[#list + 1] = e
        end
    end
    return Remember(cache, slotName, list, activeOnly and 24 or 4)
end

function Data:GetCatalogRecordValues(c, row)
    return ReadTextRecord(c, row)
end

function Data:CatalogRowVisible(c, row)
    local side = byte(c.locations, (row - 1) * 5 + 5)
    return side == 0 or SIDES[side] == self._expandedFaction[c.source.class]
end

local OriginalResolveGeneratedEntryId = Data.ResolveGeneratedEntryId
function Data:ResolveGeneratedEntryId(id)
    if type(id) ~= "string" then
        return nil
    end
    local class, item, slot, lo, spec, side = id:match("^gen:([^:]+):(%d+):([^:]+):(%d+):([^:]+):([^:]+)$")
    if not class then
        return nil
    end
    class, item, lo = class:upper(), tonumber(item), tonumber(lo)
    if self._rawCatalogClasses and self._rawCatalogClasses[class] then
        return OriginalResolveGeneratedEntryId(self, id)
    end
    local catalogs = ActiveCatalogs(self, class)
    for i = #catalogs, 1, -1 do
        local c = catalogs[i]
        local refs = c.itemRows[item]
        for off = #(refs or "") - 2, 1, -3 do
            local row = Ordinal(refs, off)
            local _, _, s, min, _, sp, fa = ReadMeta(c, row)
            if
                c.slots[s] == slot
                and min == lo
                and tostring(c.specNames[sp]) == spec
                and tostring(SIDES[fa]) == side
                and (self:CatalogRowVisible(c, row) or self._catalogLookupClass == class)
            then
                local e = self:ResolveCatalogReference(c.code * REF_BASE + row)
                if e and e.id == id then
                    return e
                end
            end
        end
    end
end

function Data:SetCatalogLookupClass(class)
    if self._catalogLookupClass == class then
        return
    end
    self._catalogLookupClass = class
    local cache = self._catalogIdCache
    for _, id in ipairs(cache and cache.keys or {}) do
        rawset(self.byId, id, nil)
    end
    if cache then
        cache.keys, cache.values, cache.next = {}, {}, 1
    end
end

function Data:HasCatalogSlotSpec(class, slot, spec)
    slot = self:NormalizeSlotName(slot)
    local map = self.byClassSlotSpec and self.byClassSlotSpec[class] and self.byClassSlotSpec[class][slot]
    if map and ((map[spec] and #map[spec] > 0) or (map._any and #map._any > 0)) then
        return true
    end
    for _, c in ipairs(ActiveCatalogs(self, class)) do
        local refs = c.slotSpecRows[slot .. "|" .. tostring(spec)]
        for off = 1, #(refs or ""), 3 do
            if self:CatalogRowVisible(c, Ordinal(refs, off)) then
                return true
            end
        end
    end
    return false
end

function Data:IterCatalogItemIds()
    local ids = {}
    for _, e in ipairs(self.entries or {}) do
        if e.itemId then
            ids[e.itemId] = true
        end
    end
    for _, c in ipairs(ActiveCatalogs(self)) do
        for item, refs in pairs(c.itemRows) do
            for off = 1, #refs, 3 do
                if self:CatalogRowVisible(c, Ordinal(refs, off)) then
                    ids[item] = true
                    break
                end
            end
        end
    end
    return next, ids, nil
end
