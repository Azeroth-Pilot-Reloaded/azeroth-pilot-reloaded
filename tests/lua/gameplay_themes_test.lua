-- Native artwork, scoped provider selection, palette refresh and secure combat behavior.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local methods, profile = env.methods, APR.settings.profile
function methods:SetTexture(path) self.texture = path end
function methods:SetTexCoord(...) self.coords = {...} end
function methods:SetColorTexture(...) self.fill = {...} end
function methods:SetVertexColor(...) self.vertex = {...} end
function methods:SetTextColor(...) self.textColor = {...} end
function methods:SetAtlas(atlas) self.atlas = atlas end
function methods:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags; return true end
function methods:GetFont() return self.font or "native.ttf", self.size or 12, self.flags or "" end
local oldLibStub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then
        return {GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end}
    end
    return oldLibStub(name, ...)
end
function APR:ResolveUIFileAsset(path) return path end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
profile.uiTheme = "wow"

local panels = {}
for _, name in ipairs({"CurrentStepScreenPanel", "FillersScreenPanel", "QuestOrderListPanel", "BuffFrameScreen",
    "HeirloomPanel", "PartyScreenPanel", "CoordinateScreenPanel", "AfkFrameScreen"}) do
    local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    panel:SetPoint("CENTER", UIParent, "CENTER", 25, 30)
    panel:SetSize(250, 60)
    panel:SetBackdrop({bgFile = "Native background"})
    APR:SetPanelColor(panel, {0.2, 0.1, 0.3, 0.6})
    APR:RegisterSkinTarget(panel, "panel")
    assert(panel:GetBackdrop().bgFile == "Native background" and panel.backdropColor[1] == 0.2,
        "WoW must preserve the exact original gameplay backdrop and configured opacity")
    panels[#panels + 1] = panel
end
local header = CreateFrame("Frame", nil, CurrentStepScreenPanel)
header.Background = header:CreateTexture()
header.Background:SetTexture("Native header")
header.Text = header:CreateFontString()
APR:RegisterFontString(header.Text, "currentStep", {role = "accent"})
APR:RegisterSkinTarget(header, "header")
local button = CreateFrame("Button", nil, header)
button:SetSize(22, 22)
button:SetNormalTexture("Native collapse")
local clicks = 0
button:SetScript("OnClick", function()
    clicks = clicks + 1
    CurrentStepScreenPanel.collapsed = not CurrentStepScreenPanel.collapsed
end)
APR:RegisterSkinTarget(button, "headerButton", {parent = CurrentStepScreenPanel})
assert(not header.aprModernHeader and button:GetNormalTexture().alpha == nil,
    "WoW cannot add chrome or fade native controls")
local divider = CreateFrame("Frame", nil, CurrentStepScreenPanel)
divider.dividerLine = divider:CreateTexture()
divider.dividerLine:SetVertexColor(0.78, 0.66, 0.35, 0.95)
APR:RegisterSkinTarget(divider, "divider")
assert(divider.dividerLine.vertex[1] == 0.78, "WoW retains its native gold divider")

profile.uiTheme = "modern"
APR:RefreshRegisteredSkins(true)
assert(divider.dividerLine.vertex[2] == APR.Themes.modern.accent[2]
    and divider.dividerLine.vertex[4] == 0.25, "Modern dividers use a subtle theme accent")
assert(APR:GetTextColor("currentStep", "warning")[2] == APR.Themes.modern.warning[2],
    "Modern warnings use the softer palette")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
local activeRow = {indexFont = QuestOrderListPanel:CreateFontString(), titleFont = QuestOrderListPanel:CreateFontString()}
APR:RegisterFontString(activeRow.indexFont, "questOrderList")
APR:RegisterFontString(activeRow.titleFont, "questOrderList")
APR.questOrderListSupport:SetStepFrameState(activeRow, "gray", true)
assert(activeRow.titleFont.textColor[2] == APR.Themes.modern.accent[2],
    "The active step uses the Modern accent rather than warning yellow")

-- Old untouched profiles adopt the palette; saved custom colors and alpha remain intact.
local defaultBlue, defaultOrange = {0, 87 / 255, 183 / 255, 1}, {1, 164 / 255, 26 / 255, 1}
profile.currentStepProgressBarColor, profile.afkBarColor = defaultBlue, defaultOrange
local defaultBar = APR:CreateStatusBar(CurrentStepScreenPanel)
local defaultAfk = APR:CreateStatusBar(AfkFrameScreen, nil, "afk", "afkBarColor")
assert(defaultBar.color[2] == APR.Themes.modern.accent[2] and defaultAfk.color[2] == defaultBar.color[2])
assert(profile.currentStepProgressBarColor == defaultBlue, "Theme resolution never rewrites saved options")
profile.currentStepProgressBarColor = {0.7, 0.2, 0.4, 0.35}
APR:RefreshStatusBarColors()
assert(defaultBar.color[1] == 0.7 and defaultBar.color[4] == 0.35, "Existing custom RGB and alpha survive")
profile.currentStepProgressBarColor = {0, 87 / 255, 183 / 255, 0.4}
APR:RefreshStatusBarColors()
assert(defaultBar.color[2] == defaultBlue[2] and defaultBar.color[4] == 0.4, "Custom alpha counts as customization")
profile.currentStepProgressBarColor, profile.currentStepProgressBarColorCustom = defaultBlue, true
APR:RefreshStatusBarColors()
assert(defaultBar.color[2] == defaultBlue[2], "Explicitly choosing the original blue remains a custom choice")
profile.currentStepProgressBarColorCustom = false
profile.uiTheme = "wow"
APR:RefreshStatusBarColors()
assert(defaultBar.color[2] == defaultBlue[2] and defaultAfk.color[2] == defaultOrange[2],
    "WoW keeps its original bar colors")
APR.questOrderListSupport:SetStepFrameState(activeRow, "gray", true)
assert(APR.textStyleRegistry[activeRow.titleFont].options.role == "activeStep"
    and activeRow.titleFont.textColor[2] == 1, "WoW keeps the active-step warning color")
profile.uiTheme = "modern"
for _, panel in ipairs(panels) do
    assert(panel:GetWidth() == 250 and panel:GetHeight() == 60 and panel.point[4] == 25,
        "Modern appearance preserves panel layout")
    assert(panel.backdropColor[1] == APR.Themes.modern.background[1]
        and math.abs(panel.backdropColor[4] - 0.6 * APR.Themes.modern.background[4]) < 0.0001,
        "Modern palette preserves each panel's opacity")
end
assert(header.aprModernHeader and header.Background.alpha == 0 and button:GetNormalTexture().alpha == 0)
local headerChrome = header.aprModernHeader
assert(headerChrome.backdrop.insets.top == 8 and headerChrome.backdrop.insets.bottom == 0
    and headerChrome.backdrop.edgeFile:find("rounded%-border%-top%-8%.tga$")
    and headerChrome.aprRoundedFill.pieces[1]:IsShown() and headerChrome.aprRoundedFill.pieces[2]:IsShown()
    and not headerChrome.aprRoundedFill.pieces[3]:IsShown() and not headerChrome.aprRoundedFill.pieces[4]:IsShown(),
    "The Modern guide header rounds only its upper corners so the body join remains straight")
assert(button:GetWidth() == 22 and header.Text.textColor[2] == APR.Themes.modern.accent[2])
CurrentStepScreenPanel:SetWidth(320)
CurrentStepScreenPanel.scripts.OnSizeChanged(CurrentStepScreenPanel, 320, 60)
assert(header:GetWidth() == 320, "Modern headers follow the guide width without resizing their controls")
CurrentStepScreenPanel:SetWidth(250)
CurrentStepScreenPanel.scripts.OnSizeChanged(CurrentStepScreenPanel, 250, 60)
local allocated = env.frames()
for _ = 1, 20 do APR:RefreshRegisteredSkins(true) end
assert(env.frames() == allocated, "Modern refresh reuses chrome and installs each handler once")
button.scripts.OnClick(button)
assert(clicks == 1 and CurrentStepScreenPanel.backdropColor[4] == 0,
    "Collapsing preserves the action and removes the modern body")
button.scripts.OnClick(button)
assert(clicks == 2 and CurrentStepScreenPanel.backdropColor[4] > 0,
    "Expanding restores the body and configured opacity")

local legacyButton = CreateFrame("Button", nil, PartyScreenPanel)
legacyButton.SetBackdrop = false -- UIPanelButtonTemplate lacks BackdropTemplate's mixin.
legacyButton:SetNormalTexture("Legacy button artwork")
local legacyLabel = legacyButton:CreateFontString()
legacyButton:SetFontString(legacyLabel)
local legacyClicks = 0
legacyButton:SetScript("OnClick", function() legacyClicks = legacyClicks + 1 end)
APR:RegisterSkinTarget(legacyButton, "button")
assert(legacyButton.aprModernButton:GetBackdrop().edgeSize == 1 and legacyButton:GetNormalTexture().alpha == 0,
    "Legacy buttons receive modern chrome without requiring a backdrop mixin")
legacyButton.scripts.OnClick(legacyButton)
assert(legacyClicks == 1 and legacyButton:GetFontString() == legacyLabel)

local secure = CreateFrame("Button", nil, CurrentStepScreenPanel, "SecureActionButtonTemplate")
secure:SetAttribute("type", "item"); secure:SetAttribute("item", "item:123")
secure:SetNormalTexture("Item artwork")
env.setCombat(true)
local secureFrames = env.frames()
APR:RegisterSkinTarget(secure, "icon", {texture = secure:GetNormalTexture()})
assert(APR:AreSkinsPending() and not secure:GetNormalTexture().coords and env.frames() == secureFrames,
    "Combat skin registration cannot mutate a protected control")
env.setCombat(false)
APR:RefreshRegisteredSkins()
assert(secure:GetNormalTexture().coords[1] == 0.07 and secure.attributes.type == "item"
    and secure.attributes.item == "item:123" and secure:GetParent() == CurrentStepScreenPanel)

-- A future palette can reuse the modern layout without adding a new renderer.
local variants = {"wowModern", "modern", "graphiteModern", "emeraldModern", "violetModern", "redModern"}
local utilityWindow = APR.UI:Panel(UIParent, "window")
utilityWindow:SetSize(700, 500)
local utilitySection = APR.UI:Panel(utilityWindow, "borderedPanel", "inset")
local utilityTitle = APR.UI:Label(utilityWindow, "Routes", 14, "accent")
local statusGreen = APR:GetThemeStatusColor("routeCompleted")
local variantFrames = env.frames()
for _, name in ipairs(variants) do
    profile.uiTheme = name
    APR:RefreshRegisteredSkins(true)
    local theme = APR.Themes[name]
    assert(APR:GetSelectedSkinName() == name and APR:GetThemeStyle("currentStep") == "modern")
    assert(header.Text.textColor[2] == theme.accent[2] and defaultBar.color[2] == theme.accent[2]
        and divider.dividerLine.vertex[2] == theme.accent[2], "Every palette reaches HUD titles, fills and dividers")
    assert(headerChrome.backdropColor[1] == theme.surface[1] and headerChrome.backdropColor[4] == theme.surface[4]
        and headerChrome.backdrop.insets.bottom == 0,
        "Rounded headers retain their palette surface and square body join after refresh")
    assert(utilityWindow:GetBackdrop().edgeSize == 8 and utilitySection:GetBackdrop().edgeSize == 6,
        "Utility windows keep APR's established rounded chrome")
    assert(utilityWindow.backdropColor[1] == theme.background[1] and utilityWindow.backdropColor[4] == 1
        and utilitySection.backdropColor[1] == theme.surface[1] and utilitySection.backdropColor[4] == 1,
        "Large windows and sections use distinct opaque palette surfaces")
    assert(utilityTitle.textColor[2] == theme.accent[2] and APR:GetThemeStatusColor("routeCompleted") == statusGreen,
        "Utility labels follow the palette while route status colors remain semantic")
end
assert(env.frames() == variantFrames, "Switching palettes reuses existing chrome")
assert(APR:GetThemeChoices({UI_THEME_WOW_MODERN = "Localized gold"}).wowModern == "Localized gold",
    "Theme labels can be localized")
assert(APR.Themes.modern.accent ~= APR.Themes.violetModern.accent
    and APR.Themes.modern.base ~= APR.Themes.violetModern.base, "Variant palettes never share mutable color arrays")

APR.Themes.future = {}
for key, value in pairs(APR.Themes.modern) do APR.Themes.future[key] = value end
APR.Themes.future.accent = {0.9, 0.2, 0.4, 1}
APR.Themes.future.background = {0.15, 0.07, 0.12, 0.8}
profile.uiTheme = "future"
APR:RefreshRegisteredSkins()
assert(defaultBar.color[1] == 0.9 and defaultAfk.color[1] == 0.9,
    "Default bars refresh with future Modern palettes")
assert(header.Text.textColor[1] == 0.9 and header.aprModernHeader.line.fill[1] == 0.9
    and CurrentStepScreenPanel.backdropColor[1] == 0.15,
    "Existing frames and labels follow the next palette")

-- Appearance and placement choices remain independent when all trackers coexist.
KalielsTrackerFrame = CreateFrame("Frame", nil, UIParent)
KalielsTrackerFrame.Background = CreateFrame("Frame", nil, KalielsTrackerFrame)
Questie = {db = {profile = {trackerEnabled = true}}}
Questie_BaseFrame = CreateFrame("Frame", nil, UIParent)
ObjectiveTrackerFrame = CreateFrame("Frame", nil, UIParent)
ElvUI, EllesmereUI = {}, {RegisterSkin = function() end}
profile.currentStepAttachFrameToQuestLog = true
profile.fillersFrameSnapToCurrentStep, profile.questOrderListSnapToCurrentStep, profile.afkSnapToCurrentStep = true, true, true
local tracker = APR.QuestTracker
profile.currentStepTrackerProvider = "questie"
assert(select(3, tracker:Resolve()) == "questie")
profile.currentStepTrackerAppearance = "kaliel"
assert(tracker:Style("currentStep").provider == "kaliel" and select(3, tracker:Resolve()) == "questie")
profile.currentStepTrackerAppearance = "questie"
profile.currentStepTrackerProvider = "kaliel"
assert(tracker:Style("currentStep").provider == "questie" and select(3, tracker:Resolve()) == "kaliel")
for _, choice in ipairs({"wow", "modern", "wowModern", "graphiteModern", "emeraldModern", "violetModern",
    "redModern", "ElvUI", "EllesmereUI"}) do
    profile.currentStepTrackerAppearance = choice
    assert(APR:GetAppearanceProvider("currentStep") == choice and not tracker:Style("currentStep"),
        "Explicit appearance disables tracker artwork and font overrides")
    assert(APR:GetAppearanceProvider("fillers") == choice and APR:GetAppearanceProvider("party") == "future")
    APR:RefreshStatusBarColors()
    local chosen = APR.Themes[choice]
    assert(defaultBar.color[2] == (chosen and chosen.style == "modern" and chosen.accent[2] or defaultBlue[2]),
        "Bars respect the independently chosen tracker appearance")
end
profile.fillersFrameSnapToCurrentStep = false
assert(APR:GetAppearanceProvider("fillers") == "future", "Independent fillers follow the global theme")
profile.currentStepTrackerProvider = "questie"
Questie.db.profile.trackerEnabled = false
assert(select(3, tracker:Resolve()) == "blizzard", "A disabled provider falls back safely")
profile.currentStepTrackerAppearance = "questie"
assert(APR:GetAppearanceProvider("currentStep") == "future", "Unavailable artwork uses the global theme")

local reloads = 0
function ReloadUI() reloads = reloads + 1 end
profile.currentStepTrackerAppearance = "EllesmereUI"
local previous = APR:GetAppearanceProvider("currentStep")
profile.currentStepAttachFrameToQuestLog = false
assert(APR:ReloadChangedTrackerAppearance("currentStep", previous) and reloads == 1,
    "Detaching rebuilds persistent provider chrome before the global palette is applied")
assert(not APR:ReloadChangedTrackerAppearance("currentStep", "future") and reloads == 1,
    "Unchanged appearance never causes an extra reload")
profile.currentStepAttachFrameToQuestLog = true

-- Both adapters can register, but a control receives only its selected provider.
profile.uiTheme, profile.elvuiSkin, profile.ellesmereuiSkin = "ElvUI", true, false
profile.currentStepTrackerAppearance = "EllesmereUI"
local function apply(name)
    return function(frame)
        assert(not InCombatLockdown())
        assert(not frame.provider, "Never layer two providers on the same control")
        frame.provider = name
    end
end
dofile("APR-Core/integrations/SkinRegistry.lua")
APR:RegisterSkinProvider("ElvUI", apply("ElvUI"), function() return APR:IsSkinProviderUsed("ElvUI") end)
APR:RegisterSkinProvider("EllesmereUI", apply("EllesmereUI"), function() return APR:IsSkinProviderUsed("EllesmereUI") end)
local attached, unrelated = CreateFrame("Button", nil, CurrentStepScreenPanel), CreateFrame("Button", nil, PartyScreenPanel)
APR:RegisterSkinTarget(attached, "button"); APR:RegisterSkinTarget(unrelated, "button")
assert(attached.provider == "EllesmereUI" and unrelated.provider == "ElvUI")
APR:RefreshRegisteredSkins()
assert(attached.provider == "EllesmereUI" and APR:GetSkinProviderName("currentStep") == "EllesmereUI")
print("Gameplay themes: exact WoW art, modern layout, opacity, collapse, palette refresh, secure combat and independent trackers passed")
