-- Real arrow and both map renderers consume the same remaining terrain bends.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local px, py, now = 0, 0, 10
function UnitPosition() return py, px, 0, 0 end
function GetPlayerFacing() return 0 end
function GetTime() return now end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetMoney() return 0 end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
function IsIndoors() return false end
C_Map = {GetBestMapForUnit = function() return 1 end,
    GetPlayerMapPosition = function() return {x=px/1000,y=py/1000} end}
C_Minimap = {GetViewRadius = function() return 1000 end}
local authored = {PickUp = {101}, Range = 3, Zone = 1, Coord = {x = 0, y = 10, instanceID = 0}}
APR.ActiveRoute, APR.PlayerID = "r", "p"
APR.RouteQuestStepList, APRData = {r = {steps = {authored}, mapID = 1}}, {p = {r = 1}}
function APR:GetGameVersion() return "forever" end
function APR:GetCurrentStep() return authored, 1, self.RouteQuestStepList.r.steps end
function APR:GetRouteSteps() return {authored} end
function APR:GetStepCoord(step) return step.Coord, 1 end
function APR:GetPlayerParentMapID() return 1 end
function APR:GetCurrentRouteMapIDsAndName() return {1}, 1 end
function APR:GetPlayerMapPos(_, y, x) return x/1000, y/1000 end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
function APR:IsStepContextCurrent() return true end
APR.NavigationData = {GetMapWorldInstanceID = function() return 0 end,
    CanWalk = function() return true end, IsSameAccessRegion = function() return true end}
APR.currentStep = {AddQuestSteps = function() end}
dofile("APR-Core/features/navigation/Navigation.lua")
dofile("APR-Core/features/navigation/Preview.lua")
dofile("APR-Core/features/navigation/Arrow.lua")
local nav = APR.navigation
local path = {{x=0,y=0,z=0,instanceID=0,uiMapID=1}, {x=0,y=40,z=0,instanceID=0,uiMapID=1},
    {x=10,y=40,z=0,instanceID=0,uiMapID=1}, {x=10,y=0,z=0,instanceID=0,uiMapID=1}}
local final = path[#path]
local advances = 0
function APR:NextQuestStep() advances = advances + 1 end
APR.NavigationData.GetWalkingProvider = function() return {HasMap=function() return true end} end
nav.state, nav.start, nav.destination = "planning", path[1], final
APR.IsInRouteZone = true
authored.Waypoint, authored.Range = 1, 20
local profile = APR.settings.profile
profile.enableAddon, profile.showArrow, profile.arrowFPS = true, true, 60
APR.Arrow:SetCoord()
APR.Arrow:UpdatePosition()
assert(not APR.Arrow.Active and advances == 0, "Pending terrain planning must not let a nearby authored waypoint advance through the arrow")
assert(#APR.navigationPreview:GetPoints() == 0, "Pending terrain planning must not draw an unverified direct map chord")
authored.Waypoint, authored.Range = nil, 3
nav.queue = {nav:PrepareGuidanceStep({kind="walk", from=path[1], to=final, path=path}, 1, 1, path[1])}
nav.state, nav.cursor, nav.context = "guiding", 1, {}
function nav:Render() end
APR.Arrow:SetCoord()
assert(APR.Arrow.x == 40 and APR.Arrow.y == 0, "The real arrow targets the first bend, not the final objective")
APR.Arrow:UpdatePosition()
assert(APR.Arrow.Distance == 90 and APR.ArrowFrame.distance:GetText():match("^90 "), "Arrow text displays remaining path yards")
px, py, now = 20, 0, 11
APR.Arrow:UpdatePosition()
assert(APR.Arrow.Distance == 70, "Movement only changes the current edge of the remaining path")
assert(APRData.p.r == 1 and authored.Range == 3, "Arrow updates cannot complete the authored interaction")

WorldMapFrame, Minimap = env.widget(), env.widget()
WorldMapFrame:SetSize(1000, 800)
Minimap:SetSize(200, 200)
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 1 end
function Minimap:GetZoom() return 0 end
function env.methods:CreateAnimationGroup() return env.widget() end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() end
local mapUpdate
function APR:NewModule()
    return {RegisterMessage = function(_, message, callback)
        if message == "APR_MAP_UPDATE" then mapUpdate = callback end
    end}
end
local pinCount = 0
local pins = {RemoveAllWorldMapIcons = function() end, RemoveAllMinimapIcons = function() end,
    AddWorldMapIconMap = function() pinCount = pinCount + 1 end, AddMinimapIconMap = function() pinCount = pinCount + 1 end}
local originalLibStub = LibStub
function LibStub(name, ...)
    if name == "HereBeDragons-Pins-2.0" then return pins end
    return originalLibStub(name, ...)
end
profile.showMiniMapLine, profile.showMapLine = true, true
profile.showMiniMapLineColor, profile.showMapLineColor = {1,0,0}, {1,0,0}
profile.showMiniMapLineThickness, profile.showMapLineThickness = 2, 2
profile.mapshowNextSteps, profile.minimapshowNextSteps = true, true
profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 0, 0
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
local tick = APR.map.stepLines.scripts.OnLoop
function APR:SendMessage(message)
    if message == "APR_MAP_UPDATE" then mapUpdate() end
end
function debugprofilestop() return now * 1000 end
nav:BeginGuidanceMeasurement("guide")
nav.generation = nav.generation + 1
now = now + 0.125
nav:Notify()
local sample = nav.guidanceMeasurement
assert(sample.Published == 125 and sample.Arrow == 125 and sample.Minimap == 125 and sample.WorldMap == 125,
    "Publication renders both visible line pools and the facing texture in the same notification")
assert(#APR.map.worldSegments == 3 and #APR.map.minimapSegments == 3, "Both map lines follow all three remaining edges")
assert(pinCount == 0, "Dense terrain bends do not allocate map pins")
local frames = env.frames()
for _ = 1, 100 do tick() end
assert(env.frames() == frames, "Stationary path refreshes reuse pooled geometry")
px, py, now = 40, 0, 12
nav:PollArrival()
assert(nav.cursor == 1 and nav.queue[1].pathCursor == 3)
assert(APR.Arrow.x == 40 and APR.Arrow.y == 10, "Reaching a bend immediately updates the arrow")
APR.Arrow:UpdatePosition()
tick()
assert(APR.Arrow.Distance == 50 and APRData.p.r == 1)
assert(not APR.map.worldSegments[3].line:IsShown() and not APR.map.minimapSegments[3].line:IsShown(),
    "Passed terrain edges disappear from both map renderers")

-- The next transport keeps its authored boarding endpoint and discontinuity.
local boat = {kind="boat", from=final, to={x=100,y=100,instanceID=8,uiMapID=2}, action={type="spell",data=888}}
local entry = nav:PrepareGuidanceStep(boat, 2, 1, path[1])
assert(entry.Coord.x == 0 and entry.Coord.y == 10 and entry.action == boat.action and not entry.path)
nav.queue[2] = entry
APR.navigationPreview.routeCache = nil
local points = nav:GetPreview()
local arrival
for _, point in ipairs(points) do if point.arrival then arrival = point end end
assert(arrival and arrival.instanceID == 8 and arrival.breakBefore, "Transport world boundaries remain disconnected")

-- Poll again only after passing two closely spaced bends. The notification
-- must update the arrow and both cached line sets in the same guidance leg.
local near={x=3,y=40,z=0,instanceID=0,uiMapID=1}
local missed={path[1],path[2],near,{x=35,y=40,z=0,instanceID=0,uiMapID=1},final}
local terrain={CanFollowWalkingSegment=function() return true end}
APR.NavigationData.GetWalkingProvider=function() return terrain end
nav.queue={nav:PrepareGuidanceStep({kind="walk",from=missed[1],to=final,path=missed},1,1,missed[1])}
APR.Arrow:SetCoord()
tick()
assert(APR.Arrow.x==40 and APR.Arrow.y==0)
px,py,now=40,15,13
nav:PollArrival()
tick()
assert(nav.queue[1].pathCursor==4 and APR.Arrow.x==40 and APR.Arrow.y==35)
assert(APR.map.worldSegments[2].line:IsShown() and APR.map.minimapSegments[2].line:IsShown())
assert(not APR.map.worldSegments[3].line:IsShown() and not APR.map.minimapSegments[3].line:IsShown())
local project = APR.navigationPreview.ProjectPoint
local projectionReadyAt = now + 0.2
function APR.navigationPreview:ProjectPoint(...)
    if now < projectionReadyAt then return nil, nil, projectionReadyAt end
    return project(self, ...)
end
APR.navigationPreview:InvalidateProjectionCache()
tick()
assert(not APR.map.worldSegments[1].line:IsShown() and not APR.map.minimapSegments[1].line:IsShown())
now = projectionReadyAt
tick()
assert(APR.map.worldSegments[1].line:IsShown() and APR.map.minimapSegments[1].line:IsShown(),
    "A stationary player gets the first visible corridor when transient map data becomes available")
do
    local outside = {x=200,y=20,z=0,instanceID=0,uiMapID=1}
    local provider = {HasMap=function() return true end}
    function provider:RequiresWalkingProof(from, to) return from.x < 100 and to.x < 100 end
    APR.NavigationData.GetWalkingProvider = function() return provider end
    local segments = {{kind="walk",from=path[1],to=outside},{kind="walk",from=outside,to=final}}
    local function assertNoLine()
        for _, pool in ipairs({APR.map.worldSegments, APR.map.minimapSegments}) do
            for _, segment in ipairs(pool) do assert(not segment.line:IsShown()) end
        end
    end
    nav:Cancel("step_changed")
    nav:Notify()
    assertNoLine()
    nav.start, nav.destination, nav.state, nav.context = path[1], final, "planning", {}
    nav:Notify()
    assertNoLine()
    nav:Publish({segments=segments}, nav.context, nav.generation)
    assert(nav.state == "waiting_data" and nav.reason == "terrain_coverage" and not nav:GetActiveStep())
    assertNoLine()
    tick()
    assertNoLine()
    assert(not nav:CanReuseServiceItinerary({segments=segments}, path[1], final, provider))
    nav.state, nav.queue = "guiding", {}
    for i, segment in ipairs(segments) do nav.queue[i] = nav:PrepareGuidanceStep(segment, i, nav.generation, path[1]) end
    assert(#nav:GetPreview() == 0, "An existing estimated queue cannot reintroduce a line from the preview")
    nav:Cancel("service_cancelled")
    nav:Notify()
    assertNoLine()
    local portal = {kind="portal",from=path[1],to=outside}
    profile.mapshowNextSteps, profile.minimapshowNextSteps = false, false
    nav.context = {}
    nav:Publish({segments={portal}}, nav.context, nav.generation)
    assert(nav:IsNavigating() and nav:GetActiveStep().kind == "portal",
        "A declared transport remains publishable on the edge of coverage")
end
do
    local pin = {x=14,y=0,instanceID=0,uiMapID=1}
    local manual = {_service=true, _mapWaypoint=true, Coord=pin, target=pin, Zone=1}
    local service = manual
    APR.Services = {GetStep=function() return service end, GetLabel=function() return "Pin" end,
        IsContextCurrent=function() return true end, Cancel=function() error("Partial path closed the pin") end}
    APR.NavigationData.GetWalkingProvider = function() return terrain end
    APR.NavigationData.IsServiceArrival = function(_, p, q, range)
        return (p.x-q.x)^2+(p.y-q.y)^2 <= (range or 5)^2
    end
    nav:Cancel("service_started")
    px, py = 0, 0
    local context, job = {service=true}, {Cancel=function() end}
    local function dispatch()
        nav.context, nav._routedStepContext, nav.search = context, context, job
        nav.start, nav.destination, nav.state = path[1], pin, "planning"
        nav._routeInputs = nav:CapturePlanningInputs(service, path[1], context)
    end
    local partial = {path=path, seconds=10, partial=true, remainingHeight=3}
    local function publish()
        return nav:PublishLocalPath(partial, context, nav.generation, job, nav._routeInputs, false, true)
    end
    dispatch()
    assert(not publish() and not nav:GetActiveStep(),
        "A manual pin cannot draw an approach that lacks geometry verification")
    partial.geometryVerified = true
    manual._mapWaypoint = false
    assert(not publish(), "A ranked service cannot accept a partial arrival")
    manual._mapWaypoint = true
    assert(publish() and nav:GetActiveStep().approachOnly)
    assert(nav.destination == pin and nav:GetActiveStep().to == final and nav.waypointApproach.residualYards == 4)
    local points = nav:GetPreview()
    local marker = points[#points]
    assert(marker.kind == "map_waypoint" and marker.breakBefore and marker.Coord.x == 14)
    assert(APR.Arrow.x == 40 and APR.Arrow.y == 0)
    for _, pool in ipairs({APR.map.worldSegments, APR.map.minimapSegments}) do
        assert(pool[3].line:IsShown() and (not pool[4] or not pool[4].line:IsShown()))
    end
    -- A physically complete transit to the pin supersedes even a cheaper approach.
    px, py = 40, 0
    nav:Publish({segments={{kind="portal",from=path[1],to=pin,seconds=500}}}, context, nav.generation)
    assert(nav:GetActiveStep().kind == "portal" and not nav.waypointApproach)
    px, py = 0, 0
    dispatch()
    assert(publish())
    nav:SearchFailed()
    assert(nav:GetActiveStep().approachOnly, "A failed comparison must retain walkable progress")
    for i = 2, #path do
        px, py = path[i].y, path[i].x
        nav:PollArrival()
    end
    assert(nav.state == "no_path" and nav.waypointApproach.reached and nav.reason == "waypoint_approach")
    assert(nav.destination == pin and advances == 0 and not nav:GetActiveStep())
    local markerOnly = nav:GetPreview()
    assert(#markerOnly == 1 and markerOnly[1].kind == "map_waypoint" and markerOnly[1].breakBefore)
    assert(not APR.Arrow.Active)
    for _, pool in ipairs({APR.map.worldSegments, APR.map.minimapSegments}) do
        for _, segment in ipairs(pool) do assert(not segment.line:IsShown()) end
    end
    nav:MarkRouteReady()
    local generation, inputs = nav.generation, nav._routeInputs
    nav:Cancel("service_cancelled")
    service = nil
    nav:Notify()
    assert(not nav.waypointApproach and not nav:PublishLocalPath(partial, context, generation, job, inputs, false, true))
end
do
    APR.Services = nil
    APR.NavigationData.GetWalkingProvider = function()
        return {CanFollowWalkingSegment = function(_, _, to, joining)
            return joining == "outdoor" and to.x == 65
        end}
    end
    local road = {}
    for x = 5, 105, 10 do road[#road + 1] = {x=x,y=0,z=0,instanceID=0,uiMapID=1} end
    local leg = nav:PrepareGuidanceStep({kind="walk",from=road[1],to=road[#road],path=road}, 1, 1, road[1])
    nav.queue, nav.cursor, nav.context, nav.state = {leg}, 1, {}, "guiding"
    px, py = 28, 38
    nav:PollArrival()
    assert(leg.pathCursor == 5 and leg.pathAimIndex == 7)
    assert(APR.Arrow.y == 65 and APR.Arrow.x == 0, "The arrow uses the proven aim ahead of the player's projection")
    local first = nav:GetPreview()[1]
    assert(first.Coord.y == 65 and first.Coord.x == 0, "Map lines start with the same forward aim as the arrow")
end
print("Terrain guidance render: shared polylines, pin retention, partial arrival, cancellation and exact transit passed")
