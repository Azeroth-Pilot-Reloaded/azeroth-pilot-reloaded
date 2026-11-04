-- Explicit engine selection through the real APR controller and its scheduler.
local noop=function()end
local timers,calls={}, {v1=0,v2=0,cancel=0,unlocks=0}
local position={x=0,y=0,z=3,instanceID=0,uiMapID=2,floor='outside'}
GetTime=function()return 10 end
GetMoney=function()return 0 end
IsIndoors=function()return false end
UnitIsDeadOrGhost=function()return false end
CreateFrame=function()return {RegisterEvent=noop,SetScript=noop}end
LibStub=function()return {GetLocale=function()return setmetatable({},{__index=function(_,k)return k end})end}end
C_Timer={NewTimer=function(delay,callback)
    local t={callback=callback,Cancel=function(self)self.cancelled=true end};timers[#timers+1]=t;return t
end}
C_Map={GetBestMapForUnit=function()return position.uiMapID end}
local step={Coord={x=0,y=3000,mapID=3,instanceID=1,floor='inside',phase='story-b'},Zone=3}
APR={PlayerID='p',ActiveRoute='r',RouteQuestStepList={r={}},stepRevision=0,
    settings={profile={enableAddon=true}},GAME_VERSIONS={Forever='forever'},
    currentStep={AddQuestSteps=noop,AddQuestDivider=noop,AddStepButton=noop},
    Arrow={SetCoord=noop},event={QueueStepRefresh=noop},SendMessage=noop,
    NewModule=function()return {}end,GetNavigationPlayerPosition=function()return position end,
    GetGameVersion=function()return 'forever'end,GetCurrentStep=function()return step,1,{step}end,
    GetCurrentRouteMapIDsAndName=function()return {3},3 end,
    GetStepCoord=function(_,s)return s.Coord,3 end,
    GetPreferredStepZone=function(_,s)return s.Zone end,CheckNavigationZoneReady=function()return false end,
    StartNavigationUnlock=function()calls.unlocks=calls.unlocks+1 end}
APRData={p={r=1}}
dofile('APR-Core/features/questing/StepTransitions.lua')
APR.NavigationData={CanWalk=function()
    assert(not APR.navigation or APR.navigation:GetEngine()~='v2','V2 must not enter the V1 traversal pipeline')
    return false
end}
function APR.NavigationData:NormalizeLocation(point)
    assert(not APR.navigation or APR.navigation:GetEngine()~='v2','V2 must preserve already-known world coordinates without the V1 normalizer')
    return point
end
APR.NavigationPlanner={Create=function()
    calls.v1=calls.v1+1
    return {Step=function()return 'no_path'end,Cancel=noop}
end}
function APR.NavigationData:IsSameAccessRegion()
    assert(APR.navigation:GetEngine()~='v2','V2 arrival must use its explicit identity, not the V1 access normalizer')
    return true
end
local pending=false
local function world(x,instance,map,floor)return {x=x,y=0,z=3,instanceID=instance,uiMapID=map,floor=floor}end
APR.NavigationV2Planner={Create=function(_,request)
    calls.v2=calls.v2+1
    assert(request.start.instanceID==0 and request.goal.instanceID==1)
    assert(request.goal.phase=='story-b','Already declared phase must survive the V2 destination boundary')
    local count=0
    local job={request=request,current=true}
    function job:IsCurrent()return self.current end
    function job:Cancel()calls.cancel=calls.cancel+1;self.cancelled=true end
    function job:Step()
        if self.cancelled then return 'cancelled'end
        count=count+1
        if pending or count==1 then return 'planning'end
        local a,b=world(0,0,2,'outside'),world(100,0,2,'outside')
        local c,d=world(2000,1,3,'inside'),world(3000,1,3,'inside')
        local function row(id,kind,from,to)
            return {id=id,v2=true,kind=kind,from=from,to=to,label=kind,mandatory=true,generated=true,
                Coord={x=0,y=(kind=='walk' and to or from).x,mapID=(kind=='walk' and to or from).uiMapID},
                departureSeen=id==1,seconds=1,copper=0}
        end
        self.result={queue={row(1,'walk',a,b),row(2,'portal',b,c),row(3,'walk',c,d)},totalSeconds=3,totalCopper=0}
        return 'ready',self.result
    end
    function job:GetResult()return self.result end
    return job
end}
dofile('APR-Core/features/navigation/Navigation.lua')
local nav=APR.navigation
assert(type(nav.GetEngine)=='function' and nav:GetEngine()=='v1','V1 is the default until explicit session opt-in')
assert(nav:SetEngine('other')==nil and nav:GetEngine()=='v1')
nav:Update();assert(calls.v1==1)
local originalV1=calls.v1
assert(nav:SetEngine('v2'))
local function flush(limit)
    for _=1,limit or 30 do
        local t=table.remove(timers,1);if not t then return end
        if not t.cancelled then t.callback()end
    end
end
flush()
assert(calls.v2==1 and calls.v1==originalV1,'Normal APR routing actually dispatches V2 without silent V1 fallback')
assert(nav:IsNavigating() and #nav.queue==3)
assert(nav:IsItineraryValid(),'V2 validity must not call V1 CanWalk')
position.x=100;nav:PollArrival();assert(nav:GetActiveStep().kind=='portal')
nav:PollArrival();assert(nav:GetActiveStep().departureSeen,'Observe departure before simulating a native transport arrival')
position.x,position.instanceID,position.uiMapID,position.floor=2000,1,3,'outside'
nav:PollArrival();assert(nav:GetActiveStep().kind=='portal','An unobserved destination floor cannot count as arrival')
position.floor='inside';nav:PollArrival();assert(nav:GetActiveStep().kind=='walk')
position.x=3000;nav:PollArrival();assert(nav:GetState()=='ready' and APRData.p.r==1)
assert(calls.unlocks==1,'Only the original V1 failure may start its legacy unlock flow')
position.x,position.instanceID,position.uiMapID,position.floor=0,0,2,'outside'
pending=true;nav:ForceRefresh();nav:Update();local stale=nav._searchTimer
local before=calls.cancel
assert(nav:SetEngine('v1'));assert(calls.cancel>before)
if stale then stale.callback()end
assert(not nav:IsNavigating(),'A retired V2 callback cannot publish after switching engines')
assert(nav:GetEngine()=='v1' and APR.settings.profile.navigationEngine==nil,'Test selection does not silently persist across reloads')
print('Normal APR V2: explicit dispatch, isolated V1, same controller, identity arrival, cancellation and unchanged quest progress passed')

-- The same normal controller must publish a route from the real V2 data
-- preparator and solver, rather than passing only a mocked provider contract.
local fixture=dofile('tests/lua/navigation_v2/fixture.lua')
local library,namespace=fixture.Load()
local facts={config={},bindings={},roads={networks={},collision={}},revision=1,
 connections={{id='invented-apr-door',kind='portal',seconds=4,instruction='Take the door',
 from={space='world',instanceID=0,x=0,y=0,z=3,uiMapID=2,floor='outside'},
 to={space='world',instanceID=1,x=3000,y=0,z=3,uiMapID=3,floor='inside',phase='story-b'}}}}
local data={GetProfile=function()return {name='forever'}end,
 GetConfig=function()return facts.config end,GetConnections=function()return facts.connections end,
 GetBindings=function()return facts.bindings end,GetRoadData=function()return facts.roads end,
 GetRoadRevision=function()return facts.revision end}
for _,method in ipairs({'NormalizeLocation','BuildEdges','CanWalk','IsSameAccessRegion'})do
 data[method]=function()error('Normal V2 uses its own route and arrival contracts')end
end
APR.NavigationData=data
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkPreparation.lua'))('test',namespace)
assert(loadfile('APR-Core/features/navigation/NavigationV2Planner.lua'))('test',namespace)
debugprofilestop=function()return 0 end
local newCount,planCount=0,0
local rawNew=library.New
library.New=function(...)
 newCount=newCount+1
 local planner,why=rawNew(...)
 if planner then local rawPlan=planner.Plan;function planner:Plan(...)planCount=planCount+1;return rawPlan(self,...)end end
 return planner,why
end
position.x,position.instanceID,position.uiMapID,position.floor=0,0,2,'outside'
assert(nav:SetEngine('v2'));flush(1000)
assert(nav:IsNavigating(),nav.lastPlanning and nav.lastPlanning.terrainReason)
assert(nav.lastPlanning.engine=='v2' and nav.lastPlanning.status=='ready')
assert(newCount==1 and planCount==1 and nav.totalSeconds==4)
local transport
for _,row in ipairs(nav.queue)do
 assert(row.v2 and row.action==nil)
 if row.kind=='portal' then transport=row end
end
assert(transport and transport.connectionID=='invented-apr-door')
-- Observe departure, then the real target identity; no authored quest advance.
for _=1,4 do nav:PollArrival()end
position.x,position.instanceID,position.uiMapID,position.floor=3000,1,3,'inside'
position.phase='story-a';nav:PollArrival();assert(nav:IsNavigating())
position.phase='story-b'
for _=1,8 do nav:PollArrival()end
assert(nav:GetState()=='ready' and APRData.p.r==1)
assert(nav:SetEngine('v1'));assert(nav:GetEngine()=='v1')
print('Normal APR real V2: preparation -> one New/Plan -> publication -> observed identity arrival -> V1 return passed')
