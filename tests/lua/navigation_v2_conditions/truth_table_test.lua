local ns={};assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
local C=ns.NavigationV2Conditions
local values={{value=true},{value=false},{}}
for _,left in ipairs(values)do for _,right in ipairs(values)do
    local t=C.New()
    local b=assert(t:Track(assert(C.Compile({quests={{questID=401,completed=true}},access={{key='door',allowed=true}}}))))
    t:Observe({sequence=1,worldState='ready',quests={[401]=left.value},access={door=right.value}})
    local expected='unknown'
    if left.value==false or right.value==false then expected='unavailable'
    elseif left.value==true and right.value==true then expected='available' end
    assert(t:Get(b)==expected,'Independently specified three-valued conjunction')
end end
local t=C.New()
local b=assert(t:Track(assert(C.Compile({world=0,phase='blue',quests={{questID=401,completed=false}}}))))
t:Observe({sequence=1,worldState='ready',world=0,quests={[401]=true}})
assert(t:Get(b)=='unavailable','False quest beats unknown phase across requirement kinds')
t:Observe({sequence=2,worldState='ready',world=0,phase='red'})
assert(t:Get(b)=='unavailable','False phase beats unknown quest')
t:Observe({sequence=3,worldState='ready',world=0,phase='blue'})
assert(t:Get(b)=='unknown','Unknown does not satisfy a negative quest predicate')
