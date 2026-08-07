local LSM = LibStub("LibSharedMedia-3.0")

APR.GLOBAL_TEXT_APPEARANCE_KEY = "globalTextAppearance"

APR.TEXT_APPEARANCE_SCOPES = {
    general = APR.GLOBAL_TEXT_APPEARANCE_KEY,
    currentStep = "currentStepTextAppearance",
    fillers = "currentStepTextAppearance",
    questOrderList = "questOrderListTextAppearance",
    arrow = "arrowTextAppearance",
    map = "mapTextAppearance",
    minimap = "mapTextAppearance",
    party = "partyTextAppearance",
    afk = "afkTextAppearance",
    heirloom = "heirloomTextAppearance",
}

local DEFAULT_COLORS = {
    color = { 1, 1, 1, 1 },
    accentColor = { 1, 209 / 255, 0, 1 },
    successColor = { 0, 1, 0, 1 },
    warningColor = { 1, 1, 0, 1 },
    errorColor = { 1, 0.2, 0.2, 1 },
    mutedColor = { 105 / 255, 105 / 255, 105 / 255, 1 },
}

local function CopyColor(color)
    return { color[1], color[2], color[3], color[4] or 1 }
end

function APR:CreateTextAppearanceDefaults(useGlobal, overrides)
    local defaults = {
        useGlobal = useGlobal == true,
        font = LSM:GetDefault("font") or "Friz Quadrata TT",
        size = 12,
        flags = "NONE",
        color = CopyColor(DEFAULT_COLORS.color),
    }

    if not useGlobal then
        defaults.accentColor = CopyColor(DEFAULT_COLORS.accentColor)
        defaults.successColor = CopyColor(DEFAULT_COLORS.successColor)
        defaults.warningColor = CopyColor(DEFAULT_COLORS.warningColor)
        defaults.errorColor = CopyColor(DEFAULT_COLORS.errorColor)
        defaults.mutedColor = CopyColor(DEFAULT_COLORS.mutedColor)
    end

    for key, value in pairs(overrides or {}) do
        defaults[key] = type(value) == "table" and CopyColor(value) or value
    end
    return defaults
end

APR.textStyleRegistry = APR.textStyleRegistry or setmetatable({}, { __mode = "k" })

local function GetProfile()
    return APR.GetSettingsProfile and APR:GetSettingsProfile() or
        (APR.settings and APR.settings.profile)
end

local function GetAppearance(scope)
    local profile = GetProfile()
    local general = profile and profile[APR.GLOBAL_TEXT_APPEARANCE_KEY] or
        APR:CreateTextAppearanceDefaults(false)
    if not scope or scope == "general" then
        return general, general
    end

    local profileKey = APR.TEXT_APPEARANCE_SCOPES[scope]
    local scoped = profile and profileKey and profile[profileKey]
    return scoped or { useGlobal = true }, general
end

local function GetTypography(scope)
    local scoped, general = GetAppearance(scope)
    if scope ~= "general" and scoped.useGlobal ~= false then
        return general
    end
    return scoped
end

local function ResolveFont(fontName)
    local fallback = LSM:Fetch("font", LSM:GetDefault("font"))
    if not fallback and GameFontNormal and GameFontNormal.GetFont then
        fallback = GameFontNormal:GetFont()
    end
    return LSM:Fetch("font", fontName, true) or fallback or "Fonts\\FRIZQT__.TTF"
end

local VALID_FONT_FLAGS = {
    [""] = true,
    ["OUTLINE"] = true,
    ["THICKOUTLINE"] = true,
    ["MONOCHROME"] = true,
    ["MONOCHROME,OUTLINE"] = true,
}

local function NormalizeFontFlags(flags)
    if type(flags) ~= "string" then return "" end

    flags = flags:upper():gsub("%s+", "")
    if flags == "NONE" then
        return ""
    end
    return VALID_FONT_FLAGS[flags] and flags or ""
end

local ROLE_KEYS = {
    base = "color",
    accent = "accentColor",
    success = "successColor",
    warning = "warningColor",
    error = "errorColor",
    muted = "mutedColor",
}

function APR:GetTextColor(scope, role)
    local scoped, general = GetAppearance(scope)
    local key = ROLE_KEYS[role or "base"] or "color"

    if scope ~= "general" and scoped[key] then
        return scoped[key]
    end
    return general[key] or DEFAULT_COLORS[key] or DEFAULT_COLORS.color
end

function APR:GetTextColorHex(scope, role)
    local color = self:GetTextColor(scope, role)
    local r = math.floor(math.max(0, math.min(1, color[1] or 1)) * 255 + 0.5)
    local g = math.floor(math.max(0, math.min(1, color[2] or 1)) * 255 + 0.5)
    local b = math.floor(math.max(0, math.min(1, color[3] or 1)) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

function APR:WrapTextWithAppearanceColor(text, scope, role)
    return self:WrapTextInColorCode(text, self:GetTextColorHex(scope, role))
end

local function RestoreTooltipTextStyles(tooltip)
    for _, original in ipairs(tooltip._aprTooltipTextOriginals or {}) do
        APR:UnregisterFontString(original.region)
        if original.font and original.size then
            original.region:SetFont(original.font, original.size, NormalizeFontFlags(original.flags))
        end
        if original.color and original.region.SetTextColor then
            original.region:SetTextColor(unpack(original.color))
        end
    end
    tooltip._aprTooltipTextOriginals = nil
    tooltip._aprTooltipTextLookup = nil
end

local function StyleTooltipRegion(tooltip, region, scope, role)
    if not tooltip or not region or not region.GetFont then return end

    tooltip._aprTooltipTextOriginals = tooltip._aprTooltipTextOriginals or {}
    tooltip._aprTooltipTextLookup = tooltip._aprTooltipTextLookup or {}
    if not tooltip._aprTooltipTextLookup[region] then
        local font, size, flags = region:GetFont()
        local r, g, b, a = region:GetTextColor()
        table.insert(tooltip._aprTooltipTextOriginals, {
            region = region,
            font = font,
            size = size,
            flags = flags,
            color = { r, g, b, a },
        })
        tooltip._aprTooltipTextLookup[region] = true
    end

    APR:RegisterFontString(region, scope or "general", { role = role or "base" })

    if tooltip._aprTooltipTextHooked then return end
    tooltip._aprTooltipTextHooked = true
    tooltip:HookScript("OnHide", RestoreTooltipTextStyles)
    if not tooltip.HasScript or tooltip:HasScript("OnTooltipCleared") then
        tooltip:HookScript("OnTooltipCleared", RestoreTooltipTextStyles)
    end
end

local function GetTooltipFontString(tooltip, side, line)
    local name = tooltip and tooltip.GetName and tooltip:GetName()
    if not name then return nil end
    return _G[name .. "Text" .. side .. tostring(line)]
end

function APR:AddTooltipLine(tooltip, text, scope, role, wrap)
    if not tooltip then return end
    local color = self:GetTextColor(scope or "general", role or "base")
    tooltip:AddLine(text, color[1], color[2], color[3], wrap)
    StyleTooltipRegion(tooltip, GetTooltipFontString(tooltip, "Left", tooltip:NumLines()), scope, role)
end

function APR:SetTooltipText(tooltip, text, scope, role)
    if not tooltip then return end
    local color = self:GetTextColor(scope or "general", role or "base")
    tooltip:SetText(text, color[1], color[2], color[3])
    StyleTooltipRegion(tooltip, GetTooltipFontString(tooltip, "Left", 1), scope, role)
end

function APR:AddTooltipDoubleLine(tooltip, leftText, rightText, scope, leftRole, rightRole)
    if not tooltip then return end
    local left = self:GetTextColor(scope or "general", leftRole or "muted")
    local right = self:GetTextColor(scope or "general", rightRole or "base")
    tooltip:AddDoubleLine(leftText, rightText, left[1], left[2], left[3], right[1], right[2], right[3])
    local line = tooltip:NumLines()
    StyleTooltipRegion(tooltip, GetTooltipFontString(tooltip, "Left", line), scope, leftRole)
    StyleTooltipRegion(tooltip, GetTooltipFontString(tooltip, "Right", line), scope, rightRole)
end

function APR:ResolveTextColorRole(hexColor, fallbackRole)
    local value = tostring(hexColor or ""):lower():gsub("^#", ""):gsub("^|c", "")
    if #value == 8 then
        value = value:sub(3)
    end
    if value == "ff0000" or value == "ff3333" or value == "ff6060" or value == "e0000f" then
        return "error"
    end
    if value == "00ff00" or value == "50c878" then
        return "success"
    end
    if value == "ffff00" or value == "ffd100" or value == "eda55f" or value == "ff8800" or
        value == "ecc00f" then
        return "warning"
    end
    if value == "696969" or value == "999999" or value == "808080" then
        return "muted"
    end
    if value == "ffffff" or value == "f1f1f1" then
        return "base"
    end
    return fallbackRole or "accent"
end

function APR:ApplyTextStyle(fontString, scope, options)
    if not fontString or not fontString.SetFont then return end
    options = options or {}

    local typography = GetTypography(scope)
    local size = tonumber(typography.size) or 12
    if options.sizeScaleProfileKey then
        local profile = GetProfile()
        size = size * (tonumber(profile and profile[options.sizeScaleProfileKey]) or 1)
    end
    size = math.max(6, size + (options.sizeDelta or 0))

    local fontFlags = NormalizeFontFlags(typography.flags)
    local applied = fontString:SetFont(ResolveFont(typography.font), size, fontFlags)
    if not applied then
        fontString:SetFont(ResolveFont(nil), size, fontFlags)
    end

    if fontString.SetTextColor and not options.preserveColor then
        local color
        if options.colorProfileKey then
            local profile = GetProfile()
            color = profile and profile[options.colorProfileKey]
        end
        color = color or self:GetTextColor(scope, options.role)
        fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end

    if options.onApplied then
        options.onApplied(fontString)
    end
end

function APR:RegisterFontString(fontString, scope, options)
    if not fontString then return fontString end
    self.textStyleRegistry[fontString] = {
        scope = scope or "general",
        options = options or {},
    }
    self:ApplyTextStyle(fontString, scope or "general", options)
    return fontString
end

function APR:RegisterButtonText(button, scope, options)
    if not button then return end
    local fontString = button.Text or (button.GetFontString and button:GetFontString())
    return self:RegisterFontString(fontString, scope, options)
end

function APR:UnregisterFontString(fontString)
    self.textStyleRegistry[fontString] = nil
end

function APR:StyleStaticPopup(popup)
    if not popup then return end

    local regions = {
        { popup.text,                                      { role = "base" } },
        { popup.button1 and popup.button1:GetFontString(), { role = "base" } },
        { popup.button2 and popup.button2:GetFontString(), { role = "base" } },
        { popup.button3 and popup.button3:GetFontString(), { role = "base" } },
        { popup.editBox,                                   { role = "base" } },
    }

    popup._aprTextOriginals = {}
    for _, entry in ipairs(regions) do
        local region, options = entry[1], entry[2]
        if region and region.GetFont then
            local font, size, flags = region:GetFont()
            local r, g, b, a
            if region.GetTextColor then
                r, g, b, a = region:GetTextColor()
            end
            table.insert(popup._aprTextOriginals, {
                region = region,
                font = font,
                size = size,
                flags = flags,
                color = r and { r, g, b, a } or nil,
            })
            self:RegisterFontString(region, "general", options)
        end
    end

    if popup._aprTextRestoreHooked then return end
    popup._aprTextRestoreHooked = true
    popup:HookScript("OnHide", function(frame)
        for _, original in ipairs(frame._aprTextOriginals or {}) do
            APR:UnregisterFontString(original.region)
            if original.font and original.size then
                original.region:SetFont(original.font, original.size, NormalizeFontFlags(original.flags))
            end
            if original.color and original.region.SetTextColor then
                original.region:SetTextColor(unpack(original.color))
            end
        end
        frame._aprTextOriginals = nil
    end)
end

function APR:SetFontStringRole(fontString, role)
    local registration = self.textStyleRegistry[fontString]
    if not registration then return end
    registration.options.role = role
    self:ApplyTextStyle(fontString, registration.scope, registration.options)
end

local function ScopeAffects(requestedScope, targetScope)
    if not requestedScope or requestedScope == "general" then
        return true
    end

    local requestedKey = APR.TEXT_APPEARANCE_SCOPES[requestedScope] or requestedScope
    local targetKey = APR.TEXT_APPEARANCE_SCOPES[targetScope] or targetScope
    return requestedKey == targetKey
end

function APR:ApplyAllTextStyles(scope)
    for fontString, registration in pairs(self.textStyleRegistry) do
        if ScopeAffects(scope, registration.scope) then
            self:ApplyTextStyle(fontString, registration.scope, registration.options)
        end
    end
end

function APR:RefreshTextAppearance(scope)
    self:ApplyAllTextStyles(scope)

    if ScopeAffects(scope, "currentStep") and self.currentStep and
        self.currentStep.RefreshTextLayout then
        self.currentStep:RefreshTextLayout()
    end
    if ScopeAffects(scope, "fillers") and self.fillersFrame and
        self.fillersFrame.RefreshTextLayout then
        self.fillersFrame:RefreshTextLayout()
    end
    if ScopeAffects(scope, "questOrderList") and self.questOrderList and
        self.questOrderList.UpdateFrameContents then
        self.questOrderList:UpdateFrameContents()
    end
    if ScopeAffects(scope, "party") and self.party and self.party.RefreshTextLayout then
        self.party:RefreshTextLayout()
    end
    if ScopeAffects(scope, "arrow") and self.Arrow and self.Arrow.UpdateTextAppearance then
        self.Arrow:UpdateTextAppearance()
    end
    if (ScopeAffects(scope, "map") or ScopeAffects(scope, "minimap")) and self.map then
        self.map:UpdateMapIconsStyle()
        self.map:UpdateMiniMapIconsStyle()
    end
    if (not scope or scope == "general") and self.changelog and self.changelog.SetChangeLog then
        self.changelog:SetChangeLog()
    end
    if (not scope or scope == "general") and self.RouteSelection and self.RouteSelection.UpdateTextAppearance then
        self.RouteSelection:UpdateTextAppearance()
    end
    if (not scope or scope == "general") and self.StatusFrame and self.updateStatusFrame then
        self:updateStatusFrame()
    end
end
