local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local graph={complete=true,nodes={'start','goal'},edges={{id='ride',from='start',to='goal',seconds=20,
    movement={mode='mount',distance=20,canMount='available'},requirements=F.Gate('open')}}}
for _,canMountHere in ipairs({false,true})do
    local movement=assert(F.Library.NewForeverMovement({initialMode='walk',level=40,mountOwned=true,
        mountUsable=true,canMountHere=canMountHere},{mountSpeed=2,mountSeconds=3}))
    local p=F.Planner(graph,{F.Unlock('keeper','start','open',2)},
        {movement=movement,conditionObservation={sequence=1,worldState='ready',access={open=false}}})
    local r=F.Result(p)
    if canMountHere then assert(r.unlock and r.unlockPlan.estimatedSeconds==15)
    else assert(r.status=='no_path' and not r.unlock,
        'A local prerequisite is not movement: it cannot erase the observed origin mount restriction')end
end
