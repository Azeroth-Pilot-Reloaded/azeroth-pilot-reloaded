local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local function Host(requirements,extra)
    local e=F.Host()
    local g={complete=true,nodes={'cave','town','goal'},edges={
        {id='fast',from='cave',to='goal',seconds=1,requirements=requirements},
        {id='detour',from='cave',to='goal',seconds=12}}}
    extra.observeConditions,extra.conditionAPI=true,e.api
    e:Enable({},extra,g);e.host:Plan({from='cave',to='goal'},e.context)
    assert(e:Finish().status=='observation_required');e.host:ResumeConditions()
    local r=e:Finish();assert(r.estimatedSeconds==1)
    return e,r
end
local e,r=Host({floor='upper'},{conditionIdentity={floor='upper',phase='present',space='hall'}})
local revision,job=e.host.planner.revision,e.host.job
assert(e.host:SetConditionIdentity({floor='upper',phase='present',space='other'})==false,
    'Changing unrequired space while retaining the required floor cannot dirty a result')
assert(e.host:ResumeConditions().status=='complete' and e.host.job==job and e.host.planner.revision==revision)
assert(e.host.planner:IsCurrent(r) and e.host.conditionSource.identity.space=='other','Full new evidence is retained')
assert(e.host:SetConditionIdentity({floor='lower',space='other'}))
e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==12,'A changed required floor invalidates')
assert(e.host:SetConditionIdentity({floor='upper'}));e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==1)
assert(e.host:SetConditionIdentity({space='other'}));e.host:ResumeConditions()
assert(e:Finish().estimatedSeconds==12,'Omitting a required identity makes it unknown')
e.host:Disable()
e,r=Host({access={{key='gate',allowed=true}}},{conditionAccess={gate=true}})
revision,job=e.host.planner.revision,e.host.job
assert(e.host:SetConditionAccess({gate=true,unrequired=false})==false,
    'Adding an unrequired false fact while retaining required access does not dirty')
assert(e.host:ResumeConditions().status=='complete' and e.host.job==job and e.host.planner.revision==revision)
assert(e.host.planner:IsCurrent(r) and e.host.conditionSource.access.unrequired==false)
assert(e.host:SetConditionAccess({gate=false}));e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==12)
assert(e.host:SetConditionAccess({gate=true}));e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==1)
assert(e.host:SetConditionAccess({unrequired=false}));e.host:ResumeConditions()
assert(e:Finish().estimatedSeconds==12,'Omitting required access is unknown, never false authorization')
-- A relevant dirty burst can receive fresh proof without another revision.
e.host:MarkConditionsDirty({access={gate=true}});revision=e.host.planner.revision
assert(e.host:SetConditionAccess({gate=true})==false,'An existing burst is coalesced')
assert(e.host.planner.revision==revision)
e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==1,'Explicitly restored required proof remains useful')
e.host:Disable()
