-- Oracle with an explicit calendar of future charge-completion events.
local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local seed=127
local function Pick(n)seed=(seed*48271)%2147483647;return seed%n end
local function Copy(events)local copy={};for i,v in ipairs(events)do copy[i]=v end;return copy end
for scenario=1,40 do
    local d,o=F.Declarations(),F.Observation()
    local maximum,charges,duration=3,1+Pick(3),4+Pick(13)
    for i=1,2 do
        if i==2 then d[2]=F.Declarations()[1];d[2].id='other';d[2].spellID=903;d[2].from='gate' end
        local action=d[i]
        action.chargeBased=true;action.cooldownGroup='recalls';action.moneyCopper=Pick(3)
        action.reagents={powder={itemID=902,count=1}};action.useSeconds=1+Pick(3);action.loadingSeconds=Pick(2)
        o.actions[action.id]={known=true,usable=true,loaded=true,readyAt=100,charges=charges,maxCharges=maximum,
            rechargeStart=99,rechargeSeconds=duration,rechargeRate=1}
    end
    o.moneyCopper=2+Pick(6);o.items[902]=2+Pick(4)
    local g={complete=true,nodes={'cave','gate','town','goal'},edges={
        {id='walk',from='cave',to='town',seconds=6+Pick(13)},
        {id='approach',from='cave',to='gate',seconds=1+Pick(4)},
        {id='stairs',from='gate',to='town',seconds=4+Pick(7)},
        {id='return',from='town',to='cave',seconds=1+Pick(3)},
        {id='finish',from='town',to='goal',seconds=1+Pick(3)}}}
    local arcs={cave={},gate={},town={},goal={}}
    for _,e in ipairs(g.edges)do arcs[e.from][#arcs[e.from]+1]=e end
    for i,action in ipairs(d)do
        arcs[action.from or 'cave'][#arcs[action.from or 'cave']+1]={to='town',action=i,
            seconds=action.useSeconds+action.loadingSeconds}
    end
    local events={}
    for i=1,maximum-charges do events[i]=99+i*duration end
    local visits,best={'town','cave','town','cave'},math.huge
    local function Visit(node,stage,now,money,items,calendar,depth)
        while visits[stage+1]==node do stage=stage+1 end
        if now-100>=best then return end
        if node=='goal' and stage==#visits then best=now-100;return end
        if depth==9 then return end
        for _,arc in ipairs(arcs[node])do
            local useAt,nextMoney,nextItems=now,money,items
            local nextCalendar=Copy(calendar)
            while nextCalendar[1] and nextCalendar[1]<=useAt do table.remove(nextCalendar,1) end
            if arc.action then
                local action=d[arc.action]
                if #nextCalendar==maximum then
                    useAt=table.remove(nextCalendar,1)
                end
                nextCalendar[#nextCalendar+1]=(nextCalendar[#nextCalendar] or useAt)+duration
                nextMoney,nextItems=money+action.moneyCopper,items+1
            end
            if nextMoney<=o.moneyCopper and nextItems<=o.items[902] then
                Visit(arc.to,stage,useAt+arc.seconds,nextMoney,nextItems,nextCalendar,depth+1)
            end
        end
    end
    Visit('cave',0,100,0,0,events,0)
    local p=assert(F.Library.New(g,F.Options(d,o)))
    local r=F.Base.Finish(p:Plan({from='cave',to='goal',via=visits}),1)
    assert(r.status=='complete' and r.estimatedSeconds==best,'Charge calendar oracle mismatch '..scenario)
end
