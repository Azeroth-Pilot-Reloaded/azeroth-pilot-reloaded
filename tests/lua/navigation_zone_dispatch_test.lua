-- Synthetic acquisition graph; production campaign edits do not change these expectations.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.maps[102] = { mapType = 3, parentMapID = 101 }
fixture.maps[101] = { mapType = 3, parentMapID = 2274 }
fixture.maps[2274] = { mapType = 2, parentMapID = 947 }
fixture.maps[104] = { mapType = 3, parentMapID = 105 }
fixture.maps[105] = { mapType = 2, parentMapID = 947 }
C_Map.GetWorldPosFromMapPos = function(map, pos)
    return map == 104 and 3 or 1, { x = pos.x * 1000, y = pos.y * 1000 }
end
local catalog = dofile("tests/lua/navigation_unlock_test_catalog.lua")
catalog.config = { ZoneRoutes = { [104] = "fixture-gated-portal", [105] = "fixture-gated-portal" } }
catalog.connections = { { id = "fixture-gated-portal", kind = "portal",
    from = { instanceID = 1, uiMapID = 102, x = 400, y = 230 },
    to = { instanceID = 3, uiMapID = 104, x = -1300, y = -500 }, seconds = 5,
    requirements = { minLevel = 80, any = { { quest = 12 }, { questActive = 12 } } } } }
local data = fixture:Load(catalog)
local completed, active, unknown, builds = {}, {}, false, 0
data.env.getCharacter = function() return { mapID = 102, level = 90, faction = "Horde" } end
data.env.isQuestCompleted = function(id) if not unknown then return completed[id] == true end end
data.env.isQuestActive = function(id) if not unknown then return active[id] == true end end
data.env.getItemCount = function() error("Zone dispatch cannot inspect unrelated items") end
local createEdgeBuild = data.CreateEdgeBuild
function data:CreateEdgeBuild(context)
    assert(context.connectionID == "fixture-gated-portal", "Only the indexed entrance may be prepared")
    builds = builds + 1
    return createEdgeBuild(self, context)
end
-- The immutable lookup owns connection references. Access checks must work
-- without even reading the full connection list after initialization.
data.connections = setmetatable({}, { __index = function() error("Whole catalogue read") end })
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local start = { x = 400, y = 230, uiMapID = 102, instanceID = 1 }
local goal = { x = -1343, y = -515.6, uiMapID = 104, instanceID = 3 }
local function create(options)
    options = options or {}
    return APR.NavigationPlanner:Create({ preferZoneAccess = true, data = data,
        start = options.start or start, goal = options.goal or goal, playerPosition = start,
        localObjective = options.localObjective, walkSpeed = 7,
        adapter = { CreatePreparation = function() error("Zone dispatch cannot scan inn bindings") end },
        taxiData = { BuildEdges = function() error("Zone dispatch cannot scan taxi paths") end },
        engine = { CreateSearch = function() error("Zone dispatch cannot launch a world graph search") end },
        prepareSegment = function(segment) return segment end })
end
local function finish(job)
    local slices = 0
    while job.status == "planning" do
        job:Step(4096, 1)
        slices = slices + 1
        assert(slices <= 6, "A listed destination cannot spend thousands of frames in global planning")
    end
    return job, slices
end
local blocked = finish(create())
assert(blocked.status == "no_path" and #blocked.blockers == 1 and not blocked.waitingData)
assert(blocked.blockers[1].id == "retail:fixture-gated-portal:forward")
assert(blocked.blockers[1].blockedRequirements.any[1].quest == 12 and builds == 1,
    "A failed destination condition immediately selects its real unlock evidence")

completed[13] = true
data.env.isQuestAvailable = function() return nil end
data.env.isQuestReadyForTurnIn = function() return false end
local unlock = data:CreateUnlockSession({ blockers = blocked.blockers, destination = goal })
local unlockStatus, action
for _ = 1, 64 do
    unlockStatus, action = unlock:Step(4096, 1)
    if unlockStatus ~= "planning" then break end
end
assert(unlockStatus == "action" and action.questID == 11,
    "The direct destination blocker starts the existing sourced unlock chain")

unknown = true
local pending = finish(create())
assert(pending.status == "no_path" and pending.waitingData,
    "Unobserved quest flags must wait for data instead of starting a false unlock")
unknown, active[12] = false, true
local open = finish(create())
assert(open.status == "ready" and open.zoneRouted and #open.result.queue == 3)
assert(open.result.queue[2].id == "retail:fixture-gated-portal:forward")
assert(open.result.queue[1].from == start and open.result.queue[3].to == goal)
assert(open.result.queue[2].canStart, "The selected portal retains live departure validation")

local definition = data.connectionLookup["fixture-gated-portal"]
definition.copper = 100
local priced = data:CreateZoneRoute({ start = start, goal = goal, walkSpeed = 7, budget = 0 })
assert(priced:Step(1, 1) == "planning" and priced:Step(4096, 1) == "fallback",
    "An indexed physical crossing still respects the character's money budget")
definition.copper = nil

active[12], completed[12] = false, true
assert(finish(create()).status == "ready")
completed[12] = false
local prior = builds
local localRun = finish(create({ localObjective = true,
    goal = { x = 410, y = 250, uiMapID = 102, instanceID = 1 } }))
assert(localRun.status == "ready" and #localRun.result.queue == 1 and builds == prior,
    "A local unlock action needs a direct arrow without catalogue, inn, taxi or global graph work")

-- Already being in the destination bypasses an entrance condition, including
-- a character who arrived through a different means.
local inside = finish(create({ start = { x = 10, y = 20, uiMapID = 104, instanceID = 3 } }))
assert(inside.status == "ready" and builds == prior)

local childGoal = { x = -1343, y = -515.6, uiMapID = 9999, instanceID = 3 }
fixture.maps[9999] = { mapType = 3, parentMapID = 104 }
assert(finish(create({ goal = childGoal })).status == "no_path", "Child maps reuse the listed zone entrance")
assert(finish(create({ goal = { x = 0, y = 0, uiMapID = 105, instanceID = 3 } })).status == "no_path",
    "The native K'aresh zone map and its destination submap share the same entrance")
local cancelled = create()
cancelled:Step(1, 1)
cancelled:Cancel()
assert(cancelled:Step(4096, 1) == "cancelled")
print("Zone dispatch: indexed real K'aresh condition, immediate blockers, pending flags, direct portal, local unlock arrow, child maps and cancellation; zero world/taxi/inn scans passed")
