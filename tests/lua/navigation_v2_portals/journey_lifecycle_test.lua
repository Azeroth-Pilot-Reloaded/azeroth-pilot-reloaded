local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env,h=H.New()
local graph=H.Graph({'s','gate','far','g'},{H.Edge('approach','s','gate','walk',7),
    H.Edge('detour','gate','far','walk',140),H.Edge('finish','far','g','walk',7)})
local portals={{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
    name='Portal',waitSeconds=0,useSeconds=1,loadingSeconds=1,timeoutSeconds=30}}
local function Observation(revision,open)
    return {revision=revision,phase='blue',portals={door={open=open,access=true}}}
end
env:Enable(graph,{portals=portals,portalObservation=Observation(1,true)})
h:Plan({from='s',to='g',via={'gate'}},env.context)
h:StartTravel(env:Finish())
h:ObserveTravel(env:Location(1,'gate'))
local journey=h.journey
local request=journey:RemainingRequest();request.from='corrupted';request.via[1]='corrupted'
h:Invalidate();h:StopTravel()
assert(h.journey==journey and journey:RemainingRequest().from=='gate')
assert(#journey:RemainingRequest().via==0,'confirmed mandatory visits survive guidance replacement')
assert(h:ObservePortals(Observation(2,false)))
local result=env:Finish();assert(result.estimatedSeconds==21 and result.objective.from=='gate')
local job=h.job
assert(h:ObservePortals(Observation(3,false))==false and h.job==job,'unchanged access cannot restart')

-- World loading revokes a confirmed origin even after guidance was destroyed.
local scans=env.scans
env:Fire('PLAYER_LEAVING_WORLD')
assert(env.scans==scans and h.journey:RemainingRequest()==nil)
assert(h:GetResult().objective.to=='g' and h:GetResult().status=='stale')
h:ObserveMovement(false) -- an explicit capture cannot clear a native loading interval
assert(env.scans==scans)
h:Plan({from='gate',to='g'},env.context)
assert(env:Finish().status=='unknown' and h.journey:RemainingRequest()==nil)
env:Fire('PLAYER_ENTERING_WORLD')
assert(env.scans==scans and h.journey:RemainingRequest()==nil,'entering world alone cannot locate')
assert(h:ObservePortals(Observation(4,true)))
assert(h:GetResult().status=='stale','a fresh access observation cannot resurrect the pre-loading origin')
h:Plan({from='far',to='g'},env.context)
assert(env:Finish().estimatedSeconds==1,'a new independently localized request can resume the retained goal')
h:Cancel();assert(h.journey==nil)
h:Disable()
