-- Repeated road slices must reuse coverage proofs for immutable plan inputs.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({"forever", "retail"}) do
    fixture.profile = profile
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    local function point(x, extra)
        local value = {instanceID = 0, uiMapID = 501, x = x, y = 0}
        for key, field in pairs(extra or {}) do value[key] = field end
        return value
    end
    local start, goal = point(0), point(100)
    local terrainRevision, roadRevision, coverageCalls, cancelled = 1, 1, 0, 0
    local terrainRequired = false
    data.HasTerrainData = function() return false end
    data.GetTerrainRevision = function() return terrainRevision end
    data.GetRoadRevision = function() return roadRevision end
    data.HasRoadData = function() return true end
    data.RequiresTerrainRoute = function(_, from)
        coverageCalls = coverageCalls + 1
        return terrainRequired or from.terrainBoundary == "interior" or from.indoors == true or from.accessKey == 1
    end
    data.CreateEdgeBuild = function()
        return {Step = function() return "ready", {}, {resources = {}} end}
    end
    data.CreateRoadRoute = function(_, request)
        local ticks = 0
        return {
            Step = function()
                ticks = ticks + 1
                if ticks < 120 then return "planning" end
                return "ready", {segments = {{kind = "walk", road = true,
                    from = request.start, to = request.goal, seconds = 100}}}
            end,
            Cancel = function() cancelled = cancelled + 1 end,
        }
    end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local function create()
        return APR.NavigationPlanner:Create({data = data, engine = lib.Engine,
            start = start, goal = goal, walkSpeed = 1,
            taxiData = {BuildEdges = function() return {} end},
            canWalk = function() return true end,
            walkSecondsFor = function() return 50 end,
            prepareSegment = function(segment) return segment end})
    end
    local job = create()
    for _ = 1, 1000 do
        if job:Step(1, 1) ~= "planning" then break end
    end
    assert(job.status == "ready" and job.result.totalSeconds == 100)
    assert(coverageCalls <= 4,
        "A suspended road and repeated searches must not rescan terrain coverage every slice")

    local before = coverageCalls
    for _ = 1, 100 do
        assert(job:GetOptimisticWalkSeconds(point(0), point(100)) == 0)
    end
    assert(coverageCalls == before, "Equivalent endpoint snapshots share the same coverage proof")
    -- Same coordinates do not authorize reuse across access, floors or height evidence.
    for _, extra in ipairs({{accessKey = "private"}, {floor = 2}, {positionSource = "unit", z = 0},
        {heightSource = "terrain", z = 0}, {terrainBoundary = "interior"}, {indoors = true}}) do
        before = coverageCalls
        local seconds = job:GetOptimisticWalkSeconds(point(0, extra), point(100))
        assert(coverageCalls == before + 1, "Coverage proofs retain endpoint access and height identity")
        assert(seconds == ((extra.terrainBoundary or extra.indoors) and 50 or 0))
    end
    before = coverageCalls
    for _ = 1, 100 do
        assert(job:GetOptimisticWalkSeconds(point(0, {accessKey = 1}), point(100)) == 50)
        assert(job:GetOptimisticWalkSeconds(point(0, {accessKey = "1"}), point(100)) == 0,
            "Numeric and string access channels must not share a coverage proof")
    end
    assert(coverageCalls == before + 2, "Repeated exterior and interior classifications both stay cached")
    before = coverageCalls
    assert(job:GetOptimisticWalkSeconds(point(100), point(0)) == 0)
    assert(coverageCalls == before + 1, "Directed pairs retain their own proof")
    before = coverageCalls
    assert(job:GetOptimisticWalkSeconds(point(0, {movementMode = "flight"}), point(100)) == 50)
    assert(coverageCalls == before, "Air movement never requests a ground-road proof")
    for x = 1, 100 do
        for y = 1, 100 do
            assert(job:GetOptimisticWalkSeconds(point(1000 + x), point(2000 + y)) == 0)
        end
    end
    before = coverageCalls
    assert(job:GetOptimisticWalkSeconds(point(1100), point(2100)) == 0)
    assert(coverageCalls == before, "Dense catalogues retain the current endpoint row")
    assert(job:GetOptimisticWalkSeconds(start, goal) == 0)
    assert(coverageCalls == before + 1, "Old endpoint rows are evicted instead of retaining a quadratic matrix")

    -- Native geometry or road replacements invalidate both successful and negative proofs.
    for _, change in ipairs({"terrain", "road"}) do
        terrainRequired = false
        job = create()
        while job.phase ~= "road_verify" or not job.active do
            assert(job:Step(1, 1) == "planning")
        end
        before = coverageCalls
        terrainRequired = true
        if change == "terrain" then terrainRevision = terrainRevision + 1
        else roadRevision = roadRevision + 1 end
        for _ = 1, 100 do
            if job:Step(1, 1) ~= "planning" then break end
        end
        assert(job.status == "ready" and job.result.totalSeconds == 50 and coverageCalls > before,
            "A new geometry revision cannot reuse a previous exterior-road classification")
        terrainRequired = false
    end
    assert(cancelled == 2, "Replacing either source cancels its suspended road worker")
    job = create()
    assert(job:GetOptimisticWalkSeconds(start, goal) == 0)
    before = coverageCalls
    terrainRequired = true
    local fresh = create()
    assert(fresh:GetOptimisticWalkSeconds(start, goal) == 50 and coverageCalls > before,
        "Coverage caches belong to one planning request")
    fresh:Cancel()
end
print("Road coverage: bounded rescans, endpoint evidence, source revisions and per-request lifetime on both profiles passed")
