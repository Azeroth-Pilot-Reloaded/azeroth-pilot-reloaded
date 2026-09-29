-- Uncached titles must load without recursion, request floods or stale-route redraws.
local function noop() end
local now, titles, requests, timers = 0, {}, {}, {}
local updates, renders, enabled = 0, 0, true
function LibStub() return { GetLocale = function() return {} end } end
function GetTime() return now end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
C_QuestLog = {
    GetTitleForQuestID = function(id) return titles[id] end,
    RequestLoadQuestByID = function(id) requests[#requests + 1] = id end,
}
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { delay = delay, callback = callback }
        function timer:Cancel() self.cancelled = true end
        timers[#timers + 1] = timer
        return timer
    end,
}
APR = {
    ActiveRoute = "route-a",
    NewModule = function() return {} end,
    Debug = noop,
    GetSettingsProfile = function() return { enableAddon = enabled } end,
    StartPerformanceSample = noop,
    FinishPerformanceSample = noop,
    UpdateStep = function() updates = updates + 1 end,
    questOrderList = { DelayedUpdate = function(_, force)
        assert(force, "Loaded titles must force a list refresh")
        renders = renders + 1
    end },
}
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/core/Event.lua")

assert(APR:GetQuestTitle(nil) == nil)
for _, id in ipairs({ false, "invalid", 0, -1, 1.5 }) do
    assert(APR:GetQuestTitle(id) == nil)
end
assert(#requests == 0, "Invalid IDs must never request data")
titles[1] = "Cached title"
assert(APR:GetQuestTitle("1") == "Cached title" and #requests == 0)
assert(APR:GetQuestTitle(2, false) == nil and #requests == 0)
titles[2] = ""
for _ = 1, 100 do assert(APR:GetQuestTitle(2) == nil) end
assert(#requests == 1 and requests[1] == 2, "Repeated reads must share one pending request")
assert(not APR:OnQuestTitleLoaded(2, false))
now = 29
APR:GetQuestTitle(2)
assert(#requests == 1, "Failed loads must respect the retry delay")
now = 30
APR:GetQuestTitle(2)
assert(#requests == 2, "Failed loads can retry after the delay")
now = 60
APR:GetQuestTitle(2)
assert(#requests == 3, "Unanswered requests can also retry")
titles[2] = "Loaded title"
assert(APR:OnQuestTitleLoaded(2, true))
assert(APR:GetQuestTitle(2) == "Loaded title")
assert(not APR:OnQuestTitleLoaded(2, true), "Duplicate results must be ignored")
assert(not APR:OnQuestTitleLoaded(999, true), "Unrequested results must be ignored")

APR:GetQuestTitle(3)
APR.ActiveRoute = "route-b"
titles[3] = "Old route quest"
assert(not APR:OnQuestTitleLoaded(3, true), "A stale route result must not trigger a redraw")
APR:GetQuestTitle(4)
APR.ActiveRoute = "route-c"
APR:GetQuestTitle(4)
titles[4] = "Shared quest"
assert(APR:OnQuestTitleLoaded(4, true), "A pending quest reused on the new route still refreshes")

for id = 10, 29 do
    APR:GetQuestTitle(id)
    titles[id] = "Quest " .. id
    APR.event.functions.questData("QUEST_DATA_LOAD_RESULT", id, true)
end
assert(#timers == 1 and timers[1].delay == 0.15 and updates == 0,
    "A burst of loaded titles must schedule a single bounded refresh")
timers[1].callback()
assert(updates == 1 and renders == 1, "Both panels refresh once with loaded titles")
APR.event.functions.questData("QUEST_DATA_LOAD_RESULT", 999, true)
assert(#timers == 1, "Unrelated results must not schedule UI work")

APR:GetQuestTitle(30)
titles[30] = "Late result"
APR.event.functions.questData("QUEST_DATA_LOAD_RESULT", 30, true)
enabled = false
timers[2].callback()
assert(updates == 1 and renders == 1, "Disabling APR prevents a queued refresh")
enabled = true
APR:GetQuestTitle(31)
titles[31] = "Cleanup result"
APR.event.functions.questData("QUEST_DATA_LOAD_RESULT", 31, true)
APR:GetQuestTitle(32)
APR.event:CleanupEvents()
assert(timers[3].cancelled, "Cleanup cancels the pending refresh")
titles[32] = "After cleanup"
assert(not APR:OnQuestTitleLoaded(32, true), "Cleanup forgets pending requests")
titles[32] = nil
local count = #requests
APR:GetQuestTitle(32)
assert(#requests == count + 1, "Re-enabling can request data immediately")
print("Quest titles: cache, validation, retries, route changes, event batching and cleanup passed")
