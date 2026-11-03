local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local S=dofile('tests/lua/navigation_v2_sectors/fixture.lua')
local _,_,_,source=S.New({edit=function(index)
    index.meadow.links={};index.pass.links={}
end})
local function Portal(id,to,seconds)
    return {id=id,from='meadow:terrain:1',to=to,phase='present',destination={space='world',phase='present'},
        waitSeconds=0,useSeconds=seconds,loadingSeconds=0,timeoutSeconds=20,requirements=F.Gate('open')}
end
local entry=F.Unlock('keeper','meadow:terrain:1','open',1);entry.destination='harbor:terrain:2'
local p=F.Planner(source,{entry},{portals={Portal('known','harbor:terrain:2',10),Portal('missing','island:terrain:1',0)},
    portalObservation={revision=1,phase='present',portals={known={open=true,access=true},missing={open=true,access=true}}},
    conditionObservation={sequence=1,worldState='ready',access={open=false}}})
local r=F.Result(p,{from='meadow:terrain:1',to='harbor:terrain:2'})
assert(r.unlock and r.unlockPlan.estimatedSeconds==11)
assert(not r.unlockPlan.optimal,'A missing future sector does not certify total conditional optimality')
assert(#r.segments==0 and p.conditions.snapshot.access.open==false)
