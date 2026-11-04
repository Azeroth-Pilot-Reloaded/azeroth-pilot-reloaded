-- Observe native state before work and after every synchronous provider/hook.
-- Bookkeeping must not require a third complete observation on each slice.
local function fixture(options)
    options = options or {}
    local t = { timers = {}, positionReads = 0, profileReads = 0, objectiveReads = 0,
        providerCalls = 0, records = 0, events = 0, publications = 0, mode = "ground",
        position = { instanceID = 7, uiMapID = 501, x = 0, y = 0, z = 0 }, opaque = {} }
    local noop = function() end
    local step = { Zone = 502, Coord = { x = 0, y = 10000, mapID = 502, instanceID = 7 }, Waypoint = 1 }
    local context = { route = "synthetic-observations", index = 1, revision = 1,
        definition = { steps = { step } } }
    function GetTime() return 10 end
    function debugprofilestop() return 0 end
    function IsIndoors() return false end
    function IsFlying() return false end
    function UnitIsDeadOrGhost() return false end
    function InCombatLockdown() return false end
    function GetMoney() return 0 end
    function issecretvalue(value) return rawequal(value, t.opaque) end
    local nativeSpeed = function(_, _, speed) return speed end
    local nativeBuilder = function() end
    local nativeLibrary = options.nativeLibrary and {
        Instance = { GetWalkingSpeed = nativeSpeed, CreateTerrainEdgeBuild = nativeBuilder },
    }
    function LibStub(name)
        if name == "LibAPRNavigation-1.0" then return nativeLibrary end
        return { GetLocale = function() return {} end }
    end
    function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
    C_PlayerInfo = nil
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        t.timers[#t.timers + 1] = timer
        return timer
    end }
    APR = { PlayerID = "synthetic-player", ActiveRoute = context.route,
        settings = { profile = { enableAddon = true } }, GAME_VERSIONS = { Forever = "forever" },
        NewModule = function() return {} end, Arrow = { SetArrowActive = noop },
        NavigationEngine = {}, NavigationAdapter = {}, taxiData = {}, performanceLogging = true }
    APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 1 } }
    function APR:GetGameVersion() return "retail" end
    function APR:CaptureStepContext() return context end
    function APR:IsStepContextCurrent(value) return value == context end
    function APR:GetCurrentStep() return step end
    function APR:PeekCurrentStep() return step end
    function APR:GetCurrentRouteMapIDsAndName() return { 502 }, 502 end
    function APR:GetStepCoord(value)
        t.objectiveReads = t.objectiveReads + 1
        return value.Coord, value.Zone
    end
    function APR:GetNavigationPlayerPosition()
        t.positionReads = t.positionReads + 1
        return t.position
    end
    function APR:CheckNavigationZoneReady() return false end
    local function hook(site)
        if t.armed and t.site == site then t.armed = false; t.mutate() end
    end
    function APR:RecordPerformanceDuration()
        t.records = t.records + 1
        hook("record")
    end
    function APR:CountPerformanceEvent()
        t.events = t.events + 1
        hook("counter")
    end
    APR.NavigationData = { profile = "retail", CanWalk = function() return true end,
        RequiresTerrainRoute = function() return false end,
        HasTerrainData = function(_, point) return point == nil end,
        HasRoadData = function() return false end, CreateTerrainEdgeBuild = noop,
        GetTerrainRevision = function() return 1 end }
    if options.nativeLibrary then
        APR.NavigationData.GetWalkingSpeed = options.customSpeed and function(_, _, speed) return speed end or nativeSpeed
        if options.missingSpeed then APR.NavigationData.GetWalkingSpeed = nil end
        APR.NavigationData.CreateTerrainEdgeBuild = options.customBuilder and function() end or nativeBuilder
    end
    APR.NavigationPlanner = { Create = function(_, request)
        t.request = request
        local job = { phase = "search", status = "planning", active = { phase = "expand", status = "planning" },
            slices = 0, waitingData = false }
        function job:Step()
            self.slices, t.providerCalls = self.slices + 1, t.providerCalls + 1
            self.lastSliceMilliseconds = 0.25
            hook("provider")
            if t.finish then
                self.status, self.waitingData = "ready", true
                return "ready", { queue = {} }
            end
            return "planning"
        end
        function job:Cancel() self.status, self.cancelled = "cancelled", true end
        t.job = job
        return job
    end }
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    nav.Notify, nav.Render, nav.ClearNavigationUiLines = noop, noop, noop
    nav.TryResumeAfterTransition = function() return false end
    nav.GuideHousingExit = function() return false end
    nav.CaptureRetainedArrow = function() return nil end
    nav.GetDestination = function() return { instanceID = 7, uiMapID = 502, x = 10000, y = 0 }, 502 end
    nav.GetThreshold = function() return options.threshold or 2000 end
    nav.GetMovementSpeed = function(_, threshold)
        return threshold == 2000 and (options.groundSpeed or 7) or (options.travelSpeed or 7)
    end
    nav.GetMovementProfile = function()
        t.profileReads = t.profileReads + 1
        return { currentMode = t.mode, canSteady = false, canSkyriding = false,
            currentCanSteady = false, currentCanSkyriding = false,
            groundSpeed = options.profileGroundSpeed, steadySpeed = options.steadySpeed, skyridingSpeed = options.skyridingSpeed }
    end
    nav.IsItineraryValid, nav.IsDirectRouteValid = function() return false end, function() return false end
    nav.Publish = function(self)
        t.publications = t.publications + 1
        self.search, self.state = nil, "ready"
    end
    t.nav, t.step = nav, step
    function t:resume()
        local timer = assert(self.nav._searchTimer, "Unfinished work remains scheduled")
        assert(not timer.cancelled)
        timer.callback()
        return timer
    end
    nav:Update(context)
    return t
end
for _, case in ipairs({
    { options = { nativeLibrary = true, threshold = 10000, travelSpeed = 60, groundSpeed = 80,
        profileGroundSpeed = 14, steadySpeed = 30, skyridingSpeed = 60 }, bound = 80 },
    { options = { nativeLibrary = true, profileGroundSpeed = 14, steadySpeed = 30, skyridingSpeed = 120 }, bound = 120 },
    { options = { nativeLibrary = true, groundSpeed = 11.2, profileGroundSpeed = -2,
        steadySpeed = math.huge, skyridingSpeed = 0 / 0 }, bound = 11.2 },
    { options = { nativeLibrary = true, customSpeed = true } },
    { options = { nativeLibrary = true, missingSpeed = true } },
    { options = { nativeLibrary = true, customBuilder = true } },
    { options = {} },
}) do
    local value = fixture(case.options)
    assert(value.request.ordinaryWalkSpeedUpperBound == case.bound,
        "Only known native speed callbacks supply a finite upper bound covering vehicles and future flight")
    value.nav:Cancel("cleared")
end

local t = fixture()
for _ = 1, 40 do
    local positions, profiles, objectives = t.positionReads, t.profileReads, t.objectiveReads
    t:resume()
    assert(t.positionReads - positions == 2 and t.profileReads - profiles == 2
        and t.objectiveReads - objectives == 2,
        "Each unchanged slice needs only one observation before work and one after all callbacks")
end
t.finish = true
t:resume()
assert(t.publications == 1 and t.nav.lastPlanning.status == "ready" and t.nav.waitingData,
    "Fresh completed work publishes its outcome and waiting-data metadata once")
assert(t.records == t.providerCalls and t.events == 1 and APRData[APR.PlayerID][APR.ActiveRoute] == 1,
    "Completed slice bookkeeping remains complete without changing authored progress")

local mutations = {
    map = function(value) value.position.uiMapID = 503 end,
    objective = function(value) value.step.Coord.y = 20000 end,
    movement = function(value) value.mode = "steady" end,
    missing = function(value) value.position = nil end,
    restricted = function(value) value.position = value.opaque end,
    geometry = function() APR.navigationGeometryRevision = (APR.navigationGeometryRevision or 0) + 1 end,
    cancelled = function(value) value.nav:Cancel("cleared") end,
}
for _, site in ipairs({ "provider", "record", "counter" }) do
    for name, change in pairs(mutations) do
        t = fixture()
        t.finish, t.site, t.armed = true, site, true
        t.mutate = function() change(t) end
        local timer = t:resume()
        assert(not t.armed and t.publications == 0,
            "A synchronous " .. site .. " change to " .. name .. " cannot publish obsolete guidance")
        assert(t.nav.lastPlanning == nil and not t.nav.waitingData,
            "Stale outcome metadata is not committed before the final freshness check")
        local calls = t.providerCalls
        timer.callback()
        assert(t.providerCalls == calls and t.publications == 0,
            "A retired continuation cannot resume after synchronous input changes")
        t.nav:Cancel("cleared")
    end
end
issecretvalue = nil
print("Controller observations: two live samples per slice, callback freshness, restricted/missing data and stale publication guards passed")
