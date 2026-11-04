local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local d,o=F.Declarations(),F.Observation();d[1].chargeBased=true;d[1].moneyCopper=0;d[1].reagents={}
local a=o.actions.recall;a.charges=1;a.maxCharges=2;a.rechargeStart=95;a.rechargeSeconds=10;a.rechargeRate=1
local time={wall=100}
local graph={complete=true,nodes={'cave','town'},edges={{id='return',from='town',to='cave',seconds=1}}}
local p=assert(F.Library.New(graph,F.Options(d,o,time)))
local request={from='cave',to='town',via={'town','cave'}}
local result=F.Base.Finish(p:Plan(request));assert(result.estimatedSeconds==11)
local job=p:Plan(request)
-- The public count did not refill despite the old forecast's completion.
-- The new snapshot must revoke that forecast, even without a field change.
o.revision=2;o.observedAt=106;time.wall=106
assert(p:ObservePersonal(o),'Expired recharge proof invalidates an unchanged raw count')
assert(not p:IsCurrent(result) and job:Step().status=='stale')
assert(F.Base.Finish(p:Plan(request)).status=='unknown')
