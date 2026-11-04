local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
local cases={'cancel','replace','logout','initial-login','reload','missing-flags','secret-flags','numeric-flags','unpaired-exit',
    'regressed-clock','missing-clock','timeout','subscription-gap'}
for _,case in ipairs(cases)do
    local e=F.Host('Camelot')
    local action=e:CommitPortal()
    local timer=e.timers[#e.timers]
    if case=='unpaired-exit' then
        e.time=107;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    else
        e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
        e.time=107
        if case=='initial-login' then e:Fire('PLAYER_ENTERING_WORLD',true,false)
        elseif case=='reload' then e:Fire('PLAYER_ENTERING_WORLD',false,true)
        elseif case=='missing-flags' then e:Fire('PLAYER_ENTERING_WORLD')
        elseif case=='secret-flags' then e:Fire('PLAYER_ENTERING_WORLD',{secret=true},false)
        elseif case=='numeric-flags' then e:Fire('PLAYER_ENTERING_WORLD',0,0)
        elseif case=='regressed-clock' then e.time=101;e:Fire('PLAYER_ENTERING_WORLD',false,false)
        elseif case=='missing-clock' then e.clockMissing=true;e:Fire('PLAYER_ENTERING_WORLD',false,false);e.clockMissing=false
        else e:Fire('PLAYER_ENTERING_WORLD',false,false)end
    end
    if case=='cancel' then e.host:Cancel()
    elseif case=='logout' then e:Fire('PLAYER_LOGOUT')
    elseif case=='replace' then
        local result=e:Plan({from='exit',to='goal'})
        assert(e:Start(result).kind=='walk')
        local marker,job=e.ws.current,e.host.job
        timer.callback()
        assert(e.ws.current==marker and e.host.job==job,'old deadline cannot disturb replacement output/job')
    elseif case=='timeout' then e.time=160;timer.callback()
    elseif case=='subscription-gap' then
        e.host:Disable();assert(e.host:Enable(F.Graph(),e:Options()))
    end
    e.time=case=='timeout' and 170 or 110 -- Other rejection controls finish before the fixed deadline.
    e.host:ObserveTravel(e:PortalLocation(2,true,action.attempt))
    assert(e.host:GetCalibrationStats().accepted==0,case..' must reject the whole sample')
    assert(e.host:GetCalibrationCost('portal/door/loading')==3,case..' must preserve last effective estimate')
    assert(e.quests==0 and APR.navigation.legacy)
    e.host:Disable()
end
