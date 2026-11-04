-- Invented transport/character data through the real client TOC/XML loader.
local Native=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local F={}
function F.Portal()
    return {id='door',from='start',to='exit',phase='present',name='Take the gate',
        destination={space='far',phase='present'},waitSeconds=1,useSeconds=2,
        loadingSeconds=3,timeoutSeconds=60,entry={mapID=42,x=.2,y=.3}}
end
function F.Graph()
    return {complete=true,nodes={'start','exit','goal'},edges={
        {id='walk',from='start',to='goal',seconds=30},
        {id='finish',from='exit',to='goal',seconds=5}}}
end
function F.Store(client,costs)
    return {foreign={keep=true},oldTaxiDurations={flight=99},navigationV2Costs={version=1,
        profiles={[client=='Camelot' and 'Forever' or 'Retail']={['synthetic-build']={
            ['synthetic-character']={desk={costs=costs or {}}}}}}}}
end
function F.Raw(client,store)
    local e=Native.Host(client,false)
    APRNavigationCharacterSettings=store
    e.guidReads,e.nativeTimeReads=0,0
    e.api.UnitGUID=function(unit)
        assert(unit=='player');e.guidReads=e.guidReads+1;return 'synthetic-character'
    end
    e.api.GetTime=function()e.nativeTimeReads=e.nativeTimeReads+1;return e.time end
    e.calOptions={client=client=='Camelot' and 'Forever' or 'Retail',build='synthetic-build',computer='desk',api=e.api}
    function e:Options(extra)
        local options={clock=function()if not self.clockMissing then return self.time end end,
            profileClock=function()return 0 end,calibration=self.calOptions,
            personal={},observePersonal=false,portals={F.Portal()},
            portalObservation={revision=1,phase='present',portals={door={open=true,access=true}}},
            positionAPI={IsPlayerInWorld=function()return true end}}
        for key,value in pairs(extra or {})do options[key]=value end
        return options
    end
    function e:Plan(request)
        local job=assert(self.host:Plan(request or {from='start',to='goal',via={'exit'}},self.context))
        local result=self:Finish()
        assert(result.status=='complete',result.reason)
        return result,job
    end
    function e:Start(result)
        return assert(self.host:StartTravel(result,{resolveTarget=function(node)
            return {key=node,title='Follow the path',position={mapID=42,x=.2,y=.3}}
        end},self.context))
    end
    function e:PortalLocation(sequence,destination,attempt)
        return {sequence=sequence,reliable=true,loading=false,node=destination and 'exit' or 'start',
            space=destination and 'far' or 'home',phase='present',
            transition=attempt and {portalId='door',from='start',to='exit',complete=true,attempt=attempt} or nil}
    end
    function e:CommitPortal()
        local result=self:Plan()
        assert(self:Start(result).kind=='approach')
        assert(self.host:ObserveTravel(self:PortalLocation(1,false)).kind=='use_portal')
        assert(self.host:GetCalibrationStats().accepted==0)
        local action=assert(self.host:BeginPortalUse())
        assert(action.kind=='awaiting_transition' and action.attempt)
        return action,result,self.host.travel,self.host.journey
    end
    return e
end
function F.Host(client,extra,graph,store)
    local e=F.Raw(client,store)
    assert(e.host:Enable(graph or F.Graph(),e:Options(extra)))
    return e
end
return F
