local _, GQ = ...

GQ.Log = GQ.Log or {}

local FRAME_WIDTH = 384
local FRAME_HEIGHT = 512
local ROW_HEIGHT = 16
local TAB_HEIGHT = 22
local TAB_BAR_PAD = 2
local TAB_ROW_HEIGHT = TAB_HEIGHT + TAB_BAR_PAD
local TAB_TOP_OFFSET = 54
local LIST_TOP_OFFSET = TAB_TOP_OFFSET + TAB_ROW_HEIGHT
local PORTRAIT_TEXTURE = "Interface\\AddOns\\GearQuest\\Art\\GearQuest-Portrait"
local PORTRAIT_DISPLAY_SIZE = 56

-- Content area below title bar and above footer buttons.
local HEADER_OFFSET = 74
local FOOTER_OFFSET = 38
local CONTENT_HEIGHT = FRAME_HEIGHT - HEADER_OFFSET - FOOTER_OFFSET
local LIST_SECTION_HEIGHT = math.max(120, math.floor(CONTENT_HEIGHT * 0.40) - 20)
local CONTENT_LEFT = 4
local CONTENT_RIGHT_GUTTER = 30
local PANEL_WIDTH = FRAME_WIDTH - CONTENT_LEFT - CONTENT_RIGHT_GUTTER
local PANEL_INSET = 2
local GUTTER_INSET = 6
local SECTION_DIVIDER_HEIGHT = 3
local METAL_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
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
local SCROLLBAR_INSET = 22

local function SafeGetItemIcon(itemId)
    if not itemId then
        return nil
    end

    if type(GetItemIcon) == "function" then
        return GetItemIcon(itemId)
    end

    return select(10, GetItemInfo(itemId))
end

local function GetListRowTextMaxWidth(row, leftInset)
    local width = row:GetWidth()
    if not width or width <= 0 then
        width = PANEL_WIDTH - (PANEL_INSET * 2)
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
    if not itemId or not GetItemInfo then
        return GetItemQualityColor(1)
    end

    GetItemInfo(itemId)
    local _, _, quality = GetItemInfo(itemId)
    return GetItemQualityColor(quality or 1)
end

local function PrimeListEntryItemInfo(entry)
    if entry and entry.itemId and GetItemInfo then
        GetItemInfo(entry.itemId)
    end
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
end
local TAB_GROUP_WIDTH = (88 * 2) + 4
local DETAIL_TEXT_COLOR = { 0.13, 0.09, 0.04 }
local LORE_TEXT_COLOR = { 0.20, 0.15, 0.10 }
local DETAIL_TEXT_HEX = "21160a"
local QUEST_DETAIL_TITLE_FONTS = {
    "QuestFont_Large", "QuestFont", "GameFontHighlight", "GameFontNormal",
}

local QUEST_DETAIL_HEADER_FONTS = {
    "QuestFont", "GameFontHighlight", "GameFontNormal",
}

local QUEST_DETAIL_BODY_FONTS = {
    "QuestFont", "GameFontHighlight", "GameFontNormal",
}

local function GetHuntRecord(id)
    GearQuestDB.hunts = GearQuestDB.hunts or {}
    return GearQuestDB.hunts[id]
end

local function GetObtainedTimestamp(id)
    GearQuestDB.obtained = GearQuestDB.obtained or {}
    return GearQuestDB.obtained[id]
end

local function IsDismissedCompleted(id)
    GearQuestDB.dismissedCompleted = GearQuestDB.dismissedCompleted or {}
    return GearQuestDB.dismissedCompleted[id] == true
end

local function EnsureHuntRecord(id)
    GearQuestDB.hunts = GearQuestDB.hunts or {}
    if not GearQuestDB.hunts[id] then
        GearQuestDB.hunts[id] = {
            status = "tracked",
            trackedAt = time(),
        }
    end
    return GearQuestDB.hunts[id]
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
    return tonumber(link:match("item:(%d+)"))
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
    GearQuestDB.crafted = GearQuestDB.crafted or {}
    return GearQuestDB.crafted[itemId]
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
    for _, font in ipairs(candidates) do
        local ok, fs = pcall(parent.CreateFontString, parent, nil, "ARTWORK", font)
        if ok and fs then
            return fs
        end
    end
    return parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
end

local PARCHMENT_TEXTURE = "Interface\\AddOns\\GearQuest\\Textures\\GQ-Parchment.png"

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

local function ApplyBlackBackground(parent)
    if parent.blackBg then
        return
    end
    local bg = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(0.02, 0.02, 0.02, 1)
    parent.blackBg = bg
end

local function ApplyMetalEdge(frame, edgeSize)
    if not frame or not frame.SetBackdrop then
        return
    end
    frame:SetBackdrop({
        edgeFile = METAL_EDGE,
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize or 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
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

    local scrollName = scroll:GetName()

    for _, suffix in ipairs({ "Top", "Bottom", "Middle", "Left", "Right" }) do
        local piece = _G[scrollName .. suffix]
        if piece then
            if piece.SetAlpha then
                piece:SetAlpha(1)
            end
            piece:Show()
        end
    end

    local scrollBar = _G[scrollName .. "ScrollBar"]
    if not scrollBar then
        return
    end

    if not scrollBar.gqTrackBg then
        local trackBg = scrollBar:CreateTexture(nil, "BACKGROUND", nil, -8)
        trackBg:SetAllPoints()
        trackBg:SetColorTexture(0, 0, 0, 1)
        scrollBar.gqTrackBg = trackBg
    end

    scrollBar:Show()
end

local function LayoutDetailScroll(frame)
    if not frame or not frame.detailScroll or not frame.detailBg then
        return
    end

    -- Parent to the log frame (not detailBg) so clipping/backdrop on the parchment
    -- panel does not hide the Blizzard scrollbar chrome.
    frame.detailScroll:SetParent(frame)
    frame.detailScroll:ClearAllPoints()
    frame.detailScroll:SetPoint("TOPLEFT", frame.detailBg, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    frame.detailScroll:SetPoint("BOTTOMRIGHT", frame.detailBg, "BOTTOMRIGHT", -PANEL_INSET, PANEL_INSET)
    frame.detailScroll:SetFrameLevel(frame.detailBg:GetFrameLevel() + 10)
    frame.detailScroll:Show()
    ConfigurePanelScrollBar(frame.detailScroll)
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

local function ApplyPortraitTexture(tex, texturePath)
    if not tex or not texturePath then
        return
    end

    tex:Show()
    tex:SetTexture(texturePath)
    -- WoW TGA rows are bottom-up; flip V so the portrait is right-side up.
    tex:SetTexCoord(0, 1, 1, 0)
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

local function SetupQuestLogPortrait(frame)
    if frame.gqBookIcon then
        frame.gqBookIcon:Hide()
    end

    if frame.gqPortraitHolder then
        frame.gqPortraitHolder:Hide()
    end

    local container = frame.PortraitContainer
        or (frame.GetName and _G[frame:GetName() .. "PortraitContainer"])
    if container then
        container:Show()
    end

    local tex = GetPortraitTexture(frame)
    if tex then
        ApplyPortraitTexture(tex, PORTRAIT_TEXTURE)
        return
    end

    local icon, holder = EnsureFallbackPortraitIcon(frame, container)
    local parent = container or frame
    if holder:GetParent() ~= parent then
        holder:SetParent(parent)
    end

    holder:ClearAllPoints()
    if container then
        holder:SetAllPoints(container)
        holder:SetFrameLevel(container:GetFrameLevel() + 1)
    else
        holder:SetSize(PORTRAIT_DISPLAY_SIZE, PORTRAIT_DISPLAY_SIZE)
        holder:SetFrameLevel(frame:GetFrameLevel() + 5)
        holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -7)
    end

    icon:ClearAllPoints()
    icon:SetAllPoints(holder)
    ApplyPortraitTexture(icon, PORTRAIT_TEXTURE)
    holder:Show()
end

function GQ.Log:GetListTab()
    GearQuestDB.ui = GearQuestDB.ui or {}
    return GearQuestDB.ui.listTab or "active"
end

function GQ.Log:SetListTab(tab)
    GearQuestDB.ui = GearQuestDB.ui or {}
    GearQuestDB.ui.listTab = tab
    self.selectedHuntId = nil
    self.selectedEntry = nil
    self:ClearDetail()
    self:Refresh()
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
    GearQuestDB.ui = GearQuestDB.ui or {}
    GearQuestDB.ui.collapsedSlots = GearQuestDB.ui.collapsedSlots or {}

    if GearQuestDB.ui.collapsedSlots[slotName] ~= nil then
        return GearQuestDB.ui.collapsedSlots[slotName]
    end

    -- Migrate saved collapse state from old duplicate categories.
    if slotName == "Finger" then
        for _, legacy in ipairs({ "Finger0", "Finger1" }) do
            if GearQuestDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestDB.ui.collapsedSlots[legacy]
            end
        end
    elseif slotName == "Trinket" then
        for _, legacy in ipairs({ "Trinket0", "Trinket1" }) do
            if GearQuestDB.ui.collapsedSlots[legacy] ~= nil then
                return GearQuestDB.ui.collapsedSlots[legacy]
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
    GearQuestDB.ui = GearQuestDB.ui or {}
    GearQuestDB.ui.collapsedSlots = GearQuestDB.ui.collapsedSlots or {}
    GearQuestDB.ui.collapsedSlots[slotName] = collapsed
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

    for id, record in pairs(GearQuestDB.hunts or {}) do
        if not seenId[id] and NormalizeHuntStatus(record.status) == "tracked" and not self:IsEntryObtained(id) then
            local entry = GQ.Data:GetEntryById(id)
            if entry and GQ.Data:EntryMatchesSlot(entry, slotName)
                and GQ.Data:EntryMatchesPlayerBand(entry)
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

    GearQuestDB.obtained = GearQuestDB.obtained or {}
    for id, obtainedAt in pairs(GearQuestDB.obtained) do
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

    for id, record in pairs(GearQuestDB.hunts or {}) do
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

    GearQuestDB.crafted = GearQuestDB.crafted or {}
    if GearQuestDB.crafted[itemId] then
        return false
    end

    GearQuestDB.crafted[itemId] = time()
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

function GQ.Log:IsEntryObtained(id)
    if not id then
        return false
    end
    if GetObtainedTimestamp(id) then
        return true
    end
    local record = GetHuntRecord(id)
    return record and NormalizeHuntStatus(record.status) == "completed"
end

function GQ.Log:IsItemIdObtained(itemId)
    if not itemId then
        return false
    end

    for _, entry in ipairs(GQ.Data:GetEntriesByItemId(itemId)) do
        if GQ.Data:EntryMatchesPlayer(entry) and self:IsEntryObtained(entry.id) then
            return true
        end
    end

    return false
end

function GQ.Log:ShouldAutoCompleteOnObtain(entry)
    if not entry or self:IsEntryObtained(entry.id) then
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

function GQ.Log:MarkEntryObtained(entry, options)
    if not entry or not entry.id or self:IsEntryObtained(entry.id) then
        return false
    end

    local now = time()
    GearQuestDB.obtained = GearQuestDB.obtained or {}
    GearQuestDB.obtained[entry.id] = now

    local record = GetHuntRecord(entry.id) or {}
    record.status = "completed"
    record.completedAt = now
    record.obtained = true
    GearQuestDB.hunts[entry.id] = record

    local showToast = not options or options.showToast ~= false
    if showToast and GQ.Toast then
        GQ.Toast:ShowForEntry(entry)
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
            GearQuestDB.obtained = GearQuestDB.obtained or {}
            GearQuestDB.obtained[id] = record.completedAt
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
        GearQuestDB.dismissedCompleted = GearQuestDB.dismissedCompleted or {}
        GearQuestDB.dismissedCompleted[id] = true
    end

    GearQuestDB.hunts[id] = nil

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
    GearQuestDB.hunts = {}
    GearQuestDB.obtained = {}
    GearQuestDB.crafted = {}
    GearQuestDB.dismissedCompleted = {}

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
        if entry and entry.id and not seen[entry.id] and not self:IsEntryObtained(entry.id) then
            seen[entry.id] = true
            table.insert(candidates, entry)
        end
    end

    for id, record in pairs(GearQuestDB.hunts or {}) do
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
                    local itemName = GQ.Data:GetEntryDisplayName(entry) or ("Item " .. entry.itemId)
                    if entry.sourceType == "profession" then
                        print("|cff66ccffGearQuest|r: Completed — " .. itemName .. " crafted.")
                    else
                        print("|cff66ccffGearQuest|r: Completed — " .. itemName .. " obtained.")
                    end
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
    C_Timer.After(0, function()
        self._listRefreshScheduled = false
        if self.frame and self.frame:IsShown() then
            self:Refresh()
        end
    end)
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
    if not self.frame or not self.frame.detailScroll then
        return
    end

    local contentHeight = self:MeasureDetailContentHeight()
    local visibleHeight = self.frame.detailScroll:GetHeight() or 120
    self.frame.detailChild:SetHeight(math.max(contentHeight, visibleHeight))
    UpdateScrollChildRect(self.frame.detailScroll)
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

    return row
end

function GQ.Log:EnsureTrackerEvents()
    if self.trackerFrame then
        return
    end

    local tracker = CreateFrame("Frame")
    tracker:RegisterEvent("BAG_UPDATE")
    tracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    tracker:RegisterEvent("MERCHANT_CLOSED")
    tracker:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    tracker:RegisterEvent("CHAT_MSG_SKILL")
    tracker:RegisterEvent("CHAT_MSG_LOOT")
    tracker:SetScript("OnEvent", function(_, event, msg)
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log then
            return
        end

        if event == "CHAT_MSG_SKILL" or event == "CHAT_MSG_LOOT" then
            log:HandleCraftChatMessage(msg)
            return
        end

        if event == "BAG_UPDATE" and GQ.Data and GQ.Data.CacheContainerItemLinks then
            GQ.Data:CacheContainerItemLinks()
        end

        if event == "GET_ITEM_INFO_RECEIVED" then
            log:ScheduleListRefresh()
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

    if arrowFrame.SetNormalTexture then
        arrowFrame:SetNormalTexture(nil)
        arrowFrame:SetPushedTexture(nil)
        arrowFrame:SetDisabledTexture(nil)
        arrowFrame:SetHighlightTexture(nil)
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

    local tabBar = frame.tabBar or frame
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

    local arrowFrame = CreateFrame("Frame", nil, control)
    frame.tabSpecArrow = arrowFrame
    self:ApplySpecArrowStyle(arrowFrame, iconFrame)
    self:WireSpecArrow(arrowFrame)

    frame.tabSpecControl = control
    frame.tabSpecIcon = iconFrame
    return control
end

function GQ.Log:RepositionSpecButton(frame)
    if not frame or not frame.tabBar then
        return
    end

    local tabBar = frame.tabBar
    local tabGroup = tabBar.tabGroup
    if not tabGroup then
        return
    end

    tabBar:SetHeight(TAB_HEIGHT)

    if tabGroup:GetParent() ~= tabBar then
        tabGroup:SetParent(tabBar)
    end

    tabGroup:ClearAllPoints()
    tabGroup:SetSize(TAB_GROUP_WIDTH, TAB_HEIGHT)
    tabGroup:SetPoint("CENTER", tabBar, "CENTER", 0, 0)

    self:EnsureSpecControl(frame)
    local control = frame.tabSpecControl
    if control then
        if control:GetParent() ~= tabBar then
            control:SetParent(tabBar)
        end
        control:ClearAllPoints()
        control:SetPoint("BOTTOMRIGHT", tabBar, "TOPRIGHT", -8, -SPEC_ROW_GAP)
    end
end

function GQ.Log:UpdateTabVisuals()
    if not self.frame or not self.frame.tabActive then
        return
    end

    local tab = self:GetListTab()
    local activeSelected = tab == "active"
    self.frame.tabActive:SetEnabled(not activeSelected)
    self.frame.tabCompleted:SetEnabled(activeSelected)
    self:UpdateSpecButton()
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

    if GQ.Spec and GQ.Spec.IsActive and GQ.Spec:IsActive() then
        control:Show()
        local specId = GQ.Spec:GetEffectiveSpec()
        if self.frame.tabSpecIcon and self.frame.tabSpecIcon.icon then
            self.frame.tabSpecIcon.icon:SetTexture(GQ.Spec:GetSpecIcon(specId, GQ:GetEffectiveClass()))
        end
    else
        control:Hide()
    end
    self:RepositionSpecButton(self.frame)
end

function GQ.Log:UpdateFooterButtons()
    if not self.frame then
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

function GQ.Log:EnsureTabBar(frame)
    if not frame.tabBar then
        local tabBar = CreateFrame("Frame", nil, frame)
        tabBar:SetHeight(TAB_HEIGHT)
        frame.tabBar = tabBar

        local tabGroup = CreateFrame("Frame", nil, tabBar)
        tabGroup:SetSize(TAB_GROUP_WIDTH, TAB_HEIGHT)
        tabGroup:SetPoint("CENTER", tabBar, "CENTER", 0, 0)
        tabBar.tabGroup = tabGroup

        local tabActive = CreateFrame("Button", "GearQuestLogTabActive", tabGroup, "UIPanelButtonTemplate")
        tabActive:SetSize(88, TAB_HEIGHT)
        tabActive:SetPoint("LEFT", tabGroup, "LEFT", 0, 0)
        tabActive:SetText("Active")
        frame.tabActive = tabActive

        local tabCompleted = CreateFrame("Button", "GearQuestLogTabCompleted", tabGroup, "UIPanelButtonTemplate")
        tabCompleted:SetSize(88, TAB_HEIGHT)
        tabCompleted:SetPoint("LEFT", tabActive, "RIGHT", 4, 0)
        tabCompleted:SetText("Completed")
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
    end

    if frame.tabBar and not frame.tabSpecControl then
        self:EnsureSpecControl(frame)
    end

    self:RepositionSpecButton(frame)

    frame.tabBar:ClearAllPoints()
    if frame.tabBar:GetParent() ~= frame then
        frame.tabBar:SetParent(frame)
    end
    frame.tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_LEFT, -TAB_TOP_OFFSET)
    frame.tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CONTENT_RIGHT_GUTTER, -TAB_TOP_OFFSET)

    if frame.listInset then
        frame.listInset:ClearAllPoints()
        frame.listInset:SetPoint("TOPLEFT", frame.tabBar, "BOTTOMLEFT", 0, -TAB_BAR_PAD)
        frame.listInset:SetSize(PANEL_WIDTH, LIST_SECTION_HEIGHT)
    end

    if frame.scroll and frame.listInset then
        frame.scroll:ClearAllPoints()
        frame.scroll:SetPoint("TOPLEFT", frame.listInset, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
        frame.scroll:SetPoint("BOTTOMRIGHT", frame.listInset, "BOTTOMRIGHT", -PANEL_INSET, PANEL_INSET)
        ConfigurePanelScrollBar(frame.scroll)
    end

    if frame.listGutter and frame.listInset then
        frame.listGutter:ClearAllPoints()
        frame.listGutter:SetPoint("TOPLEFT", frame.listInset, "TOPRIGHT", 0, 0)
        frame.listGutter:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -GUTTER_INSET, -(LIST_TOP_OFFSET + LIST_SECTION_HEIGHT))
    end

    self:UpdateTabVisuals()
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
    GearQuestDB.obtained = GearQuestDB.obtained or {}
    GearQuestDB.crafted = GearQuestDB.crafted or {}
    GearQuestDB.dismissedCompleted = GearQuestDB.dismissedCompleted or {}

    for id, record in pairs(GearQuestDB.hunts or {}) do
        if NormalizeHuntStatus(record.status) == "completed" and not GearQuestDB.obtained[id] then
            GearQuestDB.obtained[id] = record.completedAt or record.trackedAt or time()
        end
    end

    for id, obtainedAt in pairs(GearQuestDB.obtained) do
        local entry = GQ.Data:GetEntryById(id)
        if entry and entry.sourceType == "profession" and entry.itemId and not GearQuestDB.crafted[entry.itemId] then
            GearQuestDB.crafted[entry.itemId] = obtainedAt
        end
    end
end

function GQ.Log:Init()
    self:MigrateObtainedRecords()

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
    ApplyLogWindowLayer(frame)
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    SetFrameTitle(frame, "GearQuest Log")
    SetupQuestLogPortrait(frame)

    frame.listInset = CreateFrame("Frame", nil, frame)
    frame.listInset:SetSize(PANEL_WIDTH, LIST_SECTION_HEIGHT)
    ApplyBlackBackground(frame.listInset)
    ApplyMetalEdge(frame.listInset, 12)

    frame.scroll = CreatePanelScrollFrame("GearQuestLogListScrollFrame", frame.listInset)
    frame.scroll:SetPoint("TOPLEFT", frame.listInset, "TOPLEFT", PANEL_INSET, -PANEL_INSET)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame.listInset, "BOTTOMRIGHT", -PANEL_INSET, PANEL_INSET)

    frame.scrollChild = CreateFrame("Frame", "GearQuestLogListScrollChild", frame.scroll)
    frame.scrollChild:SetWidth(PANEL_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET)
    frame.scrollChild:SetHeight(1)
    frame.scroll:SetScrollChild(frame.scrollChild)

    frame.listGutter = CreateFrame("Frame", nil, frame)

    frame.sectionDivider = CreateSectionDivider(frame)
    frame.sectionDivider:SetPoint("TOPLEFT", frame.listInset, "BOTTOMLEFT", 0, 0)
    frame.sectionDivider:SetPoint("TOPRIGHT", frame.listInset, "BOTTOMRIGHT", 0, 0)

    frame.detailBg = CreateFrame("Frame", nil, frame)
    frame.detailBg:SetPoint("TOPLEFT", frame.sectionDivider, "BOTTOMLEFT", 0, 0)
    frame.detailBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_RIGHT_GUTTER, FOOTER_OFFSET)
    EnableClipping(frame.detailBg)
    ApplyParchmentBackground(frame.detailBg)
    ApplyMetalEdge(frame.detailBg, 12)

    frame.detailScroll = CreatePanelScrollFrame("GearQuestLogDetailScrollFrame", frame)
    LayoutDetailScroll(frame)

    frame.detailChild = CreateFrame("Frame", "GearQuestLogDetailScrollChild", frame.detailScroll)
    frame.detailChild:SetWidth(PANEL_WIDTH - (PANEL_INSET * 2) - SCROLLBAR_INSET - 8)
    frame.detailScroll:SetScrollChild(frame.detailChild)

    frame.detailGutter = CreateFrame("Frame", nil, frame)
    frame.detailGutter:SetPoint("TOPLEFT", frame.detailBg, "TOPRIGHT", 0, 0)
    frame.detailGutter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -GUTTER_INSET, FOOTER_OFFSET)

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
    frame.exitBtn:SetPoint("LEFT", frame.untrackBtn, "RIGHT", 2, 0)
    frame.exitBtn:SetText("Exit")

    self:WireControls(frame)
    self:EnsureTrackerEvents()
    self:EnsureTabBar(frame)

    self.listRows = {}
    self.frame = frame
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

    local visibleHeight = scroll:GetHeight() or LIST_SECTION_HEIGHT
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

    local suffixHint = GQ.Data:GetSuffixHint(entry)
    if suffixHint then
        table.insert(lines, "\nRandom enchant: " .. suffixHint)
    end

    if entry.proc then
        table.insert(lines, "\nWhy it's good: " .. entry.proc)
    end

    if GQ.Data:ShouldDisplayAsNotable(entry, entry and entry.slot) and entry.proc then
        table.insert(lines, "\nWorth considering — the proc is the point.")
    end

    if entry.origin == "guide" then
        table.insert(lines, "\nRanked from the Wowhead Classic BiS guide.")
    end

    if entry.sourceType == "world_drop" then
        local isBoE = GQ.Equip and GQ.Equip.IsBindOnEquip and GQ.Equip:IsBindOnEquip(entry.itemId)
        if isBoE then
            table.insert(lines, "\nAlso available on the Auction House (binds when equipped).")
        end
    end

    if entry.sourceType == "profession" then
        local isBoE = GQ.Equip and GQ.Equip.IsBindOnEquip and GQ.Equip:IsBindOnEquip(entry.itemId)
        if isBoE then
            table.insert(lines, "\nAlso available on the Auction House (crafted by others; binds when equipped).")
        end
    end

    if entry.zone then
        table.insert(lines, "\nZone: " .. entry.zone)
    end
    if entry.questName then
        table.insert(lines, "Quest: " .. entry.questName)
    end
    if entry.npc then
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
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        if not log or not log.frame or not log.frame:IsShown() then
            return
        end

        log:ScheduleListRefresh()

        local entry = log.selectedEntry or GQ.Data:GetEntryById(log.selectedHuntId)
        if not entry then
            return
        end

        log:UpdateDetailReward(entry)
        if entry.sourceType == "world_drop" then
            log:SelectHunt(log.selectedHuntId, false, entry)
        end
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
    self.frame.detailTitle:SetText("|cff" .. DETAIL_TEXT_HEX .. itemName:upper() .. "|r")
    self.frame.detailTitle:SetTextColor(DETAIL_TEXT_COLOR[1], DETAIL_TEXT_COLOR[2], DETAIL_TEXT_COLOR[3])

    local lore = entry.lore
    if self.frame.detailLore then
        if lore and lore ~= "" then
            self.frame.detailLore:SetText(lore)
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
    self.frame.detailBody:SetText(table.concat(lines, "\n"))

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
        GearQuestDB.ui = GearQuestDB.ui or {}
        GearQuestDB.ui.listTab = targetTab
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

    local detailVisible = self.frame.detailScroll:GetHeight() or 0
    local detailContent = self.frame.detailChild:GetHeight() or 0
    if detailContent < detailVisible then
        self.frame.detailChild:SetHeight(detailVisible + 2)
        UpdateScrollChildRect(self.frame.detailScroll)
    end
    LayoutDetailScroll(self.frame)

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

    SetupQuestLogPortrait(self.frame)
    ApplyParchmentBackground(self.frame.detailBg)
    LayoutDetailScroll(self.frame)
    BringLogWindowToFront(self.frame)
    self.frame:Show()

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
