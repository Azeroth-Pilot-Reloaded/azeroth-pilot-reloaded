local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local graph={complete=true,nodes={'gate','far'},edges={}}
local options={clock=function() return 0 end,profileClock=function() return 0 end,portals=F.Catalog()}
local p=assert(F.Library.New(graph,options))
local function Route() return F.Finish(p:Plan({from='gate',to='far'})) end
assert(Route().status=='unknown','missing observation is not no_path')
assert(p:ObservePortals({revision=1,portals={door={open=true,access=true}}})==false)
assert(Route().status=='unknown','unknown player phase is conservative')
assert(p:ObservePortals({revision=2,phase='blue',portals={door={open=true}}})==false)
assert(Route().status=='unknown','unknown access is conservative')
assert(p:ObservePortals(F.Observation(3,false)))
assert(Route().status=='no_path')
assert(p:ObservePortals(F.Observation(4,true,'red'))==false)
assert(Route().status=='no_path')
assert(p:ObservePortals(F.Observation(5)))
assert(Route().estimatedSeconds==6)
local revision=p.revision
assert(p:ObservePortals({revision=6,phase='blue',portals={door={open='yes',access=true}}})==nil)
assert(p.revision==revision and Route().estimatedSeconds==6)
assert(p:ObservePortals(F.Observation(6))==false)
local old=p:Plan({from='gate',to='far'})
assert(p:SetPortalCosts('door',{loadingSeconds=9}))
assert(old:Step().status=='stale')
assert(Route().estimatedSeconds==12)
assert(p:SetPortalCosts('door',{useSeconds=-1})==nil)
assert(Route().estimatedSeconds==12)
options.portals[1].entry=nil
local noPosition=assert(F.Library.New(graph,options))
noPosition:ObservePortals(F.Observation())
local t=assert(noPosition:StartTravel(F.Finish(noPosition:Plan({from='gate',to='far'}))))
assert(t:GetAction().kind=='approach' and t:GetAction().position==nil)

for _, edit in ipairs({function(c) c[1].loadingSeconds=0/0 end,
    function(c) c[1].timeoutSeconds=0 end,function(c) c[1].destination.phase=nil end,
    function(c) c[1].entry.x=2 end,function(c) c[2]=c[1] end,
    function(c) c[3]=c[1];c[1]=nil end}) do
    local c=F.Catalog();edit(c);options.portals=c
    assert(F.Library.New(graph,options)==nil,'invalid catalog must fail at boundary')
end

local invalid=F.Catalog();invalid[1].from='absent';options.portals=invalid
assert(F.Finish(assert(F.Library.New(graph,options)):Plan({from='gate',to='far'})).reason=='invalid_portal_node')
