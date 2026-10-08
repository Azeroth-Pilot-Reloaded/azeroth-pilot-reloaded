-- WoW styling for APR utility windows: warm dark surfaces and readable gold/ivory accents.
-- External skin providers remain authoritative when enabled.

APR.Themes = {
    wow = { background = { 0.08, 0.065, 0.045, 0.96 }, surface = { 0.16, 0.13, 0.09, 1 },
        border = { 0.53, 0.43, 0.24, 1 }, accent = { 1, 0.82, 0.28, 1 }, base = { 0.96, 0.94, 0.88, 1 },
        muted = { 0.7, 0.67, 0.59, 1 }, icon = { 0.94, 0.8, 0.55, 1 },
        selection = { 0.55, 0.42, 0.16, 1 }, stripe = { 0.28, 0.20, 0.12, 1 },
        edgeSize = 12, edge = "Interface\\Tooltips\\UI-Tooltip-Border" },
}
local semantic = { success = { 0.38, 0.91, 0.53, 1 }, warning = { 1, 0.79, 0.31, 1 }, error = { 1, 0.4, 0.4, 1 } }
-- Progress keeps the same meaning under every skin; the skin's accent still marks selection/actions.
local statusColors = { routeCompleted = { 0.38, 0.91, 0.53, 1 }, routeInProgress = { 0.40, 0.75, 1, 1 },
    routeNotStarted = { 0.90, 0.88, 0.82, 1 } }
local surfaces = { library = { 0.105, 0.075, 0.05, 1 }, inset = { 0.13, 0.095, 0.065, 1 },
    stone = { 0.17, 0.13, 0.09, 1 } }

-- Saved choices from the UI branch cannot enable an experimental theme here.
function APR:GetTheme() return self.Themes.wow, "wow" end

function APR:GetThemeStatusColor(role) return statusColors[role] end

function APR:GetThemeColor(role)
    if statusColors[role] then return statusColors[role] end
    local provider = self:GetSkinProviderName()
    local integration = provider == "ElvUI" and self.ElvUISkin or provider == "EllesmereUI" and self.EllesmereUISkin
    if integration and integration.GetThemeColor then
        local color = integration:GetThemeColor(role)
        if color then return color end
    end
    return self.Themes.wow[role] or semantic[role] or self.Themes.wow.base
end

-- Custom icons and row highlights follow the skin without rebuilding pooled controls.
-- Alpha remains per region so selected, alternating and disabled states survive a recolor.
local themeRegions = setmetatable({}, { __mode = "k" })
local function ApplyRegion(region, entry)
    local color = APR:GetThemeColor(entry.role)
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
end

-- Legacy panels retain their configured colors, including transparent collapsed frames.
function APR:SetPanelColor(frame, color)
    frame:SetBackdropColor(unpack(color))
end

-- Opt-in surfaces leave gameplay panel colors intact; external providers take precedence.
function APR:ApplyNativeTheme(frame, kind, options)
    if kind == "scrollbar" and options.compact then self.UI:StyleScrollBar(frame); return end
    if not options.themeSurface or not frame.SetBackdrop then return end
    local theme = self.Themes.wow
    -- Opaque brown fills keep contrast predictable: tinting black marble cannot lift its shadows.
    if options.surface then
        frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = theme.edge, edgeSize = 10,
            insets = {left = 3, right = 3, top = 3, bottom = 3}})
        frame:SetBackdropColor(unpack(surfaces[options.surface] or surfaces.inset))
        frame:SetBackdropBorderColor(unpack(theme.border))
        return
    end
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = theme.edge, edgeSize = theme.edgeSize,
        insets = {left = 2, right = 2, top = 2, bottom = 2}})
    local inset = kind == "button" or kind == "row" or kind == "editbox"
    frame:SetBackdropColor(unpack(inset and theme.surface or theme.background))
    frame:SetBackdropBorderColor(unpack(theme.border))
end
