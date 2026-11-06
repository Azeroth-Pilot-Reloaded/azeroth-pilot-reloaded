-- Exercise the real filler window and shared factories, including theme refreshes.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/utils/UIUtils.lua")

-- Model the template-owned header regions and visibility events.
local createFrame, hide, show = CreateFrame, env.methods.Hide, env.methods.Show
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerModuleHeaderTemplate" then
        frame.Text, frame.Background = frame:CreateFontString(), frame:CreateTexture()
        frame.MinimizeButton = createFrame("Button", nil, frame)
        frame.MinimizeButton:SetNormalTexture("Native collapse")
        frame.MinimizeButton:SetPushedTexture("Native collapse pressed")
    end
    return frame
end
function env.methods:Hide()
    local wasShown = self:IsShown()
    hide(self)
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function env.methods:Show()
    local wasShown = self:IsShown()
    show(self)
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end

local profile = APR.settings.profile
profile.uiTheme, profile.currentStepScale = "wowModern", 1
profile.fillersFrame = {}
profile.fillersFrameSnapToCurrentStep, profile.fillersFrameShowHeader = false, true
profile.currentStepbackgroundColorAlpha = { 0.1, 0.2, 0.3, 0.45 }
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 90 end
dofile("APR-Core/ui/route/FillersFrame.lua")

local fillers = APR.fillersFrame
local frame, header = fillers.Frame, fillers.FrameHeader
fillers:AddFillerStep(101, "Collect optional supplies", 1)
local row = APR.currentStep.fillersList["101-1"]
local bodyAlpha = frame.backdropColor[4]
assert(
    row.backdropColor[4] == 0 and bodyAlpha > 0 and bodyAlpha < 0.45,
    "Only the outer filler panel paints the configured translucent background"
)
assert(
    frame.backdrop.edgeSize == 8
        and frame.backdrop.insets.top == 0
        and frame.backdrop.insets.bottom == 8
        and frame.borderColor[4] > 0,
    "A detached filler body has a border and rounded lower corners without theme customization"
)
assert(header.aprModernHeader.backdrop.insets.top == 8, "The detached header owns the rounded upper corners")

for _, showHeader in ipairs({ false, true }) do
    profile.fillersFrameSnapToCurrentStep, profile.fillersFrameShowHeader = true, showHeader
    fillers:RefreshFillersFrame(true)
    assert(frame.aprSnapAnchor == CurrentStepScreenPanel and header:IsShown() == showHeader)
    assert(
        frame.backdrop.insets.top == 0
            and frame.backdrop.insets.bottom == 8
            and frame.borderColor[4] > 0
            and row.backdropColor[4] == 0,
        "Attached fillers retain their outer border and lower corners with or without a header"
    )
end

local tail = APR:CreateStandardFrame("QuestOrderListPanel", UIParent, 250, 80)
APR:SnapFrameToAnchor(tail, frame, frame:GetHeight(), 0)
assert(
    frame.backdrop.edgeSize == 1 and frame.borderColor[4] > 0,
    "A following panel squares the filler join while preserving its border"
)
tail:Hide()
assert(frame.backdrop.insets.bottom == 8, "Hiding the next panel restores the lower corners")
APR:SetFrameSnapAnchor(tail, nil)

-- A detach requested during combat is replayed through the existing layout lifecycle.
env.setCombat(true)
profile.fillersFrameSnapToCurrentStep = false
fillers:RefreshFillersFrame(true)
assert(fillers.pendingRefresh and frame.aprSnapAnchor == CurrentStepScreenPanel)
env.setCombat(false)
fillers:FlushPendingLayout()
assert(
    not frame.aprSnapAnchor and header.aprModernHeader.backdrop.insets.top == 8 and frame.backdrop.insets.bottom == 8,
    "Detaching restores both outer rounded ends after combat"
)

header.MinimizeButton.scripts.OnClick(header.MinimizeButton)
assert(
    frame.backdropColor[4] == 0 and frame.borderColor[4] == 0 and not fillers.StepHolder:IsShown(),
    "Collapsed fillers hide the body fill and border"
)
header.MinimizeButton.scripts.OnClick(header.MinimizeButton)
assert(
    frame.backdropColor[4] == bodyAlpha and frame.borderColor[4] > 0,
    "Expanding restores the configured fill and border"
)

for _, radius in ipairs({ 0, 8, 16 }) do
    profile.uiThemeCustomization = { rounded = radius > 0, radius = radius }
    APR:RefreshRegisteredSkins(true)
    assert(
        frame.backdrop.edgeSize == (radius == 0 and 1 or radius)
            and frame.backdropColor[4] == bodyAlpha
            and row.backdropColor[4] == 0,
        "Theme refreshes preserve one background and honor the chosen radius"
    )
end
fillers:RemoveFillerSteps()
fillers:AddFillerStep(202, "A replacement optional objective", 2)
assert(
    APR.currentStep.fillersList["202-2"] == row and row.backdropColor[4] == 0,
    "Recycled filler rows remain transparent"
)

print(
    "Filler theme: single fill, detached borders/corners, snapped joins, combat, collapse, radii and recycling passed"
)
