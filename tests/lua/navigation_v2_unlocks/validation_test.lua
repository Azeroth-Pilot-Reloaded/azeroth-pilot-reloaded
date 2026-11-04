local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
local function Invalid(source)
    local p,reason=F.Library.New(F.Graph(),{clock=function()return 1 end,profileClock=function()return 0 end,unlocks=source})
    assert(not p and type(reason)=='string','Malformed unlock input is rejected atomically')
end
for _,source in ipairs({false,'invalid',{false},{[2]=F.Entry()}})do Invalid(source)end
for _,change in ipairs({function(d)d.id=''end,function(d)d.node=12 end,function(d)d.destination=false end,
    function(d)d.title='Meet at 12.5, 32.4'end,function(d)d.opens={phase='after'}end,
    function(d)d.opens={access={{key='garden-open',allowed=false}}}end,
    function(d)d.opens={access={{key='garden-open',allowed=true},{key='other',allowed=true}}}end,
    function(d)d.opens={access={{key='garden-open',allowed=true,script='unsupported'}}}end,
    function(d)d.requirements={unknown=true}end,function(d)d.chain={}end})do
    local entry=F.Entry();change(entry);Invalid({entry})
end
Invalid({F.Entry(),F.Entry()})
local source={}
for i=1,65 do source[i]=F.Entry();source[i].id='entry-'..i end
Invalid(source)
local entry=F.Entry();entry.node='absent'
local r=F.Result(F.Planner(nil,{unlocks={entry}}))
assert(r.status=='invalid' and r.reason=='invalid_unlock_node')
local p=F.Planner()
for _,value in ipairs({false,1,'invalid',{}})do
    local job,reason=p:ResumeUnlock(value)
    assert(not job and reason=='no_unlock')
end
local job,reason=p:ResumeUnlock(nil);assert(not job and reason=='no_unlock')
-- Caller edits cannot replace captured prerequisite identity or its title.
entry=F.Entry();p=F.Planner(nil,{unlocks={entry}});entry.node='absent';entry.title='1, 2'
r=F.Result(p);assert(r.unlock.node=='keeper' and r.unlock.title=='Speak to the keeper')
