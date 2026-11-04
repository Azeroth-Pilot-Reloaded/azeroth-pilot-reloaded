local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
for _,observed in ipairs({false,true}) do
    local d=F.Declarations();d[1].destination.phase=nil
    local p=assert(F.Library.New(F.Graph(),F.Options(d)))
    local r=F.Base.Finish(p:Plan({from='cave',to='goal'}))
    assert(r.status=='complete' and r.estimatedSeconds==12)
    local t=assert(p:StartTravel(r));local use=assert(t:BeginPersonal())
    local proof={personalId='recall',from='cave',to='town',complete=true,attempt=use.attempt}
    local o={sequence=1,reliable=true,loading=true,node='town',space='world',
        phase=observed and 'observed' or nil,transition=proof}
    assert(t:Observe(o).kind=='personal','Loading never confirms the arrival')
    o.sequence=2;o.loading=nil
    assert(t:Observe(o).kind=='personal','Explicit ready state is still required')
    o.sequence=3;o.loading=false;o.transition=nil
    assert(t:Observe(o).kind=='personal','Location alone is not proof')
    o.sequence=4;o.transition=proof
    local arrived=t:Observe(o)
    assert(arrived.kind=='replan' and arrived.reason=='personal_arrival',
        'Unconstrained arrival must retain the resource/cooldown replan boundary')
end

local p=assert(F.Library.New(F.Graph(),F.Options()))
local r=F.Base.Finish(p:Plan({from='cave',to='goal'}))
local t=assert(p:StartTravel(r));local use=assert(t:BeginPersonal())
local proof={personalId='recall',from='cave',to='town',complete=true,attempt=use.attempt}
local o={sequence=1,reliable=true,loading=false,node='town',space='world',transition=proof}
assert(t:Observe(o).kind=='personal','Missing declared phase must wait for evidence')
o.sequence=2;o.phase='present'
assert(t:Observe(o).kind=='replan')
t=assert(p:StartTravel(r));use=assert(t:BeginPersonal())
o.sequence=1;o.phase='different';o.transition.attempt=use.attempt
assert(t:Observe(o).reason=='personal_destination_mismatch','Known mismatch remains terminal')
