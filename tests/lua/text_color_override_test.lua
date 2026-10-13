-- Exercise real settings callbacks and existing font strings across palette/provider refreshes.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local originalLibStub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then
        return {GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end}
    end
    return originalLibStub(name, ...)
end
function APR:ResolveUIFileAsset(path) return path end
function env.methods:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags; return true end
function env.methods:SetTextColor(...) self.textColor = {...} end
function env.methods:SetVertexColor(...) self.vertex = {...} end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
local profile = APR.settings.profile
profile.uiTheme = "modern"
profile.globalTextAppearance = APR:CreateTextAppearanceDefaults(false)
profile.currentStepTextAppearance = APR:CreateTextAppearanceDefaults(true, {accentColor = {1, 209 / 255, 0, 1}})
profile.questOrderListTextAppearance = APR:CreateTextAppearanceDefaults(true)
APR.settings.db = {defaults = {profile = {
    globalTextAppearance = APR:CreateTextAppearanceDefaults(false),
    currentStepTextAppearance = APR:CreateTextAppearanceDefaults(true, {accentColor = {1, 209 / 255, 0, 1}}),
    questOrderListTextAppearance = APR:CreateTextAppearanceDefaults(true),
}}}
local utils = APR.TextStyleUtils
local global = utils:CreateAppearanceOptions("globalTextAppearance", "general", 1, utils.FRAME_TEXT_COLORS).args
local current = utils:CreateAppearanceOptions("currentStepTextAppearance", "currentStep", 1, utils.FRAME_TEXT_COLORS, true).args
local quests = utils:CreateAppearanceOptions("questOrderListTextAppearance", "questOrderList", 1, utils.FRAME_TEXT_COLORS, true).args
local roles = {color = "base", accentColor = "accent", successColor = "success", warningColor = "warning",
    errorColor = "error", mutedColor = "muted"}
local function same(actual, expected, message)
    for index = 1, 4 do assert(math.abs((actual[index] or 1) - (expected[index] or 1)) < 0.00001, message) end
end
local fonts, guideFonts = {}, {}
for key, role in pairs(roles) do
    fonts[key] = APR.UI:Label(UIParent, "Settings", 12, role)
    guideFonts[key] = CurrentStepScreenPanel:CreateFontString()
    APR:RegisterFontString(guideFonts[key], "currentStep", {role = role, themeAccent = true})
    same({global[key].get()}, APR:GetTextColor("general", role), "Swatches display the effective palette")
end
same(fonts.accentColor.textColor, APR.Themes.modern.accent, "Untouched titles follow the Modern theme")
same(guideFonts.accentColor.textColor, APR.Themes.modern.accent, "Legacy gold defaults cannot override Modern")
local changes = {}
for key in pairs(roles) do
    changes[key] = {0.17, 0.36, 0.74, 0.45}
    global[key].set(nil, unpack(changes[key]))
    same(fonts[key].textColor, changes[key], "Global color callback must immediately recolor existing text: " .. key)
    same(guideFonts[key].textColor, changes[key], "Scoped default colors must inherit the global override: " .. key)
    same({global[key].get()}, changes[key], "Swatches retain the user's RGBA choice")
end
for _, name in ipairs({"wow", "wowModern", "modern", "graphiteModern", "emeraldModern", "violetModern", "redModern"}) do
    profile.uiTheme = name
    APR:RefreshRegisteredSkins(true)
    for key in pairs(roles) do
        same(fonts[key].textColor, changes[key], "Palette changes must preserve explicit text colors: " .. name)
        same(guideFonts[key].textColor, changes[key], "Guide text overrides survive palette changes")
    end
end
current.color.set(nil, 0.9, 0.2, 0.5, 0.6)
same(guideFonts.color.textColor, {0.9, 0.2, 0.5, 0.6}, "A per-frame override takes precedence")
same(fonts.color.textColor, changes.color, "A guide override cannot recolor unrelated UI")
same(APR:GetTextColor("fillers", "base"), {0.9, 0.2, 0.5, 0.6}, "Fillers share current-step text preferences")
assert(profile.currentStepTextAppearance.useGlobal, "Independent colors preserve typography inheritance")

-- Explicitly selecting the original WoW RGB still overrides Modern, including after a reload.
local defaultGold = APR.settings.db.defaults.profile.globalTextAppearance.accentColor
global.accentColor.set(nil, unpack(defaultGold))
dofile("APR-Core/ui/foundations/TextStyles.lua")
APR:ApplyAllTextStyles()
same(fonts.accentColor.textColor, defaultGold, "Choosing the default RGB must remain an explicit customization")
assert(profile.globalTextAppearance.colorOverrides.accentColor)
assert(not APR.settings.db.defaults.profile.globalTextAppearance.colorOverrides.accentColor,
    "Saved override flags never mutate AceDB defaults")

-- The active-step control remains meaningful even when Modern normally uses its accent for this row.
local questPanel = CreateFrame("Frame", "QuestOrderListPanel", UIParent)
local row = {indexFont = questPanel:CreateFontString(), titleFont = questPanel:CreateFontString(), questFonts = {}}
APR:RegisterFontString(row.indexFont, "questOrderList")
APR:RegisterFontString(row.titleFont, "questOrderList")
quests.warningColor.set(nil, 0.12, 0.48, 0.82, 0.7)
APR.questOrderListSupport:SetStepFrameState(row, "gray", true)
same(row.titleFont.textColor, {quests.warningColor.get()}, "Active-step swatch and actual row must agree")
APR.questOrderListSupport:SetStepFrameState(row, "green", false)
same(row.titleFont.textColor, changes.successColor, "Recycled completed rows use the success override")

-- Tracker/provider colors are defaults; explicit preferences apply only to APR's text.
APR.QuestTracker = {Style = function() return {font = "tracker.ttf", textColors = {base = {0.4, 0.5, 0.6, 1}}, accent = {0.7, 0.6, 0.5, 1}} end}
APR:RefreshTextAppearance()
same(guideFonts.color.textColor, {0.9, 0.2, 0.5, 0.6}, "Kaliel/Questie colors cannot discard explicit APR colors")
assert(guideFonts.color.font == "tracker.ttf", "Tracker typography is preserved")
APR.QuestTracker = nil
APR.EllesmereUISkin = {GetFont = function() return "eui.ttf" end, ApplyFont = function() end,
    GetTextColor = function() return {0.2, 0.3, 0.4, 1} end,
    ApplyHeaderTextColor = function(_, text) text:SetTextColor(0, 1, 0, 1) end}
APR:RefreshTextAppearance()
same(guideFonts.accentColor.textColor, defaultGold, "Ellesmere header styling cannot overwrite an explicit color")
assert(guideFonts.accentColor.font == "eui.ttf", "Ellesmere fonts remain integrated")
APR.EllesmereUISkin = nil

-- Existing saved colors work without the new flags; a new/default profile follows its theme.
profile.globalTextAppearance.colorOverrides = nil
profile.globalTextAppearance.errorColor = {0.3, 0.7, 0.8, 0.5}
same(APR:GetTextColor("general", "error"), profile.globalTextAppearance.errorColor, "Legacy custom colors are retained")
profile.currentStepTextAppearance.colorOverrides = nil
profile.currentStepTextAppearance.color = {0.25, 0.6, 0.2, 0.3}
same(APR:GetTextColor("currentStep", "base"), profile.currentStepTextAppearance.color, "Legacy per-frame colors are retained")
profile.globalTextAppearance = APR:CreateTextAppearanceDefaults(false)
profile.currentStepTextAppearance = APR:CreateTextAppearanceDefaults(true)
profile.questOrderListTextAppearance = APR:CreateTextAppearanceDefaults(true)
profile.uiTheme = "violetModern"
APR:RefreshTextAppearance()
same(fonts.accentColor.textColor, APR.Themes.violetModern.accent, "Reset preferences resume the palette's default colors")
same({quests.warningColor.get()}, APR.Themes.violetModern.accent, "The active-step swatch shows Modern's default accent")
APR.questOrderListSupport:SetStepFrameState(row, "gray", true)
same(row.titleFont.textColor, APR.Themes.violetModern.accent, "Untouched active rows keep the intended Modern color")

-- The mini guide reflects text overrides while its bar/chrome still preview the pending theme.
dofile("APR-Core/ui/foundations/ThemeCustomization.lua")
local constructors = {}
local gui = {RegisterWidgetType = function(_, name, constructor) constructors[name] = constructor end,
    RegisterAsWidget = function(_, widget)
        function widget:SetWidth(width) self.frame:SetWidth(width); self:OnWidthSet(width) end
        function widget:SetHeight(height) self.frame:SetHeight(height) end
        return widget
    end}
APR.ThemeCustomization:InstallPreviewWidget(gui)
global.color.set(nil, 0.2, 0.9, 0.6, 0.8)
global.accentColor.set(nil, 0.8, 0.3, 0.6, 0.7)
local preview = constructors.APRThemePreview()
preview:OnAcquire()
APR.ThemeCustomization:SetTheme("redModern")
same(preview.preview.caption.textColor, {0.8, 0.3, 0.6, 0.7}, "Preview titles reflect actual text overrides")
same(preview.preview.step.textColor, {0.2, 0.9, 0.6, 0.8}, "Preview body reflects actual text overrides")
same(preview.preview.bar.color, APR.Themes.redModern.accent, "Text colors do not replace bar/chrome theme colors")
assert(profile.uiTheme == "violetModern", "Previewing typography and a palette never publishes the draft")

-- Reset only the selected text section, clear explicit colors and refresh existing frames immediately.
global.size.set(nil, 22)
global.flags.set(nil, "OUTLINE")
current.useGlobal.set(nil, false)
current.size.set(nil, 28)
current.color.set(nil, 0.9, 0.2, 0.1, 0.3)
current.accentColor.set(nil, 0.7, 0.6, 0.2, 0.5)
current.resetTextAppearance.func()
assert(profile.currentStepTextAppearance.useGlobal and current.size.get() == 22,
    "A frame reset restores global typography inheritance")
assert(guideFonts.color.size == 22 and guideFonts.color.flags == "OUTLINE")
assert(not next(profile.currentStepTextAppearance.colorOverrides))
same(guideFonts.color.textColor, {global.color.get()}, "A frame reset resumes the global color")
assert(profile.currentStepTextAppearance ~= APR.settings.db.defaults.profile.currentStepTextAppearance
    and profile.currentStepTextAppearance.accentColor ~= APR.settings.db.defaults.profile.currentStepTextAppearance.accentColor,
    "Reset copies defaults rather than sharing mutable color tables")
assert(profile.globalTextAppearance.colorOverrides.color, "A frame reset cannot clear global customization")
current.warningColor.set(nil, 0.4, 0.7, 0.2, 0.6)
global.resetTextAppearance.func()
assert(global.font.get() == "Native" and global.size.get() == 12 and global.flags.get() == "NONE")
assert(not next(profile.globalTextAppearance.colorOverrides))
same(fonts.accentColor.textColor, APR.Themes.violetModern.accent, "Global reset restores the active palette's colors")
same(guideFonts.warningColor.textColor, {0.4, 0.7, 0.2, 0.6}, "Global reset preserves separate frame overrides")
same(preview.preview.caption.textColor, APR.Themes.redModern.accent, "Reset updates the active preview immediately")
assert(profile.uiTheme == "violetModern" and APR.ThemeCustomization:GetDraft().theme == "redModern",
    "Text reset preserves both the applied theme and any pending theme selection")

-- A section with no registered database defaults still has a complete reset.
local afk = utils:CreateAppearanceOptions("afkTextAppearance", "afk", 1, utils.BASE_TEXT_COLORS, true).args
profile.afkTextAppearance = {useGlobal = false, font = "Custom", size = 30, color = {0.3, 0.2, 0.1, 0.4}, colorOverrides = {color = true}}
afk.resetTextAppearance.func()
assert(profile.afkTextAppearance.useGlobal and profile.afkTextAppearance.size == 12
    and not next(profile.afkTextAppearance.colorOverrides), "The fallback restores inheritance and clears customization")
print("Text colors: effective swatches, six RGBA callbacks, all palettes, scope/global inheritance, explicit defaults, legacy settings and providers passed")
