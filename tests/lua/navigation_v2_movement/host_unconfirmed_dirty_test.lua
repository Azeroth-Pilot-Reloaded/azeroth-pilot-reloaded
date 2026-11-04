local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env,h=H.New()
local graph=H.Graph({'s','gate','far','g'},{H.Edge('approach','s','gate','walk',7),
    H.Edge('detour','gate','far','walk',140),H.Edge('finish','far','g','walk',7)})
local portals={{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
    name='Ancient portal',waitSeconds=0,useSeconds=1,loadingSeconds=1,timeoutSeconds=30}}
env:Enable(graph,{portals=portals,portalObservation={revision=1,phase='blue',portals={door={open=true,access=true}}}})
h:Plan({from='s',to='g'},env.context)
assert(h:StartTravel(env:Finish()))
assert(h:ObserveTravel(env:Location(1,'gate')).kind=='use_portal')
assert(h:BeginPortalUse().kind=='awaiting_transition')
env:Fire('MOUNT_JOURNAL_USABILITY_CHANGED')
assert(h:GetTravelAction()==nil)
assert(h:ObservePortals({revision=2,phase='blue',portals={door={open=false,access=true}}}))
local result=env:Finish()
assert(result.status=='stale' or result.status=='unknown',
    'lost transition localization must not be replaced with the original request origin: '..result.status)
assert(h:GetTravelAction()==nil)
h:Disable()
