-- No work is scheduled simply because APR or a client namespace is available.
for _, profile in ipairs({ "retail", "forever" }) do
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    fixture.profile = profile
    local frames, timers = {}, {}
    local create = CreateFrame
    function CreateFrame(...)
        local frame = create(...)
        frames[#frames + 1] = frame
        return frame
    end
    C_Timer = {}
    local function timer(delay, callback, repeating)
        local value = { delay = delay, callback = callback, repeating = repeating, at = fixture.time + delay }
        function value:Cancel() self.cancelled = true end
        timers[#timers + 1] = value
        return value
    end
    function C_Timer.NewTimer(delay, callback) return timer(delay, callback, false) end
    function C_Timer.NewTicker(delay, callback) return timer(delay, callback, true) end
    local data = fixture:Load({})
    APR.settings, APR.PlayerID = { profile = { enableAddon = true } }, "synthetic"
    APRData = { synthetic = {} }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    local reads, objectives, requests, work = 0, 0, 0, 0
    function UnitPosition() reads = reads + 1; return 0, 0, 0, 0 end
    function UnitIsDeadOrGhost() return false end
    function APR:GetCurrentStep() objectives = objectives + 1; return nil end
    local getTarget = data.env.getWaypointTarget
    data.env.getWaypointTarget = function(...) requests = requests + 1; return getTarget(...) end
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav, frame = APR.navigation, frames[#frames]
    dofile("APR-Core/features/navigation/NavigationTaxi.lua")
    local taxi, flightFrame = APR.taxiData, frames[#frames]
    nav:RefreshActivity()
    APR.NavigationAdapter:RefreshWaypoints()
    reads, objectives, requests = 0, 0, 0
    for _ = 1, 120 * 165 do
        fixture.time = fixture.time + 1 / 165
        for _, worker in ipairs(frames) do
            if worker.OnUpdate then work = work + 1; worker.OnUpdate(worker, 1 / 165) end
        end
        for _, pending in ipairs(timers) do
            if not pending.cancelled and pending.at <= fixture.time then
                work = work + 1
                if pending.repeating then pending.at = fixture.time + pending.delay else pending.cancelled = true end
                pending.callback()
            end
        end
    end
    assert(work == 0 and reads == 0 and objectives == 0 and requests == 0,
        profile .. ": 120 seconds at 165 FPS must cause zero idle work or objective/position reads")
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED", "SPELL_UPDATE_COOLDOWN" }) do
        frame.OnEvent(frame, event)
        APR.NavigationAdapter.frame.OnEvent(APR.NavigationAdapter.frame, event)
    end
    assert(reads == 0 and objectives == 0 and requests == 0 and frame.OnUpdate == nil,
        "Unrelated native events cannot wake navigation without an objective")

    APR.ActiveRoute, nav.state, nav.queue = "synthetic-route", "guiding", { { kind = "walk" } }
    local arrivals = 0
    function nav:PollArrival() arrivals = arrivals + 1 end
    nav:RefreshActivity()
    local old = assert(frame.OnUpdate, "An actual itinerary installs its arrival observer")
    old(frame, 0.5)
    assert(arrivals == 1)
    APR.ActiveRoute, nav.state, nav.queue = nil, "ready", {}
    nav:RefreshActivity()
    assert(frame.OnUpdate == nil)
    old(frame, 0.5)
    assert(arrivals == 1, "Retired callbacks cannot continue arrival work")
    if profile == "forever" then
        local originChecks, fullChecks = 0, 0
        APR.Services = {request = {waitingForOrigin = true, profile = profile}}
        function APR.Services:GetStep() end
        function APR.Services:Validate(originOnly)
            if originOnly then originChecks = originChecks + 1 else fullChecks = fullChecks + 1 end
        end
        nav:RefreshActivity()
        frame.OnUpdate(frame, 0.04)
        assert(originChecks == 0)
        frame.OnUpdate(frame, 0.02)
        assert(originChecks == 1 and fullChecks == 0 and arrivals == 1)
        frame.OnUpdate(frame, 0.45)
        assert(originChecks == 1 and fullChecks == 1, "The ordinary poll includes the origin check only once")
        nav:InvalidatePathCache()
        nav:InvalidatePathCache("QUEST_LOG_UPDATE")
        assert(not APR.Services.request.invalidated, "Routine refreshes leave a pending service search running")
        frame.OnEvent(frame, "QUEST_TURNED_IN")
        assert(APR.Services.request.invalidated, "An access change retires a service ranking even without a guide")
        APR.Services.request = nil
        nav:RefreshActivity()
        assert(frame.OnUpdate == nil, "Clearing the pending request also stops the fast observation")
    end

    -- A real measurement can be completed without a guide route.
    taxi.measurement = { playerID = APR.PlayerID, snapshot = taxi:GetSnapshotKey(), started = fixture.time - 3 }
    taxi:RefreshMeasurementActivity()
    assert(flightFrame.OnUpdate)
    flightFrame.OnUpdate(flightFrame, 0.2)
    assert(taxi.measurement == nil and flightFrame.OnUpdate == nil,
        "Completed standalone flight measurements detach their worker")
end
print("Idle navigation: both clients, 120 seconds / 165 FPS, unrelated events, active arrivals and standalone flight cleanup passed")
