local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local h,ns,env,ws=F.Host(false)
local route=F.Route('flight','west','east',4,10)
route.origin.position=nil;route.origin.title='Flight master 12.3, 45.6'
local options=F.Options({route},10)
assert(h:Enable({complete=true,nodes={'west','east'},edges={}},options))
h:ObserveWorld(false)
h:Plan({from='west',to='east'},env.context)
local result=F.Finish(h.job)
local a=h:StartTravel(result,{resolveTarget=function()error('No invented approach point')end})
assert(a.kind=='approach' and a.title==nil and a.position==nil and #ws.creates==0)
h:ObserveTravel({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
local quote={confirmed=true,originID='west',destinationID='east',reachable=true,fareCopper=4}
assert(h:BeginTaxi(quote,{money=10}))
local timer=env.timers[1]
env.context='replaced'
assert(select(2,h:GetTravelAction())=='stale_context')
assert(timer.cancelled and not h.journey:RemainingRequest())
timer.callback();assert(h:GetTravelAction()==nil and #ws.creates==0)
h:Disable()
