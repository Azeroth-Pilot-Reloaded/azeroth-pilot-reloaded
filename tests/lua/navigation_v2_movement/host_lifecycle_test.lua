local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env,h=H.New()
local graph=H.Graph({'s','mouth','exit','g'},{H.Edge('ride-in','s','mouth','mount',112),
    H.Edge('cave','mouth','exit','walk',14),H.Edge('ride-out','exit','g','mount',112)})
env:Enable(graph)
h:Plan({from='s',to='g'},env.context)
local result=env:Finish()
H.Path(result,{'ride-in','cave','ride-out'},28)
local options={resolveTarget=function(node) return env:Resolve(node) end}
local action=h:StartTravel(result,options)
assert(action.kind=='walk' and action.mode=='mount' and action.transitionSeconds==3)
assert(#env.provider.creates==1)
assert(h:DismissTarget()=='dismissed' and env.provider.current==nil)
local scans,creates=env.scans,#env.provider.creates
for _=1,5 do h:GetTravelAction();h:RefreshTravel();h:GetResult() end
assert(#env.provider.creates==creates and env.scans==scans,'dismissed execution target stays dismissed')

-- The next confirmed geometric segment exposes a descent and later remount.
action=h:ObserveTravel(env:Location(1,'mouth'))
assert(action.mode=='walk' and action.node=='exit' and action.transitionSeconds==0)
action=h:ObserveTravel(env:Location(2,'exit'))
assert(action.mode=='mount' and action.node=='g' and action.transitionSeconds==3)
assert(env.questCalls==0)

-- A mode-change event invalidates both cached result and live execution now,
-- while the public journal is read only at a subsequent explicit boundary.
env.character.active=true;env.character.run=11.2
scans=env.scans
env:Fire('PLAYER_MOUNT_DISPLAY_CHANGED')
assert(env.scans==scans and env.provider.current==nil)
assert(h:GetTravelAction()==nil and not h.planner:IsCurrent(result))
assert(h:GetResult().status=='stale')
assert(select(2,h:StartTravel(result,options))=='stale_result')
assert(env.scans==scans+1)
h:Plan({from='exit',to='g'},env.context)
result=env:Finish()
H.Path(result,{'ride-out'},10)
assert(h:StartTravel(result,options).transitionSeconds==0)
h:Cancel()
assert(h:GetResult()==nil and h:GetTravelAction()==nil and env.provider.current==nil)
assert(select(2,h:StartTravel(result,options))=='stale_result')

-- Replacing the objective cannot consume or resurrect an old result.
h:Plan({from='s',to='g'},env.context)
result=env:Finish();assert(h:StartTravel(result,options))
h:Plan({from='g',to='s'},env.context)
assert(h:GetTravelAction()==nil and env.provider.current==nil)
assert(select(2,h:StartTravel(result,options))=='stale_result')
assert(env:Finish().status=='no_path')
h:Plan({from='exit',to='g'},env.context)
result=env:Finish();assert(h:StartTravel(result,options))
env.context='replacement'
assert(select(2,h:GetTravelAction())=='stale_context' and env.provider.current==nil)
for _,timer in ipairs(env.timers) do if not timer.cancelled then timer.callback() end end
assert(h:GetTravelAction()==nil and env.questCalls==0)
h:Disable()
