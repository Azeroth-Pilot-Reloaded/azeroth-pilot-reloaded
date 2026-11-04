local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local c=assert(F.Personal.New(F.Declarations(),F.Observation()))
local function new()return assert(c:NewExecution('recall',{objectiveID='quest',now=100,from='cave'}))end
local e=new();assert(e:GetState().phase=='ready' and not e:GetState().position)
local state=assert(e:BeginUse(101));assert(state.phase=='awaiting_transition' and state.deadline==121)
local o={sequence=1,reliable=true,node='town',space='world',phase='present'}
assert(e:Observe(o,102).status=='running','Loading/cast/position alone is not arrival')
o.sequence=2;o.transition={personalId='recall',from='cave',to='town',complete=true,attempt={}}
assert(e:Observe(o,103).status=='running','Reject uncorrelated attempt')
o.sequence=3;o.transition.attempt=state.attempt;o.phase='wrong'
assert(e:Observe(o,104).status=='running')
o.sequence=4;o.phase='present';o.loading=true;assert(e:Observe(o,105).status=='running')
o.sequence=5;o.loading=false;assert(e:Observe(o,106).status=='complete')
e=new();assert(e:BeginUse(100));assert(e:Tick(120).reason=='transition_timeout')
assert(e:BeginUse(121)==nil)
e=new();e:Cancel('objective_replaced');assert(e:GetState().reason=='objective_replaced')
e=new();assert(e:Tick(99).reason=='clock_unavailable')
e=new();local observation=F.Observation(2);observation.items[902]=3
assert(c:Observe(observation));assert(e:GetState().reason=='invalidated')
assert(c:NewExecution('recall',{objectiveID='quest',now=100,from='exit'})==nil)
observation=F.Observation(3);observation.moneyCopper=3;assert(c:Observe(observation))
local denied,reason=c:NewExecution('recall',{objectiveID='quest',now=100,from='cave'})
assert(denied==nil and reason=='resources_insufficient')
observation=F.Observation(4);observation.items[902]=nil;assert(c:Observe(observation))
denied,reason=c:NewExecution('recall',{objectiveID='quest',now=100,from='cave'})
assert(denied==nil and reason=='resources_unknown')
