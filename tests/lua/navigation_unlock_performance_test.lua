local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")
local reads, unrelatedReads = 0, 0
local data = Lib:New({ profile = "unlock-performance", environment = {
    getCharacter = function() return { mapID = 10 } end,
    isQuestCompleted = function(id)
        reads = reads + 1
        if id > 4 then unrelatedReads = unrelatedReads + 1 end
        return false
    end,
} })
local position = { x = 0, y = 0, instanceID = 0, uiMapID = 10 }
local function recipe(id, requires)
    return { id = "q" .. id, goal = { key = "quest", value = id }, requirements = requires,
        steps = { { kind = "interact", position = position, completeWhen = { quest = id } } } }
end
data.unlockRoutes = { recipe(1, { quest = 2 }), recipe(2, { quest = 3 }), recipe(3), recipe(4, { quest = 4 }) }
for id = 5, 1004 do data.unlockRoutes[#data.unlockRoutes + 1] = recipe(id) end
local cache = {}
local function create(requirements, map, clock)
    return data:CreateUnlockBuild({ { id = "gate", from = { uiMapID = map or 10 },
        blockedRequirements = requirements } }, { preflightCache = cache, clock = clock })
end
local function finish(job)
    local operations = 0
    while job.status == "planning" do
        job:Step(8, 1)
        assert(job.workLastStep <= 8)
        operations = operations + job.workLastStep
        assert(operations < 10000)
    end
    assert(job.status == "ready")
    return job.plans, operations
end
local job = create({ any = { { quest = 4 }, { quest = 1 } } })
local plans, operations = finish(job)
assert(plans[1].goals[1].value == 1 and plans[1].viability == 0,
    "A cyclic alternative must lose to a reachable prerequisite chain")
assert(unrelatedReads == 0 and job.scoredRecipes < 20 and operations < 1100,
    "Indexing is linear; only the reachable dependency closure may poll or score recipes")
local before = reads
local warm = create({ quest = 1 })
finish(warm)
assert(not warm.scoredRecipes and reads - before < 5, "A nested goal reuses the map's completed fixed point")

-- A shared cache must support a new root, and must not share character-map
-- scores with another departure map.
local extension = create({ quest = 1004 })
finish(extension)
assert(extension.scoredRecipes == 1 and unrelatedReads > 0)
local otherMap = create({ quest = 1 }, 11)
finish(otherMap)
assert(otherMap.scoredRecipes >= 3 and otherMap.plans[1].viability == 0)

-- Cancellation halfway through extending a cached graph cannot publish its
-- discovered-but-unscored nodes to a later job.
local partial = create({ quest = 1003 })
partial:Step(3, 1)
assert(partial.status == "planning")
partial:Cancel()
assert(cache.scoresByMap == nil)
local restarted = create({ quest = 1003 })
finish(restarted)
assert(restarted.plans[1].viability == 0)

local ticks = 0
local timed = create({ quest = 1002 }, 10, function() ticks = ticks + 1; return ticks end)
assert(timed:Step(0, 1) == "planning" and timed.workLastStep == 0 and ticks == 0)
assert(timed:Step(100, 0) == "planning" and timed.workLastStep == 0 and ticks == 0)
assert(timed:Step(4096, 1) == "planning" and timed.workLastStep == 1)
timed:Cancel()
local oldTicks = ticks
assert(timed:Step(4096, 1) == "cancelled" and ticks == oldTicks)
print("Unlock performance: demand-driven dependencies, cyclic alternatives, map-scoped incremental caches, cancellation and time/operation budgets passed")
