local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.currentMap = 501
local data = fixture:Load({ connections = {} })
local function point(x,y) return data:NormalizeLocation({x=x,y=y,z=0,instanceID=0,uiMapID=501}) end
fixture.player = point(0,0)
APR.settings = {profile={enableAddon=true}}
APR.NewModule = function() return {} end
local context = {}
function APR:IsStepContextCurrent(value) return value == context end
function APR:CaptureStepContext() return context end
function APR:GetNavigationPlayerPosition() return fixture.player end
function APR:GetGameVersion() return "forever" end
APR.GAME_VERSIONS = { Forever="forever" }
APR.PlayerID, APR.ActiveRoute = "invented-character", "invented-route"
APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 7 } }
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
local segment = {kind="walk",terrain=true,movementMode="ground",from=point(0,0),to=point(100,100),seconds=200,
    polyline={point(0,0),point(100,0),point(100,100)}}
local row = nav:PrepareGuidanceStep(segment,1,0,fixture.player)
assert(row.terrain and row.polyline == segment.polyline, "The controller must preserve the actual terrain corridor")
assert(row.guidance, "Terrain rows require a guidance session instead of a straight arrow to the endpoint")
nav.queue, nav.cursor, nav.context, nav.state = {row},1,context,"guiding"
local notifications, replans, ready = 0,0,0
nav.Notify = function() notifications=notifications+1 end
nav.RequestUpdate = function() replans=replans+1 end
nav.ForceRefresh = function(self) self.dirty=true end
nav.MarkRouteReady = function(self) ready=ready+1;self.state="ready" end
nav:PollArrival()
assert(row.Coord.y > 0 and row.Coord.y <= 30 and row.Coord.x == 0,
    "The initial arrow must follow the first corridor rather than cut the corner")
fixture.player = point(90,0)
nav:PollArrival()
assert(row.Coord.y == 100 and row.Coord.x == 0, "Lookahead cannot point through the wall inside a corner")
fixture.player = point(100,0)
nav:PollArrival()
fixture.player = point(100,80)
nav:PollArrival()
assert(ready == 0, "Reaching a shape point cannot complete the authored objective")
fixture.player = point(100,100)
nav:PollArrival()
assert(ready == 1 and APRData[APR.PlayerID][APR.ActiveRoute] == 7,
    "Navigation arrival hands control back without advancing guide progress")
nav.state, nav.cursor = "guiding",1
nav.queue = {nav:PrepareGuidanceStep(segment,1,0,point(0,0))}
fixture.player = point(50,60)
nav:PollArrival()
assert(replans == 1, "Leaving the proved corridor requests a new path")
nav._routeInputs = {position=fixture.player,indoors=false,startedAt=GetTime(),geometryRevision=APR.navigationGeometryRevision}
nav.IsObjectiveCurrent = function() return true end
nav.publishedTerrainRevision, nav.search = data:GetTerrainRevision()-1, {}
assert(not nav:HasPlanningInputsChanged(fixture.player),
    "An old published revision cannot cancel a new candidate that is already rebuilding terrain")
nav.search = nil
assert(nav:HasPlanningInputsChanged(fixture.player), "A changed terrain source invalidates idle published guidance")
nav.publishedTerrainRevision = nil
nav.state, nav.context, nav.cursor = "guiding",context,1
nav.queue = {nav:PrepareGuidanceStep(segment,1,0,fixture.player)}
nav.queue[1].movementMode = "skyriding"
nav.GetMovementProfile = function() return {canSteady=false,canSkyriding=false} end
assert(not nav:IsItineraryValid(), "A lost flight permission cannot survive a failed ground replan")
nav.queue[1].movementMode = "ground"
nav.queue[1].to.noAutoconnect = true
assert(nav:IsItineraryValid(), "An explicit proved terrain path can reach an endpoint that forbids automatic walking links")
nav.publishedTerrainRevision = data:GetTerrainRevision()
LibStub("LibAPRNavigation-1.0"):RegisterTerrainData("retail", 0,
    {format=1,nodes={},edges={},anchors={}}, 1, "replacement")
assert(not nav:IsItineraryValid(), "A source replacement cannot retain a corridor proved against the previous revision")
nav.recomputeKeepingPath = true
nav:SearchFailed()
assert(nav.state == "no_path" and not nav:GetActiveStep(),
    "A failed replan must remove stale terrain guidance rather than continue along a removed corridor")
print("Terrain controller: corridor lookahead, corner safety, arrival handoff and independent guide progress")
