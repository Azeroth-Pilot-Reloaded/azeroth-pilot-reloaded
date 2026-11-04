local H=dofile('tests/lua/navigation_v2_portals/host_fixture.lua')
local h,ns,env=H.Load(false)
local calls=0
local state={level=40,active=false,owned=true,run=7}
local api={UnitLevel=function()return state.level end,IsSwimming=function()return false end,
    GetUnitSpeed=function()return 0,state.run,0,4.7 end,C_MountJournal={
        GetMountIDs=function()calls=calls+1;return {31} end,
        GetMountInfoByID=function()return 'Horse',123,1,state.active,true,1,false,false,nil,false,state.owned,31,false end,
        GetMountInfoExtraByID=function()return nil,'description','source',false,241 end,
        GetMountUsabilityByID=function()return true end}}
local graph={complete=true,nodes={'s','g'},edges={
    {id='walk',from='s',to='g',seconds=90,movement={mode='walk',distance=140}},
    {id='ride',from='s',to='g',seconds=90,movement={mode='mount',distance=112,canMount='available'}}}}
assert(env:Enable(graph,{observeMovement=true,movementAPI=api,movementSettings={walkSpeed=7}}))
h:Plan({from='s',to='g'},env.context)
local r=H.Finish(h)
assert(r.estimatedSeconds==13)
local reads=calls
assert(select(2,h:ObserveMovement('loading'))=='invalid_movement_observation' and calls==reads)
for _=1,20 do h:GetResult();h:Step(1) end
assert(calls==reads,'display/Step must not rescan journal')
assert(h:ObserveMovement()==false and calls==reads+1)
local revision=h.planner.revision
state.level=39
assert(h:ObserveMovement() and h.planner.revision>revision)
assert(select(2,h:StartTravel(r))=='stale_result')
h:Plan({from='s',to='g'},env.context);r=H.Finish(h)
assert(r.estimatedSeconds==20)
reads=calls
for _,frame in ipairs(env.frames) do
    if frame.events.PLAYER_MOUNT_DISPLAY_CHANGED then frame.callback(frame,'PLAYER_MOUNT_DISPLAY_CHANGED') end
end
assert(calls==reads,'event invalidation must not rescan journal')
assert(h:GetResult().status=='stale')
h:Plan({from='s',to='g'},env.context);r=H.Finish(h)
state.level=40
assert(select(2,h:StartTravel(r))=='stale_result','consumption recaptures and rejects changed observations')
h:Plan({from='s',to='g'},env.context);r=H.Finish(h)
assert(h:StartTravel(r).mode=='mount')
reads=calls
for _=1,20 do h:GetTravelAction() end
assert(calls==reads,'execution display must not rescan journal')
state.owned=false
assert(h:ObserveMovement() and h:GetTravelAction()==nil)
local p=assert(ns.LibAPRNavigationV2.NewForeverMovement({initialMode='walk',level=40,
    mountOwned=true,mountUsable=true,canMountHere=true},{mountSpeed=100}))
assert(h:SetMovement(p))
h:Plan({from='s',to='g'},env.context);r=H.Finish(h)
assert(math.abs(r.estimatedSeconds-4.12)<1e-9)
reads=calls;h:GetResult();h:Disable();assert(calls==reads)
for _,frame in ipairs(env.frames) do assert(next(frame.events)==nil) end
