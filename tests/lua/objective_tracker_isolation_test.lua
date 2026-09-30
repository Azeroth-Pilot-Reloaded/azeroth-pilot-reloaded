-- Lua cannot emulate WoW taint, but APR must never enter or mutate the
-- Blizzard tracker and must not anchor its secure action buttons to it.
local function forbidden() error("APR must not hook, update or mutate Blizzard's tracker") end
local originalDofile = dofile
function dofile(path)
    if path == "APR-Core/ui/route/CurrentStep.lua" then hooksecurefunc = forbidden end
    return originalDofile(path)
end
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile = originalDofile

local reads = 0
local function trackerFrame(state)
    local methods = {
        IsShown = function() return state.shown end,
        GetCenter = function() reads = reads + 1; return state.x, state.y end,
        GetBottom = function() return state.y end,
        GetEffectiveScale = function() return state.scale end,
        Update = forbidden, MarkDirty = forbidden, SetPoint = forbidden,
        SetScript = forbidden, HookScript = forbidden, SetScale = forbidden,
    }
    return setmetatable({}, { __index = methods, __newindex = forbidden })
end
local header = { shown = true, x = 400, y = 700, scale = 1.5 }
local first = { shown = true, x = 400, y = 600, scale = 1.5 }
local last = { shown = true, x = 400, y = 500, scale = 1.5 }
local trackerData = {
    Header = trackerFrame(header), modules = { trackerFrame(first), trackerFrame(last) },
    Update = forbidden, MarkDirty = forbidden, SetPoint = forbidden,
}
ObjectiveTrackerFrame = setmetatable({}, { __index = trackerData, __newindex = forbidden })
local secret = {}
function APR:CanAccessValue(value) return value ~= secret end
function APR:ShouldHideFrames() return false end
function UIParent:GetEffectiveScale() return 0.75 end

local panel, step, profile = CurrentStepScreenPanel, APR.currentStep, APR.settings.profile
local function tick(elapsed) panel.scripts.OnUpdate(panel, elapsed or 0.2) end
profile.enableAddon = true
tick()
assert(reads == 0, "Detached panels must not inspect the tracker")
profile.currentStepAttachFrameToQuestLog = true
tick(0.1)
assert(reads == 0, "Tracker observation is throttled")
tick(0.1)
assert(panel.point[1] == "TOP" and panel.point[2] == UIParent and panel.point[3] == "BOTTOMLEFT",
    "APR anchors only to UIParent, never to Blizzard's tracker or modules")
assert(panel.point[4] == 800 and panel.point[5] == 965,
    "Last visible module position is converted to UIParent's coordinate scale")
local anchors, layouts = panel.anchors, env.layouts()
tick()
assert(panel.anchors == anchors and env.layouts() == layouts, "Unchanged geometry does not trigger layout")
panel:SetScale(1.4)
tick()
assert(panel:GetScale() == 1, "Attached panels retain their root-coordinate scale after a settings refresh")

last.shown = false
tick()
assert(panel.point[5] == 1165, "Hidden modules are skipped")
first.shown = false
tick()
assert(panel.point[5] == 1365, "Collapsed/empty tracker falls back to its header")

panel.secure = true
env.setCombat(true)
header.y = 800
local beforeCombat = reads
tick()
step:RefreshQuestTrackerAnchor()
assert(reads == beforeCombat and panel.point[5] == 1365, "Combat defers both reads and protected repositioning")
env.setCombat(false)
tick()
assert(panel.point[5] == 1565, "Position catches up after combat")

header.y = secret
anchors = panel.anchors
tick()
assert(panel.anchors == anchors, "Secret geometry is not used in arithmetic or anchors")
header.y = nil
tick()
assert(panel.anchors == anchors, "Missing geometry keeps the last valid position")
header.y = 800

profile.currentStepAttachFrameToQuestLog = false
step:RefreshCurrentStepFrameAnchor()
profile.currentStepAttachFrameToQuestLog = true
step:RefreshCurrentStepFrameAnchor()
assert(panel.anchors > anchors, "Reattachment reapplies the anchor even at the same tracker position")

profile.enableAddon = false
local beforeDisabled = reads
tick()
assert(reads == beforeDisabled)
profile.enableAddon = true
ObjectiveTrackerFrame = nil
tick()
step:RefreshCurrentStepFrameAnchor()
assert(panel.point[2] == UIParent, "An unavailable tracker leaves APR's last valid anchor intact")
print("Objective tracker isolation: no hooks/writes, root anchoring, scale, combat, secrets and reattachment passed")
