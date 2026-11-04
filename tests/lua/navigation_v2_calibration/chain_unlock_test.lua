local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
local U=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Raw(client)
    local p=F.Portal();p.from='cave';p.to='town';p.requirements=U.Gate()
    local options=e:Options({unlocks={U.Entry()},portals={p},observeConditions=true,
        conditionAPI=e.api,conditionAccess={['garden-open']=false}})
    assert(e.host:Enable(U.Graph(),options))
    assert(e.host:SetConditionAccess({['garden-open']=false})~=nil,'idempotent unchanged setter may return false')
    assert(e.host:Plan({from='cave',to='goal',via={'town'}},e.context))
    local result=e:Finish()
    if result.status=='observation_required' then assert(e.host:ResumeConditions());result=e:Finish()end
    assert(result.status=='complete' and result.unlock and result.unlock.id=='speak-keeper')
    assert(e:Start(result).node=='keeper')
    local journey=e.host.journey
    local revision=e.host.planner.revision
    assert(e.host:SetCalibrationCost('portal/door/loading',7))
    assert(e.host.planner.revision==revision+1 and e.host.journey==journey and journey.unlock)
    assert(journey.objective.to=='goal' and journey.objective.via[1]=='town' and journey.viaIndex==0)
    result=e:Finish()
    assert(result.unlock and result.unlock.id=='speak-keeper' and result.objective.to=='goal')
    assert(e:Start(result).node=='keeper')
    assert(e.host:ObserveTravel({sequence=1,reliable=true,node='keeper'}).kind=='unlock')
    assert(journey.node=='keeper' and e.quests==0 and APR.navigation.legacy)
    e.host:Disable()
end
