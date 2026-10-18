-- Real route scans under a synthetic CPU clock: old totals remain published
-- until all batches complete, then the current-step rebuild runs separately.
local function noop() end
local now, timers, samples = 0, {}, {}
function debugprofilestop() return now end
function LibStub() return {GetLocale = function() return {} end} end
function wipe(t) for k in pairs(t) do t[k] = nil end end
function CreateFrame()
    return {scripts = {}, SetScript = function(self, key, fn) self.scripts[key] = fn end,
        Show = noop, Hide = noop, RegisterEvent = noop}
end
function geterrorhandler() return function(err) error(err) end end
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
local function tickTimers()
    local pending = timers; timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
APR = {ActiveRoute = "long", PlayerID = "player", settings = {profile = {enableAddon = true}}}
APRData = {player = {long = 1, short = 1, ["long-TotalSteps"] = 999}}
function APR:NewModule() return {} end
APR.Debug, APR.ResetQuestTitleRequests = noop, noop
function APR:StartPerformanceSample() return now end
function APR:FinishPerformanceSample(name, start)
    if start then samples[name] = math.max(samples[name] or 0, now - start) end
end
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
local routes = {long = {}, short = {{Note = "Short"}}}
for index = 1, 1200 do routes.long[index] = {ReputationLevel = {factionID = index, level = 5}} end
local reached = false
function APR:GetRouteSteps(key) return routes[key] end
function APR:IsSojournerSkipActive() return false end
function APR:StepFilterQoL(entry) now = now + 1; return not entry.ReputationLevel or reached end
function APR:IsReputationLevelReached() now = now + 1; return reached end
local updates, renders = 0, 0
function APR:UpdateStep() updates = updates + 1; now = now + 8 end
APR.questOrderList = {currentRouteKey = "long", reputationState = "old",
    DelayedUpdate = function(_, force) assert(force); renders = renders + 1 end}
local function drain()
    local frame = APR.event.reputationJob.renderFrame
    local ticks = 0
    while frame.scripts.OnUpdate do
        local before = now
        frame.scripts.OnUpdate()
        assert(now - before <= 3, "No scan batch exceeds three simulated milliseconds")
        ticks = ticks + 1
        assert(ticks < 3000, "The job must settle")
    end
    return ticks
end
for _ = 1, 100 do APR.event.functions.reputation() end
assert(#timers == 1)
tickTimers()
assert(now == 0 and updates == 0, "Scheduling does not scan or rebuild synchronously")
assert(drain() > 1)
assert(APRData.player["long-TotalSteps"] == 999 and updates == 0,
    "Only the separate commit may publish data or rebuild the step")
tickTimers()
assert(APRData.player["long-TotalSteps"] == 0 and updates == 1 and renders == 1)
assert(samples.ReputationScanBatch <= 3 and samples.ReputationRefresh == 8,
    "Diagnostics measure active batches and the commit separately, without suspended time")

-- A second event supersedes an in-flight scan; no partial or stale count leaks.
APR.event.functions.reputation(); tickTimers()
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
reached = true
APR.event.functions.reputation()
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
assert(not APR.event.reputationJob.renderFrame.scripts.OnUpdate)
tickTimers(); drain(); tickTimers()
assert(APRData.player["long-TotalSteps"] == 1200 and updates == 2)

-- Crossing a threshold refreshes the list, but unchanged state does not.
APR.questOrderList.reputationState = APR.questOrderListSupport:GetReputationStateSignature(routes.long)
local previousRenders = renders
APR.event.functions.reputation(); tickTimers(); drain(); tickTimers()
assert(updates == 3 and renders == previousRenders)

-- Changing routes or progress mid-job restarts against the live context.
APR.event.functions.reputation(); tickTimers()
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
APR.ActiveRoute = "short"
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
assert(updates == 3 and not APRData.player["short-TotalSteps"])
tickTimers(); drain(); tickTimers()
assert(updates == 4 and APRData.player["short-TotalSteps"] == 1 and renders == previousRenders)
APR.ActiveRoute = "long"
APR.event.functions.reputation(); tickTimers()
APRData.player.long = 2
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
tickTimers(); drain(); tickTimers()
assert(updates == 5)

-- Disabling APR after a scan cannot publish its deferred commit.
APR.event.functions.reputation(); tickTimers(); drain()
APR.settings.profile.enableAddon = false
tickTimers()
assert(updates == 5)
APR.settings.profile.enableAddon = true
APR.event.functions.reputation(); tickTimers()
APR.event:CleanupEvents()
assert(not APR.event.reputationJob.renderFrame.scripts.OnUpdate)
tickTimers()
assert(updates == 5, "Cleanup cancels pending reputation work")
APR.event.functions.reputation(); tickTimers(); drain()
APR.event:CleanupEvents(); tickTimers()
assert(updates == 5, "Cleanup also cancels the separate commit")

-- Parallel steps can activate without changing the current route/index.
APR._effectiveRouteStepsCache = {long = {}}
APR.event.functions.reputation(); tickTimers()
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
routes.long[#routes.long + 1] = {Note = "New parallel step"}
APR._effectiveRouteStepsCache.long = {}
APR.event.reputationJob.renderFrame.scripts.OnUpdate()
assert(updates == 5 and APRData.player["long-TotalSteps"] == 1200)
tickTimers(); drain(); tickTimers()
assert(updates == 6 and APRData.player["long-TotalSteps"] == 1201,
    "A parallel activation restarts the scan before publishing its total")
print("Reputation: 1200-step scans budgeted, atomic commit, bursts, thresholds, route/progress changes and cleanup passed")
