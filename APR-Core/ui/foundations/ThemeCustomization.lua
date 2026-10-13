-- Edits a profile-local draft; only Apply publishes it to native Modern frames.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.ThemeCustomization = {previews = setmetatable({}, {__mode = "k"})}
local Editor = APR.ThemeCustomization

local function Copy(settings, name)
    settings = settings or {}
    local accent = (APR.Themes[name] or APR.Themes.modern).accent
    return {theme = name, customColor = settings.customColor == true,
        color = {unpack(settings.color or accent)}, rounded = settings.rounded ~= false,
        radius = math.max(0, math.min(16, tonumber(settings.radius) or 8))}
end

function Editor:GetDraft()
    local profile = APR:GetSettingsProfile()
    if not self.draft or self.profile ~= profile then
        self.profile = profile
        self.draft = Copy(profile.uiThemeCustomization, APR:GetSelectedSkinName())
    end
    return self.draft
end

function Editor:IsModern()
    local theme = APR.Themes[self:GetDraft().theme]
    return theme and theme.style == "modern" or false
end

function Editor:IsDirty()
    local draft = self:GetDraft()
    local saved = Copy(self.profile.uiThemeCustomization, APR:GetSelectedSkinName())
    if draft.theme ~= saved.theme or draft.customColor ~= saved.customColor or draft.rounded ~= saved.rounded
        or draft.radius ~= saved.radius then return true end
    for index = 1, 3 do if math.abs(draft.color[index] - saved.color[index]) > 0.00001 then return true end end
    return false
end

function Editor:UpdatePreviews()
    for widget in pairs(self.previews) do widget:Refresh() end
    -- Color changes do not rebuild AceConfig's page, and confirmation may be
    -- suppressed when the picker already holds the selected RGB. Refresh the
    -- existing footer from the same draft without releasing the open picker.
    if APR.OptionsPanel and APR.OptionsPanel.RefreshActions then APR.OptionsPanel:RefreshActions() end
end

function Editor:SetTheme(name)
    local draft = self:GetDraft()
    draft.theme = name
    if not draft.customColor then draft.color = {unpack((APR.Themes[name] or APR.Themes.modern).accent)} end
    self:UpdatePreviews()
end

function Editor:Set(key, value)
    self:GetDraft()[key] = value
    self:UpdatePreviews()
end

function Editor:SetColor(r, g, b)
    self:Set("color", {math.max(0, math.min(1, r)), math.max(0, math.min(1, g)), math.max(0, math.min(1, b)), 1})
end

function Editor:Discard()
    self.draft, self.profile = nil, nil
    self:UpdatePreviews()
end

function Editor:Apply()
    if InCombatLockdown() then return false end
    local draft = self:GetDraft()
    local previous = APR:GetSelectedSkinName()
    local oldTheme, newTheme = APR.Themes[previous], APR.Themes[draft.theme]
    local pending, profile = Copy(draft, draft.theme), self.profile
    local function publish()
        if InCombatLockdown() or APR:GetSettingsProfile() ~= profile then return false end
        profile.uiTheme = pending.theme
        profile.elvuiSkin, profile.ellesmereuiSkin = pending.theme == "ElvUI", pending.theme == "EllesmereUI"
        profile.uiThemeCustomization = Copy(pending, pending.theme)
        self.draft = Copy(profile.uiThemeCustomization, pending.theme)
        return true
    end
    if previous ~= draft.theme and not (oldTheme and newTheme and oldTheme.style == "modern" and newTheme.style == "modern") then
        APR:RequestReload(publish)
    elseif publish() then
        APR:RefreshRegisteredSkins(true)
        if APR.RefreshTextAppearance then APR:RefreshTextAppearance() end
        if APR.Workspace and APR.Workspace.frame then APR.Workspace:LayoutTabs() end
        self:UpdatePreviews()
    end
    return true
end

function Editor:GetOptions()
    local disabled = function() return not self:IsModern() end
    return {
        themePreview = {type = "description", name = L["UI_THEME_PREVIEW"], dialogControl = "APRThemePreview", width = "full", order = 2,
            hidden = function() return APR.OptionsPanel and APR.OptionsPanel.themePreviewActive or false end},
        themePreviewHint = {type = "description", name = L["UI_THEME_PREVIEW_HINT"], dialogControl = "APRThemeNotice", width = "full", order = 3},
        themeCustomizationHeader = {type = "header", name = L["UI_THEME_CUSTOMIZATION"], order = 3.5},
        themeCustomColor = {type = "toggle", name = L["UI_THEME_CUSTOM_COLOR"], desc = L["UI_THEME_CUSTOM_COLOR_DESC"], order = 4,
            disabled = disabled, get = function() return self:GetDraft().customColor end, set = function(_, value) self:Set("customColor", value) end},
        themeAccent = {type = "color", name = L["UI_THEME_ACCENT"], order = 5, hasAlpha = false,
            disabled = function() return disabled() or not self:GetDraft().customColor end,
            get = function() return unpack(self:GetDraft().color) end, set = function(_, r, g, b) self:SetColor(r, g, b) end},
        themeRounded = {type = "toggle", name = L["UI_THEME_ROUNDED"], order = 7, disabled = disabled,
            get = function() return self:GetDraft().rounded end, set = function(_, value) self:Set("rounded", value) end},
        themeRadius = {type = "range", name = L["UI_THEME_RADIUS"], desc = L["UI_THEME_RADIUS_DESC"], order = 8, min = 0, max = 16, step = 1,
            disabled = function() return disabled() or not self:GetDraft().rounded end,
            get = function() return self:GetDraft().radius end, set = function(_, value) self:Set("radius", value) end},
        themeDiscard = {type = "execute", name = CANCEL, order = 10, disabled = function() return not self:IsDirty() end, func = function() self:Discard() end},
        themeApply = {type = "execute", name = APPLY, desc = L["UI_THEME_APPLY_DESC"], order = 11,
            disabled = function() return InCombatLockdown() or not self:IsDirty() end, func = function() self:Apply() end},
    }
end

function Editor:InstallPreviewWidget(gui)
    -- Keep the preview explanation clear of the selector's divider and the next section.
    gui:RegisterWidgetType("APRThemeNotice", function()
        local frame = CreateFrame("Frame", nil, UIParent)
        local widget = {type = "APRThemeNotice", frame = frame}
        widget.label = APR.UI:Label(frame, "", 12, "base")
        widget.label:SetPoint("TOPLEFT", 12, -20)
        widget.label:SetPoint("TOPRIGHT", -12, -20)
        widget.label:SetJustifyH("LEFT"); widget.label:SetWordWrap(true)
        function widget:Resize()
            self.label:SetWidth(math.max(1, self.frame:GetWidth() - 24))
            self:SetHeight(math.max(18, self.label:GetStringHeight()) + 40)
        end
        function widget:SetText(text) self.label:SetText(text or ""); self:Resize() end
        function widget:SetFontObject() self:Resize() end
        function widget:SetImage() end
        function widget:SetImageSize() end
        function widget:OnWidthSet() self:Resize() end
        function widget:OnAcquire() self:SetWidth(300); self:SetText("") end
        return gui:RegisterAsWidget(widget)
    end, 1)
    gui:RegisterWidgetType("APRThemePreview", function()
        local frame = CreateFrame("Frame", nil, UIParent)
        local widget = {type = "APRThemePreview", frame = frame}
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 0, -4); title:SetPoint("TOPRIGHT", 0, -4)
        title:SetJustifyH("LEFT"); title:SetText(L["UI_THEME_PREVIEW"])
        local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        local body = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        local caption = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        caption:SetPoint("LEFT", 12, 0); caption:SetPoint("RIGHT", -12, 0); caption:SetJustifyH("LEFT")
        caption:SetText(APR.title)
        local step = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        step:SetPoint("TOPLEFT", 12, -36); step:SetPoint("TOPRIGHT", -12, -36); step:SetJustifyH("LEFT")
        step:SetWordWrap(true); step:SetText(L["UI_THEME_PREVIEW_STEP"])
        local bar = CreateFrame("StatusBar", nil, body)
        bar:SetPoint("TOPLEFT", 12, -12); bar:SetPoint("TOPRIGHT", -12, -12); bar:SetHeight(16)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); bar:SetMinMaxValues(0, 40); bar:SetValue(23)
        local count = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("CENTER"); count:SetText("23 / 40")
        local button = CreateFrame("Frame", nil, body, "BackdropTemplate")
        button:SetPoint("BOTTOMLEFT", 12, 12); button:SetPoint("BOTTOMRIGHT", -12, 12); button:SetHeight(28)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER"); label:SetText(L["ROUTE_SELECTION"])
        local unavailable = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -36); unavailable:SetPoint("TOPRIGHT", 0, -36)
        unavailable:SetWordWrap(true); unavailable:SetText(L["UI_THEME_NATIVE_ONLY"])
        function widget:Refresh()
            local draft = Editor:GetDraft()
            local modern = Editor:IsModern()
            header:SetShown(modern); body:SetShown(modern); unavailable:SetShown(not modern)
            if not modern then title:SetTextColor(unpack(APR:GetThemeColor("accent"))); return end
            local theme = APR:CustomizeTheme(APR.Themes[draft.theme], draft)
            local accent = APR.GetCustomTextColor and APR:GetCustomTextColor("general", "accent") or theme.accent
            local base = APR.GetCustomTextColor and APR:GetCustomTextColor("general", "base") or theme.base
            title:SetTextColor(unpack(accent))
            APR:RenderThemePreviewPanel(header, theme, APR:GetThemeRadius(8, nil, draft), "top", "surface")
            APR:RenderThemePreviewPanel(body, theme, APR:GetThemeRadius(8, nil, draft), "bottom")
            APR:RenderThemePreviewPanel(button, theme, APR:GetThemeRadius(4, nil, draft), nil, "surface")
            caption:SetTextColor(unpack(accent)); label:SetTextColor(unpack(accent))
            step:SetTextColor(unpack(base)); bar:SetStatusBarColor(unpack(theme.accent))
        end
        function widget:SetText() self:Refresh() end
        function widget:SetFontObject() end
        function widget:SetImage() end
        function widget:SetImageSize() end
        function widget:OnWidthSet(width)
            header:SetPoint("TOPLEFT", 0, -30); header:SetPoint("TOPRIGHT", 0, -30); header:SetHeight(30)
            body:SetPoint("TOPLEFT", 0, -60); body:SetPoint("TOPRIGHT", 0, -60); body:SetHeight(120)
        end
        function widget:OnAcquire()
            self:SetWidth(300); self:SetHeight(192); self:SetPreviewActive(true)
        end
        function widget:SetPreviewActive(active)
            Editor.previews[self] = active and true or nil
            self.frame:SetShown(active)
            if active then self:Refresh() end
        end
        function widget:OnRelease() self:SetPreviewActive(false) end
        widget.preview = {title = title, caption = caption, step = step, label = label,
            header = header, body = body, button = button, bar = bar}
        return gui:RegisterAsWidget(widget)
    end, 1)
end
