local function noop() end
function LibStub() return {GetLocale = function() return {} end} end
function CreateFrame() return {RegisterEvent = noop, SetScript = noop} end
APR = {settings = {profile = {enableAddon = true}}}
function APR:NewModule() return {} end
local timers = {}
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = noop}
    timers[#timers + 1] = timer
    return timer
end}
dofile("APR-Core/core/Event.lua")
local current, renders = nil, 0
APR.Services = {GetStep = function() return current end}
function APR:UpdateStep() renders = renders + 1 end
APR.event:QueueStepRefresh()
assert(#timers == 0, "An idle empty guide needs no step refresh")
current = {_service = true}
for _ = 1, 100 do APR.event:QueueStepRefresh() end
assert(#timers == 1, "Standalone journey refreshes coalesce without an authored route")
timers[1].callback()
assert(renders == 1 and not APR.event.stepRefreshTimer)
APR.event:QueueStepRefresh()
current = nil
timers[2].callback()
assert(renders == 1 and not APR.event.stepRefreshTimer, "A cancelled journey cannot render an absent guide")
APR.ActiveRoute = "synthetic-guide"
APR.event:QueueStepRefresh()
timers[3].callback()
assert(renders == 2, "Normal guide refreshes keep their existing behavior")
print("Service refresh: no-guide scheduling, coalescing, cancellation and authored-guide compatibility passed")
