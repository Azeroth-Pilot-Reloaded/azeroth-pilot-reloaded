local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local data = F.map()
data.nx = 2
for _, field in ipairs({ "grid", "height", "class" }) do data[field][2] = data[field][1] end
local function graph(cell, offset)
    local node = F.number(cell, 3) .. "A" .. F.number(1, 2) .. "B"
    local edge = F.number(offset, 1) .. "AA" .. string.rep(F.number(67, 3), 3) .. F.number(67, 2)
    return "AB" .. node .. edge
end
data.graph = { graph(7 * 8 + 1, 7), graph(1, 1) }
local provider = F.provider(lib, data)
local a, b = F.point(1, 1, 0), F.point(14, 1, 0)
local job = provider:CreatePathJob(a, b, { walkSpeed = 10 })
local status, result = F.finish(job, 1)
assert(status == "ready", tostring(job.error))
F.near(result.yards, 13 * F.cellSize)
F.near(result.seconds, 13 * F.cellSize / 10)
assert(result.path[1].x == a.x and result.path[#result.path].x == b.x)
local reverse = provider:CreatePathJob(b, a, { walkSpeed = 10 })
assert(F.finish(reverse, 1) == "ready", tostring(reverse.error))
local quickStatus, quick = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10, quick = true }), 1)
assert(quickStatus == "ready")
F.near(quick.yards, 13 * F.cellSize)
for i = 2, #quick.path do
    assert(provider:CanFollowWalkingSegment(quick.path[i - 1], quick.path[i]))
end
-- Removing both boundary edges proves the two complete tiles disconnected.
data.graph = { "AB" .. F.number(57, 3) .. "AABA", "AB" .. F.number(1, 3) .. "AABA" }
F.provider(lib, data, 2)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 })) == "no_path")
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10, quick = true })) == "no_path")
data.graph[1] = "AB"
F.provider(lib, data, 3)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 })) == "unavailable",
    "Truncated graph records cannot prove a disconnection")
print("terrain runtime graph: hierarchical boundary crossings, directed edges and graph corruption passed")

local function portal(cell, degree)
    return F.number(cell, 3) .. "AAA" .. F.number(degree, 1)
end

local function link(offset, index)
    return F.number(offset, 1) .. F.number(index - 1, 2) .. string.rep(F.number(67, 3), 3) .. "AB"
end

-- Three cheap foreground entrances lead nowhere. A fourth, further away,
-- crosses two pages in one direction. The complete search must recover.
do
    local map = F.map()
    map.nx = 3
    for _, key in ipairs({"grid", "height", "class"}) do
        map[key][2], map[key][3] = map[key][1], map[key][1]
    end
    map.graph = {
        "AE" .. portal(51, 0) .. portal(50, 0) .. portal(52, 0) .. portal(63, 1) .. link(7, 1),
        "AC" .. portal(7, 1) .. portal(63, 1) .. link(4, 2) .. link(7, 1),
        "AB" .. portal(7, 0),
    }
    local walker = F.provider(lib, map, 4)
    local start, goal = F.point(6, 3, 0), F.point(17, 7, 0)
    local job = walker:CreatePathJob(start, goal, {
        quick = true, walkingOrigin = start, walkingGoal = goal, previewWalking = true,
    })
    local status, path, ends
    repeat
        status, path = job:Step(1, 10)
        if status == "planning" and job.walkingPreview and #job.walkingPreview == 2 then ends = job.walkingPreview end
    until status ~= "planning"
    assert(ends and ends[2].breakBefore, "Both refinements are available before the middle, with a gap between them")
    for _, section in ipairs(ends) do
        for i = 2, #section.path do
            assert(walker:CanFollowWalkingSegment(section.path[i - 1], section.path[i]))
        end
    end
    assert(status == "ready" and path.path[#path.path].x == goal.x)
    for i = 2, #path.path do
        assert(walker:CanFollowWalkingSegment(path.path[i - 1], path.path[i]))
    end
    assert(F.finish(walker:CreatePathJob(goal, start, {quick = true}), 1) == "no_path")

    local function exactPath(target)
        local query = walker:CreatePathJob(start, target, {clock = function() return 0 end})
        local state, result, operations = "planning", nil, 0
        while state == "planning" and operations < 1000 do
            state, result = query:Step(2, 1)
            operations = operations + query.workLastStep
        end
        assert(state == "ready")
        F.near(result.path[#result.path].x, target.x)
        for i = 2, #result.path do
            assert(walker:CanFollowWalkingSegment(result.path[i - 1], result.path[i]))
        end
        return operations
    end
    -- The quick queries have loaded the tiles. Distinct exact goals still
    -- share the verified graph's departure and intermediate-tile witnesses.
    local firstWork = exactPath(goal)
    local secondWork = exactPath(F.point(18, 7, 0))
    assert(secondWork < firstWork, "Adjacent goals should reuse directed walking work from the same departure")
end

-- Two parallel corridors cross both tiles. The portal graph can enter the
-- pin's corridor, but the player on the other side of the wall cannot.
do
    local map = F.map()
    map.nx = 2
    local columns = string.rep("QQQAQQQQ", 8)
    local heights = string.rep("X", 56)
    map.grid, map.height = {columns, columns}, {heights, heights}
    map.graph = {
        "AC" .. portal(57, 1) .. portal(62, 1) .. link(7, 1) .. link(7, 2),
        "AC" .. portal(1, 0) .. portal(6, 0),
    }
    local walker = F.provider(lib, map, 5)
    local below, above, pin = F.point(1, 1, 0), F.point(1, 6, 0), F.point(10, 5)
    local approach = walker:CreatePathJob(below, pin, {walkingGoalXY = true,
        walkingGoalApproach = 4 * F.cellSize, walkingGoal = pin})
    local state, route, work = "planning", nil, 0
    while state == "planning" do
        state, route = approach:Step(4, 10)
        work = work + approach.workLastStep
        assert(work <= 80, "Nearby rejected anchors should reuse the directed reachability proof")
    end
    assert(state == "ready" and route.approach and route.partial)
    F.near(route.approach.x, pin.x)
    F.near(route.approach.y, F.point(10, 2).y)
    for i = 2, #route.path do
        assert(walker:CanFollowWalkingSegment(route.path[i - 1], route.path[i]))
    end

    local exact, path = F.finish(walker:CreatePathJob(above, pin, {walkingGoalXY = true}), 4)
    assert(exact == "ready" and path.approach == nil)
    F.near(path.path[#path.path].x, pin.x)
    F.near(path.path[#path.path].y, pin.y)
end

-- A short verified chord can guide immediately while the actual objective is
-- still pending. Missing access or a blocked chord must not start guidance.
do
    local function departure(map, revision, from, to, mayPreview, accessBoundary)
        local walker, instance = F.provider(lib, map, revision)
        instance.config = {}
        function instance:CanWalk(a, b) return a.uiMapID == b.uiMapID end
        function instance:GetRemappedMapID(id, _, x)
            if accessBoundary and x > from.x and x < to.x then return 2 end
            return id
        end
        from.uiMapID, to.uiMapID = 1, 1
        local job = walker:CreatePathJob(from, to, {previewDeparture = true, clock = function() return 0 end})
        local state, route = job:Step(4096, 1)
        local first = job.walkingPreview and job.walkingPreview[1]
        if mayPreview then
            assert(state == "planning" and first and #first.path == 2)
            F.near(first.path[1].x, from.x)
            F.near(first.path[2].x, from.x + 28)
            assert(walker:CanFollowWalkingSegment(first.path[1], first.path[2]))
            state, route = F.finish(job)
        else
            assert(first == nil)
        end
        if state == "ready" then F.near(route.path[#route.path].x, to.x) end
        return state
    end
    assert(departure(F.map(), 6, F.point(1, 1, 0), F.point(6, 1, 0), true) == "ready")
    assert(departure(F.map(), 7, F.point(1, 1, 0), F.point(6, 1, 0), false, true) == "ready")
    local blocked = F.point(2, 1, 0)
    blocked.x = 3 * F.cellSize - 3
    assert(departure(F.map({wall = true, disconnected = true}), 8, blocked, F.point(6, 1, 0), false) == "no_path")
end
