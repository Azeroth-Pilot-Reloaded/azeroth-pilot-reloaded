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
        RegisterUnitEvent = function(self, event, unit)
            self.units = self.units or {}
            self.units[event] = unit
            self:RegisterEvent(event)
        end,
        SetScript = function(self, name, callback) self.scripts[name] = callback end,
        UnregisterAllEvents = function(self) self.events = {} end,
    }
end
APR = { settings = { profile = { enableAddon = true } } }
function APR:NewModule() return {} end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")

local frame = CreateFrame()
assert(APR:RegisterSupportedEvent(frame, "QUEST_LOG_UPDATE"))
assert(not APR:RegisterSupportedEvent(frame, "UNSUPPORTED"))
C_EventUtils = { IsEventValid = function(event) return event ~= "UNSUPPORTED" end }
assert(not APR:RegisterSupportedEvent(frame, "UNSUPPORTED"))
assert(APR:RegisterSupportedEvent(frame, "PLAYER_ENTERING_WORLD"))
APR.event:RegisterEvents()
assert(APR.event.framePool.group.events.GROUP_ROSTER_UPDATE,
    "Group visibility is refreshed when a party is converted to a raid")
assert(APR.event.framePool.load == nil, "The bootstrap event must not allocate an unbound runtime handler")
assert(not APR.event.framePool.lootItems.events.CURRENCY_DISPLAY_UPDATE)
assert(APR.event.framePool.buffs.units.UNIT_AURA == "player")
assert(APR.event.framePool.spell.units.UNIT_SPELLCAST_SUCCEEDED == "player")
assert(APR.event.framePool.tame.units.UNIT_SPELLCAST_START == "player")
assert(APR.event.framePool.updateQuest.units.UNIT_QUEST_LOG_CHANGED == "player")
local fallback = CreateFrame()
fallback.RegisterUnitEvent = nil
assert(APR:RegisterSupportedEvent(fallback, "UNIT_AURA", "player") and fallback.events.UNIT_AURA,
    "Clients without native unit filtering retain event delivery")

APR.IsInstanceWithUI = function() return true end
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
APR.GetCurrentStep, APR.ResetQuestTitleRequests = noop, noop
APR.StartPerformanceSample = function() return 1 end
local samples = 0
APR.FinishPerformanceSample = function() samples = samples + 1 end
APR.event.EventHandler({ tag = "broken", callback = function() error("visible failure") end }, "TEST")
assert(#errors == 1 and errors[1]:find("visible failure") and samples == 1)

local unitCalls, probes = 0, 0
local opaque = {}
APRSecret = { CanAccessValue = function(_, unit) return unit ~= opaque end }
local unitFrame = { tag = "buffs", callback = function() unitCalls = unitCalls + 1 end }
local getProfile = APR.GetSettingsProfile
function APR:GetSettingsProfile() probes = probes + 1; return getProfile(self) end
for _ = 1, 1000 do APR.event.EventHandler(unitFrame, "UNIT_AURA", "raid7") end
APR.event.EventHandler(unitFrame, "UNIT_AURA", nil)
assert(probes == 0 and unitCalls == 0, "Irrelevant units cannot probe instance state, route steps or NPCs")
for _ = 1, 1000 do APR.event.EventHandler({tag = "party"}, "CHAT_MSG_ADDON", "OtherAddon", "data", "RAID") end
assert(probes == 0, "Foreign addon-message bursts cannot enter gameplay dispatch")
APR.event.EventHandler(unitFrame, "UNIT_AURA", "player")
APR.event.EventHandler(unitFrame, "UNIT_AURA", opaque)
assert(unitCalls == 2, "Player and opaque payloads retain the conservative callback path")

APR.event:DebouncedUpdateQuest(1)
APR.event:DebouncedUpdateQuest(1)
assert(timers[1].cancelled and not timers[2].cancelled)
APR.event:CleanupEvents()
assert(timers[2].cancelled, "Cleanup cancels the timer handle; there is no C_Timer.Cancel API")

APR.PlayerID, APR.ActiveRoute = "player", "route"
APRData = { player = { route = 1 } }
APR.GetStep = function()
    return { LootItems = { { itemID = 769, quantityFromSkill = { skill = "cooking", rank = 50 } } } }
end
local refreshes = 0
APR.UpdateStep = function() refreshes = refreshes + 1 end
APR.event.functions.skill()
assert(APR.event.stepRefreshTimer, "Skill changes refresh collection goals without a separate Skill condition")
APR.event.stepRefreshTimer.callback()
assert(refreshes == 1)

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
