local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local original={foreign={keep=true}}
    APRNavigationCharacterSettings=original
    local graph=F.Graph(50)
    local e=F.Host(client,false,{calibration={client=client=='Camelot' and 'Forever' or 'Retail',build='synthetic-build',
        computer='synthetic-installation',api={UnitGUID=function()return 'Player-synthetic'end}},
        portals={{id='door',from='cave',to='goal',phase='present',destination={space='garden',phase='present'},
            useSeconds=2,waitSeconds=0,loadingSeconds=8,timeoutSeconds=120}},
        portalObservation={revision=1,phase='present',portals={door={access=true,open=true}}}},graph)
    local result=e:Result({from='cave',to='goal'})
    assert(result.estimatedSeconds==10 and not result.unlock)
    assert(e.host.calibration,'Opt-in creates the frozen calibration session through the actual TOC')
    local journey,revision=e.host.journey,e.host.planner.revision
    local clockReads=e.host:GetCalibrationStats().clockReads
    for _=1,5 do e.host:Step(1);e.host:GetResult()end
    assert(e.host:GetCalibrationStats().clockReads==clockReads)
    assert(e.host:SetCalibrationCost('portal/door/loading',50))
    assert(e.host.planner.revision==revision+1 and e.host.journey==journey)
    result=e:Finish();assert(result.estimatedSeconds==50 and not result.unlock)
    assert(APRNavigationCharacterSettings~=original and APRNavigationCharacterSettings.foreign==original.foreign)
    assert(original.navigationV2Costs==nil and e.host:GetCalibrationCost('portal/door/loading')==50)
    revision=e.host.planner.revision;local job=e.host.job
    assert(e.host:SetCalibrationCost('portal/door/loading',50)==false)
    assert(e.host:ResetCalibrationCosts('portal/door/loading','measured')==false)
    assert(e.host.planner.revision==revision and e.host.job==job)
    assert(e.host:ResetCalibrationCosts('portal/door/loading','manual'))
    assert(e.host.planner.revision==revision+1)
    assert(e:Finish().estimatedSeconds==10)
    e.host:Disable()
end
