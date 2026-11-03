local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local graph=F.Graph()
    local requirement={quests={{questID=811,completed=true}}}
    graph.edges[2].requirements=requirement;graph.edges[3].requirements=requirement
    local entry=F.Entry();entry.opens=requirement
    local e=F.Host(client,false,{unlocks={entry}},graph)
    local reads,completed=0,false
    e.api.C_QuestLog={IsQuestFlaggedCompleted=function(id)
        assert(id==811);reads=reads+1
        local subscribed=false
        for _,f in ipairs(e.frames)do if f.events.QUEST_LOG_UPDATE then subscribed=true end end
        assert(subscribed,'Quest proof must be subscribed before capture')
        return completed
    end}
    local result=e:Result();assert(result.unlock)
    local atPlan=reads;for _=1,5 do e.host:GetResult();e.host:Step(1)end
    assert(reads==atPlan,'No quest reads in Step/GetResult')
    e:Start(result)
    e.host:ObserveTravel({sequence=1,reliable=true,node='keeper'})
    local job=e.host.job
    e:Fire('QUEST_TURNED_IN',999)
    assert(e.host.job==job and e.host.travel,'Unrelated quest events leave the approach alone')
    e:Fire('QUEST_TURNED_IN',811)
    assert(not e.host.travel)
    assert(e.host:ResumeConditions().kind=='unlock' and e.host.job==job,'An event does not itself complete a prerequisite')
    completed=true;e:Fire('QUEST_LOG_UPDATE')
    assert(e.host:ResumeConditions().status=='running')
    result=e:Finish();assert(result.status=='complete' and not result.unlock)
    assert(e.quests==0 and e.protectedUses==0)
    e.host:Disable()
end
