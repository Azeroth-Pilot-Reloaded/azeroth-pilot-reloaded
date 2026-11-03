local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
local entry=F.Entry()
local graph=F.Graph();graph.edges[1].seconds=50
local e=F.Host('Standard',false,{personal={{id='recall-keeper',kind='spell',spellID=901,
    to='keeper',name='Recall',destination={space='world',phase='present'},useSeconds=2,loadingSeconds=1,
    cooldownSeconds=60,timeoutSeconds=20}}},graph)
local result=e:Result();assert(result.unlock and result.segments[1].kind=='personal')
local journey=e.host.journey
local action=e:Start(result);assert(action.kind=='personal' and action.phase=='ready')
assert(e.protectedUses==0)
local button=assert(e.host:GetPersonalButton());button:HardwareClick()
action=e.host:GetTravelAction();assert(action.phase=='awaiting_transition')
assert(not journey.node)
e.casting=false;e.time=104
action=e.host:ObserveTravel({sequence=1,reliable=true,loading=false,node='keeper',space='world',phase='present',
    transition={personalId='recall-keeper',from='cave',to='keeper',attempt=action.attempt,complete=true}})
assert(action.kind=='replan' and action.reason=='personal_arrival')
assert(e.host.journey==journey and journey.node=='keeper' and journey.viaIndex==0 and journey.unlock)
result=e:Finish();assert(result.unlock and result.travelObjective.to=='keeper' and result.estimatedSeconds==0)
assert(e:Start(result).kind=='unlock' and e.quests==0)
e.host:SetConditionAccess({['garden-open']=true})
assert(e.host:ResumeUnlock().status=='running')
result=e:Finish();assert(result.status=='complete' and not result.unlock and result.objective.via[1]=='town')
assert(e.host.journey==journey)
e.host:Disable()
