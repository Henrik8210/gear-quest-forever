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
    local picks = {}
    local seen = {}
    local function Consider(itemId, chance, kind)
        if not itemId or seen[itemId] then
            return
        end
        seen[itemId] = true
        local entry = BestHuntEntry(itemId)
        if entry then
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
    if #picks == 0 then
        return nil
    end
    local kept = {}
    for i = 1, #picks do
        local entry = picks[i].entry
        local slotName, handKind = TooltipSlot(entry)
        local list = GQ.Log and GQ.Log.GetSlotRankList and GQ.Log:GetSlotRankList(slotName, handKind) or {}
        local scored, place = CurrentListRank(entry, list)
        -- On this level's list, and it beats what is worn, or the slot is
        -- empty. A downgrade stays off. The arrow is that same comparison.
        if scored and place and not WearingEntry(scored, slotName) then
            local scoreText, index, arrow = UnitGearScore(scored, slotName, handKind)
            if scoreText and index then
                picks[i].entry = scored
                picks[i].rank = place
                picks[i].scoreText = scoreText
                picks[i].index = index
                picks[i].arrow = arrow
                kept[#kept + 1] = picks[i]
            end
        end
    end
    if #kept == 0 then
        return nil
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
    if #kept > limit then
        for i = #kept, limit + 1, -1 do
            kept[i] = nil
        end
    end
    return kept
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
    local text = "|cffffffff" .. score .. "|r"
    if arrow and arrow > 0 and GQ.Data.GearScoreDeltaText then
        text = text .. GQ.Data:GearScoreDeltaText(arrow, 0)
    end
    return text, score, arrow
end

local function AddLines(tooltip, picks)
    local header = MOB_KINDS[picks[1].kind] and "Your top items from this mob:" or "Your top items from this npc:"
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

function GQ.Data:AddUnitGearLines(tooltip, unit, hintedName)
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
    if not picks then
        return
    end
    AddLines(tooltip, picks)
end

local function ClearUnitGear(tooltip)
    tooltip.gqUnitGear = nil
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
            GQ.Data:AddUnitGearLines(tooltip, unit, name)
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
