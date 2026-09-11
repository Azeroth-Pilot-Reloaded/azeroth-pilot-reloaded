-- Public API: https://github.com/EllesmereGaming/EllesmereUI/blob/main/SKINNING_API.md
local EUI = _G.EllesmereUI
if not EUI or type(EUI.RegisterSkin) ~= "function" then return end

APR.EllesmereUISkin = APR:NewModule("EllesmereUISkin")
local module = APR.EllesmereUISkin
local skin
local headerTexts = setmetatable({}, { __mode = "k" })
local accents = setmetatable({}, { __mode = "k" })
local panelBackgrounds = setmetatable({}, { __mode = "k" })
local refreshPending = false

-- Semantic colors follow EllesmereUI's quest tracker (titles, objectives, completion).
-- Header accents and typography come from the user's live EUI theme.
local colors = {
    base = { 0.72, 0.72, 0.72, 1 },
    accent = { 1, 0.91, 0.47, 1 },
    warning = { 1, 0.91, 0.47, 1 },
    success = { 0.25, 1, 0.35, 1 },
    error = { 1, 0.3, 0.3, 1 },
    muted = { 0.5, 0.5, 0.5, 1 },
}

local function IsEnabled(candidate)
    candidate = candidate or skin
    if not candidate then return false end
    local profile = APR.settings and APR.settings.profile
    if profile and profile.ellesmereuiSkin == false then return false end
    if _G.ElvUI and (not profile or profile.elvuiSkin ~= false) then return false end
    return candidate.IsEnabled()
end

function module:GetFont()
    if IsEnabled() then return skin.GetFont() end
end

function module:ApplyFont(fontString)
    if IsEnabled() then skin.Font(fontString) end
end

function module:GetTextColor(role)
    if IsEnabled() then return colors[role or "base"] or colors.base end
end

function module:ApplyBarFill(bar)
    if not IsEnabled() then return false end
    skin.ApplyBarFill(bar)
    return true
end

function module:ApplyHeaderTextColor(fontString)
    if IsEnabled() and headerTexts[fontString] then fontString:SetTextColor(skin.GetAccentColor()) end
end

local function Accent(region, kind)
    kind = kind or "texture"
    accents[region] = kind
    local r, g, b = skin.GetAccentColor()
    if kind == "text" then region:SetTextColor(r, g, b)
    elseif kind == "icon" then region:SetVertexColor(r, g, b)
    else region:SetColorTexture(r, g, b, 1) end
end

local function StyleText(text)
    if not text then return end
    local registration = APR.textStyleRegistry and APR.textStyleRegistry[text]
    if registration then
        APR:ApplyTextStyle(text, registration.scope, registration.options)
    else
        skin.Font(text)
    end
end

local function StyleHeader(header)
    skin.Panel(header, { noBg = true, noBorder = true })
    if header.Text then
        headerTexts[header.Text] = true
        StyleText(header.Text)
        Accent(header.Text, "text")
    end
    for _, edge in ipairs({ "TOP", "BOTTOM" }) do
        local line = header:CreateTexture(nil, "OVERLAY")
        line:SetHeight(1)
        line:SetPoint(edge .. "LEFT", header, edge .. "LEFT")
        line:SetPoint(edge .. "RIGHT", header, edge .. "RIGHT")
        Accent(line)
    end
end

local function StyleHeaderButton(button, options)
    if options.close then skin.CloseButton(button); return end
    -- Keep the original atlas objects alive for APR's collapse handler.
    skin.FadeRegions(button)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    skin.Font(label)
    Accent(label, "text")
    local function UpdateGlyph()
        label:SetText(options.parent and options.parent.collapsed and "+" or "−")
        local background = options.parent and panelBackgrounds[options.parent]
        if background then background:SetShown(not options.parent.collapsed) end
    end
    UpdateGlyph()
    button:HookScript("OnClick", UpdateGlyph)
end

local function StyleContentPanel(frame)
    -- Paint behind images; never fade the image texture or its overlays.
    local chrome = CreateFrame("Frame", nil, frame)
    chrome:SetAllPoints(frame)
    chrome:SetFrameLevel(frame:GetFrameLevel())
    chrome:EnableMouse(false)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    skin.Panel(chrome)
    panelBackgrounds[frame] = chrome
    chrome:SetShown(not frame.collapsed)
end

local function RefreshTheme()
    if not IsEnabled() then return end
    if InCombatLockdown() then refreshPending = true; return end
    refreshPending = false
    for region, kind in pairs(accents) do
        Accent(region, kind)
        if kind == "text" then skin.Font(region) end
    end
    if APR.RefreshTextAppearance then APR:RefreshTextAppearance() end
end

EUI.RegisterSkin("APR", function(S)
    if not IsEnabled(S) then return end
    skin = S
    local function ApplySkin(frame, kind, options)
        if kind == "button" then
            S.Button(frame)
            StyleText(frame:GetFontString())
        elseif kind == "arrow" then
            local text = frame.GetFontString and frame:GetFontString()
            if text then text:SetText("") end
            if options.direction == "left" or options.direction == "right" then
                S.PageButton(frame, options.direction == "left" and "<" or ">")
            else
                S.Button(frame)
                local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("CENTER")
                label:SetText(options.direction == "up" and "▲" or "▼")
                frame:SetFontString(label)
                S.Font(label)
                S.StateButtonLabel(frame)
            end
        elseif kind == "scrollbar" then S.ScrollBar(frame)
        elseif kind == "close" then S.CloseButton(frame)
        elseif kind == "icon" then S.SquareIcon(options.texture, frame)
        elseif kind == "borderedPanel" or kind == "panel" then
            if options.preserveContent or options.preserveBackground then
                StyleContentPanel(frame)
            else
                S.Panel(frame)
            end
        elseif kind == "row" then S.Panel(frame, { noBg = true, noBorder = true })
        elseif kind == "divider" then
            S.Panel(frame, { noBg = true, noBorder = true })
            local line = frame:CreateTexture(nil, "OVERLAY")
            line:SetHeight(1)
            line:SetPoint("LEFT", frame, "LEFT", 12, 0)
            line:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
            Accent(line)
        elseif kind == "header" then StyleHeader(frame)
        elseif kind == "headerButton" then StyleHeaderButton(frame, options)
        elseif kind == "settings" then
            frame.APRNormalIcon = frame:GetNormalTexture()
            frame.APRPushedIcon = frame:GetPushedTexture()
            S.Button(frame, { "APRNormalIcon", "APRPushedIcon" })
            if frame.APRNormalIcon then Accent(frame.APRNormalIcon, "icon") end
            if frame.APRPushedIcon then Accent(frame.APRPushedIcon, "icon") end
        elseif kind == "editbox" then
            S.EditBox(frame)
            StyleText(frame)
        elseif kind == "statusbar" then S.ApplyBarFill(frame)
        end
    end
    if APR:RegisterSkinProvider("EllesmereUI", ApplySkin, IsEnabled) then
        APR:RegisterStaticSkinTargets()
        S.OnLooksChanged(RefreshTheme)
        RefreshTheme()
    else
        skin = nil
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    if refreshPending then RefreshTheme() end
end)
