-- A nearby objective separated by terrain must follow its walking corridor.
local function noop() end
local x, y, z, floor, now, version = 0, 0, 0, nil, 10, "forever"
local timers, request, pending, plannedStatus = {}, nil, true, "ready"
function GetTime() return now end
function UnitPosition() return x, y, z, 0 end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetMoney() return 0 end
function IsIndoors() return false end
function CreateFrame() return {RegisterEvent = noop, SetScript = noop} end
function LibStub() return {GetLocale = function() return setmetatable({}, {__index = function(_, k) return k end}) end} end
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
C_Map = {GetBestMapForUnit = function() return 1 end}
local authored = {PickUp = {901}, Zone = 1, Range = 3, Coord = {x = 0, y = 10, instanceID = 0, mapID = 1}}
APR = {PlayerID = "p", ActiveRoute = "r", stepRevision = 0,
    RouteQuestStepList = {r = {steps = {authored}, mapID = 1}},
    settings = {profile = {enableAddon = true}}, GAME_VERSIONS = {Forever = "forever"},
    currentStep = {AddQuestSteps = noop}, Arrow = {SetCoord = noop}, SendMessage = noop}
APRData = {p = {r = 1}}
function APR:NewModule() return {} end
function APR:GetGameVersion() return version end
function APR:GetCurrentStep() return authored, 1, self.RouteQuestStepList.r.steps end
function APR:GetCurrentRouteMapIDsAndName() return {1}, 1 end
function APR:GetStepCoord(step) return step.Coord, 1 end
function APR:GetPreferredStepZone() return 1 end
function APR:CheckNavigationZoneReady() return true end
function APR:GetNavigationPlayerPosition() return {x = x, y = y, z = z, floor = floor, instanceID = 0, uiMapID = 1} end
dofile("APR-Core/features/questing/StepTransitions.lua")
local covered, expose = true, true
local provider = {HasMap = function(_, map) return covered and map == 0 end}
APR.NavigationData = {GetWalkingProvider = function() return expose and provider or nil end,
    CanWalk = function() return true end,
    IsSameAccessRegion = function(_, a, b) return a.floor == b.floor end}
local path = {{x=0,y=0,z=0,instanceID=0,uiMapID=1}, {x=0,y=40,z=0,instanceID=0,uiMapID=1},
    {x=10,y=40,z=0,instanceID=0,uiMapID=1}, {x=10,y=0,z=0,instanceID=0,uiMapID=1}}
APR.NavigationPlanner = {Create = function(_, incoming)
    request = incoming
    return {request = incoming, Cancel = noop, Step = function()
        if pending then return "planning" end
        if plannedStatus ~= "ready" then return plannedStatus end
        return "ready", {segments = {{kind="walk", from=incoming.start, to=incoming.goal, path=path, seconds=90/7}}, totalSeconds=90/7}
    end}
end}
dofile("APR-Core/features/navigation/Preview.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
local function finish()
    pending = false
    while nav.search do
        local timer = table.remove(timers, 1)
        assert(timer, "Planning must schedule bounded continuations")
        if not timer.cancelled then timer.callback() end
    end
end
nav:Update()
assert(request.walkingProvider == provider, "The controller must pass the optional walking provider to planning")
assert(nav.state == "planning" and not nav.recomputeKeepingDirect, "Near objectives cannot seed an unverified direct route")
finish()
assert(nav:IsNavigating(), "A single terrain walking segment must survive zone-ready publication")
local leg = nav:GetActiveStep()
assert(leg.to.x == 10 and leg.to.y == 0 and leg.Coord.x == 0 and leg.Coord.y == 10, "The original final endpoint stays independent of corridor targets")
local target = nav:GetGuidanceTarget()
assert(target.x == 0 and target.y == 40, "The arrow must first target the corridor turn")
assert(math.abs(nav:GetRemainingSeconds() - 90/7) < 1e-8, "ETA must measure the full detour, not the ten-yard chord")
assert(nav:GetRemainingWalkYards() == 90, "Arrow distance must measure the remaining polyline")
local points = APR.navigationPreview:GetPoints()
assert(not points[1].arrival, "Walking bends must not masquerade as transport arrivals")
assert(points[1].Coord.x == 40 and points[1].Coord.y == 0 and points[2].Coord.x == 40 and points[2].Coord.y == 10,
    "The map preview must contain terrain bends in world coordinate order")
assert(APR.navigationPreview:GetPoints() == points, "Unchanged corridor preview is cached")
nav:PollArrival()
assert(nav:IsNavigating() and nav.cursor == 1, "Proximity to the final endpoint cannot skip outstanding terrain turns")
x, y, z = 0, 40, 30
nav:PollArrival()
assert(nav:GetGuidanceTarget() == target, "A stacked point with the wrong height cannot advance the corridor")
z, floor = 0, "other"
nav:PollArrival()
assert(nav:GetGuidanceTarget() == target, "A different access floor cannot advance the corridor")
floor = nil
nav:PollArrival()
assert(nav.cursor == 1 and nav:GetGuidanceTarget().x == 10, "Only the terrain cursor advances at a bend")
assert(APRData.p.r == 1 and authored.Range == 3, "Corridor progress preserves guide progress and interaction radius")
assert(nav:GetRemainingWalkYards() == 50 and math.abs(nav:GetRemainingSeconds() - 50/7) < 1e-8)
local advanced = APR.navigationPreview:GetPoints()
assert(advanced ~= points and advanced[1].Coord.y == 10, "Cursor movement invalidates shared map geometry")
x, y = 10, 40
nav:PollArrival()
x, y = 10, 0
nav:PollArrival()
assert(nav.state == "ready" and APRData.p.r == 1, "Finishing terrain guidance hands back the unchanged authored objective")
assert(path[1].x == 0 and path[2].y == 40 and #path == 4, "Guidance never mutates provider geometry")

nav:Cancel("cleared")
x, y, pending, plannedStatus = 0, 0, true, "no_path"
nav:Update()
local obsoleteContext, obsoleteGeneration = nav.context, nav.generation
finish()
assert(nav.state == "no_path", "A proven disconnection near the objective cannot retain a direct baseline")
nav:Cancel("cleared")
nav:Publish({segments={{kind="walk", from=path[1], to=path[4], path=path}}}, obsoleteContext, obsoleteGeneration)
assert(nav.state == "ready" and #nav.queue == 0, "A cancelled terrain callback cannot republish obsolete guidance")

local dense = {}
for index = 1, 150 do dense[index] = {x=0,y=0,z=0,instanceID=0,uiMapID=1} end
dense[#dense+1] = {x=100,y=0,z=0,instanceID=0,uiMapID=1}
nav.queue = {nav:PrepareGuidanceStep({kind="walk", from=dense[1], to=dense[#dense], path=dense}, 1, nav.generation, dense[1])}
nav.cursor, nav.state, nav.context = 1, "guiding", APR:CaptureStepContext()
nav:PollArrival()
assert(nav.queue[1].pathCursor == 66 and nav.cursor == 1, "Dense coincident points advance at most 64 nodes per poll")

-- Missing provider/coverage keeps the existing local-route seed behavior.
for _, mode in ipairs({"missing", "uncovered", "retail"}) do
    nav:Cancel("cleared")
    x, y, pending = 0, 0, true
    expose, covered, version = mode ~= "missing", mode ~= "uncovered", mode == "retail" and "retail" or "forever"
    nav:Update()
    assert(nav.state == "ready", "Uncovered and Retail journeys keep their direct baseline: " .. mode)
    if mode == "retail" or mode == "missing" then assert(request.walkingProvider == nil) end
end
nav:Cancel("cleared")

-- Join the actual scheduler/search with the controller contract as well.
expose, covered, version, x, y = true, true, "forever", 0, 0
function provider:CreateCostJob(from, targets)
    local costs = {}
    for index, target in ipairs(targets) do
        costs[index] = {state="ready", seconds=90/7, yards=90}
    end
    return {Step=function() return "ready", {costs=costs} end, Cancel=noop}
end
function provider:CreatePathJob(from, to)
    assert(from.instanceID == 0 and to.x == 10)
    return {Step=function() return "ready", {path=path, seconds=90/7, yards=90} end, Cancel=noop}
end
function APR.NavigationData:BuildEdges() return {}, {} end
APR.taxiData = {BuildEdges=function() return {}, {} end}
APR.NavigationEngine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
nav:Update()
finish()
assert(nav:IsNavigating() and nav:GetGuidanceTarget().y == 40 and math.abs(nav.totalSeconds-90/7) < 1e-8,
    "The real planner must deliver the terrain path and physical ETA to the controller for a nearby objective")
nav:Cancel("cleared")
print("Terrain guidance: provider dispatch, local bypass prevention, polyline cursor/ETA/preview, unchanged guide and Retail passed")
