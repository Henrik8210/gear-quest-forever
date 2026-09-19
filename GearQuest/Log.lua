local ADDON_NAME, GQ = ...

GQ.Log = GQ.Log or {}

local FRAME_WIDTH = 768
local FRAME_HEIGHT = 512
local ROW_HEIGHT = 16
local TAB_HEIGHT = 24
local TAB_BAR_PAD = 4
local TAB_ROW_HEIGHT = TAB_HEIGHT + TAB_BAR_PAD
local CONTEXT_BAND_HEIGHT = 14
local CONTEXT_BAND_TOP = -27
local TAB_TOP_OFFSET = 56 + CONTEXT_BAND_HEIGHT
local PORTRAIT_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GearQuest-Portrait"
local PORTRAIT_DISPLAY_SIZE = 61
local PORTRAIT_OFFSET_X = -6
local PORTRAIT_OFFSET_Y = 7

-- Content area below title bar and above footer buttons.
local HEADER_OFFSET = 74
local FOOTER_OFFSET = 42
local FOOTER_BUTTON_Y = 14
local CONTENT_LEFT = 14
local CONTENT_RIGHT_GUTTER = 14
local COLUMN_GAP = 8
local USABLE_WIDTH = FRAME_WIDTH - CONTENT_LEFT - CONTENT_RIGHT_GUTTER
local LEFT_COLUMN_WIDTH = math.floor((USABLE_WIDTH - COLUMN_GAP) / 2)
local RIGHT_COLUMN_WIDTH = USABLE_WIDTH - COLUMN_GAP - LEFT_COLUMN_WIDTH
local PANEL_WIDTH = LEFT_COLUMN_WIDTH
local PANEL_INSET = 4
local GUTTER_INSET = 6
local PAGE_TAB_LOG_WIDTH = 108
local PAGE_TAB_SIM_WIDTH = 92
local FILTER_TAB_WIDTH = 84
local PAGE_GROUP_WIDTH = PAGE_TAB_LOG_WIDTH + PAGE_TAB_SIM_WIDTH + 4
local FILTER_TAB_OVERLAP = 3
local FILTER_TAB_LEFT = 12
-- Status band lives on the main frame above logPage; tabs still sit on the list edge.
local LOG_SECTION_TOP = -(TAB_HEIGHT - FILTER_TAB_OVERLAP)
local SIDE_TAB_HEIGHT = 53
local SIDE_TAB_WIDTH = 53
local SIDE_TAB_OVERLAP = 8
local SIDE_TAB_GAP = 10
local SIDE_TAB_ICON_SIZE = 22
local SIDE_TAB_ICON_PAD = 8
local SIDE_TAB_TOP = -(TAB_TOP_OFFSET - LOG_SECTION_TOP)
local TAB_BORDER_EDGE = 12
local FILTER_BORDER_EDGE = 8
local LOG_TAB_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local SIM_TAB_ICON = "Interface\\Icons\\Trade_Engineering"
local SECTION_DIVIDER_HEIGHT = 3
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local GOLD = { 0.90, 0.75, 0.28 }
local GOLD_DIM = { 0.55, 0.45, 0.22 }
local FRAME_METAL = { 0.78, 0.72, 0.58 }
local FRAME_METAL_DIM = { 0.42, 0.38, 0.30 }
local PANEL_BG = { 0.14, 0.10, 0.06, 1 }
local LIST_BG = { 0.02, 0.02, 0.02, 1 }
local WHEEL_STEP = ROW_HEIGHT * 4
local REWARD_ICON_SIZE = 44
local REWARD_NAME_MIN_WIDTH = 150
local REWARD_NAME_PAD = 16
local REWARD_NAME_MAX_WIDTH = REWARD_NAME_MIN_WIDTH - REWARD_NAME_PAD

local function TruncateFontStringToWidth(fontString, text, maxWidth)
    text = text and tostring(text) or ""
    fontString:SetText(text)
    if text == "" then
        return text
    end

    if (fontString:GetStringWidth() or 0) <= maxWidth then
        return text
    end

    local ellipsis = "..."
    for len = #text - 1, 1, -1 do
        local candidate = text:sub(1, len) .. ellipsis
        fontString:SetText(candidate)
        if (fontString:GetStringWidth() or 0) <= maxWidth then
            return candidate
        end
    end

    fontString:SetText(ellipsis)
    return ellipsis
end

local LIST_ROW_RIGHT_PAD = 6
local LIST_ROW_ITEM_LEFT = 20
local LIST_ROW_NOTABLE_LEFT = 24
local LIST_NEW_LABEL = " |cffFFD200New|r"
local LIST_TOOLTIP_X_GAP = 20
local NOTABLE_LIST_ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local SCROLLBAR_WIDTH = 18
local SCROLLBAR_INSET = SCROLLBAR_WIDTH + 8

local function SafeGetItemIcon(itemId)
    if not itemId then
        return nil
    end
    if GQ.Equip and GQ.Equip.GetItemIconTexture then
        return GQ.Equip:GetItemIconTexture(itemId)
    end
    if type(GetItemIcon) == "function" then
        return GetItemIcon(itemId)
    end
    return select(10, GetItemInfo(itemId))
end

local function GetListRowTextMaxWidth(row, leftInset)
    local width = row:GetWidth()
    if not width or width <= 0 then
        width = LEFT_COLUMN_WIDTH - (PANEL_INSET * 2)
    end
    return math.max(40, width - leftInset - LIST_ROW_RIGHT_PAD)
end

local function IsListRowHighlightable(rowType)
    return rowType == "item" or rowType == "notable"
end

local function UpdateListRowHighlight(row)
    if not row or not row.highlight then
        return
    end
    if not IsListRowHighlightable(row.rowType) then
        row.highlight:Hide()
        return
    end

    local log = _G.GearQuest and _G.GearQuest.Log
    local selected = log and row.entry and row.entry.id and row.entry.id == log.selectedHuntId
    if selected or row:IsMouseOver() then
        row.highlight:Show()
    else
        row.highlight:Hide()
    end
end

local function AnchorListRow(row, scrollChild, scroll, yOffset)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    if scroll then
        row:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
    else
        row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    end
end

local function GetListItemQualityColor(itemId)
    if not itemId then
        return 1, 0.82, 0
    end

    local quality = GQ.Data and GQ.Data.GetItemQualityForDisplay and GQ.Data:GetItemQualityForDisplay(itemId)
    if not quality then
        return 1, 0.82, 0
    end
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c then
        return c.r, c.g, c.b
    end
    return GetItemQualityColor(quality)
end

local function PrimeListEntryItemInfo(entry)
end

local function BuildListItemTags(entry, status, includeNewLabel, slotName)
    local tags = ""

    if entry and entry.origin == "guide" then
        tags = tags .. " |cff88ccff(Guide)|r"
    end

    if entry and GQ.Data:ShouldDisplayAsNotable(entry, slotName or (entry and entry.slot)) then
        tags = tags .. " |cff88ccff(Notable)|r"
    end

    if includeNewLabel and entry and GQ.Data:IsEntryNewForPlayer(entry) then
        tags = tags .. LIST_NEW_LABEL
    end

    if status == "tracked" then
        tags = tags .. " |cff00ff00(Tracked)|r"
    end

    return tags
end

local function FormatListItemText(fontString, name, entry, status, includeNewLabel, maxWidth, r, g, b, slotName)
    local tags = BuildListItemTags(entry, status, includeNewLabel, slotName)

    fontString:SetText(tags)
    local tagsWidth = fontString:GetStringWidth() or 0
    local nameMaxWidth = math.max(20, maxWidth - tagsWidth)

    TruncateFontStringToWidth(fontString, name, nameMaxWidth)
    local truncatedName = fontString:GetText() or name

    local hex = string.format("%02x%02x%02x",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
    return "|cff" .. hex .. truncatedName .. "|r" .. tags
end

local function SetListRowItemText(row, leftInset, name, entry, status, showNewLabel, r, g, b, slotName)
    local maxWidth = GetListRowTextMaxWidth(row, leftInset)
    local text = FormatListItemText(row.text, name, entry, status, showNewLabel, maxWidth, r, g, b, slotName)
    row.text:SetText(text)
    row.text:SetTextColor(1, 1, 1)
end

local SPEC_PICKER_WIDTH = 188
local SPEC_PICKER_ROW_HEIGHT = 20
local SPEC_PICKER_PAD = 4
local SPEC_ICON_SIZE = 18
local SPEC_ARROW_SIZE = 27
local SPEC_CONTROL_GAP = 2
local SPEC_CONTROL_WIDTH = SPEC_ICON_SIZE + SPEC_CONTROL_GAP + SPEC_ARROW_SIZE
local SPEC_CONTROL_HEIGHT = math.max(SPEC_ICON_SIZE, SPEC_ARROW_SIZE)
local SPEC_ROW_GAP = 2
local LOG_FRAME_STRATA = "DIALOG"
local LOG_FRAME_LEVEL = 100

local function ApplyLogWindowLayer(frame)
    if not frame then
        return
    end

    if frame.SetFrameStrata then
        frame:SetFrameStrata(LOG_FRAME_STRATA)
    end
    if frame.SetFrameLevel then
        frame:SetFrameLevel(LOG_FRAME_LEVEL)
    end
end

local function BringLogWindowToFront(frame)
    ApplyLogWindowLayer(frame)
    if frame and frame.Raise then
        frame:Raise()
    end
    local log = _G.GearQuest and _G.GearQuest.Log
    if log and log.LayoutSideTabs then
        log:LayoutSideTabs(frame)
    end
end
local TAB_GROUP_WIDTH = (88 * 2) + 4
local DETAIL_TEXT_COLOR = { 0.13, 0.09, 0.04 }
local LORE_TEXT_COLOR = { 0.20, 0.15, 0.10 }
-- QuestFont in this client has no usable space glyph, so parchment
-- titles/bodies render as "LAMBENTSCALEPAULDRONS" / "Worlddrop".
local QUEST_DETAIL_TITLE_FONTS = {
    "GameFontNormalLarge", "GameFontHighlightLarge", "GameFontNormal",
}

local QUEST_DETAIL_HEADER_FONTS = {
    "GameFontNormal", "GameFontHighlight",
}

local QUEST_DETAIL_BODY_FONTS = {
    "GameFontNormal", "GameFontHighlight",
}

local function GetHuntRecord(id)
    GearQuestForeverDB.hunts = GearQuestForeverDB.hunts or {}
    return GearQuestForeverDB.hunts[id]
end

local function GetObtainedTimestamp(id)
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    return GearQuestForeverDB.obtained[id]
end

local function IsDismissedCompleted(id)
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
    return GearQuestForeverDB.dismissedCompleted[id] == true
end

local function EnsureHuntRecord(id)
    GearQuestForeverDB.hunts = GearQuestForeverDB.hunts or {}
    if not GearQuestForeverDB.hunts[id] then
        GearQuestForeverDB.hunts[id] = {
            status = "tracked",
            trackedAt = time(),
        }
    end
    return GearQuestForeverDB.hunts[id]
end

local function NormalizeHuntStatus(status)
    if status == "active" then
        return "tracked"
    end
    return status
end

local function GetHuntStatus(id)
    local record = GetHuntRecord(id)
    if not record then
        return "available"
    end
    return NormalizeHuntStatus(record.status or "tracked")
end

local function FormatCompletedDate(timestamp)
    if not timestamp then
        return nil
    end
    if date then
        return date("%B %d, %Y at %H:%M", timestamp)
    end
    return tostring(timestamp)
end

local function ItemLinkToId(link)
    if not link then
        return nil
    end
    local ok, id = pcall(function()
        return tonumber(link:match("item:(%d+)"))
    end)
    if not ok then
        return nil
    end
    return id
end

local function GetBagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
end

local function GetBagSlotCount(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function PlayerOwnsItem(itemId)
    if not itemId then
        return false
    end

    local ok, owned = pcall(function()
        for invSlot = 1, 19 do
            if ItemLinkToId(GetInventoryItemLink("player", invSlot)) == itemId then
                return true
            end
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                if ItemLinkToId(GetBagItemLink(bag, slot)) == itemId then
                    return true
                end
            end
        end

        return false
    end)

    return ok and owned or false
end

local function GetCraftedTimestamp(itemId)
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    return GearQuestForeverDB.crafted[itemId]
end

local function ExtractItemIdFromChatMessage(msg)
    if not msg then
        return nil
    end

    -- Only the local player's craft/loot lines — never party loot chat with item links.
    if msg:find("You create", 1, true) then
        local itemId = tonumber(msg:match("item:(%d+)"))
        if itemId then
            return itemId
        end

        local itemName = msg:match("You create %[(.-)%]")
            or msg:match("You create (.+)%.")
        if not itemName then
            return nil
        end

        itemName = strtrim(itemName)

        for _, entry in ipairs(GQ.Data.entries) do
            if entry.sourceType == "profession" and entry.itemId then
                local name = GetItemInfo(entry.itemId)
                if name == itemName then
                    return entry.itemId
                end
            end
        end

        return nil
    end

    if msg:find("You receive loot", 1, true) or msg:find("You loot", 1, true) then
        return tonumber(msg:match("item:(%d+)"))
    end

    return nil
end

local function PlayerHasProducedProfessionItem(entry)
    if not entry or entry.sourceType ~= "profession" or not entry.itemId then
        return false
    end
    return GetCraftedTimestamp(entry.itemId) ~= nil
end

local function PlayerHasObtainedEntryItem(entry)
    if not entry then
        return false
    end

    if entry.sourceType == "profession" then
        return PlayerHasProducedProfessionItem(entry)
    end

    return GQ.Data:PlayerOwnsEntryItem(entry)
end

local function ShowItemTooltipForRow(row)
    if not row or not row.entry or not GQ.Data then
        return
    end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GQ.Data:PopulateEntryItemTooltip(GameTooltip, row.entry)

    local textTop = row.text and row.text:GetTop()
    local textBottom = row.text and row.text:GetBottom()
    local textLeft = row.text and row.text:GetLeft()
    local textWidth = row.text and row.text:GetStringWidth()
    if textTop and textBottom then
        local textCenterY = (textTop + textBottom) / 2
        local anchorX = row:GetRight()
        if not anchorX and textLeft and textWidth then
            anchorX = textLeft + textWidth
        end
        if anchorX then
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint("LEFT", UIParent, "BOTTOMLEFT", anchorX + LIST_TOOLTIP_X_GAP, textCenterY)
        end
    end

    GameTooltip:Show()
end

local function HideItemTooltip()
    if GQ.Data and GQ.Data.ClearPendingItemTooltip then
        GQ.Data:ClearPendingItemTooltip(GameTooltip)
    end
    GameTooltip:Hide()
end

local function TryHandleModifiedItemClick(entry)
    if not entry or not entry.itemId or not IsModifiedClick or not IsModifiedClick() then
        return false
    end

    local link = GQ.Data and GQ.Data.GetEntryItemHyperlink and GQ.Data:GetEntryItemHyperlink(entry)
        or select(2, GetItemInfo(entry.itemId))
        or ("item:" .. entry.itemId)

    if HandleModifiedItemClick then
        local handled = HandleModifiedItemClick(link)
        if handled then
            return true
        end
    end

    if IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
        return true
    end

    if IsModifiedClick("DRESSUP") then
        if DressUpItemLink then
            DressUpItemLink(link)
            return true
        end
        if DressUpFrame and DressUpFrame_Show then
            DressUpFrame_Show(DressUpFrame)
            if DressUpFrameModel and DressUpFrameModel.TryOn then
                DressUpFrameModel:TryOn(link)
                return true
            end
        end
    end

    return false
end

local function OnListRowItemClick(entry)
    if not entry or not entry.id then
        return
    end

    if entry.itemId and TryHandleModifiedItemClick(entry) then
        HideItemTooltip()
        return
    end

    local log = _G.GearQuest and _G.GearQuest.Log
    if log then
        log:SelectHunt(entry.id, false, entry)
    end
end

local function CreateRewardItemButton(parent, name)
    local button = CreateFrame("Button", name, parent)
    button:SetHeight(REWARD_ICON_SIZE)
    button:SetWidth(REWARD_ICON_SIZE + REWARD_NAME_MIN_WIDTH)

    local iconFrame = CreateFrame("Frame", nil, button)
    iconFrame:SetSize(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
    iconFrame:SetPoint("LEFT", button, "LEFT", 0, 0)
    iconFrame:EnableMouse(false)

    button.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(iconFrame)

    button.nameBg = button:CreateTexture(nil, "BACKGROUND")
    button.nameBg:SetPoint("LEFT", iconFrame, "RIGHT", 0, 0)
    button.nameBg:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    button.nameBg:SetPoint("TOP", iconFrame, "TOP", 0, 0)
    button.nameBg:SetPoint("BOTTOM", iconFrame, "BOTTOM", 0, 0)
    button.nameBg:SetColorTexture(0, 0, 0, 0.55)

    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.name:SetPoint("LEFT", button.nameBg, "LEFT", 8, 0)
    button.name:SetPoint("RIGHT", button.nameBg, "RIGHT", -10, 0)
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(false)
    button.name:SetTextColor(1, 1, 1)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnEnter", function(self)
        if not self.entry and not self.itemId then
            return
        end
        local entry = self.entry or { itemId = self.itemId }
        if GQ.Data and GQ.Data.ShowEntryItemTooltip then
            GQ.Data:ShowEntryItemTooltip(GameTooltip, self, entry, "ANCHOR_RIGHT")
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemId)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        HideItemTooltip()
    end)

    button:SetScript("OnClick", function(self)
        local entry = self.entry or (self.itemId and { itemId = self.itemId })
        if entry and TryHandleModifiedItemClick(entry) then
            HideItemTooltip()
        end
    end)

    return button
end

local function CreateFontStringWithFallback(parent, candidates)
    local fs
    for _, font in ipairs(candidates) do
        local ok, created = pcall(parent.CreateFontString, parent, nil, "ARTWORK", font)
        if ok and created then
            fs = created
            break
        end
    end
    fs = fs or parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- Keep the inherited size, but always use Friz so spaces actually draw.
    local path, _, flags = GameFontNormal:GetFont()
    if path and fs.GetFont and fs.SetFont then
        local _, size = fs:GetFont()
        fs:SetFont(path, size or 13, flags or "")
    end
    return fs
end

local PARCHMENT_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Textures\\GQ-Parchment.png"

local function ApplyParchmentBackground(parent)
    if parent.parchmentApplied then
        return
    end
    parent.parchmentApplied = true

    local parchment = parent:CreateTexture(nil, "BACKGROUND", nil, 0)
    parchment:SetTexture(PARCHMENT_TEXTURE)
    parchment:SetAllPoints()
    -- Stretch once so clean top/left and worn bottom/right stay anchored to the panel.
end

local function ApplyFill(parent, color)
    if not parent.blackBg then
        local bg = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        parent.blackBg = bg
    end
    parent.blackBg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function ApplyBlackBackground(parent)
    ApplyFill(parent, LIST_BG)
end

local function ApplyPanelBackground(parent)
    ApplyFill(parent, PANEL_BG)
end

local function EnsureBackdrop(frame)
    if not frame then
        return false
    end
    if frame.SetBackdrop then
        return true
    end
    if Mixin and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropLoaded then
            pcall(frame.OnBackdropLoaded, frame)
        end
    end
    return frame.SetBackdrop ~= nil
end

local function ApplyDrawnGoldBorder(frame)
    if frame.gqBorderTop then
        return
    end
    local function makeEdge()
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.95)
        return tex
    end
    frame.gqBorderTop = makeEdge()
    frame.gqBorderTop:SetHeight(1)
    frame.gqBorderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.gqBorderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.gqBorderBottom = makeEdge()
    frame.gqBorderBottom:SetHeight(1)
    frame.gqBorderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.gqBorderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.gqBorderLeft = makeEdge()
    frame.gqBorderLeft:SetWidth(1)
    frame.gqBorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.gqBorderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.gqBorderRight = makeEdge()
    frame.gqBorderRight:SetWidth(1)
    frame.gqBorderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.gqBorderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

local function ApplyMetalEdge(frame, edgeSize)
    if not frame then
        return
    end
    if not EnsureBackdrop(frame) then
        ApplyDrawnGoldBorder(frame)
        return
    end
    frame:SetBackdrop({
        edgeFile = METAL_EDGE,
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize or 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    end
end

local function HideRegion(obj)
    if obj and obj.Hide then
        obj:Hide()
    end
end

local SetupQuestLogPortrait

local function HideDefaultFrameArt(frame)
    if not frame then
        return
    end

    -- Keep PortraitFrame metal (NineSlice) and the circular portrait well.
    -- Strip only interior fills so the panel can be tinted warmer.
    for _, key in ipairs({
        "Bg", "TitleBg", "TopTileStreaks", "Inset",
    }) do
        HideRegion(frame[key])
    end

    local name = frame.GetName and frame:GetName()
    if name then
        for _, suffix in ipairs({
            "TitleBg", "Bg", "TopTileStreaks", "Inset",
        }) do
            HideRegion(_G[name .. suffix])
        end
    end

    if frame.gqBookIcon then
        frame.gqBookIcon:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end
    if frame.gqOuterBorder then
        frame.gqOuterBorder:Hide()
    end
end

local PORTRAIT_NINESLICE_LAYOUTS = {
    "PortraitFrameTemplate",
    "PortraitFrameTemplateMinimizable",
}

local function HideNineSliceCenter(container)
    if container and container.Center then
        container.Center:SetAlpha(0)
        HideRegion(container.Center)
    end
end

local function TryApplyPortraitFrameLayout(container)
    if not container or not NineSliceUtil then
        return false
    end
    local apply = NineSliceUtil.ApplyLayout
    local applyByName = NineSliceUtil.ApplyLayoutByName
    if not apply and not applyByName then
        return false
    end

    for _, layoutName in ipairs(PORTRAIT_NINESLICE_LAYOUTS) do
        if applyByName then
            local ok = pcall(applyByName, container, layoutName)
            if ok then
                HideNineSliceCenter(container)
                return true
            end
        end
        if apply and NineSliceLayouts and NineSliceLayouts[layoutName] then
            local ok = pcall(apply, container, NineSliceLayouts[layoutName])
            if ok then
                HideNineSliceCenter(container)
                return true
            end
        end
    end
    return false
end

local function GetFrameTitle(frame)
    if frame.TitleContainer and frame.TitleContainer.TitleText then
        return frame.TitleContainer.TitleText
    end
    if frame.TitleText then
        return frame.TitleText
    end
    local name = frame.GetName and frame:GetName()
    return name and _G[name .. "TitleText"] or nil
end

local function GetFrameCloseButton(frame)
    if frame.CloseButton then
        return frame.CloseButton
    end
    local name = frame.GetName and frame:GetName()
    return name and _G[name .. "CloseButton"] or nil
end

local function ApplyOuterWindowBorder(frame)
    if not frame then
        return
    end

    if frame.gqOuterBorder then
        frame.gqOuterBorder:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end

    local ns = frame.NineSlice
    local hasMetal = false
    if ns then
        ns:Show()
        ns:SetFrameLevel((frame:GetFrameLevel() or 1) + 2)
        TryApplyPortraitFrameLayout(ns)
        HideNineSliceCenter(ns)
        hasMetal = ns.TopLeftCorner or ns.TopEdge or ns.LeftEdge
    else
        hasMetal = TryApplyPortraitFrameLayout(frame)
        HideNineSliceCenter(frame)
    end

    if not hasMetal then
        if not frame.gqOuterBorder then
            local ok, created = pcall(CreateFrame, "Frame", nil, frame, "BackdropTemplate")
            frame.gqOuterBorder = (ok and created) or CreateFrame("Frame", nil, frame)
            frame.gqOuterBorder:SetAllPoints(frame)
            frame.gqOuterBorder:EnableMouse(false)
        end
        frame.gqOuterBorder:Show()
        frame.gqOuterBorder:SetFrameLevel((frame:GetFrameLevel() or 1) + 2)
        ApplyMetalEdge(frame.gqOuterBorder, 16)
    end

    if frame.OverlayElements and frame.OverlayElements.Show then
        frame.OverlayElements:Show()
    end

    local close = GetFrameCloseButton(frame)
    if close then
        close:SetParent(frame)
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
        if close.SetFrameLevel then
            close:SetFrameLevel((frame:GetFrameLevel() or 1) + 10)
        end
        close:Show()
    end
end

local function ApplyModernChrome(frame)
    if not frame then
        return
    end

    HideDefaultFrameArt(frame)
    ApplyPanelBackground(frame)
    ApplyOuterWindowBorder(frame)
    if SetupQuestLogPortrait then
        SetupQuestLogPortrait(frame)
    end

    local title = GetFrameTitle(frame)
    if frame.TitleContainer then
        frame.TitleContainer:Show()
        frame.TitleContainer:ClearAllPoints()
        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 58, -1)
        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -1)
        frame.TitleContainer:SetHeight(22)
    end
    if title then
        if frame.TitleContainer then
            title:SetParent(frame.TitleContainer)
            title:ClearAllPoints()
            title:SetPoint("CENTER", frame.TitleContainer, "CENTER", 0, 0)
        else
            title:SetParent(frame)
            title:ClearAllPoints()
            title:SetPoint("TOP", frame, "TOP", 0, -12)
        end
        if title.SetJustifyH then
            title:SetJustifyH("CENTER")
        end
        title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        title:Show()
    end

    if frame.gqHeaderLine then
        frame.gqHeaderLine:Hide()
    end
end

local function StripDefaultButtonArt(btn)
    if not btn then
        return
    end
    local getters = {
        btn.GetNormalTexture,
        btn.GetPushedTexture,
        btn.GetHighlightTexture,
        btn.GetDisabledTexture,
    }
    for _, getter in ipairs(getters) do
        if getter then
            HideRegion(getter(btn))
        end
    end
    local name = btn.GetName and btn:GetName()
    if name then
        for _, part in ipairs({
            "Left", "Middle", "Right",
            "LeftDisabled", "MiddleDisabled", "RightDisabled",
            "HighlightLeft", "HighlightMiddle", "HighlightRight",
        }) do
            HideRegion(_G[name .. part])
        end
    end
end

local function BackdropFrameTemplate()
    if BackdropTemplateMixin then
        return "BackdropTemplate"
    end
    return nil
end

local function HideTabEdges(btn)
    if not btn then
        return
    end
    for _, key in ipairs({ "gqEdgeTop", "gqEdgeBottom", "gqEdgeLeft", "gqEdgeRight" }) do
        if btn[key] then
            btn[key]:Hide()
        end
    end
end

local function EnsureTabChrome(btn)
    if not btn then
        return
    end
    if not btn.gqFill then
        btn.gqFill = btn:CreateTexture(nil, "BACKGROUND")
        btn.gqFill:SetAllPoints()
    end
    if not btn.gqOpenCover then
        local cover = btn:CreateTexture(nil, "OVERLAY")
        cover:SetDrawLayer("OVERLAY", 7)
        btn.gqOpenCover = cover
    end
    HideTabEdges(btn)
end

local function LayoutOpenCover(btn, opts, fill, edgeSize)
    local cover = btn.gqOpenCover
    if not cover then
        return
    end
    cover:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    cover:ClearAllPoints()
    local coverSize = math.max(3, math.floor(edgeSize * 0.7))
    if opts.hideLeft then
        cover:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        cover:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        cover:SetWidth(coverSize)
        cover:Show()
    elseif opts.hideBottom then
        cover:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        cover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        cover:SetHeight(coverSize)
        cover:Show()
    else
        cover:Hide()
    end
end

local function LayoutTabChrome(btn, opts)
    if not btn then
        return
    end

    EnsureTabChrome(btn)
    opts = opts or {}
    local fill = opts.fill or LIST_BG
    local border = opts.border or GOLD
    local edgeSize = opts.edgeSize or TAB_BORDER_EDGE
    local thick = opts.thick or 1

    if EnsureBackdrop(btn) then
        if btn.gqFill then
            btn.gqFill:Hide()
        end
        HideTabEdges(btn)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = METAL_EDGE,
            tile = true,
            tileSize = 8,
            edgeSize = edgeSize,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        if btn.SetBackdropColor then
            btn:SetBackdropColor(fill[1], fill[2], fill[3], fill[4] or 1)
        end
        if btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        end
        LayoutOpenCover(btn, opts, fill, edgeSize)
        return
    end

    if btn.gqFill then
        btn.gqFill:Show()
        btn.gqFill:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 1)
    end

    local function ensureEdge(key)
        if not btn[key] then
            btn[key] = btn:CreateTexture(nil, "OVERLAY")
        end
        return btn[key]
    end

    local function paint(edge, shown)
        if not edge then
            return
        end
        edge:SetColorTexture(border[1], border[2], border[3], border[4] or 1)
        if shown then
            edge:Show()
        else
            edge:Hide()
        end
    end

    local top = ensureEdge("gqEdgeTop")
    top:ClearAllPoints()
    top:SetHeight(thick)
    top:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    paint(top, not opts.hideTop)

    local bottom = ensureEdge("gqEdgeBottom")
    bottom:ClearAllPoints()
    bottom:SetHeight(thick)
    bottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    paint(bottom, not opts.hideBottom)

    local left = ensureEdge("gqEdgeLeft")
    left:ClearAllPoints()
    left:SetWidth(thick)
    left:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    paint(left, not opts.hideLeft)

    local right = ensureEdge("gqEdgeRight")
    right:ClearAllPoints()
    right:SetWidth(thick)
    right:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    paint(right, not opts.hideRight)

    LayoutOpenCover(btn, opts, fill, thick + 2)
end

local function StyleGoldTab(btn, selected)
    if not btn then
        return
    end

    StripDefaultButtonArt(btn)
    btn:EnableMouse(true)
    if btn.SetEnabled then
        btn:SetEnabled(true)
    end

    if btn.gqTabBg then
        btn.gqTabBg:Hide()
    end
    if btn.gqTabTop then
        btn.gqTabTop:Hide()
    end
    if btn.gqTabBottom then
        btn.gqTabBottom:Hide()
    end

    local fs = btn:GetFontString()
    if not fs then
        fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER")
        btn:SetFontString(fs)
    end
    fs:Show()

    if selected then
        btn:SetHeight(TAB_HEIGHT)
        LayoutTabChrome(btn, {
            fill = LIST_BG,
            border = GOLD,
            hideBottom = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    else
        btn:SetHeight(TAB_HEIGHT)
        LayoutTabChrome(btn, {
            fill = { 0.05, 0.05, 0.05, 1 },
            border = GOLD_DIM,
            hideBottom = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        fs:SetTextColor(GOLD_DIM[1], GOLD_DIM[2], GOLD_DIM[3])
    end
end

local function CreateGoldTab(parent, name, label, width)
    local btn = CreateFrame("Button", name, parent, BackdropFrameTemplate())
    btn:SetSize(width, TAB_HEIGHT)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    btn:SetFontString(fs)
    StyleGoldTab(btn, false)
    return btn
end

local function StyleHandleTab(btn, selected)
    if not btn then
        return
    end

    StripDefaultButtonArt(btn)
    btn:EnableMouse(true)
    if btn.SetEnabled then
        btn:SetEnabled(true)
    end
    btn:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)

    local fs = btn:GetFontString()
    if fs then
        fs:Hide()
    end
    if btn.gqTabBg then
        btn.gqTabBg:Hide()
    end
    if btn.gqTabTop then
        btn.gqTabTop:Hide()
    end
    if btn.gqTabBottom then
        btn.gqTabBottom:Hide()
    end
    if btn.gqTabRight then
        btn.gqTabRight:Hide()
    end

    if btn.gqMetalHost then
        btn.gqMetalHost:Hide()
    end
    if btn.gqHandleFill then
        btn.gqHandleFill:Hide()
    end
    for _, key in ipairs({
        "gqMetalTL", "gqMetalTR", "gqMetalBL", "gqMetalBR",
        "gqMetalTop", "gqMetalBottom", "gqMetalLeft", "gqMetalRight",
    }) do
        if btn[key] then
            btn[key]:Hide()
        end
    end

    if not btn.gqIcon then
        btn.gqIcon = btn:CreateTexture(nil, "OVERLAY")
    end
    btn.gqIcon:SetDrawLayer("OVERLAY", 6)
    btn.gqIcon:ClearAllPoints()
    btn.gqIcon:SetSize(SIDE_TAB_ICON_SIZE, SIDE_TAB_ICON_SIZE)
    btn.gqIcon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    if btn.gqIconPath then
        btn.gqIcon:SetTexture(btn.gqIconPath)
    end
    btn.gqIcon:Show()

    if selected then
        LayoutTabChrome(btn, {
            fill = PANEL_BG,
            border = FRAME_METAL,
            hideLeft = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        btn.gqIcon:SetVertexColor(1, 1, 1, 1)
    else
        LayoutTabChrome(btn, {
            fill = { 0.05, 0.04, 0.03, 1 },
            border = FRAME_METAL,
            hideLeft = true,
            edgeSize = FILTER_BORDER_EDGE,
        })
        btn.gqIcon:SetVertexColor(0.55, 0.50, 0.42, 1)
    end
end

local function CreateHandleTab(parent, name, label, iconPath)
    local btn = CreateFrame("Button", name, parent, BackdropFrameTemplate())
    btn:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
    btn.gqLabel = label
    btn.gqIconPath = iconPath
    StyleHandleTab(btn, false)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.gqLabel or "", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return btn
end

local function GetScrollRange(scroll)
    if not scroll then
        return 0
    end
    if scroll.GetVerticalScrollRange then
        local range = scroll:GetVerticalScrollRange()
        if range and range > 0 then
            return range
        end
    end
    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if bar and bar.GetMinMaxValues then
        local minVal, maxVal = bar:GetMinMaxValues()
        return math.max(0, (maxVal or 0) - (minVal or 0))
    end
    return 0
end

local function ScrollFrameOnMouseWheel(scroll, delta)
    if not scroll or not scroll.IsShown or not scroll:IsShown() then
        return
    end

    local range = GetScrollRange(scroll)
    if not range or range <= 0 then
        return
    end

    local current = 0
    if scroll.GetVerticalScroll then
        current = scroll:GetVerticalScroll() or 0
    end
    local dest = current - (delta * WHEEL_STEP)
    if dest < 0 then
        dest = 0
    elseif dest > range then
        dest = range
    end

    if scroll.SetVerticalScroll then
        scroll:SetVerticalScroll(dest)
    end

    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if bar and bar.SetValue then
        bar:SetValue(dest)
    end
end

local function ApplyScrollBarVisibility(scroll)
    if not scroll then
        return
    end
    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scroll.ScrollBar or (scrollName and _G[scrollName .. "ScrollBar"])
    if not bar then
        return
    end
    if GetScrollRange(scroll) > 0 then
        bar:Show()
    else
        if scroll.SetVerticalScroll then
            scroll:SetVerticalScroll(0)
        end
        if bar.SetValue then
            bar:SetValue(0)
        end
        bar:Hide()
    end
end

local function WireLogWindowMouseWheel(frame)
    if not frame or not frame.EnableMouseWheel then
        return
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log or log:GetPageTab() ~= "log" then
            return
        end
        if self.detailBg and self.detailBg.IsMouseOver and self.detailBg:IsMouseOver() then
            ScrollFrameOnMouseWheel(self.detailScroll, delta)
        else
            ScrollFrameOnMouseWheel(self.scroll, delta)
        end
    end)
end

local function WireMouseWheel(frame, scroll)
    if not frame or not scroll or not frame.EnableMouseWheel then
        return
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        ScrollFrameOnMouseWheel(scroll, delta)
    end)
end

local function LayoutColumnScroll(scroll, host)
    if not scroll or not host then
        return
    end

    scroll:SetParent(host)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", host, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -(PANEL_INSET + SCROLLBAR_WIDTH + 6), PANEL_INSET)

    local scrollName = scroll.GetName and scroll:GetName()
    local bar = scrollName and _G[scrollName .. "ScrollBar"]
    if bar then
        if bar.gqTrackBg then
            bar.gqTrackBg:Hide()
        end
        -- Keep the bar parented to the scroll frame so UIPanelScrollBar OnValueChanged works.
        if bar.SetFrameLevel then
            bar:SetFrameLevel(scroll:GetFrameLevel() + 5)
        end
        ApplyScrollBarVisibility(scroll)
    end

    if scrollName then
        for _, suffix in ipairs({ "Top", "Bottom", "Middle" }) do
            local tex = _G[scrollName .. suffix]
            if tex and tex.Show then
                tex:Show()
            end
        end
    end

    WireMouseWheel(scroll, scroll)
    WireMouseWheel(host, scroll)
    if scroll.GetScrollChild then
        WireMouseWheel(scroll:GetScrollChild(), scroll)
    end
end

local function CreateSectionDivider(parent)
    local divider = CreateFrame("Frame", nil, parent)
    divider:SetHeight(SECTION_DIVIDER_HEIGHT)

    local top = divider:CreateTexture(nil, "ARTWORK")
    top:SetPoint("TOPLEFT", divider, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", divider, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(0.62, 0.54, 0.36, 1)

    local bottom = divider:CreateTexture(nil, "ARTWORK")
    bottom:SetPoint("BOTTOMLEFT", divider, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", divider, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(0.22, 0.19, 0.14, 1)

    return divider
end

local function EnableClipping(frame)
    if frame and frame.SetClipsChildren then
        frame:SetClipsChildren(true)
    end
end

local function ConfigurePanelScrollBar(scroll)
    if not scroll or not scroll.GetName then
        return
    end

    local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
    if scrollBar then
        if scrollBar.gqTrackBg then
            scrollBar.gqTrackBg:Hide()
        end
        scrollBar:Show()
    end
end

local function LayoutDetailScroll(frame)
    if not frame or not frame.detailScroll or not frame.detailBg then
        return
    end

    LayoutColumnScroll(frame.detailScroll, frame.detailBg)
    local log = _G.GearQuest and _G.GearQuest.Log
    if log and log.GetPageTab and log:GetPageTab() == "simulator" then
        frame.detailScroll:Hide()
        local bar = frame.detailScroll.GetName and _G[frame.detailScroll:GetName() .. "ScrollBar"]
        if bar then
            bar:Hide()
        end
    else
        frame.detailScroll:Show()
    end
end

local function CreatePanelScrollFrame(name, parent)
    local scrollOk, scroll = pcall(CreateFrame, "ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    if not scrollOk or not scroll then
        scroll = CreateFrame("ScrollFrame", name, parent)
    end

    return scroll
end

local function UpdateScrollChildRect(scroll)
    if not scroll then
        return
    end
    if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    elseif _G.ScrollFrame_UpdateScrollChildRect then
        ScrollFrame_UpdateScrollChildRect(scroll)
    end
end

local function SetFrameTitle(frame, text)
    if frame.TitleText then
        frame.TitleText:SetText(text)
        return
    end
    local title = frame:GetName() and _G[frame:GetName() .. "TitleText"]
    if title then
        title:SetText(text)
    end
end

local function GetPortraitTexture(frame)
    if not frame then
        return nil
    end

    if frame.portrait then
        return frame.portrait
    end
    local container = frame.PortraitContainer or (frame.GetName and _G[frame:GetName() .. "PortraitContainer"])
    if container and container.portrait then
        return container.portrait
    end
    if container and container.GetName then
        local named = _G[container:GetName() .. "Portrait"]
        if named then
            return named
        end
    end

    if frame.GetName then
        return _G[frame:GetName() .. "Portrait"]
    end
    return nil
end

local CIRCLE_MASKS = {
    "Interface\\Masks\\CircleMaskScalable",
    "Interface\\CharacterFrame\\TempPortraitAlphaMask",
}

local function CollectPortraitMasks(tex, owner)
    local masks = {}
    local seen = {}
    local function add(mask)
        if mask and not seen[mask] then
            seen[mask] = true
            masks[#masks + 1] = mask
        end
    end
    if owner then
        add(owner.CircleMask)
    end
    add(tex.gqCircleMask)
    local okCount, count = pcall(function()
        return tex.GetNumMaskTextures and tex:GetNumMaskTextures()
    end)
    if okCount and count and tex.GetMaskTexture then
        for i = 1, count do
            local okMask, mask = pcall(tex.GetMaskTexture, tex, i)
            if okMask then
                add(mask)
            end
        end
    end
    return masks
end

local function ApplyCircleMask(tex, owner)
    if not tex then
        return
    end
    if owner and owner.CircleMask and tex.AddMaskTexture then
        pcall(tex.AddMaskTexture, tex, owner.CircleMask)
        return
    end
    if tex.gqCircleMask or (owner and owner.CircleMask) then
        return
    end
    if not owner or not owner.CreateMaskTexture then
        return
    end
    for _, maskPath in ipairs(CIRCLE_MASKS) do
        local mask = owner:CreateMaskTexture()
        mask:SetAllPoints(tex)
        if pcall(mask.SetTexture, mask, maskPath) then
            tex:AddMaskTexture(mask)
            tex.gqCircleMask = mask
            return
        end
        HideRegion(mask)
    end
end

local function ApplyPortraitTexture(tex, texturePath, owner)
    if not tex or not texturePath then
        return
    end

    owner = owner or (tex.GetParent and tex:GetParent())
    local masks = CollectPortraitMasks(tex, owner)
    if tex.RemoveMaskTexture then
        for _, mask in ipairs(masks) do
            pcall(tex.RemoveMaskTexture, tex, mask)
        end
    end

    tex:Show()
    tex:SetTexture(texturePath)
    -- WoW TGA rows are bottom-up; flip V so the portrait is right-side up.
    -- SetTexCoord is illegal while a mask is attached (PortraitFrame CircleMask).
    pcall(tex.SetTexCoord, tex, 0, 1, 1, 0)

    local restored = false
    if tex.AddMaskTexture then
        for _, mask in ipairs(masks) do
            if pcall(tex.AddMaskTexture, tex, mask) then
                restored = true
            end
        end
    end
    if not restored then
        ApplyCircleMask(tex, owner)
    end
end

local function EnsureFallbackPortraitIcon(frame, container)
    if frame.gqPortraitIcon and frame.gqPortraitHolder then
        return frame.gqPortraitIcon, frame.gqPortraitHolder
    end

    local parent = container or frame
    local holder = CreateFrame("Frame", nil, parent)
    local icon = holder:CreateTexture(nil, "ARTWORK")
    frame.gqPortraitHolder = holder
    frame.gqPortraitIcon = icon
    return icon, holder
end

local function PlacePortraitOnFrame(region, frame)
    region:ClearAllPoints()
    region:SetSize(PORTRAIT_DISPLAY_SIZE, PORTRAIT_DISPLAY_SIZE)
    region:SetPoint("TOPLEFT", frame, "TOPLEFT", PORTRAIT_OFFSET_X, PORTRAIT_OFFSET_Y)
    if region.SetFrameLevel and frame.GetFrameLevel then
        region:SetFrameLevel(frame:GetFrameLevel() + 8)
    end
    region:Show()
end

function SetupQuestLogPortrait(frame)
    if frame.gqBookIcon then
        frame.gqBookIcon:Hide()
    end
    if frame.gqHeaderBar then
        frame.gqHeaderBar:Hide()
    end

    local name = frame.GetName and frame:GetName()
    local container = frame.PortraitContainer or (name and _G[name .. "PortraitContainer"])
    if container then
        PlacePortraitOnFrame(container, frame)
    end

    if frame.portrait then
        frame.portrait:Show()
    end
    if name then
        local named = _G[name .. "Portrait"]
        if named and named.Show then
            named:Show()
        end
    end

    local tex = GetPortraitTexture(frame)
    if tex then
        if frame.gqPortraitHolder then
            frame.gqPortraitHolder:Hide()
        end
        if container then
            tex:ClearAllPoints()
            tex:SetAllPoints(container)
        else
            PlacePortraitOnFrame(tex, frame)
        end
        ApplyPortraitTexture(tex, PORTRAIT_TEXTURE, container or frame)
        return
    end

    local icon, holder = EnsureFallbackPortraitIcon(frame, frame)
    if holder:GetParent() ~= frame then
        holder:SetParent(frame)
    end
    PlacePortraitOnFrame(holder, frame)
    icon:ClearAllPoints()
    icon:SetAllPoints(holder)
    ApplyPortraitTexture(icon, PORTRAIT_TEXTURE, holder)
    holder:Show()
end

function GQ.Log:GetListTab()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    return GearQuestForeverDB.ui.listTab or "active"
end

function GQ.Log:SetListTab(tab)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.listTab = tab
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    self:Refresh()
end

function GQ.Log:GetPageTab()
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    return GearQuestForeverDB.ui.pageTab or "log"
end

function GQ.Log:SetPageTab(tab)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.pageTab = tab or "log"
    self:HideSpecPicker()
    self:ApplyPageTab()
    if self:GetPageTab() == "simulator" then
        self:RefreshSimulator()
    else
        self:Refresh()
    end
end

function GQ.Log:EntryMatchesTrackedHunt(entry)
    if not entry then
        return false
    end

    local classFile = GQ:GetEffectiveClass()
    if entry.classes and not entry.classes[classFile] then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    if GQ.Equip and GQ.Equip.EntryMatchesSpec and not GQ.Equip:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Log:IsSlotCollapsed(slotName, cachedUpgrades)
    slotName = GQ.Data:NormalizeSlotName(slotName)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.collapsedSlots = GearQuestForeverDB.ui.collapsedSlots or {}

    if GearQuestForeverDB.ui.collapsedSlots[slotName] ~= nil then
        return GearQuestForeverDB.ui.collapsedSlots[slotName]
    end

    -- Migrate saved collapse state from old duplicate categories.
    if slotName == "Finger" then
        for _, legacy in ipairs({ "Finger0", "Finger1" }) do
            if GearQuestForeverDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestForeverDB.ui.collapsedSlots[legacy]
            end
        end
    elseif slotName == "Trinket" then
        for _, legacy in ipairs({ "Trinket0", "Trinket1" }) do
            if GearQuestForeverDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestForeverDB.ui.collapsedSlots[legacy]
            end
        end
    end

    if cachedUpgrades ~= nil then
        return #cachedUpgrades == 0
    end

    local upgrades = GQ.Data:GetTopUpgradesForSlot(slotName, 1)
    return #upgrades == 0 and #self:GetActiveSlotListEntries(slotName) == 0
end

function GQ.Log:SetSlotCollapsed(slotName, collapsed)
    slotName = GQ.Data:NormalizeSlotName(slotName)
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    GearQuestForeverDB.ui.collapsedSlots = GearQuestForeverDB.ui.collapsedSlots or {}
    GearQuestForeverDB.ui.collapsedSlots[slotName] = collapsed
end

function GQ.Log:ToggleSlotCollapsed(slotName)
    self:SetSlotCollapsed(slotName, not self:IsSlotCollapsed(slotName))
    self:Refresh()
end

function GQ.Log:GetActiveSlotListEntries(slotName)
    local results = {}
    local seenId = {}
    local seenItem = {}
    local notableCount = 0
    local MAX_NOTABLES_PER_SLOT = 1

    local function addEntry(entry, allowNotable)
        if not entry or not entry.id or seenId[entry.id] or self:IsEntryObtained(entry.id) then
            return false
        end

        local itemKey = GQ.Data:EntryListKey(entry)
        if itemKey and seenItem[itemKey] then
            return false
        end

        if allowNotable then
            if notableCount >= MAX_NOTABLES_PER_SLOT then
                return false
            end
            notableCount = notableCount + 1
        end

        seenId[entry.id] = true
        if itemKey then
            seenItem[itemKey] = true
        end
        results[#results + 1] = entry
        return true
    end

    for _, entry in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName)) do
        addEntry(entry, false)
    end

    for _, entry in ipairs(GQ.Data:GetNotableForSlot(slotName)) do
        addEntry(entry, true)
    end

    for id, record in pairs(GearQuestForeverDB.hunts or {}) do
        if not seenId[id] and NormalizeHuntStatus(record.status) == "tracked" and not self:IsEntryObtained(id) then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                and GQ.Data:EntryMatchesPlayer(entry)
                and self:EntryMatchesTrackedHunt(entry) then
                addEntry(entry, entry.notable == true)
            end
        end
    end

    return results
end

function GQ.Log:GetCompletedSlotListEntries(slotName)
    local results = {}
    local seen = {}

    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    for id, obtainedAt in pairs(GearQuestForeverDB.obtained) do
        if not IsDismissedCompleted(id) then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                and self:EntryMatchesTrackedHunt(entry) then
                seen[id] = true
                table.insert(results, {
                    entry = entry,
                    completedAt = obtainedAt or 0,
                })
            end
        end
    end

    for id, record in pairs(GearQuestForeverDB.hunts or {}) do
        if not seen[id] and not IsDismissedCompleted(id) and NormalizeHuntStatus(record.status) == "completed" then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                and self:EntryMatchesTrackedHunt(entry) then
                seen[id] = true
                table.insert(results, {
                    entry = entry,
                    completedAt = record.completedAt or record.trackedAt or 0,
                })
            end
        end
    end

    -- Best BiS first; acquisition time breaks ties between equal power.
    local equippedIlvl = GQ.Compare:GetEquippedItemLevel(slotName)
    table.sort(results, function(a, b)
        local scoreA = GQ.Compare:GetSortScore(a.entry, slotName, equippedIlvl, 0)
        local scoreB = GQ.Compare:GetSortScore(b.entry, slotName, equippedIlvl, 0)
        if scoreA ~= scoreB then
            return scoreA > scoreB
        end
        if a.completedAt ~= b.completedAt then
            return a.completedAt > b.completedAt
        end
        return a.entry.id < b.entry.id
    end)

    local entries = {}
    for _, row in ipairs(results) do
        table.insert(entries, row.entry)
    end

    return entries
end

-- Backwards-compatible alias
function GQ.Log:GetSlotListEntries(slotName)
    if self:GetListTab() == "completed" then
        return self:GetCompletedSlotListEntries(slotName)
    end
    return self:GetActiveSlotListEntries(slotName)
end

function GQ.Log:TrackHunt(id)
    local entry = GQ.Data:GetEntryById(id)
    if not entry then
        return
    end

    local record = EnsureHuntRecord(id)
    record.status = "tracked"
    record.trackedAt = time()
    self:CheckAutoCompletion()
    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:ActivateHunt(id)
    self:TrackHunt(id)
end

function GQ.Log:RecordCraftedItem(itemId)
    if not itemId then
        return false
    end

    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    if GearQuestForeverDB.crafted[itemId] then
        return false
    end

    GearQuestForeverDB.crafted[itemId] = time()
    return true
end

function GQ.Log:HandleCraftChatMessage(msg)
    local itemId = ExtractItemIdFromChatMessage(msg)
    if not itemId then
        return
    end

    if self:RecordCraftedItem(itemId) then
        self:ScheduleAutoCompletionCheck()
    end
end

function GQ.Log:HasObtainedItemId(itemId)
    if not itemId then
        return false
    end
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    return GearQuestForeverDB.obtainedItems[itemId]
        or GearQuestForeverDB.obtainedItems[tostring(itemId)]
end

function GQ.Log:IsEntryObtained(id)
    if not id then
        return false
    end
    if GetObtainedTimestamp(id) then
        return true
    end
    local record = GetHuntRecord(id)
    if record and NormalizeHuntStatus(record.status) == "completed" then
        return true
    end
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if entry and self:HasObtainedItemId(entry.itemId) then
        return true
    end
    return false
end

function GQ.Log:IsItemIdObtained(itemId)
    if not itemId then
        return false
    end
    if self:HasObtainedItemId(itemId) then
        return true
    end

    for _, entry in ipairs(GQ.Data:GetEntriesByItemId(itemId)) do
        if GQ.Data:EntryMatchesPlayer(entry) and GetObtainedTimestamp(entry.id) then
            return true
        end
        local record = GetHuntRecord(entry.id)
        if GQ.Data:EntryMatchesPlayer(entry) and record and NormalizeHuntStatus(record.status) == "completed" then
            return true
        end
    end

    return false
end

function GQ.Log:ShouldAutoCompleteOnObtain(entry)
    if not entry or self:IsEntryObtained(entry.id) or self:HasObtainedItemId(entry.itemId) then
        return false
    end

    if GetHuntStatus(entry.id) == "tracked" then
        return true
    end

    local slotName = GQ.Data:NormalizeSlotName(entry.slot)
    for _, upgrade in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName)) do
        if upgrade.id == entry.id then
            return true
        end
    end

    return false
end

function GQ.Log:RememberObtainedEntry(entry, now)
    if not entry or not entry.id then
        return
    end

    now = now or time()
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.hunts = GearQuestForeverDB.hunts or {}

    GearQuestForeverDB.obtained[entry.id] = GearQuestForeverDB.obtained[entry.id] or now
    if entry.itemId then
        GearQuestForeverDB.obtainedItems[tostring(entry.itemId)] = GearQuestForeverDB.obtainedItems[tostring(entry.itemId)] or now
    end

    local record = GetHuntRecord(entry.id) or {}
    record.status = "completed"
    record.completedAt = record.completedAt or now
    record.obtained = true
    GearQuestForeverDB.hunts[entry.id] = record
end

function GQ.Log:MarkEntryObtained(entry, options)
    if not entry or not entry.id or self:IsEntryObtained(entry.id) then
        return false
    end

    local now = time()
    local alreadyHadItem = self:HasObtainedItemId(entry.itemId)
        or (entry.itemId and self.ownedAtLogin and self.ownedAtLogin[entry.itemId])
    self:RememberObtainedEntry(entry, now)

    if entry.itemId and GQ.Data and GQ.Data.GetEntriesByItemId then
        for _, sibling in ipairs(GQ.Data:GetEntriesByItemId(entry.itemId)) do
            if sibling and sibling.id then
                self:RememberObtainedEntry(sibling, now)
            end
        end
    end

    local announce = not options or (options.showToast ~= false and options.announce ~= false)
    if announce and not alreadyHadItem and self.obtainToastsEnabled then
        if GQ.Toast then
            GQ.Toast:ShowForEntry(entry)
        end
        local itemName = (GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry))
            or ("Item " .. tostring(entry.itemId))
        if entry.sourceType == "profession" then
            print("|cff66ccffGearQuest|r: Completed — " .. itemName .. " crafted.")
        else
            print("|cff66ccffGearQuest|r: Completed — " .. itemName .. " obtained.")
        end
    end

    return true
end

function GQ.Log:CompleteHunt(id)
    local entry = GQ.Data:GetEntryById(id)
    if entry then
        self:MarkEntryObtained(entry, { showToast = false })
    else
        local record = GetHuntRecord(id)
        if record then
            record.status = "completed"
            record.completedAt = time()
            GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
            GearQuestForeverDB.obtained[id] = record.completedAt
        end
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:WillHuntDisappearFromActiveList(id)
    if self:GetListTab() ~= "active" then
        return false
    end

    local record = GetHuntRecord(id)
    if not record or NormalizeHuntStatus(record.status) ~= "tracked" then
        return false
    end

    local entry = GQ.Data:GetEntryById(id)
    if not entry or not entry.slot then
        return false
    end

    local slotName = GQ.Data:NormalizeSlotName(entry.slot)
    for _, upgrade in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName)) do
        if upgrade.id == id then
            return false
        end
    end

    return true
end

function GQ.Log:EnsureUntrackConfirmDialog()
    if self.untrackDialogRegistered then
        return
    end
    self.untrackDialogRegistered = true

    StaticPopupDialogs["GEARQUEST_CONFIRM_UNTRACK"] = {
        text = "Are you sure you want to untrack this gear quest? It will become unavailable once you do",
        button1 = "Agree",
        button2 = "Cancel",
        OnAccept = function(dialog)
            local id = dialog.data
            if id and GQ.Log then
                GQ.Log:UntrackHunt(id)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = 1,
        preferredIndex = 3,
    }
end

function GQ.Log:RequestUntrackHunt(id)
    if not id then
        return
    end

    self:EnsureUntrackConfirmDialog()

    if self:WillHuntDisappearFromActiveList(id) then
        StaticPopup_Show("GEARQUEST_CONFIRM_UNTRACK", nil, nil, id)
        return
    end

    self:UntrackHunt(id)
end

function GQ.Log:UntrackHunt(id)
    local willDisappear = self:WillHuntDisappearFromActiveList(id)
    local onCompletedTab = self:GetListTab() == "completed"

    if self:IsEntryObtained(id) and onCompletedTab then
        GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
        GearQuestForeverDB.dismissedCompleted[id] = true
    end

    GearQuestForeverDB.hunts[id] = nil

    if self.selectedHuntId == id and (willDisappear or onCompletedTab) then
        self.selectedHuntId = nil
    self.selectedEntry = nil
        self:ClearDetail()
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
end

function GQ.Log:AbandonHunt(id)
    self:RequestUntrackHunt(id)
end

function GQ.Log:WipeCharacterData()
    GearQuestForeverDB.hunts = {}
    GearQuestForeverDB.obtained = {}
    GearQuestForeverDB.obtainedItems = {}
    GearQuestForeverDB.crafted = {}
    GearQuestForeverDB.dismissedCompleted = {}
    self.ownedAtLogin = {}

    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    self:SetListTab("active")

    if GQ.Toast and GQ.Toast.ClearQueue then
        GQ.Toast:ClearQueue()
    end

    self:Refresh()
    if GQ.Tracker then
        GQ.Tracker:Refresh()
    end
    if GQ.RefreshUI then
        GQ:RefreshUI()
    end
end

function GQ.Log:CollectAutoCompletionCandidates()
    local seen = {}
    local candidates = {}

    local function add(entry)
        if entry and entry.id and not seen[entry.id]
            and not self:IsEntryObtained(entry.id)
            and not self:HasObtainedItemId(entry.itemId) then
            seen[entry.id] = true
            table.insert(candidates, entry)
        end
    end

    for id, record in pairs(GearQuestForeverDB.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "tracked" then
            add(GQ.Data:GetEntryById(id))
        end
    end

    local classFile = GQ:GetEffectiveClass()
    if classFile and GQ.Data.GetSlotsForClass then
        for _, slotName in ipairs(GQ.Data:GetSlotsForClass(classFile)) do
            for _, entry in ipairs(GQ.Data:GetTopUpgradesForSlot(slotName)) do
                add(entry)
            end
        end
    end

    return candidates
end

function GQ.Log:CheckAutoCompletion()
    local changed = false

    local ok, err = pcall(function()
        for _, entry in ipairs(self:CollectAutoCompletionCandidates()) do
            if entry
                and GQ.Data:EntryMatchesPlayer(entry)
                and self:ShouldAutoCompleteOnObtain(entry)
                and PlayerHasObtainedEntryItem(entry)
            then
                if self:MarkEntryObtained(entry) then
                    changed = true
                end
            end
        end
    end)

    if not ok then
        print("|cffff0000GearQuest auto-complete error:|r " .. tostring(err))
        return
    end

    if changed then
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end

        if GQ.Tracker then
            GQ.Tracker:Refresh()
        end

        if GQ and GQ.RefreshUI then
            GQ:RefreshUI()
        end
    end
end

function GQ.Log:ScheduleListRefresh()
    if not C_Timer or not C_Timer.After then
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end
        return
    end

    if self._listRefreshScheduled then
        return
    end
    self._listRefreshScheduled = true
    C_Timer.After(0.15, function()
        self._listRefreshScheduled = false
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end
    end)
end

function GQ.Log:UnionOwnedAtLogin()
    self.ownedAtLogin = self.ownedAtLogin or {}

    local function add(link)
        local id = ItemLinkToId(link)
        if id then
            self.ownedAtLogin[id] = true
        end
    end

    pcall(function()
        for invSlot = 1, 19 do
            add(GetInventoryItemLink("player", invSlot))
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots = GetBagSlotCount(bag)
            for slot = 1, numSlots do
                add(GetBagItemLink(bag, slot))
            end
        end
    end)
end

function GQ.Log:BeginLoginObtainScan()
    self.obtainToastsEnabled = false
    self:UnionOwnedAtLogin()
    self:ScheduleAutoCompletionCheck()

    if self.loginObtainScanTimer then
        return
    end
    self.loginObtainScanTimer = true
    if C_Timer and C_Timer.After then
        C_Timer.After(2.5, function()
            local log = GQ.Log
            if not log then
                return
            end
            log:UnionOwnedAtLogin()
            log.completionPending = false
            log:CheckAutoCompletion()
            log.obtainToastsEnabled = true
        end)
    else
        self.obtainToastsEnabled = true
    end
end

function GQ.Log:ScheduleAutoCompletionCheck()
    if self.completionPending then
        return
    end
    self.completionPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            GQ.Log.completionPending = false
            GQ.Log:CheckAutoCompletion()
        end)
    else
        self.completionPending = false
        self:CheckAutoCompletion()
    end
end

function GQ.Log:EnsureDetailLore(frame)
    if not frame or not frame.detailChild or frame.detailLore then
        return
    end

    frame.detailLore = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailLore:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -8)
    frame.detailLore:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailLore:SetJustifyH("LEFT")
    frame.detailLore:SetWordWrap(true)
    frame.detailLore:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailLore:Hide()
end

function GQ.Log:EnsureDetailReward(frame)
    if not frame or not frame.detailChild then
        return
    end

    if frame.detailRewardIcon and frame.detailRewardIcon.name then
        return
    end

    if frame.detailRewardIcon then
        frame.detailRewardIcon:Hide()
        frame.detailRewardIcon:SetParent(nil)
        frame.detailRewardIcon = nil
    end

    if not frame.detailRewardHeader then
        frame.detailRewardHeader = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_HEADER_FONTS)
        frame.detailRewardHeader:SetPoint("TOPLEFT", frame.detailBody, "BOTTOMLEFT", 0, -16)
        frame.detailRewardHeader:SetText("REWARD")
        frame.detailRewardHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
        frame.detailRewardHeader:Hide()
    end

    frame.detailRewardIcon = CreateRewardItemButton(frame.detailChild, frame:GetName() .. "RewardItem")
    frame.detailRewardIcon:SetPoint("TOPLEFT", frame.detailRewardHeader, "BOTTOMLEFT", 0, -8)
    frame.detailRewardIcon:Hide()
end

function GQ.Log:UpdateDetailReward(entryOrItemId)
    if not self.frame then
        return
    end

    self:EnsureDetailReward(self.frame)

    local header = self.frame.detailRewardHeader
    local icon = self.frame.detailRewardIcon
    if not header or not icon then
        return
    end

    local entry = type(entryOrItemId) == "table" and entryOrItemId
        or self.selectedEntry
        or (self.selectedHuntId and GQ.Data:GetEntryById(self.selectedHuntId))
    local itemId = type(entryOrItemId) == "number" and entryOrItemId
        or (entry and entry.itemId)

    if not itemId then
        header:Hide()
        icon:Hide()
        icon.itemId = nil
        icon.entry = nil
        return
    end

    if GQ.Data and GQ.Data.RequestItemInfo then
        GQ.Data:RequestItemInfo(itemId)
    end

    header:Show()
    icon:Show()
    icon.itemId = itemId
    icon.entry = entry

    local itemName = (entry and GQ.Data:GetEntryDisplayName(entry))
        or GetItemInfo(itemId)
        or ("Item " .. itemId)
    TruncateFontStringToWidth(icon.name, itemName, REWARD_NAME_MAX_WIDTH)
    icon:SetWidth(REWARD_ICON_SIZE + REWARD_NAME_MIN_WIDTH)

    local texture = SafeGetItemIcon(itemId)
    if texture then
        icon.icon:SetTexture(texture)
    else
        icon.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function GQ.Log:MeasureDetailContentHeight()
    if not self.frame then
        return 0
    end

    local height = 8

    if self.frame.detailTitle and self.frame.detailTitle:IsShown() then
        height = height + (self.frame.detailTitle:GetStringHeight() or 0) + 16
    end
    if self.frame.detailLore and self.frame.detailLore:IsShown() then
        height = height + (self.frame.detailLore:GetStringHeight() or 0) + 12
    end
    if self.frame.detailHeader and self.frame.detailHeader:IsShown() then
        height = height + (self.frame.detailHeader:GetStringHeight() or 0) + 8
    end
    if self.frame.detailBody and self.frame.detailBody:IsShown() then
        height = height + (self.frame.detailBody:GetStringHeight() or 0) + 16
    end
    if self.frame.detailRewardHeader and self.frame.detailRewardHeader:IsShown() then
        height = height + (self.frame.detailRewardHeader:GetStringHeight() or 0) + 8 + REWARD_ICON_SIZE + 16
    end

    return height
end

function GQ.Log:UpdateDetailScrollHeight()
    if not self.frame or not self.frame.detailScroll or not self.frame.detailChild then
        return
    end

    local contentHeight = self:MeasureDetailContentHeight()
    local visibleHeight = self.frame.detailScroll:GetHeight() or 120
    if contentHeight > visibleHeight then
        self.frame.detailChild:SetHeight(contentHeight)
    else
        self.frame.detailChild:SetHeight(visibleHeight)
        self.frame.detailScroll:SetVerticalScroll(0)
    end
    UpdateScrollChildRect(self.frame.detailScroll)
    ApplyScrollBarVisibility(self.frame.detailScroll)
end

function GQ.Log:CreateListRow(index)
    local row = CreateFrame("Button", "GearQuestLogRow" .. index, self.frame.scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:Hide()
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -LIST_ROW_RIGHT_PAD, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    if row.text.SetMaxLines then
        row.text:SetMaxLines(1)
    end

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.55)
    row.highlight:Hide()

    row:SetScript("OnEnter", function(self)
        ShowItemTooltipForRow(self)
        UpdateListRowHighlight(self)
    end)

    row:SetScript("OnLeave", function(self)
        HideItemTooltip()
        UpdateListRowHighlight(self)
    end)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.frame and log.frame.scroll then
            ScrollFrameOnMouseWheel(log.frame.scroll, delta)
        end
    end)

    return row
end

function GQ.Log:EnsureTrackerEvents()
    if self.trackerFrame then
        return
    end

    local tracker = CreateFrame("Frame")
    local events = {
        "BAG_UPDATE",
        "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "MERCHANT_CLOSED",
        "CHAT_MSG_SKILL",
        "CHAT_MSG_LOOT",
    }
    for i = 1, #events do
        GQ.RegisterEvent(tracker, events[i])
    end
    tracker:SetScript("OnEvent", function(_, event, msg)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            log:BeginLoginObtainScan()
            return
        end

        if event == "CHAT_MSG_SKILL" or event == "CHAT_MSG_LOOT" then
            log:HandleCraftChatMessage(msg)
            return
        end

        if event == "BAG_UPDATE" then
            if GQ.Data and GQ.Data.CacheContainerItemLinks then
                GQ.Data:CacheContainerItemLinks()
            end
            if not log.obtainToastsEnabled then
                log:UnionOwnedAtLogin()
            end
        end

        log:ScheduleAutoCompletionCheck()
    end)
    self.trackerFrame = tracker
end

local function ApplySpecPickerChrome(picker)
    if not picker then
        return
    end

    ApplyBlackBackground(picker)
    ApplyMetalEdge(picker, 12)
end

function GQ.Log:HideSpecPicker()
    if self.frame and self.frame.specPicker then
        self.frame.specPicker:Hide()
    end
    if self._specPickerCatcher then
        self._specPickerCatcher:Hide()
    end
end

function GQ.Log:EnsureSpecPicker(frame)
    if frame.specPicker then
        ApplySpecPickerChrome(frame.specPicker)
        return frame.specPicker
    end

    local parent = frame.tabBar or frame
    local picker
    local ok, framed = pcall(CreateFrame, "Frame", "GearQuestSpecPicker", parent, "BackdropTemplate")
    if ok and framed then
        picker = framed
    else
        picker = CreateFrame("Frame", "GearQuestSpecPicker", parent)
    end

    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    picker:SetSize(SPEC_PICKER_WIDTH, SPEC_PICKER_PAD * 2)
    picker:Hide()
    ApplySpecPickerChrome(picker)
    picker.rows = {}

    frame.specPicker = picker
    return picker
end

function GQ.Log:RefreshSpecPickerRows()
    local frame = self.frame
    if not frame or not frame.specPicker or not GQ.Spec then
        return
    end

    local picker = frame.specPicker
    local options = GQ.Spec:GetOptions(GQ:GetEffectiveClass()) or {}
    local current = GQ.Spec:GetEffectiveSpec()
    local rowCount = #options

    for i, row in ipairs(picker.rows) do
        row:Hide()
    end

    for i, opt in ipairs(options) do
        local row = picker.rows[i]
        if not row then
            row = CreateFrame("Button", nil, picker)
            row:SetSize(SPEC_PICKER_WIDTH - (SPEC_PICKER_PAD * 2), SPEC_PICKER_ROW_HEIGHT)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.label:SetJustifyH("LEFT")
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.55)
            row.highlight:Hide()
            row:SetScript("OnEnter", function(self)
                if self.highlight then
                    self.highlight:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                if self.highlight then
                    self.highlight:Hide()
                end
            end)
            picker.rows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", picker, "TOPLEFT", SPEC_PICKER_PAD, -(SPEC_PICKER_PAD + ((i - 1) * SPEC_PICKER_ROW_HEIGHT)))
        row:Show()

        local selectable = GQ.Spec:IsSpecSelectable(opt.id)
        row.icon:SetTexture(GQ.Spec:GetSpecIcon(opt.id, GQ:GetEffectiveClass()))
        if selectable then
            row.icon:SetVertexColor(1, 1, 1)
        else
            row.icon:SetVertexColor(0.45, 0.45, 0.45)
        end

        local selected = (current == opt.id)
        if not selectable then
            row:Disable()
            row.label:SetText("|cff888888" .. opt.label .. " (coming later)|r")
            row:SetScript("OnClick", nil)
        else
            row:Enable()
            if selected then
                row.label:SetText("|cffFFD200> |r" .. opt.label)
            else
                row.label:SetText(opt.label)
            end

            row:SetScript("OnClick", function()
                local ok, err = GQ.Spec:SetSelectedSpec(opt.id)
                if not ok then
                    print("|cff66ccffGearQuest|r: " .. (err or "Could not change specialization."))
                    return
                end
                print(string.format(
                    "|cff66ccffGearQuest|r: Now viewing |cff00ff00%s|r upgrades.",
                    opt.label
                ))
                GQ.Log:HideSpecPicker()
                GQ.Log:UpdateSpecButton()
            end)
        end
    end

    picker:SetHeight((SPEC_PICKER_PAD * 2) + (rowCount * SPEC_PICKER_ROW_HEIGHT))
end

function GQ.Log:ToggleSpecPicker(anchorBtn)
    local frame = self.frame
    if not frame or not anchorBtn then
        return
    end

    self:EnsureSpecPicker(frame)
    local picker = frame.specPicker

    if picker:IsShown() then
        self:HideSpecPicker()
        return
    end

    self:RefreshSpecPickerRows()
    picker:ClearAllPoints()
    picker:SetPoint("TOPRIGHT", anchorBtn, "BOTTOMRIGHT", 0, -2)
    picker:SetFrameLevel((anchorBtn:GetFrameLevel() or 1) + 10)
    picker:Show()

    if not self._specPickerCatcher then
        local catcher = CreateFrame("Frame", "GearQuestSpecPickerCatcher", UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:SetAllPoints(UIParent)
        catcher:EnableMouse(true)
        catcher:Hide()
        catcher:SetScript("OnMouseDown", function()
            GQ.Log:HideSpecPicker()
        end)
        self._specPickerCatcher = catcher
    end

    self._specPickerCatcher:SetFrameLevel(picker:GetFrameLevel() - 1)
    self._specPickerCatcher:Show()
end

function GQ.Log:WireSpecArrow(arrowFrame)
    if not arrowFrame or arrowFrame.gqArrowWired then
        return
    end

    arrowFrame.gqArrowWired = true
    arrowFrame:EnableMouse(true)

    arrowFrame:SetScript("OnEnter", function(self)
        if self.gqHighlight then
            self.gqHighlight:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Change specialization", 1, 1, 1)
        GameTooltip:Show()
    end)
    arrowFrame:SetScript("OnLeave", function(self)
        if self.gqHighlight then
            self.gqHighlight:Hide()
        end
        GameTooltip:Hide()
    end)
    arrowFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSpecPicker(self)
            end
        end
    end)
end

function GQ.Log:ApplySpecArrowStyle(arrowFrame, iconFrame)
    if not arrowFrame then
        return
    end

    arrowFrame:SetSize(SPEC_ARROW_SIZE, SPEC_ARROW_SIZE)

    if arrowFrame.bg then
        arrowFrame.bg:Hide()
    end

    if arrowFrame.border then
        arrowFrame.border:Hide()
    end

    if arrowFrame.text then
        arrowFrame.text:Hide()
    end

    if arrowFrame.GetNormalTexture then
        HideRegion(arrowFrame:GetNormalTexture())
        HideRegion(arrowFrame.GetPushedTexture and arrowFrame:GetPushedTexture())
        HideRegion(arrowFrame.GetDisabledTexture and arrowFrame:GetDisabledTexture())
        HideRegion(arrowFrame.GetHighlightTexture and arrowFrame:GetHighlightTexture())
    end

    if not arrowFrame.arrow then
        arrowFrame.arrow = arrowFrame:CreateTexture(nil, "ARTWORK")
        arrowFrame.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    end

    arrowFrame.arrow:ClearAllPoints()
    arrowFrame.arrow:SetAllPoints(arrowFrame)
    arrowFrame.arrow:Show()

    if not arrowFrame.gqHighlight then
        arrowFrame.gqHighlight = arrowFrame:CreateTexture(nil, "HIGHLIGHT")
        arrowFrame.gqHighlight:SetAllPoints()
        arrowFrame.gqHighlight:SetColorTexture(1, 1, 1, 0.15)
        arrowFrame.gqHighlight:Hide()
    end

    if iconFrame then
        arrowFrame:ClearAllPoints()
        arrowFrame:SetPoint("CENTER", iconFrame, "RIGHT", SPEC_CONTROL_GAP + (SPEC_ARROW_SIZE / 2), 0)
    end
end

function GQ.Log:EnsureSpecArrow(frame)
    if frame.tabSpecArrow and frame.tabSpecArrow:GetObjectType() == "Button" then
        frame.tabSpecArrow:Hide()
        frame.tabSpecArrow = nil
    end

    if not frame.tabSpecArrow and frame.tabSpecControl then
        local arrowFrame = CreateFrame("Frame", nil, frame.tabSpecControl)
        frame.tabSpecArrow = arrowFrame
        self:WireSpecArrow(arrowFrame)
    end

    self:ApplySpecArrowStyle(frame.tabSpecArrow, frame.tabSpecIcon)
end

function GQ.Log:EnsureSpecControl(frame)
    if frame.tabSpecControl then
        frame.tabSpecControl:SetSize(SPEC_CONTROL_WIDTH, SPEC_CONTROL_HEIGHT)
        self:EnsureSpecArrow(frame)
        return frame.tabSpecControl
    end

    if frame.tabSpec then
        frame.tabSpec:Hide()
        frame.tabSpec:SetScript("OnClick", nil)
    end

    local tabBar = frame.pageBar or frame.tabBar or frame
    local control = CreateFrame("Frame", "GearQuestLogSpecControl", tabBar)
    control:SetSize(SPEC_CONTROL_WIDTH, SPEC_CONTROL_HEIGHT)
    control:Hide()

    local iconFrame = CreateFrame("Frame", nil, control)
    iconFrame:SetSize(SPEC_ICON_SIZE, SPEC_ICON_SIZE)
    iconFrame:SetPoint("LEFT", control, "LEFT", 0, 0)
    iconFrame:EnableMouse(true)

    iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.border:SetAllPoints()
    iconFrame.border:SetTexture("Interface\\Common\\WhiteIconFrame")

    iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)

    iconFrame:SetScript("OnEnter", function(self)
        if not GQ.Spec then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(GQ.Spec:GetSelectedSpecLabel(), 1, 1, 1)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    iconFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSpecPicker(self)
            end
        end
    end)

    local arrowFrame = CreateFrame("Frame", nil, control)
    frame.tabSpecArrow = arrowFrame
    self:ApplySpecArrowStyle(arrowFrame, iconFrame)
    self:WireSpecArrow(arrowFrame)

    frame.tabSpecControl = control
    frame.tabSpecIcon = iconFrame
    return control
end

function GQ.Log:RepositionSpecButton(frame)
    if not frame then
        return
    end

    self:EnsureLogPages(frame)
    local logPage = frame.logPage
    if not logPage then
        return
    end

    self:EnsureSpecControl(frame)
    local control = frame.tabSpecControl
    if not control then
        return
    end

    if control:GetParent() ~= logPage then
        control:SetParent(logPage)
    end
    control:ClearAllPoints()
    if frame.detailBg then
        control:SetPoint("BOTTOMRIGHT", frame.detailBg, "TOPRIGHT", -2, 4)
    else
        control:SetPoint("TOPRIGHT", logPage, "TOPRIGHT", 0, 0)
    end
    if control.SetFrameLevel then
        control:SetFrameLevel(logPage:GetFrameLevel() + 8)
    end
end

function GQ.Log:UpdateTabVisuals()
    if not self.frame or not self.frame.tabActive then
        return
    end

    local tab = self:GetListTab()
    StyleGoldTab(self.frame.tabActive, tab == "active")
    StyleGoldTab(self.frame.tabCompleted, tab == "completed")
    local listLevel = (self.frame.listInset and self.frame.listInset:GetFrameLevel()) or (self.frame:GetFrameLevel() + 2)
    self.frame.tabActive:SetFrameLevel(tab == "active" and (listLevel + 8) or math.max(1, listLevel - 1))
    self.frame.tabCompleted:SetFrameLevel(tab == "completed" and (listLevel + 8) or math.max(1, listLevel - 1))
    self:UpdatePageTabVisuals()
    self:UpdateSpecButton()
end

function GQ.Log:UpdatePageTabVisuals()
    if not self.frame or not self.frame.tabLog then
        return
    end

    local page = self:GetPageTab()
    self:LayoutSideTabs(self.frame)
    if self.frame.tabBar then
        if page == "log" then
            self.frame.tabBar:Show()
        else
            self.frame.tabBar:Hide()
        end
    end
end

function GQ.Log:UpdateSpecButton()
    if not self.frame then
        return
    end

    self:EnsureSpecControl(self.frame)
    local control = self.frame.tabSpecControl
    if not control then
        return
    end

    if GQ.Spec and GQ.Spec.HasSpecs and GQ.Spec:HasSpecs() then
        control:Show()
        local specId = GQ.Spec.GetDisplaySpec and GQ.Spec:GetDisplaySpec() or GQ.Spec:GetEffectiveSpec()
        if self.frame.tabSpecIcon and self.frame.tabSpecIcon.icon then
            self.frame.tabSpecIcon.icon:SetTexture(GQ.Spec:GetSpecIcon(specId, GQ:GetEffectiveClass()))
        end
    else
        control:Hide()
    end
    self:RepositionSpecButton(self.frame)
end

function GQ.Log:UpdateContextStatus()
    if not self.frame or not self.frame.contextStatus then
        return
    end

    local text
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        local level = GQ:GetEffectiveLevel() or UnitLevel("player") or 1
        local spec = (GQ.Spec and GQ.Spec.GetSelectedSpecLabel and GQ.Spec:GetSelectedSpecLabel()) or "Specialization"
        local classFile = GQ:GetEffectiveClass()
        local className = classFile
        if GQ.Preview and GQ.Preview.FormatClassName then
            className = GQ.Preview:FormatClassName(classFile)
        elseif classFile then
            className = classFile:sub(1, 1) .. classFile:sub(2):lower()
        end
        local faction = (GQ.GetEffectiveFaction and GQ:GetEffectiveFaction())
            or UnitFactionGroup("player")
            or "Alliance"
        text = string.format(
            "Simulation mode: Level %d %s %s of the %s Faction.",
            level,
            spec,
            className,
            faction
        )
    else
        text = "Viewing upgrades for your current Level, Class and Faction. Use the Spec Picker to change spec."
    end

    self.frame.contextStatus:SetText(text)
end

function GQ.Log:EnsureContextStatus(frame)
    if not frame.contextStatusBar then
        frame.contextStatusBar = CreateFrame("Frame", nil, frame)
        frame.contextStatusBar:SetHeight(CONTEXT_BAND_HEIGHT)
    end
    frame.contextStatusBar:ClearAllPoints()
    frame.contextStatusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 58, CONTEXT_BAND_TOP)
    frame.contextStatusBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, CONTEXT_BAND_TOP)
    frame.contextStatusBar:Show()

    if not frame.contextStatus then
        frame.contextStatus = CreateFontStringWithFallback(frame.contextStatusBar, {
            "GameFontHighlight",
            "QuestFont",
            "GameFontNormal",
        })
        frame.contextStatus:SetJustifyH("CENTER")
        frame.contextStatus:SetJustifyV("MIDDLE")
        frame.contextStatus:SetTextColor(0.85, 0.80, 0.68)
    end
    frame.contextStatus:ClearAllPoints()
    frame.contextStatus:SetPoint("LEFT", frame.contextStatusBar, "LEFT", 0, 0)
    frame.contextStatus:SetPoint("RIGHT", frame.contextStatusBar, "RIGHT", 0, 0)
    frame.contextStatus:SetPoint("TOP", frame.contextStatusBar, "TOP", 0, 0)
    frame.contextStatus:SetPoint("BOTTOM", frame.contextStatusBar, "BOTTOM", 0, 0)
    frame.contextStatus:Show()
    self:UpdateContextStatus()
end

function GQ.Log:UpdateFooterButtons()
    if not self.frame then
        return
    end

    if self:GetPageTab() == "simulator" then
        if self.frame.trackBtn then
            self.frame.trackBtn:Hide()
        end
        if self.frame.untrackBtn then
            self.frame.untrackBtn:Hide()
        end
        if self.frame.exitBtn then
            self.frame.exitBtn:Show()
        end
        return
    end

    local tab = self:GetListTab()
    local selectedId = self.selectedHuntId
    local status = selectedId and GetHuntStatus(selectedId) or nil
    local isTracked = status == "tracked"

    if tab == "completed" then
        self.frame.trackBtn:Hide()
        self.frame.untrackBtn:Show()
        self.frame.untrackBtn:SetText("Remove")
        self.frame.untrackBtn:SetEnabled(selectedId ~= nil)
    else
        self.frame.trackBtn:Show()
        self.frame.untrackBtn:Show()
        self.frame.trackBtn:SetText("Track")
        self.frame.untrackBtn:SetText("Untrack")

        if not selectedId then
            self.frame.trackBtn:SetEnabled(false)
            self.frame.untrackBtn:SetEnabled(false)
        else
            self.frame.trackBtn:SetEnabled(not isTracked)
            self.frame.untrackBtn:SetEnabled(isTracked)
        end
    end
end

function GQ.Log:EnsurePageBar(frame)
    if not frame.pageBar then
        local pageBar = CreateFrame("Frame", nil, frame)
        pageBar:SetHeight(math.max(TAB_HEIGHT, SPEC_CONTROL_HEIGHT))
        frame.pageBar = pageBar
    end
    if frame.pageBar.tabGroup then
        frame.pageBar.tabGroup:Hide()
    end
    return frame.pageBar
end

function GQ.Log:EnsureSideTabs(frame)
    if not frame.sideTabRail then
        frame.sideTabRail = CreateFrame("Frame", nil, frame)
        frame.sideTabRail:SetSize(SIDE_TAB_WIDTH, (SIDE_TAB_HEIGHT * 2) + SIDE_TAB_GAP)
    end
    local rail = frame.sideTabRail

    if not frame.tabLog then
        frame.tabLog = CreateHandleTab(rail, "GearQuestPageTabLog", "GearQuest Log", LOG_TAB_ICON)
        frame.tabLog:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("log")
            end
        end)
    else
        frame.tabLog:SetParent(rail)
        frame.tabLog.gqLabel = frame.tabLog.gqLabel or "GearQuest Log"
        frame.tabLog.gqIconPath = LOG_TAB_ICON
        frame.tabLog:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabLog:GetScript("OnClick") then
            frame.tabLog:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("log")
                end
            end)
        end
    end

    if not frame.tabSimulator then
        frame.tabSimulator = CreateHandleTab(rail, "GearQuestPageTabSimulator", "Simulator", SIM_TAB_ICON)
        frame.tabSimulator:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SetPageTab("simulator")
            end
        end)
    else
        frame.tabSimulator:SetParent(rail)
        frame.tabSimulator.gqLabel = frame.tabSimulator.gqLabel or "Simulator"
        frame.tabSimulator.gqIconPath = SIM_TAB_ICON
        frame.tabSimulator:SetSize(SIDE_TAB_WIDTH, SIDE_TAB_HEIGHT)
        if not frame.tabSimulator:GetScript("OnClick") then
            frame.tabSimulator:SetScript("OnClick", function()
                local log = _G.GearQuest and _G.GearQuest.Log
                if log then
                    log:SetPageTab("simulator")
                end
            end)
        end
    end

    return rail
end

function GQ.Log:LayoutSideTabs(frame)
    if not frame then
        return
    end

    local rail = self:EnsureSideTabs(frame)
    if rail:GetParent() ~= UIParent then
        rail:SetParent(UIParent)
    end
    if rail.SetFrameStrata then
        rail:SetFrameStrata(LOG_FRAME_STRATA)
    end

    local frameLevel = frame:GetFrameLevel() or LOG_FRAME_LEVEL
    local railLevel = frameLevel + 5
    local frontLevel = frameLevel + 12
    local backLevel = frameLevel + 6
    rail:SetFrameLevel(railLevel)
    rail:ClearAllPoints()
    rail:SetPoint("TOPLEFT", frame, "TOPRIGHT", -SIDE_TAB_OVERLAP, SIDE_TAB_TOP)
    rail:SetSize(SIDE_TAB_WIDTH, (SIDE_TAB_HEIGHT * 2) + SIDE_TAB_GAP)
    if frame:IsShown() then
        rail:Show()
    else
        rail:Hide()
    end

    if not frame.gqRailHideWired then
        frame.gqRailHideWired = true
        local prevHide = frame:GetScript("OnHide")
        frame:SetScript("OnHide", function(self, ...)
            if self.sideTabRail then
                self.sideTabRail:Hide()
            end
            if prevHide then
                prevHide(self, ...)
            end
        end)
    end

    local page = self:GetPageTab()
    local logSelected = page == "log"
    frame.tabLog:ClearAllPoints()
    frame.tabLog:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, 0)
    frame.tabSimulator:ClearAllPoints()
    frame.tabSimulator:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, -(SIDE_TAB_HEIGHT + SIDE_TAB_GAP))
    frame.tabLog:Show()
    frame.tabSimulator:Show()
    frame.tabLog:SetFrameLevel(logSelected and frontLevel or backLevel)
    frame.tabSimulator:SetFrameLevel(logSelected and backLevel or frontLevel)
    StyleHandleTab(frame.tabLog, logSelected)
    StyleHandleTab(frame.tabSimulator, not logSelected)
end

function GQ.Log:EnsureLogPages(frame)
    if not frame.logPage then
        frame.logPage = CreateFrame("Frame", nil, frame)
    end
    if not frame.simPage then
        frame.simPage = CreateFrame("Frame", nil, frame)
    end
    return frame.logPage, frame.simPage
end

function GQ.Log:LayoutMainWindow(frame)
    if not frame then
        return
    end

    local pageBar = self:EnsurePageBar(frame)
    local logPage, simPage = self:EnsureLogPages(frame)
    self:EnsureSideTabs(frame)

    logPage:ClearAllPoints()
    logPage:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_LEFT, -TAB_TOP_OFFSET)
    logPage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, 0)

    simPage:ClearAllPoints()
    simPage:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
    simPage:SetPoint("BOTTOMRIGHT", logPage, "BOTTOMRIGHT", 0, 0)

    if pageBar:GetParent() ~= logPage then
        pageBar:SetParent(logPage)
    end
    pageBar:SetHeight(TAB_HEIGHT)
    pageBar:ClearAllPoints()
    pageBar:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, 0)
    pageBar:SetWidth(LEFT_COLUMN_WIDTH)
    pageBar:Show()

    self:EnsureContextStatus(frame)

    self:LayoutSideTabs(frame)
    self:LayoutLogColumns(frame)
    self:RepositionSpecButton(frame)
    self:LayoutSimulatorPage(frame)
    self:LayoutFooterButtons(frame)
    self:ApplyPageTab()
end

function GQ.Log:LayoutLogColumns(frame)
    local logPage = frame.logPage
    if not logPage then
        return
    end

    local filterHeight = math.max(TAB_HEIGHT, SPEC_CONTROL_HEIGHT)
    local listTop = LOG_SECTION_TOP

    if frame.listInset then
        if frame.listInset:GetParent() ~= logPage then
            frame.listInset:SetParent(logPage)
        end
        frame.listInset:ClearAllPoints()
        frame.listInset:SetPoint("TOPLEFT", logPage, "TOPLEFT", 0, listTop)
        frame.listInset:SetPoint("BOTTOMLEFT", logPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
        frame.listInset:SetWidth(LEFT_COLUMN_WIDTH)
        ApplyBlackBackground(frame.listInset)
        ApplyMetalEdge(frame.listInset, 16)
    end

    if frame.scroll and frame.listInset then
        LayoutColumnScroll(frame.scroll, frame.listInset)
    end

    if frame.scrollChild then
        frame.scrollChild:SetWidth(LEFT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET)
    end

    if frame.sectionDivider then
        frame.sectionDivider:Hide()
    end

    if frame.listGutter then
        frame.listGutter:Hide()
    end
    if frame.detailGutter then
        frame.detailGutter:Hide()
    end

    if frame.detailBg then
        if frame.detailBg:GetParent() ~= logPage then
            frame.detailBg:SetParent(logPage)
        end
        frame.detailBg:ClearAllPoints()
        frame.detailBg:SetPoint("TOPLEFT", logPage, "TOPLEFT", LEFT_COLUMN_WIDTH + COLUMN_GAP, listTop)
        frame.detailBg:SetPoint("BOTTOMRIGHT", logPage, "BOTTOMRIGHT", 0, FOOTER_OFFSET)
        ApplyMetalEdge(frame.detailBg, 16)
    end

    if frame.detailChild then
        frame.detailChild:SetWidth(RIGHT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8)
    end

    LayoutDetailScroll(frame)
end

function GQ.Log:LayoutFooterButtons(frame)
    if not frame.trackBtn then
        return
    end

    local chromeLevel = (frame.gqOuterBorder and frame.gqOuterBorder.GetFrameLevel and frame.gqOuterBorder:GetFrameLevel() or (frame:GetFrameLevel() or 1)) + 2
    frame.trackBtn:SetFrameLevel(chromeLevel)
    frame.trackBtn:ClearAllPoints()
    frame.trackBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_LEFT, FOOTER_BUTTON_Y)

    frame.untrackBtn:SetFrameLevel(chromeLevel)
    frame.untrackBtn:ClearAllPoints()
    frame.untrackBtn:SetPoint("LEFT", frame.trackBtn, "RIGHT", 4, 0)

    if frame.exitBtn then
        frame.exitBtn:SetFrameLevel(chromeLevel)
        frame.exitBtn:ClearAllPoints()
        frame.exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, FOOTER_BUTTON_Y)
    end
end

function GQ.Log:ApplyPageTab()
    if not self.frame then
        return
    end

    local page = self:GetPageTab()
    if self.frame.logPage then
        if page == "log" then
            self.frame.logPage:Show()
        else
            self.frame.logPage:Hide()
        end
    end
    if self.frame.detailScroll then
        if page == "log" then
            self.frame.detailScroll:Show()
        else
            self.frame.detailScroll:Hide()
        end
        local detailBar = self.frame.detailScroll.GetName and _G[self.frame.detailScroll:GetName() .. "ScrollBar"]
        if page == "log" then
            ApplyScrollBarVisibility(self.frame.detailScroll)
        elseif detailBar then
            detailBar:Hide()
        end
    end
    if self.frame.scroll then
        local listBar = self.frame.scroll.GetName and _G[self.frame.scroll:GetName() .. "ScrollBar"]
        if page == "log" then
            self.frame.scroll:Show()
            ApplyScrollBarVisibility(self.frame.scroll)
        else
            if listBar then
                listBar:Hide()
            end
        end
    end
    if self.frame.simPage then
        if page == "simulator" then
            self.frame.simPage:Show()
        else
            self.frame.simPage:Hide()
        end
    end

    self:UpdatePageTabVisuals()
    self:UpdateFooterButtons()
    self:UpdateContextStatus()
    if page == "log" then
        self:UpdateSpecButton()
    elseif self.frame.tabSpecControl then
        self.frame.tabSpecControl:Hide()
    end
end

function GQ.Log:EnsureTabBar(frame)
    local pageBar = self:EnsurePageBar(frame)
    self:EnsureLogPages(frame)

    if not frame.tabBar then
        local tabBar = CreateFrame("Frame", nil, pageBar)
        tabBar:SetHeight(TAB_HEIGHT)
        tabBar:SetWidth(FILTER_TAB_WIDTH * 2 + 4)
        tabBar:SetPoint("TOPLEFT", pageBar, "TOPLEFT", FILTER_TAB_LEFT, 0)
        frame.tabBar = tabBar
        tabBar.tabGroup = tabBar

        local tabActive = CreateGoldTab(tabBar, "GearQuestLogTabActive", "Active", FILTER_TAB_WIDTH)
        tabActive:SetPoint("TOPLEFT", tabBar, "TOPLEFT", 0, 0)
        frame.tabActive = tabActive

        local tabCompleted = CreateGoldTab(tabBar, "GearQuestLogTabCompleted", "Completed", FILTER_TAB_WIDTH)
        tabCompleted:SetPoint("TOPLEFT", tabActive, "TOPRIGHT", 4, 0)
        frame.tabCompleted = tabCompleted

        tabActive:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:HideSpecPicker()
                log:SetListTab("active")
            end
        end)

        tabCompleted:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:HideSpecPicker()
                log:SetListTab("completed")
            end
        end)
    else
        if frame.tabBar:GetParent() ~= pageBar then
            frame.tabBar:SetParent(pageBar)
        end
        frame.tabBar:ClearAllPoints()
        frame.tabBar:SetPoint("TOPLEFT", pageBar, "TOPLEFT", FILTER_TAB_LEFT, 0)
        StyleGoldTab(frame.tabActive, self:GetListTab() == "active")
        StyleGoldTab(frame.tabCompleted, self:GetListTab() == "completed")
    end

    self:EnsureSimulatorPage(frame)
    self:LayoutMainWindow(frame)
    self:UpdateTabVisuals()
end

function GQ.Log:EnsureSimulatorPage(frame)
    self:EnsureLogPages(frame)
    local simPage = frame.simPage
    if simPage.simReady then
        return simPage
    end
    simPage.simReady = true

    local classInset = CreateFrame("Frame", nil, simPage)
    ApplyBlackBackground(classInset)
    ApplyMetalEdge(classInset, 12)
    frame.simClassInset = classInset

    local classTitle = classInset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classTitle:SetPoint("TOPLEFT", classInset, "TOPLEFT", 10, -8)
    classTitle:SetText("Classes")
    frame.simClassTitle = classTitle

    frame.simClassButtons = {}
    local classOrder = (GQ.Preview and GQ.Preview.CLASS_ORDER) or {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
    }
    local previous
    for i, classFile in ipairs(classOrder) do
        local btn = CreateFrame("Button", "GearQuestSimClass" .. classFile, classInset)
        btn:SetHeight(22)
        if previous then
            btn:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -1)
            btn:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -1)
        else
            btn:SetPoint("TOPLEFT", classTitle, "BOTTOMLEFT", -4, -8)
            btn:SetPoint("TOPRIGHT", classInset, "TOPRIGHT", -8, -30)
        end

        btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
        btn.highlight:SetAllPoints()
        btn.highlight:SetColorTexture(0.28, 0.22, 0.08, 0.55)
        btn.highlight:Hide()

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", btn, "LEFT", 12, 0)
        btn.text:SetJustifyH("LEFT")
        local label = (GQ.Preview and GQ.Preview.FormatClassName and GQ.Preview:FormatClassName(classFile)) or classFile
        btn.text:SetText(label)
        local colors = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[classFile]
        if colors then
            btn.text:SetTextColor(colors.r, colors.g, colors.b)
        end

        btn.classFile = classFile
        btn:SetScript("OnClick", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:SelectSimulatorClass(self.classFile)
            end
        end)
        btn:SetScript("OnEnter", function(self)
            if not self.selected then
                self.highlight:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self.selected then
                self.highlight:Hide()
            end
        end)

        frame.simClassButtons[i] = btn
        previous = btn
    end

    local simDetail = CreateFrame("Frame", nil, simPage)
    EnableClipping(simDetail)
    ApplyParchmentBackground(simDetail)
    ApplyMetalEdge(simDetail, 12)
    frame.simDetail = simDetail

    local title = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_TITLE_FONTS)
    title:SetPoint("TOPLEFT", simDetail, "TOPLEFT", 16, -16)
    title:SetPoint("RIGHT", simDetail, "RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetText("SIMULATOR")
    title:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simTitle = title

    local body = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_BODY_FONTS)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    body:SetPoint("RIGHT", simDetail, "RIGHT", -16, 0)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetText("Pick a class on the left, then set faction, specialization, and level. Simulate to browse that character's upgrades in the log.")
    body:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simBody = body

    local factionHeader = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_HEADER_FONTS)
    factionHeader:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -16)
    factionHeader:SetText("FACTION")
    factionHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simFactionHeader = factionHeader

    local allianceBtn = CreateFrame("Button", "GearQuestSimFactionAlliance", simDetail, "UIPanelButtonTemplate")
    allianceBtn:SetSize(96, 22)
    allianceBtn:SetPoint("TOPLEFT", factionHeader, "BOTTOMLEFT", 0, -6)
    allianceBtn:SetText("Alliance")
    frame.simAllianceBtn = allianceBtn

    local hordeBtn = CreateFrame("Button", "GearQuestSimFactionHorde", simDetail, "UIPanelButtonTemplate")
    hordeBtn:SetSize(96, 22)
    hordeBtn:SetPoint("LEFT", allianceBtn, "RIGHT", 6, 0)
    hordeBtn:SetText("Horde")
    frame.simHordeBtn = hordeBtn

    allianceBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log.simFaction = "Alliance"
            log:RefreshSimulator()
        end
    end)
    hordeBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log.simFaction = "Horde"
            log:RefreshSimulator()
        end
    end)

    local specHeader = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_HEADER_FONTS)
    specHeader:SetPoint("TOPLEFT", allianceBtn, "BOTTOMLEFT", 0, -16)
    specHeader:SetText("SPECIALIZATION")
    specHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simSpecHeader = specHeader

    frame.simSpecButtons = {}
    for i = 1, 4 do
        local specBtn = CreateFrame("Button", "GearQuestSimSpec" .. i, simDetail, "UIPanelButtonTemplate")
        specBtn:SetSize(150, 22)
        if i == 1 then
            specBtn:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -6)
        elseif i == 2 then
            specBtn:SetPoint("LEFT", frame.simSpecButtons[1], "RIGHT", 6, 0)
        elseif i == 3 then
            specBtn:SetPoint("TOPLEFT", frame.simSpecButtons[1], "BOTTOMLEFT", 0, -4)
        else
            specBtn:SetPoint("LEFT", frame.simSpecButtons[3], "RIGHT", 6, 0)
        end
        specBtn:Hide()
        specBtn:SetScript("OnClick", function(self)
            local log = _G.GearQuest and _G.GearQuest.Log
            if not log then
                return
            end
            log.simSpec = self.specId
            if GQ.Preview and GQ.Preview.IsEnabled and GQ.Preview:IsEnabled() and GQ.Spec and self.specId then
                GQ.Spec:SetSelectedSpec(self.specId, log.simClass)
            end
            log:RefreshSimulator()
        end)
        frame.simSpecButtons[i] = specBtn
    end

    local levelHeader = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_HEADER_FONTS)
    levelHeader:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -72)
    levelHeader:SetText("LEVEL")
    levelHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simLevelHeader = levelHeader

    local levelEdit = CreateFrame("EditBox", "GearQuestSimLevelEdit", simDetail, "InputBoxTemplate")
    levelEdit:SetSize(64, 20)
    levelEdit:SetPoint("LEFT", levelHeader, "RIGHT", 12, 0)
    levelEdit:SetAutoFocus(false)
    levelEdit:SetMaxLetters(2)
    frame.simLevelEdit = levelEdit
    levelEdit:SetScript("OnTextChanged", function(self)
        if GQ.Preview and GQ.Preview.SanitizeLevelEdit then
            GQ.Preview:SanitizeLevelEdit(self)
        end
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.RefreshSimulator then
            log:RefreshSimulator()
        end
    end)
    levelEdit:SetScript("OnEnterPressed", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ApplySimulator()
        end
    end)
    levelEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    local status = CreateFontStringWithFallback(simDetail, QUEST_DETAIL_BODY_FONTS)
    status:SetPoint("TOPLEFT", levelHeader, "BOTTOMLEFT", 0, -18)
    status:SetPoint("RIGHT", simDetail, "RIGHT", -16, 0)
    status:SetJustifyH("LEFT")
    status:SetWordWrap(true)
    status:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.simStatus = status

    local simulateBtn = CreateFrame("Button", "GearQuestSimApplyButton", simDetail, "UIPanelButtonTemplate")
    simulateBtn:SetSize(106, 22)
    simulateBtn:SetPoint("BOTTOMLEFT", simDetail, "BOTTOMLEFT", 16, 14)
    simulateBtn:SetText("Simulate")
    frame.simApplyBtn = simulateBtn
    simulateBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ApplySimulator()
        end
    end)

    local resetBtn = CreateFrame("Button", "GearQuestSimResetButton", simDetail, "UIPanelButtonTemplate")
    resetBtn:SetSize(80, 22)
    resetBtn:SetPoint("LEFT", simulateBtn, "RIGHT", 6, 0)
    resetBtn:SetText("Reset")
    frame.simResetBtn = resetBtn
    resetBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:ResetSimulator()
        end
    end)

    return simPage
end

function GQ.Log:LayoutSimulatorPage(frame)
    if not frame.simPage or not frame.simClassInset or not frame.simDetail then
        return
    end

    frame.simClassInset:ClearAllPoints()
    frame.simClassInset:SetPoint("TOPLEFT", frame.simPage, "TOPLEFT", 0, LOG_SECTION_TOP)
    frame.simClassInset:SetPoint("BOTTOMLEFT", frame.simPage, "BOTTOMLEFT", 0, FOOTER_OFFSET)
    frame.simClassInset:SetWidth(LEFT_COLUMN_WIDTH)
    ApplyBlackBackground(frame.simClassInset)
    ApplyMetalEdge(frame.simClassInset, 16)

    frame.simDetail:ClearAllPoints()
    frame.simDetail:SetPoint("TOPLEFT", frame.simPage, "TOPLEFT", LEFT_COLUMN_WIDTH + COLUMN_GAP, LOG_SECTION_TOP)
    frame.simDetail:SetPoint("BOTTOMRIGHT", frame.simPage, "BOTTOMRIGHT", 0, FOOTER_OFFSET)
    ApplyMetalEdge(frame.simDetail, 16)
end

function GQ.Log:SelectSimulatorClass(classFile)
    self.simClass = classFile
    if GQ.Spec then
        local options = GQ.Spec:GetOptions(classFile) or {}
        local stillValid = false
        for _, opt in ipairs(options) do
            if opt.id == self.simSpec and GQ.Spec:IsSpecSelectable(opt.id, classFile) then
                stillValid = true
                break
            end
        end
        if not stillValid then
            self.simSpec = GQ.Spec:GetDefaultSpec(classFile)
        end
    end
    self:RefreshSimulator()
end

function GQ.Log:RefreshSimulator()
    if not self.frame or not self.frame.simClassButtons then
        return
    end

    if not self.simClass then
        self.simClass = GQ:GetEffectiveClass()
    end
    if not self.simFaction then
        self.simFaction = GQ:GetEffectiveFaction() or "Alliance"
    end
    if self.frame.simLevelEdit then
        local focused = false
        if self.frame.simLevelEdit.HasFocus then
            focused = self.frame.simLevelEdit:HasFocus()
        end
        local text = self.frame.simLevelEdit:GetText() or ""
        if not focused and text == "" then
            self.frame.simLevelEdit:SetText(tostring(GQ:GetEffectiveLevel() or 1))
        end
    end

    for _, btn in ipairs(self.frame.simClassButtons) do
        local selected = btn.classFile == self.simClass
        btn.selected = selected
        if selected then
            btn.highlight:Show()
        else
            btn.highlight:Hide()
        end
    end

    if self.frame.simAllianceBtn then
        self.frame.simAllianceBtn:SetEnabled(self.simFaction ~= "Alliance")
        self.frame.simHordeBtn:SetEnabled(self.simFaction ~= "Horde")
    end

    local level = tonumber(self.frame.simLevelEdit and self.frame.simLevelEdit:GetText()) or GQ:GetEffectiveLevel() or 1
    local specOptions = {}
    if GQ.Spec and GQ.Spec.GetOptions then
        for _, opt in ipairs(GQ.Spec:GetOptions(self.simClass) or {}) do
            if GQ.Spec:IsSpecSelectable(opt.id, self.simClass) then
                specOptions[#specOptions + 1] = opt
            end
        end
    end

    local specValid = false
    for _, opt in ipairs(specOptions) do
        if opt.id == self.simSpec then
            specValid = true
            break
        end
    end
    if not specValid then
        self.simSpec = specOptions[1] and specOptions[1].id or nil
    end

    if self.frame.simSpecHeader then
        if #specOptions > 0 then
            self.frame.simSpecHeader:Show()
        else
            self.frame.simSpecHeader:Hide()
        end
    end

    for i, specBtn in ipairs(self.frame.simSpecButtons) do
        local opt = specOptions[i]
        if opt then
            specBtn:Show()
            specBtn:SetText(opt.label)
            specBtn.specId = opt.id
            specBtn:SetEnabled(self.simSpec ~= opt.id)
        else
            specBtn:Hide()
            specBtn.specId = nil
        end
    end

    local className = (GQ.Preview and GQ.Preview.FormatClassName and GQ.Preview:FormatClassName(self.simClass)) or self.simClass
    local specLabel = ""
    if self.simSpec and GQ.Spec then
        for _, opt in ipairs(specOptions) do
            if opt.id == self.simSpec then
                specLabel = ", " .. opt.label
                break
            end
        end
    end

    local viewing = string.format(
        "Simulate a level %s %s %s%s, then open the log to hunt their upgrades.",
        tostring(level),
        self.simFaction or "Alliance",
        className,
        specLabel
    )
    if self.frame.simStatus then
        self.frame.simStatus:SetText(viewing)
    end
end

function GQ.Log:ApplySimulator()
    if not GQ.Preview then
        return
    end

    local levelText = ""
    if self.frame.simLevelEdit and GQ.Preview.SanitizeLevelEdit then
        levelText = GQ.Preview:SanitizeLevelEdit(self.frame.simLevelEdit)
    elseif self.frame.simLevelEdit then
        levelText = tostring(self.frame.simLevelEdit:GetText() or ""):gsub("%D", "")
    end
    if levelText == "" then
        print(string.format("|cff66ccffGearQuest|r: Enter a level between 1 and %d.", GQ.MAX_PLAYER_LEVEL or 60))
        return
    end

    local ok, err = GQ.Preview:ApplySimulation(self.simClass, levelText, self.simSpec, self.simFaction)
    if not ok then
        print("|cff66ccffGearQuest|r: " .. (err or "Could not simulate."))
        return
    end

    self:SetPageTab("log")
end

function GQ.Log:ResetSimulator()
    if not GQ.Preview then
        return
    end
    GQ.Preview:ApplyCurrentCharacter()
    GQ.Preview:SetEnabled(false)
    GQ.Preview:PrintNowViewing()
    self.simClass = GQ:GetEffectiveClass()
    self.simFaction = GQ:GetEffectiveFaction()
    self.simSpec = (GQ.Spec and GQ.Spec.GetDisplaySpec and GQ.Spec:GetDisplaySpec())
        or (GQ.Spec and GQ.Spec:GetEffectiveSpec())
        or nil
    if self.frame and self.frame.simLevelEdit then
        self.frame.simLevelEdit:SetText(tostring(GQ:GetEffectiveLevel() or 1))
    end
    if GQ.RefreshUI then
        GQ:RefreshUI()
    end
    self:RefreshSimulator()
    self:SetPageTab("log")
end

function GQ.Log:WireControls(frame)
    frame.trackBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.selectedHuntId then
            log:TrackHunt(log.selectedHuntId)
        end
    end)

    frame.untrackBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log and log.selectedHuntId then
            log:RequestUntrackHunt(log.selectedHuntId)
        end
    end)

    frame.exitBtn:SetScript("OnClick", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if log then
            log:Hide()
        end
    end)
end

function GQ.Log:BindExistingFrame(frame)
    self.frame = frame
    ApplyLogWindowLayer(frame)
    ApplyModernChrome(frame)
    WireLogWindowMouseWheel(frame)
    self.listRows = {}
    self.selectedHuntId = nil
    self.selectedEntry = nil
    frame.scroll = frame.scroll or _G.GearQuestLogListScrollFrame
    frame.scrollChild = frame.scrollChild or _G.GearQuestLogListScrollChild
    frame.detailScroll = frame.detailScroll or _G.GearQuestLogDetailScrollFrame
    frame.detailChild = frame.detailChild or _G.GearQuestLogDetailScrollChild
    frame.listInset = frame.listInset or frame
    self:EnsureTabBar(frame)
    self:EnsureDetailLore(frame)
    self:EnsureDetailReward(frame)
    LayoutDetailScroll(frame)
    if frame.trackBtn and frame.untrackBtn and frame.exitBtn then
        self:WireControls(frame)
    end
    self:EnsureTrackerEvents()
end

function GQ.Log:MigrateObtainedRecords()
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}

    for id, record in pairs(GearQuestForeverDB.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed" and not GearQuestForeverDB.obtained[id] then
            GearQuestForeverDB.obtained[id] = record.completedAt or record.trackedAt or time()
        end
    end

    for id, obtainedAt in pairs(GearQuestForeverDB.obtained) do
        local entry = GQ.Data:GetEntryById(id)
        if entry and entry.itemId then
            local key = tostring(entry.itemId)
            if not GearQuestForeverDB.obtainedItems[key] then
                GearQuestForeverDB.obtainedItems[key] = obtainedAt
            end
        end
        if entry and entry.sourceType == "profession" and entry.itemId and not GearQuestForeverDB.crafted[entry.itemId] then
            GearQuestForeverDB.crafted[entry.itemId] = obtainedAt
        end
    end
end

function GQ.Log:Init()
    self.obtainToastsEnabled = false
    self:MigrateObtainedRecords()
    self:BeginLoginObtainScan()

    if self.frame then
        return
    end

    self:EnsureItemInfoListener()

    if _G.GearQuestLogFrame then
        self:BindExistingFrame(_G.GearQuestLogFrame)
        return
    end

    local ok, frame = pcall(CreateFrame, "Frame", "GearQuestLogFrame", UIParent, "PortraitFrameTemplate")
    if not ok or not frame then
        frame = CreateFrame("Frame", "GearQuestLogFrame", UIParent)
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 32,
                edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
        end
        CreateFrame("Button", nil, frame, "UIPanelCloseButton"):SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    end

    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        BringLogWindowToFront(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function(self)
        BringLogWindowToFront(self)
    end)
    WireLogWindowMouseWheel(frame)
    ApplyLogWindowLayer(frame)
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    SetFrameTitle(frame, "GearQuest")
    ApplyModernChrome(frame)
    self.frame = frame
    self:EnsureLogPages(frame)

    frame.listInset = CreateFrame("Frame", nil, frame.logPage)
    frame.listInset:SetSize(LEFT_COLUMN_WIDTH, 200)
    ApplyBlackBackground(frame.listInset)
    ApplyMetalEdge(frame.listInset, 12)

    frame.scroll = CreatePanelScrollFrame("GearQuestLogListScrollFrame", frame.listInset)
    frame.scroll:SetPoint("TOPLEFT", frame.listInset, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame.listInset, "BOTTOMRIGHT", -PANEL_INSET, PANEL_INSET)

    frame.scrollChild = CreateFrame("Frame", "GearQuestLogListScrollChild", frame.scroll)
    frame.scrollChild:SetWidth(LEFT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET)
    frame.scrollChild:SetHeight(1)
    frame.scroll:SetScrollChild(frame.scrollChild)

    frame.listGutter = CreateFrame("Frame", nil, frame)
    frame.listGutter:Hide()

    frame.sectionDivider = CreateSectionDivider(frame)
    frame.sectionDivider:Hide()

    frame.detailBg = CreateFrame("Frame", nil, frame.logPage)
    EnableClipping(frame.detailBg)
    ApplyParchmentBackground(frame.detailBg)
    ApplyMetalEdge(frame.detailBg, 12)

    frame.detailScroll = CreatePanelScrollFrame("GearQuestLogDetailScrollFrame", frame)
    LayoutDetailScroll(frame)

    frame.detailChild = CreateFrame("Frame", "GearQuestLogDetailScrollChild", frame.detailScroll)
    frame.detailChild:SetWidth(RIGHT_COLUMN_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8)
    frame.detailScroll:SetScrollChild(frame.detailChild)

    frame.detailGutter = CreateFrame("Frame", nil, frame)
    frame.detailGutter:Hide()

    ConfigurePanelScrollBar(frame.scroll)

    frame.detailTitle = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_TITLE_FONTS)
    frame.detailTitle:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
    frame.detailTitle:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailTitle:SetJustifyH("LEFT")
    frame.detailTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailTitle:Hide()

    frame.detailLore = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailLore:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -8)
    frame.detailLore:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailLore:SetJustifyH("LEFT")
    frame.detailLore:SetWordWrap(true)
    frame.detailLore:SetTextColor(LORE_TEXT_COLOR[1], LORE_TEXT_COLOR[2], LORE_TEXT_COLOR[3])
    frame.detailLore:Hide()

    frame.detailHeader = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_HEADER_FONTS)
    frame.detailHeader:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -16)
    frame.detailHeader:SetText("DESCRIPTION")
    frame.detailHeader:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailHeader:Hide()

    frame.detailBody = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailBody:SetPoint("TOPLEFT", frame.detailHeader, "BOTTOMLEFT", 0, -8)
    frame.detailBody:SetPoint("RIGHT", frame.detailChild, "RIGHT", -8, 0)
    frame.detailBody:SetJustifyH("LEFT")
    frame.detailBody:SetWordWrap(true)
    frame.detailBody:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailBody:Hide()

    self:EnsureDetailLore(frame)
    self:EnsureDetailReward(frame)

    frame.detailEmpty = CreateFontStringWithFallback(frame.detailChild, QUEST_DETAIL_BODY_FONTS)
    frame.detailEmpty:SetPoint("TOPLEFT", frame.detailChild, "TOPLEFT", 8, -8)
    frame.detailEmpty:SetText("Select an upgrade to see how to get it.")
    frame.detailEmpty:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])
    frame.detailEmpty:Show()

    frame.trackBtn = CreateFrame("Button", "GearQuestLogTrackButton", frame, "UIPanelButtonTemplate")
    frame.trackBtn:SetSize(106, 22)
    frame.trackBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 12)
    frame.trackBtn:SetText("Track")

    frame.untrackBtn = CreateFrame("Button", "GearQuestLogUntrackButton", frame, "UIPanelButtonTemplate")
    frame.untrackBtn:SetSize(106, 22)
    frame.untrackBtn:SetPoint("LEFT", frame.trackBtn, "RIGHT", 2, 0)
    frame.untrackBtn:SetText("Untrack")

    frame.exitBtn = CreateFrame("Button", "GearQuestLogExitButton", frame, "UIPanelButtonTemplate")
    frame.exitBtn:SetSize(106, 22)
    frame.exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, 12)
    frame.exitBtn:SetText("Exit")

    self:WireControls(frame)
    self:EnsureTrackerEvents()
    self:EnsureTabBar(frame)

    self.listRows = {}
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
end

function GQ.Log:SetDetailEmpty(empty)
    if not self.frame then
        return
    end

    if empty then
        self.frame.detailEmpty:Show()
        self.frame.detailHeader:Hide()
        self.frame.detailTitle:Hide()
        if self.frame.detailLore then
            self.frame.detailLore:Hide()
        end
        self.frame.detailBody:Hide()
        if self.frame.detailRewardHeader then
            self.frame.detailRewardHeader:Hide()
        end
        if self.frame.detailRewardIcon then
            self.frame.detailRewardIcon:Hide()
        end
    else
        self.frame.detailEmpty:Hide()
        self.frame.detailHeader:Show()
        self.frame.detailTitle:Show()
        self.frame.detailBody:Show()
    end
end

function GQ.Log:ClearDetail()
    if not self.frame then
        return
    end
    self.frame.detailTitle:SetText("")
    self.frame.detailBody:SetText("")
    if self.frame.detailLore then
        self.frame.detailLore:SetText("")
        self.frame.detailLore:Hide()
    end
    self:UpdateDetailReward(nil)
    self:SetDetailEmpty(true)
end

function GQ.Log:ConfigureRow(row, yOffset, rowType, slotName, entry)
    row:Show()
    local scrollChild = self.frame.scrollChild
    local scroll = self.frame.scroll
    AnchorListRow(row, scrollChild, scroll, yOffset)
    row:SetHeight(ROW_HEIGHT)
    row.rowType = rowType
    row.slotName = slotName
    row.entry = entry
    row.huntId = entry and entry.id or nil

    if rowType == "header" then
        row.icon:Show()
        local collapsed = self:IsSlotCollapsed(slotName)
        row.icon:SetTexture(collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetText(GQ.Data:SlotHeaderLabel(slotName))
        row.text:SetTextColor(1, 0.82, 0)
        row.highlight:Hide()
        row:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                log:ToggleSlotCollapsed(slotName)
            end
        end)
    elseif rowType == "empty" then
        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        if self:GetListTab() == "completed" then
            row.text:SetText("No completed hunts in this slot.")
        else
            row.text:SetText("No upgrades for your level yet.")
        end
        row.text:SetTextColor(0.6, 0.6, 0.6)
        row.highlight:Hide()
        row:SetScript("OnClick", nil)
    elseif rowType == "empty_all" then
        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetText("No completed hunts yet.")
        row.text:SetTextColor(0.6, 0.6, 0.6)
        row.highlight:Hide()
        row:SetScript("OnClick", nil)
    elseif rowType == "notable" then
        local name = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)
        PrimeListEntryItemInfo(entry)
        local r, g, b = GetListItemQualityColor(entry.itemId)
        local status = GetHuntStatus(entry.id)

        row.icon:Show()
        row.icon:SetTexture(NOTABLE_LIST_ICON)
        row.icon:SetVertexColor(1, 1, 1)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -LIST_ROW_RIGHT_PAD, 0)
        SetListRowItemText(row, LIST_ROW_NOTABLE_LEFT, name, entry, status, false, r, g, b, slotName)

        UpdateListRowHighlight(row)
        row:SetScript("OnClick", function()
            OnListRowItemClick(entry)
        end)
    else
        local name = tostring(GQ.Data:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId)))
        PrimeListEntryItemInfo(entry)
        local r, g, b = GetListItemQualityColor(entry.itemId)
        local status = GetHuntStatus(entry.id)
        local onCompletedTab = self:GetListTab() == "completed"
        local isObtained = entry.id and self:IsEntryObtained(entry.id)

        row.icon:Hide()
        row.icon:SetTexture(nil)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", LIST_ROW_ITEM_LEFT, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -LIST_ROW_RIGHT_PAD, 0)

        local showNewLabel = not onCompletedTab and not isObtained and status ~= "completed"
        SetListRowItemText(row, LIST_ROW_ITEM_LEFT, name, entry, status, showNewLabel, r, g, b, slotName)

        UpdateListRowHighlight(row)
        row:SetScript("OnClick", function()
            OnListRowItemClick(entry)
        end)
    end
end

function GQ.Log:ScrollListToRow(layoutIndex)
    if not layoutIndex or not self.frame or not self.frame.scroll then
        return
    end

    local scroll = self.frame.scroll
    local scrollChild = self.frame.scrollChild
    if not scrollChild then
        return
    end

    local visibleHeight = scroll:GetHeight() or 200
    local contentHeight = scrollChild:GetHeight() or 0
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    if maxScroll <= 0 then
        scroll:SetVerticalScroll(0)
        return
    end

    local rowTop = (layoutIndex - 1) * ROW_HEIGHT
    local target = rowTop - math.floor((visibleHeight - ROW_HEIGHT) / 2)
    target = math.max(0, math.min(target, maxScroll))
    scroll:SetVerticalScroll(target)

    local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetValue(target)
    end
end

function GQ.Log:BuildDetailLines(entry)
    if entry and entry.sourceType == "profession" and GQ.Data and GQ.Data.EnrichProfessionEntry then
        GQ.Data:EnrichProfessionEntry(entry)
    end

    local lines = {
        (GQ.Data and GQ.Data.GetProfessionInstructions and GQ.Data:GetProfessionInstructions(entry))
            or entry.instructions,
    }

    local audit = GQ.Data and GQ.Data.GetForeverAudit and GQ.Data:GetForeverAudit(entry.itemId)
    if audit and audit.status == "missing" then
        table.insert(lines, "\nNot found on Wowhead Forever - it may not exist in this game.")
    elseif GQ.Data and GQ.Data.NeedsDatamineNotice and GQ.Data:NeedsDatamineNotice(entry) then
        table.insert(lines, "\nHas not been datamined yet")
    end

    local suffixHint = GQ.Data:GetSuffixHint(entry)
    if suffixHint then
        table.insert(lines, "\nRandom enchant: " .. suffixHint)
    end

    if entry.proc then
        table.insert(lines, "\nWhy it's good: " .. entry.proc)
    end

    if GQ.Data:ShouldDisplayAsNotable(entry, entry and entry.slot) and entry.proc then
        table.insert(lines, "\nWorth considering - the proc is the point.")
    end

    if entry.origin == "guide" then
        table.insert(lines, "\nRanked from the Wowhead Classic BiS guide.")
    end

    local how = string.lower(lines[1] or "")

    local function alreadySays(needle)
        return needle and needle ~= "" and how:find(string.lower(needle), 1, true)
    end

    if entry.sourceType == "world_drop" or entry.sourceType == "profession" then
        local mentionsAh = how:find("auction", 1, true)
        if not mentionsAh then
            local isBoE = GQ.Equip and GQ.Equip.IsBindOnEquip and GQ.Equip:IsBindOnEquip(entry.itemId)
            if isBoE then
                local ah = entry.sourceType == "profession"
                    and "\nAlso available on the Auction House (crafted by others; binds when equipped)."
                    or "\nAlso available on the Auction House (binds when equipped)."
                table.insert(lines, ah)
            end
        end
    end

    if entry.zone and not alreadySays(entry.zone) then
        table.insert(lines, "\nZone: " .. entry.zone)
    end
    if entry.questName and not alreadySays(entry.questName) then
        table.insert(lines, "Quest: " .. entry.questName)
    end
    if entry.npc and not alreadySays(entry.npc) then
        table.insert(lines, "NPC: " .. entry.npc)
    end
    table.insert(lines, "\nSource: " .. GQ:GetSourceLabel(entry.sourceType))

    local record = GetHuntRecord(entry.id)
    if record and NormalizeHuntStatus(record.status) == "completed" then
        local completedText = FormatCompletedDate(record.completedAt)
        if completedText then
            table.insert(lines, "\nCompleted: " .. completedText)
        end
    end

    return lines
end

function GQ.Log:EnsureItemInfoListener()
    if self.itemInfoListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log or not log.frame or not log.frame:IsShown() then
            return
        end

        itemId = tonumber(itemId)
        local entry = log.selectedEntry or GQ.Data:GetEntryById(log.selectedHuntId)
        if not entry or not itemId or entry.itemId ~= itemId then
            return
        end

        log:UpdateDetailReward(entry)
    end)
    self.itemInfoListener = frame
end

function GQ.Log:ApplyEntryDetail(entry)
    if not self.frame or not entry then
        return
    end

    self:EnsureDetailLore(self.frame)

    local itemName = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)

    self:SetDetailEmpty(false)
    local title = itemName:upper()
    if GQ.Data and GQ.Data.SanitizeText then
        title = GQ.Data:SanitizeText(title) or title
    end
    self.frame.detailTitle:SetText(title)
    self.frame.detailTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])

    local lore = entry.lore
    if self.frame.detailLore then
        if lore and lore ~= "" then
            self.frame.detailLore:SetText(GQ.Data:SanitizeText(lore) or lore)
            self.frame.detailLore:Show()
            self.frame.detailHeader:ClearAllPoints()
            self.frame.detailHeader:SetPoint("TOPLEFT", self.frame.detailLore, "BOTTOMLEFT", 0, -12)
        else
            self.frame.detailLore:SetText("")
            self.frame.detailLore:Hide()
            self.frame.detailHeader:ClearAllPoints()
            self.frame.detailHeader:SetPoint("TOPLEFT", self.frame.detailTitle, "BOTTOMLEFT", 0, -16)
        end
    end

    local lines = self:BuildDetailLines(entry)
    local body = table.concat(lines, "\n")
    if GQ.Data and GQ.Data.SanitizeText then
        body = GQ.Data:SanitizeText(body) or body
    end
    self.frame.detailBody:SetText(body)

    self:UpdateDetailReward(entry)
    self:UpdateDetailScrollHeight()
end

function GQ.Log:SelectHunt(id, scrollToSelection, entryOverride)
    local entry = entryOverride or GQ.Data:GetEntryById(id)
    if not entry then
        return
    end

    local targetTab = self:IsEntryObtained(id) and "completed" or "active"
    if self:GetListTab() ~= targetTab then
        GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
        GearQuestForeverDB.ui.listTab = targetTab
    end

    self.selectedHuntId = id
    self.selectedEntry = entry
    self.scrollListToSelected = scrollToSelection == true

    if entry.slot then
        self:SetSlotCollapsed(GQ.Data:NormalizeSlotName(entry.slot), false)
    end

    self:ApplyEntryDetail(entry)
    self:Refresh()
end

function GQ.Log:Refresh()
    local classFile = GQ:GetEffectiveClass()
    local slots = GQ.Data:GetSlotsForClass(classFile)
    local layoutRows = {}
    local rowIndex = 0
    local yOffset = 0
    local selectedLayoutIndex
    local tab = self:GetListTab()

    self:UpdateTabVisuals()
    self:UpdateFooterButtons()
    self:UpdateContextStatus()

    if tab == "completed" then
        local anyCompleted = false

        for _, slotName in ipairs(slots) do
            local completed = self:GetCompletedSlotListEntries(slotName)
            if #completed > 0 then
                anyCompleted = true
                table.insert(layoutRows, { type = "header", slotName = slotName })

                if not self:IsSlotCollapsed(slotName, completed) then
                    for _, entry in ipairs(completed) do
                        table.insert(layoutRows, { type = "item", slotName = slotName, entry = entry })
                    end
                end
            end
        end

        if not anyCompleted then
            table.insert(layoutRows, { type = "empty_all" })
        end
    else
        for _, slotName in ipairs(slots) do
            local upgrades = self:GetActiveSlotListEntries(slotName)
            table.insert(layoutRows, { type = "header", slotName = slotName })

            if not self:IsSlotCollapsed(slotName, upgrades) then
                if #upgrades == 0 then
                    table.insert(layoutRows, { type = "empty", slotName = slotName })
                else
                    for _, entry in ipairs(upgrades) do
                        local rowType = GQ.Data:ShouldDisplayAsNotable(entry, slotName) and "notable" or "item"
                        table.insert(layoutRows, { type = rowType, slotName = slotName, entry = entry })
                    end
                end
            end
        end
    end

    for i, spec in ipairs(layoutRows) do
        if spec.entry then
            PrimeListEntryItemInfo(spec.entry)
        end
        if not self.listRows[i] then
            self.listRows[i] = self:CreateListRow(i)
        end
        local ok, err = pcall(self.ConfigureRow, self, self.listRows[i], yOffset, spec.type, spec.slotName, spec.entry)
        if not ok then
            print("|cffff0000GearQuest row error:|r " .. tostring(err))
        end
        if self.selectedHuntId and spec.entry and (spec.type == "item" or spec.type == "notable") then
            local selected = spec.entry.id == self.selectedHuntId
            if not selected and self.selectedEntry then
                local entryKey = GQ.Data:EntryListKey(spec.entry)
                local selectedKey = GQ.Data:EntryListKey(self.selectedEntry)
                selected = entryKey and selectedKey and entryKey == selectedKey
            end
            if selected then
                selectedLayoutIndex = i
            end
        end
        yOffset = yOffset + ROW_HEIGHT
        rowIndex = i
    end

    for i = rowIndex + 1, #self.listRows do
        self.listRows[i]:Hide()
    end

    self.frame.scrollChild:SetHeight(math.max(yOffset, 1))
    UpdateScrollChildRect(self.frame.scroll)

    ConfigurePanelScrollBar(self.frame.scroll)
    self:UpdateDetailScrollHeight()
    LayoutDetailScroll(self.frame)
    self:ApplyPageTab()

    if self.scrollListToSelected and selectedLayoutIndex then
        local layoutIndex = selectedLayoutIndex
        self.scrollListToSelected = false
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self.frame and self.frame:IsShown() then
                    self:ScrollListToRow(layoutIndex)
                end
            end)
        else
            self:ScrollListToRow(layoutIndex)
        end
    end

    if self.selectedHuntId then
        local record = GetHuntRecord(self.selectedHuntId)
        local entry = self.selectedEntry or GQ.Data:GetEntryById(self.selectedHuntId)
        local status = record and NormalizeHuntStatus(record.status)
        local clearSelection = false

        if not entry then
            clearSelection = true
        elseif tab == "completed" and status ~= "completed" and not self:IsEntryObtained(self.selectedHuntId) then
            clearSelection = true
        elseif tab == "active" and status == "completed" then
            clearSelection = true
        end

        if clearSelection then
            self.selectedHuntId = nil
            self.selectedEntry = nil
            self:ClearDetail()
        end
    end
end

function GQ.Log:Show()
    if not self.frame then
        return
    end

    ApplyModernChrome(self.frame)
    ApplyParchmentBackground(self.frame.detailBg)
    self:LayoutMainWindow(self.frame)
    LayoutDetailScroll(self.frame)
    BringLogWindowToFront(self.frame)
    self.frame:Show()
    self:LayoutSideTabs(self.frame)

    local refreshOk, refreshErr = pcall(function()
        self:Refresh()
    end)
    if not refreshOk then
        print("|cffff0000GearQuest log error:|r " .. tostring(refreshErr))
    end

    self:ScheduleAutoCompletionCheck()
end

function GQ.Log:Hide()
    self:HideSpecPicker()
    if self.frame then
        if self.frame.sideTabRail then
            self.frame.sideTabRail:Hide()
        end
        self.frame:Hide()
    end
end

function GQ.Log:Toggle()
    if not self.frame then
        return
    end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
