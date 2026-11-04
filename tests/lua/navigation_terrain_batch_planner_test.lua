-- Small inter-world terrain inventories should be prepared once, rather than
-- rebuilding the same city after each optimistic doorway. Local/large worlds
-- keep lazy loading, and unrelated missing geometry cannot hide a usable path.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({"retail", "forever"}) do
    fixture.profile = profile
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    local function point(world, x)
        return {instanceID = world, x = x, y = 0, z = 0, region = "synthetic-outdoors"}
    end
    for index = 1, 6 do
        local x = index <= 5 and (index - 1) * 10 or 1000
        local id = "volume-" .. index
        local raw = {format = 1, scope = {id = id, bounds = {
            minX = x, maxX = x + 5, minY = -1, maxY = 1, minZ = -1, maxZ = 1}},
            nodes = {
                {id = "west", x = x, y = 0, z = 0, region = "synthetic-outdoors", terrainBoundary = id},
                {id = "east", x = x + 5, y = 0, z = 0, region = "synthetic-outdoors", terrainBoundary = id},
            }, edges = {{from = "west", to = "east", mode = "ground", seconds = 10}}}
        if index == 1 then
            raw.nodes[#raw.nodes + 1] = {id = "origin", x = 1, y = 0, z = 0, region = "synthetic-outdoors"}
            raw.edges[#raw.edges + 1] = {from = "origin", to = "east", mode = "ground", seconds = 4}
        end
        lib:RegisterTerrainData(profile, 8, raw, 1, id)
    end
    lib:RegisterTerrainData(profile, 77, {format = 1, nodes = {}, edges = {}}, 1, "unrelated-world")
    local loads = {}
    data.env.requestTerrainData = function(_, world, _, selection)
        assert(world ~= 77, "Batching must not request an unrelated catalogue world")
        for id in pairs(selection and selection.scopeIDs or {}) do
            loads[id] = (loads[id] or 0) + 1
            if id == "volume-6" then return "missing", "pack_unavailable" end
        end
        return "ready"
    end
    local start, goal = point(8, 1), point(9, 100)
    local portal = {kind = "portal", from = point(8, 50), to = goal, seconds = 2}
    data.CreateEdgeBuild = function()
        return {Step = function() return "ready", {portal}, {resources = {}} end}
    end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local searches = 0
    local request = {data = data, start = start, goal = goal, walkSpeed = 1,
        ordinaryWalkSpeedUpperBound = 1, immutablePositions = true,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        taxiData = {BuildEdges = function() return {} end},
        prepareSegment = function(segment) return segment end,
        engine = {CreateSearch = function(_, input)
            searches = searches + 1
            return lib.Engine:CreateSearch(input)
        end}}
    local function finish(limit, localGoal)
        request.terrainScopeBatchLimit, request.goal = limit, localGoal or goal
        searches, loads = 0, {}
        local job = APR.NavigationPlanner:Create(request)
        for _ = 1, 100000 do
            if job:Step(16, 1) ~= "planning" then break end
        end
        assert(job.status == "ready", "Unavailable unrelated geometry cannot discard the complete physical route")
        return job:GetResult(), job
    end
    local result = finish()
    assert(result.totalSeconds == 71 and searches == 2 and not loads["volume-6"],
        "The lazy control must refine the obstructed approach before publishing")
    result = finish(6)
    assert(result.totalSeconds == 71 and searches == 1 and loads["volume-6"] == 1,
        "At the batch boundary, prepare once and preserve the exact complete travel time")
    result = finish(5)
    assert(result.totalSeconds == 71 and searches == 2 and not loads["volume-6"],
        "An inventory larger than the cap must retain lazy preparation")
    result = finish(6, point(8, 50))
    assert(result.totalSeconds == 69 and searches == 1 and not loads["volume-6"],
        "A local objective must not load the rest of its native world speculatively")
end
print("Terrain batching: one exact inter-world search, inclusive size cap, lazy large/local worlds and unrelated unavailable scopes passed")
