local F=dofile('tests/lua/navigation_v2/fixture.lua')
local g={complete=true,nodes={'a','b','c'},edges={
    {id='first',from='a',to='b',seconds=1,resources={money=2}},
    {id='second',from='b',to='c',seconds=1,resources={money=2}}}}
local p=assert(F.Library.New(g,{resources={money=4},clock=function()return 0 end,profileClock=function()return 0 end}))
local first=F.Finish(p:Plan({from='a',to='c'}))
assert(first.status=='complete' and first.resourcesSpent.money==4)
first.segments[1].resources.money=999
local again=F.Finish(p:Plan({from='a',to='c'}))
assert(again.status=='complete' and again.resourcesSpent.money==4,
    'editing a public result must not mutate the reusable graph resource prices')
local U=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
p=U.Planner();local selected=U.Result(p).unlockEntry
assert(not selected.proof.snapshot and not selected.proof.bindings,
    'a public prerequisite result must not expose tracker/search support history')
