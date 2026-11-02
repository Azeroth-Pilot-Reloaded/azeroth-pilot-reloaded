-- Live observations and loader decisions must not weaken proved terrain paths.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, name in ipairs({ "Core.lua", "Geography.lua", "Search.lua", "Terrain.lua", "LocalRouting.lua" }) do
    dofile(root .. name)
end
local lib = LibStub("LibAPRNavigation-1.0")
local function point(x, y, z, floor, mode)
    return { instanceID = 8, uiMapID = 18, region = "outside", x = x, y = y, z = z,
        floor = floor, movementMode = mode }
end
local function node(id, x, y, z, floor, mode)
    local result = point(x, y, z, floor, mode)
    result.id = id
    return result
end
local function setup(data, environment)
    lib.terrainDatasets, lib.terrainRevision = {}, 0
    lib:RegisterTerrainData("fixture", 8, data, 1)
    return lib:New({ profile = "fixture", environment = environment or {} })
end
local function finish(job)
    for _ = 1, 20000 do
        local status, result, coverage = job:Step(5, 1)
        assert((job.workLastStep or 0) <= 5, "terrain work must remain bounded")
        if status ~= "planning" then return status, result, coverage end
    end
    error("terrain job did not finish")
end
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, tostring(actual) .. " ~= " .. tostring(expected))
end
local failures = {}
local function check(name, callback)
    local ok, reason = pcall(callback)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(reason) end
end
local function corridor()
    return { format = 1, nodes = { node(1, 0, 0, 10), node(2, 20, 0, 10) },
        edges = { { from = 1, to = 2, mode = "ground" } }, anchors = {
            { node = 1, minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = 9, maxZ = 11 },
            { node = 2, minX = 19, maxX = 21, minY = -1, maxY = 1, minZ = 9, maxZ = 11 },
        } }
end

check("XY-only endpoints project onto the unique ground surface without changing identity", function()
    local instance = setup(corridor())
    local start, goal = point(0, 0, nil), point(20, 0, nil)
    local status, edges, coverage = finish(instance:CreateTerrainEdgeBuild({ start = start, goal = goal,
        movementProfile = { groundSpeed = 10 } }))
    assert(status == "ready" and coverage.attached[start] and coverage.attached[goal], "XY-only ground endpoints must attach")
    local foundStart, foundGoal
    for _, edge in ipairs(edges) do
        if edge.from == start then
            foundStart = true
            assert(edge.polyline[1].z == 10 and edge.polyline[1].movementMode == "ground")
        end
        if edge.to == goal then
            foundGoal = true
            assert(edge.polyline[#edge.polyline].z == 10)
        end
    end
    assert(foundStart and foundGoal and start.z == nil and goal.z == nil, "request endpoints stay immutable and graph-identical")
    local route
    status, route = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = { groundSpeed = 10 } }))
    assert(status == "ready", "a unique ground surface supports ordinary XY-only objectives")
    near(route.totalSeconds, 2)
    assert(route.polyline[1].z == 10 and route.polyline[#route.polyline].z == 10)
end)

check("unknown height cannot choose between floors or an airborne volume", function()
    local raw = corridor()
    raw.nodes[#raw.nodes + 1] = node(3, 20, 0, 30, 2)
    raw.anchors[#raw.anchors + 1] = { node = 3, minX = 19, maxX = 21, minY = -1, maxY = 1, minZ = 29, maxZ = 31 }
    local instance = setup(raw)
    assert(finish(instance:CreateLocalRoute({ start = point(0, 0, 10), goal = point(20, 0, nil) })) == "waiting_data")
    raw.edges[#raw.edges + 1] = { from = 1, to = 3, mode = "ground" }
    instance = setup(raw)
    local status, route = finish(instance:CreateLocalRoute({ start = point(0, 0, 10), goal = point(20, 0, nil, 2),
        movementProfile = { groundSpeed = 10 } }))
    assert(status == "ready" and route.polyline[#route.polyline].z == 30, "an observed floor can identify the projected surface")
    instance = setup({ format = 1, nodes = { node(1, 0, 0, 100, nil, "steady") }, edges = {}, anchors = {
        { node = 1, mode = "steady", minX = -20, maxX = 20, minY = -1, maxY = 1, minZ = 99, maxZ = 101 },
    } })
    assert(finish(instance:CreateLocalRoute({ start = point(-10, 0, nil, nil, "steady"),
        goal = point(10, 0, 100, nil, "steady"), movementProfile = { canSteady = true, currentMode = "steady" } })) == "waiting_data")
end)

check("an observed floor cannot select between distinct surfaces on that floor", function()
    local instance = setup({ format = 1, nodes = {
        node("lower", 0, 0, 0, 1), node("upper", 0, 0, 20, 1), node("target", 20, 0, 20, 1),
    }, edges = { { from = "upper", to = "target", mode = "ground" } }, anchors = {
        { node = "lower", minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = -1, maxZ = 1 },
        { node = "upper", minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = 19, maxZ = 21 },
    } })
    local start, goal = point(0, 0, nil, 1), point(20, 0, 20, 1)
    assert(finish(instance:CreateLocalRoute({ start = start, goal = goal })) == "waiting_data",
        "a shared floor is not evidence of which stacked height the player occupies")
    start.z = 0
    assert(finish(instance:CreateLocalRoute({ start = start, goal = goal })) == "no_path",
        "observing the lower surface cannot borrow the upper surface's outgoing edge")
    start.z = 20
    local status, route = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = { groundSpeed = 10 } }))
    assert(status == "ready")
    near(route.totalSeconds, 2)
end)

check("a rejected middle world cannot bridge two valid portal journeys", function()
    local state = "ready"
    local instance = setup(corridor(), { requestTerrainData = function() return state, "terrain_registration_missing" end })
    local start, goal = point(0, 0, 10), point(20, 0, 10)
    start.instanceID, goal.instanceID = 9, 10
    local enter, leave = point(0, 0, 10), point(20, 0, 10)
    local transports = {
        { from = start, to = enter, kind = "portal", seconds = 1 },
        { from = leave, to = goal, kind = "portal", seconds = 1 },
        { from = start, to = goal, kind = "portal", seconds = 30 },
    }
    local function journey()
        local status, terrain, coverage = finish(instance:CreateTerrainEdgeBuild({ start = start, goal = goal,
            edges = transports, movementProfile = { groundSpeed = 10 } }))
        assert(status == "ready")
        return finish(instance:CreateSearch({ start = start, goal = goal, edgeGroups = { transports, terrain },
            canWalk = coverage.canWalk, walkingIsTransitive = false }))
    end
    local status, route = journey()
    assert(status == "ready")
    near(route.totalSeconds, 4)
    state = "missing"
    status, route = journey()
    assert(status == "ready" and #route.segments == 1, "rejected middle-world geometry cannot survive through internal edges")
    near(route.totalSeconds, 30)
end)

check("loader refusal retires cached geometry and all edges in the refused world", function()
    local state = "ready"
    local instance = setup(corridor(), { requestTerrainData = function() return state, "terrain_build_unavailable" end })
    local start, goal = point(0, 0, 10), point(20, 0, 10)
    local _, _, oldCoverage = finish(instance:CreateTerrainEdgeBuild({ start = start, goal = goal }))
    assert(oldCoverage.attached[start] and instance:CanTraverseTerrain(start, point(0.5, 0, 10), "ground") == true)
    state = "missing"
    local status, edges, coverage = finish(instance:CreateTerrainEdgeBuild({ start = start, goal = goal,
        canWalk = function() return true end }))
    assert(status == "ready" and coverage.missingData and not coverage.covered)
    assert(not coverage.attached[start] and not coverage.attached[goal] and #edges == 0,
        "refused registered packs cannot contribute attachments or internal bridge edges")
    assert(not coverage.canWalk(start, goal), "a refusal cannot restore optimistic straight walking")
    assert(instance:CanTraverseTerrain(start, point(0.5, 0, 10), "ground") == nil, "a refused pack cannot authorize visibility")
    assert(finish(instance:CreateLocalRoute({ start = start, goal = goal })) == "missing_data")
    state = "ready"
    local route
    status, route = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = { groundSpeed = 10 } }))
    assert(status == "ready", "transient refusal must not poison a later accepted geometry cache")
    near(route.totalSeconds, 2)
end)

check("a refused optional endpoint cannot leave stale edges between allowed endpoints", function()
    local raw = corridor()
    raw.nodes[#raw.nodes + 1] = node(3, 40, 0, 10)
    raw.edges[#raw.edges + 1] = { from = 2, to = 3, mode = "ground" }
    local instance = setup(raw, { requestTerrainData = function(_, _, location)
        if location.x == 40 then return "missing", "terrain_revision_unavailable" end
        return "ready"
    end })
    local start, goal, refused = point(0, 0, 10), point(20, 0, 10), point(40, 0, 10)
    local status, edges, coverage = finish(instance:CreateTerrainEdgeBuild({ start = start, goal = goal,
        edges = { { from = refused, to = refused, kind = "portal", seconds = 0 } } }))
    assert(status == "ready" and coverage.missingData and #edges == 0,
        "without pack-level acceptance, registered world geometry cannot bridge around a host refusal")
end)

check("a missing optional tile preserves accepted geometry elsewhere in the world", function()
    local raw = corridor()
    raw.nodes[#raw.nodes + 1] = node(3, 40, 0, 10)
    local instance = setup(raw, { requestTerrainData = function(_, _, location)
        if location.x == 40 then return "missing", "terrain_point_unavailable" end
        return "ready"
    end })
    local start, goal, uncovered = point(0, 0, 10), point(20, 0, 10), point(40, 0, 10)
    local request = { start = start, goal = goal, movementProfile = { groundSpeed = 10 },
        edges = { { from = uncovered, to = uncovered, kind = "portal", seconds = 0 } } }
    local status, edges, coverage = finish(instance:CreateTerrainEdgeBuild(request))
    assert(status == "ready" and coverage.missingData and coverage.attached[start] and coverage.attached[goal])
    assert(not coverage.attached[uncovered], "only the uncovered endpoint loses attachment")
    for _, edge in ipairs(edges) do assert(edge.from ~= uncovered and edge.to ~= uncovered) end
    local route
    status, route = finish(instance:CreateLocalRoute(request))
    assert(status == "ready", "an irrelevant unavailable tile cannot disable a covered local route")
    near(route.totalSeconds, 2)
end)

local function flightVolume(mode)
    return { format = 1, nodes = { node(1, 0, 0, 100, nil, mode) }, edges = {}, anchors = {
        { node = 1, mode = mode, minX = -20, maxX = 20, minY = -1, maxY = 1, minZ = 99, maxZ = 101 },
    } }
end
check("connector-only routes honor every mode capability", function()
    for _, mode in ipairs({ "ground", "steady", "skyriding" }) do
        local instance = setup(flightVolume(mode))
        local profile = { canGround = false, canSteady = false, canSkyriding = false, currentMode = mode }
        local start, goal = point(-10, 0, 100, nil, mode), point(10, 0, 100, nil, mode)
        local status = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile }))
        assert(status == "missing_data" or status == "no_path", "a disabled mode cannot supply free-volume connectors: " .. mode)
        profile[mode == "ground" and "canGround" or mode == "steady" and "canSteady" or "canSkyriding"] = true
        assert(finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile })) == "ready")
    end
end)

check("both live connector endpoints obey flight restrictions", function()
    for _, mode in ipairs({ "steady", "skyriding" }) do
        local instance = setup(flightVolume(mode))
        local profile = { canSteady = true, canSkyriding = true, currentMode = mode,
            canFlyAt = function(location) return location.x >= 0 end }
        local status = finish(instance:CreateLocalRoute({ start = point(-10, 0, 100, nil, mode),
            goal = point(10, 0, 100, nil, mode), movementProfile = profile }))
        assert(status == "missing_data" or status == "no_path", "a forbidden live departure must not gain an outward connector")
        local start, goal = point(10, 0, 100, nil, mode), point(-10, 0, 100, nil, mode)
        status = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile }))
        assert(status == "missing_data" or status == "no_path", "a forbidden live arrival must not gain an inward connector")
        profile.canFlyAt = nil
        start.noFly = true
        status = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile }))
        assert(status == "missing_data" or status == "no_path", "live noFly flags apply to outward connectors too")
    end
end)

check("parallel anchors retain independently directed paths and costs", function()
    local function anchor(bidirectional, detour)
        return { node = 1, minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = -1, maxZ = 1,
            path = { point(0, 0, 0), point(0, detour, 0), point(20, 20, 0) }, bidirectional = bidirectional }
    end
    for _, reverseOrder in ipairs({ false, true }) do
        local anchors = { anchor(false, 40), anchor(true, 20) }
        if reverseOrder then anchors[1], anchors[2] = anchors[2], anchors[1] end
        local instance = setup({ format = 1, nodes = { node(1, 20, 20, 0) }, edges = {}, anchors = anchors })
        local status, route = finish(instance:CreateLocalRoute({ start = point(20, 20, 0), goal = point(0, 0, 0),
            movementProfile = { groundSpeed = 10 } }))
        assert(status == "ready", "one-way alternatives cannot discard a reversible anchor")
        near(route.totalSeconds, 4)
        status, route = finish(instance:CreateLocalRoute({ start = point(0, 0, 0), goal = point(20, 20, 0),
            movementProfile = { groundSpeed = 10 } }))
        assert(status == "ready")
        near(route.totalSeconds, 4)
    end
end)

assert(#failures == 0, table.concat(failures, "\n"))
print("Terrain attachments: projected observations, host refusal, live permissions and independent directed anchors passed")
