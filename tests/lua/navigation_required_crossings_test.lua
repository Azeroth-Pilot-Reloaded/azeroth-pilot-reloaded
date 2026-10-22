local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = "forever"
local data = fixture:Load()
local function ui(map, x, y)
    return assert(data:NormalizeLocation({ space = "map", uiMapID = map, x = x / 100, y = y / 100 }))
end
local source, goal = ui(1448, 60, 5), { instanceID = 1, uiMapID = 1452, x = 6900, y = -2280 }
-- The fixture normally assigns UI maps to world 0; this test puts all Kalimdor
-- locations on world 1, exactly as the recorded world-yard tunnel endpoint.
C_Map.GetWorldPosFromMapPos = function(_, position) return 1, { x = position.x * 10000, y = position.y * 10000 } end
data:InvalidatePositionCache()
source = ui(1448, 60, 5)
goal.region = data:GetPositionRegion(goal)
assert(not data:CanWalk(source, goal), "Winterspring never receives a direct mainland walking shortcut")
local edges = data:BuildEdges({ playerPosition = source })
local tunnel, lift, city, roads = {}, 0, 0, 0
for _, edge in ipairs(edges) do
    if edge.kind == "walk" then
        if edge.from.uiMapID == 1448 or edge.to.uiMapID == 1448 or edge.to.uiMapID == 1452 then tunnel[#tunnel + 1] = edge end
        if edge.from.uiMapID == 1413 and edge.to.uiMapID == 1441 then lift = lift + 1 end
        if edge.to.uiMapID == 1458 then city = city + 1 end
        if (edge.from.uiMapID == 1444 or edge.from.uiMapID == 1446) and edge.to.uiMapID == 1441 then roads = roads + 1 end
    end
end
assert(#tunnel == 8 and lift == 1 and city > 0 and roads == 2,
    "Both tunnel directions, the Great Lift, legal road alternatives and Undercity entrances are retained")
local search = APR.NavigationEngine:CreateSearch({ start = source, goal = goal, edges = tunnel,
    canWalk = function(a, b) return data:CanWalk(a, b) end })
local status, result
repeat status, result = search:Step(64) until status ~= "planning"
assert(status == "ready")
local compulsory = 0
for _, segment in ipairs(result.segments) do if segment.mandatory then compulsory = compulsory + 1 end end
assert(compulsory == 4, "A route to Winterspring must retain every recorded tunnel turn")
local needles = ui(1441, 50, 50)
assert(not data:CanWalk(ui(1413, 44, 90), needles), "Great Lift restriction is applied before nearby map acceptance")
print("Required crossings: Timbermaw turn chain, lift, road alternatives, Undercity and proximity restrictions passed")
