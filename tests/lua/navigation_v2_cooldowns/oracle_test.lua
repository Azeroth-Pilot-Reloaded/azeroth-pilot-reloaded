-- Independent finite path enumeration. Cooldown availability is an event table;
-- neither the production evaluator nor its Pareto comparisons compute expectations.
local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local seed=19
local function Pick(n)seed=(seed*16807)%2147483647;return seed%n end
for scenario=1,50 do
    local shared=Pick(2)==0
    local d,o=F.Declarations(),F.Observation()
    d[1].useSeconds=1+Pick(3);d[1].loadingSeconds=Pick(3);d[1].cooldownSeconds=3+Pick(12)
    d[1].moneyCopper=Pick(4);d[1].reagents={powder={itemID=902,count=1+Pick(2)}}
    d[1].cooldownGroup='recalls'
    d[2]=F.Declarations()[1];d[2].id='other';d[2].spellID=903;d[2].from='gate'
    d[2].useSeconds=1+Pick(3);d[2].loadingSeconds=Pick(3);d[2].cooldownSeconds=3+Pick(12)
    d[2].moneyCopper=Pick(4);d[2].reagents={powder={itemID=902,count=1+Pick(2)}}
    d[2].cooldownGroup=shared and 'recalls' or 'other_recall'
    o.moneyCopper=3+Pick(10);o.items[902]=2+Pick(7)
    o.actions.recall.readyAt=100+Pick(12)
    o.actions.other={known=true,usable=true,loaded=true,readyAt=100+Pick(12)}
    local g={complete=true,nodes={'cave','gate','town','goal'},edges={
        {id='walk',from='cave',to='town',seconds=8+Pick(12)},
        {id='approach',from='cave',to='gate',seconds=1+Pick(4)},
        {id='stairs',from='gate',to='town',seconds=4+Pick(8)},
        {id='return',from='town',to='cave',seconds=1+Pick(3)},
        {id='finish',from='town',to='goal',seconds=1+Pick(4)}}}
    local arcs={cave={},gate={},town={},goal={}}
    for _,e in ipairs(g.edges)do arcs[e.from][#arcs[e.from]+1]=e end
    local initial={}
    for i,action in ipairs(d)do
        local key=action.cooldownGroup
        initial[key]=math.max(initial[key] or 0,o.actions[action.id].readyAt)
        arcs[action.from or 'cave'][#arcs[action.from or 'cave']+1]={from=action.from or 'cave',
            to='town',action=i,seconds=action.useSeconds+action.loadingSeconds}
    end
    local visits={'town','cave','town','cave'}
    local best=math.huge
    local function Visit(node,stage,now,money,items,ready,depth)
        while visits[stage+1]==node do stage=stage+1 end
        if now-100>=best then return end
        if node=='goal' and stage==#visits then best=now-100;return end
        if depth==9 then return end
        for _,arc in ipairs(arcs[node])do
            local nextTime,nextMoney,nextItems=now+arc.seconds,money,items
            local nextReady={};for k,v in pairs(ready)do nextReady[k]=v end
            if arc.action then
                local action=d[arc.action]
                nextMoney,nextItems=money+action.moneyCopper,items+action.reagents.powder.count
                local start=math.max(now,ready[action.cooldownGroup])
                nextTime=start+arc.seconds
                nextReady[action.cooldownGroup]=start+action.cooldownSeconds
            end
            if nextMoney<=o.moneyCopper and nextItems<=o.items[902] then
                Visit(arc.to,stage,nextTime,nextMoney,nextItems,nextReady,depth+1)
            end
        end
    end
    Visit('cave',0,100,0,0,initial,0)
    local p=assert(F.Library.New(g,F.Options(d,o)))
    local r=F.Base.Finish(p:Plan({from='cave',to='goal',via=visits}),1)
    assert(r.status=='complete' and r.estimatedSeconds==best,'Exact oracle mismatch scenario '..scenario)
end
