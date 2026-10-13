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

function UI:Label(parent, text, size, role, scope)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    APR:RegisterFontString(label, scope or "general", { role = role or "base", sizeDelta = (size or 12) - 12, themeAccent = true })
    return label
end

function UI:Panel(parent, kind, surface, scope, options)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    APR:RegisterSkinTarget(frame, kind or "panel", { themeSurface = true, preserveContent = true, surface = surface, scope = scope,
        nativeWoW = options and options.nativeWoW })
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

function UI:Button(parent, text, width, callback, style, scope, options)
    local nativeWoW = options and options.nativeWoW
    local button = CreateFrame("Button", nil, parent, nativeWoW and "UIPanelButtonTemplate,BackdropTemplate" or "BackdropTemplate")
    button:SetSize(width or 130, 30)
    button.aprThemeScope = scope
    local label = self:Label(button, text, 12, nativeWoW and "accent" or nil, scope)
    label:SetPoint("LEFT", 10, 0)
    label:SetPoint("RIGHT", -10, 0)
    label:SetJustifyH("CENTER")
    button:SetFontString(label)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self)
        if self.aprListRow or APR:GetSkinProviderName(scope) then return end
        if self:IsEnabled() and self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor("accent", scope))) end
    end)
    button:SetScript("OnLeave", function(self)
        if self.aprListRow or APR:GetSkinProviderName(scope) then return end
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(APR:GetThemeColor(self.active and "accent" or "border", scope))) end
    end)
    button:SetScript("OnEnable", function() label:SetAlpha(1) end)
    button:SetScript("OnDisable", function() label:SetAlpha(0.4) end)
    if style == "flat" then
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        APR:RegisterThemeRegion(highlight, "accent", 0.12)
    end
    if style == "raised" then self:ElevateButton(button) end
    local flat = style == "flat" or style == "list"
    APR:RegisterSkinTarget(button, flat and "flatButton" or "button", { themeSurface = not flat, scope = scope,
        nativeWoW = nativeWoW })
    return button
end

function UI:SetButtonActive(button, active)
    button.active = active == true
    APR:SetFontStringRole(button:GetFontString(), active and "accent" or "base")
    if button.aprListRow then
        self:SetListRowState(button, active)
    elseif not APR:GetSkinProviderName(button.aprThemeScope) then
        button:SetBackdropBorderColor(unpack(APR:GetThemeColor(active and "accent" or "border", button.aprThemeScope)))
    end
end

-- Shared list chrome lives beside the row so its translucent fill cannot cover text or actions.
local listRows = setmetatable({}, {__mode = "k"})
function UI:RefreshListRow(row)
    local look = row.aprListRow
    if not look or not look.background or InCombatLockdown() then return end
    local scope = look.scope
    local enabled = not look.gameplay or APR:GetThemeStyle(scope) == "modern"
    if not enabled then
        look.background:Hide()
        if look.iconHost then look.iconHost:Hide() end
        return
    end
    if look.gameplay and row.SetBackdrop then row:SetBackdrop(nil) end
    local background = look.background
    if background:GetParent() ~= row:GetParent() then background:SetParent(row:GetParent()) end
    background:SetFrameStrata(row:GetFrameStrata())
    background:SetFrameLevel(math.max(0, row:GetFrameLevel() - 1))
    local radius = APR:GetThemeStyle(scope) == "modern" and APR:GetThemeRadius(4, scope) or 4
    local accent = APR:GetThemeColor("accent", scope)
    if look.radius ~= radius then
        APR:RenderThemePreviewPanel(background, {background = {0,0,0,0}, border = {0,0,0,0}}, radius)
        look.radius = radius
    end
    local available = look.enabled ~= false and (not row.IsEnabled or row:IsEnabled())
    local selected = look.selected and available
    background:SetBackdropColor(accent[1], accent[2], accent[3], selected and 0.13 or look.hovered and available and 0.08 or 0)
    background:SetBackdropBorderColor(accent[1], accent[2], accent[3], selected and 0.7 or 0)
    local border = APR:GetThemeColor("border", scope)
    look.separator:SetColorTexture(border[1], border[2], border[3], 0.42)
    look.separator:SetShown(not selected and not look.last and not look.heading)
    background:SetShown(row:IsShown())
    if look.iconHost then
        look.iconHost:SetShown(row:IsShown() and look.iconName ~= nil and not look.heading)
        local color = APR:GetThemeColor(selected and "accent" or "muted", scope)
        look.icon:SetVertexColor(color[1], color[2], color[3], available and 1 or 0.45)
    end
end

function UI:StyleListRow(row, icon, scope, gameplay)
    local look = row.aprListRow
    if not look then
        look = {scope = scope, gameplay = gameplay}
        row.aprListRow = look
        listRows[row] = true
    end
    look.requestedIcon = icon
    if InCombatLockdown() then return look end
    if not look.background then
        look.background = CreateFrame("Frame", nil, row:GetParent(), "BackdropTemplate")
        look.background:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        look.background:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
        look.background:EnableMouse(false)
        look.separator = look.background:CreateTexture(nil, "BACKGROUND")
        look.separator:SetPoint("BOTTOMLEFT", 12, 0); look.separator:SetPoint("BOTTOMRIGHT", -12, 0)
        look.separator:SetHeight(1)
        row:HookScript("OnEnter", function() look.hovered = true; UI:RefreshListRow(row) end)
        row:HookScript("OnLeave", function() look.hovered = nil; UI:RefreshListRow(row) end)
        row:HookScript("OnHide", function()
            look.hovered = nil; look.background:Hide()
            if look.iconHost then look.iconHost:Hide() end
        end)
        row:HookScript("OnShow", function() UI:RefreshListRow(row) end)
        if row.HasScript and row:HasScript("OnEnable") then
            row:HookScript("OnEnable", function() UI:RefreshListRow(row) end)
            row:HookScript("OnDisable", function() UI:RefreshListRow(row) end)
        end
    end
    if icon and not look.iconHost then
        look.iconHost = CreateFrame("Frame", nil, row)
        look.iconHost:SetSize(18, 18); look.iconHost:SetPoint("LEFT", 12, 0)
        look.iconHost:EnableMouse(false)
        look.icon = self:Icon(look.iconHost, icon, 18)
        look.icon:SetAllPoints()
    elseif icon and look.iconName ~= icon then
        self:SetIcon(look.icon, icon)
    end
    look.iconName = icon
    self:RefreshListRow(row)
    return look
end

function UI:SetListRowState(row, selected, last, enabled, heading)
    local look = row.aprListRow
    if not look then return end
    look.selected = selected == true
    if last ~= nil then look.last = last end
    if enabled ~= nil then look.enabled = enabled end
    if heading ~= nil then look.heading = heading end
    self:RefreshListRow(row)
end

function UI:ListButton(parent, text, width, callback, icon, scope)
    local row = self:Button(parent, text, width, callback, "list", scope)
    self:StyleListRow(row, icon, scope)
    local label = row:GetFontString()
    label:ClearAllPoints(); label:SetPoint("LEFT", icon and 38 or 12, 0); label:SetPoint("RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    return row
end

function UI:RefreshListRows()
    for row in pairs(listRows) do
        local look = row.aprListRow
        if not look.background then self:StyleListRow(row, look.requestedIcon, look.scope, look.gameplay)
        else self:RefreshListRow(row) end
    end
end

-- AceGUI's APR-only pools retain their native value/validation handlers.
function UI:StyleDropdownListItem(widget)
    if not widget or widget.type ~= "Dropdown-Item-Toggle" then return end
    local selected = widget.GetValue and widget:GetValue() == true
    local row = widget.frame
    self:StyleListRow(row)
    if widget.highlight then widget.highlight:SetAlpha(0) end
    if widget.check then widget.check:SetAlpha(1) end
    row:SetHeight(26)
    widget.text:ClearAllPoints()
    widget.text:SetPoint("LEFT", 26, 0); widget.text:SetPoint("RIGHT", -8, 0)
    self:SetListRowState(row, selected, nil, not widget.disabled)
    APR:RegisterFontString(widget.text, "general", {role = widget.disabled and "muted" or selected and "accent" or "base", themeAccent = true})
    if not row.aprListRow.dropdownClickHook then
        row.aprListRow.dropdownClickHook = true
        -- Toggle clicks assign value directly, bypassing AceGUI's SetValue hooks.
        row:HookScript("OnClick", function() UI:StyleDropdownListItem(widget) end)
    end
end

function UI:StyleDropdownList(widget)
    if not widget or widget.type ~= "Dropdown-Pullout" then return end
    local function layout()
        local height = 0
        for index, item in ipairs(widget.items or {}) do
            UI:StyleDropdownListItem(item)
            item:SetPoint("TOP", widget.itemFrame, "TOP", 0, -2 - height)
            height = height + item.frame:GetHeight()
            if item.frame.aprListRow then UI:SetListRowState(item.frame, item:GetValue() == true, index == #widget.items) end
        end
        widget.itemFrame:SetHeight(height + 8)
        widget.frame:SetHeight(math.min(height + 34, widget.maxHeight or 600))
    end
    if not widget.aprListLayout then
        widget.aprListLayout = layout
        -- AceGUI's original Open places every item at 16px regardless of its height.
        -- Reflow only this APR-owned pullout after its native open/value callbacks.
        hooksecurefunc(widget, "Open", layout)
    end
    layout()
end

local listWatcher = CreateFrame("Frame")
listWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
listWatcher:SetScript("OnEvent", function() UI:RefreshListRows() end)

-- Blizzard and AceConfig own popup actions and reuse their frames for other addons.
-- Only APR-owned background children receive persistent skins; original artwork is restored on hide.
local pendingPopups = setmetatable({}, {__mode = "k"})
local popupWatcher = CreateFrame("Frame")
popupWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
popupWatcher:SetScript("OnEvent", function()
    for popup, buttons in pairs(pendingPopups) do
        pendingPopups[popup] = nil
        if popup:IsShown() and popup._aprTextOriginals then UI:StylePopupChrome(popup, buttons) end
    end
end)

function UI:StylePopupChrome(popup, buttons)
    if InCombatLockdown() then pendingPopups[popup] = buttons; return end
    pendingPopups[popup] = nil
    local look = popup.aprPopupChrome
    if not look then
        look = {buttons = {}}
        popup.aprPopupChrome = look
        -- A child frame can render over its parent's FontStrings even when a lower
        -- frame level is requested. Keep the opaque chrome beside the popup instead.
        look.background = self:Panel(popup:GetParent() or UIParent, "window", "library", nil, {nativeWoW = true})
        -- ResizeLayoutFrame must never measure its own all-points decorative children.
        look.background.ignoreInLayout = true
        look.background:SetAllPoints(popup)
        look.background:EnableMouse(false)
        look.background:SetFixedFrameLevel(true)
        look.background:SetFrameLevel(math.max(0, popup:GetFrameLevel() - 1))
        popup:HookScript("OnHide", function()
            for region, alpha in pairs(look.originalArt or {}) do region:SetAlpha(alpha) end
            look.originalArt = nil
            look.originalTextHeight = nil
            if look.originalLevel ~= nil then popup:SetFrameLevel(look.originalLevel); look.originalLevel = nil end
            if look.originalHeight then popup:SetHeight(look.originalHeight); look.originalHeight = nil end
            look.background:Hide()
            for button, entry in pairs(look.buttons) do
                entry.background:Hide()
                if entry.originalHeight then button:SetHeight(entry.originalHeight); entry.originalHeight = nil end
            end
        end)
    end
    look.originalArt = look.originalArt or {}
    if look.originalLevel == nil then look.originalLevel = popup:GetFrameLevel() end
    -- At level zero, a child background cannot be placed beneath the parent's text.
    popup:SetFrameLevel(math.max(10, popup:GetFrameLevel()))
    look.background:SetParent(popup:GetParent() or UIParent)
    if popup.GetFrameStrata then look.background:SetFrameStrata(popup:GetFrameStrata()) end
    look.background:SetFrameLevel(popup:GetFrameLevel() - 1)
    look.originalHeight = look.originalHeight or popup:GetHeight()
    local text = APR:GetPopupText(popup)
    look.originalTextHeight = look.originalTextHeight or (text and text:GetStringHeight() or 0)
    local excluded = {[look.background] = true}
    for _, entry in pairs(look.buttons) do excluded[entry.background] = true end
    for _, key in ipairs({"editBox", "EditBox", "AlertIcon", "alertIcon", "Icon", "icon"}) do
        if popup[key] then excluded[popup[key]] = true end
    end
    for _, button in ipairs(buttons) do excluded[button] = true end
    local function retireArt(frame)
        if frame.GetRegions then
            for _, region in ipairs({frame:GetRegions()}) do
                if not excluded[region] and region.IsObjectType and region:IsObjectType("Texture") then
                    if look.originalArt[region] == nil then look.originalArt[region] = region:GetAlpha() end
                    region:SetAlpha(0)
                end
            end
        end
        if frame.GetChildren then
            for _, child in ipairs({frame:GetChildren()}) do
                local control = child.IsObjectType and (child:IsObjectType("Button") or child:IsObjectType("EditBox"))
                if not excluded[child] and not control then retireArt(child) end
            end
        end
    end
    retireArt(popup)
    look.background:Show()
    local native = APR:GetThemeStyle() == "wow" and not APR:GetSkinProviderName()
    for _, button in ipairs(buttons) do
        local entry = look.buttons[button]
        if not entry then
            entry = {background = self:Panel(button:GetParent(), "button")}
            look.buttons[button] = entry
            entry.background.ignoreInLayout = true
            entry.background:SetAllPoints(button); entry.background:EnableMouse(false)
            entry.background:SetFixedFrameLevel(true)
            entry.background:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
            button:HookScript("OnEnter", function()
                if look.originalArt then entry.background:SetBackdropBorderColor(unpack(APR:GetThemeColor("accent"))) end
            end)
            button:HookScript("OnLeave", function()
                if look.originalArt then entry.background:SetBackdropBorderColor(unpack(APR:GetThemeColor("border"))) end
            end)
        end
        entry.background:SetParent(button:GetParent())
        if button.GetFrameStrata then entry.background:SetFrameStrata(button:GetFrameStrata()) end
        entry.background:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
        if button:IsShown() then entry.originalHeight = entry.originalHeight or button:GetHeight() end
        if button:IsShown() and not native then
            for _, state in ipairs({"Normal", "Pushed", "Highlight", "Disabled"}) do
                local texture = button["Get" .. state .. "Texture"] and button["Get" .. state .. "Texture"](button)
                if texture then
                    if look.originalArt[texture] == nil then look.originalArt[texture] = texture:GetAlpha() end
                    texture:SetAlpha(0)
                end
            end
            excluded[entry.background] = true
            retireArt(button)
            entry.background:Show()
        else
            entry.background:Hide()
        end
    end
    self:LayoutPopupChrome(popup, buttons)
end

function UI:LayoutPopupChrome(popup, buttons)
    if InCombatLockdown() then return end
    local look = popup.aprPopupChrome
    if not look or not look.originalArt then return end
    local native = APR:GetThemeStyle() == "wow" and not APR:GetSkinProviderName()
    local buttonHeight = native and 21 or 30
    for _, button in ipairs(buttons) do
        if button:IsShown() then
            local label = button:GetFontString()
            buttonHeight = math.max(buttonHeight, label and label:GetStringHeight() + (native and 6 or 12) or 0)
        end
    end
    for _, button in ipairs(buttons) do if button:IsShown() then button:SetHeight(buttonHeight) end end
    local text = APR:GetPopupText(popup)
    local textHeight, oldButtonHeight = text and text:GetStringHeight() or 0, 0
    for _, button in ipairs(buttons) do
        local entry = look.buttons[button]
        if button:IsShown() and entry then oldButtonHeight = math.max(oldButtonHeight, entry.originalHeight or buttonHeight) end
    end
    -- Keep the native edit-box/icon spacing while accommodating taller translated labels.
    local minimum = (look.originalHeight or 0) + math.max(0, buttonHeight - oldButtonHeight)
        + math.max(0, textHeight - (look.originalTextHeight or textHeight))
    local edit = popup.editBox or popup.EditBox
    local extra = (edit and edit:IsShown()) or (popup.AlertIcon and popup.AlertIcon:IsShown())
        or (popup.SubText and popup.SubText:IsShown() and (popup.SubText:GetText() or "") ~= "")
        or popup.insertedFrame or (popup.Dropdown and popup.Dropdown:IsShown())
    popup:SetHeight(extra and math.max(minimum, textHeight + buttonHeight + 40) or textHeight + buttonHeight + 40)
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
        APR:RegisterThemeRegion(thumb, "border", 1, true)
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
                local row = self:ListButton(owner, "", width - 32, function(row)
                    button.value = row.item.value
                    button:SetText(row.item.label)
                    menu:Hide()
                    changed(row.item.value)
                end)
                row:GetFontString():SetJustifyH("LEFT")
                return row
            end, function(row, item)
                row:SetText(item.label)
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
