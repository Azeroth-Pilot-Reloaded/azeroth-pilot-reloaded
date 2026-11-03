-- One synthetic operation costs 0.25 ms. Cold planning can spend 3 ms;
-- an established direct baseline or itinerary retains its 1 ms background cap.
local function fixture(mode, clockAvailable)
    local t = { now = 0, timers = {}, publications = 0, current = true }
    local noop = function() end
    local start = { x = 0, y = 0, instanceID = 7, uiMapID = 501 }
    local goal = { x = 10000, y = 0, instanceID = 7, uiMapID = 501 }
    local step = { Zone = 501, Coord = { x = 0, y = 10000 }, Waypoint = 1 }
    local context = { route = "invented-budget", index = 1, revision = 1, definition = { steps = { step } } }
    function GetTime() return 10 end
    function UnitIsDeadOrGhost() return false end
    function IsIndoors() return false end
    function IsFlying() return false end
    function InCombatLockdown() return false end
    function GetMoney() return 0 end
    debugprofilestop = clockAvailable and function() return t.now end or nil
    function LibStub() return { GetLocale = function() return {} end } end
    function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
    C_PlayerInfo = nil
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        t.timers[#t.timers + 1] = timer
        return timer
    end }
    APR = { PlayerID = "invented-player", ActiveRoute = context.route, NewModule = function() return {} end,
        settings = { profile = { enableAddon = true } }, GAME_VERSIONS = { Forever = "forever" },
        Arrow = { SetArrowActive = noop }, NavigationEngine = {}, NavigationAdapter = {}, taxiData = {} }
    APRData = { [APR.PlayerID] = { [context.route] = 1 } }
    function APR:CaptureStepContext() return context end
    function APR:IsStepContextCurrent(value) return t.current and value == context end
    function APR:GetCurrentStep() return step end
    function APR:GetNavigationPlayerPosition() return start end
    function APR:CheckNavigationZoneReady() return mode == "direct" or mode == "seed" end
    APR.NavigationData = { profile = "forever", CanWalk = function() return true end,
        RequiresTerrainRoute = function() return false end, HasTerrainData = function() return false end,
        HasRoadData = function() return false end }
    APR.NavigationPlanner = { Create = function()
        local worker = { phase = "nodes", status = "planning", completed = 0, total = 24 }
        local job = { phase = "terrain", status = "planning", active = worker, budgets = {}, operations = {}, slices = 0 }
        function job:Step(operations, milliseconds)
            self.budgets[#self.budgets + 1], self.operations[#self.operations + 1] = milliseconds, operations
            local began, count = t.now, 0
            for _ = 1, operations do
                if t.now + 0.25 > began + milliseconds or worker.completed == worker.total then break end
                count, worker.completed, t.now = count + 1, worker.completed + 1, t.now + 0.25
                if worker.completed >= 8 then self.phase, worker.phase = "search", "expand" end
            end
            worker.workLastStep = count
            self.slices = self.slices + 1
            self.lastSliceMilliseconds = t.now - began
            assert(self.lastSliceMilliseconds <= milliseconds,
                "Foreground and background workers obey their selected time allowance")
            if worker.completed == worker.total then
                self.status, worker.status = "ready", "ready"
                return "ready", { queue = {} }
            end
            return "planning"
        end
        function job:Cancel() self.status = "cancelled" end
        t.job = job
        return job
    end }
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    nav.Notify, nav.Render, nav.ClearNavigationUiLines = noop, noop, noop
    nav.TryResumeAfterTransition = function() return false end
    nav.GuideHousingExit = function() return false end
    nav.GetDestination = function() return goal, goal.uiMapID end
    nav.GetThreshold = function() return 2000 end
    nav.GetMovementSpeed = function() return 7 end
    nav.IsItineraryValid = function() return mode == "path" end
    nav.IsDirectRouteValid = function() return mode == "direct" end
    nav.CapturePlanningInputs = function() return {} end
    nav.HasPlanningInputsChanged = function() return false end
    nav.CaptureRetainedArrow = function()
        if mode == "hint" then return { instanceID = 7, Coord = { x = 0, y = 10000 } } end
    end
    nav.Publish = function(self)
        t.publications = t.publications + 1
        self.search = nil
    end
    if mode == "direct" then nav.destination = goal end
    if mode == "path" then
        nav.queue, nav.cursor, nav.state = { { kind = "walk", Coord = step.Coord } }, 1, "guiding"
    end
    t.nav, t.context = nav, context
    nav:Update(context)
    return t
end

for _, case in ipairs({ { "cold", 3, 2 }, { "hint", 3, 2 }, { "direct", 1, 6 },
    { "path", 1, 6 }, { "seed", 1, 6 } }) do
    local t = fixture(case[1], true)
    assert(t.job.budgets[1] == case[2], "Choose the allowance from established guidance, not a retained arrow hint")
    if case[1] == "hint" then assert(t.nav.retainedArrow and t.nav.state == "planning") end
    local index = 1
    while t.nav.search do
        local timer = assert(t.timers[index], "An unfinished phase must schedule its next frame")
        assert(not timer.cancelled)
        timer.callback(); index = index + 1
        assert(index <= 10)
    end
    assert(#t.job.budgets == case[3] and t.publications == 1,
        "Foreground work finishes sooner without changing the amount or outcome of work")
    assert(t.nav.lastPlanning.workerPhase == "expand" and t.nav.lastPlanning.workerCompleted == 24,
        "Worker progress survives phase transitions and publication")
    for _, value in ipairs(t.job.budgets) do assert(value == case[2]) end
    for _, operations in ipairs(t.job.operations) do assert(operations == 4096) end
end

for _, mode in ipairs({ "cold", "direct", "path", "hint" }) do
    local t = fixture(mode, true)
    local stale, calls = t.timers[#t.timers], #t.job.budgets
    t.nav:Cancel("cleared")
    assert(t.job.status == "cancelled" and stale.cancelled)
    stale.callback()
    assert(#t.job.budgets == calls and t.publications == 0,
        "A cancelled foreground or background slice cannot resume or publish")
end
local fallback = fixture("cold", false)
assert(fallback.job.operations[1] == 64, "Clients without the profiling clock retain the operation cap")
fallback.nav:Cancel("cleared")
print("Navigation budgets: bounded foreground/background work, direct/path baselines, retained hints, phases, fallback and cancellation passed")
