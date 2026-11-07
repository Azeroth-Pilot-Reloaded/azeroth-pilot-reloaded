local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
C_Map = { GetBestMapForUnit = function() return 1 end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
RACE, CLASS, CHARACTER, YES, NO = "Race", "Class", "Character", "Yes", "No"
local route = env.route("invented-start", "Invented start", { Race = { "Orc", "Troll" }, Faction = "Horde" }, {
    [APR.PREFAB_TYPES.StartingZone] = {},
}, APR.CATEGORIES.Leveling)
for _, race in ipairs({ "Orc", "Troll" }) do
    APR.Race = race
    assert(APR:GetRouteVisibility("invented-start") == "visible")
    assert(#APR:GetRouteSelectionWarnings("invented-start") == 0)
    assert(APR:GetRouteVisibility("invented-start", true) == "visible")
end
for _, race in ipairs({ "Tauren", "Skyborne" }) do
    APR.Race = race
    assert(APR:CanStartRoute("invented-start"), "Manual entry can adopt a same-faction start")
    assert(#APR:GetRouteSelectionWarnings("invented-start") == 1, "The authored starting races remain visible advice")
    assert(APR:GetRouteVisibility("invented-start", true) == "hidden", "Presets retain authored races")
end
route.conditions.Race = "Skyborne"
APR.Race = "Skyborne"
assert(#APR:GetRouteSelectionWarnings("invented-start") == 0)
APR.Race = "Orc"
assert(#APR:GetRouteSelectionWarnings("invented-start") == 1)
APR.Faction = "Alliance"
assert(not APR:CanStartRoute("invented-start") and APR:GetRouteVisibility("invented-start") == "hidden")
APR.Faction = "Horde"
route.conditions.Class = "MAGE"
assert(not APR:CanStartRoute("invented-start"), "A specialized starter retains its class access")
route.conditions.Class = nil
route.conditions.Faction = nil
assert(not APR:CanStartRoute("invented-start"), "An unproven faction cannot waive its starter race")
