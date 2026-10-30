local timers, queries, offers, completes = {}, 0, {}, {}
local function noop() end
APR = { settings = { profile = { enableAddon = true, autoHandIn = true } } }
local revision, modifier, deferred, available, kind = 1, false, false, false, "COMPLETE"
function APR:CaptureStepContext() return revision end
function APR:IsStepContextCurrent(context) return context == revision end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:IsQuestTurnInDeferred() return deferred end
function IsModifierKeyDown() return modifier end
function GetNumAutoQuestPopUps() queries = queries + 1; return available and 1 or 0 end
function GetAutoQuestPopUp() return 27, kind end
function ShowQuestOffer(id) offers[#offers + 1] = id end
function ShowQuestComplete(id) completes[#completes + 1] = id end
C_Timer = { NewTimer = function(delay, callback)
    assert(delay == 1)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function fire()
    local timer = APR.autocompleteQuestTimer
    assert(timer and not timer.cancelled)
    timer.callback()
end
dofile("APR-Core/features/questing/QuestCache.lua")
for _ = 1, 1000 do APR:PopupAutocompleteQuest() end
assert(#timers == 1 and queries == 1, "Duplicate events share one pending check")
for _ = 1, 5 do fire() end
assert(not APR.autocompleteQuestTimer and #timers == 5 and queries == 6,
    "Missing native popup data cannot leave a permanent retry chain")
APR:PopupAutocompleteQuest()
available = true
fire()
assert(#completes == 1 and completes[1] == 27 and #offers == 0,
    "A delayed completion opens exactly its quest, without a bogus offer for quest 1")
kind = "OFFER"
APR:PopupAutocompleteQuest()
assert(#offers == 1 and offers[1] == 27)
deferred = true
APR:PopupAutocompleteQuest()
assert(#offers == 1 and not APR.autocompleteQuestTimer)
deferred, available = false, false
for _, invalidation in ipairs({ "step", "disabled", "preference", "modifier", "cancel" }) do
    APR:PopupAutocompleteQuest()
    local timer, before = APR.autocompleteQuestTimer, queries
    if invalidation == "step" then revision = revision + 1
    elseif invalidation == "disabled" then APR.settings.profile.enableAddon = false
    elseif invalidation == "preference" then APR.settings.profile.autoHandIn = false
    elseif invalidation == "modifier" then modifier = true
    else APR:CancelAutocompleteQuest(); assert(timer.cancelled) end
    timer.callback() -- A cancelled/stale callback can still be delivered by an adapter.
    assert(not APR.autocompleteQuestTimer and queries == before, "Stale checks cannot query or reschedule: " .. invalidation)
    APR.settings.profile.enableAddon, APR.settings.profile.autoHandIn, modifier = true, true, false
end
APR:PopupAutocompleteQuest()
local stale = APR.autocompleteQuestTimer
APR:CancelAutocompleteQuest()
APR:PopupAutocompleteQuest()
local current = APR.autocompleteQuestTimer
stale.callback()
assert(APR.autocompleteQuestTimer == current, "An obsolete callback cannot consume a new request")
APR:CancelAutocompleteQuest()
print("Quest autocomplete: bounded duplicate bursts, delayed recovery, exact popup identity and cancellation passed")
