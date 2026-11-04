local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local second=F.Portal();second.id='other';second.loadingSeconds=4
    local old=F.Store(client,{['portal/door/loading']={manualSeconds=8},['portal/other/loading']={manualSeconds=9}})
    local e=F.Host(client,{portals={F.Portal(),second}},nil,old)
    local result=e:Plan();local journey=e.host.journey
    local realPlan=e.host.Plan
    local calls=0
    e.host.Plan=function(host,...)calls=calls+1;return realPlan(host,...)end
    local revision=e.host.planner.revision
    assert(e.host:ResetCalibrationCosts(nil,'all'))
    assert(e.host.planner.revision==revision+1 and calls==1,'two routes reset in one price revision/recovery')
    assert(e.host.journey==journey and journey.viaIndex==0)
    assert(not e.host.planner:IsCurrent(result))
    assert(select(2,e.host:StartTravel(result))=='stale_result')
    assert(e:Finish().estimatedSeconds==11)
    local current=e.host.job
    assert(not e.host:ResetCalibrationCosts(nil,'all') and calls==1 and e.host.job==current)
    e.host:ResumeCalibration();e.host:ApplyCalibrationCosts(true)
    assert(calls==1 and e.host.planner.revision==revision+1)
    e.host:Disable()
end
