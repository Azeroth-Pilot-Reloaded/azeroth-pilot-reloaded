local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
local C=assert(ns.NavigationV2Conditions)
local t=C.New()
local function track(requirements)return assert(t:Track(assert(C.Compile(requirements))))end
local open=track({})
local quest=track({quests={{questID=101,completed=true}}})
local negative=track({quests={{questID=101,completed=false}}})
local phase=track({world=0,space='hall',floor='upper',phase='blue'})
local gate=track({access={{key='gate',allowed=true}}})
local both=track({quests={{questID=101,completed=true}},access={{key='gate',allowed=true}}})
assert(t:Get(open)=='available')
assert(t:Get(quest)=='unknown' and t:Get(negative)=='unknown')
assert(t:Get(phase)=='unknown' and t:Get(gate)=='unknown')
assert(t:Observe({sequence=1,worldState='ready',quests={[101]=false},access={gate=true},
    world=0,space='hall',floor='upper',phase='blue'}))
assert(t:Get(quest)=='unavailable' and t:Get(negative)=='available')
assert(t:Get(phase)=='available' and t:Get(gate)=='available' and t:Get(both)=='unavailable')
local token=t:GetToken()
assert(t:IsCurrent(token))
assert(not t:Observe({sequence=2,worldState='ready',quests={[101]=false},access={gate=true},
    world=0,space='hall',floor='upper',phase='blue'}))
assert(t:IsCurrent(token),'Fresh unchanged evidence must not retire a job')
assert(t:Observe({sequence=3,worldState='ready',quests={[101]=true},access={gate=true},
    world=0,space='hall',floor='upper',phase='red'}))
assert(not t:IsCurrent(token))
assert(t:Get(quest)=='available' and t:Get(negative)=='unavailable')
assert(t:Get(phase)=='unavailable','Same world/map does not prove same phase')
assert(t:Observe({sequence=4,worldState='ready',quests={[101]=true},access={gate=true},world=0,space='hall'}))
local status,why=t:Get(phase)
assert(status=='unknown' and (why=='floor_ambiguous' or why=='phase_unknown'))
assert(not t:Observe({sequence=3,worldState='ready',phase='blue'}))
assert(t:Get(phase)=='unknown','Stale observation cannot restore identity')
assert(t:Observe({sequence=5,worldState='loading',quests={[101]=true},access={gate=true},phase='blue'}))
assert(t:Get(quest)=='unknown' and t:Get(gate)=='unknown' and t:Get(open)=='available')
assert(not t:Observe({sequence=6,worldState='loading'}),'Unchanged unknown must not loop')
assert(t:Observe({sequence=7,worldState='ready',quests={[101]=true},access={gate=true},
    world=0,space='hall',floor='upper',phase='blue'}))
assert(t:Get(phase)=='available' and t:Get(both)=='available')
local deps=t:Dependencies();deps.quests[101]=nil
assert(t:Dependencies().quests[101],'Caller cannot mutate dependency ownership')
local source={phase='blue',access={{key='gate',allowed=true}}}
local compiled=assert(C.Compile(source));source.phase='red';source.access[1].allowed=false
local immutable=assert(t:Track(compiled))
assert(t:Get(immutable)=='available','Compilation captures declaration once')
assert(t:Get({})==nil,'Foreign binding rejected')
assert(not t:IsCurrent({revision=token.revision}),'Foreign token rejected')
local foreign=C.New():GetToken()
foreign.revision=t:GetToken().revision
assert(not t:IsCurrent(foreign),'A matching revision from another owner is still foreign')
