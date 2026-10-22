local fixture = dofile("tests/lua/navigation_fixture.lua")

local function ConnectionsByID(data)
    local result = {}
    for _, connection in ipairs(data:GetConnections()) do result[connection.id] = connection end
    return result
end

-- Old Challenge Mode rewards remain usable travel options when the character knows them.
fixture.spells = { [131229] = true, [131231] = true }
local retail = fixture:Load()
local definitions = ConnectionsByID(retail)
local monastery = assert(definitions["spell-131229-scarlet-monastery"])
local halls = assert(definitions["spell-131231-scarlet-halls"])
assert(monastery.to.uiMapID == 18 and halls.to.uiMapID == 18)
assert(monastery.cooldownGroup == "dungeon-teleport" and halls.cooldownGroup == "dungeon-teleport")
local edges = retail:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 84, x = 100, y = 200 } })
local available = {}
for _, edge in ipairs(edges) do available[edge.id] = edge end
assert(available["retail:spell-131229-scarlet-monastery:forward"])
assert(available["retail:spell-131231-scarlet-halls:forward"])
fixture.spells = {}
edges = retail:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 84, x = 100, y = 200 } })
for _, edge in ipairs(edges) do
    assert(edge.id ~= "retail:spell-131229-scarlet-monastery:forward" and edge.id ~= "retail:spell-131231-scarlet-halls:forward")
end

-- Current and historical rewards share the same budgeted catalogue path. The
-- current season is deliberately absent from the fixture: only known spells matter.
local seasonTwo = {
    [1286801] = { id = "spell-1286801-blinding-vale", mapID = 2413 },
    [1286804] = { id = "spell-1286804-voidscar-arena", mapID = 2405 },
    [1286807] = { id = "spell-1286807-den-of-nalorakk", mapID = 2437 },
    [1286809] = { id = "spell-1286809-murder-row", mapID = 2393 },
    [1286812] = { id = "spell-1286812-altar-of-fangs", mapID = 2509 },
    [1286828] = { id = "spell-1286828-temple-of-sethraliss", mapID = 864 },
    [1286831] = { id = "spell-1286831-kings-rest", mapID = 862 },
}
local allSpells = {}
for _, connection in pairs(definitions) do
    for _, action in ipairs(connection.actions or {}) do
        if action.type == "spell" then allSpells[action.id] = true end
    end
end
assert(allSpells[393273] and not allSpells[393272], "Retain the confirmed Algeth'ar reward ID")
assert(allSpells[1254563] and not allSpells[1254553], "The older Nexus correction was itself superseded")
for spellID, expected in pairs(seasonTwo) do
    local connection = assert(definitions[expected.id])
    assert(connection.to.uiMapID == expected.mapID and connection.cooldownGroup == "dungeon-teleport")
    assert(connection.actions[1].id == spellID)
    fixture.spells[spellID] = true
end
edges = retail:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 84, x = 100, y = 200 } })
available = {}
for _, edge in ipairs(edges) do available[edge.id] = edge end
for _, expected in pairs(seasonTwo) do
    assert(available["retail:" .. expected.id .. ":forward"], "Every known Season 2 reward must enter the graph")
end

fixture.spells = { [1259190] = true, [1259194] = true }
fixture.inGroup = true
edges = retail:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 84, x = 100, y = 200 } })
local silvermoon
for _, edge in ipairs(edges) do
    if edge.id == "retail:spell-1259190-to-silvermoon-city:forward" then silvermoon = edge end
end
assert(silvermoon and silvermoon.action.data == 1259194, "Use the known Silvermoon portal for a group")
fixture.inGroup = false
fixture.spells = {}

fixture.profile = "forever"
local forever = fixture:Load()
definitions = ConnectionsByID(forever)
assert(not definitions["spell-131229-scarlet-monastery"], "Retail rewards must not leak into Forever")
local ferry = assert(definitions["boat-long-wash-ruttheran"])
assert(ferry.bidirectional and ferry.seconds == 208 and ferry.requirements.faction == "Alliance")
assert(ferry.from.uiMapID == 1439 and ferry.from.x == 0.3238 and ferry.to.x == 0.5406)
local goblinBoat = assert(definitions["boat-forever-transport-46"])
assert(goblinBoat.from.uiMapID == 1434 and goblinBoat.from.x == 0.2595 and goblinBoat.from.y == 0.7316)
assert(goblinBoat.to.uiMapID == 1413 and goblinBoat.to.x == 0.6362 and goblinBoat.to.y == 0.3863)
local feathermoon = assert(definitions["boat-forever-transport-4012"])
assert(feathermoon.from.x == 0.3101 and feathermoon.to.x == 0.4313)
local powderfuse = assert(definitions["boat-forever-transport-4008"])
assert(powderfuse.from.x == 0.6858 and powderfuse.to.x == 0.8060)

-- An arrival point is not the reverse trigger: each loading screen is directed.
local stormwind = assert(definitions["passage-tram-stormwind-entry-2173"])
local ironforge = assert(definitions["passage-tram-ironforge-entry-2175"])
assert(stormwind.from.instanceID == 0 and stormwind.to.instanceID == 369 and not stormwind.bidirectional)
assert(ironforge.from.instanceID == 0 and ironforge.to.instanceID == 369 and not ironforge.bidirectional)
assert(stormwind.from.x == -8346.46 and stormwind.to.y == 2490.98)
assert(ironforge.from.x == -4840.26 and ironforge.to.y == 10.393)
local stormwindExit = assert(definitions["passage-deeprun-tram-to-stormwind"])
local ironforgeExit = assert(definitions["passage-deeprun-tram-to-ironforge"])
assert(stormwindExit.from.instanceID == 369 and stormwindExit.to.instanceID == 0)
assert(ironforgeExit.from.instanceID == 369 and ironforgeExit.to.instanceID == 0)
assert(stormwindExit.from.x == 80.163 and ironforgeExit.from.x == 76.027)
assert(stormwindExit.to.x ~= stormwind.from.x, "Do not turn the outside landing into an entry trigger")

fixture.faction = "Horde"
edges = forever:BuildEdges({ playerPosition = { instanceID = 0, uiMapID = 1420, x = 100, y = 200 } })
for _, edge in ipairs(edges) do
    assert(not edge.id:find("boat-long-wash-ruttheran", 1, true))
    assert(not edge.id:find("passage-tram-stormwind-entry-2173", 1, true))
    assert(not edge.id:find("passage-tram-ironforge-entry-2175", 1, true))
end
print("Navigation transport catalogue: missing rewards, distinct docks and directed tram entrances passed")
