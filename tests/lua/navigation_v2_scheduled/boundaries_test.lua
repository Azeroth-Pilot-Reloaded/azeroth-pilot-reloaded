local F = assert(loadfile("tests/lua/navigation_v2_scheduled/fixture.lua"))()
local S = F.Scheduled

local invalid = { function(r) r.id = nil end, function(r) r.kind = "unknown" end,
    function(r) r.from = r.to end, function(r) r.origin.floorID = nil end,
    function(r) r.destination.worldID = nil end, function(r) r.destination.phaseID = nil end,
    function(r) r.wait = nil end, function(r) r.wait.seconds = 0 end,
    function(r) r.wait.seconds = -1 end, function(r) r.wait.seconds = math.huge end,
    function(r) r.wait.mode = "non_fifo" end, function(r) r.costs.loading = nil end,
    function(r) r.costs.ride = -1 end, function(r) r.costs.ride = 0/0 end,
    function(r) r.origin.position.x = 2 end }
for index, mutate in ipairs(invalid) do
    local route = F.Route(); mutate(route)
    assert(S.Compile(route) == nil, index)
end
local route = F.Route()
route.wait = { mode = "periodic", firstDeparture = 100, periodSeconds = 0 }
assert(S.Compile(route) == nil)
assert(S.Compile(F.Route(), { ride = -1 }) == nil)
assert(S.Compile(F.Route(), { unrecognized = 1 }) == nil)
assert(S.Compile(F.Route(), { wait = false }) == nil)
assert(S.New(F.Route(), { now = 100, timeoutSeconds = 10 }) == nil)
assert(S.New(F.Route(), { objectiveID = "objective alpha", now = nil, timeoutSeconds = 10 }) == nil)
assert(S.New(F.Route(), { objectiveID = "objective alpha", now = 100, timeoutSeconds = 0 }) == nil)

local session = F.New()
local old = session:GetState()
old.target.position.x = 0.99
assert(session:GetState().target.position.x == 0.2)
assert(session:Observe(nil, 101).phase == "approach")
assert(session:Observe({ kind = "loading" }, 102).phase == "approach")
assert(session:Observe(F.Observation("origin", 1), 103).phase == "waiting")
assert(session:Observe(F.Observation("transport_ready", 1), 104).phase == "waiting")
assert(session:Observe(F.Observation("transport_ready", 0), 105).phase == "waiting")
local changed = F.Observation("transport_ready", 2)
changed.objectiveID = "objective beta"
assert(session:Observe(changed, 106).status == "stale")
assert(session:Observe(F.Observation("transport_ready", 3), 107).status == "stale")

-- Objective replacement and previous journey proofs cannot revive an old trip.
session = F.New()
assert(session:Observe(F.Observation("origin", 10), 101).phase == "waiting")
changed = F.Observation("transport_ready", 1)
changed.objectiveID = "objective beta"
assert(session:Observe(changed, 102).status == "stale")
session = F.New()
local replay = F.Observation("origin", 1)
session = F.New()
assert(session:Observe(replay, 101).phase == "approach")
local loading = F.Observation("origin", 2)
loading.loading = true
assert(session:Observe(loading, 102).phase == "approach")
local aboardOrigin = F.Observation("origin", 3)
aboardOrigin.onTransport = true
assert(session:Observe(aboardOrigin, 103).phase == "approach")

session = F.New()
assert(session:Cancel().status == "cancelled")
assert(session:Observe(F.Observation("origin", 1), 101).status == "cancelled")
session = F.New()
F.Ride(session)
local revision = session:GetState().revision
for now = 105, 299 do
    local state = session:Tick(now)
    assert(state.status == "running" and state.phase == "riding" and state.revision == revision)
    assert(state.deadline == 300)
end
assert(session:Tick(300).status == "timeout")
for _ = 1, 20 do assert(session:Tick(301).status == "timeout") end
assert(session:Observe(F.Observation("destination", 40, true), 302).status == "timeout")
session = F.New()
assert(session:Tick(99).reason == "clock_regressed")
session = F.New()
assert(session:Tick(nil).reason == "clock_unavailable")

-- Optional UiMap positions remain absent; no fake target is constructed.
route = F.Route(); route.origin.position, route.destination.position = nil, nil
session = F.New(route)
assert(session:GetState().target == nil)
assert(session:Observe(F.Observation("origin", 1), 101).phase == "waiting")
route = F.Route(); route.origin.title = "Pier 12.3, 45.6"
assert(S.Compile(route).origin.title == nil)
