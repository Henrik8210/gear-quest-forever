local _, GQ = ...

GQ.Pins = GQ.Pins or {}

-- Classic interface art. The vendor sack is the buy cursor. The rare
-- dragon is the nameplate silver dragon, the same one on a rare portrait.
local PIN_ICONS = {
    boss_drop = { path = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
    object_drop = { path = "Interface\\GossipFrame\\BankerGossipIcon" },
    raid_trash = { path = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    profession = { path = "Interface\\QuestFrame\\UI-QuestLog-BookIcon" },
    quest_reward = { path = "Interface\\GossipFrame\\AvailableQuestIcon" },
    rare_npc = {
        atlas = "nameplates-icon-elite-silver",
        path = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare",
        coord = { 0, 0.22, 0, 0.62 },
    },
    seasonal_quest = { path = "Interface\\Icons\\INV_Holiday_Christmas_Present_01" },
    special = { path = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
    unsourced = { path = "Interface\\RaidFrame\\ReadyCheck-NotReady" },
    vendor = { path = "Interface\\Cursor\\Buy" },
    world_drop = { path = "Interface\\Icons\\Spell_Nature_FarSight" },
}

local function ApplyPinIcon(icon, kind)
    local spec = PIN_ICONS[kind] or PIN_ICONS.unsourced
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetTexCoord(0, 1, 0, 1)
    if spec.atlas and icon.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(spec.atlas) then
        icon:SetAtlas(spec.atlas, false)
        return
    end
    icon:SetTexture(spec.path)
    if spec.coord then
        icon:SetTexCoord(spec.coord[1], spec.coord[2], spec.coord[3], spec.coord[4])
    end
    icon:Show()
end

function GQ.Pins:ApplyIcon(icon, kind)
    if icon then
        ApplyPinIcon(icon, kind)
    end
end
local AREA_TEXTURE = "Interface\\Minimap\\UI-Minimap-Ping-Center"
local AREA_COLOR = { 0.3, 0.55, 1, 0.35 }
local UPDATE_INTERVAL = 0.05
local WORLD_PIN_SIZE = 24

local pins = {}
local driver
local worldPool = {}
local worldArea
local elapsedAcc = 0
local poolsActive = true

local function ShowPinTooltip(frame)
    local pin = frame.pinData
    if not pin or not pin.entry then
        return
    end
    local entry = pin.entry
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local name = GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry)
    GameTooltip:AddLine(name or ("Item " .. tostring(entry.itemId)), 1, 0.82, 0)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(pin.mapId)
    local zone = pin.map or (info and info.name) or entry.zone or ""
    if zone ~= "" then
        GameTooltip:AddLine(string.format("%s %.1f, %.1f", zone, pin.x, pin.y), 0.6, 0.8, 1)
    end
    GameTooltip:AddLine("Left-click to Guide", 0.75, 0.75, 0.75)
    GameTooltip:AddLine("Right click to open Hunt", 0.75, 0.75, 0.75)
    GameTooltip:Show()
end

local function OpenHuntFromPin(entry)
    if not entry or not entry.id then
        return
    end
    if GQ.Tracker and GQ.Tracker.OpenHunt then
        GQ.Tracker:OpenHunt(entry.id)
    end
end

local function PinClick(frame, button)
    local pin = frame.pinData
    local entry = pin and pin.entry
    if not entry then
        return
    end
    if button == "RightButton" then
        OpenHuntFromPin(entry)
        return
    end
    if GQ.Guide and GQ.Guide.ShowEntry then
        GQ.Guide:ShowEntry(entry)
    end
end

local function GuidedEntryId()
    return GQ.Guide and GQ.Guide.GuidedId and GQ.Guide:GuidedId() or nil
end

local function WirePin(frame)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnEnter", ShowPinTooltip)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnClick", PinClick)
    return frame
end

local function MapName(mapId)
    local info = mapId and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
    return info and info.name or nil
end

local function IsOverviewMap(mapId)
    local info = mapId and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
    local kind = info and info.mapType
    if not kind then
        return false
    end
    local types = Enum and Enum.UIMapType
    if not types then
        return kind < 3
    end
    return kind == types.Cosmic or kind == types.World or kind == types.Continent
end

local function PinOnShownMap(pin, mapId)
    if not pin or not mapId then
        return false
    end
    if pin.mapId == mapId then
        return true
    end
    if IsOverviewMap(mapId) then
        return false
    end
    local shown = MapName(mapId)
    return shown and pin.map and shown == pin.map
end

local function EnsureWorldPin(index, canvas)
    local frame = worldPool[index]
    if frame then
        if canvas and frame:GetParent() ~= canvas then
            frame:SetParent(canvas)
            frame:SetFrameStrata(canvas:GetFrameStrata() or "HIGH")
            frame:SetFrameLevel((canvas:GetFrameLevel() or 1) + 20)
        end
        return frame
    end
    if not canvas then
        return nil
    end
    frame = CreateFrame("Button", nil, canvas)
    frame:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    frame:SetFrameStrata(canvas:GetFrameStrata() or "HIGH")
    frame:SetFrameLevel((canvas:GetFrameLevel() or 1) + 20)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    WirePin(frame)
    frame:Hide()
    worldPool[index] = frame
    return frame
end

local function EnsureWorldArea(canvas)
    if worldArea and worldArea:GetParent() == canvas then
        return worldArea
    end
    worldArea = CreateFrame("Frame", nil, canvas)
    worldArea:SetSize(WORLD_PIN_SIZE, WORLD_PIN_SIZE)
    worldArea:SetFrameStrata(canvas:GetFrameStrata() or "HIGH")
    worldArea:SetFrameLevel((canvas:GetFrameLevel() or 1) + 2)
    worldArea.tex = worldArea:CreateTexture(nil, "ARTWORK")
    worldArea.tex:SetTexture(AREA_TEXTURE)
    worldArea.tex:SetAllPoints()
    worldArea.tex:SetVertexColor(AREA_COLOR[1], AREA_COLOR[2], AREA_COLOR[3], AREA_COLOR[4])
    worldArea:EnableMouse(false)
    worldArea:Hide()
    return worldArea
end

local function HideWorldPins()
    for _, frame in ipairs(worldPool) do
        frame:Hide()
    end
    if worldArea then
        worldArea:Hide()
    end
end

local function UpdateWorldMap()
    local mapId = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    if not (WorldMapFrame and WorldMapFrame:IsShown() and mapId and canvas) then
        HideWorldPins()
        return
    end
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    if width <= 0 or height <= 0 then
        HideWorldPins()
        return
    end

    local used = 0
    local guided = GuidedEntryId()
    for _, pin in ipairs(pins) do
        if PinOnShownMap(pin, mapId) then
            used = used + 1
            local frame = EnsureWorldPin(used, canvas)
            if not frame then
                break
            end
            local nx, ny = pin.x / 100, pin.y / 100
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", canvas, "TOPLEFT", nx * width, -ny * height)
            if frame.lastKind ~= pin.kind then
                frame.lastKind = pin.kind
                ApplyPinIcon(frame.icon, pin.kind)
            end
            frame.pinData = pin
            frame:Show()
        end
    end
    for index = used + 1, #worldPool do
        worldPool[index]:Hide()
    end

    local area = EnsureWorldArea(canvas)
    local selected
    if guided then
        for _, pin in ipairs(pins) do
            if pin.entry and pin.entry.id == guided and PinOnShownMap(pin, mapId) then
                selected = pin
                break
            end
        end
    end
    if not selected then
        area:Hide()
        return
    end
    area:ClearAllPoints()
    area:SetPoint("CENTER", canvas, "TOPLEFT", selected.x / 100 * width, -selected.y / 100 * height)
    area:SetSize(math.max(width * 0.08, 64), math.max(height * 0.08, 64))
    area:Show()
end

local function UpdateAll()
    if #pins == 0 then
        if poolsActive then
            poolsActive = false
            HideWorldPins()
        end
        return
    end
    poolsActive = true
    UpdateWorldMap()
end

function GQ.Pins:Sync()
    if not driver then
        self:Init()
    end
    pins = {}
    local entries = GQ.Tracker and GQ.Tracker.GetTrackedEntries and GQ.Tracker:GetTrackedEntries()
    if entries and GQ.Map and GQ.Map.SpotForEntry then
        for _, entry in ipairs(entries) do
            local pin = GQ.Map:SpotForEntry(entry)
            if pin then
                pins[#pins + 1] = pin
            end
        end
    end
    UpdateAll()
end

function GQ.Pins:Init()
    if driver then
        return
    end
    driver = CreateFrame("Frame")
    driver:SetScript("OnUpdate", function(_, elapsed)
        elapsedAcc = elapsedAcc + (elapsed or 0)
        if elapsedAcc < UPDATE_INTERVAL then
            return
        end
        elapsedAcc = 0
        UpdateAll()
    end)
    UpdateAll()
    if GQ.Log and GQ.Log.EnsureCoordinateWatch then
        GQ.Log:EnsureCoordinateWatch()
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    GQ.Pins:Init()
    GQ.Pins:Sync()
end)
