local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    for _,awp in ipairs({false,true})do
        local e=F.Host(client,awp);e:Enable()
        local r=e:Ready({from='cave',to='goal',via={'town'}})
        assert(r.estimatedSeconds==12 and r.segments[1].from=='cave')
        assert(e.protectedUses==0 and #e.ws.creates==0 and e.as.record==nil)
        local before=e.reads
        e.host:GetResult();e.host:Step(1);e.host:GetTravelAction()
        assert(e.reads==before,'Search/result/display must not scan personal APIs')
        local b=assert(e.host:GetPersonalButton())
        assert(#e.buttons==1 and b.attributes.spell==901 and b.attributes.type=='spell')
        assert(b.attributes.useOnKeyDown==false and b.clickModes[1]=='LeftButtonUp')
        assert(e.host:GetPersonalButton()==b and #e.buttons==1 and e.protectedUses==0)
        b:HardwareClick()
        local action=e.host:GetTravelAction()
        assert(e.protectedUses==1 and action.phase=='awaiting_transition' and action.attempt)
        assert(b.attributes.type==nil and b.attributes.spell==nil and not b.shown)
        local attempt,deadline=action.attempt,action.deadline
        before=e.reads
        e.time=104;e.readyAt=200;e.money=8;e.stock[902]=3
        e:Fire('UNIT_SPELLCAST_START','player');e:Fire('SPELL_UPDATE_COOLDOWN');e:Fire('BAG_UPDATE_DELAYED')
        assert(e.reads==before,'Dirty events invalidate without scanning')
        assert(not e.host.planner:IsCurrent(r))
        assert(e.host:ObservePersonal(),'An explicit changed planning capture replaces its catalogue')
        assert(e.reads>before)
        assert(e.host:GetTravelAction().attempt==attempt and e.host:GetTravelAction().deadline==deadline)
        local missing=e:Arrival(action);missing.transition=nil
        assert(e.host:ObserveTravel(missing).kind=='personal','Position/cast alone never arrives')
        e:Fire('PLAYER_LEAVING_WORLD')
        assert(e.host:ObserveTravel(e:Arrival(action,2)).kind=='personal','Observed loading overrides supplied ready')
        assert(not e.host.journey:RemainingRequest())
        e:Fire('PLAYER_ENTERING_WORLD');e.casting=false
        assert(e.host:GetTravelAction().deadline==deadline and e.host:GetTravelAction().attempt==attempt)
        local original=e.host.journey.objective
        assert(e.host:ObserveTravel(e:Arrival(action,3)).kind=='replan')
        local newJob=e.host.job
        assert(e.host.journey.objective==original and e.host.journey.viaIndex==1)
        assert(e.host.journey:RemainingRequest().from=='town')
        assert(e:Finish().estimatedSeconds==7 and e.host.job==newJob)
        local late,reason=e.host:ObserveTravel(e:Arrival(action,4))
        assert(late==nil and reason=='no_travel' and e.host.job==newJob,'Old receipt cannot trigger a second plan')
        assert(e.protectedUses==1 and e.quests==0 and #e.ws.creates==0 and e.as.record==nil)
        e.host:Disable()
        for _,frame in ipairs(e.frames)do assert(next(frame.events)==nil)end
    end
end
