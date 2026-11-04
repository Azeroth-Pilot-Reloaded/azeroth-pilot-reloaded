-- Scoped free travel cannot erase the ordinary approaches outside its bounds.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local function near(actual, expected)
    assert(type(actual) == "number" and math.abs(actual - expected) < 1e-8,
        tostring(actual) .. " ~= " .. tostring(expected))
end
for _, profile in ipairs({"retail", "forever"}) do
    fixture.profile = profile
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    data.env.requestTerrainData = function() return "ready" end
    local function point(x, extra)
        local p = {instanceID = 8, uiMapID = 501, x = x, y = 0, z = 0}
        for key, value in pairs(extra or {}) do p[key] = value end
        return p
    end
    local west = {id = "west", bounds = {minX = 10, maxX = 20, minY = -5, maxY = 5, minZ = -1, maxZ = 1}}
    local left, right = 9.991, 20.009
    local raw = {format = 1, scope = west, nodes = {
        {id = "entry", x = left, y = 0, z = 0, uiMapID = 501, terrainBoundary = "west"},
        {id = "exit", x = right, y = 0, z = 0, uiMapID = 501, terrainBoundary = "west"},
        {id = "far", x = 1000, y = 0, z = 0, uiMapID = 501},
    }, edges = {{from = "entry", to = "exit", mode = "ground", seconds = 0},
        {from = "entry", to = "far", mode = "ground", seconds = 0}}}
    lib:RegisterTerrainData(profile, 8, raw, 1, "fixture")
    local query = data:CreateTerrainScopeQuery()
    for _, mode in ipairs({"ground", "steady", "skyriding"}) do
        for _, upper in ipairs({1, 7, 30, 60, 80}) do
            near(data:GetTerrainWalkLowerBound(point(0, {movementMode = mode}),
                point(30, {movementMode = mode}), upper, query), 19.98 / upper)
        end
    end
    near(data:GetTerrainWalkLowerBound(point(0), point(5), 1, query), 5)
    near(data:GetTerrainWalkLowerBound(point(15), point(30), 1, query), 9.99)
    near(data:GetTerrainWalkLowerBound(point(0, {y = 15}), point(30, {y = 15}), 1, query), 19.98 * math.sqrt(2))
    near(data:GetTerrainWalkLowerBound(point(0, {z = 1000}), point(30, {z = -1000}), 1, query), 19.98)
    for _, upper in ipairs({0, -1, math.huge, "fast", false}) do
        assert(data:GetTerrainWalkLowerBound(point(0), point(30), upper, query) == 0)
    end
    assert(data:GetTerrainWalkLowerBound(point(0), point(30), nil, query) == 0)
    assert(data:GetTerrainWalkLowerBound(point(0), point(30), 0 / 0, query) == 0)
    assert(data:GetTerrainWalkLowerBound(point(0), point(30, {instanceID = 9}), 1, query) == 0)
    assert(data:GetTerrainWalkLowerBound(point(0, {x = math.huge}), point(30), 1, query) == 0)
    assert(data:GetTerrainWalkLowerBound(point(0), point(30), 1e-308, query) == 0)

    -- A native zero-cost edge may end far outside the scope, but that node is
    -- never an automatic exit. The bound must not apply to such a native target.
    local build = data:CreateTerrainEdgeBuild({start = point(0), goal = point(1000),
        canWalk = function() return true end, walkSpeed = 1})
    for _ = 1, 10000 do if build:Step(16, 1) ~= "planning" then break end end
    assert(build.status == "ready")
    local far
    for _, node in pairs(build.nodes) do if node.x == 1000 then far = node end end
    assert(far and far.noAutoconnect)
    assert(data:GetTerrainWalkLowerBound(point(0), far, 1, query) == 0)
    local function route(goal)
        local search = data:CreateSearch({start = point(0), goal = goal, edges = build.result,
            canWalk = build.coverage.canWalk, canAutoconnectAt = build.coverage.canAutoconnectAt, walkSpeed = 1})
        for _ = 1, 10000 do if search:Step(16, 1) ~= "planning" then break end end
        assert(search.status == "ready")
        return search:GetResult()
    end
    near(route(far).totalSeconds, left)
    local ordinary = route(point(1000))
    near(ordinary.totalSeconds, left + 1000 - right)
    local bound = data:GetTerrainWalkLowerBound(point(0), point(1000), 1, query)
    near(bound, 989.98)
    assert(bound <= ordinary.totalSeconds,
        "Zero-cost nonautomatic outliers cannot manufacture free ordinary egress")

    -- The speed guarantee is opt-in; unknown worlds, malformed inventories and
    -- custom factories keep the original zero bound.
    local constructor, requirements = data.CreateTerrainEdgeBuild, data.GetRequiredTerrainScopes
    data.CreateTerrainEdgeBuild = function(self, request) return constructor(self, request) end
    assert(data:GetTerrainWalkLowerBound(point(0), point(30), 1, query) == 0)
    data.CreateTerrainEdgeBuild = constructor
    data.GetRequiredTerrainScopes = function(self, ...) return requirements(self, ...) end
    assert(data:GetTerrainWalkLowerBound(point(0), point(30), 1, query) == 0)
    data.GetRequiredTerrainScopes = requirements
    local oldScopes = data.env.getTerrainScopes
    for _, inventory in ipairs({{scopes = {}, unbounded = true}, {scopes = {}, unbounded = false},
        {scopes = {{id = "invalid", bounds = {}}}, unbounded = false}}) do
        data.env.getTerrainScopes = function() return inventory.scopes, inventory.unbounded end
        assert(data:GetTerrainWalkLowerBound(point(0), point(30), 1, data:CreateTerrainScopeQuery()) == 0)
    end
    data.env.getTerrainScopes = oldScopes
    near(data:GetTerrainWalkLowerBound(point(0), point(30), 1, query), 19.98)

    -- Every declared scope participates, including unloaded or inaccessible
    -- ones: treating extra geometry as free only makes a bound more optimistic.
    local east = {id = "east", accessKey = "private", bounds = {
        minX = 100, maxX = 110, minY = -5, maxY = 5, minZ = -1, maxZ = 1}}
    data.env.getTerrainScopes = function(_, world) if world == 8 then return {west, east}, false end return {}, false end
    lib.terrainRevision = (lib.terrainRevision or 0) + 1
    near(data:GetTerrainWalkLowerBound(point(0), point(120), 1, query), 19.98)
    local gapStart, gapEnd = point(50), point(80)
    near(data:GetTerrainWalkLowerBound(gapStart, gapEnd, 1, query), 30)
    near(data:GetTerrainWalkLowerBound(point(22), point(98), 1, query), 3.98)
    gapStart.x, gapEnd.x = 22, 98
    near(data:GetTerrainWalkLowerBound(gapStart, gapEnd, 1, query), 3.98)
    local boundsReads = 0
    for _, copied in ipairs(query.worlds[8].scopes) do
        local fields = copied.bounds
        copied.bounds = setmetatable({}, {__index = function(_, key) boundsReads = boundsReads + 1; return fields[key] end})
    end
    for _ = 1, 1000 do near(data:GetTerrainWalkLowerBound(gapStart, gapEnd, 1, query), 3.98) end
    assert(boundsReads == 0, "Nearest-pocket distances are cached per unchanged point, rather than per candidate pair")
    local observed = setmetatable({}, {__mode = "v"})
    do
        local transient = point(21)
        observed[1] = transient
        near(data:GetTerrainWalkLowerBound(transient, gapEnd, 1, query), 2.98)
    end
    collectgarbage("collect"); collectgarbage("collect")
    assert(observed[1] == nil, "Lower-bound observations cannot retain retired positions")

    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local function planner(upper, walkSeconds)
        return APR.NavigationPlanner:Create({data = data, start = point(0, {instanceID = 1}),
            goal = point(0, {instanceID = 2}), walkSpeed = 7, ordinaryWalkSpeedUpperBound = upper,
            walkSecondsFor = walkSeconds or function() return 123 end})
    end
    assert(planner(nil):GetOptimisticWalkSeconds(point(0), point(120)) == 0)
    assert(planner(nil, function() return 0 end):GetOptimisticWalkSeconds(point(0), point(120)) == 0,
        "A custom ordinary cost without an explicit upper-speed guarantee keeps zero")
    near(planner(60):GetOptimisticWalkSeconds(point(0), point(120)), 19.98 / 60)
    local proved = planner(60)
    proved.terrainScopes[8] = {west = true, east = true}
    assert(proved:GetOptimisticWalkSeconds(point(0), point(120)) == 123,
        "The special lower bound only applies while additional terrain remains unresolved")
end
print("Terrain walk bounds: native zero costs, boundary tolerance, arbitrary nonautomatic outliers, all scoped pockets, modes, speed guarantees and conservative fallbacks passed")
