-- Creates native status bars and reapplies APR-owned fill colors after theme texture changes.
-- The weak registry covers existing and future bars without extending their lifetime.

-- APR owns its bars for their entire lifetime; none enter another addon's pool.
local bars = setmetatable({}, { __mode = "k" })
local barScopes = setmetatable({}, { __mode = "k" })

APR.STATUS_BAR_COLOR_DEFAULTS = {
    afkBarColor = "orange",
    currentStepProgressBarColor = "blue",
}

-- Compare old profiles against the original defaults, independent of seasonal palettes.
local nativeDefaults = {
    currentStepProgressBarColor = { 0, 87 / 255, 183 / 255, 1 },
    afkBarColor = { 1, 164 / 255, 26 / 255, 1 },
}

function APR:GetStatusBarColor(colorKey, scope)
    local profile = self:GetSettingsProfile()
    local saved = profile and profile[colorKey]
    local color = saved or self.Color[self.STATUS_BAR_COLOR_DEFAULTS[colorKey]] or self.Color.blue
    local isDefault = not (profile and profile[colorKey .. "Custom"])
    if saved and nativeDefaults[colorKey] then
        for index = 1, 4 do
            if math.abs((saved[index] or 1) - nativeDefaults[colorKey][index]) > 0.000001 then
                isDefault = false
                break
            end
        end
    end
    if isDefault and self.GetThemeStyle and self:GetThemeStyle(scope) == "modern" then
        local accent = self:GetThemeColor("accent", scope)
        return { accent[1], accent[2], accent[3], color[4] or 1 }
    end
    return color
end

function APR:ApplyStatusBarColor(bar)
    local colorKey = bars[bar]
    if not colorKey then return false end
    local scope = (self.GetSkinScope and self:GetSkinScope(bar)) or barScopes[bar]
    local color = self:GetStatusBarColor(colorKey, scope)
    -- Skins supply the texture; explicit APR options (including Love) keep their fill color.
    if self.EllesmereUISkin and not InCombatLockdown() then
        self.EllesmereUISkin:ApplyBarFill(bar, self.GetSkinScope and self:GetSkinScope(bar))
    end
    bar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
    return true
end

function APR:RefreshStatusBarColors(colorKey)
    for bar, key in pairs(bars) do
        if not colorKey or key == colorKey then self:ApplyStatusBarColor(bar) end
    end
end

function APR:CreateStatusBar(parent, name, scope, colorKey)
    local bar = CreateFrame("StatusBar", name, parent, "BackdropTemplate")
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    bar:SetBackdropColor(0, 0, 0, 0.5)
    bar.Text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.Text:SetPoint("CENTER")
    self:RegisterFontString(bar.Text, scope or "currentStep", { role = "base" })
    bars[bar] = colorKey or "currentStepProgressBarColor"
    barScopes[bar] = scope or "currentStep"
    if self.RegisterSkinTarget then self:RegisterSkinTarget(bar, "statusbar") end
    self:ApplyStatusBarColor(bar)
    return bar
end
