-- Classic/Forever client surface with separate continent coordinate spaces.
-- Coordinates are deterministic fixtures; transport definitions are real data.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile, fixture.currentMap, fixture.faction = "forever", 1453, "Alliance"
local kalimdor = { [1411] = true, [1412] = true, [1413] = true, [1438] = true, [1439] = true,
    [1440] = true, [1441] = true, [1442] = true, [1443] = true, [1444] = true, [1445] = true,
    [1446] = true, [1447] = true, [1448] = true, [1449] = true, [1450] = true, [1451] = true,
    [1452] = true, [1454] = true, [1456] = true, [1457] = true, [2521] = true, [2548] = true }
function fixture:WorldForMap(map) return map == 225 and 369 or kalimdor[map] and 1 or 0 end
function fixture:ParentForMap(map) return kalimdor[map] and 1414 or 1415 end
local originalInfo = C_Map.GetMapInfo
C_Map.GetMapInfo = function(map)
    if map == 225 then return { mapID = map, mapType = 4, parentMapID = 1415, name = "Tram" } end
    if map == 1414 or map == 1415 or map == 947 then return originalInfo(map) end
    return { mapID = map, mapType = 3, parentMapID = fixture:ParentForMap(map), name = "Map " .. map }
end
C_Map.GetBestMapForUnit = function() return fixture.currentMap end
C_Map.GetWorldPosFromMapPos = function(map, pos)
    return fixture:WorldForMap(map), { x = pos.x * 10000, y = pos.y * 10000 }
end
C_Map.GetMapPosFromWorldPos = function(instance, x, hint)
    return hint or (instance == 369 and 225 or instance == 1 and 1439 or 1453), { x = 0.5, y = 0.5 }
end
C_Map.GetMapArtID, C_Map.GetMapRectOnMap = nil, nil
C_PlayerInfo, C_Housing, C_MountJournal, C_Minimap = nil, nil, nil, nil
return fixture
