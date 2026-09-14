local _, GQ = ...

-- Expands the generated BiS tables into GQ.Data.entries, the array that
-- Indicator.lua, Log.lua and Tracker.lua already iterate. Nothing in those files
-- needs to change: generated rows arrive in exactly the shape curated ones use.
--
-- Per class, the data does not overlap the hand-curated entries in Data.lua:
--   1-9            curated in Data.lua for the classes ALLIANCE_MAIL / MAIL_MELEE
--                  covers (warrior, paladin), so those ship a Horde-only file;
--                  a class in neither table (hunter) ships BOTH factions, and its
--                  rows carry their own faction field.
--   10-69          <class>Picks            (expanded here)
--   70             curated in Data.lua (AtlasLoot Phase 3)

local FACTION = { Alliance = { Alliance = true }, Horde = { Horde = true } }

-- Paladin was first through and its generated tables are unprefixed; every class
-- after it is prefixed. Nothing collides, so the older file is left as it is
-- rather than regenerated for cosmetics.
local SOURCES = {
  { class = "PALADIN", picks = "paladinPicks",     facts = "itemFacts",
    hasSpec = true,
    specs = { retribution = { retribution = true },
              protection  = { protection  = true },
              holy        = { holy        = true } } },
  { class = "PALADIN", picks = "paladinHorde1to9", facts = "paladinHorde1to9Facts",
    hasSpec = false, faction = "Horde" },

  { class = "WARRIOR", picks = "warriorPicks",     facts = "warriorItemFacts",
    hasSpec = true,
    specs = { arms       = { arms       = true },
              fury       = { fury       = true },
              protection = { protection = true } } },
  { class = "WARRIOR", picks = "warriorHorde1to9", facts = "warriorHorde1to9Facts",
    hasSpec = false, faction = "Horde" },

  { class = "HUNTER",  picks = "hunterPicks",      facts = "hunterItemFacts",
    hasSpec = true,
    specs = { beast_mastery = { beast_mastery = true },
              marksmanship  = { marksmanship  = true },
              survival      = { survival      = true } } },
  { class = "HUNTER",  picks = "hunterEarly1to9",  facts = "hunterEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "DRUID",   picks = "druidPicks",       facts = "druidItemFacts",
    hasSpec = true,
    specs = { bear        = { bear        = true },
              feral       = { feral       = true },
              balance     = { balance     = true },
              restoration = { restoration = true } } },
  { class = "DRUID",   picks = "druidEarly1to9",   facts = "druidEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "SHAMAN",  picks = "shamanPicks",      facts = "shamanItemFacts",
    hasSpec = true,
    specs = { elemental   = { elemental   = true },
              enhancement = { enhancement = true },
              restoration = { restoration = true } } },
  { class = "SHAMAN",  picks = "shamanEarly1to9",  facts = "shamanEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "ROGUE",   picks = "roguePicks",       facts = "rogueItemFacts",
    hasSpec = true,
    specs = { combat        = { combat        = true },
              assassination = { assassination = true },
              subtlety      = { subtlety      = true } } },
  { class = "ROGUE",   picks = "rogueEarly1to9",   facts = "rogueEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "PRIEST",  picks = "priestPicks",      facts = "priestItemFacts",
    hasSpec = true,
    specs = { holy       = { holy       = true },
              discipline = { discipline = true },
              shadow     = { shadow     = true } } },
  { class = "PRIEST",  picks = "priestEarly1to9",  facts = "priestEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "WARLOCK", picks = "warlockPicks",     facts = "warlockItemFacts",
    hasSpec = true,
    specs = { affliction  = { affliction  = true },
              demonology  = { demonology  = true },
              destruction = { destruction = true } } },
  { class = "WARLOCK", picks = "warlockEarly1to9", facts = "warlockEarly1to9Facts",
    hasSpec = false, factionInRow = true },

  { class = "MAGE",    picks = "magePicks",        facts = "mageItemFacts",
    hasSpec = true,
    specs = { frost  = { frost  = true },
              fire   = { fire   = true },
              arcane = { arcane = true } } },
  { class = "MAGE",    picks = "mageEarly1to9",    facts = "mageEarly1to9Facts",
    hasSpec = false, factionInRow = true },
}

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

local function Expand(src, data, out)
    local rows, facts = data[src.picks], data[src.facts]
    if not rows or not facts then return 0 end

    CLASSTBL[src.class] = CLASSTBL[src.class] or { [src.class] = true }
    local classes = CLASSTBL[src.class]
    local prefix  = "gen:" .. src.class:lower() .. ":"
    local added   = 0

    for i = 1, #rows do
        local r = rows[i]
        local itemId = r[1]
        local f = facts[itemId]
        if f then
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
            out[#out + 1] = {
                id           = prefix .. itemId .. ":" .. r[2] .. ":" .. r[3]
                                 .. ":" .. tostring(spec) .. ":" .. tostring(faction),
                itemId       = itemId,
                slot         = r[2],
                minLevel     = r[3],
                maxLevel     = r[4],
                curatedRank  = rank,
                pipelineScore = pipelineScore,
                classes      = classes,
                specs        = spec and src.specs and src.specs[spec] or nil,
                factions     = faction and FACTION[faction] or nil,
                sourceType   = f.sourceType,
                instructions = f.instructions,
                lore         = f.lore,
                zone         = f.zone,
                npc          = f.npc,
                questName    = f.questName,
                profession   = f.profession,
                suffix       = r.suffix,
                suffixChance = r.suffixChance,
                suffixId     = r.suffixId,
                suffixRange  = r.suffixRange,
                route        = r.route,
                origin       = r.origin,
                proc         = f.proc,
                generated    = true,
            }
            if pipelineScore and GQ.Data.RegisterPipelineScore then
                GQ.Data:RegisterPipelineScore(itemId, r[2], r[3], faction, spec, pipelineScore)
            end
            added = added + 1
        end
    end
    return added
end

function GQ.Data:LoadGenerated()
    if self._generatedLoaded then return 0 end
    self._generatedLoaded = true
    self.entries = self.entries or {}
    self._pipelineScoreLookup = {}
    local n = 0
    for i = 1, #SOURCES do
        n = n + Expand(SOURCES[i], self, self.entries)
    end
    self._generatedCount = n
    self:BuildSuffixLookup()
    for i = 1, #self.entries do
        self:EnrichEntrySuffix(self.entries[i])
        self:EnrichBossChestEntry(self.entries[i])
        self:EnrichProfessionEntry(self.entries[i])
    end
    return n
end

function GQ.Data:BuildSuffixLookup()
    if self._suffixLookup then
        return
    end

    -- Per item+suffix+level only. Never cross-item: "of the Tiger" on item A
    -- is id 690 while item B at the same level may be id 753.
    self._suffixLookup = { byItemLevel = {}, byItemSuffix = {}, byItemLevelRange = {}, byItemSuffixRange = {} }

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
        local rows = self[SOURCES[i].picks]
        if rows then
            for j = 1, #rows do
                ingestRow(rows[j])
            end
        end
    end

    for _, entry in ipairs(self.entries or {}) do
        ingest(entry.itemId, entry.suffix, entry.minLevel, entry.suffixId, entry.suffixRange)
        ingestRange(entry.itemId, entry.suffix, entry.minLevel, entry.suffixRange)
    end

    local notableTables = {
        "paladinNotable", "warriorNotable", "hunterNotable",
        "druidNotable", "shamanNotable", "rogueNotable", "priestNotable",
        "warlockNotable", "mageNotable",
    }
    for t = 1, #notableTables do
        local rows = self[notableTables[t]]
        if rows then
            for i = 1, #rows do
                ingestRow(rows[i])
            end
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

GQ.Data:LoadGenerated()
