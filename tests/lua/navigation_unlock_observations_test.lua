local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")
local done, active, quantity, total, criteria, localAction = {}, {}, 0, 10, nil, false
local player = { instanceID = 2552, uiMapID = 2248, x = 20, y = 20 }
local a = { space = "world", instanceID = 2552, uiMapID = 2248, x = 1, y = 2 }
local b = { space = "world", instanceID = 2552, uiMapID = 2248, x = 20, y = 20 }
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", level = 90, mapID = player.uiMapID } end,
    getPlayerPosition = function() return player end,
    isQuestCompleted = function(id) return done[id] == true end,
    isQuestActive = function(id) return active[id] == true end,
    isQuestObjectiveCompleted = function() return false end,
    getQuestObjectiveProgress = function() return quantity, total end,
    getScenarioCriteria = function() return criteria end,
    isUnlockActionComplete = function() return localAction end,
}
local function make(steps, guidance)
    Lib:RegisterData("unlock-observations", "test", { unlockRoutes = {
        { id = "tracker", goal = { key = "quest", value = 99 }, guidanceQuestID = guidance, steps = steps },
    } }, (Lib.dataRevisions["unlock-observations:test"] or 0) + 1)
    local data = Lib:New({ profile = "unlock-observations", environment = env })
    function data:CanWalk() return true end
    local run = data:CreateUnlockSession({ destination = { uiMapID = 2472, x = 10, y = 20, instanceID = 2738 },
        blockers = { { id = "destination", blockedRequirements = { quest = 99 } } } })
    return run, data
end
local function tick(run)
    for _ = 1, 10000 do
        local status, action, destination = run:Step(8, 1)
        if status ~= "planning" then return status, action, destination end
    end
    error("Unbounded observation run")
end

-- A sourced no-arrow objective remains a real instruction while incomplete.
active[7] = true
local run, data = make({ { kind = "objective", questID = 7, sourceID = 1,
    noArrow = true, positionOptional = true, objectiveIndices = { 1 }, progressAny = { { percent = 50 }, { count = 2, total = 10 } } } })
local status, action = tick(run)
assert(status == "action" and action.positionOptional and not action.target)
quantity = 2
assert(tick(run) == "missing_data", "An explicit numeric OR threshold completes the objective instruction")
done[99] = true
assert(tick(run) == "resume", "Only an observed actual access flag resumes the destination")
done[99] = nil

-- Scenario identity and completion remain tri-state; no coordinate is invented.
run, data = make({ { kind = "scenario", sourceID = 1, noArrow = true, positionOptional = true,
    scenario = { scenarioID = 2388, stepID = 6910, criteriaID = 65266, criteriaIndex = 2 } },
    { kind = "turnin", questID = 7, position = a } })
status, action = tick(run)
assert(status == "action" and action.kind == "scenario" and action.waitingData and not action.target)
criteria = { completed = false, quantity = 0, totalQuantity = 1 }
status, action = tick(run)
assert(status == "action" and not action.waitingData)
criteria.completed = true
status, action = tick(run)
assert(status == "action" and action.kind == "turnin")
local saved = run:ExportState()
criteria = nil
run = data:RestoreUnlockSession(saved)
status, action = tick(run)
assert(status == "action" and action.kind == "turnin", "Observed scenario progress survives reload after leaving the scenario")

-- A waypoint list is reached at any authored candidate, with authored radius.
run, data = make({ { kind = "waypoint", position = a, positions = { a, b }, radius = 2 },
    { kind = "turnin", questID = 7, position = a } })
status, action = tick(run)
assert(status == "action" and action.kind == "turnin")
saved = run:ExportState()
player.x, player.y = 100, 100
run = data:RestoreUnlockSession(saved)
status, action = tick(run)
assert(action.kind == "turnin", "A completed navigation waypoint is not replayed after reloading")

-- A transport advances only on its sourced destination; departure is not proof.
run, data = make({ { kind = "transport", position = a, transport = { type = "portal", destinationMapID = 2472 },
    arrival = { uiMapID = 2472 } }, { kind = "turnin", questID = 7, position = a } })
status, action = tick(run)
assert(status == "action" and action.kind == "transport")
player.uiMapID = 2472
status, action = tick(run)
assert(action.kind == "turnin")
player.uiMapID = 2248
run = make({ { kind = "transport", position = a, transport = { type = "boat" } } })
localAction = nil
status, action = tick(run)
assert(status == "action" and action.kind == "transport" and action.waitingData,
    "An unspecific arrival stays a usable instruction with unconfirmed completion")

-- Hidden tracker guidance never fakes the actual account/character flag.
done[7] = true
run, data = make({ { kind = "turnin", questID = 7, position = a } }, 7)
status, action = tick(run)
assert(status == "waiting_data" and action.reason == "tracker_not_observed" and action.positionOptional)
done[99] = true
local destination
status, action, destination = tick(run)
assert(status == "resume" and destination.uiMapID == 2472)

-- Positionless accept actions require explicit sourced auto-accept evidence.
assert(not pcall(function()
    make({ { kind = "accept", questID = 7, noArrow = true, sourceID = 1 } })
end))
done, active = {}, {}
run = make({ { kind = "accept", questID = 7, autoAccept = true, sourceID = 1,
    acceptance = { known = false, requirements = {}, sources = { "verified:auto-accept" } } } })
status, action = tick(run)
assert(status == "action" and action.positionOptional and action.questID == 7)

for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
    for _, suffix in ipairs({ "scenario", "transport", "action", "tracker_wait" }) do
        local key = "NAVIGATION_UNLOCK_" .. suffix
        assert(Lib:GetText(key, locale) ~= key)
    end
    for _, suffix in ipairs({ "currency", "reputation", "item", "skill", "spell", "spellKnown" }) do
        local key = "NAVIGATION_REQUIRES_" .. suffix
        assert(Lib:GetText(key, locale) ~= key)
    end
end
print("Unlock observations: numeric progress, no-arrow/source validation, scenarios, transport, waypoints, tracker waits and reload passed")
