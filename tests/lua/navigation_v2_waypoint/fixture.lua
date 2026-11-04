local F = dofile("tests/lua/navigation_v2/fixture.lua")

-- Event-only frames: each registration/callback belongs to its own frame.
function F.EventEnvironment()
    local env = {frames={},events={}}
    local function Sync()
        for event in pairs(env.events) do env.events[event]=nil end
        for _,frame in ipairs(env.frames) do
            for event in pairs(frame.events) do env.events[event]=true end
        end
    end
    env.CreateFrame = function(kind)
        assert(kind=='Frame','Only nonvisual event observation is allowed')
        local frame={events={}}
        function frame:RegisterEvent(event) self.events[event]=true;Sync() end
        function frame:UnregisterEvent(event) self.events[event]=nil;Sync() end
        function frame:UnregisterAllEvents() self.events={};Sync() end
        function frame:SetScript(name,callback)
            assert(name=='OnEvent','No interaction or per-frame polling')
            self.callback=callback
        end
        env.frames[#env.frames+1]=frame
        return frame
    end
    function env:Fire(event,...)
        for _,frame in ipairs(self.frames) do
            if frame.events[event] and frame.callback then frame.callback(frame,event,...) end
        end
    end
    function env:OnlyWorldEvents()
        local count=0
        for _,frame in ipairs(self.frames) do
            for event in pairs(frame.events) do
                assert(event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_LEAVING_WORLD','Unexpected idle listener: '..event)
                count=count+1
            end
        end
        assert(count==2 and self.events.PLAYER_ENTERING_WORLD and self.events.PLAYER_LEAVING_WORLD)
        return true
    end
    return env
end

function F.Provider()
    local state = { creates = {}, clears = {}, pins = { foreign = {} }, tracked = true }
    local api = {}
    function api.GetUserNavigation() return state.current end
    function api.IsUserNavigationTracked() return state.tracked end
    function api.NewUserNavigation(options)
        assert(type(options) == "table", "WUI functions use dot calls")
        state.creates[#state.creates + 1] = options
        if state.reject then return nil end
        -- WUI takes percentages and returns normalized positions and copied flags.
        local current = {}
        for key, value in pairs(options) do current[key] = value end
        current.x, current.y = options.x / 100, options.y / 100
        state.current = current
        return current
    end
    function api.ClearUserNavigation(preserve, suppressAdvance)
        state.clears[#state.clears + 1] = { preserve = preserve, suppressAdvance = suppressAdvance }
        state.current = nil
    end
    function api.ClearAllPins() error("Foreign pins must never be cleared") end
    function api.ClearDestination() error("Foreign tracking must never be cleared") end
    return api, state
end

function F.Target(key)
    return { key = key or "gate", position = { mapID = 42, x = 0.23, y = 0.67 },
        title = "Enter the gate", iconTexture = "APR-icon", iconType = "TEXTURE",
        r = 0.2, g = 0.4, b = 0.8, requestRecolor = true }
end

function F.Session()
    local library = F.Load()
    assert(type(library.NewWaypointSession) == "function", "V2 must expose its optional WUI session")
    local api, state = F.Provider()
    local env = { api = api, combat = false }
    local session = assert(library.NewWaypointSession({
        getProvider = function() return env.api end,
        inCombat = function() return env.combat end,
        defaultTitle = "Map pin",
    }))
    return session, state, env
end

-- Public AWP dispatcher contract: registration replaces the named adapter;
-- evaluation is asynchronous and manual authority outranks passive guides.
function F.AWP()
    local original = { label = "Azeroth Pilot Reloaded", icon = "APR-logo", iconSize = 16,
        extractTarget = function() error("V2 must not extract the legacy itinerary") end,
        installHooks = function() end }
    local state = { provider = original, original = original, schedules = {}, clears = {}, pending = {}, registrations = 0 }
    local api = {}
    function api.IsRoutingEnabled() return state.routingEnabled ~= false end
    function api.RecomputeCarrier() state.rendered = state.manual or state.record end
    function api.GetGuideTargetProvider(id) assert(id == "apr"); return state.provider end
    function api.RegisterGuideTargetProvider(id, adapter)
        assert(id == "apr" and type(adapter) == "table")
        state.registrations = state.registrations + 1
        state.provider = adapter
        if state.registrationError then error("partial registration") end
        return true
    end
    function api.GetGuideRouteState(id) assert(id == nil or id == "apr"); return state.record end
    function api.ClearGuideRouteState(id)
        assert(id == "apr")
        if state.clearError then error("clear failure") end
        state.clears[#state.clears + 1] = id
        state.record = nil
        api.RecomputeCarrier()
    end
    function api.ScheduleGuideProviderEvaluation(id, reason, options)
        assert(id == "apr" and type(reason) == "string")
        assert(not options or not options.explicit, "No takeover of foreign manual authority")
        state.schedules[#state.schedules + 1] = { reason = reason, options = options }
        if state.scheduleError then error("schedule failure") end
        state.pending[#state.pending + 1] = state.provider
        return true
    end
    function state:Flush()
        local pending = self.pending
        self.pending = {}
        for _ in ipairs(pending) do
            local target, suppressed = self.provider.extractTarget()
            if not suppressed and target then
                self.record = { target = target, guideSource = target.source, guideProvider = "apr" }
            else api.ClearGuideRouteState("apr") end
            api.RecomputeCarrier()
        end
    end
    return api, state
end

function F.Guidance()
    local library = F.Load()
    local wui, ws = F.Provider()
    local awp, as = F.AWP()
    local env = { wui = wui, awp = awp, combat = false, allowed = true }
    local session = assert(library.NewWaypointSession({
        getProvider = function() return env.wui end,
        getAzerothWaypoint = function() return env.awp end,
        inCombat = function() return env.combat end,
        canPublish = function() return env.allowed end,
        defaultTitle = "Map pin",
    }))
    return session, ws, as, env
end

function F.Host()
    local _, namespace = F.Load()
    local wuiAPI, wui = F.Provider()
    local awpAPI, awp = F.AWP()
    local env = { combat = false, events = {}, timers = {}, context = "step", questCalls = 0, hooks = 0 }
    local events = F.EventEnvironment()
    env.events,env.frames=events.events,events.frames
    function env:OnlyWorldEvents() return events:OnlyWorldEvents() end
    APR = { navigation = {}, IsStepContextCurrent = function(_, value) return value == env.context end,
        NextQuestStep = function() env.questCalls = env.questCalls + 1 end }
    GetTime, debugprofilestop = function() return 0 end, function() return 0 end
    MAP_PIN = "Map pin"
    InCombatLockdown = function() return env.combat end
    WaypointUIAPI, AzerothWaypointNS = { Navigation = wuiAPI }, awpAPI
    CreateFrame = events.CreateFrame
    C_Timer = { NewTimer = function(delay, callback)
        assert(delay > 0)
        local timer = { callback = callback }
        function timer:Cancel() self.cancelled = true end
        env.timers[#env.timers + 1] = timer
        return timer
    end, NewTicker = function() error("No permanent polling") end }
    C_Map = { GetUserWaypoint = function() return env.native end }
    C_Navigation = { GetDistance = function() return 0 end }
    hooksecurefunc = function(object, key, callback)
        env.hooks = env.hooks + 1
        local original = object[key]
        object[key] = function(...)
            local result = original(...)
            callback(...)
            return result
        end
    end
    local create, clear, schedule = wuiAPI.NewUserNavigation, wuiAPI.ClearUserNavigation, awpAPI.ScheduleGuideProviderEvaluation
    wuiAPI.NewUserNavigation = function(options)
        assert(not awp.record, "No AWP route when WUI publishes")
        local value = create(options)
        env.native = { uiMapID = options.mapID, position = { x = options.x / 100, y = options.y / 100 } }
        return value
    end
    wuiAPI.ClearUserNavigation = function(preserve, suppressAdvance)
        clear(preserve, suppressAdvance)
        if not preserve then env.native = nil end
    end
    awpAPI.ScheduleGuideProviderEvaluation = function(...)
        assert(wui.current == nil, "No WUI marker when AWP publishes")
        return schedule(...)
    end
    function env:Fire(event, ...)
        events:Fire(event, ...)
    end
    function env:Flush()
        local timers = self.timers
        self.timers = {}
        for _, timer in ipairs(timers) do if not timer.cancelled then timer.callback() end end
        awp:Flush()
    end
    assert(loadfile("APR-Core/features/navigation/NavigationV2.lua"))("APR", namespace)
    return APR.NavigationV2, wui, awp, env, awpAPI
end

return F
