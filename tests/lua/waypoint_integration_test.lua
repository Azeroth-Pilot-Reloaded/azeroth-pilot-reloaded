-- Exercise the public WUI and AWP contracts without installing either addon.
-- WUI NewUserNavigation accepts percentages, returns its normalized session,
-- and synchronizes a native UiMapPoint. AWP already owns the APR provider and
-- carrier: the library decorates its extractor and requests normal evaluations.
local function noop() end
strmatch = string.match
local function near(actual, expected, message)
    assert(type(actual) == "number" and math.abs(actual - expected) < 0.000001,
        (message or "Coordinate") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function fixture()
    local t = { completed = {}, timers = {}, tickers = {}, frames = {}, combat = false,
        position = { x = 0, y = 0, mapID = 1, instanceID = 0 }, summary = "Travel to goal",
        creates = {}, clears = {}, nativeWrites = 0, nativeClears = 0, summaryReads = 0,
        maps = { [1] = { parentMapID = 10, mapType = 3, instanceID = 0 },
            [2] = { parentMapID = 10, mapType = 3, instanceID = 0 },
            [3] = { parentMapID = 0, mapType = 3, instanceID = 0 },
            [10] = { parentMapID = 0, mapType = 2, instanceID = 100 },
            [11] = { parentMapID = 0, mapType = 4, instanceID = 11 } },
        blockedMaps = {} }
    WaypointUIAPI, WaypointDB_Global, AzerothWaypointNS, C_Navigation, issecretvalue, AprRCData = nil, nil, nil, nil, nil, nil
    local locale = { LOCAL_HINT = "[COLOR:#00ff00]Localized hint" }
    local hbd = {}
    function hbd:GetZoneCoordinatesFromWorldInstance(x, y, instanceID, mapID)
        if t.maps[mapID] and t.maps[mapID].instanceID == instanceID then return x / 1000, y / 1000 end
    end
    LibStub = nil
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    local dragons = LibStub:NewLibrary("HereBeDragons-2.0", 1)
    for key, value in pairs(hbd) do dragons[key] = value end
    local aceLocale = LibStub:NewLibrary("AceLocale-3.0", 1)
    function aceLocale:GetLocale() return locale end
    local root = "APR-Core/libs/LibAPRNavigation-1.0/"
    local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
    local xml = manifest:read("*a"); manifest:close()
    for path in xml:gmatch('file="([^"]+)"') do dofile(root .. path) end
    function GetBuildInfo() return "12.1.0", "1", "", 120100 end
    function GetLocale() return "enUS" end
    function GetTime() return 10 end
    function UnitIsDeadOrGhost() return t.dead end
    function InCombatLockdown() return t.combat end
    function UnitPosition()
        if t.position then return t.position.y, t.position.x, 0, t.position.instanceID end
    end
    function CreateVector2D(x, y) return { x = x, y = y } end
    function CreateFrame()
        local frame = { scripts = {}, events = {} }
        function frame:RegisterEvent(name) self.events[name] = true end
        function frame:SetScript(name, callback) self.scripts[name] = callback end
        t.frames[#t.frames + 1] = frame
        return frame
    end
    UiMapPoint = { CreateFromCoordinates = function(mapID, x, y)
        return { uiMapID = mapID, position = CreateVector2D(x, y) }
    end }
    C_Timer = { NewTicker = function(delay, callback)
        local ticker = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        t.tickers[#t.tickers + 1] = ticker
        return ticker
    end, NewTimer = function(delay, callback)
        local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        t.timers[#t.timers + 1] = timer
        return timer
    end }
    C_QuestLog = { IsQuestFlaggedCompleted = function(id) return t.completed[id] == true end }
    C_Map = {
        GetBestMapForUnit = function() return t.position and t.position.mapID end,
        GetMapInfo = function(id) return t.maps[id] end,
        GetWorldPosFromMapPos = function(id, pos)
            local map = t.maps[id]
            if map then return map.instanceID, pos end
        end,
        GetMapRectOnMap = function(id, parent)
            assert(t.maps[id] and t.maps[id].parentMapID == parent)
            if id == 1 or id == 2 then return 0.5, 1, 0, 0.5 end
        end,
        GetUserWaypoint = function() return t.native end,
        CanSetUserWaypointOnMap = function(id) return t.maps[id] ~= nil and not t.blockedMaps[id] end,
        SetUserWaypoint = function(point)
            assert(not t.combat, "Native waypoint mutation is forbidden in combat")
            assert(point.uiMapID and point.position and point.position.x <= 1 and point.position.y <= 1,
                "Native waypoints use normalized UiMapPoint coordinates")
            t.nativeWrites, t.native = t.nativeWrites + 1, point
        end,
        ClearUserWaypoint = function()
            assert(not t.combat, "Native waypoint clearing is forbidden in combat")
            t.nativeClears, t.native = t.nativeClears + 1, nil
        end,
    }
    C_SuperTrack = {
        IsSuperTrackingAnything = function() return t.anyTracking == true end,
        IsSuperTrackingUserWaypoint = function() return t.userTracking == true end,
        SetSuperTrackedUserWaypoint = function(value)
            assert(not t.combat)
            t.userTracking, t.anyTracking = value, value
        end,
    }
    local authored = { Waypoint = 101, WaypointDB = { 102, 103 }, Zone = 1, Range = 10,
        Coord = { x = 200, y = 300 }, Note = { "LOCAL_HINT", "Same hint" },
        ExtraLineText = { "Same hint", "Another hint" } }
    t.routes = { route = { mapID = 1, steps = { authored, {
        Waypoint = 104, Zone = 1, Range = 10, Coord = { x = 400, y = 500 }, Note = "Next hint" } } } }
    APR = { PlayerID = "p", ActiveRoute = "route", RouteQuestStepList = t.routes, IsInRouteZone = true,
        settings = { profile = { enableAddon = true, showArrow = false } }, stepRevision = 0 }
    APRData = { p = { route = 1 } }
    function APR:NewModule()
        local module = { messages = {}, events = {} }
        function module:RegisterMessage(name, callback) self.messages[name] = callback end
        function module:RegisterEvent(name, callback) self.events[name] = callback end
        function module:UnregisterAllMessages() self.messages = {} end
        function module:UnregisterAllEvents() self.events = {} end
        return module
    end
    function APR:GetRouteSteps(key) return t.routes[key].steps end
    function APR:GetPlayerParentMapID() return t.parentMap or (t.position and t.position.mapID) end
    function APR:GetCurrentRouteMapIDsAndName()
        local mapID = t.routes[self.ActiveRoute].mapID
        return { mapID }, mapID
    end
    function APR:GetScenarioStepTarget() end
    function APR:GetContinent() return 1 end
    function APR:Contains(values, value)
        for _, entry in ipairs(values) do if entry == value then return true end end
        return false
    end
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    function APR:CheckWaypointText() t.summaryReads = t.summaryReads + 1; return t.summary end
    dofile("APR-Core/features/navigation/Preview.lua")
    APR.navigation = { state = "ready" }
    function APR.navigation:IsNavigating() return self.state == "guiding" and self.active ~= nil end
    function APR.navigation:GetActiveStep() return self.active end
    function APR.navigation:GetRetainedArrow()
        local retained = self.retainedArrow
        if retained and (not retained.context or APR:IsStepContextCurrent(retained.context)) then return retained end
    end
    dofile("APR-Core/features/navigation/NavigationAdapter.lua")
    t.integration = {}
    function t.integration:Refresh() APR.NavigationData:RefreshWaypoints() end
    function t.integration:Release(suppress) APR.NavigationData:ReleaseWaypoints(suppress) end
    function t.integration:RequestRefresh() APR.NavigationData:RefreshWaypoints() end
    function t.integration:OnEnable() APR.NavigationData:SetWaypointsEnabled(true) end
    function t.integration:OnDisable() APR.NavigationData:SetWaypointsEnabled(false) end
    t.step, t.source = APR:GetCurrentStep(), authored
    function t:WUI()
        local api = {}
        api.GetUserNavigation = function() return self.session end
        api.IsPathStepWaypointTracked = function() return self.pathTracked == true end
        api.NewUserNavigation = function(options)
            assert(not self.combat, "WUI creation is forbidden in combat")
            assert(type(options) == "table" and options.mapID and options.x >= 0 and options.x <= 100
                and options.y >= 0 and options.y <= 100)
            self.creates[#self.creates + 1] = options
            self.session = { name = options.name, mapID = options.mapID,
                x = options.x / 100, y = options.y / 100, flags = options.flags,
                fromWUI = true, superTracked = true }
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(options.mapID, self.session.x, self.session.y))
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            return self.session
        end
        api.ClearUserNavigation = function(preserveWaypoint, suppressAdvance)
            assert(not self.combat, "WUI clearing is forbidden in combat")
            assert(suppressAdvance == nil, "Clearing APR guidance must allow WUI's normal path cleanup callback")
            self.clears[#self.clears + 1] = { preserve = preserveWaypoint }
            if not preserveWaypoint then C_Map.ClearUserWaypoint(); self.userTracking = false end
            self.session, self.pathTracked = nil, false
        end
        WaypointUIAPI = { Navigation = api }
        self.api = api
        return api
    end
    function t:AWP()
        self.normalTarget = { mapID = 3, x = 0.7, y = 0.8, title = "Existing AWP quest target" }
        self.normalCalls, self.registrations, self.scheduled, self.awClears = 0, 0, {}, {}
        local original = { priority = 40, addonNames = { "APR" }, isAvailable = noop,
            getActivationToken = function() return "original:quest" end,
            extractTarget = function()
                self.normalCalls = self.normalCalls + 1
                return self.normalTarget, false
            end }
        self.providers = { apr = original }
        AzerothWaypointNS = {
            GetGuideTargetProvider = function(id) assert(id == "apr"); return self.providers[id] end,
            RegisterGuideTargetProvider = function(id, provider)
                assert(id == "apr" and provider ~= original)
                self.registrations, self.providers[id] = self.registrations + 1, provider
                return true
            end,
            ScheduleGuideProviderEvaluation = function(id, reason)
                assert(id == "apr" and not self.combat)
                self.scheduled[#self.scheduled + 1] = reason
            end,
            ClearGuideRouteState = function(id)
                assert(id == "apr" and not self.combat)
                self.awClears[#self.awClears + 1] = id
            end,
        }
        self.originalProvider = original
        return original
    end
    function t:Refresh() self.integration:Refresh() end
    function t:Drain()
        local turns = 0
        while #self.timers > 0 do
            turns = turns + 1; assert(turns < 100, "Waypoint refresh events must settle")
            local timer = table.remove(self.timers, 1)
            if not timer.cancelled then timer.callback() end
        end
    end
    function t:Tick()
        for _, ticker in ipairs(self.tickers) do if not ticker.cancelled then ticker.callback() end end
        for _, frame in ipairs(self.frames) do if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.5) end end
    end
    function t:Guidance(id, x, y, mapID)
        return { id = id, label = "Use the active passage", Coord = { x = x, y = y, mapID = mapID or 1 },
            uiMapID = mapID or 1, instanceID = 0, context = APR:CaptureStepContext() }
    end
    return t
end

local failures, count = {}, 0
local function scenario(name, body)
    count = count + 1
    local ok, message = xpcall(function() body(fixture()) end, debug.traceback)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(message) end
end

scenario("optional providers absent", function(t)
    t:Refresh(); t:Tick()
    assert(t.nativeWrites == 0 and APRData.p.route == 1)
end)

for _, provider in ipairs({ "WUI", "AWP" }) do
    scenario("legacy disabled waypoint option does not prevent automatic " .. provider .. " output", function(t)
        APR.settings.profile.waypointUI = false
        t[provider](t)
        t:Tick()
        local function Published()
            if provider == "WUI" then return t.session end
            return t.providers.apr.extractTarget()
        end
        assert(Published(), "An installed provider receives APR guidance automatically, including older profiles")
        APR.NavigationAdapter:RefreshWaypoints()
        assert(Published(), "Profile synchronization must ignore the removed waypointUI setting")
        assert(APR.settings.profile.showArrow == false and APRData.p.route == 1,
            "Automatic output remains independent of APR arrow visibility and guide progression")
    end)
end

scenario("APR exports normalized guidance and a stable authored context", function(t)
    local target, options = APR.NavigationAdapter.environment.getWaypointTarget()
    assert(target.space == "map" and target.uiMapID == 1 and target.mapID == 1)
    near(target.x, 0.2); near(target.y, 0.3)
    assert(target.worldPosition.instanceID == 0 and target.worldPosition.x == 300
        and target.worldPosition.y == 200 and options.guideMode == "override")
    local context = options.context
    APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("7:1", 650, 750, 2)
    local transient, activeOptions = APR.NavigationAdapter.environment.getWaypointTarget()
    assert(transient.transient and transient.mapID == 2 and activeOptions.context == context
        and activeOptions.token ~= options.token,
        "Generated legs change presentation identity without changing their authored context")
end)

scenario("navigation cancellation delegates cleanup and context suppression to the library", function(t)
    t:WUI(); t:Refresh(); assert(t.session)
    dofile("APR-Core/features/navigation/Navigation.lua")
    APR.navigation:Cancel("replan", true)
    assert(t.session and #t.clears == 0, "Retained guidance keeps its provider session")
    APR.navigation:ClearActivePath(); t:Refresh()
    assert(not t.session and #t.creates == 1 and #t.clears == 1,
        "Clearing the APR path also suppresses its authored context")
    APR.stepRevision = APR.stepRevision + 1; t:Refresh()
    assert(t.session and #t.creates == 2)
    APR.navigation:Cancel("step_changed"); t:Refresh()
    assert(t.session and #t.creates == 3, "Technical cleanup remains eligible for a fresh publication")
end)

scenario("committed step rendering refreshes the library after pending flags reset", function(t)
    t:WUI(); APR.currentStep = {}
    function APR:StartPerformanceSample() return 0 end
    function APR:FinishPerformanceSample() end
    function APR:RenderCurrentStep()
        assert(self.stepUpdateRunning and not self.stepUpdatePending)
    end
    dofile("APR-Core/features/questing/QuestHandler.lua")
    APR:UpdateStep()
    assert(t.session and not APR.stepUpdateRunning and not APR.stepUpdatePending,
        "The finalized step publishes immediately through the library")
end)

scenario("WUI public contract, runtime target and authored hints", function(t)
    t:WUI(); t.step.Coord = { x = 250, y = 350 }
    t:Refresh()
    assert(#t.creates == 1 and APR.NavigationData:GetWaypointUIStatus())
    near(t.creates[1].x, 25); near(t.creates[1].y, 35)
    near(t.session.x, 0.25); near(t.native.position.y, 0.35)
    assert(type(t.creates[1].flags) == "string" and t.creates[1].suppressAudio == true)
    assert(t.session.name == "Travel to goal\nLocalized hint\nSame hint\nAnother hint")
    assert(t.source.Coord.x == 200 and APRData.p.route == 1, "Waypoint consumers cannot rewrite the route")
    local summaryReads = t.summaryReads
    for _ = 1, 8 do t:Refresh() end
    assert(#t.creates == 1 and #t.clears == 0 and t.summaryReads == summaryReads,
        "An unchanged target preserves session identity and avoids API churn")
end)

for name, change in pairs({
    NoArrow = function(t) t.step.NoArrow = true end,
    WaypointCompleted = function(t) t.completed[101] = true end,
    WaypointDBCompleted = function(t) t.completed[103] = true end,
    OrdinaryQuest = function(t) t.step.Waypoint = nil; t.step.Qpart = { [101] = { 1 } } end,
    OutOfRouteZone = function() APR.IsInRouteZone = false end,
    PlayerDead = function(t) t.dead = true end,
    PendingStepBatch = function() APR.stepUpdatePending = true end,
    RunningStepBatch = function() APR.stepUpdateRunning = true end,
}) do
    scenario("suppresses " .. name, function(t)
        t:WUI(); change(t); t:Refresh()
        assert(#t.creates == 0 and APRData.p.route == 1)
    end)
end

scenario("explicit arrival survives completed quest anchors", function(t)
    t:WUI(); t.completed[101], t.completed[103] = true, true
    t.step.ZoneStepTrigger = { mapID = 1, x = 600, y = 700, Range = 10 }
    t:Refresh()
    assert(#t.creates == 1)
    near(t.session.x, 0.6); near(t.session.y, 0.7)
    assert(APRData.p.route == 1)
end)

scenario("active transient guidance overrides ordinary quest coordinates", function(t)
    t:WUI(); t.step.Waypoint = nil; t.step.Qpart = { [101] = { 1 } }
    APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("8:2", 600, 700, 2)
    APR.navigation.context = APR:CaptureStepContext()
    t:Refresh()
    assert(#t.creates == 1 and t.session.mapID == 2)
    near(t.session.x, 0.6); near(t.session.y, 0.7)
    assert(t.session.name == "Use the active passage\nLocalized hint\nSame hint\nAnother hint")
    APR.navigation.active = t:Guidance("8:3", 650, 750, 2)
    t:Refresh()
    assert(#t.creates == 2 and APRData.p.route == 1, "A synthetic leg update never advances the authored objective")
end)

scenario("retained guidance keeps its own map and text during replanning", function(t)
    t:WUI(); APR.navigation.state = "planning"
    APR.navigation.retainedArrow = t:Guidance("8:2", 600, 700, 2)
    t:Refresh()
    assert(#t.creates == 1 and t.session.mapID == 2 and t.session.name:find("Use the active passage", 1, true))
    APR.navigation.retainedArrow.context.revision = -1
    t:Refresh()
    assert(not t.session, "Invalid retained context cannot fall back to obsolete authored guidance")
end)

scenario("planning, stale guidance and source-free actions do not invent a waypoint", function(t)
    t:WUI(); APR.navigation.state = "planning"; t:Refresh(); assert(#t.creates == 0)
    APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("8:1", 500, 600)
    APR.navigation.context = APR:CaptureStepContext(); APR.navigation.context.revision = -1
    t:Refresh(); assert(#t.creates == 0)
    APR.navigation.context = APR:CaptureStepContext()
    APR.navigation.active.sourceFree, APR.navigation.active.action = true, { type = "item", data = 6948 }
    t:Refresh(); assert(#t.creates == 0)
end)

scenario("multi-zone active coordinate selection", function(t)
    t:WUI(); t.step.Zone, t.step.Zones, t.step.Coord = nil, { 1, 2 }, nil
    t.step.Coords = { [1] = { x = 200, y = 300 }, [2] = { x = 650, y = 750 } }
    t.position.mapID = 2
    t:Refresh()
    assert(t.session and t.session.mapID == 2)
    near(t.session.x, 0.65); near(t.session.y, 0.75)
end)

scenario("simple world coordinates still resolve a table of zones", function(t)
    t:WUI(); t.step.Zone = { 1, 2 }; t.position.mapID = 2
    t:Refresh()
    assert(t.session and t.session.mapID == 2)
    near(t.session.x, 0.2); near(t.session.y, 0.3)
end)

scenario("arrival retires presentation with the APR arrow hidden", function(t)
    t:WUI(); t:Refresh(); t.position.x, t.position.y = 200, 300
    t:Tick()
    assert(not t.session and not t.native and #t.clears == 1)
    assert(APRData.p.route == 1, "Arrival in a provider cannot change route progress")
    t.position.x, t.position.y = 0, 0; t:Tick()
    assert(#t.creates == 1, "Leaving the arrival radius cannot resurrect a retired authored waypoint")
end)

scenario("world instance and loading positions reject stale targets", function(t)
    t:WUI(); t:Refresh(); t.position.instanceID = 11; t:Refresh()
    assert(not t.session and #t.creates == 1)
    t.position = nil; t:Refresh(); assert(#t.creates == 1)
end)

for _, legacy in ipairs({ false, true }) do
    scenario(legacy and "legacy relevant objective tracking" or "C_Navigation relevant objective tracking", function(t)
        t:WUI(); t.anyTracking = true
        local get = function(mapID) assert(mapID == 1); return 0.2, 0.3 end
        if legacy then C_SuperTrack.GetNextWaypointForMap = get
        else C_Navigation = { GetNextWaypointForMap = get } end
        t:Refresh()
        assert(#t.creates == 0, "A meaningful existing objective needs no extra WUI waypoint")
        local other = function() return 0.8, 0.9 end
        if legacy then C_SuperTrack.GetNextWaypointForMap = other else C_Navigation.GetNextWaypointForMap = other end
        t:Refresh(); assert(#t.creates == 1, "An unrelated objective cannot hide the active APR path")
    end)
end

scenario("player marker and another consumer retain authority", function(t)
    t:WUI(); t.native = UiMapPoint.CreateFromCoordinates(1, 0.8, 0.9)
    local manual = t.native
    t:Refresh(); assert(#t.creates == 0 and t.native == manual)
    t.native, t.session = nil, { name = "Other consumer", mapID = 1, x = 0.8, y = 0.9 }
    local foreign = t.session
    t:Refresh(); t.integration:Release()
    assert(t.session == foreign and #t.clears == 0)
end)

scenario("manual removal is respected until the active identity changes", function(t)
    t:WUI(); t:Refresh(); t.session, t.native, t.userTracking, t.anyTracking = nil, nil, false, false
    t:Refresh(); t:Tick(); assert(#t.creates == 1, "Periodic refresh cannot recreate a dismissed session")
    APR.stepRevision = APR.stepRevision + 1; t:Refresh()
    assert(#t.creates == 2, "A new step revision may publish its own waypoint")
end)

scenario("identical metadata cannot transfer session ownership", function(t)
    t:WUI(); t:Refresh()
    local foreign = {}; for key, value in pairs(t.session) do foreign[key] = value end
    t.session = foreign
    t.integration:Release()
    assert(t.session == foreign and #t.clears == 0 and t.native,
        "Only the original session object may be cleared by APR")
end)

scenario("manual replacement survives cleanup", function(t)
    t:WUI(); t:Refresh(); t.native = UiMapPoint.CreateFromCoordinates(1, 0.8, 0.9)
    local manual = t.native
    t:Refresh(); t:Tick()
    assert(t.native == manual and not t.session and t.clears[1].preserve == true and #t.creates == 1)
end)

scenario("a selected objective is respected while a temporarily untracked overlay is retained", function(t)
    t:WUI(); t:Refresh(); t.userTracking = false; t:Refresh()
    assert(t.session and #t.clears == 0,
        "A WUI overlay may temporarily clear native supertracking without dismissing its session")
    t.session.superTracked = false; t:Refresh(); t:Tick()
    assert(not t.session and #t.creates == 1 and #t.clears == 1,
        "Explicitly selecting another objective dismisses this APR session")
end)

scenario("WUI path-step carrier is not a manual replacement", function(t)
    t:WUI(); t:Refresh(); t.pathTracked = true
    t.native = UiMapPoint.CreateFromCoordinates(1, 0.1, 0.15)
    t:Refresh()
    assert(t.session and #t.clears == 0 and #t.creates == 1)
    t.integration:Release()
    assert(not t.session and #t.clears == 1 and not t.clears[1].preserve)
end)

scenario("explicit cancellation and route identity", function(t)
    t:WUI(); t:Refresh(); t.integration:Release(true); t:Refresh()
    assert(not t.session and #t.creates == 1, "Cancellation cannot immediately resurrect the same target")
    APR:SetRouteProgress("route", 2, "manual")
    t:Refresh(); assert(#t.creates == 2 and t.session.name:find("Next hint", 1, true))
    t.routes.other = { mapID = 1, steps = { t.source } }; APRData.p.other = 1
    APR:ActivateRoute("other"); t:Refresh()
    assert(#t.creates == 3 and APRData.p.other == 1, "Route switches with the same coordinate keep distinct ownership")
end)

scenario("technical cleanup can republish the same still-active waypoint", function(t)
    t:WUI(); t:Refresh(); t.integration:Release(); t:Refresh()
    assert(t.session and #t.creates == 2 and APRData.p.route == 1,
        "A temporary planning cleanup must not act as a player cancellation")
end)

scenario("cancelling transient guidance also cancels fallback for that authored context", function(t)
    t:WUI(); APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("4:2", 600, 700)
    t:Refresh(); t.integration:Release(true)
    APR.navigation.state, APR.navigation.active = "ready", nil; t:Refresh()
    assert(not t.session and #t.creates == 1,
        "Cancellation cannot silently replace transient guidance with its authored destination")
    APR.stepRevision = APR.stepRevision + 1; t:Refresh()
    assert(t.session and #t.creates == 2)
end)

scenario("combat creation resolves the live target after combat", function(t)
    t:WUI(); t.combat = true; t:Refresh(); assert(#t.creates == 0)
    t.step.Coord = { x = 650, y = 750 }; t.combat = false
    t.integration:RequestRefresh(); t:Drain()
    assert(#t.creates == 1); near(t.session.x, 0.65); near(t.session.y, 0.75)
end)

scenario("deferred combat cleanup preserves a newer player marker", function(t)
    t:WUI(); t:Refresh(); t.combat = true; t.integration:Release()
    assert(t.session and #t.clears == 0)
    t.native = UiMapPoint.CreateFromCoordinates(1, 0.8, 0.9)
    local manual = t.native
    t.combat = false; t:Refresh()
    assert(t.native == manual and not t.session and #t.creates == 1 and t.clears[1].preserve)
end)

scenario("profile disable and reenable", function(t)
    t:WUI(); t:Refresh(); APR.settings.profile.enableAddon = false; t:Tick()
    assert(not t.session and not t.native)
    APR.settings.profile.enableAddon = true; t:Refresh()
    assert(t.session and #t.creates == 2, "Reenabling APR may restore its active waypoint")
end)

scenario("library disable stops scheduled work and reenable resumes it", function(t)
    t:WUI(); t.integration:OnEnable(); t:Tick(); assert(t.session)
    local pending = t.tickers[#t.tickers]
    t.integration:OnDisable()
    assert(pending.cancelled and not t.session)
    t:Drain(); t:Tick(); assert(#t.creates == 1)
    pending.callback(); assert(#t.creates == 1, "Cancelled observers cannot publish")
    t.integration:OnEnable(); t:Tick()
    assert(t.session and #t.creates == 2, "The library restores the current authored target")
end)

scenario("polling cleans up after combat with the APR arrow hidden", function(t)
    t:WUI(); t:Tick()
    assert(#t.creates == 1 and APR.settings.profile.showArrow == false)
    APR.settings.profile.enableAddon = false; t.combat = true; t:Tick(); assert(t.session)
    t.combat = false; t:Tick()
    assert(not t.session, "The library observes combat cleanup while APR gameplay events are disabled")
end)

scenario("native APR support avoids duplicate WUI sessions", function(t)
    t:WUI(); WaypointDB_Global = { APRSupportEnabled = true }; t:Refresh(); assert(#t.creates == 0)
    WaypointDB_Global.APRSupportEnabled = false; t:Refresh(); assert(#t.creates == 1)
    WaypointDB_Global.APRSupportEnabled = true; t:Refresh(); assert(not t.session)
end)

scenario("unsupported native child map projects onto its supported parent", function(t)
    t:WUI(); t.blockedMaps[1] = true; t:Refresh()
    assert(t.session and t.session.mapID == 10)
    near(t.session.x, 0.6); near(t.session.y, 0.15)
    assert(t.native.uiMapID == 10 and #t.creates == 1)
end)

scenario("unavailable maps and invalid coordinates are not published", function(t)
    t:WUI(); t.blockedMaps[1], t.blockedMaps[10] = true, true; t:Refresh(); assert(#t.creates == 0)
    t.blockedMaps = {}; t.step.Coord = { x = 1500, y = 300 }; t:Refresh(); assert(#t.creates == 0)
    t.step.Coord = { x = 0 / 0, y = 300 }; t:Refresh(); assert(#t.creates == 0)
    t.step.Coord = { x = 200, y = 300 }; issecretvalue = function(value) return value == 200 end
    t:Refresh(); assert(#t.creates == 0)
end)

scenario("AWP keeps its normal APR provider extraction and metadata", function(t)
    local original = t:AWP(); t.step.Waypoint = nil; t.step.Qpart = { [101] = { 1 } }; t:Refresh()
    local provider = t.providers.apr
    assert(provider ~= original and provider.priority == original.priority and provider.addonNames == original.addonNames
        and provider.isAvailable == original.isAvailable)
    local target, blocked = provider.extractTarget()
    assert(target == t.normalTarget and blocked == false and t.normalCalls == 1)
    assert(provider.getActivationToken() == "original:quest", "Ordinary AWP activation identity stays unchanged")
    for _ = 1, 5 do t:Refresh() end
    assert(t.registrations == 1 and #t.scheduled == 1, "Stable refreshes never stack wrappers or spam provider evaluation")
    assert(t.nativeWrites == 0 and #t.creates == 0, "AWP owns its existing map/TomTom carrier")
end)

scenario("AWP waypoint target and precedence over WUI", function(t)
    t:WUI(); t:AWP(); t:Refresh()
    t.normalTarget.aprQuestIDs, t.normalTarget.semanticQuestID = { 101, 102, 103 }, 101
    local target, blocked = t.providers.apr.extractTarget()
    assert(target and blocked == false and target.guideProvider == "apr" and target.kind == "guide_goal"
        and target.source == "apr.step#1" and target.title == "Travel to goal" and target.rawTitle == target.title)
    near(target.x, 0.2); near(target.y, 0.3)
    assert(target.subtext == "Localized hint\nSame hint\nAnother hint")
    assert(target.aprQuestIDs == t.normalTarget.aprQuestIDs and target.semanticQuestID == 101
        and t.normalTarget.title == "Existing AWP quest target" and t.normalTarget.mapID == 3,
        "AWP keeps its authored quest semantics without mutating the native extractor's result")
    assert(#t.creates == 0 and t.nativeWrites == 0 and t.normalCalls == 1 and #t.scheduled == 1)
    local token = t.providers.apr.getActivationToken()
    APR.stepRevision = APR.stepRevision + 1; t:Refresh()
    assert(t.providers.apr.getActivationToken() ~= token,
        "AWP activation sees a new APR identity even when coordinates and text coincide")
    t.completed[102] = true; t:Refresh()
    target, blocked = t.providers.apr.extractTarget()
    assert(target == nil and blocked == true, "Completed WaypointDB targets cannot leak through the original AWP extractor")
end)

scenario("AWP acquisition retires only APR's former WUI carrier", function(t)
    t:WUI(); t:Refresh(); t:AWP(); t:Refresh()
    assert(not t.session and #t.clears == 1 and t.registrations == 1 and t.nativeWrites == 1)
    assert(t.providers.apr.extractTarget() and #t.creates == 1)
end)

scenario("AWP wraps active and retained navigation instead of authored quest targets", function(t)
    t:AWP(); t.step.Waypoint = nil; t.step.Qpart = { [101] = { 1 } }
    APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("7:3", 600, 700, 2)
    APR.navigation.context = APR:CaptureStepContext(); t:Refresh()
    local target = t.providers.apr.extractTarget()
    assert(target.mapID == 2 and target.title == "Use the active passage" and target.source == "apr.step#1:7:3")
    near(target.x, 0.6); near(target.y, 0.7)
    APR.navigation.retainedArrow, APR.navigation.state = APR.navigation.active, "planning"
    APR.navigation.active = nil; t:Refresh()
    assert(t.providers.apr.extractTarget().mapID == 2 and t.normalCalls == 0)
end)

scenario("AWP keeps combat routing ownership and defers evaluations and releases", function(t)
    t:AWP(); t:Refresh(); local scheduled = #t.scheduled
    t.combat = true; t:Refresh()
    assert(t.providers.apr.extractTarget(), "AWP can inspect the live APR target while its own combat handling defers mutation")
    assert(#t.scheduled == scheduled)
    t.integration:Release(); assert(#t.awClears == 0)
    t.combat = false; APR.stepRevision = APR.stepRevision + 1; t:Refresh()
    assert(#t.awClears == 1 and #t.scheduled == scheduled + 1 and t.nativeWrites == 0)
end)

scenario("AWP cancellation of transient guidance suppresses ordinary quest fallback", function(t)
    t:AWP(); t.step.Waypoint = nil; t.step.Qpart = { [101] = { 1 } }
    APR.navigation.state, APR.navigation.active = "guiding", t:Guidance("7:3", 600, 700, 2)
    t:Refresh(); t.integration:Release(true)
    APR.navigation.state, APR.navigation.active = "ready", nil
    t:Refresh()
    local target, blocked = t.providers.apr.extractTarget()
    assert(target == nil and blocked == true and t.normalCalls == 0,
        "An explicit cancellation cannot restart AWP's normal quest carrier for the same context")
    APR.stepRevision = APR.stepRevision + 1
    assert(t.providers.apr.extractTarget() == t.normalTarget)
end)

scenario("incomplete AWP registry falls back to WUI", function(t)
    t:WUI(); t:AWP(); t.providers.apr = nil; t:Refresh()
    assert(#t.creates == 1 and t.registrations == 0 and #t.scheduled == 0)
end)

scenario("disabled AWP wrapper cannot advertise APR targets", function(t)
    t:AWP(); t:Refresh(); APR.settings.profile.enableAddon = false; t:Refresh()
    local target, blocked = t.providers.apr.extractTarget()
    assert(target == nil and blocked == true and #t.awClears == 1 and APRData.p.route == 1,
        "Disabled provider state: target=" .. tostring(target) .. ", blocked=" .. tostring(blocked)
            .. ", clears=" .. tostring(#t.awClears))
end)

assert(#failures == 0, table.concat(failures, "\n\n"))
print("Waypoint integration: " .. count .. " scenarios passed through real APR runtime/geometry and faithful public provider contracts")
