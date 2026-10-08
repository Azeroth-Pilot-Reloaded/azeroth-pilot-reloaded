-- Small APR-owned controls shared by the library, settings, diagnostics and performance windows.
-- Windows are lazy, clamped to screen, keyboard-dismissable and registered with the selected skin.

APR.UI = {}
local UI = APR.UI

function UI:Label(parent, text, size, role)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    APR:RegisterFontString(label, "general", { role = role or "base", sizeDelta = (size or 12) - 12 })
    return label
end

function UI:Panel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    APR:RegisterSkinTarget(frame, "panel", { themeSurface = true, preserveContent = true })
    return frame
end

function UI:Button(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 130, 30)
    local label = self:Label(button, text, 12)
    label:SetPoint("LEFT", 10, 0)
    label:SetPoint("RIGHT", -10, 0)
    label:SetJustifyH("CENTER")
    button:SetFontString(label)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() and self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("accent"))) end
    end)
    button:SetScript("OnLeave", function(self)
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("border"))) end
    end)
    button:SetScript("OnEnable", function() label:SetAlpha(1) end)
    button:SetScript("OnDisable", function() label:SetAlpha(0.4) end)
    APR:RegisterSkinTarget(button, "button", { themeSurface = true })
    return button
end

function UI:SearchBox(parent, width, placeholder, changed)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width or 280, 32)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlight)
    edit:SetTextInsets(10, 10, 0, 0)
    edit:SetMaxLetters(160)
    edit.placeholder = self:Label(edit, placeholder, 12, "muted")
    edit.placeholder:SetPoint("LEFT", 10, 0)
    edit.placeholder:SetPoint("RIGHT", -10, 0)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        self.placeholder:SetShown(self:GetText() == "")
        changed(self:GetText())
    end)
    APR:RegisterSkinTarget(edit, "editbox", { themeSurface = true })
    return edit
end

function UI:Tooltip(control, title, description)
    control:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        APR:SetTooltipText(GameTooltip, title, "general", "accent")
        if description then APR:AddTooltipLine(GameTooltip, description, "general", "base", true) end
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI:Scroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    if scroll.ScrollBar then APR:RegisterSkinTarget(scroll.ScrollBar, "scrollbar") end
    return scroll
end

-- FontStrings expose measured text height on both clients; EditBoxes do not.
function UI:CopyBox(parent)
    local scroll = self:Scroll(parent)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(600)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local measure = scroll:CreateFontString(nil, "OVERLAY")
    measure:SetFontObject(ChatFontNormal)
    measure:SetWordWrap(true)
    measure:Hide()
    local function resize()
        local width = math.max(1, scroll:GetWidth())
        edit:SetWidth(width)
        measure:SetWidth(width)
        measure:SetText(edit:GetText() or "")
        edit:SetHeight(math.max(30, measure:GetStringHeight() + 20))
    end
    edit:SetScript("OnTextChanged", resize)
    scroll:HookScript("OnSizeChanged", resize)
    scroll:SetScrollChild(edit)
    return scroll, edit
end

function UI:ShowTextReport(title, report)
    local frame = self.reportWindow
    if not frame then
        frame = self:Window("APRTextReport", title, 900, 650)
        self.reportWindow = frame
        local scroll, edit = self:CopyBox(frame.content)
        frame.edit = edit
        scroll:SetPoint("TOPLEFT")
        scroll:SetPoint("BOTTOMRIGHT", -26, 45)
        local copy = self:Button(frame.content, APR:LocalizeUI("EXPORT"), 150, function()
            edit:SetFocus(); edit:HighlightText()
        end)
        copy:SetPoint("BOTTOMRIGHT")
        self:Tooltip(copy, APR:LocalizeUI("COPY_HINT"))
    end
    frame.header.Text:SetText(title)
    frame.edit:SetText(report)
    frame.edit:SetCursorPosition(0)
    frame.edit:ClearFocus()
    frame:Show()
end

-- A scrollable menu keeps expansion/category pickers usable with large imported catalogs.
function UI:Select(parent, width, changed)
    local button = self:Button(parent, "", width)
    button:SetScript("OnClick", function()
        if button.menu and button.menu:IsShown() then button.menu:Hide(); return end
        if not button.menu then
            local menu = self:Panel(button)
            button.menu = menu
            menu:SetFrameStrata("TOOLTIP")
            menu:SetClampedToScreen(true)
            menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
            menu:SetSize(width, 244)
            local scroll = self:Scroll(menu)
            scroll:SetPoint("TOPLEFT", 4, -4)
            scroll:SetPoint("BOTTOMRIGHT", -26, 4)
            menu.list = APR.VirtualList:New(scroll, function(owner)
                return self:Button(owner, "", width - 32, function(row)
                    button.value = row.item.value
                    button:SetText(row.item.label)
                    menu:Hide()
                    changed(row.item.value)
                end)
            end, function(row, item) row:SetText(item.label) end, 30)
            button:HookScript("OnHide", function() menu:Hide() end)
        end
        button.menu:Show()
        button.menu.list:SetItems(button.options or {})
    end)
    function button:SetOptions(options, value)
        self.options, self.value = options, value
        for _, option in ipairs(options) do
            if option.value == value then self:SetText(option.label); break end
        end
    end
    return button
end

function UI:Window(name, title, width, height)
    local frame = self:Panel(UIParent)
    _G[name] = frame
    frame:SetSize(math.min(width, UIParent:GetWidth() - 40), math.min(height, UIParent:GetHeight() - 60))
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(math.min(680, UIParent:GetWidth() - 40), math.min(430, UIParent:GetHeight() - 60))
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 16, -8)
    frame.header:SetPoint("TOPRIGHT", -52, -8)
    frame.header:SetHeight(42)
    frame.header:EnableMouse(true)
    frame.header.Text = self:Label(frame.header, title, 20, "accent")
    frame.header.Text:SetPoint("LEFT")
    APR:SetupHeaderDrag(frame.header, frame, function() return not InCombatLockdown() end)
    frame.close = self:Button(frame, "×", 30, function() frame:Hide() end)
    frame.close:SetPoint("TOPRIGHT", -12, -12)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 16, -58)
    frame.content:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.resize = self:Button(frame, "◢", 22, function() end)
    frame.resize:SetHeight(22)
    frame.resize:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.resize:SetScript("OnMouseDown", function() if not InCombatLockdown() then frame:StartSizing("BOTTOMRIGHT") end end)
    frame.resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    frame:SetScript("OnHide", function(self) self:StopMovingOrSizing(); GameTooltip:Hide() end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
    frame:Hide()
    return frame
end
