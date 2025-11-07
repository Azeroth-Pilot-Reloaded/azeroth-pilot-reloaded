if APR.Faction == "Alliance" then
    APR.RouteQuestStepList["84-Intro-Legion"] = {
        {
            PickUp = { 40519 },
            ChromiePick = 10,
            coord = { x = 745.5, y = -8196.3 },
            GossipOptionIDs = { 51901, 51902 },
            Zone = 84,
            _index = 1
        },
        {
            Done = { 40519 },
            coord = { x = 1079.2, y = -8494.9 },
            Zone = 84,
            _index = 2
        },
        {
            PickUp = { 42782 },
            coord = { x = 1079.2, y = -8494.9 },
            Zone = 84,
            _index = 3
        },
        {
            Qpart = { [42782] = { 1 } },
            coord = { x = 1205.6, y = -8493.5 },
            Range = 1,
            Zone = 84,
            _index = 4
        },
        {
            Qpart = { [42782] = { 2 } },
            coord = { x = 1202.2, y = -8390.2 },
            Range = 1,
            Zone = 84,
            _index = 5
        },
        {
            Qpart = { [42782] = { 3 } },
            coord = { x = 1206.9, y = -8347 },
            Range = 2,
            Zone = 84,
            _index = 6
        },
        {
            Qpart = { [42782] = { 4 } },
            coord = { x = 1144.8, y = -8377.8 },
            ExtraLineText = "TALK_NPC",
            GossipOptionIDs = { 45729 },
            RaidIcon = 108747,
            Zone = 84,
            _index = 7
        },
        {
            Done = { 42782 },
            coord = { x = 1392.9, y = -8302.4 },
            Zone = 84,
            _index = 8
        },
        {
            PickUp = { 42740 },
            coord = { x = 1392.9, y = -8302.4 },
            Zone = 84,
            _index = 9
        },
        {
            Qpart = { [42740] = { 1 } },
            coord = { x = 1377.2, y = -8336.8 },
            ExtraLineText = "NPC_TELEPORT",
            GossipOptionIDs = { 45838 },
            InstanceQuest = true,
            RaidIcon = 108920,
            Zone = 84,
            _index = 10
        },
        {
            Scenario = { criteriaID = 27653, criteriaIndex = 1, scenarioID = 786, stepID = 1522 },
            coord = { x = 2077.9, y = 511.8 },
            Range = 30,
            InstanceQuest = true,
            Zone = 619,
            _index = 11
        },
        {
            Scenario = { criteriaID = 29377, criteriaIndex = 2, scenarioID = 786, stepID = 1522 },
            coord = { x = 2077.9, y = 511.8 },
            Range = 30,
            InstanceQuest = true,
            Zone = 619,
            _index = 12
        },
        {
            Scenario = { criteriaID = 27619, criteriaIndex = 3, scenarioID = 786, stepID = 1522 },
            coord = { x = 2077.9, y = 511.8 },
            Range = 30,
            InstanceQuest = true,
            Zone = 619,
            _index = 13
        },
        {
            Scenario = { criteriaID = 30883, criteriaIndex = 1, scenarioID = 786, stepID = 2685 },
            coord = { x = 2078.2, y = 508.1 },
            Range = 5,
            InstanceQuest = true,
            Zone = 619,
            _index = 14
        },
        {
            Scenario = { criteriaID = 28017, criteriaIndex = 1, scenarioID = 786, stepID = 1589 },
            coord = { x = 2477.1, y = 1121.7 },
            Range = 5,
            InstanceQuest = true,
            Zone = 619,
            _index = 15
        },
        {
            Scenario = { criteriaID = 27940, criteriaIndex = 1, scenarioID = 786, stepID = 1532 },
            coord = { x = 2146.6, y = 1412.8 },
            Range = 100,
            InstanceQuest = true,
            Zone = 619,
            _index = 16
        },
        {
            Waypoint = 42740,
            coord = { x = 1806, y = 1496.1 },
            Range = 5,
            InstanceQuest = true,
            Zone = 619,
            _index = 17
        },
        {
            Scenario = { criteriaID = 29715, criteriaIndex = 1, scenarioID = 786, stepID = 1506 },
            coord = { x = 1806, y = 1496.1 },
            Range = 5,
            InstanceQuest = true,
            Zone = 619,
            _index = 18
        },
        {
            Scenario = { criteriaID = 28055, criteriaIndex = 1, scenarioID = 786, stepID = 1761 },
            coord = { x = 1806.2, y = 1495.5 },
            Range = 10,
            InstanceQuest = true,
            Zone = 619,
            _index = 19
        },
        {
            Scenario = { criteriaID = 29714, criteriaIndex = 1, scenarioID = 786, stepID = 2084 },
            coord = { x = 1696.5, y = 1626.7 },
            Range = 30,
            InstanceQuest = true,
            Zone = 619,
            _index = 20
        },
        {
            Done = { 42740 },
            coord = { x = 1373.8, y = -8400 },
            Zone = 84,
            _index = 21
        },
        {
            PickUp = { 40517 },
            coord = { x = 1373.8, y = -8400 },
            Zone = 84,
            _index = 22
        },
        {
            Qpart = { [40517] = { 1 } },
            coord = { x = 1352.8, y = -8386.4 },
            Range = 1,
            Zone = 84,
            _index = 23
        },
        {
            Qpart = { [40517] = { 2 } },
            coord = { x = 230.8, y = -8362.1 },
            GossipOptionIDs = { 45042 },
            ETA = 105,
            Zone = 84,
            _index = 24
        },
        {
            Done = { 40517 },
            coord = { x = 230.8, y = -8362.1 },
            Zone = 84,
            _index = 25
        },
        {
            PickUp = { 40593 },
            coord = { x = 240.4, y = -8369.6 },
            Zone = 84,
            _index = 26
        },
        {
            Qpart = { [40593] = { 1 } },
            coord = { x = 240.4, y = -8369.6 },
            GossipOptionIDs = { 44945 },
            Zone = 84,
            _index = 27
        },
        {
            Qpart = { [40593] = { 3 } },
            coord = { x = 290.2, y = -8319 },
            Fillers = { [40593] = { 2 } },
            Range = 2,
            Zone = 84,
            _index = 28
        },
        {
            Qpart = { [40593] = { 2 } },
            coord = { x = 253.3, y = -8366.2 },
            Range = 30,
            Zone = 84,
            _index = 29
        },
        {
            Done = { 40593 },
            coord = { x = 233.2, y = -8363.8 },
            Zone = 84,
            _index = 30
        },
        {
            PickUp = { 44120 },
            coord = { x = 233.2, y = -8363.8 },
            Zone = 84,
            _index = 31
        },
        {
            Done = { 44120 },
            coord = { x = 1023.4, y = -8895.9 },
            Zone = 84,
            _index = 32
        },
        {
            PickUp = { 44663 },
            coord = { x = 1023.4, y = -8895.9 },
            Zone = 84,
            _index = 33
        },
        {
            Waypoint = 44663,
            coord = { x = 864.2, y = -9001.4 },
            ExtraLineText = "INSIDE_TOWER",
            Range = 5,
            Zone = 84,
            _index = 34
        },
        {
            Qpart = { [44663] = { 1 } },
            coord = { x = 871.5, y = -9010.1 },
            GossipOptionIDs = { 51032 },
            Zone = 84,
            _index = 35
        },
        {
            Waypoint = 44663,
            coord = { x = -2046.1, y = -11076.5 },
            Range = 5,
            Zone = 42,
            _index = 36
        },
        {
            Qpart = { [44663] = { 2 } },
            coord = { x = -2025.2, y = -11112.2 },
            GossipOptionIDs = { 45530 },
            Zone = 42,
            _index = 37
        },
        {
            Done = { 44663 },
            coord = { x = 4398.8, y = -834.2 },
            Zone = 627,
            _index = 38
        },
        {
            RouteCompleted = 1,
            _index = 39
        }
    }

    APR.RouteQuestStepList["634-Stormheim"] = {
        {
            Done = { 39800 },
            coord = { x = 3078.1, y = 3204.6 },
            _index = 1
        },
        {
            PickUp = { 38558, 38053, 38052, 38036 },
            coord = { x = 3079.5, y = 3210.1 },
            _index = 2
        },
        {
            Qpart = { [38053] = { 1 } },
            coord = { x = 2984.6, y = 3085.6 },
            Fillers = { [38036] = { 1 }, [38052] = { 1 } },
            Range = 0.69,
            _index = 3
        },
        {
            Qpart = { [38558] = { 1 } },
            coord = { x = 3081.4, y = 2963.6 },
            Fillers = { [38036] = { 1 }, [38052] = { 1 } },
            Range = 0.69,
            _index = 4
        },
        {
            Qpart = { [38036] = { 1 }, [38052] = { 1 } },
            coord = { x = 3041.5, y = 3123.3 },
            Range = 75.5,
            _index = 5
        },
        {
            Done = { 38558, 38053, 38052 },
            coord = { x = 3081.4, y = 3208.1 },
            _index = 6
        },
        {
            Done = { 38036 },
            coord = { x = 3074.6, y = 3214 },
            _index = 7
        },
        {
            PickUp = { 38058, 38057 },
            coord = { x = 3079.3, y = 3212.1 },
            _index = 8
        },
        {
            Waypoint = 38057,
            coord = { x = 3191.1, y = 3131.9 },
            Range = 46.95,
            _index = 9
        },
        {
            Waypoint = 38057,
            coord = { x = 3214.5, y = 2953.5 },
            Range = 21.39,
            _index = 10
        },
        {
            Done = { 38057 },
            coord = { x = 3224.1, y = 2935.8 },
            _index = 11
        },
        {
            PickUp = { 38059 },
            coord = { x = 3224.1, y = 2935.8 },
            _index = 12
        },
        {
            Qpart = { [38058] = { 1 }, [38059] = { 1 } },
            coord = { x = 3317.5, y = 2854.1 },
            Range = 46.49,
            _index = 13
        },
        {
            Done = { 38058 },
            coord = { x = 3291.6, y = 3048.1 },
            _index = 14
        },
        {
            PickUp = { 38060 },
            coord = { x = 3291.6, y = 3048.1 },
            _index = 15
        },
        {
            Done = { 38059 },
            coord = { x = 3294.5, y = 3045.4 },
            _index = 16
        },
        {
            Qpart = { [38060] = { 1 } },
            coord = { x = 3154.6, y = 3248.1 },
            Range = 18.43,
            _index = 17
        },
        {
            Qpart = { [38060] = { 2 } },
            coord = { x = 3156.4, y = 3249.1 },
            Range = 19.96,
            _index = 18
        },
        {
            Done = { 38060 },
            coord = { x = 3072.4, y = 3397.1 },
            _index = 19
        },
        {
            PickUp = { 38210 },
            coord = { x = 3073, y = 3405.9 },
            _index = 20
        },
        {
            PickUp = { 39775 },
            coord = { x = 3073, y = 3405.9 },
            _index = 21
        },
        {
            Done = { 38210 },
            coord = { x = 2529.3, y = 3276 },
            _index = 22
        },
        {
            PickUp = { 38331 },
            coord = { x = 2529.3, y = 3276 },
            _index = 23
        },
        {
            Qpart = { [38331] = { 1, 3, 2 } },
            coord = { x = 2529.3, y = 3276 },
            Range = 36.53,
            _index = 24
        },
        {
            Done = { 38331 },
            coord = { x = 2529.3, y = 3276 },
            _index = 25
        },
        {
            PickUp = { 39590 },
            coord = { x = 2529.3, y = 3276 },
            _index = 26
        },
        {
            Qpart = { [39590] = { 3 } },
            DroppableQuest = { MobId = 96236, Qid = 39595, Text = "Mightstone Savage" },
            coord = { x = 2403.8, y = 3321.1 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 27
        },
        {
            Qpart = { [39590] = { 2 } },
            DroppableQuest = { MobId = 96236, Qid = 39595, Text = "Mightstone Savage" },
            coord = { x = 2585.8, y = 3394 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 28
        },
        {
            Qpart = { [39590] = { 1 } },
            DroppableQuest = { MobId = 96236, Qid = 39595, Text = "Mightstone Savage" },
            coord = { x = 2434.9, y = 3603.6 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 29
        },
        {
            DropQuest = 39595,
            DroppableQuest = { MobId = 96236, Qid = 39595, Text = "Mightstone Savage" },
            coord = { x = 2459.6, y = 3581 },
            Fillers = { [38442] = { 1 } },
            _index = 30
        },
        {
            Qpart = { [39595] = { 1 } },
            coord = { x = 2456.3, y = 3561.8 },
            Fillers = { [38442] = { 1 } },
            Range = 91.91,
            _index = 31
        },
        {
            Done = { 39590, 39595 },
            coord = { x = 2323.1, y = 3457 },
            _index = 32
        },
        {
            PickUp = { 39593, 39592, 39591 },
            coord = { x = 2323.1, y = 3457 },
            _index = 33
        },
        {
            Qpart = { [39593] = { 4 } },
            coord = { x = 2210.1, y = 3565.3 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 34
        },
        {
            Qpart = { [39591] = { 1 } },
            coord = { x = 2103.6, y = 3443.4 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 35
        },
        {
            Qpart = { [39593] = { 2 } },
            coord = { x = 2177.1, y = 3412.8 },
            Fillers = { [38442] = { 1 } },
            Range = 0.69,
            _index = 36
        },
        {
            Waypoint = 39592,
            coord = { x = 2157.6, y = 3350.1 },
            Range = 32.3,
            _index = 37
        },
        {
            Qpart = { [39593] = { 1 } },
            coord = { x = 2246.3, y = 3340.6 },
            Fillers = { [38442] = { 1 } },
            Range = 0.75,
            _index = 38
        },
        {
            Qpart = { [39592] = { 1 } },
            coord = { x = 2209.9, y = 3333.6 },
            Range = 0.75,
            _index = 39
        },
        {
            Qpart = { [39593] = { 3 } },
            coord = { x = 2202.9, y = 3391.6 },
            Fillers = { [38442] = { 1 } },
            Range = 0.69,
            _index = 40
        },
        {
            Qpart = { [38442] = { 1 } },
            coord = { x = 2215.1, y = 3406.5 },
            Range = 75.14,
            _index = 41
        },
        {
            Done = { 39593, 39592, 39591 },
            coord = { x = 2322.1, y = 3457.1 },
            _index = 42
        },
        {
            PickUp = { 39594 },
            coord = { x = 2323.6, y = 3457.6 },
            _index = 43
        },
        {
            Waypoint = 39594,
            coord = { x = 2267.3, y = 3446.5 },
            Range = 15.3,
            _index = 44
        },
        {
            Waypoint = 39594,
            coord = { x = 2175.9, y = 3452.9 },
            Range = 18.81,
            _index = 45
        },
        {
            Qpart = { [39594] = { 1 } },
            coord = { x = 2163.8, y = 3544.1 },
            Range = 0.75,
            _index = 46
        },
        {
            Qpart = { [39594] = { 2 } },
            coord = { x = 2166.4, y = 3507.3 },
            Range = 0.75,
            _index = 47
        },
        {
            Waypoint = 39594,
            coord = { x = 2188.1, y = 3445.5 },
            Range = 16.39,
            _index = 48
        },
        {
            Done = { 39594 },
            coord = { x = 2347.1, y = 3443.1 },
            _index = 49
        },
        {
            PickUp = { 39597 },
            coord = { x = 2344.8, y = 3443.6 },
            _index = 50
        },
        {
            Qpart = { [39597] = { 1 } },
            coord = { x = 2344.8, y = 3443.6 },
            Range = 0.75,
            Gossip = 1,
            _index = 51
        },
        {
            Done = { 39597 },
            coord = { x = 2529.3, y = 3276 },
            _index = 52
        },
        {
            PickUp = { 38473 },
            coord = { x = 2529.3, y = 3276 },
            _index = 53
        },
        {
            Waypoint = 38473,
            coord = { x = 2548.4, y = 2892.8 },
            Range = 66.24,
            _index = 54
        },
        {
            Done = { 38473 },
            coord = { x = 2865.1, y = 2707.4 },
            _index = 55
        },
        {
            PickUp = { 38312 },
            coord = { x = 2865.6, y = 2707.6 },
            _index = 56
        },
        {
            Done = { 38312 },
            coord = { x = 2596.1, y = 2683.3 },
            _index = 57
        },
        {
            PickUp = { 38318, 38405 },
            coord = { x = 2596.1, y = 2683.3 },
            _index = 58
        },
        {
            Qpart = { [38318] = { 1 } },
            coord = { x = 2546.4, y = 2668.9 },
            Range = 0.75,
            _index = 59
        },
        {
            Qpart = { [38405] = { 3 } },
            coord = { x = 2387.1, y = 2604.8 },
            Fillers = { [38374] = { 1 } },
            Range = 0.69,
            _index = 60
        },
        {
            Qpart = { [38405] = { 1 } },
            coord = { x = 2488, y = 2595.6 },
            Fillers = { [38374] = { 1 } },
            Range = 0.69,
            _index = 61
        },
        {
            Qpart = { [38405] = { 2 } },
            coord = { x = 2602.6, y = 2536.5 },
            Fillers = { [38374] = { 1 } },
            Range = 0.69,
            _index = 62
        },
        {
            Done = { 38318, 38405 },
            coord = { x = 2492.8, y = 2538.6 },
            Fillers = { [38374] = { 1 } },
            _index = 63
        },
        {
            PickUp = { 38410 },
            coord = { x = 2492.1, y = 2537.6 },
            _index = 64
        },
        {
            Qpart = { [38410] = { 1 } },
            coord = { x = 2489.6, y = 2532.8 },
            Fillers = { [38374] = { 1 } },
            Range = 66.87,
            _index = 65
        },
        {
            Done = { 38410 },
            coord = { x = 2349, y = 2454.6 },
            Fillers = { [38374] = { 1 } },
            _index = 66
        },
        {
            PickUp = { 38342 },
            coord = { x = 2350.8, y = 2455 },
            _index = 67
        },
        {
            Qpart = { [38342] = { 1 } },
            coord = { x = 2348.1, y = 2388.1 },
            Fillers = { [38374] = { 1 } },
            Range = 0.69,
            _index = 68
        },
        {
            Qpart = { [38374] = { 1 } },
            coord = { x = 2339, y = 2405.8 },
            Range = 72.66,
            _index = 69
        },
        {
            Qpart = { [38342] = { 2 } },
            coord = { x = 2385.1, y = 2356 },
            Range = 0.75,
            _index = 70
        },
        {
            Done = { 38342 },
            coord = { x = 2385.1, y = 2356 },
            _index = 71
        },
        {
            PickUp = { 38412 },
            coord = { x = 2385.1, y = 2356 },
            _index = 72
        },
        {
            Qpart = { [38412] = { 1 } },
            coord = { x = 2343.8, y = 2299.1 },
            Range = 0.69,
            _index = 73
        },
        {
            Qpart = { [38412] = { 2 } },
            coord = { x = 2438.3, y = 2180.4 },
            Range = 0.75,
            _index = 74
        },
        {
            Done = { 38412 },
            coord = { x = 2435.8, y = 2181 },
            _index = 75
        },
        {
            PickUp = { 38414, 38413, 40568 },
            coord = { x = 2435.8, y = 2181 },
            _index = 76
        },
        {
            Qpart = { [38413] = { 2 } },
            coord = { x = 2374.8, y = 2134.5 },
            Fillers = { [40568] = { 1 } },
            Range = 0.75,
            _index = 77
        },
        {
            Waypoint = 38413,
            coord = { x = 2193.1, y = 2096.3 },
            Fillers = { [40568] = { 1 } },
            Range = 21.56,
            _index = 78
        },
        {
            Qpart = { [38413] = { 1 } },
            coord = { x = 2187.1, y = 2037.5 },
            Fillers = { [40568] = { 1 } },
            Range = 0.69,
            _index = 79
        },
        {
            Waypoint = 38413,
            coord = { x = 2191.3, y = 2080.5 },
            Fillers = { [40568] = { 1 } },
            Range = 11.62,
            _index = 80
        },
        {
            Qpart = { [38413] = { 4 } },
            coord = { x = 2383.6, y = 2003.9 },
            Fillers = { [40568] = { 1 } },
            Range = 0.75,
            _index = 81
        },
        {
            Qpart = { [38413] = { 3 } },
            coord = { x = 2474.4, y = 2058.4 },
            Fillers = { [40568] = { 1 } },
            Range = 0.75,
            _index = 82
        },
        {
            Qpart = { [40568] = { 1 } },
            coord = { x = 2472.6, y = 2058.5 },
            Range = 63.79,
            _index = 83
        },
        {
            Waypoint = 40568,
            coord = { x = 2566, y = 2011.2 },
            Range = 19.95,
            _index = 84
        },
        {
            Qpart = { [38414] = { 1, 2 } },
            coord = { x = 2604.5, y = 2023.8 },
            Range = 0.75,
            _index = 85
        },
        {
            Waypoint = 40568,
            coord = { x = 2556.4, y = 2009.9 },
            Range = 16.09,
            _index = 86
        },
        {
            Done = { 38414, 38413, 40568 },
            coord = { x = 2551, y = 1979.7 },
            _index = 87
        },
        {
            PickUp = { 39652 },
            coord = { x = 2551.3, y = 1979.3 },
            _index = 88
        },
        {
            Qpart = { [39652] = { 1 } },
            coord = { x = 2550.8, y = 1980 },
            Range = 0.75,
            Gossip = 1,
            _index = 89
        },
        {
            Qpart = { [39652] = { 2 } },
            coord = { x = 2662, y = 2045.2 },
            Range = 0.75,
            Gossip = 1,
            _index = 90
        },
        {
            Done = { 39652 },
            coord = { x = 2663.4, y = 2045.3 },
            _index = 91
        },
        {
            PickUp = { 38624 },
            coord = { x = 2662.1, y = 2044.5 },
            _index = 92
        },
        {
            Qpart = { [38624] = { 1 } },
            coord = { x = 2641.3, y = 2083 },
            Range = 0.75,
            _index = 93
        },
        {
            Qpart = { [38624] = { 2 } },
            coord = { x = 2583.3, y = 2052.6 },
            Range = 54.27,
            _index = 94
        },
        {
            Done = { 38624 },
            coord = { x = 2247.6, y = 3068 },
            _index = 95
        },
        {
            PickUp = { 39803 },
            coord = { x = 2248, y = 3065.8 },
            _index = 96
        },
        {
            Done = { 39803 },
            coord = { x = 1544.2, y = 3215.3 },
            _index = 97
        },
        {
            PickUp = { 39804 },
            coord = { x = 1544, y = 3215.1 },
            _index = 98
        },
        {
            Qpart = { [39804] = { 1 } },
            coord = { x = 1513.7, y = 3189.1 },
            Range = 0.69,
            _index = 99
        },
        {
            Done = { 39804 },
            coord = { x = 1543.5, y = 3214.6 },
            _index = 100
        },
        {
            PickUp = { 39796 },
            coord = { x = 1543.9, y = 3214.1 },
            _index = 101
        },
        {
            Done = { 39796 },
            coord = { x = 1062, y = 3075.1 },
            _index = 102
        },
        {
            PickUp = { 39788, 38778 },
            coord = { x = 1062, y = 3075.1 },
            _index = 103
        },
        {
            Qpart = { [38778] = { 1 }, [39788] = { 1, 2 } },
            coord = { x = 1121.4, y = 3002.4 },
            Range = 42.36,
            _index = 104
        },
        {
            Done = { 38778, 39788 },
            coord = { x = 1061.8, y = 3075.9 },
            _index = 105
        },
        {
            PickUp = { 38808, 38810 },
            coord = { x = 1061.7, y = 3075.9 },
            _index = 106
        },
        {
            Qpart = { [38808] = { 1 }, [38810] = { 1 } },
            coord = { x = 973, y = 3088.6 },
            Range = 33.3,
            _index = 107
        },
        {
            Done = { 38808, 38810 },
            coord = { x = 1059.4, y = 3074.9 },
            _index = 108
        },
        {
            PickUp = { 38811, 39791 },
            coord = { x = 1059.4, y = 3074.9 },
            _index = 109
        },
        {
            Qpart = { [38811] = { 2 } },
            coord = { x = 1273.2, y = 3376.9 },
            Fillers = { [39791] = { 1 } },
            Button = { ["39791-1"] = 128772 },
            Range = 0.75,
            _index = 110
        },
        {
            Qpart = { [38811] = { 3 } },
            coord = { x = 1154.4, y = 3407.6 },
            Fillers = { [39791] = { 1 } },
            Button = { ["39791-1"] = 128772 },
            Range = 0.69,
            _index = 111
        },
        {
            Qpart = { [38811] = { 1 } },
            coord = { x = 1114.8, y = 3514.1 },
            Fillers = { [39791] = { 1 } },
            Button = { ["39791-1"] = 128772 },
            Range = 0.75,
            _index = 112
        },
        {
            Qpart = { [39791] = { 1 } },
            coord = { x = 1114.8, y = 3514.1 },
            Button = { ["39791-1"] = 128772 },
            Range = 74.35,
            _index = 113
        },
        {
            Done = { 38811, 39791 },
            coord = { x = 1079.8, y = 3293.1 },
            _index = 114
        },
        {
            PickUp = { 38816, 38817 },
            coord = { x = 1079.8, y = 3293.1 },
            _index = 115
        },
        {
            PickUp = { 38823 },
            coord = { x = 984.5, y = 3408 },
            _index = 116
        },
        {
            Qpart = { [38816] = { 1 }, [38817] = { 1 }, [38823] = { 1 } },
            coord = { x = 965.7, y = 3468 },
            Range = 51.58,
            _index = 117
        },
        {
            Done = { 38816, 38817, 38823 },
            coord = { x = 978.2, y = 3416.9 },
            _index = 118
        },
        {
            PickUp = { 38815 },
            coord = { x = 978.2, y = 3416.9 },
            _index = 119
        },
        {
            Qpart = { [38815] = { 1 } },
            coord = { x = 888.4, y = 3532.9 },
            Range = 0.75,
            _index = 120
        },
        {
            Done = { 38815 },
            coord = { x = 888.7, y = 3532.8 },
            _index = 121
        },
        {
            PickUp = { 38818 },
            coord = { x = 888.7, y = 3532.8 },
            _index = 122
        },
        {
            Waypoint = 38818,
            coord = { x = 799.6, y = 3568.6 },
            Range = 24.18,
            _index = 123
        },
        {
            Qpart = { [38818] = { 1 } },
            coord = { x = 791.9, y = 3626.8 },
            Range = 0.75,
            _index = 124
        },
        {
            Done = { 38818 },
            coord = { x = 358.8, y = 342.6 },
            _index = 125
        },
        {
            PickUp = { 39837 },
            coord = { x = 359.2, y = 342.6 },
            _index = 126
        },
        {
            Qpart = { [39837] = { 1 } },
            coord = { x = 412.6, y = 365 },
            Fillers = { [38343] = { 1 } },
            Range = 0.75,
            _index = 127
        },
        {
            Done = { 39837 },
            coord = { x = 370, y = 370.1 },
            _index = 128
        },
        {
            PickUp = { 38339, 38324 },
            coord = { x = 369.1, y = 371.3 },
            _index = 129
        },
        {
            Qpart = { [38324] = { 1 }, [38339] = { 1 } },
            coord = { x = 411.6, y = 445.7 },
            Fillers = { [38343] = { 1 } },
            Range = 56.22,
            _index = 130
        },
        {
            Done = { 38339, 38324 },
            coord = { x = 368.8, y = 372.2 },
            _index = 131
        },
        {
            Waypoint = 38347,
            coord = { x = 480.1, y = 449.8 },
            Range = 15.08,
            _index = 132
        },
        {
            Waypoint = 38347,
            coord = { x = 523.7, y = 446 },
            Range = 11.65,
            _index = 133
        },
        {
            Waypoint = 38347,
            coord = { x = 565.1, y = 452.7 },
            Range = 11.12,
            _index = 134
        },
        {
            Done = { 38347 },
            coord = { x = 580.2, y = 456.5 },
            _index = 135
        },
        {
            PickUp = { 39848 },
            coord = { x = 580.2, y = 456.5 },
            _index = 136
        },
        {
            Waypoint = 39848,
            coord = { x = 695.9, y = 446.1 },
            Range = 14.1,
            _index = 137
        },
        {
            Qpart = { [39848] = { 1 } },
            coord = { x = 720, y = 487.8 },
            Range = 0.69,
            _index = 138
        },
        {
            Qpart = { [39848] = { 2 } },
            coord = { x = 721.7, y = 490.3 },
            Range = 0.69,
            Gossip = 1,
            _index = 139
        },
        {
            Done = { 39848 },
            coord = { x = 721.5, y = 490 },
            _index = 140
        },
        {
            PickUp = { 39857 },
            coord = { x = 721.5, y = 490 },
            _index = 141
        },
        {
            Done = { 39857 },
            coord = { x = 574.7, y = 328.7 },
            Fillers = { [38343] = { 1 } },
            _index = 142
        },
        {
            PickUp = { 39849 },
            coord = { x = 574.7, y = 328.7 },
            _index = 143
        },
        {
            Waypoint = 39849,
            coord = { x = 767, y = 338.5 },
            Range = 17.99,
            _index = 144
        },
        {
            Waypoint = 39849,
            coord = { x = 839.6, y = 278.6 },
            Range = 12.1,
            _index = 145
        },
        {
            Qpart = { [39849] = { 1 } },
            coord = { x = 862.1, y = 230.6 },
            Fillers = { [38343] = { 1 } },
            Range = 0.75,
            _index = 146
        },
        {
            Done = { 39849 },
            coord = { x = 573.4, y = 328 },
            Fillers = { [38343] = { 1 } },
            _index = 147
        },
        {
            PickUp = { 39851, 39850 },
            coord = { x = 575, y = 328.7 },
            _index = 148
        },
        {
            Qpart = { [39850] = { 1 } },
            coord = { x = 378.3, y = 231.9 },
            Fillers = { [38343] = { 1 }, [39851] = { 1 } },
            Range = 0.75,
            _index = 149
        },
        {
            Waypoint = 39850,
            coord = { x = 530.2, y = 138 },
            Range = 13.81,
            _index = 150
        },
        {
            Qpart = { [39850] = { 2 } },
            coord = { x = 451.3, y = 110.3 },
            Fillers = { [38343] = { 1 }, [39851] = { 1 } },
            Range = 0.75,
            _index = 151
        },
        {
            Qpart = { [39850] = { 3 } },
            coord = { x = 706.5, y = 118 },
            Fillers = { [38343] = { 1 }, [39851] = { 1 } },
            Range = 0.69,
            _index = 152
        },
        {
            Qpart = { [39851] = { 1 } },
            coord = { x = 705.6, y = 118 },
            Fillers = { [38343] = { 1 } },
            Range = 54.4,
            _index = 153
        },
        {
            Done = { 39851, 39850 },
            coord = { x = 575.2, y = 328.2 },
            Fillers = { [38343] = { 1 } },
            _index = 154
        },
        {
            PickUp = { 39853 },
            coord = { x = 575.2, y = 328.2 },
            _index = 155
        },
        {
            Qpart = { [39853] = { 1 } },
            coord = { x = 586.4, y = 212.3 },
            Fillers = { [38343] = { 1 } },
            Range = 0.75,
            _index = 156
        },
        {
            Done = { 39853 },
            coord = { x = 586.7, y = 227.8 },
            _index = 157
        },
        {
            PickUp = { 39855 },
            coord = { x = 586.7, y = 227.8 },
            _index = 158
        },
        {
            Qpart = { [38343] = { 1 } },
            coord = { x = 586.7, y = 227.8 },
            Range = 100.4,
            _index = 159
        },
        {
            Qpart = { [39855] = { 1 } },
            coord = { x = 720.2, y = 488.7 },
            Range = 0.69,
            Gossip = 1,
            _index = 160
        },
        {
            Done = { 39855 },
            coord = { x = 1544, y = 3216.1 },
            _index = 161
        },
        {
            PickUp = { 40078 },
            coord = { x = 1544.9, y = 3214.8 },
            _index = 162
        },
        {
            Qpart = { [40078] = { 1 } },
            coord = { x = 1554.5, y = 3219.3 },
            Range = 0.75,
            _index = 163
        },
        {
            Done = { 40078 },
            coord = { x = 1544.3, y = 3213.8 },
            _index = 164
        },
        {
            PickUp = { 40001 },
            coord = { x = 1544, y = 3213.3 },
            _index = 165
        },
        {
            PickUp = { 39059 },
            coord = { x = 1554, y = 3191.1 },
            _index = 166
        },
        {
            DropQuest = 39060,
            coord = { x = 1554, y = 3191.5 },
            ExtraLineText = "TALK_ENSIGN_WARD",
            Gossip = 38872,
            _index = 167
        },
        {
            Done = { 39059 },
            coord = { x = 882.6, y = 2863.4 },
            _index = 168
        },
        {
            PickUp = { 39060, 39061 },
            coord = { x = 882.6, y = 2863.4 },
            _index = 169
        },
        {
            PickUp = { 39472 },
            coord = { x = 833.6, y = 2817.1 },
            Fillers = { [39061] = { 1 } },
            _index = 170
        },
        {
            Qpart = { [39060] = { 3 } },
            coord = { x = 819.5, y = 2826.9 },
            Button = { ["39060-3"] = 127295 },
            Range = 0.75,
            _index = 171
        },
        {
            Qpart = { [39060] = { 2 } },
            coord = { x = 769.2, y = 2733.5 },
            Fillers = { [39061] = { 1 } },
            Button = { ["39060-2"] = 127295 },
            Range = 0.69,
            _index = 172
        },
        {
            Qpart = { [39472] = { 1 } },
            coord = { x = 673.7, y = 2775.9 },
            Fillers = { [39061] = { 1 } },
            Range = 0.69,
            _index = 173
        },
        {
            Qpart = { [39060] = { 1 } },
            coord = { x = 715.4, y = 2923.8 },
            Fillers = { [39061] = { 1 } },
            Button = { ["39060-1"] = 127295 },
            Range = 0.75,
            _index = 174
        },
        {
            Qpart = { [39061] = { 1 } },
            coord = { x = 715.4, y = 2923.8 },
            Range = 60.44,
            _index = 175
        },
        {
            Done = { 39061, 39060, 39472 },
            coord = { x = 883.6, y = 2863.1 },
            _index = 176
        },
        {
            PickUp = { 39062 },
            coord = { x = 883.6, y = 2863.1 },
            _index = 177
        },
        {
            Waypoint = 39062,
            coord = { x = 1155.7, y = 2769.5 },
            Range = 43.54,
            _index = 178
        },
        {
            Done = { 39062 },
            coord = { x = 1346, y = 2789.1 },
            _index = 179
        },
        {
            PickUp = { 39063 },
            coord = { x = 1346, y = 2789.1 },
            _index = 180
        },
        {
            PickUp = { 39405 },
            coord = { x = 1351.5, y = 2673.6 },
            Fillers = { [39063] = { 1 }, [39119] = { 1 } },
            _index = 181
        },
        {
            Qpart = { [39063] = { 1 }, [39405] = { 1 } },
            coord = { x = 1352.5, y = 2673.9 },
            Fillers = { [39119] = { 1 } },
            Range = 22.19,
            _index = 182
        },
        {
            Done = { 39405, 39063 },
            coord = { x = 1518.7, y = 2660 },
            _index = 183
        },
        {
            PickUp = { 39092 },
            coord = { x = 1518.7, y = 2660 },
            _index = 184
        },
        {
            Qpart = { [39119] = { 1 } },
            coord = { x = 1519.7, y = 2660 },
            Range = 73.71,
            _index = 185
        },
        {
            Qpart = { [39092] = { 4 } },
            coord = { x = 1474.3, y = 2597.8 },
            Range = 0.75,
            _index = 186
        },
        {
            Qpart = { [39092] = { 3 } },
            coord = { x = 1526.5, y = 2598.1 },
            Range = 0.61,
            _index = 187
        },
        {
            Qpart = { [39092] = { 2 } },
            coord = { x = 1527, y = 2487.9 },
            Range = 0.75,
            _index = 188
        },
        {
            Qpart = { [39092] = { 1 } },
            coord = { x = 1474, y = 2485.8 },
            Range = 0.75,
            _index = 189
        },
        {
            Qpart = { [39092] = { 5 } },
            coord = { x = 1452, y = 2542.3 },
            Range = 0.69,
            Gossip = 1,
            _index = 190
        },
        {
            Done = { 39092 },
            coord = { x = 1419.4, y = 2543.6 },
            _index = 191
        },
        {
            PickUp = { 39122 },
            coord = { x = 1419.4, y = 2543.6 },
            _index = 192
        },
        {
            Qpart = { [39122] = { 1 } },
            coord = { x = 1294.4, y = 2542.1 },
            Range = 0.69,
            _index = 193
        },
        {
            Done = { 39122 },
            coord = { x = 887.4, y = 2834 },
            _index = 194
        },
        {
            Done = { 40001 },
            coord = { x = 1211.4, y = 2877.6 },
            _index = 195
        },
        {
            PickUp = { 40002 },
            coord = { x = 1211.4, y = 2877.6 },
            _index = 196
        },
        {
            Qpart = { [40002] = { 1 } },
            coord = { x = 1238.9, y = 2946.4 },
            Range = 0.75,
            _index = 197
        },
        {
            Qpart = { [40002] = { 2 } },
            coord = { x = 1212.5, y = 2878.6 },
            Range = 0.75,
            _index = 198
        },
        {
            Done = { 40002 },
            coord = { x = 1211, y = 2878 },
            _index = 199
        },
        {
            PickUp = { 40004, 40003 },
            coord = { x = 1211, y = 2878 },
            _index = 200
        },
        {
            Qpart = { [40004] = { 3 } },
            coord = { x = 1165.3, y = 2557.1 },
            Fillers = { [39998] = { 1 } },
            Range = 0.69,
            _index = 201
        },
        {
            Qpart = { [40003] = { 3 } },
            coord = { x = 1061, y = 2469.3 },
            Fillers = { [39998] = { 1 } },
            Button = { ["40003-3"] = 129161 },
            Range = 0.69,
            _index = 202
        },
        {
            Qpart = { [40004] = { 2 } },
            coord = { x = 1082.3, y = 2520.4 },
            Fillers = { [39998] = { 1 } },
            Range = 0.75,
            _index = 203
        },
        {
            Qpart = { [40003] = { 2 } },
            coord = { x = 986.7, y = 2597.8 },
            Fillers = { [39998] = { 1 } },
            Button = { ["40003-2"] = 129161 },
            Range = 0.75,
            _index = 204
        },
        {
            Qpart = { [40004] = { 1 } },
            coord = { x = 1025.3, y = 2631.6 },
            Fillers = { [39998] = { 1 } },
            Range = 0.75,
            _index = 205
        },
        {
            Qpart = { [40004] = { 4 } },
            coord = { x = 890.2, y = 2675.3 },
            Fillers = { [39998] = { 1 } },
            Range = 0.69,
            _index = 206
        },
        {
            Qpart = { [40003] = { 1 } },
            coord = { x = 967.4, y = 2713.4 },
            Fillers = { [39998] = { 1 } },
            Button = { ["40003-1"] = 129161 },
            Range = 0.75,
            _index = 207
        },
        {
            Qpart = { [39998] = { 1 } },
            coord = { x = 979.6, y = 2710.3 },
            Range = 67.93,
            _index = 208
        },
        {
            Done = { 40004, 40003 },
            coord = { x = 962.5, y = 2493.3 },
            _index = 209
        },
        {
            PickUp = { 40005 },
            coord = { x = 962.5, y = 2493.3 },
            _index = 210
        },
        {
            Qpart = { [40005] = { 1 } },
            coord = { x = 962.2, y = 2491 },
            Range = 11.83,
            Gossip = 1,
            _index = 211
        },
        {
            Done = { 40005 },
            coord = { x = 944.2, y = 2487.9 },
            _index = 212
        },
        {
            PickUp = { 40072 },
            coord = { x = 958.2, y = 2499.1 },
            _index = 213
        },
        {
            UseDalaHS = 40072,
            coord = { x = 958.2, y = 2499.1 },
            Button = { ["40072-1"] = 140192 },
            _index = 214
        },
        {
            RouteCompleted = 1,
            _index = 215
        }
    }

    APR.RouteQuestStepList["971-VoidElf-intro"] = {
        {
            PickUp = { 49788 },
            coord = { x = 3318.8, y = 2136.2 },
            Zone = 971,
            _index = 1
        },
        {
            Waypoint = 49788,
            coord = { x = 3329.4, y = 2148.4 },
            ExtraLineText = "USE_PORTAL_STORMWIND",
            Range = 2,
            Zone = 971,
            _index = 2
        },
        {
            Done = { 49788 },
            coord = { x = 799.8, y = -8172.3 },
            Zone = 84,
            _index = 3
        },
        {
            PickUp = { 50305 },
            coord = { x = 799.8, y = -8172.3 },
            RaidIcon = 167032,
            Zone = 84,
            _index = 4
        },
        {
            Qpart = { [50305] = { 1 } },
            coord = { x = 747.7, y = -8196.5 },
            Range = 30,
            Zone = 84,
            _index = 5
        },
        {
            Done = { 50305 },
            coord = { x = 747.3, y = -8199.1 },
            Zone = 84,
            _index = 6
        },
        {
            RouteCompleted = 1,
            _index = 7
        }
    }

    APR.RouteQuestStepList["940-LightforgedDraenei-intro"] = {
        {
            PickUp = { 49772 },
            coord = { x = 1451, y = 461.9 },
            Zone = 940,
            _index = 1
        },
        {
            Waypoint = 49772,
            coord = { x = 1473.8, y = 463.8 },
            ExtraLineText = "DOWN",
            Range = 5,
            Zone = 940,
            _index = 2
        },
        {
            Waypoint = 49772,
            coord = { x = 1453.9, y = 429.7 },
            ExtraLineText = "DOWN",
            Range = 5,
            Zone = 941,
            _index = 3
        },
        {
            Waypoint = 49772,
            coord = { x = 1437.7, y = 432.5 },
            Range = 5,
            Zone = 941,
            _index = 4
        },
        {
            Waypoint = 49772,
            coord = { x = 1469, y = 499.2 },
            ExtraLineText = "USE_PORTAL_STORMWIND",
            Range = 2,
            Zone = 941,
            _index = 5
        },
        {
            Done = { 49772 },
            coord = { x = 799.8, y = -8172.2 },
            Zone = 84,
            _index = 6
        },
        {
            PickUp = { 50313 },
            coord = { x = 799.9, y = -8172.8 },
            Zone = 84,
            _index = 7
        },
        {
            Qpart = { [50313] = { 1 } },
            coord = { x = 748.2, y = -8197.1 },
            RaidIcon = 167032,
            Zone = 84,
            _index = 8
        },
        {
            Done = { 50313 },
            coord = { x = 748.2, y = -8197.1 },
            Zone = 84,
            _index = 9
        },
        {
            RouteCompleted = 1,
            _index = 10
        }
    }
end
