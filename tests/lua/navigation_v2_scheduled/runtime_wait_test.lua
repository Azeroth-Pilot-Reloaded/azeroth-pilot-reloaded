local R = dofile("tests/lua/navigation_v2_scheduled/runtime_fixture.lua")

-- Callers must be able to distinguish an estimate from a known wait/horaire.
for _, wait in ipairs({ { mode = "known", seconds = 0 }, { mode = "estimated", seconds = 20 },
    { mode = "periodic", firstDeparture = 110, periodSeconds = 30 } }) do
    local h, env = R.Host(false)
    local route = R.Route(); route.access = "available"; route.wait = wait
    assert(h:Enable({ complete = true, nodes = { route.from, route.to }, edges = {} }, { scheduled = { route } }))
    h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
    h:Plan({ from = route.from, to = route.to }, env.context)
    local action = assert(h:StartTravel(R.Finish(h.job), { objectiveID = "waiting contract" }))
    action = h:ObserveTravel(R.Proof(route, action, "origin", 1))
    assert(action.phase == "waiting")
    assert(action.wait and action.wait.mode == wait.mode, "Public travel action must retain known/estimated/periodic wait metadata")
    if wait.seconds then assert(action.wait.seconds == wait.seconds) end
    if wait.firstDeparture then assert(action.wait.firstDeparture == 110 and action.wait.periodSeconds == 30) end
    action.wait.mode = "changed externally"
    assert(h:GetTravelAction().wait.mode == wait.mode, "Action snapshots must not mutate captured wait data")
    h:Disable()
end
