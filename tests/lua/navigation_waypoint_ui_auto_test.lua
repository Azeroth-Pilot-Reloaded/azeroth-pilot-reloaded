-- Automatic output observes host guidance without APR, frames or a second
-- arrival controller. Only the enabled instance may resolve its dependencies.
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
    error("Unexpected automatic waypoint global dependency: " .. tostring(key))
end })
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a")
manifest:close()
for path in xml:gmatch('file="([^"]+)"') do Load(root .. path) end
local library = sandbox.LibStub("LibAPRNavigation-1.0")

local function MapPoint(x, y)
    return { space = "map", uiMapID = 10, x = x, y = y }
end
local function New(environment, enabled)
    return library:New({ profile = "retail", environment = environment, waypointUI = enabled })
end
local function Provider()
    local state = { creates = 0, clears = 0 }
    local api = { Navigation = {} }
    function api.Navigation.NewUserNavigation(request)
        if state.createError then error("creation failed") end
        if state.reject then return nil end
        state.creates = state.creates + 1
        state.current = { mapID = request.mapID, x = request.x / 100, y = request.y / 100,
            name = request.name, flags = request.flags }
        assert(request.suppressPathfinding == true)
        return state.current
    end
    function api.Navigation.GetUserNavigation()
        if state.getError then error("getter failed") end
        return state.current
    end
    function api.Navigation.IsUserNavigationTracked() return true end
    function api.Navigation.ClearUserNavigation(_, suppressAdvance)
        assert(suppressAdvance == nil)
        if state.clearError then error("cleanup failed") end
        state.clears, state.current = state.clears + 1, nil
    end
    return api, state
end
local function Scheduler()
    local timers = {}
    local function create(interval, callback)
        assert(interval > 0 and interval <= 1)
        local timer = { callback = callback }
        function timer:Cancel() self.cancelled = true end
        timers[#timers + 1] = timer
        return timer
    end
    return create, timers
end
local function Reason(instance, expected)
    local _, reason = instance:GetWaypointUIStatus()
    assert(reason == expected, "Expected " .. tostring(expected) .. ", received " .. tostring(reason))
end

-- Default/false modes must not even inspect target, API or scheduler callbacks.
local unavailable = setmetatable({}, { __index = function(_, key)
    error("Disabled automatic output inspected environment: " .. tostring(key))
end })
local default, disabled = New(unavailable), New(unavailable, false)
assert(default.waypointUIEnabled ~= true and disabled.waypointUIEnabled ~= true)
Reason(default, "waypoint_ui_disabled")
disabled:SetWaypointUIEnabled(false)
disabled:RefreshWaypointUI()

local createTicker, timers = Scheduler()
local missing = New({ newWaypointTicker = createTicker, getWaypointUIAPI = function()
    error("A missing target must not resolve the renderer")
end }, true)
Reason(missing, "waypoint_target_unavailable")
assert(#timers == 1)
missing:SetWaypointUIEnabled(false)
assert(timers[1].cancelled)

-- Without any scheduler, immediate and explicit refresh still work. No global
-- lookups escape through the sandbox's erroring metatable.
local manualAPI, manual = Provider()
local unscheduledTarget = MapPoint(0.1, 0.2)
local unscheduled = New({ getWaypointUIAPI = function() return manualAPI end,
    getWaypointTarget = function() return unscheduledTarget end }, true)
assert(manual.creates == 1)
Reason(unscheduled, "waypoint_scheduler_unavailable")
unscheduledTarget.x = 0.3
assert(unscheduled:RefreshWaypointUI())
assert(manual.creates == 2 and manual.current.x == 0.3)
unscheduled:SetWaypointUIEnabled(false)
assert(manual.current == nil)

-- The normal WoW scheduler is optional and resolved only upon activation.
local globalCreate, globalTimers = Scheduler()
sandbox.C_Timer = { NewTicker = globalCreate }
local globalTimerInstance = New({ getWaypointTarget = function() return nil end }, true)
assert(#globalTimers == 1)
globalTimerInstance:SetWaypointUIEnabled(false)
sandbox.C_Timer = nil

local api, state = Provider()
local schedule, ticks = Scheduler()
local target, options = MapPoint(0.2, 0.3), { name = "Current target" }
local getterError = false
local instance = New({ getWaypointUIAPI = function() return api end, newWaypointTicker = schedule,
    getWaypointTarget = function()
        if getterError then error("host not ready") end
        return target, options
    end }, true)
local tick = ticks[1].callback
assert(#ticks == 1 and state.creates == 1 and state.current.x == 0.2)
Reason(instance, nil)
tick(); tick()
assert(state.creates == 1, "An unchanged target must be deduplicated")
target.x = 0.4
tick()
assert(state.creates == 2 and state.current.x == 0.4, "In-place target changes must be observed")
options.name = "Renamed target"
tick()
assert(state.creates == 3 and state.current.name == "Renamed target")

local from, to = MapPoint(0.1, 0.2), MapPoint(0.6, 0.7)
target, options = { kind = "walk", from = from, to = to, instruction = "Walk here" }, nil
tick()
assert(state.current.x == 0.6 and state.current.name == "Walk here")
to.x = 0.65
tick()
assert(state.current.x == 0.65, "In-place segment endpoint changes must not be hidden by shared references")
target.kind, target.instruction = "portal", "Enter here"
tick()
assert(state.current.x == 0.1 and state.current.name == "Enter here")
target = { kind = "spell", sourceFree = true, action = { type = "spell", id = 123 }, from = from, to = to }
tick()
assert(state.current == nil and state.clears == 1)
Reason(instance, "no_waypoint")
target = nil
tick()
assert(state.clears == 1, "Repeated empty guidance must not clear repeatedly")

target = MapPoint(0.2, 0.3)
tick()
local retained = state.current
getterError = true
tick()
assert(state.current == retained, "A failed host getter must preserve the published pin")
Reason(instance, "waypoint_target_error")
getterError = false
tick()
Reason(instance, nil)

-- Invalid manual publication does not suspend a valid automatic target. A
-- provider may also call a host refresh synchronously without recursing.
local invalidPoint, invalidReason = instance:SetWaypoint(MapPoint(-1, 0.5))
assert(invalidPoint == nil and invalidReason == "invalid_position")
target.x = 0.25
tick()
assert(state.current.x == 0.25)
local originalCreate, inCreate = api.Navigation.NewUserNavigation, false
api.Navigation.NewUserNavigation = function(request)
    assert(not inCreate, "Automatic refresh must guard against provider reentry")
    inCreate = true
    instance:RefreshWaypointUI()
    local point = originalCreate(request)
    inCreate = false
    return point
end
target.x = 0.27
tick()
assert(state.current.x == 0.27)
api.Navigation.NewUserNavigation = originalCreate
retained = state.current

-- A transient renderer failure preserves ownership and retries the same target.
state.createError, target.x = true, 0.5
tick()
assert(state.current == retained)
Reason(instance, "waypoint_ui_error")
state.createError = nil
tick()
assert(state.current.x == 0.5)
state.clearError, target = true, nil
tick()
Reason(instance, "waypoint_ui_error")
assert(state.current ~= nil)
state.clearError = nil
tick()
assert(state.current == nil)
Reason(instance, "no_waypoint")

-- Explicit APIs remain usable during automatic mode. Their override persists
-- through ticks until guidance or its display options actually change.
target, options = MapPoint(0.3, 0.4), { name = "Automatic target" }
tick()
assert(instance:SetWaypoint(MapPoint(0.8, 0.9), { name = "Manual target" }))
local creates = state.creates
tick(); tick()
assert(state.creates == creates and state.current.name == "Manual target")
Reason(instance, "waypoint_manual_override")
options.name = "Automatic changed"
tick()
assert(state.current.x == 0.3 and state.current.name == "Automatic changed")
assert(instance:ClearWaypoint())
creates = state.creates
tick()
assert(state.current == nil and state.creates == creates)
target.x = 0.35
tick()
assert(state.current.x == 0.35 and state.creates == creates + 1)
assert(instance:SetWaypointForSegment({ kind = "walk", from = from, to = to }, { name = "Manual segment" }))
tick()
assert(state.current.name == "Manual segment")
instance:SetWaypointUIEnabled(false)
assert(ticks[1].cancelled and state.current.name == "Manual segment",
    "Stopping automatic mode must preserve an explicit manual publication")
target.x = 0.45
tick()
assert(state.current.name == "Manual segment", "A cancelled callback must be harmless")
instance:SetWaypointUIEnabled(true)
assert(#ticks == 2 and state.current.x == 0.45)
target.x = 0.55
creates = state.creates
tick()
assert(state.creates == creates, "Callbacks from an earlier generation must stay inactive after restarting")
ticks[2].callback()
assert(state.current.x == 0.55)
instance:SetWaypointUIEnabled(false)
assert(state.current == nil and ticks[2].cancelled)

-- A provider may arrive later. Missing/failed creation never latches a target
-- as complete, and a user replacing the current pin is respected thereafter.
local lateAPI, lateState = Provider()
local selectedAPI
local lateSchedule, lateTicks = Scheduler()
local lateTarget = MapPoint(0.6, 0.7)
local late = New({ getWaypointUIAPI = function() return selectedAPI end, newWaypointTicker = lateSchedule,
    getWaypointTarget = function() return lateTarget end }, true)
Reason(late, "waypoint_ui_unavailable")
selectedAPI = lateAPI
lateTicks[1].callback()
assert(lateState.creates == 1 and lateState.current.x == 0.6)
lateState.current = { name = "Another addon", mapID = 10, x = 0.9, y = 0.9, flags = "other" }
lateTicks[1].callback()
Reason(late, "waypoint_replaced")
assert(lateState.creates == 1)
late:SetWaypointUIEnabled(false)
assert(lateState.current.name == "Another addon" and lateState.clears == 0)

-- Two automatic consumers share the optional renderer without sharing pins or
-- cancelling one another's ticker. Stopping the replaced consumer does no harm.
local sharedAPI, shared = Provider()
local sharedSchedule, sharedTicks = Scheduler()
local sharedEnv = { newWaypointTicker = sharedSchedule, getWaypointUIAPI = function() return sharedAPI end }
local envA, envB = {}, {}
for key, value in pairs(sharedEnv) do envA[key], envB[key] = value, value end
envA.getWaypointTarget = function() return MapPoint(0.1, 0.2), { name = "A" } end
envB.getWaypointTarget = function() return MapPoint(0.3, 0.4), { name = "B" } end
local a, b = New(envA, true), New(envB, true)
assert(#sharedTicks == 2 and shared.current.name == "A")
sharedTicks[1].callback()
assert(shared.current.name == "A" and shared.creates == 1,
    "An automatic consumer must preserve an existing consumer's waypoint")
a:SetWaypointUIEnabled(false)
assert(sharedTicks[1].cancelled and not sharedTicks[2].cancelled and shared.clears == 1)
sharedTicks[2].callback()
assert(shared.current.name == "B" and shared.creates == 2)
b:SetWaypointUIEnabled(false)
assert(shared.current == nil and shared.clears == 2)

local errorSchedule = New({ newWaypointTicker = function() error("scheduler unavailable") end,
    getWaypointTarget = function() return MapPoint(0.4, 0.5) end,
    getWaypointUIAPI = function() return sharedAPI end }, true)
Reason(errorSchedule, "waypoint_scheduler_error")
assert(shared.current.x == 0.4)
shared.clearError = true
errorSchedule:SetWaypointUIEnabled(false)
Reason(errorSchedule, "waypoint_ui_error")
assert(shared.current ~= nil)
shared.clearError = nil
errorSchedule:SetWaypointUIEnabled(false)
assert(shared.current == nil, "Disabling again must retry a failed owned cleanup")

print("Navigation automatic Waypoint UI: optional observers, transitions, retries, manual overrides and ticker ownership passed")
