-- Shared palettes for utility windows and gameplay chrome. WoW gameplay art stays native.
-- A tracker scope can choose its own appearance without changing the rest of APR.

APR.Themes = {
    wow = { label = "World of Warcraft", style = "wow", background = { 0.08, 0.065, 0.045, 0.96 }, surface = { 0.16, 0.13, 0.09, 1 },
        border = { 0.53, 0.43, 0.24, 1 }, accent = { 1, 0.82, 0.28, 1 }, base = { 0.96, 0.94, 0.88, 1 },
        muted = { 0.7, 0.67, 0.59, 1 }, icon = { 0.94, 0.8, 0.55, 1 },
        selection = { 0.55, 0.42, 0.16, 1 }, stripe = { 0.28, 0.20, 0.12, 1 },
    },
    -- Keep the saved "modern" identifier so existing profiles retain the user's Blue Modern palette.
    modern = { label = "Blue Modern", labelKey = "UI_THEME_MODERN", style = "modern",
        background = { 0.075, 0.08, 0.09, 0.94 }, surface = { 0.12, 0.13, 0.15, 0.97 },
        border = { 0.25, 0.28, 0.32, 0.85 }, accent = { 0, 176 / 255, 150 / 255, 1 }, -- Bleu canard #00B096.
        base = { 0.88, 0.90, 0.92, 1 }, muted = { 0.52, 0.57, 0.62, 1 },
        icon = { 0, 176 / 255, 150 / 255, 1 }, selection = { 0, 176 / 255, 150 / 255, 1 },
        warning = { 214 / 255, 184 / 255, 138 / 255, 1 },
        stripe = { 0.19, 0.21, 0.24, 1 },
    },
}

local function RGB(r, g, b, alpha) return {r / 255, g / 255, b / 255, alpha or 1} end
local function ModernVariant(name, label, labelKey, overrides)
    local theme = {}
    for key, value in pairs(APR.Themes.modern) do
        theme[key] = type(value) == "table" and {unpack(value)} or value
    end
    for key, value in pairs(overrides) do theme[key] = value end
    theme.label, theme.labelKey = label, labelKey
    theme.icon, theme.selection = {unpack(theme.accent)}, {unpack(theme.accent)}
    APR.Themes[name] = theme
end

ModernVariant("wowModern", "WoW Modern", "UI_THEME_WOW_MODERN", {
    background = {0.08, 0.065, 0.045, 0.96}, surface = {0.16, 0.13, 0.09, 1},
    border = {0.53, 0.43, 0.24, 1}, accent = RGB(213, 181, 106),
    base = RGB(245, 239, 224), muted = RGB(170, 160, 139), stripe = {0.28, 0.20, 0.12, 1},
})
ModernVariant("graphiteModern", "Graphite Modern", "UI_THEME_GRAPHITE_MODERN", {
    background = RGB(21, 22, 25, 0.94), surface = RGB(34, 37, 42, 0.97),
    border = RGB(69, 74, 82, 0.85), accent = RGB(196, 203, 212), muted = RGB(157, 164, 173),
    stripe = RGB(44, 47, 53),
})
ModernVariant("emeraldModern", "Emerald Modern", "UI_THEME_EMERALD_MODERN", {
    background = RGB(17, 27, 23, 0.94), surface = RGB(27, 43, 35, 0.97),
    border = RGB(52, 80, 68, 0.85), accent = RGB(85, 201, 139), muted = RGB(140, 173, 160),
    stripe = RGB(35, 54, 45),
})
ModernVariant("violetModern", "Violet Modern", "UI_THEME_VIOLET_MODERN", {
    background = RGB(24, 20, 31, 0.94), surface = RGB(41, 33, 51, 0.97),
    border = RGB(80, 64, 98, 0.85), accent = RGB(181, 147, 244), muted = RGB(167, 152, 190),
    stripe = RGB(49, 39, 62),
})
ModernVariant("redModern", "Crimson Modern", "UI_THEME_RED_MODERN", {
    background = RGB(32, 21, 24, 0.94), surface = RGB(50, 32, 37, 0.97),
    border = RGB(101, 66, 76, 0.85), accent = RGB(232, 135, 135), muted = RGB(180, 156, 163),
    stripe = RGB(61, 38, 45),
})

function APR:GetThemeChoices(locale)
    local choices = {}
    for name, theme in pairs(self.Themes) do
        choices[name] = (theme.labelKey and locale and locale[theme.labelKey]) or theme.label or name
    end
    return choices
end

-- Utility windows keep APR's established rounded chrome; gameplay uses the flat Modern renderer.
local themeSurfaces = setmetatable({}, {__mode = "k"})
local semantic = { success = { 0.38, 0.91, 0.53, 1 }, warning = { 1, 0.79, 0.31, 1 }, error = { 1, 0.4, 0.4, 1 } }
-- Progress keeps the same meaning under every skin; the skin's accent still marks selection/actions.
local statusColors = { routeCompleted = { 0.38, 0.91, 0.53, 1 }, routeInProgress = { 0.40, 0.75, 1, 1 },
    routeNotStarted = { 0.90, 0.88, 0.82, 1 } }
local surfaces = { library = { 0.105, 0.075, 0.05, 1 }, inset = { 0.13, 0.095, 0.065, 1 },
    stone = { 0.17, 0.13, 0.09, 1 } }

local customizedThemes = setmetatable({}, {__mode = "k"})
local integrationThemes = {}
function APR:GetTheme(scope)
    local profile = self.GetSettingsProfile and self:GetSettingsProfile()
    local name = self.GetAppearanceProvider and self:GetAppearanceProvider(scope) or (profile and profile.uiTheme)
    if (name == "ElvUI" or name == "EllesmereUI") and self:GetSkinProviderName(scope) == name then
        local integration = name == "ElvUI" and self.ElvUISkin or self.EllesmereUISkin
        local theme = integrationThemes[name] or {}
        integrationThemes[name] = theme
        for key, value in pairs(self.Themes.modern) do
            theme[key] = type(value) == "table" and integration and integration.GetThemeColor
                and integration:GetThemeColor(key, scope) or value
        end
        return theme, name
    end
    if not self.Themes[name] then name = "wow" end
    local theme, custom = self.Themes[name], profile and profile.uiThemeCustomization
    if theme.style ~= "modern" or not custom or not custom.customColor then return theme, name end
    local color = custom.color or theme.accent
    local cache = customizedThemes[custom] or {}
    customizedThemes[custom] = cache
    local entry = cache[name]
    if not entry or entry.source ~= theme or entry.r ~= color[1] or entry.g ~= color[2] or entry.b ~= color[3] then
        entry = {source = theme, r = color[1], g = color[2], b = color[3], theme = self:CustomizeTheme(theme, custom)}
        cache[name] = entry
    end
    return entry.theme, name
end

-- The preview uses the same pure palette builder as live frames, without changing SavedVariables.
function APR:CustomizeTheme(theme, custom)
    if theme.style ~= "modern" or not custom or not custom.customColor then return theme end
    local color = custom.color or theme.accent
    local result = {}
    for key, value in pairs(theme) do result[key] = value end
    local r, g, b = color[1], color[2], color[3]
    result.accent, result.icon, result.selection = {r, g, b, 1}, {r, g, b, 1}, {r, g, b, 1}
    result.background = {0.06 + r * 0.08, 0.06 + g * 0.08, 0.06 + b * 0.08, theme.background[4]}
    result.surface = {0.10 + r * 0.10, 0.10 + g * 0.10, 0.10 + b * 0.10, theme.surface[4]}
    result.border = {0.15 + r * 0.35, 0.15 + g * 0.35, 0.15 + b * 0.35, theme.border[4]}
    result.stripe = {0.14 + r * 0.12, 0.14 + g * 0.12, 0.14 + b * 0.12, 1}
    return result
end

function APR:GetThemeRadius(base, scope, custom)
    if not custom and self:GetSkinProviderName(scope) then return 0 end
    if not custom then
        local profile = self:GetSettingsProfile()
        custom = profile and profile.uiThemeCustomization
    end
    if not custom then return base end
    if custom.rounded == false then return 0 end
    local radius = math.max(0, math.min(16, tonumber(custom.radius) or 8))
    return math.floor(base * radius / 8 + 0.5)
end

function APR:GetThemeStatusColor(role) return statusColors[role] end

function APR:GetThemeStyle(scope)
    local theme, name = self:GetTheme(scope)
    return theme.style or name
end

function APR:GetThemeColor(role, scope)
    if statusColors[role] then return statusColors[role] end
    local provider = self:GetSkinProviderName(scope)
    local integration = provider == "ElvUI" and self.ElvUISkin or provider == "EllesmereUI" and self.EllesmereUISkin
    if integration and integration.GetThemeColor then
        local color = integration:GetThemeColor(role, scope)
        if color then return color end
    end
    local theme = self:GetTheme(scope)
    return theme[role] or semantic[role] or theme.base
end

function APR:GetNativeThemeTextColor(role, scope)
    if self:GetThemeStyle(scope) == "modern" then
        return self:GetThemeColor((role == "title" or role == "activeStep") and "accent" or role or "base", scope)
    end
end

-- Custom icons and row highlights follow the skin without rebuilding pooled controls.
-- Alpha remains per region so selected, alternating and disabled states survive a recolor.
local themeRegions = setmetatable({}, { __mode = "k" })
local function ApplyRegion(region, entry)
    local color = APR:GetThemeColor(entry.role, APR.GetSkinScope and APR:GetSkinScope(region))
    local apply = entry.vertex and region.SetVertexColor or region.SetColorTexture
    apply(region, color[1], color[2], color[3], entry.alpha)
end

function APR:RegisterThemeRegion(region, role, alpha, vertex)
    local entry = themeRegions[region] or {}
    entry.role, entry.alpha, entry.vertex = role, alpha or 1, vertex
    themeRegions[region] = entry
    ApplyRegion(region, entry)
end

function APR:RefreshThemeRegions()
    for region, entry in pairs(themeRegions) do ApplyRegion(region, entry) end
    self:RefreshModernTheme()
    if not InCombatLockdown() then
        for frame, entry in pairs(themeSurfaces) do self:ApplyNativeTheme(frame, entry.kind, entry.options) end
    end
    if self.UI and self.UI.RefreshListRows then self.UI:RefreshListRows() end
end

-- Legacy panels retain their configured colors, including transparent collapsed frames.
function APR:SetPanelColor(frame, color)
    frame.aprPanelColor = color
    if color[4] ~= 0 then frame.aprExpandedPanelColor = color end
    local contentBackdrop = type(frame) == "table" and rawget(frame, "aprContentBackdrop")
    if contentBackdrop then
        self:SetPanelColor(contentBackdrop, color)
    end
    local scope = self.GetSkinScope and self:GetSkinScope(frame)
    if self:GetThemeStyle(scope) == "modern" then
        local themed = self:GetThemeColor("background", scope)
        local alpha = (color[4] or 1) * (themed[4] or 1)
        if self:GetSkinProviderName(scope) then
            -- The untouched APR backdrop must adopt the provider's opacity, too.
            -- Multiplying its old 40% opacity made external skins look washed out.
            local original = self.Color.defaultLightBackdrop or {0, 0, 0, 0.4}
            local unchanged = true
            for index = 1, 4 do
                if math.abs((color[index] or 1) - original[index]) > 0.000001 then unchanged = false; break end
            end
            alpha = unchanged and (themed[4] or 1) or (color[4] or 1)
        end
        color = {themed[1], themed[2], themed[3], alpha}
        if frame.SetBackdropBorderColor then
            local border = self:GetThemeColor("border", scope)
            frame:SetBackdropBorderColor(border[1], border[2], border[3], color[4] == 0 and 0 or border[4])
        end
    end
    if self.QuestTracker then color = self.QuestTracker:ApplyPanel(frame, color) end
    if contentBackdrop then
        color = {0, 0, 0, 0}
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0, 0, 0, 0) end
    end
    frame:SetBackdropColor(unpack(color))
end

local white = "Interface\\Buttons\\WHITE8X8"
local modernPanels = setmetatable({}, {__mode = "k"})
local modernButtons = setmetatable({}, {__mode = "k"})
local modernHeaders = setmetatable({}, {__mode = "k"})
local snappedFrames = setmetatable({}, {__mode = "k"})
local gameplayRoots = {currentStep = "CurrentStepScreenPanel", fillers = "FillersScreenPanel",
    questOrderList = "QuestOrderListPanel", afk = "AfkFrameScreen", party = "PartyScreenPanel",
    buff = "BuffFrameScreen", heirloom = "HeirloomPanel", coordinates = "CoordinateScreenPanel"}
local RoundedBackdrop, FlatPanel

local function GameplayCorners(frame, radius, corners)
    local scope = APR:GetSkinScope(frame)
    local root = gameplayRoots[scope] and _G[gameplayRoots[scope]] or frame
    if frame ~= root and frame ~= root.aprContentBackdrop and not frame.aprGameplayCorners then return radius, corners end
    local top, bottom = corners ~= "bottom", corners ~= "top"
    if root.aprSnapAnchor then top = false end
    for child in pairs(snappedFrames) do
        if child.aprSnapAnchor == root and child:IsShown() then bottom = false; break end
    end
    if not top and not bottom then return 0 end
    return radius, not top and "bottom" or not bottom and "top" or nil
end

function APR:RefreshSnappedTheme()
    if InCombatLockdown() then return end
    for frame, entry in pairs(modernPanels) do
        if entry.radius then
            FlatPanel(frame, entry.scope, entry.role, entry.border, entry.radius)
            if frame.aprPanelColor then self:SetPanelColor(frame, frame.aprPanelColor) end
        end
    end
    for header, entry in pairs(modernHeaders) do self:ApplyModernTheme(header, "header", entry.options, entry.scope) end
    for frame, entry in pairs(themeSurfaces) do
        if entry.options.roundedGameplay or frame.aprSnapCornersInitialized then self:ApplyNativeTheme(frame, entry.kind, entry.options) end
    end
end

function APR:SetFrameSnapAnchor(frame, anchor)
    if InCombatLockdown() or not frame or frame.aprSnapAnchor == anchor then return end
    frame.aprSnapAnchor = anchor
    frame.aprSnapCornersInitialized = true
    snappedFrames[frame] = anchor and true or nil
    if not frame.aprSnapVisibilityHook and frame.HookScript then
        frame.aprSnapVisibilityHook = true
        frame:HookScript("OnShow", function() APR:RefreshSnappedTheme() end)
        frame:HookScript("OnHide", function() APR:RefreshSnappedTheme() end)
    end
    self:RefreshSnappedTheme()
end

FlatPanel = function(frame, scope, role, border, radius)
    local profile = APR:GetSettingsProfile()
    local custom = profile and profile.uiThemeCustomization
    if radius and ((custom and next(custom)) or frame.aprSnapAnchor) then
        RoundedBackdrop(frame, GameplayCorners(frame, APR:GetThemeRadius(radius, scope)))
    else
        if radius then frame.aprCornerSpec = nil end
        if radius and frame.aprRoundedFill then
            frame.aprRoundedFill.enabled = false
            for _, piece in ipairs(frame.aprRoundedFill.pieces) do piece:Hide() end
        end
        frame:SetBackdrop({bgFile = white, edgeFile = border and white or nil, edgeSize = border and 1 or nil})
    end
    local color = APR:GetThemeColor(role or "background", scope)
    frame:SetBackdropColor(color[1], color[2], color[3], frame.collapsed and 0 or color[4])
    frame:SetBackdropBorderColor(unpack(APR:GetThemeColor("border", scope)))
    modernPanels[frame] = {scope = scope, role = role or "background", border = border, radius = radius}
end

-- Draw inside the existing hit area; actions, anchors and protected attributes stay untouched.
local function ModernAction(button, kind, options, scope)
    if kind == "resize" and options.bottomRightResize then
        local scroll = options.scrollFrame
        local arrow = scroll and scroll.ScrollBar and scroll.ScrollBar.ScrollDownButton
        button:ClearAllPoints()
        if arrow then
            button:SetPoint("RIGHT", arrow, "LEFT", -2, 0)
        else
            button:SetPoint("BOTTOMRIGHT", button:GetParent(), "BOTTOMRIGHT", -22, 2)
        end
        -- The grip shares the arrow's row; no empty footer needs to be reserved.
        if scroll then
            scroll:SetPoint("BOTTOMRIGHT", scroll:GetParent(), "BOTTOMRIGHT", -22, 0)
        end
    end
    local look = modernButtons[button]
    if not look then
        look = {kind = kind, options = options, scope = scope}
        modernButtons[button] = look
        for _, state in ipairs({"Normal", "Pushed", "Highlight", "Disabled"}) do
            local texture = button["Get" .. state .. "Texture"] and button["Get" .. state .. "Texture"](button)
            if texture then texture:SetAlpha(0) end
        end
        look.hover = button:CreateTexture(nil, "HIGHLIGHT")
        look.hover:SetAllPoints()
        look.host = CreateFrame("Frame", nil, button)
        look.host:SetAllPoints()
        look.host:EnableMouse(false)
        if kind == "settings" or kind == "arrow" or kind == "close" or kind == "resize" or options.close then
            look.icon = look.host:CreateTexture(nil, "ARTWORK")
            look.icon:SetSize(16, 16); look.icon:SetPoint("CENTER")
            if kind == "settings" then
                look.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
                look.icon:SetDesaturated(true)
            else
                local name = kind == "arrow" and "up" or kind == "resize" and "resize" or "close"
                look.icon:SetTexture("Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\" .. name .. ".tga")
                if kind == "arrow" then
                    look.icon:SetRotation(({left = math.pi / 2, right = -math.pi / 2, down = math.pi})[options.direction] or 0)
                end
            end
        else
            look.label = look.host:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            look.label:SetPoint("CENTER")
        end
        local function update()
            local collapsed = options.parent and options.parent.collapsed
            if look.label then
                look.label:SetText(collapsed and "+" or "-")
            end
            look.host:SetAlpha(button.IsEnabled and not button:IsEnabled() and 0.35 or 1)
            if options.parent and options.parent.SetBackdropColor and kind == "headerButton" then
                local color = options.parent.aprExpandedPanelColor or APR:GetThemeColor("background", scope)
                APR:SetPanelColor(options.parent, collapsed and {0, 0, 0, 0} or color)
            end
        end
        look.update = update
        button:HookScript("OnClick", update)
        button:HookScript("OnEnable", update)
        button:HookScript("OnDisable", update)
    end
    APR:RegisterThemeRegion(look.hover, "accent", 0.12)
    local accent = APR:GetThemeColor("accent", scope)
    if look.icon then look.icon:SetVertexColor(unpack(accent)) end
    if look.label then
        APR:RegisterFontString(look.label, scope or "general", {role = "accent", sizeDelta = 6})
    end
    look.update()
end

function APR:ApplyModernTheme(frame, kind, options, scope)
    if kind == "flatButton" then return end
    if kind == "header" then
        modernHeaders[frame] = {options = options, scope = scope}
        if frame.Background then frame.Background:SetAlpha(0) end
        local chrome = frame.aprModernHeader
        if not chrome then
            chrome = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            chrome:SetAllPoints(); chrome:EnableMouse(false)
            chrome:SetFrameLevel(frame:GetFrameLevel())
            frame.aprModernHeader = chrome
            chrome.aprGameplayCorners = true
            chrome.line = chrome:CreateTexture(nil, "OVERLAY")
            chrome.line:SetPoint("TOPLEFT"); chrome.line:SetPoint("TOPRIGHT"); chrome.line:SetHeight(1)
            chrome.marker = chrome:CreateTexture(nil, "OVERLAY")
            chrome.marker:SetPoint("TOPLEFT", 0, -4); chrome.marker:SetPoint("BOTTOMLEFT", 0, 4); chrome.marker:SetWidth(2)
            local parent = frame:GetParent()
            if parent then
                local function matchWidth()
                    if not InCombatLockdown() and math.abs(frame:GetWidth() - parent:GetWidth()) > 0.01 then
                        frame:SetWidth(parent:GetWidth())
                    end
                end
                parent:HookScript("OnSizeChanged", matchWidth)
                frame:HookScript("OnShow", matchWidth)
                matchWidth()
            end
        end
        if scope then
            self:ApplyNativeTheme(chrome, "panel", {roundedHeader = true, scope = scope})
            local radius = GameplayCorners(frame, self:GetThemeRadius(8, scope), "top")
            chrome.line:ClearAllPoints()
            chrome.line:SetPoint("TOPLEFT", radius, 0); chrome.line:SetPoint("TOPRIGHT", -radius, 0)
            chrome.marker:ClearAllPoints()
            chrome.marker:SetPoint("TOPLEFT", 0, -radius); chrome.marker:SetPoint("BOTTOMLEFT", 0, 0)
        else
            FlatPanel(chrome, scope, "surface", false)
        end
        local provider = self:GetSkinProviderName(scope)
        local ellesmereTracker = provider == "EllesmereUI" and gameplayRoots[scope] ~= nil
        if ellesmereTracker then
            -- EUI tracker headers carry an accent underline below their own translucent fill.
            chrome.line:ClearAllPoints()
            chrome.line:SetPoint("BOTTOMLEFT", 7, 0)
            chrome.line:SetPoint("BOTTOMRIGHT", -1, 0)
            chrome.line:SetHeight(1 / math.max(0.01, chrome:GetEffectiveScale()))
        end
        self:RegisterThemeRegion(chrome.line, ellesmereTracker and "accent" or provider and "border" or "accent",
            provider and 1 or 0.65)
        self:RegisterThemeRegion(chrome.marker, "accent", 1)
        chrome.marker:SetShown(not provider)
    elseif kind == "headerButton" or kind == "settings" or kind == "arrow" or kind == "close" or kind == "resize" then
        ModernAction(frame, kind, options, scope)
    elseif kind == "icon" then
        -- Preserve the secure button; only crop the artwork's baked bevel.
        if options.texture then options.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
    elseif kind == "scrollbar" then
        if self.UI then self.UI:StyleScrollBar(frame) end
    elseif kind == "statusbar" then
        frame:SetStatusBarTexture(white)
        FlatPanel(frame, scope, "surface", false)
    elseif kind == "button" then
        local chrome = frame.aprModernButton
        if not chrome then
            -- Legacy UIPanelButtonTemplates have no backdrop mixin. Keep their label and hit area.
            for _, state in ipairs({"Normal", "Pushed", "Highlight", "Disabled"}) do
                local texture = frame["Get" .. state .. "Texture"] and frame["Get" .. state .. "Texture"](frame)
                if texture then texture:SetAlpha(0) end
            end
            for _, key in ipairs({"Left", "Right", "Middle"}) do
                if frame[key] then frame[key]:SetAlpha(0) end
            end
            chrome = frame.SetBackdrop and frame or CreateFrame("Frame", nil, frame, "BackdropTemplate")
            if chrome ~= frame then
                chrome:SetAllPoints(); chrome:EnableMouse(false); chrome:SetFrameLevel(frame:GetFrameLevel())
            end
            frame.aprModernButton = chrome
            frame.aprModernHover = frame:CreateTexture(nil, "HIGHLIGHT")
            frame.aprModernHover:SetAllPoints()
        end
        FlatPanel(chrome, scope, "surface", true, 4)
        self:RegisterThemeRegion(frame.aprModernHover, "accent", 0.12)
        local label = frame.GetFontString and frame:GetFontString()
        if label and not (self.textStyleRegistry and self.textStyleRegistry[label]) then
            self:RegisterFontString(label, scope or "general", {role = "base"})
        end
    elseif frame.SetBackdrop then
        local row = kind == "row" or kind == "divider" or
            (kind == "panel" and (scope == "currentStep" or scope == "fillers"))
        FlatPanel(frame, scope, (kind == "button" or kind == "editbox") and "surface" or "background", not row,
            not row and kind == "panel" and 8 or nil)
        if frame.aprPanelColor then self:SetPanelColor(frame, frame.aprPanelColor) end
        if (kind == "divider" or frame.rowKind == "divider") and frame.dividerLine then
            local provider = self:GetSkinProviderName(scope)
            self:RegisterThemeRegion(frame.dividerLine, provider and "border" or "accent", provider and 1 or 0.25, true)
        end
    end
end

function APR:RefreshModernTheme()
    if InCombatLockdown() then return end
    for frame, entry in pairs(modernPanels) do
        FlatPanel(frame, entry.scope, entry.role, entry.border, entry.radius)
        if frame.aprPanelColor then self:SetPanelColor(frame, frame.aprPanelColor) end
    end
    for button, entry in pairs(modernButtons) do self:ApplyModernTheme(button, entry.kind, entry.options, entry.scope) end
end

local chromeRoot = "Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\"

-- Backdrop's center is rectangular. Six non-overlapping fill pieces complete its
-- rounded ends, leaving the outer corners transparent instead of leaking a square.
RoundedBackdrop = function(frame, radius, corners)
    frame.aprCornerSpec = radius > 8 and {radius = radius, corners = corners} or nil
    if radius > 8 then
        local width, height = frame:GetSize()
        if width > 0 and height > 0 then
            radius = math.min(radius, math.floor(math.min(width / 2, height / (corners and 1 or 2))))
        end
        if not frame.aprCornerBoundsHooked then
            frame.aprCornerBoundsHooked = true
            frame:HookScript("OnSizeChanged", function()
                local spec = frame.aprCornerSpec
                if not spec or InCombatLockdown() then return end
                local color = {frame:GetBackdropColor()}
                local border = frame.GetBackdropBorderColor and {frame:GetBackdropBorderColor()}
                RoundedBackdrop(frame, spec.radius, spec.corners)
                frame:SetBackdropColor(unpack(color))
                if border then frame:SetBackdropBorderColor(unpack(border)) end
            end)
        end
    end
    local fill = frame.aprRoundedFill
    if radius == 0 then
        if fill then
            fill.enabled = false
            for _, piece in ipairs(fill.pieces) do piece:Hide() end
        end
        frame:SetBackdrop({bgFile = white, edgeFile = white, edgeSize = 1})
        return
    end
    if not fill then
        fill = {pieces = {}}
        frame.aprRoundedFill = fill
        for index = 1, 6 do
            local texture = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
            texture:SetTexture(index <= 4 and chromeRoot .. "rounded-fill.tga" or "Interface\\Buttons\\WHITE8X8")
            texture:SetSnapToPixelGrid(false)
            texture:SetTexelSnappingBias(0)
            fill.pieces[index] = texture
        end
        hooksecurefunc(frame, "SetBackdropColor", function(_, r, g, b, a)
            if fill.enabled then
                for _, piece in ipairs(fill.pieces) do piece:SetVertexColor(r, g, b, a or 1) end
            end
        end)
    end
    fill.enabled = true
    fill.topRounded, fill.bottomRounded = corners ~= "bottom", corners ~= "top"
    for index, corner in ipairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}) do
        local piece = fill.pieces[index]
        piece:ClearAllPoints(); piece:SetPoint(corner); piece:SetSize(radius, radius)
        local right, bottom = index % 2 == 0, index > 2
        piece:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
        piece:SetShown(bottom and fill.bottomRounded or (not bottom and fill.topRounded))
    end
    for index, side in ipairs({"TOP", "BOTTOM"}) do
        local piece = fill.pieces[index + 4]
        piece:ClearAllPoints()
        piece:SetPoint(side .. "LEFT", radius, 0); piece:SetPoint(side .. "RIGHT", -radius, 0)
        piece:SetHeight(radius)
        piece:SetShown(index == 1 and fill.topRounded or (index == 2 and fill.bottomRounded))
    end
    local suffix = corners and (corners .. "-") or ""
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = chromeRoot .. "rounded-border-" .. suffix .. radius .. ".tga",
        edgeSize = radius, insets = {left = 0, right = 0,
            top = fill.topRounded and radius or 0, bottom = fill.bottomRounded and radius or 0}})
end

-- Preview-owned frames bypass the persistent skin/font registries and cannot recolor the live UI.
function APR:RenderThemePreviewPanel(frame, theme, radius, corners, role)
    RoundedBackdrop(frame, radius, corners)
    frame:SetBackdropColor(unpack(theme[role or "background"]))
    frame:SetBackdropBorderColor(unpack(theme.border))
end

-- Late skin registration must also retire the native corner fills before the provider adds its chrome.
function APR:RestoreNativeTheme(frame)
    frame.aprCornerSpec = nil
    themeSurfaces[frame] = nil
    if frame.aprRoundedFill then
        frame.aprRoundedFill.enabled = false
        for _, piece in ipairs(frame.aprRoundedFill.pieces) do piece:Hide() end
        frame:SetBackdrop(nil)
    end
end

-- Opt-in surfaces leave gameplay panel colors intact; external providers take precedence.
function APR:ApplyNativeTheme(frame, kind, options)
    local scope = options.scope or self:GetSkinScope(frame)
    local theme, name = self:GetTheme(scope)
    local modern = (theme.style or name) == "modern"
    if modern and options.roundedHeader then
        RoundedBackdrop(frame, GameplayCorners(frame, self:GetThemeRadius(8, scope), "top"))
        themeSurfaces[frame] = {kind = kind, options = options}
        -- Gameplay headers sit above their parent body, so they need their own fill.
        frame:SetBackdropColor(unpack(self:GetThemeColor("surface", scope)))
        frame:SetBackdropBorderColor(unpack(self:GetThemeColor("border", scope)))
        return
    end
    if modern and options.roundedGameplay then
        RoundedBackdrop(frame, GameplayCorners(frame, self:GetThemeRadius(8, scope), "bottom"))
        themeSurfaces[frame] = {kind = kind, options = options}
        self:SetPanelColor(frame, frame.aprPanelColor or theme.background)
        return
    end
    if modern and not options.themeSurface then self:ApplyModernTheme(frame, kind, options, scope); return end
    if kind == "scrollbar" and options.compact then self.UI:StyleScrollBar(frame); return end
    if not options.themeSurface or not frame.SetBackdrop then return end
    if options.nativeWoW and not modern then
        self:RestoreNativeTheme(frame)
        themeSurfaces[frame] = {kind = kind, options = options}
        if kind == "button" then
            -- UIPanelButtonTemplate supplies Blizzard's red button and bevel.
            frame:SetBackdrop(nil)
            for texture, alpha in pairs(frame.aprWoWButtonArt or {}) do texture:SetAlpha(alpha) end
        else
            frame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32, edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}})
            frame:SetBackdropColor(1, 1, 1, 1)
            frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        end
        return
    end
    if options.nativeWoW and kind == "button" then
        frame.aprWoWButtonArt = frame.aprWoWButtonArt or {}
        local function hide(texture)
            if not texture then return end
            if frame.aprWoWButtonArt[texture] == nil then
                frame.aprWoWButtonArt[texture] = texture:GetAlpha()
            end
            texture:SetAlpha(0)
        end
        for _, key in ipairs({"Left", "Middle", "Right"}) do
            hide(frame[key])
        end
        for _, state in ipairs({"Normal", "Pushed", "Highlight", "Disabled"}) do
            local texture = frame["Get" .. state .. "Texture"] and frame["Get" .. state .. "Texture"](frame)
            hide(texture)
        end
    end
    local radius = kind == "window" and 8 or kind == "borderedPanel" and 6 or 4
    if modern then radius = self:GetThemeRadius(radius, scope) end
    if modern then RoundedBackdrop(frame, GameplayCorners(frame, radius)) else RoundedBackdrop(frame, radius) end
    themeSurfaces[frame] = {kind = kind, options = options}
    -- Opaque brown fills keep contrast predictable: tinting black marble cannot lift its shadows.
    if options.surface then
        local color = modern and (options.surface == "library" and theme.background or theme.surface)
            or (surfaces[options.surface] or surfaces.inset)
        frame:SetBackdropColor(color[1], color[2], color[3], 1)
        frame:SetBackdropBorderColor(unpack(theme.border))
        return
    end
    local inset = kind == "button" or kind == "row" or kind == "editbox"
    local color = inset and theme.surface or theme.background
    frame:SetBackdropColor(color[1], color[2], color[3], modern and 1 or color[4])
    frame:SetBackdropBorderColor(unpack(theme.border))
end
