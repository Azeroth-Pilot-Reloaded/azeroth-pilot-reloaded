-- A request observes each scope inventory once, rather than once per walk pair.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({"retail", "forever"}) do
    fixture.profile = profile
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    local revision, inventories, reads = 1, {}, 0
    data.GetTerrainRevision = function() return revision end
    local function scope(id, minX, maxX, minZ, maxZ, access)
        return {id = id, accessKey = access, groundOnly = true,
            bounds = {minX = minX, maxX = maxX, minY = 0, maxY = 10, minZ = minZ, maxZ = maxZ}}
    end
    local lower, upper = scope("lower", 10, 20, 10, 20), scope("private-upper", 10, 20, 30, 40, "owner")
    local packs = {{scope = lower}, {scope = upper}}
    for i = 1, 40 do packs[#packs + 1] = {scope = scope("distant-" .. i, i * 1000, i * 1000 + 20, 10, 20)} end
    local other = profile == "retail" and "forever" or "retail"
    APR.NavigationTerrainIndex = {schema = 1, profiles = {
        [profile] = {worlds = {[8] = {packs = packs}, [9] = {packs = {{id = "legacy"}}}}},
        [other] = {worlds = {[8] = {packs = {{scope = scope("other-profile", 10, 20, 10, 20)}}}}},
    }}
    dofile("APR-Core/features/navigation/NavigationTerrain.lua")
    local host = APR.NavigationTerrain
    for _, pack in ipairs(packs) do
        local fields = pack.scope.bounds
        pack.scope.bounds = setmetatable({}, {__index = function(_, key) reads = reads + 1; return fields[key] end})
        pack.fields = fields
    end
    data.env.getTerrainScopes = function(name, world)
        inventories[world] = (inventories[world] or 0) + 1
        if world == 11 then return {{id = "invalid", bounds = {}}}, false end
        return host:GetScopes(name, world)
    end
    local function point(x, z, extra)
        local p = {instanceID = 8, x = x, y = 5, z = z, uiMapID = 501}
        for key, value in pairs(extra or {}) do p[key] = value end
        return p
    end
    local query = data:CreateTerrainScopeQuery()
    assert(next(inventories) == nil and next(query.worlds) == nil,
        "Creating a request does not eagerly scan every world")
    local function selected(from, to, expected, unboundedWorld, knownScopes, knownUnbounded)
        local result, unbounded = data:GetRequiredTerrainScopes(from, to, query, knownScopes, knownUnbounded)
        local found = {}
        for world, ids in pairs(result) do
            for id in pairs(ids) do found[world .. ":" .. id] = true end
        end
        local count = 0
        for _ in pairs(found) do count = count + 1 end
        assert(count == #expected)
        for _, id in ipairs(expected) do assert(found[id], "Missing independent scope expectation: " .. id) end
        for world in pairs(unbounded) do assert(world == unboundedWorld) end
        assert(not unboundedWorld or unbounded[unboundedWorld])
    end
    selected(point(0, 15), point(30, 15), {"8:lower"})
    local observedReads = reads
    for i = 1, 1000 do
        -- Every pair has new coordinates; this cannot be implemented as a pair cache.
        selected(point(-i / 100, 15), point(30 + i / 100, 15), {"8:lower"})
    end
    assert(inventories[8] == 1 and reads == observedReads,
        "Unique candidate pairs reuse one copied inventory without rereading host scope bounds")
    local known, mathReads = {[8] = {}}, 0
    for _, copied in ipairs(query.worlds[8].scopes) do
        known[8][copied.id] = true
        local fields = copied.bounds
        copied.bounds = setmetatable({}, {__index = function(_, key) mathReads = mathReads + 1; return fields[key] end})
    end
    selected(point(0, 15), point(30, 15), {}, nil, known)
    assert(mathReads == 0, "Known scope IDs are skipped before reading their intersection bounds")
    known[8].lower = nil
    selected(point(0, 15), point(30, 15), {"8:lower"}, nil, known)
    assert(mathReads > 0, "Changing the known set immediately restores a missing scope requirement")
    known[8].lower = true
    selected(point(0, 15), point(30, 15), {}, nil, known)
    mathReads = 0
    for i = 1, 200 do selected(point(100 + i / 1000, 15), point(200 + i / 1000, 15), {}) end
    assert(mathReads < 200 * 100,
        "Spatially local unique chords cannot rescan the bounds of every distant scope")
    selected(point(0, 15, {floor = 2}), point(30, 15, {floor = 3}), {"8:lower"})
    selected(point(0, 35, {accessKey = "owner"}), point(30, 35, {accessKey = "owner"}), {"8:private-upper"})
    selected(point(0, 35, {accessKey = "visitor"}), point(30, 35, {accessKey = "visitor"}), {})
    selected(point(0, 0, {positionSource = "unit"}), point(30, 0, {positionSource = "unit"}), {"8:lower"})
    selected(point(0, 0, {positionSource = "unit", heightSource = "terrain"}), point(30, 0), {})
    selected(point(10, 15, {terrainBoundary = "lower"}), point(0, 15), {})
    selected(point(10, 15, {terrainBoundary = "lower"}), point(15, 15), {"8:lower"})
    selected(point(10, 15, {terrainBoundary = "lower"}), point(10.001, 15), {"8:lower"})
    selected(point(0 / 0, 15), point(15, 15), {"8:lower"})
    selected(point(0, 15, {y = 0}), point(30, 15, {y = 0}), {})
    selected(point(15, 15), point(0, 0, {instanceID = 9}), {"8:lower"}, 9)
    selected(point(15, 15), point(0, 0, {instanceID = 9}), {}, nil, known, {[9] = true})
    selected(point(15, 15), point(0, 0, {instanceID = 9}), {}, 9, known, {[9] = false})
    selected(point(0, 15), point(0, 15, {instanceID = 10}), {})
    selected(point(0, 15), point(0, 15, {instanceID = 11}), {}, 11)
    assert(inventories[8] == 1 and inventories[9] == 1 and inventories[10] == 1 and inventories[11] == 1,
        "Unbounded and absent worlds are cached independently too")
    assert(data:IsTerrainWorldUnmanaged(10, query), "An observed empty native world permits geometric walking costs")
    assert(data:AreTerrainScopesSelected(10, query), "An empty native world has no missing scope cost")
    assert(next(data:GetTerrainScopeBatch(10, query, 0)) == nil, "A proved empty world has an empty metadata batch")
    local batch = data:GetTerrainScopeBatch(8, query, #packs)
    local batched = 0
    for id in pairs(batch) do assert(known[8][id]); batched = batched + 1 end
    assert(batched == #packs and data:GetTerrainScopeBatch(8, query, #packs + 1),
        "Small native inventories can be batched at or below the explicit limit")
    assert(data:GetTerrainScopeBatch(8, query, #packs - 1) == nil,
        "A larger inventory cannot silently exceed the host's batching budget")
    for _, limit in ipairs({-1, 1.5, math.huge, "many", false}) do assert(data:GetTerrainScopeBatch(8, query, limit) == nil) end
    assert(data:GetTerrainScopeBatch(8, query, nil) == nil and data:GetTerrainScopeBatch(8, nil, #packs) == nil)
    assert(data:GetTerrainScopeBatch(9, query, 100) == nil and data:GetTerrainScopeBatch(11, query, 100) == nil,
        "Unknown or malformed geometry cannot be turned into a bounded batch")
    assert(data:AreTerrainScopesSelected(8, query, known), "All selected IDs make every missing-scope probe ordinary")
    known[8].lower = nil
    assert(not data:AreTerrainScopesSelected(8, query, known), "One omitted scope can still yield an optimistic terrain cost")
    known[8].lower = true
    assert(not data:AreTerrainScopesSelected(9, query, known, {[9] = true})
        and not data:AreTerrainScopesSelected(11, query, known, {[11] = true}), "Unknown and malformed worlds keep conservative costs")
    assert(not data:IsTerrainWorldUnmanaged(8, query) and not data:IsTerrainWorldUnmanaged(9, query)
        and not data:IsTerrainWorldUnmanaged(11, query), "Scoped, unbounded and malformed worlds cannot claim an empty graph")
    assert(not data:IsTerrainWorldUnmanaged(10, nil), "The capability requires an owned planning observation")
    assert(not data:IsTerrainWorldUnmanaged(nil, query) and not data:IsTerrainWorldUnmanaged("unknown", query)
        and not data:AreTerrainScopesSelected(-1, query, known), "Unknown world identities cannot carry a geometry proof")
    local nativeBuild, nativeRequirements = data.CreateTerrainEdgeBuild, data.GetRequiredTerrainScopes
    data.CreateTerrainEdgeBuild = function() end
    assert(not data:IsTerrainWorldUnmanaged(10, query), "A custom terrain factory can add travel to an empty metadata world")
    assert(not data:AreTerrainScopesSelected(8, query, known))
    assert(data:GetTerrainScopeBatch(8, query, #packs) == nil)
    data.CreateTerrainEdgeBuild = nativeBuild
    data.GetRequiredTerrainScopes = function() return {}, {} end
    assert(not data:IsTerrainWorldUnmanaged(10, query), "Custom scope requirements do not carry the native proof")
    assert(not data:AreTerrainScopesSelected(8, query, known))
    assert(data:GetTerrainScopeBatch(8, query, #packs) == nil)
    data.GetRequiredTerrainScopes = nativeRequirements
    data.env.hasTerrainData = function(_, world) return world == 10 end
    assert(not data:IsTerrainWorldUnmanaged(10, query), "Unscoped host data still makes the world managed")
    data.env.hasTerrainData = nil
    lib:RegisterTerrainData(profile, 10, {format = 1, nodes = {}, edges = {}}, 1, "synthetic-unlisted")
    assert(not data:IsTerrainWorldUnmanaged(10, query), "Registered terrain cannot hide behind an incomplete host inventory")
    assert(not data:AreTerrainScopesSelected(10, query), "Incomplete empty metadata does not prove ordinary native costs")
    local changing = lib:New({profile = profile, environment = {
        getTerrainScopes = function() return {}, false end,
    }})
    local current = changing:CreateTerrainScopeQuery()
    assert(changing:IsTerrainWorldUnmanaged(12, current))
    changing.env.getTerrainScopes = function() return {scope("new-scope", 10, 20, 10, 20)}, false end
    changing.GetTerrainRevision = function() return 999 end
    assert(not changing:IsTerrainWorldUnmanaged(12, current), "A revision refresh cannot retain an old empty-world proof")
    assert(not changing:AreTerrainScopesSelected(12, current, {[12] = {}}))
    assert(changing:AreTerrainScopesSelected(12, current, {[12] = {["new-scope"] = true}}))
    assert(not changing:IsTerrainWorldUnmanaged(12, query), "A foreign observation cannot authorize the capability")
    assert(changing:GetTerrainScopeBatch(12, query, 100) == nil)
    local sparse = lib:New({profile = profile, environment = {
        getTerrainScopes = function() return {[2] = scope("omitted", 10, 20, 10, 20)}, false end,
    }})
    local sparseQuery = sparse:CreateTerrainScopeQuery()
    local _, sparseUnknown = sparse:GetRequiredTerrainScopes(point(0, 15), point(30, 15), sparseQuery)
    assert(sparseUnknown[8] and not sparse:IsTerrainWorldUnmanaged(8, sparseQuery),
        "Sparse host inventories cannot silently discard geometry and authorize an empty world")
    sparse.GetTerrainScopes = function() return nil end
    sparseQuery = sparse:CreateTerrainScopeQuery()
    assert(not sparse:IsTerrainWorldUnmanaged(8, sparseQuery), "A missing custom inventory remains unknown")
    local foreign = lib:New({profile = other, environment = {getTerrainScopes = function()
        return {scope("foreign-owner", 10, 20, 10, 20)}, false
    end}})
    local foreignSelected = foreign:GetRequiredTerrainScopes(point(0, 15), point(30, 15), query)
    assert(foreignSelected[8]["foreign-owner"] and not foreignSelected[8].lower,
        "Another owner cannot borrow a request's scope observations")

    -- Public calls still observe live host mutation. Existing queries own their copy.
    local unfiltered = data:GetRequiredTerrainScopes(point(0, 15), point(30, 15), nil, known, {[8] = true})
    assert(unfiltered[8].lower, "Filters cannot change the live public query contract without a request snapshot")
    packs[1].fields.maxX = 5
    local live = data:GetRequiredTerrainScopes(point(0, 15), point(30, 15))
    assert(not live[8], "An invalid live scope cannot become selected")
    local _, liveUnbounded = data:GetRequiredTerrainScopes(point(0, 15), point(30, 15))
    assert(liveUnbounded[8], "Malformed live metadata remains conservatively unbounded")
    selected(point(0, 15), point(30, 15), {"8:lower"})
    local fresh = data:CreateTerrainScopeQuery()
    local _, freshUnbounded = data:GetRequiredTerrainScopes(point(0, 15), point(30, 15), fresh)
    assert(freshUnbounded[8], "A fresh request sees changed metadata even without a source revision")
    revision = revision + 1
    selected(point(0, 15), point(30, 15), {}, 8)
    packs[1].fields.maxX = 20
    revision = revision + 1
    selected(point(0, 15), point(30, 15), {"8:lower"})
    local before = inventories[8]
    data.profile = other
    selected(point(0, 15), point(30, 15), {"8:other-profile"})
    assert(inventories[8] == before + 1, "A profile replacement cannot retain another profile's scope copy")
    data.profile = profile

    -- The real APR pipeline must pass this optional query through its callbacks.
    local searchCreations, cancelled, evaluated = 0, 0, 0
    data.HasTerrainData = function() return true end
    data.HasRoadData = function() return false end
    data.CreateEdgeBuild = function()
        return {Step = function() return "ready", {}, {resources = {}} end}
    end
    data.CreateTerrainEdgeBuild = function()
        return {Step = function()
            return "ready", {}, {revision = revision, canWalk = function() return true end}
        end}
    end
    data.CreateLocalExitCheck = nil
    data.CreateTerrainRouteBuild = nil
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local engine = {CreateSearch = function(_, request)
        searchCreations = searchCreations + 1
        local remaining = 200
        return {Step = function(_, operations)
            for _ = 1, operations do
                evaluated = evaluated + 1
                local x = -100 - remaining * 5
                assert(request.walkSecondsFor(point(x, 15), point(x - 3, 15)) == 4)
                remaining = remaining - 1
                if remaining == 0 then return "ready", {segments = {}, totalSeconds = 4} end
            end
            return "planning"
        end, Cancel = function() cancelled = cancelled + 1 end}
    end}
    local function create()
        return APR.NavigationPlanner:Create({data = data, engine = engine,
            start = point(-100, 15), goal = point(-200, 15), walkSpeed = 7,
            walkSecondsFor = function() return 4 end, canWalk = function() return true end,
            taxiData = {BuildEdges = function() return {} end}, prepareSegment = function(segment) return segment end})
    end
    before = inventories[8]
    local job = create()
    while job.phase ~= "search" do assert(job:Step(4, 1) == "planning") end
    assert(job:Step(4, 1) == "planning")
    local obsolete = job.terrainScopeQuery
    revision = revision + 1
    while job:Step(4, 1) == "planning" do end
    assert(job.status == "ready" and job.result.totalSeconds == 4 and evaluated >= 200)
    assert(searchCreations == 2 and cancelled == 1 and job.terrainScopeQuery ~= obsolete,
        "A source revision retires the active search and its scope query")
    assert(inventories[8] == before + 2,
        "APR's optimistic callbacks fetch once per source observation, not once per candidate")
    job = create()
    assert(job.terrainScopeQuery)
    job:Cancel()
    assert(job.terrainScopeQuery == nil and job.status == "cancelled", "Cancelled requests release their scope snapshot")
end
print("Terrain scope queries: bounded immutable per-request inventories, native/access/boundary semantics, live public mutations and source lifecycle on both profiles passed")
