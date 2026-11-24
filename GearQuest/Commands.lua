local _, GQ = ...
local L = GQ.L

GQ.Commands = GQ.Commands or {}

local PREVIEW_PREFIXES = {
    "set ",
    "class ",
    "level ",
    "lvl ",
    "faction ",
    "spec ",
    "preview ",
}

local function IsPreviewCommand(lower)
    if lower == "set"
        or lower == "debug"
        or lower == "status"
        or lower == "preview"
        or lower == "me"
    then
        return true
    end

    for _, prefix in ipairs(PREVIEW_PREFIXES) do
        if lower:sub(1, #prefix) == prefix then
            return true
        end
    end

    return false
end

-- /gq mem [seconds]. Stand still with the arrow closed and nothing tracked.
-- Counts the idle paths and the map calls while the addon memory moves.
local memorySample

local function MemorySay(text)
    _G.print("|cff66ccffGearQuest|r mem: " .. tostring(text))
end

local function MemoryWrap(tbl, key, label, counts, restores)
    if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
        return
    end
    local orig = tbl[key]
    tbl[key] = function(...)
        counts[label] = (counts[label] or 0) + 1
        return orig(...)
    end
    restores[#restores + 1] = function()
        if tbl[key] ~= orig then
            tbl[key] = orig
        end
    end
end

function GQ.Commands:MemorySample(seconds)
    if memorySample then
        MemorySay("already sampling")
        return
    end
    if not (C_Timer and C_Timer.NewTicker and UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then
        MemorySay("this client cannot sample addon memory")
        return
    end
    seconds = tonumber(seconds) or 30
    if seconds < 10 then
        seconds = 10
    elseif seconds > 120 then
        seconds = 120
    end

    local counts = {}
    local restores = {}
    if C_Map then
        MemoryWrap(C_Map, "GetBestMapForUnit", "GetBestMapForUnit", counts, restores)
        MemoryWrap(C_Map, "GetPlayerMapPosition", "GetPlayerMapPosition", counts, restores)
        MemoryWrap(C_Map, "GetWorldPosFromMapPos", "GetWorldPosFromMapPos", counts, restores)
        MemoryWrap(C_Map, "GetMapPosFromWorldPos", "GetMapPosFromWorldPos", counts, restores)
        MemoryWrap(C_Map, "GetMapInfo", "GetMapInfo", counts, restores)
    end
    MemoryWrap(_G, "CreateVector2D", "CreateVector2D", counts, restores)
    if GQ.Data then
        MemoryWrap(GQ.Data, "PlayerWorld", "PlayerWorld", counts, restores)
        MemoryWrap(GQ.Data, "SpotWorld", "SpotWorld", counts, restores)
        MemoryWrap(GQ.Data, "NearestCoordinateSpot", "NearestCoordinateSpot", counts, restores)
        MemoryWrap(GQ.Data, "InvalidateQueryCache", "InvalidateQueryCache", counts, restores)
        MemoryWrap(GQ.Data, "AddUnitGearHint", "AddUnitGearHint", counts, restores)
        MemoryWrap(GQ.Data, "AddUnitGearLines", "AddUnitGearLines", counts, restores)
        MemoryWrap(GQ.Data, "StartWorldDropBuild", "StartWorldDropBuild", counts, restores)
        MemoryWrap(GQ.Data, "WarmQueryCacheAsync", "WarmQueryCacheAsync", counts, restores)
    end
    if GQ.Log then
        MemoryWrap(GQ.Log, "RefreshNearestCoordinates", "RefreshNearest", counts, restores)
        MemoryWrap(GQ.Log, "CheckAutoCompletion", "CheckAutoCompletion", counts, restores)
        MemoryWrap(GQ.Log, "ScheduleAutoCompletionCheck", "ScheduleAutoComplete", counts, restores)
        MemoryWrap(GQ.Log, "Refresh", "LogRefresh", counts, restores)
    end
    if GQ.Indicator then
        MemoryWrap(GQ.Indicator, "RefreshAll", "IndicatorRefresh", counts, restores)
        MemoryWrap(GQ.Indicator, "RebuildCacheAsync", "RebuildArrows", counts, restores)
    end

    local frame = CreateFrame("Frame")
    local events = {
        "QUEST_LOG_UPDATE",
        "BAG_UPDATE",
        "BAG_UPDATE_DELAYED",
        "GET_ITEM_INFO_RECEIVED",
        "UNIT_AURA",
        "UNIT_INVENTORY_CHANGED",
        "NAME_PLATE_UNIT_ADDED",
        "UPDATE_MOUSEOVER_UNIT",
        "ZONE_CHANGED",
        "ZONE_CHANGED_INDOORS",
    }
    for i = 1, #events do
        frame:RegisterEvent(events[i])
    end
    frame:SetScript("OnEvent", function(_, event)
        counts[event] = (counts[event] or 0) + 1
    end)

    local function shown(widget)
        return widget and widget.IsShown and widget:IsShown() and "on" or "off"
    end
    local function StateText()
        local tracked = 0
        if GQ.Tracker and GQ.Tracker.GetTrackedEntries then
            local ok, entries = pcall(GQ.Tracker.GetTrackedEntries, GQ.Tracker)
            if ok and type(entries) == "table" then
                tracked = #entries
            end
        end
        local guideId = "none"
        if GQ.Guide and GQ.Guide.GuidedId then
            local ok, id = pcall(GQ.Guide.GuidedId, GQ.Guide)
            if ok and id then
                guideId = tostring(id)
            end
        end
        return string.format(
            "log %s, guide %s, tracker %s, tracked %d, guide id %s",
            shown(GQ.Log and GQ.Log.frame),
            shown(GQ.Guide and GQ.Guide.frame),
            shown(GQ.Tracker and GQ.Tracker.frame),
            tracked,
            guideId
        )
    end

    local function AddonKB()
        UpdateAddOnMemoryUsage()
        return GetAddOnMemoryUsage("GearQuestForever") or 0
    end

    local samples = { AddonKB() }
    local elapsed = 0
    local nextReport = 10
    memorySample = true
    MemorySay(string.format("sampling %d seconds. Stand still. %s", seconds, StateText()))

    local ticker
    ticker = C_Timer.NewTicker(1, function()
        if not memorySample then
            ticker:Cancel()
            return
        end
        elapsed = elapsed + 1
        samples[#samples + 1] = AddonKB()
        if elapsed >= seconds then
            ticker:Cancel()
            memorySample = nil
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            for i = 1, #restores do
                restores[i]()
            end
            local started = samples[1]
            local ended = samples[#samples]
            MemorySay(string.format(
                "%.0f seconds, %.0f KB to %.0f KB (%+.2f KB/s). %s",
                elapsed,
                started,
                ended,
                (ended - started) / elapsed,
                StateText()
            ))
            local rows = {}
            for name, n in pairs(counts) do
                if n > 0 then
                    rows[#rows + 1] = { name = name, n = n }
                end
            end
            table.sort(rows, function(a, b)
                if a.n ~= b.n then
                    return a.n > b.n
                end
                return a.name < b.name
            end)
            if #rows == 0 then
                MemorySay("no counted calls")
                return
            end
            local parts = {}
            local limit = math.min(14, #rows)
            for i = 1, limit do
                parts[#parts + 1] = rows[i].name .. " " .. rows[i].n
            end
            MemorySay(table.concat(parts, ", "))
            return
        end
        if elapsed >= nextReport then
            nextReport = nextReport + 10
            local now = samples[#samples]
            MemorySay(string.format("%d seconds, %.0f KB (%+.1f)", elapsed, now, now - samples[1]))
        end
    end)
end

function GQ.Commands:Init()
    SLASH_GEARQUEST1 = "/gearquest"
    SLASH_GEARQUEST2 = "/gq"

    SlashCmdList["GEARQUEST"] = function(msg)
        msg = strtrim(msg or "")
        local lower = msg:lower()

        if lower == "" then
            GQ.Log:Toggle()
        elseif IsPreviewCommand(lower) then
            GQ.Preview:HandleCommand(lower)
            GQ:RefreshUI()
        elseif lower == "log" then
            GQ.Log:Toggle()
        elseif lower == "track" then
            if GQ.Log.selectedHuntId then
                GQ.Log:TrackHunt(GQ.Log.selectedHuntId)
            else
                GQ:Chat("|cff66ccffGearQuest|r: " .. L["No upgrade selected. Open |cff00ff00/gq log|r and pick one."])
            end
        elseif lower == "untrack" then
            if GQ.Log.selectedHuntId then
                GQ.Log:RequestUntrackHunt(GQ.Log.selectedHuntId)
            else
                GQ:Chat("|cff66ccffGearQuest|r: " .. L["No upgrade selected."])
            end
        elseif lower == "weights" then
            local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass() or "?"
            local specId = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or "?"
            local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
            local rev = GQ.SCORING_WEIGHTS_REVISION or "?"
            GQ:Chat(string.format(
                "|cff66ccffGearQuest|r weights rev |cff00ff00%s|r · addon v%s · %s/%s L%s",
                rev,
                GQ.VERSION or "?",
                classFile,
                specId,
                tostring(level)
            ))
            if GQ.Compare and GQ.Compare.GetEffectiveScoringRows then
                local effectiveRows = GQ.Compare:GetEffectiveScoringRows(classFile, specId, level)
                if effectiveRows then
                    for i = 1, math.min(6, #effectiveRows) do
                        local val = effectiveRows[i].value
                        local text = (val == math.floor(val)) and tostring(val) or string.format("%.2f", val)
                        GQ:Chat(string.format(
                            "  |cffaaaaaa%s|r |cffffffff%s|r",
                            effectiveRows[i].label,
                            text
                        ))
                    end
                    if #effectiveRows > 6 then
                        GQ:Chat(string.format("  |cffaaaaaa… %d more (hover the spec icon)|r", #effectiveRows - 6))
                    end
                end
            end
        elseif lower == "mem" or lower:sub(1, 4) == "mem " then
            local secs = lower:match("^mem%s+(%d+)")
            GQ.Commands:MemorySample(secs)
        elseif lower == "help" then
            GQ.Preview:PrintHelp()
        elseif lower == "wipe data" then
            GQ.Log:WipeCharacterData()
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["Cleared hunt progress for this character (tracked, completed, and obtained). Preview and UI settings kept."])
        elseif lower == "seen" or lower == "seen wipe" then
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["The seen-item notebook is retired. Forever item data comes from Wowhead."])
        else
            GQ:Chat("|cff66ccffGearQuest|r: " .. L["Unknown command. Try |cff00ff00/gq help|r, |cff00ff00/gq set|r, or |cff00ff00/gq log|r."])
        end
    end
end
