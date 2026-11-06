-- Count live observations around a deliberately long, synthetic planning job.
-- The controller is real; controlled slices isolate its scheduling overhead.
local function fixture(profile)
    local s = {
        now = 10,
        positionReads = 0,
        coordinateReads = 0,
        valueReads = 0,
        frames = 0,
        timers = {},
        position = { x = 0, y = 0, instanceID = 1, uiMapID = 101 },
    }
    local noop = function() end
    local step = { Zone = 102, Coord = { x = 0, y = 3000, instanceID = 1 } }
    local steps = { step, {} }
    function LibStub()
        return { GetLocale = function() return {} end }
    end
    function CreateFrame() return { SetScript = noop, RegisterEvent = noop } end
    function GetTime() return s.now end
    function UnitIsDeadOrGhost() return s.dead end
    function IsIndoors() return false end
    function IsFlyableArea() return false end
    function IsFlying() return false end
    function GetUnitSpeed() return 0, 7, 0 end
    C_Map, C_PlayerInfo, C_MountJournal = nil, nil, nil
    C_Timer = {
        NewTimer = function(delay, callback)
            local timer = {
                callback = callback,
                due = s.now + delay,
                Cancel = function(self) self.cancelled = true end,
            }
            s.timers[#s.timers + 1] = timer
            return timer
        end,
    }
    APR = {
        PlayerID = "synthetic-player",
        ActiveRoute = "synthetic-route",
        RouteQuestStepList = { ["synthetic-route"] = steps },
        settings = { profile = { enableAddon = true } },
        GAME_VERSIONS = { Forever = "forever" },
        NewModule = function() return {} end,
    }
    APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 1 } }
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return step, 1, steps end
    function APR:PeekCurrentStep() return step end
    function APR:GetCurrentRouteMapIDsAndName() return { 102 }, 102 end
    function APR:GetStepCoord(value)
        s.coordinateReads = s.coordinateReads + 1
        return s.override or value.Coord, value.Zone
    end
    function APR:GetNavigationPlayerPosition()
        s.positionReads = s.positionReads + 1
        return not s.missingPosition and s.position or nil
    end
    function APR:CanAccessValue(value)
        s.valueReads = s.valueReads + 1
        return s.opaque == nil or not rawequal(value, s.opaque)
    end
    function APR:CheckNavigationZoneReady() return false end
    APR.NavigationData = { profile = profile, CanWalk = function() return true end }
    APR.NavigationPlanner = {
        Create = function(_, request)
            local job = { request = request, slices = 0 }
            function job:Step(_, milliseconds)
                assert(milliseconds <= 1, "The search keeps its one-millisecond work allowance")
                self.slices = self.slices + 1
                self.lastSliceMilliseconds = 0.5
                if s.onStep then s.onStep() end
                return s.resultState or "planning", s.result
            end
            function job:Cancel() self.cancelled = true end
            return job
        end,
    }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/Navigation.lua")
    s.nav, s.step = APR.navigation, step
    s.nav:Update()
    assert(s.nav.search and s.nav.state == "planning")
    s.job = s.nav.search
    function s:frame(delta)
        self.now, self.frames = self.now + delta, self.frames + 1
        local pending = self.timers
        self.timers = {}
        for _, timer in ipairs(pending) do
            if not timer.cancelled then
                if timer.due <= self.now + 0.0000001 then
                    timer.callback()
                else
                    self.timers[#self.timers + 1] = timer
                end
            end
        end
    end
    return s
end

for _, profile in ipairs({ "retail", "forever" }) do
    local s = fixture(profile)
    local positions, coordinates, values, slices = s.positionReads, s.coordinateReads, s.valueReads, s.job.slices
    for _ = 1, 120 do
        s:frame(1 / 60)
    end
    local observedPositions, observedCoordinates, observedValues =
        s.positionReads - positions, s.coordinateReads - coordinates, s.valueReads - values
    assert(s.job.slices - slices == 120, "Normal 60 FPS planning still advances every frame")
    assert(
        observedPositions <= 120 and observedCoordinates <= 120,
        string.format(
            "120 pending frames must not repeat observations: %d positions, %d objectives",
            observedPositions,
            observedCoordinates
        )
    )
    assert(
        observedValues <= 4000,
        "Repeated authored/resolved coordinates must share one validation: " .. observedValues
    )
    print(
        string.format(
            "Controller %s / 120 pending slices: %d position reads, %d objective resolutions, %d value checks",
            profile,
            observedPositions,
            observedCoordinates,
            observedValues
        )
    )
    s.nav:Cancel("test_end")

    s = fixture(profile)
    slices = s.job.slices
    for _ = 1, 400 do
        s:frame(1 / 400)
    end
    assert(
        s.job.slices - slices >= 50 and s.job.slices - slices <= 100,
        "High FPS must not multiply background work; planning still makes steady progress"
    )
    assert(#s.timers == 1, "Only one continuation timer may remain pending")
    s.nav:Cancel("test_end")

    -- Mutable observations and unavailable data must still be noticed before
    -- the very next slice, despite the lower observation count.
    for _, change in ipairs({ "player", "objective", "override", "missing", "geometry", "secret" }) do
        s = fixture(profile)
        slices = s.job.slices
        if change == "player" then
            s.position.floor = 2
        elseif change == "objective" then
            s.step.Coord.y = 4000
        elseif change == "override" then
            s.override = { x = 2, y = 5, instanceID = 1 }
        elseif change == "missing" then
            s.missingPosition = true
        elseif change == "geometry" then
            APR.navigationGeometryRevision = 1
        else
            s.opaque = setmetatable({}, { __eq = function() error("Opaque comparison") end })
            s.step.Coord.floor = s.opaque
        end
        s.nav._searchTimer.callback()
        assert(
            s.job.cancelled and s.job.slices == slices and not s.nav.search and s.nav._stepCheckTimer,
            "Changed " .. change .. " retires the old candidate before advancing it"
        )
        s.nav:Cancel("test_end")
    end

    -- Sharing a snapshot is only valid when both live sources are identical.
    s = fixture(profile)
    s.override = { x = 0, y = 3000, instanceID = 1 }
    s.nav:ForceRefresh()
    s.nav:Update()
    local inputs = s.nav._routeInputs
    s.step.Coord.floor = 3
    assert(not s.nav:IsObjectiveCurrent(inputs), "A distinct authored coordinate is still validated")
    s.step.Coord.floor, s.override.floor = nil, 4
    assert(not s.nav:IsObjectiveCurrent(inputs), "A distinct resolved coordinate is still validated")
    s.nav:Cancel("test_end")

    for _, state in ipairs({ "ready", "no_path" }) do
        for _, boundary in ipairs({ "provider", "telemetry" }) do
            s = fixture(profile)
            s.resultState, s.result = state, { queue = {} }
            local function mutate() s.step.Coord.y = 4500 end
            if boundary == "provider" then
                s.onStep = mutate
            else
                APR.RecordPerformanceDuration = mutate
            end
            s.nav._searchTimer.callback()
            assert(
                s.job.cancelled and not s.nav.search and s.nav.state == "planning" and s.nav._stepCheckTimer,
                "A " .. state .. " result changed by " .. boundary .. " must replan before publication"
            )
            assert(APRData[APR.PlayerID][APR.ActiveRoute] == 1, "Cancellation cannot advance authored progress")
            s.nav:Cancel("test_end")
        end
    end

    s = fixture(profile)
    s.onStep = function() s.step.Coord.y = 4600 end
    s.nav._searchTimer.callback()
    slices = s.job.slices
    assert(not s.nav:IsNavigating(), "Unfinished work cannot publish a changed objective")
    s.nav._searchTimer.callback()
    assert(
        s.job.cancelled and s.job.slices == slices and s.nav._stepCheckTimer,
        "A mutation during unfinished work is rejected before the next slice"
    )
    s.nav:Cancel("test_end")

    s = fixture(profile)
    local oldTimer = s.nav._searchTimer
    s.onStep = function()
        s.onStep = nil
        s.nav:ForceRefresh()
        s.nav:Update()
    end
    oldTimer.callback()
    local replacement = s.nav.search
    assert(s.job.cancelled and replacement and replacement ~= s.job)
    local pending = s.nav._searchTimer
    oldTimer.callback()
    assert(
        s.nav.search == replacement and s.nav._searchTimer == pending,
        "A reentrant replacement keeps its timer and is immune to old callbacks"
    )
    s.nav:Cancel("test_end")

    s = fixture(profile)
    s.resultState = "ready"
    s.result = {
        queue = {
            {
                kind = "portal",
                from = s.position,
                to = { x = 3000, y = 0, instanceID = 1, uiMapID = 102 },
                seconds = 3,
            },
        },
        totalSeconds = 3,
    }
    s.nav._searchTimer.callback()
    assert(
        s.nav:IsNavigating() and not s.nav.search and s.nav.totalSeconds == 3,
        "An unchanged completed job still publishes its usable itinerary"
    )
    s.nav:Cancel("test_end")
end
print(
    "Controller overhead: bounded observations, high-FPS scheduling, live mutations, reentrancy and publication passed"
)
