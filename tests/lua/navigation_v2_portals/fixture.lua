local F = dofile('tests/lua/navigation_v2/fixture.lua')
function F.Catalog(loading)
    return {{id='door',from='gate',to='far',phase='blue',destination={space='other',phase='blue'},
        entry={mapID=42,x=.2,y=.3},name='Ancient portal',waitSeconds=1,useSeconds=2,
        loadingSeconds=loading or 3,timeoutSeconds=30}}
end
function F.Observation(revision,open,phase)
    return {revision=revision or 1,phase=phase or 'blue',portals={door={open=open ~= false,access=true}}}
end
function F.PortalPlanner(loading)
    local time={wall=0}
    local planner=assert(F.Library.New({complete=true,nodes={'start','gate','far','goal'},edges={
        {id='approach',from='start',to='gate',seconds=4},
        {id='walk',from='gate',to='far',seconds=20},
        {id='finish',from='far',to='goal',seconds=3}}}, {
        clock=function() return time.wall end,profileClock=function() return 0 end,
        portals=F.Catalog(loading),portalObservation=F.Observation()}))
    return planner,time
end
function F.Location(sequence,node,space,transition)
    return {sequence=sequence,reliable=true,node=node,space=space,phase='blue',transition=transition}
end
return F
