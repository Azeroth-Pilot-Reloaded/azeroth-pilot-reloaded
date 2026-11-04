local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
for _,operation in ipairs({'Cancel','Disable','Invalidate','Plan'})do
    local e=F.Host();local options=e:Enable();e:Ready()
    local b=assert(e.host:GetPersonalButton());assert(b.attributes.type=='spell')
    e.combat=true
    if operation=='Plan' then e.context='next';e.host:Plan({from='town',to='goal'},e.context)
    else e.host[operation](e.host)end
    b:HardwareClick() -- Before ANY asynchronous secure state-driver tick.
    assert(e.protectedUses==0 and b.attributes.type==nil and b.attributes.spell==nil and not b.shown)
    e:SecureTick()
    if operation=='Disable' then
        for _,frame in ipairs(e.frames)do
            for event in pairs(frame.events)do assert(event=='PLAYER_REGEN_ENABLED')end
        end
        assert(e.host:Enable(F.Graph(),options)) -- Pending protected cleanup survives re-enable.
    end
    e.combat=false;e:SecureTick();e:Fire('PLAYER_REGEN_ENABLED')
    assert(b.attributes.type==nil and not b.shown and #e.buttons==1 and e.protectedUses==0)
    b:HardwareClick();assert(e.protectedUses==0,'Combat exit cannot restore a stale action')
    e.casting=false;e:Ready()
    assert(e.host:GetPersonalButton()==b,'Use one bounded APR-owned button')
    b:HardwareClick();assert(e.protectedUses==1,'A newly validated hardware action still works')
    e.host:Disable()
end
-- Invalidating the source immediately retires a prepared action without scanning.
local e=F.Host();e:Enable();local old=e:Ready();local b=assert(e.host:GetPersonalButton())
local reads=e.reads;e:Fire('UNIT_SPELLCAST_START','party1')
assert(e.host.planner:IsCurrent(old) and e.reads==reads,'Other units do not dirty the source')
e:Fire('SPELL_UPDATE_USABLE')
assert(not e.host.planner:IsCurrent(old) and e.reads==reads and b.attributes.type==nil)
b:HardwareClick();assert(e.protectedUses==0)
-- PreClick also revalidates a source/context change with no event delivered yet.
for _,cause in ipairs({'inventory','context'})do
    e=F.Host();e:Enable();e:Ready();b=assert(e.host:GetPersonalButton())
    if cause=='inventory' then e.stock[902]=0 else e.context='another' end
    b:HardwareClick();assert(e.protectedUses==0 and b.attributes.type==nil,cause)
    e.stock[902]=5;e:Ready();b=assert(e.host:GetPersonalButton())
    b:HardwareClick();assert(e.protectedUses==1,'Fresh evidence/context permits the next explicit use')
end
