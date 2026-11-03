local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, state, env = F.Session()
for _, position in ipairs({ false, {}, { x = 0.3, y = 0.4 },
    { mapID = 42, x = -0.1, y = 0.2 }, { mapID = 42, x = 0.5, y = 1.1 },
    { mapID = 42, x = math.huge, y = 0.2 }, { mapID = 42, x = 0/0, y = 0.2 } }) do
    local target = F.Target()
    target.position = position
    assert(session:SetTarget(target) == "unlocated")
end
local action = { key = "interact", title = "Use the portal" }
assert(session:SetTarget(action) == "unlocated" and #state.creates == 0)
assert(session:SetTarget(false) == "invalid_target")
assert(session:SetTarget({}) == "invalid_target")
local edge = F.Target("edge")
edge.position = { mapID = 42, x = 0, y = 1 }
assert(session:SetTarget(edge) == "active")
assert(state.creates[1].x == 0 and state.creates[1].y == 100)
for i, text in ipairs({ "Étage 2", "Atelier 9", "Étage 2, atelier 9", "Workshop 9E", "9e étage",
    "Enter gate E2", "Workshop 9 entrance", "Key=2" }) do
    local named = F.Target("human-title-" .. i)
    named.title = text
    session:SetTarget(named)
    assert(state.current.name == text, "Human names and instructions must retain meaningful numbers")
    assert(state.current.stripCoordinates == true)
end
for i, text in ipairs({ "Gate (23.0, 67.0)", "Gate 23 67", "Gate |Hworldmap:42:2300:6700|h[23, 67]|h",
    "Gate x=0.23 y=0.67", "Gate 2.3e-1 6.7e-1", "|cffffffffGate 23;67|r",
    "Gate [23,0 / 67,0]", "Gate x:23 y:67", "Gate /way 42 23 67",
    "|Hworldmap:42:2300:6700|h[Gate]|h", "23, 67", "-23.0; +67.0", "0.23 0.67" }) do
    local t = F.Target("label-" .. i)
    t.title, t.stripCoordinates = text, false
    session:SetTarget(t)
    assert(state.current.name == "Map pin", "Coordinate presentations must use the human fallback title")
    assert(state.current.stripCoordinates == true)
end
local t = F.Target("empty")
t.title = "23, 67"
session:SetTarget(t)
assert(state.current.name == "Map pin")
-- Output failures return stable technical reasons, never raw provider errors.
session, state, env = F.Session()
env.api.NewUserNavigation = function() error("map=42 x=23 y=67") end
assert(session:SetTarget(F.Target()) == "provider_error")
local library = F.Load()
assert(not library.NewWaypointSession(false))
assert(not library.NewWaypointSession({ getProvider = false }))
