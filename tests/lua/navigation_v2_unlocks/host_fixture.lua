local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
local Native=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
function F.Host(client,awp,extra,graph)
    local e=Native.Host(client,awp)
    local options={unlocks={F.Entry()},observeConditions=true,conditionAPI=e.api,
        conditionAccess={['garden-open']=false}}
    for key,value in pairs(extra or {})do options[key]=value end
    e:Enable({},options,graph or F.Graph())
    -- Bootstrap retires pre-world identity/access. Supply fresh trusted evidence.
    e.host:SetConditionAccess({['garden-open']=false})
    function e:Result(request)
        local job=assert(self.host:Plan(request or {from='cave',to='goal',via={'town'}},self.context))
        local result=self:Finish()
        if result.status=='observation_required' then
            assert(self.host:ResumeConditions().status=='running')
            assert(self.host.job==job);result=self:Finish()
        end
        return result
    end
    function e:Start(result,resolver)
        return self.host:StartTravel(result,{resolveTarget=resolver or function(node)
            return {key=node,title='Follow the passage',position={mapID=42,x=.2,y=.3},aprStepKey='authored-step'}
        end},self.context)
    end
    function e:HasMarker()self.as:Flush();return awp and self.as.record~=nil or not awp and self.ws.current~=nil end
    return e
end
return F
