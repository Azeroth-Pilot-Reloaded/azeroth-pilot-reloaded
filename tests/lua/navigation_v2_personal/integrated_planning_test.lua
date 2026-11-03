local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local function Plan(graph,declarations,observation,extra,request)
    local options=F.Options(declarations,observation)
    for k,v in pairs(extra or {})do options[k]=v end
    local planner=assert(F.Library.New(graph or F.Graph(),options))
    return F.Base.Finish(planner:Plan(request or {from='cave',to='goal'})),planner
end
local r,p=Plan()
assert(r.status=='complete' and r.estimatedSeconds==12 and r.nodes[1]=='cave' and r.nodes[2]=='town')
assert(r.segments[1].kind=='personal' and #r.nodes==3,'No exit node is required for an indoor recall')
local o=F.Observation();o.items[902]=1
assert(Plan(nil,nil,o).estimatedSeconds==40,'Insufficient reagent takes the available normal path')
o.items[902]=2;assert(Plan(nil,nil,o).estimatedSeconds==12)
local d=F.Declarations();d[1].rare=true
assert(Plan(nil,d).estimatedSeconds==40)
o=F.Observation();o.allowRare=true;assert(Plan(nil,d,o).estimatedSeconds==12)
d=F.Declarations();d[1].origin={phase='present',space='underground'}
for _,key in ipairs({'phase','space','reliable'})do
    o=F.Observation();o.origin[key]=nil
    assert(Plan(nil,d,o).estimatedSeconds==40,'Known free alternative wins over unknown shortcut')
end
local noAlternative=F.Graph();table.remove(noAlternative.edges,1)
o=F.Observation();o.origin.phase=nil
assert(Plan(noAlternative,d,o).status=='unknown')
o.origin.phase='wrong';assert(Plan(noAlternative,d,o).status=='no_path')
o.origin.phase='present';assert(Plan(noAlternative,d,o).estimatedSeconds==12)
for _,key in ipairs({'loaded','usable','readyAt'})do
    o=F.Observation();o.actions.recall[key]=nil
    assert(Plan(noAlternative,nil,o).status=='unknown')
end
o=F.Observation();o.origin=nil;assert(Plan(noAlternative,nil,o).status=='unknown')
-- Taxies and personal actions spend a shared copper budget across the journey.
d=F.Declarations();d[1].moneyCopper=7
local graph={complete=true,nodes={'cave','town','goal'},edges={
    {id='approach',from='cave',to='town',seconds=20},{id='whole walk',from='cave',to='goal',seconds=70}}}
o=F.Observation();o.moneyCopper=15
local extra={taxi={F.Taxi(9)},taxiObservation=F.TaxiObservation(9)}
r=Plan(graph,d,o,extra);assert(r.estimatedSeconds==26 and r.resourcesSpent.money==9)
o.moneyCopper=16;r=Plan(graph,d,o,extra)
assert(r.estimatedSeconds==11 and r.resourcesSpent.money==16 and r.resourcesSpent['item:travel_powder']==2)
-- Item use + same-item reagent + a later resource edge consume one physical balance.
d=F.Declarations();d[1].kind,d[1].spellID,d[1].itemID='item',nil,902
d[1].consumable,d[1].itemResourceId,d[1].moneyCopper=true,'travel_powder',0
graph=F.Graph();graph.edges[1].seconds=70
graph.edges[#graph.edges+1]={id='free approach',from='cave',to='town',seconds=20}
graph.edges[2].resources={['item:travel_powder']=2}
o=F.Observation();o.actions.recall={owned=true,loaded=true,usable=true,readyAt=0};o.items[902]=4
r=Plan(graph,d,o);assert(r.estimatedSeconds==27 and r.resourcesSpent['item:travel_powder']==2)
o.items[902]=5;r=Plan(graph,d,o);assert(r.estimatedSeconds==12 and r.resourcesSpent['item:travel_powder']==5)
