local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Host(client)
    local old,oldResult=e:CommitPortal()
    local oldTimer=e.timers[#e.timers]
    e.time=103
    local fresh=e:Plan()
    assert(select(2,e.host:StartTravel(oldResult))=='stale_result','a new request retires the previous result even before prices change')
    assert(e:Start(fresh).kind=='approach')
    e.host:ObserveTravel(e:PortalLocation(1,false))
    local current=assert(e.host:BeginPortalUse())
    assert(current.attempt~=old.attempt,'same goal still needs a distinct actual execution')
    local travel,journey=e.host.travel,e.host.journey
    e.time=105;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=110;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    oldTimer.callback()
    assert(e.host.travel==travel and e.host:GetTravelAction().attempt==current.attempt)
    e.time=115
    assert(e.host:ObserveTravel(e:PortalLocation(2,true,old.attempt)).kind=='awaiting_transition')
    assert(e.host:GetCalibrationStats().accepted==0,'old correlated receipt cannot complete the new attempt')
    assert(e.host:ObserveTravel(e:PortalLocation(3,true,current.attempt)).kind=='replan')
    assert(e.host:GetCalibrationStats().accepted==1 and e.host:GetCalibrationCost('portal/door/loading')==5)
    assert(e.host.journey==journey and journey.viaIndex==1)
    assert(not e.host.planner:IsCurrent(oldResult),'real price revision retires earlier results')
    local replacement=e.host.job
    assert(e:Finish().estimatedSeconds==5)
    local _,reason=e.host:ObserveTravel(e:PortalLocation(4,true,old.attempt))
    assert(reason=='no_travel' and e.host.job==replacement)
    e.host:Disable()
end
