local H=dofile('tests/lua/navigation_v2_portals/host_fixture.lua')
local S=dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
local h,ns,env,ws=H.Load(false)
local route=S.Route();route.from='start';route.to='goal';route.access='available'
local graph={complete=true,nodes={'start','goal'},edges={}}
assert(env:Enable(graph,{scheduled={route}}))
h:Plan({from='start',to='goal'},env.context);local r=H.Finish(h)
local a=assert(h:StartTravel(r,{objectiveID='test',scheduledTimeoutSeconds=10}))
assert(a.kind=='scheduled' and a.phase=='approach' and #env.timers==1 and ws.current)
assert(select(2,h:StartTravel(r,false))=='invalid_travel_options')
assert(select(2,h:StartTravel(r,{scheduledTimeoutSeconds=false}))=='invalid_travel_options')
assert(select(2,h:StartTravel(r,{objectiveID=false}))=='invalid_travel_options')
assert(h:GetTravelAction().attempt==a.attempt and #env.timers==1)
local generation,revision=h.generation,h.planner.revision
assert(h:SetScheduled({route})==false)
assert(h.generation==generation and h.planner.revision==revision and h:GetTravelAction().attempt==a.attempt)
local o={kind='origin',sequence=1,routeID=route.id,objectiveID='test',attempt=a.attempt,confirmed=true,
    stopID=route.origin.id,worldID=route.origin.worldID,floorID=route.origin.floorID,phaseID=route.origin.phaseID,
    onTransport=false,loading=true}
assert(h:ObserveTravel(o).phase=='approach')
o.loading=false
assert(h:ObserveTravel(o).phase=='waiting' and ws.current==nil)
local timer=env.timers[1]
env.time=110;timer.callback()
assert(h:GetTravelAction().kind=='failed' and h:GetTravelAction().reason=='transport_deadline')
assert(#env.timers==1 and h.generation==generation,'missing arrival cannot restart unchanged work')
assert(h:ObserveTravel(o).kind=='failed')

-- A fresh localized request is required after the terminal unknown position.
assert(select(2,h:StartTravel(r,{objectiveID='test'}))=='location_unknown')
h:Plan({from='start',to='goal'},env.context);r=H.Finish(h)
a=assert(h:StartTravel(r,{objectiveID='test',scheduledTimeoutSeconds=10}))
assert(a.attempt~=o.attempt and #env.timers==2)
assert(h:SetScheduled({route},{[route.id]={ride=1}}))
assert(h:GetTravelAction()==nil and env.timers[2].cancelled and ws.current==nil)
assert(select(2,h:StartTravel(r))=='stale_result')
h:Plan({from='start',to='goal'},env.context);r=H.Finish(h)
assert(r.estimatedSeconds==33)
a=h:StartTravel(r,{scheduledTimeoutSeconds=10})
local latest=env.timers[#env.timers]
h:Plan({from='goal',to='start'},env.context)
assert(h:GetTravelAction()==nil and latest.cancelled)
latest.callback();assert(h:GetTravelAction()==nil)

-- Missing real stop positions must never fall back to an invented marker.
route.origin.position,route.destination.position=nil,nil
assert(h:SetScheduled({route}))
h:Plan({from='start',to='goal'},env.context);r=H.Finish(h)
local count=#ws.creates
assert(h:StartTravel(r,{resolveTarget=function()error('Nonpositional transport cannot call resolver')end}).kind=='scheduled')
assert(#ws.creates==count and ws.current==nil)
local profile=assert(ns.LibAPRNavigationV2.NewForeverMovement({initialMode='walk'}))
assert(h:SetMovement(profile) and h:GetTravelAction()==nil)
assert(env.questCalls==0)
h:Disable()
