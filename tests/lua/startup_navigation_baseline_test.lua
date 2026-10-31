-- Cold direct guidance must not wait for the optimal transport catalogue.
-- All maps, routes, actions and coordinates below are invented. The real
-- geography provider, planner, search and controller run on a 60 FPS scheduler.
local FRAME_MS = 1000 / 60
local noop = function() end
local function point(world, map, x)
    return { space = "world", instanceID = world, uiMapID = map, x = x, y = 50 }
end

local function fixture(profile, options)
    options = options or {}
    local f = dofile("tests/lua/navigation_fixture.lua")
    f.profile, f.currentMap = profile, 51003
    f.player = point(7, 51003, 100)
    f.maps = {
        [51000] = { mapID = 51000, parentMapID = 0, mapType = 0 },
        [51001] = { mapID = 51001, parentMapID = 51000, mapType = 2 },
        [51002] = { mapID = 51002, parentMapID = 51001, mapType = 3 },
        [51003] = { mapID = 51003, parentMapID = 51002, mapType = 3 },
        [51004] = { mapID = 51004, parentMapID = 51001, mapType = 3 },
        [51005] = { mapID = 51005, parentMapID = 51000, mapType = 2 },
        [51006] = { mapID = 51006, parentMapID = 51005, mapType = 3 },
    }
    f.translations = setmetatable({}, { __index = function(_, key) return key end })
    local s = { timers = {}, frame = 0, wall = 0, cpu = 0, catalogueSlices = 0,
        catalogueOperations = 0, maxOperations = 0, refreshes = 0, paints = {}, allowed = true }
    function GetTime() return s.wall / 1000 + 1 end
    function debugprofilestop() s.cpu = s.cpu + 0.002; return s.cpu end
    function UnitIsDeadOrGhost() return s.dead end
    function IsFlyableArea() return false end
    function IsFlying() return false end
    function IsMounted() return false end
    function GetUnitSpeed() return 0, 10, 0 end
    function GetMoney() return 100 end
    function GetBindLocation() return nil end
    C_QuestLog.IsQuestFlaggedCompleted = function() return s.allowed end
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { callback = callback,
            due = math.max(s.frame + 1, math.ceil((s.wall + delay * 1000) / FRAME_MS - 0.000001)),
            Cancel = function(self) self.cancelled = true end }
        s.timers[#s.timers + 1] = timer
        return timer
    end }
    local catalogue = { config = { IsolatedAreas = {} }, connections = {} }
    if options.phase then catalogue.config.MapRequirements = { [51002] = { quest = 880002 } } end
    -- Hundreds of irrelevant declarations make catalogue completion take many
    -- frames; no test depends on the shipped inventory or an actual journey.
    for i = 1, 480 do
        catalogue.connections[i] = { id = "closed-" .. i, kind = "portal", seconds = 10,
            from = point(7, 51004, i), to = point(8, 51006, i), requirements = { level = 1000 } }
    end
    if options.shortcut then
        f.spells[880001] = true
        catalogue.connections[#catalogue.connections + 1] = { id = "personal-shortcut", kind = "spell",
            seconds = 2, from = { dynamic = "player" }, to = point(7, 51002, 1350),
            actions = { { type = "spell", id = 880001 } } }
    end
    local data = f:Load(catalogue)
    data.env.getActionCastSeconds = function() return 2 end
    dofile("APR-Core/utils/Utils.lua")
    APR.Debug = noop
    dofile("APR-Core/utils/NavigationZones.lua")
    local step = { Zone = 51002, Coord = { x = 50, y = 1350, instanceID = 7 }, PickUp = { 880003 } }
    local route = { steps = { {}, step, {} } }
    APR.PlayerID, APR.ActiveRoute = "invented-player", "invented-baseline"
    APR.RouteQuestStepList = { [APR.ActiveRoute] = route }
    APR.settings, APR.GAME_VERSIONS = { profile = { enableAddon = true } }, { Forever = "forever" }
    APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 2 } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep()
        local index = APRData[self.PlayerID][self.ActiveRoute]
        local steps = self.RouteQuestStepList[self.ActiveRoute].steps
        return steps[index], index, steps
    end
    function APR:PeekCurrentStep() return self:GetCurrentStep() end
    function APR:GetCurrentRouteMapIDsAndName() return { 51004 }, 51004 end
    function APR:GetStepCoord(value) return value.Coord, value.Zone end
    function APR:GetPreferredStepZone(value) return value.Zone end
    function APR:GetNavigationPlayerPosition()
        if s.missingPosition then return nil end
        local p = {}; for key, value in pairs(f.player) do p[key] = value end
        if s.missingMap then p.uiMapID = nil else p.uiMapID = f.currentMap end
        return p
    end
    local function recordUsefulCommit()
        local nav, rendered = APR.navigation, s.rendered
        if rendered and nav.state == "ready" and APR.IsInRouteZone and APR.Arrow.Active
            and APR:IsStepContextCurrent(rendered) and APR:IsStepContextCurrent(nav.context)
            and nav:IsObjectiveCurrent(nav._routeInputs) then
            s.commit = { frame = s.frame, wall = s.wall, context = rendered,
                x = APR.Arrow.x, y = APR.Arrow.y }
            s.firstCommit = s.firstCommit or s.commit
        end
    end
    function APR:UpdateStep()
        s.refreshes = s.refreshes + 1
        -- The renderer already permits the authored PickUp row during planning.
        -- A useful commit requires that row AND the proven arrow for its token.
        s.rendered = self:CaptureStepContext()
        recordUsefulCommit()
    end
    APR.Arrow = { SetArrowActive = function(self, active) self.Active = active end,
        SetCoord = function(self)
            local nav = APR.navigation
            local guidance = nav:GetActiveStep()
            local coord = guidance and guidance.Coord or (APR.IsInRouteZone and select(1, APR:GetCurrentStep()).Coord)
            self.Active = coord ~= nil
            if coord then self.x, self.y = coord.x, coord.y end
            recordUsefulCommit()
        end }
    APR.event = { QueueStepRefresh = function()
        if s.refreshTimer then return end
        -- Match Event's existing debounce; usefulness must not depend on it.
        s.refreshTimer = C_Timer.NewTimer(0.1, function()
            s.refreshTimer = nil
            APR:UpdateStep()
        end)
    end }
    APR.SendMessage = noop
    APR.currentStep = { AddQuestSteps = noop, AddQuestDivider = noop, AddStepButton = noop }
    APR.taxiData = { BuildEdges = function() return {}, {} end }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    dofile("APR-Core/features/navigation/Navigation.lua")
    APR:UpdateStep()
    -- Bound synthetic catalogue work explicitly. Each real declaration costs
    -- 0.15 simulated CPU ms. Wall time advances only on frames, never on clock
    -- reads; a timer zero queued inside another timer cannot run in that frame.
    local create = data.CreateEdgeBuild
    function data:CreateEdgeBuild(context)
        local build = create(self, context)
        local advance = build.Step
        function build:Step(operations, milliseconds)
            local before = self.index
            local status, result, metadata = advance(self, math.min(2, operations), milliseconds)
            local work = self.index - before
            s.catalogueSlices = s.catalogueSlices + 1
            s.catalogueOperations = s.catalogueOperations + work
            s.maxOperations = math.max(s.maxOperations, work)
            s.cpu = s.cpu + work * 0.15
            return status, result, metadata
        end
        return build
    end
    s.nav, s.data, s.step, s.f = APR.navigation, data, step, f
    function s:frameOnce()
        self.frame = self.frame + 1
        self.wall = self.frame * FRAME_MS
        -- Paint commits from the preceding frame, before this frame's timers.
        local commit = self.commit
        if commit and commit.frame < self.frame and APR:IsStepContextCurrent(commit.context) then
            self.paints[#self.paints + 1] = { wall = self.wall, frame = self.frame, commit = commit }
            self.firstPaint = self.firstPaint or self.paints[#self.paints]
        end
        local pending = self.timers
        self.timers = {}
        for _, timer in ipairs(pending) do
            if not timer.cancelled then
                if timer.due <= self.frame then timer.callback()
                else self.timers[#self.timers + 1] = timer end
            end
        end
    end
    function s:frames(count) for _ = 1, count do self:frameOnce() end end
    function s:settle()
        local limit = self.frame + 2000
        while self.nav.search or self.nav._stepCheckTimer or self.refreshTimer do
            assert(self.frame < limit, "The synthetic search must finish")
            self:frameOnce()
        end
    end
    return s
end

for _, profile in ipairs({ "retail", "forever" }) do
    local t = fixture(profile)
    local nativeStarted = os.clock()
    t.nav:Update()
    local nativeCPU = (os.clock() - nativeStarted) * 1000
    assert(t.nav.state == "ready" and t.nav.recomputeKeepingDirect and t.nav.search,
        "Cold provider-proven direct guidance must be usable while optimal planning continues")
    assert(t.nav.zoneReady == true and APR.IsInRouteZone == true and t.nav.destination.uiMapID == 51002,
        "The authored step zone takes priority over the unrelated route map")
    assert(t.nav.search.request.preferZoneAccess == false and t.nav.search.phase ~= "zone",
        "Ordinary objectives must still compare all transports")
    assert(t.catalogueOperations == 0, "Publishing the cold baseline cannot scan the catalogue")
    local initialCPU = t.cpu
    t:frames(2)
    assert(t.firstCommit and t.firstCommit.frame == 0 and t.firstPaint.frame == 1,
        "The direct arrow completes the existing authored row synchronously, painting next frame")
    assert(t.firstPaint.wall < 100 and t.firstPaint.commit.context.route == "invented-baseline"
        and t.firstPaint.commit.context.index == 2 and t.firstPaint.commit.x == 50 and t.firstPaint.commit.y == 1350,
        "Latency is measured for useful guidance belonging to the correct route/index token")
    assert(t.nav.search and t.catalogueOperations < 480,
        "Useful paint must precede completion of the deliberately long catalogue")
    local old = t.nav.search
    t.nav:ForceRefresh(); t.nav:Update()
    assert(t.nav.state == "ready" and t.nav.recomputeKeepingDirect and old.status == "cancelled",
        "A refresh retains the direct baseline and cancels its obsolete candidate")
    t:frames(4) -- Retire the normal debounced row refresh before comparing UI work.
    local refreshes = t.refreshes
    t:settle()
    assert(t.nav.state == "ready" and not t.nav.search and not t.nav.recomputeKeepingDirect
        and t.refreshes == refreshes and APRData[APR.PlayerID][APR.ActiveRoute] == 2,
        "The optimal direct confirmation is silent and never advances authored progress")
    assert(t.catalogueSlices >= 240 and t.maxOperations <= 2,
        "The real catalogue runs incrementally instead of moving its work into startup")
    print(string.format("Cold baseline %s: commit frame %d / %.2f ms, paint frame %d / %.2f ms; " ..
        "initial simulated CPU %.3f ms, native CPU %.3f ms, catalogue %d slices / %d operations (max %d per slice)",
        profile, t.firstCommit.frame, t.firstCommit.wall, t.firstPaint.frame, t.firstPaint.wall,
        initialCPU, nativeCPU, t.catalogueSlices, t.catalogueOperations, t.maxOperations))

    t = fixture(profile, { shortcut = true })
    t.nav:RequestUpdate()
    t:frames(5)
    assert(t.firstPaint and t.firstPaint.wall < 100 and t.nav.state == "ready" and t.nav.search,
        "The existing deferred navigation request also publishes a useful baseline within 100 ms")
    assert(t.firstCommit.frame == 3 and t.firstPaint.frame == 4,
        "The existing 50 ms request commits at frame 3 and paints at frame 4")
    print(string.format("Deferred baseline %s: commit frame %d / %.2f ms, paint frame %d / %.2f ms",
        profile, t.firstCommit.frame, t.firstCommit.wall, t.firstPaint.frame, t.firstPaint.wall))
    t:settle()
    assert(t.nav:IsNavigating() and t.nav:GetActiveStep().kind == "spell"
        and t.nav:GetActiveStep().action.data == 880001 and t.nav.totalSeconds < 10,
        "A faster personal transport discovered later replaces cold direct guidance")

    -- Normal waiting behavior remains until actual coordinates/map data exist.
    for _, missing in ipairs({ "missingPosition", "missingMap", "missingGoal" }) do
        t = fixture(profile)
        if missing == "missingGoal" then t.step.Coord, t.step.Zone = nil, 51006 else t[missing] = true end
        t.nav:Update(); t:frames(2)
        assert(t.nav.state == "waiting_data" and not t.firstCommit and not t.nav.recomputeKeepingDirect,
            "Missing observations cannot publish a fabricated direct baseline: " .. missing)
        if missing == "missingGoal" then t.step.Coord, t.step.Zone = { x = 50, y = 1350, instanceID = 7 }, 51002
        else t[missing] = false end
        local readyFrame = t.frame
        t.nav:ForceRefresh(); t.nav:Update(); t:frames(2)
        assert(t.nav.state == "ready" and t.firstCommit.frame == readyFrame
            and t.firstPaint.frame == readyFrame + 1 and t.nav.search,
            "Late observations permit a freshly proven baseline before catalogue completion")
        t.nav:Cancel("test_end")
    end

    t = fixture(profile)
    local mapInfo = t.data.env.getMapInfo
    t.data.env.getMapInfo = function(id) if id ~= 51003 then return mapInfo(id) end end
    t.nav:Update(); t:frames(2)
    assert(t.nav.state == "planning" and not t.firstCommit and t.nav._directBaselinePending,
        "Unknown provider ancestry is not evidence of direct access")
    t.data.env.getMapInfo = mapInfo
    t.nav:ForceRefresh(); t.nav:Update(); t:frameOnce()
    assert(t.nav.state == "ready" and t.nav.search and t.firstCommit.frame == 2 and t.firstPaint.frame == 3,
        "Late provider geography can prove the still-unpublished cold baseline without waiting for its catalogue")
    t.nav:Cancel("test_end")

    -- Every negative is decided by the real provider, not a hierarchy guess.
    for _, restriction in ipairs({ "world", "floor", "access", "noAutoconnect", "phase", "isolated", "far" }) do
        t = fixture(profile, { phase = restriction == "phase" })
        if restriction == "world" then t.step.Coord.instanceID = 8
        elseif restriction == "floor" then t.step.Coord.floor = 2
        elseif restriction == "access" then t.step.Coord.accessKey = "sealed-room"
        elseif restriction == "noAutoconnect" then t.step.Coord.noAutoconnect = true
        elseif restriction == "phase" then t.allowed = false
        elseif restriction == "isolated" then t.data.config.IsolatedAreas[51003] = "interior"
        elseif restriction == "far" then t.step.Zone, t.step.Coord.y = 51004, 2100 end
        t.nav:Update(); t:frames(2)
        assert(t.nav.state == "planning" and not t.nav.zoneReady and not t.nav.recomputeKeepingDirect
            and t.nav.search and not t.firstCommit,
            "Cold direct publication cannot bypass " .. restriction)
        t.nav:Cancel("test_end")
    end

    t = fixture(profile)
    t.step.Zone, t.step.Coord.y = 51004, 2099
    t.nav:Update()
    assert(t.nav.state == "ready" and t.nav.zoneReady and t.nav.search,
        "A different connected zone just inside the existing distance threshold permits a cold baseline")
    t.nav:Cancel("test_end")

    -- Invalidate a publication's proof instead of recycling it for edited data.
    for _, change in ipairs({ "geometry", "objective", "access", "world", "floor", "phase" }) do
        t = fixture(profile, { phase = change == "phase" })
        t.nav:Update(); t:frames(2)
        local candidate, stale = t.nav.search, t.nav._searchTimer
        if change == "geometry" then APR.navigationGeometryRevision = 1
        elseif change == "objective" then t.step.Coord.y = 1450
        elseif change == "access" then t.f.player.accessKey = "new-room"
        elseif change == "world" then t.f.player.instanceID = 8
        elseif change == "floor" then t.f.player.floor = 3
        elseif change == "phase" then t.allowed = false end
        t.nav:ForceRefresh(); t.nav:Update()
        assert(candidate.status == "cancelled" and t.nav.state == "planning" and not t.nav.recomputeKeepingDirect,
            "A changed " .. change .. " invalidates the old direct proof")
        local current = t.nav.search
        stale.callback()
        assert(t.nav.search == current and t.nav.state == "planning",
            "An obsolete catalogue callback cannot republish an invalid direct proof")
        t.nav:Cancel("test_end")
    end

    -- In-place mutations are discovered by Update/async callbacks themselves;
    -- an explicit ForceRefresh would conceal an incomplete freshness snapshot.
    for _, owner in ipairs({ "player", "objective" }) do
        for _, field in ipairs({ "floor", "accessKey", "noAutoconnect", "phaseAgnostic", "isInstance", "region" }) do
            for _, boundary in ipairs({ "update", "callback" }) do
                t = fixture(profile)
                -- Deliberately return one mutable table on every observation.
                function APR:GetNavigationPlayerPosition() return t.f.player end
                t.nav:Update()
                local job, timer, inputs = t.nav.search, t.nav._searchTimer, t.nav._routeInputs
                local raw = owner == "player" and t.f.player or t.step.Coord
                local value = field == "floor" and 3 or (field == "accessKey" or field == "region") and "sealed" or true
                raw[field] = value
                assert(inputs.position ~= t.f.player and job.request.start ~= t.f.player,
                    "A reused live point must not mutate the request or its snapshot")
                assert(inputs.position[field] == nil and inputs.coordValues[field] == nil,
                    "Snapshots preserve the original optional values, including nil")
                assert(t.nav:HasPlanningInputsChanged(t.f.player),
                    "Freshness detects " .. owner .. "." .. field .. " without ForceRefresh")
                if owner == "objective" then
                    assert(not t.nav:IsObjectiveCurrent(inputs), "Objective metadata belongs to its original proof")
                end
                if boundary == "update" then t.nav:Update() else timer.callback() end
                assert(job.status == "cancelled" and t.nav.search ~= job,
                    "Changed " .. owner .. "." .. field .. " retires its pending candidate at " .. boundary)
                if boundary == "callback" then
                    assert(t.nav.state == "planning" and not t.nav.recomputeKeepingDirect and not t.nav.zoneReady,
                        "A stale callback cannot leave its old direct proof ready")
                end
                t.nav:Cancel("test_end")
            end
        end
    end

    t = fixture(profile)
    t.nav:Update()
    local old, oldTimer = t.nav.search, t.nav._searchTimer
    t.step.Coord.z = 30
    assert(not t.nav:IsObjectiveCurrent(t.nav._routeInputs), "In-place target altitude edits invalidate cost/arrival inputs")
    oldTimer.callback()
    assert(old.status == "cancelled" and t.nav.state == "planning")
    t.nav:Cancel("test_end")

    for _, boundary in ipairs({ "update", "callback" }) do
        t = fixture(profile, { phase = true })
        t.nav:Update()
        local job, timer = t.nav.search, t.nav._searchTimer
        t.allowed = false
        assert(t.nav:HasPlanningInputsChanged(t.f.player),
            "A closed live phase invalidates direct proof even when point fields are unchanged")
        if boundary == "update" then t.nav:Update() else timer.callback() end
        assert(job.status == "cancelled" and t.nav.state == "planning" and not t.nav.recomputeKeepingDirect)
        t.nav:Cancel("test_end")
    end

    -- Phase-agnostic access itself is snapshotted, not merely the current quest state.
    t = fixture(profile, { phase = true })
    t.allowed, t.step.Coord.phaseAgnostic = false, true
    t.nav:Update()
    assert(t.nav.state == "ready")
    old, oldTimer = t.nav.search, t.nav._searchTimer
    t.step.Coord.phaseAgnostic = nil
    oldTimer.callback()
    assert(old.status == "cancelled" and t.nav.state == "planning" and not t.nav.zoneReady,
        "Removing phase-agnostic access cannot retain a closed destination's baseline")
    t.nav:Cancel("test_end")

    for _, boundary in ipairs({ "inside_step", "publish" }) do
        t = fixture(profile)
        t.nav:Update()
        local job, timer = t.nav.search, t.nav._searchTimer
        local context, generation = t.nav.context, t.nav.generation
        local result = { segments = { { kind = "walk", from = job.request.start, to = job.request.goal } } }
        if boundary == "inside_step" then
            function job:Step()
                t.step.Coord.floor = 2
                return "ready", result
            end
            timer.callback()
        else
            t.f.player.floor = 2
            t.nav:Publish(result, context, generation)
        end
        assert(job.status == "cancelled" and t.nav.state == "planning" and not t.nav.recomputeKeepingDirect
            and not t.nav.zoneReady and not t.nav.search,
            "A stale ready result is rejected at " .. boundary .. " before publication")
        t.nav:Cancel("test_end")
    end

    -- The selected alternative coordinate carries the same proof metadata.
    for _, boundary in ipairs({ "callback", "publish" }) do
        t = fixture(profile)
        t.nav:Update()
        local job, timer, context, generation = t.nav.search, t.nav._searchTimer, t.nav.context, t.nav.generation
        local canWalk, replacement, once = t.data.CanWalk
        function t.data:CanWalk(from, to)
            if not once then
                once = true
                t.nav:ForceRefresh(); t.nav:Update()
                replacement = t.nav.search
            end
            return canWalk(self, from, to)
        end
        if boundary == "callback" then timer.callback()
        else t.nav:Publish({ segments = { { kind = "walk", from = job.request.start, to = job.request.goal } } }, context, generation) end
        assert(job.status == "cancelled" and replacement and t.nav.search == replacement and replacement.status == "planning",
            "Reentrant access proof cannot detach the replacement job at " .. boundary)
        t.nav:Cancel("test_end")
    end

    t = fixture(profile)
    t.step.Coords, t.step.Coord = { { x = 50, y = 1350, instanceID = 7 } }, nil
    function APR:GetStepCoord(step) return step.Coords[1], step.Zone end
    t.nav:Update()
    old, oldTimer = t.nav.search, t.nav._searchTimer
    t.step.Coords[1].accessKey = "new-access"
    assert(not t.nav:IsObjectiveCurrent(t.nav._routeInputs))
    oldTimer.callback()
    assert(old.status == "cancelled" and t.nav.state == "planning",
        "An in-place edit of the resolved Coords entry cannot escape freshness checks")
    t.nav:Cancel("test_end")

    t = fixture(profile)
    local alternate = { x = 50, y = 1600, instanceID = 7, floor = 2 }
    function APR:GetStepCoord(step) return t.targetOverride and alternate or step.Coord, step.Zone end
    t.nav:Update()
    old, oldTimer = t.nav.search, t.nav._searchTimer
    t.targetOverride = true
    assert(not t.nav:IsObjectiveCurrent(t.nav._routeInputs) and t.nav:HasPlanningInputsChanged(t.f.player),
        "A late scenario/entrance override invalidates a previously ordinary coordinate")
    oldTimer.callback()
    assert(old.status == "cancelled" and t.nav.state == "planning")
    t.nav:Cancel("test_end")

    for _, owner in ipairs({ "player", "objective" }) do
        for _, field in ipairs({ "floor", "accessKey", "noAutoconnect", "phaseAgnostic" }) do
            t = fixture(profile)
            t.nav:Update()
            local job = t.nav.search
            local opaque = setmetatable({}, { __eq = function() error("Opaque value compared") end,
                __lt = function() error("Opaque value ordered") end, __tostring = function() error("Opaque value formatted") end })
            function issecretvalue(value) return rawequal(value, opaque) end
            function APR:CanAccessValue(value) return not rawequal(value, opaque) end
            local raw = owner == "player" and t.f.player or t.step.Coord
            raw[field] = opaque
            assert(t.nav:HasPlanningInputsChanged(t.f.player), "Opaque restrictions invalidate existing proof")
            t.nav:Update()
            assert(job.status == "cancelled" and t.nav.state == "waiting_data" and not t.nav.recomputeKeepingDirect,
                "Unreadable " .. owner .. "." .. field .. " stays unknown instead of becoming nil access")
            t.nav:Cancel("test_end")
            issecretvalue = nil
        end
    end

    t = fixture(profile)
    t.nav:Update(); t:frames(2)
    local job, stale = t.nav.search, t.nav._searchTimer
    APR:SetRouteProgress(APR.ActiveRoute, 3, "manual_skip")
    stale.callback()
    assert(job.status == "cancelled" and not t.nav.search and not t.nav.recomputeKeepingDirect,
        "Progress/context changes cancel the cold candidate before any stale publication")
    t.nav:Cancel("test_end")

    t = fixture(profile)
    t.step._navigationUnlock = true
    function APR:GetNavigationUnlockStep() return t.step end
    t.nav:Update()
    assert(t.nav.state == "planning" and not t.nav.recomputeKeepingDirect and t.nav.search.request.preferZoneAccess,
        "An unlock instruction keeps its entrance/action planning even when walking access is proven")
    t.nav:Cancel("test_end")

    t = fixture(profile)
    local candidate
    APR.event.QueueStepRefresh = function()
        candidate = t.nav.search
        APR:SetRouteProgress(APR.ActiveRoute, 3, "manual_skip")
    end
    t.nav:Update()
    assert(candidate and candidate.status == "cancelled" and not t.nav.search and not t.nav._searchTimer
        and not t.nav.recomputeKeepingDirect and APRData[APR.PlayerID][APR.ActiveRoute] == 3,
        "A reentrant notification cannot advance/publish the job whose context it just cancelled")
    t.nav:Cancel("test_end")

    t = fixture(profile)
    t.nav:Update()
    local candidate = t.nav.search
    t.nav:BeginWorldLoading("PLAYER_LEAVING_WORLD")
    assert(candidate.status == "cancelled" and t.nav.worldLoading and not t.nav.search,
        "Loading cancels the candidate instead of publishing a baseline in a different world")
end
print("Startup navigation baseline: cold/replan, faster alternatives, late data, access, geometry and stale contexts passed")
