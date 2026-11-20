local ADDON_NAME, GQ = ...
local L = GQ.L

local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 0.95, 0.85 }
local WHITE_DIM = { 0.78, 0.75, 0.7 }
local SCROLLBAR_WIDTH = 18
local PANEL_W = 720
local PANEL_H = 420
local COLUMN_W = math.floor((PANEL_W - 48) / 2) - 12
local PREVIEW_H = 76
-- Tall enough for max target (header + 3 lines) and item (stats + enchant + score + other specs).
local PREVIEW_BOX_H = 140
local SETTINGS_LEFT_PAD = 34
local SETTINGS_CHECK_COLUMN = 30
local SLIM_SCROLL_W = 6
local SCROLL_GOLD = { 0.9, 0.75, 0.28 }
local PREVIEW_DATA_REV = 12
local PREVIEW_SAMPLE_ITEM_ID = 1981
local PREVIEW_CREATURE_FALLBACK = "Elder Crag Coyote"
local PREVIEW_MOB_LEVEL = 40
local PREVIEW_HUNTER_LEVEL = 50
local PREVIEW_HUNTER_SPEC = "beast_mastery"
local PREVIEW_ITEM_FALLBACK = "Icemail Jerkin"
local PREVIEW_ITEM_ENTRY = { itemId = PREVIEW_SAMPLE_ITEM_ID, slot = "Chest" }

local function localeText(key, english)
    local t = L[key]
    if t and t ~= key then
        return t
    end
    return english
end

local function tooltipsLabelFont(fs)
    if not fs then
        return
    end
    if fs.SetFontObject then
        fs:SetFontObject(GameFontNormal)
    elseif fs.SetFont then
        local font, size, flags = GameFontNormal:GetFont()
        if font then
            fs:SetFont(font, size or 12, flags or "")
        end
    end
    if GQ.CalmFont then
        GQ:CalmFont(fs)
    end
end

local function tooltipsHintFont(fs)
    if not fs then
        return
    end
    if fs.SetFontObject then
        fs:SetFontObject(GameFontNormalSmall)
    elseif fs.SetFont then
        local font, size, flags = GameFontNormalSmall:GetFont()
        if font then
            fs:SetFont(font, size or 10, flags or "")
        end
    end
    if GQ.CalmFont then
        GQ:CalmFont(fs)
    end
end

local function colorFontStringWhite(fs, dim)
    if not fs or not fs.SetTextColor then
        return
    end
    if dim then
        fs:SetTextColor(WHITE_DIM[1], WHITE_DIM[2], WHITE_DIM[3])
    else
        fs:SetTextColor(WHITE[1], WHITE[2], WHITE[3])
    end
end

local function labelOnHit(frame, hitKey)
    local hit = frame and frame[hitKey]
    if not hit then
        return nil
    end
    local labelKey = hitKey:gsub("Hit$", "")
    if labelKey == hitKey then
        labelKey = hitKey:gsub("LabelHit$", "Label")
    end
    return frame[labelKey]
end

local LEFT_SETTING_KEYS = {
    "settingsUnitGearLabel", "settingsUnitGearLabelHit", "settingsUnitGearCheck", "settingsUnitGearHint",
    "settingsUnitGearAlwaysLabel", "settingsUnitGearAlwaysLabelHit", "settingsUnitGearAlwaysCheck", "settingsUnitGearAlwaysHint",
    "settingsUnitGearChanceLabel", "settingsUnitGearChanceLabelHit", "settingsUnitGearChanceCheck", "settingsUnitGearChanceHint",
    "settingsUnitGearSourcesLabel", "settingsUnitGearSourcesRow", "settingsUnitGearSourcesBtn", "settingsUnitGearSourcesHint",
    "settingsUnitGearMinDropLabel", "settingsUnitGearMinDropLabelHit", "settingsUnitGearMinDropValue",
    "settingsUnitGearMinDropSlider", "settingsUnitGearMinDropHint",
}

local RIGHT_SETTING_KEYS = {
    "settingsEnchantLabel", "settingsEnchantLabelHit", "settingsEnchantCheck", "settingsEnchantHint",
    "settingsScoreLabel", "settingsScoreLabelHit", "settingsScoreCheck", "settingsScoreHint",
    "settingsOtherSpecLabel", "settingsOtherSpecLabelHit", "settingsOtherSpecCheck", "settingsOtherSpecHint",
}

local function wheelScroll(scroll, arg2, arg3)
    if not scroll or not scroll.GetVerticalScrollRange then
        return
    end
    -- OnMouseWheel calls this as (scroll, delta). Child handlers call (scroll, nil, delta).
    local delta = arg3
    if delta == nil then
        delta = arg2
    end
    if not delta or delta == 0 then
        return
    end
    local range = scroll:GetVerticalScrollRange() or 0
    if range <= 0 then
        return
    end
    local step = 40
    local cur = scroll:GetVerticalScroll() or 0
    scroll:SetVerticalScroll(math.max(0, math.min(range, cur - delta * step)))
    local log = GQ.Log
    if log and log.UpdateTooltipsSlimScrollBar then
        log:UpdateTooltipsSlimScrollBar(scroll)
    end
end

local function tooltipsItemQualityHex(quality)
    local color = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if not color then
        return "ff1eff00"
    end
    return string.format(
        "%02x%02x%02x",
        math.floor((color.r or 1) * 255 + 0.5),
        math.floor((color.g or 1) * 255 + 0.5),
        math.floor((color.b or 1) * 255 + 0.5)
    )
end

local function wireTooltipsScroll(scroll)
    if not scroll then
        return
    end
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)
    if scroll.SetClipsChildren then
        scroll:SetClipsChildren(true)
    end
    scroll:SetScript("OnMouseWheel", wheelScroll)
end

local function makePreviewBox(parent, dark)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    if dark then
        box:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
        box:SetBackdropBorderColor(0.45, 0.4, 0.35, 1)
    end
    box:EnableMouse(false)
    local text = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -6)
    text:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -8, 6)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetTextColor(1, 1, 1)
    box.previewText = text
    return box
end

local function layoutColumnScroll(panel, side)
    local scroll = side == "left" and panel.leftScroll or panel.rightScroll
    local child = side == "left" and panel.leftScrollChild or panel.rightScrollChild
    if not scroll or not child then
        return
    end
    child:SetWidth(COLUMN_W - SCROLLBAR_WIDTH - 4)
    local last = side == "left" and panel.leftSettingsLast or panel.rightSettingsLast
    if not last and side == "left" then
        last = panel._frame and panel._frame.settingsUnitGearMinDropHint
    end
    if not last and side == "right" then
        last = panel._frame and panel._frame.settingsOtherSpecHint
    end
    local top = child:GetTop()
    local bottom = last and last.GetBottom and last:GetBottom()
    local height = 220
    if top and bottom and top > bottom then
        height = (top - bottom) + 28
    end
    child:SetHeight(math.max(height, 120))
    if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    elseif _G.ScrollFrame_UpdateScrollChildRect then
        ScrollFrame_UpdateScrollChildRect(scroll)
    end
end

function GQ.Log:LayoutTooltipsPanelChrome(panel)
    if not panel then
        return
    end
    panel:SetSize(PANEL_W, PANEL_H)
    local previewH = PREVIEW_BOX_H
    local scrollH = PANEL_H - previewH - 118
    if panel.leftScroll then
        panel.leftScroll:SetHeight(scrollH)
        panel.leftScroll:SetWidth(COLUMN_W)
    end
    if panel.rightScroll then
        panel.rightScroll:SetHeight(scrollH)
        panel.rightScroll:SetWidth(COLUMN_W)
    end
    if panel.leftPreview then
        panel.leftPreview:SetWidth(COLUMN_W)
        panel.leftPreview:SetHeight(PREVIEW_BOX_H)
    end
    if panel.rightPreview then
        panel.rightPreview:SetWidth(COLUMN_W)
        panel.rightPreview:SetHeight(PREVIEW_BOX_H)
    end
    if GQ.Log.UpdateTooltipsSlimScrollBar then
        if panel.leftScroll then
            GQ.Log:UpdateTooltipsSlimScrollBar(panel.leftScroll)
        end
        if panel.rightScroll then
            GQ.Log:UpdateTooltipsSlimScrollBar(panel.rightScroll)
        end
    end
end

function GQ.Log:HideBlizzardTooltipsScrollBar(scroll)
    if not scroll or not scroll.GetName then
        return
    end
    local scrollName = scroll:GetName()
    local bar = scroll.ScrollBar or _G[scrollName .. "ScrollBar"]
    if bar then
        bar:Hide()
        if bar.SetAlpha then
            bar:SetAlpha(0)
        end
        if bar.EnableMouse then
            bar:EnableMouse(false)
        end
    end
    for _, suffix in ipairs({ "Top", "Bottom", "Middle" }) do
        local region = _G[scrollName .. suffix]
        if region and region.Hide then
            region:Hide()
        end
    end
end

function GQ.Log:EnsureTooltipsSlimScroll(scroll)
    if not scroll then
        return
    end
    self:HideBlizzardTooltipsScrollBar(scroll)
    if scroll.gqSlimBar and scroll.gqSlimThumb then
        return
    end
    local bar = CreateFrame("Frame", nil, scroll)
    bar:SetWidth(SLIM_SCROLL_W)
    bar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
    bar:EnableMouse(false)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(SCROLL_GOLD[1], SCROLL_GOLD[2], SCROLL_GOLD[3], 1)
    thumb:SetWidth(SLIM_SCROLL_W)
    scroll.gqSlimBar = bar
    scroll.gqSlimThumb = thumb
end

function GQ.Log:UpdateTooltipsSlimScrollBar(scroll)
    if not scroll then
        return
    end
    self:EnsureTooltipsSlimScroll(scroll)
    self:HideBlizzardTooltipsScrollBar(scroll)
    local bar = scroll.gqSlimBar
    local thumb = scroll.gqSlimThumb
    if not bar or not thumb then
        return
    end
    if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    end
    local range = 0
    if scroll.GetVerticalScrollRange then
        range = scroll:GetVerticalScrollRange() or 0
    end
    if range <= 0 then
        bar:Hide()
        return
    end
    bar:Show()
    local viewH = scroll:GetHeight() or 1
    local child = scroll.GetScrollChild and scroll:GetScrollChild()
    local contentH = (child and child.GetHeight and child:GetHeight()) or viewH
    contentH = math.max(contentH, viewH + 1)
    local thumbH = math.max(24, math.floor(viewH * viewH / contentH))
    thumbH = math.min(thumbH, viewH)
    local cur = scroll.GetVerticalScroll and scroll:GetVerticalScroll() or 0
    local travel = math.max(0, viewH - thumbH)
    local offset = range > 0 and (cur / range) * travel or 0
    thumb:SetHeight(thumbH)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", bar, "TOP", 0, -offset)
    thumb:SetPoint("LEFT", bar, "LEFT", 0, 0)
    thumb:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
end

-- Legacy name used while the panel is built.
function GQ.Log:StyleTooltipsSlimScrollBar(scroll)
    self:UpdateTooltipsSlimScrollBar(scroll)
end

function GQ.Log:StyleTooltipsPanelMinDropSlider(slider)
    if not slider then
        return
    end
    if slider.gqMinDropTrack then
        slider.gqMinDropTrack:Hide()
    end
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    if thumb then
        if thumb.SetTexture then
            thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        end
        if thumb.SetVertexColor then
            thumb:SetVertexColor(1, 1, 1)
        end
        if thumb.SetSize then
            thumb:SetSize(32, 32)
        end
    end
    local sliderName = slider.GetName and slider:GetName()
    local lowText = slider.Low or (sliderName and _G[sliderName .. "Low"])
    local highText = slider.High or (sliderName and _G[sliderName .. "High"])
    local titleText = slider.Text or (sliderName and _G[sliderName .. "Text"])
    local ends = { lowText, highText }
    for i = 1, #ends do
        local fs = ends[i]
        if fs then
            if tooltipsHintFont then
                tooltipsHintFont(fs)
            end
            if fs.SetTextColor then
                fs:SetTextColor(WHITE[1], WHITE[2], WHITE[3])
            end
        end
    end
    if titleText then
        titleText:SetText("")
        if titleText.Hide then
            titleText:Hide()
        end
    end
end

function GQ.Log:LayoutTooltipsPanelTargetSources(frame)
    local row = frame and frame.settingsUnitGearSourcesRow
    local btn = frame and frame.settingsUnitGearSourcesBtn
    local label = frame and frame.settingsUnitGearSourcesLabel
    local hint = frame and frame.settingsUnitGearSourcesHint
    if not row or not btn or not hint then
        return
    end
    if label then
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(true)
    end
    local textH = label and label.GetStringHeight and label:GetStringHeight() or 16
    row:SetHeight(math.max(textH + 4, 18))

    hint:ClearAllPoints()
    hint:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
    btn:SetHeight(22)
    if GQ.FitButton then
        GQ:FitButton(btn, math.min(170, COLUMN_W - 8))
    else
        btn:SetWidth(math.min(170, COLUMN_W - 8))
    end
end

local function tooltipsExamplePrefix()
    return localeText("Tooltip preview hunter example prefix", "Example (Hunter):")
end

local PREVIEW_STAT_SKIP = {
    ["Item Level"] = true,
    ["Requires Level"] = true,
    ["Binds when picked up"] = true,
    ["Binds when equipped"] = true,
    ["Unique"] = true,
    ["Unique-Equipped"] = true,
}

function GQ.Log:TooltipsPreviewWithHunterDemo(fn)
    if type(fn) ~= "function" then
        return nil
    end
    local data = GQ.Data
    local savedPreview = GQ._tooltipsPanelPreview
    GQ._tooltipsPanelPreview = true
    local savedCtx = GQ._ctx
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or "Alliance"
    GQ._ctx = {
        class = "HUNTER",
        spec = PREVIEW_HUNTER_SPEC,
        level = PREVIEW_HUNTER_LEVEL,
        faction = faction,
    }
    local savedBand = self._slotRankBand
    local savedRanks = self._slotRankCache
    local savedSlots = data and data._catalogSlots
    local savedQuery = data and data._queryCache
    local savedUnit = data and data._unitGearCache
    local savedProbe = self._specProbeStore
    local savedOther = self._otherSpecRankCache
    self._slotRankBand = nil
    self._slotRankCache = nil
    self._specProbeStore = nil
    if data and data.EnsureClassLoaded then
        data:EnsureClassLoaded("HUNTER")
    end
    local ok, a, b, c, d, e, f = pcall(fn)
    GQ._ctx = savedCtx
    GQ._tooltipsPanelPreview = savedPreview
    self._slotRankBand = savedBand
    self._slotRankCache = savedRanks
    self._specProbeStore = savedProbe
    self._otherSpecRankCache = savedOther
    if data then
        data._catalogSlots = savedSlots
        data._queryCache = savedQuery
        data._unitGearCache = savedUnit
    end
    if ok then
        return a, b, c, d, e, f
    end
    return nil
end

function GQ.Log:TooltipsPreviewMobDropSkip(mobName)
    local key = self:TooltipsPreviewMobNormKey(mobName)
    local rows = key and GQ.Data and GQ.Data.mobDrops and GQ.Data.mobDrops[key]
    local skip = {}
    for i = 1, #(rows or {}) do
        local row = rows[i]
        if row then
            skip[row[1]] = true
        end
    end
    return skip, key
end

function GQ.Log:EnsureTooltipsPreviewData()
    if self._tooltipsPreviewPaint then
        return self._tooltipsPreviewPaint
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.hideUnitGearTips then
        return nil
    end
    return self:BuildTooltipsPreviewPaint()
end

function GQ.Log:TooltipsPreviewMobNormKey(name)
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

local function TooltipsPreviewWorldDropsAtLevel(data, mobLevel, skip, mobKey)
    if not data or not data.TopWorldDrops then
        return nil, nil, mobLevel
    end
    local worldPicks, worldMeta = data:TopWorldDrops(mobLevel, skip, 3, mobKey)
    if worldPicks and worldPicks[1] then
        return worldPicks, worldMeta, mobLevel
    end
    for delta = 1, 8 do
        local tryUp = mobLevel + delta
        local tryDown = mobLevel - delta
        if tryUp <= 60 then
            worldPicks, worldMeta = data:TopWorldDrops(tryUp, skip, 3, mobKey)
            if worldPicks and worldPicks[1] then
                return worldPicks, worldMeta, tryUp
            end
        end
        if tryDown >= 1 then
            worldPicks, worldMeta = data:TopWorldDrops(tryDown, skip, 3, mobKey)
            if worldPicks and worldPicks[1] then
                return worldPicks, worldMeta, tryDown
            end
        end
    end
    return worldPicks, worldMeta, mobLevel
end

function GQ.Log:TooltipsPreviewLinesForMob(data, mobName, mobLevel)
    if not data or not mobName then
        return nil, nil, mobLevel
    end
    local skip, mobKey = self:TooltipsPreviewMobDropSkip(mobName)
    local unitPicks = data.TopUnitGear and data:TopUnitGear(mobName, 3, nil)
    local worldPicks, _, levelUsed = TooltipsPreviewWorldDropsAtLevel(data, mobLevel, skip, mobKey)
    return unitPicks, worldPicks, levelUsed
end

function GQ.Log:TooltipsPreviewMobLines(mobName, mobLevel)
    return self:TooltipsPreviewWithHunterDemo(function()
        local data = GQ.Data
        if not data or not mobName then
            return nil, nil, nil, nil, mobLevel
        end
        local skip, mobKey = self:TooltipsPreviewMobDropSkip(mobName)
        mobLevel = tonumber(mobLevel) or PREVIEW_MOB_LEVEL
        local unitPicks, unitMeta = data.TopUnitGear and data:TopUnitGear(mobName, 3, nil)
        local worldPicks, worldMeta, levelUsed = TooltipsPreviewWorldDropsAtLevel(data, mobLevel, skip, mobKey)
        return unitPicks, worldPicks, unitMeta, worldMeta, levelUsed
    end)
end

-- Fixed sample for the coyote box. Elder Crag Coyote is not in the named-drop
-- index, and a geared character would hide level-40 world drops that do not
-- beat what is worn. These lines are a level-50 beast mastery hunter's world
-- drops whose range includes the sample mob. They do not start the world-drop
-- build and they do not look at worn gear.
function GQ.Log:CollectTooltipsPreviewSample()
    local data = GQ.Data
    if not data or not data.WorldDropSlotEntries then
        return nil
    end
    local ranges = data.genericWorldDropRanges
    local slots = { "Chest", "Hands", "Wrist" }
    local picks = {}
    local seen = {}
    for s = 1, #slots do
        local rows = data:WorldDropSlotEntries(slots[s], 10) or {}
        local chosen
        for i = 1, #rows do
            local entry = rows[i]
            local itemId = entry and entry.itemId
            local range = itemId and type(ranges) == "table" and ranges[itemId]
            if itemId and not seen[itemId] and type(range) == "table"
                and range[1] <= PREVIEW_MOB_LEVEL and PREVIEW_MOB_LEVEL <= range[2] then
                chosen = entry
                break
            end
        end
        if not chosen then
            for i = 1, #rows do
                local entry = rows[i]
                local itemId = entry and entry.itemId
                if itemId and not seen[itemId] then
                    chosen = entry
                    break
                end
            end
        end
        if chosen and chosen.itemId then
            seen[chosen.itemId] = true
            picks[#picks + 1] = {
                entry = chosen,
                kind = "w",
                rank = chosen.curatedRank,
            }
        end
    end
    return #picks > 0 and picks or nil
end

function GQ.Log:PickTooltipsPreviewSampleEntry()
    local slots = { "Trinket", "Neck", "Finger0", "Chest" }
    for s = 1, #slots do
        local list = self:GetSlotRankList(slots[s])
        for i = 1, math.min(30, #list) do
            local entry = list[i]
            if entry and entry.itemId == PREVIEW_SAMPLE_ITEM_ID then
                return entry
            end
        end
    end
    local list = self:GetSlotRankList("Trinket")
    return (list and list[1]) or { itemId = PREVIEW_SAMPLE_ITEM_ID }
end

-- Sample lines for the coyote box. Real world drops a level-40 mob can drop.
-- Names come from the audit. Chances are read from the packed drop table.
-- Nothing here walks a hunt list or starts the world-drop pass.
local PREVIEW_SAMPLE_DROPS = {
    { itemId = 1981, slot = "Chest" },
    { itemId = 4080, slot = "Head" },
    { itemId = 6426, slot = "Wrist" },
}

local function previewQualityHex(quality)
    local colors = ITEM_QUALITY_COLORS
    local color = colors and quality and colors[quality]
    if not color then
        return "1eff00"
    end
    return string.format(
        "%02x%02x%02x",
        math.floor((color.r or 1) * 255 + 0.5),
        math.floor((color.g or 1) * 255 + 0.5),
        math.floor((color.b or 1) * 255 + 0.5)
    )
end

local function previewOpenChance(itemId)
    local data = GQ.Data
    if not data or not itemId then
        return nil
    end
    if type(data.worldDropOpenChance) == "table" then
        local stored = tonumber(data.worldDropOpenChance[itemId])
        if stored and stored > 0 then
            return stored
        end
    end
    local packed = data.worldDropOpenChancePacked
    if type(packed) ~= "string" then
        return nil
    end
    local cent = string.match(packed, "^" .. itemId .. ":(%d+)")
        or string.match(packed, "," .. itemId .. ":(%d+)")
    cent = tonumber(cent)
    if not cent or cent <= 0 then
        return nil
    end
    return cent * 0.01
end

local function previewDropText(chance)
    chance = tonumber(chance)
    if not chance or chance <= 0 then
        return nil
    end
    if math.abs(chance - math.floor(chance + 0.0001)) < 0.001 then
        return string.format("%.0f", chance)
    end
    return string.format("%.2f", chance)
end

-- Hunter chest enchant for the item example. Uses the loaded weight row.
-- It does not load a class catalog.
local function previewEnchantLine(entry)
    if not (GQ.Enchant and GQ.Enchant.Text and entry) then
        return nil
    end
    local saved = GQ._ctx
    local faction = (GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()) or "Alliance"
    GQ._ctx = {
        class = "HUNTER",
        spec = PREVIEW_HUNTER_SPEC,
        level = PREVIEW_HUNTER_LEVEL,
        faction = faction,
    }
    local ok, line = pcall(GQ.Enchant.Text, GQ.Enchant, nil, entry)
    GQ._ctx = saved
    if ok and type(line) == "string" and line ~= "" then
        return line
    end
    return nil
end

-- The item half of the example. Drop lines are painted on each refresh so
-- the chance checkbox and the minimum slider match the live tooltip.
function GQ.Log:BuildTooltipsPreviewPaint()
    if self._tooltipsPreviewPaint then
        return self._tooltipsPreviewPaint
    end
    if self._tooltipsPreviewBuilding then
        return nil
    end
    self._tooltipsPreviewBuilding = true
    local paint = {
        entry = PREVIEW_ITEM_ENTRY,
        stats = self:TooltipsPreviewItemStatLines(PREVIEW_ITEM_ENTRY),
    }
    self._tooltipsPreviewPaint = paint
    self._tooltipsPreviewBuilding = nil
    return paint
end

function GQ.Log:TooltipsPreviewDropLines(settings)
    settings = settings or {}
    local hidden = settings.unitGearHiddenSources
    if hidden and hidden.world_drop then
        return nil, false
    end
    local showChance = settings.unitGearShowDropChance ~= false
    local minPct = tonumber(settings.unitGearMinDropPercent) or 0
    if minPct < 0 then
        minPct = 0
    end
    local audit = GQ.Data and GQ.Data.foreverAudit
    local lines = {}
    local hiddenByMin = 0
    for i = 1, #PREVIEW_SAMPLE_DROPS do
        local row = PREVIEW_SAMPLE_DROPS[i]
        local fact = audit and audit[row.itemId]
        local name = fact and fact.name
        local chance = previewOpenChance(row.itemId)
        if name and name ~= "" then
            if minPct > 0 and chance and chance < minPct then
                hiddenByMin = hiddenByMin + 1
            else
                local slotLabel = (GQ.Data and GQ.Data.SlotLabel and GQ.Data:SlotLabel(row.slot)) or row.slot
                local line = string.format(
                    "%d. |cff%s%s|r |cffc8c0b0(%s)|r",
                    #lines + 1,
                    previewQualityHex(fact.quality),
                    name,
                    slotLabel
                )
                if showChance then
                    local pct = previewDropText(chance)
                    if pct then
                        line = line .. string.format(" |cff888888(%s%%)|r", pct)
                    end
                end
                lines[#lines + 1] = line
            end
        end
    end
    return lines, hiddenByMin > 0 and #lines == 0
end

function GQ.Log:TooltipsPreviewSampleLines()
    local paint = self._tooltipsPreviewPaint
    return paint and paint.picks or nil
end

function GQ.Log:PickTooltipsPreviewMobAndPick()
    local data = GQ.Data
    if not data then
        return nil, nil, nil, nil, nil, nil
    end
    local name = PREVIEW_CREATURE_FALLBACK
    local mobLevel = PREVIEW_MOB_LEVEL
    local unitPicks, worldPicks, levelUsed = self:TooltipsPreviewLinesForMob(data, name, mobLevel)
    mobLevel = levelUsed or mobLevel
    local pick = (unitPicks and unitPicks[1]) or (worldPicks and worldPicks[1])
    local picks = worldPicks
    if unitPicks and unitPicks[1] then
        picks = unitPicks
    end
    return name, mobLevel, unitPicks, worldPicks, pick, picks
end

function GQ.Log:TooltipsPreviewCreatureDisplayName(englishName)
    englishName = englishName or self:TooltipsPreviewCreatureName()
    if GQ.TN and GQ.LocaleActive then
        return GQ.TN("npc", englishName) or englishName
    end
    return englishName
end

function GQ.Log:PickTooltipsPreviewItemEntry()
    local slots = { "Trinket", "Finger0", "Chest", "Head", "Neck", "Hands" }
    local bestEntry, bestCount = nil, 0
    for si = 1, #slots do
        local list = self:GetSlotRankList(slots[si])
        for i = 1, math.min(12, #list) do
            local entry = list[i]
            local link = self:TooltipsPreviewLinkForEntry(entry)
            local lines = link and self.OtherSpecRankLines and self:OtherSpecRankLines(link, entry)
            local count = type(lines) == "table" and #lines or 0
            if count > bestCount then
                bestCount = count
                bestEntry = entry
            end
        end
    end
    if bestEntry then
        return bestEntry
    end
    local list = self:GetSlotRankList("Trinket")
    return list and list[1]
end

function GQ.Log:TooltipsPreviewLinkForEntry(entry)
    if not entry or not entry.itemId then
        return nil
    end
    local itemId = entry.itemId
    if GetItemInfo then
        local _, link = GetItemInfo(itemId)
        if link then
            return link
        end
    end
    local data = GQ.Data
    local name
    if data then
        if data.ShownEntryName then
            name = data:ShownEntryName(entry)
        end
        if (not name or name == "") and data.LocaleItemName then
            name = data:LocaleItemName(itemId)
        end
    end
    if not name or name == "" then
        name = PREVIEW_ITEM_FALLBACK
    end
    return "|cffa335ee|Hitem:" .. tostring(itemId) .. ":0:0:0|h[" .. name .. "]|h|r"
end

function GQ.Log:TooltipsPreviewActiveEntry()
    local cache = self:EnsureTooltipsPreviewData()
    return cache and cache.entry
end

function GQ.Log:TooltipsPreviewItemLink()
    local entry = self:TooltipsPreviewActiveEntry()
    if entry then
        return self:TooltipsPreviewLinkForEntry(entry)
    end
    local itemId = PREVIEW_SAMPLE_ITEM_ID
    if GetItemInfo then
        local _, link = GetItemInfo(itemId)
        if link then
            return link
        end
    end
    return self:TooltipsPreviewLinkForEntry({ itemId = itemId })
end

function GQ.Log:TooltipsPreviewShownItemName(entry)
    entry = entry or self:TooltipsPreviewActiveEntry()
    local data = GQ.Data
    if entry and data and data.ShownEntryName then
        local name = data:ShownEntryName(entry)
        if name and name ~= "" then
            return name
        end
    end
    local itemId = entry and entry.itemId or PREVIEW_SAMPLE_ITEM_ID
    if data and data.LocaleItemName then
        local name = data:LocaleItemName(itemId)
        if name and name ~= "" then
            return name
        end
    end
    if GetItemInfo then
        local clientName = GetItemInfo(itemId)
        if clientName and clientName ~= "" then
            return clientName
        end
    end
    local audit = data and data.foreverAudit and data.foreverAudit[itemId]
    if audit and audit.name and audit.name ~= "" then
        return (GQ.TN and GQ.LocaleActive and GQ.TN("item", audit.name)) or audit.name
    end
    local fact = data and data.GetItemFact and data:GetItemFact(itemId)
    local english = fact and fact.name
    if english and english ~= "" and GQ.TN and GQ.LocaleActive then
        return GQ.TN("item", english) or english
    end
    return localeText("Tooltip preview sample item", PREVIEW_ITEM_FALLBACK)
end

function GQ.Log:TooltipsPreviewCreatureName()
    return self:TooltipsPreviewCreatureDisplayName(PREVIEW_CREATURE_FALLBACK)
end

function GQ.Log:TooltipsPreviewItemName()
    return self:TooltipsPreviewShownItemName()
end

function GQ.Log:TooltipsPreviewItemQuality()
    local entry = self:TooltipsPreviewActiveEntry()
    local itemId = entry and entry.itemId or PREVIEW_SAMPLE_ITEM_ID
    if GQ.Data and GQ.Data.GetItemQualityForDisplay then
        local quality = GQ.Data:GetItemQualityForDisplay(itemId)
        if type(quality) == "number" then
            return quality
        end
    end
    if GetItemInfo then
        local _, _, quality = GetItemInfo(itemId)
        if type(quality) == "number" and quality > 0 then
            return quality
        end
    end
    local audit = GQ.Data and GQ.Data.foreverAudit and GQ.Data.foreverAudit[itemId]
    if audit and type(audit.quality) == "number" and audit.quality > 0 then
        return audit.quality
    end
    return 2
end

function GQ.Log:TooltipsPreviewItemStatLines(entry)
    entry = entry or self:TooltipsPreviewActiveEntry()
    if not entry then
        return {}
    end
    local tip = self.HuntTooltipText and self:HuntTooltipText(entry)
    if not tip or tip == "" then
        return {}
    end
    local lines = {}
    local first = true
    for line in string.gmatch(tip, "[^\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            if first then
                first = false
            else
                local skip
                for prefix in pairs(PREVIEW_STAT_SKIP) do
                    if string.find(line, prefix, 1, true) then
                        skip = true
                        break
                    end
                end
                if not skip and #lines < 5 then
                    lines[#lines + 1] = "|cffffffff" .. line .. "|r"
                end
            end
        end
    end
    return lines
end

function GQ.Log:TooltipsPreviewOtherSpecLines(entry)
    entry = entry or self:TooltipsPreviewActiveEntry()
    local function collect()
        if not GQ.Spec or not GQ.Spec.IsActive or not GQ.Spec:IsActive() then
            return nil
        end
        local link = self:TooltipsPreviewLinkForEntry(entry)
        if link and entry and self.OtherSpecRankLines then
            local lines = self:OtherSpecRankLines(link, entry)
            if type(lines) == "table" and #lines > 0 then
                return lines
            end
        end
        return nil
    end
    if GQ._tooltipsPanelPreview then
        return collect()
    end
    return self:TooltipsPreviewWithHunterDemo(collect)
end

function GQ.Log:LayoutTooltipsPreviewBoxHeight(panel)
    if not panel then
        return
    end
    if panel.leftPreview and panel.leftPreview.SetHeight then
        panel.leftPreview:SetHeight(PREVIEW_BOX_H)
    end
    if panel.rightPreview and panel.rightPreview.SetHeight then
        panel.rightPreview:SetHeight(PREVIEW_BOX_H)
    end
end

function GQ.Log:UpdateTooltipsPanelPreviewLabels(panel)
    if not panel then
        return
    end
    local prefix = tooltipsExamplePrefix() .. " "
    local leftLabel = panel.leftPreviewLabel
    local rightLabel = panel.rightPreviewLabel
    if leftLabel then
        leftLabel:SetText(prefix .. self:TooltipsPreviewCreatureName())
        leftLabel:SetTextColor(WHITE[1], WHITE[2], WHITE[3])
    end
    if rightLabel then
        local name = self:TooltipsPreviewItemName()
        local quality = self:TooltipsPreviewItemQuality()
        local hex = tooltipsItemQualityHex(quality)
        rightLabel:SetText("|cffffffff" .. prefix .. "|r|cff" .. hex .. name .. "|r")
    end
end

function GQ.Log:StyleTooltipsPanelSettings(frame, panel)
    if not frame then
        return
    end
    local level = (panel and panel.GetFrameLevel and panel:GetFrameLevel() or 300) + 12

    local function styleTitle(fs)
        if not fs then
            return
        end
        tooltipsLabelFont(fs)
        colorFontStringWhite(fs, false)
    end

    local function styleHint(fs)
        if not fs then
            return
        end
        tooltipsHintFont(fs)
        colorFontStringWhite(fs, true)
    end

    for i = 1, #LEFT_SETTING_KEYS do
        local key = LEFT_SETTING_KEYS[i]
        local w = frame[key]
        if w then
            if w.Show then
                w:Show()
            end
            if w.SetFrameLevel then
                w:SetFrameLevel(level)
            end
            if string.find(key, "Hint") then
                styleHint(w)
            elseif string.find(key, "Label") and not string.find(key, "Hit") then
                styleTitle(w)
            elseif key == "settingsUnitGearMinDropValue" then
                styleTitle(w)
            elseif key == "settingsUnitGearSourcesBtn" then
                if w.GetFontString then
                    local btnText = w:GetFontString()
                    if btnText then
                        styleTitle(btnText)
                    end
                end
            end
        end
    end

    if frame.settingsUnitGearMinDropValue then
        styleTitle(frame.settingsUnitGearMinDropValue)
    end
    if self.StyleTooltipsPanelMinDropSlider then
        self:StyleTooltipsPanelMinDropSlider(frame.settingsUnitGearMinDropSlider)
    end

    for i = 1, #RIGHT_SETTING_KEYS do
        local key = RIGHT_SETTING_KEYS[i]
        local w = frame[key]
        if w then
            if w.Show then
                w:Show()
            end
            if w.SetFrameLevel then
                w:SetFrameLevel(level)
            end
            if string.find(key, "Hint") then
                styleHint(w)
            elseif string.find(key, "Label") and not string.find(key, "Hit") then
                styleTitle(w)
            end
        end
    end

    if panel and panel.leftPreviewLabel then
        panel.leftPreviewLabel:SetTextColor(WHITE_DIM[1], WHITE_DIM[2], WHITE_DIM[3])
    end
    if panel and panel.rightPreviewLabel then
        panel.rightPreviewLabel:SetTextColor(WHITE_DIM[1], WHITE_DIM[2], WHITE_DIM[3])
    end
end

function GQ.Log:WipeTooltipsScrollChild(child)
    if not child or not child.GetNumChildren then
        return
    end
    while child:GetNumChildren() > 0 do
        local sub = select(1, child:GetChildren())
        if not sub then
            break
        end
        if sub.Hide then
            sub:Hide()
        end
        if sub.SetParent then
            sub:SetParent(nil)
        end
    end
end

function GQ.Log:ClearTooltipsSettingKeys(frame, keys)
    if not frame or not keys then
        return
    end
    for i = 1, #keys do
        local key = keys[i]
        local w = frame[key]
        if w and w.Hide then
            w:Hide()
        end
        if key == "settingsUnitGearMinDropSlider" and w and w.SetParent then
            w:ClearAllPoints()
            w:SetParent(nil)
            local name = w.GetName and w:GetName()
            if name and _G[name] == w then
                _G[name] = nil
            end
        end
        frame[key] = nil
    end
end

function GQ.Log:WidgetOnTooltipsChild(widget, child)
    return widget and widget.GetParent and child and widget:GetParent() == child
end

function GQ.Log:TargetTooltipsSettingsComplete(frame, leftChild)
    if not frame or not leftChild then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsUnitGearLabelHit, leftChild) then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsUnitGearAlwaysLabelHit, leftChild) then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsUnitGearChanceLabelHit, leftChild) then
        return false
    end
    local row = frame.settingsUnitGearSourcesRow
    if not row or row:GetParent() ~= leftChild then
        return false
    end
    local btn = frame.settingsUnitGearSourcesBtn
    if not btn or btn:GetParent() ~= row then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsUnitGearMinDropSlider, leftChild) then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsUnitGearMinDropHint, leftChild) then
        return false
    end
    return true
end

function GQ.Log:ItemTooltipsSettingsComplete(frame, rightChild)
    if not frame or not rightChild then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsEnchantLabelHit, rightChild) then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsScoreLabelHit, rightChild) then
        return false
    end
    if not self:WidgetOnTooltipsChild(frame.settingsOtherSpecLabelHit, rightChild) then
        return false
    end
    return true
end

function GQ.Log:LayoutTooltipsPanelSettingRows(frame, panel)
    if not frame or not panel then
        return
    end
    local leftChild = panel.leftScrollChild
    local rightChild = panel.rightScrollChild
    local textW = COLUMN_W - SETTINGS_LEFT_PAD - SETTINGS_CHECK_COLUMN - 8

    local function widenHits(keys, child)
        if not child then
            return
        end
        for i = 1, #keys do
            local key = keys[i]
            if string.find(key, "LabelHit$") then
                local hit = frame[key]
                local label = labelOnHit(frame, key)
                if hit and label and label.SetWidth then
                    hit:SetHeight(math.max(hit:GetHeight() or 18, (label:GetStringHeight() or 14) + 4))
                    label:SetWidth(textW)
                    label:SetWordWrap(true)
                    if label.SetNonSpaceWrap then
                        label:SetNonSpaceWrap(false)
                    end
                    if hit.SetPoint and child then
                        hit:SetPoint("RIGHT", child, "RIGHT", -SETTINGS_CHECK_COLUMN - 8, 0)
                    end
                end
            end
        end
    end

    local leftHits = {
        "settingsUnitGearLabelHit", "settingsUnitGearAlwaysLabelHit", "settingsUnitGearChanceLabelHit",
        "settingsUnitGearMinDropLabelHit",
    }
    local rightHits = {
        "settingsEnchantLabelHit", "settingsScoreLabelHit", "settingsOtherSpecLabelHit",
    }
    widenHits(leftHits, leftChild)
    widenHits(rightHits, rightChild)

    local function wrapHints(keys)
        for i = 1, #keys do
            local hint = frame[keys[i]]
            if hint and hint.SetWidth then
                hint:SetWidth(textW + SETTINGS_CHECK_COLUMN)
                hint:SetWordWrap(true)
                if hint.SetNonSpaceWrap then
                    hint:SetNonSpaceWrap(false)
                end
            end
        end
    end

    wrapHints({
        "settingsUnitGearHint", "settingsUnitGearAlwaysHint", "settingsUnitGearChanceHint",
        "settingsUnitGearSourcesHint", "settingsUnitGearMinDropHint",
    })
    wrapHints({
        "settingsEnchantHint", "settingsScoreHint", "settingsOtherSpecHint",
    })

    local sourcesTitle = frame.settingsUnitGearSourcesLabel
    if sourcesTitle and sourcesTitle.SetWidth then
        sourcesTitle:SetWidth(textW + SETTINGS_CHECK_COLUMN)
        sourcesTitle:SetWordWrap(true)
    end
end

function GQ.Log:ReparentTooltipsSettings(frame, panel)
    local leftChild = panel.leftScrollChild
    local rightChild = panel.rightScrollChild
    if not leftChild or not rightChild then
        return false
    end

    local function move(keys, parent)
        for i = 1, #keys do
            local w = frame[keys[i]]
            if w and w.SetParent then
                w:SetParent(parent)
            end
        end
    end

    move(LEFT_SETTING_KEYS, leftChild)
    move(RIGHT_SETTING_KEYS, rightChild)
    return frame.settingsEnchantLabelHit and frame.settingsEnchantLabelHit:GetParent() == rightChild
end

function GQ.Log:BuildTooltipsPanel(frame)
    if not frame.tooltipsBtn then
        local btn = CreateFrame("Button", "GearQuestTooltipsButton", frame, "UIPanelButtonTemplate")
        btn:SetSize(96, 22)
        btn:SetText(L["Tooltips"])
        if GQ.FitButton then
            GQ:FitButton(btn, 96)
        end
        btn:SetScript("OnClick", function()
            local log = _G.GearQuest and _G.GearQuest.Log
            if log then
                if log.DismissTooltipsIntro then
                    log:DismissTooltipsIntro()
                end
                if log.ToggleTooltipsPanel then
                    log:ToggleTooltipsPanel()
                end
            end
        end)
        local windowLevel = (frame.gqOuterBorder and frame.gqOuterBorder.GetFrameLevel and frame.gqOuterBorder:GetFrameLevel() or (frame:GetFrameLevel() or 1)) + 3
        btn:SetFrameLevel(windowLevel)
        frame.tooltipsBtn = btn
        if self.StartTooltipsIntro then
            self:StartTooltipsIntro(btn)
        end
    end

    if frame.tooltipsPanel then
        return
    end

    local panel = CreateFrame("Frame", "GearQuestTooltipsPanel", frame, "BackdropTemplate")
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(300)
    panel:EnableMouse(true)
    panel:SetSize(PANEL_W, PANEL_H)
    if panel.SetClampedToScreen then
        panel:SetClampedToScreen(true)
    end
    panel:SetPoint("CENTER", frame, "CENTER", 0, 16)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if panel.SetBackdropColor then
        panel:SetBackdropColor(0.07, 0.06, 0.05, 1)
    end
    if panel.SetBackdropBorderColor then
        panel:SetBackdropBorderColor(0.78, 0.72, 0.58, 1)
    end
    panel:Hide()
    panel._frame = frame

    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", panel, "TOP", 0, -12)
    heading:SetJustifyH("CENTER")
    heading:SetText(L["Tooltips"])
    heading:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    local headingFont = heading:GetFont()
    if headingFont then
        heading:SetFont(headingFont, 16, "")
        if GQ.CalmFont then
            GQ:CalmFont(heading)
        end
    end

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.55, 0.48, 0.36, 0.55)
    divider:SetWidth(2)
    divider:SetPoint("TOP", panel, "TOP", 0, -34)
    divider:SetPoint("BOTTOM", panel, "BOTTOM", 0, 44)

    local leftTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -34)
    leftTitle:SetWidth(COLUMN_W)
    leftTitle:SetJustifyH("LEFT")
    leftTitle:SetText(L["Target tooltips"])
    leftTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    local rightTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightTitle:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -34)
    rightTitle:SetWidth(COLUMN_W)
    rightTitle:SetJustifyH("LEFT")
    rightTitle:SetText(L["Item tooltips"])
    rightTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

    panel.leftPreviewLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.leftPreviewLabel:SetPoint("TOPLEFT", leftTitle, "BOTTOMLEFT", 0, -4)
    tooltipsHintFont(panel.leftPreviewLabel)
    panel.leftPreviewLabel:SetJustifyH("LEFT")

    panel.rightPreviewLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.rightPreviewLabel:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", 0, -4)
    tooltipsHintFont(panel.rightPreviewLabel)
    panel.rightPreviewLabel:SetJustifyH("LEFT")

    panel.leftPreview = makePreviewBox(panel, true)
    panel.leftPreview:SetSize(COLUMN_W, PREVIEW_BOX_H)
    panel.leftPreview:SetPoint("TOPLEFT", panel.leftPreviewLabel, "BOTTOMLEFT", 0, -2)

    panel.rightPreview = makePreviewBox(panel, true)
    panel.rightPreview:SetSize(COLUMN_W, PREVIEW_BOX_H)
    panel.rightPreview:SetPoint("TOPLEFT", panel.rightPreviewLabel, "BOTTOMLEFT", 0, -2)

    local scrollH = PANEL_H - PREVIEW_BOX_H - 118

    local function makeScroll(name, anchor, alignRight)
        local scroll = CreateFrame("ScrollFrame", name, panel)
        if alignRight then
            scroll:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -6)
        else
            scroll:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
        end
        scroll:SetSize(COLUMN_W, scrollH)
        wireTooltipsScroll(scroll)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(COLUMN_W - SCROLLBAR_WIDTH, 240)
        child:EnableMouse(false)
        scroll:SetScrollChild(child)
        child:SetScript("OnMouseWheel", function(_, delta)
            wheelScroll(scroll, nil, delta)
        end)
        if GQ.Log.EnsureTooltipsSlimScroll then
            GQ.Log:EnsureTooltipsSlimScroll(scroll)
        end
        return scroll, child
    end

    panel.leftScroll, panel.leftScrollChild = makeScroll("GearQuestTooltipsLeftScroll", panel.leftPreview, false)
    panel.rightScroll, panel.rightScrollChild = makeScroll("GearQuestTooltipsRightScroll", panel.rightPreview, true)

    if panel.SetClipsChildren then
        panel:SetClipsChildren(true)
    end

    panel.closeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.closeBtn:SetSize(100, 22)
    panel.closeBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 12)
    panel.closeBtn:SetText(L["Close"])
    panel.closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)

    panel:SetScript("OnShow", function()
        local log = _G.GearQuest and _G.GearQuest.Log
        local owner = panel._frame
        if log and owner then
            log:MountTooltipsPanelSettings(owner, panel)
            log:LayoutTooltipsPanelScroll(panel)
            log:StyleTooltipsPanelSettings(owner, panel)
        end
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(PREVIEW_SAMPLE_ITEM_ID)
        end
        if log and log.RefreshTooltipsPanelPreview then
            log:RefreshTooltipsPanelPreview()
        end
    end)

    frame.tooltipsPanel = panel
    if self.UpdateTooltipsPanelPreviewLabels then
        self:UpdateTooltipsPanelPreviewLabels(panel)
    end
end

function GQ.Log:EnsureTooltipsPanel(frame)
    frame = frame or self.frame
    if not frame then
        return
    end
    if not frame.tooltipsBtn or not frame.tooltipsPanel then
        self:BuildTooltipsPanel(frame)
    end
    if frame.tooltipsBtn and self.StartTooltipsIntro then
        self:StartTooltipsIntro(frame.tooltipsBtn)
    end
    if frame.tooltipsPanel then
        self:LayoutTooltipsPanelChrome(frame.tooltipsPanel)
    end
end

function GQ.Log:MountTooltipsPanelSettings(frame, panel)
    if not frame or not panel then
        return
    end

    local leftChild = panel.leftScrollChild
    local rightChild = panel.rightScrollChild
    if not leftChild or not rightChild then
        return
    end

    panel.settingsReady = false
    leftChild._gqTooltipsPanel = true
    rightChild._gqTooltipsPanel = true

    self:ClearTooltipsSettingKeys(frame, LEFT_SETTING_KEYS)
    self:ClearTooltipsSettingKeys(frame, RIGHT_SETTING_KEYS)

    local orphan = _G.GearQuestUnitGearMinDropSlider
    if orphan and orphan.SetParent then
        orphan:Hide()
        orphan:ClearAllPoints()
        orphan:SetParent(nil)
        local name = orphan.GetName and orphan:GetName()
        if name and _G[name] == orphan then
            _G[name] = nil
        end
    end

    self:WipeTooltipsScrollChild(leftChild)
    self:WipeTooltipsScrollChild(rightChild)

    local leftAnchor = leftChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    leftAnchor:SetPoint("TOPLEFT", leftChild, "TOPLEFT", SETTINGS_LEFT_PAD, -4)
    leftAnchor:SetSize(1, 1)
    leftAnchor:SetText("")

    local targetOk, targetErr = pcall(function()
        self:CreateUnitGearSetting(frame, leftChild, leftAnchor)
        local unitChain = frame.settingsUnitGearHint or frame.settingsUnitGearLabelHit or leftAnchor
        self:CreateUnitGearTooltipOptions(frame, leftChild, unitChain)
    end)
    if not targetOk and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("GearQuest target tooltip settings: " .. tostring(targetErr), 1, 0.2, 0.2)
    end

    local rightAnchor = rightChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rightAnchor:SetPoint("TOPLEFT", rightChild, "TOPLEFT", SETTINGS_LEFT_PAD, -4)
    rightAnchor:SetSize(1, 1)
    rightAnchor:SetText("")

    local itemOk, itemErr = pcall(function()
        self:CreateEnchantSetting(frame, rightChild, rightAnchor)
        local itemChain = frame.settingsEnchantHint or frame.settingsEnchantLabelHit or rightAnchor
        self:CreateGearScoreTooltipSettings(frame, rightChild, itemChain)
    end)
    if not itemOk and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("GearQuest item tooltip settings: " .. tostring(itemErr), 1, 0.2, 0.2)
    end

    local leftHints = {
        frame.settingsUnitGearHint,
        frame.settingsUnitGearAlwaysHint,
        frame.settingsUnitGearChanceHint,
        frame.settingsUnitGearSourcesHint,
        frame.settingsUnitGearMinDropHint,
    }
    for i = 1, #leftHints do
        local hint = leftHints[i]
        if hint then
            hint:SetPoint("RIGHT", leftChild, "RIGHT", -6, 0)
        end
    end
    local rightHints = {
        frame.settingsEnchantHint,
        frame.settingsScoreHint,
        frame.settingsOtherSpecHint,
    }
    for i = 1, #rightHints do
        local hint = rightHints[i]
        if hint then
            hint:SetPoint("RIGHT", rightChild, "RIGHT", -6, 0)
        end
    end

    if frame.settingsUnitGearMinDropSlider and frame.settingsUnitGearMinDropSlider.SetWidth then
        frame.settingsUnitGearMinDropSlider:SetWidth(math.min(200, COLUMN_W - SETTINGS_LEFT_PAD - 40))
    end

    panel.leftSettingsLast = frame.settingsUnitGearMinDropHint
    panel.rightSettingsLast = frame.settingsOtherSpecHint
    panel.settingsReady = self:TargetTooltipsSettingsComplete(frame, leftChild)
        and self:ItemTooltipsSettingsComplete(frame, rightChild)

    self:LayoutTooltipsPanelTargetSources(frame)

    if frame.settingsUnitGearSourcesMenu then
        frame.settingsUnitGearSourcesMenu:SetFrameStrata("TOOLTIP")
        frame.settingsUnitGearSourcesMenu:SetFrameLevel(400)
    end

    self:StyleTooltipsPanelSettings(frame, panel)
    self:LayoutTooltipsPanelSettingRows(frame, panel)
end

function GQ.Log:LayoutTooltipsPanelScroll(panel)
    if not panel then
        return
    end
    layoutColumnScroll(panel, "left")
    layoutColumnScroll(panel, "right")
    if GQ.Log.ApplyTooltipsScrollBars then
        GQ.Log:ApplyTooltipsScrollBars(panel)
    end
end

function GQ.Log:RefreshTooltipsPanelContent(frame, panel)
    if not frame or not panel then
        return
    end
    self:LayoutTooltipsPanelChrome(panel)
    if self.RefreshSettings then
        self:RefreshSettings()
    end
    self:MountTooltipsPanelSettings(frame, panel)
    self:LayoutTooltipsPanelScroll(panel)
    self:StyleTooltipsPanelSettings(frame, panel)
    self:RefreshTooltipsPanelPreview()
    if self.ApplyTooltipsScrollBars then
        self:ApplyTooltipsScrollBars(panel)
    end
end

function GQ.Log:ToggleTooltipsPanel()
    local frame = self.frame
    if not frame then
        return
    end
    self:DismissTooltipsIntro()
    self:EnsureTooltipsPanel(frame)
    local panel = frame.tooltipsPanel
    if not panel then
        return
    end
    if panel:IsShown() then
        panel:Hide()
        if frame.settingsUnitGearSourcesMenu then
            frame.settingsUnitGearSourcesMenu:Hide()
        end
        local catcher = frame.settingsUnitGearSourcesMenu and frame.settingsUnitGearSourcesMenu.catcher
        if catcher then
            catcher:Hide()
        end
        return
    end
    if frame.playStylePanel and frame.playStylePanel:IsShown() then
        frame.playStylePanel:Hide()
    end
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(350)
    if panel.leftScroll and panel.leftScroll.SetVerticalScroll then
        panel.leftScroll:SetVerticalScroll(0)
    end
    if panel.rightScroll and panel.rightScroll.SetVerticalScroll then
        panel.rightScroll:SetVerticalScroll(0)
    end
    panel:Show()
    local ok, err = pcall(self.RefreshTooltipsPanelContent, self, frame, panel)
    if not ok then
        panel:Show()
        local msg = "GearQuest Tooltips failed to open: " .. tostring(err)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 0.2, 0.2)
        end
    end
end

function GQ.Log:RefreshTooltipsPanelPreview()
    local panel = self.frame and self.frame.tooltipsPanel
    if not panel or not panel:IsShown() then
        return
    end
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings or {}
    local leftText = panel.leftPreview and panel.leftPreview.previewText
    local rightText = panel.rightPreview and panel.rightPreview.previewText
    if not leftText or not rightText then
        return
    end
    if not self._tooltipsPreviewPaint then
        self:BuildTooltipsPreviewPaint()
    end
    self:UpdateTooltipsPanelPreviewLabels(panel)

    if settings.hideUnitGearTips then
        leftText:SetText("|cff888888" .. localeText("Unit gear tips are hidden.", "Unit gear tips are hidden.") .. "|r")
    else
        local lines = {}
        local drops, minHidAll = self:TooltipsPreviewDropLines(settings)
        if drops and drops[1] then
            lines[#lines + 1] = "|cffffd200" .. (L["Your top world drops from this mob:"] or "Your top world drops from this mob:") .. "|r"
            for i = 1, #drops do
                lines[#lines + 1] = drops[i]
            end
        elseif minHidAll then
            lines[#lines + 1] = "|cff888888"
                .. (L["Your minimum drop chance hid every upgrade line. Lower it on the Tooltips page, under Minimum drop chance on unit gear."]
                    or "Your minimum drop chance hid every upgrade line. Lower it on the Tooltips page, under Minimum drop chance on unit gear.")
                .. "|r"
        end
        if not settings.unitGearAlwaysShow then
            lines[#lines + 1] = "|cff888888" .. (L["Hold Shift to see BiS items from this NPC"] or "") .. "|r"
        end
        leftText:SetText(table.concat(lines, "\n"))
    end

    local paint = self._tooltipsPreviewPaint
    local entry = (paint and paint.entry) or PREVIEW_ITEM_ENTRY
    local rlines = {}
    local stats = (paint and paint.stats) or self:TooltipsPreviewItemStatLines(entry)
    for i = 1, #stats do
        rlines[#rlines + 1] = stats[i]
    end
    if #stats == 0 and entry and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(entry.itemId)
        if fact and fact.ap and fact.ap > 0 then
            rlines[#rlines + 1] = "|cffffffff+" .. tostring(fact.ap) .. " Attack Power|r"
        end
    end
    if settings.showGearEnchant == true then
        local enchant = previewEnchantLine(entry)
        if enchant then
            rlines[#rlines + 1] = enchant
        end
    end
    if paint and not settings.hideUnitGearTips then
        if settings.showGearScore ~= false and paint.score then
            rlines[#rlines + 1] = paint.score
        end
        if settings.showGearScore ~= false and paint.note then
            rlines[#rlines + 1] = paint.note
        end
        if settings.showOtherSpecRanks ~= false and paint.other then
            for i = 1, #paint.other do
                local otherLine = paint.other[i]
                if otherLine:find("|cff") then
                    rlines[#rlines + 1] = otherLine
                else
                    rlines[#rlines + 1] = "|cffd9bf73" .. otherLine .. "|r"
                end
            end
        end
    end
    self:LayoutTooltipsPreviewBoxHeight(panel)
    rightText:SetText(table.concat(rlines, "\n"))
    if self.LayoutTooltipsPanelChrome then
        self:LayoutTooltipsPanelChrome(panel)
    end
end

function GQ.Log:NotifyTooltipsPreview()
    if self.RefreshTooltipsPanelPreview then
        self:RefreshTooltipsPanelPreview()
    end
end