local F=dofile('tests/lua/navigation_v2/fixture.lua')
local _,ns=F.Load()
local api=ns.NavigationV2ForeverTransports
local row={id='crossing',kind='boat',bidirectional=false,seconds=17,
    from={space='world',instanceID=0,x=1,y=2},to={space='world',instanceID=1,x=3,y=4}}
ns.NavigationV2ForeverTransportsData={routes={crossing=row},excluded={}}
local binding={from={node='a',space='region-a',worldID=0},
    to={node='b',space='region-b',worldID=1},access='available',timeoutSeconds=40}
local b=assert(api.Bind('crossing',binding),'Only actual spatial constraints are needed')
local d=b.options.scheduled[1]
assert(d.origin.worldID==0 and d.origin.floorID==nil and d.origin.phaseID==nil)
assert(d.destination.worldID==1 and d.destination.floorID==nil and d.destination.phaseID==nil)
assert(d.totalSeconds==17 and #b.graph.edges==0,'Costs and approach policy unchanged')
local function travel(bundle,observations)
    local options=bundle.options
    options.clock=function()return 100 end;options.profileClock=function()return 0 end
    for k,v in pairs(observations or {}) do options[k]=v end
    local planner=assert(ns.LibAPRNavigationV2.New(bundle.graph,options))
    local result=F.Finish(planner:Plan({from='a',to='b'}))
    assert(result.status=='complete')
    return assert(planner:StartTravel(result,{objectiveID='unit',scheduledTimeoutSeconds=40}))
end
local t=travel(b)
for sequence,kind in ipairs({'origin','transport_ready','boarded','departed','destination','disembarked'}) do
    local destination=sequence>=5
    local stop=destination and d.destination or d.origin
    local o={sequence=sequence,kind=kind,confirmed=true,loading=false,objectiveID='unit',
        routeID=d.id,attempt=t:GetAction().attempt,stopID=stop.id,worldID=stop.worldID,
        floorID=93,phaseID='observed',onTransport=sequence>=3 and sequence<=5}
    local action=t:Observe(o)
    if kind=='disembarked' then assert(action.kind=='complete') else assert(action.kind=='scheduled') end
end
for _,key in ipairs({'phase','floorID'}) do
    for _,bad in ipairs({false,'',-1,1.5,{}}) do
        binding.from[key]=bad
        local rejected,why=api.Bind('crossing',binding)
        assert(not rejected and why=='transport_endpoint_identity_missing')
    end
    binding.from[key]=nil
end
binding.from.worldID=1
assert(select(2,api.Bind('crossing',binding))=='transport_world_mismatch')
binding.from.worldID=0
binding.from.floorID=0;binding.from.phase='declared'
b=assert(api.Bind('crossing',binding));d=b.options.scheduled[1]
assert(d.origin.floorID==0 and d.origin.phaseID=='declared','Explicit constraints retained')
binding.from.floorID=nil;binding.from.phase=nil
row.kind='portal'
b=assert(api.Bind('crossing',binding));d=b.options.portals[1]
assert(d.phase==nil and d.destination.phase==nil and d.destination.space=='region-b')
t=travel(b,{portalObservation={revision=1,portals={[d.id]={open=true,access=true}}}})
assert(t:Observe({sequence=1,reliable=true,loading=false,node='a',phase='observed'}).kind=='use_portal')
local use=assert(t:BeginUse())
local arrival={sequence=2,reliable=true,loading=true,node='b',space='region-b',phase='observed',
    transition={portalId=d.id,from='a',to='b',complete=true,attempt=use.attempt}}
assert(t:Observe(arrival).kind=='awaiting_transition')
arrival.sequence=3;arrival.loading=false
assert(t:Observe(arrival).kind=='complete')
row.kind='spell';row.from={dynamic='player'};row.actions={{type='spell',id=781}}
binding.costs={useSeconds=3,loadingSeconds=2};binding.cooldownSeconds=20
binding.consumable=false;binding.rare=false;binding.chargeBased=false
b=assert(api.Bind('crossing',binding));d=b.options.personal[1]
assert(d.destination.phase==nil and d.destination.space=='region-b' and d.spellID==781)
t=travel(b,{personalObservation={revision=1,observedAt=100,combat=false,casting=false,loading=false,
    moneyCopper=0,items={},origin={node='a',space='region-a',reliable=true},
    actions={[d.id]={known=true,loaded=true,usable=true,readyAt=100}}}})
use=assert(t:BeginPersonal())
arrival={sequence=1,reliable=true,loading=false,node='b',space='region-b',phase='observed',
    transition={personalId=d.id,from='a',to='b',complete=true,attempt=use.attempt}}
assert(t:Observe(arrival).kind=='replan','Personal arrival retains its resource/cooldown boundary')
