-- Diagnostic contexts must not keep completed/cancelled workers alive in Lua 5.1.
APR, APRData = {}, {}
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/core/PerformanceScopes.lua")
APR:SetPerformanceCapture(true)
local D = APRInstrumentation
local observed = setmetatable({}, { __mode = "v" })
local worker = D.Wrap("SyntheticRetiredWorker", function() D.Yield("waiting") end)
local function retireWorkers()
    for index = 1, 200 do
        local thread = coroutine.create(worker)
        observed[index] = thread
        local ok, value = D.Resume(thread)
        assert(ok and value == "waiting")
        -- Half finish; the other half represent cancelled jobs with no owner.
        if index % 2 == 0 then assert(D.Resume(thread)) end
    end
end
retireWorkers()
collectgarbage("collect")
collectgarbage("collect")
assert(next(observed) == nil,
    "Neither completed nor abandoned diagnostic coroutine contexts may retain their workers")
assert(APRData.PerformanceLog.summary.SyntheticRetiredWorker.count == 100,
    "Completed workers still contribute their timing records")

local live = coroutine.create(D.Wrap("SyntheticLiveWorker", function()
    D.Yield("paused")
    return "finished", 7
end))
local liveReference = setmetatable({ live }, { __mode = "v" })
local ok, value = D.Resume(live)
assert(ok and value == "paused")
collectgarbage("collect")
assert(liveReference[1] == live, "A caller-owned suspended coroutine remains alive")
local number
ok, value, number = D.Resume(live)
assert(ok and value == "finished" and number == 7 and D.CurrentName() == nil)
assert(APRData.PerformanceLog.summary.SyntheticLiveWorker.count == 1)
live = nil
collectgarbage("collect")
collectgarbage("collect")
assert(liveReference[1] == nil, "A finished worker is collectible after its caller releases it")
APR:SetPerformanceCapture(false)
print("Diagnostic coroutine lifetime: 200 retired workers released, completed timings retained and live suspension/resume preserved")
