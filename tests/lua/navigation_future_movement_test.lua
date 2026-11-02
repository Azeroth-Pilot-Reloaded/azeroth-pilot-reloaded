-- A grounded departure does not remove capabilities from a later proved air leg.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
data.env.requestTerrainData=function()return "ready"end
data.GetFlightPermission=function(_,p,mode)
    return mode=="skyriding" and (p.x==14 or p.x==614)
end
local lib=LibStub("LibAPRNavigation-1.0")
local function point(x,mode,ground)
    return {instanceID=8,uiMapID=18,x=x,y=0,z=0,region="fixture",movementMode=mode,groundOnly=ground}
end
local start,exit,air,airGoal,goal=point(0,"ground",true),point(14,"ground"),point(14,"skyriding"),point(614,"skyriding"),point(614,"ground")
APR.GAME_VERSIONS={Forever="forever"}
function APR:GetGameVersion()return "retail"end
function APR:NewModule()return {}end
function APR:GetNavigationPlayerPosition()return start end
function APR:CheckFlySkill()return true end
function IsIndoors()return true end
function IsFlyableArea()return false end
function IsAdvancedFlyableArea()return false end
function IsFlying()return false end
function GetUnitSpeed()return 0,7,60 end
C_PlayerInfo={GetGlidingInfo=function()return false,false,0 end}
local mountLists=0
C_MountJournal={GetCollectedDragonridingMounts=function()mountLists=mountLists+1;return {1}end,
    IsDragonridingUnlocked=function()return true end,
    GetMountInfoByID=function()return "owned mount",1,1,false,false,0,false,false,nil,false,true end,
    GetMountUsabilityByID=function()return false end}
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
local movement=nav:GetMovementProfile()
assert(movement.canSteady and movement.canSkyriding,
    "Learned and collected flight capabilities survive current cave and mount-usability restrictions")
assert(nav:GetThreshold()==2000 and nav:GetMovementSpeed(10000)==7 and movement.currentMode=="ground")
assert(not movement.canFlyAt(start,"skyriding") and movement.canFlyAt(air,"skyriding"),
    "The cave stays grounded while the explicitly proved future aerial node can use the collected mount")
assert(not movement.canFlyAt(point(300,nil),"skyriding"),
    "An unrestricted-looking future coordinate without flight evidence remains grounded")
for _=1,100 do assert(nav:GetMovementProfile().canSkyriding)end
assert(mountLists==1,"Repeated cave plans revalidate one owned flying candidate without enumerating the journal again")
local n={start,exit,air,airGoal,goal}
for index,p in ipairs(n)do p.id=index end
lib:RegisterTerrainData("retail",8,{format=1,nodes=n,edges={
    {from=1,to=2,mode="ground",length=14},
    {from=2,to=3,mode="skyriding",seconds=0},
    {from=3,to=4,mode="skyriding",length=600,horizontal=600},
    {from=4,to=5,mode="skyriding",seconds=0},
}},1,"future-air")
local build=data:CreateTerrainEdgeBuild({start=start,goal=goal,movementProfile=movement})
local status,edges,coverage
for _=1,10000 do status,edges,coverage=build:Step(64,100);if status~="planning"then break end end
assert(status=="ready" and not coverage.missingData)
edges[#edges+1]={kind="portal",id="slow-teleport",from=start,to=goal,seconds=30}
local search=data:CreateSearch({start=start,goal=goal,edges=edges,canWalk=coverage.canWalk,movementProfile=movement,walkSpeed=7})
local route
for _=1,10000 do status,route=search:Step(64,100);if status~="planning"then break end end
assert(status=="ready" and math.abs(route.totalSeconds-12)<0.001,
    "Fourteen yards on foot plus six hundred proved aerial yards costs twelve seconds and beats the thirty-second teleport")
for _,segment in ipairs(route.segments)do assert(segment.id~="slow-teleport")end
local step={Zone=18,Coord={x=0,y=614,z=0,instanceID=8,mapID=18}}
local definition={step}
local context={route="synthetic-route",index=1,definition=definition,revision=1}
APR.settings,APR.PlayerID,APR.ActiveRoute={profile={enableAddon=true}},"fixture-player","synthetic-route"
function APR:CaptureStepContext()return context end
function APR:IsStepContextCurrent(value)return value==context end
function APR:GetCurrentStep()return step,1,definition end
function APR:GetCurrentRouteMapIDsAndName()return {18},18 end
function APR:GetStepCoord(value)return value.Coord,value.Zone end
function APR:CheckNavigationZoneReady()return false end
function GetMoney()return 0 end
function UnitIsDeadOrGhost()return false end
function UnitOnTaxi()return false end
C_Timer={NewTimer=function()return {Cancel=function()end}end}
local captured
APR.NavigationPlanner={Create=function(_,request)
    captured=request
    return {Step=function()return "planning"end,Cancel=function()end}
end}
nav.Notify,nav.Render=function()end,function()end
nav:Update(context)
assert(captured and captured.walkSpeedAt(start)==7 and captured.walkSpeedAt(air)==60
    and captured.walkSpeedAt(point(300,nil))==7,
    "The host cost callbacks price future proved air independently from the current cave and unknown legacy points")
local changed={}
for key,value in pairs(start)do changed[key]=value end
changed.spaceID="new-physical-space"
assert(nav:HasPlanningInputsChanged(changed),"A logical space transition invalidates a plan even if UI map and enclosure flag are unchanged")
nav:Cancel("cleared")
local journal=C_MountJournal
local opaque={}
function issecretvalue(value)return rawequal(value,opaque)end
nav._ownedFlyingMountID=nil
C_MountJournal={GetCollectedDragonridingMounts=function()error("journal unavailable")end,
    IsDragonridingUnlocked=function()return opaque end}
movement=nav:GetMovementProfile()
assert(not movement.canSteady and not movement.canSkyriding,"Missing and protected capability observations cannot become future flight")
C_MountJournal=nil
assert(not nav:GetMovementProfile().canSkyriding)
C_MountJournal=journal
assert(nav:GetMovementProfile().canSkyriding,"Transient missing native data remains retryable")
APR.CheckFlySkill=function()return false end
IsFlying=function()return true end
assert(not nav:GetMovementProfile().canSteady,
    "Being carried through the air cannot substitute for a learned personal flight capability")
APR.GetNavigationPlayerPosition=nil
UnitPosition=nil
assert(pcall(nav.GetMovementProfile,nav),"Missing native position observation cannot raise an error while capturing owned abilities")
UnitPosition=function()error("position unavailable")end
assert(pcall(nav.GetMovementProfile,nav),"A temporarily failed native position observation stays retryable")
print("Future movement: learned capability, local cave permission, proved aerial continuation, unknown safety and native recovery")
