-- Join the actual walking router and transport search on invented collision.
local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
local provider = F.provider(lib, F.map({ wall = true }))
local start, goal = F.point(1, 1, 0), F.point(6, 1, 0)
local function finish(job)
    for _ = 1, 200000 do
        local state, result = job:Step(64, 10)
        assert(job.workLastStep <= 64, "Transport and terrain share the operation budget")
        if state ~= "planning" then return state, result end
    end
    error("Integrated terrain search did not complete")
end
local function route(terrain, edges)
    return finish(lib.Engine:CreateSearch({
        start = start, goal = goal, walkSpeed = 7, walkingProvider = terrain,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        walkingIsTransitive = true, edges = edges,
    }))
end
local status, walk = route(provider)
assert(status == "ready" and #walk.segments == 1)
local segment = walk.segments[1]
assert(segment.kind == "walk" and #segment.path > 2)
assert(walk.totalSeconds > 60, "The actual wall detour is slower than the invented boat")
local crossesOpening = false
for _, point in ipairs(segment.path) do
    if point.y > 6 * F.cellSize then crossesOpening = true end
end
assert(crossesOpening, "The published corridor uses the opening, not the wall")
F.near(segment.seconds, walk.totalSeconds)

local edges = {{ id = "river-boat", kind = "boat", from = start, to = goal, seconds = 60, copper = 0 }}
local trip
status, trip = route(provider, edges)
assert(status == "ready" and trip.totalSeconds == 60 and #trip.segments == 1)
assert(trip.segments[1].id == "river-boat", "Actual terrain prices select the useful transport")

status, trip = route(nil, edges)
assert(status == "ready" and trip.segments[1].kind == "walk" and not trip.segments[1].path)
F.near(trip.totalSeconds, 1000 / 21)
print("Terrain integration: actual collision path, physical transport comparison, shared budgets and legacy fallback passed")
