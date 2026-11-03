local H=dofile('tests/lua/navigation_v2_portals/host_fixture.lua')
local S=dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
for _,awp in ipairs({false,true}) do
    local h,ns,env,ws,as=H.Load(awp)
    local route=S.Route();route.from='dock';route.to='exit';route.access='available'
    local graph={complete=true,nodes={'start','gate','far','dock','exit','goal'},edges={
        {id='ride-to-gate',from='start',to='gate',seconds=99,movement={mode='mount',distance=7,canMount='available'}},
        {id='to-dock',from='far',to='dock',seconds=2,movement={mode='walk',distance=7}},
        {id='last',from='exit',to='goal',seconds=1,movement={mode='walk',distance=7}}}}
    local portals={{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
        entry={mapID=42,x=.2,y=.3},name='Portal',waitSeconds=0,useSeconds=1,loadingSeconds=1,timeoutSeconds=30}}
    local movement=assert(ns.LibAPRNavigationV2.NewForeverMovement({initialMode='walk',level=40,
        mountOwned=true,mountUsable=true,canMountHere=true},{mountSpeed=7,dismountSeconds=2}))
    assert(env:Enable(graph,{movement=movement,scheduled={route},portals=portals,
        portalObservation={revision=1,phase='blue',portals={door={open=true,access=true}}}}))
    h:Plan({from='start',to='goal'},env.context)
    local r=H.Finish(h)
    assert(r.status=='complete' and r.estimatedSeconds==72)
    assert(r.segments[1].mode=='mount' and r.segments[1].transitionSeconds==3)
    assert(r.segments[2].mode=='walk' and r.segments[2].transitionSeconds==2)
    assert(r.segments[4].kind=='scheduled' and r.segments[4].transportId==route.id)
    assert(#ws.creates==0 and #as.schedules==0,'planning cannot publish')
    local action=assert(h:StartTravel(r,{objectiveID='mixed',scheduledTimeoutSeconds=25,
        resolveTarget=function(node)return {key=node,title='Continue',position={mapID=44,x=.4,y=.4}}end}))
    assert(action.kind=='walk' and action.mode=='mount')
    local function CheckOutput()
        if awp then as:Flush();assert(as.record and #ws.creates==0)
        else assert(ws.current) end
    end
    CheckOutput()
    h:ObserveTravel({sequence=1,reliable=true,node='gate',phase='blue'})
    assert(h:BeginPortalUse().kind=='awaiting_transition')
    action=h:GetTravelAction()
    h:ObserveTravel({sequence=2,reliable=true,node='far',space='other',phase='blue',
        transition={portalId='door',from='gate',to='far',complete=true,attempt=action.attempt}})
    h:ObserveTravel({sequence=3,reliable=true,node='dock'})
    action=h:GetTravelAction()
    assert(action.kind=='scheduled' and action.phase=='approach' and action.attempt)
    CheckOutput()
    local function Observe(kind,sequence,destination)
        local stop=destination and route.destination or route.origin
        return h:ObserveTravel({kind=kind,sequence=sequence,routeID=route.id,objectiveID='mixed',confirmed=true,
            attempt=action.attempt,stopID=stop.id,worldID=stop.worldID,floorID=stop.floorID,phaseID=stop.phaseID,
            onTransport=kind=='boarded'or kind=='departed'or kind=='destination'})
    end
    assert(Observe('origin',1).phase=='waiting')
    if awp then as:Flush();assert(as.record==nil) else assert(ws.current==nil) end
    assert(Observe('transport_ready',2).phase=='boarding')
    CheckOutput()
    assert(Observe('boarded',3).phase=='riding')
    assert(Observe('destination',4,true).phase=='riding','departure cannot be inferred')
    Observe('departed',5)
    assert(Observe('destination',6,true).phase=='disembarking')
    CheckOutput()
    assert(Observe('disembarked',7,true).kind=='walk')
    assert(h:ObserveTravel({sequence=8,reliable=true,node='goal'}).kind=='complete')
    assert(env.questCalls==0)
    h:Disable()
end
