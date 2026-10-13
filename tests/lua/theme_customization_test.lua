-- Preview edits must not leak into live colors, profiles, bars or providers before Apply.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/ThemeCustomization.lua")
function env.methods:SetVertexColor(...) self.vertex = {...} end
function env.methods:SetTextColor(...) self.textColor = {...} end
function env.methods:SetTexture(path) self.texture = path end
local profile, editor = APR.settings.profile, APR.ThemeCustomization
profile.uiTheme, profile.uiThemeCustomization = "modern", {}
local reloads, refreshes = 0, 0
function ReloadUI() reloads = reloads + 1 end
function APR:RefreshTextAppearance() refreshes = refreshes + 1 end
local body = APR.currentStep.contentBackdrop
APR:RegisterSkinTarget(body, "panel", {roundedGameplay = true})
local panel = CreateFrame("Frame", nil, _G.CurrentStepScreenPanel, "BackdropTemplate")
panel:SetSize(250, 80)
APR:RegisterSkinTarget(panel, "panel", {scope = "party"})
local utility = APR.UI:Panel(UIParent, "window")
utility:SetSize(640, 400)
local action = APR.UI:Button(utility, "Action", 160)
local defaultBar = APR:CreateStatusBar(CurrentStepScreenPanel)
profile.currentStepProgressBarColor = {0.8, 0.2, 0.1, 0.7}
profile.currentStepProgressBarColorCustom = true
local customBar = APR:CreateStatusBar(CurrentStepScreenPanel)
profile.currentStepProgressBarColor = {0, 87 / 255, 183 / 255, 1}
profile.currentStepProgressBarColorCustom = false
-- AFK is independent: its explicit color must survive theme publication.
profile.afkBarColor, profile.afkBarColorCustom = {0.8, 0.2, 0.1, 0.7}, true
customBar = APR:CreateStatusBar(UIParent, nil, "afk", "afkBarColor")

-- The preview is an actual widget using the same rounded renderer, not a screenshot.
local constructors = {}
local gui = {RegisterWidgetType = function(_, name, constructor) constructors[name] = constructor end,
    RegisterAsWidget = function(_, widget)
        function widget:SetWidth(width) self.frame:SetWidth(width); self:OnWidthSet(width) end
        function widget:SetHeight(height) self.frame:SetHeight(height) end
        return widget
    end}
editor:InstallPreviewWidget(gui)
local preview = constructors.APRThemePreview()
preview:OnAcquire()
local options = editor:GetOptions()
assert(not editor:IsDirty() and options.themeAccent.disabled() and options.themeApply.disabled())
local originalAccent, originalBackground = APR:GetThemeColor("accent")[2], body.backdropColor[2]
options.themeCustomColor.set(nil, true)
options.themeAccent.set(nil, 0.8, 0.2, 119 / 255)
options.themeRadius.set(nil, 12)
local r, g, b = options.themeAccent.get()
assert(editor:IsDirty() and r == 0.8 and g == 0.2 and b == 119 / 255)
assert(not options.themeAccentHex, "The native color picker already exposes the hexadecimal value")
assert(not options.themeDefaults, "Cancel is the only action for discarding theme edits")
assert(not profile.uiThemeCustomization.customColor and APR:GetThemeColor("accent")[2] == originalAccent
    and body.backdropColor[2] == originalBackground and defaultBar.color[2] == originalAccent,
    "Live settings and all existing widgets stay unchanged during draft editing")
assert(preview.preview.header.backdrop.edgeSize == 12 and preview.preview.body.backdrop.insets.top == 0
    and preview.preview.button.backdrop.edgeSize == 6 and preview.preview.bar.color[1] == 0.8,
    "Draft color and radius update the mini guide immediately, preserving its straight header/body join")
assert(preview.preview.title.textColor[1] == 0.8 and preview.preview.title.textColor[2] == 0.2,
    "The preview title uses the draft accent instead of the yellow GameFontNormal default")
editor:Apply()
assert(reloads == 0 and refreshes == 1 and not editor:IsDirty())
assert(body.backdrop.edgeSize == 12 and panel.backdrop.edgeSize == 12
    and utility.backdrop.edgeSize == 12 and action.backdrop.edgeSize == 6,
    "Applying reaches HUD, utility windows, anonymous panels and buttons")
assert(defaultBar.color[1] == 0.8 and customBar.color[1] == 0.8 and customBar.color[2] == 0.2 and customBar.color[4] == 0.7,
    "Default bars adopt the accent while explicitly colored bars keep their RGB and alpha")
assert(APR.Themes.modern.accent[1] == 0, "Custom accents never mutate the preset palettes")
assert(profile.uiThemeCustomization.color ~= editor:GetDraft().color)
editor:SetColor(0, 1, 0)
editor:Discard()
assert(editor:GetDraft().color[1] == 0.8 and not editor:IsDirty(), "Cancel restores the saved customization")
editor:Set("rounded", false)
assert(preview.preview.body.backdrop.edgeSize == 1 and body.backdrop.edgeSize == 12)
editor:Apply()
assert(body.backdrop.edgeSize == 1 and utility.backdrop.edgeSize == 1 and action.backdrop.edgeSize == 1
    and not body.aprRoundedFill.enabled, "Disabling rounding retires the corner fills everywhere")
editor:Set("rounded", true)
editor:Set("radius", 16)
env.setCombat(true)
assert(options.themeApply.disabled() and not editor:Apply() and profile.uiThemeCustomization.rounded == false,
    "Combat allows draft editing but cannot publish protected visual changes")
env.setCombat(false)
assert(editor:Apply() and body.backdrop.edgeSize == 16)
editor:SetTheme("violetModern")
assert(profile.uiTheme == "modern" and preview.preview.header.backdrop.edgeSize == 16)
editor:Apply()
assert(profile.uiTheme == "violetModern" and reloads == 0)
options.themeCustomColor.set(nil, false)
options.themeRadius.set(nil, 8)
assert(editor:GetDraft().customColor == false and editor:GetDraft().radius == 8 and profile.uiThemeCustomization.customColor)
editor:Apply()
assert(APR:GetThemeColor("accent")[1] == APR.Themes.violetModern.accent[1] and body.backdrop.edgeSize == 8)
editor:SetTheme("wow")
assert(not editor:IsModern() and options.themeRounded.disabled() and not preview.preview.body:IsShown())
editor:Apply()
assert(reloads == 1 and profile.uiTheme == "wow", "Changing to native artwork reloads only after Apply")
editor:SetTheme("ElvUI")
editor:Apply()
assert(reloads == 2 and profile.elvuiSkin and not profile.ellesmereuiSkin)
local fresh = {uiTheme = "modern", uiThemeCustomization = {customColor = true, color = {0.1, 0.3, 0.5, 1}, rounded = true, radius = 5}}
APR.settings.profile = fresh
assert(editor:GetDraft().radius == 5 and editor:GetDraft().color[3] == 0.5 and not editor:IsDirty(),
    "Changing the profile cannot apply a draft belonging to the previous one")
preview:OnRelease()
assert(not editor.previews[preview])
print("Theme customization: live isolated preview, Apply/Cancel, all surfaces, explicit bars, radius, profiles, providers and combat passed")
