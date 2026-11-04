local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local F={Base=Base,Library=Base.Library}
function F.Gate()return {access={{key='garden-open',allowed=true}}}end
function F.Entry()
    return {id='speak-keeper',destination='goal',node='keeper',title='Speak to the keeper',opens=F.Gate()}
end
function F.Graph(detour)
    local graph={complete=true,nodes={'cave','keeper','town','goal'},edges={
        {id='approach',from='cave',to='keeper',seconds=2},
        {id='gate',from='cave',to='town',seconds=1,requirements=F.Gate()},
        {id='return',from='keeper',to='town',seconds=3,requirements=F.Gate()},
        {id='finish',from='town',to='goal',seconds=1}}}
    if detour then graph.edges[#graph.edges+1]={id='detour',from='cave',to='goal',seconds=detour}end
    return graph
end
function F.Planner(graph,extra)
    local options={clock=function()return 100 end,profileClock=function()return 0 end,
        conditionObservation={sequence=1,worldState='ready',access={['garden-open']=false}},unlocks={F.Entry()}}
    for key,value in pairs(extra or {})do options[key]=value end
    return assert(F.Library.New(graph or F.Graph(),options))
end
function F.Result(planner,request)return Base.Finish(planner:Plan(request or {from='cave',to='goal'}),1)end
return F
