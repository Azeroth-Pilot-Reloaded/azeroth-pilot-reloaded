local R = dofile("tests/lua/navigation_v2_scheduled/runtime_fixture.lua")

for _, useAWP in ipairs({ false, true }) do
    local h, env, ws, awp = R.Host(useAWP)
    local route = R.Route(); route.access = "available"
    route.origin.title = "Pier 12.3, 45.6"
    route.destination.title = "Arrival landing"
    local graph = { complete = true, nodes = { route.from, route.to }, edges = {} }
    assert(h:Enable(graph, { scheduled = { route } }))
    h:ObserveWorld(false) -- explicit synthetic ready-world evidence after fresh activation
    h:Plan({ from = route.from, to = route.to }, env.context)
    local result = R.Finish(h.job)
    assert(result.estimatedSeconds == 62 and #ws.creates == 0 and #awp.schedules == 0 and #env.timers == 0)
    local action = assert(h:StartTravel(result, { objectiveID = "cross river", scheduledTimeoutSeconds = 25 }))
    assert(action.kind == "scheduled" and action.phase == "approach" and action.attempt)
    assert(h.waypoint and h:GetWaypointStatus() == "active", "The existing library session owns publication")
    local function Output(map, x, y)
        if useAWP then
            awp:Flush()
            assert(awp.record and #ws.creates == 0)
            local target = awp.record.target
            assert(target.mapID == map and target.x == x and target.y == y)
            assert(target.title and not target.title:find("12.3", 1, true))
        else
            assert(ws.current and ws.current.mapID == map and ws.current.x == x and ws.current.y == y)
            local options = ws.creates[#ws.creates]
            assert(options.stripCoordinates == true and options.name and not options.name:find("12.3", 1, true))
        end
    end
    local function Cleared()
        awp:Flush()
        assert(not awp.record and not ws.current)
    end
    Output(77, 0.2, 0.4)
    local attempt, deadline = action.attempt, action.deadline
    local job, generation, revision = h.job, h.generation, h.planner.revision
    local operations = result.diagnostics.operations
    local count, schedules = #ws.creates, #awp.schedules
    for _ = 1, 30 do
        action = h:GetTravelAction()
        assert(action.attempt == attempt and action.deadline == deadline)
    end
    assert(#env.timers == 1 and #ws.creates == count and #awp.schedules == schedules)
    assert(h.job == job and h.generation == generation and h.planner.revision == revision)
    assert(result.diagnostics.operations == operations)
    assert(h:SetScheduled({ route }) == false and h:GetTravelAction().attempt == attempt)

    assert(h:ObserveTravel(nil).phase == "approach")
    local proof = R.Proof(route, action, "origin", 1)
    proof.floorID = 999
    assert(h:ObserveTravel(proof).phase == "approach")
    proof = R.Proof(route, action, "origin", 2); proof.loading = true
    assert(h:ObserveTravel(proof).phase == "approach")
    proof.loading = false
    assert(h:ObserveTravel(proof).phase == "waiting"); Cleared()
    proof = R.Proof(route, action, "transport_ready", 3); proof.attempt = {}
    assert(h:ObserveTravel(proof).phase == "waiting")
    proof.attempt = attempt
    assert(h:ObserveTravel(proof).phase == "boarding"); Output(77, 0.2, 0.4)
    assert(h:ObserveTravel(R.Proof(route, action, "boarded", 4)).phase == "riding"); Cleared()
    assert(h:ObserveTravel(R.Proof(route, action, "destination", 5, true)).phase == "riding")
    assert(h:ObserveTravel(R.Proof(route, action, "departed", 6)).phase == "riding")
    proof = R.Proof(route, action, "destination", 7, true); proof.worldID = 999
    assert(h:ObserveTravel(proof).phase == "riding")
    assert(h:ObserveTravel(R.Proof(route, action, "destination", 8, true)).phase == "disembarking")
    Output(78, 0.6, 0.8)
    proof = R.Proof(route, action, "disembarked", 9, true); proof.onTransport = true
    assert(h:ObserveTravel(proof).phase == "disembarking")
    assert(h:ObserveTravel(R.Proof(route, action, "disembarked", 10, true)).kind == "complete")
    Cleared()
    assert(#env.timers == 1 and env.timers[1].cancelled and env.questCalls == 0)
    assert(h:ObserveTravel(proof).kind == "complete" and h.generation == generation)
    h:Disable()
    assert(APR.navigation.legacy)
end
