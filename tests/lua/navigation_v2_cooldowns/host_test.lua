local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'}) do
    local e=F.Host(client);e.api.SPELL_FAILED_NOT_READY='Not yet recovered';e.readyAt=108;e:Enable()
    e.host:Plan({from='cave',to='goal'},e.context)
    local result=e:Finish();assert(result.estimatedSeconds==20)
    local a=assert(e.host:StartTravel(result))
    assert(a.kind=='personal' and a.phase=='waiting' and a.remainingSeconds==8 and a.readyAt==108)
    assert(a.message=='Not yet recovered' and a.position==nil and a.target==nil)
    assert(e.host:GetPersonalButton()==nil and e.protectedUses==0 and e.ws.active==nil)
    local timer=e.host.travelTimer;assert(timer and timer.delay==8)
    e.host:RefreshTravel();assert(e.host.travelTimer==timer,'Reading guidance cannot restart its wait timer')
    e.time=108;timer.callback()
    assert(e.host.travel==nil and e.host.job~=nil and e.host.job~=result)
    result=e:Finish();assert(result.estimatedSeconds==12,'One fresh plan at the real wait boundary')
    a=assert(e.host:StartTravel(result));assert(a.phase=='ready')
    local b=assert(e.host:GetPersonalButton());assert(e.protectedUses==0)
    e.readyAt=200;b:HardwareClick();assert(e.protectedUses==0,'Actual click recaptures the changed cooldown')
    e.host:Disable();assert(e.quests==0)
end
-- A manual planning snapshot also needs a fresh public capture at a real click.
local e=F.Host();e:Enable(nil,{observePersonal=false,personalObservation=F.Observation()})
e:Ready();local b=assert(e.host:GetPersonalButton());e.readyAt=200
b:HardwareClick();assert(e.protectedUses==0 and e.quests==0)
e.host:Disable()
-- A superseded wait cannot wake another objective or resurrect its output.
e=F.Host();e.readyAt=108;e:Enable();e:Ready()
local timer=e.host.travelTimer
e.context='second';assert(e.host:Plan({from='cave',to='town'},e.context))
local job=e.host.job;assert(timer.cancelled)
e.time=108;timer.callback();assert(e.host.job==job and e.host.travel==nil)
e.host:Disable()
