if APR.Faction == "Horde" then
    APR.RouteQuestStepList["118-Allied_Icecrown Citadel"] = {
        {
            PickUp = { 58877 },
            Coord = { x = -2123.4, y = 429 },
            _index = 1,
        },
        {
            Qpart = { [58877] = { 1 } },
            Coord = { x = -2123.4, y = 429 },
            Range = 0.5,
            _index = 2,
        },
        {
            Done = { 58877 },
            Coord = { x = -2123.4, y = 429 },
            _index = 3,
        },
        {
            PickUp = { 58903 },
            Coord = { x = -2123.4, y = 429 },
            _index = 4,
        },
        {
            Qpart = { [58903] = { 1 } },
            Coord = { x = -2126.8, y = 467.7 },
            Range = 0.5,
            Gossip = 1,
            _index = 5,
        },
        {
            Qpart = { [58903] = { 2 } },
            Coord = { x = -2124.7, y = 529 },
            ExtraLineText = "USE_PORTAL",
            Range = 0.5,
            _index = 6,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4369.5, y = 1389.5 },
            Range = 15,
            Zone = 1,
            _index = 7,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4420.7, y = 1447.8 },
            Range = 15,
            Zone = 85,
            _index = 8,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4409.3, y = 1526.3 },
            Range = 15,
            Zone = 85,
            _index = 9,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4281.5, y = 1616.3 },
            Range = 15,
            Zone = 85,
            _index = 10,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4270.4, y = 1639.8 },
            Range = 15,
            Zone = 85,
            _index = 11,
        },
        {
            Waypoint = 58903,
            Coord = { x = -4264.5, y = 1607.6 },
            Range = 15,
            Zone = 85,
            _index = 12,
        },
        {
            Qpart = { [58903] = { 4 } },
            Coord = { x = -4370.2, y = 1600 },
            Range = 0.5,
            Zone = 85,
            _index = 13,
        },
        {
            Done = { 58903 },
            Coord = { x = -4370.2, y = 1600 },
            Zone = 85,
            _index = 14,
        },
        {
            RouteCompleted = true,
            _index = 15,
        },
    }
end
