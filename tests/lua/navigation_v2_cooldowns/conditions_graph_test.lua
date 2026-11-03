local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local g={complete=true,zones={{id='hall',requirements={access={{key='open',allowed=true}}}}},
    nodes={'cave',{id='gate',zone='hall',requirements={phase='present'}},'town'},edges={
    {id='shortcut',from='cave',to='gate',seconds=1,requirements={quests={{questID=901,completed=true}}}},
    {id='finish',from='gate',to='town',seconds=1},
    {id='detour',from='cave',to='town',seconds=12}}}
local function Plan(observation)
    local options=F.Options();options.personal=nil;options.personalObservation=nil
    options.conditionObservation=observation
    local p=assert(F.Library.New(g,options))
    return F.Base.Finish(p:Plan({from='cave',to='town'})),p
end
local o={sequence=1,worldState='ready',phase='present',access={open=true},quests={[901]=true}}
local r,p=Plan(o);assert(r.estimatedSeconds==2,'Zone, both endpoints and passage conditions compose')
o.access.open=false;assert(Plan(o).estimatedSeconds==12)
o.access.open=nil;assert(Plan(o).estimatedSeconds==12,'A known detour beats an uncertain shortcut')
o.access.open=true;o.phase='other';assert(Plan(o).estimatedSeconds==12)
o.phase='present';o.quests[901]=false;assert(Plan(o).estimatedSeconds==12)
-- Origin/destination constraints also apply without traversing an edge.
g.nodes[1]={id='cave',requirements={world=7}}
o.world=8;r=Plan(o);assert(r.status=='no_path')
o.world=nil;assert(Plan(o).status=='unknown')
g.nodes[1]='cave';g.nodes[3]={id='town',requirements={floor='upper'}}
o.floor=nil;assert(Plan(o).status=='unknown')
o.floor='lower';assert(Plan(o).status=='no_path')
-- Thousands of semantically identical requirements reuse one binding.
g={complete=true,nodes={'cave','town'},edges={}}
for i=1,5000 do g.nodes[#g.nodes+1]={id='node'..i,requirements={phase='present'}} end
o.floor='upper';o.quests[901]=true
r,p=Plan(o);assert(r.status=='no_path' and p.conditions.bindingCount==1)
