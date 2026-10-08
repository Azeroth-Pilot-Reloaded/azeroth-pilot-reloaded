-- Shared choice/confirmation dialog for route browsing. Callers own options, restrictions and actions.
-- Text determines row heights; a bounded viewport keeps every choice reachable on small screens.
local UI = APR.UI

local function CreateSelectionDialog()
    local frame = UI:Panel(UIParent, "window", "library")
    _G.APRSelectionPopup = frame
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:EnableMouse(true)
    frame.title = UI:Label(frame.header, "", 18, "accent")
    frame.title:SetPoint("TOPLEFT")
    frame.title:SetWordWrap(true)
    APR:SetupHeaderDrag(frame.header, frame, function() return not InCombatLockdown() end)
    frame.close = UI:IconButton(frame.header, "close", 30, function() frame:Hide() end)
    frame.close:SetPoint("TOPRIGHT", 0, 4)
    UI:Tooltip(frame.close, CLOSE)

    frame.description = UI:Label(frame, "", 12)
    frame.description:SetWordWrap(true)
    frame.body = UI:Panel(frame, "borderedPanel", "stone")
    frame.scroll = UI:Scroll(frame.body)
    frame.scroll:SetPoint("TOPLEFT", 8, -8)
    frame.measure = UI:Label(frame, "", 12)
    frame.measure:SetWordWrap(true)
    frame.measure:Hide()
    frame.cancelButton = UI:Button(frame, CANCEL, 120, function() frame:Hide() end)
    frame.cancelButton:SetPoint("BOTTOMRIGHT", -16, 14)
    frame.acceptButton = UI:Button(frame, ACCEPT, 120, function() frame:Accept() end)
    frame.acceptButton:SetPoint("RIGHT", frame.cancelButton, "LEFT", -10, 0)
    UI:SetButtonActive(frame.acceptButton, true)
    frame.acceptButton:Hide()

    function frame:Accept()
        local callback = self.onAccept
        self.onAccept, self.onCancel = nil, nil
        self:Hide()
        if callback then callback() end
    end

    function frame:Choose(option)
        if not option or option.enabled == false then return end
        local callback = self.onSelect
        -- Clear the cancellation handler before hiding, so a choice cannot also count as a cancellation.
        self.onSelect, self.onCancel = nil, nil
        self:Hide()
        if callback then callback(option) end
    end

    frame.list = APR.VirtualList:New(frame.scroll, function(parent)
        local row = CreateFrame("Frame", nil, parent)
        row.button = UI:Button(row, "", 1, function() frame:Choose(row.item.option) end)
        -- A locked expansion still explains its level requirement on hover.
        row.button:SetMotionScriptsWhileDisabled(true)
        row.button:SetPoint("TOPLEFT")
        row.button:SetPoint("BOTTOMRIGHT", 0, 6)
        row.button:GetFontString():SetJustifyH("LEFT")
        row.button:GetFontString():SetWordWrap(true)
        UI:Tooltip(row.button, function() return row.item and row.item.option.label end,
            function() return row.item and row.item.option.tooltip end)
        function row:onRecycle()
            if GameTooltip:GetOwner() == self.button then GameTooltip:Hide() end
        end
        return row
    end, function(row, item)
        row:onRecycle()
        row.button:SetText(item.option.label)
        row.button:SetEnabled(item.option.enabled ~= false)
    end, function(item) return item.height end)

    function frame:Layout()
        if not self.options or self.layingOut then return end
        self.layingOut = true
        local width = math.min(self.confirming and 440 or 560, UIParent:GetWidth() - 40)
        local innerWidth = width - 32
        self:SetWidth(width)
        self.header:SetPoint("TOPLEFT", 16, -16)
        self.header:SetWidth(innerWidth)
        self.title:SetWidth(innerWidth - 40)
        local headerHeight = math.max(30, self.title:GetStringHeight())
        self.header:SetHeight(headerHeight)
        self.description:SetWidth(innerWidth)
        local descriptionHeight = self.description:GetText() ~= "" and self.description:GetStringHeight() or 0
        self.description:SetShown(descriptionHeight > 0)
        self.description:SetPoint("TOPLEFT", 16, -(16 + headerHeight + 10))
        self.acceptButton:SetShown(self.confirming)
        self.body:SetShown(not self.confirming)
        if self.confirming then
            local buttonWidth = (innerWidth - 10) / 2
            self.acceptButton:SetWidth(buttonWidth)
            self.cancelButton:SetWidth(buttonWidth)
            local buttonHeight = math.max(30, self.acceptButton:GetFontString():GetStringHeight() + 12,
                self.cancelButton:GetFontString():GetStringHeight() + 12)
            self.acceptButton:SetHeight(buttonHeight)
            self.cancelButton:SetHeight(buttonHeight)
            self:SetHeight(16 + headerHeight + 24 + buttonHeight + 14)
            self.layingOut = nil
            return
        end
        self.cancelButton:SetSize(120, 30)
        local bodyTop = 16 + headerHeight + (descriptionHeight > 0 and 10 + descriptionHeight or 0) + 16

        self.measure:SetWidth(innerWidth - 54)
        local items, totalHeight = {}, 0
        for _, option in ipairs(self.options) do
            self.measure:SetText(option.label)
            local height = math.max(34, self.measure:GetStringHeight() + 16) + 6
            items[#items + 1] = {option = option, height = height}
            totalHeight = totalHeight + height
        end
        local bodyHeight = math.min(math.max(56, totalHeight + 16), math.max(56, UIParent:GetHeight() - bodyTop - 96))
        self.body:SetPoint("TOPLEFT", 16, -bodyTop)
        self.body:SetSize(innerWidth, bodyHeight)
        self.scroll:SetSize(innerWidth - 34, bodyHeight - 16)
        self:SetHeight(bodyTop + bodyHeight + 58)
        self.list:SetItems(items)
        self.layingOut = nil
    end

    -- Escape, the cross and Cancel share the same lifecycle, including the delve prompt's callback.
    frame:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
        GameTooltip:Hide()
        local callback = self.onCancel
        self.onSelect, self.onAccept, self.onCancel, self.options = nil, nil, nil, nil
        self.list:SetItems({})
        if callback then callback() end
    end)
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    frame:RegisterEvent("UI_SCALE_CHANGED")
    frame:SetScript("OnEvent", function(self) if self:IsShown() then self:Layout() end end)
    for _, font in ipairs({frame.title, frame.description, frame.measure}) do
        local title = font == frame.title
        APR:RegisterFontString(font, "general", {role = title and "accent" or "base", sizeDelta = title and 6 or 0, themeAccent = true,
            onApplied = function() frame:Layout() end})
    end
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "APRSelectionPopup")
    frame:Hide()
    return frame
end

local function ShowDialog(settings)
    if UI.activeMenu then UI.activeMenu:Hide() end
    local frame = UI.selectionDialog
    if not frame then frame = CreateSelectionDialog(); UI.selectionDialog = frame end
    -- Replacing an open prompt resolves its previous cancellation callback first.
    frame:Hide()
    frame.title:SetText(settings.title or "APR")
    frame.description:SetText(settings.description or "")
    frame.confirming = settings.confirmation == true
    frame.options, frame.onSelect = settings.options or {}, settings.onSelect
    frame.onAccept, frame.onCancel = settings.onAccept, settings.onCancel
    frame:Layout()
    frame:ClearAllPoints()
    local owner = settings.owner
    frame:SetPoint("CENTER", owner and owner:IsShown() and owner or UIParent, "CENTER")
    frame:Show()
    frame.list:RefreshVisible(true)
    return frame
end

function UI:ShowSelectionDialog(title, description, options, onSelect, onCancel, owner)
    return ShowDialog({title = title, description = description, options = options,
        onSelect = onSelect, onCancel = onCancel, owner = owner})
end

function UI:ShowConfirmationDialog(text, onAccept, onCancel, owner)
    return ShowDialog({title = text, onAccept = onAccept, onCancel = onCancel, owner = owner, confirmation = true})
end
