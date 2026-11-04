-- The host must provide character capabilities before a later world is refined.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.currentMap = 101
local data = fixture:Load({connections={}})
data.env.requestTerrainData=function()return "ready" end
local lib = LibStub("LibAPRNavigation-1.0")
local function point(world, map, x)
    return data:NormalizeLocation({instanceID=world,uiMapID=map,x=x,y=0,z=0})
end
local start, goal = point(1,101,0), point(2,201,0)
local arrival, departure = point(9,601,0), point(9,601,1000)
lib:RegisterTerrainData("retail",9,{format=1,
    nodes={{id="a",x=0,y=0,z=0,uiMapID=601},{id="b",x=1000,y=0,z=0,uiMapID=601}},
    edges={{from="a",to="b",mode="ground"}},
    anchors={
        {node="a",minX=-1,maxX=1,minY=-1,maxY=1,minZ=-1,maxZ=1,mode="ground",bidirectional=true},
        {node="b",minX=999,maxX=1001,minY=-1,maxY=1,minZ=-1,maxZ=1,mode="ground",bidirectional=true}}},1,"fixture")
local edges = {
    {kind="portal",id="direct",from=start,to=goal,seconds=30},
    {kind="portal",id="entry",from=start,to=arrival,seconds=1},
    {kind="portal",id="exit",from=departure,to=goal,seconds=1}}
data.CreateEdgeBuild = function() return {Step=function()return "ready",edges,{resources={}} end} end
local timers = {}
C_Timer={NewTimer=function(_,callback)
    local timer={callback=callback,Cancel=function(self)self.cancelled=true end}
    timers[#timers+1]=timer; return timer
end}
function GetMoney()return 0 end
function UnitIsDeadOrGhost()return false end
function UnitOnTaxi()return false end
APR.PlayerID,APR.ActiveRoute="synthetic-player","synthetic-route"
APR.settings={profile={enableAddon=true}}
function APR:NewModule()return {} end
function APR:GetGameVersion()return "retail" end
APR.GAME_VERSIONS={Forever="forever"}
function APR:GetNavigationPlayerPosition()return start end
local step={Zone=201,Coord={x=0,y=0,z=0,instanceID=2,mapID=201}}
local definition={step}
local context={route=APR.ActiveRoute,index=1,definition=definition,revision=1}
function APR:CaptureStepContext()return context end
function APR:IsStepContextCurrent(value)return value==context end
function APR:GetCurrentStep()return step,1,definition end
function APR:GetCurrentRouteMapIDsAndName()return {201},201 end
function APR:GetStepCoord(value)return value.Coord,value.Zone end
function APR:CheckNavigationZoneReady()return false end
APR.NavigationAdapter={CreatePreparation=function()return {Step=function()return "ready" end} end}
APR.taxiData={BuildEdges=function()return {} end}
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
nav.Notify=function()end
nav.Render=function()end
nav.GetThreshold=function()return 10000 end
nav.GetMovementSpeed=function(_,threshold)return threshold==2000 and 14 or 60 end
local profiles,currentMode=0,"skyriding"
nav.GetMovementProfile=function()
    profiles=profiles+1
    return {groundSpeed=14,canSteady=false,canSkyriding=true,skyridingSpeed=60,currentMode=currentMode}
end
local function plan()
    nav:Update(context)
    local slices=0
    while nav.search do
        local timer=table.remove(timers,1)
        assert(timer,"Planning remains scheduled")
        if not timer.cancelled then timer.callback() end
        slices=slices+1; assert(slices<1000,"The small synthetic graph must finish")
    end
end
plan()
assert(nav.plannedMovementProfile and profiles>0,
    "Terrain capability capture cannot depend only on the departure and final worlds")
assert(nav.queue[1].connectionID=="direct" and nav.totalSeconds==30,
    "A ground-only intermediate corridor costs 1000/14 seconds, not the departure's airborne 1000/60")
assert(nav.plannedMovementProfile.currentMode=="skyriding",
    "Legacy departure access must coexist with the live capability snapshot used by intermediate terrain")
nav:Cancel("cleared")
start,goal=arrival,departure
currentMode="ground"
step.Zone,step.Coord=601,{x=0,y=1000,z=0,instanceID=9,mapID=601}
edges={}
plan()
assert(nav:IsNavigating() and nav.queue[1].terrain,"The original synthetic corridor is reachable")
local previous=nav.queue
local source=lib.terrainDatasets.retail[9].packs.fixture.data
APR.Arrow={Active=true,x=previous[1].Coord.x,y=previous[1].Coord.y,
    SetArrowActive=function(self,active)self.Active=active end}
nav.retainedArrow=nav:CaptureRetainedArrow(start)
assert(nav:GetRetainedArrow(),"A current corridor can retain its arrow while replacement work runs")
lib:RegisterTerrainData("retail",9,{format=1,nodes=source.nodes,anchors=source.anchors,edges={}},2,"fixture")
nav.queue,nav.state={},"planning"
assert(not nav:GetRetainedArrow() and not nav:CaptureRetainedArrow(start),
    "A retained terrain arrow must lose its proof when the source changes during planning")
nav.queue,nav.state,nav.retainedArrow=previous,"guiding",nil
data.env.requestTerrainData=function()return "planning","fixture_pending" end
plan()
assert(nav.state=="waiting_data" and not nav:GetRetainedArrow() and not APR.Arrow.Active,
    "A waiting replacement must not continue displaying a target from the retired terrain corridor")
data.env.requestTerrainData=function()return "ready" end
nav:ForceRefresh("geometry_ready")
plan()
assert(nav.state=="no_path" and nav.queue~=previous and not nav:GetActiveStep(),
    "A new source removing the only corridor must clear the published trip after its failed replacement search")
nav:Cancel("cleared")
goal=point(2,201,0)
currentMode="skyriding"
step.Zone,step.Coord=201,{x=0,y=0,z=0,instanceID=2,mapID=201}
edges={{kind="portal",id="ground-portal",from=start,to=goal,seconds=30}}
local states={
    {id="air",x=0,y=0,z=0,uiMapID=601,movementMode="skyriding"},
    {id="ground",x=0,y=0,z=0,uiMapID=601,movementMode="ground"}}
lib:RegisterTerrainData("retail",9,{format=1,nodes=states,anchors={},edges={}},3,"fixture")
plan()
assert(nav.state=="no_path" and not nav:GetActiveStep(),
    "An airborne managed departure cannot reach a coincident ground portal without a proved landing")
local checks=0
local build=data.CreateEdgeBuild
data.CreateEdgeBuild=function(self,request) checks=checks+1;return build(self,request) end
plan()
assert(checks==0,"An unchanged failed terrain source must not trigger another catalogue build")
lib:RegisterTerrainData("retail",9,{format=1,nodes=states,anchors={},
    edges={{from="air",to="ground",mode="skyriding",seconds=3}}},4,"fixture")
plan()
assert(nav:IsNavigating() and nav.totalSeconds==33,
    "An explicit three-second landing restores access to the thirty-second ground portal")
assert(checks>0,"A newly registered source must retry a previously failed itinerary without another gameplay event")
nav:Cancel("cleared")
lib.terrainDatasets.retail=nil
profiles=0
nav:Update(context)
assert(nav.plannedMovementProfile==nil and profiles==0,
    "Legacy catalogues without terrain must not acquire movement-profile work")
nav:Cancel("cleared")
print("Terrain host profile: intermediate capabilities and legacy lookup avoidance")
