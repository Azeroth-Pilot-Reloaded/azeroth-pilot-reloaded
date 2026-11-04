-- Load actual addon V2 declarations in TOC/XML order; mock external providers only.
local R = {}
local F = dofile("tests/lua/navigation_v2_scheduled/fixture.lua")
local W = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
R.Route = F.Route

local function Read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

function R.Load(host)
    local ns, loaded = {}, {}
    for path in Read("APR.toc"):gmatch("[^\r\n]+") do
        if path:match("^APR%-Core/libs/LibAPRNavigation%-2%.0/.*%.xml$") then
            local root = path:match("^(.*/)")
            for name in Read(path):gmatch('<Script%s+file="([^"]+)"') do
                assert(not loaded[root .. name], "Duplicate module registration")
                assert(loadfile(root .. name))("APR", ns)
                loaded[root .. name] = true
            end
        elseif host and path:match("^APR%-Core/features/navigation/NavigationV2[%w]*%.lua$") then
            assert(ns.LibAPRNavigationV2, "Library must load before host adapters")
            assert(not loaded[path], "Duplicate host registration")
            assert(loadfile(path))("APR", ns)
            loaded[path] = true
        end
    end
    assert(ns.NavigationV2Scheduled and ns.NavigationV2Actions and ns.LibAPRNavigationV2)
    if host then assert(APR.NavigationV2 and ns.NavigationV2Movement) end
    return ns
end

function R.Timed()
    local route = F.Route()
    route.access = "available"
    route.wait = { mode = "periodic", firstDeparture = 110, periodSeconds = 30 }
    return route
end

function R.Graph(approach, walk)
    return { complete = true, nodes = { "start", "west pier", "east pier", "goal" }, edges = {
        { id = "to pier", from = "start", to = "west pier", seconds = approach or 5 },
        { id = "from pier", from = "east pier", to = "goal", seconds = 3 },
        { id = "overland", from = "start", to = "goal", seconds = walk or 80 },
    } }
end

function R.Planner(graph, options)
    local ns = R.Load()
    local time = { now = 100 }
    options = options or {}
    options.clock, options.profileClock = function() return time.now end, function() return 0 end
    return assert(ns.LibAPRNavigationV2.New(graph, options)), time, ns
end

function R.Finish(job)
    for _ = 1, 10000 do
        local result = assert(job:Step(1))
        if result.status ~= "running" then return result end
    end
    error("Scheduled integration did not terminate")
end

function R.Host(awp)
    local env = { now = 100, context = "active objective", timers = {}, frames = {}, questCalls = 0 }
    APR = { navigation = { legacy = true }, IsStepContextCurrent = function(_, context) return context == env.context end,
        NextQuestStep = function() env.questCalls = env.questCalls + 1; error("Transport must not advance quests") end }
    GetTime, debugprofilestop = function() return env.now end, function() return 0 end
    MAP_PIN, InCombatLockdown = "Map pin", function() return env.combat == true end
    local wui, ws = W.Provider()
    local api, as = W.AWP()
    WaypointUIAPI, AzerothWaypointNS = { Navigation = wui }, awp and api or nil
    C_Map, hooksecurefunc = { GetUserWaypoint = function() return nil end }, nil
    C_Timer = { NewTimer = function(delay, callback)
        assert(delay > 0)
        local timer = { delay = delay, callback = callback }
        function timer:Cancel() self.cancelled = true end
        env.timers[#env.timers + 1] = timer
        return timer
    end, NewTicker = function() error("No periodic polling") end }
    CreateFrame = function()
        local frame = { events = {} }
        function frame:SetScript(kind, callback)
            assert(kind ~= "OnUpdate", "No permanent per-frame work")
            self.callback = callback
        end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        env.frames[#env.frames + 1] = frame
        return frame
    end
    local ns = R.Load(true)
    return APR.NavigationV2, env, ws, as, ns
end

function R.Proof(route, action, kind, sequence, destination)
    local stop = destination and route.destination or route.origin
    return { kind = kind, sequence = sequence, objectiveID = action.objectiveID, routeID = route.id,
        confirmed = true, attempt = action.attempt, stopID = stop.id, worldID = stop.worldID,
        floorID = stop.floorID, phaseID = stop.phaseID,
        onTransport = kind == "boarded" or kind == "departed" or kind == "destination" }
end

return R
