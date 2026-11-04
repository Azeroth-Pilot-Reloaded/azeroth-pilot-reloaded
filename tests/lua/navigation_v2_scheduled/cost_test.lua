local F = assert(loadfile("tests/lua/navigation_v2_scheduled/fixture.lua"))()
local S = F.Scheduled
local route = assert(S.Compile(F.Route()))
assert(route.from == "west pier" and route.to == "east pier")
assert(route.seconds == 62)
local seconds, detail = S.Cost(route, 0, 100)
assert(seconds == 62 and detail.waitSeconds == 20 and detail.waitMode == "estimated")
assert(detail.approach == 4 and detail.boarding == 2 and detail.ride == 30)
assert(detail.loading == 3 and detail.disembark == 2 and detail.final == 1)

local source = F.Route()
source.wait = { mode = "known", seconds = 0 }
local captured = assert(S.Compile(source, { approach = 10, ride = 11 }))
source.costs.ride, source.wait.seconds, source.origin.position.x = 999, 999, 0.9
assert(captured.seconds == 29 and captured.origin.position.x == 0.2)
assert(S.Cost(captured, 0, 100) == 29)
assert(S.Compile(F.Route(), { wait = { mode = "estimated", seconds = 40 } }).seconds == 82)

-- Departures at 110, 140, 170. Previous legs + approach/boarding miss 110.
local timetable = F.Route()
timetable.wait = { mode = "periodic", firstDeparture = 110, periodSeconds = 30 }
local timed = assert(S.Compile(timetable))
assert(timed.seconds == nil, "A time-dependent edge must not advertise a static optimum")
seconds, detail = S.Cost(timed, 0, 100)
assert(seconds == 46 and detail.waitSeconds == 4 and detail.departureAt == 110)
seconds, detail = S.Cost(timed, 5, 100)
assert(seconds == 71 and detail.waitSeconds == 29 and detail.departureAt == 140)
assert(S.Cost(timed, 4, 100) == 42, "Exactly ready at departure has no extra cycle")
seconds, detail = S.Cost(timed, 0, 1)
assert(seconds == 145 and detail.waitSeconds == 103 and detail.departureAt == 110)
assert(S.Cost(timed, 0, nil) == nil)
assert(S.Cost(timed, -1, 100) == nil)
assert(S.Cost(timed, math.huge, 100) == nil)

-- Compile captures the timetable; external observations cannot mutate this request.
timetable.wait.periodSeconds = 1
assert(S.Cost(timed, 5, 100) == 71)
for elapsed = 0, 100 do
    local a = assert(S.Cost(timed, elapsed, 100)) + elapsed
    local b = assert(S.Cost(timed, elapsed + 1, 100)) + elapsed + 1
    assert(a <= b, "Periodic departures must satisfy FIFO for label-setting search")
end
