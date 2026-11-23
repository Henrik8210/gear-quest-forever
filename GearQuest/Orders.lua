local ADDON_NAME, GQ = ...
local L = GQ.L

GQ.Orders = GQ.Orders or {}
local Orders = GQ.Orders

-- Armor and weapon crafts. Alchemy and Enchanting appear only once an
-- order for them exists. The handle is the second one on the right rail.
Orders.PRIMARY = { "Blacksmithing", "Leatherworking", "Tailoring", "Engineering" }

local ROW_H = 28
local HEADER_H = 22

function Orders:List()
    GearQuestForeverDB = GearQuestForeverDB or {}
    GearQuestForeverDB.craftingOrders = GearQuestForeverDB.craftingOrders or {}
    return GearQuestForeverDB.craftingOrders
end

function Orders:PlayerName()
    local name, realm = UnitName("player")
    if type(name) ~= "string" or name == "" then
        return "?"
    end
    if type(realm) == "string" and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

function Orders:Count(profession)
    local n = 0
    local list = self:List()
    for i = 1, #list do
        if list[i].profession == profession then
            n = n + 1
        end
    end
    return n
end

function Orders:Professions()
    local names = {}
    local seen = {}
    for i = 1, #self.PRIMARY do
        names[#names + 1] = self.PRIMARY[i]
        seen[self.PRIMARY[i]] = true
    end
    local list = self:List()
    for i = 1, #list do
        local prof = list[i].profession
        if prof and not seen[prof] then
            seen[prof] = true
            names[#names + 1] = prof
        end
    end
    return names
end

function Orders:PreferredProfession()
    local ranks = GQ.Log and GQ.Log.PlayerProfessionRanks and GQ.Log:PlayerProfessionRanks() or {}
    local bestName, bestRank, bestOrders
    for i = 1, #self.PRIMARY do
        local name = self.PRIMARY[i]
        local rank = ranks[name] or 0
        local orders = self:Count(name)
        if rank > 0 and (not bestName or orders > bestOrders or (orders == bestOrders and rank > bestRank)) then
            bestName = name
            bestRank = rank
            bestOrders = orders
        end
    end
    if bestName then
        return bestName
    end
    for i = 1, #self.PRIMARY do
        if self:Count(self.PRIMARY[i]) > 0 then
            return self.PRIMARY[i]
        end
    end
    return self.PRIMARY[1]
end

function Orders:Find(itemId, who)
    local list = self:List()
    for i = 1, #list do
        local row = list[i]
        if row.itemId == itemId and row.who == who then
            return row, i
        end
    end
end

function Orders:Add(entry)
    local log = GQ.Log
    if not entry or not entry.itemId or not log or not log.CraftedProfession then
        return nil
    end
    local prof = log:CraftedProfession(entry)
    if not prof or prof == "" then
        return nil
    end
    local skill = log.CraftSkillNeeded and log:CraftSkillNeeded(entry) or nil
    local who = self:PlayerName()
    local existing = self:Find(entry.itemId, who)
    if existing then
        existing.skill = skill
        existing.profession = prof
        if GQ.Chat then
            GQ:Chat("|cff00ccffGearQuest|r", L["Already on your crafting orders."])
        end
        if self.page and self.page:IsShown() then
            self:Paint()
        end
        if GQ.Log and GQ.Log.UpdateOrderButton then
            GQ.Log:UpdateOrderButton()
        end
        return "duplicate"
    end
    local name = (GQ.Data and GQ.Data.ShownEntryName and GQ.Data:ShownEntryName(entry))
        or (GQ.Data and GQ.Data.GetEntryDisplayName and GQ.Data:GetEntryDisplayName(entry))
        or (GQ.Data and GQ.Data.LocaleItemName and GQ.Data:LocaleItemName(entry.itemId))
    local list = self:List()
    list[#list + 1] = {
        itemId = entry.itemId,
        entryId = entry.id,
        profession = prof,
        skill = skill,
        who = who,
        name = name,
    }
    if GQ.Chat then
        GQ:Chat("|cff00ccffGearQuest|r", L["Added to your crafting orders."])
    end
    self:ShowAddedNotice()
    self.profession = prof
    self._picked = true
    if self.page and self.page:IsShown() then
        self:Paint()
    end
    if GQ.Log and GQ.Log.UpdateOrderButton then
        GQ.Log:UpdateOrderButton()
    end
    return "added"
end

local NOTICE_IN = 0.35
local NOTICE_HOLD = 3
local NOTICE_OUT = 0.45

function Orders:EnsureNotice()
    if self.notice then
        return self.notice
    end
    local frame = CreateFrame("Frame", "GearQuestOrderNotice", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(200)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:EnableMouse(false)
    frame:Hide()
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        frame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
        frame:SetBackdropBorderColor(0.85, 0.65, 0.12, 1)
    else
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)
    end
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")
    frame.text:SetTextColor(1, 0.82, 0)
    frame:SetScript("OnUpdate", function(_, elapsed)
        Orders:TickNotice(elapsed)
    end)
    self.notice = frame
    return frame
end

function Orders:ShowNotice(text)
    local frame = self:EnsureNotice()
    frame.text:SetText(text or "")
    local width = (frame.text:GetStringWidth() or 180) + 56
    if width < 240 then
        width = 240
    end
    if width > 520 then
        width = 520
    end
    frame:SetSize(width, 52)
    frame._phase = "in"
    frame._t = 0
    frame:SetAlpha(0)
    frame:Show()
end

function Orders:ShowAddedNotice()
    self:ShowNotice(L["Added to your orders"])
end

function Orders:TickNotice(elapsed)
    local frame = self.notice
    if not frame or not frame:IsShown() then
        return
    end
    frame._t = (frame._t or 0) + (elapsed or 0)
    if frame._phase == "in" then
        local alpha = frame._t / NOTICE_IN
        if alpha >= 1 then
            frame:SetAlpha(1)
            frame._phase = "hold"
            frame._t = 0
        else
            frame:SetAlpha(alpha)
        end
    elseif frame._phase == "hold" then
        if frame._t >= NOTICE_HOLD then
            frame._phase = "out"
            frame._t = 0
        end
    else
        local alpha = 1 - (frame._t / NOTICE_OUT)
        if alpha <= 0 then
            frame:SetAlpha(1)
            frame:Hide()
        else
            frame:SetAlpha(alpha)
        end
    end
end

function Orders:Open(itemId, entryId)
    if GQ.Log and GQ.Log.OpenCraftingOrder then
        GQ.Log:OpenCraftingOrder(itemId, entryId)
    end
end

function Orders:RemoveAt(index)
    local list = self:List()
    if list[index] then
        table.remove(list, index)
        self:ShowNotice(L["Removed from your orders"])
    end
    if self.page then
        self:Paint()
    end
    if GQ.Log and GQ.Log.UpdateOrderButton then
        GQ.Log:UpdateOrderButton()
    end
end

function Orders:Ensure(frame)
    if self.page or not frame then
        return
    end
    local page = CreateFrame("Frame", "GearQuestOrdersPage", frame)
    page:SetPoint("TOPLEFT", frame.logPage, "TOPLEFT", 0, 0)
    page:SetPoint("BOTTOMRIGHT", frame.logPage, "BOTTOMRIGHT", 0, 42)
    page:Hide()
    self.page = page

    -- The scene stays visible. This shade is what the hunt list uses, so the
    -- white lines on this page can be read.
    local shade = page:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetTexture("Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-ListShade.png")
    page.shade = shade

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 8, -8)
    title:SetText(L["Account crafting orders"])
    title:SetTextColor(1, 0.82, 0)
    page.title = title

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetPoint("RIGHT", page, "RIGHT", -12, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText(L["Open a crafted hunt and press Add order. Alt-click a crafted hunt does the same."])
    hint:SetTextColor(0.9, 0.85, 0.7)
    page.hint = hint

    page.profButtons = {}
    page.rows = {}

    local scroll = CreateFrame("ScrollFrame", "GearQuestOrdersScroll", page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -96)
    scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 8)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 1)
    scroll:SetScrollChild(child)
    page.scroll = scroll
    page.child = child

    local empty = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    empty:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -8)
    empty:SetPoint("RIGHT", child, "RIGHT", -8, 0)
    empty:SetJustifyH("LEFT")
    empty:SetWordWrap(true)
    empty:SetText(L["No orders for this profession yet."])
    empty:SetTextColor(0.8, 0.8, 0.8)
    empty:Hide()
    page.empty = empty
end

function Orders:ApplyPage(frame, pageName)
    self:Ensure(frame)
    if not self.page then
        return
    end
    if pageName == "orders" then
        self.page:Show()
        self:Refresh()
    else
        self.page:Hide()
    end
end

function Orders:Refresh()
    local who = self:PlayerName()
    if self._autoWho ~= who then
        self._autoWho = who
        self._picked = nil
        self.profession = self:PreferredProfession()
    end
    self.profession = self.profession or self:PreferredProfession()
    self:Paint()
end

function Orders:SelectProfession(name)
    self.profession = name
    self._picked = true
    self:Paint()
end

local function ItemIcon(itemId)
    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemId)
        if icon then
            return icon
        end
    end
    if GetItemIcon then
        return GetItemIcon(itemId)
    end
end

local function QualityColor(itemId)
    local quality = GQ.Data and GQ.Data.GetItemQualityForDisplay and GQ.Data:GetItemQualityForDisplay(itemId)
    local c = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c then
        return c.r, c.g, c.b
    end
    return nil
end

function Orders:EnsureRow(index)
    local row = self.page.rows[index]
    if row then
        return row
    end
    local parent = self.page.child
    row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 16, 0)
    row.border = row:CreateTexture(nil, "OVERLAY")
    row.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    row.border:SetAllPoints(row.icon)
    row.border:Hide()
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -116, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetTextColor(1, 1, 1)
    row.drop = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.drop:SetSize(108, 20)
    row.drop:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.drop:SetText(L["Remove order"])
    row.drop:SetScript("OnClick", function(self)
        if self.orderIndex then
            Orders:RemoveAt(self.orderIndex)
        end
    end)
    row:EnableMouse(true)
    row:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or not self.itemId then
            return
        end
        Orders:Open(self.itemId, self.entryId)
    end)
    row:SetScript("OnEnter", function(self)
        if not self.itemId then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(self.itemId)
        else
            GameTooltip:SetHyperlink("item:" .. self.itemId)
        end
        GameTooltip:AddLine(L["Opens this hunt on the log."], 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    self.page.rows[index] = row
    return row
end

function Orders:Paint()
    local page = self.page
    if not page then
        return
    end
    local names = self:Professions()
    local selected = self.profession
    local x = 8
    local rowY = -66
    local limit = page:GetWidth()
    if not limit or limit < 200 then
        limit = 700
    end
    for i = 1, #names do
        local name = names[i]
        local btn = page.profButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
            btn:SetHeight(22)
            btn:SetScript("OnClick", function(self)
                Orders:SelectProfession(self.profession)
            end)
            page.profButtons[i] = btn
        end
        btn.profession = name
        local shown = (GQ.TX and GQ.TX(name)) or (L[name] or name)
        btn:SetText(shown .. " (" .. self:Count(name) .. ")")
        local label = btn:GetFontString()
        local width = (label and label:GetStringWidth() or 80) + 20
        if width < 90 then
            width = 90
        end
        btn:SetWidth(width)
        if x > 8 and (x + width) > (limit - 8) then
            x = 8
            rowY = rowY - 26
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", page, "TOPLEFT", x, rowY)
        btn:Show()
        if label then
            if name == selected then
                label:SetTextColor(1, 0.82, 0)
            else
                label:SetTextColor(1, 1, 1)
            end
        end
        x = x + width + 6
    end
    for i = #names + 1, #page.profButtons do
        page.profButtons[i]:Hide()
    end
    page.scroll:ClearAllPoints()
    page.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 4, rowY - 30)
    page.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 8)

    local list = self:List()
    local grouped = {}
    local order = {}
    for i = 1, #list do
        local row = list[i]
        if row.profession == selected then
            local who = row.who or "?"
            if not grouped[who] then
                grouped[who] = {}
                order[#order + 1] = who
            end
            grouped[who][#grouped[who] + 1] = { row = row, index = i }
        end
    end

    local y = 0
    local used = 0
    local child = page.child
    local width = page.scroll:GetWidth()
    if not width or width < 80 then
        width = 360
    end
    child:SetWidth(width)
    if #order == 0 then
        page.empty:Show()
        page.empty:ClearAllPoints()
        page.empty:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -8)
        y = 40
    else
        page.empty:Hide()
        for g = 1, #order do
            local who = order[g]
            used = used + 1
            local header = self:EnsureRow(used)
            header:Show()
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            header:SetPoint("RIGHT", child, "RIGHT", 0, 0)
            header:SetHeight(HEADER_H)
            header.icon:Hide()
            header.border:Hide()
            header.drop:Hide()
            header.itemId = nil
            header.entryId = nil
            header.text:ClearAllPoints()
            header.text:SetPoint("LEFT", header, "LEFT", 4, 0)
            header.text:SetPoint("RIGHT", header, "RIGHT", -8, 0)
            header.text:SetText(string.format(L["Asked by %s"], who))
            header.text:SetTextColor(1, 0.82, 0)
            y = y + HEADER_H
            local items = grouped[who]
            for n = 1, #items do
                local packed = items[n]
                local data = packed.row
                used = used + 1
                local row = self:EnsureRow(used)
                row:Show()
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
                row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
                row:SetHeight(ROW_H)
                row.itemId = data.itemId
                row.entryId = data.entryId
                row.icon:Show()
                local icon = ItemIcon(data.itemId)
                row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                local r, g, b = QualityColor(data.itemId)
                if r then
                    row.border:SetVertexColor(r, g, b)
                    row.border:Show()
                else
                    row.border:Hide()
                end
                local itemName = data.name or ("Item " .. tostring(data.itemId))
                if GQ.Data and GQ.Data.LocaleItemName then
                    local localized = GQ.Data:LocaleItemName(data.itemId)
                    if localized and localized ~= "" then
                        itemName = localized
                    end
                end
                local skill = data.skill
                local line = itemName
                if type(skill) == "number" and skill > 1 then
                    line = itemName .. "  |cffb0b0b0" .. string.format(L["Skill %d"], skill) .. "|r"
                end
                row.text:ClearAllPoints()
                row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -116, 0)
                row.text:SetText(line)
                local nr, ng, nb = QualityColor(data.itemId)
                if nr then
                    row.text:SetTextColor(nr, ng, nb)
                else
                    row.text:SetTextColor(1, 0.82, 0)
                end
                row.drop:Show()
                row.drop.orderIndex = packed.index
                y = y + ROW_H
            end
        end
    end
    for i = used + 1, #page.rows do
        page.rows[i]:Hide()
    end
    child:SetHeight(math.max(y + 8, 1))
end
