local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.translations = { USE_PORTAL_TO = "APR portal %s", UNKNOWN = "APR unknown" }
UNKNOWN = "Client unknown"
local data = fixture:Load()
local adapter, env = APR.NavigationAdapter, APR.NavigationAdapter.environment
do
    local previous = GetAchievementInfo
    assert(env.isAchievementCompleted(42045) == nil, "Absent achievement APIs must remain unknown")
    GetAchievementInfo = function(id) return id, "Client name", 0, true, nil, nil, nil, nil, nil, nil, nil, nil, false end
    assert(env.isAchievementCompleted(42045) == true, "Account completion applies even when this character did not earn it")
    GetAchievementInfo = function(id) return id, "Client name", 0, false end
    assert(env.isAchievementCompleted(42045) == false)
    GetAchievementInfo = function() error("unavailable") end
    assert(env.isAchievementCompleted(42045) == nil, "Failed achievement queries must not authorize travel")
    GetAchievementInfo = previous
end
assert(APR.NavigationEngine == LibStub("LibAPRNavigation-1.0").Engine)
local instance, x, y = env.mapToWorld(2413, 0.25, 0.75)
assert(instance == 2694 and x == 2500 and y == 7500, "Map conversion preserves every API return")
do
    local originalProjection, originalLookup, originalInfo = C_Map.GetMapPosFromWorldPos,
        C_Map.GetMapInfoAtPosition, C_Map.GetMapInfo
    local projections, lookups, mapReads = 0, 0, 0
    local sourceMap, localResult, failProjection = 12, { mapID = 85, mapType = 3 }, false
    C_Map.GetMapInfo = function(id)
        mapReads = mapReads + 1
        if id == 85 then return { mapID = 85, mapType = 3, parentMapID = 12, name = "Orgrimmar" } end
        return originalInfo(id)
    end
    C_Map.GetMapPosFromWorldPos = function(world, point, hint)
        projections = projections + 1
        assert(world == 1 and point.x == 1445.21 and point.y == -4499.56)
        if hint == 85 and not failProjection then return 85, { x = 0.571, y = 0.8981 } end
        return sourceMap, { x = 0.6, y = 0.4 }
    end
    C_Map.GetMapInfoAtPosition = function(id, mapX, mapY)
        lookups = lookups + 1
        assert(id == 12 and mapX == 0.6 and mapY == 0.4)
        return localResult
    end
    local map, mapX, mapY = env.worldToMap(1, 1445.21, -4499.56)
    assert(map == 85 and mapX == 0.571 and mapY == 0.8981 and projections == 2 and lookups == 1,
        "A continent result resolves through the client to consistent city coordinates")
    local endpoint = data:NormalizeLocation({ space = "world", instanceID = 1, x = 1445.21, y = -4499.56 })
    assert(endpoint.uiMapID == 85 and data:GetDisplayMapName(endpoint) == "Orgrimmar",
        "Unlabelled world endpoints use the client's local map name instead of the continent")

    failProjection = true
    map, mapX, mapY = env.worldToMap(1, 1445.21, -4499.56)
    assert(map == 12 and mapX == 0.6 and mapY == 0.4,
        "A failed local projection keeps the original map and its coordinates together")
    failProjection, localResult = false, nil
    map, mapX, mapY = env.worldToMap(1, 1445.21, -4499.56)
    assert(map == 12 and mapX == 0.6 and mapY == 0.4, "Missing local map information preserves the original result")
    C_Map.GetMapInfoAtPosition = function() error("restricted") end
    assert(env.worldToMap(1, 1445.21, -4499.56) == 12, "A restricted lookup does not discard a known world map")

    local beforeLookups, beforeReads, beforeProjections = lookups, mapReads, projections
    C_Map.GetMapInfoAtPosition = function() error("Specific maps must not be refined") end
    assert(env.worldToMap(1, 1445.21, -4499.56, 85) == 85)
    assert(projections == beforeProjections + 1 and mapReads == beforeReads and lookups == beforeLookups,
        "An explicit map hint avoids all refinement queries")
    sourceMap = 85
    beforeReads, beforeProjections = mapReads, projections
    assert(env.worldToMap(1, 1445.21, -4499.56) == 85)
    assert(projections == beforeProjections + 1 and mapReads == beforeReads + 1 and lookups == beforeLookups,
        "An already specific map needs no local lookup or second projection")
    C_Map.GetMapPosFromWorldPos, C_Map.GetMapInfoAtPosition, C_Map.GetMapInfo = originalProjection, originalLookup, originalInfo
end
local player = env.getPlayerPosition()
assert(player.x == 100 and player.y == 200 and player.instanceID == 0)
assert(env.getCharacter().class == "MAGE")
assert(env.getText("USE_PORTAL_TO") == APR.NavigationData:GetText("USE_PORTAL_TO"))
PORTAL = "Client portal"
assert(env.getText("USE_PORTAL_TO", "PORTAL") ~= PORTAL)
assert(env.getItemName(1) == APR.NavigationData:GetText("UNKNOWN") and env.getSpellName(1) == APR.NavigationData:GetText("UNKNOWN"))
assert(env.hasAura(123) == nil, "Missing aura API remains unknown")
C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end }
assert(env.hasAura(123) == false)
C_UnitAuras.GetPlayerAuraBySpellID = function() error("restricted") end
assert(env.hasAura(123) == nil)

fixture.bindName = "Client inn"
local clientInnName = fixture.bindName
data:GetBindings()[999999] = { space = "world", instanceID = 0, uiMapID = 2395, x = 700, y = 800 }
local area = C_Map.GetAreaInfo
C_Map.GetAreaInfo = function(id) return id == 999999 and clientInnName or area(id) end
assert(data:GetBindPosition().x == 700, "Binding coordinates resolve through the client's localized area name")
APRNavigationCharacterSettings.bindLocation = { name = fixture.bindName,
    location = { x = 950, y = 850, instanceID = 0, uiMapID = 2395 } }
assert(data:GetBindPosition().x == 950, "Observed bind beats coarse area coordinates")
fixture.bindName = "An inn absent from the area API"
assert(not data:GetBindPosition(), "A changed unknown bind never reuses the old location")
adapter.frame:OnEvent("HEARTHSTONE_BOUND")
assert(data:GetBindPosition().x == 100)
APRNavigationCharacterSettings.bindLocation = nil
adapter.bindLookup = nil
adapter.frame:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 8690)
adapter:CheckBindLanding()
assert(not APRNavigationCharacterSettings.bindLocation, "A successful cast does not record the departure as home")
fixture.player = { x = 1000, y = 2000, z = 10, instanceID = 0 }
adapter:CheckBindLanding()
assert(data:GetBindPosition().x == 1000 and not adapter.pendingBindLanding,
    "Actual arrival without a loading screen also learns the hearth destination")

local houses = {
    { houseGUID = "house-one", neighborhoodGUID = "neighborhood-one", plotID = 12 },
    { houseGUID = "house-two", neighborhoodGUID = "neighborhood-two", plotID = 12 },
}
local trackedHouse = "house-two"
C_Housing = {
    GetTrackedHouseGuid = function() return trackedHouse end,
    GetUIMapIDForNeighborhood = function(guid) return guid == "neighborhood-one" and 2351 or 2352 end,
    GetCurrentNeighborhoodGUID = function() return "neighborhood-one" end,
}
C_HousingNeighborhood = {
    GetNeighborhoodMapData = function() return { { plotID = 12, mapPosition = { x = 0.2, y = 0.3 } } } end,
    CanReturnAfterVisitingHouse = function() return true end,
}
adapter.frame:OnEvent("PLAYER_HOUSE_LIST_UPDATED", houses)
assert(data:GetHousingData().houseGUID == "house-two", "Secure action and destination use the same selected owned house")
assert(not env.getDynamicPosition("housing"), "A different neighborhood's matching plot number is not the selected house")
local usable, reason = env.getActionUsability("housing")
assert(not usable and reason == "pending_data")
C_Housing.GetCurrentNeighborhoodGUID = function() return "neighborhood-two" end
local home = env.getDynamicPosition("housing")
assert(home.uiMapID == 2352 and home.x == 2000 and home.y == 3000)
C_Housing.GetCurrentNeighborhoodGUID = function() return "neighborhood-one" end
assert(env.getDynamicPosition("housing").uiMapID == 2352, "An observed position remains keyed to that exact house")
assert(env.getActionUsability("housing") and env.getActionUsability("housing_return"))
C_Housing.GetVisitCooldownInfo = function() return { startTime = fixture.time, duration = 30 } end
usable, reason = env.getActionUsability("housing")
assert(not usable and reason == "cooldown", "The housing action respects the client cooldown")
C_Housing.GetVisitCooldownInfo = nil
APRNavigationCharacterSettings.housingExitLocation = nil
assert(data:GetBindPosition(), "A known hearth bind exists while testing an unknown housing return")
assert(not env.getDynamicPosition("housing_exit"), "An unknown housing return must not borrow the hearth destination")
local Lib = LibStub("LibAPRNavigation-1.0")
Lib:RegisterData("adapter-return-test", "return", { connections = { { id = "return", kind = "portal", seconds = 10,
    from = { dynamic = "player" }, to = { dynamic = "housing_exit" }, actions = { { type = "housing_return" } } } } })
local returnData = Lib:New({ profile = "adapter-return-test", environment = env })
assert(#returnData:BuildEdges({ playerPosition = env.getPlayerPosition() }) == 0,
    "Native return availability alone cannot create an edge with an invented endpoint")
data:UpdateHousingExitLocation()
assert(env.getDynamicPosition("housing_exit").x == 1000)
local returnEdges = returnData:BuildEdges({ playerPosition = env.getPlayerPosition() })
assert(#returnEdges == 1 and returnEdges[1].to.x == 1000 and returnEdges[1].to.y == 2000,
    "A recorded departure enables return to that exact point")

local cancelled, refreshed, requested = 0, 0, 0
APR.navigation = { generation = 1, cursor = 1,
    queue = { { kind = "walk" }, { action = { type = "housing" } } },
    GetActiveStep = function(self) return self.queue[self.cursor] end,
    Cancel = function(self, reason)
        assert(reason == "housing_changed")
        cancelled = cancelled + 1
        self.generation, self.queue, self.search = self.generation + 1, {}, nil
    end,
    ForceRefresh = function(self) refreshed = refreshed + 1; self.dirty = true end,
    RequestUpdate = function(self)
        assert(self.dirty and #self.queue == 0 and not self.search,
            "Replanning starts after cancellation and the refreshed data snapshot")
        requested = requested + 1
        self.updateScheduled = true
    end,
}
trackedHouse = "house-one"
adapter.frame:OnEvent("TRACKED_HOUSE_CHANGED", trackedHouse)
assert(cancelled == 1 and requested == 1 and APR.navigation.updateScheduled
    and APR.navigation.generation == 2 and #APR.navigation.queue == 0
    and data:GetHousingData().houseGUID == "house-one",
    "Changing houses cancels even an approach walk before a later housing action can target another house")
APR.navigation.queue = { { action = { type = "housing" } } }
adapter.frame:OnEvent("PLAYER_HOUSE_LIST_UPDATED", {})
assert(not data:GetHousingData() and not env.getDynamicPosition("housing"), "Revoked ownership removes its optional shortcut")
assert(cancelled == 2 and requested == 2, "Ownership changes discard the old housing action and schedule its replacement")
APR.navigation.queue = { { action = { type = "item", data = 6948 } } }
adapter.frame:OnEvent("TRACKED_HOUSE_CHANGED", nil)
assert(cancelled == 2 and requested == 2 and #APR.navigation.queue == 1,
    "A settled itinerary without housing keeps its guidance")
APR.navigation.queue, APR.navigation.search = {}, { pending = true }
adapter.frame:OnEvent("PLAYER_HOUSE_LIST_UPDATED", houses)
assert(cancelled == 3 and requested == 3 and not APR.navigation.search and refreshed == 4,
    "An unfinished search cannot publish housing edges built for the previous selection")
APR.navigation = nil
assert(data._catalog == nil, "APR uses the standalone library's public interface")

fixture.bindName = "Same client inn name"
APRNavigationCharacterSettings.bindLocation = nil
data:GetBindings()[1000000] = { space = "world", instanceID = 0, uiMapID = 2395, x = 10, y = 10 }
data:GetBindings()[1000001] = { space = "world", instanceID = 0, uiMapID = 2395, x = 5000, y = 5000 }
C_Map.GetAreaInfo = function(id) return (id == 1000000 or id == 1000001) and fixture.bindName or area(id) end
assert(not data:GetBindPosition(), "Ambiguous client names cannot select a random distant inn")
adapter.frame:OnEvent("HEARTHSTONE_BOUND")
assert(data:GetBindPosition().x == 1000, "A confirmed observation resolves the ambiguous name")
APRNavigationCharacterSettings.bindLocation = nil
adapter.frame:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 8690)
UnitIsDeadOrGhost = function() return true end
adapter:CheckBindLanding(true)
assert(not APRNavigationCharacterSettings.bindLocation and not adapter.pendingBindLanding,
    "Death must not turn a later loading-screen position into the hearth destination")
UnitIsDeadOrGhost = nil

C_Item.GetItemSpell = function() return "Client item spell", 98765 end
C_Spell.GetSpellInfo = function(id) return { name = "Client spell", castTime = id == 98765 and 2500 or 1000 } end
assert(env.getActionCastSeconds("item", 1) == 2.5 and env.getActionCastSeconds("spell", 2) == 1,
    "Cast durations come from the item spell or spell API")
APR.CanAccessValue = function(_, value) return value ~= "restricted" end
C_Spell.GetSpellInfo = function() return { name = "Client spell", castTime = "restricted" } end
assert(env.getSpellInfo(1).castTime == nil and env.getActionCastSeconds("spell", 1) == nil,
    "Restricted cast data does not cross the library boundary")

fixture.bindName = "An unobserved inn for the budget test"
APRNavigationCharacterSettings.bindLocation = nil
adapter.bindLookup = nil
local areaReads, elapsed = 0, 0
C_Map.GetAreaInfo = function(id)
    areaReads, elapsed = areaReads + 1, elapsed + 0.125
    return "Area " .. id
end
local lookup = adapter:CreatePreparation({ clock = function() return elapsed end })
assert(areaReads == 0, "Preparing a bind lookup does not synchronously scan the area catalogue")
assert(lookup:Step(64, 1) == "planning" and areaReads == 8,
    "Binding names obey the same deadline as the later graph preparation")
lookup:Cancel()
local stoppedAt = areaReads
assert(lookup:Step(64, 1) == "cancelled" and areaReads == stoppedAt)
lookup = adapter:CreatePreparation({ clock = function() return elapsed end })
while lookup:Step(64, 1) == "planning" do end
local preparedReads = areaReads
for _ = 1, 100 do assert(data:GetBindPosition() == nil) end
assert(areaReads == preparedReads, "Hearth variants reuse the completed negative lookup")
print("Navigation adapter: API coordinates, localized names, bind landing, selected-house geography, ownership and separate APR state passed")
