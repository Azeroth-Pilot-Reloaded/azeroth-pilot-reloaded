local F = dofile("tests/lua/navigation_v2/fixture.lua")

-- Exhaustive simple-path enumeration on the ordered-visit state space. This
-- deliberately uses neither a priority queue nor the production search helpers.
local function Oracle(graph, request)
    local best, active = math.huge, {}
    local function Visit(node, nextVisit, seconds)
        while request.via[nextVisit] == node do nextVisit = nextVisit + 1 end
        if seconds >= best then return end
        if node == request.to and nextVisit > #request.via then best = seconds; return end
        local key = node .. ":" .. nextVisit
        if active[key] then return end
        active[key] = true
        for _, edge in ipairs(graph.edges) do
            if edge.from == node and edge.access ~= "unavailable" then
                Visit(edge.to, nextVisit, seconds + edge.seconds)
            end
        end
        active[key] = nil
    end
    Visit(request.from, 1, 0)
    return best
end

local seed = 71
local function Random(limit)
    seed = (seed * 48271) % 2147483647
    return seed % limit
end

for sample = 1, 120 do
    local graph = { complete = true, nodes = { "a", "b", "c", "d" }, edges = {} }
    for _, from in ipairs(graph.nodes) do
        for _, to in ipairs(graph.nodes) do
            if from ~= to and Random(3) == 0 then
                graph.edges[#graph.edges + 1] = { id = from .. to, from = from, to = to,
                    seconds = Random(11), access = Random(5) == 0 and "unavailable" or "available" }
            end
        end
    end
    local request = { from = "a", to = "d", via = sample % 2 == 0 and { "b", "c" } or {} }
    local expected = Oracle(graph, request)
    local planner = F.New(graph)
    local result = F.Finish(planner:Plan(request), sample % 7 + 1)
    if expected == math.huge then
        assert(result.status == "no_path", "Oracle disconnection " .. sample)
    else
        assert(result.status == "complete" and result.estimatedSeconds == expected, "Oracle minimum " .. sample)
        local seconds, cursor, required = 0, request.from, 1
        while request.via[required] == cursor do required = required + 1 end
        for i, segment in ipairs(result.segments) do
            assert(segment.from == cursor and result.nodes[i] == cursor)
            cursor, seconds = segment.to, seconds + segment.seconds
            while request.via[required] == cursor do required = required + 1 end
        end
        assert(cursor == request.to and seconds == expected and required > #request.via)
    end
end
