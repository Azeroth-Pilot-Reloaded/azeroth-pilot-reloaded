local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local d,o=F.Declarations(),F.Observation()
d[1].chargeBased=true;o.actions.recall.charges=1;o.actions.recall.maxCharges=3
local graph={complete=true,nodes={'cave','town'},edges={
    {id='normal',from='cave',to='town',seconds=20},{id='return',from='town',to='cave',seconds=1}}}
local function Finish(planner)
    return F.Base.Finish(planner:Plan({from='cave',to='town',via={'town','cave'}}))
end
local p=assert(F.Library.New(graph,F.Options(d,o)))
local r=Finish(p);assert(r.estimatedSeconds==26 and r.resourcesSpent['personal:recall']==1)
o.revision=2;o.actions.recall.charges=2;assert(p:ObservePersonal(o))
r=Finish(p);assert(r.estimatedSeconds==11 and r.resourcesSpent['personal:recall']==2)
-- A group shared by distinct abilities cannot allocate each ability a fresh budget.
d[1].cooldownGroup='shared_recall';d[2]=F.Declarations()[1]
d[2].id,d[2].spellID,d[2].chargeBased,d[2].cooldownGroup='second',903,true,'shared_recall'
o.actions.second={known=true,loaded=true,usable=true,readyAt=0,charges=1,maxCharges=3}
p=assert(F.Library.New(graph,F.Options(d,o)));r=Finish(p)
assert(r.estimatedSeconds==26 and r.resourcesSpent['personal:shared_recall']==1)
o.revision=3;o.actions.second.charges=2;assert(p:ObservePersonal(o));assert(Finish(p).estimatedSeconds==11)
o.revision=4;o.actions.second.charges=nil;assert(p:ObservePersonal(o))
assert(Finish(p).estimatedSeconds==41,'Unknown shared charges cannot be replaced with a fresh allocation')
o.revision=5;o.actions.second.charges=2;assert(p:ObservePersonal(o));assert(Finish(p).estimatedSeconds==11)
-- A full resource-map replacement is transactional at the32-key boundary.
d,o=F.Declarations(),F.Observation()
local balances={money=12,['item:travel_powder']=5,['personal:recall']=1}
for i=1,29 do balances['unrelated:'..i]=1 end
p=assert(F.Library.New(F.Graph(),F.Options(d,o)));assert(p:SetResources(balances))
r=F.Base.Finish(p:Plan({from='cave',to='goal'}));assert(r.estimatedSeconds==12)
local revision,resources=p.revision,p.resources
balances['overflow']=1
local changed,reason=p:SetResources(balances)
assert(changed==nil and reason=='resource_limit_exceeded' and p.revision==revision and p.resources==resources)
assert(p:IsCurrent(r) and p.resources['unrelated:29']==1 and p.resources.overflow==nil)
o.revision=2;o.items[902]=nil;assert(p:ObservePersonal(o))
assert(p.resources['item:travel_powder']==nil and p.resources['unrelated:29']==1)
assert(F.Base.Finish(p:Plan({from='cave',to='goal'})).estimatedSeconds==40)
o.revision=3;o.items[902]=5;assert(p:ObservePersonal(o))
assert(F.Base.Finish(p:Plan({from='cave',to='goal'})).estimatedSeconds==12)
