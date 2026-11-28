-- A private approach chain cannot be flattened into a straight public walk.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, size in ipairs({ 2, 4, 7 }) do
    local points, connections = {}, {}
    for index = 1, size + 1 do
        points[index] = {
            instanceID = 0,
            uiMapID = 101,
            x = index * 10,
            y = index % 2 * 10,
            noAutoconnect = index > 1 and index <= size,
        }
    end
    points[size + 1].uiMapID = 102
    for index = 1, size do
        connections[index] = {
            id = "fixture-turn-" .. index,
            kind = "passage",
            costMode = "ground",
            from = points[index],
            to = points[index + 1],
        }
    end
    local data = fixture:Load({ config = { IsolatedAreas = { [102] = "exit" } }, connections = connections })
    local start, goal = data:NormalizeLocation(points[1]), data:NormalizeLocation(points[size + 1])
    assert(not data:CanWalk(start, goal))
    local edges = data:BuildEdges({ playerPosition = start, walkSpeed = 10 })
    local search = data:CreateSearch({
        start = start,
        goal = goal,
        edges = edges,
        walkSpeed = 10,
        canWalk = function(a, b) return data:CanWalk(a, b) end,
    })
    for _ = 1, 1000 do
        if search:Step(32) ~= "planning" then break end
    end
    local result = assert(search:GetResult())
    local mandatory = 0
    for _, step in ipairs(result.segments) do
        if step.mandatory then mandatory = mandatory + 1 end
    end
    assert(mandatory == size, "Every controlled bend must remain in the itinerary")
    assert(math.abs(result.totalSeconds - size * math.sqrt(2)) < 0.000001)
end

-- Walking in a station with no terrain pack must use its explicit platform
-- passages when the exterior legs of the journey require terrain proof.
local data = fixture:Load({})
local function point(world, x, region)
    return { instanceID = world, x = x, y = 0, region = region }
end
local start, goal = point(7, 15, "outdoors"), point(7, 900, "outdoors")
local entry, boarding = point(8, 15, "station-a"), point(8, 35, "station-a")
local landing, exit = point(8, 760, "station-b"), point(8, 790, "station-b")
local edges = {
    { kind = "passage", from = start, to = entry, seconds = 2 },
    { kind = "passage", from = entry, to = boarding, seconds = 4 },
    { kind = "tram", from = boarding, to = landing, seconds = 26 },
    { kind = "passage", from = landing, to = exit, seconds = 3 },
    { kind = "passage", from = exit, to = goal, seconds = 2 },
}
local terrain = { proveCandidatePaths = true }
function terrain:RequiresWalkingProof(a, b) return a.instanceID == 7 and b.instanceID == 7 end
function terrain:CreatePathJob(a, b)
    return {
        Step = function()
            if self:RequiresWalkingProof(a, b) then return "ready", { seconds = 100, path = { a, b } } end
            return "unavailable"
        end,
    }
end
local function route(connections)
    local search = data:CreateSearch({
        start = start,
        goal = goal,
        edges = connections,
        walkingProvider = terrain,
        walkSpeed = 10,
        walkingSpeedCeiling = 10,
        batchTerrainWork = true,
    })
    for _ = 1, 200 do
        local status, result = search:Step(32)
        if status ~= "planning" then
            assert(status == "ready")
            return result
        end
    end
    error("The synthetic station route did not settle")
end
local result = route(edges)
assert(result.totalSeconds == 37 and #result.segments == 5 and result.segments[3].kind == "tram")
for _, step in ipairs(result.segments) do
    assert(step.mandatory)
end
table.remove(edges, 4)
assert(route(edges).totalSeconds == 100, "An uncovered automatic station walk cannot replace its explicit corridor")

-- A side entrance is admitted according to the original departure, even if
-- a traveller starting farther away could walk to its mouth.
local mouth = { instanceID = 0, uiMapID = 101, x = 100, y = 50 }
local landing = { instanceID = 0, uiMapID = 102, x = 120, y = 50 }
data = fixture:Load({
    config = { IsolatedAreas = { [102] = "interior" } },
    connections = {
        { id = "side-entrance", kind = "passage", from = mouth, to = landing, seconds = 5, originRadius = 20 },
    },
})
local function entranceCount(x, y, map)
    local origin = data:NormalizeLocation({ instanceID = 0, uiMapID = map or 101, x = x, y = y })
    return #data:BuildEdges({ playerPosition = origin })
end
assert(entranceCount(88, 66) == 1, "The radius includes its boundary")
assert(entranceCount(88, 67) == 0, "A distant start cannot enable the side entrance")
assert(entranceCount(100, 50, 102) == 0, "Overlapping coordinates on the other access layer do not qualify")
assert(#data:BuildEdges({}) == 0)
