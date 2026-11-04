local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local old=F.Store(client,{['portal/door/loading']={manualSeconds=8,foreign='keep'}})
    local e=F.Host(client,nil,nil,old)
    assert(e.guidReads==1 and e.nativeTimeReads==0)
    assert(e.registered['APR-Core/libs/LibAPRNavigation-2.0/Calibration.lua']==1)
    assert(e.registered['APR-Core/features/navigation/NavigationV2Calibration.lua']==1)
    assert(e.host:GetCalibrationCost('portal/door/loading')==8)
    local initialClockReads=e.host:GetCalibrationStats().clockReads
    local result,job=e:Plan()
    assert(result.estimatedSeconds==16 and result.segments[1].kind=='portal','first plan uses persisted seconds')
    assert(e.host:GetCalibrationStats().clockReads==initialClockReads,'no calibration capture during the actual first search')
    local reads,clocks=e.reads,e.host:GetCalibrationStats().clockReads
    for _=1,4 do e.host:Step(1);e.host:GetResult()end
    assert(e.host.job==job and e.guidReads==1 and e.nativeTimeReads==0 and e.reads==reads)
    assert(e.host:GetCalibrationStats().clockReads==clocks,'no capture in Step/GetResult/relaxation')
    assert(#e.ws.creates==0 and #e.timers==0 and e.quests==0 and APR.navigation.legacy)
    local revision=e.host.planner.revision
    assert(not e.host:SetCalibrationCost('portal/door/loading',8))
    assert(e.host.planner.revision==revision and e.host.job==job)
    assert(APRNavigationCharacterSettings~=old and APRNavigationCharacterSettings.foreign==old.foreign)
    assert(APRNavigationCharacterSettings.oldTaxiDurations==old.oldTaxiDurations)
    assert(old.navigationV2Costs.profiles[e.calOptions.client]['synthetic-build']['synthetic-character'].desk.costs['portal/door/loading'].manualSeconds==8)
    assert(e.host:ResetCalibrationCosts('portal/door/loading','manual'))
    assert(e.host.planner.revision==revision+1 and not e.host.planner:IsCurrent(result))
    assert(e.host.journey.objective.to=='goal' and e.host.journey.objective.via[1]=='exit')
    assert(e:Finish().estimatedSeconds==11)
    local replacement=e.host.job
    revision=e.host.planner.revision
    assert(not e.host:ResetCalibrationCosts('portal/door/loading','all'))
    assert(e.host.job==replacement and e.host.planner.revision==revision)
    e.host:Disable()
    for _,frame in ipairs(e.frames)do assert(next(frame.events)==nil)end
end
