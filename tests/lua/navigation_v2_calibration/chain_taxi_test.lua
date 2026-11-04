local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Raw(client)
    local route={id='flight',from='start',to='exit',fareCopper=4,timeoutSeconds=60,
        origin={id='departure',worldID=7,floorID=0,phaseID='present'},
        destination={id='arrival',worldID=8,floorID=0,phaseID='present'},
        costs={approach=0,boarding=1,ride=12,loading=2,disembark=1,final=0}}
    local options=e:Options({portals={},taxi={route},resources={money=20},
        taxiSettings={routes={flight={fareCopper=4,boarding=3,final=2}}},
        taxiObservation={revision=1,nodes={departure={discovered=true},arrival={discovered=true}},
            routes={flight={reachable=true,fareCopper=4}}}})
    options.personal=nil -- No unused personal catalogue may replace the explicit money observation.
    assert(e.host:Enable(F.Graph(),options))
    local result=e:Plan();assert(e:Start(result).kind=='approach')
    local function location(sequence,destination,onTaxi,attempt)
        return {sequence=sequence,reliable=true,loading=false,node=destination and 'exit' or 'start',
            stopID=destination and 'arrival' or 'departure',worldID=destination and 8 or 7,floorID=0,
            phaseID='present',onTaxi=onTaxi,taxiId='flight',attempt=attempt}
    end
    assert(e.host:ObserveTravel(location(1,false,false)).kind=='board_taxi')
    local action=assert(e.host:BeginTaxi({confirmed=true,originID='departure',destinationID='arrival',
        reachable=true,fareCopper=4},{money=20}))
    assert(action.kind=='awaiting_taxi' and e.host:GetCalibrationStats().accepted==0)
    e.time=105
    assert(e.host:ObserveTravel(location(2,false,true,action.attempt)).kind=='riding_taxi')
    local travel,journey=e.host.travel,e.host.journey
    assert(travel:GetMeasurement().startedAt==105,'quote/boarding wait excluded from ride')
    e.time=107;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=110;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    assert(e.host:GetCalibrationStats().accepted==0)
    local revision=e.host.planner.revision
    e.time=118
    assert(e.host:ObserveTravel(location(3,true,false,action.attempt)).kind=='replan')
    assert(e.host:GetCalibrationStats().accepted==1)
    assert(e.host:GetCalibrationCost('taxi/flight/ride')==10 and e.host:GetCalibrationCost('taxi/flight/loading')==3)
    assert(e.host.planner.revision==revision+1,'two adjusted components form one revision')
    assert(travel.measuredTaxi==nil and e.host.planner.taxi.routes.flight.rideSeconds==nil,'no parallel elapsed-duration update')
    local settings=e.host.planner.taxi.settings.flight
    assert(settings.fareCopper==4 and settings.boarding==3 and settings.final==2 and settings.ride==10 and settings.loading==3)
    assert(e.host.planner.resources.money==20,'calibration does not replace the observed resource balance')
    assert(e.host.journey==journey and journey.viaIndex==1 and e:Finish().estimatedSeconds==5)
    e.host:Disable()
end
-- Existing legacy duration observation is unchanged when calibration is off.
local Taxi=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
APRNavigationCharacterSettings={foreign='untouched'}
local host,_,env=Taxi.Host(false)
local route=Taxi.Route('flight','west','east',4,10)
local opts=Taxi.Options({route},10)
opts.observeTaxi=true;opts.taxiAPI=env.api;opts.clock=function()return env.time end
assert(host:Enable({complete=true,nodes={'west','east'},edges={}},opts))
host:ObserveWorld(false)
host:Plan({from='west',to='east'},env.context)
local result=Taxi.Finish(host.job)
assert(host:StartTravel(result).kind=='approach')
host:ObserveTravel({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
env:Fire('TAXIMAP_OPENED');assert(host:BeginTaxi())
env.onTaxi=true;env:Fire('PLAYER_CONTROL_LOST')
env.time=112;env.onTaxi=false
assert(host:ObserveTaxiFlight({reliable=true,node='east',stopID='east',worldID=7,floorID=0,phaseID='shared'}))
assert(host.planner.taxi.routes.flight.rideSeconds==12 and APRNavigationCharacterSettings.foreign=='untouched')
assert(host:GetCalibrationStats()==nil)
host:Disable()
