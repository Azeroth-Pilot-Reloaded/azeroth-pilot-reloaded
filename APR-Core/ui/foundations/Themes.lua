-- WoW styling for APR utility windows: warm dark surfaces and readable gold/ivory accents.
-- External skin providers remain authoritative when enabled.

APR.Themes = {
    wow = { background = { 0.08, 0.065, 0.045, 0.96 }, surface = { 0.16, 0.13, 0.09, 1 },
        border = { 0.53, 0.43, 0.24, 1 }, accent = { 1, 0.82, 0.28, 1 }, base = { 0.96, 0.94, 0.88, 1 },
        muted = { 0.7, 0.67, 0.59, 1 }, icon = { 0.94, 0.8, 0.55, 1 },
        selection = { 0.55, 0.42, 0.16, 1 }, stripe = { 0.28, 0.20, 0.12, 1 },
    },
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

local chromeRoot = "Interface\\AddOns\\APR\\APR-Core\\assets\\ui\\"

-- Backdrop's center is rectangular. Six non-overlapping fill pieces complete its
-- rounded ends, leaving the outer corners transparent instead of leaking a square.
local function RoundedBackdrop(frame, radius)
    local fill = frame.aprRoundedFill
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
    for index, corner in ipairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}) do
        local piece = fill.pieces[index]
        piece:ClearAllPoints(); piece:SetPoint(corner); piece:SetSize(radius, radius)
        local right, bottom = index % 2 == 0, index > 2
        piece:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
    end
    for index, side in ipairs({"TOP", "BOTTOM"}) do
        local piece = fill.pieces[index + 4]
        piece:ClearAllPoints()
        piece:SetPoint(side .. "LEFT", radius, 0); piece:SetPoint(side .. "RIGHT", -radius, 0)
        piece:SetHeight(radius)
    end
    for _, piece in ipairs(fill.pieces) do piece:Show() end
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = chromeRoot .. "rounded-border-" .. radius .. ".tga",
        edgeSize = radius, insets = {left = 0, right = 0, top = radius, bottom = radius}})
end

-- Late skin registration must also retire the native corner fills before the provider adds its chrome.
function APR:RestoreNativeTheme(frame)
    if frame.aprRoundedFill then
        frame.aprRoundedFill.enabled = false
        for _, piece in ipairs(frame.aprRoundedFill.pieces) do piece:Hide() end
        frame:SetBackdrop(nil)
    end
end

-- Opt-in surfaces leave gameplay panel colors intact; external providers take precedence.
function APR:ApplyNativeTheme(frame, kind, options)
    if kind == "scrollbar" and options.compact then self.UI:StyleScrollBar(frame); return end
    if not options.themeSurface or not frame.SetBackdrop then return end
    local theme = self.Themes.wow
    local radius = kind == "window" and 8 or kind == "borderedPanel" and 6 or 4
    RoundedBackdrop(frame, radius)
    -- Opaque brown fills keep contrast predictable: tinting black marble cannot lift its shadows.
    if options.surface then
        frame:SetBackdropColor(unpack(surfaces[options.surface] or surfaces.inset))
        frame:SetBackdropBorderColor(unpack(theme.border))
        return
    end
    local inset = kind == "button" or kind == "row" or kind == "editbox"
    frame:SetBackdropColor(unpack(inset and theme.surface or theme.background))
    frame:SetBackdropBorderColor(unpack(theme.border))
end
