local _, GQ = ...

local L = GQ.L
GQ.Data = GQ.Data or {}

local MOB_KINDS = {
    b = true,
    r = true,
    w = true,
    t = true,
}

local UnitGearScore
local KeepUpgrades

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

local function CachedLines(cache, key, picks, limit)
    local kept = cache.lines[key]
    if kept == nil then
        local unsure
        kept, unsure = KeepUpgrades(picks)
        -- A worn piece the client has not loaded yet cannot be compared. Ask
        -- again on the next hover instead of keeping the empty answer.
        if not unsure then
            cache.lines[key] = kept or false
        end
    end
    if not kept then
        return nil
    end
    local shown = {}
    for i = 1, #kept do
        if #shown >= limit then
            break
        end
        if StillHunted(kept[i].entry) then
            shown[#shown + 1] = kept[i]
        end
    end
    return #shown > 0 and shown or nil
end

function GQ.Data:TopUnitGear(name, limit)
    limit = limit or 3
    local key = MobKey(name)
    local index = key and self.mobDrops
    local rows = index and index[key]
    local trainer = key and self.professionTrainers and self.professionTrainers[key]
    if not rows and not trainer then
        return nil
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
    return CachedLines(cache, "unit:" .. key, picks, limit)
end

function KeepUpgrades(picks)
    if #picks == 0 then
        return nil
    end
    local kept = {}
    local unsure = false
    for i = 1, #picks do
        local pick = picks[i]
        local slotName, handKind = TooltipSlot(pick.entry)
        local list = GQ.Log and GQ.Log.GetSlotRankList and GQ.Log:GetSlotRankList(slotName, handKind) or {}
        local scored, place = CurrentListRank(pick.entry, list)
        -- On this level's list, and it beats what is worn, or the slot is
        -- empty. A downgrade stays off. The arrow is that same comparison.
        if scored and place and not WearingEntry(scored, slotName) then
            local scoreText, index, arrow, pending = UnitGearScore(scored, slotName, handKind)
            if scoreText and index then
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
    local ranges = {}
    for itemId in data:IterCatalogItemIds() do
        local fact = data:GetItemFact(itemId)
        if fact and fact.sourceType == "world_drop" and not fact.npc then
            local lo, hi = string.match(fact.instructions or "", "^World drop around level (%d+)%-(%d+)%.")
            lo, hi = tonumber(lo), tonumber(hi)
            if lo and hi then
                ranges[itemId] = { lo, hi }
            end
        end
    end
    worldDrops.class = classFile
    worldDrops.ranges = ranges
    worldDrops.byLevel = {}
    return worldDrops
end

function GQ.Data:TopWorldDrops(mobLevel, skip, limit, skipKey)
    mobLevel = tonumber(mobLevel)
    if not mobLevel or mobLevel < 1 then
        return nil
    end
    if self.EnsureClassLoaded and GQ.GetEffectiveClass then
        self:EnsureClassLoaded(GQ:GetEffectiveClass())
    end
    local cache = WorldDropRanges(self)
    local ids = cache.byLevel[mobLevel]
    if not ids then
        ids = {}
        for itemId, range in pairs(cache.ranges) do
            if mobLevel >= range[1] and mobLevel <= range[2] then
                ids[#ids + 1] = itemId
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
                picks[#picks + 1] = { entry = entry, chance = 0, kind = "w" }
            end
        end
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
    return CachedLines(unitCache, pickKey .. ":" .. (skipKey or ""), shown, limit)
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

function UnitGearScore(entry, slotName, handKind)
    if not entry or type(entry.pipelineScore) ~= "number" then
        return nil
    end
    if not slotName then
        slotName = entry.slot
        if GQ.Data.NormalizeSlotName then
            slotName = GQ.Data:NormalizeSlotName(slotName) or slotName
        end
    end
    local ctx = GQ.Data:GearScoreContext(slotName, handKind)
    if not ctx then
        return nil
    end
    -- The item tooltip's green number. A downgrade, a tie, and a piece we
    -- cannot compare stay off. An empty slot is an upgrade.
    local arrow = GQ.Data:GearScoreArrowDelta(entry, ctx)
    if not ctx.empty and (not arrow or arrow <= 0) then
        return nil, nil, nil, arrow == nil and #(ctx.unscoredWorn or {}) > 0
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
    local text = "|cffffffff" .. score .. "|r"
    if arrow and arrow > 0 and GQ.Data.GearScoreDeltaText then
        text = text .. GQ.Data:GearScoreDeltaText(arrow, 0)
    end
    return text, score, arrow
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
    guid = guid or ("name:" .. string.lower(name))
    if tooltip.gqUnitGear == guid then
        return
    end
    tooltip.gqUnitGear = guid
    local picks = self:TopUnitGear(name, 3)
    local drops
    local kind = GQ.PublicText and GQ.PublicText(dataGuid) or guid
    if not (string.find(kind, "^Player%-") or string.find(kind, "^Pet%-")) and MobIsHostile(tooltip, token) then
        local skip = {}
        local key = MobKey(name)
        local rows = key and self.mobDrops and self.mobDrops[key]
        for i = 1, #(rows or {}) do
            skip[rows[i][1]] = true
        end
        drops = self:TopWorldDrops(MobLevel(tooltip, token), skip, 3, key)
    end
    if not picks and not drops then
        return
    end
    tooltip.gqUnitShiftHint = true
    if not (IsShiftKeyDown and IsShiftKeyDown()) then
        tooltip:AddLine(L["Hold Shift to see BiS items from this NPC"], 0.6, 0.6, 0.6, true)
        return
    end
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

local hooked

local function HookTip(tip)
    if not tip or tip.gqUnitGearHook or not tip.HookScript then
        return
    end
    tip.gqUnitGearHook = true
    tip:HookScript("OnTooltipCleared", ClearUnitGear)
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
