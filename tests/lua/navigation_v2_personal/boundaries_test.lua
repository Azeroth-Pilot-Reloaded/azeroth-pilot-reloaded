local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local bad={false,0/0,math.huge,-1,'unknown'}
for _,value in ipairs(bad) do
    local declarations=F.Declarations();declarations[1].useSeconds=value
    assert(F.Personal.New(declarations,F.Observation())==nil)
end
for _,key in ipairs({'combat','casting','loading','observedAt'}) do
    local observation=F.Observation();observation[key]=nil
    local c=assert(F.Personal.New(F.Declarations(),observation))
    assert(c:Edge('cave',1).access=='unknown')
end
local c=assert(F.Personal.New(F.Declarations(),F.Observation()))
local before=c:Edge('cave',1)
assert(c:Observe({revision=0})==nil)
assert(c:Edge('cave',1).seconds==before.seconds)
assert(c:SetCosts('recall',{useSeconds=3})==false)
assert(c:SetCosts('recall',{moneyCopper=2})==nil)
local graph={index={town=true}}
assert(c:Prepare(graph)==false and c:Prepare(graph)==true)
local declarations=F.Declarations();declarations[1].from='cave'
c=assert(F.Personal.New(declarations,F.Observation()))
local ready,status,reason=c:Prepare({index={town=true}})
assert(ready==nil and status=='invalid' and reason=='invalid_personal_node')
declarations=F.Declarations();declarations[1].origin={outdoorsOnly=true}
c=assert(F.Personal.New(declarations,F.Observation()));assert(c:Edge('cave',1).access=='unavailable')
declarations[1].origin.outdoorsOnly=false
c=assert(F.Personal.New(declarations,F.Observation()));assert(c:Edge('cave',1).access=='available')
local o=F.Observation();o.actions.recall.readyAt=103
c=assert(F.Personal.New(F.Declarations(),o));assert(c:Edge('cave',1).access=='unknown')
o.revision=2;o.observedAt=103;assert(c:Observe(o));assert(c:Edge('cave',1).access=='available')
o.revision=3;o.observedAt=104;assert(c:Observe(o)==false,'Time sampling alone need not invalidate identical availability')
declarations=F.Declarations();declarations[2]=F.Declarations()[1];declarations[2].id='other';declarations[2].cooldownSeconds=0
assert(F.Personal.New(declarations,F.Observation())==nil,'One API ability cannot have conflicting usage budgets')
declarations=F.Declarations();declarations[1].from='other'
declarations[2]=F.Declarations()[1];declarations[2].id='local';declarations[2].spellID=903
o=F.Observation();o.actions['local']={known=true,loaded=true,usable=true,readyAt=0}
c=assert(F.Personal.New(declarations,o))
assert(c:Edge('cave',1).personalId=='local' and c:Edge('cave',2)==nil,'Outgoing cursors have no declaration-index holes')
o=F.Observation();o.origin=nil
c=assert(F.Personal.New(F.Declarations(),o))
assert(c:Edge('cave',1).access=='unknown','An unobserved origin must not erase an unknown shortcut')
o=F.Observation();o.actions.recall.loaded=false
c=assert(F.Personal.New(F.Declarations(),o));assert(c:Edge('cave',1).access=='unknown','Unloaded is unknown, never an impossibility proof')
