local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.locale, fixture.bindName = "frFR", "Area 24"
local data = fixture:Load()
assert(data:GetProfile().name == "retail" and data:GetConfig().IsolatedAreas[2413] == "area:2413")
local city = { instanceID = 0, x = 100, y = 200, uiMapID = 2393 }
local forest = { instanceID = 0, x = 101, y = 201, uiMapID = 2395 }
local harandar = { instanceID = 0, x = 102, y = 202, uiMapID = 2413 }
assert(data:CanWalk(city, forest) and data:CanWalk(forest, city))
assert(not data:CanWalk(forest, harandar), "Harandar remains isolated despite hierarchy and proximity")
assert(data:GetBindPosition() and data:GetBindLocationMapID())
local edges, metadata = data:BuildEdges({ playerPosition = forest })
local hasHarandar = false
for _, edge in ipairs(edges) do
    assert(edge.kind ~= "flight", "Only the taxi provider supplies flight routing")
    if edge.to.instanceID == 2694 then hasHarandar = true; assert(edge.to.uiMapID == 2413) end
end
assert(hasHarandar and metadata.profile == "retail")
data:UpdateHousingExitLocation()
assert(APRNavigationCharacterSettings.housingExitLocation and not _G.FarstriderLibData)

fixture.profile, fixture.locale = "forever", "enUS"
fixture.spells, fixture.items = { [3561] = true, [10059] = true }, { [17031] = 1, [17032] = 1 }
data = fixture:Load()
C_Spell.GetSpellInfo = function(id) return { name = "Spell " .. id } end
local player = { instanceID = 0, x = 100, y = 200, uiMapID = 1453 }
local function selected()
    local result, meta = data:BuildEdges({ playerPosition = player, inGroup = fixture.inGroup })
    local found
    for _, edge in ipairs(result) do
        if edge.action and edge.action.type == "spell" and (edge.action.data == 3561 or edge.action.data == 10059) then
            found = edge
            assert(edge.resources["item:" .. (fixture.inGroup and 17032 or 17031)] == 1)
        end
    end
    return found, meta
end
fixture.inGroup = false
local spell, resources = selected()
assert(spell and spell.action.data == 3561 and resources.resources["item:17031"] == 1)
assert(spell.seconds >= 10 and spell.instruction:find("Spell 3561", 1, true))
fixture.inGroup = true
assert(selected().action.data == 10059, "Usable mage portals take precedence when grouped")
local portals = {}
for _, connection in ipairs(data:GetConnections()) do
    for _, action in ipairs(connection.actions or {}) do portals[action.id] = action.groupSpellID end
end
assert(portals[3567] == 11417 and portals[3563] == 11418, "Horde portal spells retain their recorded destinations")
fixture.spells[3561], fixture.inGroup = nil, false
assert(not selected(), "A group portal cannot replace an unusable solo teleport")
fixture.inGroup = true
assert(selected().action.data == 10059, "The portal remains available to a group")
fixture.spells[3561], fixture.items[17031], fixture.items[17032] = true, 0, 0
assert(not selected(), "Forever mage spells require owned reagents")
local _, mismatch = data:BuildEdges({ profile = "retail", playerPosition = player })
assert(mismatch.waitingData and mismatch.reason == "profile_mismatch")
assert(not _G.FarstriderLib_API and not _G.FarstriderLibData_API)

local Lib = LibStub("LibAPRNavigation-1.0")
Lib:RegisterData("predicate-test", "connections", { connections = { { id = "closed-destination", kind = "portal",
    from = { space = "world", instanceID = 0, uiMapID = 1453, x = 100, y = 200 },
    to = { space = "world", instanceID = 0, uiMapID = 1453, x = 200, y = 200 },
    seconds = 1, requirements = { quest = 999999 } } } })
C_QuestLog.IsQuestFlaggedCompleted = function() return false end
local conditional = Lib:New({ profile = "predicate-test", environment = APR.NavigationAdapter.environment })
assert(#conditional:BuildEdges({ playerPosition = player }) == 0, "Access requirements cannot be bypassed by an open origin")
print("Navigation data: independent catalogues, Harandar, city geography, group spells, reagents and destination requirements passed")
