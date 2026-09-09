local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
local completed, active, ready = {}, {}, {}
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    IsComplete = function(id) return ready[id] == true end,
    IsQuestFlaggedCompleted = function(id) return completed[id] == true end,
}
function UnitLevel() return 80 end
C_Map = { GetBestMapForUnit = function() return 2395 end }
function tContains(list, value)
    for _, entry in ipairs(list) do if entry == value then return true end end
    return false
end
APR = { RouteQuestStepList = {}, Faction = "Alliance" }
APR.worldCoordinateConverter = { ConvertMapCoordinate = function(_, _, x, y) return { x = x, y = y } end }
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("Routes/Midnight/midnight-Speedrun/2393-Midnight-Speedrun-alt.lua")
local route = APR.RouteQuestStepList["2393-Midnight-Speedrun-alt"]
local intro = route.parallelSteps[11]
local handin = route.parallelSteps[12]
assert(#route.parallelSteps == 12 and #intro.steps == 36)
assert(APR:AreConditionalFiltersMet(nil))
assert(not APR:AreConditionalFiltersMet({ AnyOf = {} }))
assert(not APR:AreConditionalFiltersMet(intro.conditions), "A fresh skip character does not take the normal branch")
completed[86852] = true
assert(APR:AreConditionalFiltersMet(intro.conditions), "Completing the normal Sunwell intro unlocks Silvermoon")
for _, quest in ipairs({ 86733, 86734, 86735, 86736, 86737 }) do
    completed, active = { [94993] = true }, { [quest] = true }
    assert(APR:AreConditionalFiltersMet(intro.conditions), "Resume any active city quest even with a board breadcrumb")
end
completed, active = { [86852] = true, [86733] = true, [86734] = true,
    [86735] = true, [86736] = true, [94993] = true }, {}
assert(not APR:AreConditionalFiltersMet(intro.conditions), "Skipped city flags plus the adventure breadcrumb do not replay the tour")
completed[86737], active[86737] = true, true
assert(not APR:AreConditionalFiltersMet(intro.conditions), "Completed city chain never replays")
completed, active = {}, { [86737] = true }
for _, idx in ipairs({ 9, 10, 11, 12, 13 }) do
    local s = route.steps[idx]
    -- Evaluate only the added branching keys; dynamic XP policy is tested separately.
    assert(not APR:AreConditionalFiltersMet({ IsQuestNotOnQuest = s.IsQuestNotOnQuest,
        IsQuestUncompleted = s.IsQuestUncompleted }), "Normal breadcrumb suppresses the skip-only board steps")
end
assert(not APR:AreConditionalFiltersMet({ IsQuestOnQuest = route.steps[156].IsQuestOnQuest }))
assert(not APR:AreConditionalFiltersMet(handin.conditions), "Do not turn in before arriving at Fairbreeze")
ready[86737] = true
assert(APR:AreConditionalFiltersMet(handin.conditions))
assert(handin.steps[1].Done[1] == 86737 and handin.steps[1].Coord.x == route.steps[156].Coord.x)
local last = 0
for _, quest in ipairs({ 86733, 86734, 86735, 86736, 86737 }) do
    local pickup
    for i, s in ipairs(intro.steps) do
        if s.PickUp and tContains(s.PickUp, quest) then assert(not pickup); pickup = i end
    end
    assert(pickup and pickup > last)
    last = pickup
end
for quest, faction in pairs({ [86735] = "Alliance", [86736] = "Horde" }) do
    local objectives = {}
    for _, s in ipairs(intro.steps) do
        if s.Qpart and s.Qpart[quest] then
            assert(s.Faction == faction and s.Coord and s.Zone)
            for _, id in ipairs(s.Qpart[quest]) do assert(not objectives[id]); objectives[id] = true end
        end
    end
    for id = 1, 7 do assert(objectives[id], "Missing city tour objective") end
end
assert(route.steps[159].PickUp[1] == 86738, "The shared campaign entry remains unchanged")
print("Silvermoon branch: fresh skip, normal intro, partial progress, factions, seven objectives and Fairbreeze rejoin passed")
