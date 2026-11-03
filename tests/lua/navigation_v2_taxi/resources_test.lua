local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=F.Load()
local graph={complete=true,nodes={'start','hub','goal'},edges={
    {id='fast costly',from='start',to='hub',seconds=1,resources={dust=1,money=3}},
    {id='slow free',from='start',to='hub',seconds=4},
    {id='consumable',from='hub',to='goal',seconds=1,resources={dust=1,money=3}},
    {id='free fallback',from='start',to='goal',seconds=20}}}
local options={resources={dust=1,money=5},clock=function()return 0 end,profileClock=function()return 0 end}
local planner=assert(ns.LibAPRNavigationV2.New(graph,options))
options.resources.dust=0 -- isolated balance capture
local result=F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==5 and result.resourcesSpent.dust==1 and result.resourcesSpent.money==3)
assert(planner:SetResources({dust=2,money=6}))
assert(not planner:IsCurrent(result))
result=F.Finish(planner:Plan({from='start',to='goal',via={'hub'}}))
assert(result.estimatedSeconds==2 and result.resourcesSpent.dust==2 and result.resourcesSpent.money==6)
assert(planner:SetResources({dust=0,money=0}))
result=F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==20 and next(result.resourcesSpent)==nil)
assert(planner:SetResources({money=6}))
assert(F.Finish(planner:Plan({from='hub',to='goal'})).reason=='resources_unknown')
local job=planner:Plan({from='start',to='goal'});assert(job:Cancel().status=='cancelled')
assert(F.Finish(planner:Plan({from='start',to='goal'})).estimatedSeconds==20)
assert(planner:SetResources({money=6})==false)
assert(select(2,planner:SetResources({dust=-1}))=='invalid_resources')
assert(select(2,planner:SetResources({dust=0/0}))=='invalid_resources')
