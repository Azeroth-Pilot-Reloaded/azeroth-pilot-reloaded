local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
local step, definitions, references = APR.currentStep, {}, {}
local renders, arrowUpdates, fillerUpdates = 0, 0, 0
APR.QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" }
APR.ActiveQuests = {}
APR.Debug, APR.UpdateQpartPart = noop, noop
APR.UpdateStep = function() renders = renders + 1 end
APR.party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop }
APR.fillersFrame = { UpdateFillerStep = function() fillerUpdates = fillerUpdates + 1 end }
APR.Arrow = { UpdateActionText = function() arrowUpdates = arrowUpdates + 1 end }
APR.GetQuestTitle = function(_, id) return "Quest " .. id end
for id = 1, 50 do
    definitions[id] = {}
    for index = 1, 3 do definitions[id][index] = { text = "Collect 0/10", finished = false } end
end
C_QuestLog.GetNumQuestLogEntries = function() return 50 end
C_QuestLog.GetInfo = function(index) return { questID = index } end
C_QuestLog.IsComplete = function() return false end
C_QuestLog.GetNumQuestObjectives = function(id) return #definitions[id] end
C_QuestLog.GetQuestObjectives = function(id) return definitions[id] end
local percent = 10
APR.GetQuestObjectiveProgressPercent = function(_, id) if id == 1 then return percent end end
dofile("APR-Core/features/questing/QuestCache.lua")
APR:UpdateQuest(true)
assert(fillerUpdates == 0, "Combined refreshes synchronize data without touching soon-to-be-rebuilt rows")
for id = 1, 50 do
    references[id] = { quest = APR.ActiveQuests[id], objectives = {} }
    for index = 1, 3 do references[id].objectives[index] = APR.ActiveQuests[id].objectives[index] end
end
step:BeginContentUpdate()
for id = 1, 4 do
    for index = 1, 3 do step:AddQuestSteps(id, "Collect 0/10", index) end
end
step:EndContentUpdate(true)
local layouts, frames, fonts = env.layouts(), env.frames(), env.fonts()
arrowUpdates = 0
for _ = 1, 100 do APR:UpdateQuest() end
assert(env.layouts() == layouts and arrowUpdates == 0 and renders == 0,
    "100 unchanged logs with 150 objectives trigger zero layouts, arrow refreshes or renders")
assert(env.frames() == frames and env.fonts() == fonts)
for id = 1, 50 do
    assert(APR.ActiveQuests[id] == references[id].quest)
    for index = 1, 3 do assert(APR.ActiveQuests[id].objectives[index] == references[id].objectives[index]) end
end
local row = step.questsList["1-1"]
percent = 35
APR:UpdateQuest()
assert(row.questProgressBar.value == 35 and env.layouts() == layouts,
    "A percentage change without a text change updates the bar without layout")
percent = nil
APR:UpdateQuest()
assert(not row.questProgressBar:IsShown() and env.layouts() > layouts)
layouts = env.layouts()
APR:UpdateQuest()
assert(env.layouts() == layouts, "An already hidden progress bar cannot continually invalidate geometry")
definitions[2][1].text = "Collect 1/10"
APR:UpdateQuest()
assert(renders == 1 and step.questsList["2-1"].objectiveText == "Collect 1/10")
assert(APR.ActiveQuests[2].objectives[1] == references[2].objectives[1])
definitions[2][3] = nil
APR:UpdateQuest()
assert(renders == 2 and APR.ActiveQuests[2].objectives[3] == nil, "Removed objectives are retired from the cache")
definitions[2] = {}
APR:UpdateQuest()
assert(renders == 3 and #APR.ActiveQuests[2].objectives == 1
    and APR.ActiveQuests[2].objectives[1].text == "Quest 2", "Objective-less quests get a fresh fallback")
print("Quest cache: 150 stable objectives, zero idle layouts, live percentages, in-place changes and shrink recovery passed")
