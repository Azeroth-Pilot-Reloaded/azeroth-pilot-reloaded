-- First usable guide is a frame/paint contract, independent of history work.
-- Reuse the real joined quest UI/engine fixture; only native boundaries and the
-- scheduler below are controlled. No shipped route is a regression fixture.
local FRAME_MS, DEADLINE_MS = 1000 / 60, 100
local function noop() end
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = copy(entry) end
    return result
end

local function fixture(saved)
    -- A reload can observe the native login phase before this addon loads.
    function IsLoggedIn() return saved ~= nil end
    -- Capture the real ADDON_LOADED receiver without replacing its callback or
    -- duplicating the Event implementation inside this test.
    local load, eventFrames = dofile, {}
    dofile = function(path)
        if path ~= "APR-Core/core/Event.lua" then return load(path) end
        local create = CreateFrame
        CreateFrame = function(...)
            local frame = create(...)
            eventFrames[#eventFrames + 1] = frame
            return frame
        end
        local ok, result = pcall(load, path)
        CreateFrame = create
        if not ok then error(result, 0) end
        return result
    end
    local ok, env = pcall(load, "tests/lua/addon_journey_quest_env.lua")
    dofile = load
    if not ok then error(env, 0) end
    local state = H
    state.frameNumber, state.wallMs, state.clock, state.bytes = 0, 0, 0, 0
    state.timers, state.paints, state.candidate, state.maximumFrameCpu = {}, {}, nil, 0

    -- Native LuaBitOp boundary, including its double-number normalization.
    -- Charge hash bytes, not timing reads, so reducing CPU slices cannot hide
    -- the number of rendered frames spent waiting for a large inactive guide.
    local function normalized(value)
        local fraction = math.frexp(math.abs(value + 6755399441055744))
        return (fraction * 9007199254740992) % 4294967296
    end
    local function signed(value)
        return value >= 2147483648 and value - 4294967296 or value
    end
    bit = {
        bxor = function(left, right)
            left, right = normalized(left), normalized(right)
            local result, place = 0, 1
            while right > 0 do
                if left % 2 ~= right % 2 then result = result + place end
                left, right, place = math.floor(left / 2), math.floor(right / 2), place * 2
            end
            return signed(result + left * place)
        end,
        band = function(value, mask)
            assert(mask == 4294967295, "This fixture models the route hash's native mask")
            state.bytes, state.clock = state.bytes + 1, state.clock + 0.01
            return signed(normalized(value))
        end,
    }

    local function schedule(delay, callback)
        local timer = { callback = callback, due = state.wallMs + delay * 1000,
            earliestFrame = state.frameNumber + 1, Cancel = function(self) self.cancelled = true end }
        state.timers[#state.timers + 1] = timer
        return timer
    end
    C_Timer.NewTimer, C_Timer.After = schedule, schedule
    function GetTime() return state.wallMs / 1000 end
    function debugprofilestop() return state.clock end

    APR.version = "synthetic-current"
    APR.settings.profile.lastRecordedVersion = saved and saved.version or "synthetic-previous"
    APR.RouteQuestStepList = {
        small = { label = "First invented guide", mapID = 10, expansion = APR.EXPANSIONS.Custom,
            steps = { { Note = "Previously visited" }, { PickUp = { 8101 }, Zone = 10 }, { Note = "Next" } } },
        alternate = { label = "Second invented guide", mapID = 10, expansion = APR.EXPANSIONS.Custom,
            steps = { { Note = "Previously visited" }, { PickUp = { 8102 }, Zone = 10 }, { Note = "Next" } } },
        history = { label = "Inactive invented history", mapID = 10,
            steps = { { Note = string.rep("x", 184320) } } },
    }
    if saved then
        APRData, APRCustomPath, APRZoneCompleted = copy(saved.data), copy(saved.path), copy(saved.completed)
    else
        APRData.player.small, APRData.player.alternate, APRData.player.history = 2, 2, 1
        APRData.player["small-RawTotalSteps"], APRData.player["alternate-RawTotalSteps"] = 3, 3
        APRData.player["history-RawTotalSteps"] = 1
        APRData.player.RouteSignatures = { history = "incompatible-synthetic-history" }
        APRCustomPath.player = { "First invented guide" }
    end
    APR.ActiveRoute = nil
    -- These are unrelated native/UI services, not route/validation substitutes.
    APR.heirloom.RefreshFrameAnchor, APR.coordinate.RefreshFrameAnchor = noop, noop
    APR.ScheduleDelveRouteRefresh = noop
    function APR:WrapTextWithAppearanceColor(value) return tostring(value) end

    local function useful(route, questID)
        local row = APR.currentStep.questsList.PickUp
        if not row or row.stale or row.hiddenInCombat or row.font:GetText() ~= "Pick up"
            or not row.detailFonts or not row.detailFonts[1]
            or not row.detailFonts[1]:GetText():find("Quest " .. questID, 1, true) then return false end
        local parent = row
        while parent do
            if not parent:IsShown() then return false end
            parent = parent:GetParent()
        end
        local context = APR.lastRenderedStepContext
        return context and context.route == route and context.index == 2
            and context.definition == APR.RouteQuestStepList[route]
            and APRData.player[route] == 2 and APR:IsStepContextCurrent(context)
    end
    local finish = APR.currentStep.EndContentUpdate
    function APR.currentStep:EndContentUpdate(success)
        finish(self, success)
        if success then
            state.candidate = { frame = state.frameNumber, context = APR:CaptureStepContext() }
        end
    end
    function state:Frame()
        self.frameNumber = self.frameNumber + 1
        self.wallMs = self.wallMs + FRAME_MS
        local before, pending = self.clock, self.timers
        self.timers = {}
        for _, timer in ipairs(pending) do
            if not timer.cancelled then
                if timer.earliestFrame <= self.frameNumber and timer.due <= self.wallMs + 0.000001 then
                    timer.callback()
                else self.timers[#self.timers + 1] = timer end
            end
        end
        local cpu = self.clock - before
        self.maximumFrameCpu = math.max(self.maximumFrameCpu, cpu)
        assert(cpu <= 8, "A usable guide cannot be obtained by blocking one startup frame on the whole history")
        assert(#self.errors == 0, table.concat(self.errors, "\n"))
        -- A commit during this frame is first credited at the NEXT paint. A
        -- current token alone or a calculating/navigation row is insufficient.
        local candidate = self.candidate
        if candidate and candidate.frame < self.frameNumber and APR:IsStepContextCurrent(candidate.context) then
            for route, questID in pairs({ small = 8101, alternate = 8102 }) do
                if not self.paints[route] and useful(route, questID) then self.paints[route] = self.wallMs end
            end
        end
    end
    function state:AwaitUseful(route, started)
        for _ = 1, 6 do
            if self.paints[route] then break end
            self:Frame()
        end
        local painted = self.paints[route]
        assert(painted and painted - started <= DEADLINE_MS + 0.000001,
            string.format("The correct playable %s guide must paint within 100 ms, not wait for historical routes (elapsed %.2f ms)",
                route, self.wallMs - started))
        assert(not APR.routeValidationPending and not APR.routeValidationFailed,
            "A painted guide must also release foreground actions")
        assert(not APR.startupQuestStatePending,
            "The real native login snapshot must be observed before declaring startup gameplay ready")
        assert(useful(route, route == "small" and 8101 or 8102), "The painted objective must retain its expected progress/token")
        return painted - started
    end
    for _, frame in ipairs(eventFrames) do
        if frame.events and frame.events.ADDON_LOADED then state.loginFrame = frame end
    end
    assert(state.loginFrame, "The fixture must execute the real addon startup event")
    return state
end

local savedForReload
for _, mode in ipairs({ "login", "reload" }) do
    local state = fixture(mode == "reload" and savedForReload or nil)
    state.loginFrame.scripts.OnEvent(state.loginFrame, "ADDON_LOADED", "APR")
    if mode == "login" then
        C_Timer.NewTimer(0, function() state.loginFrame.scripts.OnEvent(state.loginFrame, "PLAYER_LOGIN") end)
    end
    local firstMs = state:AwaitUseful("small", 0)
    assert(APR.event.routeMaintenanceJob and APRData.player.history == 1,
        "Large inactive history must still be in the background when the guide becomes usable")
    if mode == "login" then
        savedForReload = { data = copy(APRData), path = copy(APRCustomPath), completed = copy(APRZoneCompleted),
            version = APR.settings.profile.lastRecordedVersion }
        assert(savedForReload.version == "synthetic-previous", "Foreground readiness must not certify the entire history")
    end

    local current = APR:CaptureStepContext()
    assert(APR:AdvanceStep(false, current) and APRData.player.small == 3,
        "A ready guide must accept a real progression action while history is still running")
    local switchedAt = state.wallMs
    APRCustomPath.player = { "Second invented guide" }
    assert(APR:ActivateRoute("alternate", "manual"))
    assert(not APR:TransitionStep(3, "automatic", false, APR:CaptureStepContext()) and APRData.player.alternate == 2,
        "The newly selected guide's actions must wait for its own validation")
    APR:UpdateQuestAndStep()
    local switchMs = state:AwaitUseful("alternate", switchedAt)
    assert(APR.event.routeMaintenanceJob, "Selecting a small guide must not wait for the inactive history")
    current = APR:CaptureStepContext()
    assert(APR:AdvanceStep(false, current) and APRData.player.alternate == 3)

    local frames = 0
    while APR.event.routeMaintenanceJob or #state.timers > 0 do
        state:Frame()
        frames = frames + 1
        assert(frames < 2000, "Background maintenance and cancelled startup callbacks must eventually settle")
    end
    assert(APR.ActiveRoute == "alternate" and APRData.player.small == 3 and APRData.player.alternate == 3,
        "Background validation must not reset either validated guide's live progression")
    assert(APRData.player.history == nil,
        "Deferring history must still eventually repair its independently incompatible saved progress")
    assert(not APR.routeValidationPending and not APR.routeValidationFailed)
    print(string.format("Startup %s at 60 FPS: useful guide %.2f ms, manual selection %.2f ms; background %.2f ms, largest CPU frame %.2f ms",
        mode, firstMs, switchMs, state.wallMs, state.maximumFrameCpu))
end
