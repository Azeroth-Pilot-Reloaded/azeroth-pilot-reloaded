local F = dofile("tests/lua/navigation_v2/fixture.lua")
local planner, time = F.New(F.Graph())
local request = { from = "start", to = "goal", via = { "gate" } }
local job = planner:Plan(request)
time.tick = 0.6
local slice = job:Step(1000)
assert(slice.status == "running" and slice.diagnostics.operations <= 2,
    "Default 1ms slice must interrupt edge scanning")
assert(slice.diagnostics.cpuMs >= 1)
time.tick = 0
assert(F.Finish(job).estimatedSeconds == 9)

planner, time = F.New(F.Graph(), { cpuMs = 2 })
job = planner:Plan(request)
time.tick = 1
local limited = F.Finish(job, 1)
assert(limited.status == "budget_exceeded" and limited.reason == "cpu_budget")
assert(limited.diagnostics.cpuMs >= 2 and not limited.optimal)
assert(job:Step() == limited, "Exhausted jobs cannot silently restart")

planner, time = F.New(F.Graph())
job = planner:Plan(request)
time.wall = 5
local elapsed = job:Step()
assert(elapsed.status == "budget_exceeded" and elapsed.reason == "elapsed_budget")
assert(elapsed.diagnostics.operations == 0 and elapsed.objective.to == "goal")

planner, time = F.New(F.Graph())
job = planner:Plan(request)
time.cpu = 500 -- Idle time is not charged as search CPU.
assert(job:Step(1).status == "running")
assert(job:GetResult().diagnostics.cpuMs == 0)
assert(not job:Step(0))
assert(F.Finish(job).status == "complete")
time.wall = 6
job = planner:Plan(request)
time.wall = 5
local reversed = job:Step()
assert(reversed.status == "unknown" and reversed.reason == "clock_regressed")
