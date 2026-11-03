local R = dofile("tests/lua/navigation_v2_scheduled/runtime_fixture.lua")
local h, env, ws = R.Host(false)
local route = R.Route(); route.access = "available"
local portal = { id = "landing gate", from = route.to, to = "other side", phase = "shared",
    destination = { space = "other realm", phase = "shared" }, name = "Gate to the path",
    entry = { mapID = 78, x = 0.6, y = 0.8 }, waitSeconds = 1, useSeconds = 2, loadingSeconds = 5, timeoutSeconds = 20 }
local graph = { complete = true, nodes = { route.from, route.to, "other side", "goal" }, edges = {
    { id = "last steps", from = "other side", to = "goal", seconds = 3 },
} }
assert(h:Enable(graph, { scheduled = { route }, portals = { portal },
    portalObservation = { revision = 1, phase = "shared", portals = { [portal.id] = { open = true, access = true } } } }))
h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
h:Plan({ from = route.from, to = "goal", via = { route.to, "other side" } }, env.context)
local result = R.Finish(h.job)
assert(result.status == "complete" and result.estimatedSeconds == 73)
assert(result.segments[1].kind == "scheduled" and result.segments[2].kind == "portal")
local action = h:StartTravel(result, { objectiveID = "mixed journey", resolveTarget = function(node)
    if node == "goal" then return { key = "final landing", title = "The path ends here",
        position = { mapID = 79, x = 0.3, y = 0.5 } } end
end })
local scheduledAttempt = action.attempt
for sequence, event in ipairs({ "origin", "transport_ready", "boarded", "departed", "destination", "disembarked" }) do
    action = h:ObserveTravel(R.Proof(route, action, event, sequence, sequence >= 5))
end
assert(action.kind == "approach" and action.portalId == portal.id and ws.current.mapID == 78)
local remaining = h.travel:RemainingRequest()
assert(remaining.from == route.to and remaining.to == "goal" and #remaining.via == 1 and remaining.via[1] == "other side")
assert(h:ObserveTravel({ sequence = 7, reliable = true, node = route.to, phase = "shared" }).kind == "use_portal")
action = h:BeginPortalUse()
assert(action.kind == "awaiting_transition" and action.attempt ~= scheduledAttempt)
local observation = { sequence = 8, reliable = true, node = "other side", space = "other realm", phase = "shared",
    transition = { portalId = portal.id, from = portal.from, to = portal.to, complete = true, attempt = scheduledAttempt } }
assert(h:ObserveTravel(observation).kind == "awaiting_transition", "Transport proof cannot confirm a portal")
observation.sequence, observation.transition.attempt = 9, action.attempt
assert(h:ObserveTravel(observation).kind == "walk" and ws.current.mapID == 79)
assert(h:ObserveTravel({ sequence = 10, reliable = true, node = "goal" }).kind == "complete")
assert(ws.current == nil and env.questCalls == 0)
h:Disable()
