local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=F.Load()
local route=F.Route('flight','west','east',10,20)
local options=F.Options({route},10)
local catalog=assert(ns.NavigationV2Taxi.New({route},options.taxiObservation))
assert(loadfile('APR-Core/features/navigation/NavigationV2Taxi.lua'))('test',ns)
local slots,costCalls=0,0
local state={types={'CURRENT','REACHABLE'},fare=4,money=9}
local api={GetTaxiMapID=function()return 77 end,NumTaxiNodes=function()return 2 end,
    TaxiNodeGetType=function(slot)slots=slots+1;return state.types[slot]end,
    TaxiNodeCost=function(slot)assert(slot==2);costCalls=costCalls+1;return state.fare end,
    GetMoney=function()return state.money end,
    UnitOnTaxi=function(unit)assert(unit=='player');return state.flying end,
    C_TaxiMap={GetAllTaxiNodes=function(map)assert(map==77);return {
        {nodeID=10,slotIndex=1,name='Ambiguous localized name'},
        {nodeID=20,slotIndex=2,name='Ambiguous localized name'},
        {nodeID=999,slotIndex=0}} end}}
local snapshot,balances,quotes=ns.NavigationV2TaxiAdapter.Capture(catalog,options.taxiObservation,api,true)
assert(snapshot.nodes.west.discovered and snapshot.nodes.east.discovered)
assert(snapshot.routes.flight.fareCopper==4 and balances.money==9 and quotes.flight.confirmed)
assert(costCalls==1 and slots==2)
assert(catalog:Observe(snapshot))
assert(catalog:Edge('west',1).fareCopper==4,'Observed fare overrides declared fare')
local calls=costCalls
local closed,_,closedQuotes=ns.NavigationV2TaxiAdapter.Capture(catalog,snapshot,api,false)
assert(next(closedQuotes)==nil and costCalls==calls and closed.routes.flight.fareCopper==4)
assert(catalog:Observe(closed)==false,'same observations never cause an identical reroute')
assert(catalog:Observe(snapshot)==false,'stale observations ignored')
state.fare=nil;state.money=nil;state.types[2]=nil
local missing,unknown,unquoted=ns.NavigationV2TaxiAdapter.Capture(catalog,closed,api,true)
assert(missing.routes.flight.reachable==nil and missing.routes.flight.fareCopper==nil)
assert(unknown.money==nil and unquoted.flight.confirmed==false)
assert(catalog:Observe(missing))
assert(catalog:Edge('west',1).access=='unknown','nil must not turn into unavailable')
state.fare=0;state.types[2]='DISTANT'
local undiscovered=ns.NavigationV2TaxiAdapter.Capture(catalog,missing,api,true)
assert(undiscovered.routes.flight.reachable==false and undiscovered.routes.flight.fareCopper==nil)
assert(costCalls==calls,'undiscovered zero fare is not a free flight')
state.types[2]='REACHABLE';state.fare=0
local free=ns.NavigationV2TaxiAdapter.Capture(catalog,undiscovered,api,true)
assert(free.routes.flight.fareCopper==0)
local secret={}
api.issecretvalue=function(value)return value==secret end
state.fare,state.money=secret,secret
local restricted,restrictedBalances,restrictedQuotes=ns.NavigationV2TaxiAdapter.Capture(catalog,free,api,true)
assert(restricted.routes.flight.fareCopper==nil and restrictedBalances.money==nil and not restrictedQuotes.flight.confirmed)
assert(catalog:Observe(restricted))
assert(catalog:Edge('west',1).access=='unknown','A hidden observed fare cannot fall back to a stale declared fare')
state.flying=true;assert(ns.NavigationV2TaxiAdapter.OnTaxi(api)==true)
state.flying=secret;assert(ns.NavigationV2TaxiAdapter.OnTaxi(api)==nil)
-- A third business stop using the same API attribute cannot acquire an identity.
local ambiguous=F.Route('other flight','other','last',1,1)
ambiguous.origin.taxiNodeID=10;ambiguous.destination.taxiNodeID=21
local collision=assert(ns.NavigationV2Taxi.New({route,ambiguous}))
local observed=ns.NavigationV2TaxiAdapter.Capture(collision,nil,api,true)
assert(observed.nodes.west==nil and observed.nodes.other==nil and next(observed.routes)==nil)
api.issecretvalue=function()return nil end
local uncertain,uncertainMoney=ns.NavigationV2TaxiAdapter.Capture(catalog,restricted,api,true)
assert(uncertainMoney.money==nil and uncertain.routes.flight==nil,'An uncertain public-value predicate is not evidence')
