-- A private approach chain cannot be flattened into a straight public walk.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, size in ipairs({ 2, 4, 7 }) do
    local points, connections = {}, {}
    for index = 1, size + 1 do
        points[index] = { instanceID = 0, uiMapID = 101, x = index * 10, y = index % 2 * 10,
            noAutoconnect = index > 1 and index <= size }
    end
    points[size + 1].uiMapID = 102
    for index = 1, size do
        connections[index] = { id = "fixture-turn-" .. index, kind = "passage", costMode = "ground",
            from = points[index], to = points[index + 1] }
    end
    local data = fixture:Load({ config = { IsolatedAreas = { [102] = "exit" } }, connections = connections })
    local start, goal = data:NormalizeLocation(points[1]), data:NormalizeLocation(points[size + 1])
    assert(not data:CanWalk(start, goal))
    local edges = data:BuildEdges({ playerPosition = start, walkSpeed = 10 })
    local search = data:CreateSearch({ start = start, goal = goal, edges = edges, walkSpeed = 10,
        canWalk = function(a, b) return data:CanWalk(a, b) end })
    for _ = 1, 1000 do if search:Step(32) ~= "planning" then break end end
    local result = assert(search:GetResult())
    local mandatory = 0
    for _, step in ipairs(result.segments) do if step.mandatory then mandatory = mandatory + 1 end end
    assert(mandatory == size, "Every controlled bend must remain in the itinerary")
    assert(math.abs(result.totalSeconds - size * math.sqrt(2)) < 0.000001)
end
