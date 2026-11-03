local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Raw(client)
    local route={id='ferry',kind='boat',from='start',to='exit',access='available',requirements={phase='present'},
        origin={id='departure',worldID=7,floorID=0,phaseID='present'},
        destination={id='arrival',worldID=8,floorID=0,phaseID='present'},
        wait={mode='periodic',firstDeparture=100,periodSeconds=20},
        costs={approach=2,boarding=3,ride=12,loading=2,disembark=4,final=1}}
    local spare={id='spare',kind='elevator',from='exit',to='goal',access='unavailable',
        origin=route.destination,destination={id='upper',worldID=8,floorID=1,phaseID='present'},
        wait={mode='known',seconds=0},costs={approach=0,boarding=0,ride=8,loading=0,disembark=0,final=0}}
    local options=e:Options({portals={},scheduled={route,spare},
        scheduledOverrides={ferry={approach=4},spare={boarding=2}},
        conditionObservation={sequence=1,worldState='ready',phase='present'}})
    assert(e.host:Enable(F.Graph(),options))
    local result=e:Plan();local action=e:Start(result)
    assert(action.kind=='scheduled' and e.host:GetCalibrationStats().accepted==0)
    local function proof(kind,sequence,destination)
        local stop=destination and route.destination or route.origin
        return {kind=kind,sequence=sequence,routeID='ferry',objectiveID=action.objectiveID,confirmed=true,
            attempt=action.attempt,stopID=stop.id,worldID=stop.worldID,floorID=stop.floorID,phaseID=stop.phaseID,
            onTransport=kind=='boarded' or kind=='departed' or kind=='destination'}
    end
    e.host:ObserveTravel(proof('origin',1,false))
    e.time=101;e.host:ObserveTravel(proof('transport_ready',2,false))
    e.time=102;e.host:ObserveTravel(proof('boarded',3,false))
    assert(e.host:GetCalibrationStats().accepted==0 and e.host.travel:GetMeasurement()==nil,'boarding is not departure')
    e.time=105;e.host:ObserveTravel(proof('departed',4,false))
    local travel,journey=e.host.travel,e.host.journey
    assert(travel:GetMeasurement().startedAt==105)
    e.time=107;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=110;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    e.time=118
    assert(e.host:ObserveTravel(proof('destination',5,true)).phase=='disembarking')
    assert(e.host:GetCalibrationStats().accepted==0,'destination alone does not prove completed transport')
    assert(travel:GetMeasurement().endedAt==118)
    e.time=122;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=130;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    local revision=e.host.planner.revision
    e.time=140
    assert(e.host:ObserveTravel(proof('disembarked',6,true)).kind=='replan')
    assert(e.host:GetCalibrationStats().accepted==1)
    assert(e.host:GetCalibrationCost('scheduled/ferry/ride')==10 and e.host:GetCalibrationCost('scheduled/ferry/loading')==3,
        'disembark time/loading excluded and ride loading charged once')
    assert(e.host.planner.revision==revision+1)
    assert(e.host.planner.scheduled.byId.ferry.costs.approach==4)
    assert(e.host.planner.scheduled.byId.ferry.wait.periodSeconds==20)
    assert(e.host.planner.scheduled.byId.spare.costs.boarding==2 and e.host.planner.scheduled.byId.spare.access=='unavailable')
    assert(e.host.planner.scheduledDeclarations[1].requirements.phase=='present')
    assert(e.host.journey==journey and journey.viaIndex==1 and e:Finish().estimatedSeconds==5)
    e.host:Disable()
end
