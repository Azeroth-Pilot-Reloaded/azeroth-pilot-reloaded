function LibStub() return {GetLocale = function() return {GRIND = 'Reach level %d'} end} end
local now, cooldown, token, completed = 100, 600, 1, 0
local timers = {}
APR = {stepHandlers = {}, PlayerID = 'p', ActiveRoute = 'r', settings = {profile = {enableAddon = true}}}
APRData = {p = {r = 1}}
function APR:CaptureStepContext() return token end
function APR:IsStepContextCurrent(value) return value == token end
function APR:GetCurrentStepToken() return token end
function APR:NextQuestStep() completed = completed + 1; token = token + 1 end
function GetTime() return now end
C_Item = {GetItemCooldown = function() return 100, cooldown, 1 end}
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
dofile('APR-Core/features/questing/StepTravelHandlers.lua')
local handler = APR.stepHandlers.CheckCooldownSkips
assert(not handler({SkipIfCooldown = {{itemID = 6948, operator = '<', seconds = 300}}}))
assert(completed == 0)
now = 401
timers[#timers].callback()
assert(completed == 1, 'Live cooldown must complete without an XP or movement event')
local oldTimer = timers[#timers]
oldTimer.callback()
assert(completed == 1, 'A stale timer must not complete the next step')
now, cooldown = 100, 600
handler({SkipIfCooldown = {{itemID = 6948, operator = '<', seconds = 2, once = true}}})
cooldown = 0
assert(not handler({SkipIfCooldown = {{itemID = 6948, operator = '<', seconds = 2, once = true}}}))
assert(completed == 1, 'Entry-only branch must not change during the step')
token = token + 1
handler({SkipIfCooldown = {{itemID = 6948, operator = '<', seconds = 2, once = true}}})
assert(completed == 2, 'A new step must evaluate its own entry condition')
token = token + 1
cooldown = 600
handler({SkipIfCooldown = {{itemID = 6948, operator = '>', seconds = 2, once = true}}})
assert(completed == 3, 'An unavailable hearthstone selects the walking branch')

local level = 59
function UnitLevel() return level end
function UnitXPMax() return 200000 end
C_QuestLog = {IsOnQuest = function(q) return q == 1 or q == 2 end,
              IsComplete = function(q) return q == 1 or q == 3 end}
function GetQuestLogRewardXP(q) return q == 1 and 5000 or 99999 end
dofile('APR-Core/utils/RouteUtils.lua')
local target = {level = 60, xp = 0, questLogXP = {1, 1, 2, 3}}
assert(APR:GetPendingRouteQuestXP(target.questLogXP) == 5000, 'Credit only ready, unclaimed quests, once')
assert(APR:ResolveLevelRequirement(target) == 59.975)
assert(target.xp == 0 and #target.questLogXP == 4, 'Never mutate saved route data')
assert(APR:GetGrindStepText(target) == 'Reach level 60 - 5000 XP')
GetQuestLogRewardXP = nil
assert(APR:ResolveLevelRequirement(target) == 60, 'Unavailable XP data must not skip required XP')
level = 60
assert(APR:ResolveLevelRequirement(target) == 60)
print('Cooldown branches and pending quest XP: OK')
