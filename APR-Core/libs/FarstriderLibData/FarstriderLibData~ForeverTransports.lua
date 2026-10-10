local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
local interfaceVersion = GetBuildInfo and tonumber((select(4, GetBuildInfo()))) or 0
if interfaceVersion < 16000 or interfaceVersion >= 17000 then return end

-- Replace the generated and supplemental legacy transports rather than adding parallel routes
-- to outdated platforms. Other clients retain their original data.
for index = #FarstriderLibData.Waypoints, 1, -1 do
    local waypoint = FarstriderLibData.Waypoints[index]
    if waypoint.id == 44 or waypoint.id == 46
        or waypoint.from.locaId == 1003 or waypoint.from.locaId == 1004 then
        table.remove(FarstriderLibData.Waypoints, index)
    end
end

-- mapID, UI x, UI y, optional AreaTable ID, localization key for transport instructions.
local ports = {
    DOCK_AUBERDINE_MENETHIL = { 1439, 0.3237, 0.4381, 442, "ForeverPort_Auberdine" }, -- captured live
    DOCK_AUBERDINE_RUTTHERAN = { 1439, 0.3318, 0.4013, 442, "ForeverPort_Auberdine" }, -- captured live
    DOCK_AUBERDINE_STORMWIND = { 1439, 0.3077, 0.4101, 442, "ForeverPort_Auberdine" }, -- captured live
    DOCK_BOOTYBAY = { 1434, 0.3908, 0.6673, 35, "ForeverPort_BootyBay" }, -- estimated
    DOCK_DALARAN = { 1416, 0.1262, 0.5203, nil, "ForeverPort_Dalaran" }, -- captured live
    DOCK_FEATHERMOON = { 1444, 0.2780, 0.3171, nil, "ForeverPort_Feathermoon" }, -- estimated
    DOCK_FORGOTTENCOAST = { 1444, 0.3542, 0.5040, nil, "ForeverPort_ForgottenCoast" }, -- estimated
    DOCK_MENETHIL = { 1437, 0.0464, 0.5716, 150, "ForeverPort_Menethil" }, -- captured live
    DOCK_MENETHIL_THERAMORE = { 1437, 0.0509, 0.6351, 150, "ForeverPort_Menethil" }, -- captured live
    DOCK_POWDERFUSE = { 2548, 0.7222, 0.7603, nil, "ForeverPort_Powderfuse" }, -- estimated
    DOCK_RATCHET = { 1413, 0.6446, 0.5083, 392, "ForeverPort_Ratchet" }, -- estimated
    DOCK_RUTTHERAN = { 1438, 0.5488, 0.9671, 702, "ForeverPort_Ruttheran" }, -- captured live
    DOCK_SKYWATCHER = { 1412, 0.3430, 0.2576, nil, "ForeverPort_Skywatcher" }, -- captured live
    DOCK_SOUTHSHORE = { 1424, 0.5053, 0.6975, 271, "ForeverPort_Southshore" }, -- captured live
    DOCK_STEAMWHEEDLE = { 1446, 0.6538, 0.2245, nil, "ForeverPort_Steamwheedle" }, -- estimated
    DOCK_STORMWIND = { 1453, 0.2255, 0.5613, 1519, "ForeverPort_Stormwind" }, -- captured live
    DOCK_THERAMORE = { 1445, 0.7150, 0.5635, 513, "ForeverPort_Theramore" }, -- captured live
    DOCK_VALANAAR = { 2521, 0.5791, 0.8078, 16628, "ForeverPort_Valanaar" }, -- captured live
    DOCK_ZEPHRAS_ALLIANCE = { 2521, 0.6581, 0.8341, nil, "ForeverPort_Zephras" }, -- captured live
    ZEPPELIN_GROMGOL_ORGRIMMAR = { 1434, 0.3130, 0.3010, 117, "ForeverPort_Gromgol" }, -- captured live
    ZEPPELIN_GROMGOL_TIRISFAL = { 1434, 0.3160, 0.2920, 117, "ForeverPort_Gromgol" }, -- captured live
    ZEPPELIN_ORGRIMMAR_GROMGOL = { 1411, 0.5070, 0.1280, 1637, "ForeverPort_Orgrimmar" }, -- captured live
    ZEPPELIN_ORGRIMMAR_TIRISFAL = { 1411, 0.5080, 0.1370, 1637, "ForeverPort_Orgrimmar" }, -- captured live
    ZEPPELIN_TIRISFAL_GROMGOL = { 1420, 0.6190, 0.5910, 1497, "ForeverPort_Undercity" }, -- captured live
    ZEPPELIN_TIRISFAL_ORGRIMMAR = { 1420, 0.6070, 0.5880, 1497, "ForeverPort_Undercity" }, -- captured live
}

-- from, to, localization ID, average travel seconds, bidirectional, optional faction.
local routes = {
    { "DOCK_STORMWIND", "DOCK_AUBERDINE_STORMWIND", 1003, 170, true, "Alliance" },
    { "DOCK_AUBERDINE_MENETHIL", "DOCK_MENETHIL", 1003, 293, false, "Alliance" },
    { "DOCK_MENETHIL", "DOCK_SOUTHSHORE", 1003, 363, false, "Alliance" },
    { "DOCK_SOUTHSHORE", "DOCK_AUBERDINE_MENETHIL", 1003, 303, false, "Alliance" },
    { "DOCK_AUBERDINE_MENETHIL", "DOCK_SOUTHSHORE", 1003, 488, false, "Alliance" },
    { "DOCK_MENETHIL", "DOCK_AUBERDINE_MENETHIL", 1003, 498, false, "Alliance" },
    { "DOCK_SOUTHSHORE", "DOCK_MENETHIL", 1003, 428, false, "Alliance" },
    { "DOCK_STEAMWHEEDLE", "DOCK_POWDERFUSE", 1003, 90, true },
    { "DOCK_MENETHIL_THERAMORE", "DOCK_THERAMORE", 1003, 370, true, "Alliance" },
    { "DOCK_AUBERDINE_RUTTHERAN", "DOCK_RUTTHERAN", 1003, 190, true, "Alliance" },
    { "DOCK_BOOTYBAY", "DOCK_RATCHET", 1003, 250, true },
    { "DOCK_FEATHERMOON", "DOCK_FORGOTTENCOAST", 1003, 60, true, "Alliance" },
    { "DOCK_VALANAAR", "DOCK_SKYWATCHER", 1003, 310, true, "Horde" },
    { "DOCK_ZEPHRAS_ALLIANCE", "DOCK_DALARAN", 1003, 290, true, "Alliance" },
    { "ZEPPELIN_TIRISFAL_ORGRIMMAR", "ZEPPELIN_ORGRIMMAR_TIRISFAL", 1004, 300, true, "Horde" },
    { "ZEPPELIN_ORGRIMMAR_GROMGOL", "ZEPPELIN_GROMGOL_ORGRIMMAR", 1004, 250, true, "Horde" },
    { "ZEPPELIN_TIRISFAL_GROMGOL", "ZEPPELIN_GROMGOL_TIRISFAL", 1004, 240, true, "Horde" },
}

local function portName(port)
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(port[1])
    if mapInfo and mapInfo.name and mapInfo.name ~= "" then
        return mapInfo.name
    end
    if port[4] then
        return (C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(port[4]))
            or rawget(FarstriderLibData.L, "Area_" .. port[4]) or FarstriderLibData.L[port[5]]
    end
    return FarstriderLibData.L[port[5]]
end

local function endpoint(port, otherPort, locaId, condition)
    return {
        unknown1 = 0, flags = 0, type = 1, important = true,
        loc = { mapId = port[1], pos = { x = port[2], y = port[3], z = 0 }, isUI = true },
        condition = condition,
        locaId = locaId,
        locaArgs = function() return { portName(port), portName(otherPort) } end,
    }
end

for index, route in ipairs(routes) do
    local from, to = ports[route[1]], ports[route[2]]
    local faction = route[6]
    local condition = faction and function() return UnitFactionGroup("player") == faction end or nil
    local id = 4000 + index
    -- Keep the native boat IDs for consumers of these entries, including their faction gate.
    if route[1] == "DOCK_MENETHIL_THERAMORE" then id = 44 end
    if route[1] == "DOCK_BOOTYBAY" then id = 46 end
    if not condition or condition() or id == 44 then
        table.insert(FarstriderLibData.Waypoints, {
            id = id,
            from = endpoint(from, to, route[3], condition),
            to = endpoint(to, from, route[3], condition),
            bidirectional = route[5], cost = route[4], condition = condition,
        })
    end
end
