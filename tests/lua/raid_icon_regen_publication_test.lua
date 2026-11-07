local env = dofile("tests/lua/route_ui_test_env.lua")
local step, profile = APR.currentStep, APR.settings.profile
local function noop() end
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = noop, noop
step:PreviousNextStepButton()
profile.currentStepScale, profile.fillersFrame = 1, {}
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 100 end
dofile("APR-Core/ui/route/FillersFrame.lua")

local fillers, publications = APR.fillersFrame, 0
local refresh = fillers.RefreshFillersFrame
function fillers:RefreshFillersFrame(...)
    publications = publications + 1
    return refresh(self, ...)
end

local function render(targets, item)
    step:BeginContentUpdate()
    step:Reset()
    step:PrepareRaidIcon({ RaidIcon = targets })
    step:AddQuestSteps(10, "Main objective", 1)
    fillers:AddFillerStep(20, "Optional objective", 1)
    step:AddStepButton("10-1", item, "item")
    step:EndContentUpdate(true)
end

render({ 101, 202 }, 500)
assert(publications == 1, "A content transaction publishes the host once")
local button = step.questsList["10-1"].IconButton

-- The rail and a row action share one regeneration owner. Its final layout
-- must include the latest data without publishing the rail separately first.
env.setCombat(true)
render({ 101, 202 }, 501)
render({}, 502)
assert(#step.raidIconButtons == 2 and button.itemID == 500, "Combat preserves the published controls")
env.setCombat(false)
publications = 0
step:ProcessPendingStepButtons()
assert(publications == 1, "One regeneration flush must publish Fillers only once when row actions also changed")
assert(#step.raidIconButtons == 0 and button.itemID == 502 and button:GetAttribute("item") == "item:502")
assert(fillers.Frame:IsShown() and not fillers.pendingRefresh and not fillers.layoutDirty)
assert(not next(step.pendingButtonRequests) and not APR.RaidIconButtons.pendingTargets)

env.setCombat(true)
render({ 303 }, 503)
env.setCombat(false)
publications = 0
step:ProcessPendingStepButtons()
assert(publications == 1 and #step.raidIconButtons == 1 and step.raidIconButtons[1].npcID == 303,
    "A replacement target set joins the same final row publication")
assert(button.itemID == 503)
publications = 0
step:ProcessPendingStepButtons()
assert(publications == 0, "An idle regeneration flush must not republish the host")

-- With no queued row work there is no later layout owner: preserve the rail's
-- immediate host refresh, both on regeneration and on a direct out-of-combat call.
env.setCombat(true)
step:PrepareRaidIcon({ RaidIcon = 404 })
assert(not next(step.pendingButtonRequests) and step.raidIconButtons[1].npcID == 303)
env.setCombat(false)
publications = 0
step:ProcessPendingStepButtons()
assert(publications == 1 and step.raidIconButtons[1].npcID == 404,
    "A rail-only regeneration request still publishes immediately")
publications = 0
step:PrepareRaidIcon({ RaidIcon = 505 })
assert(publications == 1 and step.raidIconButtons[1].npcID == 505,
    "A direct out-of-combat request retains immediate publication")
print("RaidIcon regeneration: one shared host publication, latest/empty sets, idle and immediate paths passed")
