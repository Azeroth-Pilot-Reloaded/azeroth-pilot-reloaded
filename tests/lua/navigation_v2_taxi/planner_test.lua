local F = dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns = F.Load()
local routes = {F.Route('first flight','start','hub',6,1),F.Route('second flight','hub','goal',6,1)}
local graph = {complete=true,nodes={'start','hub','goal'},edges={
    {id='free approach',from='start',to='hub',seconds=8},
    {id='long walk',from='start',to='goal',seconds=30}}}
local planner = assert(ns.LibAPRNavigationV2.New(graph,F.Options(routes,10)))
local result = F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.status == 'complete' and result.estimatedSeconds == 11,
    'Keep the slower free arrival: two successive fares cost12, only10 available')
assert(result.segments[1].edgeId == 'free approach' and result.segments[2].taxiId == 'second flight')
assert(result.resourcesSpent.money == 6)
local revision=planner.revision
assert(planner:ObserveTaxi({revision=2,nodes=F.Options(routes,10).taxiObservation.nodes,
    routes=F.Options(routes,10).taxiObservation.routes})==false)
assert(planner.revision==revision and planner:IsCurrent(result))
assert(planner:SetResources({money=12}))
result=F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==6 and result.resourcesSpent.money==12)
local changed=F.Options(routes,10).taxiObservation;changed.revision=3;changed.routes['second flight'].fareCopper=100
assert(planner:ObserveTaxi(changed))
result=F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==30 and next(result.resourcesSpent)==nil)
-- Unknown money and undiscovered destinations stay explicit; free alternatives win.
local only={complete=true,nodes={'start','hub','goal'},edges={}}
local unknownOptions=F.Options(routes,nil)
local unknown=assert(ns.LibAPRNavigationV2.New(only,unknownOptions))
assert(F.Finish(unknown:Plan({from='start',to='goal'})).reason=='resources_unknown')
unknownOptions.taxiObservation.nodes.goal=nil
unknownOptions.resources.money=100
unknown=assert(ns.LibAPRNavigationV2.New(only,unknownOptions))
assert(F.Finish(unknown:Plan({from='start',to='goal'})).status=='unknown')
unknownOptions.taxiObservation.nodes.goal={discovered=false}
unknown=assert(ns.LibAPRNavigationV2.New(only,unknownOptions))
assert(F.Finish(unknown:Plan({from='start',to='goal'})).status=='no_path')
-- Missing ride time uses one central positive estimate; overrides outrank observations.
local missing=F.Route('missing','start','goal',1,nil)
assert(select(2,ns.NavigationV2Taxi.New({missing},false))=='invalid_taxi_observation')
assert(select(2,ns.NavigationV2Taxi.New({missing},nil,false))=='invalid_taxi_settings')
assert(select(2,ns.NavigationV2Taxi.New({missing},nil,{defaultRideSeconds=false}))=='invalid_taxi_settings')
local missingOptions=F.Options({missing},10)
missingOptions.taxiSettings={defaultRideSeconds=50,routes={missing={ride=20,fareCopper=2}}}
missingOptions.taxiObservation.routes.missing.rideSeconds=5
local timed=assert(ns.LibAPRNavigationV2.New(only,missingOptions))
result=F.Finish(timed:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==22 and result.resourcesSpent.money==2)
missingOptions.taxiSettings.routes={}
missingOptions.taxiObservation.routes.missing.rideSeconds=nil
timed=assert(ns.LibAPRNavigationV2.New(only,missingOptions))
result=F.Finish(timed:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==52 and result.segments[1].costDetail.estimatedRide==true)
missingOptions.taxiSettings=nil
timed=assert(ns.LibAPRNavigationV2.New(only,missingOptions))
assert(F.Finish(timed:Plan({from='start',to='goal'})).estimatedSeconds==182)
assert(timed:SetTaxiCosts('missing',{ride=1,fareCopper=3}))
result=F.Finish(timed:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==3 and result.resourcesSpent.money==3)
assert(timed:SetTaxiCosts('missing',{ride=1,fareCopper=3})==false)
assert(select(2,timed:SetTaxiCosts('missing',{ride=0}))=='invalid_taxi_costs')
assert(timed:SetTaxiCosts('missing',{}))
-- A malformed update is atomic; stale search/cancellation never reuses a result.
local old=timed:Plan({from='start',to='goal'});old:Step(1)
assert(select(2,timed:ObserveTaxi({revision=2,nodes={},routes={missing={fareCopper=-1}}}))=='invalid_taxi_observation')
assert(timed:SetResources({money=0}))
assert(old:Step().status=='stale')
assert(F.Finish(timed:Plan({from='start',to='goal'})).status=='no_path')
