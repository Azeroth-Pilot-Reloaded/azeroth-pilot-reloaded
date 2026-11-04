local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do for _,awp in ipairs({false,true})do
    local e=F.Host(client,awp);e.readyAt=108;e.api.SPELL_FAILED_NOT_READY='Not yet recovered'
    local declarations=F.Native.Declarations()
    declarations[1].requirements={quests={{questID=711,completed=true}}}
    e:EnableConditions(F.Native.Graph(),nil,declarations)
    local r=e:FirstResult();assert(r.estimatedSeconds==20)
    local a=assert(e.host:StartTravel(r))
    assert(a.kind=='personal' and a.phase=='waiting' and a.remainingSeconds==8)
    assert(a.position==nil and a.target==nil and a.message=='Not yet recovered' and not e:HasMarker())
    assert(e.host:GetPersonalButton()==nil and e.protectedUses==0)
    local timer=e.host.travelTimer;assert(timer and timer.delay==8)
    e:Fire('QUEST_LOG_UPDATE')
    assert(timer.cancelled and e.host.travel==nil and not e:HasMarker())
    e.host:ResumeConditions();r=e:Finish();assert(r.estimatedSeconds==20)
    a=assert(e.host:StartTravel(r));assert(a.phase=='waiting' and a.readyAt==108)
    e.completed=false;e:Fire('QUEST_LOG_UPDATE')
    e.host:ResumeConditions();r=e:Finish()
    assert(r.estimatedSeconds==40,'A denied transport cannot wait into permission')
    e:StartWalk(r);assert(e:HasMarker())
    local job=e.host.job;local marker=awp and e.as.record or e.ws.current
    e.time=108;timer.callback()
    assert(e.host.job==job and e:HasMarker() and (awp and e.as.record or e.ws.current)==marker,
        'An invalidated cooldown callback cannot affect a newer walk')
    e:Cleanup()
end end
-- A committed use is a bounded receipt, not proof that its destination exists.
local e=F.Host('Standard');local d=F.Native.Declarations()
d[1].requirements={quests={{questID=711,completed=true}}}
e:EnableConditions(F.Native.Graph(),nil,d)
local r=e:FirstResult();assert(r.estimatedSeconds==12)
assert(e.host:StartTravel(r).phase=='ready')
local action=assert(e.host:BeginPersonalUse())
local attempt,deadline=action.attempt,action.deadline
assert(action.phase=='awaiting_transition' and attempt and deadline==120 and e.host.journey.node==nil)
e:Fire('QUEST_LOG_UPDATE');e:Fire('PLAYER_ENTERING_WORLD')
action=e.host:GetTravelAction()
assert(action.phase=='awaiting_transition' and action.attempt==attempt and action.deadline==deadline)
assert(e.host.journey.node==nil and e.host.journey.objective.to=='goal')
assert(e.protectedUses==0 and e.quests==0,'Events neither cast nor advance a quest')
e.time=121;action=e.host:GetTravelAction()
assert((action.kind=='failed' or action.kind=='cancelled') and e.host.journey.node==nil,
    'Expired invalidated receipt is terminal, without deadline extension or fabricated arrival')
e:Cleanup()
