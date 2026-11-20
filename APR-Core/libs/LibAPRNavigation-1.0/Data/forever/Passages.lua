-- Declarative travel data. Names are resolved through the game client.
local function World(instanceID, uiMapID, x, y, z, noAutoconnect)
    return {
        space = "world",
        instanceID = instanceID,
        uiMapID = uiMapID,
        x = x,
        y = y,
        z = z,
        noAutoconnect = noAutoconnect,
    }
end

local function Passage(id, from, to, seconds, requirements)
    return {
        id = id,
        kind = "passage",
        from = from,
        to = to,
        requirements = requirements,
        seconds = seconds,
        costMode = not seconds and "ground" or nil,
    }
end

local function Lift(id, from, to, seconds)
    return {
        id = id,
        kind = "elevator",
        bidirectional = true,
        from = from,
        to = to,
        seconds = seconds,
        arrivalRadius = 16,
        arrivalZTolerance = 8,
        durationSource = "estimated-wait-and-ride",
        reviewStatus = "confirmed",
    }
end

-- Recorded bends from the road, through the gate and throne room, to the
-- upper lift hall. The terrain grid has stacked surfaces at the gate.
local undercityApproach = {
    World(0, 1420, 1884, 241, 58),
    World(0, 1420, 1877.57, 240.75, 61, true),
    World(0, 1420, 1749.54, 239.14, 62),
    World(0, 1420, 1724.7, 255.64, 64, true),
    World(0, 1420, 1706.97, 240.68, 63, true),
    World(0, 1420, 1660.12, 241.06, 63, true),
    World(0, 1420, 1623.38, 257.08, 63, true),
    World(0, 1420, 1598.73, 244.51, 60),
}
local undercityLifts = {
    { "west", World(0, 1420, 1596.1, 280.8, 62), World(0, 1458, 1596.15, 291.8, -40.784) },
    { "east", World(0, 1420, 1595.3, 198.3, 63), World(0, 1458, 1595.26, 188.644, -40.783) },
    { "south", World(0, 1420, 1551.2, 241.1, 62), World(0, 1458, 1544.24, 240.773, -40.783) },
}
-- The sewer is an alternate entrance for travellers already at its mouth.
-- Keep its bends private so an approach cannot join from the terrain above.
local undercitySewer = {
    World(0, 1420, 1684.44, 610.42, 40.1),
    World(0, 1420, 1665.17, 539.52, nil, true),
    World(0, 1420, 1659.8, 481.48, nil, true),
    World(0, 1420, 1632.15, 476.49, nil, true),
    World(0, 1420, 1627.02, 439.08, nil, true),
    World(0, 1420, 1598.86, 435.05, nil, true),
    World(0, 1458, 1595, 415, -62),
}

local function AddPassageChain(connections, id, points, radius, first)
    for index = (first or 1) + 1, #points do
        local edge = Passage(id .. ":" .. (index - 1), points[index - 1], points[index])
        edge.bidirectional, edge.arrivalRadius = true, radius
        connections[#connections + 1] = edge
    end
end

-- Each platform has its own walking region inside the tram instance.
local alliance = { faction = "Alliance" }
local ironforgeStation = World(369, 499, 69.228, 10.393, -4.297)
local stormwindStation = World(369, 499, 67.761, 2490.98, -4.296)
local ironforgeExit = World(369, 499, 76.027, 10.504, -4.297)
local stormwindExit = World(369, 499, 80.163, 2490.88, -1.857)
local ironforgeBoarding = World(369, 499, 4.6296, 28.139, -3.4569)
local stormwindBoarding = World(369, 499, 4.6294, 2510.42, -3.2704)
local stormwindArrival = World(369, 499, 45.0956, 2490.52, -4.2965)
local function Tram(id, from, to)
    return {
        id = id,
        kind = "tram",
        from = from,
        to = to,
        requirements = alliance,
        seconds = 160,
        arrivalRadius = 16,
    }
end

local catalogue = {
    connections = {
        -- Classic AreaTrigger 2534/2530 and their server return landings.
        -- Exit-only: entering the PvP halls has additional access conditions.
        {
            id = "passage-champions-hall-to-stormwind",
            kind = "passage",
            from = { instanceID = 449, space = "world", x = -0.358041, y = -1.97986, z = -0.255884 },
            to = { instanceID = 0, space = "world", uiMapID = 1453, x = -8762.45, y = 403.062, z = 103.902 },
            seconds = 5,
        },
        {
            id = "passage-hall-of-legends-to-orgrimmar",
            kind = "passage",
            from = { instanceID = 450, space = "world", x = 215.194, y = 71.157, z = 30.1276 },
            to = { instanceID = 1, space = "world", uiMapID = 1454, x = 1637.32, y = -4242.7, z = 56.1827 },
            seconds = 5,
        },
        {
            id = "passage-eastern-kingdoms-to-eastern-kingdoms",
            kind = "passage",
            bidirectional = true,
            from = { instanceID = 0, space = "world", x = -9016.9404296875, y = 877.29400634766, z = 148.6190032959 },
            to = {
                instanceID = 0,
                space = "world",
                x = -9004.4443359375,
                y = 870.625,
                z = 64.86025238037,
                accessKey = "wizards-sanctum",
            },
            requirements = { faction = "Alliance" },
            seconds = 0,
        },
        {
            id = "walk-timbermaw:1",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1448, x = 0.6544, y = 0.0281 },
            to = { space = "map", uiMapID = 1448, x = 0.6651, y = 0.0298, noAutoconnect = true },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-timbermaw:2",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1448, x = 0.6651, y = 0.0298, noAutoconnect = true },
            to = { space = "map", uiMapID = 1448, x = 0.6781999999999999, y = 0.0433, noAutoconnect = true },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-timbermaw:3",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1448, x = 0.6781999999999999, y = 0.0433, noAutoconnect = true },
            to = { space = "map", uiMapID = 1448, x = 0.6793, y = 0.051100000000000007, noAutoconnect = true },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-timbermaw:4",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1448, x = 0.6793, y = 0.051100000000000007, noAutoconnect = true },
            to = { instanceID = 1, space = "world", uiMapID = 1452, x = 6896.07, y = -2287.63 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-great-lift:1",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1413, x = 0.4413, y = 0.9144 },
            to = { space = "map", uiMapID = 1441, x = 0.3197, y = 0.2376 },
            seconds = 45,
        },
        {
            id = "walk-feralas-road:1",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1441, x = 0.2304, y = 0.38365000000000005 },
            to = { space = "map", uiMapID = 1444, x = 0.8924, y = 0.4117 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-tanaris-road:1",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1441, x = 0.7544, y = 0.9737 },
            to = { space = "map", uiMapID = 1446, x = 0.516, y = 0.2544 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "walk-freewind-post-lift",
            kind = "elevator",
            reviewStatus = "candidate",
            bidirectional = true,
            from = { instanceID = 1, space = "world", uiMapID = 1441, x = -5390.845, y = -2497.02, z = 89.023 },
            to = { instanceID = 1, space = "world", uiMapID = 1441, x = -5390.845, y = -2497.02, z = -40.404 },
            seconds = 45,
            arrivalZTolerance = 8,
            disabled = true,
        },
        {
            id = "forever-border-1",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.1902, y = 0.183 },
            to = { space = "map", uiMapID = 1439, x = 0.3755, y = 0.9626 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-2",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.2919, y = 0.15 },
            to = { space = "map", uiMapID = 1439, x = 0.4312, y = 0.9363 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-3",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.4229, y = 0.7106 },
            to = { space = "map", uiMapID = 1442, x = 0.7823, y = 0.427 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-4",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.5575, y = 0.2928 },
            to = { space = "map", uiMapID = 1448, x = 0.5482, y = 0.9117 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-5",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.6862, y = 0.8648 },
            to = { space = "map", uiMapID = 1413, x = 0.4816, y = 0.0432 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-6",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1440, x = 0.9474, y = 0.4777 },
            to = { space = "map", uiMapID = 1447, x = 0.1056, y = 0.7509 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-7",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1457, x = 0.8626, y = 0.3556, z = 1328 },
            to = { space = "map", uiMapID = 1438, x = 0.3616, y = 0.5439, z = 1327 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-8",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1443, x = 0.4093, y = 0.9068 },
            to = { space = "map", uiMapID = 1444, x = 0.4555, y = 0.0309 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-9",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1443, x = 0.5338, y = 0.0568 },
            to = { space = "map", uiMapID = 1442, x = 0.3018, y = 0.7595 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-10",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1411, x = 0.4553, y = 0.1212, z = 26 },
            to = { space = "map", uiMapID = 1454, x = 0.5252, y = 0.8477, z = 25 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-11",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1445, x = 0.288, y = 0.4715 },
            to = { space = "map", uiMapID = 1413, x = 0.4963, y = 0.7841 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-12",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1448, x = 0.6511, y = 0.0803 },
            to = { space = "map", uiMapID = 1448, x = 0.654, y = 0.0702 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-13",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1450, x = 0.3573, y = 0.7246 },
            to = { space = "map", uiMapID = 1450, x = 0.3545, y = 0.7424 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-14",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1452, x = 0.2791, y = 0.3445 },
            to = { space = "map", uiMapID = 1448, x = 0.6794, y = 0.0515 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-15",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1412, x = 0.6443, y = 0.6367 },
            to = { space = "map", uiMapID = 1413, x = 0.4192, y = 0.5862 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-16",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1449, x = 0.2931, y = 0.2236 },
            to = { space = "map", uiMapID = 1451, x = 0.8404, y = 0.1393 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-17",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1442, x = 0.8338, y = 0.9772 },
            to = { space = "map", uiMapID = 1413, x = 0.3572, y = 0.275 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-18",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1413, x = 0.4455, y = 0.8657 },
            to = { space = "map", uiMapID = 1441, x = 0.3225, y = 0.2217 },
            seconds = 45,
            costMode = "ground",
        },
        {
            id = "forever-border-19",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1441, x = 0.7419, y = 0.9334 },
            to = { space = "map", uiMapID = 1446, x = 0.5075, y = 0.2413 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-20",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1446, x = 0.2705, y = 0.5684 },
            to = { space = "map", uiMapID = 1449, x = 0.7161, y = 0.7744 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-21",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1429, x = 0.3249, y = 0.5006, z = 92 },
            to = { space = "map", uiMapID = 1453, x = 0.7333, y = 0.9069, z = 93 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-22",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1431, x = 0.4491, y = 0.7981 },
            to = { space = "map", uiMapID = 1434, x = 0.393, y = 0.0562 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-23",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1431, x = 0.8861, y = 0.4102 },
            to = { space = "map", uiMapID = 1430, x = 0.3565, y = 0.356 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-24",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1430, x = 0.5911, y = 0.4116 },
            to = { space = "map", uiMapID = 1435, x = 0.1037, y = 0.5022 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-25",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1435, x = 0.3564, y = 0.6207 },
            to = { space = "map", uiMapID = 1419, x = 0.5201, y = 0.0781 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-26",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1429, x = 0.9214, y = 0.7278 },
            to = { space = "map", uiMapID = 1433, x = 0.0431, y = 0.7186 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-27",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1433, x = 0.0188, y = 0.8962 },
            to = { space = "map", uiMapID = 1431, x = 0.9378, y = 0.1137 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-28",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1433, x = 0.4151, y = 0.0847 },
            to = { space = "map", uiMapID = 1428, x = 0.783, y = 0.776 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-29",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1433, x = 0.4404, y = 0.1101 },
            to = { space = "map", uiMapID = 2548, x = 0.1709, y = 0.6813 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-30",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 2548, x = 0.321, y = 0.3065 },
            to = { space = "map", uiMapID = 1418, x = 0.5454, y = 0.8862 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-31",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 2548, x = 0.2537, y = 0.7221 },
            to = { space = "map", uiMapID = 1433, x = 0.6722, y = 0.2101, accessKey = "redridge_road" },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-32",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1433, x = 0.9715, y = 0.6667, accessKey = "redridge_road" },
            to = { space = "map", uiMapID = 1435, x = 0.6762, y = 0.1073 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-33",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1427, x = 0.6954, y = 0.5429 },
            to = { space = "map", uiMapID = 1418, x = 0.0418, y = 0.6156 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-34",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1428, x = 0.2943, y = 0.387 },
            to = { space = "mapProjection", uiMapID = 1427, x = 0.3599, y = 1.1196 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-35",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1418, x = 0.4925, y = 0.0742 },
            to = { space = "map", uiMapID = 1432, x = 0.4683, y = 0.7775 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-36",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1426, x = 0.8015, y = 0.5259 },
            to = { space = "map", uiMapID = 1432, x = 0.2234, y = 0.7001 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-37",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1426, x = 0.8438, y = 0.3104 },
            to = { space = "map", uiMapID = 1432, x = 0.1914, y = 0.1729 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-38",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1432, x = 0.2557, y = 0.1029 },
            to = { space = "map", uiMapID = 1437, x = 0.5388, y = 0.7033 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-39",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1437, x = 0.5108, y = 0.117 },
            to = { space = "map", uiMapID = 1417, x = 0.4546, y = 0.8918 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-40",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1417, x = 0.2036, y = 0.2978 },
            to = { space = "map", uiMapID = 1424, x = 0.8216, y = 0.5708 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-41",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1424, x = 0.8439, y = 0.3227 },
            to = { space = "map", uiMapID = 1425, x = 0.1122, y = 0.5119 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-42",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1425, x = 0.2072, y = 0.4795 },
            to = { space = "map", uiMapID = 1422, x = 0.6528, y = 0.8679 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-43",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1416, x = 0.7991, y = 0.4263 },
            to = { space = "map", uiMapID = 1422, x = 0.4404, y = 0.8638 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-44",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1421, x = 0.658, y = 0.7945 },
            to = { space = "map", uiMapID = 1424, x = 0.1413, y = 0.462 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-45",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1420, x = 0.5488, y = 0.726 },
            to = { space = "map", uiMapID = 1421, x = 0.6603, y = 0.0765 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-46",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1420, x = 0.845, y = 0.7039 },
            to = { space = "map", uiMapID = 1422, x = 0.2899, y = 0.5748 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-border-47",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1426, x = 0.534, y = 0.35, z = 496 },
            to = { space = "map", uiMapID = 1455, x = 0.1616, y = 0.8458, z = 497 },
            seconds = 0,
            costMode = "ground",
        },
        {
            id = "forever-dalaran-underbelly",
            kind = "walk",
            bidirectional = true,
            from = { space = "map", uiMapID = 1416, x = 0.1808, y = 0.7187 },
            to = { space = "map", uiMapID = 1416, x = 0.1806, y = 0.7203 },
            seconds = 0,
            costMode = "ground",
        },
        Lift(
            "elevator-thunder-bluff-west",
            World(1, 1412, -1281.6, 193.9, 69),
            World(1, 1456, -1284.7, 182.1, 130),
            39
        ),
        Lift(
            "elevator-thunder-bluff-west-south",
            World(1, 1412, -1314.7, 182, 69),
            World(1, 1456, -1306.8, 177.2, 130),
            18
        ),
        Lift(
            "elevator-thunder-bluff-north",
            World(1, 1412, -1037.3, -50.5, 61),
            World(1, 1456, -1053.3, -39.4, 141),
            16
        ),
        Lift(
            "elevator-thunder-bluff-north-east",
            World(1, 1412, -1022.5, -24, 69),
            World(1, 1456, -1037.2, -25.2, 141),
            14
        ),
        Passage("passage-stormwind-deeprun-tram", World(0, 1453, -8346.46, 514.031, 92), stormwindStation, 5, alliance),
        Passage(
            "passage-ironforge-deeprun-tram",
            World(0, 1455, -4840.26, -1330.46, 502),
            ironforgeStation,
            5,
            alliance
        ),
        Passage(
            "passage-deeprun-tram-stormwind",
            stormwindExit,
            World(0, 1453, -8354.23, 524.068, 91.797),
            5,
            alliance
        ),
        Passage(
            "passage-deeprun-tram-ironforge",
            ironforgeExit,
            World(0, 1455, -4839.51, -1317.74, 501.868),
            5,
            alliance
        ),
        Tram("tram-stormwind-ironforge", stormwindBoarding, ironforgeStation),
        Tram("tram-ironforge-stormwind", ironforgeBoarding, stormwindArrival),
    },
}

-- These platform corridors are inside an instance without a terrain pack.
-- Keep them usable even when the exterior walking legs require terrain proof.
AddPassageChain(
    catalogue.connections,
    "passage-deeprun-tram-stormwind-platform",
    { stormwindExit, stormwindStation, stormwindArrival, stormwindBoarding },
    8
)
AddPassageChain(
    catalogue.connections,
    "passage-deeprun-tram-ironforge-platform",
    { ironforgeExit, ironforgeStation, ironforgeBoarding },
    8
)

AddPassageChain(catalogue.connections, "passage-undercity-gate", undercityApproach, 8)
local sewerEntry = Passage("passage-undercity-sewer-entry", undercitySewer[1], undercitySewer[2])
sewerEntry.originRadius, sewerEntry.arrivalRadius = 75, 8
catalogue.connections[#catalogue.connections + 1] = sewerEntry
local sewerExit = Passage("passage-undercity-sewer-exit", undercitySewer[2], undercitySewer[1])
sewerExit.arrivalRadius = 8
catalogue.connections[#catalogue.connections + 1] = sewerExit
AddPassageChain(catalogue.connections, "passage-undercity-sewer", undercitySewer, 8, 2)
for _, lift in ipairs(undercityLifts) do
    local side, upper, lower = lift[1], lift[2], lift[3]
    AddPassageChain(
        catalogue.connections,
        "passage-undercity-" .. side .. "-lift",
        { undercityApproach[#undercityApproach], upper },
        8
    )
    catalogue.connections[#catalogue.connections + 1] =
        Lift("elevator-undercity-" .. side .. "-surface-to-city", upper, lower, 13)
end

LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "passages", catalogue, 35)
