-- Exercise AFK visibility with the actual snap helper and both dependent panels.
local env = dofile("tests/lua/route_ui_test_env.lua")
-- Provide a real viewport around the synthetic 420px-wide snap chain.
UIParent:SetSize(1600, 900)
local now, timers = 100, {}
function GetTime() return now end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function drain()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do
        callback()
    end
end

function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
APR.Color.orange = { 1, 0.6, 0.1 }
local profile = APR.settings.profile
profile.enableAddon, profile.showQuestOrderList = true, true
profile.afkSnapToCurrentStep, profile.questOrderListSnapToCurrentStep = true, true
profile.fillersFrameSnapToCurrentStep, profile.fillersFrameShowHeader = true, true
profile.afkHeight, profile.afkWidth, profile.fillersFrameSnapGap = 20, 250, 7
local stepHeight = 100
function APR.currentStep:GetContentHeight() return stepHeight end
CurrentStepScreenPanel:SetSize(420, stepHeight)
CurrentStepScreenPanel:SetScale(1.25)

dofile("APR-Core/ui/route/FillersFrame.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/route/QuestOrderList.lua")
dofile("APR-Core/features/player/AFK.lua")
-- Load the shared anchor selection and positioning functions after mock widgets
-- have supplied the game templates needed during panel creation.
dofile("APR-Core/utils/UIUtils.lua")
local afk, fillers = APR.AFK, APR.fillersFrame
afk:HideFrame()
drain()

local function anchored(frame, anchor, offset)
    assert(frame.point[2] == anchor, "Panel must use the current visible snap anchor")
    assert(frame.point[5] == -offset, "Panel must reserve the anchor's height and header gap")
    assert(frame:GetScale() == anchor:GetScale(), "Snapped panels inherit the anchor scale")
end
local function assertListAnchor(anchor, height)
    anchored(QuestOrderListPanel, anchor, height + 30)
    assert(QuestOrderListPanel:GetWidth() == anchor:GetWidth())
end
local function startRealTimer()
    afk:SetAfkTimer(30)
    assert(not afk.fakeTimerActive, "Real timers do not require test mode")
    drain()
    assert(APR:IsAFKFrameActiveShouldSnap())
    anchored(AfkFrameScreen, CurrentStepScreenPanel, stepHeight)
end

-- The quest list must move even when there are no visible fillers.
assertListAnchor(CurrentStepScreenPanel, stepHeight)
-- A saved-position restore can leave cached dimensions unchanged but overwrite the point.
QuestOrderListPanel:ClearAllPoints()
QuestOrderListPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
APR.questOrderList:ApplySnapAnchor()
assertListAnchor(CurrentStepScreenPanel, stepHeight)
QuestOrderListPanel:ClearAllPoints()
QuestOrderListPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
QuestOrderListPanel.scripts.OnShow(QuestOrderListPanel)
assertListAnchor(CurrentStepScreenPanel, stepHeight)
startRealTimer()
assertListAnchor(AfkFrameScreen, 20)
afk:HideFrame()
drain()
assertListAnchor(CurrentStepScreenPanel, stepHeight)

-- With fillers, the entire chain becomes Current Step -> AFK -> Fillers -> List.
stepHeight = 140
local filler = env.widget(fillers.StepHolder)
filler.questID = 123
filler.font = env.widget(filler)
filler.font.GetStringHeight = function() return 25 end
APR.currentStep.fillersList.bonus = filler
fillers.contentHeight = 45
fillers:RefreshFillersFrame()
anchored(fillers.Frame, CurrentStepScreenPanel, stepHeight + 7 + 22)
assertListAnchor(fillers.Frame, 45)
startRealTimer()
anchored(fillers.Frame, AfkFrameScreen, 20 + 7 + 22)
assertListAnchor(fillers.Frame, 45)

-- A live timer's resize and snap setting changes must also reflow the fillers.
now = now + 1
profile.afkHeight = 35
afk:RefreshFrameAnchor()
anchored(fillers.Frame, AfkFrameScreen, 35 + 7 + 22)
profile.afkSnapToCurrentStep = false
afk:RefreshFrameAnchor()
assert(not APR:IsAFKFrameActiveShouldSnap())
anchored(fillers.Frame, CurrentStepScreenPanel, stepHeight + 7 + 22)
profile.afkSnapToCurrentStep = true
afk:RefreshFrameAnchor()
anchored(fillers.Frame, AfkFrameScreen, 35 + 7 + 22)

-- Natural expiry removes the AFK gap through the same deferred refresh.
now = afk.timerEnd
local bar
for _, child in ipairs(AfkFrameScreen.children) do
    if child.scripts.OnUpdate then bar = child end
end
assert(bar)
bar.scripts.OnUpdate(bar, 1)
drain()
assert(not APR:IsAFKFrameActiveShouldSnap() and not AfkFrameScreen:IsShown())
anchored(fillers.Frame, CurrentStepScreenPanel, stepHeight + 7 + 22)
assertListAnchor(fillers.Frame, 45)

-- Test timers still use the same layout and return to the prior anchor on stop.
afk:ToggleFakeTimer()
drain()
assert(afk.fakeTimerActive and APR:IsAFKFrameActiveShouldSnap())
anchored(fillers.Frame, AfkFrameScreen, 35 + 7 + 22)
afk:ToggleFakeTimer()
drain()
anchored(fillers.Frame, CurrentStepScreenPanel, stepHeight + 7 + 22)

-- Independent windows keep their positions; a reset uses the visible AFK bar.
profile.fillersFrameSnapToCurrentStep = false
fillers:RefreshFillersFrame()
fillers.Frame:SetPoint("CENTER", UIParent, "CENTER", 11, 12)
startRealTimer()
assert(fillers.Frame.point[1] == "CENTER" and fillers.Frame.point[4] == 11)
assertListAnchor(AfkFrameScreen, 35)
fillers:ResetPosition()
anchored(fillers.Frame, AfkFrameScreen, 35 + 30)
profile.questOrderListSnapToCurrentStep = false
QuestOrderListPanel:SetPoint("CENTER", UIParent, "CENTER", 21, 22)
afk:HideFrame()
drain()
assert(QuestOrderListPanel.point[1] == "CENTER" and QuestOrderListPanel.point[4] == 21)

-- A synthetic snapped stack has one bottom grip and a shared user-sized width.
profile.currentStepFrame, profile.fillersFrame, profile.questOrderListFrame = {}, {}, {}
profile.fillersFrameSnapToCurrentStep, profile.questOrderListSnapToCurrentStep = true, true
APR.currentStep:PreviousNextStepButton()
APR.currentStep:ProgressBar("synthetic", 9, 2)
APR.questOrderList.DelayedUpdate = function() end
QuestOrderListPanel.SetResizeBounds = function(self, minWidth, minHeight, maxWidth, maxHeight)
    self.resizeBounds = { minWidth, minHeight, maxWidth, maxHeight }
end
for _, frame in pairs({ CurrentStepScreenPanel, FillersScreenPanel, QuestOrderListPanel, AfkFrameScreen }) do
    frame.StartSizing = function(self, direction) self.resizeDirection = direction end
    frame.aprResizeButton.UnregisterEvent = function() end
end
fillers:RefreshFillersFrame()
APR:RefreshSnappedFrames()
assert(not CurrentStepScreenPanel.aprResizeButton:IsShown() and not FillersScreenPanel.aprResizeButton:IsShown())
assert(QuestOrderListPanel.aprResizeButton:IsShown())
assert(QuestOrderListPanel.resizeBounds[1] == 250 and QuestOrderListPanel.resizeBounds[3] > 530,
    "Snapping must not freeze the list's resize bounds to its anchor width")
local listGrip = QuestOrderListPanel.aprResizeButton
listGrip.scripts.OnMouseDown(listGrip, "LeftButton")
assert(QuestOrderListPanel.isSizing and QuestOrderListPanel.resizeDirection == "BOTTOMRIGHT")
QuestOrderListPanel:SetWidth(530)
QuestOrderListPanel.scripts.OnSizeChanged(QuestOrderListPanel, 530, 270)
assert(CurrentStepScreenPanel:GetWidth() == 530 and FillersScreenPanel:GetWidth() == 530)
assert(CurrentStepFrameHeader:GetWidth() == 530, "Classic navigation buttons follow their resized header")
assert(FillersFrameHeader:GetWidth() == 530)
assert(APR.currentStep.progressBar.Text:GetWidth() == 430)
listGrip.scripts.OnMouseUp(listGrip, "LeftButton")
assert(not QuestOrderListPanel.isSizing and profile.currentStepFrame.width == 530 and profile.fillersFrame.width == 530)
assertListAnchor(FillersScreenPanel, 45)

QuestOrderListPanel:Hide()
FillersScreenPanel.collapsed = true -- A snapped filler body remains expanded.
APR:RefreshGameplayResizeHandles()
assert(FillersScreenPanel.aprResizeButton:IsShown() and not CurrentStepScreenPanel.aprResizeButton:IsShown())
FillersScreenPanel.collapsed = false
local fillerGrip = FillersScreenPanel.aprResizeButton
fillerGrip.scripts.OnMouseDown(fillerGrip, "LeftButton")
FillersScreenPanel:SetWidth(360)
FillersScreenPanel.scripts.OnSizeChanged(FillersScreenPanel, 360, 45)
assert(CurrentStepScreenPanel:GetWidth() == 360 and FillersScreenPanel:GetWidth() == 360)
fillerGrip.scripts.OnMouseUp(fillerGrip, "LeftButton")
assert(profile.currentStepFrame.width == 360 and profile.fillersFrame.width == 360)

profile.fillersFrameSnapToCurrentStep = false
APR:RefreshGameplayResizeHandles()
assert(FillersScreenPanel.aprResizeButton:IsShown() and CurrentStepScreenPanel.aprResizeButton:IsShown())
fillerGrip.scripts.OnMouseDown(fillerGrip, "LeftButton")
FillersScreenPanel:SetWidth(410)
FillersScreenPanel.scripts.OnSizeChanged(FillersScreenPanel, 410, 45)
fillerGrip.scripts.OnMouseUp(fillerGrip, "LeftButton")
assert(CurrentStepScreenPanel:GetWidth() == 360 and profile.fillersFrame.width == 410)
profile.currentStepLock = true
profile.fillersFrameSnapToCurrentStep = true
APR:RefreshGameplayResizeHandles()
assert(not FillersScreenPanel.aprResizeButton:IsShown())
profile.currentStepLock = false
APR:RefreshGameplayResizeHandles()
fillerGrip.scripts.OnMouseDown(fillerGrip, "LeftButton")
env.setCombat(true)
FillersScreenPanel:SetWidth(470)
FillersScreenPanel.scripts.OnSizeChanged(FillersScreenPanel, 470, 45)
fillerGrip.scripts.OnMouseUp(fillerGrip, "LeftButton")
assert(FillersScreenPanel.isSizing and CurrentStepScreenPanel:GetWidth() == 360)
env.setCombat(false)
fillerGrip.scripts.OnEvent(fillerGrip, "PLAYER_REGEN_ENABLED")
assert(not FillersScreenPanel.isSizing and CurrentStepScreenPanel:GetWidth() == 470)
assert(profile.currentStepFrame.width == 470)
env.setCombat(true)
fillerGrip.scripts.OnMouseDown(fillerGrip, "LeftButton")
assert(not FillersScreenPanel.isSizing)
env.setCombat(false)
FillersScreenPanel:Hide()
startRealTimer()
FillersScreenPanel:Hide()
APR:RefreshGameplayResizeHandles()
assert(AfkFrameScreen.aprResizeButton:IsShown() and not CurrentStepScreenPanel.aprResizeButton:IsShown(),
    "The countdown owns the grip when it is the last visible snapped panel")

print("PASS: real/test AFK timers reflow snapped fillers and quest list on show, hide, expiry, resize and snap changes")
