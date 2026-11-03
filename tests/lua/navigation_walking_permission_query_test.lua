-- A planning request reuses static endpoint geography, never live map access.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile = profile
    fixture.maps[501] = { mapID = 501, mapType = 3, parentMapID = 502 }
    fixture.maps[502] = { mapID = 502, mapType = 2, parentMapID = 0 }
    local data = fixture:Load({ connections = {}, config = { NavigationSpaces = {
        { id = "plain", kind = "outdoor", worldID = 8, mapIDs = { 501 }, region = "shared",
            bounds = { minX = -10, maxX = 1000, minY = -5, maxY = 5, minZ = -1, maxZ = 1 } },
        { id = "adjacent", kind = "outdoor", worldID = 8, mapIDs = { 501 }, region = "shared",
            bounds = { minX = 200, maxX = 300, minY = -5, maxY = 5, minZ = -1, maxZ = 1 } },
        { id = "room", kind = "building", worldID = 8, mapIDs = { 501 }, region = "shared",
            requiresExit = true, floor = 2, accessKey = "owner",
            bounds = { minX = -10, maxX = 1000, minY = -5, maxY = 5, minZ = 10, maxZ = 20 } },
    } } })
    local lib = LibStub("LibAPRNavigation-1.0")
    local query = data:CreateWalkingPermissionQuery()
    assert(type(query) == "function")
    local function point(x, fields)
        local p = { instanceID = 8, uiMapID = 501, x = x, y = 0, z = 0, spaceID = "plain" }
        for key, value in pairs(fields or {}) do p[key] = value end
        return p
    end
    assert(data:GetNavigationSpace("plain")) -- Warm the declaration index.
    local reads, bounds = 0, data.config.NavigationSpaces[1].bounds
    data.config.NavigationSpaces[1].bounds = setmetatable({}, { __index = function(_, key)
        reads = reads + 1
        return bounds[key]
    end })
    local points = {}
    for i = 1, 120 do points[i] = point(i) end
    for _, from in ipairs(points) do
        for _, to in ipairs(points) do assert(query(from, to), "Every invented outdoor pair shares access") end
    end
    assert(reads < #points * 50,
        "Dense walking pairs must classify endpoint geography per point, not four times per pair")

    -- Search owns immutable endpoint snapshots. Its explicit opt-in removes
    -- per-pair scalar snapshot comparisons while retaining all policy gates.
    local immutableQuery = data:CreateWalkingPermissionQuery({ immutablePositions = true })
    local pointReads = 0
    local function observedPoint(raw)
        return setmetatable({}, { __index = function(_, key)
            pointReads = pointReads + 1
            return raw[key]
        end })
    end
    local immutableFrom, immutableTo = observedPoint(point(1)), observedPoint(point(2))
    assert(immutableQuery(immutableFrom, immutableTo))
    pointReads = 0
    for _ = 1, 100 do assert(immutableQuery(immutableFrom, immutableTo)) end
    assert(pointReads <= 1200,
        "Immutable search endpoints avoid repeated scalar snapshot comparisons per walking pair")

    -- Target requirements are observed even when both endpoint records are hot.
    local allowed, gateReads = true, 0
    data.config.MapRequirements = { [501] = { quest = 700 } }
    data.env.isQuestCompleted = function()
        gateReads = gateReads + 1
        return allowed
    end
    for _, value in ipairs({ true, false, true, false }) do
        allowed = value
        assert(query(points[1], points[2]) == value, "Cached geography cannot preserve a closed quest gate")
        assert(immutableQuery(immutableFrom, immutableTo) == value,
            "Immutable endpoint reuse still checks live target requirements")
    end
    assert(gateReads >= 4)
    points[2].phaseAgnostic = true
    assert(query(points[1], points[2]), "An explicitly phase-agnostic target retains its access policy")
    points[2].phaseAgnostic = nil
    assert(not query(points[1], points[2]))
    data.config.MapRequirements = nil

    -- Reused position objects cannot retain stale bounds, channels or floors.
    local from, to = point(0), point(10)
    assert(query(from, to))
    from.x = 1001
    assert(not query(from, to))
    from.x = 0
    assert(query(from, to), "A failed position lookup remains retryable")
    from.noAutoconnect = true
    assert(not query(from, to))
    from.noAutoconnect = nil
    from.accessKey = "different"
    assert(not query(from, to))
    from.accessKey, from.floor = nil, 2
    assert(not query(from, to))
    from.floor = nil
    from.instanceID = 9
    assert(not query(from, to))
    from.instanceID = 8
    assert(query(from, to))
    local roomA = point(0, { spaceID = "room", floor = 2, accessKey = "owner", z = 15 })
    local roomB = point(10, { spaceID = "room", floor = 2, accessKey = "owner", z = 15 })
    assert(query(roomA, roomB), "A single declared private floor retains its own walking access")
    roomB.spaceID = "plain"
    assert(not query(roomA, roomB), "Shared region text cannot bridge a required physical exit")
    roomB.spaceID = "room"
    assert(query(roomA, roomB))
    roomA.positionSource, roomA.z, roomA.heightSource = "unit", 0, nil
    assert(query(roomA, roomB), "An explicit floor channel can accompany unknown native height")
    roomA.heightSource = "terrain"
    assert(not query(roomA, roomB), "A proved zero is outside the declared elevated floor")
    roomA.heightSource = nil
    assert(query(roomA, roomB))

    -- Position-cache epochs and same-count catalogue replacements retire proofs.
    local adjacent = point(250, { spaceID = "adjacent" })
    assert(query(from, adjacent))
    local originalSpaces = data.config.NavigationSpaces
    data.config.NavigationSpaces = lib.Copy(originalSpaces)
    data.config.NavigationSpaces[1].bounds = lib.Copy(bounds)
    data.config.NavigationSpaces[1].requiresExit = true
    assert(not query(from, adjacent), "A replacement catalogue can close an exit without changing its count")
    data.config.NavigationSpaces = originalSpaces
    assert(query(from, adjacent))
    bounds.maxX = -1
    assert(not data:CanWalk(from, to), "The public predicate still resolves live declaration bounds")
    data:InvalidatePositionCache()
    assert(not query(from, to), "Geometry invalidation retires even an in-place bounds edit")
    assert(not immutableQuery(immutableFrom, immutableTo), "Immutable position opt-in retains geometry epoch invalidation")
    bounds.maxX = 1000
    data:InvalidatePositionCache()
    assert(query(from, to))
    assert(immutableQuery(immutableFrom, immutableTo))
    local before = reads
    data.positions = {}
    assert(query(from, to) and reads > before, "A replaced projection cache also retires endpoint records")
    before = reads
    data.mapInfos = {}
    assert(query(from, to) and reads > before, "A replaced native-map cache retires endpoint records")
    local unqualifiedA, unqualifiedB = point(0), point(10)
    unqualifiedA.spaceID, unqualifiedB.spaceID = nil, nil
    assert(query(unqualifiedA, unqualifiedB))
    originalSpaces[#originalSpaces + 1] = { id = "new-child", kind = "building", worldID = 8,
        mapIDs = { 501 }, parentSpace = "plain", region = "shared", requiresExit = true,
        bounds = { minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = -1, maxZ = 1 } }
    assert(not query(unqualifiedA, unqualifiedB), "An appended child space can create a required exit")
    table.remove(originalSpaces)
    assert(query(unqualifiedA, unqualifiedB))
    local nativeRegion = { instanceID = 8, uiMapID = 602, x = 0, y = 0, z = 0, region = "other" }
    assert(not query(nativeRegion, to))
    nativeRegion.region = "shared"
    assert(query(nativeRegion, to), "An explicit native-region value is part of a reused observation's identity")

    -- Newly loaded native map metadata may add an enclosure. Missing reads
    -- must not freeze the earlier permissive fallback in the request cache.
    local mapReady, missingReads, loadingReads = false, 0, 0
    local originalMapInfo = data.env.getMapInfo
    data.env.getMapInfo = function(id)
        if id == 601 then
            missingReads = missingReads + 1
            return mapReady and { mapID = 601, mapType = 4, parentMapID = 0 } or nil
        end
        if id == 603 then
            loadingReads = loadingReads + 1
            return loadingReads >= 3 and { mapID = 603, mapType = 4, parentMapID = 0 } or nil
        end
        return originalMapInfo(id)
    end
    data:InvalidatePositionCache()
    local unresolved = { instanceID = 8, uiMapID = 601, x = 0, y = 0, z = 0, region = "shared" }
    assert(query(unresolved, to))
    assert(query(unresolved, to) and missingReads > 1)
    mapReady = true
    assert(not query(unresolved, to), "A newly identified instance cannot keep its former outdoor fallback")
    local duringQuery = { instanceID = 8, uiMapID = 603, x = 0, y = 0, z = 0, region = "shared" }
    query(duringQuery, to)
    assert(not query(duringQuery, to), "An incomplete result cannot be cached when its map arrives during the same call")

    -- Public/custom policies stay live; the opt-in cannot decompose an override.
    local customCalls = 0
    data.CanWalk = function(_, a, b) customCalls = customCalls + 1; return a.custom == b.custom end
    assert(query({ custom = 1 }, { custom = 1 }))
    assert(not query({ custom = 1 }, { custom = 2 }) and customCalls == 2)
    data.CanWalk = nil
    data.IsSameAccessRegion = function() return false end
    assert(not query(from, to))
    data.IsSameAccessRegion = nil
    data.GetPositionRegion = function() return nil end
    assert(not query(from, to))
    data.GetPositionRegion = nil
    local closed = true
    data.ResolveNavigationSpace = function(_, p)
        return { known = true, id = p.spaceID, region = "shared", requiresExit = closed }
    end
    assert(not query(from, adjacent))
    closed = false
    assert(query(from, adjacent), "A custom resolver's changing access is queried live")
    data.ResolveNavigationSpace = nil
    assert(query(from, to))
    local nativeCanWalk = lib.Instance.CanWalk
    lib.Instance.CanWalk = function() return false end
    assert(not query(from, to), "A prototype walking-policy replacement also keeps its live contract")
    assert(not immutableQuery(immutableFrom, immutableTo), "Immutable opt-in never suppresses custom policy changes")
    lib.Instance.CanWalk = nativeCanWalk
    assert(query(from, to))
end
print("Walking permission query: per-endpoint geography, live gates, mutable observations, native recovery, epochs and policy overrides passed")
