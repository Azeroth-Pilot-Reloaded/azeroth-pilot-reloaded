local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.locale, fixture.faction, fixture.currentMap = "frFR", "Horde", 2512
fixture.maps[2512] = { mapID = 2512, mapType = 3, parentMapID = 2537, name = "Island" }
fixture.maps[2537] = { mapID = 2537, mapType = 3, parentMapID = 13 }
fixture.maps[2393].name = "Silvermoon"
fixture.maps[2541] = { mapID = 2541, mapType = 3, parentMapID = 13, name = "Arcantina" }
ASTALORS_SANCTUM = "Client sanctum name"

local completed, active, account = {}, {}, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completed[id] == true end
C_QuestLog.IsOnQuest = function(id) return active[id] == true end
local accountQueries = 0
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function(id)
    if id == 96525 then accountQueries = accountQueries + 1 end
    return account[id] == true
end
local ownsKey = false
PlayerHasToy = function(id) return id == 253629 and ownsKey end
local data = fixture:Load()
local player = data:NormalizeLocation({ space = "map", uiMapID = 2512, x = 0.5841, y = 0.4849 })
local function BuildPortals()
    local result = {}
    local edges = data:BuildEdges({ playerPosition = player })
    for _, edge in ipairs(edges) do result[edge.id] = edge end
    return result
end
local inward = "retail:coiled-isle-to-astalor:forward"
local outward = "retail:astalor-to-coiled-isle:forward"
local portals = BuildPortals()
assert(not portals[inward] and not portals[outward], "Undiscovered quest unlocks must not create usable portals")

active[96466] = true
portals = BuildPortals()
assert(portals[outward] and not portals[inward], "The first outbound quest does not unlock the later return")
active[96466], active[96525] = nil, true
portals = BuildPortals()
assert(portals[inward] and portals[outward], "The return quest opens both documented directions")
assert(portals[inward].from.x == 5949.6 and portals[inward].from.y == -12070
    and portals[inward].from.instanceID == 0, "Preserve the observed world point and resolve only its instance")
assert(portals[inward].instruction:find(ASTALORS_SANCTUM, 1, true), "Use the client interior name")
ASTALORS_SANCTUM = nil
assert(data:GetDisplayMapName(portals[inward].to) == "Silvermoon", "Missing GlobalStrings fall back to the map API")
active[96525] = nil

account[96525], accountQueries = true, 0
portals = BuildPortals()
assert(portals[inward] and portals[outward], "Account completion unlocks the portal for an alt")
assert(accountQueries == 1, "One build shares its account lookup across both directions")
account[96525] = nil
assert(portals[inward].canStart(player, true) == false, "Live checks must not reuse a prior account snapshot")
C_QuestLog.IsQuestFlaggedCompletedOnAccount = nil
assert(not BuildPortals()[inward], "An unavailable account API cannot authorize a portal")
completed[96525] = true
assert(BuildPortals()[inward], "Character completion still works without the account API")

local arcantinaExit = "retail:arcantina-silvermoon:forward"
assert(not BuildPortals()[arcantinaExit], "The Arcantina portal requires key ownership")
ownsKey = true
portals = BuildPortals()
assert(portals[arcantinaExit] and portals["retail:arcantina-silvermoon:reverse"])
assert(portals[arcantinaExit].from.uiMapID == 2541 and portals[arcantinaExit].to.uiMapID == 2393)
assert(not data:CanWalk(portals[arcantinaExit].from, portals[arcantinaExit].to),
    "Arcantina travel must use its exit, never a direct walk through a different instance")

fixture.profile = "forever"
local forever = fixture:Load()
for _, definition in ipairs(forever:GetConnections()) do
    assert(definition.id ~= "coiled-isle-to-astalor" and definition.id ~= "astalor-to-coiled-isle"
        and definition.id ~= "arcantina-silvermoon", "Midnight portals must not leak into Forever")
end
print("Midnight portals: directional unlocks, account progress, live names and owned Arcantina exit passed")
