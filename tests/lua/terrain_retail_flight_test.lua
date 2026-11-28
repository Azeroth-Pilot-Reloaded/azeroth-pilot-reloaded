local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")

function GetBuildInfo() return "99.0.0", "1", nil, 990000 end
assert(lib:MatchesGeneratedTerrain("retail", "99.0.0.1"))
local data = F.map()
local heights = {}
for x = 0, 7 do
    for y = 0, 7 do
        local z = x == 3 and y == 3 and 22 or 0
        heights[#heights + 1] = "v" .. F.number(2048 + z, 2)
    end
end
data.height[1] = table.concat(heights)
lib:RegisterTerrainData("retail", 900, data, 1)
local instance = setmetatable({ profile = "retail", env = {} }, lib.Instance)
local provider = assert(instance:GetWalkingProvider())
local start, goal = F.point(1, 3), F.point(6, 3)
local model = {
    origin = start,
    airborne = false,
    speed = 60,
    climbSpeed = 18,
    groundSpeedCeiling = 7,
    groundSpeedFor = function() return 7 end,
    canFly = function(_, to) return not to.noFlight end,
}
local options = { flight = model, walkSpeed = 60, walkingGoalXY = true }
local function path(a, b)
    local status, result = F.finish(provider:CreatePathJob(a or start, b or goal, options), 1)
    assert(status == "ready")
    return result
end

local detour = path()
assert(#detour.path == 3 and detour.path.flight.climb == 12)
assert(math.abs(detour.path[2].y - start.y) >= 50)
assert(detour.seconds < 2 + 5 * F.cellSize / 60 + 34 / 18,
    "Lateral flight is faster than climbing over the ridge from the ground")

model.airborne = true
local direct = path()
assert(#direct.path == 2 and direct.path.flight.climb == 4)
F.near(direct.seconds, 5 * F.cellSize / 60 + 4 / 18)
assert(direct.path[1].z == nil and start.z == nil, "An estimated altitude cannot become player position")

local far = F.point(9, 3)
assert(path(start, far).path.flight.estimated, "Missing tiles preserve an authorized flight estimate")
local status, costs = F.finish(provider:CreateCostJob(start, {goal}, options), 1)
assert(status == "ready" and costs.costs[1].state == "ready")
F.near(costs.costs[1].seconds, direct.seconds)

goal.noFlight = true
local walk = path()
assert(not walk.path.flight and walk.seconds >= 5 * F.cellSize / 7,
    "Flight restrictions use the shared ground path and ground speed")
goal.noFlight = nil

local function itinerary(airborne)
    model.airborne = airborne
    local state, result = F.finish(lib.Engine:CreateSearch({
        start = start, goal = goal, walkingProvider = provider, flight = model,
        walkSpeed = 60, walkingGoalXY = true, walkingSpeedCeiling = 60, batchTerrainWork = true,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        edges = {{ id = "mountain-boat", kind = "boat", from = start, to = goal, seconds = 7, copper = 0 }},
    }), 64)
    assert(state == "ready" and #result.segments == 1)
    return result.segments[1]
end
assert(itinerary(false).id == "mountain-boat", "Ground departure makes the boat competitive")
assert(itinerary(true).path.flight.climb == 4, "Airborne departure makes overflight competitive")

-- Reaching this interior takes longer than flying to the goal, even if
-- the onward transport is instantaneous. Avoid computing its ground path.
local interiorEntrance = F.point(4, 3, 0)
interiorEntrance.indoors = true
local createPath = provider.CreatePathJob
function provider:CreatePathJob(from, to, context)
    assert(to ~= interiorEntrance, "A ground-only detour that cannot win needs no terrain query")
    return createPath(self, from, to, context)
end
model.airborne = false
local arrivalState, arrival = F.finish(lib.Engine:CreateSearch({
    start = start, goal = goal, walkingProvider = provider, flight = model,
    walkSpeed = 60, walkingGoalXY = true, walkingSpeedCeiling = 60, batchTerrainWork = true,
    edges = {{ kind = "portal", from = interiorEntrance, to = goal, seconds = 0 }},
    canWalk = function() return true end,
}), 64)
provider.CreatePathJob = nil
assert(arrivalState == "ready" and #arrival.segments == 1 and arrival.segments[1].path.flight)
F.near(arrival.totalSeconds, detour.seconds)

local locale = LibStub:NewLibrary("AceLocale-3.0", 1)
function locale:GetLocale() return {} end
local position, airborne, flyable = start, false, true
local context = {}
APR = {
    ActiveRoute = "synthetic", settings = { profile = { enableAddon = true } },
    GAME_VERSIONS = { Forever = "forever" }, NavigationData = instance,
}
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetNavigationPlayerPosition() return position end
function IsFlyableArea() return flyable end
function IsIndoors() return false end
function IsFlying() return airborne end
function GetUnitSpeed() return 0, 7, 28 end
C_PlayerInfo = { GetGlidingInfo = function() return airborne, true end }
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
function instance:IsSameAccessRegion(a, b) return a.instanceID == b.instanceID end
function instance:GetWalkingSpeed(point, travel, ground) return point.uiMapID == 901 and ground or travel end
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
local _, _, _, _, flight = nav:GetWalkingSpeedModel(start)
assert(flight and not flight.airborne and flight.speed == 60)
assert(not flight.canFly(start, { uiMapID = 901 }), "A known ground-only destination disables flight")
flyable = false
local _, _, _, _, prohibited = nav:GetWalkingSpeedModel(start)
assert(not prohibited, "Native no-fly areas disable flight even with a usable mount")
airborne = true
function IsMounted() return true end
function GetUnitSpeed() return 55, 7, 28 end
local restrictedSpeed = nav:GetWalkingSpeedModel(start)
assert(restrictedSpeed <= 14, "Airborne movement cannot price a ground-only segment")
airborne = false
flyable = true

local row = nav:PrepareGuidanceStep({ kind = "walk", from = start, to = goal, path = detour.path }, 1, 1, start)
nav.queue, nav.cursor, nav.state, nav.context = { row }, 1, "guiding", context
function nav:Notify() end
function nav:MarkRouteReady() self.state = "ready" end
assert(nav:GetGuidanceTarget() == detour.path[2])
airborne, position = true, detour.path[2]
nav:PollArrival()
assert(nav:GetGuidanceTarget() == detour.path[3])
position = goal
nav:PollArrival()
assert(nav.state == "guiding", "Overflying the goal must not complete a ground arrival")
airborne = false
nav:PollArrival()
assert(nav.state == "ready" and nav.cursor == 2, "Landing advances flight guidance without a player Z")

-- A covered world transition has a straight ground corridor under its roof.
-- Landing at the transition XY would put the player on the wrong surface.
local tunnel = F.map()
local roof = {}
for x = 5, 7 do
    for y = 0, 7 do
        roof[#roof + 1] = F.number(x * tunnel.cells + y, 3) .. "BB" .. F.number(2100, 2) .. "AA"
    end
end
tunnel.floor[1] = F.number(#roof, 3) .. table.concat(roof) .. "AAA"
lib:RegisterTerrainData("retail", 900, tunnel, 2)
lib:RegisterTerrainData("retail", 901, F.map(), 1)
local trigger, inside, endPoint = F.point(6, 3, 0), F.point(1, 3, 0), F.point(4, 3, 0)
inside.instanceID, endPoint.instanceID = 901, 901
inside.indoors, endPoint.indoors = true, true

local function passageRoute(destination, edges)
    return F.finish(lib.Engine:CreateSearch({
        start = start, goal = destination, walkingProvider = provider, flight = model,
        walkSpeed = 60, walkingSpeedCeiling = 60, batchTerrainWork = true, previewEntryWalk = true,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        edges = edges,
    }), 64)
end
local unchanged, ordinary = passageRoute(trigger, {})
assert(unchanged == "ready" and #ordinary.segments == 1 and not ordinary.segments[1].path.flight,
    "An arbitrary lower floor is not a flight landing")

local crossing = { id = "covered-transition", kind = "passage", from = trigger, to = inside, seconds = 3 }
local state, journey = passageRoute(endPoint, { crossing })
assert(state == "ready" and #journey.segments == 4)
local approach, tunnelWalk, passage, interiorWalk = unpack(journey.segments)
assert(approach.path.flight and not approach.path.flight.groundPath and approach.to == tunnelWalk.from)
assert(approach.to.x >= 4 * F.cellSize and approach.to.x < 5 * F.cellSize and approach.to.z == 0,
    "Land on the exposed path at the mouth of the tunnel")
assert(not tunnelWalk.path.flight and tunnelWalk.to == trigger and passage.id == crossing.id)
assert(not interiorWalk.path.flight and interiorWalk.from == inside and interiorWalk.to == endPoint)
assert(journey.totalSeconds < 8 * F.cellSize / 7 + crossing.seconds)
F.near(journey.totalSeconds, approach.seconds + tunnelWalk.seconds + crossing.seconds + interiorWalk.seconds)

model.airborne, start.z = true, 120
local airborneState, airborneJourney = passageRoute(endPoint, { crossing })
assert(airborneState == "ready" and airborneJourney.segments[1].path.flight and start.z == 120,
    "Replanning in the air uses a ground projection without changing the player observation")
model.airborne, start.z = false, nil

nav.queue = { nav:PrepareGuidanceStep(approach, 1, 2, start), nav:PrepareGuidanceStep(tunnelWalk, 2, 2, start) }
nav.cursor, nav.state, position = 1, "guiding", approach.to
airborne = true
nav:PollArrival()
assert(nav.cursor == 1, "Flying over the mouth keeps flight guidance active")
airborne = false
position = { x = approach.to.x, y = approach.to.y, z = 52, instanceID = approach.to.instanceID }
nav:PollArrival()
assert(nav.cursor == 1, "Landing at the wrong height cannot start the tunnel corridor")
position = approach.to
nav:PollArrival()
assert(nav.cursor == 2 and nav:GetGuidanceTarget() == tunnelWalk.path[2],
    "Landing at the mouth starts ground guidance")

-- An indoor portal landing must walk under the roof before taking off.
local interior = F.map()
roof = {}
for x = 0, 1 do
    for y = 0, 7 do
        roof[#roof + 1] = F.number(x * interior.cells + y, 3) .. "BB" .. F.number(2100, 2) .. "AA"
    end
end
interior.floor[1] = F.number(#roof, 3) .. table.concat(roof) .. "AAA"
interior.class[1] = string.rep("E", 16) .. string.rep("A", 48)
lib:RegisterTerrainData("retail", 901, interior, 2)
local outdoorGoal = F.point(7, 3, 0)
outdoorGoal.instanceID = 901
local portal = { id = "indoor-landing", kind = "portal", from = start, to = inside, seconds = 5 }
local exitState, exitJourney = passageRoute(outdoorGoal, { portal })
assert(exitState == "ready" and #exitJourney.segments == 3)
local transport, exitWalk, onward = unpack(exitJourney.segments)
assert(transport.id == portal.id and exitWalk.from.indoors and not exitWalk.path.flight)
assert(exitWalk.to == onward.from and exitWalk.to.x >= 2 * F.cellSize and exitWalk.to.z == 0,
    "The takeoff must be outside the roof and on the same floor as the ground approach")
assert(onward.path.flight and not onward.path.flight.groundBefore and onward.to == outdoorGoal)
F.near(exitJourney.totalSeconds, transport.seconds + exitWalk.seconds + onward.seconds)
assert(exitJourney.totalSeconds < transport.seconds + 6 * F.cellSize / 7)

print("Retail terrain: flight pricing, ground restrictions, covered entrances and landing guidance passed")
