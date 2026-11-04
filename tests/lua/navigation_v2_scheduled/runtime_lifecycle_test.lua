local R = dofile("tests/lua/navigation_v2_scheduled/runtime_fixture.lua")
local h, env, ws = R.Host(false)
local route = R.Route(); route.access = "available"
local graph = { complete = true, nodes = { route.from, route.to }, edges = {} }
assert(h:Enable(graph, { scheduled = { route } }))
h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
local function Start()
    h:Plan({ from = route.from, to = route.to }, env.context)
    local result = R.Finish(h.job)
    return assert(h:StartTravel(result, { objectiveID = "bounded trip", scheduledTimeoutSeconds = 10 })), result
end
local action, result = Start()
local timer, job, generation = env.timers[1], h.job, h.generation
env.now = 110; timer.callback()
assert(h:GetTravelAction().kind == "failed" and h:GetTravelAction().reason == "transport_deadline")
for _ = 1, 30 do
    assert(h:GetTravelAction().kind == "failed")
    assert(h:ObserveTravel(R.Proof(route, action, "origin", 1)).kind == "failed")
end
assert(#env.timers == 1 and h.job == job and h.generation == generation and ws.current == nil)

action, result = Start()
local cancelled = env.timers[#env.timers]
local oldAttempt = action.attempt
assert(h:Cancel())
assert(h:GetTravelAction() == nil and cancelled.cancelled and ws.current == nil)
cancelled.callback(); assert(h:GetTravelAction() == nil)
action, result = Start()
local stale = R.Proof(route, action, "origin", 1); stale.attempt = oldAttempt
assert(h:ObserveTravel(stale).phase == "approach")
cancelled = env.timers[#env.timers]
local revision = h.planner.revision
assert(h:SetScheduled({ route }, { [route.id] = { ride = 1 } }))
assert(h.planner.revision == revision + 1 and h:GetTravelAction() == nil and cancelled.cancelled)
assert(select(2, h:StartTravel(result)) == "stale_result")

action, result = Start()
cancelled = env.timers[#env.timers]
h:Plan({ from = route.to, to = route.from }, env.context)
assert(h:GetTravelAction() == nil and cancelled.cancelled)
cancelled.callback(); assert(h:GetTravelAction() == nil)
assert(select(2, h:StartTravel(result)) == "stale_result")
action = Start()
cancelled = env.timers[#env.timers]
env.context = "different APR step"
assert(select(2, h:GetTravelAction()) == "stale_context")
assert(cancelled.cancelled and ws.current == nil)
cancelled.callback(); assert(h:GetTravelAction() == nil)
h:Disable()

-- No real position means no synthetic marker or resolver fallback.
h, env, ws = R.Host(false)
route.origin.position, route.destination.position = nil, nil
assert(h:Enable(graph, { scheduled = { route } }))
h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
h:Plan({ from = route.from, to = route.to }, env.context)
action = h:StartTravel(R.Finish(h.job), { resolveTarget = function() error("No fake point for transport") end })
assert(action.kind == "scheduled" and action.target == nil and #ws.creates == 0)
assert(h:ObserveTravel(nil).phase == "approach" and #ws.creates == 0)
h:Disable()

-- Absent client/provider APIs cannot prove arrival or crash the transport path.
h, env, ws = R.Host(false)
WaypointUIAPI, AzerothWaypointNS, C_Map, CreateFrame, C_Timer = nil, nil, nil, nil, nil
assert(h:Enable(graph, { scheduled = { route } }))
h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
h:Plan({ from = route.from, to = route.to }, env.context)
action = h:StartTravel(R.Finish(h.job), { scheduledTimeoutSeconds = 10 })
assert(action.phase == "approach" and h:ObserveTravel(nil).phase == "approach")
env.now = 110
assert(h:GetTravelAction().kind == "failed" and h:GetTravelAction().reason == "transport_deadline")
assert(env.questCalls == 0)
h:Disable()
