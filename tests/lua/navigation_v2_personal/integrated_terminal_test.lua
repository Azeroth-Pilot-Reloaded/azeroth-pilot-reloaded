local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
-- A positive genuine correlated arrival is in integrated_host; these reject
-- evidence tied to the active attempt that contradicts its captured contract.
for _,change in ipairs({'phase','space','node','personalId','from','to','failed'})do
    local e=F.Host();e:Enable();e:Ready()
    local action=assert(e.host:BeginPersonalUse())
    local proof=e:Arrival(action)
    if change=='failed' then proof.failed=true
    elseif change=='personalId' or change=='from' or change=='to' then proof.transition[change]='wrong'
    else proof[change]='wrong'end
    local result=e.host:ObserveTravel(proof)
    assert(result.kind=='failed' and not e.host.journey:RemainingRequest())
    assert(e.quests==0 and e.protectedUses==0)
end
for _,operation in ipairs({'Cancel','Disable','Plan','context','SetPersonalCosts'})do
    local e=F.Host();e:Enable();e:Ready()
    local action=assert(e.host:BeginPersonalUse())
    if operation=='context' then e.context='replacement'
    elseif operation=='Plan' then e.context='replacement';assert(e.host:Plan({from='town',to='goal'},e.context))
    elseif operation=='SetPersonalCosts' then assert(e.host:SetPersonalCosts('recall',{useSeconds=4}))
    else e.host[operation](e.host)end
    local job=e.host.job
    local late=e.host:ObserveTravel(e:Arrival(action))
    assert(late==nil and e.host.job==job and e.quests==0)
    if operation=='Plan' then assert(e:Finish().estimatedSeconds==7)end
end
local e=F.Host();e:Enable();e:Ready()
local action=assert(e.host:BeginPersonalUse())
local deadline=action.deadline
e.time=deadline-1;e:Fire('SPELL_UPDATE_COOLDOWN')
assert(e.host:GetTravelAction().phase=='awaiting_transition' and e.host:GetTravelAction().deadline==deadline)
e.time=deadline
assert(e.host:GetTravelAction().reason=='transition_timeout')
assert(e.host:ObserveTravel(e:Arrival(action)).kind=='failed')
assert(e.quests==0)
-- A foreign attempt is not incompatible evidence about this attempt and cannot arrive.
e=F.Host();e:Enable();e:Ready();action=assert(e.host:BeginPersonalUse())
local stale=e:Arrival(action);stale.transition.attempt={}
assert(e.host:ObserveTravel(stale).kind=='personal')
assert(e.host:ObserveTravel(e:Arrival(action,2)).kind=='replan')
