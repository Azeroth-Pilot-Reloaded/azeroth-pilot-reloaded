-- Exercise controller lifecycle and path replacement through the real engine.
local function fixture()
    local t = { now = 10, money = 100, usable = true, timers = {}, rows = {}, buttons = {},
        position = { x = 0, y = 0, instanceID = 0, uiMapID = 2 } }
    local noop = function() end
    function GetTime() return t.now end
    function UnitPosition()
        local p = t.position
        if p then return p.x, p.y, 0, p.instanceID end
    end
    function UnitIsDeadOrGhost() return t.dead end
    function InCombatLockdown() return t.combat end
    function UnitOnTaxi() return t.onTaxi end
    function GetMoney() return t.money end
    function IsFlyableArea() return false end
    function CreateVector2D(x, y) return { x = x, y = y } end
    function LibStub() return { GetLocale = function() return setmetatable({
        RUN_WAYPOINT = "Marcher vers le point", TRAVEL_TO = "Aller Ã ",
    }, { __index = function(_, key) return key end }) end } end
    function CreateFrame()
        t.frame = { events = {}, scripts = {} }
        function t.frame:RegisterEvent(event) self.events[event] = true end
        function t.frame:SetScript(key, fn) self.scripts[key] = fn end
        return t.frame
    end
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { callback = callback, delay = delay, Cancel = function(self) self.cancelled = true end }
        t.timers[#t.timers + 1] = timer
        return timer
    end }
    C_Map = { GetBestMapForUnit = function() return t.position and t.position.uiMapID end,
        GetWorldPosFromMapPos = function() return 0 end }
    local step = { Zone = 3, Coord = { x = 0, y = 15000, mapID = 3 } }
    APR = { PlayerID = "p", ActiveRoute = "r", RouteQuestStepList = { r = { step } },
        settings = { profile = { enableAddon = true } }, GAME_VERSIONS = { Forever = "forever" },
        Arrow = { SetCoord = function(self)
            local guidance = APR.navigation:GetRetainedArrow() or APR.navigation:GetActiveStep()
            if guidance and (guidance.displayAction or (guidance.sourceFree and guidance.action)) then
                self:SetArrowActive(true, 0, 0); return
            end
            local coord = guidance and guidance.Coord or (APR.IsInRouteZone and step.Coord)
            if coord then self:SetArrowActive(true, coord.x, coord.y) end
        end, SetArrowActive = function(self, active, x, y)
            self.Active, self.x, self.y = active, x or 0, y or 0
            t.arrowActive = active; if not active then t.arrowHides = (t.arrowHides or 0) + 1 end
        end },
        event = { QueueStepRefresh = function() t.notifications = (t.notifications or 0) + 1 end }, SendMessage = noop }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return "forever" end
    function APR:GetCurrentStep() return step, 1, { step } end
    function APR:GetCurrentRouteMapIDsAndName() return { 3 }, 3 end
    function APR:GetStepCoord(s) return s.Coord, s.Zone end
    function APR:GetPreferredStepZone(s) return s.Zone end
    function APR:CheckNavigationZoneReady() return false end
    function APR:GetNavigationPlayerPosition()
        if not t.position then return nil end
        local copy = {}; for key, value in pairs(t.position) do copy[key] = value end
        return copy
    end
    local ui = { pendingRemoval = {}, pendingButtonRequests = {}, pendingContainerDestroy = {},
        questsList = t.rows, questsExtraTextList = {}, SoftHide = noop }
    function ui:AddQuestSteps(key, text, id, _, _, _, _, presentation)
        self.questsList[key .. "-" .. tostring(id)] = { text = text, presentation = presentation }
    end
    function ui:AddQuestDivider(key) self.questsList[key] = { divider = true } end
    function ui:AddStepButton(key, id) t.buttons[key] = id end
    function ui:FlushPendingContainers()
        for key in pairs(self.pendingRemoval) do self.questsList[key], t.buttons[key] = nil, nil end
        self.pendingRemoval = {}
    end
    APR.currentStep = ui
    APRData = { p = { r = 1 } }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    APR.NavigationData = { profile = "forever", GetText = function(_, key)
        return ({ RUN_WAYPOINT = "Va au point de passage", TRAVEL_TO = "Rejoins %s" })[key] or key
    end }
    function APR.NavigationData:CanWalk(a, b) return a.uiMapID == b.uiMapID end
    function APR.NavigationData:GetActionUsability() return t.usable, t.usable and nil or "cooldown" end
    function APR.NavigationData:BuildEdges(context)
        t.builds = (t.builds or 0) + 1
        t.searchContext = context
        local edges = t.filterActions and not t.usable and {} or t.edges
        return edges or {}, { waitingData = t.pendingData, blockedEdges = t.blockedEdges }
    end
    APR.taxiData = { BuildEdges = function() return {}, {} end }
    APR.NavigationAdapter = { CreateCooldownCheck = function()
        return { Step = function() return "ready", t.cooldownsChanged == true end }
    end }
    t.edges = { { id = "portal", kind = "portal", seconds = 50, copper = 0,
        from = { x = 100, y = 0, instanceID = 0, uiMapID = 2 },
        to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 }, instruction = "Portal" } }
    APR.NavigationEngine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
    t.nav = APR.navigation
    function t:Update()
        self.nav:ForceRefresh(); self.nav:Update()
        local attempts = 0
        while self.nav.search do
            attempts = attempts + 1; assert(attempts < 1000)
            local timer = table.remove(self.timers, 1); assert(timer)
            if not timer.cancelled then timer.callback() end
        end
    end
    function t:HasError()
        for key in pairs(self.rows) do if key:find("^01_NAVIGATION_ERROR") then return true end end
        return false
    end
    return t
end

local t = fixture()
t.edges[1].instruction = nil
C_Map.GetMapInfo = function() return { name = "Nom du client" } end
t:Update()
assert(t.nav.queue[1].label == "Va au point de passage" and t.nav.queue[2].label == "Rejoins Nom du client",
    "Fallback instructions use library translations and the client's destination name")
-- Every distance compares complete journeys; thresholds do not veto shortcuts.
for _, threshold in ipairs({ 2000, 10000 }) do
    for _, kind in ipairs({ "portal", "spell", "item" }) do
        for _, destination in ipairs({ 581, threshold - 1, threshold, threshold + 1, 7774 }) do
            t = fixture()
            local objective = APR:GetCurrentStep()
            objective.Zone, objective.Coord.mapID, objective.Coord.y = 2, 2, destination
            function APR:CheckNavigationZoneReady() return true end
            function t.nav:GetThreshold() return threshold end
            function t.nav:GetMovementSpeed() return 7 end
            local personal = kind ~= "portal"
            t.edges = { { id = "shortcut", kind = kind, seconds = 5,
                sourceFree = personal, action = personal and { type = kind, data = 123 } or nil,
                from = { x = personal and 0 or 100, y = 0, instanceID = 0, uiMapID = 2 },
                to = { x = destination - 100, y = 0, instanceID = 0, uiMapID = 2 } } }
            t:Update()
            local shortcut
            for _, leg in ipairs(t.nav.queue) do if leg.kind == kind then shortcut = leg end end
            assert(shortcut and t.nav:IsNavigating() and t.nav.totalSeconds < destination / 7,
                "A faster " .. kind .. " must remain eligible at " .. destination .. " yards")
            assert(APRData.p.r == 1)
            local builds, generation = t.builds, t.nav.generation
            for _ = 1, 50 do t.nav:Update() end
            assert(t.builds == builds and t.nav.generation == generation, "Idle updates reuse the selected journey")
            t.edges[1].seconds = destination / 7 + 1
            t.nav.queue, t.nav.state = {}, "ready"
            t:Update()
            assert(t.nav:GetState() == "ready" and not t.nav:GetActiveStep(), "A slower shortcut loses to direct travel")
        end
    end
end

t = fixture()
t.position.accessKey = "wizards-sanctum"
t:Update()
assert(t.searchContext.start.accessKey == "wizards-sanctum", "Controller preserves verified indoor access identity")
local active, queue = t.nav:GetActiveStep(), t.nav.queue
local hides = t.arrowHides
t.edges[1].seconds = 45
t:Update()
assert(t.nav.queue ~= queue and t.nav:GetActiveStep() ~= active, "A five-second improvement replaces a slower valid itinerary")
assert(t.arrowHides == hides, "A harmless dirty event never hides the valid guidance arrow")
t.edges[1].seconds = 1
t:Update()
assert(t.nav.queue ~= queue and t.nav:GetActiveStep() ~= active, "A material improvement replaces the old itinerary")

-- A direct portal discovered during guidance saves four seconds on a short
-- trip. It must not be held behind the old fifteen-second replacement floor.
t = fixture()
t.edges = {
    { id = "via-other-zone", kind = "portal", seconds = 9, from = t.position,
        to = { x = 500, y = 0, instanceID = 0, uiMapID = 4 } },
    { id = "second-portal", kind = "portal", seconds = 10,
        from = { x = 500, y = 0, instanceID = 0, uiMapID = 4 },
        to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 } },
}
t:Update()
assert(t.nav.totalSeconds == 19)
local detour = t.nav.queue
t.edges[#t.edges + 1] = { id = "direct-portal", kind = "portal", seconds = 15,
    from = t.position, to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 } }
assert(t.frame.events.ACHIEVEMENT_EARNED, "An account achievement must request fresh routing")
t.frame.scripts.OnEvent(t.frame, "ACHIEVEMENT_EARNED", 42045)
t:Update()
assert(t.nav.queue ~= detour and t.nav:GetActiveStep().connectionID == "direct-portal",
    "A newly unlocked faster direct portal replaces a short valid detour")
assert(math.abs(t.nav.lastComparison.requiredGain - 0.001) < 0.000001 and not t.nav.lastComparison.retained)
local directQueue = t.nav.queue
t.edges[#t.edges + 1] = { id = "near-tie", kind = "portal", seconds = 14.9999,
    from = t.position, to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 } }
for _ = 1, 4 do t:Update() end
assert(t.nav.queue == directQueue and t.nav.lastComparison.retained,
    "Sub-millisecond ties cannot oscillate the current portal instruction")

t = fixture(); t:Update()
assert(t.nav:GetActiveStep().kind == "walk")
t.position.accessKey = "mandatory-interior"
function APR.NavigationData:CanWalk(from, to)
    return from.uiMapID == to.uiMapID and from.accessKey == to.accessKey
end
assert(not t.nav:IsItineraryValid(), "Crossing an access boundary invalidates an unreachable approach walk")

t = fixture()
t.edges = { { id = "personal", kind = "spell", sourceFree = true, action = { type = "spell", data = 123 }, seconds = 5,
    from = { x = 0, y = 0, instanceID = 0, uiMapID = 2 }, to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 } } }
t:Update()
active = t.nav:GetActiveStep()
assert(active.sourceFree and active.kind == "spell")
assert(not active.Coord and active.from and active.to,
    "A personal spell retains its planning endpoints without presenting its cast origin as a waypoint")
t.position.x = 1000; t.buttons = {}; t.nav:Render()
assert(next(t.buttons), "Personal travel remains actionable away from the originally planned cast position")
t.frame.scripts.OnEvent(t.frame, "UNIT_SPELLCAST_START", "player", "cast", 123)
t.usable, t.filterActions = false, true
t:Update()
assert(t.nav:GetActiveStep() == active, "A casting spell's cooldown must not replace travel before actual arrival")
t.position.x, t.position.uiMapID = 15000, 2
t.nav:PollArrival()
assert(t.nav:GetActiveStep() == active, "Matching XY in the departure map does not complete a personal teleport")
t.position.uiMapID = 3; t.nav:PollArrival()
assert(t.nav:GetState() == "ready" and APRData.p.r == 1, "Only actual arrival resumes the authored objective")

-- Every leg is already planned. Expected loading/arrival consumes the used
-- transport and validates the remaining queue instead of rebuilding providers.
local function plannedTransition(kind)
    local sample = fixture()
    local personal = kind == "spell" or kind == "item"
    local landing = { x = 1000, y = 0, instanceID = 1, uiMapID = 4 }
    local gate = { x = 1200, y = 0, instanceID = 1, uiMapID = 4 }
    local goal = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 }
    sample.edges = {
        { id = "first-crossing", kind = kind, from = sample.position, to = landing, seconds = 5,
            sourceFree = personal, action = personal and { type = kind, data = 123 } or nil },
        { id = "second-crossing", kind = "portal", from = gate, to = goal, seconds = 5,
            canStart = function() return not sample.gateClosed end },
    }
    sample:Update()
    assert(sample.nav:GetActiveStep().connectionID == "first-crossing")
    sample.landing, sample.gate = landing, gate
    return sample
end

-- Leaving the world is an explicit suspension, not a failed position/action
-- check. Loading can outlast every cast and map-settling timeout.
for _, reversed in ipairs({ false, true }) do
    t = plannedTransition("spell")
    local cached, builds, frame = t.nav.queue, t.builds, t.frame
    local oldGeneration, context, cancelled = t.nav.generation, t.nav.context, false
    t.nav.search = { Cancel = function() cancelled = true end }
    for _, event in ipairs({ "PLAYER_LEAVING_WORLD", "LOADING_SCREEN_ENABLED",
        "PLAYER_ENTERING_WORLD", "LOADING_SCREEN_DISABLED" }) do
        assert(frame.events[event], "Navigation must observe the complete native world/loading lifecycle")
    end
    frame.scripts.OnEvent(frame, reversed and "LOADING_SCREEN_ENABLED" or "PLAYER_LEAVING_WORLD")
    frame.scripts.OnEvent(frame, reversed and "PLAYER_LEAVING_WORLD" or "LOADING_SCREEN_ENABLED")
    assert(t.nav.worldLoading and cancelled and not t.nav.search and t.nav.queue == cached,
        "World departure discards only an obsolete candidate, preserving published guidance")
    local previousCancellation = t.nav.lastCancellation
    t.position, t.dead, t.usable, t.now = nil, true, false, t.now + 90
    frame.scripts.OnEvent(frame, "QUEST_LOG_UPDATE")
    frame.scripts.OnEvent(frame, "BAG_UPDATE_DELAYED")
    t.nav:Update(); t.nav:Render(); t.nav:PollArrival()
    frame.scripts.OnUpdate(frame, 1)
    assert(t.nav.queue == cached and t.builds == builds and t.nav.lastCancellation == previousCancellation,
        "Unavailable world observations cannot cancel or rebuild a suspended trip")
    t.position, t.dead = t.landing, false
    frame.scripts.OnEvent(frame, reversed and "LOADING_SCREEN_DISABLED" or "PLAYER_ENTERING_WORLD")
    t.nav:Update()
    assert(t.nav.worldLoading and t.nav.queue == cached and t.builds == builds,
        "Both the world and loading-screen notifications must settle before resuming")
    frame.scripts.OnEvent(frame, reversed and "PLAYER_ENTERING_WORLD" or "LOADING_SCREEN_DISABLED")
    t.nav:Update()
    assert(not t.nav.worldLoading and t.nav.queue == cached and t.nav:GetActiveStep().kind == "walk"
        and t.builds == builds and not t.nav.search,
        "Even a long native loading screen resumes the full itinerary without a provider rebuild")
    t.nav:Publish({ segments = {} }, context, oldGeneration)
    assert(t.nav.queue == cached, "A discarded pre-loading candidate cannot overwrite the resumed cursor")
end

for _, cancellation in ipairs({ "step", "disable", "clear" }) do
    t = plannedTransition("spell")
    local cached, frame = t.nav.queue, t.frame
    frame.scripts.OnEvent(frame, "PLAYER_LEAVING_WORLD")
    if cancellation == "step" then APR:SetRouteProgress("r", 2, "manual_skip")
    elseif cancellation == "disable" then APR.settings.profile.enableAddon = false; t.nav:Update()
    else t.nav:ClearActivePath() end
    frame.scripts.OnEvent(frame, "PLAYER_ENTERING_WORLD")
    assert(t.nav.queue ~= cached and #t.nav.queue == 0,
        "Explicit " .. cancellation .. " changes during loading cannot resurrect an old itinerary")
end
for _, kind in ipairs({ "spell", "item", "portal" }) do
    t = plannedTransition(kind)
    local cached, builds = t.nav.queue, t.builds
    local first = t.nav:GetActiveStep()
    t.position = nil
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and t.nav:IsNavigating(),
        "Unavailable map data during loading must preserve the complete itinerary")
    t.usable = false -- The consumed action's cooldown is irrelevant after arrival.
    t.position = { x = 1003, y = 0, instanceID = 1, uiMapID = 4 }
    APR.navigationGeometryRevision = 1
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.queue == cached and t.nav:GetActiveStep().kind == "walk"
        and t.builds == builds and not t.nav.search and not t.nav.dirty,
        "Expected arrival resumes the precomputed walk without a new provider build")
    assert(t.nav._routeInputs.position.instanceID == 1 and t.nav._routeInputs.geometryRevision == 1,
        "The movement/geometry baseline follows the confirmed landing")
    t.position.x = 1050
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds,
        "Repeated post-load notifications cannot restart a settled continuation")
    t.position = t.gate
    t.nav:PollArrival()
    assert(t.nav:GetActiveStep().connectionID == "second-crossing")
    t.nav:PollArrival()
    t.position = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 }
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav:GetState() == "ready" and t.builds == builds and APRData.p.r == 1,
        "The cached final crossing completes guidance without recalculation or quest progress")
end
APR.navigationGeometryRevision = nil

-- Native loading does not deliver one atomic position or an isolated world
-- event. Cast, quest/bag updates and source/destination map observations mix.
for _, beforeWorldEvent in ipairs({ true, false }) do
    t = plannedTransition("spell")
    local cached, builds = t.nav.queue, t.builds
    t.frame.scripts.OnEvent(t.frame, "UNIT_SPELLCAST_START", "player", "cast", 123)
    t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and not t.nav.search,
        "Starting the planned cast must not launch another full search")
    if not beforeWorldEvent then
        t.nav._worldTransitionTime = t.now
        t.nav:ForceRefresh("world_transition")
    end
    -- World and coordinates have arrived, but the map API still names source.
    t.position = { x = 1000, y = 0, instanceID = 1, uiMapID = 2 }
    APR.navigationGeometryRevision = 1
    t.frame.scripts.OnEvent(t.frame, "QUEST_LOG_UPDATE")
    t.frame.scripts.OnEvent(t.frame, "BAG_UPDATE_DELAYED")
    t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and not t.nav.search,
        "A partial destination snapshot cannot discard the precomputed queue")
    -- A successful cast may have cooled down long before a slow load ends.
    t.now, t.usable = t.now + 40, false
    t.position.uiMapID = 4
    t.frame.scripts.OnEvent(t.frame, "QUEST_LOG_UPDATE")
    t.nav:Update()
    assert(t.nav.queue == cached and t.nav:GetActiveStep().kind == "walk"
        and t.builds == builds and not t.nav.search,
        "Actual arrival wins even when unrelated events preceded the world event and the cast timeout elapsed")
    -- The delayed world event can itself be followed by a generic refresh.
    t.nav:ForceRefresh("world_transition")
    t.frame.scripts.OnEvent(t.frame, "BAG_UPDATE_DELAYED")
    t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and not t.nav.search,
        "Generic post-load updates must not erase an expected-transition validation")
end
APR.navigationGeometryRevision = nil

t = plannedTransition("spell")
do
    local cached, builds = t.nav.queue, t.builds
    t.position = { x = 400, y = 0, instanceID = 0, uiMapID = 8 }
    t.frame.scripts.OnEvent(t.frame, "UNIT_SPELLCAST_START", "player", "cast", 123)
    t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and not t.nav.search,
        "Personal casts use their observed origin even after leaving the originally planned map")
    t.position = t.landing
    t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and t.nav:GetActiveStep().kind == "walk")
end

t = plannedTransition("portal")
do
    local cached, builds = t.nav.queue, t.builds
    t.nav._worldTransitionTime = t.now
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.queue == cached and t.builds == builds and not t.nav.search,
        "A source snapshot immediately after the world event is still loading data")
    t.now = t.now + 6
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.search or t.builds > builds, "An unconfirmed crossing must eventually fall back to fresh planning")
end

t = plannedTransition("spell")
do
    local first, builds = t.nav:GetActiveStep(), t.builds
    first.to.instanceID, first.to.uiMapID = 0, 2
    t.frame.scripts.OnEvent(t.frame, "UNIT_SPELLCAST_START", "player", "cast", 123)
    t.position = { x = 5000, y = 0, instanceID = 0, uiMapID = 2 }
    t.nav:Update()
    assert(t.nav.search or t.builds > builds,
        "A different same-map landing cannot be mistaken for a cast still at its origin")
end

-- PollArrival may run before the delayed world handler. Its continuation must
-- survive both orders, as well as an obsolete background candidate.
t = plannedTransition("spell")
local cached, builds = t.nav.queue, t.builds
t.position = t.landing
t.nav:PollArrival()
local cancelledCandidate = false
t.nav.search = { Cancel = function() cancelledCandidate = true end }
t.nav:ForceRefresh("world_transition"); t.nav:Update()
assert(t.nav.queue == cached and t.builds == builds and cancelledCandidate and not t.nav.search,
    "A delayed world callback reuses the already-advanced cursor and cancels an old-origin candidate")

for _, mismatch in ipairs({ "world", "map", "distance", "access", "floor", "height" }) do
    t = plannedTransition("spell")
    if mismatch == "height" then
        t.nav:GetActiveStep().to.z, t.nav:GetActiveStep().arrivalZTolerance = 100, 5
    end
    t.position = { x = 1000, y = 0, instanceID = 1, uiMapID = 4, z = 0 }
    if mismatch == "world" then t.position.instanceID = 2 end
    if mismatch == "map" then t.position.uiMapID = 5 end
    if mismatch == "distance" then t.position.x = 2000 end
    if mismatch == "access" then t.position.accessKey = "private" end
    if mismatch == "floor" then t.position.floor = "lower" end
    function APR.NavigationData:IsSameAccessRegion(a, b)
        return a.instanceID == b.instanceID and a.uiMapID == b.uiMapID
            and a.accessKey == b.accessKey and a.floor == b.floor
    end
    builds = t.builds
    t.nav:ForceRefresh("world_transition"); t.nav:Update()
    assert(t.nav.search or t.builds > builds,
        "An unexpected " .. mismatch .. " must trigger fresh planning")
end

t = plannedTransition("spell")
t.position, t.gateClosed = t.landing, true
builds = t.builds
t.nav:ForceRefresh("world_transition"); t.nav:Update()
assert(t.nav.search or t.builds > builds, "A closed later gate cannot reuse the cached continuation")

t = plannedTransition("spell")
t.position = t.landing
local changedObjective = APR:GetCurrentStep()
changedObjective.Coord.y = 25000
builds = t.builds
t.nav:ForceRefresh("world_transition"); t.nav:Update()
assert(t.nav.search or t.builds > builds, "A changed objective cannot inherit the previous itinerary")

t = fixture()
t.edges[1].action = { type = "spell", data = 123 }
t:Update()
t.usable, t.filterActions = false, true
t:Update()
assert(t.nav:GetState() == "no_path" and t:HasError(), "A proven unusable itinerary is discarded even without a faster alternative")

t = fixture()
t.edges = { { id = "restricted-item", kind = "item", sourceFree = true,
    action = { type = "item", data = 123 }, seconds = 5,
    from = { x = 0, y = 0, instanceID = 0, uiMapID = 2 },
    to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 },
    canStart = function(position, live)
        if live then t.liveValidation = true end
        return position.uiMapID == 2
    end } }
t:Update()
active = t.nav:GetActiveStep()
assert(active.canStart and next(t.buttons) and t.nav:IsItineraryValid() and t.liveValidation,
    "Published guidance retains the departure predicate and revalidates it live")
t.position.uiMapID = 4
t.nav:Render()
assert(not next(t.buttons) and not t.nav:IsItineraryValid(),
    "A changed departure map removes an already-rendered secure action and invalidates the retained route")
t.nav:PollArrival()
assert(t.nav.dirty and t.nav._stepCheckTimer, "Invalid departure conditions trigger a replan without relying on the arrow")
t.edges = {}; t:Update()
assert(t.nav:GetState() == "no_path", "Failed replanning must not restore an invalid restricted action")

t = fixture()
t.edges[1].to = { x = 10000, y = 0, instanceID = 0, uiMapID = 3 }
t.edges[2] = { id = "future-item", kind = "item", sourceFree = true,
    action = { type = "item", data = 123 }, seconds = 5,
    from = t.edges[1].to, to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 },
    canStart = function(position) return position.uiMapID == 3 end }
t:Update()
assert(#t.nav.queue == 3 and t.nav.queue[3].kind == "item" and t.nav:IsItineraryValid(),
    "Future actions are validated at their planned departure, not at the player's current map")
t.position.x = 100; t.nav:PollArrival(); t.nav:PollArrival()
t.position.x, t.position.uiMapID = 10000, 3; t.nav:PollArrival()
active = t.nav:GetActiveStep()
active.actionCommittedUntil = t.now + 30
t.position.uiMapID = 4
assert(t.nav:IsItineraryValid(), "A committed transport is preserved while its departure restriction changes during loading")
t.position.x, t.position.uiMapID = 15000, 3; t.nav:PollArrival()
assert(t.nav:GetState() == "ready", "Confirmed arrival completes the committed transport")

t = fixture()
local fake = { status = "planning", Step = function() return "planning" end,
    Cancel = function(self) self.cancelled = true end }
function APR.NavigationEngine:CreateSearch() return fake end
t.nav:Update()
while t.nav.search.phase ~= "search" do
    local timer = table.remove(t.timers, 1)
    assert(timer, "Preparation must resume through the scheduler")
    if not timer.cancelled then timer.callback() end
end
local stale = t.nav._searchTimer
assert(stale and t.nav:GetState() == "planning")
t.position = nil
t.nav:ForceRefresh(); t.nav:Update()
assert(fake.cancelled and t.nav:GetState() == "waiting_data" and not t:HasError())
stale.callback()
assert(t.nav:GetState() == "waiting_data" and not t.nav:IsNavigating(), "Missing geometry invalidates a search's delayed publication")

t = fixture()
t.edges, t.pendingData = {}, true
t:Update()
assert(t.nav:GetState() == "waiting_data" and not t:HasError(), "Unknown provider data is neutral")
t.pendingData = false; t:Update()
assert(t.nav:GetState() == "no_path" and t:HasError(), "Only a completed, known graph failure is an error")
t.combat = true; t:Update()
assert(t.nav:GetState() == "waiting_data" and not t:HasError(), "Combat restrictions never become a terminal path error")
t.combat = false
APR.NavigationData.profile = "unsupported"; t:Update()
assert(t.nav:GetState() == "waiting_data" and t.nav.reason == "unsupported" and not t:HasError(),
    "Unsupported clients never silently use another client's graph")

t = fixture(); t:Update()
APR.currentStep.pendingButtonRequests["01_NAVIGATION_PATH-orphaned-generation"] = { stale = true }
APR.currentStep.pendingButtonRequests["authored-quest"] = { keep = true }
APR.settings.profile.enableAddon = false
t.nav:PollArrival(); t.nav:Render()
assert(not t.nav:IsNavigating() and t.arrowActive == false and not next(t.rows), "Disabling clears guidance and its arrow")
assert(not APR.currentStep.pendingButtonRequests["01_NAVIGATION_PATH-orphaned-generation"]
    and APR.currentStep.pendingButtonRequests["authored-quest"], "Cancellation clears stale secure requests even after their rows disappeared")

t = fixture()
local calls = 0
function t.nav:Update() calls = calls + 1 end
t.nav:RequestUpdate(); local old = t.nav._stepCheckTimer
t.nav:Cancel("replaced"); t.nav:RequestUpdate(); local current = t.nav._stepCheckTimer
old.callback()
assert(t.nav._stepCheckTimer == current, "A cancelled callback cannot clear a newer request's identity")
current.callback(); assert(calls == 1)

t = fixture()
assert(t.frame.events.NEW_TOY_ADDED and t.frame.events.TOYS_UPDATED,
    "Collection updates must invalidate toy routes even when bag inventory does not change")
local inProgress = { Cancel = function() error("Cooldown bursts must not cancel active planning") end }
t.nav.search = inProgress
t.frame.scripts.OnEvent(t.frame, "SPELL_UPDATE_COOLDOWN")
local cooldownTimer = t.nav._cooldownRefreshTimer
assert(cooldownTimer and cooldownTimer.delay == 1)
t.frame.scripts.OnEvent(t.frame, "SPELL_UPDATE_COOLDOWN")
assert(t.nav._cooldownRefreshTimer == cooldownTimer, "Cooldown bursts share one deferred update")
cooldownTimer.callback()
assert(t.nav.search == inProgress and not t.nav.dirty and not t.nav._stepCheckTimer,
    "Cooldown invalidation waits until the current calculation can publish")
t.nav.search = nil
t.cooldownsChanged = true
t.nav._cooldownRefreshTimer.callback()
assert(t.nav.dirty and t.nav._stepCheckTimer, "Once planning finishes, refresh from the latest cooldown state")
t.nav.dirty = false
t.frame.scripts.OnEvent(t.frame, "NEW_TOY_ADDED")
assert(t.nav.dirty, "Newly learned toys are not delayed behind the cooldown debounce")

t = fixture()
objective = APR:GetCurrentStep()
objective.Zone, objective.Coord.mapID, objective.Coord.y = 2, 2, 3000
objective.Coord.x = 50
function APR:CheckNavigationZoneReady() return true end
t.edges = {}
t:Update()
local readyGeneration, readyHides, readyNotifications = t.nav.generation, t.arrowHides, t.notifications
for tick = 1, 120 do
    t.now = t.now + 1
    t.position.x = tick % 80
    t.nav:Update()
    t.frame.scripts.OnUpdate(t.frame, 0.5)
end
assert(t.builds == 1 and t.nav.generation == readyGeneration and not t.nav.search,
    "Idle time and small movements around a proven direct objective never rebuild the graph")
assert(t.arrowHides == readyHides and t.notifications == readyNotifications,
    "Repeated direct-ready checks leave the arrow and quest rows untouched")
for _ = 1, 30 do
    t.frame.scripts.OnEvent(t.frame, "SPELL_UPDATE_COOLDOWN")
    t.nav._cooldownRefreshTimer.callback()
end
assert(not t.nav.dirty and not t.nav._stepCheckTimer and t.builds == 1,
    "Unchanged travel cooldowns never schedule a routing update")

-- Hold a replacement search open to observe the state between its frames.
local target = t.nav.destination
function APR.NavigationPlanner:Create()
    local job = { Step = function() return "planning" end, Cancel = function() end }
    t.replacement = job
    return job
end
t.nav:ForceRefresh(); t.nav:Update()
assert(t.nav.search and t.nav:GetState() == "ready" and t.nav.recomputeKeepingDirect
    and t.arrowHides == readyHides, "A background refresh retains proven direct guidance")
function t.replacement:Step()
    return "ready", { segments = { { kind = "walk", from = t.position, to = target } } }
end
t.nav._searchTimer.callback()
assert(t.nav:GetState() == "ready" and not t.nav.search and t.notifications == readyNotifications,
    "Publishing the same direct journey does not rebuild its UI")
t.position.x = t.position.x + 120
t.now = t.now + 6
t.frame.scripts.OnUpdate(t.frame, 0.5)
assert(t.nav._stepCheckTimer, "Meaningful displacement eventually reconsiders faster shortcuts")
t.nav._stepCheckTimer.callback()
assert(t.nav.search and t.nav:GetState() == "ready", "Movement replans retain the direct arrow too")
t.nav:SearchFailed()
assert(t.nav:GetState() == "ready" and t.arrowHides == readyHides,
    "A failed background alternative cannot erase a still-accessible direct journey")
t.position.accessKey = "mandatory-interior"
function APR.NavigationData:CanWalk(from, to) return from.accessKey == to.accessKey end
t.nav:Update()
assert(t.nav:GetState() == "planning" and not t.nav.recomputeKeepingDirect and t.arrowHides == readyHides
    and t.nav:GetRetainedArrow(),
    "An access boundary invalidates the route proof while retaining its display during the replacement search")

local function directFixture()
    local case = fixture()
    local current = APR:GetCurrentStep()
    current.Zone, current.Coord.mapID, current.Coord.y = 2, 2, 3000
    current.Coord.x = 50
    function APR:CheckNavigationZoneReady() return true end
    case.edges = {}
    case:Update()
    return case, current
end
t, objective = directFixture()
readyHides = t.arrowHides
objective.Coord.y = 3200
t.nav:Update()
assert(t.arrowHides > readyHides and t.nav.destination.x == 3200 and not t.nav.recomputeKeepingDirect,
    "An in-place objective coordinate edit invalidates its old direct proof without changing saved progress")
t, objective = directFixture()
readyHides = t.arrowHides
objective.Coord = { x = 50, y = 3500, mapID = 2 }
t.nav:Update()
assert(t.arrowHides > readyHides and t.nav.destination.x == 3500,
    "A scenario's replacement coordinate triggers routing while the player remains stationary")
t, objective = directFixture()
readyHides = t.arrowHides
APR.RouteQuestStepList.r[1] = { Zone = 2, Coord = { x = 0, y = 3600, mapID = 2 } }
function APR:GetCurrentStep() return self.RouteQuestStepList.r[1], 1, self.RouteQuestStepList.r end
t.nav:Update()
assert(t.arrowHides > readyHides and t.nav.destination.x == 3600,
    "Replacing the source step without replacing its route definition invalidates the old target")
t, objective = directFixture()
readyHides = t.arrowHides
APR.navigationGeometryRevision = 1
t.nav:Update()
assert(t.arrowHides == readyHides and not t.nav.recomputeKeepingDirect and t.nav:GetRetainedArrow(),
    "A phased-map change invalidates the direct proof without hiding its last direction in the same world")
t, objective = directFixture()
objective.Dungeon, objective.InstanceQuest, objective.NoArrow = true, true, true
t.position.uiMapID = 3
t.nav:Update()
assert(not t.nav._routeInputs and not t.nav.dirty, "Exempt objectives discard the old geometry proof")
for _ = 1, 20 do t.frame.scripts.OnUpdate(t.frame, 0.5) end
assert(not t.nav._stepCheckTimer, "An exempt objective cannot reschedule routing on every arrival poll")

for _, event in ipairs({ "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP" }) do
    t = directFixture()
    assert(t.frame.events[event], "Navigation observes discrete quest and level unlock changes")
    t.frame.scripts.OnEvent(t.frame, event)
    assert(t.nav.dirty and t.nav._stepCheckTimer,
        "Acquiring or losing a travel condition rechecks cached direct guidance: " .. event)
end

t = fixture(); t.nav:Update()
t.dead = true; t.frame.scripts.OnUpdate(t.frame, 0.5)
assert(not t.nav:IsNavigating() and APRData.p.r == 1, "Death cancels guidance without route progression")

t = fixture()
t.edges = { { id = "taxi", kind = "taxi", seconds = 10,
    from = { x = 0, y = 0, instanceID = 0, uiMapID = 2 },
    to = { x = 50, y = 0, instanceID = 0, uiMapID = 3 } } }
t:Update(); active = t.nav:GetActiveStep()
t.position.x, t.position.uiMapID = 50, 3
t.nav:PollArrival()
assert(t.nav:GetActiveStep() == active and active.kind == "taxi", "Being close to a destination never substitutes for boarding a taxi")
t.onTaxi = true; t.nav:PollArrival()
t.onTaxi = false; t.nav:PollArrival()
assert(t.nav:GetActiveStep().kind == "walk" and APRData.p.r == 1, "A taxi completes only after observed boarding and actual landing")

t = fixture()
local threshold, mounted, indoors, collected, usable, run = 10000, false, false, false, false, 7
function t.nav:GetThreshold() return threshold end
function GetUnitSpeed() return 0, run, 321, 4.7 end
function IsMounted() return mounted end
function IsIndoors() return indoors end
function APR:IsSpellKnown() return true end
C_MountJournal = { GetMountIDs = function() return { 1 } end,
    GetMountInfoByID = function() return "Mount", 123, 1, false, usable, 1, false, false, nil, false, collected end,
    GetMountUsabilityByID = function() return usable end }
assert(t.nav:GetMovementSpeed() == 321, "Flight estimates read the API's third result, not a truncated or running result")
threshold, mounted, run = 2000, true, 11.2
assert(t.nav:GetMovementSpeed() == 11.2, "A mounted player retains the actual running speed rather than assuming a fast mount")
mounted, run = false, 7
assert(t.nav:GetMovementSpeed() == 7, "Riding skill alone does not imply ownership of a mount")
collected = true; t.nav:InvalidatePathCache()
assert(t.nav:GetMovementSpeed() == 7, "An owned but unusable mount is not used for estimates")
usable = true; t.nav:InvalidatePathCache()
assert(t.nav:GetMovementSpeed() == 14, "An owned usable mount and riding skill improve the ground estimate")
indoors = true
assert(t.nav:GetMovementSpeed() == 7, "Indoor travel does not assume the mount can be summoned")
print("Navigation lifecycle: stable replans, personal travel, pending data, stale callbacks, disable/death and secure cleanup passed")

-- A display target can outlive an unusable itinerary, but none of that
-- itinerary's actions or arrival checks may survive with it.
local function holdReplacement(case)
    function APR.NavigationPlanner:Create()
        case.replacement = { Step = function() return "planning" end,
            Cancel = function(self) self.cancelled = true end }
        return case.replacement
    end
    case.nav:ForceRefresh(); case.nav:Update()
end

t = fixture()
t.edges = { { id = "personal", kind = "spell", sourceFree = true,
    action = { type = "spell", data = 123 }, seconds = 5,
    from = t.position, to = { x = 15000, y = 0, instanceID = 0, uiMapID = 3 } } }
t:Update()
assert(next(t.buttons), "The original personal transport exposes its secure action")
local originalGuidance = t.nav:GetActiveStep()
hides = t.arrowHides
t.usable = false
holdReplacement(t)
local retained = t.nav:GetRetainedArrow()
assert(retained and retained.uiMapID == originalGuidance.uiMapID and retained.label == originalGuidance.label
    and retained.id == originalGuidance.id, "Retained navigation preserves its native map, text and consumer identity")
assert(retained and not retained.Coord and retained.displayAction and retained.displayAction.data == 123
    and not retained.action
    and t.arrowActive and t.arrowHides == hides,
    "Retiring an unusable personal route keeps its display-only icon while the replacement is pending")
assert(t.nav:GetState() == "planning" and not t.nav:IsNavigating() and not t.nav:GetActiveStep()
    and not next(t.buttons), "Only the visual target remains; the retired action cannot execute or progress")
t.nav:PollArrival()
assert(APRData.p.r == 1, "Arriving at a retained target cannot advance authored progression")
local staleGeneration, staleContext = t.nav.generation, t.nav.context
holdReplacement(t)
assert(t.nav:GetRetainedArrow() and t.arrowHides == hides,
    "Further invalidations preserve a retained target even when its world X coordinate is zero")
assert(t.nav:GetRetainedArrow().uiMapID == retained.uiMapID and t.nav:GetRetainedArrow().label == retained.label
    and t.nav:GetRetainedArrow().id == retained.id, "Repeated replanning cannot lose the retained waypoint metadata")
t.nav:Publish({ queue = {} }, staleContext, staleGeneration)
assert(t.nav.search and t.nav:GetRetainedArrow() and t.arrowHides == hides,
    "A stale result cannot replace or clear the display from a newer search")
t.nav.waitingData = true
t.nav:SearchFailed()
assert(t.nav:GetState() == "waiting_data" and t.nav:GetRetainedArrow() and t.arrowHides == hides,
    "Missing provider data keeps the last direction while waiting for a usable result")
holdReplacement(t)
local waypoint = { x = 200, y = 50, instanceID = 0, uiMapID = 2 }
function t.replacement:Step()
    return "ready", { totalSeconds = 100, segments = {
        { kind = "walk", from = t.position, to = waypoint },
        { kind = "portal", from = waypoint, to = t.nav.destination, seconds = 10 },
    } }
end
t.nav._searchTimer.callback()
assert(not t.nav.retainedArrow and t.nav:IsNavigating() and APR.Arrow.x == waypoint.y
    and APR.Arrow.y == waypoint.x and t.arrowHides == hides,
    "Publishing a replacement swaps the target directly without an intermediate hide")

-- Geometry invalidation also preserves a direct target until the result is
-- published. A terminal failure, unlike missing data, retires that display.
t = directFixture()
hides = t.arrowHides
APR.navigationGeometryRevision = 1
holdReplacement(t)
assert(t.nav:GetRetainedArrow() and t.arrowHides == hides)
function t.replacement:Step()
    return "ready", { queue = {}, totalSeconds = 10 }
end
t.nav._searchTimer.callback()
assert(t.nav:GetState() == "ready" and not t.nav.retainedArrow and t.arrowHides == hides,
    "Publishing direct guidance clears the snapshot without hiding the arrow")
APR.navigationGeometryRevision = 2
holdReplacement(t)
APR.IsInRouteZone = false
t.nav:SearchFailed()
assert(t.nav:GetState() == "no_path" and not t.nav.retainedArrow and not t.arrowActive,
    "A completed no-path result removes the retained direction")

t = directFixture()
APR.navigationGeometryRevision = 1
holdReplacement(t)
local currentObjective = APR:GetCurrentStep()
currentObjective.NoArrow = true
assert(not t.nav:GetRetainedArrow(), "An authored visibility change invalidates the old snapshot")
currentObjective.NoArrow = nil
APR.stepRevision = (APR.stepRevision or 0) + 1
assert(not t.nav:GetRetainedArrow(), "A changed route context invalidates the snapshot before a new result arrives")
t.nav:Cancel("cleared")
assert(not t.nav.retainedArrow and not t.arrowActive, "Explicit cancellation still clears the visible arrow")

t = fixture(); t:Update()
t.nav:GetActiveStep().instanceID = 1
t.position.instanceID = 1
APR.navigationGeometryRevision = 1
holdReplacement(t)
assert(t.nav:GetRetainedArrow() and t.nav:GetRetainedArrow().instanceID == 1,
    "After a cross-world leg, preservation uses the current arrow's world rather than the route's original start")
t.position.instanceID = 2
t.nav:ForceRefresh(); t.nav:Update()
assert(not t.nav.retainedArrow and not t.arrowActive, "A different world cannot retain the old target")
print("Replanning lifecycle: display survives pending searches and swaps atomically; retired actions and stale results stay inactive")

-- An entrance leg reaches the gate first, then points inside. Coordinates alone
-- cannot complete a mandatory leg while the character remains on another map.
t = fixture()
local from = { x = 100, y = 0, instanceID = 0, uiMapID = 2 }
local to = { x = 500, y = 0, instanceID = 0, uiMapID = 3 }
local passage = t.nav:PrepareGuidanceStep({ kind = "passage", from = from, to = to, seconds = 30 }, 1, 1, from)
assert(passage.Coord.y == 500 and passage.Coord.mapID == 3, "Same-world cavern guidance continues inside after the gate")
t.nav.queue, t.nav.cursor, t.nav.state, t.nav.context = { passage }, 1, "guiding", APR:CaptureStepContext()
t.position.x = 500
t.nav:PollArrival()
assert(t.nav:GetActiveStep() == passage, "A point directly above the cavern is not an interior arrival")
t.position.uiMapID = 3
t.nav:PollArrival()
assert(not t.nav:GetActiveStep(), "Actual interior arrival completes the passage")
local otherWorld = { x = 500, y = 0, instanceID = 1, uiMapID = 3 }
passage = t.nav:PrepareGuidanceStep({ kind = "passage", from = from, to = otherWorld, seconds = 30 }, 1, 1, from)
assert(passage.Coord.y == 100 and passage.Coord.mapID == 2, "Cross-world tunnels initially point at the reachable entrance")

-- The ground-only estimate must not rescan every mount after movement speed was
-- already resolved. Indoor running needs no mount-journal walk at all.
t = fixture()
function t.nav:HasUsableMount() error("Unnecessary mount journal scan") end
t:Update()
assert(t.nav:IsNavigating())

t = fixture()
local lockedEdge = t.edges[1]
lockedEdge.blockedRequirements = { quest = 84957 }
t.edges, t.blockedEdges = {}, { lockedEdge }
APR.NavigationAdapter.GetBlockedRouteText = function(_, blockers, styled)
    assert(blockers and blockers[1].id == lockedEdge.id and blockers[1].blockedRequirements.quest == 84957)
    assert(styled == true, "The guide requests themed access diagnostics")
    return "Missing quest 84957"
end
local unlockRequests = 0
function APR:StartNavigationUnlock(blockers, context)
    assert(blockers[1].id == lockedEdge.id and self:IsStepContextCurrent(context))
    unlockRequests = unlockRequests + 1
end
t:Update()
assert(unlockRequests == 1, "A failed plan requests quest guidance for the original authored step")
assert(t.nav.state == "no_path" and t.nav.blockers[1].id == lockedEdge.id and not t.arrowActive)
local displayed
for _, row in pairs(t.rows) do displayed = displayed or row.text == "Missing quest 84957" end
assert(displayed, "A failed plan retains and renders its gate diagnostic after cancellation")
assert(not t.rows[t.nav.ErrorStepKey .. "-3"].presentation
    and t.rows[t.nav.NavigationDividerStepKey].divider, "Blocked routes use a separator without an enclosure")
t.nav.state = "waiting_data"
t.nav:Render()
displayed = false
for _, row in pairs(t.rows) do
    displayed = displayed or row.text == "NAVIGATION_WAITING\n\nMissing quest 84957"
end
assert(displayed, "Pending client data remains separate from the access requirements")
assert(not t.rows[t.nav.NavigationStepKey .. "-0"].presentation
    and t.rows[t.nav.NavigationDividerStepKey].divider, "Pending access diagnostics use the same separator")
t.nav:Cancel("cleared")
assert(not t.nav.blockers and not t:HasError(), "Cancellation clears stale prerequisite diagnostics")

-- Drive the real loading-event retries as well as the controller: even the
-- geometry invalidation performed by that handler must not rebuild the trip.
t = plannedTransition("item")
cached, builds = t.nav.queue, t.builds
t.position, t.usable = t.landing, false
function APR:GetSettingsProfile() return self.settings.profile end
function APR:RefreshLevelProfileTargets() end
function APR:InvalidatePlayerZoneCache()
    self.navigationGeometryRevision = (self.navigationGeometryRevision or 0) + 1
end
function APR:ScheduleDelveRouteRefresh() end
function APR:StartPerformanceSample() end
function APR:FinishPerformanceSample() end
dofile("APR-Core/core/Event.lua")
function APR.event:QueueStepRefresh() end
for _ = 1, 2 do
    APR.event.functions.zone("PLAYER_ENTERING_WORLD")
    local retries = t.nav._pewRetryTimers
    for _, timer in ipairs(retries) do if not timer.cancelled then timer.callback() end end
    assert(t.nav.queue == cached and t.nav:GetActiveStep().kind == "walk"
        and t.builds == builds and not t.nav.search,
        "Native loading-event retries resume the cached itinerary after fresh geometry detection")
end
assert(t.nav.continuationReuses == 2 and APRData.p.r == 1)
print("Precomputed continuation: spell/item/portal landings, loading, event order, native retries, invalid arrivals and live future gates passed")
