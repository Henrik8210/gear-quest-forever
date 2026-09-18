local _, GQ = ...

-- Local Forever item notebook. Records unique equippable items this client has
-- actually seen (loot, bags, quest rewards, equipped, vendor, tooltip hover).
-- Hover snapshots the live tooltip so vendor items you cannot buy still get saved.
-- Nothing is uploaded. Export: WTF\<account>\SavedVariables\GearQuestForever.lua → seenItems.

GQ.Collector = GQ.Collector or {}

local SKIP_EQUIP = {
    INVTYPE_BAG = true,
    INVTYPE_QUIVER = true,
    INVTYPE_AMMO = true,
    INVTYPE_NON_EQUIP = true,
    INVTYPE_NON_EQUIP_IGNORE = true,
    INVTYPE_TABARD = true,
    INVTYPE_BODY = true,
}

local EQUIP_TO_SLOT = {
    INVTYPE_HEAD = "Head",
    INVTYPE_NECK = "Neck",
    INVTYPE_SHOULDER = "Shoulder",
    INVTYPE_CHEST = "Chest",
    INVTYPE_ROBE = "Chest",
    INVTYPE_WAIST = "Waist",
    INVTYPE_LEGS = "Legs",
    INVTYPE_FEET = "Feet",
    INVTYPE_WRIST = "Wrist",
    INVTYPE_HAND = "Hands",
    INVTYPE_FINGER = "Finger",
    INVTYPE_TRINKET = "Trinket",
    INVTYPE_CLOAK = "Back",
    INVTYPE_WEAPON = "MainHand",
    INVTYPE_2HWEAPON = "MainHand",
    INVTYPE_WEAPONMAINHAND = "MainHand",
    INVTYPE_WEAPONOFFHAND = "SecondaryHand",
    INVTYPE_HOLDABLE = "SecondaryHand",
    INVTYPE_SHIELD = "SecondaryHand",
    INVTYPE_RANGED = "Ranged",
    INVTYPE_THROWN = "Ranged",
    INVTYPE_RANGEDRIGHT = "Ranged",
    INVTYPE_RELIC = "Ranged",
}

local pending = {}
local bagScanAt = 0
local hoverAt = 0
local scanning = false
local tooltip
local hoverThrottle = {}

local function Store()
    GearQuestForeverDB = GearQuestForeverDB or {}
    GearQuestForeverDB.seenItems = GearQuestForeverDB.seenItems or {}
    return GearQuestForeverDB.seenItems
end

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
        return
    end
    local f = CreateFrame("Frame")
    local left = delay
    f:SetScript("OnUpdate", function(self, elapsed)
        left = left - elapsed
        if left <= 0 then
            self:SetScript("OnUpdate", nil)
            fn()
        end
    end)
end

local function Sanitize(text)
    if GQ.Data and GQ.Data.SanitizeText then
        return GQ.Data:SanitizeText(text) or text
    end
    return text
end

local function ParseItemId(link)
    if not link then
        return nil
    end
    return tonumber(tostring(link):match("item:(%d+)"))
end

local function ExtractChatLink(msg)
    if not msg then
        return nil
    end
    return msg:match("|Hitem:[^|]+|h[^|]*|h") or msg:match("|c%x+|Hitem:.-|h.-|h|r")
end

local function ParseSuffixId(link)
    if not link then
        return nil
    end
    -- item:id:enchant:gem1:gem2:gem3:gem4:suffixId:...
    local suffix = tonumber(tostring(link):match("item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:(-?%d+)"))
    if not suffix or suffix == 0 then
        return nil
    end
    return suffix
end

local function EnsureTooltip()
    if tooltip then
        return tooltip
    end
    tooltip = CreateFrame("GameTooltip", "GearQuestCollectorTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    return tooltip
end

local LINE_SLOT = {
    Head = "INVTYPE_HEAD",
    Neck = "INVTYPE_NECK",
    Shoulder = "INVTYPE_SHOULDER",
    Back = "INVTYPE_CLOAK",
    Chest = "INVTYPE_CHEST",
    Wrist = "INVTYPE_WRIST",
    Hands = "INVTYPE_HAND",
    Waist = "INVTYPE_WAIST",
    Legs = "INVTYPE_LEGS",
    Feet = "INVTYPE_FEET",
    Finger = "INVTYPE_FINGER",
    Trinket = "INVTYPE_TRINKET",
    Shield = "INVTYPE_SHIELD",
    ["One-Hand"] = "INVTYPE_WEAPON",
    ["Main Hand"] = "INVTYPE_WEAPONMAINHAND",
    ["Off Hand"] = "INVTYPE_WEAPONOFFHAND",
    ["Held In Off-hand"] = "INVTYPE_HOLDABLE",
    ["Two-Hand"] = "INVTYPE_2HWEAPON",
    Ranged = "INVTYPE_RANGEDRIGHT",
    Thrown = "INVTYPE_THROWN",
    Relic = "INVTYPE_RELIC",
}

local function StripColors(text)
    if not text then
        return ""
    end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function ReadTooltipLines(tip)
    if not tip then
        return nil, false
    end
    local name = tip.GetName and tip:GetName()
    if not name then
        return nil, false
    end
    local lines = {}
    local hasStats = false
    local n = tip:NumLines() or 0
    for i = 1, n do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text and text ~= "" then
            text = Sanitize(text)
            lines[#lines + 1] = text
            if text:find("%+%d") or text:find("%d+%-%d+") or text:find("Armor") or text:find("Damage") then
                hasStats = true
            end
        end
    end
    if #lines == 0 then
        return nil, false
    end
    return lines, hasStats
end

local function InferEquipLoc(lines)
    for i = 1, #(lines or {}) do
        local t = strtrim(StripColors(lines[i]))
        if LINE_SLOT[t] then
            return LINE_SLOT[t]
        end
        for word, loc in pairs(LINE_SLOT) do
            local nextChar = t:sub(#word + 1, #word + 1)
            if t:sub(1, #word) == word and (t == word or nextChar == " " or nextChar == ",") then
                return loc
            end
        end
    end
    return nil
end

local function LooksLikeGear(lines)
    if InferEquipLoc(lines) then
        return true
    end
    for i = 1, #(lines or {}) do
        local t = StripColors(lines[i])
        if t:find("Armor") or t:find("Damage") or t:find("Mail") or t:find("Leather")
            or t:find("Cloth") or t:find("Plate") or t:find("Shield")
        then
            return true
        end
    end
    return false
end

local function ScanTooltip(link)
    if not link then
        return nil, false
    end

    local tip = EnsureTooltip()
    scanning = true
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    pcall(function()
        tip:SetHyperlink(link)
    end)

    local lines, hasStats = ReadTooltipLines(tip)
    tip:Hide()
    scanning = false
    return lines, hasStats
end

local function ScanApiStats(link)
    if not link or type(GetItemStats) ~= "function" then
        return nil
    end
    local ok, stats = pcall(GetItemStats, link)
    if not ok or type(stats) ~= "table" then
        return nil
    end
    local out = {}
    local count = 0
    for k, v in pairs(stats) do
        out[k] = v
        count = count + 1
    end
    if count == 0 then
        return nil
    end
    return out
end

local function IsGearEquipLoc(equipLoc)
    if not equipLoc or equipLoc == "" then
        return false
    end
    if SKIP_EQUIP[equipLoc] then
        return false
    end
    return EQUIP_TO_SLOT[equipLoc] ~= nil
end

local function BagNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function BagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

function GQ.Collector:Record(itemId, link, source, snapshot)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end

    source = source or "unknown"
    if not link then
        local _, itemLink = GetItemInfo(itemId)
        link = itemLink
    end

    local name, itemLink, quality, itemLevel, reqLevel, itemType, itemSubType, _, equipLoc = GetItemInfo(link or itemId)
    link = itemLink or link

    local snapLines = snapshot and snapshot.lines
    local snapStats = snapshot and snapshot.hasStats

    if not name and snapLines then
        name = strtrim(StripColors(snapLines[1] or ""))
        if name == "" then
            name = nil
        end
        if not equipLoc or equipLoc == "" then
            equipLoc = InferEquipLoc(snapLines)
        end
    end

    if not name then
        pending[itemId] = source
        if type(GetItemInfo) == "function" then
            GetItemInfo(itemId)
        elseif C_Item and C_Item.GetItemInfo then
            C_Item.GetItemInfo(itemId)
        end
        return false
    end

    if not IsGearEquipLoc(equipLoc) then
        equipLoc = InferEquipLoc(snapLines) or equipLoc
    end

    if not IsGearEquipLoc(equipLoc) and not LooksLikeGear(snapLines) then
        pending[itemId] = nil
        return false
    end

    pending[itemId] = nil

    local tooltipLines, hasStats
    if snapLines then
        tooltipLines, hasStats = snapLines, snapStats
    else
        tooltipLines, hasStats = ScanTooltip(link)
    end
    local apiStats = ScanApiStats(link)
    if apiStats then
        hasStats = true
    end

    local store = Store()
    local key = tostring(itemId)
    local now = time()
    local zone = GetRealZoneText and GetRealZoneText() or nil
    local subzone = GetSubZoneText and GetSubZoneText() or nil
    if subzone == "" then
        subzone = nil
    end

    local prev = store[key]
    local row = prev or {}
    row.id = itemId
    row.name = name
    row.link = link
    row.quality = quality
    row.ilvl = itemLevel
    row.rlvl = reqLevel
    row.itemType = itemType
    row.itemSubType = itemSubType
    row.equipLoc = equipLoc
    row.slot = EQUIP_TO_SLOT[equipLoc]
    row.suffixId = ParseSuffixId(link)
    row.zone = zone or row.zone
    row.subzone = subzone or row.subzone
    row.playerLevel = UnitLevel("player")
    row.lastSource = source
    row.lastSeen = now
    if source == "vendor" then
        local npc = UnitName("npc")
        if (not npc or npc == "") and MerchantFrameTitleText and MerchantFrameTitleText.GetText then
            npc = MerchantFrameTitleText:GetText()
        end
        if npc and npc ~= "" then
            row.npc = npc
        end
    end
    if not row.firstSeen then
        row.firstSeen = now
        row.firstSource = source
    end

    if tooltipLines and (not row.tooltip or (hasStats and not row.hasStats) or #tooltipLines > #(row.tooltip or {})) then
        row.tooltip = tooltipLines
    end
    if apiStats then
        row.stats = apiStats
    end
    row.hasStats = row.hasStats or hasStats or false

    if name then
        store["n:" .. string.lower(name)] = nil
    end
    store[key] = row
    return true
end

function GQ.Collector:RecordNameSnapshot(name, source, snapshot)
    name = strtrim(StripColors(name or ""))
    if name == "" then
        return false
    end

    local store = Store()
    local lower = string.lower(name)
    for _, row in pairs(store) do
        if type(row) == "table" and row.name and string.lower(row.name) == lower and row.id then
            return true
        end
    end

    local lines = snapshot and snapshot.lines
    local hasStats = snapshot and snapshot.hasStats
    local equipLoc = InferEquipLoc(lines)
    local now = time()
    local key = "n:" .. lower
    local row = store[key] or {}
    row.name = name
    row.equipLoc = equipLoc or row.equipLoc
    row.slot = EQUIP_TO_SLOT[row.equipLoc] or row.slot
    row.tooltip = lines or row.tooltip
    row.hasStats = row.hasStats or hasStats or false
    row.lastSource = source or "recipe"
    row.lastSeen = now
    row.zone = (GetRealZoneText and GetRealZoneText()) or row.zone
    row.playerLevel = UnitLevel("player")
    if not row.firstSeen then
        row.firstSeen = now
        row.firstSource = row.lastSource
    end
    store[key] = row

    if self.listFrame and self.listFrame:IsShown() then
        local t = GetTime()
        if (t - hoverAt) > 1 then
            hoverAt = t
            self:RefreshList()
        end
    end
    return true
end

function GQ.Collector:RecordLink(link, source)
    local itemId = ParseItemId(link)
    if not itemId then
        return false
    end
    return self:Record(itemId, link, source)
end

local function HoverSource()
    if MerchantFrame and MerchantFrame:IsShown() then
        return "vendor"
    end
    if (ClassTrainerFrame and ClassTrainerFrame:IsShown())
        or (TradeSkillFrame and TradeSkillFrame:IsShown())
        or (CraftFrame and CraftFrame:IsShown())
        or (ProfessionsFrame and ProfessionsFrame:IsShown())
    then
        return "recipe"
    end
    if AuctionFrame and AuctionFrame:IsShown() then
        return "auction"
    end
    if InspectFrame and InspectFrame:IsShown() then
        return "inspect"
    end
    return "hover"
end

local ARMOR_WORDS = {
    Cloth = true,
    Leather = true,
    Mail = true,
    Plate = true,
    Miscellaneous = true,
}

local function IsTooltipMetaLine(text)
    if not text or text == "" then
        return true
    end
    if LINE_SLOT[text] or ARMOR_WORDS[text] then
        return true
    end
    if text:find("^Reagents") or text:find("^Requires") or text:find("^Binds") then
        return true
    end
    if text:find("^Unique") or text:find("^Item Level") or text:find("^Durability") then
        return true
    end
    if text:find("^%d+%s+Armor") or text:find("^%+") or text:find("^Equip:") then
        return true
    end
    if text:find("^Use:") or text:find("^Chance on hit") or text:find("^Sell Price") then
        return true
    end
    if text:find("appearance") or text:find("^Press F") or text:find("^You haven't") then
        return true
    end
    return false
end

local function CraftedNameFromLines(lines)
    local slotIndex
    for i = 1, #(lines or {}) do
        local t = strtrim(StripColors(lines[i]))
        if LINE_SLOT[t] then
            slotIndex = i
            break
        end
    end
    if slotIndex then
        for i = slotIndex - 1, 1, -1 do
            local t = strtrim(StripColors(lines[i]))
            if t ~= "" and not IsTooltipMetaLine(t) and not t:find("%(%d+%)") then
                return t:match("^[^:]+:%s*(.+)$") or t
            end
        end
    end
    local first = strtrim(StripColors((lines and lines[1]) or ""))
    if first:find(":") then
        return first:match("^[^:]+:%s*(.+)$")
    end
    return nil
end

local function WalkTooltipData(data, depth)
    depth = depth or 0
    if type(data) ~= "table" or depth > 8 then
        return nil, nil
    end

    local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
    local spellType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell
    local link = data.hyperlink
    local fromLink = link and ParseItemId(link)
    if fromLink then
        return fromLink, link
    end

    if data.itemID or data.itemId then
        local id = tonumber(data.itemID or data.itemId)
        if id then
            return id, link
        end
    end

    if itemType ~= nil and data.type == itemType then
        local id = tonumber(data.id)
        if id then
            return id, link
        end
    end

    if spellType ~= nil and data.type == spellType then
        -- spell id is not an item id
    elseif data.type == nil and data.id and link then
        local id = ParseItemId(link) or tonumber(data.id)
        if id and link then
            return id, link
        end
    end

    if data.lines then
        for i = 1, #data.lines do
            local nid, nlink = WalkTooltipData(data.lines[i], depth + 1)
            if nid then
                return nid, nlink
            end
        end
    end

    local nested = { data.tooltipData, data.itemData, data.recipeData, data.extraItem, data.childData }
    for i = 1, #nested do
        local nid, nlink = WalkTooltipData(nested[i], depth + 1)
        if nid then
            return nid, nlink
        end
    end

    return nil, nil
end

local function RecipeItemFromSpell(spellId)
    spellId = tonumber(spellId)
    if not spellId then
        return nil, nil
    end
    if C_TradeSkillUI then
        if C_TradeSkillUI.GetRecipeItemLink then
            local link = C_TradeSkillUI.GetRecipeItemLink(spellId)
            local id = ParseItemId(link)
            if id then
                return id, link
            end
        end
        if C_TradeSkillUI.GetRecipeInfo then
            local info = C_TradeSkillUI.GetRecipeInfo(spellId)
            if type(info) == "table" then
                local id = tonumber(info.itemID or info.craftedItemID or info.resultItemID)
                local link = info.hyperlink or info.itemLink
                if id then
                    return id, link
                end
                if link then
                    return ParseItemId(link), link
                end
            end
        end
    end
    return nil, nil
end

local function ExtractTooltipItem(tooltip, trainerIndex)
    if not tooltip then
        return nil, nil
    end

    if type(tooltip.GetItem) == "function" then
        local ok, _, itemLink = pcall(tooltip.GetItem, tooltip)
        if ok and itemLink then
            local id = ParseItemId(itemLink)
            if id then
                return id, itemLink
            end
        end
    end

    if type(tooltip.GetTooltipData) == "function" then
        local ok, data = pcall(tooltip.GetTooltipData, tooltip)
        if ok and data then
            local id, link = WalkTooltipData(data)
            if id then
                return id, link
            end
        end
    end

    if trainerIndex and GetTrainerServiceItemLink then
        local link = GetTrainerServiceItemLink(trainerIndex)
        local id = ParseItemId(link)
        if id then
            return id, link
        end
    end
    if trainerIndex and C_TooltipInfo and C_TooltipInfo.GetTrainerService then
        local ok, data = pcall(C_TooltipInfo.GetTrainerService, trainerIndex)
        if ok and data then
            local id, link = WalkTooltipData(data)
            if id then
                return id, link
            end
        end
    end

    if type(tooltip.GetSpell) == "function" then
        local ok, _, spellId = pcall(tooltip.GetSpell, tooltip)
        if ok then
            local id, link = RecipeItemFromSpell(spellId)
            if id then
                return id, link
            end
        end
    end

    local lines = ReadTooltipLines(tooltip)
    for i = 1, #(lines or {}) do
        local id = ParseItemId(lines[i])
        if id then
            return id, lines[i]:match("|Hitem:[^|]+|h[^|]*|h") or ("item:" .. id)
        end
    end

    local craftedName = CraftedNameFromLines(lines)
    if craftedName and craftedName ~= "" then
        if type(GetItemInfoInstant) == "function" then
            local id = GetItemInfoInstant(craftedName)
            if id then
                local _, itemLink = GetItemInfo(id)
                return id, itemLink
            end
        end
        if C_Item and C_Item.GetItemInfoInstant then
            local id = C_Item.GetItemInfoInstant(craftedName)
            if type(id) == "number" then
                local _, itemLink = GetItemInfo(id)
                return id, itemLink
            elseif type(id) == "table" and id.itemID then
                return id.itemID, id.hyperlink
            end
        end
        if type(GetItemInfo) == "function" then
            local _, itemLink = GetItemInfo(craftedName)
            local id = ParseItemId(itemLink)
            if id then
                return id, itemLink
            end
        end
    end

    return nil, nil, craftedName, lines
end

function GQ.Collector:RecordFromTooltip(tooltip, source, trainerIndex)
    if scanning or not tooltip then
        return false
    end
    local tipName = tooltip.GetName and tooltip:GetName()
    if tipName == "GearQuestCollectorTooltip" then
        return false
    end

    source = source or HoverSource()
    local itemId, link, craftedName, parsedLines = ExtractTooltipItem(tooltip, trainerIndex)
    local lines, hasStats = ReadTooltipLines(tooltip)
    lines = lines or parsedLines

    if not itemId and craftedName and LooksLikeGear(lines) then
        if type(GetItemInfo) == "function" then
            GetItemInfo(craftedName)
        end
        return self:RecordNameSnapshot(craftedName, source, { lines = lines, hasStats = hasStats })
    end

    if not itemId then
        return false
    end

    local now = GetTime()
    local prev = Store()[tostring(itemId)]
    if hoverThrottle[itemId] and (now - hoverThrottle[itemId]) < 1.25 and prev and prev.tooltip then
        return true
    end
    hoverThrottle[itemId] = now

    local ok = self:Record(itemId, link, source, { lines = lines, hasStats = hasStats })
    if ok and self.listFrame and self.listFrame:IsShown() and (now - hoverAt) > 1 then
        hoverAt = now
        self:RefreshList()
    end
    return ok
end

function GQ.Collector:ScanMerchant()
    local n = GetMerchantNumItems and GetMerchantNumItems() or 0
    for i = 1, n do
        local link = GetMerchantItemLink and GetMerchantItemLink(i)
        if link then
            self:RecordLink(link, "vendor")
        end
    end
end

function GQ.Collector:ScanTrainer()
    if not GetNumTrainerServices then
        return
    end
    local n = GetNumTrainerServices() or 0
    for i = 1, n do
        local link
        if GetTrainerServiceItemLink then
            link = GetTrainerServiceItemLink(i)
        end
        if link then
            self:RecordLink(link, "recipe")
        end
    end
end

function GQ.Collector:ScanTradeSkills()
    if GetNumTradeSkills and GetTradeSkillItemLink then
        local n = GetNumTradeSkills() or 0
        for i = 1, n do
            local link = GetTradeSkillItemLink(i)
            if link then
                self:RecordLink(link, "recipe")
            end
        end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        local ids = C_TradeSkillUI.GetAllRecipeIDs() or {}
        for i = 1, #ids do
            local link = C_TradeSkillUI.GetRecipeItemLink and C_TradeSkillUI.GetRecipeItemLink(ids[i])
            if link then
                self:RecordLink(link, "recipe")
            end
        end
    end
end

function GQ.Collector:HookTooltips()
    if self.tooltipsHooked then
        return
    end
    self.tooltipsHooked = true

    local function onTip(tip)
        GQ.Collector:RecordFromTooltip(tip)
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        local types = {}
        if Enum and Enum.TooltipDataType then
            types[#types + 1] = Enum.TooltipDataType.Item
            types[#types + 1] = Enum.TooltipDataType.Spell
            if Enum.TooltipDataType.Recipe then
                types[#types + 1] = Enum.TooltipDataType.Recipe
            end
        end
        for i = 1, #types do
            if types[i] ~= nil then
                pcall(TooltipDataProcessor.AddTooltipPostCall, types[i], function(tip)
                    onTip(tip)
                end)
            end
        end
    end

    local function hookScript(tip)
        if not tip or tip.gqCollectorHooked then
            return
        end
        tip.gqCollectorHooked = true
        pcall(function()
            tip:HookScript("OnTooltipSetItem", onTip)
        end)
        pcall(function()
            tip:HookScript("OnTooltipSetSpell", onTip)
        end)
    end
    hookScript(GameTooltip)
    hookScript(ItemRefTooltip)
    hookScript(EmbeddedItemTooltip)

    if GameTooltip then
        local function hookSetter(method, source)
            pcall(function()
                hooksecurefunc(GameTooltip, method, function(self, arg1)
                    GQ.Collector:RecordFromTooltip(self, source, arg1)
                    After(0, function()
                        if self.IsShown and self:IsShown() then
                            GQ.Collector:RecordFromTooltip(self, source, arg1)
                        end
                    end)
                end)
            end)
        end
        hookSetter("SetMerchantItem", "vendor")
        hookSetter("SetBuybackItem", "vendor")
        hookSetter("SetTrainerService", "recipe")
        hookSetter("SetTradeSkillItem", "recipe")
        hookSetter("SetCraftItem", "recipe")
        hookSetter("SetRecipeResultItem", "recipe")
        hookSetter("SetSpellByID", "recipe")
    end
end

local function OwnLootChat(msg)
    if not msg then
        return false
    end
    return msg:find("You create", 1, true)
        or msg:find("You receive loot", 1, true)
        or msg:find("You loot", 1, true)
        or msg:find("You receive item", 1, true)
        or msg:find("Received item", 1, true)
end

function GQ.Collector:ScanLootWindow()
    local n = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, n do
        local link = GetLootSlotLink and GetLootSlotLink(i)
        if link then
            self:RecordLink(link, "loot")
        end
    end
end

function GQ.Collector:ScanQuestRewards()
    local function scan(kind, countFn)
        local n = countFn and countFn() or 0
        for i = 1, n do
            local link = GetQuestItemLink and GetQuestItemLink(kind, i)
            if link then
                self:RecordLink(link, "quest")
            end
        end
    end
    scan("reward", GetNumQuestRewards)
    scan("choice", GetNumQuestChoices)
end

function GQ.Collector:ScanEquipped()
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            self:RecordLink(link, "equipped")
        end
    end
end

function GQ.Collector:ScanBags()
    for bag = 0, 4 do
        local slots = BagNumSlots(bag)
        for slot = 1, slots do
            local link = BagItemLink(bag, slot)
            if link then
                self:RecordLink(link, "bag")
            end
        end
    end
end

function GQ.Collector:ScheduleBagScan()
    local now = GetTime()
    if now - bagScanAt < 2 then
        return
    end
    bagScanAt = now
    After(0.4, function()
        GQ.Collector:ScanBags()
        GQ.Collector:ScanEquipped()
        if GQ.Collector.listFrame and GQ.Collector.listFrame:IsShown() then
            GQ.Collector:RefreshList()
        end
    end)
end

function GQ.Collector:Count()
    local store = Store()
    local total, withStats = 0, 0
    for _, row in pairs(store) do
        total = total + 1
        if row.hasStats then
            withStats = withStats + 1
        end
    end
    return total, withStats
end

function GQ.Collector:SortedRows()
    local store = Store()
    local list = {}
    for _, row in pairs(store) do
        list[#list + 1] = row
    end
    table.sort(list, function(a, b)
        local na = string.lower(a.name or "")
        local nb = string.lower(b.name or "")
        if na ~= nb then
            return na < nb
        end
        return (a.id or 0) < (b.id or 0)
    end)
    return list
end

local function GetFilterText()
    local frame = GQ.Collector.listFrame
    if frame and frame.search then
        return strtrim(frame.search:GetText() or "")
    end
    return GQ.Collector.searchText or ""
end

local function RowMatchesFilter(row, needle)
    if not needle or needle == "" then
        return true
    end
    needle = string.lower(needle)
    local parts = {
        row.name,
        tostring(row.id or ""),
        row.slot,
        row.equipLoc,
        row.zone,
        row.subzone,
        row.lastSource,
        row.firstSource,
        row.npc,
        row.itemType,
        row.itemSubType,
    }
    for i = 1, #parts do
        local text = parts[i]
        if text and text ~= "" and string.find(string.lower(tostring(text)), needle, 1, true) then
            return true
        end
    end
    return false
end

function GQ.Collector:FilteredRows()
    local rows = self:SortedRows()
    local needle = GetFilterText()
    if needle == "" then
        return rows, #rows, #rows
    end
    local out = {}
    for i = 1, #rows do
        if RowMatchesFilter(rows[i], needle) then
            out[#out + 1] = rows[i]
        end
    end
    return out, #out, #rows
end

local LIST_WIDTH = 460
local LIST_HEIGHT = 420
local LIST_ROW_H = 18
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"

local function QualityColor(quality)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    if c then
        return c.r, c.g, c.b
    end
    return 0.9, 0.9, 0.9
end

local function ApplyListChrome(frame)
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = METAL_EDGE,
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.08, 0.06, 0.04, 0.96)
        frame:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
end

function GQ.Collector:EnsureList()
    if self.listFrame then
        return self.listFrame
    end

    local frame = CreateFrame("Frame", "GearQuestSeenList", UIParent)
    tinsert(UISpecialFrames, "GearQuestSeenList")
    frame:SetSize(LIST_WIDTH, LIST_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    ApplyListChrome(frame)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Seen items")
    title:SetTextColor(0.90, 0.75, 0.28)
    frame.title = title

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetTextColor(0.75, 0.75, 0.7)
    frame.subtitle = subtitle

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 10)
    hint:SetText("Hover any item tooltip to snapshot it. /gq seen wipe clears the notebook.")
    frame.hint = hint

    local search = CreateFrame("EditBox", "GearQuestSeenSearch", frame, "InputBoxTemplate")
    search:SetHeight(20)
    search:SetAutoFocus(false)
    search:SetMaxLetters(80)
    search:SetPoint("TOPLEFT", 20, -52)
    search:SetPoint("TOPRIGHT", -36, -52)
    search:SetTextInsets(6, 6, 0, 0)
    frame.search = search

    local placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetText("Filter by name, slot, zone, id...")
    frame.searchPlaceholder = placeholder

    search:SetScript("OnTextChanged", function(self)
        local text = strtrim(self:GetText() or "")
        GQ.Collector.searchText = text
        if frame.searchPlaceholder then
            if text == "" then
                frame.searchPlaceholder:Show()
            else
                frame.searchPlaceholder:Hide()
            end
        end
        GQ.Collector:RefreshList()
    end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    search:SetScript("OnEscapePressed", function(self)
        if (self:GetText() or "") ~= "" then
            self:SetText("")
            self:ClearFocus()
            return
        end
        self:ClearFocus()
        frame:Hide()
    end)
    search:SetScript("OnEditFocusGained", function()
        if frame.searchPlaceholder then
            frame.searchPlaceholder:Hide()
        end
    end)
    search:SetScript("OnEditFocusLost", function(self)
        if frame.searchPlaceholder and strtrim(self:GetText() or "") == "" then
            frame.searchPlaceholder:Show()
        end
    end)

    local scroll = CreateFrame("ScrollFrame", "GearQuestSeenScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -76)
    scroll:SetPoint("BOTTOMRIGHT", -32, 28)
    frame.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() or (LIST_WIDTH - 44), 1)
    scroll:SetScrollChild(content)
    frame.content = content
    frame.rows = {}

    if frame.EnableMouseWheel then
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            local bar = scroll.ScrollBar
            if not bar then
                return
            end
            local step = LIST_ROW_H * 4
            bar:SetValue(bar:GetValue() - (delta * step))
        end)
    end

    frame:SetScript("OnShow", function()
        GQ.Collector:RefreshList()
    end)

    self.listFrame = frame
    return frame
end

function GQ.Collector:RefreshList()
    local frame = self.listFrame
    if not frame then
        return
    end

    local rows, shown, totalAll = self:FilteredRows()
    local _, withStats = self:Count()
    local needle = GetFilterText()
    if needle ~= "" then
        frame.subtitle:SetText(string.format("%d shown  ·  %d unique  ·  %d with stats", shown, totalAll, withStats))
    else
        frame.subtitle:SetText(string.format("%d unique  ·  %d with stats", totalAll, withStats))
    end
    if needle ~= self._listFilter then
        self._listFilter = needle
        if frame.scroll.ScrollBar then
            frame.scroll.ScrollBar:SetValue(0)
        end
    end

    local content = frame.content
    local used = frame.rows
    local width = (frame.scroll:GetWidth() or (LIST_WIDTH - 44)) - 4

    if #rows == 0 then
        if not frame.empty then
            local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            empty:SetPoint("TOPLEFT", 8, -8)
            empty:SetWidth(width)
            empty:SetJustifyH("LEFT")
            frame.empty = empty
        end
        if needle ~= "" then
            frame.empty:SetText("No items match that filter.")
        else
            frame.empty:SetText("No equip items recorded yet. Hover a vendor item, or loot/equip something.")
        end
        frame.empty:Show()
    elseif frame.empty then
        frame.empty:Hide()
    end

    for i, rowData in ipairs(rows) do
        local row = used[i]
        if not row then
            row = CreateFrame("Button", nil, content)
            row:SetHeight(LIST_ROW_H)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", 4, 0)
            row.label:SetPoint("RIGHT", -4, 0)
            row.label:SetJustifyH("LEFT")
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            row:SetScript("OnEnter", function(self)
                if not self.itemLink and not self.itemId then
                    return
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.itemLink then
                    GameTooltip:SetHyperlink(self.itemLink)
                else
                    GameTooltip:SetHyperlink("item:" .. self.itemId)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            row:SetScript("OnClick", function(self)
                if IsShiftKeyDown() and self.itemLink and ChatEdit_InsertLink then
                    ChatEdit_InsertLink(self.itemLink)
                end
            end)
            used[i] = row
        end

        local r, g, b = QualityColor(rowData.quality)
        local stats = rowData.hasStats and "" or "  |cff888888(no stats)|r"
        local slot = rowData.slot or rowData.equipLoc or "?"
        local zone = rowData.zone or ""
        local extra = zone ~= "" and ("  |cff888888" .. zone .. "|r") or ""
        if rowData.lastSource then
            extra = extra .. "  |cff888888" .. rowData.lastSource .. "|r"
        end
        row.label:SetText(string.format(
            "|cff%02x%02x%02x%s|r  |cff888888%s|r  %s%s%s",
            math.floor(r * 255 + 0.5),
            math.floor(g * 255 + 0.5),
            math.floor(b * 255 + 0.5),
            rowData.name or "?",
            rowData.id and rowData.id > 0 and tostring(rowData.id) or "—",
            slot,
            extra,
            stats
        ))
        row.itemId = rowData.id
        row.itemLink = rowData.link
        row:SetWidth(width)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * LIST_ROW_H))
        row:Show()
    end

    for i = #rows + 1, #used do
        used[i]:Hide()
    end

    local height = math.max(1, #rows * LIST_ROW_H)
    content:SetWidth(width)
    content:SetHeight(height)
    frame.scroll:UpdateScrollChildRect()
    if frame.scroll.ScrollBar then
        local range = height - (frame.scroll:GetHeight() or 0)
        if range <= 0 then
            frame.scroll.ScrollBar:SetMinMaxValues(0, 0)
            frame.scroll.ScrollBar:Hide()
        else
            frame.scroll.ScrollBar:Show()
        end
    end
end

function GQ.Collector:ToggleList()
    local frame = self:EnsureList()
    if frame:IsShown() then
        frame:Hide()
        return
    end
    self:ScanBags()
    self:ScanEquipped()
    frame:Show()
    self:RefreshList()
end

function GQ.Collector:PrintStatus()
    local total, withStats = self:Count()
    print(string.format(
        "|cff66ccffGearQuest|r: %d unique equip items recorded (%d with tooltip stats). Saved in GearQuestForeverDB.seenItems.",
        total,
        withStats
    ))
    print("|cff66ccffGearQuest|r: Copy |cff00ff00WTF\\<account>\\SavedVariables\\GearQuestForever.lua|r after logout/reload to ingest.")
end

function GQ.Collector:Wipe()
    GearQuestForeverDB = GearQuestForeverDB or {}
    GearQuestForeverDB.seenItems = {}
    print("|cff66ccffGearQuest|r: Cleared local seen-item notebook.")
    if self.listFrame and self.listFrame:IsShown() then
        self:RefreshList()
    end
end

function GQ.Collector:Init()
    if self.initialized then
        return
    end
    self.initialized = true
    Store()

    local frame = CreateFrame("Frame")
    local events = {
        "CHAT_MSG_LOOT",
        "LOOT_OPENED",
        "START_LOOT_ROLL",
        "PLAYER_EQUIPMENT_CHANGED",
        "BAG_UPDATE",
        "GET_ITEM_INFO_RECEIVED",
        "QUEST_COMPLETE",
        "QUEST_FINISHED",
        "PLAYER_ENTERING_WORLD",
        "MERCHANT_SHOW",
        "TRAINER_SHOW",
        "TRADE_SKILL_SHOW",
    }
    for i = 1, #events do
        GQ.RegisterEvent(frame, events[i])
    end
    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "CHAT_MSG_LOOT" then
            if OwnLootChat(arg1) then
                local link = ExtractChatLink(arg1)
                GQ.Collector:Record(ParseItemId(link or arg1), link, "loot")
            end
        elseif event == "LOOT_OPENED" then
            GQ.Collector:ScanLootWindow()
        elseif event == "START_LOOT_ROLL" then
            local link = GetLootRollItemLink and GetLootRollItemLink(arg1)
            if link then
                GQ.Collector:RecordLink(link, "roll")
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            GQ.Collector:ScanEquipped()
        elseif event == "BAG_UPDATE" then
            GQ.Collector:ScheduleBagScan()
        elseif event == "GET_ITEM_INFO_RECEIVED" then
            local itemId = tonumber(arg1)
            if itemId and pending[itemId] then
                GQ.Collector:Record(itemId, nil, pending[itemId])
            elseif itemId then
                local name = GetItemInfo(itemId)
                if name then
                    local named = Store()["n:" .. string.lower(name)]
                    if named then
                        GQ.Collector:Record(itemId, nil, named.lastSource or "recipe", {
                            lines = named.tooltip,
                            hasStats = named.hasStats,
                        })
                    end
                end
            end
        elseif event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" then
            GQ.Collector:ScanQuestRewards()
        elseif event == "PLAYER_ENTERING_WORLD" then
            After(2, function()
                GQ.Collector:ScanBags()
                GQ.Collector:ScanEquipped()
            end)
        elseif event == "MERCHANT_SHOW" then
            GQ.Collector:ScanMerchant()
        elseif event == "TRAINER_SHOW" then
            GQ.Collector:ScanTrainer()
        elseif event == "TRADE_SKILL_SHOW" then
            GQ.Collector:ScanTradeSkills()
        end
    end)
    self.frame = frame
    self:HookTooltips()
end
