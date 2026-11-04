local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
for _,observed in ipairs({false,true}) do
    local declarations=F.Catalog();declarations[1].phase=nil;declarations[1].destination.phase=nil
    local clock={now=0}
    local p=assert(F.Library.New({complete=true,nodes={'gate','far'},edges={}},{
        clock=function()return clock.now end,profileClock=function()return 0 end,
        portals=declarations,portalObservation={revision=1,portals={door={open=true,access=true}}}}))
    local r=F.Finish(p:Plan({from='gate',to='far'}))
    assert(r.status=='complete' and r.estimatedSeconds==6)
    local t=assert(p:StartTravel(r))
    local function location(sequence,node,space,proof)
        return {sequence=sequence,reliable=true,loading=false,node=node,space=space,
            phase=observed and 'current' or nil,transition=proof}
    end
    assert(t:Observe(location(1,'gate','home')).kind=='use_portal','No origin phase constraint')
    assert(t:Observe(location(2,'far','other')).kind=='approach','Cannot arrive before use')
    assert(t:Observe(location(3,'gate','home')).kind=='use_portal')
    local started=assert(t:BeginUse())
    local proof={portalId='door',from='gate',to='far',complete=true,attempt=started.attempt}
    local o=location(4,'far','other',proof);o.loading=true
    assert(t:Observe(o).kind=='awaiting_transition')
    assert(t:Observe(location(5,'far','other')).kind=='awaiting_transition')
    o=location(6,'far','other',proof);o.reliable=false
    assert(t:Observe(o).kind=='awaiting_transition')
    assert(t:Observe(location(6,'far','other',proof)).kind=='awaiting_transition')
    assert(t:Observe(location(7,'far','wrong',proof)).kind=='awaiting_transition','Space remains required')
    assert(t:Observe(location(8,'far','other',proof)).kind=='complete')
    local old=assert(p:StartTravel(r));old:Observe(location(1,'gate','home'));old:BeginUse()
    old:Cancel();assert(old:Observe(location(2,'far','other',proof)).kind=='cancelled')
    old=assert(p:StartTravel(r));old:Observe(location(1,'gate','home'));old:BeginUse()
    p:Invalidate();assert(old:GetAction().kind=='cancelled')
end

-- An explicit destination phase remains a required condition after loading.
local p=F.PortalPlanner()
local r=F.Finish(p:Plan({from='start',to='goal'}));local t=assert(p:StartTravel(r))
t:Observe(F.Location(1,'gate','home'));local start=assert(t:BeginUse())
local proof={portalId='door',from='gate',to='far',complete=true,attempt=start.attempt}
local o=F.Location(2,'far','other',proof);o.phase=nil;o.loading=false
assert(t:Observe(o).kind=='awaiting_transition','Missing declared destination phase stays pending')
o=F.Location(3,'far','other',proof);o.phase='different';o.loading=false
assert(t:Observe(o).kind=='awaiting_transition','Mismatched declared phase cannot arrive')
o=F.Location(4,'far','other',proof);o.loading=false
assert(t:Observe(o).kind=='walk')
