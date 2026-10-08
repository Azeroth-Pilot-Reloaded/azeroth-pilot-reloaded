-- Small APR-owned controls shared by the library, settings, diagnostics and performance windows.
-- Windows are lazy, clamped to screen, keyboard-dismissable and registered with the selected skin.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.UI = {}
local UI = APR.UI

function UI:Label(parent, text, size, role)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    APR:RegisterFontString(label, "general", { role = role or "base", sizeDelta = (size or 12) - 12 })
    return label
end

function UI:Panel(parent, kind)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    APR:RegisterSkinTarget(frame, kind or "panel", { themeSurface = true, preserveContent = true })
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
        if APR:GetSkinProviderName() then return end
        if self:IsEnabled() and self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("accent"))) end
    end)
    button:SetScript("OnLeave", function(self)
        if APR:GetSkinProviderName() then return end
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
    APR:RegisterFontString(edit, "general", {role = "base"})
    return edit
end

function UI:Tooltip(control, title, description)
    control:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Resolve recycled rows at hover time, including descriptions that return nil.
        local heading, body = title, description
        if type(heading) == "function" then heading = heading(self) end
        if type(body) == "function" then body = body(self) end
        APR:SetTooltipText(GameTooltip, heading, "general", "accent")
        if body then APR:AddTooltipLine(GameTooltip, body, "general", "base", true) end
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
    -- The measuring region and selectable text must use the same font and size.
    APR:RegisterFontString(edit, "general", {role = "base"})
    APR:RegisterFontString(measure, "general", {role = "base", onApplied = resize})
    return scroll, edit
end

function UI:ShowTextReport(title, report, owner)
    local frame = self.reportWindow
    if not frame then
        frame = self:Window("APRTextReport", title, 900, 650)
        self.reportWindow = frame
        local scroll, edit = self:CopyBox(frame.content)
        frame.edit = edit
        scroll:SetPoint("TOPLEFT")
        scroll:SetPoint("BOTTOMRIGHT", -26, 45)
        local copy = self:Button(frame.content, L["STATUS_EXPORT"], 150, function()
            edit:SetFocus(); edit:HighlightText()
        end)
        copy:SetPoint("BOTTOMRIGHT")
        self:Tooltip(copy, L["COPY_HELPER"])
    end
    frame.reportOwner = owner
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
        if UI.activeMenu then UI.activeMenu:Hide() end
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
        UI.activeMenu = button.menu
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
    local frame = self:Panel(UIParent, "window")
    _G[name] = frame
    local profile = APR:GetSettingsProfile()
    profile.uiWindows = profile.uiWindows or {}
    profile.uiWindows[name] = profile.uiWindows[name] or {}
    local position = profile.uiWindows[name]
    local window = LibStub("LibWindow-1.1")
    frame:SetSize(math.min(tonumber(position.width) or width, UIParent:GetWidth() - 40),
        math.min(tonumber(position.height) or height, UIParent:GetHeight() - 60))
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(math.min(680, UIParent:GetWidth() - 40), math.min(430, UIParent:GetHeight() - 60))
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    window.RegisterConfig(frame, position)
    if position.point then window.RestorePosition(frame) end
    local function saveGeometry()
        window.SavePosition(frame)
        position.width, position.height = frame:GetSize()
    end
    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 16, -8)
    frame.header:SetPoint("TOPRIGHT", -52, -8)
    frame.header:SetHeight(42)
    frame.header:EnableMouse(true)
    frame.header.Text = self:Label(frame.header, title, 20, "accent")
    frame.header.Text:SetPoint("LEFT")
    APR:SetupHeaderDrag(frame.header, frame, function() return not InCombatLockdown() end, saveGeometry)
    frame.close = self:Button(frame, "×", 30, function() frame:Hide() end)
    frame.close:SetPoint("TOPRIGHT", -12, -12)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 16, -58)
    frame.content:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.resize = self:Button(frame, "◢", 22, function() end)
    frame.resize:SetHeight(22)
    frame.resize:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.resize:SetScript("OnMouseDown", function() if not InCombatLockdown() then frame:StartSizing("BOTTOMRIGHT") end end)
    frame.resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); saveGeometry() end)
    frame:SetScript("OnHide", function(self) self:StopMovingOrSizing(); saveGeometry(); GameTooltip:Hide() end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
    frame:Hide()
    return frame
end
