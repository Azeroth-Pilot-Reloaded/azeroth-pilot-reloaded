-- The real controller accepts proved native worlds, without a UI map gate.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({config={NavigationSpaces={
    {id="room",kind="instance",worldID=77,mapIDs={},groundOnly=true,requiresExit=true,
        bounds={minX=0,maxX=200,minY=0,maxY=40,minZ=10,maxZ=20}},
    {id="lower",kind="floor",worldID=78,mapIDs={},floor="lower",groundOnly=true,requiresExit=true,
        bounds={minX=0,maxX=200,minY=0,maxY=40,minZ=0,maxZ=5}},
    {id="upper",kind="floor",worldID=78,mapIDs={},floor="upper",groundOnly=true,requiresExit=true,
        bounds={minX=0,maxX=200,minY=0,maxY=40,minZ=20,maxZ=25}},
}},connections={}})
local step={Coord={x=20,y=150,z=15,instanceID=77}}
local steps={step}
local context={route="invented",index=1,revision=1,definition=steps}
local function noop()end
fixture.player={instanceID=77,x=10,y=20,z=15}
C_Map.GetBestMapForUnit=function()return nil end
APR.settings,APR.ActiveRoute,APR.PlayerID={profile={enableAddon=true}},"invented","player"
APR.GAME_VERSIONS={Forever="forever"}
APRData={player={invented=1}}
function APR:NewModule()return {}end
function APR:GetGameVersion()return "retail"end
function APR:GetCurrentStep()return step,1,steps end
function APR:GetStepCoord(value)return value.Coord end
function APR:GetCurrentRouteMapIDsAndName()return {},nil end
function APR:GetStepZoneForPlayer()return nil end
function APR:CaptureStepContext()return context end
function APR:IsStepContextCurrent(value)return value==context end
function UnitIsDeadOrGhost()return false end
function UnitOnTaxi()return false end
function GetUnitSpeed()return 0,7,0 end
function GetMoney()return 100 end
C_Timer={NewTimer=function(_,callback)return {callback=callback,Cancel=noop}end}
APR.event,APR.SendMessage={QueueStepRefresh=noop},noop
local plans=0
APR.NavigationPlanner={Create=function(_,request)
    plans=plans+1
    assert(request.start.instanceID==77 and request.start.uiMapID==nil and request.start.spaceID=="room"
        and request.goal.uiMapID==nil and request.goal.spaceID=="room",
        "The controller passes the same proved world geometry into planning")
    return {Step=function()return "planning"end,Cancel=noop}
end}
dofile("APR-Core/utils/NavigationZones.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
nav:Update(context)
assert(plans==1 and nav.search and nav:GetState()~="waiting_data",
    "A valid mapless native world must reach the ordinary planner")
assert(nav.destination.uiMapID==nil and nav.destination.x==150 and APRData.player.invented==1)
nav:Cancel("test")
fixture.player={instanceID=78,x=10,y=20,z=0}
step.Coord.instanceID,step.Coord.z=78,22
nav:Update(context)
assert(plans==1 and nav:GetState()=="waiting_data" and not nav.search,
    "Ambiguous mapless floors wait before planning and cannot fabricate a ready route")
nav:Cancel("test")
fixture.player={instanceID=77,x=10,y=20,z=15}
step.Coord.instanceID,step.Coord.z=77,15
nav:Update(context)
assert(plans==2 and nav.search,"A later complete native observation resumes ordinary planning")
nav:Cancel("test")
C_Map.GetBestMapForUnit=function()return "invalid"end
nav:Update(context)
assert(plans==2 and nav:GetState()=="waiting_data" and APRData.player.invented==1,
    "The controller still rejects a nonnil invalid native map and preserves authored progress")
print("Mapless controller: real native provider, world-space goals, ambiguity waiting, recovery and invalid-map rejection")
