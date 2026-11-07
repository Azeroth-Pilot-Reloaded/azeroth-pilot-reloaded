local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile = profile
    fixture.currentMap = 10
    function IsInInstance() return false end
    local data = fixture:Load({ entrances = {
        { id = "near-door", kind = "dungeon", reviewStatus = "confirmed", instanceID = 900,
            interiorMapIDs = profile == "retail" and { 30 } or {},
            exterior = { uiMapID = 10, instanceID = 0, x = 100, y = 200 } },
        { id = "quest-door", kind = "dungeon", reviewStatus = "confirmed", instanceID = 900,
            interiorMapIDs = profile == "retail" and { 30 } or {},
            exterior = { uiMapID = 10, instanceID = 0, x = 900, y = 800 } },
        { id = "other-instance", kind = "dungeon", reviewStatus = "confirmed", instanceID = 901,
            interiorMapIDs = {}, exterior = { uiMapID = 10, instanceID = 0, x = 500, y = 600 } },
        { id = "locked-door", kind = "dungeon", reviewStatus = "confirmed", instanceID = 900,
            requirements = { questActive = 42 }, interiorMapIDs = {},
            exterior = { uiMapID = 10, instanceID = 0, x = 700, y = 600 } },
    } })
    dofile("APR-Core/integrations/NavigationEntrances.lua")
    dofile("APR-Core/features/questing/DelveRoutes.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    dofile("APR-Core/utils/DungeonUtils.lua")
    APR.DungeonData = { forever = { invented = { instanceID = 900, instanceType = "party" } } }
    function APR:GetScenarioZoneInfo(mapID) return self:GetNavigationEntranceInfo(mapID) end
    function APR:IsDelveRoute() return false end
    function APR:GetPlayerParentMapID() return fixture.currentMap end
    local selected = { EnterInstance = { dungeonKey = "invented", entranceID = "quest-door" } }
    local generic = { EnterInstance = { dungeonKey = "invented" } }
    for _, mapID in ipairs({ 10, 99 }) do
        fixture.currentMap = mapID
        local coord, zone = APR:GetStepCoord(selected)
        assert(coord and coord.x == 800 and coord.y == 900 and zone == 10,
            "A chosen door guides from its zone and a distant zone")
        local fallback = APR:GetStepCoord(generic)
        assert(fallback and fallback.x == 200 and fallback.y == 100,
            "Unqualified instance steps retain closest-door selection")
        assert(coord.x == 800 and coord.y == 900, "Generic lookup cannot overwrite a selected cached view")
    end
    for _, id in ipairs({ "missing", "other-instance" }) do
        local invalid = { EnterInstance = { dungeonKey = "invented", entranceID = id }, Coord = { x = 1, y = 2 } }
        assert(APR:GetStepCoord(invalid) == nil, "Invalid or wrong-instance doors cannot fall back to another entrance")
    end
    data.env.isQuestActive = function() return false end
    assert(APR:GetNavigationEntranceInfoForInstance(900, "locked-door").unavailable == "requirements_unmet")
    data.env.isQuestActive = function() return nil end
    assert(APR:GetNavigationEntranceInfoForInstance(900, "locked-door").unavailable == "pending_data")
    data.env.isQuestActive = function() return true end
    assert(APR:GetNavigationEntranceInfoForInstance(900, "locked-door").Coord.y == 700,
        "A locked selected entrance remains retryable when its requirement changes")
    local inside, instanceID, advances = false, 900, 0
    function IsInInstance() return inside, "party" end
    function GetInstanceInfo() return "invented", "party", 0, 0, 0, 0, 0, instanceID end
    function APR:UpdateNextStep() advances = advances + 1 end
    function APR:GetDungeonTravelText() return "enter" end
    APR.currentStep = { AddQuestSteps = function() end }
    APR:RenderDungeonTravel(selected)
    assert(advances == 0, "Exterior proximity is not physical instance entry")
    inside, instanceID = true, 901
    APR:RenderDungeonTravel(selected)
    assert(advances == 0, "Another instance is not the destination")
    instanceID = 900
    APR:RenderDungeonTravel(selected)
    assert(advances == 1, "Starting or reloading inside continues without returning to the exterior door")
end
print("Instance entrance selection: explicit doors, defaults, invalid references and native entry passed")
