local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
for _, kind in ipairs({'fixed','explicit','replace_observer'}) do
    local env,h=H.New()
    local graph={complete=true,nodes={'s','g'},edges={{id='foot',from='s',to='g',seconds=1}}}
    local profile=assert(env.namespace.LibAPRNavigationV2.NewForeverMovement({initialMode='walk'}))
    if kind=='replace_observer' then env:Enable(graph)
    else assert(h:Enable(graph,kind=='explicit' and {movement=profile} or {})) end
    h:ObserveWorld(false) -- fresh synthetic readiness after the observer is active
    h:Plan({from='s',to='g'},env.context)
    local r=env:Finish();assert(r.status=='complete')
    assert(h:StartTravel(r,{resolveTarget=function(node)return env:Resolve(node)end}))
    local scans=env.scans
    env:Fire('PLAYER_LEAVING_WORLD')
    assert(not h.planner:IsCurrent(r),kind..': world loading must invalidate every profile variant')
    assert(env.scans==scans and h:GetTravelAction()==nil and env.provider.current==nil)
    assert(h.journey:RemainingRequest()==nil and h:GetResult().objective.to=='g')
    assert(h:SetTarget(env:Resolve('g'),env.context)=='loading' and env.provider.current==nil,
        'direct target publication cannot bypass native loading')
    if kind=='replace_observer' then
        assert(h:SetMovement(profile))
        assert(h.movementSource==nil,'mount subscriptions may end during loading')
    end
    h:Plan({from='s',to='g'},env.context)
    assert(env:Finish().status=='unknown',kind..': a request during loading must stay unknown')
    assert(select(2,h:StartTravel(r))=='stale_result')
    env:Fire('PLAYER_ENTERING_WORLD')
    assert(env.scans==scans and h.worldLoading==false and h.journey:RemainingRequest()==nil)
    h:Plan({from='s',to='g'},env.context)
    assert(env:Finish().status=='complete',kind..': fresh localization after entering can resume')
    assert(env.questCalls==0)
    h:Disable()
    for _,frame in ipairs(env.frames) do assert(next(frame.events)==nil) end
end

-- The core receives only a pure localization constraint, never native events.
local env,h=H.New()
local library=env.namespace.LibAPRNavigationV2
local graph={complete=true,nodes={'s','g'},edges={{id='foot',from='s',to='g',seconds=5}}}
local p=assert(library.New(graph,{clock=function()return 0 end,profileClock=function()return 0 end}))
local held=p:Plan({from='s',to='g'},{locationKnown=false})
assert(held:Step().status=='unknown' and held:GetResult().reason=='location_unknown')
assert(held:GetResult().objective.to=='g' and held:GetResult().diagnostics.operations==0)
assert(p.preparation.phase=='prepare_nodes','unknown position must not prepare or search the graph')
assert(p:Plan({from='s',to='g'},false):GetResult().status=='invalid')
assert(p:Plan({from='s',to='g'},{locationKnown='yes'}):GetResult().reason=='invalid_request_context')
local F=dofile('tests/lua/navigation_v2/fixture.lua')
assert(F.Finish(p:Plan({from='s',to='g'},{locationKnown=true})).estimatedSeconds==5)
