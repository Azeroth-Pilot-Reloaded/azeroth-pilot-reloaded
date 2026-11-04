local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local environment = getfenv(engine.CreateSearch)
local originalPairs, tracked, copies = environment.pairs, {}, 0
environment.pairs = function(value)
    if tracked[value] then copies = copies + 1 end
    return originalPairs(value)
end
local function point(world, x)
    return { instanceID = world, x = x or 0, y = 0, noAutoconnect = true }
end
local function edge(id, from, to, seconds)
    local value = { id = id, from = from, to = to, seconds = seconds, kind = "portal",
        instruction = "Synthetic transport " .. id, verifiedBuild = "fixture" }
    tracked[value] = true
    return value
end
local function finish(search)
    local work = 0
    while search.status == "planning" do
        local before = copies
        search:Step(1)
        assert(copies - before <= 1, "One assembly operation cannot materialize a whole itinerary")
        work = work + 1
        assert(work < 20000)
    end
    return search:GetResult()
end

local start, goal = point(0), point(1001)
local edges = {}
for i = 1, 500 do edges[i] = edge("unused-" .. i, start, point(i), 1) end
edges[501] = edge("winner", start, goal, 2)
local request = { start = start, goal = goal, edges = edges }
local search = engine:CreateSearch(request)
assert(copies == 0)
while search.ingestedEdges < #edges do search:Step(1) end
assert(copies == 0, "Reading a catalogue must not copy metadata for unused transports")
local result = finish(search)
assert(result.totalSeconds == 2 and #result.segments == 1 and result.segments[1].id == "winner")
assert(copies == 1, "Only the selected transport needs an independently writable segment")
local selected = result.segments[1]
assert(selected ~= edges[501] and selected.mandatory and selected.verifiedBuild == "fixture")
selected.instruction, selected.seconds = "Consumer label", 100
assert(edges[501].instruction == "Synthetic transport winner" and edges[501].seconds == 2,
    "Result edits cannot modify the shared catalogue")
print("Search materialization: 501 candidate transports, 1 selected transport copied")

copies = 0
search = engine:CreateSearch(request)
search:Step(20)
search:Cancel()
assert(search:Step(100) == "cancelled" and not search:GetResult() and copies == 0,
    "An abandoned search never materializes its speculative transports")

local intermediate = point(2)
local crossing = edge("crossing", start, intermediate, 1)
local action = edge("restricted-action", start, goal, 3)
action.sourceFree, action.action = true, { type = "spell", data = 71 }
action.canStart = function(position) return position.instanceID == 2 end
copies = 0
search = engine:CreateSearch({ start = start, goal = goal, edges = { crossing, action } })
result = finish(search)
assert(result.totalSeconds == 4 and #result.segments == 2 and copies == 2)
assert(result.segments[2].from == intermediate and result.segments[2].to == goal
    and result.segments[2].action.data == 71 and result.segments[2].mandatory,
    "A selected personal action uses its actual departure after a prior transport")
assert(action.from == start and action.to == goal, "Rebinding a result leaves the input action intact")

local a = { x = 0, y = 0, instanceID = 1, region = "outside" }
local b = { x = 14, y = 0, instanceID = 1, region = "outside" }
result = finish(engine:CreateSearch({ start = a, goal = b, walkSpeed = 7 }))
assert(result.totalSeconds == 2 and #result.segments == 1 and result.segments[1].kind == "walk"
    and result.segments[1].seconds == 2 and result.segments[1].copper == 0
    and not result.segments[1].mandatory and result.segments[1].from == a and result.segments[1].to == b,
    "Deferred automatic walks keep their duration, endpoints and optional guidance contract")
environment.pairs = originalPairs
