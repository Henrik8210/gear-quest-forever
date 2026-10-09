local ADDON_NAME, GQ = ...

GQ.Guide = GQ.Guide or {}

local ARROW_TEXTURE = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\Art\\GQ-GuideArrow3D.png"
local ARROW_FRAMES = 32
local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local HERE_YARDS = 12

local function Settings()
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    return GearQuestForeverDB.settings
end

local function CharSettings()
    if type(GearQuestForeverCharDB) ~= "table" then
        GearQuestForeverCharDB = {}
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
    return GearQuestForeverCharDB
end

function GQ.Guide:IsSuppressed()
    return Settings().hideGuideArrow and true or false
end

function GQ.Guide:GuidedId()
    return CharSettings().guideEntryId
end

-- /reload keeps the guide. A logout countdown clears it. Tracked hunts stay.
-- C_UI.Reload is protected. Replacing ReloadUI or C_UI.Reload puts this
-- addon on that call, and the AddOn List Reload button then fails with
-- "Interface action failed because of an AddOn". PLAYER_CAMPING fires when
-- the logout countdown starts, and it does not fire for a reload.
local guideLoggingOut = false
local guideLogout = CreateFrame("Frame")
guideLogout:RegisterEvent("PLAYER_CAMPING")
guideLogout:RegisterEvent("PLAYER_LOGOUT")
guideLogout:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_CAMPING" then
        guideLoggingOut = true
        return
    end
    if not guideLoggingOut then
        return
    end
    if type(GearQuestForeverCharDB) == "table" then
        GearQuestForeverCharDB.guideEntryId = nil
    end
end)
if hooksecurefunc and type(CancelLogout) == "function" then
    hooksecurefunc("CancelLogout", function()
        guideLoggingOut = false
    end)
end

local function WorldXY(world)
    if not world then
        return nil
    end
    if world.GetXY then
        return world:GetXY()
    end
    return world.x, world.y
end

local function WorldOn(mapId, x, y)
    if not (mapId and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return nil
    end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, mapId, CreateVector2D(x, y))
    if not ok or not continent or not world then
        return nil
    end
    local wx, wy = WorldXY(world)
    if not wx or not wy then
        return nil
    end
    return continent, wx, wy
end

-- Position on a specific map. A cave or town map still reports the parent
-- zone, which is the map the pin is stored on.
local function PositionOn(mapId)
    if not (mapId and C_Map and C_Map.GetPlayerMapPosition) then
        return nil
    end
    local pos = C_Map.GetPlayerMapPosition(mapId, "player")
    if not pos or not pos.GetXY then
        return nil
    end
    local x, y = pos:GetXY()
    if not x or not y or (x == 0 and y == 0) then
        return nil
    end
    return x, y
end

-- Same bearing as TomTom and HereBeDragons. 0 is north and the angle
-- increases counterclockwise, which is also how GetPlayerFacing works.
-- Subtracting it from facing leaves 0 when you are looking at the hunt,
-- including when that direction is west. Our frames then turn clockwise,
-- so the difference is flipped and the right-hand side stays on the right.
local function Aim(east, north, facing)
    local angle = math.atan2(east or 0, north or 0)
    if angle > 0 then
        angle = math.pi * 2 - angle
    else
        angle = -angle
    end
    return (facing or 0) - angle
end

local function FormatYards(dist)
    if not dist then
        return nil
    end
    if dist < HERE_YARDS then
        return "Here"
    end
    return string.format("%d yards", dist + 0.5)
end

local function WrapPi(angle)
    while angle > math.pi do
        angle = angle - math.pi * 2
    end
    while angle < -math.pi do
        angle = angle + math.pi * 2
    end
    return angle
end

-- Frame 0 points forward, away from the camera. Positive turns to the right.
local function ArrowIndex(rel)
    local t = rel / (math.pi * 2)
    if t < 0 then
        t = t + 1
    end
    return math.floor(t * ARROW_FRAMES + 0.5) % ARROW_FRAMES
end

local axisSignCache = {}

-- World axes are not "x is east". Measure which way east and north
-- actually move, then project the waypoint onto those two directions.
local function WorldBasis(mapId)
    local cached = axisSignCache[mapId]
    if cached then
        return cached[1], cached[2], cached[3], cached[4]
    end
    local _, eastX, eastY = WorldOn(mapId, 0.6, 0.5)
    local _, westX, westY = WorldOn(mapId, 0.4, 0.5)
    local _, northX, northY = WorldOn(mapId, 0.5, 0.4)
    local _, southX, southY = WorldOn(mapId, 0.5, 0.6)
    if not (eastX and westX and eastY and westY and northX and northY and southX and southY) then
        return nil
    end
    local basis = { eastX - westX, eastY - westY, northX - southX, northY - southY }
    axisSignCache[mapId] = basis
    return basis[1], basis[2], basis[3], basis[4]
end

local function AimWorld(mapId, dx, dy, facing)
    local eastX, eastY, northX, northY = WorldBasis(mapId)
    if not eastX then
        return 0
    end
    local det = eastX * northY - eastY * northX
    if det == 0 then
        return 0
    end
    local east = (dx * northY - dy * northX) / det
    local north = (eastX * dy - eastY * dx) / det
    return Aim(east, north, facing)
end

local function ParentChain(mapId)
    local chain, seen = {}, {}
    local guard = 0
    while mapId and mapId ~= 0 and not seen[mapId] and guard < 12 and C_Map and C_Map.GetMapInfo do
        seen[mapId] = true
        chain[#chain + 1] = mapId
        local info = C_Map.GetMapInfo(mapId)
        mapId = info and info.parentMapID
        guard = guard + 1
    end
    return chain
end

local function CommonMap(a, b)
    local parents = {}
    local chain = ParentChain(a)
    for i = 1, #chain do
        parents[chain[i]] = true
    end
    chain = ParentChain(b)
    for i = 1, #chain do
        if parents[chain[i]] then
            return chain[i]
        end
    end
end

local function VectorXY(pos)
    if not pos then
        return nil
    end
    if pos.GetXY then
        return pos:GetXY()
    end
    return pos.x, pos.y
end

local function ProjectToMap(srcMap, x, y, destMap)
    if not destMap then
        return nil
    end
    if srcMap == destMap then
        return x, y
    end
    local continent, wx, wy = WorldOn(srcMap, x, y)
    if not (continent and wx and C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then
        return nil
    end
    local ok, first, second = pcall(C_Map.GetMapPosFromWorldPos, continent, CreateVector2D(wx, wy), destMap)
    if not ok then
        return nil
    end
    local mx, my = VectorXY(first)
    if not mx then
        mx, my = VectorXY(second)
    end
    return mx, my
end

-- Published docks that cross continents. A hunt on the other continent aims
-- at the nearest one this character can board. Arrival switches the arrow
-- back to the hunt, because both are then on the same continent.
-- Wowhead Classic flight, zeppelin, and ship guide.
local CROSSINGS = {
    { id = "durotar", zone = "Durotar", place = "Durotar", x = 50.8, y = 13.6, faction = "Horde", kind = "Zeppelin", to = { "tirisfal", "gromgol" } },
    { id = "tirisfal", zone = "Tirisfal Glades", place = "Tirisfal Glades", x = 61.0, y = 59.0, faction = "Horde", kind = "Zeppelin", to = { "durotar" } },
    { id = "gromgol", zone = "Stranglethorn Vale", place = "Grom'gol", x = 31.5, y = 29.6, faction = "Horde", kind = "Zeppelin", to = { "durotar" } },
    { id = "ratchet", zone = "The Barrens", place = "Ratchet", x = 63.6, y = 38.7, kind = "Ship", to = { "booty" } },
    { id = "booty", zone = "Stranglethorn Vale", place = "Booty Bay", x = 26.0, y = 73.2, kind = "Ship", to = { "ratchet" } },
    { id = "auberdine", zone = "Darkshore", place = "Auberdine", x = 32.7, y = 43.7, faction = "Alliance", kind = "Ship", to = { "menethilNorth" } },
    { id = "menethilNorth", zone = "Wetlands", place = "Menethil Harbor", x = 4.7, y = 57.0, faction = "Alliance", kind = "Ship", to = { "auberdine" } },
    { id = "menethilSouth", zone = "Wetlands", place = "Menethil Harbor", x = 5.0, y = 63.0, faction = "Alliance", kind = "Ship", to = { "theramore" } },
    { id = "theramore", zone = "Dustwallow Marsh", place = "Theramore", x = 71.0, y = 56.0, faction = "Alliance", kind = "Ship", to = { "menethilSouth" } },
}

local function DockLabel(dock)
    if dock and dock.place and dock.place ~= "" then
        return dock.kind .. " in " .. dock.place
    end
    return dock and dock.kind or ""
end

local crossingById = {}
for i = 1, #CROSSINGS do
    crossingById[CROSSINGS[i].id] = CROSSINGS[i]
end

local function DockWorld(place)
    if place.continent then
        return place.continent, place.wx, place.wy, place.mapId
    end
    local mapId = GQ.Map and GQ.Map.ZoneMap and GQ.Map:ZoneMap(place.zone)
    if not mapId then
        return nil
    end
    local continent, wx, wy = WorldOn(mapId, place.x / 100, place.y / 100)
    if not continent then
        return nil
    end
    place.mapId = mapId
    place.continent = continent
    place.wx = wx
    place.wy = wy
    return continent, wx, wy, mapId
end

local function NearestCrossing(playerContinent, pwx, pwy, huntContinent)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local best, bestDist
    for i = 1, #CROSSINGS do
        local dock = CROSSINGS[i]
        if not dock.faction or dock.faction == faction then
            local continent, wx, wy = DockWorld(dock)
            if continent == playerContinent and wx then
                local reaches
                local tos = dock.to
                for t = 1, #tos do
                    local dest = crossingById[tos[t]]
                    local destContinent = dest and DockWorld(dest)
                    if destContinent == huntContinent then
                        reaches = true
                        break
                    end
                end
                if reaches then
                    local dx = wx - pwx
                    local dy = wy - pwy
                    local dist = dx * dx + dy * dy
                    if not bestDist or dist < bestDist then
                        best = dock
                        bestDist = dist
                    end
                end
            end
        end
    end
    return best
end

function GQ.Guide:AnchorToTracker()
    local frame = self.frame
    local tracker = GQ.Tracker and GQ.Tracker.frame
    if not frame or not tracker or frame.anchorHost == tracker then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", tracker, "TOPLEFT", 0, 4)
    frame.anchorHost = tracker
    local strata = tracker.GetFrameStrata and tracker:GetFrameStrata()
    if strata then
        frame:SetFrameStrata(strata)
    end
    if tracker.GetFrameLevel and frame.SetFrameLevel then
        frame:SetFrameLevel((tracker:GetFrameLevel() or 0) + 4)
    end
end

function GQ.Guide:RefreshChecks()
    if GQ.Tracker and GQ.Tracker.UpdateGuideChecks then
        GQ.Tracker:UpdateGuideChecks()
    end
end

function GQ.Guide:ShowEntry(entry)
    if not entry or not entry.id then
        return
    end
    CharSettings().guideEntryId = entry.id
    self._waypointKey = nil
    self:Apply()
    self:PlaceForeverPin(entry)
    self:RefreshChecks()
    if GQ.Pins and GQ.Pins.Sync then
        GQ.Pins:Sync()
    end
end

function GQ.Guide:PlaceForeverPin(entry)
    if not (entry and GQ.Map and GQ.Map.SpotForEntry and C_Map and C_Map.SetUserWaypoint and UiMapPoint) then
        return
    end
    local spot = GQ.Map:SpotForEntry(entry)
    if not spot or not spot.mapId or not spot.x or not spot.y then
        return
    end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(spot.mapId) then
        return
    end
    local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(spot.mapId, spot.x / 100, spot.y / 100))
    if not ok then
        return
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    self.ownsWaypoint = true
    self._waypointKey = string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0)
end

function GQ.Guide:ClearForeverPin()
    if not self.ownsWaypoint then
        return
    end
    self.ownsWaypoint = false
    self._waypointKey = nil
    if C_Map and C_Map.ClearUserWaypoint then
        pcall(C_Map.ClearUserWaypoint)
    end
end

function GQ.Guide:Dismiss()
    CharSettings().guideEntryId = nil
    self:ClearForeverPin()
    self:Apply()
    self:RefreshChecks()
    if GQ.Pins and GQ.Pins.Sync then
        GQ.Pins:Sync()
    end
end

function GQ.Guide:Apply()
    local frame = self.frame
    if not frame then
        return
    end
    local id = CharSettings().guideEntryId
    if self:IsSuppressed() or not id then
        frame:Hide()
        return
    end
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if not entry then
        frame:Hide()
        return
    end
    frame.entryId = id
    frame.spot = nil
    frame.spotUntil = 0
    frame:Show()
end

local function UpdateGuide(frame)
    GQ.Guide:AnchorToTracker()
    local id = frame.entryId
    if not id or GQ.Guide:IsSuppressed() then
        frame:Hide()
        return
    end
    local entry = GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(id)
    if not entry then
        frame:Hide()
        return
    end
    local now = GetTime and GetTime() or 0
    if not frame.spotUntil or now >= frame.spotUntil then
        frame.spotUntil = now + 0.3
        frame.spot = GQ.Data and GQ.Data.NearestCoordinateSpot and GQ.Data:NearestCoordinateSpot(entry.itemId) or nil
    end
    local spot = frame.spot
    local facing = 0
    if GetPlayerFacing then
        local ok, value = pcall(GetPlayerFacing)
        if ok and type(value) == "number" then
            facing = value
        end
    end
    frame.crossing = nil
    local text = spot and spot.map or "No pin"
    local rotation = 0
    local spotMap = spot and GQ.Data and GQ.Data.SpotMapId and GQ.Data:SpotMapId(spot)
    local px, py = spotMap and PositionOn(spotMap)
    if spot and px and py and spot.x and spot.y then
        local sx, sy = spot.x / 100, spot.y / 100
        local pc, pwx, pwy = WorldOn(spotMap, px, py)
        local sc, swx, swy = WorldOn(spotMap, sx, sy)
        if pc and sc and pc == sc then
            local dx = swx - pwx
            local dy = swy - pwy
            local dist = math.sqrt(dx * dx + dy * dy)
            text = FormatYards(dist) or text
            if dist < HERE_YARDS then
                rotation = math.pi
            else
                rotation = AimWorld(spotMap, dx, dy, facing)
            end
        else
            -- Map y grows south. Yards need a world position, so the line
            -- keeps the zone name until that conversion exists.
            rotation = Aim(sx - px, py - sy, facing)
            text = spot.map or text
        end
    elseif spot and spotMap and spot.x and spot.y and C_Map and C_Map.GetBestMapForUnit then
        local playerMap = C_Map.GetBestMapForUnit("player")
        local guard = 0
        local pc, pwx, pwy
        while playerMap and guard < 8 and not pc do
            local x, y = PositionOn(playerMap)
            if x and y then
                pc, pwx, pwy = WorldOn(playerMap, x, y)
            end
            if pc then
                break
            end
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(playerMap)
            playerMap = info and info.parentMapID
            if playerMap == 0 then
                break
            end
            guard = guard + 1
        end
        local sc, swx, swy = WorldOn(spotMap, spot.x / 100, spot.y / 100)
        if pc and sc and pc == sc then
            local dx = swx - pwx
            local dy = swy - pwy
            local dist = math.sqrt(dx * dx + dy * dy)
            text = FormatYards(dist) or text
            if dist < HERE_YARDS then
                rotation = math.pi
            else
                rotation = AimWorld(spotMap, dx, dy, facing)
            end
        else
            local dock = pc and sc and pc ~= sc and NearestCrossing(pc, pwx, pwy, sc)
            if dock then
                local dx = dock.wx - pwx
                local dy = dock.wy - pwy
                local dist = math.sqrt(dx * dx + dy * dy)
                frame.crossing = dock
                if dist < HERE_YARDS then
                    rotation = math.pi
                    text = "Here"
                else
                    rotation = AimWorld(dock.mapId, dx, dy, facing)
                    text = dock.kind
                end
            else
                local here = C_Map.GetBestMapForUnit("player")
                local shared = here and CommonMap(here, spotMap)
                local ppx, ppy, ssx, ssy
                if shared then
                    ppx, ppy = PositionOn(shared)
                    if not ppx and here then
                        local hx, hy = PositionOn(here)
                        ppx, ppy = ProjectToMap(here, hx, hy, shared)
                    end
                    ssx, ssy = ProjectToMap(spotMap, spot.x / 100, spot.y / 100, shared)
                end
                if ppx and ppy and ssx and ssy then
                    rotation = Aim(ssx - ppx, ppy - ssy, facing)
                    text = spot.map or text
                end
            end
        end
    end
    if frame.distance and frame.distanceText ~= text then
        frame.distanceText = text
        frame.distance:SetText(text)
    end
    if frame.arrow then
        frame.arrow:Show()
        frame.arrow:SetAlpha(1)
        local rel = WrapPi(rotation)
        local index = text == "Here" and (ARROW_FRAMES / 2) or ArrowIndex(rel)
        local left = index / ARROW_FRAMES
        frame.arrow:SetTexCoord(left, left + 1 / ARROW_FRAMES, 0, 1)
    end
    if spot and GQ.Guide.ownsWaypoint then
        local key = string.format("%s|%.1f|%.1f", spot.map or "", spot.x or 0, spot.y or 0)
        if key ~= GQ.Guide._waypointKey then
            local guided = GQ.Data:GetEntryById(id)
            if guided then
                GQ.Guide:PlaceForeverPin(guided)
            end
            GQ.Guide._waypointKey = key
        end
    end
end

function GQ.Guide:Init()
    if GearQuestForeverDB and GearQuestForeverDB.settings then
        GearQuestForeverDB.settings.guideEntryId = nil
    end
    if self.frame then
        self:AnchorToTracker()
        self:Apply()
        return
    end

    local frame = CreateFrame("Frame", "GearQuestGuide", UIParent)
    frame:SetSize(136, 130)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        GameTooltip:Hide()
        local tracker = GQ.Tracker and GQ.Tracker.frame
        if tracker and tracker.StartMoving then
            tracker:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        local tracker = GQ.Tracker and GQ.Tracker.frame
        if tracker and tracker.StopMovingOrSizing then
            tracker:StopMovingOrSizing()
        end
        if GQ.Tracker and GQ.Tracker.SavePosition then
            GQ.Tracker:SavePosition()
        end
    end)
    frame:SetScript("OnUpdate", UpdateGuide)
    frame:SetScript("OnEnter", function(self)
        local entry = self.entryId and GQ.Data and GQ.Data.GetEntryById and GQ.Data:GetEntryById(self.entryId)
        if not entry then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local name = GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry) or entry.questName or "Hunt"
        GameTooltip:SetText(name, GOLD_R, GOLD_G, GOLD_B)
        local spot = self.spot
        if spot and spot.map then
            GameTooltip:AddLine(string.format("%s %.1f, %.1f", spot.map, spot.x or 0, spot.y or 0), 1, 1, 1)
        end
        if self.crossing then
            GameTooltip:AddLine(self.crossing.kind .. " in " .. self.crossing.zone, 1, 1, 1)
        end
        GameTooltip:AddLine("Drag to move", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local distance = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, _, flags = GameFontNormal:GetFont()
    if font then
        distance:SetFont(font, 16, "OUTLINE")
    end
    distance:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    distance:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    distance:SetWidth(112)
    distance:SetJustifyH("LEFT")
    distance:SetText(" ")
    frame.distance = distance

    local arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(110, 110)
    arrow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18)
    arrow:SetTexture(ARROW_TEXTURE)
    frame.arrow = arrow

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(18, 18)
    close:SetPoint("TOPLEFT", frame, "TOPLEFT", 114, 0)
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if font then
        closeText:SetFont(font, 13, "OUTLINE")
    end
    closeText:SetPoint("CENTER", close, "CENTER", 1, 0)
    closeText:SetText("X")
    closeText:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
    close:SetScript("OnClick", function()
        GQ.Guide:Dismiss()
    end)
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Remove the guide", 1, 1, 1)
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.frame = frame
    frame:Hide()
    self:AnchorToTracker()
    self:Apply()
end
