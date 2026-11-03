-- A native terrain-free destination can bound an inter-world search, while
-- custom zero-cost walking must retain the original unconstrained search.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({"retail", "forever"}) do
    fixture.profile = profile
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    data.env.requestTerrainData = function() return "ready" end
    lib:RegisterTerrainData(profile, 99, {format = 1, nodes = {}, edges = {},
        scope = {id = "unrelated", bounds = {minX = 10, maxX = 20,
            minY = -5, maxY = 5, minZ = -1, maxZ = 1}}}, 1, "unrelated")
    local function point(world, x)
        return {instanceID = world, x = x, y = 0, z = 0, region = "synthetic-outdoors"}
    end
    local start, goal = point(8, 0), point(9, 100)
    local edges = {
        {id = "long-approach", kind = "portal", from = start, to = point(9, 0), seconds = 3},
        {id = "short-approach", kind = "portal", from = point(8, 20), to = point(9, 90), seconds = 4},
    }
    data.CreateEdgeBuild = function()
        return {Step = function() return "ready", edges, {resources = {}} end}
    end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local observed
    local request = {
        data = data, start = start, goal = goal, walkSpeed = 10,
        walkSpeedAt = function() return 10 end,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        taxiData = {BuildEdges = function() return {} end},
        prepareSegment = function(segment) return segment end,
        engine = {CreateSearch = function(_, input)
            observed = input.walkingHeuristic
            return lib.Engine:CreateSearch(input)
        end},
    }
    local function finish()
        observed = nil
        local job = APR.NavigationPlanner:Create(request)
        for _ = 1, 10000 do
            if job:Step(8, 1) ~= "planning" then break end
        end
        assert(job.status == "ready", "Both native variants must retain the feasible transport")
        return job:GetResult(), job
    end
    local result = finish()
    assert(not observed and result.totalSeconds == 7,
        "An ordinary-speed guarantee is optional and cannot change the winner")
    request.ordinaryWalkSpeedUpperBound = 60
    local boundedJob
    result, boundedJob = finish()
    assert(observed and observed.euclideanWorld(8) == true and observed.euclideanWorld(9) == true
        and observed.euclideanWorld(99) ~= true and result.totalSeconds == 7,
        "Only proven ordinary worlds retain geometric lower costs in the relaxation")
    boundedJob.terrainScopes[99] = {unrelated = true}
    assert(boundedJob:GetWalkingHeuristic().euclideanWorld(99) == true,
        "Fully selected scopes retain explicit terrain costs while ordinary walks become geometric")
    local used
    for _, segment in ipairs(result.segments) do if segment.id == "short-approach" then used = true end end
    assert(used, "The physical approaches must select the faster complete itinerary")

    request.walkSecondsFor = function() return 0 end
    result = finish()
    assert(not observed and result.totalSeconds == 3 and result.segments[1].id == "long-approach",
        "A custom zero-cost walk cannot inherit the native Euclidean promise")
    request.walkSecondsFor = nil
    request.walkSpeedAt, request.walkSpeedFor = nil, function() return 1000 end
    result = finish()
    assert(not observed and math.abs(result.totalSeconds - 3.1) < 1e-9,
        "A pair-specific speed cannot be bounded by the default node speed")
    request.walkSpeedFor = nil
    local _, job = finish()
    job.roadEnabled = true
    assert(job:GetWalkingHeuristic() == nil,
        "Unrefined road shortcuts have no ordinary geometric guarantee")
end
print("Planner heuristic: native ordinary worlds, inter-world approach costs, optional guarantees, custom zero costs and pair speeds passed")
