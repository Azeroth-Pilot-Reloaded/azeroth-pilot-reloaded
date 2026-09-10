-- Public API: https://github.com/EllesmereGaming/EllesmereUI/blob/main/SKINNING_API.md
local EUI = _G.EllesmereUI
if not EUI or type(EUI.RegisterSkin) ~= "function" then return end

APR.EllesmereUISkin = APR:NewModule("EllesmereUISkin")

local function IsEnabled(skin)
    local profile = APR.settings and APR.settings.profile
    if profile and profile.ellesmereuiSkin == false then return false end
    -- Keep the existing ElvUI integration authoritative when both are installed.
    if _G.ElvUI and (not profile or profile.elvuiSkin ~= false) then return false end
    return skin.IsEnabled()
end

local function SkinIconButton(S, button)
    -- Keep the actual state textures: APR changes their atlases on collapse/expand.
    button.APRNormalIcon = button:GetNormalTexture()
    button.APRPushedIcon = button:GetPushedTexture()
    button.APRDisabledIcon = button:GetDisabledTexture()
    S.Button(button, { "APRNormalIcon", "APRPushedIcon", "APRDisabledIcon" })
end

EUI.RegisterSkin("APR", function(S)
    if not IsEnabled(S) then return end

    local function ApplySkin(frame, kind, options)
        if kind == "button" then
            S.Button(frame)
        elseif kind == "arrow" then
            if options.direction == "left" or options.direction == "right" then
                S.PageButton(frame, options.direction == "left" and "<" or ">")
            else
                -- The public API provides horizontal page arrows only.
                -- Give vertical route-order controls a themed button and a small glyph.
                S.Button(frame)
                local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("CENTER")
                label:SetText(options.direction == "up" and "▲" or "▼")
                frame:SetFontString(label)
                S.Font(label)
                S.StateButtonLabel(frame)
            end
        elseif kind == "scrollbar" then
            S.ScrollBar(frame)
        elseif kind == "close" then
            S.CloseButton(frame)
        elseif kind == "icon" then
            S.SquareIcon(options.texture, frame)
        elseif kind == "borderedPanel" then
            S.Panel(frame)
        elseif kind == "panel" and not options.preserveBackground then
            S.Shell(frame, { noTopBar = true })
        elseif kind == "header" then
            S.Panel(frame, { noBg = true, noBorder = true })
        elseif kind == "settings" or kind == "headerButton" then
            SkinIconButton(S, frame)
        elseif kind == "editbox" then
            S.EditBox(frame)
        end
    end

    if APR:RegisterSkinProvider("EllesmereUI", ApplySkin, function() return IsEnabled(S) end) then
        APR:RegisterStaticSkinTargets()
    end
end)
