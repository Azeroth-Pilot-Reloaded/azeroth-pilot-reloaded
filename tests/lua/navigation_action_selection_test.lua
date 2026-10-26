-- Real adapter observations select actions from a small independent catalog.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile, fixture.currentMap = "forever", 101
fixture.spells, fixture.items = { [10] = true, [11] = true }, { [20] = 1, [21] = 1, [40] = 1, [41] = 2 }
local function point(world, map, x) return { instanceID = world, uiMapID = map, x = x, y = 0 } end
local catalog = { config = { actionLoadingSeconds = 5, IsolatedAreas = { [103] = "interior" } }, connections = {
    { id = "learned-destination", kind = "spell", from = { dynamic = "player" }, to = point(0, 102, 100),
        actions = { { type = "spell", id = 10, reagentID = 20, groupSpellID = 11, groupReagentID = 21 } } },
    { id = "owned-toy", kind = "item", from = { dynamic = "player" }, to = point(0, 103, 0),
        actions = { { type = "item", id = 30 } } },
    { id = "first-consumable", kind = "item", from = { dynamic = "player" }, to = point(0, 102, 100), cooldownGroup = "shared",
        actions = { { type = "item", id = 40, consumable = true } } },
    { id = "second-consumable", kind = "item", from = { dynamic = "player" }, to = point(0, 102, 200), cooldownGroup = "shared",
        actions = { { type = "item", id = 41, consumable = true } } },
    { id = "ferry", kind = "boat", from = point(0, 101, 0), to = point(1, 104, 100), seconds = 25, bidirectional = true },
} }
local owned, toyUsable, cooling = true, true, false
function PlayerHasToy(id) return id == 30 and owned end
C_ToyBox = { IsToyUsable = function() return toyUsable end }
C_Item.IsUsableItem = function() return true end
C_Item.GetItemCooldown = function() return cooling and 1 or 0, cooling and 60 or 0, 1 end
C_Spell.GetSpellInfo = function(id) if fixture.spells[id] then return { name = "Fixture spell " .. id } end end
C_SpellBook = { IsSpellKnown = function(id) return fixture.spells[id] == true end }
local data = fixture:Load(catalog)
dofile("APR-Core/utils/PlayerUtils.lua")
data.env.getActionCastSeconds = function() return 2 end
local player = point(0, 101, 0)
local function build()
    local edges, meta = data:BuildEdges({ playerPosition = player, inGroup = fixture.inGroup })
    local indexed = {}
    for _, edge in ipairs(edges) do indexed[edge.id] = edge end
    return indexed, meta
end
local key = "forever:learned-destination:forward"
local edges, metadata = build()
assert(edges[key].action.data == 10 and edges[key].resources["item:20"] == 1 and edges[key].seconds == 7)
assert(edges[key].sourceFree and edges[key].from.x == player.x and edges[key].from.uiMapID == player.uiMapID)
fixture.inGroup = true
edges = build()
assert(edges[key].action.data == 11 and edges[key].resources["item:21"] == 1)
fixture.inGroup, fixture.spells[10] = false, nil
assert(not build()[key], "A group-only spell cannot replace an unlearned solo action")
fixture.inGroup = true
assert(build()[key].action.data == 11)
fixture.items[21] = 0
assert(not build()[key], "A learned action cannot spend absent reagents")
edges, metadata = build()
for _, item in ipairs({ 40, 41 }) do
    local id = item == 40 and "first-consumable" or "second-consumable"
    local edge = assert(edges["forever:" .. id .. ":forward"])
    assert(edge.resources["item:" .. item] == 1 and metadata.resources["item:" .. item] == fixture.items[item])
    assert(edge.resources["cooldown:shared"] == 1 and metadata.resources["cooldown:shared"] == 1)
end
local forward, reverse = edges["forever:ferry:forward"], edges["forever:ferry:reverse"]
assert(forward.from.instanceID == reverse.to.instanceID and forward.to.instanceID == reverse.from.instanceID)
assert(forward.seconds == 25 and reverse.seconds == 25 and not data:CanWalk(forward.from, forward.to))
assert(edges["forever:owned-toy:forward"], "Owned usable toys do not require a bag item")
toyUsable = nil
edges, metadata = build()
assert(not edges["forever:owned-toy:forward"] and metadata.waitingData)
toyUsable, cooling = true, true
edges = build()
assert(not edges["forever:owned-toy:forward"])
cooling, owned = false, false
assert(not build()["forever:owned-toy:forward"])
local _, mismatch = data:BuildEdges({ profile = "retail", playerPosition = player })
assert(mismatch.waitingData and mismatch.reason == "profile_mismatch")
