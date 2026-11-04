local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local e=F.Host();e:Enable();local old=e:Ready()
local b=assert(e.host:GetPersonalButton())
local planner,job,travel=e.host.planner,e.host.job,e.host.travel
local balances={}
for i=1,30 do balances['extra:'..i]=1 end
local accepted,reason=e.host:Enable(F.Graph(),{personal=F.Declarations(),resources=balances})
assert(accepted==nil and reason=='resource_limit_exceeded')
assert(e.host.planner==planner and e.host.job==job and e.host.travel==travel and planner:IsCurrent(old))
assert(b.attributes.type=='spell','A rejected transaction cannot partially replace the active host')
-- Reducing below the limit gives a valid replacement; nothing is truncated.
balances['extra:30'],balances['extra:29']=nil,nil
assert(e.host:Enable(F.Graph(),{personal=F.Declarations(),resources=balances}))
assert(e.host.planner~=planner and b.attributes.type==nil)
assert(e.host.planner.resources['extra:28']==1)
-- Canonical aliases also survive Planner's captured catalogue replacement.
local d=F.Declarations();d[1].moneyCopper=0
d[2]=F.Declarations()[1];d[2].id,d[2].spellID='other',903
d[2].reagents={alias={itemID=902,count=4}}
local o=F.Observation();o.actions.other={known=true,loaded=true,usable=true,readyAt=0}
local p=assert(F.Library.New(F.Graph(),F.Options(d,o)))
assert(p.resources['item:travel_powder']==5 and p.resources['item:alias']==nil)
o.revision=2;o.items[902]=4;assert(p:ObservePersonal(o))
assert(p.resources['item:travel_powder']==4 and p.resources['item:alias']==nil)
o.revision=3;o.items[902]=nil;assert(p:ObservePersonal(o))
assert(p.resources['item:travel_powder']==nil and p.resources['item:alias']==nil)
local r=F.Base.Finish(p:Plan({from='cave',to='goal'}));assert(r.estimatedSeconds==40)
o.revision=4;o.items[902]=5;assert(p:ObservePersonal(o))
assert(F.Base.Finish(p:Plan({from='cave',to='goal'})).estimatedSeconds==12)
