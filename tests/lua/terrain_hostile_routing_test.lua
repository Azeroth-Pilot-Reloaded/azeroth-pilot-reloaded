local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local start, goal = F.point(1, 3, 0), F.point(6, 3, 0)

local function makeMap(allY, side)
    local map = F.map()
    map.factionCosts = true
    local classes = {}
    for x = 0, 7 do
        for y = 0, 7 do
            classes[#classes + 1] = F.number(x == 3 and (allY or (y >= 1 and y <= 5)) and side or 0, 1)
        end
    end
    map.class[1] = table.concat(classes)
    return map
end

local function route(provider, faction, from, to)
    local job = provider:CreatePathJob(from or start, to or goal, { walkSpeed = 10, faction = faction })
    local status, result = F.finish(job)
    assert(status == "ready", tostring(job.error))
    return result
end

local provider = F.provider(lib, makeMap(false, 16))
local alliance, horde = route(provider, "Alliance"), route(provider, "Horde")
assert(alliance.yards > horde.yards and not alliance.path.lastHostileIndex)
F.near(alliance.weightedSeconds, alliance.seconds)
F.near(horde.yards, F.cellSize * 5)
F.near(horde.weightedSeconds, horde.seconds)
assert(not horde.path.lastHostileIndex and not route(provider).weightedSeconds)

provider = F.provider(lib, makeMap(true, 8), 2)
horde = route(provider, "Horde")
F.near(horde.seconds, F.cellSize * 0.5)
F.near(horde.weightedSeconds, horde.seconds + 19 * F.cellSize / 10)
assert(horde.path.lastHostileIndex >= 2 and horde.path[horde.path.lastHostileIndex].hostileDistance > 0)
assert(not route(provider, "Alliance").path.lastHostileIndex)
assert(route(provider, "Horde", start, F.point(3, 3, 0)).path.lastHostileIndex)
assert(route(provider, "Horde", F.point(3, 3, 0), goal).path.lastHostileIndex)
goal.terrainFaction = "Horde"
assert(provider:CanFollowWalkingSegment(start, goal, "outdoor") == false)

local job = provider:CreateCostJob(start, {goal}, {walkSpeed = 10, faction = "Horde"})
local state, prices = F.finish(job)
assert(state == "ready")
F.near(prices.costs[1].seconds, horde.seconds)
F.near(prices.costs[1].weightedSeconds, horde.weightedSeconds)


-- A hub footprint can begin at the shared tile boundary.
local boundary = F.map()
boundary.nx, boundary.factionCosts = 2, true
boundary.grid[2], boundary.height[2] = boundary.grid[1], boundary.height[1]
boundary.class[2] = string.rep(F.number(16, 1), 8) .. string.rep("A", 56)
local function crossing(cell, offset)
    return "AB" .. F.number(cell, 3) .. "AABB"
        .. F.number(offset, 1) .. "AA" .. string.rep(F.number(67, 3), 3) .. F.number(67, 2)
end
boundary.graph = {crossing(57, 7), crossing(1, 1)}
provider = F.provider(lib, boundary, 3)
local west, east = F.point(6, 1, 0), F.point(10, 1, 0)
alliance = route(provider, "Alliance", west, east)
horde = route(provider, "Horde", west, east)
F.near(alliance.seconds, horde.seconds)
F.near(alliance.weightedSeconds - horde.weightedSeconds, 19 * F.cellSize / 10)
assert(alliance.path.lastHostileIndex and not horde.path.lastHostileIndex)
