-- Each dungeon offer has a complete localization key; no automatic legacy aliases.
dofile("tests/lua/forever_dungeon_prefab_test.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
function APR:GetGameVersion() return APR.GAME_VERSIONS.Forever end
function APR:Debug() end
APR.ActiveRoute, APR.Level = nil, 30
APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Human", 1, "WARRIOR", 1

local named = 0
for key, route in pairs(APR.RouteQuestStepList) do
    if key:find("^Forever%-.+%-Dungeons%-") then
        named = named + 1
        assert(route.legacyLabels == nil, "Only a human may author legacyLabels")
        if key:find("^Forever%-Shared%-") then
            assert(route.label:find("^Forever %- Dungeon %- "))
        else
            assert(route.label:find("^Forever %- Leveling Dungeon %- "))
        end
        assert(not route.label:find(" + ", 1, true), "A route name cannot assemble translated fragments")
    end
end
assert(named == 22, "Both offers must name every maintained dungeon chapter")

-- Normal resuming uses the complete name and stable route key, without aliases.
local function resume(faction, key)
    APR.Faction = faction
    local route = APR.RouteQuestStepList[key]
    assert(APR:GetRouteKeyFromDisplayName(route.label) == key)
    APRCustomPath.player = {route.label}
    APRData.player[key] = 3
    local _, _, resumed = APR:GetCurrentRouteMapIDsAndName()
    assert(resumed == key and APRCustomPath.player[1] == route.label)
    assert(APRData.player[key] == 3, "Renaming must not reset the stable route key")
    -- Generic normalization does not manufacture another name or completion.
    APR.Level = 1
    APRCustomPath.player = {route.label}
    APRZoneCompleted.player[route.label] = true
    APR:NormalizeSavedRouteLabels()
    assert(APRCustomPath.player[1] == route.label, "An entry level cannot discard a queued route")
    assert(APRZoneCompleted.player[route.label] == true)
    assert(not APR:IsRequiredRouteApplicable(key), "Completed routes must remain completed after renaming")
    APR.Level = 30
end
resume("Alliance", "Forever-Alliance-Dungeons-Deadmines")
resume("Alliance", "Forever-Shared-Dungeons-Deadmines")
resume("Horde", "Forever-Horde-Dungeons-Ruins-of-Lordaeron")
resume("Horde", "Forever-Shared-Dungeons-Ruins-of-Lordaeron")

-- The two RFC offers resolve independently, including on a Horde character.
local factionKey, sharedKey = "Forever-Horde-Dungeons-Ragefire-Chasm", "Forever-Shared-Dungeons-Ragefire-Chasm"
for _, key in ipairs({factionKey, sharedKey}) do
    APR.Faction = "Horde"
    assert(APR:GetRouteKeyFromDisplayName(APR.RouteQuestStepList[key].label) == key)
end

local definition = APR.routeconfig.PREFAB_POPUP_DEFINITIONS.dungeons
assert(not definition.title:find("SPEEDRUN", 1, true))
assert(definition.title == DUNGEONS)
assert(definition.description == "LEVELING_TOOLTIPS")
print("Dungeon names: complete localization keys, no aliases, stable progress and distinct offers passed")
