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
local WORLD_DROP_CANDIDATE_CAP = 24

local function UnitGearSettings()
    return GearQuestForeverDB and GearQuestForeverDB.settings
end

local function UnitGearAlwaysShow()
    local settings = UnitGearSettings()
    return settings and settings.unitGearAlwaysShow == true
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
local function UnitGearCache(data)
    local band = data:GetActiveBandCacheKey()
    local cache = data._unitGearCache
    if not cache or cache.band ~= band then
        cache = { band = band, picks = {}, lines = {} }
        data._unitGearCache = cache
    end
    local worn = {}
    for inv = 1, 19 do
        worn[inv] = data:EquippedItemId(inv) or 0
    end
    local gear = table.concat(worn, ",")
    if cache.gear ~= gear then
        cache.gear = gear
        cache.lines = {}
    end
    return cache
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
    if kept == nil then
        if not allowHeavy then
            return nil, nil, true
        end
        local unsure
        kept, unsure = KeepUpgrades(picks)
        -- A worn piece the client has not loaded yet cannot be compared. Ask
        -- again on the next hover instead of keeping the empty answer.
        if not unsure then
            cache.lines[lineKey] = kept or false
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

function GQ.Data:TopWorldDrops(mobLevel, skip, limit, skipKey, allowHeavy)
    mobLevel = tonumber(mobLevel)
    if not mobLevel or mobLevel < 1 then
        return nil, nil, false
    end
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
    limit = limit or 3
    local unitCache = UnitGearCache(self)
    local pickKey = "world:" .. mobLevel
    local picks = unitCache.picks[pickKey]
    if not picks then
        local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
        picks = {}
        for i = 1, #ids do
            local entry = BestHuntEntry(ids[i])
            if entry and BandContainsLevel(entry, level) then
                local chance = 0
                if skipKey then
                    chance = MobIndexedDropChance(self, skipKey, ids[i])
                end
                if chance <= 0 then
                    chance = OpenWorldDropChance(self, ids[i])
                end
                picks[#picks + 1] = { entry = entry, chance = chance, kind = "w" }
            end
        end
        picks = CapPicksByPipelineScore(picks, WORLD_DROP_CANDIDATE_CAP)
        unitCache.picks[pickKey] = picks
    end
    local shown = picks
    if skipKey and skip then
        shown = {}
        for i = 1, #picks do
            if not skip[picks[i].entry.itemId] then
                shown[#shown + 1] = picks[i]
            end
        end
    end
    return CachedLines(unitCache, pickKey .. ":" .. (skipKey or ""), shown, limit, nil, allowHeavy)
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

function GQ.Data:UnitMayHaveGearLines(name, hostile, mobLevel, mobKey, skip)
    if self.EnsureClassLoaded and GQ.GetEffectiveClass then
        self:EnsureClassLoaded(GQ:GetEffectiveClass())
    end
    local charLevel = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
    local cache = UnitGearCache(self)
    if mobKey then
        local lineKey = "unit:" .. mobKey
        local cached = cache.lines[lineKey]
        if cached and cached ~= false then
            return true
        end
        if self:MobHasIndexedGearCandidates(mobKey, charLevel) then
            return true
        end
    end
    if hostile and mobLevel and self:MobHasWorldDropCandidates(mobLevel, charLevel, skip) then
        return true
    end
    if mobKey and hostile and mobLevel then
        local wkey = "world:" .. mobLevel .. ":" .. mobKey
        local cached = cache.lines[wkey]
        if cached and cached ~= false then
            return true
        end
    end
    return false
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
    if job.name then
        self:TopUnitGear(job.name, 3, nil, true)
    end
    if job.hostile and job.mobLevel then
        self:TopWorldDrops(job.mobLevel, job.skip, 3, job.mobKey, true)
    end
    local tip = job.tooltip
    if tip and tip.IsShown and tip:IsShown() and tip.gqUnitGear == job.guid then
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

function GQ.Data:AddUnitGearLines(tooltip, unit, hintedName, dataGuid)
    if not tooltip then
        return
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.hideUnitGearTips then
        return
    end
    -- A secret token is not a unit id. Never hand it to UnitExists.
    local token = GQ.PublicText and GQ.PublicText(unit) or nil
    if token and UnitExists then
        local ok, exists = pcall(UnitExists, token)
        if not ok or not exists then
            token = nil
        end
    end
    local name = GQ.PublicText and GQ.PublicText(hintedName) or nil
    local guid
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
    guid = guid or ("name:" .. string.lower(name))
    if tooltip.gqUnitGear == guid and not tooltip.gqUnitGearPending then
        return
    end
    local kind = GQ.PublicText and GQ.PublicText(dataGuid) or guid
    local hostile = not (string.find(kind, "^Player%-") or string.find(kind, "^Pet%-"))
        and MobIsHostile(tooltip, token)
    local key = MobKey(name)
    local mobLevel = hostile and MobLevel(tooltip, token) or nil
    local skip
    if hostile and key then
        local rows = self.mobDrops and self.mobDrops[key]
        if rows and #rows > 0 then
            skip = {}
            for i = 1, #rows do
                skip[rows[i][1]] = true
            end
        end
    end
    local showContent = UnitGearAlwaysShow() or (IsShiftKeyDown and IsShiftKeyDown())
    if not showContent then
        if not self:UnitMayHaveGearLines(name, hostile, mobLevel, key, skip) then
            return
        end
        if tooltip.gqUnitGear == guid then
            return
        end
        tooltip.gqUnitGear = guid
        tooltip.gqUnitShiftHint = true
        tooltip:AddLine(L["Hold Shift to see BiS items from this NPC"], 0.6, 0.6, 0.6, true)
        return
    end
    local picks, pickMeta, pendingUnit = self:TopUnitGear(name, 3, nil, false)
    local drops, dropMeta, pendingWorld
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
                skip = skip,
                mobKey = key,
            })
            return
        end
    end
    local minDropEmpty = (pickMeta and pickMeta.minDropEmpty) or (dropMeta and dropMeta.minDropEmpty)
    if not picks and not drops then
        if minDropEmpty then
            tooltip.gqUnitGear = guid
            tooltip:AddLine(
                L["Your minimum drop chance hid every upgrade line. Lower the slider in Hunt settings → Tooltips."],
                0.6,
                0.6,
                0.6,
                true
            )
        end
        return
    end
    tooltip.gqUnitGear = guid
    tooltip.gqUnitShiftHint = false
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

-- Shift down or up while a unit tooltip waits on it draws that tooltip again.
local function RefreshShiftTip(tip)
    if not tip or not tip.gqUnitShiftHint or not tip.IsShown or not tip:IsShown() then
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
    RefreshShiftTip(GameTooltip)
end

local hooked

local function HookTip(tip)
    if not tip or tip.gqUnitGearHook or not tip.HookScript then
        return
    end
    tip.gqUnitGearHook = true
    tip:HookScript("OnTooltipCleared", ClearUnitGear)
end

-- Build world-drop picks for the current level once class data is loaded so the
-- first hostile mob tooltip does not scan the whole catalog on the hover frame.
function GQ.Data:WarmUnitGearTooltipCache()
    if self._unitGearWarmDone then
        return
    end
    if not C_Timer or not C_Timer.After then
        return
    end
    C_Timer.After(0, function()
        if self._unitGearWarmDone then
            return
        end
        if self.EnsureClassLoaded and GQ.GetEffectiveClass then
            self:EnsureClassLoaded(GQ:GetEffectiveClass())
        end
        WorldDropRanges(self)
        local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
        level = tonumber(level) or 1
        if level > 0 then
            self:TopWorldDrops(level, nil, 3, "__warm__")
        end
        self._unitGearWarmDone = true
    end)
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
        shiftWatch:SetScript("OnEvent", function(_, _, key)
            if key == "LSHIFT" or key == "RSHIFT" then
                RefreshShiftTip(GameTooltip)
            end
        end)
    end
    if hasUnit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            local name, unit
            if tooltip.GetUnit then
                local ok, hinted, token = pcall(tooltip.GetUnit, tooltip)
                if ok then
                    name, unit = hinted, token
                end
            end
            local line = data and data.lines and data.lines[1]
            -- GetUnit's name is often the same secret as the unit token.
            -- A public line on the tooltip data still names the creature.
            if line and line.leftText and not (GQ.PublicText and GQ.PublicText(name)) then
                name = line.leftText
            end
            GQ.Data:AddUnitGearLines(tooltip, unit, name, data and data.guid)
        end)
        return
    end
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            local name, unit
            if self.GetUnit then
                local ok, hinted, token = pcall(self.GetUnit, self)
                if ok then
                    name, unit = hinted, token
                end
            end
            GQ.Data:AddUnitGearLines(self, unit, name)
        end)
    end
end

GQ.Data:InstallUnitGearTips()
