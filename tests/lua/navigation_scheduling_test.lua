-- Deferred navigation requests must coalesce and reject a replaced route context.
local function noop() end
local timers={}
function LibStub() return {GetLocale=function() return {} end} end
function CreateFrame() return {RegisterEvent=noop,SetScript=noop} end
C_Timer={NewTimer=function(delay,callback)
    local t={callback=callback,Cancel=function(self) self.cancelled=true end};timers[#timers+1]=t;return t
end}
APR={NewModule=function() return {} end, PlayerID="p",ActiveRoute="r",RouteQuestStepList={r={}}}
APRData={p={r=1}}
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local calls=0
function APR.navigation:Update() calls=calls+1 end
for i=1,100 do APR.navigation:RequestUpdate() end
assert(#timers==1 and calls==0,"A render burst schedules one deferred routing request")
timers[1].callback();assert(calls==1)
APR.navigation:RequestUpdate()
local old=timers[#timers]
APR:SetRouteProgress("r",2,"manual_skip")
old.callback();assert(calls==1,"A stale scheduled request cannot route another objective")
assert(old.cancelled,"Changing original route progress cancels scheduled guidance")
print("Navigation scheduling: request bursts coalesce; progress invalidates stale callbacks")
