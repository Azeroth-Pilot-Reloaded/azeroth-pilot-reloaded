local function noop() end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function LibStub() return { GetLocale = function() return {} end } end
local timers, errors = {}, {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
function geterrorhandler() return function(message) errors[#errors + 1] = message end end
function CreateFrame()
    return {
        events = {}, scripts = {},
        RegisterEvent = function(self, event)
            if event == "UNSUPPORTED" then error("Unknown event") end
            self.events[event] = true
        end,
        SetScript = function(self, name, callback) self.scripts[name] = callback end,
        UnregisterAllEvents = function(self) self.events = {} end,
    }
end
APR = { settings = { profile = { enableAddon = true } } }
function APR:NewModule() return {} end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/core/Event.lua")

local frame = CreateFrame()
assert(APR:RegisterSupportedEvent(frame, "QUEST_LOG_UPDATE"))
assert(not APR:RegisterSupportedEvent(frame, "UNSUPPORTED"))
C_EventUtils = { IsEventValid = function(event) return event ~= "UNSUPPORTED" end }
assert(not APR:RegisterSupportedEvent(frame, "UNSUPPORTED"))
assert(APR:RegisterSupportedEvent(frame, "PLAYER_ENTERING_WORLD"))
APR.event:RegisterEvents()
assert(APR.event.framePool.load == nil, "The bootstrap event must not allocate an unbound runtime handler")
assert(not APR.event.framePool.lootItems.events.CURRENCY_DISPLAY_UPDATE)

APR.IsInstanceWithUI = function() return true end
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
APR.GetCurrentStep, APR.ResetQuestTitleRequests = noop, noop
APR.StartPerformanceSample = function() return 1 end
local samples = 0
APR.FinishPerformanceSample = function() samples = samples + 1 end
APR.event.EventHandler({ tag = "broken", callback = function() error("visible failure") end }, "TEST")
assert(#errors == 1 and errors[1]:find("visible failure") and samples == 1)

APR.event:DebouncedUpdateQuest(1)
APR.event:DebouncedUpdateQuest(1)
assert(timers[1].cancelled and not timers[2].cancelled)
APR.event:CleanupEvents()
assert(timers[2].cancelled, "Cleanup cancels the timer handle; there is no C_Timer.Cancel API")

dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
local standings = { [1] = false, [2] = false }
function APR:IsReputationLevelReached(requirement) return standings[requirement.factionID] end
local steps = { { AllOf = { { Reputation = { factionID = 1, level = 5 } } },
    Not = { Reputation = { factionID = 2, level = 5 } } } }
local signature = APR.questOrderListSupport:GetReputationStateSignature(steps)
standings[1] = true
local afterAllOf = APR.questOrderListSupport:GetReputationStateSignature(steps)
assert(signature ~= afterAllOf)
standings[2] = true
assert(afterAllOf ~= APR.questOrderListSupport:GetReputationStateSignature(steps))
print("Events: supported registration, visible errors, timer cancellation and nested reputation invalidation passed")
