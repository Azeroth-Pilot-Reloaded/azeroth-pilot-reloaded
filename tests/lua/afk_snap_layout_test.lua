-- Exercise AFK visibility with the actual snap helper and both dependent panels.
local env = dofile("tests/lua/route_ui_test_env.lua")
local now, timers = 100, {}
function GetTime() return now end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function drain()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
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
startRealTimer()
assertListAnchor(AfkFrameScreen, 20)
afk:HideFrame()
drain()
assertListAnchor(CurrentStepScreenPanel, stepHeight)

-- With fillers, the entire chain becomes Current Step -> AFK -> Fillers -> List.
stepHeight = 140
local filler = env.widget(fillers.StepHolder)
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

print("PASS: real/test AFK timers reflow snapped fillers and quest list on show, hide, expiry, resize and snap changes")
