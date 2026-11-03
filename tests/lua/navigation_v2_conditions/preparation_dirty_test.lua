-- A native event may arrive between bounded graph preparation slices.
local ns={};assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
local C=ns.NavigationV2Conditions
for _,case in ipairs({
    {requirements={phase='after-event'},evidence={phase='after-event'},dirty={identity={phase=true}}},
    {requirements={quests={{questID=601,completed=false}}},evidence={quests={[601]=false}},dirty={quests={[601]=true}}},
    {requirements={access={{key='bridge',allowed=true}}},evidence={access={bridge=true}},dirty={access={bridge=true}}},
})do
    local t=C.New()
    local compiled=assert(C.Compile(case.requirements))
    local first=assert(t:Track(compiled))
    local observation={sequence=1,worldState='ready'}
    for key,value in pairs(case.evidence)do observation[key]=value end
    assert(t:Observe(observation))
    assert(t:Get(first)=='available')
    local before=t:GetToken()
    assert(t:MarkDirty(case.dirty))
    local added=assert(t:Track(compiled))
    assert(t:Get(first)=='unknown')
    assert(t:Get(added)=='unknown','New binding must not resurrect a revoked fact during preparation')
    local unconditional=assert(t:Track(assert(C.Compile({}))))
    assert(t:Get(unconditional)=='available','Unconditional declaration needs no proof')
    assert(not t:IsCurrent(before) and not t:IsCurrent(t:GetToken()))
    local stale,reason=t:Observe(observation)
    assert(stale==false and reason=='stale_observation')
    assert(t:Get(added)=='unknown','Stale observation must not restore revoked proof')
    observation.sequence=2
    local _,why,recovered=t:Observe(observation)
    assert(why==nil and recovered)
    assert(t:Get(first)=='available' and t:Get(added)=='available')
    assert(t:Get(unconditional)=='available' and t:IsCurrent(t:GetToken()))
    assert(not t:IsCurrent(before),'Fresh identical recovery cannot revive an old token')
    local current=t:GetToken()
    observation.sequence=3
    local changed,_,again=t:Observe(observation)
    assert(not changed and not again and t:IsCurrent(current),'Recovery is signalled once')
end
