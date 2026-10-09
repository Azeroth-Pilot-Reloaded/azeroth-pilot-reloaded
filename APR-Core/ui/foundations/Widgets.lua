-- Small APR-owned controls shared by the library, settings, diagnostics and performance windows.
-- Windows are lazy, clamped to screen, keyboard-dismissable and registered with the selected skin.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.UI = {}
local UI = APR.UI

-- MDI exports share the Route Recorder's icon language; SVG sources/licenses are in assets/ui/mdi.
local iconRoot = "Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\"

function UI:SetIcon(texture, name)
    texture:SetTexture(iconRoot .. name .. ".tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "TRILINEAR")
    texture:SetTexCoord(0, 1, 0, 1)
    -- Fractional UI scales must not snap the pictogram's edges to different pixels.
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    if name == "logo" then texture:SetVertexColor(1, 1, 1, 1)
    else APR:RegisterThemeRegion(texture, "icon", 1, true) end
end

function UI:Icon(parent, name, size)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetSize(size or 18, size or 18)
    self:SetIcon(texture, name)
    return texture
end

function UI:Label(parent, text, size, role)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    APR:RegisterFontString(label, "general", { role = role or "base", sizeDelta = (size or 12) - 12, themeAccent = true })
    return label
end

function UI:Panel(parent, kind, surface)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    APR:RegisterSkinTarget(frame, kind or "panel", { themeSurface = true, preserveContent = true, surface = surface })
    return frame
end

-- Keep the shadow above the panel and below the button, in a child that skins cannot strip.
-- Short, tapered bands below the lower edge suggest depth without outlining the whole button.
function UI:ElevateButton(button)
    if button.elevation then return end
    button:SetFrameLevel(math.max(button:GetFrameLevel(), button:GetParent():GetFrameLevel() + 2))
    local shadow = CreateFrame("Frame", nil, button)
    button.elevation = shadow
    shadow:SetFrameLevel(button:GetFrameLevel() - 1)
    shadow:SetAllPoints(button)
    shadow:EnableMouse(false)
    for index, opacity in ipairs({0.12, 0.065, 0.025}) do
        local inset = 4 + index * 2
        local layer = shadow:CreateTexture(nil, "BACKGROUND")
        layer:SetPoint("TOPLEFT", shadow, "BOTTOMLEFT", inset, 1 - index)
        layer:SetPoint("TOPRIGHT", shadow, "BOTTOMRIGHT", -inset, 1 - index)
        layer:SetHeight(1)
        layer:SetColorTexture(0.025, 0.015, 0.01, opacity)
    end
    local hovered, pressed = false, false
    local function update()
        shadow:SetAlpha(not button:IsEnabled() and 0.15 or pressed and 0.25 or hovered and 0.85 or 0.65)
    end
    button:HookScript("OnEnter", function() hovered = true; update() end)
    button:HookScript("OnLeave", function() hovered, pressed = false, false; update() end)
    button:HookScript("OnMouseDown", function(_, key) if key == "LeftButton" then pressed = true; update() end end)
    button:HookScript("OnMouseUp", function() pressed = false; update() end)
    button:HookScript("OnHide", function() hovered, pressed = false, false; update() end)
    button:HookScript("OnDisable", function() hovered, pressed = false, false; update() end)
    button:HookScript("OnEnable", update)
    update()
end

function UI:Button(parent, text, width, callback, style)
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
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor(self.active and "accent" or "border"))) end
    end)
    button:SetScript("OnEnable", function() label:SetAlpha(1) end)
    button:SetScript("OnDisable", function() label:SetAlpha(0.4) end)
    if style == "flat" then
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        APR:RegisterThemeRegion(highlight, "accent", 0.12)
    end
    if style == "raised" then self:ElevateButton(button) end
    APR:RegisterSkinTarget(button, style == "flat" and "flatButton" or "button", { themeSurface = style ~= "flat" })
    return button
end

function UI:SetButtonActive(button, active)
    button.active = active == true
    APR:SetFontStringRole(button:GetFontString(), active and "accent" or "base")
    if not APR:GetSkinProviderName() then
        button:SetBackdropBorderColor(unpack(APR:GetThemeColor(active and "accent" or "border")))
    end
end

-- A child frame keeps functional icons intact when an external skin strips button textures.
function UI:ButtonIcon(button, name, size, centered)
    local host = CreateFrame("Frame", nil, button)
    host:SetSize(size or 18, size or 18)
    if centered then host:SetPoint("CENTER") else host:SetPoint("LEFT", 12, 0) end
    host:EnableMouse(false)
    button.icon = self:Icon(host, name, size)
    button.icon:SetAllPoints()
    button:HookScript("OnEnable", function() host:SetAlpha(1) end)
    button:HookScript("OnDisable", function() host:SetAlpha(0.3) end)
    if not centered then
        local label = button:GetFontString()
        label:ClearAllPoints()
        label:SetPoint("LEFT", (size or 18) + 20, 0)
        label:SetPoint("RIGHT", -10, 0)
    end
    return button.icon
end

function UI:IconButton(parent, icon, size, callback, style)
    local button = self:Button(parent, "", size, callback, style or "flat")
    button:SetSize(size, size)
    self:ButtonIcon(button, icon, math.min(icon == "favorite" and 16 or 20, size - 4), true)
    return button
end

function UI:Section(parent, title, surface)
    local panel = self:Panel(parent, "borderedPanel", surface or "inset")
    panel.title = self:Label(panel, title, 14, "accent")
    panel.title:SetPoint("TOPLEFT", 12, -10)
    panel.title:SetPoint("TOPRIGHT", -12, -10)
    panel.title:SetHeight(22)
    panel.title:SetWordWrap(false)
    return panel
end

-- Column labels share one header band; the sort indicator is a texture, not a font glyph.
function UI:ColumnHeader(parent, text, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    local label = self:Label(button, text, 11)
    label:SetPoint("LEFT", 4, 0)
    label:SetPoint("RIGHT", -22, 0)
    label:SetWordWrap(false)
    button:SetFontString(label)
    button:SetScript("OnClick", callback)
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    APR:RegisterThemeRegion(hover, "accent", 0.1)
    APR:RegisterSkinTarget(button, "flatButton")
    self:ButtonIcon(button, "up", 16, true)
    button.icon:GetParent():ClearAllPoints()
    button.icon:GetParent():SetPoint("RIGHT", -3, 0)
    return button
end

function UI:SearchBox(parent, width, placeholder, changed)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width or 280, 32)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlight)
    edit:SetTextInsets(30, 10, 0, 0)
    edit:SetMaxLetters(160)
    edit.placeholder = self:Label(edit, placeholder, 12, "muted")
    edit.placeholder:SetPoint("LEFT", 30, 0)
    edit.placeholder:SetPoint("RIGHT", -10, 0)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        self.placeholder:SetShown(self:GetText() == "")
        changed(self:GetText())
    end)
    APR:RegisterSkinTarget(edit, "editbox", { themeSurface = true })
    -- EUI re-fades direct input textures when other windows refresh; keep the functional icon in a child.
    local iconHost = CreateFrame("Frame", nil, edit)
    iconHost:SetAllPoints(edit)
    iconHost:EnableMouse(false)
    edit.searchIcon = self:Icon(iconHost, "search", 16)
    edit.searchIcon:SetPoint("LEFT", 9, 0)
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

-- Keep Blizzard's scroll behavior and hit areas, replacing only its framed arrow artwork.
function UI:StyleScrollBar(bar)
    for _, definition in ipairs({{bar.ScrollUpButton, "up"}, {bar.ScrollDownButton, "down"}}) do
        local button, name = unpack(definition)
        if button then
            local path = iconRoot .. name .. ".tga"
            button:SetNormalTexture(path)
            button:SetPushedTexture(path)
            button:SetDisabledTexture(path)
            button:SetHighlightTexture(path, "ADD")
            for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
                local texture = button["Get" .. state .. "Texture"](button)
                self:SetIcon(texture, name)
                texture:ClearAllPoints()
                texture:SetPoint("CENTER", 0, state == "Pushed" and -1 or 0)
                texture:SetSize(16, 16)
                texture:SetAlpha(state == "Disabled" and 0.25 or state == "Highlight" and 0.35 or 1)
            end
        end
    end
    local thumb = bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        thumb:SetVertexColor(unpack(APR:GetThemeColor("border")))
        thumb:SetSize(6, 24)
    end
end

function UI:Scroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    if scroll.ScrollBar then APR:RegisterSkinTarget(scroll.ScrollBar, "scrollbar", { compact = true }) end
    return scroll
end

-- FontStrings expose measured text height on both clients; EditBoxes do not.
function UI:CopyBox(parent)
    local scroll = self:Scroll(parent)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:EnableMouse(true)
    edit:SetAutoFocus(false)
    edit:SetAltArrowKeyMode(false)
    edit:SetMaxLetters(0)
    edit:SetFontObject(ChatFontNormal)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    edit:SetWidth(600)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local measure = scroll:CreateFontString(nil, "OVERLAY")
    measure:SetFontObject(ChatFontNormal)
    measure:SetWordWrap(true)
    measure:Hide()
    local function updateHitRect()
        local offset = scroll:GetVerticalScroll()
        -- Long edit boxes must not intercept clicks on the header or footer outside the viewport.
        edit:SetHitRectInsets(0, 0, offset, math.max(0, edit:GetHeight() - offset - scroll:GetHeight()))
    end
    local function resize()
        local width = math.max(1, scroll:GetWidth())
        edit:SetWidth(width)
        measure:SetWidth(width)
        measure:SetText(edit:GetText() or "")
        edit:SetHeight(math.max(30, scroll:GetHeight(), measure:GetStringHeight() + 20))
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), math.max(0, edit:GetHeight() - scroll:GetHeight())))
        updateHitRect()
    end
    edit:SetScript("OnTextChanged", resize)
    edit:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local top, offset = -y, scroll:GetVerticalScroll()
        if top < offset then offset = top
        elseif top + height > offset + scroll:GetHeight() then offset = top + height - scroll:GetHeight() end
        scroll:SetVerticalScroll(math.max(0, math.min(offset, edit:GetHeight() - scroll:GetHeight())))
    end)
    scroll:HookScript("OnSizeChanged", resize)
    scroll:HookScript("OnVerticalScroll", updateHitRect)
    scroll:HookScript("OnScrollRangeChanged", updateHitRect)
    scroll:SetScrollChild(edit)
    -- The measuring region and selectable text must use the same font and size.
    APR:RegisterFontString(edit, "general", {role = "base"})
    APR:RegisterFontString(measure, "general", {role = "base", onApplied = resize})
    return scroll, edit
end

function UI:FormatCodeBlock(text, language)
    -- A diagnostic may itself contain backticks; keep the complete payload inside one code block.
    local fence = "```"
    while text:find(fence, 1, true) do fence = fence .. "`" end
    return fence .. (language or "") .. "\n" .. text .. "\n" .. fence
end

function UI:ShowTextReport(title, report, owner, language)
    local frame = self.reportWindow
    if not frame then
        frame = self:Window("APRTextReport", title, 900, 650)
        self.reportWindow = frame
        local editor = self:Panel(frame.content, "borderedPanel", "inset")
        editor:SetPoint("TOPLEFT")
        editor:SetPoint("BOTTOMRIGHT", 0, 45)
        local scroll, edit = self:CopyBox(editor)
        frame.edit, frame.scroll = edit, scroll
        scroll:SetPoint("TOPLEFT", 12, -12)
        scroll:SetPoint("BOTTOMRIGHT", -32, 12)
        local copy = self:Button(frame.content, L["STATUS_EXPORT"], 150, function()
            edit:SetFocus(); edit:HighlightText()
        end)
        copy:SetPoint("BOTTOMRIGHT")
        self:Tooltip(copy, L["COPY_HELPER"])
        frame:HookScript("OnHide", function() edit:ClearFocus() end)
    end
    frame.reportOwner = owner
    frame.header.Text:SetText(title)
    if language then report = self:FormatCodeBlock(report, language) end
    frame.edit:SetText(report)
    frame.edit:SetCursorPosition(0)
    frame:Show()
    frame:Raise()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
    frame.scroll:SetVerticalScroll(0)
end

-- A scrollable menu keeps expansion/category pickers usable with large imported catalogs.
function UI:Select(parent, width, changed)
    local button = self:Button(parent, "", width)
    button:GetFontString():SetPoint("RIGHT", -30, 0)
    button.arrow = self:ButtonIcon(button, "down", 20, true)
    button.arrow:GetParent():ClearAllPoints()
    button.arrow:GetParent():SetPoint("RIGHT", -6, 0)
    button:SetScript("OnClick", function()
        if button.menu and button.menu:IsShown() then button.menu:Hide(); return end
        if UI.activeMenu then UI.activeMenu:Hide() end
        if not button.menu then
            local menu = self:Panel(button)
            button.menu = menu
            menu:SetFrameStrata("FULLSCREEN_DIALOG")
            menu:SetClampedToScreen(true)
            menu:SetWidth(width)
            menu:EnableMouse(true)
            menu:SetScript("OnShow", function()
                UI.activeMenu = menu
                menu:RegisterEvent("GLOBAL_MOUSE_DOWN")
                menu:RegisterEvent("PLAYER_REGEN_DISABLED")
                menu:EnableKeyboard(not InCombatLockdown())
                if not InCombatLockdown() then menu:SetPropagateKeyboardInput(true) end
                UI:SetIcon(button.arrow, "up")
            end)
            menu:SetScript("OnHide", function()
                menu:UnregisterEvent("GLOBAL_MOUSE_DOWN")
                menu:UnregisterEvent("PLAYER_REGEN_DISABLED")
                if UI.activeMenu == menu then UI.activeMenu = nil end
                UI:SetIcon(button.arrow, "down")
            end)
            -- Observe the click without an overlay: the underlying control still receives it.
            menu:SetScript("OnEvent", function(_, event)
                if event == "PLAYER_REGEN_DISABLED" or (not menu:IsMouseOver() and not button:IsMouseOver()) then menu:Hide() end
            end)
            menu:SetScript("OnKeyDown", function(_, key)
                if not InCombatLockdown() then menu:SetPropagateKeyboardInput(key ~= "ESCAPE") end
                if key == "ESCAPE" then menu:Hide() end
            end)
            local scroll = self:Scroll(menu)
            scroll:SetPoint("TOPLEFT", 4, -4)
            scroll:SetPoint("BOTTOMRIGHT", -26, 4)
            menu.list = APR.VirtualList:New(scroll, function(owner)
                local row = self:Button(owner, "", width - 32, function(row)
                    button.value = row.item.value
                    button:SetText(row.item.label)
                    menu:Hide()
                    changed(row.item.value)
                end)
                self:ButtonIcon(row, "check", 16)
                row:GetFontString():SetJustifyH("LEFT")
                return row
            end, function(row, item)
                row:SetText(item.label)
                row.icon:SetShown(item.value == button.value)
                UI:SetButtonActive(row, item.value == button.value)
            end, 28)
            button:HookScript("OnHide", function() menu:Hide() end)
            menu:Hide()
        end
        -- Use the screen space on the roomier side, and scroll only when all rows cannot fit.
        -- Positions returned by GetTop/GetBottom use the button's effective scale.
        local screenHeight = UIParent:GetHeight() * UIParent:GetEffectiveScale() / button:GetEffectiveScale()
        local below = math.max(0, (button:GetBottom() or 0) - 10)
        local above = math.max(0, screenHeight - (button:GetTop() or screenHeight) - 10)
        local desired = #(button.options or {}) * 28 + 8
        local upwards = desired > below and above > below
        local available = upwards and above or below
        local capacity = math.max(36, math.floor((available - 8) / 28) * 28 + 8)
        button.menu:ClearAllPoints()
        button.menu:SetPoint(upwards and "BOTTOMLEFT" or "TOPLEFT", button,
            upwards and "TOPLEFT" or "BOTTOMLEFT", 0, upwards and 2 or -2)
        button.menu:SetHeight(math.min(desired, capacity))
        button.menu:SetWidth(button:GetWidth())
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

function UI:Window(name, title, width, height, surface, logo)
    local frame = self:Panel(UIParent, "window", surface)
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
    if logo then frame:SetClampRectInsets(-24, 0, 26, 0) end
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
    frame.header:SetPoint("TOPLEFT", logo and 72 or 16, logo and -3 or -8)
    frame.header:SetPoint("TOPRIGHT", -52, logo and -3 or -8)
    frame.header:SetHeight(42)
    frame.header:EnableMouse(true)
    frame.header.Text = self:Label(frame.header, title, 20, "accent")
    frame.header.Text:SetPoint("LEFT")
    frame.header.Text:SetPoint("RIGHT", -8, 0)
    frame.header.Text:SetWordWrap(false)
    APR:SetupHeaderDrag(frame.header, frame, function() return not InCombatLockdown() end, saveGeometry)
    if logo then
        -- The artwork already contains its ring; a portrait template would add a second one and its own title bar.
        frame.logo = self:Icon(frame.header, logo, 80)
        -- Cover the frame's corner with the opaque part of the medallion, not its transparent margin.
        frame.logo:SetPoint("CENTER", frame, "TOPLEFT", 18, -18)
    end
    frame.close = self:IconButton(frame, "close", 30, function() frame:Hide() end)
    self:Tooltip(frame.close, CLOSE)
    frame.close:SetPoint("CENTER", frame.header, "RIGHT", 25, 0)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 16, -58)
    frame.content:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.resize = self:IconButton(frame, "resize", 22, function() end)
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
