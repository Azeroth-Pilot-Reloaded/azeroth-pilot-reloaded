local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Host(client)
    local action,result,travel,journey=e:CommitPortal()
    local deadline=action.deadline
    assert(e.host:GetCalibrationStats().accepted==0)
    e.time=101
    assert(e.host:ObserveTravel(e:PortalLocation(2,true)).kind=='awaiting_transition')
    assert(e.host:GetCalibrationStats().accepted==0,'destination alone cannot sample')
    e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=107;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    assert(e.host.travel==travel and e.host:GetTravelAction().attempt==action.attempt)
    assert(e.host:GetTravelAction().deadline==deadline,'normal loading preserves the original deadline')
    assert(e.host:GetCalibrationStats().accepted==0,'enter-world closes loading but does not arrive')
    local revision=e.host.planner.revision
    e.time=110
    assert(e.host:ObserveTravel(e:PortalLocation(3,true,action.attempt)).kind=='replan')
    assert(e.host:GetCalibrationCost('portal/door/loading')==5,'accepted correlated journey retains its loading measurement')
    assert(e.host:GetCalibrationStats().accepted==1 and e.host:GetCalibrationStats().clockReads==2)
    assert(e.host.planner.revision==revision+1 and not e.host.planner:IsCurrent(result))
    assert(e.host.journey==journey and journey.viaIndex==1 and journey.node=='exit')
    local replacement=e.host.job
    assert(e:Finish().estimatedSeconds==5 and e.host.job==replacement)
    e.host:ResumeCalibration();e.host:ApplyCalibrationCosts(true)
    assert(e.host.job==replacement and e.host.planner.revision==revision+1,'one useful recovery only')
    assert(e:Start(e.host:GetResult()).kind=='walk')
    local marker=e.ws.current
    local creates=#e.ws.creates
    local late=e.timers[1];assert(late.cancelled);late.callback()
    assert(e.ws.current==marker and #e.ws.creates==creates and e.host.job==replacement)
    assert(e.quests==0 and APR.navigation.legacy)
    e.host:Disable()
end
-- Equal/masked measurements persist without a price revision/recovery.
local e=F.Host('Camelot',nil,nil,F.Store('Camelot',{['portal/door/loading']={manualSeconds=9}}))
local action=e:CommitPortal()
e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
e.time=107;e:Fire('PLAYER_ENTERING_WORLD',false,false)
local revision,job=e.host.planner.revision,e.host.job
e.time=110;e.host:ObserveTravel(e:PortalLocation(2,true,action.attempt))
assert(e.host:GetCalibrationStats().accepted==1 and e.host:GetCalibrationCost('portal/door/loading')==9)
assert(e.host.planner.revision==revision and e.host.job==job,'manual mask prevents price revision/replan')
assert(e.host:ResetCalibrationCosts('portal/door/loading','manual'))
assert(e.host:GetCalibrationCost('portal/door/loading')==5)
assert(e.host.planner.revision==revision+1)
e.host:Disable()
