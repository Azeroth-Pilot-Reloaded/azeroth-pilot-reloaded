local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local h,ns,env,ws=F.Host(false)
assert(ns.NavigationV2World and ns.NavigationV2Position,'Actual XML/TOC must load position modules')
local calls,x=0,100
local api={IsPlayerInWorld=function()
    calls=calls+1
    assert(env.frames[1].events.PLAYER_ENTERING_WORLD,'Subscribe before bootstrap')
    return true
end,UnitPosition=function()return x,200,30,7 end}
local graph={complete=true,nodes={'start','goal'},edges={{id='walk',from='start',to='goal',seconds=3}}}
local options={observePosition=true,positionAPI=api,positionIdentity={space='surface',floor=0,phase='shared'},
    positionExpected={world=7,floor=0}}
assert(h:Enable(graph,options) and calls==1 and h.worldLoading==false)
assert(h:GetPositionSnapshot().world==7 and h:GetPositionSnapshot().uiMapID==nil)
h:Plan({from='start',to='goal'},env.context)
local result=F.Finish(h.job);assert(result.estimatedSeconds==3)
local revision=h.planner.revision
for _=1,20 do x=x+1;assert(h:ObservePosition()==false)end
assert(h.planner.revision==revision and h.planner:IsCurrent(result) and calls==1)
env:Fire('PLAYER_LEAVING_WORLD')
assert(h.worldLoading==true and not h.planner:IsCurrent(result))
h:Plan({from='start',to='goal'},env.context)
assert(h:GetResult().reason=='loading' and calls==1)
assert(h:Enable(graph,options) and h.worldLoading==true and calls==1)
env:Fire('PLAYER_ENTERING_WORLD')
h:Plan({from='start',to='goal'},env.context)
assert(h:GetResult().reason=='floor_ambiguous','Loading revoked stale identity')
assert(h:SetPositionIdentity({space='surface',floor=0,phase='shared'}))
h:Plan({from='start',to='goal'},env.context);result=F.Finish(h.job)
assert(result.estimatedSeconds==3)
local target={key='world goal',title='Destination',uiMapID=77,
    worldPosition={world=7,x=100,y=200,z=30,space='surface',floor=0,phase='shared'}}
assert(select(2,h:SetWorldTarget(target,env.context))=='projection_unavailable')
assert(#ws.creates==0)
api.CreateVector2D=function(a,b)return {x=a,y=b}end
api.C_Map={GetMapPosFromWorldPos=function()return 77,{x=.3,y=.4}end,
    GetWorldPosFromMapPos=function()return 7,{x=100,y=200}end}
assert(h:SetWorldTarget(target,env.context)=='active' and ws.current)
local sequence=h:GetPositionSnapshot().sequence
assert(h:ObservePosition({sequence=sequence,worldState='ready',world=8,x=1,y=2})==false)
assert(h:GetPositionSnapshot().world==7)
h:Disable();assert(h.worldLoading==nil)
assert(h:Enable(graph,options) and calls==2)
h:Disable()
