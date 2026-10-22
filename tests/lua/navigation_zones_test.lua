local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
dofile("APR-Core/utils/Utils.lua")
APR.Debug = function() end
dofile("APR-Core/utils/NavigationZones.lua")
local function point(map, x) return { uiMapID = map, instanceID = 0, x = x or 100, y = 200 } end
fixture.currentMap = 2395
local ready, reason = APR:CheckNavigationZoneReady(point(2393, 101), { playerPosition = point(2395) })
assert(ready and reason == "nearby_connected", "Nested cities connect symmetrically without a transport")
fixture.currentMap = 2393; APR:InvalidatePlayerZoneCache()
assert(APR:CheckNavigationZoneReady(point(2395), { playerPosition = point(2393) }))
fixture.currentMap = 2395; APR:InvalidatePlayerZoneCache()
ready, reason = APR:CheckNavigationZoneReady(point(2413, 101), { playerPosition = point(2395) })
assert(not ready and reason == "required_crossing", "Harandar isolation precedes geography and proximity")
local config = APR.NavigationData:GetConfig()
config.IsolatedAreas[2395] = "parent-access"
config.IsolatedAreas[2393] = "child-access"
ready, reason = APR:CheckNavigationZoneReady(point(2393, 101), { playerPosition = point(2395) })
assert(not ready and reason == "required_crossing", "Matching parent ancestry cannot bypass a child restriction")
config.IsolatedAreas[2395], config.IsolatedAreas[2393] = nil, nil
fixture.maps[8001] = { mapID = 8001, parentMapID = 2395, mapType = 5 }
fixture.currentMap = 8001; APR:InvalidatePlayerZoneCache()
assert(APR:CheckNavigationZoneReady(point(2395), { playerPosition = point(8001) }), "Child caves/buildings share their accessible parent")
fixture.currentMap = 2395; APR:InvalidatePlayerZoneCache()
fixture.maps[8002] = { mapID = 8002, parentMapID = 13, mapType = 3 }
assert(APR:CheckNavigationZoneReady(point(8002, 2099), { playerPosition = point(2395), threshold = 2000 }))
assert(not APR:CheckNavigationZoneReady(point(8002, 2100), { playerPosition = point(2395), threshold = 2000 }))
local other = point(2395); other.instanceID = 1
ready, reason = APR:CheckNavigationZoneReady(other, { playerPosition = point(2395) })
assert(not ready and reason == "different_instance")
fixture.maps[9001] = { mapID = 9001, parentMapID = 9001, mapType = 3 }
assert(APR.NavigationData:GetPositionRegion(point(9001)) == nil, "Cyclic map parents fail closed")
assert(APR:GetPlayerParentMapID() == 2395 and APR:GetContinent(2393) == 13,
    "Geographic helper contracts remain usable by prefabs, previews and corpse navigation")
fixture.time = fixture.time + 1
assert(APR:GetZoneDetectionReport().playerCurrent == 2395)
print("Navigation zones: hierarchy, exact thresholds, world identity, restrictions-first semantics, cycles and geographic compatibility passed")
