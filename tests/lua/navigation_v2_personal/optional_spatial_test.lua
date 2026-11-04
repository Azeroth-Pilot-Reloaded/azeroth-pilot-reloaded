local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local declarations=F.Declarations();declarations[1].destination.phase=nil
local c=assert(F.Personal.New(declarations,F.Observation()),'Destination phase is optional')
assert(c.byId.recall.destination.phase==nil and c:Edge('cave',1).access=='available')
local function new()
    return assert(c:NewExecution('recall',{objectiveID='quest',now=100,from='cave'}))
end
for _,observed in ipairs({false,true}) do
    local e=new();local started=assert(e:BeginUse(100))
    local o={sequence=1,reliable=true,node='town',space='world',phase=observed and 'observed' or nil}
    assert(e:Observe(o,101).status=='running','Node/space alone never prove use')
    o.sequence=2;o.transition={personalId='recall',from='cave',to='town',complete=true,attempt={}}
    assert(e:Observe(o,102).status=='running','Attempt must correlate')
    o.sequence=3;o.transition.attempt=started.attempt;o.loading=true
    assert(e:Observe(o,103).status=='running','Loading never proves arrival')
    o.sequence=4;o.loading=false;o.space='other'
    assert(e:Observe(o,104).status=='running','Space remains mandatory')
    o.sequence=5;o.space='world';o.reliable=false
    assert(e:Observe(o,105).status=='running')
    o.reliable=true;assert(e:Observe(o,106).status=='running','A sequence cannot be replayed')
    o.sequence=6;assert(e:Observe(o,107).status=='complete')
end
for _,bad in ipairs({false,'',4,{}}) do
    declarations=F.Declarations();declarations[1].destination.phase=bad
    assert(F.Personal.New(declarations,F.Observation())==nil)
end
declarations=F.Declarations();declarations[1].origin={phase='present'}
local o=F.Observation();o.origin.phase=nil
local constrained=assert(F.Personal.New(declarations,o))
assert(constrained:Edge('cave',1).access=='unknown')
o=F.Observation(2);o.origin.phase='other';assert(constrained:Observe(o))
assert(constrained:Edge('cave',1).access=='unavailable')
o=F.Observation(3);assert(constrained:Observe(o))
assert(constrained:Edge('cave',1).access=='available')
local e=new();assert(e:BeginUse(100));e:Cancel('objective_replaced')
assert(e:Observe({sequence=1},101).status=='cancelled')
e=new();assert(e:BeginUse(100))
o=F.Observation(2);o.items[902]=3
assert(c:Observe(o))
assert(e:GetState().reason=='invalidated','Observation changes still invalidate live use')
