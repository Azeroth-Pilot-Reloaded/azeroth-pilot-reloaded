local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local requirements={access={{key='open',allowed=true}}}
for _,kind in ipairs({'personal','portal','scheduled','taxi'})do
    local graph=F.Graph()
    graph.nodes[2]={id='town',requirements={access={{key='destination',allowed=true}}}}
    local options=F.Options();options.personal=nil;options.personalObservation=nil
    if kind=='personal' then
        options.personal,options.personalObservation=F.Declarations(),F.Observation()
        options.personal[1].requirements=requirements
    elseif kind=='portal' then
        options.portals={{id='door',from='cave',to='town',phase='present',name='Door',
            destination={space='world',phase='present'},waitSeconds=1,useSeconds=2,loadingSeconds=3,
            timeoutSeconds=20,requirements=requirements}}
        options.portalObservation={revision=1,phase='present',portals={door={open=true,access=true}}}
    elseif kind=='scheduled' then
        options.scheduled={{id='boat',kind='boat',from='cave',to='town',access='available',
            origin={id='dock',worldID=7,floorID=0,phaseID='present'},
            destination={id='pier',worldID=7,floorID=0,phaseID='present'},
            costs={approach=0,boarding=0,ride=3,loading=0,disembark=0,final=0},
            wait={mode='known',seconds=0},requirements=requirements}}
    else
        options.taxi={F.Taxi(4)};options.taxi[1].from,options.taxi[1].to='cave','town'
        options.taxi[1].requirements=requirements
        options.taxiObservation=F.TaxiObservation(4);options.resources={money=12}
    end
    options.conditionObservation={sequence=1,worldState='ready',access={open=true,destination=true}}
    local p=assert(F.Library.New(graph,options))
    local function Plan()return F.Base.Finish(p:Plan({from='cave',to='goal'}))end
    local r=Plan();assert(r.estimatedSeconds<40 and r.segments[1].kind==kind)
    local observation={sequence=2,worldState='ready',access={open=false,destination=true}}
    assert(p:ObserveConditions(observation));assert(not p:IsCurrent(r))
    assert(Plan().estimatedSeconds==40,'A denied '..kind..' cannot bypass its condition')
    observation.sequence=3;observation.access.open=nil;p:ObserveConditions(observation)
    assert(Plan().estimatedSeconds==40,'Unknown '..kind..' preserves walking')
    observation.sequence=4;observation.access.open=true;observation.access.destination=false;p:ObserveConditions(observation)
    assert(Plan().estimatedSeconds==40,'A transport cannot bypass destination requirements')
    observation.sequence=5;observation.access.destination=true;p:ObserveConditions(observation)
    assert(Plan().estimatedSeconds==r.estimatedSeconds,'Fresh proof can restore a prepared '..kind)
    if kind=='scheduled' then
        local revision=p.revision
        local replacement=F.ns.NavigationV2WaypointTarget.Copy(options.scheduled)
        replacement[1].requirements={access={{key='replacement',allowed=true}}}
        local changed,reason=p:SetScheduled(replacement)
        assert(changed==nil and reason=='condition_reconfiguration_requires_enable' and p.revision==revision)
        assert(Plan().estimatedSeconds==r.estimatedSeconds,'Rejected reconfiguration leaves no partial binding or proof')
        assert(p.conditions.dependencyCount==2,'No discarded dependency is retained')
        options.scheduled[1].costs.ride=8
        assert(p:SetScheduled(options.scheduled),'Cost-only replacement retains its captured requirement ownership')
        assert(Plan().estimatedSeconds==15)
    end
end
