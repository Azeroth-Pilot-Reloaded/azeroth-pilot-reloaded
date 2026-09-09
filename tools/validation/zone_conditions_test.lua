-- Zone conditions use the same evaluator for progression and list visibility.
function LibStub() return { GetLocale = function() return {} end } end
APR = {}
local currentMap
C_Map = { GetBestMapForUnit = function() return currentMap end }
function UnitLevel() return 88 end
function tContains(list, value)
    for _, entry in ipairs(list) do if entry == value then return true end end
    return false
end
dofile("APR-Core/utils/RouteUtils.lua")
local function check(condition, mapID, visible)
    currentMap = mapID
    assert(not not APR:StepFilterQoL(condition) == visible, "Unexpected list visibility")
    assert(APR:StepFilterQuestHandler(condition) == not visible, "Unexpected automatic skip")
end
check({ SkipInZones = { 2393 } }, 2393, false)
check({ SkipInZones = { 2393 } }, 2413, true)
check({ SkipInZones = { 2393, 2413 } }, 2413, false)
check({ SkipInZones = { 2393 } }, nil, true)
check({ OnlyInZones = { 2541 } }, 2541, true)
check({ OnlyInZones = { 2541 } }, 2393, false)
check({ OnlyInZones = { 2393, 2541 } }, 2393, true)
check({ OnlyInZones = { 2541 } }, nil, false)
check({ Zones = { 2393, 2413 }, SkipInZones = { 2393 } }, 2393, false)
check({ Zones = { 2393, 2413 }, SkipInZones = { 2393 } }, 2413, true)
check({ OnlyInZones = { 2541 }, SkipForLvl = 88 }, 2541, false)
check({ Zone = 2541 }, 2393, true)
print("Zone conditions: inclusion/exclusion, multiple maps, missing map, composition and navigation-only Zone passed")
