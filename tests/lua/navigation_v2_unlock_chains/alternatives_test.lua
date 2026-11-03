local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local p=F.Planner()
local r=F.Result(p)
assert(r.status=='complete' and r.unlock and r.unlock.id=='far-keeper',
    'Compare approach + declared realization + known remaining journey: far costs 4+3+2=9, near 1+10+30=41')
assert(r.estimatedSeconds==4 and r.travelObjective.to=='far' and #r.segments==1)
assert(r.objective.to=='goal' and not r.optimal and r.estimateScope=='unlock_approach')
assert(r.unlockPlan.estimatedSeconds==9 and r.unlockPlan.optimal and r.unlockPlan.conditional)
assert(#r.unlockPlan.steps==1 and r.unlockPlan.steps[1].id=='far-keeper')
assert(p.conditions.snapshot.access['far-open']==false and p.conditions.snapshot.access['near-open']==false)
local g=F.Graph();g.edges[#g.edges+1]={id='detour',from='start',to='goal',seconds=1000}
r=F.Result(F.Planner(g));assert(not r.unlock and r.estimatedSeconds==1000 and r.optimal)
