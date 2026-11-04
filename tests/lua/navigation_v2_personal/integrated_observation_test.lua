local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    for _,case in ipairs({'unloaded','secret_item','secret_money','unknown_cooldown','unknown_clock','unknown_known',
        'missing_phase','missing_space','missing_reliability'})do
        local e=F.Host(client);local d=F.Declarations()
        d[1].origin={space='underground',phase='present'}
        local extra={personalOrigin={node='cave',space='underground',phase='present',reliable=true}}
        if case=='unloaded' then e.loaded=false
        elseif case=='secret_item' then e.stock[902]={secret=true}
        elseif case=='secret_money' then e.money={secret=true}
        elseif case=='unknown_cooldown' then e.cooldownUnknown=true
        elseif case=='unknown_clock' then e.api.GetTime=nil
        elseif case=='unknown_known' then e.known=nil
        elseif case=='missing_phase' then extra.personalOrigin.phase=nil
        elseif case=='missing_space' then extra.personalOrigin.space=nil
        elseif case=='missing_reliability' then extra.personalOrigin.reliable=nil end
        e:Enable(d,extra)
        assert(e.host:Plan({from='cave',to='goal'},e.context))
        local r=e:Finish();assert(r.status=='complete' and r.estimatedSeconds==40,case)
        assert(r.segments[1].kind~='personal' and e.protectedUses==0)
        -- Positive control: restore actual public evidence and reobserve at Plan.
        e.loaded,e.stock[902],e.money,e.cooldownUnknown,e.known=true,5,12,false,true
        e.api.GetTime=function()return e.time end
        e.host:SetPersonalOrigin({node='cave',space='underground',phase='present',reliable=true})
        assert(e.host:Plan({from='cave',to='goal'},e.context));assert(e:Finish().estimatedSeconds==12)
    end
    local e=F.Host(client);local d=F.Declarations();d[1].rare=true
    e:Enable(d);e.host:Plan({from='cave',to='goal'},e.context);assert(e:Finish().estimatedSeconds==40)
    e:Enable(d,{personalSettings={allowRare=true}})
    e.host:Plan({from='cave',to='goal'},e.context);assert(e:Finish().estimatedSeconds==12)
    -- Unknown world cannot be converted into ready by planning or an observer.
    e=F.Host(client);e:Enable(nil,{positionAPI={}})
    local reads=e.reads;assert(e.host.worldLoading==nil)
    e.host:Plan({from='cave',to='goal'},e.context)
    assert(e:Finish().status=='unknown' and e.reads==reads)
    e:Fire('PLAYER_ENTERING_WORLD');assert(e.reads==reads)
    e.host:Plan({from='cave',to='goal'},e.context);assert(e:Finish().estimatedSeconds==12)
end
