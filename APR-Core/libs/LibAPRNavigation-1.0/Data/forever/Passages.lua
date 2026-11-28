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

local function AddPassageChain(connections, id, points, radius, first, transitGroup)
    for index = (first or 1) + 1, #points do
        local edge = Passage(id .. ":" .. (index - 1), points[index - 1], points[index])
        edge.bidirectional, edge.arrivalRadius, edge.transitGroup = true, radius, transitGroup
        connections[#connections + 1] = edge
    end
end

-- Each platform has its own walking region inside the tram instance.
local alliance = { faction = "Alliance" }
local tramGroup = "deeprun-tram"
local ironforgeStation = World(369, 499, 69.228, 10.393, -4.297)
local stormwindStation = World(369, 499, 67.761, 2490.98, -4.296)
local ironforgeExit = World(369, 499, 76.027, 10.504, -4.297)
local stormwindExit = World(369, 499, 80.163, 2490.88, -1.857)
local ironforgeBoarding = World(369, 499, 4.6296, 28.139, -3.4569)
local stormwindBoarding = World(369, 499, 4.6294, 2510.42, -3.2704)
local stormwindArrival = World(369, 499, 45.0956, 2490.52, -4.2965)
-- The portal lips only connect to the street through the declared walks.
local stormwindEntrance = World(0, 1453, -8346.46, 514.031, 92, true)
local stormwindLanding = World(0, 1453, -8354.23, 524.068, 91.797, true)
local stormwindStreet = World(0, 1453, -8384, 580, 91.38)
local function TramPassage(id, from, to)
    local edge = Passage(id, from, to, 5, alliance)
    edge.transitGroup = tramGroup
    return edge
end

local function Tram(id, from, to)
    return {
        id = id,
        kind = "tram",
        from = from,
        to = to,
        requirements = alliance,
        transitGroup = tramGroup,
        seconds = 160,
        arrivalRadius = 16,
    }
end

local catalogue = {
    connections = {
        -- AreaTrigger 78 starts at the walkable lip of its trigger volume.
        -- AreaTrigger 119 returns to a different point outside the instance.
        Passage(
            "passage-westfall-to-deadmines",
            World(0, 1436, -11208.63, 1679.55, 24.54),
            World(36, nil, -14.5732, -385.475, 62.4561),
            5,
            { minLevel = 10 }
        ),
        Passage(
            "passage-deadmines-to-westfall",
            World(36, nil, -14.3628, -393.38, 64.5605),
            World(0, 1436, -11208.7, 1675.9, 24.5733),
            5
        ),
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
        Lift(
            "elevator-great-lift",
            World(1, 1413, -4661.428, -1836.135, 86),
            World(1, 1441, -4673.929, -1836.135, -44),
            45
        ),
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
        -- Mesa Elevator 11899 has a 30-second cycle. Both approach points
        -- are on the walking mesh beside the platform at its respective stops.
        Lift(
            "elevator-freewind-post",
            World(1, 1441, -5367.5, -2489.42, -40.962),
            World(1, 1441, -5385.2, -2485.333, 89.43),
            25
        ),
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
        TramPassage("passage-stormwind-deeprun-tram", stormwindEntrance, stormwindStation),
        TramPassage(
            "passage-ironforge-deeprun-tram",
            World(0, 1455, -4840.26, -1330.46, 502, true),
            ironforgeStation
        ),
        TramPassage("passage-deeprun-tram-stormwind", stormwindExit, stormwindLanding),
        TramPassage(
            "passage-deeprun-tram-ironforge",
            ironforgeExit,
            World(0, 1455, -4839.51, -1317.74, 501.868)
        ),
        Tram("tram-stormwind-ironforge", stormwindBoarding, ironforgeStation),
        Tram("tram-ironforge-stormwind", ironforgeBoarding, stormwindArrival),
        -- Split the terrain search at the street so the detailed tram approach
        -- can connect to routes across the city, including the harbor and taxi.
        {
            id = "walk-stormwind-tram-entrance",
            kind = "walk",
            from = stormwindStreet,
            to = stormwindEntrance,
            requirements = alliance,
            transitGroup = tramGroup,
            costMode = "ground",
        },
        {
            id = "walk-stormwind-tram-landing",
            kind = "walk",
            from = stormwindLanding,
            to = stormwindStreet,
            requirements = alliance,
            transitGroup = tramGroup,
            costMode = "ground",
        },
    },
}

-- Walking thresholds checked on both sides of the native area boundaries.
AddPassageChain(catalogue.connections, "passage-deadmines-entry-approach", {
    World(0, 1436, -11208.7, 1675.9, 24.5733),
    World(0, 1436, -11208.63, 1679.55, 24.54),
}, 3)
AddPassageChain(catalogue.connections, "passage-deadmines-exit-approach", {
    World(36, nil, -14.5732, -385.475, 62.4561),
    World(36, nil, -14.3628, -393.38, 64.5605),
}, 3)
-- The Timbermaw tunnel sits below other walkable surfaces. Follow the native
-- walking mesh through its bends and keep those nodes private to the passage.
AddPassageChain(catalogue.connections, "passage-timbermaw", {
    World(1, 1448, 7025.616, -2121.133, 586.979),
    World(1, 1448, 7001.066, -2141.067, 587.418, true),
    World(1, 1448, 7000, -2142.933, 587.951, true),
    World(1, 1448, 6999.733, -2146.667, 589.551, true),
    World(1, 1448, 7002.133, -2150.933, 592.218, true),
    World(1, 1448, 7018.399, -2163.200, 596.485, true),
    World(1, 1448, 7019.100, -2182.658, 591.317, true),
    World(1, 1448, 7006.667, -2193.600, 587.951, true),
    World(1, 1448, 7004.266, -2195.733, 587.418, true),
    World(1, 1448, 6990.667, -2216.533, 585.818, true),
    World(1, 1448, 6976, -2240, 583.151, true),
    World(1, 1448, 6967.350, -2257.983, 586.956),
    World(1, 1448, 6954.667, -2261.333, 590.618, true),
    World(1, 1448, 6937.450, -2264.308, 590.234, true),
    World(1, 1448, 6933.333, -2262.133, 590.885, true),
    World(1, 1448, 6921.600, -2274.933, 590.770, true),
    World(1, 1448, 6905.066, -2292.533, 590.770, true),
    World(1, 1448, 6904, -2293.600, 590.237, true),
    World(1, 1448, 6902.399, -2293.600, 589.704, true),
    World(1, 1452, 6896.070, -2287.630, 588.119),
}, 4)
-- The temple and its approach overlap other model surfaces. The measured
-- route follows the temple floor and ramp into the public portal courtyard.
AddPassageChain(catalogue.connections, "passage-temple-of-the-moon", {
    World(1, 1457, 9654.678, 2537.255, 1331.6),
    World(1, 1457, 9688.267, 2529.333, 1336.798, true),
    World(1, 1457, 9712.7, 2530.3, 1335.9, true),
    World(1, 1457, 9741.8, 2531.5, 1330.5, true),
    World(1, 1457, 9770, 2532.7, 1320.3, true),
    World(1, 1457, 9799.9, 2533.9, 1321.3, true),
    World(1, 1457, 9829.9, 2535.1, 1321.9, true),
    World(1, 1457, 9859.8, 2536.3, 1321.5, true),
    World(1, 1457, 9889.6, 2537.5, 1319.5, true),
    World(1, 1457, 9899.733, 2538.667, 1313.865, true),
    World(1, 1457, 9920, 2560, 1313.865, true),
    World(1, 1457, 9941.333, 2602.667, 1316.532, true),
    World(1, 1457, 9946.25, 2612.97, 1316.49),
}, 6)
-- The upper platform in the Valley of Spirits reaches the road by the ramp.
-- Its model overlaps several lower floors in the navigation grid.
AddPassageChain(catalogue.connections, "passage-orgrimmar-valley-of-spirits-ramp", {
    World(1, 1454, 1472.225, -4217.799, 43),
    World(1, 1454, 1483.8, -4220.8, 43.2, true),
    World(1, 1454, 1495.5, -4222.8, 43.7, true),
    World(1, 1454, 1506.9, -4219.8, 45, true),
    World(1, 1454, 1511.7, -4209.7, 40.3, true),
    World(1, 1454, 1519, -4202.7, 40.3),
}, 5)
-- Follow the stairs out of the Forlorn Cavern and the ramp out of the
-- Cleft of Shadow. The terrain grid also sees the streets over both caves.
AddPassageChain(catalogue.connections, "passage-ironforge-forlorn-cavern", {
    World(0, 1455, -4646.799, -1119.973, 502),
    World(0, 1455, -4652.8, -1117.333, 505.168, true),
    World(0, 1455, -4653.067, -1119.467, 506.235, true),
    World(0, 1455, -4645.6, -1123.733, 508.635, true),
    World(0, 1455, -4638.934, -1129.067, 508.101, true),
    World(0, 1455, -4632.267, -1134.4, 504.101, true),
    World(0, 1455, -4632, -1135.467, 501.435, true),
    World(0, 1455, -4644.267, -1178.133, 501.701, true),
    World(0, 1455, -4659.467, -1182.2, 501.701, true),
    World(0, 1455, -4705.067, -1194.4, 501.701, true),
    World(0, 1455, -4738.222, -1178.4, 502.057, true),
    World(0, 1455, -4779.645, -1165.956, 502.774, true),
    World(0, 1455, -4821.78, -1155.44, 502.21),
}, 5)
AddPassageChain(catalogue.connections, "passage-orgrimmar-cleft-of-shadow", {
    World(1, 1454, 1847.327, -4356.656, -14.8),
    World(1, 1454, 1840, -4352, -14.704, true),
    World(1, 1454, 1798.4, -4315.2, -11.237, true),
    World(1, 1454, 1797.067, -4314.133, -7.504, true),
    World(1, 1454, 1776.533, -4302.4, 6.096, true),
    World(1, 1454, 1744.8, -4296, 14.096, true),
    World(1, 1454, 1740.267, -4274.667, 20.763, true),
    World(1, 1454, 1765.333, -4233.066, 41.609, true),
    World(1, 1454, 1760.267, -4224.8, 43.742, true),
    World(1, 1454, 1714.733, -4236.4, 49.275, true),
    World(1, 1454, 1674.933, -4255.2, 53.876, true),
    World(1, 1454, 1674.133, -4269.2, 53.186, true),
    World(1, 1454, 1672.8, -4317.067, 59.429, true),
    World(1, 1454, 1676.21, -4315.29, 61.5292),
}, 5)
-- The Cathedral approach uses the bridge and its stairs above the canal.
AddPassageChain(catalogue.connections, "passage-stormwind-cathedral", {
    World(0, 1453, -8519.4, 836.793, 106.5),
    World(0, 1453, -8546.133, 819.733, 107.248, true),
    World(0, 1453, -8561.866, 821.6, 106.715, true),
    World(0, 1453, -8566.133, 811.2, 106.982, true),
    World(0, 1453, -8582.133, 804.533, 106.715, true),
    World(0, 1453, -8623.533, 775.534, 100.515, true),
    World(0, 1453, -8661.333, 746.667, 96.848, true),
    World(0, 1453, -8697.6, 720.267, 97.382, true),
    World(0, 1453, -8704, 725.333, 97.115, true),
    World(0, 1453, -8711.732, 726.4, 97.648, true),
    World(0, 1453, -8713.066, 726.4, 100.315, true),
    World(0, 1453, -8739.732, 711.2, 98.982, true),
    World(0, 1453, -8771.199, 668.8, 103.515, true),
    World(0, 1453, -8764.266, 618.667, 98.982, true),
    World(0, 1453, -8789.066, 592.8, 97.382, true),
    World(0, 1453, -8824.932, 550.8, 95.915, true),
    World(0, 1453, -8849.066, 528.267, 106.448, true),
    World(0, 1453, -8855.732, 534.133, 106.448, true),
    World(0, 1453, -8863.466, 532.533, 106.982, true),
    World(0, 1453, -8853.333, 512, 109.648, true),
    World(0, 1453, -8832.77, 478.62, 109.62),
}, 5)
-- The tram's arrival and departure triggers sit at different points on
-- the Forge approach. Give both directions a verified link to the city.
AddPassageChain(catalogue.connections, "passage-ironforge-tram-approach", {
    World(0, 1455, -4840.26, -1330.46, 502, true),
    World(0, 1455, -4829.867, -1288.267, 501.985),
    World(0, 1455, -4800, -1280, 501.968, true),
    World(0, 1455, -4748.533, -1265.6, 501.701, true),
    World(0, 1455, -4743.333, -1252.133, 501.701, true),
    World(0, 1455, -4727.733, -1211.733, 501.701, true),
    World(0, 1455, -4752, -1173.333, 502.235, true),
    World(0, 1455, -4779.645, -1165.956, 502.774, true),
    World(0, 1455, -4821.78, -1155.44, 502.21),
}, 5, nil, tramGroup)
AddPassageChain(catalogue.connections, "passage-ironforge-tram-arrival-approach", {
    World(0, 1455, -4839.51, -1317.74, 501.868),
    World(0, 1455, -4829.867, -1288.267, 501.985),
}, 5, nil, tramGroup)
-- The bridge and ramp from Spirit Rise cross terrain below the same XY.
-- The path rejoins the regular terrain graph at the foot of the tower.
AddPassageChain(catalogue.connections, "passage-thunder-bluff-spirit-rise", {
    World(1, 1456, -1000.3, 211.892, 136.2),
    World(1, 1456, -1012.5, 201.7, 136.6, true),
    World(1, 1456, -1024.9, 191.6, 136.4, true),
    World(1, 1456, -1038.4, 183.8, 139.6, true),
    World(1, 1456, -1050.3, 173.8, 138.9, true),
    World(1, 1456, -1062.3, 163.3, 139.6, true),
    World(1, 1456, -1074.3, 152.7, 140.1, true),
    World(1, 1456, -1085.4, 142.7, 143.9, true),
    World(1, 1456, -1096.9, 132.4, 147.4, true),
    World(1, 1456, -1107.8, 122.5, 152.6, true),
    World(1, 1456, -1111, 108.3, 152.1, true),
    World(1, 1456, -1119.7, 96.7, 148, true),
    World(1, 1456, -1124.3, 82.4, 143.6, true),
    World(1, 1456, -1126.3, 67.2, 143, true),
    World(1, 1456, -1139.5, 58.5, 144.9, true),
    World(1, 1456, -1152.7, 49.7, 145.1),
}, 5)
AddPassageChain(catalogue.connections, "passage-darkwhisper-gorge-hyjal", {
    World(1, 1452, 4802.083, -3967.812, 1020.261),
    World(1, 2482, 4802.083, -3965.521, 1020.408),
}, 6)
AddPassageChain(catalogue.connections, "passage-valley-of-bones-north", {
    World(1, 1443, -1965.521, 1352.084, 63.629),
    World(1, 2652, -1967.812, 1352.084, 63.632),
}, 6)
AddPassageChain(catalogue.connections, "passage-valley-of-bones-west", {
    World(1, 1443, -2165.521, 1547.917, 75.662),
    World(1, 2652, -2167.812, 1547.917, 75.852),
}, 6)
AddPassageChain(catalogue.connections, "passage-bristleback-retreat-mulgore", {
    World(1, 1412, -2193.749, 398.854, 186.600),
    World(1, 2652, -2193.749, 401.147, 186.611),
}, 6)
AddPassageChain(catalogue.connections, "passage-bristle-hills-burning-steppes", {
    World(0, 1428, -8565.521, -2793.749, 252.328),
    World(0, 2548, -8567.812, -2793.749, 252.234),
}, 6)

-- These platform corridors are inside an instance without a terrain pack.
-- Keep them usable even when the exterior walking legs require terrain proof.
AddPassageChain(
    catalogue.connections,
    "passage-deeprun-tram-stormwind-platform",
    { stormwindExit, stormwindStation, stormwindArrival, stormwindBoarding },
    8, nil, tramGroup
)
AddPassageChain(
    catalogue.connections,
    "passage-deeprun-tram-ironforge-platform",
    { ironforgeExit, ironforgeStation, ironforgeBoarding },
    8, nil, tramGroup
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

LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "passages", catalogue, 43)
