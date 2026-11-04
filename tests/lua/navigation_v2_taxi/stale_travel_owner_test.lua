local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
for _,awp in ipairs({false,true})do
    local h,ns,env,ws,as=F.Host(awp)
    local route=F.Route('flight','west','east',4,10)
    assert(h:Enable({complete=true,nodes={'west','east'},edges={}},F.Options({route},10)))
    h:ObserveWorld(false);h:Plan({from='west',to='east'},env.context)
    local result=F.Finish(h.job);h:StartTravel(result)
    h:ObserveTravel({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
    assert(h:BeginTaxi({confirmed=true,originID='west',destinationID='east',reachable=true,fareCopper=4},{money=10}))
    local oldTimer=env.timers[#env.timers]
    env.context='new objective'
    assert(h:SetTarget({key='new goal',title='Destination',position={mapID=77,x=.3,y=.4}},env.context)=='active')
    if awp then as:Flush();assert(as.record)else assert(ws.current)end
    env.time=400;oldTimer.callback()
    if awp then assert(as.record,'Expired travel timer cannot clear a newer current owner')
    else assert(ws.current,'Expired travel timer cannot clear a newer current owner')end
    h:GetResult();h:Step()
    if awp then assert(as.record,'Expired planning callbacks cannot clear a newer owner')
    else assert(ws.current,'Expired planning callbacks cannot clear a newer owner')end
    h:Disable()
end
