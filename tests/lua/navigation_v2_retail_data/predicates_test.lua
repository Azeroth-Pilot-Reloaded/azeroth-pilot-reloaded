local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local D=assert(F.ns.NavigationV2RetailData)
local function Prepare(requirements,observation,actor,config,personal)
    local data={config=config or {},bindings={},connections={{id='test-portal',kind='portal',seconds=8,
        from={space='map',uiMapID=11,x=.1,y=.2},to={space='map',uiMapID=22,x=.3,y=.4},
        requirements=requirements}}}
    local prepared=F.Finish(assert(D.Prepare(data,{from={mapID=11,x=.1,y=.2},to={mapID=22,x=.3,y=.4}},
        {clock=function()return 0 end,conditionObservation=observation,actor=actor,personalObservation=personal})),1)
    assert(prepared.status=='complete',prepared.reason)
    local options=prepared.options;options.clock=function()return 0 end;options.profileClock=function()return 0 end
    local planner=assert(F.Library.New(prepared.graph,options))
    return F.Finish(planner:Plan(prepared.request),1),planner,prepared
end
local yes={sequence=1,worldState='ready',quests={[1001]=false,[1002]=true},access={}}
local result,planner=Prepare({any={{quest=1001},{quest=1002}}},yes)
assert(result.status=='complete' and result.estimatedSeconds==8,'one usable OR alternative must authorize the portal')
assert(Prepare({all={{quest=1001},{quest=1002}}},yes).status=='unknown')
assert(Prepare({faction='Alliance',all={{any={{quest=1001},{quest=1002}}},{minLevel=5}}},yes,
    {faction='Alliance',level=10}).status=='complete')
assert(Prepare({any={{phase={group='test',phase='past'}},{quest=1002}}},yes).status=='complete',
    'unknown phase alternative must not erase a known usable quest alternative')
local phase={sequence=1,worldState='ready',access={['phase:test:past']=true}}
assert(Prepare({phase={group='test',phase='past'}},phase).status=='complete')
assert(Prepare({notCondition={quest=1001}},yes).status=='complete')
assert(Prepare({notCondition={any={{quest=1001},{quest=1002}}}},yes).status=='unknown')
assert(Prepare({any={}},yes).status=='unknown')
assert(Prepare({all={}},yes).status=='complete')
assert(Prepare({any={{quest=1001},{unsupported=true}}},yes).status=='unknown')
assert(Prepare({any={{quest=1001},{quest=1002}}},{sequence=1,worldState='loading',quests={[1002]=true}}).status=='unknown')
assert(planner:ObserveConditions({sequence=2,worldState='ready',quests={[1001]=false,[1002]=false}}))
assert(F.Finish(planner:Plan(result.objective),1).status=='unknown','revoking both alternatives revokes the route')
-- Request actor.mapID cannot be a global substitute for the future source map.
assert(Prepare({maps={11},notMaps={22}},yes,{mapID=999}).status=='complete')
assert(Prepare({maps={22}},yes,{mapID=11}).status=='unknown')
assert(Prepare({garrison={type=2,minLevel=3}},
    {sequence=1,worldState='ready',access={['garrison:2:3']=true}}).status=='complete')
assert(Prepare({housing=false},
    {sequence=1,worldState='ready',access={['housing:available']=false}}).status=='complete')
local outdoor={NavigationSpaces={{id='test-exterior',kind='outdoor',mapIDs={11}}}}
assert(Prepare({notInstance=true},yes,nil,outdoor).status=='complete')
local origin={origin={node='retail-point:1',reliable=true,indoors=true}}
assert(Prepare({notInstance=true},yes,{inInstance=true},outdoor,origin).status=='unknown',
    'actual instance observation overrides a generic exterior at the confirmed departure')
assert(Prepare({outdoors=true},yes,nil,outdoor,origin).status=='unknown')
origin.origin.node='another-departure'
assert(Prepare({outdoors=true},yes,nil,outdoor,origin).status=='complete',
    'current indoor observation cannot deny an unrelated future exterior')
local courtyard={NavigationSpaces={{id='test-instance',kind='instance',mapIDs={11}},
    {id='test-courtyard',kind='outdoor',mapIDs={11},parentSpace='test-instance'}}}
assert(Prepare({notInstance=true},yes,nil,courtyard).status=='unknown',
    'an exterior child still inherits its declared instance')
local mapFacts={config={MapRequirements={[22]={phase={group='arrival',phase='old'}}}},bindings={},connections={{
    id='arrival-gate',kind='portal',seconds=4,from={space='map',uiMapID=11,x=.1,y=.2},to={space='map',uiMapID=22,x=.3,y=.4}}}}
local request={from={mapID=11,x=.1,y=.2},to={mapID=22,x=.3,y=.4}}
local scoped=F.Finish(assert(D.Prepare(mapFacts,request,{clock=function()return 0 end,
    conditionObservation={sequence=1,worldState='ready',access={['phase:arrival:old']=true}}})),1)
assert(scoped.graph.edges[1].requirements.world==nil,'destination conditions cannot require current player in the future world')
local o=scoped.options;o.clock=function()return 0 end;o.profileClock=function()return 0 end
assert(F.Finish(assert(F.Library.New(scoped.graph,o)):Plan(scoped.request),1).estimatedSeconds==4)
