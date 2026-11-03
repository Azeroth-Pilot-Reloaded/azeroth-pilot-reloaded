local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local W=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
local library,ns=W.Load()
local api,state=W.Provider()
local time,context,timers=0,'first',{}
APR={navigation={legacy=true},IsStepContextCurrent=function(_,c) return c==context end}
APR.NextQuestStep=function() error('travel never advances quests') end
GetTime,debugprofilestop=function() return time end,function() return 0 end
MAP_PIN='Map pin'; InCombatLockdown=function() return false end
WaypointUIAPI={Navigation=api}; C_Map={GetUserWaypoint=function() return nil end}
CreateFrame=function() return {SetScript=function() end,RegisterEvent=function() end,UnregisterEvent=function() end,UnregisterAllEvents=function() end} end
C_Timer={NewTimer=function(delay,callback)
    local t={delay=delay,callback=callback}; function t:Cancel() self.cancelled=true end
    timers[#timers+1]=t; return t
end,NewTicker=function() error('no polling') end}
assert(loadfile('APR-Core/features/navigation/NavigationV2.lua'))('test',ns)
local h=APR.NavigationV2
local graph={complete=true,nodes={'start','gate','far','goal'},edges={
    {id='approach',from='start',to='gate',seconds=4},
    {id='walk',from='gate',to='far',seconds=20},
    {id='finish',from='far',to='goal',seconds=3}}}
assert(h:Enable(graph,{portals=F.Catalog(),portalObservation=F.Observation()}))
h:ObserveWorld(false)
h:Plan({from='start',to='goal'},context)
local r
repeat r=h:Step() until r.status~='running'
assert(r.estimatedSeconds==13 and #state.creates==0 and #timers==0)
assert(h:StartTravel(r,{resolveTarget=function(node)
    if node=='goal' then return {key='goal',title='The destination',position={mapID=43,x=.4,y=.6}} end
end},context).kind=='walk')
assert(#state.creates==1)
h:ObserveTravel(F.Location(1,'gate','home'))
assert(h:GetTravelAction().kind=='use_portal' and state.current==nil)
assert(h:BeginPortalUse().kind=='awaiting_transition')
assert(#timers==1 and timers[1].delay==30)
assert(h:ObserveTravel(F.Location(2,'far','other')).kind=='awaiting_transition')
local proof={portalId='door',from='gate',to='far',complete=true,attempt=h:GetTravelAction().attempt}
assert(h:ObserveTravel(F.Location(3,'far','other',proof)).kind=='walk')
assert(timers[1].cancelled and #state.creates==2)
assert(h:ObserveTravel(F.Location(4,'goal','other')).kind=='complete' and state.current==nil)
h:Plan({from='start',to='goal'},context) -- a newly localized request, independent of the completed trip
repeat r=h:Step() until r.status~='running'
local generation=h.generation
assert(h:ObservePortals(F.Observation(2))==false and h.generation==generation)
assert(h:ObservePortals(F.Observation(3,false)))
repeat r=h:Step() until r.status~='running'
assert(r.estimatedSeconds==27)
assert(h:ObservePortals(F.Observation(4)))
repeat r=h:Step() until r.status~='running'
assert(h:StartTravel(r,{},context))
h:ObserveTravel(F.Location(1,'gate','home')); h:BeginPortalUse()
local deadline=timers[#timers]; time=30; deadline.callback()
assert(h:GetTravelAction().reason=='transition_timeout')
h:Plan({from='goal',to='start'},context)
assert(h:GetTravelAction()==nil and state.current==nil)
assert(select(2,h:StartTravel(r,{},context))=='stale_result')
local unlocated=F.Catalog();unlocated[1].entry=nil;unlocated[1].name='Portal 12.3, 45.6'
assert(h:Enable(graph,{portals=unlocated,portalObservation=F.Observation()}))
h:Plan({from='start',to='goal'},context)
repeat r=h:Step() until r.status~='running'
local count=#state.creates
assert(h:StartTravel(r).position==nil and #state.creates==count)
h:ObserveTravel(F.Location(1,'gate','home'))
assert(h:GetTravelAction().title==nil,'coordinate titles are not visible')
h:BeginPortalUse()
local cancelledTimer=timers[#timers]
context='second'
assert(select(2,h:GetTravelAction())=='stale_context' and cancelledTimer.cancelled)
assert(h:GetTravelAction()==nil)
cancelledTimer.callback()
assert(h:GetTravelAction()==nil,'late callbacks cannot resurrect cancelled travel')
h:Disable()
assert(APR.navigation.legacy)
