local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env,h=H.New()
local graph=H.Graph({'s','g'},{H.Edge('foot','s','g','walk',140),H.Edge('ride','s','g','mount',112)})
env:Enable(graph)
assert(#env.frames==1 and #env.timers==0)
h:Plan({from='s',to='g'},env.context)
local scans=env.scans
for _=1,20 do h:Step(1);h:GetResult() end
local result=env:Finish()
H.Path(result,{'ride'},13)
assert(env.scans==scans,'no journal scan per relaxation, Step or GetResult')
assert(#env.provider.creates==0 and #env.timers==0,'planning never publishes or polls')
for _=1,20 do assert(h:GetResult()==result) end
assert(env.scans==scans and #env.timers==0)

-- A changed observation is checked at the explicit consumption boundary.
env.character.owned=false
assert(select(2,h:StartTravel(result,{resolveTarget=function(node) return env:Resolve(node) end}))=='stale_result')
assert(not h.planner:IsCurrent(result) and #env.provider.creates==0)
h:Plan({from='s',to='g'},env.context)
H.Path(env:Finish(),{'foot'},20)
env.character.owned=true
assert(h:ObserveMovement())
h:Plan({from='s',to='g'},env.context)
result=env:Finish()
local revision=h.planner.revision
assert(h:ObserveMovement()==false and h.planner.revision==revision,'unchanged capture is idempotent')

-- Settings are copied on enable. Explicit profile replacement invalidates.
local settings={mountSpeed=7}
env:Enable(graph,{movementSettings=settings})
settings.mountSpeed=112
h:Plan({from='s',to='g'},env.context)
H.Path(env:Finish(),{'ride'},19)
local profile=assert(env.namespace.LibAPRNavigationV2.NewForeverMovement({level=40,mountOwned=true,
    mountUsable=true,initialMode='walk',canMountHere=true},{mountSpeed=4}))
assert(h:SetMovement(profile))
h:Plan({from='s',to='g'},env.context)
H.Path(env:Finish(),{'foot'},20)
local scansAfter=env.scans
env:Fire('MOUNT_JOURNAL_USABILITY_CHANGED')
assert(env.scans==scansAfter,'manual profile removes public observer listeners')

-- Optional missing APIs/results and loading produce unknown, without errors.
env:Enable(H.Graph({'s','g'},{H.Edge('walk','s','g','walk',7)}))
env.character.run=nil
h:Plan({from='s',to='g'},env.context)
assert(env:Finish().status=='unknown')
env.character.run=7
assert(h:ObserveMovement(true))
h:Plan({from='s',to='g'},env.context)
assert(env:Finish().status=='unknown' and #env.timers==0)
assert(h:ObserveMovement(false))
h:Plan({from='s',to='g'},env.context)
H.Path(env:Finish(),{'walk'},1)
env.api.C_MountJournal.GetMountInfoByID=function() return end
h:Plan({from='s',to='g'},env.context)
assert(env:Finish().status=='unknown')
h:Disable()
for _,frame in ipairs(env.frames) do assert(next(frame.events)==nil) end
assert(env.questCalls==0 and APR.navigation.legacy)
