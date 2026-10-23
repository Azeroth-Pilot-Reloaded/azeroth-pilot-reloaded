local fixture = dofile("tests/lua/navigation_fixture.lua")
local completed, active, account, mapArt = {}, {}, {}, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completed[id] == true end
C_QuestLog.IsOnQuest = function(id) return active[id] == true end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function(id) return account[id] == true end
C_Map.GetMapArtID = function(id) return mapArt[id] end
local data = fixture:Load()
local definitions, count = {}, 0
for _, definition in ipairs(data:GetConnections()) do
    if definition.id:match("^additional%-") then
        assert(not definitions[definition.id], "Additional portal IDs must be unique")
        definitions[definition.id] = definition
        count = count + 1
        assert(definition.bidirectional == false, "Each direction has its own observed endpoints")
        assert(definition.source == nil, "Runtime facts do not carry external provenance")
    end
end
assert(count == 54, "All reviewed Retail portal directions must be loaded through XML")
-- Shared map coordinates cannot make an underground teleporter reachable through the floor.
local gnomeregan = definitions["additional-gnomeregan-new-tinkertown"]
assert(gnomeregan.disabled, "Retain Gnomeregan facts until its elevator approach is modelled")
local origin = data:NormalizeLocation({ space = "map", uiMapID = 27, x = 0.3135, y = 0.3803 })
local edges = data:BuildEdges({ start = origin, playerPosition = origin, walkSpeed = 7 })
for _, edge in ipairs(edges) do
    assert(edge.id ~= "retail:" .. gnomeregan.id .. ":forward",
        "The planner must not approach the teleporter through solid ground")
end
local function allowed(id, character)
    return data:CheckRequirements(definitions["additional-" .. id].requirements,
        character or { faction = "Alliance", class = "MAGE", level = 90 })
end

-- A class-hall portal must not unlock for another class or an unfinished introduction.
assert(not allowed("dreamway-moonglade", { class = "DRUID" }))
completed[40645] = true
assert(allowed("dreamway-moonglade", { class = "DRUID" }))
assert(not allowed("dreamway-moonglade", { class = "MAGE" }))
local outward = definitions["additional-dreamway-moonglade"]
local inward = definitions["additional-dreamway-moonglade-return"]
assert(outward.to.x ~= inward.from.x, "Do not use a landing pad as the reverse entrance")
assert(not definitions["additional-dreamgrove-dalaran-return"], "No Dalaran class-hall return is documented")

assert(not allowed("pet-travel-boralus-gnomeregan"))
completed[54185] = true
assert(allowed("pet-travel-boralus-gnomeregan"))
assert(not allowed("pet-travel-boralus-gnomeregan", { faction = "Horde" }))
assert(not definitions["additional-pet-travel-boralus-gnomeregan-return"])
active[83137] = true
assert(allowed("dornogal-undermine"), "The introductory quest opens the documented portal")
active[83137], account[83137] = nil, true
assert(allowed("dornogal-undermine"), "Account unlocks are checked independently")

for _, id in ipairs({ "dornogal-karesh", "karesh-dornogal" }) do
    account[84957], completed[79095], completed[79105] = true, true, true
    assert(not allowed(id), "TWW introduction and another character's progress do not unlock K'aresh")
    active[84957] = true
    assert(allowed(id), "The character's spatial-rift quest opens the portal")
    active[84957], completed[84957] = nil, true
    assert(allowed(id), "Completed K'aresh introduction retains the portal")
    completed[84957] = nil
end

-- The client's two Tirisfal maps always report their own art. They cannot
-- choose a phase-specific landing without another verified availability signal.
assert(not definitions["additional-silvermoon-bc-tirisfal-past"])
assert(not definitions["additional-silvermoon-bc-lordaeron-present"])
mapArt[62] = 67
assert(allowed("stormwind-ruttheran-past"))
assert(not allowed("azuremyst-darkshore-present"))
mapArt[62] = 1176
assert(not allowed("stormwind-ruttheran-past"))
assert(allowed("azuremyst-darkshore-present"))

for _, id in ipairs({ "silvermoon-lycaneum", "silvermoon-timeways", "dreamway-moonglade" }) do
    local definition = definitions["additional-" .. id]
    local from, to = data:NormalizeLocation(definition.from), data:NormalizeLocation(definition.to)
    assert(not data:CanWalk(from, to), "Interior portals cannot be replaced with a walk through the shared frame")
end

fixture.profile = "forever"
data = fixture:Load()
definitions, count = {}, 0
for _, definition in ipairs(data:GetConnections()) do
    if definition.id:match("^additional%-") then
        definitions[definition.id] = definition
        count = count + 1
        assert(definition.from.instanceID == 1 and definition.to.instanceID == 1)
    end
end
assert(count == 2, "Retail phase/class portals must not leak into Forever")
outward, inward = definitions["additional-darnassus-ruttheran"], definitions["additional-ruttheran-darnassus"]
assert(outward.to.x ~= inward.from.x and outward.from.x ~= inward.to.x)
assert(outward.from.z > 1300 and outward.to.z < 40, "Preserve the tree's vertical separation")
print("Additional portals: directed endpoints, class/quest/account gates, phase gates and profile isolation passed")
