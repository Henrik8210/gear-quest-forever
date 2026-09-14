local _, GQ = ...

GQ.Minimap = GQ.Minimap or {}

local MINIMAP_TEXTURE = "Interface\\AddOns\\GearQuest\\Art\\GearQuest-Icon"
local MINIMAP_ICON_SIZE = 20
local BUTTON_SIZE = 31
local MINIMAP_RADIUS = 80

local function ApplyMinimapIcon(icon)
    if not icon then
        return
    end

    icon:SetTexture(MINIMAP_TEXTURE)
    icon:SetTexCoord(0, 1, 1, 0)
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
    GearQuestDB.settings = GearQuestDB.settings or {}
    return GearQuestDB.settings.minimapAngle or 200
end

local function SetAngle(angle)
    GearQuestDB.settings = GearQuestDB.settings or {}
    GearQuestDB.settings.minimapAngle = angle
end

local function UpdatePosition(button)
    local angle = math.rad(GetAngle())
    local x = math.cos(angle) * MINIMAP_RADIUS
    local y = math.sin(angle) * MINIMAP_RADIUS
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

local function IsRightClick(mouseButton)
    return mouseButton == "RightButton" or mouseButton == "RightButtonUp"
end

local function IsLeftClick(mouseButton)
    return mouseButton == "LeftButton" or mouseButton == "LeftButtonUp" or mouseButton == nil
end

local function OpenSimulateDialog(button)
    local gq = _G.GearQuest
    if gq and gq.Preview and gq.Preview.ShowDialog then
        gq.Preview:ShowDialog(button)
    end
end

local function OnMinimapClick(button, mouseButton)
    local gq = _G.GearQuest
    if not gq then
        return
    end

    if IsRightClick(mouseButton) then
        OpenSimulateDialog(button)
        return
    end

    if IsLeftClick(mouseButton) and gq.Log then
        gq.Log:Toggle()
    end
end

local function WireMinimapButton(button)
    EnsureMinimapIcon(button)
    RegisterButtonClicks(button)
    button:SetScript("OnClick", OnMinimapClick)
    button:SetScript("OnMouseUp", function(self, mouseButton)
        if IsRightClick(mouseButton) then
            OpenSimulateDialog(self)
        end
    end)
end

function GQ.Minimap:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    if self.button or _G.GearQuestMinimapButton then
        self.button = self.button or _G.GearQuestMinimapButton
        if self.button then
            WireMinimapButton(self.button)
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

    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(s)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            SetAngle(math.deg(math.atan2(py - my, px - mx)))
            UpdatePosition(s)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GearQuest", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open the hunt log.", 1, 0.82, 0)
        GameTooltip:AddLine("Right-click: simulate another class or level.", 1, 0.82, 0)
        GameTooltip:AddLine("Drag to move icon.", 1, 0.82, 0)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition(button)
    button:Show()
    self.button = button
end
