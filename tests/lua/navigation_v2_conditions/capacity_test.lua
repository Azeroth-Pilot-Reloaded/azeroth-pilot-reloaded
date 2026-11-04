local ns={};assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
local C=ns.NavigationV2Conditions
local t=C.New();local empty=assert(C.Compile({}))
local first=assert(t:Track(empty))
for _=1,10000 do assert(t:Track(assert(C.Compile({})))==first)end
local last
for id=1,C.MAX_BINDINGS-1 do last=assert(t:Track(assert(C.Compile({quests={{questID=id,completed=true}}}))))end
local token=t:GetToken()
local rejected,why=t:Track(assert(C.Compile({quests={{questID=9000,completed=true}}})))
assert(rejected==nil and why=='condition_capacity_exceeded')
assert(t:IsCurrent(token) and not t:Dependencies().quests[9000],'Capacity rejection must be atomic')
assert(t:Track(empty)==first,'Unconditional sharing stays available at capacity')
local source={sequence=1,worldState='ready',quests={}}
for id=1,C.MAX_BINDINGS-1 do source.quests[id]=true end
assert(t:Observe(source))
assert(t:Get(last)=='available')
local another=C.New()
for block=0,63 do
    local requirements={quests={}}
    for i=1,64 do requirements.quests[i]={questID=block*64+i,completed=true}end
    assert(another:Track(assert(C.Compile(requirements))))
end
assert(another:Track(assert(C.Compile({quests={{questID=5000,completed=true}}})))==nil)
local dependencies=another:Dependencies();local count=0
for _ in pairs(dependencies.quests)do count=count+1 end
assert(count==4096 and not dependencies.quests[5000])
