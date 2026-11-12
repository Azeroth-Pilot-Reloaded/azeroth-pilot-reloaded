local env = dofile("tests/lua/route_ui_test_env.lua")
local step, frame = APR.currentStep, CurrentStepScreenPanel
local handle, profile = step.resizeButton, APR.settings.profile
profile.currentStepFrame = {}
UIParent:SetWidth(1920)
UIParent:SetHeight(1080)
frame:SetHeight(30)
local starts, stops = 0, 0
APR.GetSkinProviderName = function() end
frame.StartSizing = function(_, direction)
    assert(direction == "RIGHT", "Height remains content-driven")
    starts = starts + 1
end
frame.StopMovingOrSizing = function()
    assert(not InCombatLockdown(), "Never stop a protected resize in combat")
    stops = stops + 1
end
handle.UnregisterEvent = function() end
step:PreviousNextStepButton()
step:ProgressBar("synthetic", 10, 1)
local progressText = "1 / 1 - " .. string.rep("A long destination name ", 8)
step.progressBar.Text:SetText(progressText)
step:AddQuestSteps(1, string.rep("Objective ", 20), 1)
local row = step.questsList["1-1"]
for _, theme in ipairs({ "wow", "modern" }) do
    profile.uiTheme = theme
    APR:ApplyNativeTheme(handle, "resize", { scope = "currentStep" })
    if theme == "modern" then
        assert(handle:GetNormalTexture().alpha == 0, "Modern supplies its own resize icon")
    end
    step:RefreshResizeHandle()
    assert(handle:IsShown())
    handle.scripts.OnMouseDown(handle, "RightButton")
    assert(not frame.isSizing)
    handle.scripts.OnMouseDown(handle, "LeftButton")
    assert(frame.isSizing)
    frame:SetWidth(420)
    frame.scripts.OnSizeChanged(frame, 420, 30)
    assert(step.layout.width == 420 and row:GetWidth() == 420 and row.font:GetWidth() == 388)
    assert(CurrentStepFrameHeader:GetWidth() == 420, "Navigation buttons retain edge anchors as the header grows")
    assert(step.progressBar:GetWidth() == (theme == "modern" and 348 or 328))
    assert(step.progressBar.Text:GetWidth() == (theme == "modern" and 340 or 320))
    assert(step.progressBar.Text:GetText() == progressText, "Resizing preserves the full label for later expansion")
    assert(frame:GetHeight() == 30 and step.contentBackdrop:GetHeight() == step.FrameHeight)
    handle.scripts.OnMouseUp(handle, "LeftButton")
    assert(not frame.isSizing and profile.currentStepFrame.width == 420)
    step:SetContentWidth(250)
    assert(step.progressBar.Text:GetWidth() == (theme == "modern" and 170 or 150),
        "Shrinking constrains the label immediately, without a progress refresh")
end
assert(starts == 2 and stops == 2)

profile.currentStepLock = true
step:RefreshResizeHandle()
assert(not handle:IsShown())
handle.scripts.OnMouseDown(handle, "LeftButton")
assert(starts == 2)
profile.currentStepLock = false
frame.collapsed = true
step:RefreshResizeHandle()
assert(not handle:IsShown())
frame.collapsed = false
step:RefreshResizeHandle()

handle.scripts.OnMouseDown(handle, "LeftButton")
env.setCombat(true)
frame:SetWidth(480)
frame.scripts.OnSizeChanged(frame, 480, 30)
handle.scripts.OnMouseUp(handle, "LeftButton")
assert(frame.isSizing and step.layout.width == 250 and profile.currentStepFrame.width == 420)
env.setCombat(false)
handle.scripts.OnEvent(handle, "PLAYER_REGEN_ENABLED")
assert(not frame.isSizing and step.layout.width == 480 and profile.currentStepFrame.width == 480)

env.setCombat(true)
handle.scripts.OnMouseDown(handle, "LeftButton")
assert(not frame.isSizing and starts == 3)
env.setCombat(false)
local style = APR.QuestTracker.Style
APR.QuestTracker.Style = function() return { provider = "kaliel" } end
step:RefreshResizeHandle()
assert(not handle:IsShown(), "An external tracker retains control of imposed widths")
APR.QuestTracker.Style = style

-- Reinitialization restores the saved width through the production init path.
step:SetContentWidth(250)
step.RefreshCurrentStepFrameAnchor = function() end
step.UpdateFrameScale = function() end
step.RefreshPartyFinderButton = function() end
APR.fillersFrame.UpdateBackgroundColorAlpha = function() end
step:CurrentStepFrameOnInit()
assert(step.layout.width == 480 and row.font:GetWidth() == 448)
profile.currentStepFrame.width = 0 / 0
step:CurrentStepFrameOnInit()
assert(step.layout.width == 480, "Invalid legacy dimensions are ignored")
print("Current step resizing: themes, layout, persistence, locks and combat recovery")
