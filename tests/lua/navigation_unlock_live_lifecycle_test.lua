-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Map/UI readers use the real RouteUtils getter in the client. It must not
-- restore a SavedVariables checkpoint over an already active native session.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load(dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local completed, active, timers, rows = { [13] = true }, {}, {}, {}
data.env.isQuestAvailable = function() return nil end
data.env.isQuestCompleted = function(id) return completed[id] == true end
data.env.isQuestActive = function(id) return active[id] == true end
data.env.isQuestCompletedOnAccount = function() return false end
data.env.getCharacter = function() return { level = 90, faction = "Horde", class = "PALADIN", mapID = 101 } end
local function noop() end
function debugprofilestop() return 0 end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function InCombatLockdown() return false end
function IsFlyableArea() return false end
function GetMoney() return 0 end
APR.PlayerID, APR.ActiveRoute = "live", "fixture-parent-guide"
local route = APR.ActiveRoute
local original = { Zone = 104, Waypoint = 1, NonSkippableWaypoint = true,
    Coord = { x = -515.6, y = -1343, mapID = 104, instanceID = 3 } }
local definition = { label = route, expansion = "Custom", steps = { [8] = original } }
APRData, APRCustomPath = { live = { [route] = 8 } }, { live = { route } }
APR.RouteQuestStepList = { [route] = definition }
APR.settings = { profile = { enableAddon = true } }
APR.SendMessage = noop
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
APR.GAME_VERSIONS = { Forever = "forever" }
dofile("APR-Core/utils/RouteUtils.lua")
function APR:GetPrimaryCustomPathRouteKey() return APRCustomPath.live[1] and route end
function APR:GetRouteData(key) return key == route and definition or nil end
function APR:GetRouteSteps(key) return key == route and definition.steps or {} end
function APR:IsTemporaryRoute() return false end
function APR:GetRouteMapIDsAndName() return { 104 }, 104, route, "Custom" end
function APR:GetCurrentStep() return original, 8, definition.steps end
function APR:PeekCurrentStep() return original end
function APR:GetStepCoord(step) return step.Coord, step.Zone end
function APR:GetPreferredStepZone(step) return step.Zone end
function APR:CheckNavigationZoneReady() return true end
function APR:GetNavigationPlayerPosition() return { x = 2922.4, y = -2407.6, uiMapID = 101, instanceID = 1 } end
function APR:ActivateTemporaryRoute() error("Unlocks cannot activate an APR temporary route") end
dofile("APR-Core/features/questing/StepTransitions.lua")
local mapReads = 0
local function readMaps()
    local _, map, key = APR:GetCurrentRouteMapIDsAndName()
    assert(map == 104 and key == route)
    mapReads = mapReads + 1
end
APR.Arrow = { SetCoord = readMaps, SetArrowActive = noop }
APR.event = { QueueStepRefresh = readMaps }
APR.currentStep = {
    AddQuestSteps = function(_, _, text) rows[#rows + 1] = text; readMaps() end,
    AddQuestDivider = noop, AddStepButton = noop,
}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
APR.NavigationEngine = LibStub("LibAPRNavigation-1.0").Engine
APR.taxiData = { BuildEdges = function() return {}, {} end }
function data:CreateEdgeBuild() return { Step = function() return "ready", {}, { resources = {} } end } end
function data:CanWalk(a, b) return a.uiMapID == b.uiMapID end
function data:GetWalkingSpeed(_, speed) return speed end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/NavigationUnlocks.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
nav.destination = { x = -1343, y = -515.6, uiMapID = 104, instanceID = 3 }
local blocker = { id = "karesh-live", from = { uiMapID = 101 }, blockedRequirements = {
    minLevel = 80, any = { { quest = 12 }, { questActive = 12 } },
} }
local context = APR:CaptureStepContext()
nav.context = context
APRData.live.NavigationUnlockAttempts = { route = route, index = 8, edges = { [blocker.id] = true } }
nav:SearchFailed({ blocker })
assert(APR._navigationUnlock and not APRData.live.NavigationUnlockAttempts,
    "A real no_path result starts the unlock automatically despite an orphaned historical attempt")
local state, session = APR._navigationUnlock, APR._navigationUnlock.session
local function drain()
    for _ = 1, 10000 do
        readMaps()
        assert(APR._navigationUnlock == state and state.session == session,
            "Ordinary route-map reads cannot replace an active native unlock session")
        local timer = table.remove(timers, 1)
        if not timer then return end
        if not timer.cancelled then timer.callback() end
    end
    error("Map readers repeatedly restarted native unlock planning")
end
drain()
local step = assert(APR:GetNavigationUnlockStep())
assert(step.unlockAction.kind == "accept" and step.unlockAction.questID == 11)
assert(nav:IsNavigating() and nav:GetActiveStep().kind == "unlock" and #rows > 0)
local signature, cursor = state.signature, session.cursor
for _ = 1, 25 do readMaps() end
assert(state.step == step and state.signature == signature and session.cursor == cursor)
assert(APRData.live[route] == 8 and APR.ActiveRoute == route and mapReads > 25)

-- A reload still restores the saved session once. Subsequent map readers
-- preserve that new session and the original route/step context.
APR._navigationUnlock = nil
readMaps()
state, session = APR._navigationUnlock, APR._navigationUnlock.session
assert(state and session)
for _ = 1, 25 do readMaps(); assert(APR._navigationUnlock == state and state.session == session) end
nav:Update(); drain()
assert(APR:GetNavigationUnlockStep().unlockAction.questID == 11)
assert(nav:IsNavigating() and APRData.live[route] == 8)
APR.stepRevision = (APR.stepRevision or 0) + 1
readMaps()
assert(not APR._navigationUnlock and not APRData.live.NavigationUnlockState,
    "Idempotent restoration still cancels a session when its real step context becomes stale")

-- Exercise the same notification as both route-browser removal actions, with
-- the real route resolver, transition invalidation and navigation controller.
local handlers = {}
dofile("APR-Core/config/Config_Route.lua")
function APR.routeconfig:RegisterMessage(name, callback) handlers[name] = callback end
function APR.routeconfig:SendMessage(name) handlers[name]() end
APR.routeconfig.SchedulePathUiRefresh = noop
APR.routeconfig:InitRouteConfig()
APR.Buff = { RemoveAllBuffIcon = noop }
APR.XPBuffOverlay = { QueueRefresh = noop }
APR.Debug, APR.UpdateMapId, APR.UpdateStep = noop, noop, noop
function APR:GetSettingsProfile() return self.settings.profile end
APR.InvalidatePlayerZoneCache = noop
local arrowActive
APR.Arrow.SetArrowActive = function(_, value) arrowActive = value end
APR.currentStep.pendingRemoval, APR.currentStep.questsList = {}, {}
APR.currentStep.pendingButtonRequests = {}
function APR.currentStep:Reset() self.questsList = {} end
function APR.currentStep:FlushPendingContainers()
    for key in pairs(self.pendingRemoval) do self.questsList[key] = nil end
    self.pendingRemoval = {}
end
local addQuestSteps = APR.currentStep.AddQuestSteps
function APR.currentStep:AddQuestSteps(key, text, ...)
    self.questsList[key] = {}
    return addQuestSteps(self, key, text, ...)
end

local function startUnlock(publish)
    APRCustomPath.live = { route }
    APR:ActivateRoute(route)
    nav.context = APR:CaptureStepContext()
    nav:SearchFailed({ blocker })
    state = assert(APR._navigationUnlock)
    session = state.session
    if publish then
        drain()
        assert(nav:GetActiveStep().kind == "unlock" and next(APR.currentStep.questsList))
    else
        local ticks = 0
        debugprofilestop = function() ticks = ticks + 2; return ticks end
        nav:Update()
        assert(state.timer, "The unlock planner must have a pending cooperative slice")
        debugprofilestop = function() return 0 end
    end
end

local function removePath(clearAll, simulateReload)
    local oldContext, oldGeneration = APR:CaptureStepContext(), nav.generation
    if simulateReload then APR._navigationUnlock = nil end
    if clearAll then APRCustomPath.live = {} else table.remove(APRCustomPath.live, 1) end
    APR.routeconfig:SendCustomPathUpdate()
    assert(APR.ActiveRoute == nil, "Removing the final route must deactivate it")
    assert(not APR._navigationUnlock and not APRData.live.NavigationUnlockState,
        "Removing the final route must discard live and saved unlock guidance")
    assert(not nav:GetActiveStep() and not nav:IsNavigating() and not nav.search and arrowActive == false)
    assert(not next(APR.currentStep.questsList) and not next(APR.currentStep.pendingButtonRequests))
    -- Even callbacks already dispatched when cancellation occurs cannot publish.
    for _ = 1, 100 do
        local timer = table.remove(timers, 1)
        if not timer then break end
        timer.callback()
    end
    assert(#timers == 0, "An empty path must not keep scheduling navigation work")
    nav:Publish({ steps = { { kind = "walk" } } }, oldContext, oldGeneration)
    APR:RestoreNavigationUnlockRoute()
    assert(APR.ActiveRoute == nil and not APR:GetNavigationUnlockStep() and not nav:GetActiveStep())
    assert(not APR._navigationUnlock and not APRData.live.NavigationUnlockState)
    assert(APRData.live[route] == 8, "Deselecting a route preserves authored progress")
end

startUnlock(true); removePath(false)
startUnlock(true); removePath(true)
startUnlock(false); removePath(true)
startUnlock(true); removePath(true, true)
print("Live unlock lifecycle: real route-map getter/UI readers preserve planning and published action; reload restores once")
print("Route removal: last entry, clear all, pending planner and saved checkpoint discard orphaned guidance")
