local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
local function Graph()
    return {complete=true,nodes={'cave','town','goal'},edges={
        {id='finish',from='town',to='goal',seconds=2},{id='detour',from='cave',to='goal',seconds=13}}}
end
local constructors={
    portal=function()
        return {portals={{id='door',from='cave',to='town',phase='present',name='Passage',
            destination={space='world',phase='present'},entry={mapID=42,x=.2,y=.3},
            waitSeconds=0,useSeconds=1,loadingSeconds=0,timeoutSeconds=30,requirements=F.Require('transport')}},
            portalObservation={revision=1,phase='present',portals={door={open=true,access=true}}}},3
    end,
    scheduled=function()
        return {scheduled={{id='ferry',kind='boat',from='cave',to='town',access='available',requirements=F.Require('transport'),
            origin={id='west',worldID=7,floorID=0,phaseID='present',title='Departure'},
            destination={id='east',worldID=7,floorID=0,phaseID='present',title='Arrival'},
            costs={approach=0,boarding=0,ride=1,loading=0,disembark=0,final=0},wait={mode='known',seconds=0}}}},3
    end,
    taxi=function()
        local route=F.Native.Taxi(0);route.from,route.to='cave','town'
        route.requirements=F.Require('transport')
        route.costs={approach=0,boarding=0,ride=1,loading=0,disembark=0,final=0}
        return {taxi={route},taxiObservation=F.Native.TaxiObservation(0),resources={money=0}},3
    end,
    personal=function()
        local declarations=F.Native.Declarations();declarations[1].requirements=F.Require('transport')
        return {personal=declarations,personalObservation=F.Native.Observation()},7
    end,
}
for kind,constructor in pairs(constructors)do
    for _,state in ipairs({'allowed','denied','unknown'})do
        local options,expected=constructor()
        local snapshot={sequence=1,worldState='ready',access={transport=true}}
        if state=='denied'then snapshot.access.transport=false elseif state=='unknown'then snapshot.access.transport=nil end
        local p=F.Planner(Graph(),snapshot,options)
        local r=F.Result(p)
        assert(r.status=='complete' and r.estimatedSeconds==(state=='allowed' and expected or 13),
            kind..' requirements must filter its own transport arc')
        if state=='allowed'then assert(r.segments[1].kind==kind)
        else assert(r.segments[1].edgeId=='detour' and r.segments[1].kind==nil)end
    end
end
