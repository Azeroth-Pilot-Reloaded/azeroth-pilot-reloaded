-- An explicit passage joins native maps in two distinct world frames.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.maps[2274] = { mapID = 2274, mapType = 2, parentMapID = 947 }
fixture.maps[2248] = { mapID = 2248, mapType = 3, parentMapID = 2274 }
fixture.maps[2339] = { mapID = 2339, mapType = 3, parentMapID = 2248 }
fixture.maps[2214] = { mapID = 2214, mapType = 3, parentMapID = 2274 }
C_Map.GetWorldPosFromMapPos = function(map, point)
    if map ~= 2339 and map ~= 2214 then return nil end
    -- Deliberately overlap the numerical XY across worlds. Subtracting them
    -- would incorrectly make this world transition almost instantaneous.
    return map == 2339 and 2552 or 2601, { x = point.x * 100, y = point.y * 100 }
end
local data = fixture:Load({ connections = { {
    id = "fixture-world-transition", kind = "passage", bidirectional = true, costMode = "ground", seconds = 30,
    from = { space = "map", uiMapID = 2339, x = 0.5, y = 0.5 },
    to = { space = "map", uiMapID = 2214, x = 0.5, y = 0.5 },
} } })
local edges = data:BuildEdges({ walkSpeed = 10 })
assert(#edges == 2, "Both declared directions must remain available")
for _, edge in ipairs(edges) do
    assert(edge.mandatory and edge.seconds == 30 and edge.durationSource == "estimated-world-transition")
    assert(edge.from.instanceID ~= edge.to.instanceID and not data:CanWalk(edge.from, edge.to),
        "A world transition cannot be replaced with an automatic walk")
    local start = { instanceID = edge.from.instanceID, uiMapID = edge.from.uiMapID,
        x = edge.from.x - 10, y = edge.from.y }
    local goal = { instanceID = edge.to.instanceID, uiMapID = edge.to.uiMapID,
        x = edge.to.x + 30, y = edge.to.y }
    local job = data:CreateSearch({ start = start, goal = goal, edges = edges, walkSpeed = 10,
        canWalk = function(first, last) return data:CanWalk(first, last) end })
    while job:Step(32) == "planning" do end
    local result = assert(job:GetResult(), "The real native entry/arrival must connect to their respective outdoor regions")
    assert(math.abs(result.totalSeconds - 34) < 0.000001)
    local used = false
    for _, segment in ipairs(result.segments) do if segment.id == edge.id then used = segment.mandatory end end
    assert(used, "The entry and exit approach must retain the mandatory world transition")
end
print("World transitions: native maps, both directions, mandatory approaches and interworld cost passed")
