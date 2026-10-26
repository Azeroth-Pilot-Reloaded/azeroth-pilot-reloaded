-- Stacked floors must stay distinct even when their map and XY are identical.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({})
local upper = { instanceID = 0, uiMapID = 2395, x = 100, y = 100, z = 100, floor = "upper" }
local lower = { instanceID = 0, uiMapID = 2395, x = 100, y = 100, z = 0, floor = "lower" }
assert(not data:CanWalk(upper, lower), "Floor identity cannot be waived by identical XY")
local edge = { id = "lift", kind = "elevator", from = upper, to = lower, seconds = 13 }
local search = data:CreateSearch({ start = upper, goal = lower, edges = { edge },
    canWalk = function(a, b) return data:CanWalk(a, b) end })
local status, result
repeat status, result = search:Step(32) until status ~= "planning"
assert(status == "ready" and result.totalSeconds == 13 and #result.segments == 1,
    "The upper node and lower node must not merge into a zero-second journey")

data.connections = {
    { id = "height", kind = "passage", from = upper, to = lower, costMode = "ground" },
    { id = "candidate", kind = "passage", from = upper, to = lower, seconds = 0, reviewStatus = "candidate" },
    { id = "disabled", kind = "passage", from = upper, to = lower, seconds = 0, reviewStatus = "disabled" },
    { id = "transition", kind = "passage", costMode = "ground", seconds = 31,
        from = upper, to = { instanceID = 1, uiMapID = 85, x = -10000, y = 25000 } },
}
local edges = data:BuildEdges({ playerPosition = upper, walkSpeed = 10 })
assert(#edges == 2 and edges[1].seconds == 10, "Ground duration includes the known vertical distance")
assert(edges[2].seconds == 31 and edges[2].durationSource == "estimated-world-transition",
    "World transitions keep their estimate instead of subtracting unrelated coordinates")
assert(edges[1].source == nil and edges[2].source == nil)

print("Vertical access: distinct Z/floors, 3D costs, world transitions and review gates passed")
