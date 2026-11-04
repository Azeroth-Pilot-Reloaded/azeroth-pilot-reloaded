-- Invented ready declarations; never freeze a maintained journey or source.
local F=dofile('tests/lua/navigation_v2/fixture.lua')
local library,ns=F.Load()
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/Forever.lua'))('test',ns)
local api=assert(ns.NavigationV2ForeverData)
local function point(x,y,z) return {x=x,y=y or 0,z=z or 3} end
local function context()
    local clock={ms=0}
    local data={format=1,profile='forever',worldID=0,scope={id='room'},
        nodes={{id='a',x=0,y=0,z=3,spaceID='first'}, {id='b',x=4,y=0,z=3,spaceID='second'}},
        edges={{from='a',to='b',mode='ground',length=8,
            polyline={point(0),point(0,3),point(4)}}},
        anchors={{node='a',minX=-1,maxX=1,minY=-1,maxY=1,minZ=2,maxZ=4,mode='ground'},
            {node='b',minX=3,maxX=5,minY=-1,maxY=1,minZ=2,maxZ=4,mode='ground'}}}
    return {profile='forever',clock=function()return clock.ms end,walkSpeed=2,
        terrain={[0]={packs={sample={data=data,revision=7}}}},
        roads={networks={},collision={}}},clock,data
end
local function finish(job)
    for _=1,50000 do local r=job:Step(32);if r.status~='running' then return r end end
    error('bounded synthetic job did not terminate')
end
local function solve(prepared)
    assert(prepared.status=='complete',prepared.reason)
    local planner=assert(library.New(prepared.graph,prepared.options))
    return F.Finish(planner:Plan(prepared.request),32)
end
local function roundoffPortal(scale)
    local c=context();c.terrain={}
    local y=scale==1 and 0 or -14*scale
    c.connections={{id='synthetic-roundtrip-portal',kind='portal',seconds=3,
        from={world=78,x=2*scale,y=y,uiMapID=91081},to={world=78,x=14*scale,y=y,uiMapID=91082}}}
    local r={from={world=78,x=2*scale,y=y,uiMapID=91081},
        to={world=78,x=(14/100*100)*scale,y=scale==1 and 0 or -(14/100*100)*scale,uiMapID=91082}}
    return c,r
end
do
    local c,r=roundoffPortal(1)
    c.connections[1].bidirectional=true
    c.connections[1].instruction='take-declared-portal'
    c.connections[1].arrivalRange=4;c.connections[1].arrivalZTolerance=0
    local prepared=finish(assert(api.Prepare(r,c)))
    local hints=assert(prepared.guidance,'Prepared transport semantics must reach APR guidance')
    local hint=assert(hints['transition-edge:1'])
    assert(hint.kind=='portal' and hint.connectionID=='synthetic-roundtrip-portal')
    assert(hint.instruction=='take-declared-portal' and hint.arrivalRange==4 and hint.arrivalZTolerance==0)
    assert(hint.action==nil and hint.sourceFree==nil)
    assert(hints['transition-edge:1:reverse']==hint,'Both fixed directions may share immutable semantic metadata')
    assert(solve(prepared).estimatedSeconds==3)
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).estimatedSeconds==3)
    for _,edge in ipairs(prepared.graph.edges)do
        if edge.id~='transition-edge:1' and edge.id~='transition-edge:1:reverse' then assert(hints[edge.id]==nil) end
    end
    hint.instruction='changed-output'
    assert(c.connections[1].instruction=='take-declared-portal','Guidance is independent of authored source')
end
do
    local c,r=roundoffPortal(1)
    for _,kind in ipairs({'portal','passage','boat','zeppelin','tram','elevator'})do
        c.connections[1].kind=kind;c.connections[1].bidirectional=true
        local prepared=finish(assert(api.Prepare(r,c)))
        assert(prepared.guidance['transition-edge:1'].kind==kind and solve(prepared).estimatedSeconds==3)
        assert(prepared.guidance['transition-edge:1:reverse']==prepared.guidance['transition-edge:1'])
    end
    c.connections[1].instruction={invalid=true};c.connections[1].arrivalRange=-1;c.connections[1].arrivalZTolerance=math.huge
    local prepared=finish(assert(api.Prepare(r,c)))
    local hint=prepared.guidance['transition-edge:1']
    assert(hint.instruction==nil and hint.arrivalRange==nil and hint.arrivalZTolerance==nil)
    c.connections[1].arrivalRange=0/0;c.connections[1].arrivalZTolerance='unknown'
    prepared=finish(assert(api.Prepare(r,c)))
    assert(prepared.guidance['transition-edge:1'].arrivalRange==nil and prepared.guidance['transition-edge:1'].arrivalZTolerance==nil)
    assert(solve(prepared).estimatedSeconds==3,'Invalid optional guidance fields do not change planning')
    c.connections[2]={id='not-admitted',kind='unsupported-kind'}
    prepared=finish(assert(api.Prepare(r,c)))
    assert(prepared.guidance['transition-edge:2']==nil and prepared.guidance['transition-edge:2:reverse']==nil)
end
for _,scale in ipairs({1,1000000})do
    local c,r=roundoffPortal(scale)
    assert(r.to.x~=c.connections[1].to.x,'The fixture must exercise actual representational roundoff')
    local prepared=finish(assert(api.Prepare(r,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==3,'Map-percent roundtrip identifies the declared portal arrival at machine precision')
    assert(prepared.positions[prepared.request.to].x==r.to.x and c.connections[1].to.x==14*scale,'Neither authored nor requested coordinates are snapped')
end
for _,case in ipairs({{scale=1,offset=1e-12},{scale=1000000,offset=1e-6}})do
    local c,r=roundoffPortal(case.scale)
    r.to.x=14*case.scale+case.offset
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','A real small X displacement is not numeric identity')
    r.to.x=c.connections[1].to.x;r.to.y=c.connections[1].to.y+case.offset
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','A real small Y displacement is not numeric identity')
end
do
    local c,r=roundoffPortal(1)
    r.to.x=14+2^-47
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Several representable steps exceed roundtrip identity')
    c.connections[1].to.x=0;r.to.x=1e-100
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','There is no absolute epsilon around zero')
    r.to.x=0
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==3)
end
do
    local c,r=roundoffPortal(1)
    r.to.world=79
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Representational identity cannot cross worlds')
    r.to.world=78
    c.connections[1].to.z=14;r.to.z=14/100*100
    assert(r.to.z~=14 and solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Explicit Z stays strict even for representational XY identity')
    r.to.z=14
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==3)
    c.connections[1].from.z=3
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','The original origin knownZ guard is unchanged')
end
do
    local c,r=roundoffPortal(1)
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        c.connections[1].to[key]='arrival-a';r.to[key]='arrival-b'
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Representational XY cannot erase explicit identity: '..key)
        r.to[key]='arrival-a'
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==3)
        c.connections[1].to[key]=nil;r.to[key]=nil
    end
end
do
    local c,r=roundoffPortal(1)
    c.connections[1].to.z=3
    c.connections[2]=ns.NavigationV2WaypointTarget.Copy(c.connections[1])
    c.connections[2].id='unavailable-alternate-arrival';c.connections[2].disabled=true
    c.connections[2].to.x=r.to.x;c.connections[2].to.z=9
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Contradictory arrival heights remain ambiguous across roundoff-equivalent XY')
    r.to.z=3
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==3)
    r.to.z=nil;c.connections[2].to.z=3
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        c.connections[1].to[key]='arrival-a';c.connections[2].to[key]='arrival-b'
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Contradictory arrival domains remain ambiguous across roundoff: '..key)
        r.to[key]='arrival-a'
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==3)
        c.connections[1].to[key]=nil;c.connections[2].to[key]=nil;r.to[key]=nil
    end
    assert(c.connections[1].to.x==14 and c.connections[2].to.x==14/100*100 and r.to.x==14/100*100)
end
local function personalContext(kind)
    local c,clock=context()
    c.terrain={}
    local key=kind..':101'
    c.connections={{id='invented-personal',kind=kind,from={dynamic='player'},
        to={world=1,x=4,y=0,z=3},actions={{type=kind,id=101}}}}
    c.config={defaultSpellCastSeconds=2,defaultItemCastSeconds=2,actionLoadingSeconds=3}
    c.personalObservation={revision=1,observedAt=0,loading=false,combat=false,casting=false,
        origin={node='query:1',space='source',reliable=true},items={[101]=2},
        actions={[key]={loaded=true,usable=true,known=true,owned=true,readyAt=0}}}
    c.actionPolicies={[key]={cooldownSeconds=10,chargeBased=false}}
    return c,clock,key
end
local personalRequest={from={world=0,x=0,y=0,z=3},to={world=1,x=4,y=0,z=3}}
for _,singleUse in ipairs({false,true})do
    local c,_,key=personalContext('spell')
    c.connections[1].actions[2]={type='item',id=202,consumable=true}
    c.connections[1].instruction='use-selected-alternative';c.connections[1].arrivalRange=6
    c.personalObservation.actions[key].known=false
    c.personalObservation.actions['item:202']={loaded=true,usable=true,owned=true,readyAt=0,castSeconds=1}
    c.personalObservation.items[202]=1;c.actionPolicies['item:202']={cooldownSeconds=10,chargeBased=false}
    if singleUse then c.actionPolicies={} end
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==4 and route.resourcesSpent['item:forever-item-202']==1)
    local selected=0
    for _,segment in ipairs(route.segments)do
        local hint=prepared.guidance[segment.edgeId]
        if hint then
            selected=selected+1
            assert(hint.kind=='spell' and hint.connectionID=='invented-personal','Source kind and business ID are retained')
            assert(hint.action.type=='item' and hint.action.id==202 and hint.sourceFree==true,'The actual selected alternative supplies action semantics')
            assert(hint.instruction=='use-selected-alternative' and hint.arrivalRange==6 and hint.arrivalZTolerance==nil)
        end
    end
    assert(selected==1)
    for _,descriptor in ipairs(prepared.options.personal or {})do
        assert(prepared.guidance[descriptor.id]==prepared.guidance['personal:'..descriptor.id])
    end
    for _,hint in pairs(prepared.guidance)do
        if hint.action and hint.action.id==202 then hint.action.id=303 end
    end
    assert(c.connections[1].actions[2].id==202 and c.connections[1].from.dynamic=='player')
end
do
    local c=personalContext('item')
    c.connections[1].from=personalRequest.from
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    assert(solve(prepared).estimatedSeconds==5)
    for _,hint in pairs(prepared.guidance)do assert(hint.sourceFree==nil and hint.action.type=='item' and hint.action.id==101) end
    c.connections[1].from={dynamic='unobserved-source'}
    prepared=finish(assert(api.Prepare(personalRequest,c)))
    assert(solve(prepared).status=='unknown' and next(prepared.guidance)==nil,'Unresolved actions do not gain a fabricated hint')
end
do
    local c,_,key=personalContext('spell')
    c.actionPolicies[key]=nil
    local r={from=personalRequest.from,to={world=1,x=4,y=0}}
    local prepared=finish(assert(api.Prepare(r,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==5,'An exact unique declared arrival satisfies a 2D goal without observed height')
    assert(prepared.positions[prepared.request.to].z==nil and r.to.z==nil)
    assert(c.connections[1].to.z==3 and c.connections[1].to.world==1,'Authored arrival source is immutable')
end
do
    local c=personalContext('spell')
    local r={from=personalRequest.from,to={world=1,x=4,y=0}}
    for _,incompatible in ipairs({{world=2,x=4,y=0},{world=1,x=4.000001,y=0},
        {world=1,x=4,y=.000001},{world=1,x=4,y=0,z=4}})do
        r.to=incompatible
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Declared arrival aliases require exact compatible world/XY/explicit Z')
    end
    r.to={world=1,x=4,y=0,z=3}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5)
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        c.connections[1].to[key]='arrival-a';r.to={world=1,x=4,y=0,[key]='arrival-b'}
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Explicit incompatible arrival identity: '..key)
        r.to[key]='arrival-a'
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5)
        r.to[key]=nil
        local prepared=finish(assert(api.Prepare(r,c)))
        assert(solve(prepared).estimatedSeconds==5 and prepared.positions[prepared.request.to][key]==nil)
        c.connections[1].to[key]=nil
    end
end
do
    local c=personalContext('spell')
    c.connections[2]=ns.NavigationV2WaypointTarget.Copy(c.connections[1])
    c.connections[2].id='latent-arrival';c.connections[2].actions[1].id=202
    c.personalObservation.actions['spell:202']={known=false,loaded=true,usable=true,readyAt=0}
    local r={from=personalRequest.from,to={world=1,x=4,y=0}}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5,'Duplicate declarations of the same arrival domain are unambiguous')
    c.connections[2].to.z=9
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Different authored heights stay ambiguous even when only one action is available')
    r.to.z=3
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5,'An explicit compatible height selects the authored domain')
    r.to.z=nil;c.connections[2].to.z=3
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        c.connections[1].to[key]='arrival-a';c.connections[2].to[key]='arrival-b'
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Overlapping authored arrival identities stay ambiguous: '..key)
        r.to[key]='arrival-a'
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5)
        r.to[key]='arrival-b'
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
        r.to[key]=nil;c.connections[1].to[key]=nil;c.connections[2].to[key]=nil
    end
    assert(c.connections[1].to.z==3 and c.connections[2].to.z==3 and r.to.z==nil)
end
do
    local c=personalContext('spell')
    c.personalObservation.origin={reliable=false}
    local r={from={world=1,x=4,y=0},to={world=1,x=4,y=0,z=3}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','An unknown-height origin cannot alias into an arbitrary declared floor')
    r.to.z=nil
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','A model arrival height is not evidence about the same-XY original origin')
    c.personalObservation.origin={node='query:1',reliable=true}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5,'Only taking the declared action supplies arrival proof')
    r={from=personalRequest.to,to={world=0,x=0,y=0}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','The arrival alias does not create a reverse personal journey')
end
do
    local c=personalContext('spell')
    c.terrain={[1]={packs={levels={revision=1,data={format=1,worldID=1,
        nodes={{id='lower',x=4,y=0,z=3,space='lower'},{id='upper',x=4,y=0,z=9,space='upper'}},edges={},
        anchors={{node='lower',minX=3,maxX=5,minY=-1,maxY=1,minZ=2,maxZ=4},
            {node='upper',minX=3,maxX=5,minY=-1,maxY=1,minZ=8,maxZ=10}}}}}}}
    local r={from=personalRequest.from,to={world=1,x=4,y=0}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(solve(prepared).status=='unknown' and prepared.positions[prepared.request.to].z==nil,'Loaded overlapping terrain heights still prevent a 2D arrival claim')
    r.to.z=3
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==5)
    assert(c.terrain[1].packs.levels.data.nodes[1].z==3 and c.terrain[1].packs.levels.data.nodes[2].z==9)
end
do
    local c,_,key=personalContext('spell')
    c.actionPolicies[key]=nil
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==5,'Known readiness permits one shared use without inventing future cooldown policy')
end
for _,kind in ipairs({'spell','item'})do
    local c=personalContext(kind)
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    assert(prepared.status=='complete','Existing personal declaration must reach preparation')
    assert(prepared.request.to=='query:2' and #prepared.request.via==0)
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==5,'Personal cast and loading must reach the actual planner')
end
local function observationPause(c,r)
    c.deferObservations=true
    local job=assert(api.Prepare(r or personalRequest,c))
    assert(job:GetObservationRequests()==nil)
    for _=1,1000 do
        local result=job:Step(8)
        assert(result.status=='running',result.reason)
        if result.phase=='observation_required' then return job,assert(job:GetObservationRequests()) end
    end
    error('bounded observation discovery did not pause')
end
do
    local c,_,key=personalContext('spell')
    c.connections[1].requirements={quest=71,access={{key='gate',allowed=true}}}
    local supplied=ns.NavigationV2WaypointTarget.Copy(c.personalObservation)
    c.personalObservation.origin=nil;c.personalObservation.actions[key].loaded=nil
    local job,requests=observationPause(c)
    assert(requests.actions[key].spellID==101 and requests.actions[key].kind=='spell')
    assert(requests.quests[71] and requests.access.gate.field=='access')
    assert(requests.origin.node=='query:1' and requests.origin.position.world==0)
    local before=job:GetMetrics().operations
    assert(job:Step(8).phase=='observation_required' and job:GetMetrics().operations==before)
    assert(job:ResumeObservations({personalObservation={actions=false}})==nil)
    assert(job:ResumeObservations({personalObservation=supplied,actionPolicies=c.actionPolicies,
        conditionObservation={sequence=1,worldState='ready',quests={[71]=true},access={gate=true}}}))
    assert(job:ResumeObservations({})==nil,'A resumed job cannot capture twice')
    local prepared=finish(job)
    assert(job:GetMetrics().operations>before and solve(prepared).estimatedSeconds==5)
    local planner=assert(library.New(prepared.graph,prepared.options))
    assert(F.Finish(planner:Plan(prepared.request)).status=='complete')
    assert(planner:ObserveConditions({sequence=2,worldState='ready',quests={[71]=true},access={gate=false}}))
    assert(F.Finish(planner:Plan(prepared.request)).status=='unknown','Revoked access must revoke the personal path')
end
for _,allowed in ipairs({true,false})do
    local c,_,key=personalContext('spell')
    c.connections[1].requirements={quest=71,access={{key='gate',allowed=allowed}}}
    c.conditionObservation={sequence=7,worldState='ready',quests={[71]=allowed},access={gate=allowed}}
    c.dynamicPositions={bind={reliable=true,position=personalRequest.to}}
    local job,requests=observationPause(c)
    assert(next(requests.actions)==nil and next(requests.quests)==nil and next(requests.access)==nil)
    assert(requests.origin==nil,'Supplied positive and negative facts are not requested again')
    assert(job:ResumeObservations({conditionObservation={sequence=1,worldState='unknown',quests={},access={}},
        personalObservation={actions={},items={}},dynamicPositions={},actionPolicies={}}))
    local prepared=finish(job)
    assert(prepared.options.conditionObservation.sequence==7 and prepared.options.conditionObservation.quests[71]==allowed)
    assert(prepared.options.personalObservation.loading==false)
    assert(prepared.options.personal[1].cooldownSeconds==10)
    assert(solve(prepared).status==(allowed and 'complete' or 'unknown'),'Sparse capture preserves provided conditions in the same job')
end
do
    local c,_,key=personalContext('spell')
    c.connections[1].requirements={access={{key='gate',allowed=true}}}
    c.conditionObservation={sequence=3,worldState='ready',access={gate=false}}
    local job,requests=observationPause(c)
    assert(next(requests.access)==nil)
    assert(job:ResumeObservations({conditionObservation={sequence=1,worldState='ready',access={gate=true}}}))
    assert(solve(finish(job)).status=='unknown','A provided negative fact cannot be granted by an unrequested capture')
    c,_,key=personalContext('spell');c.personalObservation.actions[key].loaded=nil
    job,requests=observationPause(c)
    assert(requests.actions[key])
    assert(job:ResumeObservations({personalObservation={actions={[key]={loaded=true,known=false}}}}))
    assert(solve(finish(job)).status=='unknown','An explicit native revocation guards a requested action')
end
do
    local c,_,key=personalContext('spell')
    c.personalObservation.actions[key].known=false;c.actionPolicies[key].cooldownSeconds=0
    local job,requests=observationPause(c)
    assert(next(requests.actions)==nil)
    assert(job:ResumeObservations({personalObservation={actions={[key]={known=true}}},
        actionPolicies={[key]={cooldownSeconds=20,chargeBased=true}}}))
    local prepared=finish(job)
    assert(prepared.options.personal[1].cooldownSeconds==0 and prepared.options.personal[1].chargeBased==false)
    for _,fact in pairs(prepared.options.personalObservation.actions)do assert(fact.known==false) end
    assert(solve(prepared).status=='unknown','Unrequested positive capture cannot replace supplied negative action facts')
    c,_,key=personalContext('spell');c.personalObservation.actions[key].loaded=nil
    job=observationPause(c)
    assert(job:ResumeObservations({personalObservation={actions={[key]={loaded=true,readyAt=12}}}}))
    assert(solve(finish(job)).estimatedSeconds==17,'A captured cooldown revokes earlier availability')
end
for _,field in ipairs({'cast','load','ready','loaded','usable','known','origin'})do
    local c,_,key=personalContext('spell')
    if field=='cast' then c.config.defaultSpellCastSeconds=nil
    elseif field=='load' then c.config.actionLoadingSeconds=nil
    elseif field=='origin' then c.personalObservation.origin.reliable=nil
    else c.personalObservation.actions[key][field=='ready' and 'readyAt' or field]=nil end
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Missing '..field..' cannot grant personal travel')
end
for _,field in ipairs({'loading','combat','casting'})do
    local c=personalContext('spell');c.personalObservation[field]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
end
do
    local c,_,key=personalContext('spell')
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    local planner=assert(library.New(prepared.graph,prepared.options))
    assert(F.Finish(planner:Plan(prepared.request)).status=='complete')
    local observation=ns.NavigationV2WaypointTarget.Copy(prepared.options.personalObservation)
    observation.revision=2
    for _,fact in pairs(observation.actions)do fact.known=false end
    assert(planner:ObservePersonal(observation))
    assert(F.Finish(planner:Plan(prepared.request)).status=='unknown')
    assert(planner:ObservePersonal(observation)==false,'Repeated observation is stale')
    c.personalObservation.origin.node='another-origin'
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
    assert(solve(finish(assert(api.Prepare({from=personalRequest.to,to=personalRequest.from},c)))).status=='unknown')
end
do
    local c=personalContext('item')
    c.connections[1].to={dynamic='bind'}
    c.bindings={[71]={world=1,x=4,y=0,z=3,areaID=71},[72]={world=2,x=8,y=0,z=3,areaID=72}}
    local job,requests=observationPause(c)
    assert(requests.dynamic.bind.kind=='bind')
    assert(job:ResumeObservations({dynamicPositions={bind={reliable=true,areaID=71}}}))
    assert(solve(finish(job)).estimatedSeconds==5)
    c.deferObservations=false;c.dynamicPositions={bind={reliable=true,areaID=72}}
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Another bind is not the first candidate')
    c.dynamicPositions.bind={areaID=71}
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
    c.dynamicPositions.bind={reliable=true,areaID=71}
    c.bindings[71]={{world=1,x=4,y=0,z=3}}
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Candidate arrays are not exact bind facts')
    c.dynamicPositions.bind={reliable=true,position=personalRequest.to}
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).estimatedSeconds==5)
    c.bindings[71]={world=1,x=4,y=0,z=3,areaID=71}
    c.dynamicPositions.bind={reliable=true,areaID=71}
    job,requests=observationPause(c)
    assert(next(requests.dynamic)==nil)
    assert(job:ResumeObservations({dynamicPositions={bind={reliable=true,position={world=2,x=8,y=0,z=3},areaID=72}}}))
    assert(solve(finish(job)).estimatedSeconds==5,'A supplied exact bind cannot mix with an unrequested position')
    c.dynamicPositions.bind={reliable=false}
    job,requests=observationPause(c)
    assert(next(requests.dynamic)==nil)
    assert(job:ResumeObservations({dynamicPositions={bind={reliable=true,areaID=71}}}))
    assert(solve(finish(job)).status=='unknown','A supplied unreliable bind cannot become reliable by unrequested capture')
end
local repeatedRequest={from={world=0,x=0,y=0,z=3},via={{world=1,x=4,y=0,z=3}},to={world=2,x=8,y=0,z=3}}
local function repeatedPersonal(kind)
    local c,clock,key=personalContext(kind)
    c.connections[2]={id='invented-second-destination',kind=kind,from={dynamic='player'},
        to=repeatedRequest.to,actions={{type=kind,id=101}}}
    return c,clock,key
end
do
    local c=repeatedPersonal('spell')
    local r=ns.NavigationV2WaypointTarget.Copy(repeatedRequest)
    r.via[1].z=nil
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','The declared arrival exception is limited to the final goal')
    r.via[1].z=3;r.to.z=nil
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(solve(prepared).estimatedSeconds==15 and prepared.positions[prepared.request.to].z==nil)
end
for _,missing in ipairs({'cooldownSeconds','chargeBased'})do
    local c,_,key=repeatedPersonal('spell')
    c.actionPolicies[key][missing]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).estimatedSeconds==5)
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown','Unknown '..missing..' permits only one shared use')
    c.personalObservation.actions[key].readyAt=1
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','An unknown future policy cannot justify a future use')
end
do
    local c,_,key=repeatedPersonal('spell')
    c.actionPolicies[key]=nil
    c.connections[1].cooldownGroup='first-alias';c.connections[2].cooldownGroup='second-alias'
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).estimatedSeconds==5)
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown','One ability cannot be spent twice through different group aliases')
    c.connections[2].actions[1].id=202;c.connections[2].cooldownGroup='first-alias'
    c.personalObservation.actions['spell:202']={known=true,loaded=true,usable=true,readyAt=0}
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown','Different abilities in one declared group share the single-use balance')
end
do
    local c,_,key=repeatedPersonal('item')
    c.actionPolicies[key]=nil
    c.connections[1].actions[1].consumable=true
    c.personalObservation.items[101]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
    c.personalObservation.items[101]=1
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).estimatedSeconds==5)
    c.personalObservation.actions[key].owned=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
end
do
    local c,_,key=personalContext('spell')
    c.connections[1].seconds=10;c.personalObservation.actions[key].castSeconds=1.5
    c.config.defaultSpellCastSeconds=10;c.config.actionLoadingSeconds=5
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    assert(solve(prepared).estimatedSeconds==6.5,'Legacy personal action cost uses observed cast plus loading, not an inherited portal weight')
    c.personalObservation.actions[key].castSeconds=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).estimatedSeconds==15,'Declared cast fallback plus loading retains its components')
    c.config.defaultSpellCastSeconds=nil;c.actionPolicies[key]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Legacy personal seconds cannot replace missing cast data')
    c.connections[1].seconds=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
end
do
    local c,_,key=repeatedPersonal('spell')
    local route=solve(finish(assert(api.Prepare(repeatedRequest,c))))
    assert(route.status=='complete' and route.estimatedSeconds==15,'One physical spell shares one cooldown timeline')
    c.actionPolicies[key].chargeBased=true
    c.personalObservation.actions[key].charges=2;c.personalObservation.actions[key].maxCharges=2
    route=solve(finish(assert(api.Prepare(repeatedRequest,c))))
    assert(route.status=='complete' and route.estimatedSeconds==10)
    c.personalObservation.actions[key].charges=1;c.personalObservation.actions[key].maxCharges=1
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown','Missing recharge proof cannot create future charges')
    c.personalObservation.actions[key].charges=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
end
do
    local c,_,key=repeatedPersonal('item')
    c.actionPolicies[key].cooldownSeconds=0
    for _,connection in ipairs(c.connections)do connection.actions[1].consumable=true end
    local route=solve(finish(assert(api.Prepare(repeatedRequest,c))))
    assert(route.status=='complete' and route.estimatedSeconds==10)
    assert(route.resourcesSpent['item:forever-item-101']==2)
    c.personalObservation.items[101]=1
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown')
    c.personalObservation.items[101]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Missing inventory cannot become zero or owned=true')
end
do
    local c,_,key=repeatedPersonal('spell')
    for _,connection in ipairs(c.connections)do connection.actions[1].reagentID=303 end
    c.actionPolicies[key].reagentCount=1;c.personalObservation.items[303]=2
    local route=solve(finish(assert(api.Prepare(repeatedRequest,c))))
    assert(route.status=='complete' and route.estimatedSeconds==15 and route.resourcesSpent['item:forever-item-303']==2)
    c.personalObservation.items[303]=1
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown')
    c.actionPolicies[key].reagentCount=nil
    local single=solve(finish(assert(api.Prepare(personalRequest,c))))
    assert(single.status=='complete' and single.resourcesSpent['item:forever-item-303']==1,'Legacy reagentID declares one unit')
    c.personalObservation.items[303]=0
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
    c.personalObservation.items[303]=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
    c.personalObservation.items[303]=4;c.actionPolicies[key].reagentCount=2
    local extended=solve(finish(assert(api.Prepare(repeatedRequest,c))))
    assert(extended.status=='complete' and extended.resourcesSpent['item:forever-item-303']==4)
    c.personalObservation.items[303]=3
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown')
    for _,invalid in ipairs({0,-1,1.5,'unknown'})do
        c.actionPolicies[key].reagentCount=invalid
        assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','An invalid explicit quantity cannot default to one')
    end
    c.actionPolicies[key].reagentCount=nil
    c.actionPolicies[key].reagents={typed={itemID=303}}
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Missing typed reagent count is genuinely unknown')
end
do
    local c,_,key=personalContext('spell')
    local a=c.connections[1].actions[1];a.groupSpellID=202;a.groupReagentID=302;a.reagentID=301
    c.actor={inGroup=true}
    c.personalObservation.actions[key].known=false
    c.personalObservation.actions['spell:202']={known=true,loaded=true,usable=true,readyAt=0}
    c.personalObservation.items[302]=1
    c.actionPolicies['spell:202']={cooldownSeconds=0,chargeBased=false}
    local prepared=finish(assert(api.Prepare(personalRequest,c)))
    local group=solve(prepared)
    assert(group.estimatedSeconds==5 and group.resourcesSpent['item:forever-item-302']==1)
    assert(group.resourcesSpent['item:forever-item-301']==nil,'The group alternative does not consume the solo reagent')
    local selected=0
    for _,segment in ipairs(group.segments)do
        local hint=prepared.guidance[segment.edgeId]
        if hint then
            selected=selected+1
            assert(hint.kind=='spell' and hint.action.type=='spell' and hint.action.id==202 and hint.sourceFree==true)
        end
    end
    assert(selected==1 and c.connections[1].actions[1].id==101 and c.connections[1].actions[1].groupSpellID==202)
    c.actor.inGroup=false
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown','Group-only action needs the observed group')
    c.actor.inGroup=nil
    assert(solve(finish(assert(api.Prepare(personalRequest,c)))).status=='unknown')
end
do
    local c,clock=personalContext('spell')
    local job=observationPause(c)
    clock.ms=5001
    assert(job:Step().status=='budget_exceeded','Observation pause consumes the same elapsed budget')
    assert(job:ResumeObservations({})==nil)
    c,clock=personalContext('spell');job=observationPause(c)
    assert(job:Cancel().status=='cancelled' and job:ResumeObservations({})==nil)
    assert(job:Step().status=='cancelled')
    c,clock=personalContext('spell');job=observationPause(c)
    local before=job:GetMetrics().operations
    c.connections={}
    assert(job:ResumeObservations({}))
    local result=finish(job)
    assert(result.status=='unknown' and result.reason=='data_source_changed' and job:GetMetrics().operations>before)
end
local request={from={world=0,x=.5,y=0},to={world=0,x=3.5,y=0}}
do
    local c,clock=personalContext('spell')
    local tick=.01
    c.clock=function()clock.ms=clock.ms+tick;return clock.ms end
    c.budgets={sliceMs=1,cpuMs=3,elapsedMs=5000}
    local job=observationPause(c)
    local before=job:GetMetrics()
    assert(before.cpuMs>0 and before.cpuMs<3)
    tick=(3-before.cpuMs)/2+.01
    assert(job:ResumeObservations({}))
    local result=finish(job)
    assert(result.status=='budget_exceeded' and result.diagnostics.operations==before.operations+2,'CPU consumed before capture is not reset by Resume')
end
do
    local c=personalContext('spell')
    local _,_,terrain=context()
    c.terrain={[0]={packs={invented={data=terrain,revision=1}}}}
    c.connections[1].to={world=0,x=0,y=0,z=3}
    local r={from={world=1,x=0,y=0,z=3},to={world=0,x=3.5,y=0,z=3}}
    local route=solve(finish(assert(api.Prepare(r,c))))
    assert(route.status=='complete' and route.estimatedSeconds==9.25,'Personal arrival uses authored terrain anchors and directed path geometry')
    c.connections[1].to.x=20
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Personal arrival cannot invent a proximity link')
    c.personalObservation=nil;c.actionPolicies=nil
    assert(solve(finish(assert(api.Prepare(request,c)))).estimatedSeconds==4.5,'Unknown personal facts do not ban a known ordinary path')
end
do
    local c,_,key=repeatedPersonal('spell')
    c.actionPolicies[key].cooldownSeconds=nil
    c.connections[1].cooldownSeconds=10;c.connections[2].cooldownSeconds=20
    assert(solve(finish(assert(api.Prepare(repeatedRequest,c)))).status=='unknown','Conflicting models of one ability remain local unknowns')
    c=personalContext('item');c.connections[1].to={dynamic='bind'}
    c.dynamicPositions={bind={reliable=true,areaID=71}}
    local bindings={[71]={world=1,x=4,y=0,z=3,areaID=71}}
    c.data={GetBindings=function()return bindings end}
    local job=assert(api.Prepare(personalRequest,c))
    for _=1,1000 do
        assert(job:Step(1).status=='running')
        if job:GetMetrics().preparedNodes==3 then break end
    end
    bindings={}
    local result=finish(job)
    assert(result.status=='unknown' and result.reason=='data_source_changed','Changed GetBindings identity invalidates publication')
end
do
    local c,_,data=context()
    local originalFrom=data.edges[1].from
    local job=assert(api.Prepare(request,c))
    assert(job:GetMetrics().preparedNodes==0,'Prepare must not enumerate sources')
    local prepared=finish(job)
    assert(prepared.status=='complete' and prepared.provenance.scope=='declared_model')
    assert(prepared.request.from~=prepared.request.to)
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==4.5)
    assert(#route.segments==3)
    assert(next(prepared.guidance)==nil,'Authored ground geometry needs no per-node guidance hints')
    local path=prepared.geometry[route.segments[2].edgeId]
    assert(#path==3 and path[1].x==0 and path[2].y==3 and path[3].x==4)
    assert(prepared.geometry[route.segments[1].edgeId][1].x==.5)
    assert(prepared.positions[prepared.request.from].z==nil,'No observed Z may be fabricated')
    assert(data.edges[1].from==originalFrom and #data.nodes==2 and #data.anchors==2)
    assert(prepared.provenance.collisionQueries==0,'Declared terrain does not need fresh mask proofs')
    assert(solve(finish(assert(api.Prepare({from=request.to,to=request.from},c)))).status=='unknown')
end
do
    local c,_,data=context()
    data.anchors[1].node='b' -- outside this convex volume, no path was declared
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown')
    data.anchors[1].node='a'
    data.anchors[1].path={point(.5),point(.5,2),point(0,2),point(0)}
    local prepared=finish(assert(api.Prepare(request,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==6.5)
    assert(solve(finish(assert(api.Prepare({from=request.to,to=request.from},c)))).status=='unknown')
end
do
    local c,_,data=context()
    data.edges[1].requirements={quests={{questID=59,completed=true}}}
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown')
    c.conditionObservation={sequence=1,worldState='ready',quests={[59]=true}}
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='complete')
    data.edges[1].disabled=true
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown')
end
do
    local c,clock=context()
    local job=assert(api.Prepare(request,c))
    job:Step(1);job:Cancel()
    local stopped=job:Step(128)
    assert(stopped.status=='cancelled' and stopped.graph==nil)
    assert(job:Step(128).diagnostics.operations==stopped.diagnostics.operations)
    job=assert(api.Prepare(request,c));clock.ms=5000
    assert(job:Step(1).status=='budget_exceeded')
end
do
    local c=context()
    c.terrainStatus='missing';c.terrainReason='terrain_build_unavailable'
    local result=finish(assert(api.Prepare(request,c)))
    assert(result.status=='unknown' and result.reason=='terrain_build_unavailable')
end
do
    local c=context()
    local job=assert(api.Prepare(request,c))
    while job:GetMetrics().preparedNodes<=2 do assert(job:Step(1).status=='running') end
    c.terrain[0].packs.sample.revision=8
    local result=finish(job)
    assert(result.status=='unknown' and result.reason=='data_source_changed' and result.graph==nil)
end
local function roadContext(state)
    local c=context();c.terrain={}
    local rows={};for i=1,10 do rows[i]={{from=1,to=10,state=state or 'open'}} end
    c.roads={networks={lane={id='lane',instanceID=0,collision={base='plain',overlays={}},
        walls={},openings={},sections={{id='lane',kind='road',nodes={
            {id='north',x=5,y=8,z=3},{id='south',x=5,y=2,z=3}},
            edges={{id='lane',from='north',to='south',kind='road',bidirectional=false,
                points={point(5,8),point(5,2)}}}}}}},
        collision={plain={id='plain',originX=10,originY=10,cellSize=1,width=10,height=10,rows=rows}}}
    return c
end
do
    local c=roadContext()
    c.roads.collision={};c.roads.networks.lane.walls={{id='unresolved',points={point(4,8),point(4,2)}}}
    local r={from={world=0,x=5,y=8},to={world=0,x=5,y=2}}
    local prepared=finish(assert(api.Prepare(r,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==3,tostring(route.status)..'/'..tostring(route.estimatedSeconds))
    assert(prepared.provenance.collisionQueries==0,'Never re-prove the declared road segment')
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).status=='unknown')
end
do
    local c=roadContext()
    local r={from={world=0,x=7,y=8},to={world=0,x=7,y=2}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(prepared.provenance.collisionQueries>0)
    assert(solve(prepared).estimatedSeconds==3,'A new free chord can beat the road approach')
    assert(prepared.positions[prepared.request.from].z==nil)
    assert(solve(finish(assert(api.Prepare(r,roadContext('blocked'))))).status=='unknown')
    c.roads.networks.lane.openings={{id='unresolved-opening'}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
end
do
    local c=roadContext()
    c.roads.collision={}
    local r={from={world=0,x=5,y=7},to={world=0,x=5,y=3}}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==2,'Ordered projections on one-way segment')
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).status=='unknown')
    c.roads.networks.lane.sections[1].nodes[1].requirements={quests={{questID=61,completed=true}}}
    r.from.y=8
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Endpoint alias must retain its node gate')
    c.conditionObservation={sequence=1,worldState='ready',quests={[61]=true}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
end
do
    local c,_,data=context()
    data.neighborScopeIDs={'outer'}
    data.edges[#data.edges+1]={from='b',to={pack='next',node='a'},neighborScopeID='outer',
        mode='ground',seconds=0,sharedPoint=point(4),polyline={point(4)}}
    c.terrain[0].packs.next={revision=9,data={format=1,scope={id='outer'},
        nodes={{id='a',x=4,y=0,z=3},{id='b',x=8,y=0,z=3}},
        edges={{from='a',to='b',mode='ground',length=4,polyline={point(4),point(8)}}},
        anchors={{node='b',minX=7,maxX=9,minY=-1,maxY=1,minZ=2,maxZ=4}}}}
    local r={from=request.from,to={world=0,x=7.5,y=0}}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==6.5)
    data.edges[2].neighborScopeID='not-declared'
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
end
do
    local c,clock=context()
    c.clock=function()clock.ms=clock.ms+.4;return clock.ms end
    c.budgets={sliceMs=1,cpuMs=3,elapsedMs=5000}
    local job=assert(api.Prepare(request,c))
    local r=finish(job)
    assert(r.status=='budget_exceeded' and r.graph==nil)
    assert(job:Step(128).diagnostics.operations==r.diagnostics.operations)
end
do
    local c=roadContext()
    local roads=c.roads;c.roads=nil
    local revision,reads=1,0
    c.data={GetRoadData=function()reads=reads+1;return roads end,
        GetRoadRevision=function()return revision end,
        BuildEdges=function()error('V1 search is forbidden')end,CanWalk=function()error('V1 walking is forbidden')end}
    local r={from={world=0,x=5,y=8},to={world=0,x=5,y=2}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(reads==1 and solve(prepared).status=='complete')
    local job=assert(api.Prepare(r,c))
    while job:GetMetrics().preparedNodes<=2 do assert(job:Step(1).status=='running') end
    revision=2
    local result=finish(job)
    assert(result.status=='unknown' and result.reason=='data_source_changed' and result.graph==nil)
end
do
    local c=roadContext()
    local network=c.roads.networks.lane
    network.sections[1].edges[1].dropHeight=9
    local r={from={world=0,x=5,y=8},to={world=0,x=5,y=2}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Missing safe-drop evidence stays unknown')
    c.safeDropHeight=8
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.safeDropHeight=9
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).status=='unknown')
end
do
    local c=roadContext()
    local network=c.roads.networks.lane
    network.sections[1].kind='building'
    -- A mask cannot invent an entrance into an unjoined building.
    local r={from={world=0,x=7,y=8},to={world=0,x=5,y=2}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(solve(prepared).status=='unknown')
end
do
    local c,_,data=context()
    data.edges[1].transitionSeconds=2
    assert(solve(finish(assert(api.Prepare(request,c)))).estimatedSeconds==6.5)
    data.edges[1].seconds=3
    assert(solve(finish(assert(api.Prepare(request,c)))).estimatedSeconds==3.5,'Explicit total includes transitions')
    data.edges[1].bidirectional=true
    data.anchors[1].bidirectional=false
    assert(solve(finish(assert(api.Prepare({from=request.to,to=request.from},c)))).status=='unknown')
    data.anchors[1].bidirectional=nil;data.anchors[1].mode='steady'
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown','An air volume cannot authorize a walking connector')
end
local function crossingContext()
    local c=context()
    c.terrain[1]={packs={arrival={revision=4,data={format=1,worldID=1,
        nodes={{id='landing',x=0,y=0,z=3}},edges={},anchors={
            {node='landing',minX=-1,maxX=1,minY=-1,maxY=1,minZ=2,maxZ=4}}}}}}
    c.connections={{id='declared-crossing',kind='portal',bidirectional=false,
        from={space='world',instanceID=0,x=4,y=0,z=3},to={space='world',instanceID=1,x=0,y=0,z=3},
        seconds=3.5,waitSeconds=2,requirements={faction='Alliance'}}}
    c.actor={faction='Alliance'}
    return c,{from={world=0,x=.5,y=0},to={world=1,x=.5,y=0}}
end
do
    local c,r=crossingContext()
    local prepared=finish(assert(api.Prepare(r,c)))
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==10,'Fixed authored transition joins the ready graphs')
    assert(prepared.provenance.preparedTransitions==1)
    assert(#prepared.request.via==0)
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).status=='unknown')
    c.actor.faction='Horde'
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.actor=nil
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
end
do
    local c,r=crossingContext()
    c.connections[2]={id='irrelevant-portal',kind='portal',seconds=.1,bidirectional=true,
        from={world=9,x=100,y=0,z=3},to={world=10,x=200,y=0,z=3}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(#prepared.request.via==0,'Unused portals must never become objective visits')
    assert(prepared.request.to=='query:2','Destination must stay the original request point')
    local route=solve(prepared)
    assert(route.status=='complete' and route.estimatedSeconds==10)
    for _,segment in ipairs(route.segments)do assert(segment.edgeId~='transition-edge:2') end
end
do
    local c,r=crossingContext()
    c.config={actionLoadingSeconds=5};c.connections[1].seconds=nil
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==11.5)
    c.config={}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Missing cost is not zero')
    c.connections[1].seconds=0
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==6.5,'Zero total overrides loading estimate')
end
do
    local c,r=crossingContext()
    local config={actionLoadingSeconds=5}
    c.data={GetConfig=function()return config end}
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==10,'Explicit records can use a separate config getter')
    c=context();c.config=config
    assert(solve(finish(assert(api.Prepare(request,c)))).status=='complete','Optional config cannot veto unrelated terrain')
end
do
    local c,r=crossingContext()
    c.connections[1].requirements={quest=71,quests={{questID=73,completed=true}}}
    c.conditionObservation={sequence=1,worldState='ready',quests={[71]=true,[73]=false}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.conditionObservation.quests={[71]=false,[73]=true}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.conditionObservation.quests={[71]=true,[73]=true}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
end
do
    local c,r=crossingContext()
    c.connections[1].requirements.access={{key='door-open',allowed=true}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.conditionObservation={sequence=1,worldState='ready',access={['door-open']=true}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
    c.conditionObservation.access['door-open']=false
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
end
do
    local c,r=crossingContext()
    local records,config=c.connections,{actionLoadingSeconds=5}
    c.connections=nil
    c.data={GetConnections=function()return records end,GetConfig=function()return config end}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
    local job=assert(api.Prepare(r,c))
    while job:GetMetrics().preparedTransitions==0 do assert(job:Step(1).status=='running') end
    records={}
    local result=finish(job)
    assert(result.status=='unknown' and result.reason=='data_source_changed' and result.graph==nil)
end
do
    local c,r=crossingContext()
    c.connections[1].bidirectional=true
    c.terrain[0].packs.sample.data.edges[1].bidirectional=true
    assert(solve(finish(assert(api.Prepare({from=r.to,to=r.from},c)))).estimatedSeconds==10)
    r.via={{world=0,x=0,y=0}}
    local prepared=finish(assert(api.Prepare(r,c)))
    assert(#prepared.request.via==1 and prepared.request.via[1]=='query:2' and prepared.request.to=='query:3')
    assert(solve(prepared).estimatedSeconds==10)
end
do
    local c,r=crossingContext()
    c.connections[1].from={space='map',uiMapID=70,x=.2,y=.3}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown')
    c.connectionPositions={['declared-crossing']={from={world=0,x=4,y=0,z=3,uiMapID=70}}}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete')
end
do
    local c,r=crossingContext()
    c.connections[1].from.accessKey='entry-room'
    c.connections[1].to.accessKey='arrival-room'
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='complete','Spatial tags do not invent boolean permissions')
    c.connections[1].from={space='map',instanceID=0,uiMapID=70,x=.2,y=.3}
    c.connectionPositions={['declared-crossing']={from={world=8,x=4,y=0,z=3,uiMapID=70}}}
    r.from={world=8,x=4,y=0,z=3}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','A projection cannot contradict the authored native world')
end
do
    for _,location in ipairs({'data','scope','node'})do
        local c,_,data=context()
        if location=='data' then data.accessKey='room-alpha'
        elseif location=='scope' then data.scope.accessKey='room-alpha'
        else for _,node in ipairs(data.nodes)do node.accessKey='room-alpha' end end
        local prepared=finish(assert(api.Prepare(request,c)))
        local route=solve(prepared)
        assert(route.status=='complete' and route.estimatedSeconds==4.5,'A unique spatial channel is not a permission: '..location)
        assert(prepared.positions[prepared.request.from].accessKey==nil,'No current channel observation is invented')
        data.scope.requirements={access={{key='door-open',allowed=true}}}
        assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown')
        c.conditionObservation={sequence=1,worldState='ready',access={['door-open']=true}}
        assert(solve(finish(assert(api.Prepare(request,c)))).status=='complete','Only the real explicit permission is needed')
        c.conditionObservation.access['door-open']=false
        assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown')
        data.scope.requirements.access[1].allowed=false
        assert(solve(finish(assert(api.Prepare(request,c)))).status=='complete','Explicit negative permission remains meaningful')
    end
end
do
    for _,key in ipairs({'accessKey','spaceID','floor','phase'})do
        local c,_,data=context()
        data.scope[key]='channel-alpha'
        if key=='spaceID' then for _,node in ipairs(data.nodes)do node.spaceID=nil end end
        local inputKey=key=='spaceID' and 'space' or key
        local r={from={world=0,x=.5,y=0,[inputKey]='channel-beta'},to=request.to}
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Known scope identity mismatch: '..key)
    end
end
do
    for _,location in ipairs({'scope','node','data'})do
        local c,_,data=context()
        local _,_,other=context()
        if location=='node' then
            for _,node in ipairs(data.nodes)do node.accessKey='room-alpha' end
            for _,node in ipairs(other.nodes)do node.accessKey='room-beta' end
        else
            local a=location=='scope' and data.scope or data
            local b=location=='scope' and other.scope or other
            a.accessKey,b.accessKey='room-alpha','room-beta'
        end
        other.scope.id='other-room';c.terrain[0].packs.other={data=other,revision=8}
        -- Supplying arbitrary permission values cannot resolve a spatial ambiguity.
        c.conditionObservation={sequence=1,worldState='ready',access={['room-alpha']=true,['room-beta']=true}}
        local prepared=finish(assert(api.Prepare(request,c)))
        local ambiguous=false
        for _,gap in ipairs(prepared.provenance.gaps)do if gap.reason=='anchor_ambiguous' then ambiguous=true end end
        assert(ambiguous and solve(prepared).status=='unknown','Overlapping channels stay separate: '..location)
        local r={from={world=0,x=.5,y=0,accessKey='room-alpha'},to={world=0,x=3.5,y=0,accessKey='room-alpha'}}
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==4.5,'A supplied channel selects only that channel')
    end
end
do
    for _,key in ipairs({'spaceID','floor','phase'})do
        local c,_,data=context()
        local _,_,other=context()
        for _,node in ipairs(data.nodes)do node.spaceID=nil end
        for _,node in ipairs(other.nodes)do node.spaceID=nil end
        data.scope[key],other.scope[key]='first-channel','second-channel'
        other.scope.id='other-room';c.terrain[0].packs.other={data=other,revision=8}
        assert(solve(finish(assert(api.Prepare(request,c)))).status=='unknown','Unknown overlapping identity: '..key)
    end
end
local function crossingRoads(key)
    local c=context();c.terrain={}
    local function road(id,a,b,channel)
        a.id,b.id='start','finish';a[key],b[key]=channel,channel
        return {id=id,instanceID=0,sections={{id=id,kind='road',nodes={a,b},
            edges={{id=id,from='start',to='finish',kind='road',bidirectional=true,
                points={point(a.x,a.y),point(b.x,b.y)}}}}}}
    end
    c.roads={networks={
        first=road('first',point(-5),point(5),'room-a'),
        second=road('second',point(0,-5),point(0,5),'room-b')},collision={}}
    return c,{from={world=0,x=0,y=0,z=3},to={world=0,x=5,y=0,z=3,[key]='room-a'}}
end
do
    for _,key in ipairs({'accessKey','space','floor','phase'})do
        local c,r=crossingRoads(key)
        local prepared=finish(assert(api.Prepare(r,c)))
        assert(solve(prepared).status=='unknown','Crossing roads with unknown spatial channel: '..key)
        r.from[key]='room-a'
        assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==2.5,'Known matching road channel: '..key)
        r.from[key]='room-b'
        assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Known incompatible road channel: '..key)
        assert(c.roads.networks.first.sections[1].edges[1].points[1][key]==nil,'Geometry source is read only')
    end
end
do
    local c,r=crossingRoads('accessKey')
    c.connections={{id='at-crossing',kind='portal',seconds=1,bidirectional=false,
        from={world=0,x=0,y=0,z=3,accessKey='room-a'},to={world=1,x=0,y=0,z=3,accessKey='arrival'}}}
    r.to={world=1,x=0,y=0,z=3,accessKey='arrival'}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','An endpoint alias cannot bypass an ambiguous origin')
    r.from.accessKey='room-a'
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==1)
end
do
    local c,r=crossingRoads('accessKey')
    local _,_,terrain=context()
    terrain.scope.accessKey='room-a'
    c.terrain={[0]={packs={room={data=terrain,revision=3}}}}
    c.roads.networks.first=nil
    r.to={world=0,x=3.5,y=0,z=3,accessKey='room-a'}
    assert(solve(finish(assert(api.Prepare(r,c)))).status=='unknown','Terrain and exact road hypotheses must agree before attachment')
    r.from.accessKey='room-a'
    assert(solve(finish(assert(api.Prepare(r,c)))).estimatedSeconds==4.25)
end
