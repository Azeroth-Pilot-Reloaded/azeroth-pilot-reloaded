local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
local function Host()
    APRNavigationCharacterSettings={foreign=true}
    return F.Host('Camelot',false,{calibration={client='Forever',build='build',computer='pc',
        api={UnitGUID=function()return 'Player-test'end}},
        portals={{id='door',from='cave',to='goal',phase='present',destination={space='garden',phase='present'},
            useSeconds=2,waitSeconds=0,loadingSeconds=8,timeoutSeconds=120}},
        portalObservation={revision=1,phase='present',portals={door={access=true,open=true}}}},F.Graph(50))
end
for _,manual in ipairs({false,true})do
    local e=Host();local result=e:Result({from='cave',to='goal'})
    e:Start(result)
    assert(e.host:ObserveTravel({sequence=1,reliable=true,node='cave',phase='present'}).kind=='use_portal')
    local action=assert(e.host:BeginPortalUse());local deadline=action.deadline
    local revision,journey=e.host.planner.revision,e.host.journey
    assert(e.host.calibrationMeasurement,'Only accepted portal use starts a measurement')
    if manual then
        local changed,reason=e.host:SetCalibrationCost('portal/door/loading',30)
        assert(changed and reason=='deferred' and e.host.planner.revision==revision)
        assert(e.host:GetTravelAction().deadline==deadline)
    end
    assert(e.host:ObservePortals({revision=2,phase='present',portals={door={open=false,access=true}}}))
    assert(e.host.travel and e.host:GetTravelAction().deadline==deadline,'Future portal revocation preserves only the committed receipt')
    e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
    assert(e.host.travel and e.host:GetTravelAction().deadline==deadline)
    e.time=106;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    assert(e.host:GetCalibrationStats().accepted==0,'World entry is not destination confirmation')
    e.time=110
    action=e.host:ObserveTravel({sequence=2,reliable=true,node='goal',space='garden',phase='present',loading=false,
        transition={portalId='door',from='cave',to='goal',complete=true,attempt=action.attempt}})
    assert(action.kind=='replan' and action.reason=='calibration')
    assert(e.host:GetCalibrationStats().accepted==1 and e.host.journey==journey and journey.node=='goal')
    assert(e.host:GetCalibrationCost('portal/door/loading')==(manual and 30 or 4))
    assert(e.host.planner.portals.byId.door.loadingSeconds==(manual and 30 or 4))
    assert(e:Finish().status=='complete' and e.quests==0)
    assert(e.host:ResetCalibrationCosts('portal/door/loading','manual')==manual)
    assert(e.host:GetCalibrationCost('portal/door/loading')==4,'Masked measurements were still persisted')
    e.host:Disable()
end
for _,stop in ipairs({'replace','reload','logout','timeout'})do
    local e=Host();local result=e:Result({from='cave',to='goal'});e:Start(result)
    e.host:ObserveTravel({sequence=1,reliable=true,node='cave',phase='present'})
    local old=assert(e.host:BeginPortalUse());e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
    if stop=='replace' then e.context='new';e.host:Plan({from='town',to='goal'},e.context)
    elseif stop=='reload' then e:Fire('PLAYER_ENTERING_WORLD',false,true)
    elseif stop=='logout' then e:Fire('PLAYER_LOGOUT')
    else e.time=221;e.host:RefreshTravel()end
    e.time=222;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    if e.host.travel then e.host:ObserveTravel({sequence=2,reliable=true,node='goal',space='garden',phase='present',
        transition={portalId='door',from='cave',to='goal',complete=true,attempt=old.attempt}})end
    assert(e.host:GetCalibrationStats().accepted==0,'Interrupted/reloaded/stale execution never saves a sample')
    assert(e.host:GetCalibrationCost('portal/door/loading')==8)
    e.host:Disable()
end
