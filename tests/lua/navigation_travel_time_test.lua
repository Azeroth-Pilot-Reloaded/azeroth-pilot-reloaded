-- Exercise APR's dispatch as well as the engine: an access-only route can look
-- valid while ignoring a personal shortcut to its distant departure point.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local function point(world, map, x)
    return { instanceID = world, uiMapID = map, x = x, y = 0 }
end
for _, map in ipairs({ 101, 102, 201 }) do
    fixture.maps[map] = { mapID = map, mapType = 3, parentMapID = map == 201 and 13 or 12 }
end
fixture.currentMap, fixture.spells[10] = 101, true
local landing, departure, arrival, goal = point(1, 102, 5800), point(1, 102, 6000),
    point(2, 201, 0), point(2, 201, 600)
local data = fixture:Load({ config = { actionLoadingSeconds = 5 }, connections = {
    { id = "city-crossing", kind = "portal", from = departure, to = arrival, seconds = 5 },
    { id = "personal-city", kind = "spell", from = { dynamic = "player" }, to = landing,
        actions = { { type = "spell", id = 10 } } },
    { id = "personal-item", kind = "item", from = { dynamic = "player" }, to = point(1, 102, 5990),
        actions = { { type = "item", id = 20, consumable = true } } },
} })
local nativeAdapter = APR.NavigationAdapter
data.env.getActionCastSeconds = function(kind) return kind == "spell" and 3 or 1 end

local function noop() end
local timers, start, speed = {}, point(1, 101, 0), 10
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetMoney() return 0 end
APR.PlayerID, APR.ActiveRoute, APR.RouteQuestStepList = "fixture-player", "fixture-route", {}
APR.settings = { profile = { enableAddon = true } }
APR.currentStep = { AddQuestSteps = noop, AddQuestDivider = noop, AddStepButton = noop }
APR.Arrow, APR.event, APR.SendMessage = { SetCoord = noop }, { QueueStepRefresh = noop }, noop
APR.GAME_VERSIONS = { Forever = "forever" }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
local step = { Zone = 201, Coord = { x = 0, y = goal.x, mapID = 201, instanceID = 2 } }
APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 1 } }
function APR:GetCurrentStep() return step, 1, { step } end
function APR:GetCurrentRouteMapIDsAndName() return { 201 }, 201 end
function APR:GetStepCoord(current) return current.Coord, current.Zone end
function APR:GetPreferredStepZone(current) return current.Zone end
function APR:CheckNavigationZoneReady() return false end
function APR:GetNavigationPlayerPosition() return data:NormalizeLocation(start) end
APR.NavigationAdapter = { CreatePreparation = function() return { Step = function() return "ready" end } end }
APR.taxiData = { BuildEdges = function() return {} end }
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
function nav:GetMovementSpeed() return speed end

local function plan()
    nav:Cancel("cleared")
    nav:ForceRefresh()
    nav:Update()
    local slices = 0
    while nav.search do
        local timer = table.remove(timers, 1)
        assert(timer, "Planning must remain scheduled")
        if not timer.cancelled then timer.callback() end
        slices = slices + 1
        assert(slices < 200, "The small comparison graph must finish with bounded work")
    end
    assert(nav:IsNavigating())
    return nav:GetActiveStep(), nav.totalSeconds
end
local active, seconds = plan()
assert(active.kind == "spell" and active.action.data == 10 and seconds == 93,
    "The complete journey must prefer an 8-second teleport over a 600-second approach")

-- The same physical route wins near its departure; no blanket teleport bias.
start = point(1, 102, 5950)
active, seconds = plan()
assert(active.kind == "walk" and seconds == 70,
    "Nearby travel beats a teleport after charging cast, loading and both walking legs")

-- Faster movement changes the boundary without changing action weights.
start, speed = point(1, 101, 0), 1000
active, seconds = plan()
assert(active.kind == "walk" and math.abs(seconds - 11.6) < 0.000001)
speed = 10
fixture.spells[10] = nil
active, seconds = plan()
assert(active.kind == "walk" and seconds == 665,
    "An unavailable spell cannot replace valid physical travel")

fixture.spells[10], fixture.items[20] = true, 1
active, seconds = plan()
assert(active.kind == "item" and active.action.data == 20 and seconds == 72,
    "An owned usable item competes by complete duration with both walking and spells")
fixture.items[20] = nil
active, seconds = plan()
assert(active.kind == "spell" and seconds == 93, "Removing an item restores the best available spell")
assert(APRData[APR.PlayerID][APR.ActiveRoute] == 1, "Travel choices cannot advance the authored guide")

-- Use the real adapter event handler and real access-region checks too. Generic
-- inventory/log updates after a native world event cannot erase its signal.
start, fixture.currentMap = point(1, 101, 0), 101
plan()
local cached, builds = nav.queue, 0
local createBuild = data.CreateEdgeBuild
function data:CreateEdgeBuild(context) builds = builds + 1; return createBuild(self, context) end
nav:GetActiveStep().actionCommittedUntil = fixture.time + 30
start = point(1, 101, 5800)
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "PLAYER_ENTERING_WORLD")
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "QUEST_LOG_UPDATE")
nav:Update()
assert(nav.queue == cached and builds == 0 and not nav.search, "The native adapter preserves a casting/loading itinerary")
start, fixture.currentMap = point(1, 102, 5800), 102
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "BAG_UPDATE_DELAYED")
nav:Update()
assert(nav.queue == cached and nav:GetActiveStep().kind == "walk" and builds == 0 and not nav.search
    and nav.lastContinuation.status == "reused", "Native adapter events and real geography resume the cached trip")
local discarded = false
nav.search = { Cancel = function() discarded = true end }
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "PLAYER_HOUSE_LIST_UPDATED", {})
assert(nav.queue == cached and nav:GetActiveStep().kind == "walk" and discarded and not nav.search,
    "A house-list refresh discards a candidate without deleting published travel that does not use housing")

-- A returning client can expose the destination continent before its city.
-- Use real geography and native adapter notifications, without live catalog IDs.
local function fromSeparateWorld()
    start, fixture.currentMap = point(9, 101, 0), 101
    plan()
    builds = 0
    return nav.queue
end
cached = fromSeparateWorld()
local expectedSteps = #cached
nav:BeginWorldLoading("PLAYER_LEAVING_WORLD")
nav:BeginWorldLoading("LOADING_SCREEN_ENABLED")
start, fixture.currentMap = point(1, 12, 5800.04), 12
nav:EndWorldLoading("PLAYER_ENTERING_WORLD")
nav:EndWorldLoading("LOADING_SCREEN_DISABLED")
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "QUEST_LOG_UPDATE")
nav:Update()
assert(nav.queue == cached and #nav.queue == expectedSteps and nav.cursor == 2
    and nav:GetActiveStep().kind == "walk" and builds == 0 and not nav.search,
    "A matching world/position and proven outdoor access must resume despite a continent-only map")
assert(nav.lastContinuation.reason == "parent_map_arrival")
local resumedCursor = nav.cursor
APR.navigationGeometryRevision = (APR.navigationGeometryRevision or 0) + 1
start, fixture.currentMap = point(1, 102, 5800.04), 102
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "QUEST_LOG_UPDATE")
nativeAdapter.frame.OnEvent(nativeAdapter.frame, "BAG_UPDATE_DELAYED")
nav:Update()
assert(nav.queue == cached and nav.cursor == resumedCursor and builds == 0 and not nav.search
    and nav._routeInputs.position.uiMapID == 102,
    "Refining the continent to the city rebases observations without replanning or skipping the next leg")

fixture.maps[103] = { mapID = 103, mapType = 3, parentMapID = 12 }
for _, mismatch in ipairs({ "continent", "sibling", "world", "distance", "floor", "access" }) do
    fromSeparateWorld()
    start, fixture.currentMap = point(1, 12, 5800.04), 12
    if mismatch == "continent" then start.uiMapID = 13 end
    if mismatch == "sibling" then start.uiMapID = 103 end
    if mismatch == "world" then start.instanceID = 2 end
    if mismatch == "distance" then start.x = 6800 end
    if mismatch == "floor" then start.floor = "lower" end
    if mismatch == "access" then start.accessKey = "private" end
    fixture.currentMap = start.uiMapID
    nav:ForceRefresh("world_transition"); nav:Update()
    assert(nav.search or builds > 0, "Coarse arrival cannot conceal a different " .. mismatch)
end

-- A parent map alone cannot prove entry into an isolated child/interior.
data.config.IsolatedAreas = { [102] = "sealed" }
data:InvalidatePositionCache()
cached = fromSeparateWorld()
start, fixture.currentMap = point(1, 12, 5800.04), 12
nav:ForceRefresh("world_transition"); nav:Update()
assert(nav.queue == cached and nav.cursor == 1 and nav:GetActiveStep().kind == "spell" and builds == 0,
    "Matching XY on a parent continent is insufficient evidence for a restricted interior")
start, fixture.currentMap = point(1, 102, 5800.04), 102
nav:Update()
assert(nav.queue == cached and nav:GetActiveStep().kind == "walk" and builds == 0,
    "A precise native interior arrival supplies the missing access evidence")

-- Exiting housing is a native local action, not a world-graph comparison.
-- Unknown return coordinates do not prevent displaying its secure button.
data.config.HousingMaps = { [102] = true }
data:InvalidatePositionCache()
local canReturn = true
C_HousingNeighborhood = { CanReturnAfterVisitingHouse = function() return canReturn end }
nativeAdapter:GetCharacterSettings().housingExitLocation = nil
start, fixture.currentMap, builds = point(5, 102, 200), 102, 0
active = plan()
assert(active.kind == "housing_return" and active.action.type == "housing_return"
    and active.exitHousing and active.to == nil and builds == 0 and not nav.search,
    "A usable native housing return is shown immediately without inventing its destination")
cached = nav.queue
for _ = 1, 20 do
    APR.navigationGeometryRevision = (APR.navigationGeometryRevision or 0) + 1
    nativeAdapter.frame.OnEvent(nativeAdapter.frame, "NEIGHBORHOOD_MAP_DATA_UPDATED")
    nav:Update(); nav:PollArrival()
end
assert(nav.queue == cached and builds == 0 and not nav.search,
    "Neighborhood data bursts cannot trigger world searches while the direct exit is offered")
canReturn = nil
nav:ForceRefresh("housing_availability_changed"); nav:Update()
do
    local slices = 0
    while nav.search do
        local timer = table.remove(timers, 1)
        assert(timer)
        if not timer.cancelled then timer.callback() end
        slices = slices + 1; assert(slices < 200)
    end
end
assert(nav:GetActiveStep().kind ~= "housing_return" and builds > 0,
    "An unconfirmed escape prefix cannot beat a usable complete trip with an invented zero cost")
canReturn = true

-- A housing objective stays local; merely owning unrelated housing quests
-- cannot change the outside objective used by this controlled route.
step.Zone, step.Coord.mapID, step.Coord.instanceID, step.Coord.y = 102, 102, 5, 500
builds = 0
active = plan()
assert(active.kind == "walk" and builds > 0, "An objective in housing must not be sent outside")
step.Zone, step.Coord.mapID, step.Coord.instanceID, step.Coord.y = 201, 201, 2, 600
for _, availability in ipairs({ false, "unknown" }) do
    canReturn = false
    if availability == "unknown" then canReturn = nil end
    builds = 0
    active = plan()
    assert(active.kind ~= "housing_return" and builds > 0,
        "An unavailable native return falls back to the ordinary usable transports")
end
canReturn, builds = true, 0
active = plan()
assert(active.exitHousing and builds == 0)
-- A continent-only map inside the same housing world is not an exit.
start, fixture.currentMap = point(5, 12, 200), 12
nav:PollArrival()
assert(nav:GetActiveStep() == active, "A coarse map observation cannot complete housing departure")
start, fixture.currentMap = point(1, 101, 300), 101
nav:PollArrival()
assert(not nav:GetActiveStep() and nav.dirty and APRData[APR.PlayerID][APR.ActiveRoute] == 1,
    "Actual housing departure requests the outside journey without completing the authored objective")
print("Housing exit: immediate native return, no invented destination, no neighborhood-triggered global builds and local-goal/unavailable fallbacks passed")
print("Parent-map arrivals: proven outdoor continuation, city refinement, wrong maps/worlds/access and isolated-child evidence passed")
print("APR travel time: distant and nearby approaches, cast/loading/arrival costs, movement speed and unavailable/owned actions passed")
