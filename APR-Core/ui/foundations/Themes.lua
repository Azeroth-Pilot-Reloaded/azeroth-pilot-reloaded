-- WoW styling for APR diagnostic and performance controls, using shared Blizzard primitives.
-- External skin providers remain authoritative when enabled; no third-party artwork is bundled.

APR.Themes = {
    wow = { label = "THEME_WOW", background = { 0.08, 0.065, 0.045, 0.96 }, surface = { 0.16, 0.13, 0.09, 1 },
        border = { 0.53, 0.43, 0.24, 1 }, accent = { 1, 0.82, 0.28, 1 }, base = { 0.96, 0.94, 0.88, 1 },
        muted = { 0.7, 0.67, 0.59, 1 }, edgeSize = 12, edge = "Interface\\Tooltips\\UI-Tooltip-Border" },
}
local semantic = { success = { 0.38, 0.91, 0.53, 1 }, warning = { 1, 0.79, 0.31, 1 }, error = { 1, 0.4, 0.4, 1 } }

-- Saved choices from the UI branch cannot enable an experimental theme here.
function APR:GetTheme() return self.Themes.wow, "wow" end

function APR:GetThemeColor(role)
    return self.Themes.wow[role] or semantic[role] or self.Themes.wow.base
end

-- Legacy panels retain their configured colors, including transparent collapsed frames.
function APR:SetPanelColor(frame, color)
    frame:SetBackdropColor(unpack(color))
end

-- Only APR's diagnostic/performance controls opt into this surface; external providers take precedence.
function APR:ApplyNativeTheme(frame, kind, options)
    if not options.themeSurface or not frame.SetBackdrop then return end
    local theme = self.Themes.wow
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = theme.edge, edgeSize = theme.edgeSize,
        insets = {left = 2, right = 2, top = 2, bottom = 2}})
    local inset = kind == "button" or kind == "row" or kind == "editbox"
    frame:SetBackdropColor(unpack(inset and theme.surface or theme.background))
    frame:SetBackdropBorderColor(unpack(theme.border))
end
