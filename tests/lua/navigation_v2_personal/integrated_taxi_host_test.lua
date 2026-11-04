local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local e=F.Host();e.money=13
local taxi=F.Taxi(9)
local api={GetMoney=function()return e.money end,UnitOnTaxi=function()return false end,
    GetTaxiMapID=function()return 77 end,NumTaxiNodes=function()return 2 end,
    TaxiNodeGetType=function(slot)return slot==1 and 'CURRENT' or 'REACHABLE'end,
    TaxiNodeCost=function()return 9 end,
    C_TaxiMap={GetAllTaxiNodes=function()return {{nodeID=1,slotIndex=1},{nodeID=2,slotIndex=2}}end},
    TakeTaxiNode=function()error('No automatic taxi interaction')end}
local graph={complete=true,nodes={'cave','town','goal'},edges={
    {id='approach',from='cave',to='town',seconds=18},{id='whole walk',from='cave',to='goal',seconds=70}}}
e:Enable(nil,{taxi={taxi},taxiObservation=F.TaxiObservation(9),observeTaxi=true,taxiAPI=api},graph)
e.host:Plan({from='cave',to='goal'},e.context)
local r=e:Finish();assert(r.estimatedSeconds==11 and r.resourcesSpent.money==13)
assert(r.resourcesSpent['item:travel_powder']==2)
assert(e.host:StartTravel(r).kind=='personal')
assert(e.host.planner.resources['item:travel_powder']==5)
e.money=12;assert(e.host:ObserveTaxi())
assert(e.host.planner.resources.money==12 and e.host.planner.resources['item:travel_powder']==5)
assert(not e.host.planner:IsCurrent(r))
e.host:Plan({from='cave',to='goal'},e.context)
r=e:Finish();assert(r.estimatedSeconds==24 and r.resourcesSpent.money==9,'Shared budget cannot reset after Personal')
e.money=13;e.stock[902]=nil
e.host:Plan({from='cave',to='goal'},e.context)
assert(e:Finish().estimatedSeconds==24 and e.host.planner.resources['item:travel_powder']==nil)
e.stock[902]=5;e.host:Plan({from='cave',to='goal'},e.context)
assert(e:Finish().estimatedSeconds==11 and e.host.planner.resources['item:travel_powder']==5)
assert(e.protectedUses==0 and e.quests==0 and #e.ws.creates==0)
