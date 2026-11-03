-- Reuse public fakes; library and host always come from real XML/TOC closure.
local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local Native=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local F={Base=Base,Library=Base.Library,Native=Native}
function F.Require(key)return {access={{key=key,allowed=true}}}end
function F.Graph()
    return {complete=true,nodes={'cave','town','goal'},edges={
        {id='short',from='cave',to='town',seconds=1,requirements={quests={{questID=711,completed=true}}}},
        {id='finish',from='town',to='goal',seconds=2},
        {id='detour',from='cave',to='goal',seconds=13}}}
end
function F.Planner(graph,snapshot,extra)
    local options={clock=function()return 100 end,profileClock=function()return 0 end,conditionObservation=snapshot}
    for key,value in pairs(extra or {})do options[key]=value end
    return assert(F.Library.New(graph,options))
end
function F.Result(planner,request)
    return Base.Finish(planner:Plan(request or {from='cave',to='goal'}),1)
end
function F.Host(client,awp)
    local e=Native.Host(client,awp)
    e.questReads,e.completed=0,true
    e.api.C_QuestLog={IsQuestFlaggedCompleted=function(id)
        assert(id==711);e.questReads=e.questReads+1
        local subscribed=false
        for _,frame in ipairs(e.frames)do
            if frame.events.QUEST_LOG_UPDATE and frame.events.QUEST_TURNED_IN then subscribed=true end
        end
        assert(subscribed,'New dependencies must be subscribed before their first native read')
        if e.questError then error('Native query unavailable')end
        return e.completed
    end}
    function e:EnableConditions(graph,extra,declarations)
        local options={observeConditions=true,conditionAPI=self.api,
            conditionIdentity={world=7,space='hall',floor='upper',phase='present'}}
        for key,value in pairs(extra or {})do options[key]=value end
        return self:Enable(declarations or {},options,graph or F.Graph())
    end
    function e:FirstResult(request)
        local job=assert(self.host:Plan(request or {from='cave',to='goal'},self.context))
        local result=self:Finish()
        if result.status=='observation_required' then
            assert(self.host:ResumeConditions().status=='running')
            assert(self.host.job==job,'The first useful capture continues the same bounded job')
            result=self:Finish()
            assert(result.status~='observation_required','One capture covers the prepared dependencies')
        end
        return result,job
    end
    function e:StartWalk(result)
        return self.host:StartTravel(result,{resolveTarget=function(node)
            return {key='walk:'..node,title='Follow the passage',position={mapID=42,x=.2,y=.3},
                iconTexture='APR-icon',iconType='TEXTURE'}
        end},self.context)
    end
    function e:HasMarker()
        self.as:Flush()
        return awp and self.as.record~=nil or not awp and self.ws.current~=nil
    end
    function e:Cleanup()
        self.host:Disable()
        for _,frame in ipairs(self.frames)do assert(next(frame.events)==nil)end
        assert(self.protectedUses==0 and self.quests==0)
    end
    return e
end
return F
