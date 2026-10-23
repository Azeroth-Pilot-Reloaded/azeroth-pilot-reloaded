-- Reproduce the reported world positions without fitting client map projections.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2576
fixture.spells[3567] = true
fixture.player = { x = -253.4, y = -412.7, instanceID = 2694 }
fixture.maps[2576] = { mapID = 2576, mapType = 5, parentMapID = 2413 }
fixture.maps[85] = { mapID = 85, mapType = 3, parentMapID = 12 }
C_Map.GetMapPosFromWorldPos = function(instance)
    return instance == 2694 and 2413 or instance == 1 and 85 or 2395, {}
end
C_Spell.GetSpellInfo = function() return { name = "Teleport: Orgrimmar", castTime = 8808 } end
local data = fixture:Load()
local start = data:NormalizeLocation(fixture.player)
local goal = data:NormalizeLocation({ x = 8016.7, y = -4577.6, instanceID = 0, uiMapID = 2395 })
local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
local portal, teleport
for _, edge in ipairs(edges) do
    if edge.id == "retail:portal-harandar-to-silvermoon-city:forward" then portal = edge end
    if edge.id == "retail:spell-3567-teleport-orgrimmar:forward" then teleport = edge end
end
assert(portal and teleport, "The real catalogue must offer both the Harandar portal and learned teleport")
assert(portal.seconds == 5 and portal.durationSource == "profile-estimated-loading",
    "Harandar's inherited weight of 30 must not be treated as a measured duration")
assert(teleport.seconds == 13.808 and teleport.sourceFree and teleport.action.data == 3567)
assert(not portal.action and not portal.sourceFree and data:CanWalk(start, portal.from),
    "The Den child map can reach the physical portal without a personal spell action")

-- Give Orgrimmar an unrealistically favourable onward portal: no approach and
-- no final walk. Beating this lower bound also beats the real two-transport detour.
local onward = { id = "optimistic-org-portal", kind = "portal", from = teleport.to, to = goal,
    seconds = data.config.actionLoadingSeconds, copper = 0 }
local function Route(position)
    local search = data:CreateSearch({ start = position, goal = goal,
        edges = { portal, teleport, onward }, resources = metadata.resources, walkSpeed = 60,
        canWalk = function(a, b) return data:CanWalk(a, b) end, walkingIsTransitive = true })
    while search:Step(32) == "planning" do end
    assert(search.status == "ready")
    return search:GetResult()
end
local result = Route(start)
assert(result.totalSeconds < teleport.seconds + onward.seconds,
    "The nearby direct portal beats even an optimistic Orgrimmar detour at the reported speed")
local usedPortal = false
for _, segment in ipairs(result.segments) do
    assert(not segment.action, "The selected route must not ask for Teleport: Orgrimmar")
    if segment.id == portal.id then usedPortal = true end
end
assert(usedPortal, "The route must include Harandar's real directed return portal")

-- This is a duration correction, not a forced portal preference. Farther away,
-- a genuinely faster personal teleport must remain eligible to win.
local distant = data:NormalizeLocation({ x = start.x - 3000, y = start.y, instanceID = 2694, uiMapID = 2576 })
result = Route(distant)
assert(result.segments[1].action and result.segments[1].action.data == 3567,
    "Personal travel still wins when its complete route is faster")
print("Harandar: nearby portal beats the Orgrimmar detour; faster remote personal travel remains available")
