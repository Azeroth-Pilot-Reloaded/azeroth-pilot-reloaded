local H=dofile('tests/lua/navigation_v2_movement/host_fixture.lua')
local env=H.New()
local ns=env.namespace
assert(ns.NavigationV2Retail,'Retail movement must load through the real host XML')
APR.GAME_VERSIONS={Retail='retail',Forever='forever'}
APR.GetGameVersion=function()return 'retail' end
local state={owned=true,here=true,active=false,gliding=false}
env.api.IsAdvancedFlyableArea=function()return state.here end
env.api.IsIndoors=function()return false end
env.api.IsFlying=function()return state.gliding end
env.api.C_PlayerInfo={GetGlidingInfo=function()return state.gliding,state.gliding,100 end}
env.api.C_MountJournal.GetCollectedDragonridingMounts=function()
    if state.owned then return {71} end;return {}
end
env.api.C_MountJournal.GetMountInfoByID=function()
    return 'Invented flying mount',1,1,state.active,true,1,false,false,nil,false,state.owned,71,false
end
local E=H.Edge
env:Enable(H.Graph({'s','g'},{E('walk','s','g','walk',140),
    E('sky','s','g','skyriding',600)}))
assert(ns.NavigationV2Retail.IsProfile(env.host.planner.movement))
assert(env.host:Plan({from='s',to='g'},'objective'))
local scans=env.scans
H.Path(env:Finish(),{'sky'},13)
assert(env.scans==scans,'native observations do not run inside Step')
assert(#env.provider.creates==0 and env.questCalls==0)
assert(env.host:Plan({from='s',to='g'},'objective'))
local pending=env.host.job
assert(env.host:Step(1).status=='running')
state.owned=false
env:Fire('MOUNT_JOURNAL_USABILITY_CHANGED')
assert(pending:Step(1).status=='stale')
assert(env.host:Plan({from='s',to='g'},'objective'))
H.Path(env:Finish(),{'walk'},20)
state.owned=true;state.here=false
env:Fire('PLAYER_MOUNT_DISPLAY_CHANGED')
assert(env.host:Plan({from='s',to='g'},'objective'))
H.Path(env:Finish(),{'walk'},20)
env.host:Disable()
assert(APR.navigation.legacy and #env.provider.creates==0 and env.questCalls==0)
