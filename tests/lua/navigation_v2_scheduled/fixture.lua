local Fixture = {}
local namespace = {}
local root = "APR-Core/libs/LibAPRNavigation-2.0/"
for _, file in ipairs({ "Graph.lua", "Waypoints/Target.lua", "Transports/Scheduled.lua" }) do
    assert(loadfile(root .. file))("synthetic", namespace)
end
Fixture.Scheduled, Fixture.namespace = namespace.NavigationV2Scheduled, namespace

function Fixture.Route(kind)
    return {
        id = "river crossing", kind = kind or "boat", from = "west pier", to = "east pier",
        origin = { id = "west berth", worldID = 7, floorID = 0, phaseID = "shared",
            title = "Departure pier", position = { mapID = 77, x = 0.2, y = 0.4 } },
        destination = { id = "east berth", worldID = 8, floorID = 1, phaseID = "shared",
            title = "Arrival pier", position = { mapID = 78, x = 0.6, y = 0.8 } },
        costs = { approach = 4, boarding = 2, ride = 30, loading = 3, disembark = 2, final = 1 },
        wait = { mode = "estimated", seconds = 20 },
    }
end

function Fixture.New(route, options)
    local session, reason = Fixture.Scheduled.New(route or Fixture.Route(), options or {
        objectiveID = "objective alpha", now = 100, timeoutSeconds = 200,
    })
    assert(session, reason)
    Fixture.currentAttempt = session:GetState().attempt
    return session
end

function Fixture.Observation(kind, sequence, destination)
    local stop = destination and Fixture.Route().destination or Fixture.Route().origin
    return { kind = kind, sequence = sequence, objectiveID = "objective alpha", routeID = "river crossing",
        confirmed = true, stopID = stop.id, worldID = stop.worldID, floorID = stop.floorID,
        phaseID = stop.phaseID, attempt = Fixture.currentAttempt,
        onTransport = kind == "boarded" or kind == "departed" or kind == "destination" }
end

function Fixture.Ride(session)
    local events = { "origin", "transport_ready", "boarded", "departed" }
    for sequence, kind in ipairs(events) do
        assert(session:Observe(Fixture.Observation(kind, sequence), 100 + sequence).status == "running")
    end
    assert(session:GetState().phase == "riding")
end

return Fixture
