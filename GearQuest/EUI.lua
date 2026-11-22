-- EUI.lua — Optional EllesmereUI skin integration for GearQuest Forever.
--
-- When the player runs EllesmereUI (with the "Blizz UI Enhanced" module,
-- v9.7+), register these windows with EUI's third-party skinning API so they
-- take on the player's EllesmereUI theme (accent, borders, fonts) instead of
-- the addon's built-in gold/parchment look. Without EllesmereUI this file is a
-- no-op and changes nothing.
--
-- Development note: this is the v1.4.0 addition. Ask before merging upstream —
-- it only affects EUI users and is safe without EUI, but it is new surface.

local _, GQ = ...

if not EllesmereUI or not EllesmereUI.RegisterSkin then
    return -- no EUI (or EUI too old): keep the default look, do nothing.
end

-- Windows we re-shell with EUI's window backdrop + border.
local SHELL_FRAMES = {
    "GearQuestLogFrame",        -- the Log (main window)
}

-- Floating / embedded surfaces we re-panel with EUI's flat panel + border.
local PANEL_FRAMES = {
    "GearQuestSimulateDialog",  -- Simulator window
    "GearQuestTooltipsPanel",   -- Tooltips settings
    "GearQuestCustomSpecPanel", -- Custom spec editor
    "GearQuestGuide",           -- Guide overlay
    "GearQuestPortraitGuide",   -- Portrait guide overlay
    "GearQuestSpecPicker",      -- spec chooser
    "GearQuestSlotPopup",       -- char-panel upgrade popup
    "GearQuestTracker",         -- "hunts on screen" objective frame
    "GearQuestObtainToast",     -- hunt-done toast banner
    "GearQuestSourceFilterMenu",
    "GearQuestArmorMenu",
    "GearQuestWeaponMenu",
    "GearQuestLanguageMenu",
    "GearQuestPlayStylePanel",
    "GearQuestCustomSpecMenu",
    "GearQuestDungeonFilterBranch",
}

local function FrameNamed(name)
    local f = _G[name]
    if f and f.GetObjectType then return f end
    return nil
end

local function SkinWidget(S, f)
    if not f or not f.GetObjectType then return end
    local ot = f:GetObjectType()
    local name = (f.GetName and f:GetName()) or ""

    if ot == "Button" then
        -- Close / exit buttons get the EUI "X".
        if S.CloseButton and (name:find("Close", 1, true)
            or name:find("Exit", 1, true)) then
            pcall(S.CloseButton, f)
        elseif S.Tab and name:find("Tab", 1, true) then
            pcall(S.Tab, f)
        else
            local keep = f.Icon and { "Icon" } or nil
            pcall(S.Button, f, keep)
        end
    elseif ot == "EditBox" and S.EditBox then
        pcall(S.EditBox, f)
    elseif ot == "CheckButton" and S.Checkbox then
        pcall(S.Checkbox, f)
    end
    -- Sliders/scrollbars/drop-widgets are left to build the EUI look less
    -- invasively; the themes above carry the visual weight.
end

local function SkinNamed(S, f, depth)
    depth = depth or 0
    if depth > 8 then return end
    if f.GetName and (f:GetName() or ""):find("^GearQuest", 1) then
        SkinWidget(S, f)
    end
    for _, c in ipairs(f.GetChildren and { f:GetChildren() } or {}) do
        SkinNamed(S, c, depth + 1)
    end
end

local function Apply(S)
    local painted = 0
    for _, n in ipairs(SHELL_FRAMES) do
        local f = FrameNamed(n)
        if f and S.Shell then pcall(S.Shell, f); painted = painted + 1 end
    end
    for _, n in ipairs(PANEL_FRAMES) do
        local f = FrameNamed(n)
        if f and S.Panel then pcall(S.Panel, f); painted = painted + 1 end
    end
    -- Inner buttons / edit boxes / check buttons of the shelled windows.
    for _, n in ipairs(SHELL_FRAMES) do
        local f = FrameNamed(n)
        if f then SkinNamed(S, f, 0) end
    end
    return painted
end

-- EUI calls this at login/registration and again whenever the player switches
-- theme in EUI options, so the addon tracks the user's current look.
local residentS
EllesmereUI.RegisterSkin("GearQuestForever", function(S)
    residentS = residentS or S
    Apply(S)
end)

-- Re-paint windows created or (re)shown after login. Idempotent + pcall'd.
local function HookShown(frame)
    if frame and not frame._euiGQ then
        frame._euiGQ = true
        frame:HookScript("OnShow", function()
            if residentS then Apply(residentS) end
        end)
    end
end

local function HookAllShown()
    for _, n in ipairs(SHELL_FRAMES) do HookShown(FrameNamed(n)) end
    for _, n in ipairs(PANEL_FRAMES) do HookShown(FrameNamed(n)) end
    -- Module entry points that (re)build chrome.
    local Log = GQ and GQ.Log;    if Log and Log.Show    and not Log._euiGQ    then Log._euiGQ    = true; hooksecurefunc(Log, "Show",    function() if residentS then Apply(residentS) end end) end
    local To = GQ and GQ.Toast;   if To  and To.Init     and not To._euiGQ     then To._euiGQ     = true; hooksecurefunc(To,  "Init",     function() if residentS then Apply(residentS) end end) end
    local Pop = GQ and GQ.Popup;  if Pop and Pop.Show    and not Pop._euiGQ    then Pop._euiGQ    = true; hooksecurefunc(Pop, "Show",    function() if residentS then Apply(residentS) end end) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    HookAllShown()
    if residentS then Apply(residentS) end
end)

-- Catch windows created right after a module loads (e.g. the Tracker), then stop.
local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(self, elapsed)
    local n = (self._n or 0) + elapsed
    if n > 30 then self:Hide(); return end
    if residentS then HookAllShown(); Apply(residentS) end
end)
