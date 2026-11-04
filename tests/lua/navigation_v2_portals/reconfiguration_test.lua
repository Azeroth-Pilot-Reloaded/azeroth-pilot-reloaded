local H=dofile('tests/lua/navigation_v2_portals/host_fixture.lua')
local graph={complete=true,nodes={'s','gate','far','g'},edges={
    {id='approach',from='s',to='gate',seconds=1},{id='finish',from='far',to='g',seconds=3}}}
local portals={{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
    entry={mapID=42,x=.2,y=.3},waitSeconds=0,useSeconds=1,loadingSeconds=1,timeoutSeconds=30}}
local function Fire(env,event)
    for _,frame in ipairs(env.frames) do if frame.events[event] then frame.callback(frame,event) end end
end
for _,kind in ipairs({'fixed','explicit','observer'}) do
    local h,ns,env,ws=H.Load(false)
    local scans=0
    local options={portals=portals,portalObservation={revision=1,phase='blue',portals={door={open=true,access=true}}}}
    if kind=='explicit' then options.movement=assert(ns.LibAPRNavigationV2.NewForeverMovement({initialMode='walk'})) end
    if kind=='observer' then
        options.observeMovement=true
        options.movementAPI={UnitLevel=function()return 40 end,IsSwimming=function()return false end,
            GetUnitSpeed=function()return 0,7,0,4.7 end,C_MountJournal={GetMountIDs=function()scans=scans+1;return {} end}}
    end
    assert(not h:Enable(false,options) and not h.enabled and h.worldLoading==nil and #env.frames==0)
    assert(h:Enable(graph,options))
    h:Plan({from='s',to='g'},env.context)
    assert(H.Finish(h).status=='unknown' and h.worldLoading==nil,'initial world knowledge is unknown')
    assert(h:SetTarget({key='g',position={mapID=42,x=.2,y=.3}},env.context)=='world_unknown')
    h:ObserveWorld(false)
    h:Plan({from='s',to='g'},env.context)
    local r=H.Finish(h);assert(r.status=='complete')
    local readyPlanner=h.planner
    assert(not h:Enable(false,options) and h.planner==readyPlanner and h.worldLoading==false)
    assert(h.planner:IsCurrent(r),'failed validation cannot revoke an old valid plan')
    assert(h:StartTravel(r))
    h:ObserveTravel({sequence=1,reliable=true,node='gate',phase='blue'})
    h:BeginPortalUse()
    local timer=env.timers[#env.timers]
    local frame=h.observationFrame
    local unregistrations=frame.unregistrations or 0
    local activeAttempt=h:GetTravelAction().attempt
    assert(not h:Enable(false,options) and h:GetTravelAction().attempt==activeAttempt and not timer.cancelled,
        'failed reconfiguration must keep the current action intact')
    assert(h:Enable(graph,options) and h.worldLoading==false,'ready knowledge also survives active replacement')
    assert(timer.cancelled and h:GetTravelAction()==nil and ws.current==nil)
    assert(h.observationFrame==frame and (frame.unregistrations or 0)==unregistrations)
    timer.callback();assert(h:GetTravelAction()==nil)
    assert(select(2,h:StartTravel(r))=='stale_result')
    h:Plan({from='gate',to='g'},env.context);r=H.Finish(h)
    assert(r.estimatedSeconds==5 and h:StartTravel(r))
    h:ObserveTravel({sequence=1,reliable=true,node='gate',phase='blue'});h:BeginPortalUse()
    timer=env.timers[#env.timers]
    Fire(env,'PLAYER_LEAVING_WORLD')
    local capturedScans=scans
    assert(h.worldLoading==true and h:Enable(graph,options))
    assert(h.worldLoading==true and h.observationFrame==frame and (frame.unregistrations or 0)==unregistrations,
        'active reconfiguration cannot erase world knowledge or unsubscribe the world pair')
    assert(scans==capturedScans,'configuring an observer during loading cannot read transient journal data')
    assert(timer.cancelled and h:GetTravelAction()==nil and ws.current==nil)
    timer.callback();assert(h:GetTravelAction()==nil)
    assert(select(2,h:StartTravel(r))=='stale_result')
    local planner=h.planner
    assert(not h:Enable(false,options) and h.planner==planner and h.worldLoading==true)
    assert(not h:EnableSectors({}, {}, false, options) and h.planner==planner and h.worldLoading==true)
    h:Plan({from='s',to='g'},env.context);assert(H.Finish(h).status=='unknown')
    Fire(env,'PLAYER_ENTERING_WORLD')
    h:Plan({from='s',to='g'},env.context);assert(H.Finish(h).status=='complete')
    -- A real unsubscribe loses information: entering while off is not received.
    Fire(env,'PLAYER_LEAVING_WORLD');h:Disable()
    assert(h.worldLoading==nil and next(frame.events)==nil)
    Fire(env,'PLAYER_ENTERING_WORLD')
    frame.callback(frame,'PLAYER_ENTERING_WORLD') -- a queued callback after real unsubscribe is also rejected
    assert(h.worldLoading==nil)
    assert(h:Enable(graph,options) and h.worldLoading==nil)
    h:Plan({from='s',to='g'},env.context);assert(H.Finish(h).status=='unknown')
    assert(h:ObserveWorld(false)~=false) -- genuinely fresh trusted readiness, not Enable itself
    h:Plan({from='far',to='g'},env.context);assert(H.Finish(h).estimatedSeconds==3)
    h:Disable()
    assert(select(2,h:ObserveWorld(false))=='disabled','readiness cannot be cached across an unsubscribed gap')
    assert(h:Enable(graph,options) and h.worldLoading==nil)
    h:Plan({from='far',to='g'},env.context);assert(H.Finish(h).status=='unknown')
    h:ObserveWorld(false)
    assert(h.worldLoading==false)
    h:Disable()
    assert(env.questCalls==0)
end

-- The actual sector factory shares the same continuous reconfiguration path.
local h,ns,env=H.Load(false)
assert(h:Enable(graph,{}));h:ObserveWorld(true)
local decodes=0
local index={garden={name='Garden',nodes=1,complete=true,links={}}}
local catalog={garden={complete=true,blocks={{first=1,nodes=1,edges=0,rawBytes=1,payload='x'}}}}
local options={complete=true,profileClock=function()return 0 end,
    decodeBase64=function(s)decodes=decodes+1;return s end,inflate=function(s)return s end,
    deserialize=function()return {2,1,{{0,0,0}},{}} end}
local frame=h.observationFrame;local count=frame.unregistrations or 0
assert(h:EnableSectors(index,catalog,options) and h.worldLoading==true)
assert(h.observationFrame==frame and (frame.unregistrations or 0)==count)
h:Plan({from='garden:terrain:1',to='garden:terrain:1'},env.context)
assert(H.Finish(h).status=='unknown' and decodes==0)
Fire(env,'PLAYER_ENTERING_WORLD')
h:Plan({from='garden:terrain:1',to='garden:terrain:1'},env.context)
assert(H.Finish(h).status=='complete' and decodes==1)
h:Disable()
