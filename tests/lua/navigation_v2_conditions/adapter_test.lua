local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Conditions.lua'))('APR',ns)
assert(loadfile('APR-Core/features/navigation/NavigationV2Conditions.lua'))('APR',ns)
local C,A=ns.NavigationV2Conditions,assert(ns.NavigationV2ConditionsAdapter)
local t=C.New()
local binding=assert(t:Track(assert(C.Compile({phase='blue',quests={{questID=301,completed=true}},
    access={{key='gate',allowed=true}}}))))
local calls=0
local secret=setmetatable({},{__eq=function()error('Cannot compare secret')end,__tostring=function()error('secret')end})
local answer=false
local api={issecretvalue=function(v)return rawequal(v,secret)end,C_QuestLog={IsQuestFlaggedCompleted=function(id)
    assert(id==301);calls=calls+1;return answer
end},UnitPhaseReason=function()error('Not phase identity')end,C_Map={GetBestMapForUnit=function()error('Not phase evidence')end}}
local deps=t:Dependencies()
local events=A.Events(deps)
assert(#events==3 and events[1]=='QUEST_LOG_UPDATE' and events[2]=='QUEST_TURNED_IN' and events[3]=='UNIT_PHASE')
assert(#A.Events({quests={}})==0)
assert(A.Affected('BAG_UPDATE',nil,deps,api)==nil)
assert(A.Affected('QUEST_TURNED_IN',999,deps,api)==nil)
assert(A.Affected('QUEST_TURNED_IN',301,deps,api).quests[301])
assert(A.Affected('QUEST_TURNED_IN',secret,deps,api).quests[301],'Secret payload cannot narrow affected dependencies')
assert(A.Affected('QUEST_LOG_UPDATE',nil,deps,api).quests[301])
assert(A.Affected('UNIT_PHASE','target',deps,api)==nil)
assert(A.Affected('UNIT_PHASE','player',deps,api).identity.phase)
assert(A.Affected('UNIT_PHASE',secret,deps,api).identity.phase)
local observation=assert(A.Capture(api,deps,1,'ready',{phase='blue'},{gate=true}))
assert(calls==1 and observation.quests[301]==false and observation.phase=='blue')
assert(t:Observe(observation));assert(t:Get(binding)=='unavailable')
answer=secret
assert(t:Observe(A.Capture(api,deps,2,'ready',{phase='blue'},{gate=true})))
assert(t:Get(binding)=='unknown','Secret query result must not be false')
answer=true
assert(t:Observe(A.Capture(api,deps,3,'ready',{phase=secret},{gate=true}))==false)
assert(t:Get(binding)=='unknown','Secret identity cannot become a default phase')
assert(t:Observe(A.Capture(api,deps,4,'ready',{phase='blue'},{gate=secret}))==false)
assert(t:Get(binding)=='unknown','Secret access cannot authorize')
assert(t:Observe(A.Capture(api,deps,5,'ready',{phase='blue'},{gate=true})))
assert(t:Get(binding)=='available')
local before=calls
assert(t:Observe(A.Capture(api,deps,6,'loading',{phase='blue'},{gate=true})))
assert(calls==before and t:Get(binding)=='unknown','Loading does not query or retain evidence')
assert(not t:Observe(A.Capture(api,deps,7,'unknown',{phase='blue'},{gate=true})))
assert(calls==before)
for _,missing in ipairs({{}, {C_QuestLog={}}, {C_QuestLog={IsQuestFlaggedCompleted=function()error('Unavailable')end}},
    {C_QuestLog={IsQuestFlaggedCompleted=function()return 1 end}},
    {issecretvalue=function()error('Restricted')end,C_QuestLog=api.C_QuestLog}})do
    local o=assert(A.Capture(missing,deps,8,'ready',{phase='blue'},{gate=true}))
    assert(o.quests[301]==nil)
end
assert(A.Capture(false,deps,9,'ready')==nil)
assert(A.Capture(api,false,9,'ready')==nil)
CreateFrame=function()error('No adapter frame')end
C_Timer={NewTicker=function()error('No polling')end,NewTimer=function()error('No adapter timer')end}
assert(loadfile('APR-Core/features/navigation/NavigationV2Conditions.lua'))('APR',{})
