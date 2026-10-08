-- Native APR palettes use shared Blizzard primitives, so every theme works on both clients.
-- External skin providers remain authoritative when enabled; no third-party artwork is bundled.

APR.Themes = {
    wow = { label = "THEME_WOW", background = { 0.08, 0.065, 0.045, 0.96 }, surface = { 0.16, 0.13, 0.09, 1 },
        border = { 0.53, 0.43, 0.24, 1 }, accent = { 1, 0.82, 0.28, 1 }, base = { 0.96, 0.94, 0.88, 1 },
        muted = { 0.7, 0.67, 0.59, 1 }, edgeSize = 12, edge = "Interface\\Tooltips\\UI-Tooltip-Border" },
    forever = { label = "THEME_FOREVER", background = { 0.095, 0.06, 0.045, 0.97 }, surface = { 0.22, 0.14, 0.09, 1 },
        border = { 0.66, 0.43, 0.22, 1 }, accent = { 1, 0.73, 0.34, 1 }, base = { 0.98, 0.9, 0.73, 1 },
        muted = { 0.76, 0.65, 0.48, 1 }, edgeSize = 2 },
    modern = { label = "THEME_MODERN", background = { 0.025, 0.052, 0.061, 0.98 }, surface = { 0.055, 0.105, 0.12, 1 },
        border = { 0.15, 0.3, 0.33, 1 }, accent = { 0.24, 0.78, 0.77, 1 }, base = { 0.91, 0.96, 0.96, 1 },
        muted = { 0.58, 0.71, 0.74, 1 }, edgeSize = 1 },
    contrast = { label = "THEME_CONTRAST", background = { 0.015, 0.015, 0.015, 1 }, surface = { 0.08, 0.08, 0.08, 1 },
        border = { 0.8, 0.8, 0.8, 1 }, accent = { 0.35, 1, 1, 1 }, base = { 1, 1, 1, 1 },
        muted = { 0.8, 0.8, 0.8, 1 }, edgeSize = 2 },
}
APR.ThemeOrder = { "wow", "forever", "modern", "contrast" }
local semantic = { success = { 0.38, 0.91, 0.53, 1 }, warning = { 1, 0.79, 0.31, 1 }, error = { 1, 0.4, 0.4, 1 } }

function APR:GetTheme()
    local profile = self.GetSettingsProfile and self:GetSettingsProfile() or self.settings and self.settings.profile
    local key = profile and profile.uiTheme or "wow"
    return self.Themes[key] or self.Themes.wow, self.Themes[key] and key or "wow"
end

function APR:GetThemeColor(role)
    local theme = self:GetTheme()
    return theme[role] or semantic[role] or theme.base
end

function APR:GetNativeThemeTextColor(role)
    local _, key = self:GetTheme()
    if key == "wow" or (self.GetSkinProviderName and self:GetSkinProviderName()) then return end
    return self:GetThemeColor(role == "title" and "accent" or role or "base")
end

function APR:GetPanelColor(fallback)
    local theme, key = self:GetTheme()
    if key == "wow" or (self.GetSkinProviderName and self:GetSkinProviderName()) then return fallback end
    -- Preserve transparent collapsed containers rather than reopening their background.
    if fallback and fallback[4] == 0 then return fallback end
    return theme.background
end

-- Retain the requested alpha/color so theme switches preserve collapsed frames and restore custom WoW colors.
function APR:SetPanelColor(frame, color)
    frame.aprPanelColor = color
    frame:SetBackdropColor(unpack(self:GetPanelColor(color)))
end

function APR:RestoreNativeTheme(frame)
    if frame.aprNativeOriginal then
        local original = frame.aprNativeOriginal
        frame:SetBackdrop(original.backdrop)
        if original.backdrop then
            frame:SetBackdropColor(unpack(frame.aprPanelColor or original.color))
            if original.border then frame:SetBackdropBorderColor(unpack(original.border)) end
        end
    end
    if frame.aprThemeSurface then frame.aprThemeSurface:Hide() end
    for texture, shown in pairs(frame.aprNativeArtwork or {}) do texture:SetShown(shown) end
end

function APR:ApplyNativeTheme(frame, kind, options)
    local theme, key = self:GetTheme()
    if key == "wow" and not options.themeSurface then
        self:RestoreNativeTheme(frame)
        return
    end
    if kind == "window" or kind == "panel" or kind == "borderedPanel" or kind == "row" or kind == "button" or kind == "editbox" then
        if not frame.SetBackdrop then return end
        if not options.themeSurface and not frame.aprNativeOriginal and frame.GetBackdrop then
            frame.aprNativeOriginal = {backdrop = frame:GetBackdrop(), color = {frame:GetBackdropColor()},
                border = frame.GetBackdropBorderColor and {frame:GetBackdropBorderColor()}}
        end
        if kind == "button" and not options.themeSurface then
            frame.aprNativeArtwork = frame.aprNativeArtwork or {}
            for _, name in ipairs({"Left", "Middle", "Right"}) do
                local texture = frame[name]
                if texture then
                    if frame.aprNativeArtwork[texture] == nil then frame.aprNativeArtwork[texture] = texture:IsShown() end
                    texture:Hide()
                end
            end
        end
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = theme.edge or "Interface\\Buttons\\WHITE8X8", edgeSize = theme.edgeSize,
            insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        local inset = kind == "button" or kind == "row" or kind == "editbox"
        local color = inset and theme.surface or theme.background
        if frame.aprPanelColor and frame.aprPanelColor[4] == 0 then color = frame.aprPanelColor end
        frame:SetBackdropColor(unpack(color))
        frame:SetBackdropBorderColor(unpack(theme.border))
    elseif kind == "header" and frame.Text then
        frame.aprNativeArtwork = frame.aprNativeArtwork or {}
        if frame.Background then
            if frame.aprNativeArtwork[frame.Background] == nil then frame.aprNativeArtwork[frame.Background] = frame.Background:IsShown() end
            frame.Background:Hide()
        end
        if not frame.aprThemeSurface then
            frame.aprThemeSurface = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame.aprThemeSurface:SetAllPoints()
            frame.aprThemeSurface:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        end
        frame.aprThemeSurface:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        frame.aprThemeSurface:SetBackdropColor(unpack(theme.surface))
        frame.aprThemeSurface:Show()
        frame.Text:SetTextColor(unpack(theme.accent))
    end
end

function APR:SetTheme(key)
    local profile = self:GetSettingsProfile()
    if not profile or not self.Themes[key] then return false end
    profile.uiTheme = key
    self:RefreshRegisteredSkins(true)
    if InCombatLockdown() then self.nativeTextRefreshPending = true; return true end
    if self.RefreshTextAppearance then self:RefreshTextAppearance() end
    return true
end
