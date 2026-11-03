local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local C=F.ns.NavigationV2Cooldowns
local p={recall={readyAt=0,chargeBased=false}}
assert(not C.Dominates(p,{recall={readyAt=115}},{},110),
    'Earlier arrival with a busy ability cannot delete a later unspent label')
assert(C.Dominates(p,{recall={readyAt=115}},{},115))
assert(next(C.Trim(p,{recall={readyAt=115}},115))==nil,'Expired timers are not state dimensions')
local q={recall={readyAt=0,chargeBased=true,charges=3,maximum=3,duration=10}}
assert(not C.Dominates(q,{recall={charges=2,nextAt=140}},{recall={charges=1,nextAt=110}},100),
    'More current charges does not dominate an earlier recharge sequence')
assert(C.Dominates(q,{recall={charges=2,nextAt=120}},{recall={charges=1,nextAt=110}},100))
assert(next(C.Trim(q,{recall={charges=1,nextAt=110}},120))==nil,'A restored queue is not historical state')
-- The graph contains cheap loops and32 irrelevant balances. History must not
-- create an endless family of labels or copy unrelated resources into a result.
local d,o=F.Declarations(),F.Observation();d[1].useSeconds=1;d[1].loadingSeconds=0
d[1].cooldownSeconds=2;d[1].moneyCopper=0;d[1].reagents={}
local options=F.Options(d,o)
options.resources={};for i=1,30 do options.resources['irrelevant:'..i]=1 end
local g={complete=true,nodes={'cave','town','goal'},edges={
    {id='return',from='town',to='cave',seconds=3},{id='finish',from='town',to='goal',seconds=100}}}
local planner=assert(F.Library.New(g,options))
local r=F.Base.Finish(planner:Plan({from='cave',to='goal'}),1)
assert(r.estimatedSeconds==101 and r.diagnostics.expanded<=4 and r.diagnostics.operations<80)
assert(r.resourcesSpent['personal:recall']==1 and r.resourcesSpent['irrelevant:1']==nil)
