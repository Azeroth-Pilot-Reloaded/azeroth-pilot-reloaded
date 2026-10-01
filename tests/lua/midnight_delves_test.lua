-- Exercise the packaged alt route with real condition and parallel-step evaluation.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function wipe(value) for key in pairs(value) do value[key] = nil end end
function tContains(values, value)
    for _, entry in ipairs(values) do if entry == value then return true end end
    return false
end

local level, zone = 89.5, 2413
local active, ready, complete, account = {}, {}, {}, {}
function UnitLevel() return math.floor(level) end
C_Map = { GetBestMapForUnit = function() return zone end }
C_QuestLog = {
    IsOnQuest = function(id) return active[id] == true end,
    IsComplete = function(id) return ready[id] == true end,
    IsQuestFlaggedCompleted = function(id) return complete[id] == true end,
    IsQuestFlaggedCompletedOnAccount = function(id) return account[id] == true end,
}
C_PvP = { IsWarModeActive = function() return true end }
C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end }
APR = {
    interfaceVersion = 120100, PlayerID = "test", RouteQuestStepList = {},
    worldCoordinateConverter = { ConvertMapCoordinate = function(_, _, x, y) return { x = x, y = y } end },
}
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteManager.lua")
dofile("APR-Core/config/LevelProfiles.lua")
function APR:GetPlayerEffectiveLevel() return level end
function APR:HasAura(id) return id == 430191 or id == 1221184 end
function APR:HasAchievement(id) return id == 42328 end
function APR:IsDelveRoute() return false end
dofile("Routes/Midnight/Midnight-Speedrun-alt.lua")

local key = "2393-Midnight-Speedrun-alt"
local route = APR.RouteQuestStepList[key]
local rewards = { 93384, 93372, 93386, 93385, 93409, 93410, 93427, 93428, 93416, 93421 }
local start, reserve
for index, step in ipairs(route.steps) do
    if step.Grind == "MidnightDelves" then start = index end
    if start and step.PickUp then reserve = index; break end
end
assert(start and reserve, "The hand-in circuit precedes the reserve quests")
local function reset()
    active, ready, complete, account = {}, {}, { [86737] = true }, {}
    APRData = { test = { [key] = start } }
    APR.ActiveRoute = key
    APR:InvalidateEffectiveRouteStepsCache()
    level, zone = 89.5, 2413
end

assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 87.30,
    "5% mentorship, 10% potion and configured War Mode target level 87 with 30% XP")

-- A single ready quest must activate its hub even when every sibling is absent.
for _, quest in ipairs(rewards) do
    reset()
    active[quest], ready[quest] = true, true
    local group
    for _, candidate in ipairs(route.parallelSteps) do
        for _, step in ipairs(candidate.steps) do
            if step.Done and tContains(step.Done, quest) then group = candidate end
        end
    end
    assert(group, "Every delve reward is reserved by a parallel group")
    zone = group.conditions.Zones[1]
    level = 87.29
    assert(not APR:AreConditionalFiltersMet(group.conditions), "Do not spend rewards below the threshold")
    assert(APR:IsQuestTurnInDeferred(quest), "Automatic turn-ins remain deferred below the threshold")
    level = 87.30
    assert(APR:AreConditionalFiltersMet(group.conditions), "No missing sibling may block a ready reward")
    assert(not APR:IsQuestTurnInDeferred(quest), "An eligible reward can be turned in automatically")
    local effective = APR:GetRouteSteps(key)
    local enabled = 0
    for _, step in ipairs(group.steps) do
        if APR:AreConditionalFiltersMet(step) then enabled = enabled + 1 end
    end
    assert(#effective > #route.steps and enabled == 1, "Only the ready pending reward is displayed")
    active[quest], ready[quest], complete[quest] = nil, nil, true
    assert(not APR:AreConditionalFiltersMet(group.conditions), "Spent rewards do not activate a hub")
end

-- Simulate player travel and hand-ins; use the actual engine for insertion and filtering.
-- With parallel insertion disabled, the ordinary steps must still cover every reward.
local function runCircuit(pending, disableParallel)
    reset()
    for _, quest in ipairs(rewards) do complete[quest] = true end
    complete[92732] = true -- An unrelated reserve quest must not skip a portal.
    for _, quest in ipairs(pending) do
        complete[quest], active[quest], ready[quest] = nil, true, true
    end
    local handins, cityVisited = 0, false
    for _ = 1, 100 do
        local index = APRData.test[key]
        local steps = disableParallel and route.steps or APR:GetRouteSteps(key)
        local step = steps[index]
        assert(step, "The circuit must reach its reserve boundary")
        if step == route.steps[reserve] then break end
        if APR:AreConditionalFiltersMet(step) then
            if step.UseSpell then
                if not complete[step.UseSpell.questID] then zone = 2541 end
            elseif step.TakePortal then
                if not complete[step.TakePortal.questID] then
                    zone = step.TakePortal.mapID
                    if zone == 2393 or zone == 2395 then cityVisited = true end
                end
            elseif step.Done then
                for _, quest in ipairs(step.Done) do
                    if not complete[quest] then
                        assert(active[quest] and ready[quest], "Never request an absent or unfinished reward")
                        if quest == 93384 or quest == 93372 or quest == 93386 or quest == 93385 then
                            assert(cityVisited, "Return to Silvermoon before its rewards, even after 93421 is spent")
                        end
                        zone = step.Zone
                        active[quest], ready[quest], complete[quest] = nil, nil, true
                        handins = handins + 1
                    end
                end
            end
        end
        APRData.test[key] = index + 1
    end
    assert(handins == #pending, "All pending rewards are handled before ordinary Harandar quests")
end
for _, disableParallel in ipairs({ false, true }) do
    runCircuit({ 93384, 93372, 93386, 93385 }, disableParallel) -- Reported 89.5 scenario.
    runCircuit(rewards, disableParallel)
    for _, quest in ipairs(rewards) do runCircuit({ quest }, disableParallel) end
end

reset()
-- Inline safeguards must skip a quest that is in the log but still unfinished.
for _, quest in ipairs(rewards) do active[quest] = true end
for index = start, reserve - 1 do
    local step = route.steps[index]
    if step.Done then
        assert(not APR:AreConditionalFiltersMet(step), "Unfinished rewards cannot block the fallback")
        for _, quest in ipairs(step.Done) do ready[quest] = true end
        level = 90
        assert(not APR:AreConditionalFiltersMet(step), "Stop the reward circuit at level 90")
        level = 89.5
    end
end

reset()
account[86930], account[86898], account[86890] = true, true, true
local inChain, checked = false, 0
for _, step in ipairs(route.steps) do
    if step.PickUp and tContains(step.PickUp, 90824) then inChain = true end
    if inChain and step.Grind then break end
    if inChain then
        assert(not APR:AreConditionalFiltersMet(step), "Account campaign progress does not unlock this character's chain")
        complete[86890] = true
        assert(APR:AreConditionalFiltersMet(step), "The character's prerequisite unlocks the entire reserve chain")
        complete[86890] = nil
        checked = checked + 1
    end
end
assert(checked > 0, "The campaign-gated reserve was tested")
print("Midnight delve route regressions passed")
