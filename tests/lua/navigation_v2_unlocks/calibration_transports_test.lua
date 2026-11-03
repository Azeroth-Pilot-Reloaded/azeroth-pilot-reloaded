local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
local Taxi=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local Scheduled=dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
local function Options()
    return {calibration={client='Forever',build='build',computer='pc',api={UnitGUID=function()return 'Player-test'end}},
        observeConditions=false,conditionObservation={sequence=1,worldState='ready',access={['garden-open']=false}},
        observePersonal=false,personalObservation={revision=1,observedAt=100,combat=false,casting=false,loading=false,
            moneyCopper=20,origin={node='cave',reliable=true},actions={}}}
end
APRNavigationCharacterSettings={}
local route=Taxi.Route('flight','cave','town',4,10);route.costs.loading=3
local options=Options();options.taxi={route}
options.taxiObservation={revision=1,nodes={cave={discovered=true},town={discovered=true}},
    routes={flight={reachable=true,fareCopper=4}}}
options.taxiSettings={routes={flight={fareCopper=4,approach=2,boarding=3,disembark=4,final=5}}}
local e=F.Host('Camelot',false,options,F.Graph(100))
local result=e:Result();assert(result.segments[1].kind=='taxi');e:Start(result)
e.host:ObserveTravel({sequence=1,reliable=true,node='cave',stopID='cave',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
local action=assert(e.host:BeginTaxi({confirmed=true,originID='cave',destinationID='town',reachable=true,fareCopper=4},{money=20}))
assert(not e.host.calibrationMeasurement,'Taxi purchase is not boarding')
e.time=105
action=e.host:ObserveTravel({sequence=2,reliable=true,taxiId='flight',attempt=action.attempt,onTaxi=true})
assert(e.host.calibrationMeasurement)
e.time=107;e:Fire('PLAYER_LEAVING_WORLD');e.time=110;e:Fire('PLAYER_ENTERING_WORLD',false,false)
local revision=e.host.planner.revision;e.time=125
action=e.host:ObserveTravel({sequence=3,reliable=true,taxiId='flight',attempt=action.attempt,onTaxi=false,loading=false,
    node='town',stopID='town',worldID=7,floorID=0,phaseID='shared'})
assert(action.kind=='replan' and action.reason=='calibration')
assert(e.host.planner.revision==revision+1,'Ride/loading updates coalesce into one revision')
local costs=e.host.planner.taxi.settings.flight
assert(costs.ride==17 and costs.approach==2 and costs.boarding==3 and costs.disembark==4 and costs.final==5 and costs.fareCopper==4)
assert(e.host.planner.taxi.routes.flight.rideSeconds==nil,'Legacy full elapsed duration is not charged alongside calibration')
assert(e.host:GetCalibrationStats().accepted==1 and e:Finish().objective.from=='town')
e.host:Disable()

APRNavigationCharacterSettings={}
route=Scheduled.Route();route.id='ferry';route.from='cave';route.to='town';route.access='available'
options=Options();options.scheduled={route}
options.scheduledOverrides={ferry={approach=4,boarding=5,disembark=6,final=7,wait={mode='known',seconds=0}}}
e=F.Host('Standard',false,options,F.Graph(100))
result=e:Result();assert(result.segments[1].kind=='scheduled');action=e:Start(result)
local function Observe(kind,sequence,destination,onTransport)
    local stop=destination and route.destination or route.origin
    e.time=100+sequence
    return e.host:ObserveTravel({kind=kind,sequence=sequence,objectiveID='navigation',routeID='ferry',confirmed=true,
        stopID=stop.id,worldID=stop.worldID,floorID=stop.floorID,phaseID=stop.phaseID,
        attempt=action.attempt,onTransport=onTransport})
end
action=Observe('origin',1,false,false);action=Observe('transport_ready',2,false,false)
action=Observe('boarded',3,false,true)
assert(not e.host.calibrationMeasurement,'Boarded scheduled transport has not departed')
action=Observe('departed',4,false,true);assert(e.host.calibrationMeasurement)
e.time=106;e:Fire('PLAYER_LEAVING_WORLD');e.time=109;e:Fire('PLAYER_ENTERING_WORLD',false,false)
action=Observe('destination',24,true,true)
assert(action.phase=='disembarking' and e.host:GetCalibrationStats().accepted==0)
revision=e.host.planner.revision
action=Observe('disembarked',40,true,false)
assert(action.kind=='replan' and action.reason=='calibration')
assert(e.host.planner.revision==revision+1)
costs=e.host.planner.scheduled.byId.ferry.costs
assert(costs.ride==17 and costs.loading==3,'Ride excludes both loading and disembarking')
assert(costs.approach==4 and costs.boarding==5 and costs.disembark==6 and costs.final==7)
assert(e.host.planner.scheduled.byId.ferry.wait.mode=='known' and e.host.planner.scheduledDeclarations[1].destination.id==route.destination.id)
assert(e.host:GetCalibrationStats().accepted==1 and e:Finish().objective.from=='town' and e.quests==0)
e.host:Disable()
