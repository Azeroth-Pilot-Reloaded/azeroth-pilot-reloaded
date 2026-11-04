-- Dense walking checks reuse owned scope geometry and per-point membership.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({"retail", "forever"}) do
    fixture.profile = profile
    fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    local function scope(id, x, access)
        return {id = id, accessKey = access, bounds = {
            minX = x, maxX = x + 10, minY = 0, maxY = 10, minZ = 10, maxZ = 20}}
    end
    local scopes = {scope("room", 10), scope("private", 50, "owner")}
    for i = 1, 19 do scopes[#scopes + 1] = scope("distant-" .. i, i * 100 + 100) end
    local calls, sourceReads, boundaryReads = 0, 0, 0
    local validate = lib.Terrain.ScopeValid
    lib.Terrain.ScopeValid = function(value) calls = calls + 1; return validate(value) end
    local owner = lib:New({profile = profile, environment = {
        getTerrainScopes = function(_, world)
            if world == 8 then return scopes, false end
            return {}, false
        end,
        requestTerrainData = function() return "missing", "fixture_geometry_unavailable" end,
    }})
    local function point(x, z, extra)
        local p = {instanceID = 8, x = x, y = 5, z = z, uiMapID = 501}
        for key, value in pairs(extra or {}) do p[key] = value end
        return setmetatable(p, {__index = function(_, key)
            if key == "terrainBoundary" then boundaryReads = boundaryReads + 1 end
        end})
    end
    local function build(instance, immutable)
        local job = instance:CreateTerrainEdgeBuild({start = point(0, 15), goal = point(80, 15),
            immutablePositions = immutable,
            canWalk = function(a, b) return a.instanceID == b.instanceID end})
        assert(not job.coverage.canWalk(point(30, 15), point(35, 15)), "Unfinished coverage cannot prove a walk")
        for _ = 1, 10000 do
            if job:Step(16, 1) ~= "planning" then break end
        end
        assert(job.status == "ready")
        return job, job.coverage
    end
    local job, coverage = build(owner)
    for _, s in ipairs(scopes) do
        local fields = s.bounds
        s.fields = fields
        s.bounds = setmetatable({}, {__index = function(_, key) sourceReads = sourceReads + 1; return fields[key] end})
    end
    local before = calls
    assert(coverage.canWalk(point(30, 15), point(35, 15)))
    assert(calls == before + #scopes, "Coverage validates its owned geometry once")
    local copiedReads, copiedCalls = sourceReads, calls
    local spatialReads = 0
    for _, copied in ipairs(job.coverageProof.worlds[8].scopes) do
        local fields = copied.bounds
        copied.bounds = setmetatable({}, {__index = function(_, key) spatialReads = spatialReads + 1; return fields[key] end})
    end
    assert(coverage.canAutoconnectAt(point(30, 15)) and not coverage.canAutoconnectAt(point(15, 15)),
        "Only exterior points participate in automatic walking; room points retain explicit edges")
    assert(coverage.canAutoconnectAt(point(10, 15, {terrainBoundary = "room"})),
        "A labelled exterior doorway remains eligible for normal approaches")
    assert(coverage.canAutoconnectAt({instanceID = 9}), "Unmanaged automatic walking stays under host control")
    local points = {}
    for i = 1, 120 do points[i] = point(30 + i / 1000, 15) end
    boundaryReads = 0
    for _, a in ipairs(points) do
        for _, b in ipairs(points) do
            assert(coverage.canWalk(a, b), "Chords inside an invented exterior gap remain walkable")
        end
    end
    assert(calls == copiedCalls and sourceReads == copiedReads,
        "A dense pair graph cannot revalidate or reread the host's scope metadata")
    assert(boundaryReads < #points * #points * 5,
        "Endpoint membership work scales with points instead of repeated pair-by-scope scans")
    assert(spatialReads < #points * #points * 64,
        "Dense exterior pairs visit nearby spatial leaves instead of every remote scope")

    local a, b = point(30, 15), point(35, 15)
    assert(coverage.canWalk(a, b))
    a.x = 15
    assert(not coverage.canWalk(a, b), "A reused mutable point cannot retain an exterior classification")
    assert(not coverage.canAutoconnectAt(a))
    a.x, a.z = 30, 0
    assert(coverage.canWalk(a, b))
    a.x, a.positionSource, b.z = 15, "unit", 0
    assert(not coverage.canWalk(a, b), "Native placeholder zero cannot select the floor below a room")
    a.heightSource = "terrain"
    assert(coverage.canWalk(a, b), "Proved sea-level zero clears the room's real altitude")
    assert(coverage.canAutoconnectAt(a))
    a.heightSource, a.positionSource = nil, "authored"
    assert(coverage.canWalk(a, b), "An authored zero is a real height, not a native placeholder")
    a.x, a.z, a.positionSource, b.x, b.z = 55, 15, nil, 75, 15
    a.accessKey, b.accessKey = "owner", "owner"
    assert(not coverage.canWalk(a, b))
    a.accessKey, b.accessKey = "visitor", "visitor"
    assert(coverage.canWalk(a, b), "A changed access channel cannot borrow a private room's membership")
    a.x, b.x, a.accessKey, b.accessKey = 10, 0, nil, nil
    a.terrainBoundary = "room"
    assert(coverage.canWalk(a, b), "A labelled doorway stays in the exterior graph")
    a.terrainBoundary = nil
    assert(not coverage.canWalk(a, b), "Removing that boundary evidence restores room membership")
    a.x, b.x, a.y, b.y = 0, 30, 0, 0
    assert(coverage.canWalk(a, b), "Tangency along a scope face does not cross its interior")
    a.y, b.y = 5, 5
    assert(not coverage.canWalk(a, b), "Exterior endpoints cannot create a chord through a room")
    a.x, b.x, a.y, b.y, a.terrainBoundary, b.terrainBoundary = 10, 20, 5, 5, "room", "room"
    assert(not coverage.canWalk(a, b), "Boundary labels cannot authorize an inward chord through their own room")
    a.x, b.x, a.y, b.y, a.terrainBoundary, b.terrainBoundary = 0, 30, 0, 11, nil, nil
    assert(not coverage.canWalk(a, b), "A diagonal crossing must survive hierarchical pruning")
    a.y, b.y = -20, 1
    assert(coverage.canWalk(a, b), "A diagonal missing every actual room can cross the broad inventory box")
    a.y, b.y = 5, 5
    a.z, b.z = 50, 50
    assert(coverage.canWalk(a, b), "Known altitude above the entire scope inventory is distinct")
    a.instanceID, b.instanceID = 9, 9
    assert(coverage.canWalk(a, b), "Unmanaged worlds retain the host predicate")
    assert(coverage.canWalk({instanceID = 9}, {instanceID = 9}), "Coverage does not impose XY on unmanaged host policies")
    a.instanceID, b.instanceID, a.z, b.z = 8, 8, 15, 15
    assert(not coverage.canWalk(a, b), "Returning to a managed world restores its scope rules")

    local observed = setmetatable({}, {__mode = "v"})
    do
        local transient = point(32, 15)
        observed[1] = transient
        assert(coverage.canWalk(transient, points[1]))
    end
    collectgarbage("collect"); collectgarbage("collect")
    assert(observed[1] == nil, "Membership caching must not retain retired position tables")

    -- A ready build owns its metadata; the live public predicate stays live.
    scopes[1].fields.maxX = 40
    assert(lib.Terrain.ScopeContains(scopes[1], point(35, 15)))
    assert(coverage.canWalk(point(30, 15), point(35, 15)))
    lib.terrainRevision = (lib.terrainRevision or 0) + 1
    assert(not coverage.canWalk(point(30, 15), point(35, 15)), "New source revisions retire old coverage proofs")
    assert(not coverage.canAutoconnectAt(point(-30, 15)))
    assert(not job.coverageProof.ready and job.coverageProof.points == nil)
    local fresh, renewed = build(owner)
    assert(not renewed.canWalk(point(30, 15), point(35, 15)), "A new build sees the new room bounds")
    assert(renewed.canWalk(point(-30, 15), point(-35, 15)))
    fresh:Cancel()
    assert(not renewed.canWalk(point(-30, 15), point(-35, 15)), "Cancelling releases and retires a ready predicate")
    assert(not renewed.canAutoconnectAt(point(-30, 15)))

    local function constrained(inventory, unbounded)
        return lib:New({profile = profile, environment = {
            getTerrainScopes = function(_, world) if world == 8 then return inventory, unbounded end return {}, false end,
            hasTerrainData = function() return true end,
            requestTerrainData = function() return "missing", "fixture_unavailable" end,
        }})
    end
    local _, unknown = build(constrained({}, true))
    assert(not unknown.canWalk(point(-30, 15), point(-35, 15)), "An unbounded managed world cannot authorize an exterior shortcut")
    assert(not unknown.canAutoconnectAt(point(-30, 15)))
    local _, invalid = build(constrained({{id = "malformed", bounds = {}}}, false))
    assert(not invalid.canWalk(point(-30, 15), point(-35, 15)), "Invalid scope geometry remains conservatively blocked")
    assert(not invalid.canAutoconnectAt(point(-30, 15)))
    local profileJob, profileCoverage = build(owner)
    assert(profileCoverage.canWalk(point(-30, 15), point(-35, 15)))
    owner.profile = profile == "retail" and "forever" or "retail"
    assert(not profileCoverage.canWalk(point(-30, 15), point(-35, 15)), "A profile replacement retires its old coverage")
    assert(not profileJob.coverageProof.ready)

    owner.profile = profile
    local _, immutableCoverage = build(owner, true)
    local endpointReads = 0
    local function observedPoint(x)
        local fields = {instanceID = 8, x = x, y = 5, z = 15}
        return setmetatable({}, {__index = function(_, key)
            if key ~= "instanceID" then endpointReads = endpointReads + 1 end
            return fields[key]
        end})
    end
    local fixedA, fixedB = observedPoint(-30), observedPoint(-35)
    assert(immutableCoverage.canWalk(fixedA, fixedB))
    endpointReads = 0
    for _ = 1, 1000 do
        assert(immutableCoverage.canWalk(fixedA, fixedB) and immutableCoverage.canAutoconnectAt(fixedA))
    end
    assert(endpointReads == 0, "An explicit immutable request reuses proved endpoints without repeated field guards")
end
print("Terrain coverage: owned geometry, linear endpoint membership, access/height/boundary mutation, weak lifetime and source/profile/cancel retirement passed")
