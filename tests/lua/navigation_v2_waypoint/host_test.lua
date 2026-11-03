local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local library, namespace = F.Load()
local api, state = F.Provider()
local observation=F.EventEnvironment()
local events, timers, combat, distance = observation.events, {}, false, 80
local context = "step-a"
local questCalls = 0
APR = { navigation = {}, IsStepContextCurrent = function(_, value) return value == context end }
APR.NextQuestStep = function() questCalls = questCalls + 1 end
GetTime, debugprofilestop = function() return 0 end, function() return 0 end
MAP_PIN = "Map pin"
InCombatLockdown = function() return combat end
WaypointUIAPI = { Navigation = api }
CreateFrame = observation.CreateFrame
C_Timer = { NewTimer = function(delay, callback)
    assert(delay > 0)
    local timer = { callback = callback, cancelled = false }
    function timer:Cancel() self.cancelled = true end
    timers[#timers + 1] = timer
    return timer
end, NewTicker = function() error("No permanent polling") end }
C_Navigation = { GetDistance = function() return distance end }
local native
C_Map = { GetUserWaypoint = function() return native end }
local create, clear = api.NewUserNavigation, api.ClearUserNavigation
api.NewUserNavigation = function(options)
    local result = create(options)
    native = { uiMapID = options.mapID, position = { x = options.x / 100, y = options.y / 100 } }
    return result
end
api.ClearUserNavigation = function(preserve, suppressAdvance)
    if not preserve then native = nil end
    clear(preserve, suppressAdvance)
end
local function Fire(event, ...)
    observation:Fire(event, ...)
end
local function Flush()
    local pending = timers
    timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
assert(loadfile("APR-Core/features/navigation/NavigationV2.lua"))("APR", namespace)
local host = APR.NavigationV2
assert(#observation.frames == 0)
assert(host:Enable(F.Graph()))
host:ObserveWorld(false)
host:Plan({ from = "start", to = "goal" }, context)
for _ = 1, 100 do if host:Step().status ~= "running" then break end end
assert(#state.creates == 0 and #observation.frames == 1 and observation:OnlyWorldEvents(),
    "A complete search only observes world state and never publishes guidance")
assert(type(host.SetTarget) == "function", "Host must create output when it supplies its target")
native = { uiMapID = 42, position = { x = 0.8, y = 0.8 } }
assert(host:SetTarget(F.Target(), context) == "occupied" and #state.creates == 0,
    "A native user marker without WUI session is still foreign")
native = nil
assert(host:SetTarget(F.Target(), context) == "active")
assert(#state.creates == 1 and #observation.frames == 2 and events.PLAYER_REGEN_ENABLED)
native = { uiMapID = 42, position = { x = 0.23, y = 0.67 } }
Fire("NAVIGATION_DESTINATION_REACHED", false)
assert(host:GetWaypointStatus() == "active")
distance = 0
Fire("PLAYER_LEAVING_WORLD")
state.tracked = false
Fire("USER_WAYPOINT_UPDATED")
Flush()
assert(host:GetWaypointStatus() == "idle" and state.current==nil, "Loading invalidates old output")
state.tracked = true
Fire("NAVIGATION_DESTINATION_REACHED", true)
assert(host:GetWaypointStatus() == "idle", "Loading is not proof of arrival")
Fire("PLAYER_ENTERING_WORLD")
assert(host:GetWaypointStatus()=='idle' and state.current==nil and observation:OnlyWorldEvents(),
    'Entering world cannot resurrect an old target')
assert(host:SetTarget(F.Target('after-loading'),context)=='active','A newly localized explicit target may publish')
native = { uiMapID = 42, position = { x = 0.23, y = 0.67 } }
Fire("NAVIGATION_DESTINATION_REACHED", true)
assert(host:GetWaypointStatus() == "arrived" and state.current == nil)
assert(observation:OnlyWorldEvents())

host:SetTarget(F.Target("second"), context)
state.current, native = nil, nil
Fire("USER_WAYPOINT_UPDATED")
Flush()
assert(host:GetWaypointStatus() == "dismissed")
assert(host:SetTarget(F.Target("second"), context) == "dismissed" and #state.creates == 3)
host:SetTarget(F.Target("third"), context)
context = "step-b"
assert(host:SetTarget({}, context) == "invalid_target")
Fire("SUPER_TRACKING_CHANGED")
Flush()
assert(state.current == nil and host:GetWaypointStatus() == "idle")

-- Late provider discovery is event-driven with bounded startup retries.
WaypointUIAPI = nil
assert(host:SetTarget(F.Target("late"), context) == "provider_unavailable")
assert(#timers == 0 and events.ADDON_LOADED)
Fire("ADDON_LOADED", "Unrelated")
assert(#timers == 0)
WaypointUIAPI = { Navigation = api }
Fire("ADDON_LOADED", "WaypointUI")
Flush()
assert(host:GetWaypointStatus() == "active")

-- Invalid replacement context is rejected without transferring the old target.
local bad = host:SetTarget(F.Target("bad"), "obsolete")
assert(bad == nil and host:GetWaypointStatus() == "active")
assert(host:SetTarget({ key = "action", title = "Use the object" }, context) == "unlocated")
assert(state.current == nil and observation:OnlyWorldEvents())
assert(host:SetTarget(F.Target("late-again"), context) == "active")
Fire("PLAYER_LEAVING_WORLD")
host:ClearTarget()
Fire('PLAYER_ENTERING_WORLD')
assert(host:SetTarget(F.Target("after-cancelled-loading"), context) == "active")
state.current, native = nil, nil
Fire("USER_WAYPOINT_UPDATED")
Flush()
assert(host:GetWaypointStatus() == "dismissed", "Cancelled loading state cannot freeze future sessions")

-- A missing provider never blocks a planning job; retry timers stop at a bound.
host:ClearTarget()
WaypointUIAPI = nil
assert(host:SetTarget(F.Target("missing"), context) == "provider_unavailable")
Fire("ADDON_LOADED", "WaypointUI")
for _ = 1, 4 do Flush() end
assert(#timers == 0 and host:GetWaypointStatus() == "provider_unavailable")
local job = host:Plan({ from = "start", to = "goal" }, context)
assert(F.Finish(job).status == "complete")
assert(host:GetWaypointStatus() == "idle" and observation:OnlyWorldEvents())
WaypointUIAPI = { Navigation = api }
host:SetTarget(F.Target("arrive-secret"), context)
native = { uiMapID = 42, position = { x = 0.23, y = 0.67 } }
issecretvalue = function(value) return value == distance end
Fire("NAVIGATION_DESTINATION_REACHED", true)
assert(host:GetWaypointStatus() == "active", "Opaque API distances cannot prove arrival")
issecretvalue = nil

-- Arrival requires current owned native position, not merely WUI data/distance.
native = { uiMapID = 42, position = { x = 0.8, y = 0.8 } }
Fire("NAVIGATION_DESTINATION_REACHED", true)
assert(host:GetWaypointStatus() == "active")
combat = true
host:Disable()
assert(state.current and events.PLAYER_REGEN_ENABLED)
combat = false
Fire("PLAYER_REGEN_ENABLED")
assert(state.current == nil and next(events) == nil)
assert(not host.enabled)
Flush()
assert(next(events) == nil and state.current == nil)
assert(questCalls == 0, "Waypoint arrival cannot progress a quest")
