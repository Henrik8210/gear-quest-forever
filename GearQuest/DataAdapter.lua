local _, GQ = ...
local L = GQ.L

-- Expands the generated BiS tables into GQ.Data.entries, the array that
-- Indicator.lua, Log.lua and Tracker.lua already iterate. Nothing in those files
-- needs to change: generated rows arrive in exactly the shape curated ones use.
--
-- Per class, levels 1-9 and 10-60 both come from the scorer.
--   1-9            <class>Early1to9, both factions, one row per spec
--   10-60          <class>Picks
--   70             not used (Forever cap is 60; TBC L70 curated was stripped)

local FACTION = { Alliance = { Alliance = true }, Horde = { Horde = true } }

-- Paladin was first through and its generated tables are unprefixed; every class
-- after it is prefixed. Nothing collides, so the older file is left as it is
-- rather than regenerated for cosmetics.
local SOURCES = {
  { class = "PALADIN", picks = "paladinPicks",     facts = "itemFacts",
    hasSpec = true,
    specs = { retribution = { retribution = true },
              protection  = { protection  = true },
              holy        = { holy        = true },
              shockadin   = { shockadin   = true } } },
  { class = "PALADIN", picks = "paladinEarly1to9", facts = "paladinEarly1to9Facts",
    hasSpec = true,
    specs = { retribution = { retribution = true },
              protection  = { protection  = true },
              holy        = { holy        = true },
              shockadin   = { shockadin   = true } } },

  { class = "WARRIOR", picks = "warriorPicks",     facts = "warriorItemFacts",
    hasSpec = true,
    specs = { arms       = { arms       = true },
              fury       = { fury       = true },
              protection = { protection = true } } },
  { class = "WARRIOR", picks = "warriorEarly1to9", facts = "warriorEarly1to9Facts",
    hasSpec = true,
    specs = { arms       = { arms       = true },
              fury       = { fury       = true },
              protection = { protection = true } } },

  { class = "HUNTER",  picks = "hunterPicks",      facts = "hunterItemFacts",
    hasSpec = true,
    specs = { beast_mastery = { beast_mastery = true },
              marksmanship  = { marksmanship  = true },
              survival      = { survival      = true } } },
  { class = "HUNTER",  picks = "hunterEarly1to9",  facts = "hunterEarly1to9Facts",
    hasSpec = true,
    specs = { beast_mastery = { beast_mastery = true },
              marksmanship  = { marksmanship  = true },
              survival      = { survival      = true } } },

  { class = "DRUID",   picks = "druidPicks",       facts = "druidItemFacts",
    hasSpec = true,
    specs = { bear        = { bear        = true },
              feral       = { feral       = true },
              balance     = { balance     = true },
              restoration = { restoration = true } } },
  { class = "DRUID",   picks = "druidEarly1to9",   facts = "druidEarly1to9Facts",
    hasSpec = true,
    specs = { bear        = { bear        = true },
              feral       = { feral       = true },
              balance     = { balance     = true },
              restoration = { restoration = true } } },

  { class = "SHAMAN",  picks = "shamanPicks",      facts = "shamanItemFacts",
    hasSpec = true,
    specs = { elemental   = { elemental   = true },
              enhancement = { enhancement = true },
              enhancement_tank = { enhancement_tank = true },
              restoration = { restoration = true } } },
  { class = "SHAMAN",  picks = "shamanEarly1to9",  facts = "shamanEarly1to9Facts",
    hasSpec = true,
    specs = { elemental   = { elemental   = true },
              enhancement = { enhancement = true },
              enhancement_tank = { enhancement_tank = true },
              restoration = { restoration = true } } },

  { class = "ROGUE",   picks = "roguePicks",       facts = "rogueItemFacts",
    hasSpec = true,
    specs = { combat        = { combat        = true },
              assassination = { assassination = true },
              subtlety      = { subtlety      = true } } },
  { class = "ROGUE",   picks = "rogueEarly1to9",   facts = "rogueEarly1to9Facts",
    hasSpec = true,
    specs = { combat        = { combat        = true },
              assassination = { assassination = true },
              subtlety      = { subtlety      = true } } },

  { class = "PRIEST",  picks = "priestPicks",      facts = "priestItemFacts",
    hasSpec = true,
    specs = { holy       = { holy       = true },
              discipline = { discipline = true },
              shadow     = { shadow     = true } } },
  { class = "PRIEST",  picks = "priestEarly1to9",  facts = "priestEarly1to9Facts",
    hasSpec = true,
    specs = { holy       = { holy       = true },
              discipline = { discipline = true },
              shadow     = { shadow     = true } } },

  { class = "WARLOCK", picks = "warlockPicks",     facts = "warlockItemFacts",
    hasSpec = true,
    specs = { affliction  = { affliction  = true },
              demonology  = { demonology  = true },
              destruction = { destruction = true } } },
  { class = "WARLOCK", picks = "warlockEarly1to9", facts = "warlockEarly1to9Facts",
    hasSpec = true,
    specs = { affliction  = { affliction  = true },
              demonology  = { demonology  = true },
              destruction = { destruction = true } } },

  { class = "MAGE",    picks = "magePicks",        facts = "mageItemFacts",
    hasSpec = true,
    specs = { frost  = { frost  = true },
              fire   = { fire   = true },
              arcane = { arcane = true },
              battlemage_frost  = { battlemage_frost  = true },
              battlemage_fire   = { battlemage_fire   = true },
              battlemage_arcane = { battlemage_arcane = true } } },
  { class = "MAGE",    picks = "mageEarly1to9",    facts = "mageEarly1to9Facts",
    hasSpec = true,
    specs = { frost  = { frost  = true },
              fire   = { fire   = true },
              arcane = { arcane = true },
              battlemage_frost  = { battlemage_frost  = true },
              battlemage_fire   = { battlemage_fire   = true },
              battlemage_arcane = { battlemage_arcane = true } } },
}

for i = 1, #SOURCES do
    SOURCES[i].ix = i
end

-- Hunt rows live in a load-on-demand addon per class so a shaman does not
-- parse warrior, mage, and the rest at login. The first time you simulate
-- another class, that addon loads and its rows are expanded once.
local CLASS_ADDONS = {
    PALADIN = "GearQuestForever_PALADIN",
    WARRIOR = "GearQuestForever_WARRIOR",
    HUNTER  = "GearQuestForever_HUNTER",
    DRUID   = "GearQuestForever_DRUID",
    SHAMAN  = "GearQuestForever_SHAMAN",
    ROGUE   = "GearQuestForever_ROGUE",
    PRIEST  = "GearQuestForever_PRIEST",
    WARLOCK = "GearQuestForever_WARLOCK",
    MAGE    = "GearQuestForever_MAGE",
}

local function AddonIsLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    if IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

local function LoadClassAddon(name)
    if AddonIsLoaded(name) then
        return true
    end
    if C_AddOns and C_AddOns.LoadAddOn then
        return C_AddOns.LoadAddOn(name)
    end
    if LoadAddOn then
        return LoadAddOn(name)
    end
    return false, "LoadAddOn missing"
end

local CLASSTBL = {}

local function ExtractPipelineScore(r, src)
    if src.hasSpec then
        if type(r[5]) == "number" and type(r[8]) == "number" then
            return r[8]
        end
    elseif type(r[6]) == "number" then
        return r[6]
    end
    return nil
end

local function PipelineScoreKey(itemId, slot, minLevel, faction, spec)
    return string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
end

-- Item facts and the repeating suffix / route / hand fields live once per
-- item. A row keeps the band, the rank, and the score. Reads of entry.zone
-- and the rest still find those facts. A write lands on that row.
local SHARED_FACT_FIELDS = {
    "sourceType", "instructions", "setPiece", "lore", "zone", "npc",
    "questName", "profession", "reqRep", "reqSkills", "proc",
}
local OPTIONAL_ROW_FIELDS = {
    "suffix", "suffixChance", "suffixId", "suffixRange", "route", "hand",
    "origin", "reserve", "healOnly",
}
local SHARED_MT = setmetatable({}, { __mode = "k" })

local function SharedMetatable(classFile, classes, itemId, f, r, sourceIx)
    local byClass = SHARED_MT[f]
    if not byClass then
        byClass = {}
        SHARED_MT[f] = byClass
    end
    local variant = classFile
    local hasExtra = false
    for i = 1, #OPTIONAL_ROW_FIELDS do
        if r[OPTIONAL_ROW_FIELDS[i]] ~= nil then
            hasExtra = true
            break
        end
    end
    if hasExtra then
        local parts = { classFile }
        for i = 1, #OPTIONAL_ROW_FIELDS do
            local value = r[OPTIONAL_ROW_FIELDS[i]]
            parts[#parts + 1] = value == nil and "" or (type(value) .. ":" .. tostring(value))
        end
        variant = table.concat(parts, "\0")
    end
    local mt = byClass[variant]
    if mt then
        return mt
    end
    local base = byClass[classFile]
    if hasExtra and not base then
        base = SharedMetatable(classFile, classes, itemId, f, {}, sourceIx)
    end
    local shared = { itemId = itemId, classes = classes, generated = true }
    for i = 1, #SHARED_FACT_FIELDS do
        local key = SHARED_FACT_FIELDS[i]
        local value = f[key]
        if value ~= nil then
            shared[key] = value
        end
    end
    if hasExtra then
        for i = 1, #OPTIONAL_ROW_FIELDS do
            local key = OPTIONAL_ROW_FIELDS[i]
            local value = r[key]
            if value ~= nil then
                shared[key] = value
            end
        end
    end
    mt = { __index = shared, __gqShared = shared, __gqSource = sourceIx }
    mt.__gqBase = hasExtra and base or mt
    byClass[variant] = mt
    return mt
end

function GQ.Data:CopyEntry(entry)
    local copy = {}
    if not entry then
        return copy
    end
    for key, value in pairs(entry) do
        copy[key] = value
    end
    local mt = getmetatable(entry)
    if mt and mt.__gqShared then
        local shared = mt.__gqShared
        for i = 1, #OPTIONAL_ROW_FIELDS do
            local key = OPTIONAL_ROW_FIELDS[i]
            if rawget(copy, key) == nil and shared[key] ~= nil then
                copy[key] = shared[key]
            end
        end
        setmetatable(copy, mt.__gqBase or mt)
    end
    return copy
end

-- The staged class addon packs each pick table as <picks>Packed: one text
-- line per row, grouped by faction (scripts/stage_pack.py). A class file
-- copied straight from the repo still has the row array, and is read the same
-- way. Only the faction on screen is expanded. The packed text stays, so the
-- other faction can be read again for a faction switch or for Lookup.
local ROW_PATTERN = "^(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%d+)\n"
local NO_EXTRA = {}
local NO_FACTION = "_"
local RAW_FACTIONS = { "Alliance", "Horde", NO_FACTION }

local function SourceFactions(data, src)
    local packed = data[src.picks .. "Packed"]
    if packed then
        local list = {}
        for faction in pairs(packed.rows or {}) do
            list[#list + 1] = faction
        end
        table.sort(list)
        return list
    end
    return data[src.picks] and RAW_FACTIONS or {}
end

-- fn(itemId, slot, minLevel, maxLevel, rank, spec, faction, score, extra)
-- for each row of one faction, from pos. Stops after limit rows and returns
-- the next pos, or nil at the end.
local function ReadRows(data, src, faction, pos, limit, fn)
    local n = 0
    local packed = data[src.picks .. "Packed"]
    if packed then
        local text = packed.rows and packed.rows[faction]
        if not text then
            return nil
        end
        local slots, specs, extras = packed.slots, packed.specs, packed.extras
        local find, num = string.find, tonumber
        local rowFaction = faction ~= NO_FACTION and faction or nil
        pos = pos or 1
        while true do
            local _, e, item, slot, lo, hi, rank, spec, score, extra = find(text, ROW_PATTERN, pos)
            if not e then
                return nil
            end
            pos = e + 1
            fn(num(item), slots[num(slot)], num(lo), num(hi), num(rank), specs[num(spec)], rowFaction, num(score),
                extra == "0" and NO_EXTRA or extras[num(extra)])
            n = n + 1
            if limit and n >= limit then
                return pos
            end
        end
    end
    local rows = data[src.picks]
    if not rows then
        return nil
    end
    for i = pos or 1, #rows do
        local r = rows[i]
        local rank, spec, rowFaction
        if src.hasSpec then
            if type(r[5]) == "number" then
                rank = r[5]
                spec = r[6]
                rowFaction = r[7]
            else
                spec = r[5]
                rowFaction = r[6]
                rank = r.rank or 4
            end
        else
            rank = r[5]
            spec = nil
            rowFaction = src.factionInRow and r.faction or src.faction
        end
        if (rowFaction or NO_FACTION) == faction then
            fn(r[1], r[2], r[3], r[4], rank, spec, rowFaction, ExtractPipelineScore(r, src), r)
            n = n + 1
            if limit and n >= limit then
                return i + 1
            end
        end
    end
    return nil
end

-- Appends one hunt entry per row to out. Rows of an item the class has no
-- facts for, or that Forever does not have, are skipped.
local function RowAdder(src, data, out)
    local facts = data[src.facts]
    CLASSTBL[src.class] = CLASSTBL[src.class] or { [src.class] = true }
    local classes = CLASSTBL[src.class]
    local classFile = src.class
    local prefix = "gen:" .. src.class:lower() .. ":"
    local state = { added = 0 }
    local n = #out
    local function add(itemId, slot, minLevel, maxLevel, rank, spec, faction, score, extra)
        local f = facts[itemId]
        if f and not (data.IsForeverMissing and data:IsForeverMissing(itemId)) then
            local entry = {
                id           = prefix .. itemId .. ":" .. slot .. ":" .. minLevel
                                 .. ":" .. tostring(spec) .. ":" .. tostring(faction),
                slot         = slot,
                minLevel     = minLevel,
                maxLevel     = maxLevel,
                curatedRank  = rank,
                pipelineScore = score,
                specs        = spec and src.specs and src.specs[spec] or nil,
                factions     = faction and FACTION[faction] or nil,
            }
            setmetatable(entry, SharedMetatable(classFile, classes, itemId, f, extra, src.ix))
            n = n + 1
            out[n] = entry
            state.added = state.added + 1
        end
    end
    return add, state
end

local function Expand(src, data, out, faction)
    if not data[src.facts] or not (data[src.picks .. "Packed"] or data[src.picks]) then
        return 0
    end
    local add, state = RowAdder(src, data, out)
    ReadRows(data, src, faction, nil, nil, add)
    ReadRows(data, src, NO_FACTION, nil, nil, add)
    return state.added
end

function GQ.Data:IsClassLoaded(classFile)
    classFile = classFile and string.upper(classFile)
    return self._loadedClasses and self._loadedClasses[classFile] == true
end

function GQ.Data:IsClassExpanded(classFile)
    classFile = classFile and string.upper(classFile)
    return self._expandedClasses and self._expandedClasses[classFile] == true
end

function GQ.Data:EnsureClassLoaded(classFile)
    if not classFile then
        return false
    end
    classFile = string.upper(classFile)
    self._loadedClasses = self._loadedClasses or {}
    self._expandedClasses = self._expandedClasses or {}
    if self._expandedClasses[classFile] then
        return true
    end

    local addon = CLASS_ADDONS[classFile]
    if not addon then
        return false
    end
    if not AddonIsLoaded(addon) then
        local ok, reason = LoadClassAddon(addon)
        if not ok then
            self._classLoadFailed = self._classLoadFailed or {}
            if not self._classLoadFailed[classFile] then
                self._classLoadFailed[classFile] = true
                local label = classFile:sub(1, 1) .. classFile:sub(2):lower()
                GQ:Chat("|cffff0000GearQuest|r: " .. string.format(L["could not load %s hunt data (%s). Enable |cff00ff00GearQuest Forever: %s|r in the addon list, then /reload."], label, tostring(reason), label))
            end
            return false
        end
    end

    -- Class tips just landed in foreverAudit. Drop remembered show/hide answers.
    self._showEntryMemo = nil
    self.entries = self.entries or {}
    local start = #self.entries
    local n = 0
    local found = false
    local faction = self:HuntFactionFor(classFile)
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        if src.class == classFile then
            if (self[src.picks .. "Packed"] or self[src.picks]) and self[src.facts] then
                found = true
            end
            n = n + Expand(src, self, self.entries, faction)
        end
    end
    if not found then
        self._classLoadFailed = self._classLoadFailed or {}
        if not self._classLoadFailed[classFile] then
            self._classLoadFailed[classFile] = true
            GQ:Chat("|cffff0000GearQuest|r: " .. string.format(L["%s hunt data loaded with no picks."], classFile))

        end
        return false
    end

    self._entryGeneration = (self._entryGeneration or 0) + 1
    self._classEntrySpan = self._classEntrySpan or {}
    self._classEntrySpan[classFile] = { start + 1, #self.entries }
    self:BuildSuffixLookup(classFile)
    for i = start + 1, #self.entries do
        self:EnrichEntrySuffix(self.entries[i])
        self:EnrichBossChestEntry(self.entries[i])
    end
    self._loadedClasses[classFile] = true
    self._expandedClasses[classFile] = true
    self._expandedFaction = self._expandedFaction or {}
    self._expandedFaction[classFile] = faction
    self._generatedCount = (self._generatedCount or 0) + n
    if GQ.Custom and GQ.Custom.OnClassExpanded then
        GQ.Custom:OnClassExpanded(classFile)
    end
    return true
end

function GQ.Data:ReleaseExpandedClass(classFile)
    classFile = classFile and string.upper(classFile)
    if not classFile or not self._expandedClasses or not self._expandedClasses[classFile] then
        return false
    end
    local kept = {}
    local entries = self.entries or {}
    for i = 1, #entries do
        local entry = entries[i]
        if not (entry.generated and entry.classes and entry.classes[classFile]) then
            kept[#kept + 1] = entry
        end
    end
    self.entries = kept
    self._expandedClasses[classFile] = nil
    if self._expandedFaction then
        self._expandedFaction[classFile] = nil
    end
    if GQ.Custom and GQ.Custom.OnClassReleased then
        GQ.Custom:OnClassReleased(classFile)
    end
    -- Dropping rows shifts every later index. A lookup walk must start over.
    self._entryGeneration = (self._entryGeneration or 0) + 1
    self._classEntrySpan = nil
    return true
end

function GQ.Data:ReleaseIdleHuntClasses(keepGarbage)
    -- Your class stays. The class on screen stays. An earlier sim class drops
    -- its expanded rows. Its addon stays loaded until /reload.
    local playerClass
    if UnitClass then
        local _
        _, playerClass = UnitClass("player")
    end
    playerClass = playerClass and string.upper(playerClass)
    local current = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    current = current and string.upper(current)

    local removed = false
    if self._expandedClasses then
        for classFile in pairs(self._expandedClasses) do
            if classFile ~= playerClass and classFile ~= current then
                if self:ReleaseExpandedClass(classFile) then
                    removed = true
                end
            end
        end
    end
    if removed and not keepGarbage and collectgarbage then
        collectgarbage("collect")
    end
    return removed
end

-- The class on screen is expanded for the faction on screen. Your own class,
-- while another class is simulated, keeps your faction.
function GQ.Data:HuntFactionFor(classFile)
    classFile = classFile and string.upper(classFile)
    local current = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if current and classFile and string.upper(current) == classFile and GQ.GetEffectiveFaction then
        return GQ:GetEffectiveFaction()
    end
    return (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
end

-- After the Simulator changes class, faction, or turns off. Expands the class
-- on screen for the faction on screen, drops idle classes, and rebuilds the
-- index when the rows changed. Returns true then.
function GQ.Data:SyncEffectiveHuntData()
    if not self._huntDataReady then
        return false
    end
    local generation = self._entryGeneration
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    classFile = classFile and string.upper(classFile)
    if classFile then
        local want = self:HuntFactionFor(classFile)
        if self:IsClassExpanded(classFile) and self._expandedFaction and self._expandedFaction[classFile] ~= want then
            self:ReleaseExpandedClass(classFile)
        end
        self:EnsureClassLoaded(classFile)
    end
    self:ReleaseIdleHuntClasses(true)
    if generation == self._entryGeneration then
        return false
    end
    self:BuildIndex()
    if self.InvalidateClassCache then
        self:InvalidateClassCache()
    end
    if collectgarbage then
        collectgarbage("collect")
    end
    return true
end

function GQ.Data:EnsureActiveHuntClasses()
    local playerClass
    if UnitClass then
        local _
        _, playerClass = UnitClass("player")
    end
    if playerClass then
        self:EnsureClassLoaded(playerClass)
    end
    if GQ.Preview and GQ.Preview.IsEnabled and GQ.Preview:IsEnabled() then
        local sim = GQ.Preview:GetEffectiveClass()
        if sim and sim ~= playerClass then
            self:EnsureClassLoaded(sim)
        end
    end
    self:ReleaseIdleHuntClasses(true)
    self._huntDataReady = true
    if collectgarbage then
        collectgarbage("collect")
    end
end

-- Rows of a loaded class that are not expanded: the other faction. Lookup
-- reads them while its tab is open. Each call reads up to limit rows into
-- out and returns true when every row has been read.
function GQ.Data:OtherFactionReader(classFile)
    classFile = classFile and string.upper(classFile)
    local expanded = classFile and self._expandedFaction and self._expandedFaction[classFile]
    if not expanded then
        return nil
    end
    local jobs = {}
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        if src.class == classFile and self[src.facts] then
            local factions = SourceFactions(self, src)
            for k = 1, #factions do
                if factions[k] ~= expanded and factions[k] ~= NO_FACTION then
                    jobs[#jobs + 1] = { src = src, faction = factions[k] }
                end
            end
        end
    end
    local data = self
    local index, pos = 1, nil
    local adders = {}
    return function(limit, out)
        local job = jobs[index]
        if not job then
            return true
        end
        local add = adders[index]
        if not add then
            add = RowAdder(job.src, data, out)
            adders[index] = add
        end
        local first = #out + 1
        pos = ReadRows(data, job.src, job.faction, pos, limit, add)
        for i = first, #out do
            data:EnrichEntrySuffix(out[i])
            data:EnrichBossChestEntry(out[i])
        end
        if not pos then
            index = index + 1
        end
        return jobs[index] == nil
    end
end

-- Other-faction entries Lookup is showing. A hunt tracked from Lookup is
-- found by its id while they are held.
function GQ.Data:HoldDetachedEntries(list)
    local byId = {}
    for i = 1, #(list or {}) do
        local entry = list[i]
        if entry.id then
            byId[entry.id] = entry
        end
    end
    self._detachedById = byId
end

function GQ.Data:ReleaseDetachedEntries()
    self._detachedById = nil
end

-- Specs that rank itemId in rows that are not expanded, per loaded class:
-- { [classFile] = { [spec] = true } }, or nil. The tooltip's "Not ranked for
-- your faction." needs to know those rows exist.
function GQ.Data:UnexpandedRowSpecs(itemId)
    if not itemId or not self._expandedFaction then
        return nil
    end
    local found
    local function mark(classFile, src, spec)
        found = found or {}
        local specs = found[classFile]
        if not specs then
            specs = {}
            found[classFile] = specs
        end
        if spec and src.specs and src.specs[spec] then
            specs[spec] = true
        else
            specs._any = true
        end
    end
    for classFile, expanded in pairs(self._expandedFaction) do
        for i = 1, #SOURCES do
            local src = SOURCES[i]
            local facts = self[src.facts]
            if src.class == classFile and facts and facts[itemId] and not self:IsForeverMissing(itemId) then
                local packed = self[src.picks .. "Packed"]
                if packed then
                    for faction, mask in pairs(packed.specMask or {}) do
                        if faction ~= expanded and faction ~= NO_FACTION then
                            local _, _, digits = string.find(mask, "\n" .. itemId .. " (%d+)\n", 1)
                            if digits then
                                for k = 1, #digits do
                                    mark(classFile, src, packed.specs[tonumber(digits:sub(k, k))])
                                end
                            end
                        end
                    end
                elseif self[src.picks] then
                    local factions = RAW_FACTIONS
                    for k = 1, #factions do
                        if factions[k] ~= expanded and factions[k] ~= NO_FACTION then
                            ReadRows(self, src, factions[k], nil, nil, function(rowItem, _, _, _, _, spec)
                                if rowItem == itemId then
                                    mark(classFile, src, spec)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
    return found
end

-- Entries for itemId's rows that are not expanded, built fresh and not kept.
-- Dismissing a completed hunt dismisses those ids too.
function GQ.Data:UnexpandedItemEntries(itemId)
    local out = {}
    if not itemId or not self._expandedFaction then
        return out
    end
    local head = tostring(itemId) .. " "
    local needle = "\n" .. head
    for classFile, expanded in pairs(self._expandedFaction) do
        for i = 1, #SOURCES do
            local src = SOURCES[i]
            local facts = self[src.facts]
            if src.class == classFile and facts and facts[itemId] then
                local add = RowAdder(src, self, out)
                local packed = self[src.picks .. "Packed"]
                local factions = SourceFactions(self, src)
                for k = 1, #factions do
                    local faction = factions[k]
                    if faction ~= expanded and faction ~= NO_FACTION then
                        local text = packed and packed.rows and packed.rows[faction]
                        if text then
                            local pos = text:sub(1, #head) == head and 1 or nil
                            local from = 1
                            while true do
                                if pos then
                                    ReadRows(self, src, faction, pos, 1, add)
                                end
                                local s = string.find(text, needle, from, true)
                                if not s then
                                    break
                                end
                                pos = s + 1
                                from = s + 1
                            end
                        elseif not packed then
                            ReadRows(self, src, faction, nil, nil, function(rowItem, ...)
                                if rowItem == itemId then
                                    add(rowItem, ...)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
    for i = 1, #out do
        self:EnrichEntrySuffix(out[i])
    end
    return out
end

-- A saved hunt id of a loaded class whose faction is not expanded. That row
-- still exists, so the id is not stale.
function GQ.Data:IsUnexpandedHuntId(id)
    if type(id) ~= "string" or not self._expandedFaction then
        return false
    end
    local classLower, rest = id:match("^gen:(%a+):(.*)$")
    if not classLower then
        return false
    end
    local expanded = self._expandedFaction[string.upper(classLower)]
    if not expanded then
        return false
    end
    local faction = select(5, rest:match("^([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)"))
    return faction ~= nil and faction ~= "nil" and faction ~= expanded
end

-- Spec -> the order it first appears in the source's pick table.
function GQ.Data:SpecFileOrder(src)
    self._specFileOrder = self._specFileOrder or {}
    local order = self._specFileOrder[src.picks]
    if order then
        return order
    end
    order = {}
    local packed = self[src.picks .. "Packed"]
    if packed then
        for i = 1, #(packed.specs or {}) do
            order[packed.specs[i]] = i
        end
    else
        local n = 0
        local rows = self[src.picks] or {}
        for i = 1, #rows do
            local r = rows[i]
            local spec = type(r[5]) == "number" and r[6] or r[5]
            if spec ~= nil and not order[spec] then
                n = n + 1
                order[spec] = n
            end
        end
    end
    self._specFileOrder[src.picks] = order
    return order
end

local FACTION_ORDER = { Alliance = 1, Horde = 2 }

-- Where an entry's row sits in its class file: source, spec block, faction.
-- The generated files are sorted by spec, then faction, so the expanded rows
-- and the other faction's rows merge back into file order by this key.
function GQ.Data:FileBlockKey(entry)
    local mt = entry and getmetatable(entry)
    local ix = mt and mt.__gqSource
    local src = ix and SOURCES[ix]
    if not src then
        return 0
    end
    local spec = entry.specs and next(entry.specs)
    local faction = entry.factions and next(entry.factions)
    local specIx = spec and self:SpecFileOrder(src)[spec] or 0
    return ix * 100 + specIx * 3 + (faction and FACTION_ORDER[faction] or 0)
end

-- Custom specs score from these stat rows. They are their own load-on-demand
-- addon and load the first time a custom spec is scored.
local ITEM_STATS_ADDON = "GearQuestForever_ItemStats"

function GQ.Data:EnsureItemStats()
    if self.itemStats then
        return true
    end
    if self._itemStatsFailed then
        return false
    end
    local ok, reason = true, nil
    if not AddonIsLoaded(ITEM_STATS_ADDON) then
        ok, reason = LoadClassAddon(ITEM_STATS_ADDON)
    end
    if ok and self.itemStats then
        return true
    end
    self._itemStatsFailed = true
    GQ:Chat("|cffff0000GearQuest|r: " .. string.format(L["could not load the item stats for custom specs (%s). Enable |cff00ff00GearQuest Forever: Item Stats|r in the addon list, then /reload."], tostring(reason or "?")))
    return false
end

function GQ.Data:LoadGenerated()
    self:EnsureActiveHuntClasses()
    return self._generatedCount or 0
end

function GQ.Data:BuildSuffixLookup(classFile)
    if self._suffixLookup and not classFile then
        return
    end

    -- Per item+suffix+level only. Never cross-item: "of the Tiger" on item A
    -- is id 690 while item B at the same level may be id 753.
    if not self._suffixLookup then
        self._suffixLookup = { byItemLevel = {}, byItemSuffix = {}, byItemLevelRange = {}, byItemSuffixRange = {} }
    end

    local function ingest(itemId, suffix, minLevel, suffixId, suffixRange)
        if not suffix or suffix == "" or not suffixId or suffixId == 0 then
            return
        end

        minLevel = minLevel or 0
        local exactKey = itemId .. "\0" .. suffix .. "\0" .. minLevel
        self._suffixLookup.byItemLevel[exactKey] = {
            suffixId = suffixId,
            suffixRange = suffixRange,
        }

        local itemKey = itemId .. "\0" .. suffix
        local bands = self._suffixLookup.byItemSuffix[itemKey]
        if not bands then
            bands = {}
            self._suffixLookup.byItemSuffix[itemKey] = bands
        end
        bands[minLevel] = {
            suffixId = suffixId,
            suffixRange = suffixRange,
        }
    end

    local function ingestRange(itemId, suffix, minLevel, suffixRange)
        if not suffix or suffix == "" or not suffixRange or suffixRange == "" then
            return
        end

        minLevel = minLevel or 0
        local exactKey = itemId .. "\0" .. suffix .. "\0" .. minLevel
        self._suffixLookup.byItemLevelRange[exactKey] = suffixRange

        local itemKey = itemId .. "\0" .. suffix
        local bands = self._suffixLookup.byItemSuffixRange[itemKey]
        if not bands then
            bands = {}
            self._suffixLookup.byItemSuffixRange[itemKey] = bands
        end
        bands[minLevel] = suffixRange
    end

    local function ingestRow(row)
        if not row then
            return
        end
        ingest(row[1], row.suffix, row[3], row.suffixId, row.suffixRange)
        ingestRange(row[1], row.suffix, row[3], row.suffixRange)
    end

    -- Both factions, in file order. The packed table keeps every row that
    -- names a suffix, so the lookup is the same whichever faction is expanded.
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        if not classFile or src.class == classFile then
            local packed = self[src.picks .. "Packed"]
            local rows = self[src.picks]
            if packed then
                local extras = packed.extras or {}
                for item, lo, extra in string.gmatch(packed.suffixRows or "", "(%d+) (%d+) (%d+)\n") do
                    local x = extras[tonumber(extra)]
                    if x then
                        local itemId, minLevel = tonumber(item), tonumber(lo)
                        ingest(itemId, x.suffix, minLevel, x.suffixId, x.suffixRange)
                        ingestRange(itemId, x.suffix, minLevel, x.suffixRange)
                    end
                end
            elseif rows then
                for j = 1, #rows do
                    ingestRow(rows[j])
                end
            end
        end
    end

    for _, entry in ipairs(self.entries or {}) do
        if not classFile or (entry.classes and entry.classes[classFile]) then
            ingest(entry.itemId, entry.suffix, entry.minLevel, entry.suffixId, entry.suffixRange)
            ingestRange(entry.itemId, entry.suffix, entry.minLevel, entry.suffixRange)
        end
    end
end

local function LookupSuffixBand(map, itemId, suffix, minLevel)
    if not map or not itemId or not suffix then
        return nil
    end

    local exactKey = itemId .. "\0" .. suffix .. "\0" .. (minLevel or 0)
    local hit = map[exactKey]
    if hit then
        return hit
    end

    local bands = map[itemId .. "\0" .. suffix]
    if not bands then
        return nil
    end

    local bestLevel, bestHit = nil, nil
    for bandLevel, bandHit in pairs(bands) do
        if bandLevel <= (minLevel or 0) and (not bestLevel or bandLevel > bestLevel) then
            bestLevel = bandLevel
            bestHit = bandHit
        end
    end

    return bestHit
end

function GQ.Data:EnrichEntrySuffix(entry)
    if not entry or not entry.suffix or entry.suffix == "" then
        return entry
    end

    if entry.suffixId and entry.suffixId ~= 0 then
        if not entry.suffixRange or entry.suffixRange == "" then
            self:BuildSuffixLookup()
            local range = LookupSuffixBand(
                self._suffixLookup.byItemLevelRange,
                entry.itemId,
                entry.suffix,
                entry.minLevel
            )
            if not range then
                range = LookupSuffixBand(
                    self._suffixLookup.byItemSuffixRange,
                    entry.itemId,
                    entry.suffix,
                    entry.minLevel
                )
            end
            if range then
                entry.suffixRange = range
            end
        end
        return entry
    end

    self:BuildSuffixLookup()
    local hit = LookupSuffixBand(
        self._suffixLookup.byItemLevel,
        entry.itemId,
        entry.suffix,
        entry.minLevel
    )

    if not hit then
        hit = LookupSuffixBand(
            self._suffixLookup.byItemSuffix,
            entry.itemId,
            entry.suffix,
            entry.minLevel
        )
    end

    if hit then
        entry.suffixId = hit.suffixId
        if hit.suffixRange and (not entry.suffixRange or entry.suffixRange == "") then
            entry.suffixRange = hit.suffixRange
        end
    end

    if not entry.suffixRange or entry.suffixRange == "" then
        local range = LookupSuffixBand(
            self._suffixLookup.byItemLevelRange,
            entry.itemId,
            entry.suffix,
            entry.minLevel
        )
        if not range then
            range = LookupSuffixBand(
                self._suffixLookup.byItemSuffixRange,
                entry.itemId,
                entry.suffix,
                entry.minLevel
            )
        end
        if range then
            entry.suffixRange = range
        end
    end

    return entry
end
