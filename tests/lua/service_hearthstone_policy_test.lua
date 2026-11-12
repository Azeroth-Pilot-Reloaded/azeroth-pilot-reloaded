local library = dofile("tests/lua/navigation_engine_fixture.lua")
function LibStub() return library end
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
local nav = setmetatable({profile = "forever", env = {}}, {__index = library.Instance})
local function point(x) return {x = x, y = 0, instanceID = 0, uiMapID = 1} end
function nav:CanWalk(a, b) return a.instanceID == b.instanceID and a.uiMapID == b.uiMapID end
function nav:NormalizeLocation(p) return point(p.x * 1000) end
local edges = {}
function nav:CreateEdgeBuild() return {Step = function() return "ready", edges, {} end} end
local function finish(job)
    local status, result
    for _ = 1, 10000 do
        status, result = job:Step(32, 1)
        if status ~= "planning" then return status, result end
    end
    error("Service search failed to terminate")
end
local function recall(x)
    return {id = "synthetic-recall", kind = "item", from = point(0), to = point(x), seconds = 5,
        hearthstone = true, sourceFree = true, action = {type = "item", data = 900001}}
end
local character = {faction = "Horde", class = "PALADIN"}
-- A far trainer beside the inn must not beat the nearby trainer through recall.
nav.serviceLocations = {
    {service = "class", class = "PALADIN", name = "Nearby trainer", npcID = 11, mapID = 1, x = 30, y = 0},
    {service = "class", class = "PALADIN", name = "Distant trainer", npcID = 12, mapID = 1, x = 90, y = 0},
}
edges = {recall(900)}
local status, result = finish(nav:CreateServiceSearch({query = {service = "class"}, character = character,
    start = point(0), walkSpeed = 7}))
assert(status == "ready" and result.record.npcID == 11)
assert(result.itinerary.segments[1].kind == "walk" and not result.itinerary.hearthstoneAllowed)
-- The same policy also governs the subsequent single-destination guidance.
edges = {recall(300)}
status, result = finish(nav:CreateServiceRouteSearch({start = point(0), goal = point(300), walkSpeed = 7, edges = edges,
    canWalk = function(a, b) return nav:CanWalk(a, b) end}))
assert(status == "ready" and result.segments[1].kind == "walk" and not result.hearthstoneAllowed)

-- Ten minutes is the exact boundary; a faster recall becomes eligible only above it.
for _, seconds in ipairs({599, 600, 601}) do
    local target = seconds * 7
    local stone = recall(target)
    status, result = finish(nav:CreateServiceRouteSearch({start = point(0), goal = point(target), walkSpeed = 7,
        edges = {stone}, canWalk = function(a, b) return nav:CanWalk(a, b) end}))
    assert(status == "ready" and result.withoutHearthstoneSeconds == seconds)
    assert(result.hearthstoneAllowed == (seconds > 600))
    assert((result.segments[1].kind == "item") == (seconds > 600))
end
-- A long-trip shortcut still goes to the destination chosen without recall.
edges = {recall(9000)}
function nav:NormalizeLocation(p) return point(p.x * 10000) end
nav.serviceLocations = {
    {service = "bank", name = "Nearest bank", npcID = 21, mapID = 1, x = 50, y = 0},
    {service = "bank", name = "Bank at inn", npcID = 22, mapID = 1, x = 90, y = 0},
}
status, result = finish(nav:CreateServiceSearch({query = {service = "bank"}, start = point(0), walkSpeed = 7}))
assert(status == "ready" and result.record.npcID == 21 and result.itinerary.hearthstoneAllowed)
assert(result.itinerary.goalIndex == 1 and result.totalSeconds < result.itinerary.withoutHearthstoneSeconds)
-- No ordinary path: a known available recall is a legitimate last resort.
status, result = finish(nav:CreateServiceRouteSearch({start = point(0), goal = point(9000), walkSpeed = 7,
    edges = edges, canWalk = function(a, b) return a.x == b.x end}))
assert(status == "ready" and result.segments[1].hearthstone and result.hearthstoneAllowed)
status = finish(nav:CreateServiceRouteSearch({start = point(0), goal = point(9000), walkSpeed = 7,
    edges = edges, waitingData = true, canWalk = function(a, b) return a.x == b.x end}))
assert(status == "no_path", "Incomplete access data cannot justify consuming a recall")
-- The ordinary route planner retains its original shortest-time behavior.
status, result = finish(nav:CreateSearch({start = point(0), goal = point(9000), walkSpeed = 7,
    edges = edges, canWalk = function(a, b) return nav:CanWalk(a, b) end}))
assert(status == "ready" and result.segments[1].kind == "item")
assert(not nav:IsServiceItineraryAllowed({{hearthstone = true}}, 1, {hearthstoneAllowed = false}))
assert(nav:IsServiceItineraryAllowed({{hearthstone = true}, {kind = "walk"}}, 2, {hearthstoneAllowed = false}))
assert(nav:IsServiceItineraryAllowed({{hearthstone = true}}, 1, {hearthstoneAllowed = true}))
print("Service hearthstones: nearby trainers, ordinary-travel ranking, ten-minute boundary, selected destination, long-trip recall, pending data and normal-route isolation passed")
