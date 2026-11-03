local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env,h=H.New()
local graph=H.Graph({'s','gate','far','g'},{H.Edge('approach','s','gate','walk',7),
    H.Edge('detour','gate','far','walk',140),H.Edge('finish','far','g','walk',7)})
local portals={{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
    entry={mapID=42,x=.2,y=.3},name='Ancient portal',waitSeconds=0,useSeconds=1,loadingSeconds=1,timeoutSeconds=30}}
local function observation(revision,open)
    return {revision=revision,phase='blue',portals={door={open=open,access=true}}}
end
env:Enable(graph,{portals=portals,portalObservation=observation(1,true)})
local options={resolveTarget=function(node) return env:Resolve(node) end}
h:Plan({from='s',to='g'},env.context)
local original=env:Finish()
assert(h:StartTravel(original,options))
assert(h:ObserveTravel(env:Location(1,'gate')).kind=='use_portal')
assert(h:ObservePortals(observation(2,false)))
assert(h:GetTravelAction()==nil and env.provider.current==nil)
local resumed=env:Finish()
H.Path(resumed,{'detour','finish'},21)
assert(resumed.objective.from=='gate' and resumed.nodes[1]=='gate',
    'replanning starts from the last confirmed node, not the old origin')
assert(select(2,h:StartTravel(original,options))=='stale_result')

-- BeginUse invalidates the entry position. No environment update can assume
-- that a loading/transition event already reached either side.
assert(h:ObservePortals(observation(3,true)))
resumed=env:Finish();assert(h:StartTravel(resumed,options))
assert(h:ObserveTravel(env:Location(1,'gate')).kind=='use_portal')
assert(h:BeginPortalUse().kind=='awaiting_transition')
local timer=env.timers[#env.timers]
local unconfirmed=h:ObserveTravel({sequence=2,reliable=true,node='far',space='other',phase='blue'})
assert(unconfirmed.kind=='awaiting_transition')
assert(h:ObservePortals(observation(4,false)))
assert(h:GetTravelAction()==nil and timer.cancelled)
assert(h:GetResult().status=='stale' and h:Step(1).status=='stale',
    'unconfirmed transition must wait for a new reliable localized request')
assert(env.provider.current==nil)
timer.callback()
assert(h:GetTravelAction()==nil,'late timeout cannot restart from the old origin')
-- APR can now supply an independently localized request; no arrival is inferred.
h:Plan({from='far',to='g'},env.context)
H.Path(env:Finish(),{'finish'},1)
assert(env.questCalls==0)
h:Disable()
