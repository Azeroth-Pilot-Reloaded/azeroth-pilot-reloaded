local F = dofile("tests/lua/navigation_v2/fixture.lua")
local exported, namespace = F.Load()
assert(namespace.LibAPRNavigationV2 == exported, "WoW loader namespace must export the pure core")
local legacy = { sentinel = true }
local current = "first"
APR = {
    navigation = legacy,
    IsStepContextCurrent = function(_, context) return context == current end,
}
local function Forbidden() error("Loading/using V2 must not touch live guidance or quest progress") end
local observation=dofile('tests/lua/navigation_v2_waypoint/fixture.lua').EventEnvironment()
CreateFrame, C_Timer, LibStub = observation.CreateFrame, { NewTicker = Forbidden }, Forbidden
APR.NextQuestStep, APR.UpdateMap = Forbidden, Forbidden
assert(loadfile("APR-Core/features/navigation/NavigationV2.lua"))("APR", namespace)
local host = APR.NavigationV2
assert(host.enabled == false and APR.navigation == legacy)
assert(#observation.frames==0,'Loading a disabled host creates no observation')
local result, reason = host:Plan({ from = "start", to = "goal" })
assert(not result and reason == "disabled")
local time = 0
GetTime = function() return time end
debugprofilestop = function() return 0 end
assert(host:Enable(F.Graph()))
host:ObserveWorld(false)
assert(#observation.frames==1 and observation:OnlyWorldEvents(),'Enable observes only world state, without live guidance')
local job = host:Plan({ from = "start", to = "goal", via = { "gate" } }, current)
for _ = 1, 100 do
    result = assert(host:Step(1))
    if result.status ~= "running" then break end
end
assert(result.status == "complete" and result.estimatedSeconds == 9)
assert(host:GetResult() == result and APR.navigation == legacy)
current = "second"
assert(host:GetResult().status == "stale", "A completed result must lose its former step context")

local old = host:Plan({ from = "start", to = "goal" }, current)
local newest = host:Plan({ from = "goal", to = "start" }, current)
assert(old:Step().status == "cancelled")
result = F.Finish(newest)
assert(result.status == "no_path")
assert(host:Step() == result)
host:Invalidate()
assert(host:GetResult().status == "stale")
host:Cancel()
assert(host:GetResult() == nil)
assert(select(2, host:Step()) == "no_request")
host:Disable()
assert(not host.enabled and APR.navigation == legacy)

-- Optional/missing APIs fail closed; injected clocks support nonstandard clients.
GetTime, debugprofilestop = nil, nil
assert(select(2, host:Enable(F.Graph())) == "invalid_clocks")
assert(host:Enable(F.Graph(), { clock = function() return 0 end, profileClock = function() return 0 end }))
host:ObserveWorld(false)
assert(not host:Enable(F.Graph(), false))
assert(host.enabled, "A failed replacement cannot destroy a validated host")

-- Reentrant request replacement while a clock is sampled cannot publish the old job.
host:Plan({ from = "start", to = "goal" })
local armed = false
assert(host:Enable(F.Graph(), {
    clock = function()
        if armed then
            armed = false
            host:Plan({ from = "goal", to = "start" })
        end
        return 0
    end,
    profileClock = function() return 0 end,
}))
host:Plan({ from = "start", to = "goal" })
armed = true
assert(select(2, host:Step(1)) == "superseded")
assert(host:GetResult().objective.from == "goal")
host:Disable()
