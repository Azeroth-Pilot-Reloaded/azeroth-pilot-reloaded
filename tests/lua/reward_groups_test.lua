-- Reserved rewards use reusable condition semantics on synthetic guides.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function wipe(value) for key in pairs(value) do value[key] = nil end end
function tContains(values, value)
    for _, entry in ipairs(values) do if entry == value then return true end end
    return false
end
local level, zone = 50.5, 101
local active, ready, complete, account = {}, {}, {}, {}
function UnitLevel() return math.floor(level) end
C_Map = { GetBestMapForUnit = function() return zone end }
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    IsComplete = function(id) return ready[id] == true end,
    IsQuestFlaggedCompleted = function(id) return complete[id] == true end,
    IsQuestFlaggedCompletedOnAccount = function(id) return account[id] == true end,
}
APR = { interfaceVersion = 120100, PlayerID = "test", RouteQuestStepList = {} }
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/config/LevelProfiles.lua")
APR.LevelRequirementProfiles.FixtureRewards = { levels = { [0] = 50.5 } }
function APR:GetPlayerEffectiveLevel() return level end
function APR:IsDelveRoute() return false end

for _, size in ipairs({ 1, 2, 5 }) do
    local key = "fixture-rewards-" .. size
    local rewards, group = {}, { steps = {} }
    local route = { label = "Arbitrary reward guide " .. size, steps = { { Note = { "Main" } } }, parallelSteps = { group } }
    for index = 1, size do
        local quest = 1000 + index
        rewards[index] = quest
        local function handin()
            return { Done = { quest }, MinLevel = "FixtureRewards", MaxLevel = 51,
                Zones = { 101 }, IsQuestReadyForTurnIn = quest, IsQuestUncompleted = quest }
        end
        group.steps[index] = handin()
        route.steps[#route.steps + 1] = handin()
    end
    route.steps[#route.steps + 1] = { RouteCompleted = true }
    local alternatives = {}
    for index, quest in ipairs(rewards) do alternatives[index] = { IsQuestReadyForTurnIn = quest } end
    group.conditions = { MinLevel = "FixtureRewards", MaxLevel = 51, Zones = { 101 }, AnyOf = alternatives }
    APR.RouteQuestStepList[key] = route
    local function reset()
        active, ready, complete, account = {}, {}, {}, {}
        level, zone = 50.5, 101
        APRData, APR.ActiveRoute = { test = { [key] = 1 } }, key
        APR:InvalidateEffectiveRouteStepsCache()
    end
    for index, quest in ipairs(rewards) do
        reset()
        active[quest], ready[quest] = true, true
        level = 50.49
        assert(not APR:AreConditionalFiltersMet(group.conditions) and APR:IsQuestTurnInDeferred(quest))
        assert(#APR:GetRouteSteps(key) == #route.steps)
        zone, level = 102, 50.5
        assert(not APR:AreConditionalFiltersMet(group.conditions) and APR:IsQuestTurnInDeferred(quest))
        zone = 101
        assert(APR:AreConditionalFiltersMet(group.conditions), "One ready quest enables the group despite absent siblings")
        assert(not APR:IsQuestTurnInDeferred(quest))
        for siblingIndex, step in ipairs(group.steps) do
            assert(APR:AreConditionalFiltersMet(step) == (siblingIndex == index))
        end
        local expanded = APR:GetRouteSteps(key)
        assert(#expanded == #route.steps + size, "An eligible group inserts once")
        assert(APR:GetRouteSteps(key) == expanded)
        assert(APR:AreConditionalFiltersMet(route.steps[index + 1]))
        ready[quest] = nil
        assert(not APR:AreConditionalFiltersMet(route.steps[index + 1]), "An unfinished reward cannot block the fallback")
        ready[quest], complete[quest] = true, true
        assert(not APR:AreConditionalFiltersMet(route.steps[index + 1]), "A spent reward is skipped")
        complete[quest], level = nil, 51
        assert(APR:AreConditionalFiltersMet(group.conditions), "The maximum level is inclusive")
        level = 51.01
        assert(not APR:AreConditionalFiltersMet(group.conditions), "The maximum level ends the reward circuit")
    end
    reset()
    for _, quest in ipairs(rewards) do active[quest], ready[quest] = true, true end
    assert(APR:AreConditionalFiltersMet(group.conditions))
    assert(#APR:GetRouteSteps(key) == #route.steps + size)
    reset()
    account[999] = true
    local characterGate = { IsQuestCompleted = 999 }
    assert(not APR:AreConditionalFiltersMet(characterGate), "Account progress cannot satisfy a character prerequisite")
    complete[999] = true
    assert(APR:AreConditionalFiltersMet(characterGate))
end
