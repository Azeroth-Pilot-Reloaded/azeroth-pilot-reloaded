local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
-- All mandatory locations are conjunctive request constraints, irrespective
-- of validation order: a denied destination cannot become usable by learning
-- the still-unknown origin/visit fact.
local graph={complete=true,nodes={{id='cave',requirements=F.Require('origin')},
    {id='town',requirements=F.Require('visit')},{id='goal',requirements=F.Require('destination')}},edges={
    {id='approach',from='cave',to='town',seconds=1},{id='finish',from='town',to='goal',seconds=1}}}
local p=F.Planner(graph,{sequence=1,worldState='ready',access={destination=false}})
local r=F.Result(p,{from='cave',to='goal',via={'town'}})
assert(r.status=='no_path','Denied mandatory destination outranks unknown origin/visit')
p=F.Planner(graph,{sequence=1,worldState='ready',access={origin=true,destination=true,visit=false}})
assert(F.Result(p,{from='cave',to='goal',via={'town'}}).status=='no_path')
p=F.Planner(graph,{sequence=1,worldState='ready',access={origin=true,destination=true}})
assert(F.Result(p,{from='cave',to='goal',via={'town'}}).status=='unknown')
