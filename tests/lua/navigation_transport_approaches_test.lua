local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine

local function point(x, region, instanceID, z)
    return { x = x, y = 0, z = z or 0, region = region, instanceID = instanceID or 1 }
end

local function terminal(x, region, instanceID, z)
    return {
        street = point(x, region, instanceID, z),
        entrance = point(x + 10, region, instanceID, z),
        arrival = point(x + 15, region, instanceID, z),
        junction = point(x + 20, region, instanceID, z),
    }
end

local function walk(from, to, seconds)
    return { kind = "walk", from = from, to = to, seconds = seconds }
end

local function search(kind, departure, arrival, blocked, dynamic, budget)
    local start, goal = departure.street, arrival.street
    local boarding, landing = departure.entrance, arrival.arrival
    local junction = arrival.junction
    local steps = {
        [start] = { [goal] = 120, [boarding] = 5 },
        [landing] = { [junction] = 8 },
        [junction] = { [goal] = 12 },
    }
    if blocked then steps[landing][junction] = nil end
    local provider = { proveCandidatePaths = true }
    function provider:RequiresWalkingProof(from, to)
        return from.instanceID == to.instanceID
    end
    function provider:CreatePathJob(from, to)
        return {
            Step = function()
                local seconds = steps[from] and steps[from][to]
                if not seconds then return "no_path" end
                return "ready", { path = { from, to }, seconds = seconds }
            end,
        }
    end
    provider.CreatePassageJob = provider.CreatePathJob
    -- Price the ordinary approach and exit with terrain. The fixed walk
    -- supplies a reachable junction when the landing has no direct proof.
    local transport = {
        id = "synthetic-transport",
        kind = kind,
        from = dynamic and start or boarding,
        to = landing,
        seconds = 20,
        copper = kind == "taxi" and 30 or 0,
        sourceFree = dynamic,
    }
    local job = engine:CreateSearch({
        start = start,
        goal = goal,
        edges = { transport, walk(landing, junction, 8) },
        walkingProvider = provider,
        canWalk = function(from, to)
            return from == start and to == goal and from.instanceID == to.instanceID
                or from.region == to.region
        end,
        walkSpeed = 10,
        walkingSpeedCeiling = 10,
        batchTerrainWork = true,
        budget = budget or 30,
    })
    for _ = 1, 2000 do
        local status, result = job:Step(7, 1)
        if status ~= "planning" then return result, status end
    end
    error("Transport search did not settle for " .. kind)
end

local function verify(kind, departure, arrival, dynamic)
    local result, status = search(kind, departure, arrival, false, dynamic)
    local first = dynamic and 1 or 2
    assert(status == "ready" and #result.segments == first + 2, "Complete approach and exit for " .. kind)
    local segments = result.segments
    if not dynamic then
        assert(segments[1].path[1] == departure.street and segments[1].to == departure.entrance)
    end
    assert(segments[first].kind == kind and segments[first].mandatory)
    assert(segments[first].from == (dynamic and departure.street or departure.entrance))
    assert(segments[first].to == arrival.arrival)
    assert(segments[first + 1].path[1] == arrival.arrival and segments[first + 1].to == arrival.junction)
    assert(segments[first + 2].path[1] == arrival.junction and segments[first + 2].to == arrival.street)
    assert(result.totalSeconds == (dynamic and 40 or 45))

    local failed, failure = search(kind, departure, arrival, true, dynamic)
    if departure.street.instanceID == arrival.street.instanceID then
        assert(failure == "ready" and failed.totalSeconds == 120 and #failed.segments == 1)
        assert(failed.segments[1].kind == "walk", "Reject a transport with a disconnected arrival for " .. kind)
    else
        assert(failure == "no_path" and not failed, "No walking fallback between worlds for " .. kind)
    end
end

local west, east = terminal(0, "west"), terminal(200, "east")
local upstairs = terminal(0, "upstairs", 1, 80)
local island = terminal(200, "island", 2)
local cases = {
    { "boat", island },
    { "zeppelin", island },
    { "tram", east },
    { "elevator", upstairs },
    { "passage", island },
    { "portal", island },
    { "taxi", east },
}
for _, case in ipairs(cases) do
    verify(case[1], west, case[2])
    verify(case[1], case[2], west)
end
local noFare = assert(search("taxi", west, east, false, false, 29))
assert(noFare.totalSeconds == 120 and #noFare.segments == 1 and noFare.segments[1].kind == "walk")

-- Personal transports are directed actions. Their inverse is a separate
-- available action, such as a different spell or the housing return.
verify("spell", west, island, true)
verify("spell", island, west, true)
verify("item", west, island, true)
verify("item", island, west, true)
verify("housing", west, island, true)
verify("housing_return", island, west, true)
