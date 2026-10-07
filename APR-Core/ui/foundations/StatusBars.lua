-- Creates native status bars and reapplies APR-owned fill colors after theme texture changes.
-- The weak registry covers existing and future bars without extending their lifetime.

-- APR owns its bars for their entire lifetime; none enter another addon's pool.
local bars = setmetatable({}, { __mode = "k" })

APR.STATUS_BAR_COLOR_DEFAULTS = {
    afkBarColor = "orange",
    currentStepProgressBarColor = "blue",
}

function APR:ApplyStatusBarColor(bar)
    local colorKey = bars[bar]
    if not colorKey then return false end
    local profile = self:GetSettingsProfile()
    local color = (profile and profile[colorKey]) or self.Color[self.STATUS_BAR_COLOR_DEFAULTS[colorKey]]
        or self.Color.blue
    -- Skins supply the texture; APR's options (including Love) own the fill color.
    if self.EllesmereUISkin and not InCombatLockdown() then self.EllesmereUISkin:ApplyBarFill(bar) end
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
    if self.RegisterSkinTarget then self:RegisterSkinTarget(bar, "statusbar") end
    self:ApplyStatusBarColor(bar)
    return bar
end
