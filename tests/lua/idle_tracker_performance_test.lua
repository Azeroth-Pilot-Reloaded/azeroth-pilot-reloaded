-- Use the real tracker/CurrentStep observer path and count expensive layout work.
local env = dofile("tests/lua/route_ui_test_env.lua")
local tracker, profile = APR.QuestTracker, APR.settings.profile
function APR:CanAccessValue(value) return type(value) ~= "table" end
function APR:ShouldHideFrames() return false end
profile.enableAddon, profile.currentStepAttachFrameToQuestLog = true, true
profile.currentStepTrackerSide = "below"
ObjectiveTrackerFrame = env.widget(UIParent)
local root = ObjectiveTrackerFrame
root:SetSize(300, 200)
root:SetPoint("TOP", UIParent, "BOTTOMLEFT", 600, 800)
local top = 800
function root:GetCenter() return 600 end
function root:GetTop() return top end
function root:GetBottom() return top - 200 end
local realGetAnchor, realSnap = tracker.GetAnchor, APR.RefreshSnappedFrames
local anchors, snaps, appearances = 0, 0, 0
function tracker:GetAnchor() anchors = anchors + 1; return realGetAnchor(self) end
function APR:RefreshSnappedFrames() snaps = snaps + 1; return realSnap(self) end
tracker.RefreshAppearance = function() appearances = appearances + 1 end
tracker:Initialize()
local function tick(delta) tracker.observer.scripts.OnUpdate(tracker.observer, delta or 0.2) end
tick()
local observedState = tracker.layoutObservation
local initialAnchors, initialSnaps = anchors, snaps
for _ = 1, 100 do tick() end
assert(anchors - initialAnchors <= 21 and snaps - initialSnaps <= 21,
    "Twenty idle seconds cannot perform one hundred complete layouts")
assert(appearances <= 21, "Style checks run at most once a second rather than every geometry poll")
assert(tracker.layoutObservation == observedState, "Idle geometry probes reuse their storage")

local before = anchors
top = top - 100
tick()
assert(anchors == before + 1 and CurrentStepScreenPanel.point[5] == 465,
    "A tracker move is followed on the next geometry poll")
before = anchors
APR:RefreshSnappedFrames() -- A content/layout change can keep every outer frame dimension unchanged.
tick()
assert(anchors == before + 1, "Explicit APR layout changes invalidate the geometry probe")

-- Missing optional AFK/fillers panels must not hide changes to later linked panels.
AfkFrameScreen, FillersScreenPanel = nil, nil
QuestOrderListPanel = env.widget(UIParent)
tick()
before = anchors
QuestOrderListPanel:SetHeight(50)
tick()
assert(anchors == before + 1, "Geometry probes include panels after missing optional frames")

before = anchors
env.setCombat(true)
top = top - 50
tick()
assert(anchors == before, "Combat cannot invoke protected layout work")
env.setCombat(false)
tick()
assert(anchors == before + 1, "Leaving combat immediately catches up with deferred geometry")

before = anchors
profile.currentStepAttachFrameToQuestLog = false
tick()
assert(anchors == before and tracker.layoutObservation == nil, "Detached panels do no geometry work")
profile.currentStepAttachFrameToQuestLog = true
tick()
assert(anchors == before + 1, "Reattachment forces a new geometry check")
before = anchors
CurrentStepScreenPanel:Hide()
tick()
assert(anchors == before, "Hidden panels do no geometry work")
CurrentStepScreenPanel:Show()
tick()
assert(anchors == before + 1)

-- The fallback uses the same observation cache, but it never duplicates an active observer.
before = anchors
CurrentStepScreenPanel.scripts.OnUpdate(CurrentStepScreenPanel, 0.2)
assert(anchors == before, "CurrentStep stays dormant while the shared observer is installed")
profile.enableAddon = false
local previousAppearances = appearances
for _ = 1, 10 do tick() end
assert(appearances == previousAppearances and anchors == before, "Disabled APR does no style or layout polling")
print("Idle tracker: cheap geometry probes, bounded safety checks, immediate invalidation and combat/visibility guards passed")
