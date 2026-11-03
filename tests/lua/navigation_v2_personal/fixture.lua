local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local _,ns=Base.Load()
assert(ns.NavigationV2Personal,'Real library XML must load Personal; no test injection')
local F={Personal=ns.NavigationV2Personal,ns=ns,Base=Base,Library=ns.LibAPRNavigationV2}
function F.Declarations()
    return {{id='recall',kind='spell',spellID=901,to='town',name='Recall',
        destination={space='world',phase='present'},useSeconds=3,loadingSeconds=2,
        cooldownSeconds=60,timeoutSeconds=20,moneyCopper=4,reagents={travel_powder={itemID=902,count=2}}}}
end
function F.Observation(revision)
    return {revision=revision or 1,observedAt=100,combat=false,casting=false,loading=false,moneyCopper=12,
        items={[902]=5},origin={node='cave',space='underground',phase='present',indoors=true,reliable=true},
        actions={recall={known=true,loaded=true,usable=true,readyAt=100}}}
end
function F.Graph()
    return {complete=true,nodes={'cave','town','goal'},edges={
        {id='normal',from='cave',to='goal',seconds=40},
        {id='finish',from='town',to='goal',seconds=7}}}
end
function F.Options(declarations,observation,time)
    time=time or {wall=100}
    return {clock=function()return time.wall end,profileClock=function()return 0 end,
        personal=declarations or F.Declarations(),personalObservation=observation or F.Observation()}
end
function F.Taxi(fare)
    return {id='flight',from='town',to='goal',fareCopper=fare,timeoutSeconds=60,
        origin={id='harbor',worldID=7,floorID=0,phaseID='present',taxiNodeID=1,title='Flight'},
        destination={id='village',worldID=7,floorID=0,phaseID='present',taxiNodeID=2,title='Flight'},
        costs={approach=0,boarding=1,ride=4,loading=0,disembark=1,final=0}}
end
function F.TaxiObservation(fare)
    return {revision=1,nodes={harbor={discovered=true},village={discovered=true}},
        routes={flight={reachable=true,fareCopper=fare}}}
end
return F
