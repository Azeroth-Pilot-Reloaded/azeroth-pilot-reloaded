-- One cache refresh can update many rows. Exercise real widgets so a mock of
-- UpdateQuestStep cannot hide a complete relayout for every changed objective.
local env = dofile("tests/lua/route_ui_test_env.lua")
local noop = function() end
local step = APR.currentStep
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = noop, noop
step:PreviousNextStepButton()
APR.settings.profile.enableAddon, APR.settings.profile.arrowActionText = true, true
APR.PlayerID, APR.ActiveRoute = "player", "invented"
APRData = { player = { invented = 1 } }
function APR:GetCurrentStepToken() return "invented:1" end
function APR:ShouldHideFrames() return false end
function APR:IsInstanceWithUI() return true end
function APR:IsPetBattleActive() return false end
dofile("APR-Core/ui/route/FillersFrame.lua")
local fillers, count = APR.fillersFrame, 100
local model, fail, nested = { [1] = {}, [2] = {} }, false, false
for index = 1, count do
    model[1][index] = { text = "Main 0/2", finished = false }
    model[2][index] = { text = "Extra 0/2", finished = false }
end
APR.QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" }
APR.ActiveQuests = {}
APR.GetQuestTitle = function(_, id) return "Quest " .. id end
local renders, arrowUpdates = 0, 0
APR.UpdateQpartPart = noop
APR.UpdateStep = function() renders = renders + 1 end
APR.party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop }
APR.Arrow = { UpdateActionText = function() arrowUpdates = arrowUpdates + 1 end }
C_QuestLog.GetNumQuestLogEntries = function() return 2 end
C_QuestLog.GetInfo = function(index) return { questID = index } end
C_QuestLog.IsComplete = function() return false end
C_QuestLog.GetNumQuestObjectives = function() return count end
local nestedDepth
C_QuestLog.GetQuestObjectives = function(id)
    if fail and id == 2 then error("Synthetic objective failure") end
    if nested and id == 1 then
        nested = false
        APR:UpdateQuest()
        nestedDepth = step.questUpdateDepth
    end
    return model[id]
end
dofile("APR-Core/features/questing/QuestCache.lua")
APR:UpdateQuest(true)
local function render(during)
    step:BeginContentUpdate()
    step:Reset()
    fillers:RemoveFillerSteps()
    step:SetActionTextStep({ Qpart = { [1] = { 1 } } }, "invented:1")
    step:SetActionTextScope("primary", "Qpart")
    for index = 1, count do
        step:AddQuestSteps(1, model[1][index].text, index)
        fillers:AddFillerStep(2, model[2][index].text, index)
    end
    step:AddStepButton("1-1", 50, "item")
    if during then during() end
    step:EndContentUpdate(true)
end
render()
local main, extra = step.questsList["1-1"], step.fillersList["2-1"]
local button = main.IconButton
local frames, fonts = env.frames(), env.fonts()
local heightCalls, nativeHeight = 0, env.methods.GetStringHeight
local fillerRefreshes, nativeFillerRefresh = 0, fillers.RefreshFillersFrame
function env.methods:GetStringHeight(...)
    heightCalls = heightCalls + 1
    return nativeHeight(self, ...)
end
function fillers:RefreshFillersFrame(...)
    fillerRefreshes = fillerRefreshes + 1
    return nativeFillerRefresh(self, ...)
end
local function change(mainText, extraText)
    for index = 1, count do model[1][index].text, model[2][index].text = mainText, extraText end
end
local function observedRefresh()
    local before = env.layouts()
    heightCalls, arrowUpdates, fillerRefreshes = 0, 0, 0
    APR:UpdateQuest()
    return env.layouts() - before, heightCalls, arrowUpdates, fillerRefreshes
end
change("Main 1/2", "Extra 1/2")
local layouts, measurements, arrows = observedRefresh()
assert(layouts == 2 and measurements == 300 and arrows == 1,
    "100 main +100 optional changes publish one main/filler layout and one arrow update: "
    .. layouts .. " layouts, " .. measurements .. " measurements, " .. arrows .. " arrow updates")
assert(renders == 1 and main.objectiveText == "Main 1/2" and extra.objectiveText == "Extra 1/2")
assert(APR.ActiveQuests[1].objectives[100].text == "Main 1/2"
    and APR.ActiveQuests[2].objectives[100].text == "Extra 1/2")
assert(step.questsList["1-1"] == main and step.fillersList["2-1"] == extra and main.IconButton == button)
assert(env.frames() == frames and env.fonts() == fonts and not step.questUpdateDepth and not step.pendingQuestActionText)
for _ = 1, 30 do
    local idleLayouts, idleMeasurements, idleArrows = observedRefresh()
    assert(idleLayouts == 0 and idleMeasurements == 0 and idleArrows == 0,
        "An unchanged cache remains dormant even after a batched publication")
end

-- Nesting has one owner. Inner cache completion cannot release the outer batch.
change("Main nested", "Extra nested")
nested = true
layouts, measurements, arrows = observedRefresh()
assert(nestedDepth == 1 and layouts == 2 and measurements <= 300 and arrows == 1)
assert(not step.questUpdateDepth and main.objectiveText == "Main nested" and extra.objectiveText == "Extra nested")

-- Errors preserve original reporting, retire the guard and keep geometry dirty
-- for a later successful refresh instead of stranding all future layouts.
change("Main after failure", "Extra after failure")
fail, nested = true, true
local before = env.layouts()
arrowUpdates = 0
local ok, err = pcall(APR.UpdateQuest, APR)
assert(not ok and tostring(err):find("Synthetic objective failure", 1, true))
assert(not step.questUpdateDepth and step.layoutDirty and env.layouts() == before and arrowUpdates == 0)
fail = false
layouts, measurements, arrows = observedRefresh()
assert(layouts == 2 and measurements <= 300 and arrows == 1)
assert(not step.layoutDirty and not fillers.layoutDirty and not step.pendingQuestActionText)
assert(extra.objectiveText == "Extra after failure")

-- Deferred cache reads never touch UI. An already-open content pass retains
-- ownership and publishes exactly once when its caller completes the render.
change("Main deferred", "Extra deferred")
before, heightCalls, arrowUpdates = env.layouts(), 0, 0
APR:UpdateQuest(true)
assert(env.layouts() == before and heightCalls == 0 and arrowUpdates == 0)
assert(main.objectiveText == "Main after failure" and APR.ActiveQuests[1].objectives[1].text == "Main deferred")
before, arrowUpdates = env.layouts(), 0
render(function()
    local current = env.layouts()
    APR:UpdateQuest()
    assert(step.contentUpdateActive and not step.questUpdateDepth and env.layouts() == current and arrowUpdates == 0)
end)
assert(env.layouts() - before == 2 and arrowUpdates == 1)

env.setCombat(true)
change(string.rep("Wrapped in combat ", 8), "Extra combat")
APR:UpdateQuest()
assert(not step.questUpdateDepth and main.IconButton == button and main:IsShown()
    and extra.objectiveText == "Extra combat", "Batch completion respects the existing secure-row combat deferral")
assert(step.layoutDirty and fillers.pendingRefresh, "Protected layout remains pending until combat ends")
for _ = 1, 30 do
    local idleLayouts, idleMeasurements, idleArrows, idleFillers = observedRefresh()
    assert(idleLayouts == 0 and idleMeasurements == 0 and idleArrows == 0 and idleFillers == 0,
        "An unchanged combat refresh must not retry already-deferred geometry or publish filler visibility")
end
env.setCombat(false)
step:ReOrderQuestSteps()
fillers:FlushPendingLayout(true)
assert(main:GetHeight() > 30 and not step.layoutDirty and not fillers.pendingRefresh)
env.methods.GetStringHeight = nativeHeight
fillers.RefreshFillersFrame = nativeFillerRefresh
print("Quest UI batching: 100 main +100 fillers, 300 ->2 publications, 20100 ->300 font reads; nested/error/deferred/content/combat recovery passed")
