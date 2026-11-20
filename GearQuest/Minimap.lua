local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Minimap = GQ.Minimap or {}

local LIBDBICON_NAME = "GearQuest"
local MINIMAP_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GearQuest-Icon"
local MINIMAP_ICON_SIZE = 20
local BUTTON_SIZE = 31
-- Center sits on the rim, the same offset Questie uses (half the minimap, plus 5).
local MINIMAP_BORDER_OUTSET = 5

local function GetMinimapDB()
    GearQuestForeverDB.minimap = GearQuestForeverDB.minimap or {}
    local db = GearQuestForeverDB.minimap
    if db.minimapPos == nil then
        GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
        local angle = GearQuestForeverDB.settings.minimapAngle
        if type(angle) == "number" then
            db.minimapPos = angle
        end
    end
    return db
end

local function LibDBIconLib()
    if not LibStub then
        return nil
    end
    local ok, lib = pcall(LibStub, "LibDBIcon-1.0", true)
    if ok and lib and lib.Register then
        return lib
    end
    return nil
end

local function GetRadius()
    if not Minimap then
        return 70
    end
    local w = Minimap:GetWidth() or 140
    local h = Minimap:GetHeight() or w
    return (math.min(w, h) / 2) + MINIMAP_BORDER_OUTSET
end

local function ApplyMinimapIcon(icon)
    if not icon then
        return
    end

    icon:SetTexture(MINIMAP_TEXTURE)
end

local function EnsureMinimapIcon(button)
    if not button.gqIcon then
        button.gqIcon = button:CreateTexture(nil, "BACKGROUND")
        button.gqIcon:SetSize(MINIMAP_ICON_SIZE, MINIMAP_ICON_SIZE)
        button.gqIcon:SetPoint("CENTER", 0, 1)
    end

    ApplyMinimapIcon(button.gqIcon)
    return button.gqIcon
end

local function GetAngle()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    return GearQuestForeverDB.settings.minimapAngle or 200
end

local function SetAngle(angle)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.minimapAngle = angle
    local db = GearQuestForeverDB.minimap
    if db then
        db.minimapPos = angle
    end
end

local function UpdatePosition(button)
    if not button or not Minimap then
        return
    end
    local radius = GetRadius()
    local angle = math.rad(GetAngle())
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function RegisterButtonClicks(button)
    if not button.RegisterForClicks then
        return
    end

    if pcall(function() button:RegisterForClicks("LeftButtonUp", "RightButtonUp") end) then
        return
    end
    pcall(function() button:RegisterForClicks("LeftButton", "RightButton") end)
end

local function OnMinimapClick()
    local gq = _G.GearQuest
    if gq and gq.Log then
        gq.Log:Toggle()
    end
end

local function WireMinimapButton(button)
    EnsureMinimapIcon(button)
    RegisterButtonClicks(button)
    button:SetScript("OnClick", OnMinimapClick)
    button:SetScript("OnMouseUp", nil)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GearQuest", 0.90, 0.75, 0.28)
        GameTooltip:AddLine(L["Click to open GearQuest"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function GQ.Minimap:IsHidden()
    return type(GearQuestForeverDB) == "table"
        and type(GearQuestForeverDB.settings) == "table"
        and GearQuestForeverDB.settings.hideMinimapIcon
        and true
        or false
end

function GQ.Minimap:SyncLibDBHide()
    if not self.libDBIconRegistered then
        return
    end
    local db = GetMinimapDB()
    db.hide = self:IsHidden() and true or false
    if self.libDBIcon then
        if db.hide then
            self.libDBIcon:Hide(LIBDBICON_NAME)
        else
            self.libDBIcon:Show(LIBDBICON_NAME)
        end
    end
end

function GQ.Minimap:ApplyVisibility()
    if self.libDBIconRegistered and self.libDBIcon then
        self:SyncLibDBHide()
        local button = self.libDBIcon.GetMinimapButton and self.libDBIcon:GetMinimapButton(LIBDBICON_NAME)
        if button and GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == button then
            if self:IsHidden() then
                GameTooltip:Hide()
            end
        end
        return
    end

    local button = self.button
    if not button then
        return
    end
    if self:IsHidden() then
        button:Hide()
        if GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() == button then
            GameTooltip:Hide()
        end
    else
        button:Show()
        UpdatePosition(button)
    end
end

function GQ.Minimap:SetHidden(hidden)
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.hideMinimapIcon = hidden and true or false
    self:ApplyVisibility()
end

local function RegisterLauncher()
    if GQ.Minimap.launcher or not LibStub then
        return GQ.Minimap.launcher and true or false
    end
    local ok, lib = pcall(LibStub, "LibDataBroker-1.1", true)
    if not ok or not lib or not lib.NewDataObject then
        return false
    end
    GQ.Minimap.launcher = lib:NewDataObject("GearQuest", {
        type = "launcher",
        text = "GearQuest",
        label = "GearQuest",
        icon = MINIMAP_TEXTURE,
        OnClick = function()
            OnMinimapClick()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then
                return
            end
            tooltip:SetText("GearQuest", 0.90, 0.75, 0.28)
            tooltip:AddLine(L["Click to open GearQuest"], 1, 1, 1)
        end,
    })
    return true
end

function GQ.Minimap:RegisterLauncher()
    if RegisterLauncher() or self.launcherWatch then
        return
    end
    local watch = CreateFrame("Frame")
    self.launcherWatch = watch
    watch:RegisterEvent("ADDON_LOADED")
    watch:SetScript("OnEvent", function(frame)
        if RegisterLauncher() then
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            GQ.Minimap:TryLibDBIcon()
        end
    end)
end

function GQ.Minimap:HideCustomButton()
    local button = self.button
    if not button or button == (self.libDBIcon and self.libDBIcon.GetMinimapButton and self.libDBIcon:GetMinimapButton(LIBDBICON_NAME)) then
        return
    end
    button:SetScript("OnUpdate", nil)
    button:Hide()
    button:SetParent(UIParent)
end

function GQ.Minimap:TryLibDBIcon()
    if self.libDBIconRegistered then
        return true
    end
    if not RegisterLauncher() then
        return false
    end
    local lib = LibDBIconLib()
    if not lib then
        return false
    end
    if lib.IsRegistered and lib:IsRegistered(LIBDBICON_NAME) then
        self.libDBIconRegistered = true
        self.libDBIcon = lib
        self.button = lib:GetMinimapButton(LIBDBICON_NAME)
        self:HideCustomButton()
        self:ApplyVisibility()
        return true
    end
    local db = GetMinimapDB()
    db.hide = self:IsHidden() and true or false
    lib:Register(LIBDBICON_NAME, self.launcher, db)
    self.libDBIconRegistered = true
    self.libDBIcon = lib
    self.button = lib.GetMinimapButton and lib:GetMinimapButton(LIBDBICON_NAME) or self.button
    self:HideCustomButton()
    self:ApplyVisibility()
    return true
end

function GQ.Minimap:WatchLibDBIcon()
    if self.libDBIconWatch or self.libDBIconRegistered then
        return
    end
    local watch = CreateFrame("Frame")
    self.libDBIconWatch = watch
    watch:RegisterEvent("ADDON_LOADED")
    watch:SetScript("OnEvent", function(frame, _, addonName)
        if addonName == ADDON_NAME then
            return
        end
        if GQ.Minimap:TryLibDBIcon() then
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
        end
    end)
end

local function InitCustomButton(self)
    if self.button or self.customButton or _G.GearQuestMinimapButton then
        self.button = self.button or _G.GearQuestMinimapButton
        if self.button then
            WireMinimapButton(self.button)
            UpdatePosition(self.button)
            self.customButton = true
            self:ApplyVisibility()
        end
        return
    end

    if not Minimap then
        return
    end

    local button = CreateFrame("Button", "GearQuestMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(20)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    WireMinimapButton(button)
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnDragStart", function(btn)
        btn:LockHighlight()
        btn:SetScript("OnUpdate", function(s)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            SetAngle(math.deg(math.atan2(py - my, px - mx)))
            UpdatePosition(s)
        end)
    end)

    button:SetScript("OnDragStop", function(btn)
        btn:UnlockHighlight()
        btn:SetScript("OnUpdate", nil)
    end)

    UpdatePosition(button)
    self.button = button
    self.customButton = true
    self:ApplyVisibility()

    if Minimap.HookScript then
        pcall(function()
            Minimap:HookScript("OnSizeChanged", function()
                local minimap = GQ.Minimap
                if minimap and minimap.customButton and minimap.button then
                    UpdatePosition(minimap.button)
                end
            end)
        end)
    end
end

function GQ.Minimap:Init()
    self:RegisterLauncher()
    if self:TryLibDBIcon() then
        return
    end
    if self.initialized then
        self:WatchLibDBIcon()
        return
    end
    self.initialized = true

    InitCustomButton(self)
    self:WatchLibDBIcon()
end