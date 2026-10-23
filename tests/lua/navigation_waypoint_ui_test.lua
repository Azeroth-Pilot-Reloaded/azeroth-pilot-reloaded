-- Load the shipped manifest with only standard Lua globals. The optional
-- Waypoint UI bridge must also work when APR and all WoW UI APIs are absent.
local sandbox = {
    assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
    type = type, tonumber = tonumber, tostring = tostring, select = select,
    pcall = pcall, xpcall = xpcall, unpack = unpack, rawget = rawget, rawset = rawset,
    setmetatable = setmetatable, getmetatable = getmetatable,
    math = math, string = string, table = table, strmatch = string.match,
}
sandbox._G = sandbox
local function Load(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, sandbox)
    return chunk()
end
Load("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
setmetatable(sandbox, { __index = function(_, key)
    error("Unexpected waypoint bridge global dependency: " .. tostring(key))
end })
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a")
manifest:close()
for path in xml:gmatch('file="([^"]+)"') do Load(root .. path) end
local library = sandbox.LibStub("LibAPRNavigation-1.0")
assert(rawget(sandbox, "APR") == nil and rawget(sandbox, "CreateFrame") == nil
    and rawget(sandbox, "C_Map") == nil)
assert(type(library.Instance.SetWaypoint) == "function", "The bridge must ship in LibAPRNavigation.xml")

local function MapPoint(x, y, mapID)
    return { space = "map", uiMapID = mapID or 10, x = x, y = y }
end
local function WorldPoint(x, y, instanceID, mapID)
    return { space = "world", instanceID = instanceID or 0, uiMapID = mapID or 10, x = x, y = y }
end
local function Provider()
    local state = { creates = {}, clears = {}, tracked = true }
    local navigation = {}
    function navigation.NewUserNavigation(...)
        assert(select("#", ...) == 1, "Waypoint UI creation uses a dot call")
        local options = ...
        assert(type(options) == "table" and type(options.mapID) == "number")
        assert(options.x >= 0 and options.x <= 100 and options.y >= 0 and options.y <= 100)
        assert(type(options.flags) == "string" and options.flags ~= "", "Every consumer needs an ownership flag")
        assert(options.suppressAudio == true and options.suppressPathfinding == true,
            "Exporting already planned legs must suppress audio and nested pathfinding")
        if state.createError then error("provider creation error") end
        state.creates[#state.creates + 1] = options
        if state.reject then return nil end
        state.current = { mapID = options.mapID, x = options.x / 100, y = options.y / 100,
            name = options.name, flags = options.flags }
        if state.mutateInput then
            options.name, options.x, options.flags = "Changed by provider", -100, "provider_mutation"
        end
        return state.current
    end
    function navigation.GetUserNavigation(...)
        assert(select("#", ...) == 0, "Waypoint UI getters use dot calls")
        if state.getError then error("provider getter error") end
        return state.current
    end
    function navigation.IsUserNavigationTracked(...)
        assert(select("#", ...) == 0, "Waypoint UI tracking checks use dot calls")
        if state.trackedError then error("provider tracking error") end
        return state.tracked
    end
    function navigation.IsUserNavigationFlagged(...)
        assert(select("#", ...) == 1, "Waypoint UI flag checks use dot calls")
        local flag = ...
        return state.current ~= nil and state.current.flags == flag
    end
    function navigation.ClearUserNavigation(...)
        assert(select("#", ...) == 1, "Waypoint UI clear uses a dot call without suppressing path cleanup")
        local preserveWaypoint, suppressAdvance = ...
        assert(suppressAdvance == nil, "A library point has no source pin; normal destination cleanup must run")
        if state.clearError then error("provider clearing error") end
        state.clears[#state.clears + 1] = { preserve = preserveWaypoint, suppressAdvance = suppressAdvance }
        state.current = nil
    end
    return { Navigation = navigation }, state
end
local function New(environment)
    return library:New({ profile = "retail", environment = environment or {} })
end
local function ExpectFailure(instance, position, expected, options)
    local ok, waypoint, reason = pcall(instance.SetWaypoint, instance, position, options or { name = "Target" })
    assert(ok, "Missing or malformed provider data must not escape as an error")
    assert(waypoint == nil and reason == expected,
        "Expected " .. expected .. ", received " .. tostring(reason))
end

-- Provider lookup is lazy, allowing the consuming addon and the library to
-- load before Waypoint UI. The environment can also select its own provider.
local late = New()
ExpectFailure(late, MapPoint(0.25, 0.75), "waypoint_ui_unavailable")
local api, state = Provider()
sandbox.WaypointUIAPI = api
local point = assert(late:SetWaypoint(MapPoint(0.25, 0.75), { name = "Late provider" }))
assert(point == state.current and point.x == 0.25 and point.y == 0.75)
assert(state.creates[1].x == 25 and state.creates[1].y == 75)
assert(late:ClearWaypoint() == true and state.clears[1].preserve == nil)
sandbox.WaypointUIAPI = nil

local injectedAPI, injected = Provider()
local providerReads = 0
local injectedEnvironment = { getWaypointUIAPI = function()
    providerReads = providerReads + 1
    return injectedAPI
end }
local direct = New(injectedEnvironment)
assert(providerReads == 0, "Constructing an instance must not access the optional renderer")
local input, options = MapPoint(0, 1), { name = "Map edge" }
assert(direct:SetWaypoint(input, options))
assert(injected.creates[1].x == 0 and injected.creates[1].y == 100,
    "Normalized map boundaries include zero and one without requiring mapToWorld")
assert(input.x == 0 and input.y == 1 and options.flags == nil,
    "Creating a waypoint must not mutate consumer positions or options")
local creations = #injected.creates
assert(direct:SetWaypoint(MapPoint(0, 1), { name = "Map edge" }))
assert(#injected.creates == creations, "Unchanged targets must not be recreated every frame")
assert(direct:SetWaypoint(MapPoint(0, 1), { name = "Renamed map edge" }))
assert(#injected.creates == creations + 1 and injected.current.name == "Renamed map edge")
assert(direct:ClearWaypoint() == true)

local projectionAPI, projected = Provider()
local projections = 0
local projectedConsumer = New({ getWaypointUIAPI = function() return projectionAPI end,
    worldToMap = function(instanceID, x, y, hint)
        projections = projections + 1
        assert(instanceID == 0 and x == -1234 and y == -5678 and hint == 10,
            "World coordinates retain signs, axes, instance and the target map hint")
        return 20, 0.4, 0.6
    end })
assert(projectedConsumer:SetWaypoint(WorldPoint(-1234, -5678), { name = "Projected world" }))
assert(projections == 1 and projected.creates[1].mapID == 20
    and projected.creates[1].x == 40 and projected.creates[1].y == 60)
assert(projectedConsumer:ClearWaypoint() == true)

local unprojected = New({ getWaypointUIAPI = function() return projectionAPI end })
ExpectFailure(unprojected, WorldPoint(-10, -20), "projection_unavailable")
ExpectFailure(unprojected, WorldPoint(0.2, 0.3), "projection_unavailable")
local legacyProjection = New({ getWaypointUIAPI = function() return projectionAPI end,
    worldToMap = function() return 10 end })
ExpectFailure(legacyProjection, WorldPoint(123, 456), "projection_unavailable")
assert(#projected.creates == 1, "World values must never be submitted as normalized map coordinates")

for _, invalid in ipairs({ false, "invalid", {}, MapPoint(-0.1, 0.5), MapPoint(0.5, 1.1),
    MapPoint(0 / 0, 0.5), MapPoint(0.5, math.huge), MapPoint(0.5, 0.5, 0),
    { space = "map", x = 0.5, y = 0.5 }, { space = "world", x = 1, y = 2 },
    WorldPoint(math.huge, -1) }) do
    ExpectFailure(unprojected, invalid, "invalid_position")
end
ExpectFailure(unprojected, nil, "invalid_position")

local rejectingAPI, rejecting = Provider()
local rejectedConsumer = New({ getWaypointUIAPI = function() return rejectingAPI end })
rejecting.reject = true
ExpectFailure(rejectedConsumer, MapPoint(0.4, 0.5), "waypoint_rejected")
rejecting.reject, rejecting.createError = nil, true
ExpectFailure(rejectedConsumer, MapPoint(0.4, 0.5), "waypoint_ui_error")
rejecting.createError = nil
assert(rejectedConsumer:SetWaypoint(MapPoint(0.4, 0.5), { name = "Recovered provider" }),
    "Provider failure must not prevent a later successful retry")
rejecting.clearError = true
local ok, cleared, clearReason = pcall(rejectedConsumer.ClearWaypoint, rejectedConsumer)
assert(ok and cleared == false and clearReason == "waypoint_ui_error")
rejecting.clearError = nil
assert(rejectedConsumer:ClearWaypoint() == true)
local throwingLookup = New({ getWaypointUIAPI = function() error("provider lookup error") end })
ExpectFailure(throwingLookup, MapPoint(0.4, 0.5), "waypoint_ui_error")

local mutatingAPI, mutating = Provider()
mutating.mutateInput = true
local mutationConsumer = New({ getWaypointUIAPI = function() return mutatingAPI end })
local mutationPosition, mutationOptions = MapPoint(0.25, 0.75), { name = "Original request", iconTexture = 123 }
assert(mutationConsumer:SetWaypoint(mutationPosition, mutationOptions))
assert(mutationPosition.x == 0.25 and mutationOptions.name == "Original request" and mutationOptions.flags == nil,
    "A provider must not receive the consumer's original options or position table")
local mutationsCreated = #mutating.creates
assert(mutationConsumer:SetWaypoint(MapPoint(0.25, 0.75), { name = "Original request", iconTexture = 123 }))
assert(#mutating.creates == mutationsCreated,
    "Provider mutations must not invalidate the library's saved deduplication request")
assert(mutationConsumer:ClearWaypoint() == true,
    "Provider mutations to input flags must not compromise ownership of its returned waypoint")

local cleanupAPI, cleanup = Provider()
local cleanupConsumer = New({ getWaypointUIAPI = function() return cleanupAPI end })
assert(cleanupConsumer:SetWaypoint(MapPoint(0.25, 0.75), { name = "Cleanup retry" }))
cleanup.getError = true
ExpectFailure(cleanupConsumer, MapPoint(0.25, 0.75), "waypoint_ui_error", { name = "Cleanup retry" })
local cleanupOK, cleanupCleared, cleanupReason = pcall(cleanupConsumer.ClearWaypoint, cleanupConsumer)
assert(cleanupOK and cleanupCleared == false and cleanupReason == "waypoint_ui_error"
    and #cleanup.clears == 0 and cleanup.current ~= nil,
    "A getter error must leave ownership and native state available for a later cleanup retry")
cleanup.getError = nil
assert(cleanupConsumer:ClearWaypoint() == true and #cleanup.clears == 1)
assert(cleanupConsumer:SetWaypoint(MapPoint(0.25, 0.75), { name = "Uncertain tracking" }))
cleanup.trackedError = true
local trackingCreations = #cleanup.creates
ExpectFailure(cleanupConsumer, MapPoint(0.25, 0.75), "waypoint_ui_error", { name = "Uncertain tracking" })
assert(#cleanup.creates == trackingCreations,
    "A tracking lookup error cannot authorize republishing an unchanged target")
cleanup.trackedError = nil
assert(cleanupConsumer:SetWaypoint(MapPoint(0.25, 0.75), { name = "Uncertain tracking" }))
assert(#cleanup.creates == trackingCreations,
    "A recovered tracking lookup should return the existing marker without recreating it")
cleanup.trackedError = true
cleanupOK, cleanupCleared = pcall(cleanupConsumer.ClearWaypoint, cleanupConsumer)
assert(cleanupOK and cleanupCleared == true and cleanup.clears[2].preserve == true,
    "A tracking error must preserve the potentially replaced native waypoint while clearing owned session data")

-- Different library instances share a renderer but never share ownership.
local sharedAPI, shared = Provider()
local a = New({ getWaypointUIAPI = function() return sharedAPI end })
local b = New({ getWaypointUIAPI = function() return sharedAPI end })
assert(a:SetWaypoint(MapPoint(0.1, 0.2), { name = "Consumer A" }))
local aFlags = shared.current.flags
assert(b:SetWaypoint(MapPoint(0.3, 0.4), { name = "Consumer B" }))
assert(aFlags ~= shared.current.flags, "Ownership flags must be unique per library instance")
local clearCount = #shared.clears
assert(a:ClearWaypoint() == false and #shared.clears == clearCount and shared.current.name == "Consumer B")
assert(b:ClearWaypoint() == true and #shared.clears == clearCount + 1)

assert(a:SetWaypoint(MapPoint(0.5, 0.6), { name = "Library target" }))
local own = shared.current
shared.current = { mapID = 10, x = 0.8, y = 0.9, flags = "manual_waypoint", name = "User selection" }
creations, clearCount = #shared.creates, #shared.clears
ExpectFailure(a, MapPoint(0.5, 0.6), "waypoint_replaced", { name = "Library target" })
assert(#shared.creates == creations and a:ClearWaypoint() == false and #shared.clears == clearCount,
    "An unchanged library update must respect a user's replacement and leave it intact")
assert(a:SetWaypoint(MapPoint(0.5, 0.6), { name = "Library target" }))
own = shared.current
shared.current = { mapID = own.mapID, x = own.x + 0.1, y = own.y, flags = own.flags, name = own.name }
assert(a:ClearWaypoint() == false and #shared.clears == clearCount,
    "Matching flags alone cannot authorize clearing different coordinates")

local staleAPI, stale = Provider()
local staleConsumer = New({ getWaypointUIAPI = function() return staleAPI end })
assert(staleConsumer:SetWaypoint(MapPoint(0.2, 0.3), { name = "Stale native target" }))
stale.tracked = false
local staleCreations = #stale.creates
ExpectFailure(staleConsumer, MapPoint(0.2, 0.3), "waypoint_replaced", { name = "Stale native target" })
assert(#stale.creates == staleCreations,
    "A matching WUI session must not reclaim a native waypoint replaced before session validation")
assert(staleConsumer:ClearWaypoint() == true and stale.clears[1].preserve == true,
    "A native waypoint changed before WUI validation must be preserved during cleanup")

-- A walking leg targets arrival; transport legs target their departure.
local segmentAPI, segments = Provider()
local segmentConsumer = New({ getWaypointUIAPI = function() return segmentAPI end })
local from, destination = MapPoint(0.2, 0.3), MapPoint(0.7, 0.8)
from.instanceID, destination.instanceID = 0, 0
for _, kind in ipairs({ "walk", "passage" }) do
    assert(segmentConsumer:SetWaypointForSegment({ kind = kind, from = from, to = destination }, { name = kind }))
    assert(segments.current.x == destination.x and segments.current.y == destination.y)
end
for _, kind in ipairs({ "portal", "boat", "taxi" }) do
    assert(segmentConsumer:SetWaypointForSegment({ kind = kind, from = from, to = destination }, { name = kind }))
    assert(segments.current.x == from.x and segments.current.y == from.y)
end
destination.instanceID = 1
assert(segmentConsumer:SetWaypointForSegment({ kind = "passage", from = from, to = destination }, { name = "Cross-world passage" }))
assert(segments.current.x == from.x and segments.current.y == from.y)
local noWaypoint, noWaypointReason = segmentConsumer:SetWaypointForSegment({ kind = "spell", from = from,
    to = destination, sourceFree = true, action = { type = "spell", id = 3561 } }, { name = "Personal action" })
assert(noWaypoint == nil and noWaypointReason == "no_waypoint" and segments.current == nil,
    "Personal travel must clear the old marker instead of sending the player back to its cast origin")

assert(segmentConsumer:SetWaypointForSegment({ kind = "walk", from = from, to = destination }, { name = "Last leg" }))
local segmentClears = #segments.clears
noWaypoint, noWaypointReason = segmentConsumer:SetWaypointForSegment(nil)
assert(noWaypoint == nil and noWaypointReason == "no_waypoint" and segments.current == nil
    and #segments.clears == segmentClears + 1,
    "Passing no active segment must remove the final owned marker")
assert(segmentConsumer:SetWaypointForSegment({ kind = "walk", from = from, to = destination }, { name = "Valid leg" }))
local validSegmentPoint = segments.current
for _, invalidSegment in ipairs({ false, "invalid", 42 }) do
    local segmentOK, waypoint, reason = pcall(segmentConsumer.SetWaypointForSegment, segmentConsumer, invalidSegment)
    assert(segmentOK and waypoint == nil and reason == "invalid_position" and segments.current == validSegmentPoint,
        "A malformed segment must fail safely without discarding the current valid target")
end
local incompletePoint, incompleteReason = segmentConsumer:SetWaypointForSegment({ kind = "walk", from = from })
assert(incompletePoint == nil and incompleteReason == "invalid_position" and segments.current == validSegmentPoint,
    "A walking leg without a destination must never fall back to its departure")
for _, invalidOptions in ipairs({ false, "invalid", 42 }) do
    local positionOK, waypoint, reason = pcall(segmentConsumer.SetWaypoint, segmentConsumer, MapPoint(0.4, 0.5), invalidOptions)
    assert(positionOK and waypoint == nil and reason == "invalid_options")
    local segmentOK
    segmentOK, waypoint, reason = pcall(segmentConsumer.SetWaypointForSegment, segmentConsumer,
        { kind = "walk", from = from, to = destination }, invalidOptions)
    assert(segmentOK and waypoint == nil and reason == "invalid_options" and segments.current == validSegmentPoint,
        "Malformed rendering options must not crash or replace a valid waypoint")
end
assert(segmentConsumer:ClearWaypoint() == true)

print("Navigation Waypoint UI: standalone manifest, lazy providers, coordinate spaces, ownership, failures and segment guidance passed")
