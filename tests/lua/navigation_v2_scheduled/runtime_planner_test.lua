local R = dofile("tests/lua/navigation_v2_scheduled/runtime_fixture.lua")
local request = { from = "start", to = "goal" }

-- Arrival at the pier is105, ready111: departure110 is missed; crossing79 loses to60.
local planner = R.Planner(R.Graph(5, 60), { scheduled = { R.Timed() } })
local result = R.Finish(planner:Plan(request))
assert(result.status == "complete" and result.optimal and result.estimatedSeconds == 60)
assert(#result.segments == 1 and result.segments[1].edgeId == "overland")

planner = R.Planner(R.Graph(5, 80), { scheduled = { R.Timed() } })
result = R.Finish(planner:Plan(request))
assert(result.status == "complete" and result.estimatedSeconds == 79)
assert(result.segments[2].kind == "scheduled" and result.segments[2].transportId == "river crossing")
assert(result.segments[2].costDetail.waitSeconds == 29 and result.segments[2].costDetail.departureAt == 140)
assert(result.segments[2].costDetail.waitMode == "periodic")
assert(R.Finish(planner:Plan({ from = "east pier", to = "west pier" })).status == "no_path")

planner = R.Planner(R.Graph(4, 60), { scheduled = { R.Timed() } })
result = R.Finish(planner:Plan(request))
assert(result.estimatedSeconds == 49 and result.segments[2].costDetail.waitSeconds == 0)

-- Epoch is captured by Plan, not sampled anew for each relaxation.
local time, ns
planner, time = R.Planner(R.Graph(5, 80), { scheduled = { R.Timed() } })
local frozen = planner:Plan(request)
time.now = 101
assert(R.Finish(frozen).estimatedSeconds == 79)

ns = R.Load()
local movement = assert(ns.LibAPRNavigationV2.NewForeverMovement({ initialMode = "mount", level = 40,
    mountOwned = true, mountUsable = true, canMountHere = true }, { mountSpeed = 1, dismountSeconds = 2 }))
local graph = R.Graph(4, 100)
graph.edges[1].movement = { mode = "mount", distance = 4, canMount = "available" }
planner = assert(ns.LibAPRNavigationV2.New(graph, { scheduled = { R.Timed() }, movement = movement,
    clock = function() return 100 end, profileClock = function() return 0 end }))
result = R.Finish(planner:Plan(request))
assert(result.estimatedSeconds == 79, "Dismount must happen before timetable selection, not after")
assert(result.segments[2].costDetail.waitSeconds == 28 and result.segments[2].seconds == 72)
assert(result.segments[2].mode == "walk" and result.segments[2].transitionSeconds == 2)
assert(result.segments[3].transitionSeconds == 0, "Dismount is charged once")

local route = R.Timed()
planner = R.Planner(R.Graph(), { scheduled = { route } })
route.wait.firstDeparture, route.costs.ride = 999, 999
result = R.Finish(planner:Plan(request))
assert(result.estimatedSeconds == 79, "External timetable edits cannot mutate the query snapshot")
local old = result
local pending = planner:Plan(request)
assert(planner:SetScheduled({ R.Timed() }, { [route.id] = { ride = 1 } }))
assert(not planner:IsCurrent(old) and R.Finish(pending).status == "stale")
assert(select(2, planner:StartTravel(old)) == "stale_result")
result = R.Finish(planner:Plan(request))
assert(result.estimatedSeconds == 50)
local revision = planner.revision
assert(planner:SetScheduled({ R.Timed() }, { [route.id] = { ride = 1 } }) == false and planner.revision == revision)
local unknown = R.Timed(); unknown.access = "unknown"
graph = R.Graph(); graph.edges = { graph.edges[1], graph.edges[2] }
planner = R.Planner(graph, { scheduled = { unknown } })
result = R.Finish(planner:Plan(request))
assert(result.status == "unknown" and result.reason == "unknown_access" and not result.segments)
graph.complete = false
unknown.access = "unavailable"
planner = R.Planner(graph, { scheduled = { unknown } })
result = R.Finish(planner:Plan(request))
assert(result.status == "unknown" and result.reason == "incomplete_graph")

-- Malformed endpoint references are distinct from proven disconnection.
route = R.Timed(); route.to = "unindexed destination"
planner = R.Planner(R.Graph(), { scheduled = { route } })
result = R.Finish(planner:Plan(request))
assert(result.status == "invalid" and result.reason == "invalid_transport_node")

-- A transport overlay must not turn missing destination terrain into arrival.
local SF = dofile("tests/lua/navigation_v2_sectors/fixture.lua")
local _, _, sectorTime, source = SF.New({ edit = function(_, catalog) catalog.harbor = nil end })
route = R.Timed(); route.from = "meadow:terrain:1"; route.to = "harbor:terrain:1"
ns = R.Load()
planner = assert(ns.LibAPRNavigationV2.New(source, { scheduled = { route },
    clock = function() return sectorTime.wall end, profileClock = function() return 0 end }))
result = R.Finish(planner:Plan({ from = route.from, to = route.to }))
assert(result.status == "unknown" and not result.segments)
assert(result.objective.to == route.to)
