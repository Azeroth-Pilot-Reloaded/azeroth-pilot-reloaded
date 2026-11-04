local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local o=F.Observation();o.actions.recall.readyAt=108
local c=assert(F.Personal.New(F.Declarations(),o))
local e=assert(c:NewExecution('recall',{objectiveID='goal',now=100,from='cave'}))
local a=e:GetState()
assert(a.phase=='waiting' and a.instruction=='wait_personal' and a.readyAt==108 and a.remainingSeconds==8)
assert(a.position==nil and a.attempt==nil and a.usedAt==nil)
assert(e:BeginUse(107)==nil,'Waiting never starts an automatic or early use')
a=e:Tick(108);assert(a.phase=='ready' and a.deadline==nil)
a=assert(e:BeginUse(109));assert(a.phase=='awaiting_transition' and a.usedAt==109 and a.deadline==129)
local attempt=a.attempt
e:Tick(110);assert(e:GetState().attempt==attempt and e:GetState().deadline==129)
assert(e:Tick(129).status=='failed','No deadline extension')
e=assert(c:NewExecution('recall',{objectiveID='goal',now=100,from='cave'}))
assert(e:Tick(99).status=='failed','A wait cannot survive a regressing clock')
e=assert(c:NewExecution('recall',{objectiveID='goal',now=100,from='cave'}));e:Cancel()
assert(e:Tick(108).status=='cancelled')
-- A zero-charge wait does not pretend a charge is already present.
local d=F.Declarations();d[1].chargeBased=true
local s=o.actions.recall;s.readyAt=0;s.charges=0;s.maxCharges=2
s.rechargeStart=99;s.rechargeSeconds=10;s.rechargeRate=1
c=assert(F.Personal.New(d,o))
e=assert(c:NewExecution('recall',{objectiveID='goal',now=100,from='cave'}))
assert(e:GetState().readyAt==109 and e:GetState().phase=='waiting')
