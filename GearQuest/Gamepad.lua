local ADDON_NAME, GQ = ...

GQ.Log = GQ.Log or {}

-- Gamepad UI only. Mouse mode never enables this. The log takes pad buttons
-- while it is open: arrows move a highlight, the bottom face button activates
-- it, the right face button closes, and the bumpers change page.
local DIRECTION = {
    PADDUP = "up",
    PADDDOWN = "down",
    PADDLEFT = "left",
    PADDRIGHT = "right",
    PADLSTICKUP = "up",
    PADLSTICKDOWN = "down",
    PADLSTICKLEFT = "left",
    PADLSTICKRIGHT = "right",
}

local HELD_NAMES = {
    up = { PADDUP = true, PADLSTICKUP = true },
    down = { PADDDOWN = true, PADLSTICKDOWN = true },
    left = { PADDLEFT = true, PADLSTICKLEFT = true },
    right = { PADDRIGHT = true, PADLSTICKRIGHT = true },
}

local PAGES = { "log", "lookup", "simulator", "settings" }

local function ObjectType(widget)
    if widget and widget.GetObjectType then
        return widget:GetObjectType()
    end
end

local function WidgetName(widget)
    if widget and widget.GetName then
        return widget:GetName()
    end
end

local function IsScrollBar(widget)
    local name = WidgetName(widget)
    return name and name:find("ScrollBar", 1, true) ~= nil
end

local function SliderAncestor(widget)
    local parent = widget and widget.GetParent and widget:GetParent()
    while parent do
        if ObjectType(parent) == "Slider" then
            return true
        end
        parent = parent.GetParent and parent:GetParent()
    end
    return false
end

local function Usable(widget)
    if not widget or widget.gqGamepadRing then
        return false
    end
    if not widget.IsShown or not widget:IsShown() then
        return false
    end
    if widget.IsVisible and not widget:IsVisible() then
        return false
    end
    local kind = ObjectType(widget)
    if kind ~= "Button" and kind ~= "CheckButton" and kind ~= "EditBox" and kind ~= "Slider" then
        return false
    end
    if IsScrollBar(widget) or (kind ~= "Slider" and SliderAncestor(widget)) then
        return false
    end
    local width = widget.GetWidth and widget:GetWidth() or 0
    local height = widget.GetHeight and widget:GetHeight() or 0
    if width < 8 or height < 8 then
        return false
    end
    if widget.IsEnabled and not widget:IsEnabled() then
        return false
    end
    if (kind == "Button" or kind == "CheckButton") and widget.IsMouseEnabled and not widget:IsMouseEnabled() then
        return false
    end
    return widget.GetCenter and widget:GetCenter() ~= nil
end

local function Walk(root, into)
    if not root or not root.IsShown or not root:IsShown() then
        return
    end
    if Usable(root) then
        into[#into + 1] = root
    end
    if root.GetChildren then
        local children = { root:GetChildren() }
        for i = 1, #children do
            Walk(children[i], into)
        end
    end
end

local function PageTab(log, page)
    local frame = log.frame
    if not frame then
        return nil
    end
    if page == "log" then
        return frame.tabLog
    elseif page == "lookup" then
        return frame.tabLookup
    elseif page == "simulator" then
        return frame.tabSimulator
    elseif page == "settings" then
        return frame.tabSettings
    end
end

function GQ.Log:GamepadOverlay()
    local frame = self.frame
    local panels = {
        frame and frame.sourceFilterMenu,
        frame and frame.playStylePanel,
        frame and frame.specPicker,
        self.weaponMenu,
    }
    local best, bestLevel
    for i = 1, #panels do
        local panel = panels[i]
        if panel and panel.IsShown and panel:IsShown() then
            local level = panel.GetFrameLevel and panel:GetFrameLevel() or 0
            if not best or level >= bestLevel then
                best = panel
                bestLevel = level
            end
        end
    end
    if not best then
        return nil
    end
    local probe = {}
    Walk(best, probe)
    if #probe == 0 then
        return nil
    end
    return best
end

function GQ.Log:GamepadCandidates()
    local list = {}
    local overlay = self:GamepadOverlay()
    if overlay then
        Walk(overlay, list)
        return list
    end
    local frame = self.frame
    if frame then
        Walk(frame, list)
        Walk(frame.sideTabRail, list)
    end
    return list
end

function GQ.Log:GamepadContains(list, widget)
    for i = 1, #list do
        if list[i] == widget then
            return true
        end
    end
    return false
end

local function CallHandler(widget, name)
    if not widget or not widget.GetScript then
        return
    end
    local handler = widget:GetScript(name)
    if handler then
        pcall(handler, widget)
    end
end

-- Mouse OnLeave closes filter flyouts. Only hunt rows and their (i) buttons
-- use those handlers, so a pad move can show the same tooltip a hover would.
local function HoverWidget(widget)
    if not widget then
        return false
    end
    if widget.rowType or widget.entry or widget.lookupItem then
        return true
    end
    local parent = widget.GetParent and widget:GetParent()
    return parent and (parent.rowType or parent.entry or parent.lookupItem) or false
end

function GQ.Log:GamepadEnsureRing()
    if self._padRing then
        return self._padRing
    end
    local ring
    local ok, created = pcall(CreateFrame, "Frame", nil, UIParent, "BackdropTemplate")
    if ok and created then
        ring = created
    else
        ring = CreateFrame("Frame", nil, UIParent)
    end
    ring.gqGamepadRing = true
    ring:Hide()
    ring:EnableMouse(false)
    pcall(ring.SetBackdrop, ring, {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    if ring.SetBackdropBorderColor then
        ring:SetBackdropBorderColor(1, 0.82, 0.15, 1)
    end
    self._padRing = ring
    return ring
end

function GQ.Log:GamepadReveal(widget)
    local node = widget
    while node and node.GetParent do
        local parent = node:GetParent()
        if parent and parent.GetScrollChild and parent:GetScrollChild() == node and parent.GetVerticalScroll then
            local top = widget:GetTop()
            local bottom = widget:GetBottom()
            local frameTop = parent:GetTop()
            local frameBottom = parent:GetBottom()
            if not top or not bottom or not frameTop or not frameBottom then
                return
            end
            local scale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
            if scale <= 0 then
                scale = 1
            end
            local current = parent:GetVerticalScroll() or 0
            local pad = 12
            if top > frameTop - 2 then
                parent:SetVerticalScroll(math.max(0, current - ((top - frameTop) / scale) - pad))
            elseif bottom < frameBottom + 2 then
                local range = 0
                if parent.GetVerticalScrollRange then
                    range = parent:GetVerticalScrollRange() or 0
                end
                local dest = current + ((frameBottom - bottom) / scale) + pad
                if dest > range then
                    dest = range
                end
                if dest < 0 then
                    dest = 0
                end
                parent:SetVerticalScroll(dest)
            end
            return
        end
        node = parent
    end
end

function GQ.Log:GamepadSetFocus(widget)
    local previous = self._padFocus
    if previous == widget then
        self:GamepadReveal(widget)
        return
    end
    if previous and HoverWidget(previous) then
        CallHandler(previous, "OnLeave")
    end
    self._padFocus = widget
    local ring = self:GamepadEnsureRing()
    if not widget then
        ring:Hide()
        return
    end
    ring:SetParent(widget)
    ring:ClearAllPoints()
    ring:SetPoint("TOPLEFT", widget, "TOPLEFT", -5, 5)
    ring:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 5, -5)
    local level = widget.GetFrameLevel and widget:GetFrameLevel() or 1
    ring:SetFrameLevel(level + 20)
    ring:Show()
    self:GamepadReveal(widget)
    if HoverWidget(widget) then
        CallHandler(widget, "OnEnter")
    end
end

function GQ.Log:GamepadPickInitial(list)
    local best, bestY, bestX
    for i = 1, #list do
        local widget = list[i]
        if widget ~= PageTab(self, "log")
            and widget ~= PageTab(self, "lookup")
            and widget ~= PageTab(self, "simulator")
            and widget ~= PageTab(self, "settings") then
            local x, y = widget:GetCenter()
            if y and (not best or y > bestY + 4 or (math.abs(y - bestY) <= 4 and x < bestX)) then
                best = widget
                bestY = y
                bestX = x
            end
        end
    end
    return best or list[1]
end

function GQ.Log:GamepadPick(origin, direction, list)
    local ox, oy = origin:GetCenter()
    if not ox then
        return nil
    end
    local best, bestScore
    local loose, looseScore
    for i = 1, #list do
        local widget = list[i]
        if widget ~= origin then
            local x, y = widget:GetCenter()
            if x then
                local dx = x - ox
                local dy = y - oy
                local primary, secondary
                if direction == "up" then
                    primary, secondary = dy, math.abs(dx)
                elseif direction == "down" then
                    primary, secondary = -dy, math.abs(dx)
                elseif direction == "left" then
                    primary, secondary = -dx, math.abs(dy)
                else
                    primary, secondary = dx, math.abs(dy)
                end
                if primary > 6 then
                    local score = primary + (secondary * 2.2)
                    if not loose or score < looseScore then
                        loose = widget
                        looseScore = score
                    end
                    if secondary < (primary * 1.75) + 48 and (not best or score < bestScore) then
                        best = widget
                        bestScore = score
                    end
                end
            end
        end
    end
    return best or loose
end

function GQ.Log:GamepadNudgeSlider(slider, direction)
    local value = slider:GetValue() or 0
    local step = slider.GetValueStep and slider:GetValueStep() or 1
    if not step or step <= 0 then
        step = 1
    end
    if direction == "left" then
        value = value - step
    else
        value = value + step
    end
    local minValue, maxValue
    if slider.GetMinMaxValues then
        minValue, maxValue = slider:GetMinMaxValues()
    end
    if minValue and value < minValue then
        value = minValue
    end
    if maxValue and value > maxValue then
        value = maxValue
    end
    slider:SetValue(value)
end

function GQ.Log:GamepadNudgeEdit(edit, direction)
    local value = tonumber(edit:GetText()) or 1
    if direction == "left" then
        value = value - 1
    else
        value = value + 1
    end
    if value < 1 then
        value = 1
    elseif value > 60 then
        value = 60
    end
    edit:SetText(tostring(value))
end

function GQ.Log:GamepadMove(direction)
    local list = self:GamepadCandidates()
    local focus = self._padFocus
    if not focus or not self:GamepadContains(list, focus) then
        self:GamepadSetFocus(self:GamepadPickInitial(list))
        return
    end
    local kind = ObjectType(focus)
    if kind == "Slider" and (direction == "left" or direction == "right") then
        self:GamepadNudgeSlider(focus, direction)
        return
    end
    if kind == "EditBox" and (direction == "left" or direction == "right") then
        self:GamepadNudgeEdit(focus, direction)
        return
    end
    local nextWidget = self:GamepadPick(focus, direction, list)
    if nextWidget then
        self:GamepadSetFocus(nextWidget)
    end
end

function GQ.Log:GamepadPage(step)
    if self:GamepadOverlay() then
        return
    end
    local current = self:GetPageTab()
    local index = 1
    for i = 1, #PAGES do
        if PAGES[i] == current then
            index = i
            break
        end
    end
    index = index + step
    if index < 1 then
        index = #PAGES
    elseif index > #PAGES then
        index = 1
    end
    self:SetPageTab(PAGES[index])
    local list = self:GamepadCandidates()
    self:GamepadSetFocus(self:GamepadPickInitial(list))
end

function GQ.Log:GamepadConfirm()
    local widget = self._padFocus
    local list = self:GamepadCandidates()
    if not widget or not self:GamepadContains(list, widget) then
        self:GamepadSetFocus(self:GamepadPickInitial(list))
        return
    end
    local before = self:GamepadOverlay()
    local kind = ObjectType(widget)
    if kind == "EditBox" then
        CallHandler(widget, "OnEnterPressed")
    elseif kind == "Button" or kind == "CheckButton" then
        pcall(widget.Click, widget, "LeftButton")
    end
    local after = self:GamepadOverlay()
    if after and after ~= before then
        local opened = {}
        Walk(after, opened)
        self:GamepadSetFocus(self:GamepadPickInitial(opened))
        return
    end
    if widget.IsShown and not widget:IsShown() then
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
    end
end

function GQ.Log:GamepadBack()
    if self.slotRankPanel and self.slotRankPanel:IsShown() and self.HideSlotRankPanel then
        self:HideSlotRankPanel()
        return
    end
    local overlay = self:GamepadOverlay()
    if overlay then
        if overlay == self.slotRankPanel and self.HideSlotRankPanel then
            self:HideSlotRankPanel()
        elseif overlay == (self.frame and self.frame.specPicker) and self.HideSpecPicker then
            self:HideSpecPicker()
        else
            overlay:Hide()
        end
        self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
        return
    end
    self:Hide()
end

function GQ.Log:GamepadButton(button)
    if not self._padOn or not GQ.UsesGamepad or not GQ:UsesGamepad() then
        return
    end
    local name = type(button) == "string" and button:upper() or ""
    local now = GetTime()
    if name == self._padLastName and self._padLastAt and (now - self._padLastAt) < 0.05 then
        return
    end
    self._padLastName = name
    self._padLastAt = now
    local direction = DIRECTION[name]
    if direction then
        self:GamepadMove(direction)
        self._padRepeatDir = direction
        self._padRepeatAt = GetTime() + 0.34
        return
    end
    self._padRepeatDir = nil
    if name == "PADLSHOULDER" then
        self:GamepadPage(-1)
    elseif name == "PADRSHOULDER" then
        self:GamepadPage(1)
    elseif name == "PAD1" then
        self:GamepadConfirm()
    elseif name == "PAD2" then
        self:GamepadBack()
    end
end

function GQ.Log:GamepadReadButtons()
    if not C_GamePad or not C_GamePad.GetDeviceMappedState or not C_GamePad.ButtonIndexToBinding then
        return nil
    end
    local ok, state = pcall(C_GamePad.GetDeviceMappedState)
    if not ok or type(state) ~= "table" or type(state.buttons) ~= "table" then
        return nil
    end
    local down = {}
    for index, pressed in pairs(state.buttons) do
        if pressed then
            local boundOk, binding = pcall(C_GamePad.ButtonIndexToBinding, index)
            if (not boundOk or type(binding) ~= "string") and type(index) == "number" then
                boundOk, binding = pcall(C_GamePad.ButtonIndexToBinding, index - 1)
            end
            if boundOk and type(binding) == "string" then
                down[binding:upper()] = true
            end
        end
    end
    return down
end

function GQ.Log:GamepadPollEdges()
    local down = self:GamepadReadButtons()
    if not down then
        return
    end
    local was = self._padWasDown or {}
    self._padWasDown = down
    for name in pairs(down) do
        if not was[name] then
            self:GamepadButton(name)
        end
    end
end

function GQ.Log:GamepadDirectionHeld(direction)
    local down = self:GamepadReadButtons()
    local names = down and HELD_NAMES[direction]
    if not names then
        return false
    end
    for name in pairs(down) do
        if names[name] then
            return true
        end
    end
    return false
end

function GQ.Log:GamepadOnUpdate()
    if not self._padOn then
        return
    end
    if not self.frame or not self.frame:IsShown() or not GQ:UsesGamepad() then
        self:GamepadRelease()
        return
    end
    local focus = self._padFocus
    if not focus or not focus.IsShown or not focus:IsShown() then
        local now = GetTime()
        if not self._padSeekAt or now >= self._padSeekAt then
            self._padSeekAt = now + 0.2
            self:GamepadSetFocus(self:GamepadPickInitial(self:GamepadCandidates()))
        end
    end
    local direction = self._padRepeatDir
    if self._padPoll then
        self:GamepadPollEdges()
        if not self._padOn then
            return
        end
    end
    if direction and self._padRepeatAt and GetTime() >= self._padRepeatAt then
        if self:GamepadDirectionHeld(direction) then
            self:GamepadMove(direction)
            local kind = ObjectType(self._padFocus)
            local delay = 0.09
            if kind == "Slider" or kind == "EditBox" then
                delay = 0.18
            end
            self._padRepeatAt = GetTime() + delay
        else
            self._padRepeatDir = nil
        end
    end
end

local function PadTick()
    if GQ.Log and GQ.Log.GamepadOnUpdate then
        GQ.Log:GamepadOnUpdate()
    end
end

function GQ.Log:GamepadEnsureDriver()
    if self._padDriver then
        return
    end
    self._padDriver = CreateFrame("Frame")
end

function GQ.Log:GamepadAcquire()
    local frame = self.frame
    if not frame or not frame:IsShown() or not GQ.UsesGamepad or not GQ:UsesGamepad() then
        self:GamepadRelease()
        return
    end
    if GQ.SilenceGamepadActionPopup then
        GQ:SilenceGamepadActionPopup()
    end
    self:GamepadEnsureDriver()
    self._padDriver:SetScript("OnUpdate", PadTick)
    self:GamepadEnsureRing()
    local enabled = pcall(frame.EnableGamePadButton, frame, true)
    if enabled then
        pcall(frame.SetScript, frame, "OnGamePadButtonDown", function(_, button)
            GQ.Log:GamepadButton(button)
        end)
    end
    self._padOn = true
    self._padPoll = true
    self._padWasDown = self:GamepadReadButtons() or {}
    local list = self:GamepadCandidates()
    self:GamepadSetFocus(self:GamepadPickInitial(list))
end

function GQ.Log:GamepadRelease()
    self._padOn = false
    self._padPoll = false
    self._padRepeatDir = nil
    self._padWasDown = nil
    if self._padDriver then
        self._padDriver:SetScript("OnUpdate", nil)
    end
    local frame = self.frame
    if frame then
        pcall(frame.EnableGamePadButton, frame, false)
        local hasScript, current = pcall(frame.GetScript, frame, "OnGamePadButtonDown")
        if hasScript and current then
            pcall(frame.SetScript, frame, "OnGamePadButtonDown", nil)
        end
    end
    if self._padFocus and HoverWidget(self._padFocus) then
        CallHandler(self._padFocus, "OnLeave")
    end
    self._padFocus = nil
    if self._padRing then
        self._padRing:Hide()
        self._padRing:SetParent(UIParent)
    end
end
