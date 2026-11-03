local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
APRNavigationCharacterSettings={}
local e=F.Host('Camelot',false,{calibration={client='Forever',build='build',computer='pc',
    api={UnitGUID=function()return 'Player-test'end}},
    portals={{id='door',from='cave',to='goal',phase='present',destination={space='garden',phase='present'},
        useSeconds=2,waitSeconds=0,loadingSeconds=8,timeoutSeconds=120}},
    portalObservation={revision=1,phase='present',portals={door={access=true,open=true}}}},F.Graph(50))
local result=e:Result({from='cave',to='goal'});e:Start(result)
e.host:ObserveTravel({sequence=1,reliable=true,node='cave',phase='present'})
local action=assert(e.host:BeginPortalUse())
local changed,reason=e.host:SetCalibrationCost('portal/door/loading',20)
assert(changed and reason=='deferred')
e.context='replacement'
result=e:Result({from='cave',to='goal'})
assert(result.estimatedSeconds==22,'Replacing a committed attempt must apply its deferred prices before the new search')
assert(e.host:GetCalibrationStats().accepted==0 and not e.host.calibrationMeasurement)
assert(#e.host.calibration:Pending()==0)
assert(e.host:GetCalibrationCost('portal/door/loading')==20 and e.quests==0)
e.host:Disable()
