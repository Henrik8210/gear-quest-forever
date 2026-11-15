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

local function PlayerClassFile()
    if UnitClass then
        local _, classFile = UnitClass("player")
        return classFile and string.upper(classFile) or nil
    end
    return nil
end

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

local function SharedMetatable(classFile, classes, itemId, f, r)
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
        base = SharedMetatable(classFile, classes, itemId, f, {})
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
    mt = { __index = shared, __gqShared = shared }
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

local function Expand(src, data, out)
    local rows, facts = data[src.picks], data[src.facts]
    if not rows or not facts then return 0 end

    CLASSTBL[src.class] = CLASSTBL[src.class] or { [src.class] = true }
    local classes = CLASSTBL[src.class]
    local classFile = src.class
    local prefix  = "gen:" .. src.class:lower() .. ":"
    local added   = 0
    local n = #out

    for i = 1, #rows do
        local r = rows[i]
        local itemId = r[1]
        local f = facts[itemId]
        if f and not (data.IsForeverMissing and data:IsForeverMissing(itemId)) then
            local rank, spec, faction
            if src.hasSpec then
                if type(r[5]) == "number" then
                    rank = r[5]
                    spec = r[6]
                    faction = r[7]
                else
                    spec = r[5]
                    faction = r[6]
                    rank = r.rank or 4
                end
            else
                rank = r[5]
                spec = nil
                faction = src.factionInRow and r.faction or src.faction
            end
            local pipelineScore = ExtractPipelineScore(r, src)
            local entry = {
                id           = prefix .. itemId .. ":" .. r[2] .. ":" .. r[3]
                                 .. ":" .. tostring(spec) .. ":" .. tostring(faction),
                slot         = r[2],
                minLevel     = r[3],
                maxLevel     = r[4],
                curatedRank  = rank,
                pipelineScore = pipelineScore,
                specs        = spec and src.specs and src.specs[spec] or nil,
                factions     = faction and FACTION[faction] or nil,
            }
            setmetatable(entry, SharedMetatable(classFile, classes, itemId, f, r))
            n = n + 1
            out[n] = entry
            added = added + 1
        end
    end
    return added
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
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        if src.class == classFile then
            if self[src.picks] and self[src.facts] then
                found = true
            end
            n = n + Expand(src, self, self.entries)
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
    -- The suffix lookup is already built. Your own class is never released,
    -- so its pick arrays are not read again. A simulated class keeps them,
    -- because leaving that class drops only the expanded rows and WoW will
    -- not run the file again.
    if classFile == PlayerClassFile() then
        self._picksDropped = self._picksDropped or {}
        for i = 1, #SOURCES do
            local src = SOURCES[i]
            if src.class == classFile then
                self[src.picks] = nil
            end
        end
        self._picksDropped[classFile] = true
    end
    self._loadedClasses[classFile] = true
    self._expandedClasses[classFile] = true
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
    -- Its pick arrays are gone, so it could not be expanded again.
    if self._picksDropped and self._picksDropped[classFile] then
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
    if GQ.Custom and GQ.Custom.OnClassReleased then
        GQ.Custom:OnClassReleased(classFile)
    end
    -- Dropping rows shifts every later index. A lookup walk must start over.
    self._entryGeneration = (self._entryGeneration or 0) + 1
    self._classEntrySpan = nil
    return true
end

function GQ.Data:ReleaseIdleHuntClasses()
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
    if removed and collectgarbage then
        collectgarbage("collect")
    end
    return removed
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
    self:ReleaseIdleHuntClasses()
    if collectgarbage then
        collectgarbage("collect")
    end
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

    for i = 1, #SOURCES do
        local src = SOURCES[i]
        if not classFile or src.class == classFile then
            local rows = self[src.picks]
            if rows then
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
