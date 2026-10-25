-- Item-started dungeon quests interrupt the run before their objectives;
-- equipment and other parallel groups still wait for the instance exit.
local L = setmetatable({}, {__index = function(_, key) return key end})
function LibStub() return {GetLocale = function() return L end} end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function CreateFrame() return {RegisterEvent = function() end, SetScript = function() end} end
local bags, onQuest, completed = {}, {}, {}
local inside, instanceID = true, 2999
function IsInInstance() return inside, inside and "party" or "none" end
function GetInstanceInfo() return "instance", "party", 0, "", 0, 0, false, instanceID end
function UnitLevel() return 20 end
C_Item = {GetItemCount = function(id) return bags[id] or 0 end}
C_QuestLog = {
    IsOnQuest = function(id) return onQuest[id] == true end,
    IsQuestFlaggedCompleted = function(id) return completed[id] == true end,
}
DUNGEONS, QUESTS_LABEL = "Dungeons", "Quests"
APR = {PlayerID = "player", Faction = "Alliance", RouteQuestStepList = {},
    ActiveQuests = {}, stepHandlers = {}, QUEST_STATUS = {COMPLETE = 1, PROGRESS = 2}, Debug = function() end}
APRData = {player = {BonusSkips = {}}}
function APR:IsDelveRoute() return false end
function APR:EnsureQuestPool() end
function APR:ResetQuestPool() end
function APR:TrackQuest() end
function APR:UpdateNextStep() APRData.player[self.ActiveRoute] = APRData.player[self.ActiveRoute] + 1 end
APR.NextQuestStep = APR.UpdateNextStep
APR.worldCoordinateConverter = {ConvertMapCoordinate = function(_, _, x, y) return {x = x, y = y} end}
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
function APR:GetGameVersion() return "forever" end
function APR:GetPlayerEffectiveLevel() return 20 end
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("tests/lua/dungeon_data_test_env.lua")
dofile("APR-Core/utils/DungeonUtils.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")

local main = {
    {Note = {"Approach"}},
    {KillNPC = {dungeonKey = "ROL", npcID = 250483}, Dungeon = "ROL", InstanceQuest = true},
    {Qpart = {[2002] = {1}}, Dungeon = "ROL", InstanceQuest = true},
    {LeaveInstance = {dungeonKey = "ROL"}, Dungeon = "ROL", InstanceQuest = true},
    {Note = {"Outside"}},
    {RouteCompleted = true},
}
local function pickup(quest, dungeon)
    return {PickUp = {quest}, Dungeon = dungeon or "ROL", InstanceQuest = true, NoArrow = true}
end
local function group(item, steps)
    return {conditions = {ItemCount = {itemID = item, count = 1}}, steps = steps}
end
local immediate = group(222, {pickup(2002)})
local route = {label = "Synthetic dungeon", steps = main, parallelSteps = {
    group(111, {{EquipItem = {itemID = 111, slot = 16}}}),
    immediate,
    group(333, {pickup(3003), {Done = {3003}, Dungeon = "ROL", InstanceQuest = true}}),
    group(444, {pickup(4004)}),
    group(555, {pickup(5005, "HOT")}),
}}
APR.RouteQuestStepList.synthetic = route
APR.ActiveRoute, APRData.player.synthetic = "synthetic", 2
assert(APR:GetParallelStepsInsertionIndex(2, main, immediate) == 2)
assert(APR:GetParallelStepsInsertionIndex(2, main) == 5, "Existing callers retain instance deferral")
for _, candidate in ipairs({
    {steps = {pickup(1)}},
    {conditions = {ItemCount = {itemID = 1, count = 0}}, steps = {pickup(1)}},
    {conditions = {ItemCount = {itemID = 1, count = 1, operator = "<"}}, steps = {pickup(1)}},
    group(1, {pickup(1, "HOT")}),
    group(1, {pickup(1), pickup(2)}),
    group(1, {{PickUp = {1}, Dungeon = "ROL"}}),
    group(1, {{UseItem = {itemID = 1}, Dungeon = "ROL", InstanceQuest = true}}),
}) do
    assert(APR:GetParallelStepsInsertionIndex(2, main, candidate) == 5,
        "Only a single item-gated pickup in the current dungeon can interrupt")
end
for _, operator in ipairs({">=", ">", "=="}) do
    immediate.conditions.ItemCount.operator = operator
    assert(APR:GetParallelStepsInsertionIndex(2, main, immediate) == 2)
end
immediate.conditions.ItemCount.operator = nil
inside = false
assert(APR:GetParallelStepsInsertionIndex(2, main, immediate) == 5, "Entry/overworld steps cannot use the exception")
inside, instanceID = true, 3065
assert(APR:GetParallelStepsInsertionIndex(2, main, immediate) == 5, "An unrelated actual instance cannot use the exception")
instanceID = 2999
assert(APR:GetParallelStepsInsertionIndex(1, {{InstanceQuest = true}, {}}, immediate) == 2,
    "Scenario blocks without a dungeon remain protected")
assert(APR:GetParallelStepsInsertionIndex(1, main, immediate) == 1, "Normal outdoor insertion stays unchanged")

assert(#APR:GetRouteSteps("synthetic") == #main, "An absent starter cannot insert a pickup")
for _, id in ipairs({111, 222, 333, 444, 555}) do bags[id] = 1 end
local steps = APR:GetRouteSteps("synthetic")
assert(#steps == 12 and steps[2].PickUp[1] == 2002 and steps[3].PickUp[1] == 4004,
    "Immediate groups sort before deferred groups even when equipment has a lower group index")
assert(steps[4] == main[2] and steps[5] == main[3] and steps[6] == main[4])
assert(steps[7].EquipItem and steps[8].PickUp[1] == 3003 and steps[9].Done[1] == 3003
    and steps[10].PickUp[1] == 5005 and steps[11] == main[5],
    "Deferred groups retain group order and the correct index offsets after the exit")
local savedState = APRData.player["synthetic-ParallelStepsState"]
assert(savedState.activationSequence == 5)
assert(APR:GetRouteSteps("synthetic") == steps, "Repeated renders reuse the unchanged effective cache")
for _, quest in ipairs({2002, 4004}) do
    onQuest[quest], APR.ActiveQuests[quest] = true, {}
    APR.stepHandlers.PickUp(steps[APRData.player.synthetic], false)
end
assert(APRData.player.synthetic == 4 and steps[4] == main[2], "Accepting the starters resumes the interrupted boss")
bags[222], bags[444] = 0, 0
APR:InvalidateEffectiveRouteStepsCache("synthetic")
dofile("APR-Core/features/questing/RouteManager.lua")
steps = APR:GetRouteSteps("synthetic")
assert(#steps == 12 and steps[APRData.player.synthetic] == main[2] and savedState.activationSequence == 5,
    "Saved activations and progress reconstruct after reload without duplicate pickups")

-- A later drop inserts relative to the already expanded route, preserving
-- previously deferred groups and main-route progress.
route.parallelSteps[6] = group(666, {pickup(6006)})
APRData.player.synthetic, bags[666] = 5, 1
steps = APR:GetRouteSteps("synthetic")
assert(#steps == 13 and steps[5].PickUp[1] == 6006 and steps[6] == main[3]
    and steps[7] == main[4] and steps[8].EquipItem and steps[12] == main[5])
APR:InvalidateEffectiveRouteStepsCache("synthetic")
assert(#APR:GetRouteSteps("synthetic") == 13 and savedState.activationSequence == 6)

-- Exercise the maintained ROL declaration: the insignia starter must be
-- accepted while the route still has dungeon trash available to collect it.
dofile("Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Ruins_of_Lordaeron.lua")
local key = "Forever-Shared-Dungeons-Ruins-of-Lordaeron"
local live = APR.RouteQuestStepList[key]
bags, onQuest, completed, APR.ActiveQuests = {}, {}, {}, {}
APR.ActiveRoute = key
local bossIndex
for index, step in ipairs(live.steps) do if step.KillNPC then bossIndex = index; break end end
assert(bossIndex)
APRData.player[key] = bossIndex
assert(#APR:GetRouteSteps(key) == #live.steps)
bags[268535] = 1
steps = APR:GetRouteSteps(key)
assert(steps[bossIndex].PickUp[1] == 95195 and steps[bossIndex + 1] == live.steps[bossIndex])
local objectiveIndex, leaveIndex
for index, step in ipairs(steps) do
    if step.Qpart and step.Qpart[95195] and step.Dungeon == "ROL" then objectiveIndex = index end
    if step.LeaveInstance then leaveIndex = index end
end
assert(bossIndex < objectiveIndex and objectiveIndex < leaveIndex,
    "The item pickup precedes the real insignia objective and instance exit")
onQuest[95195] = true
APR.ActiveQuests[95195] = {objectives = {{status = APR.QUEST_STATUS.PROGRESS}}}
APR.stepHandlers.PickUp(steps[bossIndex], false)
assert(APRData.player[key] == bossIndex + 1)
assert(APR:AreConditionalFiltersMet(steps[objectiveIndex]))
APRData.player[key] = objectiveIndex
APR.stepHandlers.Qpart(steps[objectiveIndex], false)
assert(APRData.player[key] == objectiveIndex, "The dungeon objective waits for actual collection")
APR.ActiveQuests[95195].objectives[1].status = APR.QUEST_STATUS.COMPLETE
APR.stepHandlers.Qpart(steps[objectiveIndex], false)
assert(APRData.player[key] == objectiveIndex + 1)
bags[268535] = 0
APR:InvalidateEffectiveRouteStepsCache(key)
dofile("APR-Core/features/questing/RouteManager.lua")
assert(#APR:GetRouteSteps(key) == #live.steps + 1
    and APRData.player[key] == objectiveIndex + 1, "The live quest resumes without another acceptance after reload")
print("Dungeon parallel pickups: narrow eligibility, mixed ordering, late drops, reload and ROL insignia flow passed")
