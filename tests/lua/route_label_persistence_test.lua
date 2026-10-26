-- Display names and saved progress are independent of actual guide content.
local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
function APR:Debug() end
APR.Level = 30
for index, label in ipairs({ "Nom complet : étape suivante", "別のルート", "Dungeon only / arbitrary label" }) do
    local key = "fixture-label-" .. index
    local route = env.route(key, label, { MinLevel = 20 })
    assert(APR:GetRouteKeyFromDisplayName(label) == key)
    APRCustomPath.player, APRData.player[key], APR.ActiveRoute = { label }, 2, nil
    local _, _, resumed = APR:GetCurrentRouteMapIDsAndName()
    assert(resumed == key and APRData.player[key] == 2)
    APR.Level = 1
    APRZoneCompleted.player[label] = true
    APR:NormalizeSavedRouteLabels()
    assert(APRCustomPath.player[1] == label and APRZoneCompleted.player[label])
    assert(not APR:IsRequiredRouteApplicable(key), "Normalization preserves completion despite a level gate")
    APR.Level = 30
    -- Rename the display label without changing the route's stable progress key.
    route.label = label .. " (renamed)"
    APRCustomPath.player, APR.ActiveRoute = { route.label }, nil
    local _, _, renamed = APR:GetCurrentRouteMapIDsAndName()
    assert(renamed == key and APRData.player[key] == 2)
end
