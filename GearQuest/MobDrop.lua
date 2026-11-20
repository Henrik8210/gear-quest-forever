local _, GQ = ...

local L = GQ.L
GQ.Data = GQ.Data or {}

local MOB_KINDS = {
    b = true,
    r = true,
    w = true,
    t = true,
}

local KIND_SOURCE = {
    b = "boss_drop",
    t = "raid_trash",
    r = "rare_npc",
    w = "world_drop",
    v = "vendor",
    p = "profession",
    q = "quest_reward",
}

local UnitGearScore
local KeepUpgrades

-- World-drop bands can list hundreds of ids. Upgrade filtering only needs a
-- small shortlist scored from the hunt tables.
-- Ten generic world drops per slot, and about sixteen slots. The per-level
-- list keeps those, so a high score in one slot cannot crowd out another.
local WORLD_DROP_CANDIDATE_CAP = 160
local WORLD_SLOT_CAP = 10

local function UnitGearSettings()
    return GearQuestForeverDB and GearQuestForeverDB.settings
end

local function UnitGearAlwaysShow()
    local settings = UnitGearSettings()
    return settings and settings.unitGearAlwaysShow == true
end

-- The key event can run before IsShiftKeyDown changes. Trust the event for
-- that press, then the tooltip redraw on the next frame reads the real state.
local shiftHeld = false
local shiftDownAt = 0
local shiftUpAt = 0
local RefreshShiftTip

local function NoteShiftKey(pressed)
    local now = (GetTime and GetTime()) or 0
    if pressed then
        shiftHeld = true
        shiftDownAt = now
    else
        shiftHeld = false
        shiftUpAt = now
    end
end

local function UnitGearShiftDown()
    if IsShiftKeyDown then
        local ok, down = pcall(IsShiftKeyDown)
        if ok and down == true then
            shiftHeld = true
            return true
        end
        if ok and down == false then
            local now = (GetTime and GetTime()) or 0
            if shiftHeld and shiftDownAt >= shiftUpAt and (now - shiftDownAt) < 0.25 then
                return true
            end
            shiftHeld = false
            return false
        end
    end
    return shiftHeld
end

local function UnitGearShowDropChance()
    local settings = UnitGearSettings()
    return not settings or settings.unitGearShowDropChance ~= false
end

local function UnitGearMinDropPercent()
    local settings = UnitGearSettings()
    return math.max(0, tonumber(settings and settings.unitGearMinDropPercent) or 0)
end

local function UnitGearSourceId(pick)
    if not pick then
        return nil
    end
    local kind = pick.kind
    if kind and KIND_SOURCE[kind] then
        return KIND_SOURCE[kind]
    end
    local entry = pick.entry
    if entry and GQ.NormalizeSourceType then
        return GQ:NormalizeSourceType(entry.sourceType or "")
    end
    if entry and entry.sourceType and entry.sourceType ~= "" then
        return entry.sourceType
    end
    return nil
end

local function UnitGearSourceHidden(pick)
    local settings = UnitGearSettings()
    local hidden = settings and settings.unitGearHiddenSources
    if not hidden then
        return false
    end
    local src = UnitGearSourceId(pick)
    return src and hidden[src] == true
end

local function UnitGearPassesMinDrop(pick)
    local minPct = UnitGearMinDropPercent()
    if minPct <= 0 then
        return true
    end
    local chance = tonumber(pick and pick.chance) or 0
    if chance <= 0 then
        return true
    end
    return chance >= minPct
end

local function FilterUnitGearPicks(picks, minOverride)
    if not picks or #picks == 0 then
        return nil, nil
    end
    local minPct = minOverride
    if minPct == nil then
        minPct = UnitGearMinDropPercent()
    end
    local filtered = {}
    local blockedByMin = 0
    local hadUpgradeSource = false
    for i = 1, #picks do
        local pick = picks[i]
        if not UnitGearSourceHidden(pick) then
            hadUpgradeSource = true
            if UnitGearPassesMinDrop(pick) then
                filtered[#filtered + 1] = pick
            elseif minPct > 0 and (tonumber(pick.chance) or 0) > 0 then
                blockedByMin = blockedByMin + 1
            end
        end
    end
    local meta
    if #filtered == 0 and blockedByMin > 0 and hadUpgradeSource then
        meta = { minDropEmpty = true }
    end
    return #filtered > 0 and filtered or nil, meta
end

local function FormatDropPercent(chance)
    chance = tonumber(chance)
    if not chance or chance <= 0 then
        return nil
    end
    if math.abs(chance - math.floor(chance + 0.0001)) < 0.001 then
        return string.format("%.0f", chance)
    end
    return string.format("%.2f", chance)
end

local function MobIndexedDropChance(data, mobKey, itemId)
    if not mobKey or not itemId then
        return 0
    end
    local rows = data.mobDrops and data.mobDrops[mobKey]
    if type(rows) ~= "table" then
        return 0
    end
    for i = 1, #rows do
        local row = rows[i]
        if row and row[1] == itemId then
            return tonumber(row[2]) or 0
        end
    end
    return 0
end

local openWorldChanceById

local function OpenWorldDropChance(data, itemId)
    if not itemId or not UnitGearShowDropChance() then
        return 0
    end
    if type(data.worldDropOpenChance) == "table" then
        return tonumber(data.worldDropOpenChance[itemId]) or 0
    end
    if openWorldChanceById == nil then
        local packed = data.worldDropOpenChancePacked
        if type(packed) ~= "string" or packed == "" then
            openWorldChanceById = false
        else
            openWorldChanceById = {}
            for part in string.gmatch(packed, "[^,]+") do
                local id, cent = string.match(part, "^(%d+):(%d+)$")
                id = tonumber(id)
                cent = tonumber(cent)
                if id and cent then
                    openWorldChanceById[id] = cent * 0.01
                end
            end
            data.worldDropOpenChancePacked = nil
        end
    end
    if openWorldChanceById == false then
        return 0
    end
    return tonumber(openWorldChanceById[itemId]) or 0
end

local function MobKey(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    name = string.lower(name)
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    name = string.gsub(name, "%s+", " ")
    if name == "" then
        return nil
    end
    return name
end

local function PlayerFactionCode()
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
    if faction == "Alliance" then
        return 1
    end
    if faction == "Horde" then
        return 2
    end
    return 0
end

local function FactionAllows(code)
    code = tonumber(code) or 0
    if code == 0 then
        return true
    end
    local player = PlayerFactionCode()
    if player == 0 then
        return true
    end
    return code == player
end

local function UnitNpcFactionCode(token)
    if not token or not UnitFactionGroup then
        return nil
    end
    local ok, group = pcall(UnitFactionGroup, token)
    if not ok or not group then
        return nil
    end
    group = GQ.PublicText and GQ.PublicText(group) or group
    if group == "Alliance" then
        return 1
    end
    if group == "Horde" then
        return 2
    end
    return 0
end

-- An Alliance vendor or quest giver offers nothing to a Horde character, and
-- the other way around. They are not a world-drop table either.
local function OppositeFactionNpc(token)
    if not token then
        return false
    end
    local npcFac = UnitNpcFactionCode(token)
    if not npcFac or npcFac == 0 then
        return false
    end
    local player = PlayerFactionCode()
    if player == 0 then
        return false
    end
    return npcFac ~= player
end

local function BandContainsLevel(entry, level)
    return level >= (entry.minLevel or 1) and level <= (entry.maxLevel or level)
end

-- The row for this level. A band the character has left is only used when
-- nothing in the current band matches, and then the most recent band wins.
-- An older curated rank must not replace the current row.
local function BestHuntEntry(itemId)
    local rows = GQ.Data:GetEntriesByItemId(itemId)
    local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    local exact, grace
    for i = 1, #rows do
        local entry = rows[i]
        if entry and GQ.Data:EntryMatchesPlayer(entry) then
            if BandContainsLevel(entry, level) then
                if not exact or (entry.pipelineScore or 0) > (exact.pipelineScore or 0) then
                    exact = entry
                end
            elseif not grace
                or (entry.maxLevel or 0) > (grace.maxLevel or 0)
                or ((entry.maxLevel or 0) == (grace.maxLevel or 0)
                    and (entry.pipelineScore or 0) > (grace.pipelineScore or 0)) then
                grace = entry
            end
        end
    end
    return exact or grace
end

local function TooltipSlot(entry)
    local slotName = entry and entry.slot
    if GQ.Data.NormalizeSlotName then
        slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
    end
    local handKind
    if GQ.Log and GQ.Log.RankListContext then
        slotName, handKind = GQ.Log:RankListContext(entry)
    end
    return slotName, handKind
end

-- The row on this level's hunt list, with that list's rank. A piece from
-- an older band is not on the list, so it gets no line.
local function CurrentListRank(entry, list)
    if not entry or not list or not GQ.Log or not GQ.Log.VisibleSlotRank then
        return nil
    end
    local suffix = entry.suffix or ""
    local scored
    for i = 1, #list do
        local row = list[i]
        if row.itemId == entry.itemId and (row.suffix or "") == suffix then
            scored = row
            break
        end
    end
    if not scored then
        return nil
    end
    local place = GQ.Log:VisibleSlotRank(scored)
    if not place then
        return nil
    end
    return scored, place
end

-- The piece already in that slot. A ring or trinket counts in either slot.
-- A different item in the slot still leaves this one on the tooltip.
local function WearingEntry(entry, slotName)
    if not entry or not entry.itemId or not GQ.Data.GetInventorySlots or not GQ.Data.EquippedItemId then
        return false
    end
    local slots = GQ.Data:GetInventorySlots(slotName)
    for i = 1, #slots do
        local inv = slots[i]
        if GQ.Data:EquippedItemId(inv) == entry.itemId then
            if not entry.suffix or entry.suffix == "" then
                return true
            end
            local link = GetInventoryItemLink and GetInventoryItemLink("player", inv)
            if link and GQ.Data.EntrySuffixMatchesLink and GQ.Data:EntrySuffixMatchesLink(entry, link) then
                return true
            end
        end
    end
    return false
end

-- A hover is answered from two tables. The pieces a unit answers for are
-- kept per level, spec, class, and faction. The lines are kept per worn gear
-- on top of that. A trainer walks every crafted hunt of the profession, and
-- doing that again on each hover froze the game for a moment.
-- The unit tooltip refreshes many times while the mouse rests on a mob.
-- Reading 19 item links on every refresh was part of the hover stutter, so
-- the worn signature is rebuilt only after an equipment change (or every few
-- seconds, in case that event was missed).
local WORN_RESCAN_SECONDS = 5

local function WornSignature(data)
    local now = GetTime and GetTime() or 0
    if data._unitGearWornSig and not data._unitGearWornDirty
        and now - (data._unitGearWornAt or 0) < WORN_RESCAN_SECONDS then
        return data._unitGearWornSig
    end
    local worn = {}
    for inv = 1, 19 do
        worn[inv] = data:EquippedItemId(inv) or 0
    end
    data._unitGearWornSig = table.concat(worn, ",")
    data._unitGearWornDirty = false
    data._unitGearWornAt = now
    return data._unitGearWornSig
end

local function UnitGearCache(data)
    local band = data:GetActiveBandCacheKey()
    local cache = data._unitGearCache
    if not cache or cache.band ~= band then
        cache = { band = band, picks = {}, lines = {}, retry = {} }
        data._unitGearCache = cache
    end
    local gear = WornSignature(data)
    if cache.gear ~= gear then
        cache.gear = gear
        cache.lines = {}
        cache.retry = {}
    end
    return cache
end

-- Whether a unit could have lines at all, per band. It does not depend on
-- worn gear, so it survives equipment changes and is never rebuilt on a hover.
local function UnitHintStore(data)
    local band = data:GetActiveBandCacheKey()
    local memo = data._unitHintMemo
    if not memo or memo.band ~= band then
        memo = { band = band, unit = {}, world = {} }
        data._unitHintMemo = memo
    end
    return memo
end

-- A hunt already obtained or removed has nothing left to send the player
-- for. That is read on every hover, so looting the piece takes it off the
-- quest giver without waiting for the cache.
local function StillHunted(entry)
    local log = GQ.Log
    if not log then
        return true
    end
    if log.IsEntryObtained and log:IsEntryObtained(entry.id) then
        return false
    end
    if log.IsHuntRemoved and log:IsHuntRemoved(entry) then
        return false
    end
    return true
end

local function CapPicksByPipelineScore(picks, cap)
    if not picks or cap <= 0 or #picks <= cap then
        return picks
    end
    table.sort(picks, function(a, b)
        local sa = (a.entry and a.entry.pipelineScore) or 0
        local sb = (b.entry and b.entry.pipelineScore) or 0
        if sa ~= sb then
            return sa > sb
        end
        return (a.entry.itemId or 0) < (b.entry.itemId or 0)
    end)
    local trimmed = {}
    for i = 1, cap do
        trimmed[i] = picks[i]
    end
    return trimmed
end

local function CachedLines(cache, key, picks, limit, minOverride, allowHeavy)
    if allowHeavy == nil then
        allowHeavy = true
    end
    local lineKey = key
    if minOverride ~= nil then
        lineKey = key .. ":gqmin" .. tostring(minOverride)
    end
    local kept = cache.lines[lineKey]
    local retryAt = cache.retry and cache.retry[lineKey]
    local due = retryAt and (GetTime and GetTime() or 0) >= retryAt
    if kept == nil or due then
        if not allowHeavy then
            return nil, nil, true
        end
        local unsure
        kept, unsure = KeepUpgrades(picks)
        -- A worn piece the client has not loaded yet cannot be compared.
        -- Keep the partial answer for a moment instead of recomputing it on
        -- every tooltip refresh, then ask again.
        cache.lines[lineKey] = kept or false
        if cache.retry then
            cache.retry[lineKey] = unsure and ((GetTime and GetTime() or 0) + 2) or nil
        end
    end
    if not kept then
        return nil, nil, false
    end
    local candidates = {}
    for i = 1, #kept do
        if StillHunted(kept[i].entry) then
            candidates[#candidates + 1] = kept[i]
        end
    end
    local filtered, meta = FilterUnitGearPicks(candidates, minOverride)
    if not filtered then
        return nil, meta, false
    end
    local shown = {}
    for i = 1, #filtered do
        if #shown >= limit then
            break
        end
        shown[#shown + 1] = filtered[i]
    end
    return #shown > 0 and shown or nil, meta, false
end

function GQ.Data:TopUnitGear(name, limit, minOverride, allowHeavy)
    limit = limit or 3
    local key = MobKey(name)
    local index = key and self.mobDrops
    local rows = index and index[key]
    local trainer = key and self.professionTrainers and self.professionTrainers[key]
    if not rows and not trainer then
        return nil, nil, false
    end
    if self.EnsureClassLoaded and GQ.GetEffectiveClass then
        self:EnsureClassLoaded(GQ:GetEffectiveClass())
    end
    local cache = UnitGearCache(self)
    local picks = cache.picks[key]
    if not picks then
        local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
        picks = {}
        local seen = {}
        local function Consider(itemId, chance, kind)
            if not itemId or seen[itemId] then
                return
            end
            seen[itemId] = true
            local entry = BestHuntEntry(itemId)
            if entry and BandContainsLevel(entry, level) then
                picks[#picks + 1] = {
                    entry = entry,
                    chance = chance,
                    kind = kind,
                }
            end
        end
        if rows then
            for i = 1, #rows do
                local row = rows[i]
                if FactionAllows(row[4]) then
                    Consider(row[1], row[2], row[3])
                end
            end
        end
        -- A trainer who does not sell the recipe still teaches that profession.
        -- The pieces are the crafted hunts for this level, not the trainer window.
        if trainer and FactionAllows(trainer[2]) then
            local gear = self.professionGear and self.professionGear[trainer[1]]
            if gear then
                for i = 1, #gear do
                    Consider(gear[i], 0, "p")
                end
            end
        end
        cache.picks[key] = picks
    end
    return CachedLines(cache, "unit:" .. key, picks, limit, minOverride, allowHeavy)
end

function KeepUpgrades(picks)
    if #picks == 0 then
        return nil
    end
    local kept = {}
    local unsure = false
    local ctxBySlot = {}
    for i = 1, #picks do
        local pick = picks[i]
        local slotName, handKind = TooltipSlot(pick.entry)
        local list = GQ.Log and GQ.Log.GetSlotRankList and GQ.Log:GetSlotRankList(slotName, handKind) or {}
        local scored, place = CurrentListRank(pick.entry, list)
        -- On this level's list, and it beats what is worn, or the slot is
        -- empty. A downgrade stays off. The arrow is that same comparison.
        if scored and place and not WearingEntry(scored, slotName) then
            local scoreText, index, arrow, pending = UnitGearScore(scored, slotName, handKind, ctxBySlot)
            if scoreText and index and arrow and arrow > 0 then
                kept[#kept + 1] = {
                    entry = scored,
                    chance = pick.chance,
                    kind = pick.kind,
                    rank = place,
                    scoreText = scoreText,
                    index = index,
                    arrow = arrow,
                }
            elseif pending then
                unsure = true
            end
        end
    end
    if #kept == 0 then
        return nil, unsure
    end
    local bestPerSlot = {}
    for i = 1, #kept do
        local pick = kept[i]
        local slotName, handKind = TooltipSlot(pick.entry)
        local slotKey = (slotName or "?") .. "\0" .. (handKind or "")
        local prev = bestPerSlot[slotKey]
        if not prev or (pick.arrow or 0) > (prev.arrow or 0) then
            bestPerSlot[slotKey] = pick
        end
    end
    kept = {}
    for _, pick in pairs(bestPerSlot) do
        kept[#kept + 1] = pick
    end
    if #kept == 0 then
        return nil, unsure
    end
    table.sort(kept, function(a, b)
        local again = a.arrow or a.index or 0
        local bgain = b.arrow or b.index or 0
        if again ~= bgain then
            return again > bgain
        end
        local arank = a.rank or 99
        local brank = b.rank or 99
        if arank ~= brank then
            return arank < brank
        end
        return (a.entry.itemId or 0) < (b.entry.itemId or 0)
    end)
    return kept, unsure
end

function GQ.Data:DemoUnitGearLines(name, limit)
    return self:TopUnitGear(name, limit or 3, 0)
end

function GQ.Data:DemoWorldDropLines(mobLevel, skip, limit, skipKey)
    return self:TopWorldDrops(mobLevel, skip, limit or 3, skipKey)
end

-- A generic world drop names no creature. Its stored range is the mob
-- levels that can drop it ("World drop around level 42-52."), so any mob
-- inside that range answers for it. A world drop with a named dropper is
-- already on that creature's own rows.
local worldDrops = { class = nil, ranges = nil, byLevel = {} }

local function WorldDropRanges(data)
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if worldDrops.ranges and worldDrops.class == classFile then
        return worldDrops
    end
    local ranges = data.genericWorldDropRanges
    if type(ranges) ~= "table" then
        ranges = {}
    end
    worldDrops.class = classFile
    worldDrops.ranges = ranges
    worldDrops.byLevel = {}
    return worldDrops
end

-- One gear slot per frame. Each slot asks for at most ten generic world
-- drops on this level's list. World-drop tooltip lines stay blank until
-- that short pass finishes.

local function PushWorldTop(top, mobLevel, pick)
    local list = top[mobLevel]
    if not list then
        list = {}
        top[mobLevel] = list
    end
    local score = (pick.entry and pick.entry.pipelineScore) or 0
    local last = list[#list]
    if #list >= WORLD_DROP_CANDIDATE_CAP and score <= ((last and last.entry and last.entry.pipelineScore) or 0) then
        return
    end
    list[#list + 1] = pick
    table.sort(list, function(a, b)
        return ((a.entry and a.entry.pipelineScore) or 0) > ((b.entry and b.entry.pipelineScore) or 0)
    end)
    if #list > WORLD_DROP_CANDIDATE_CAP then
        list[WORLD_DROP_CANDIDATE_CAP + 1] = nil
    end
end

local function UnitGearTipsHidden()
    local settings = UnitGearSettings()
    return settings and settings.hideUnitGearTips and true or false
end

local function WorldDropSlotList(data)
    local slots = {}
    local base = data.BASE_SLOTS
    if base then
        for i = 1, #base do
            slots[#slots + 1] = base[i]
        end
    end
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if classFile and data.CLASS_RANGED and data.CLASS_RANGED[classFile] then
        slots[#slots + 1] = "Ranged"
    end
    return slots
end

local function CollectReleasedTipGarbage()
    if not collectgarbage or not (C_Timer and C_Timer.NewTicker) then
        return
    end
    if GQ._tipGcTicker then
        GQ._tipGcTicker:Cancel()
        GQ._tipGcTicker = nil
    end
    local ticks = 0
    local ticker
    ticker = C_Timer.NewTicker(0, function()
        ticks = ticks + 1
        local finished = false
        for _ = 1, 80 do
            local ok, done = pcall(collectgarbage, "step")
            if not ok or done then
                finished = true
                break
            end
        end
        if finished or ticks >= 40 then
            ticker:Cancel()
            if GQ._tipGcTicker == ticker then
                GQ._tipGcTicker = nil
            end
        end
    end)
    GQ._tipGcTicker = ticker
end

function GQ.Data:ReleaseUnitGearTipData()
    self._worldDropBuild = nil
    self._unitGearCache = nil
    worldDrops.class = nil
    worldDrops.ranges = nil
    worldDrops.byLevel = {}
    if GQ.Log then
        GQ.Log._tooltipsPreviewData = nil
        GQ.Log._tooltipsPreviewSample = nil
        GQ.Log._tooltipsPreviewPaint = nil
        GQ.Log._tooltipsPreviewBuilding = nil
    end
    CollectReleasedTipGarbage()
end

function GQ.Data:CollectReleasedTipGarbage()
    CollectReleasedTipGarbage()
end

function GQ.Data:StartWorldDropBuild()
    if UnitGearTipsHidden() then
        self._worldDropBuild = nil
        return
    end
    local band = self:GetActiveBandCacheKey()
    local build = self._worldDropBuild
    if build and build.band == band then
        if build.done or build.started or not (C_Timer and C_Timer.After) then
            return
        end
        build.started = true
        local this = build
        C_Timer.After(0, function()
            self:StepWorldDropBuild(this)
        end)
        return
    end
    build = {
        band = band,
        slots = WorldDropSlotList(self),
        index = 1,
        top = {},
        done = false,
        started = false,
    }
    self._worldDropBuild = build
    if not (C_Timer and C_Timer.After) then
        return
    end
    build.started = true
    local this = build
    C_Timer.After(0, function()
        self:StepWorldDropBuild(this)
    end)
end

function GQ.Data:StepWorldDropBuild(build)
    if self._worldDropBuild ~= build or build.done then
        return
    end
    if build.band ~= self:GetActiveBandCacheKey() then
        return
    end
    if UnitGearTipsHidden() then
        if self._worldDropBuild == build then
            self._worldDropBuild = nil
        end
        return
    end
    local slot = build.slots and build.slots[build.index]
    if not slot then
        build.done = true
        if RefreshShiftTip then
            RefreshShiftTip(GameTooltip, true)
        end
        return
    end
    local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    local ranges = self.genericWorldDropRanges
    local ok, entries = pcall(function()
        return self:WorldDropSlotEntries(slot, WORLD_SLOT_CAP)
    end)
    if not ok or type(entries) ~= "table" then
        entries = {}
    end
    for i = 1, #entries do
        local entry = entries[i]
        local range = ranges and entry.itemId and ranges[entry.itemId]
        if entry and BandContainsLevel(entry, level) and type(range) == "table" then
            local pick = { entry = entry, chance = OpenWorldDropChance(self, entry.itemId), kind = "w" }
            local lo = tonumber(range[1]) or level
            local hi = tonumber(range[2]) or lo
            if hi < lo then
                lo, hi = hi, lo
            end
            for mobLevel = lo, hi do
                PushWorldTop(build.top, mobLevel, pick)
            end
        end
    end
    build.index = build.index + 1
    if not build.slots[build.index] then
        build.done = true
        if RefreshShiftTip then
            RefreshShiftTip(GameTooltip, true)
        end
        return
    end
    if C_Timer and C_Timer.After then
        local this = build
        C_Timer.After(0, function()
            self:StepWorldDropBuild(this)
        end)
    end
end

function GQ.Data:TopWorldDrops(mobLevel, skip, limit, skipKey, allowHeavy)
    mobLevel = tonumber(mobLevel)
    if not mobLevel or mobLevel < 1 then
        return nil, nil, false
    end
    if UnitGearTipsHidden() then
        return nil, nil, false
    end
    local build = self._worldDropBuild
    local band = self:GetActiveBandCacheKey()
    -- Never walk the raw id list from a tooltip. The background pass fills top.
    -- The tooltips preview must not start that pass under a stand-in hunter.
    if not build or build.band ~= band or not build.done then
        if not GQ._tooltipsPanelPreview then
            self:StartWorldDropBuild()
        end
        return nil, nil, false
    end
    local picks = build.top[mobLevel]
    if not picks or not picks[1] then
        return nil, nil, false
    end
    limit = limit or 3
    local unitCache = UnitGearCache(self)
    local shown = picks
    if skipKey and skip then
        shown = {}
        for i = 1, #picks do
            local itemId = picks[i].entry and picks[i].entry.itemId
            if not skip[itemId] then
                local chance = MobIndexedDropChance(self, skipKey, itemId)
                if chance > 0 and chance ~= picks[i].chance then
                    shown[#shown + 1] = { entry = picks[i].entry, chance = chance, kind = "w" }
                else
                    shown[#shown + 1] = picks[i]
                end
            end
        end
    end
    return CachedLines(unitCache, "world:" .. mobLevel .. ":" .. (skipKey or ""), shown, limit, nil, allowHeavy)
end

local function ClientKnowsItem(itemId)
    return itemId and C_Item and C_Item.IsItemDataCachedByID and C_Item.IsItemDataCachedByID(itemId) == true
end

local function DropItemName(entry)
    local itemId = entry and entry.itemId
    if not itemId then
        return nil
    end
    local base
    if ClientKnowsItem(itemId) and GQ.Data.ShownEntryName then
        base = GQ.Data:ShownEntryName(entry)
    end
    if not base or base == "" then
        base = GQ.Data.LocaleItemName and GQ.Data:LocaleItemName(itemId)
    end
    if not base or base == "" then
        local fact = GQ.Data:GetItemFact(itemId)
        local english = fact and fact.name
        if type(english) == "string" and english ~= "" then
            base = (GQ.TN and GQ.TN("item", english)) or english
        end
    end
    if not base or base == "" then
        return nil
    end
    local suffix = entry.suffix
    if suffix and suffix ~= "" and not string.find(base, suffix, 1, true) then
        base = base .. " " .. (L[suffix] or suffix)
    end
    return base
end

local function QualityHex(itemId)
    local quality = GQ.Data:GetItemQualityForDisplay(itemId)
    local color = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if not color then
        return "ffffff"
    end
    return string.format(
        "%02x%02x%02x",
        math.floor((color.r or 1) * 255 + 0.5),
        math.floor((color.g or 1) * 255 + 0.5),
        math.floor((color.b or 1) * 255 + 0.5)
    )
end

function UnitGearScore(entry, slotName, handKind, ctxBySlot)
    if not entry or type(entry.pipelineScore) ~= "number" then
        return nil
    end
    if not slotName then
        slotName = entry.slot
        if GQ.Data.NormalizeSlotName then
            slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
        end
    end
    local ctxKey = (slotName or "?") .. "\0" .. (handKind or "")
    local ctx = ctxBySlot and ctxBySlot[ctxKey]
    if not ctx then
        ctx = GQ.Data:GearScoreContext(slotName, handKind)
        if ctxBySlot then
            ctxBySlot[ctxKey] = ctx
        end
    end
    if not ctx then
        return nil
    end
    local indexScore = entry.pipelineScore
    if GQ.Data.EntryIsDamagingWeapon and GQ.Data:EntryIsDamagingWeapon(entry) then
        local shown = GQ.Data:DisplayedWeaponScore(entry)
        if type(shown) == "number" then
            indexScore = shown
        end
    end
    local score = GQ.Data:GearScoreIndex(indexScore, ctx.minScore, ctx.maxScore)
    if not score then
        score = math.floor(entry.pipelineScore + 0.5)
    end
    -- The item tooltip's green number. A downgrade, a tie, and a piece we
    -- cannot compare stay off. An empty slot is an upgrade on that index.
    local arrow = GQ.Data:GearScoreArrowDelta(entry, ctx)
    if (not arrow or arrow <= 0) and ctx.empty then
        arrow = score
    end
    if not arrow or arrow <= 0 then
        return nil, nil, nil, arrow == nil and #(ctx.unscoredWorn or {}) > 0
    end
    local text = "|cffffffff" .. score .. "|r"
    if GQ.Data.GearScoreDeltaText then
        text = text .. GQ.Data:GearScoreDeltaText(arrow, 0)
    end
    return text, score, arrow
end

function GQ.Data:UnitGearPreviewHeaderKey(picks)
    if not picks or not picks[1] then
        return nil
    end
    if MOB_KINDS[picks[1].kind] then
        return "Your top items from this mob:"
    end
    return "Your top items from this npc:"
end

function GQ.Data:FormatUnitGearPreviewLine(pick, lineNum)
    if not pick or not pick.entry then
        return nil
    end
    local entry = pick.entry
    local name = DropItemName(entry)
    if not name or name == "" then
        return nil
    end
    lineNum = lineNum or 1
    local line = tostring(lineNum) .. ". "
    local rank = pick.rank
    if rank then
        line = line .. string.format(L["Rank #%d"], rank) .. ". "
    end
    line = line .. "|cff" .. QualityHex(entry.itemId) .. name .. "|r"
    local slotName = entry.slot
    if GQ.Data.NormalizeSlotName then
        slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
    end
    local slotLabel = GQ.Data.SlotLabel and GQ.Data:SlotLabel(slotName)
    if slotLabel and slotLabel ~= "" then
        line = line .. " |cffc8c0b0(" .. slotLabel .. ")|r"
    end
    if pick.scoreText and pick.scoreText ~= "" then
        line = line .. "  " .. pick.scoreText
    end
    if UnitGearShowDropChance() then
        local pct = FormatDropPercent(pick.chance)
        if pct then
            line = line .. string.format(" |cff888888(%s%%)|r", pct)
        end
    end
    return line
end

local function AddLines(tooltip, picks, header)
    header = header or (MOB_KINDS[picks[1].kind] and "Your top items from this mob:" or "Your top items from this npc:")
    tooltip:AddLine(L[header] or header, 1, 0.82, 0, true)
    local shown = 0
    for i = 1, #picks do
        local entry = picks[i].entry
        local name = DropItemName(entry)
        if name then
            shown = shown + 1
            local rank = picks[i].rank
            local line = tostring(shown) .. ". "
            if rank then
                line = line .. string.format(L["Rank #%d"], rank) .. ". "
            end
            line = line .. "|cff" .. QualityHex(entry.itemId) .. name .. "|r"
            local slotName = entry.slot
            if GQ.Data.NormalizeSlotName then
                slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
            end
            local slotLabel = GQ.Data.SlotLabel and GQ.Data:SlotLabel(slotName)
            if slotLabel and slotLabel ~= "" then
                line = line .. " |cffc8c0b0(" .. slotLabel .. ")|r"
            end
            if picks[i].scoreText and picks[i].scoreText ~= "" then
                line = line .. "  " .. picks[i].scoreText
            end
            if UnitGearShowDropChance() then
                local pct = FormatDropPercent(picks[i].chance)
                if pct then
                    line = line .. string.format(" |cff888888(%s%%)|r", pct)
                end
            end
            tooltip:AddLine(line, 1, 1, 1, true)
        end
    end
end

-- The first line of a unit tooltip is the creature name. World-cursor
-- tooltips (a dungeon nameplate, a mouseover inside Wailing Caverns) mark
-- the unit token as a secret. UnitExists, UnitIsPlayer, UnitGUID, and
-- UnitName throw if addon code passes that secret. Read the painted name
-- instead, and add nothing when that text is secret too.
local function TooltipUnitName(tooltip)
    local left = tooltip.TextLeft1
    if not left or not left.GetText then
        local tipName = tooltip.GetName and tooltip:GetName()
        if tipName then
            left = _G[tipName .. "TextLeft1"]
        end
    end
    if not left or not left.GetText then
        return nil
    end
    local ok, text = pcall(left.GetText, left)
    if not ok then
        return nil
    end
    if GQ.PublicText then
        return GQ.PublicText(text)
    end
    if type(text) ~= "string" or text == "" then
        return nil
    end
    return text
end

local function PublicUnitCall(fn, unit)
    if not fn or not unit then
        return nil
    end
    local ok, value = pcall(fn, unit)
    if not ok then
        return nil
    end
    if GQ.PublicText then
        return GQ.PublicText(value)
    end
    return value
end

local function IsSecret(value)
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then
            return true
        end
    end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if not ok or not accessible then
            return true
        end
    end
    return false
end

local function PublicNumber(value)
    if value == nil or IsSecret(value) then
        return nil
    end
    local ok, number = pcall(tonumber, value)
    return ok and number or nil
end

local function PublicBoolean(value)
    if value == nil or IsSecret(value) or type(value) ~= "boolean" then
        return nil
    end
    return value
end

local function TooltipLine(tooltip, side, index)
    local tipName = tooltip.GetName and tooltip:GetName()
    local line = tooltip["Text" .. side .. index] or (tipName and _G[tipName .. "Text" .. side .. index])
    if line and line.GetText then
        return line
    end
    return nil
end

-- The level on the tooltip ("Level 45 Elite"). A ?? boss has no number.
local function MobLevel(tooltip, token)
    if token and UnitLevel then
        local ok, level = pcall(UnitLevel, token)
        level = ok and PublicNumber(level) or nil
        if level then
            return level > 0 and level or nil
        end
    end
    local word = type(LEVEL) == "string" and LEVEL ~= "" and LEVEL or "Level"
    for i = 2, 4 do
        local line = TooltipLine(tooltip, "Left", i)
        if line then
            local ok, text = pcall(line.GetText, line)
            text = ok and GQ.PublicText and GQ.PublicText(text) or nil
            if text and string.find(text, word, 1, true) then
                return tonumber(string.match(text, "(%d+)"))
            end
        end
    end
    return nil
end

-- A mob the player can fight. A friendly name is green. Inside a dungeon
-- the token and the name color can both be secret, and the units there are
-- nearly all hostile.
function GQ.Data:MobHasIndexedGearCandidates(mobKey, charLevel)
    if not mobKey then
        return false
    end
    local rows = self.mobDrops and self.mobDrops[mobKey]
    local trainer = self.professionTrainers and self.professionTrainers[mobKey]
    if not rows and not trainer then
        return false
    end
    charLevel = charLevel or (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    if rows then
        for i = 1, #rows do
            local row = rows[i]
            if row and FactionAllows(row[4]) then
                local entry = BestHuntEntry(row[1])
                if entry and BandContainsLevel(entry, charLevel) then
                    return true
                end
            end
        end
    end
    if trainer and FactionAllows(trainer[2]) then
        local gear = self.professionGear and self.professionGear[trainer[1]]
        if gear then
            for i = 1, #gear do
                local entry = BestHuntEntry(gear[i])
                if entry and BandContainsLevel(entry, charLevel) then
                    return true
                end
            end
        end
    end
    return false
end

function GQ.Data:MobHasWorldDropCandidates(mobLevel, charLevel, skip)
    mobLevel = tonumber(mobLevel)
    if not mobLevel or mobLevel < 1 then
        return false
    end
    charLevel = charLevel or (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    if self.EnsureClassLoaded and GQ.GetEffectiveClass then
        self:EnsureClassLoaded(GQ:GetEffectiveClass())
    end
    local cache = WorldDropRanges(self)
    local ids = cache.byLevel[mobLevel]
    if not ids then
        if type(self.worldDropIdsByLevel) == "table" and self.worldDropIdsByLevel[mobLevel] then
            ids = self.worldDropIdsByLevel[mobLevel]
        else
            ids = {}
            for itemId, range in pairs(cache.ranges) do
                if mobLevel >= range[1] and mobLevel <= range[2] then
                    ids[#ids + 1] = itemId
                end
            end
        end
        cache.byLevel[mobLevel] = ids
    end
    local checked = 0
    for i = 1, #ids do
        local itemId = ids[i]
        if not (skip and skip[itemId]) then
            local entry = BestHuntEntry(itemId)
            if entry and BandContainsLevel(entry, charLevel) then
                return true
            end
            checked = checked + 1
            if checked >= WORLD_DROP_CANDIDATE_CAP then
                break
            end
        end
    end
    return false
end

-- The Shift hint answer from the memo only. true or false when known, nil
-- when a later frame still has to look. Never walks hunt rows.
function GQ.Data:UnitHintAnswer(mobKey, hostile, mobLevel)
    local memo = UnitHintStore(self)
    local unitAns = false
    if mobKey then
        unitAns = memo.unit[mobKey]
        if unitAns == nil then
            local rows = self.mobDrops and self.mobDrops[mobKey]
            local trainer = self.professionTrainers and self.professionTrainers[mobKey]
            if not rows and not trainer then
                unitAns = false
                memo.unit[mobKey] = false
            end
        end
    end
    if unitAns == true then
        return true
    end
    local worldAns = false
    if hostile and mobLevel then
        worldAns = memo.world[mobLevel]
    end
    if worldAns == true then
        return true
    end
    if unitAns == nil or worldAns == nil then
        return nil
    end
    return false
end

function GQ.Data:FillUnitHint(mobKey, hostile, mobLevel)
    local memo = UnitHintStore(self)
    if self.EnsureClassLoaded and GQ.GetEffectiveClass then
        self:EnsureClassLoaded(GQ:GetEffectiveClass())
    end
    local charLevel = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    if mobKey and memo.unit[mobKey] == nil then
        memo.unit[mobKey] = self:MobHasIndexedGearCandidates(mobKey, charLevel) and true or false
    end
    if hostile and mobLevel and memo.world[mobLevel] == nil then
        memo.world[mobLevel] = self:MobHasWorldDropCandidates(mobLevel, charLevel, nil) and true or false
    end
end

local function MobSkip(data, mobKey)
    local rows = mobKey and data.mobDrops and data.mobDrops[mobKey]
    if not rows or #rows == 0 then
        return nil
    end
    local skip = {}
    for i = 1, #rows do
        skip[rows[i][1]] = true
    end
    return skip
end

function GQ.Data:EnqueueUnitGearBuild(job)
    self._unitGearBuildQueue = self._unitGearBuildQueue or {}
    local queue = self._unitGearBuildQueue
    for i = 1, #queue do
        local existing = queue[i]
        if existing.tooltip == job.tooltip and existing.guid == job.guid then
            return
        end
    end
    queue[#queue + 1] = job
    if self._unitGearPumpScheduled or not C_Timer or not C_Timer.After then
        return
    end
    self._unitGearPumpScheduled = true
    C_Timer.After(0, function()
        self._unitGearPumpScheduled = false
        self:PumpUnitGearBuildQueue()
    end)
end

function GQ.Data:PumpUnitGearBuildQueue()
    local queue = self._unitGearBuildQueue
    if not queue or #queue == 0 then
        return
    end
    local job = table.remove(queue, 1)
    local refresh = true
    if job.hint then
        self:FillUnitHint(job.mobKey, job.hostile, job.mobLevel)
        refresh = self:UnitHintAnswer(job.mobKey, job.hostile, job.mobLevel) == true
    else
        if job.name then
            self:TopUnitGear(job.name, 3, nil, true)
        end
        if job.hostile and job.mobLevel then
            self:TopWorldDrops(job.mobLevel, MobSkip(self, job.mobKey), 3, job.mobKey, true)
        end
    end
    local tip = job.tooltip
    if not refresh and tip then
        tip.gqUnitGearPending = nil
    end
    if refresh and tip and tip.IsShown and tip:IsShown() and (tip.gqUnitGear == job.guid or tip.gqUnitWatch == job.guid) then
        tip.gqUnitGearPending = nil
        tip.gqUnitGear = nil
        if tip.RefreshData then
            pcall(tip.RefreshData, tip)
        elseif tip.SetUnit and UnitExists then
            local ok, exists = pcall(UnitExists, "mouseover")
            if ok and exists == true then
                pcall(tip.SetUnit, tip, "mouseover")
            end
        end
    end
    if #queue > 0 and C_Timer and C_Timer.After then
        self._unitGearPumpScheduled = true
        C_Timer.After(0, function()
            self._unitGearPumpScheduled = false
            self:PumpUnitGearBuildQueue()
        end)
    end
end

local function MobIsHostile(tooltip, token)
    if token and UnitCanAttack then
        local ok, attack = pcall(UnitCanAttack, "player", token)
        if ok then
            attack = PublicBoolean(attack)
        else
            attack = nil
        end
        if attack == false then
            return false
        end
        if attack == true then
            if UnitPlayerControlled then
                local okPet, pet = pcall(UnitPlayerControlled, token)
                if okPet and PublicBoolean(pet) == true then
                    return false
                end
            end
            return true
        end
    end
    local line = TooltipLine(tooltip, "Left", 1)
    if line and line.GetTextColor then
        local ok, r, g, b = pcall(line.GetTextColor, line)
        r, g, b = ok and PublicNumber(r), ok and PublicNumber(g), ok and PublicNumber(b)
        if r and g and b then
            return r > 0.8 and b < 0.3
        end
    end
    local ok, inside = pcall(IsInInstance)
    return ok and inside == true
end

local function TooltipDataText(line)
    if not line then
        return nil
    end
    local text = line.leftText or line.left
    if GQ.PublicText then
        return GQ.PublicText(text)
    end
    return type(text) == "string" and text ~= "" and text or nil
end

local function TooltipDataName(data)
    local lines = data and data.lines
    return TooltipDataText(lines and lines[1])
end

local function TooltipDataLevel(data)
    local lines = data and data.lines
    if not lines then
        return nil
    end
    local word = type(LEVEL) == "string" and LEVEL ~= "" and LEVEL or "Level"
    local last = #lines
    if last > 4 then
        last = 4
    end
    for i = 2, last do
        local text = TooltipDataText(lines[i])
        if text and string.find(text, word, 1, true) then
            return tonumber(string.match(text, "(%d+)"))
        end
    end
    return nil
end

-- nil when the name color is not on the tooltip data. Red and yellow can be attacked.
local function TooltipDataHostile(data)
    local line = data and data.lines and data.lines[1]
    local color = line and (line.leftColor or line.color)
    if type(color) ~= "table" then
        return nil
    end
    local r = PublicNumber(color.r or color[1])
    local b = PublicNumber(color.b or color[3])
    if not r or not b then
        return nil
    end
    return r > 0.8 and b < 0.3
end

function GQ.Data:ReadUnitTooltipData(data)
    local guid = data and data.guid
    if GQ.PublicText then
        guid = GQ.PublicText(guid)
    elseif type(guid) ~= "string" then
        guid = nil
    end
    if guid and (string.find(guid, "^Player%-") or string.find(guid, "^Pet%-")) then
        return nil
    end
    local name = TooltipDataName(data)
    if not name then
        return nil
    end
    return name, guid or ("name:" .. string.lower(name)), TooltipDataHostile(data), TooltipDataLevel(data), MobKey(name)
end

-- Whether the upgrade lines for this unit are already cached. A miss means the
-- scan has not run. It does not run the scan.
function GQ.Data:UnitGearReady(key, hostile, mobLevel)
    local cache = UnitGearCache(self)
    local listed = key and ((self.mobDrops and self.mobDrops[key]) or (self.professionTrainers and self.professionTrainers[key]))
    if listed and cache.lines["unit:" .. key] == nil then
        return false
    end
    if hostile ~= false and mobLevel then
        local build = self._worldDropBuild
        local top = build and build.done and build.band == self:GetActiveBandCacheKey() and build.top[mobLevel]
        if top and top[1] and cache.lines["world:" .. mobLevel .. ":" .. (key or "")] == nil then
            return false
        end
    end
    return true
end

-- No Shift: one index lookup on the tooltip data the game already built.
-- No unit calls, no hunt rows, no timer, no tooltip rebuild.
function GQ.Data:AddUnitGearHint(tooltip, data)
    local name, guid, hostile, mobLevel, key = self:ReadUnitTooltipData(data)
    if not name then
        return
    end
    if not mobLevel and hostile ~= false then
        mobLevel = MobLevel(tooltip, nil)
    end
    tooltip.gqUnitWatch = guid
    local may = key and ((self.mobDrops and self.mobDrops[key]) or (self.professionTrainers and self.professionTrainers[key]))
    if not may and hostile ~= false and mobLevel then
        local ids = self.worldDropIdsByLevel and self.worldDropIdsByLevel[mobLevel]
        may = ids and ids[1] and true or false
    end
    tooltip.gqUnitGear = guid
    tooltip.gqUnitGearPending = nil
    if not may then
        tooltip.gqUnitShiftHint = nil
        return
    end
    tooltip.gqUnitShiftHint = true
    tooltip:AddLine(L["Hold Shift to see BiS items from this NPC"], 0.6, 0.6, 0.6, true)
end

function GQ.Data:AddUnitGearLines(tooltip, unit, hintedName, dataGuid, data)
    if not tooltip then
        return
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.hideUnitGearTips then
        return
    end
    local name, guid, hostile, mobLevel, key
    if data then
        -- The tooltip data is already built. Do not call GetUnit or any Unit* API.
        name, guid, hostile, mobLevel, key = self:ReadUnitTooltipData(data)
        if not name then
            return
        end
    else
        -- A secret token is not a unit id. Never hand it to UnitExists.
        local token = GQ.PublicText and GQ.PublicText(unit) or nil
        if token and UnitExists then
            local ok, exists = pcall(UnitExists, token)
            if not ok or not exists then
                token = nil
            end
        end
        name = GQ.PublicText and GQ.PublicText(hintedName) or nil
        if token and UnitIsPlayer then
            local ok, player = pcall(UnitIsPlayer, token)
            if ok and player then
                return
            end
            guid = PublicUnitCall(UnitGUID, token) or token
            if not name then
                name = PublicUnitCall(UnitName, token)
            end
        end
        if not name then
            name = TooltipUnitName(tooltip)
        end
        if not name then
            return
        end
        if token and OppositeFactionNpc(token) then
            return
        end
        guid = guid or (GQ.PublicText and GQ.PublicText(dataGuid)) or ("name:" .. string.lower(name))
        if string.find(guid, "^Player%-") or string.find(guid, "^Pet%-") then
            return
        end
        hostile = MobIsHostile(tooltip, token)
        key = MobKey(name)
        mobLevel = hostile and MobLevel(tooltip, token) or nil
    end
    if not mobLevel and hostile ~= false then
        mobLevel = MobLevel(tooltip, nil)
    end
    tooltip.gqUnitWatch = guid
    local showContent = UnitGearAlwaysShow() or UnitGearShiftDown()
    if not showContent then
        if data then
            self:AddUnitGearHint(tooltip, data)
            return
        end
        local may = key and ((self.mobDrops and self.mobDrops[key]) or (self.professionTrainers and self.professionTrainers[key]))
        if not may and hostile and mobLevel then
            local ids = self.worldDropIdsByLevel and self.worldDropIdsByLevel[mobLevel]
            may = ids and ids[1] and true or false
        end
        tooltip.gqUnitGear = guid
        tooltip.gqUnitGearPending = nil
        if may then
            tooltip.gqUnitShiftHint = true
            tooltip:AddLine(L["Hold Shift to see BiS items from this NPC"], 0.6, 0.6, 0.6, true)
        else
            tooltip.gqUnitShiftHint = nil
        end
        return
    end
    if hostile == nil then
        -- Once per creature name. The tooltip refreshes many times while it is open.
        local memo = self._hostileMemo
        if not memo then
            memo = {}
            self._hostileMemo = memo
        end
        if key and memo[key] ~= nil then
            hostile = memo[key]
        else
            hostile = MobIsHostile(tooltip, nil) and true or false
            if key then
                memo[key] = hostile
            end
        end
        if hostile and not mobLevel then
            mobLevel = MobLevel(tooltip, nil)
        end
    end
    tooltip.gqUnitShiftHint = not UnitGearAlwaysShow()
    -- The scan waits for Shift, and it waits one frame past the tooltip build.
    if not self:UnitGearReady(key, hostile, mobLevel) then
        if C_Timer and C_Timer.After then
            tooltip.gqUnitGear = guid
            tooltip.gqUnitGearPending = true
            self:EnqueueUnitGearBuild({
                tooltip = tooltip,
                guid = guid,
                name = name,
                hostile = hostile,
                mobLevel = mobLevel,
                mobKey = key,
            })
            return
        end
    end
    local picks, pickMeta, pendingUnit = self:TopUnitGear(name, 3, nil, false)
    local drops, dropMeta, pendingWorld
    local skip = hostile and MobSkip(self, key) or nil
    if hostile and mobLevel then
        drops, dropMeta, pendingWorld = self:TopWorldDrops(mobLevel, skip, 3, key, false)
    end
    if pendingUnit or pendingWorld then
        if not C_Timer or not C_Timer.After then
            picks, pickMeta = self:TopUnitGear(name, 3, nil, true)
            if hostile and mobLevel then
                drops, dropMeta = self:TopWorldDrops(mobLevel, skip, 3, key, true)
            else
                drops, dropMeta = nil, nil
            end
            pendingUnit, pendingWorld = nil, nil
        else
            tooltip.gqUnitGear = guid
            tooltip.gqUnitGearPending = true
            self:EnqueueUnitGearBuild({
                tooltip = tooltip,
                guid = guid,
                name = name,
                hostile = hostile,
                mobLevel = mobLevel,
                mobKey = key,
            })
            return
        end
    end
    tooltip.gqUnitGearPending = nil
    local minDropEmpty = (pickMeta and pickMeta.minDropEmpty) or (dropMeta and dropMeta.minDropEmpty)
    if not picks and not drops then
        if minDropEmpty then
            tooltip.gqUnitGear = guid
            tooltip:AddLine(
                L["Your minimum drop chance hid every upgrade line. Lower it on the Tooltips page, under Minimum drop chance on unit gear."],
                0.6,
                0.6,
                0.6,
                true
            )
        end
        return
    end
    tooltip.gqUnitGear = guid
    if picks then
        AddLines(tooltip, picks)
    end
    if drops then
        AddLines(tooltip, drops, "Your top world drops from this mob:")
    end
end

local function ClearUnitGear(tooltip)
    tooltip.gqUnitGear = nil
    tooltip.gqUnitShiftHint = nil
    tooltip.gqUnitGearPending = nil
end

local function ClearUnitGearWatch(tooltip)
    tooltip.gqUnitWatch = nil
end

-- Shift down or up while a unit tooltip waits on it draws that tooltip again.
-- The hint flag is wiped whenever the tooltip clears, including the refresh
-- that Shift itself starts. The watched unit stays until the tooltip hides.
function RefreshShiftTip(tip, force)
    if not tip or not tip.IsShown or not tip:IsShown() then
        return
    end
    local settings = UnitGearSettings()
    if settings and settings.hideUnitGearTips then
        tip.gqUnitShiftHint = nil
        return
    end
    if not tip.gqUnitShiftHint and not tip.gqUnitWatch and not tip.gqUnitGear then
        return
    end
    tip.gqUnitGear = nil
    if tip.RefreshData then
        pcall(tip.RefreshData, tip)
        return
    end
    if tip.SetUnit and UnitExists then
        local ok, exists = pcall(UnitExists, "mouseover")
        if ok and exists == true then
            pcall(tip.SetUnit, tip, "mouseover")
        end
    end
end

function GQ.Data:RefreshUnitGearTips()
    -- A checkbox only changes when the lines are drawn. It does not build
    -- the world-drop list. That list starts when a mob tooltip asks for it.
    RefreshShiftTip(GameTooltip, true)
end

local hooked

local function HookTip(tip)
    if not tip or tip.gqUnitGearHook or not tip.HookScript then
        return
    end
    tip.gqUnitGearHook = true
    tip:HookScript("OnTooltipCleared", ClearUnitGear)
    tip:HookScript("OnHide", ClearUnitGearWatch)
end

-- Class load used to scan world drops here. That scan is the hover hitch, so
-- it stays off until Shift asks for the lines.
function GQ.Data:WarmUnitGearTooltipCache()
    if self._unitGearWarmDone then
        return
    end
    self._unitGearWarmDone = true
    if UnitGearTipsHidden() then
        return
    end
    self:StartWorldDropBuild()
end

function GQ.Data:InstallUnitGearTips()
    if hooked then
        return
    end
    hooked = true
    local hasUnit = TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit
    HookTip(GameTooltip)
    if CreateFrame then
        local shiftWatch = CreateFrame("Frame")
        shiftWatch:RegisterEvent("MODIFIER_STATE_CHANGED")
        shiftWatch:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        if IsShiftKeyDown then
            local ok, held = pcall(IsShiftKeyDown)
            if ok and held == true then
                NoteShiftKey(true)
            end
        end
        shiftWatch:SetScript("OnEvent", function(_, event, key, down)
            if event == "PLAYER_EQUIPMENT_CHANGED" then
                GQ.Data._unitGearWornDirty = true
                return
            end
            if key ~= "LSHIFT" and key ~= "RSHIFT" and key ~= "SHIFT" then
                return
            end
            local pressed
            local ok, value = pcall(function()
                return down == 1 or down == true
            end)
            if ok then
                pressed = value and true or false
            elseif IsShiftKeyDown then
                local readOk, held = pcall(IsShiftKeyDown)
                if readOk and type(held) == "boolean" then
                    pressed = held
                end
            end
            if pressed ~= nil then
                NoteShiftKey(pressed)
            end
            if shiftWatch.gqShiftRefresh or not C_Timer or not C_Timer.After then
                RefreshShiftTip(GameTooltip)
                return
            end
            shiftWatch.gqShiftRefresh = true
            C_Timer.After(0, function()
                shiftWatch.gqShiftRefresh = false
                RefreshShiftTip(GameTooltip)
            end)
        end)
    end
    if hasUnit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            local settings = GearQuestForeverDB and GearQuestForeverDB.settings
            if settings and settings.hideUnitGearTips then
                return
            end
            -- Nothing is queried until Shift. GetUnit is not called from here.
            if not UnitGearAlwaysShow() and not UnitGearShiftDown() then
                GQ.Data:AddUnitGearHint(tooltip, data)
                return
            end
            GQ.Data:AddUnitGearLines(tooltip, nil, nil, nil, data)
        end)
        return
    end
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            local settings = GearQuestForeverDB and GearQuestForeverDB.settings
            if settings and settings.hideUnitGearTips then
                return
            end
            if not UnitGearAlwaysShow() and not UnitGearShiftDown() then
                return
            end
            GQ.Data:AddUnitGearLines(self, nil, nil, nil, nil)
        end)
    end
end

GQ.Data:InstallUnitGearTips()
