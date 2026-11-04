local ns={};assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
local C=ns.NavigationV2Conditions
for _,bad in ipairs({false,'script',{uiMapID=1},{phase=''},{world=-1},{floor=false},
    {quests=false},{quests={[2]={questID=1,completed=true}}},
    {quests={{questID=0,completed=true}}},{quests={{questID=1,completed=1}}},
    {quests={{questID=1,completed=true},{questID=1,completed=false}}},
    {access={{key='',allowed=true}}},{access={{key='gate',allowed='yes'}}},
    {access={{key='gate',allowed=true,script='return true'}}}})do
    local value,reason=C.Compile(bad);assert(value==nil and reason=='invalid_conditions')
end
local huge={quests={}}
for i=1,65 do huge.quests[i]={questID=i,completed=true}end
assert(C.Compile(huge)==nil,'Bound compilation per declaration')
local t=C.New();assert(t:Track({})==nil)
assert(t:Track(assert(C.Compile({phase=0}))))
assert(t:Observe({sequence=1,worldState='ready',phase=0}))
local token=t:GetToken()
for _,bad in ipairs({{}, {sequence=0,worldState='ready'}, {sequence=2,worldState='yes'},
    {sequence=2,worldState='ready',phase=false}, {sequence=2,worldState='ready',quests=false},
    {sequence=2,worldState='ready',access={door=1}}})do
    local value,reason=t:Observe(bad)
    assert(value==nil and reason=='invalid_condition_observation')
    assert(t:IsCurrent(token),'Failed capture must be atomic')
end
