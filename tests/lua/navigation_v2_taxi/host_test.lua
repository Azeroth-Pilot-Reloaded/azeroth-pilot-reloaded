local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
for _,awp in ipairs({false,true})do
    local h,ns,env,ws,as=F.Host(awp)
    local route=F.Route('flight','west','east',4,10)
    local options=F.Options({route},10);options.observeTaxi=true;options.taxiAPI=env.api
    options.clock=function()return env.time end
    local graph={complete=true,nodes={'west','east','goal'},edges={{id='exit',from='east',to='goal',seconds=2}}}
    assert(h:Enable(graph,options))
    assert(h.worldLoading==nil,'Taxi must not create a fake ready observation')
    assert(h:Plan({from='west',to='goal'}):GetResult().reason=='location_unknown')
    h:ObserveWorld(false)
    h:Plan({from='west',to='goal',via={'east'}},env.context)
    local result=F.Finish(h.job)
    local calls=env.calls
    assert(result.estimatedSeconds==14 and #ws.creates==0 and #env.timers==0)
    h:GetResult();h:Step();assert(env.calls==calls,'Step/GetResult never scan the taxi map')
    assert(h:StartTravel(result).kind=='approach')
    if awp then as:Flush();assert(as.record and #ws.creates==0)else assert(ws.current)end
    assert(h:ObserveTravel({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,
        phaseID='shared',onTaxi=false}).kind=='board_taxi')
    if awp then as:Flush();assert(as.record==nil)else assert(ws.current==nil)end
    env:Fire('TAXIMAP_OPENED')
    local taxiRevision=h.planner.taxi.revision
    assert(h:ObserveTaxi(options.taxiObservation)==false)
    assert(h.taxiSource.observation.revision==taxiRevision,'Stale external evidence cannot roll back the native source')
    env.fare=5
    assert(select(2,h:BeginTaxi())=='taxi_fare_changed')
    assert(not h.planner:IsCurrent(result),'A changed native quote invalidates the old plan immediately')
    assert(h.journey:RemainingRequest().from=='west')
    env.fare=4
    h:Plan(h.journey:RemainingRequest(),env.context);result=F.Finish(h.job)
    assert(h:StartTravel(result).kind=='approach')
    h:ObserveTravel({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
    local action=assert(h:BeginTaxi())
    assert(action.kind=='awaiting_taxi' and #env.timers==1)
    assert(not h.journey:RemainingRequest())
    env.onTaxi=true;env:Fire('PLAYER_CONTROL_LOST')
    assert(h:GetTravelAction().kind=='riding_taxi')
    local attempt=h:GetTravelAction().attempt
    env.money=6;env:Fire('PLAYER_MONEY')
    env:Fire('PLAYER_LEAVING_WORLD')
    assert(h:GetTravelAction().attempt==attempt and not h.journey:RemainingRequest())
    env.time=112
    env:Fire('PLAYER_ENTERING_WORLD');env.onTaxi=false;env:Fire('PLAYER_CONTROL_GAINED')
    assert(h:GetTravelAction().kind=='riding_taxi','Flight ended and ready still do not identify destination')
    local landing={reliable=true,node='east',stopID='east',worldID=7,floorID=0,phaseID='wrong'}
    assert(h:ObserveTaxiFlight(landing).kind=='riding_taxi')
    landing.phaseID='shared'
    assert(h:ObserveTaxiFlight(landing).kind=='replan')
    assert(h.journey.objective.from=='west' and h.journey.objective.to=='goal' and h.journey.viaIndex==1)
    assert(env.timers[1].cancelled)
    result=F.Finish(h.job)
    assert(result.estimatedSeconds==2 and result.objective.from=='east' and #result.objective.via==0)
    assert(h.planner.taxi.routes.flight.rideSeconds==12,'Only proven arrival calibrates observed duration')
    assert(h:StartTravel(result,{resolveTarget=function()
        return {key='goal',title='Destination',position={mapID=77,x=.4,y=.6}}
    end}).kind=='walk')
    assert(h:ObserveTravel({sequence=1,reliable=true,node='goal'}).kind=='complete')
    assert(h:ResetTaxiDurations())
    assert(h.planner.taxi.routes.flight.rideSeconds==nil)
    assert(h:ResetTaxiDurations()==false)
    assert(APR.navigation.legacy)
    h:Disable()
    for _,frame in ipairs(env.frames)do assert(next(frame.events)==nil)end
end
