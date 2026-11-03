local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
-- Independent exhaustive finite-state relaxation. No production Search, cost,
-- condition evaluator or reconstruction participates in this oracle.
local function Has(mask,bit)return math.floor(mask/2^(bit-1))%2==1 end
local function Allowed(requirements,mask)
    for _,fact in ipairs(requirements and requirements.access or {})do
        local value=Has(mask,tonumber(fact.key:sub(2)))
        if value~=fact.allowed then return false end
    end
    return true
end
local function Oracle(g,entries,enable)
    local distance={['start:0']=0}
    for _=1,#g.nodes*8 do
        local changed=false
        local function Relax(from,to,mask,newMask,seconds)
            local old=distance[from..':'..mask]
            local key=to..':'..newMask
            if old and (not distance[key] or old+seconds<distance[key])then
                distance[key]=old+seconds;changed=true
            end
        end
        for mask=0,7 do
            for _,edge in ipairs(g.edges)do
                if Allowed(edge.requirements,mask)then Relax(edge.from,edge.to,mask,mask,edge.seconds)end
            end
            if enable then for _,entry in ipairs(entries)do
                local bit=tonumber(entry.opens.access[1].key:sub(2))
                if not Has(mask,bit) and Allowed(entry.requirements,mask)then
                    Relax(entry.node,entry.node,mask,mask+2^(bit-1),entry.completionSeconds)
                end
            end end
        end
        if not changed then break end
    end
    local best
    for mask=0,7 do local value=distance['goal:'..mask];if value and (not best or value<best)then best=value end end
    return best
end
local seed=417
local function Random(n)seed=(seed*16807)%2147483647;return seed%n+1 end
local unlockCount,normalCount,disconnected=0,0,0
for case=1,96 do
    local g={complete=true,nodes={'start','near','far','goal'},edges={}}
    local entries={}
    for bit=1,3 do
        entries[bit]=F.Unlock('action-'..bit,g.nodes[Random(3)],'g'..bit,Random(6)-1,
            Random(3)==1 and F.Gate('g'..Random(3)) or nil)
    end
    -- Include alternatives granting the same effect and positive/negative guards.
    if case%3==0 then entries[4]=F.Unlock('alternate',g.nodes[Random(3)],'g1',Random(9)-1)end
    for from=1,4 do for to=1,4 do if from~=to and Random(3)~=1 then
        local guard
        if Random(3)~=1 then guard={access={{key='g'..Random(3),allowed=Random(4)~=1}}}end
        g.edges[#g.edges+1]={id='e'..from..'-'..to,from=g.nodes[from],to=g.nodes[to],seconds=Random(8)-1,requirements=guard}
    end end end
    local native=Oracle(g,entries,false)
    local best=Oracle(g,entries,true)
    local p=F.Planner(g,entries,{conditionObservation={sequence=1,worldState='ready',access={g1=false,g2=false,g3=false}}})
    local r=F.Result(p)
    if native then
        normalCount=normalCount+1
        assert(r.status=='complete' and not r.unlock and r.estimatedSeconds==native,'Normal route oracle case '..case)
    elseif best then
        unlockCount=unlockCount+1
        assert(r.unlock and r.unlockPlan.optimal and r.unlockPlan.estimatedSeconds==best,'Conditional cost oracle case '..case)
        local cost=0
        for _,segment in ipairs(r.segments)do
            assert(not segment.unlockEntry and segment.kind~='unlock')
            cost=cost+segment.seconds
        end
        assert(cost==r.estimatedSeconds and r.travelObjective.to==r.unlock.node)
    else
        disconnected=disconnected+1
        assert(r.status=='no_path' and not r.unlock,'Infeasible oracle case '..case)
    end
    assert(p.conditions.snapshot.access.g1==false and p.conditions.snapshot.access.g2==false and p.conditions.snapshot.access.g3==false)
end
assert(unlockCount>0 and normalCount>0 and disconnected>0,'Oracle must exercise all three outcomes')
