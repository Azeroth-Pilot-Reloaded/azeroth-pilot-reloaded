local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local F={Base=Base,Library=Base.Library}
function F.Gate(key)return {access={{key=key,allowed=true}}}end
function F.Unlock(id,node,key,seconds,requirements)
    return {id=id,node=node,destination='goal',title='Ask the keeper',opens=F.Gate(key),
        completionSeconds=seconds,requirements=requirements}
end
function F.Graph()
    return {complete=true,nodes={'start','near','far','goal'},edges={
        {id='near',from='start',to='near',seconds=1},
        {id='far',from='start',to='far',seconds=4},
        {id='near-finish',from='near',to='goal',seconds=30,requirements=F.Gate('near-open')},
        {id='far-finish',from='far',to='goal',seconds=2,requirements=F.Gate('far-open')}}}
end
function F.Entries()
    return {F.Unlock('near-keeper','near','near-open',10),F.Unlock('far-keeper','far','far-open',3)}
end
function F.Planner(graph,entries,extra)
    local options={clock=function()return 100 end,profileClock=function()return 0 end,
        conditionObservation={sequence=1,worldState='ready',access={['near-open']=false,['far-open']=false}},
        unlocks=entries or F.Entries()}
    for k,v in pairs(extra or {})do options[k]=v end
    return assert(F.Library.New(graph or F.Graph(),options))
end
function F.Result(p,request)return F.Base.Finish(p:Plan(request or {from='start',to='goal'}),1)end
return F
