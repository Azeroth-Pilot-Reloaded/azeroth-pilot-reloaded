-- An empty guide offers route browsing in-place across startup, resets, visibility and tracker skins.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
function env.methods:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags; return true end
function env.methods:GetFont() return self.font or "native.ttf", self.size or 12, self.flags or "" end
function env.methods:SetTextColor(...) self.textColor = {...} end
function APR:ResolveUIFileAsset(path) return path end
local oldLibStub = LibStub
function LibStub(name, ...)
    if name == "LibSharedMedia-3.0" then return {GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end} end
    return oldLibStub(name, ...)
end
dofile("APR-Core/ui/foundations/TextStyles.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
APR:RegisterSkinTarget(APR.currentStep.contentBackdrop, "panel", {preserveBackground = true, roundedGameplay = true})
function env.methods:GetAlpha() return self.alpha or 1 end
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "UIPanelButtonTemplate,BackdropTemplate" then
        frame.Left, frame.Middle, frame.Right = env.widget(frame), env.widget(frame), env.widget(frame)
        frame:SetNormalTexture("native red button")
        frame:SetHighlightTexture("native gold highlight")
    end
    return frame
end
function APR.fillersFrame:UpdateBackgroundColorAlpha() end
function APR.fillersFrame:Hide() end
function APR.fillersFrame:Show() end
local profile = APR.settings.profile
profile.enableAddon, profile.currentStepScale, profile.currentStepFrame = true, 1, {}
profile.uiTheme = "modern"
APR:RefreshRegisteredSkins(true)
APR.PlayerID = "player"
APRData, APRZoneCompleted, APRCustomPath = {player = {FirstLoad = false}}, {player = {}}, {player = {}}
local petBattle, allowedInstance, opened = false, true, 0
function APR:IsPetBattleActive() return petBattle end
function APR:IsInstanceWithUI() return allowedInstance end
function APR.settings:OpenSettings(section) opened = opened + 1; assert(section == "ROUTE") end
function env.methods:GetTop()
    if self == UIParent then return 1080 end
    if self == CurrentStepScreenPanel then return 600 end
    return (self.parent and self.parent:GetTop() or 600) + (self.point and self.point[5] or 0)
end
function env.methods:GetBottom() return self:GetTop() - self:GetHeight() end
dofile("APR-Core/ui/route/RouteSelection.lua")
local selection, step = APR.RouteSelection, APR.currentStep
local rootHeight = CurrentStepScreenPanel:GetHeight()
step:CurrentStepFrameOnInit() -- SetDefaultDisplay runs before previous/next buttons exist.
selection:RouteSelectionOnInit()
local card = selection.frame
assert(card and card:GetParent() == CurrentStepFrame_StepHolder and card:IsShown())
assert(not RouteSelectionPanel and not OpenSettingsButton, "Startup must not create the old standalone window")
assert(not step.progressBar:IsShown() and not CurrentStepFrame_StepHolder.skipButton:IsShown(),
    "The empty guide has no fake progress or step navigation")
assert(step.FrameHeight == card:GetHeight() + 16 and step:GetContentHeight(false) >= card:GetHeight(),
    "Snapped frames reserve room for the empty-guide card")
assert(step.contentBackdrop:GetHeight() == step.FrameHeight,
    "The guide backdrop fills the complete empty-route card and its bottom padding")
assert(CurrentStepScreenPanel:GetHeight() == rootHeight and CurrentStepScreenPanel.backdropColor[4] == 0,
    "Extending the background preserves the movable root's geometry and avoids doubled opacity")
assert(step.contentBackdrop.backdropColor[4] > 0,
    "The full-height background inherits the configured opacity")
assert(step.contentBackdrop.backdrop.edgeSize == 8 and step.contentBackdrop.aprRoundedFill.enabled,
    "Modern guide backgrounds have rounded corners over the whole content height")
local bodyFill = step.contentBackdrop.aprRoundedFill
assert(step.contentBackdrop.backdrop.insets.top == 0 and step.contentBackdrop.backdrop.insets.bottom == 8
    and step.contentBackdrop.backdrop.edgeFile:find("rounded%-border%-bottom%-8%.tga$")
    and not bodyFill.pieces[1]:IsShown() and not bodyFill.pieces[2]:IsShown() and not bodyFill.pieces[5]:IsShown()
    and bodyFill.pieces[3]:IsShown() and bodyFill.pieces[4]:IsShown() and bodyFill.pieces[6]:IsShown(),
    "The guide body meets its header with square top corners and rounds only its bottom corners")
profile.currentStepbackgroundColorAlpha[4] = 0.4
step:UpdateBackgroundColorAlpha()
APR:RefreshRegisteredSkins(true)
assert(math.abs(step.contentBackdrop.backdropColor[4] - 0.4 * APR.Themes.modern.background[4]) < 0.0001,
    "Refreshing rounded chrome preserves the player's background opacity")
profile.currentStepbackgroundColorAlpha[4] = 1
step:UpdateBackgroundColorAlpha()
assert(card.button.Left:GetAlpha() == 0, "Modern buttons hide Blizzard's red artwork")
card.button.scripts.OnClick()
assert(opened == 1 and card:IsShown(), "Opening the catalog keeps the prompt until a route is chosen")
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 100 do selection:RefreshFrameAnchor() end
assert(env.frames() == frames and env.fonts() == fonts, "Idle refreshes reuse the card")

-- A saved path can exist before the active route is resolved, or while its first route is locked.
APRCustomPath.player = {"saved route", "later route"}
for _, active in ipairs({false, ""}) do
    APR.ActiveRoute = active or nil
    selection:RefreshFrameAnchor()
    assert(not card:IsShown() and not step.emptyRoutePromptActive,
        "A non-empty saved path never displays the onboarding card")
end
APR.ActiveRoute = nil
APRCustomPath.player = {}
selection:RefreshFrameAnchor()
assert(card:IsShown(), "Clearing the last saved route restores the card")

APR.ActiveRoute = "chosen"
step:Reset()
step:ProgressBar("chosen", 120, 23)
assert(not card:IsShown() and step.progressBar:IsShown() and CurrentStepFrame_StepHolder.skipButton:IsShown(),
    "Selecting a route restores guide progress and navigation")
step:BeginContentUpdate()
local rootAnchors = CurrentStepScreenPanel.anchors
step:AddExtraLineText("instruction", "A long instruction for the active route")
step:EndContentUpdate(true)
assert(step.contentBackdrop:GetHeight() == step.FrameHeight and step.FrameHeight > step.layout.topOffset,
    "The guide backdrop covers active instructions too")
assert(CurrentStepScreenPanel:GetHeight() == rootHeight and CurrentStepScreenPanel.anchors == rootAnchors,
    "Growing guide instructions never shifts a saved center/bottom anchor")
assert(step.questsExtraTextList.instruction.backdropColor[4] == 0,
    "Rows do not double the configured background opacity")
step:Reset()
assert(step.contentBackdrop:GetHeight() == step.layout.topOffset,
    "Removing instructions shrinks the backdrop without stale empty space")
APR.ActiveRoute = nil
step:Reset()
assert(card:IsShown() and not step.progressBar:IsShown())
CurrentStepScreenPanel.collapsed = true
selection:RefreshFrameAnchor()
assert(not card:IsShown())
step:SetDefaultDisplay()
assert(card:IsShown() and not step.progressBar:IsShown(), "Expanding an empty guide restores only its route card")
CurrentStepFrameHeader.MinimizeButton.scripts.OnClick()
assert(step.contentBackdrop:GetHeight() == step.layout.topOffset)
CurrentStepFrameHeader.MinimizeButton.scripts.OnClick()
assert(step.contentBackdrop:GetHeight() == step.FrameHeight and not step.progressBar:IsShown())
step:SetContentWidth(340)
assert(card:GetWidth() == 324 and card.button:GetWidth() == 304)

for _, hide in ipairs({"disabled", "hidden", "pet", "instance"}) do
    profile.enableAddon = hide ~= "disabled"
    profile.currentStepShow = hide ~= "hidden"
    petBattle, allowedInstance = hide == "pet", hide ~= "instance"
    selection:RefreshFrameAnchor()
    assert(not card:IsShown(), "The empty guide respects " .. hide .. " visibility")
end
profile.enableAddon, profile.currentStepShow, petBattle, allowedInstance = true, true, false, true
selection:RefreshFrameAnchor()
profile.currentStepAttachFrameToQuestLog, profile.currentStepTrackerAppearance = true, "violetModern"
APR:RefreshRegisteredSkins(true)
assert(card.backdropColor[1] == APR.Themes.violetModern.surface[1],
    "The embedded card follows the independent attached-frame palette")
assert(APR.textStyleRegistry[card.title].scope == "currentStep"
    and APR.textStyleRegistry[card.button:GetFontString()].scope == "currentStep")
profile.currentStepAttachFrameToQuestLog = false

profile.uiTheme = "wow"
APR:RefreshRegisteredSkins(true)
assert(card.backdrop.bgFile == "Interface\\DialogFrame\\UI-DialogBox-Background"
    and card.backdrop.edgeFile == "Interface\\Tooltips\\UI-Tooltip-Border",
    "World of Warcraft uses Blizzard artwork instead of the modern rounded card")
assert(not card.aprRoundedFill.enabled and not card.button.backdrop and card.button.Left:GetAlpha() == 1,
    "World of Warcraft restores the native red button and retires rounded fills")
profile.uiTheme = "wowModern"
APR:RefreshRegisteredSkins(true)
assert(card.aprRoundedFill.enabled and card.backdrop.edgeSize == 6 and card.button.Left:GetAlpha() == 0,
    "WoW Modern remains a separate rounded appearance")
profile.uiTheme = "modern"
APR:RefreshRegisteredSkins(true)

env.setCombat(true)
APR.ActiveRoute = "next"
selection:RefreshFrameAnchor()
assert(selection.pendingRefresh and card:IsShown(), "Protected guide changes wait for combat to end")
env.setCombat(false)
selection:RefreshFrameAnchor()
assert(not card:IsShown() and not selection.pendingRefresh)

-- Clearing a path uses the actual route-config owner; force reset preserves the same entry point.
function APR:IsTemporaryRouteActive() return false end
function APR:ActivateRoute(route) self.ActiveRoute = route end
APR.XPBuffOverlay = {QueueRefresh = function() end}
APR.Buff = {RemoveAllBuffIcon = function() end}
APR.map = {RemoveMapLine = function() end, RemoveMinimapLine = function() end}
APR.Arrow, APR.party = {}, {SendGroupMessage = function() end}
function APR:SendMessage() end
function APR.questOrderList:AddStepFromRoute() end
dofile("APR-Core/config/Config_Route.lua")
APR.routeconfig:CheckIsCustomPathEmpty()
assert(card:IsShown() and not step.questsExtraTextList.NO_ROUTE,
    "An empty path renders the card instead of the old no-route text")
function APR:TrimString(text) return text end
function APR:RemoveContiguousSpaces(text) return text end
local reloaded = false
C_UI = {Reload = function() reloaded = true; APR.ActiveRoute = nil end}
local acceptReset
function APR.UI:ShowConfirmationDialog(_, accept) acceptReset = accept end
dofile("APR-Core/core/Commands.lua")
APRCustomPath.player, APRData.player, APRZoneCompleted.player = {"route"}, {FirstLoad = false}, {route = true}
APR.command:SlashCmd("forcereset")
assert(not reloaded and APRCustomPath.player[1] == "route", "Force reset preserves the path until accepted")
acceptReset()
selection:RouteSelectionOnInit()
assert(reloaded and not next(APRCustomPath.player) and card:IsShown() and not RouteSelectionPanel,
    "Force reset returns to the embedded route picker")
print("Empty guide: startup, force reset, catalog action, sizing, reuse, visibility, combat and independent palettes passed")
