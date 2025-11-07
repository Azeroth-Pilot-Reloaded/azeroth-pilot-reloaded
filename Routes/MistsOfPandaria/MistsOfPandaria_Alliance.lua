if APR.Faction == "Alliance" then
    APR.RouteQuestStepList["84-MoP Intro"] = {
        {
            PickUp = { 60125 },
            ChromiePick = 8,
            coord = { x = 745.6, y = -8196.3 },
            GossipOptionIDs = { 51901, 51902 },
            Zone = 84,
            _index = 1
        },
        {
            Waypoint = 60125,
            coord = { x = 647.4, y = -8334.2 },
            Range = 5,
            Zone = 84,
            _index = 2
        },
        {
            Waypoint = 60125,
            coord = { x = 500.7, y = -8544 },
            Range = 5,
            Zone = 84,
            _index = 3
        },
        {
            Waypoint = 60125,
            coord = { x = 440.1, y = -8526 },
            Range = 5,
            Zone = 84,
            _index = 4
        },
        {
            Qpart = { [60125] = { 1 } },
            coord = { x = 313.2, y = -8427.7 },
            Zone = 84,
            _index = 5
        },
        {
            Done = { 60125 },
            coord = { x = 351.2, y = -8457 },
            Zone = 84,
            _index = 6
        },
        {
            PickUp = { 29548 },
            coord = { x = 351.2, y = -8457 },
            Zone = 84,
            _index = 7
        },
        {
            Qpart = { [29548] = { 1 } },
            coord = { x = 372.6, y = -8450.5 },
            GossipOptionIDs = { 54294 },
            Zone = 84,
            _index = 8
        },
        {
            Qpart = { [29548] = { 2 } },
            coord = { x = 1277.3, y = -7879.8 },
            GossipOptionIDs = { 40614 },
            Zone = 13,
            _index = 9
        },
        {
            Done = { 29548 },
            coord = { x = -1483, y = -665.7 },
            Zone = 371,
            _index = 10
        },
        {
            RouteCompleted = 1,
            _index = 11
        }
    }

    APR.RouteQuestStepList["371-The Jade Forest"] = {
        {
            PickUp = { 31732 },
            coord = { x = -1482.8, y = -665.5 },
            Zone = 371,
            _index = 1
        },
        {
            Qpart = { [31732] = { 1, 2, 3, 4 } },
            coord = { x = -1482, y = -653.9 },
            ExtraLineText = "USE_GYROCHOPPA",
            Zone = 371,
            _index = 2
        },
        {
            Done = { 31732 },
            coord = { x = -1483.3, y = -663.8 },
            Zone = 371,
            _index = 3
        },
        {
            PickUp = { 31733 },
            coord = { x = -1483.3, y = -663.8 },
            Zone = 371,
            _index = 4
        },
        {
            Qpart = { [31733] = { 1 } },
            coord = { x = -1502.7, y = -666.6 },
            Zone = 371,
            _index = 5
        },
        {
            Done = { 31733 },
            coord = { x = -1591.1, y = -568.1 },
            Zone = 371,
            _index = 6
        },
        {
            PickUp = { 30069, 31734 },
            coord = { x = -1591.1, y = -568.1 },
            Zone = 371,
            _index = 7
        },
        {
            Qpart = { [30069] = { 1, 2 }, [31734] = { 1 } },
            coord = { x = -1680.2, y = -718.7 },
            Button = { ["31734-1"] = 89612 },
            Range = 30,
            Zone = 371,
            _index = 8
        },
        {
            Done = { 30069, 31734 },
            coord = { x = -1701.9, y = -770.6 },
            Zone = 371,
            _index = 9
        },
        {
            PickUp = { 31735 },
            coord = { x = -1701.9, y = -770.6 },
            Zone = 371,
            _index = 10
        },
        {
            Qpart = { [31735] = { 1 } },
            coord = { x = -1732, y = -777.5 },
            Button = { ["31735-1"] = 89624 },
            Range = 2,
            Zone = 371,
            _index = 11
        },
        {
            Qpart = { [31735] = { 2 } },
            coord = { x = -1756.3, y = -808.3 },
            Button = { ["31735-2"] = 89624 },
            Range = 5,
            Zone = 371,
            _index = 12
        },
        {
            Qpart = { [31735] = { 3 } },
            coord = { x = -1790.2, y = -833.8 },
            Button = { ["31735-3"] = 89624 },
            Zone = 371,
            _index = 13
        },
        {
            Done = { 31735 },
            coord = { x = -1793.5, y = -830.3 },
            Zone = 371,
            _index = 14
        },
        {
            PickUp = { 31736, 31737 },
            coord = { x = -1792.5, y = -834.7 },
            Zone = 371,
            _index = 15
        },
        {
            Qpart = { [31737] = { 1, 2 } },
            coord = { x = -1654.4, y = -714 },
            Range = 30,
            Zone = 371,
            _index = 16
        },
        {
            Waypoint = 31737,
            coord = { x = -1651.9, y = -509.7 },
            Range = 5,
            Zone = 371,
            _index = 17
        },
        {
            Waypoint = 31737,
            coord = { x = -1621, y = -397.8 },
            Range = 5,
            Zone = 371,
            _index = 18
        },
        {
            Qpart = { [31736] = { 1 } },
            coord = { x = -1751.5, y = -306 },
            Range = 30,
            Zone = 371,
            _index = 19
        },
        {
            Done = { 31736, 31737 },
            coord = { x = -1778.5, y = -290.4 },
            Zone = 371,
            _index = 20
        },
        {
            PickUp = { 31738, 31739 },
            coord = { x = -1778.5, y = -291.8 },
            Zone = 371,
            _index = 21
        },
        {
            PickUp = { 29552 },
            coord = { x = -1770, y = -284 },
            Zone = 371,
            _index = 22
        },
        {
            GetFP = 966,
            coord = { x = -1763.1, y = -311.7 },
            Zone = 371,
            _index = 23
        },
        {
            SetHS = 29552,
            coord = { x = -1681.8, y = -276 },
            Zone = 371,
            _index = 24
        },
        {
            Qpart = { [29552] = { 1 }, [31738] = { 1 }, [31739] = { 1 } },
            coord = { x = -1521.1, y = -432.5 },
            Range = 60,
            Zone = 371,
            _index = 25
        },
        {
            Done = { 31739 },
            coord = { x = -1308.8, y = -538.4 },
            Zone = 371,
            _index = 26
        },
        {
            PickUp = { 31740 },
            coord = { x = -1308.8, y = -538.4 },
            Zone = 371,
            _index = 27
        },
        {
            Qpart = { [31740] = { 1 } },
            coord = { x = -1295.2, y = -532.1 },
            Range = 5,
            Zone = 371,
            _index = 28
        },
        {
            UseHS = 29552,
            Zone = 371,
            _index = 29
        },
        {
            Done = { 29552 },
            coord = { x = -1770.3, y = -283.6 },
            Zone = 371,
            _index = 30
        },
        {
            Done = { 31738, 31740 },
            coord = { x = -1779, y = -291.5 },
            Zone = 371,
            _index = 31
        },
        {
            PickUp = { 31741, 31744 },
            coord = { x = -1779, y = -291.5 },
            Zone = 371,
            _index = 32
        },
        {
            PickUp = { 31742, 31743 },
            coord = { x = -1774, y = -295.5 },
            Zone = 371,
            _index = 33
        },
        {
            Waypoint = 31742,
            coord = { x = -1618.3, y = -396.3 },
            Range = 5,
            Zone = 371,
            _index = 34
        },
        {
            Waypoint = 31742,
            coord = { x = -1444.5, y = -228.7 },
            Range = 5,
            Zone = 371,
            _index = 35
        },
        {
            Qpart = { [31743] = { 4 } },
            coord = { x = -1565.3, y = -131.5 },
            Fillers = { [31741] = { 1 }, [31744] = { 1 } },
            Button = { ["31743-4"] = 89602 },
            Range = 5,
            Zone = 371,
            _index = 36
        },
        {
            Qpart = { [31743] = { 1 } },
            coord = { x = -1400.5, y = -183.5 },
            Fillers = { [31741] = { 1 }, [31744] = { 1 } },
            Button = { ["31743-1"] = 89602 },
            Range = 5,
            Zone = 371,
            _index = 37
        },
        {
            Qpart = { [31743] = { 3 } },
            coord = { x = -1349.2, y = -147.1 },
            Fillers = { [31741] = { 1 }, [31744] = { 1 } },
            Button = { ["31743-3"] = 89602 },
            Range = 5,
            Zone = 371,
            _index = 38
        },
        {
            Qpart = { [31743] = { 2 } },
            coord = { x = -1443.9, y = -146.1 },
            Fillers = { [31741] = { 1 }, [31744] = { 1 } },
            Button = { ["31743-2"] = 89602 },
            Range = 5,
            Zone = 371,
            _index = 39
        },
        {
            Qpart = { [31741] = { 1 }, [31744] = { 1 } },
            coord = { x = -1443.9, y = -146.1 },
            Range = 30,
            Zone = 371,
            _index = 40
        },
        {
            Waypoint = 31743,
            coord = { x = -1503.1, y = -106.5 },
            Range = 5,
            Zone = 371,
            _index = 41
        },
        {
            Waypoint = 31743,
            coord = { x = -1502.1, y = -50.9 },
            Range = 5,
            Zone = 371,
            _index = 42
        },
        {
            Qpart = { [31742] = { 2 } },
            coord = { x = -1466.5, y = -81.7 },
            Range = 5,
            Zone = 371,
            _index = 43
        },
        {
            Qpart = { [31742] = { 1 } },
            coord = { x = -1426.3, y = -82.1 },
            Range = 5,
            Zone = 371,
            _index = 44
        },
        {
            Done = { 31741, 31742, 31743, 31744 },
            coord = { x = -1439.5, y = -51.8 },
            Zone = 371,
            _index = 45
        },
        {
            PickUp = { 30070 },
            coord = { x = -1439.5, y = -51.8 },
            Zone = 371,
            _index = 46
        },
        {
            Qpart = { [30070] = { 1 } },
            coord = { x = -1443.6, y = -3.7 },
            Range = 5,
            Zone = 371,
            _index = 47
        },
        {
            Done = { 30070 },
            coord = { x = -1443, y = -30.8 },
            Zone = 371,
            _index = 48
        },
        {
            PickUp = { 31745 },
            coord = { x = -1443, y = -30.8 },
            Zone = 371,
            _index = 49
        },
        {
            Qpart = { [31745] = { 1 } },
            coord = { x = -1446.7, y = -59.6 },
            ExtraLineText = "USE_GYROCHOPPA",
            Zone = 371,
            _index = 50
        },
        {
            Done = { 31745 },
            coord = { x = -1903.4, y = -461.7 },
            Zone = 371,
            _index = 51
        },
        {
            PickUp = { 29555, 29556 },
            coord = { x = -1903.4, y = -461.7 },
            Zone = 371,
            _index = 52
        },
        {
            Qpart = { [29555] = { 2 } },
            coord = { x = -2061.4, y = -580.2 },
            Fillers = { [29555] = { 1 }, [29556] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 53
        },
        {
            Qpart = { [29555] = { 1 } },
            coord = { x = -2037.7, y = -550.1 },
            Fillers = { [29556] = { 1 } },
            Range = 15,
            Zone = 371,
            _index = 54
        },
        {
            Qpart = { [29556] = { 1 } },
            coord = { x = -2061.4, y = -580.2 },
            Range = 30,
            Zone = 371,
            _index = 55
        },
        {
            Done = { 29555, 29556 },
            coord = { x = -2068.1, y = -455.6 },
            Zone = 371,
            _index = 56
        },
        {
            PickUp = { 29553 },
            coord = { x = -2068.1, y = -455.6 },
            Zone = 371,
            _index = 57
        },
        {
            Done = { 29553 },
            coord = { x = -2331.9, y = -188.1 },
            Zone = 371,
            _index = 58
        },
        {
            PickUp = { 29558, 29559, 29560 },
            coord = { x = -2331.3, y = -182 },
            Zone = 371,
            _index = 59
        },
        {
            Qpart = { [29560] = { 1 } },
            coord = { x = -2365.9, y = -72.9 },
            Fillers = { [29558] = { 1 }, [29559] = { 1 } },
            Range = 30,
            Zone = 371,
            _index = 60
        },
        {
            Qpart = { [29558] = { 1 }, [29559] = { 1 } },
            coord = { x = -2310.5, y = -109.4 },
            Range = 30,
            Zone = 371,
            _index = 61
        },
        {
            Done = { 29558, 29559, 29560 },
            coord = { x = -2331.8, y = -183.6 },
            Zone = 371,
            _index = 62
        },
        {
            PickUp = { 29759 },
            coord = { x = -2331.8, y = -183.6 },
            Zone = 371,
            _index = 63
        },
        {
            Qpart = { [29759] = { 1 } },
            coord = { x = -2364.5, y = -76.2 },
            Range = 5,
            Zone = 371,
            _index = 64
        },
        {
            Done = { 29759 },
            coord = { x = -2331.8, y = -183.2 },
            Zone = 371,
            _index = 65
        },
        {
            PickUp = { 29562 },
            coord = { x = -2331.8, y = -183.2 },
            Zone = 371,
            _index = 66
        },
        {
            Qpart = { [29562] = { 1 } },
            coord = { x = -2446.3, y = -152.5 },
            Range = 30,
            Zone = 371,
            _index = 67
        },
        {
            Done = { 29562 },
            coord = { x = -2666.3, y = -149.7 },
            Zone = 371,
            _index = 68
        },
        {
            PickUp = { 29883, 29885 },
            coord = { x = -2663.2, y = -161.4 },
            Zone = 371,
            _index = 69
        },
        {
            Qpart = { [29883] = { 1 } },
            coord = { x = -2651.1, y = -130.6 },
            GossipOptionIDs = { 40616 },
            Zone = 371,
            _index = 70
        },
        {
            Qpart = { [29883] = { 4 } },
            coord = { x = -2601.3, y = -97.1 },
            GossipOptionIDs = { 40442 },
            Zone = 371,
            _index = 71
        },
        {
            Qpart = { [29883] = { 3 } },
            coord = { x = -2653.1, y = -284.6 },
            GossipOptionIDs = { 40617 },
            Zone = 371,
            _index = 72
        },
        {
            Qpart = { [29883] = { 2 } },
            coord = { x = -2732, y = -253.7 },
            GossipOptionIDs = { 40427 },
            Zone = 371,
            _index = 73
        },
        {
            Qpart = { [29885] = { 1 } },
            coord = { x = -2808.2, y = -271.5 },
            Range = 15,
            Zone = 371,
            _index = 74
        },
        {
            Done = { 29883, 29885 },
            coord = { x = -2663.2, y = -161.2 },
            Zone = 371,
            _index = 75
        },
        {
            PickUp = { 29762 },
            coord = { x = -2665.7, y = -150.4 },
            Zone = 371,
            _index = 76
        },
        {
            PickUp = { 29887 },
            coord = { x = -2651.2, y = -130.6 },
            Zone = 371,
            _index = 77
        },
        {
            Waypoint = 29762,
            coord = { x = -2768, y = -257.5 },
            Range = 5,
            Zone = 371,
            _index = 78
        },
        {
            Waypoint = 29762,
            coord = { x = -3157.7, y = -423.3 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 1,
            Zone = 371,
            _index = 79
        },
        {
            Qpart = { [29762] = { 1 }, [29887] = { 1, 2, 3, 4 } },
            coord = { x = -3201.7, y = -413.7 },
            Range = 45,
            Zone = 371,
            _index = 80
        },
        {
            Done = { 29762 },
            coord = { x = -2665.9, y = -150 },
            Zone = 371,
            _index = 81
        },
        {
            Done = { 29887 },
            coord = { x = -2651.2, y = -130.3 },
            Zone = 371,
            _index = 82
        },
        {
            PickUp = { 29894 },
            coord = { x = -2651.2, y = -130.3 },
            Zone = 371,
            _index = 83
        },
        {
            Qpart = { [29894] = { 1, 2 } },
            coord = { x = -2638.6, y = -205.7 },
            GossipOptionIDs = { 40441 },
            Zone = 371,
            _index = 84
        },
        {
            Done = { 29894 },
            coord = { x = -2666, y = -150 },
            Zone = 371,
            _index = 85
        },
        {
            PickUp = { 29733 },
            coord = { x = -2667.1, y = -155.8 },
            Zone = 371,
            _index = 86
        },
        {
            Qpart = { [29733] = { 1 } },
            coord = { x = -2031, y = 356.7 },
            GossipOptionIDs = { 40098 },
            Zone = 371,
            _index = 87
        },
        {
            Done = { 29733 },
            coord = { x = -2667.1, y = -156.3 },
            Zone = 371,
            _index = 88
        },
        {
            PickUp = { 29725 },
            coord = { x = -2659.6, y = -158.9 },
            Zone = 371,
            _index = 89
        },
        {
            Qpart = { [29725] = { 1 } },
            coord = { x = -2085.8, y = 720.3 },
            Range = 5,
            Zone = 371,
            _index = 90
        },
        {
            Qpart = { [29725] = { 2 } },
            coord = { x = -1789.2, y = 770.1 },
            Range = 5,
            Zone = 371,
            _index = 91
        },
        {
            Qpart = { [29725] = { 3 } },
            coord = { x = -1881.9, y = 928.2 },
            Range = 5,
            Zone = 371,
            _index = 92
        },
        {
            Qpart = { [29725] = { 4 } },
            coord = { x = -2102.4, y = 717.4 },
            Range = 5,
            Zone = 371,
            _index = 93
        },
        {
            Done = { 29725 },
            coord = { x = -2660.6, y = -158.1 },
            Zone = 371,
            _index = 94
        },
        {
            PickUp = { 29726 },
            coord = { x = -2672.7, y = -159.3 },
            Zone = 371,
            _index = 95
        },
        {
            Qpart = { [29726] = { 1 } },
            coord = { x = -1223.2, y = 1539.2 },
            Range = 2,
            Zone = 371,
            _index = 96
        },
        {
            Qpart = { [29726] = { 2 } },
            coord = { x = -1261.2, y = 1502.2 },
            Range = 2,
            Zone = 371,
            _index = 97
        },
        {
            Qpart = { [29726] = { 3 } },
            coord = { x = -1267.7, y = 1494.7 },
            Range = 2,
            Zone = 371,
            _index = 98
        },
        {
            Qpart = { [29726] = { 4 } },
            coord = { x = -1288.9, y = 1501.3 },
            GossipOptionIDs = { 40113 },
            Zone = 371,
            _index = 99
        },
        {
            Done = { 29726 },
            coord = { x = -2672.2, y = -159 },
            Zone = 371,
            _index = 100
        },
        {
            PickUp = { 29727 },
            coord = { x = -2663.1, y = -161 },
            Zone = 371,
            _index = 101
        },
        {
            Qpart = { [29727] = { 1 } },
            coord = { x = -546, y = 1117.1 },
            Range = 2,
            Zone = 371,
            _index = 102
        },
        {
            Done = { 29727 },
            coord = { x = -2663, y = -161.4 },
            Zone = 371,
            _index = 103
        },
        {
            PickUp = { 29903 },
            coord = { x = -2658.9, y = -149 },
            Zone = 371,
            _index = 104
        },
        {
            PickUp = { 29888 },
            coord = { x = -2666.1, y = -150 },
            Zone = 371,
            _index = 105
        },
        {
            Qpart = { [29903] = { 1 } },
            coord = { x = -2692.6, y = -266 },
            ExtraLineText1 = "SPEAK_TO_NPC_TO_GIVE_THEM_EQUIPMENT",
            ExtraLineText2 = "DAGGERS_GIVE_DAGGER",
            ExtraLineText3 = "SWORD_GIVE_SHIELD",
            ExtraLineText4 = "RED_STAFF_GIVE_HEALING_PRAYER",
            ExtraLineText5 = "BLEUGREEN_STAFF_GIVE_STAFF",
            Range = 60,
            Zone = 371,
            _index = 106
        },
        {
            Done = { 29903 },
            coord = { x = -2658.8, y = -149.4 },
            Zone = 371,
            _index = 107
        },
        {
            PickUp = { 29904 },
            coord = { x = -2658.8, y = -149.4 },
            Zone = 371,
            _index = 108
        },
        {
            Waypoint = 29904,
            coord = { x = -2745.3, y = -233.9 },
            Range = 5,
            Zone = 371,
            _index = 109
        },
        {
            Waypoint = 29904,
            coord = { x = -2832.5, y = -169.6 },
            Range = 5,
            Zone = 371,
            _index = 110
        },
        {
            Qpart = { [29904] = { 1 } },
            coord = { x = -3000.5, y = -47.6 },
            Range = 60,
            Zone = 371,
            _index = 111
        },
        {
            Done = { 29904 },
            coord = { x = -2658.9, y = -149.3 },
            Zone = 371,
            _index = 112
        },
        {
            PickUp = { 29905, 29906 },
            coord = { x = -2658.9, y = -149.3 },
            Zone = 371,
            _index = 113
        },
        {
            Qpart = { [29906] = { 1 } },
            coord = { x = -2363, y = -74.1 },
            Fillers = { [29905] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 114
        },
        {
            Qpart = { [29905] = { 1 } },
            coord = { x = -2425.4, y = -163.8 },
            Range = 30,
            Zone = 371,
            _index = 115
        },
        {
            Done = { 29905, 29906 },
            coord = { x = -2661, y = -139.9 },
            Zone = 371,
            _index = 116
        },
        {
            SetHS = 29890,
            coord = { x = -2710.8, y = -220.4 },
            Zone = 371,
            _index = 117
        },
        {
            Waypoint = 29888,
            coord = { x = -2728.7, y = -363.6 },
            Range = 5,
            Zone = 371,
            _index = 118
        },
        {
            Waypoint = 29888,
            coord = { x = -2372.5, y = -421 },
            Range = 5,
            Zone = 371,
            _index = 119
        },
        {
            Done = { 29888 },
            coord = { x = -2298.5, y = -606.9 },
            Zone = 371,
            _index = 120
        },
        {
            PickUp = { 29889 },
            coord = { x = -2298.5, y = -606.9 },
            Zone = 371,
            _index = 121
        },
        {
            Qpart = { [29889] = { 1 } },
            coord = { x = -2298.6, y = -605.3 },
            Zone = 371,
            _index = 122
        },
        {
            Done = { 29889 },
            coord = { x = -2295.3, y = -602.1 },
            Zone = 371,
            _index = 123
        },
        {
            PickUp = { 31130 },
            coord = { x = -2295.3, y = -602.1 },
            Zone = 371,
            _index = 124
        },
        {
            Qpart = { [31130] = { 1 } },
            coord = { x = -2299.9, y = -582.6 },
            Range = 2,
            Zone = 371,
            _index = 125
        },
        {
            Qpart = { [31130] = { 2 } },
            coord = { x = -2324.3, y = -567.7 },
            GossipOptionIDs = { 33295 },
            Zone = 371,
            _index = 126
        },
        {
            Qpart = { [31130] = { 3 } },
            coord = { x = -2320.8, y = -599.2 },
            Range = 1,
            Zone = 371,
            _index = 127
        },
        {
            Done = { 31130 },
            coord = { x = -2320.5, y = -592.1 },
            Zone = 371,
            _index = 128
        },
        {
            PickUp = { 29891, 29892, 29893 },
            coord = { x = -2320.5, y = -592.1 },
            Zone = 371,
            _index = 129
        },
        {
            Qpart = { [29891] = { 1, 2 }, [29893] = { 1 } },
            coord = { x = -2593.4, y = -537.4 },
            Fillers = { [29892] = { 1 } },
            Button = { ["29893-1"] = 76128 },
            Range = 60,
            Zone = 371,
            _index = 130
        },
        {
            Qpart = { [29892] = { 1 } },
            coord = { x = -2588, y = -526.5 },
            Range = 60,
            Zone = 371,
            _index = 131
        },
        {
            Done = { 29891, 29892, 29893 },
            coord = { x = -2303.5, y = -565.9 },
            Zone = 371,
            _index = 132
        },
        {
            PickUp = { 29890 },
            coord = { x = -2303.2, y = -566.2 },
            Zone = 371,
            _index = 133
        },
        {
            Qpart = { [29890] = { 1 } },
            coord = { x = -2366, y = -632.2 },
            Zone = 371,
            _index = 134
        },
        {
            UseHS = 29890,
            Zone = 371,
            _index = 135
        },
        {
            Waypoint = 29890,
            coord = { x = -2750.9, y = -228.9 },
            Range = 5,
            Zone = 371,
            _index = 136
        },
        {
            Waypoint = 29890,
            coord = { x = -2829, y = -167.6 },
            Range = 5,
            Zone = 371,
            _index = 137
        },
        {
            Waypoint = 29890,
            coord = { x = -2870.2, y = 7.7 },
            Range = 5,
            Zone = 371,
            _index = 138
        },
        {
            Done = { 29890 },
            coord = { x = -3147.8, y = -36.7 },
            Zone = 371,
            _index = 139
        },
        {
            PickUp = { 29898 },
            coord = { x = -3147.8, y = -36.7 },
            Zone = 371,
            _index = 140
        },
        {
            PickUp = { 29899, 29900 },
            coord = { x = -3155.7, y = -38.2 },
            Zone = 371,
            _index = 141
        },
        {
            Waypoint = 29899,
            coord = { x = -3173, y = -171.4 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 371,
            _index = 142
        },
        {
            Qpart = { [29898] = { 1 } },
            coord = { x = -3215.4, y = -168 },
            Fillers = { [29899] = { 1 } },
            Zone = 371,
            _index = 143
        },
        {
            Waypoint = 29898,
            coord = { x = -3213.3, y = -210.4 },
            Range = 5,
            Zone = 371,
            _index = 144
        },
        {
            Qpart = { [29898] = { 2 } },
            coord = { x = -3245.7, y = -145.8 },
            Fillers = { [29899] = { 1 } },
            Zone = 371,
            _index = 145
        },
        {
            Qpart = { [29898] = { 3 } },
            coord = { x = -3299.2, y = -158.2 },
            Fillers = { [29899] = { 1 } },
            Zone = 371,
            _index = 146
        },
        {
            Qpart = { [29900] = { 1 } },
            coord = { x = -3208.8, y = -86 },
            Fillers = { [29899] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 147
        },
        {
            Qpart = { [29898] = { 4 } },
            coord = { x = -3186.5, y = -71.3 },
            Fillers = { [29899] = { 1 } },
            Zone = 371,
            _index = 148
        },
        {
            Qpart = { [29900] = { 2 } },
            coord = { x = -3189.6, y = -96.5 },
            Range = 2,
            Zone = 371,
            _index = 149
        },
        {
            Waypoint = 29900,
            coord = { x = -3194.8, y = -169.9 },
            Range = 5,
            Zone = 371,
            _index = 150
        },
        {
            Waypoint = 29900,
            coord = { x = -3149.4, y = -112 },
            Range = 5,
            Zone = 371,
            _index = 151
        },
        {
            Done = { 29898, 29899, 29900 },
            coord = { x = -3156, y = -42.2 },
            Zone = 371,
            _index = 152
        },
        {
            PickUp = { 29901 },
            coord = { x = -3155.6, y = -37.8 },
            Zone = 371,
            _index = 153
        },
        {
            Qpart = { [29901] = { 1 } },
            coord = { x = -3150.3, y = -37.4 },
            GossipOptionIDs = { 40503 },
            Zone = 371,
            _index = 154
        },
        {
            UseHS = 29901,
            Zone = 371,
            _index = 155
        },
        {
            Done = { 29901 },
            coord = { x = -2658.8, y = -149.4 },
            Zone = 371,
            _index = 156
        },
        {
            PickUp = { 29922 },
            coord = { x = -2661, y = -140.1 },
            Zone = 371,
            _index = 157
        },
        {
            Qpart = { [29922] = { 1 } },
            coord = { x = -2594.1, y = -188.6 },
            GossipOptionIDs = { 41374 },
            Zone = 371,
            _index = 158
        },
        {
            UseFlightPath = 29922,
            NodeID = 895,
            coord = { x = -2594.1, y = -188.6 },
            ZoneStepTrigger = { Range = 15, x = -1831.9, y = 1502.5 },
            ETA = 67,
            Zone = 371,
            _index = 159
        },
        {
            GetFP = 895,
            coord = { x = -1833.5, y = 1499.9 },
            Zone = 371,
            _index = 160
        },
        {
            Done = { 29922 },
            coord = { x = -1817.2, y = 1504.7 },
            Zone = 371,
            _index = 161
        },
        {
            PickUp = { 31230 },
            coord = { x = -1841, y = 1503.4 },
            Zone = 371,
            _index = 162
        },
        {
            Qpart = { [31230] = { 3 } },
            coord = { x = -1808.6, y = 1520.8 },
            Range = 5,
            Zone = 371,
            _index = 163
        },
        {
            Qpart = { [31230] = { 2 } },
            coord = { x = -1740.3, y = 1618.1 },
            Range = 2,
            Zone = 371,
            _index = 164
        },
        {
            SetHS = 31230,
            coord = { x = -1741.1, y = 1618.1 },
            Zone = 371,
            _index = 165
        },
        {
            PickUp = { 32018 },
            coord = { x = -1744.4, y = 1606.7 },
            DontHaveAura = 424143,
            Zone = 371,
            _index = 166
        },
        {
            Qpart = { [31230] = { 1 } },
            coord = { x = -1934, y = 1581.3 },
            Range = 2,
            Zone = 371,
            _index = 167
        },
        {
            Done = { 31230 },
            coord = { x = -1842, y = 1505.1 },
            Zone = 371,
            _index = 168
        },
        {
            PickUp = { 29716, 29717 },
            coord = { x = -1807, y = 1505 },
            Zone = 371,
            _index = 169
        },
        {
            PickUp = { 29865 },
            coord = { x = -1793, y = 1520.2 },
            Zone = 371,
            _index = 170
        },
        {
            PickUp = { 29866 },
            coord = { x = -1805, y = 1543.2 },
            Zone = 371,
            _index = 171
        },
        {
            Qpart = { [29865] = { 1 }, [29866] = { 1 } },
            coord = { x = -1598.7, y = 1371 },
            Range = 69,
            Zone = 371,
            _index = 172
        },
        {
            Waypoint = 29716,
            coord = { x = -1389.1, y = 1382.9 },
            Range = 5,
            Zone = 371,
            _index = 173
        },
        {
            Qpart = { [29716] = { 1 }, [29717] = { 1 } },
            coord = { x = -1166.2, y = 1489 },
            GossipOptionIDs = { 39304 },
            Range = 30,
            Zone = 371,
            _index = 174
        },
        {
            Done = { 29716, 29717 },
            NoArrow = 1,
            Zone = 371,
            _index = 175
        },
        {
            PickUp = { 29723 },
            NoArrow = 1,
            Zone = 371,
            _index = 176
        },
        {
            Waypoint = 29865,
            coord = { x = -1294.3, y = 1500.8 },
            GossipOptionIDs = { 39810 },
            Range = 2,
            Zone = 371,
            _index = 177
        },
        {
            Qpart = { [29723] = { 1 } },
            coord = { x = -1321.8, y = 1497.5 },
            GossipOptionIDs = { 39810 },
            Range = 5,
            Zone = 371,
            _index = 178
        },
        {
            Waypoint = 29865,
            coord = { x = -1364.2, y = 1393.3 },
            Range = 5,
            Zone = 371,
            _index = 179
        },
        {
            Waypoint = 29865,
            coord = { x = -1526.6, y = 1376.9 },
            Range = 5,
            Zone = 371,
            _index = 180
        },
        {
            Waypoint = 29865,
            coord = { x = -1803.2, y = 1477.8 },
            Range = 5,
            Zone = 371,
            _index = 181
        },
        {
            Done = { 29865 },
            coord = { x = -1793.6, y = 1519.8 },
            Zone = 371,
            _index = 182
        },
        {
            Done = { 29866 },
            coord = { x = -1803.3, y = 1540.7 },
            Zone = 371,
            _index = 183
        },
        {
            Done = { 29723 },
            coord = { x = -1792.2, y = 1593.2 },
            Zone = 371,
            _index = 184
        },
        {
            PickUp = { 29993 },
            coord = { x = -1822.7, y = 1513.2 },
            Zone = 371,
            _index = 185
        },
        {
            PickUp = { 29925 },
            coord = { x = -1841.3, y = 1503.4 },
            Zone = 371,
            _index = 186
        },
        {
            PickUp = { 29576 },
            coord = { x = -1922.4, y = 1508.5 },
            Zone = 371,
            _index = 187
        },
        {
            PickUp = { 29617 },
            coord = { x = -2013.1, y = 1519.6 },
            Zone = 371,
            _index = 188
        },
        {
            Waypoint = 29993,
            coord = { x = -2133.9, y = 1534.5 },
            Range = 5,
            Zone = 371,
            _index = 189
        },
        {
            Waypoint = 29993,
            coord = { x = -2348.7, y = 1460.9 },
            Range = 5,
            Zone = 371,
            _index = 190
        },
        {
            PickUp = { 29881 },
            coord = { x = -2382.6, y = 1541.7 },
            Zone = 371,
            _index = 191
        },
        {
            Done = { 29993 },
            coord = { x = -2365.7, y = 1598.2 },
            Zone = 371,
            _index = 192
        },
        {
            PickUp = { 29995 },
            coord = { x = -2365.7, y = 1598.2 },
            Zone = 371,
            _index = 193
        },
        {
            PickUp = { 29882 },
            coord = { x = -2409.5, y = 1544.7 },
            Zone = 371,
            _index = 194
        },
        {
            GetFP = 967,
            coord = { x = -2529.3, y = 1602.4 },
            Zone = 371,
            _index = 195
        },
        {
            Qpart = { [29881] = { 1 }, [29882] = { 1 } },
            coord = { x = -2261.6, y = 1594.3 },
            ExtraLineText = "LOOK_FOR_RED_FLOWERS_BENEATH_TREES",
            Range = 69,
            Zone = 371,
            _index = 196
        },
        {
            Done = { 29882 },
            coord = { x = -2411.5, y = 1545.7 },
            Zone = 371,
            _index = 197
        },
        {
            Done = { 29881 },
            coord = { x = -2381.2, y = 1543.3 },
            Zone = 371,
            _index = 198
        },
        {
            Waypoint = 29995,
            coord = { x = -2281.5, y = 1740.2 },
            Range = 5,
            Zone = 371,
            _index = 199
        },
        {
            Waypoint = 29995,
            coord = { x = -2259.6, y = 1792.3 },
            Range = 5,
            Zone = 371,
            _index = 200
        },
        {
            Done = { 29995 },
            coord = { x = -2218.6, y = 1876.6 },
            Zone = 371,
            _index = 201
        },
        {
            PickUp = { 29920 },
            coord = { x = -2218.6, y = 1876.6 },
            Zone = 371,
            _index = 202
        },
        {
            Qpart = { [29920] = { 2 } },
            coord = { x = -2324.7, y = 1862.3 },
            GossipOptionIDs = { 40636 },
            Zone = 371,
            _index = 203
        },
        {
            Qpart = { [29920] = { 3 } },
            coord = { x = -2289.9, y = 1942.1 },
            GossipOptionIDs = { 40637 },
            Zone = 371,
            _index = 204
        },
        {
            Qpart = { [29920] = { 1 } },
            coord = { x = -2217.2, y = 1996 },
            GossipOptionIDs = { 40541 },
            Zone = 371,
            _index = 205
        },
        {
            Done = { 29920 },
            coord = { x = -2220.8, y = 1877 },
            Zone = 371,
            _index = 206
        },
        {
            Waypoint = 29925,
            coord = { x = -2092.3, y = 2317.3 },
            Range = 5,
            Zone = 371,
            _index = 207
        },
        {
            Done = { 29925 },
            coord = { x = -2103.2, y = 2391.2 },
            Zone = 371,
            _index = 208
        },
        {
            PickUp = { 29928 },
            coord = { x = -2104.5, y = 2393.6 },
            Zone = 371,
            _index = 209
        },
        {
            GetFP = 970,
            coord = { x = -2098.2, y = 2401.4 },
            Zone = 371,
            _index = 210
        },
        {
            Qpart = { [29928] = { 1 } },
            coord = { x = -1923.3, y = 2160.9 },
            ExtraLineText = "KILL_MOD_TO_DROP_JADE",
            Range = 30,
            Zone = 371,
            _index = 211
        },
        {
            Done = { 29928 },
            coord = { x = -2106.4, y = 2393 },
            Zone = 371,
            _index = 212
        },
        {
            PickUp = { 29926, 29927 },
            coord = { x = -2106.4, y = 2393 },
            Zone = 371,
            _index = 213
        },
        {
            Waypoint = 29927,
            coord = { x = -1768.1, y = 2295.6 },
            Range = 5,
            Zone = 371,
            _index = 214
        },
        {
            Qpart = { [29927] = { 1 } },
            coord = { x = -1730.2, y = 2311 },
            Range = 30,
            Zone = 372,
            _index = 215
        },
        {
            Done = { 29927 },
            coord = { x = -1721.1, y = 2301.1 },
            Zone = 372,
            _index = 216
        },
        {
            PickUp = { 29929 },
            coord = { x = -1721.1, y = 2301.1 },
            Zone = 372,
            _index = 217
        },
        {
            Qpart = { [29926] = { 1, 2 }, [29929] = { 1 } },
            coord = { x = -1709.2, y = 2270 },
            Range = 45,
            Zone = 372,
            _index = 218
        },
        {
            Waypoint = 29929,
            coord = { x = -1688.1, y = 2279 },
            Range = 5,
            Zone = 373,
            _index = 219
        },
        {
            Waypoint = 29929,
            coord = { x = -1675.5, y = 2288.4 },
            Range = 5,
            Zone = 373,
            _index = 220
        },
        {
            Waypoint = 29929,
            coord = { x = -1688.7, y = 2302.2 },
            Range = 5,
            Zone = 372,
            _index = 221
        },
        {
            Waypoint = 29929,
            coord = { x = -1705.4, y = 2290.7 },
            Range = 5,
            Zone = 372,
            _index = 222
        },
        {
            Waypoint = 29929,
            coord = { x = -1750.3, y = 2310 },
            Range = 5,
            Zone = 371,
            _index = 223
        },
        {
            Done = { 29929 },
            coord = { x = -1780.5, y = 2285 },
            Zone = 371,
            _index = 224
        },
        {
            PickUp = { 29930 },
            coord = { x = -1780.5, y = 2285 },
            Zone = 371,
            _index = 225
        },
        {
            Qpart = { [29930] = { 1 } },
            coord = { x = -1780.5, y = 2285 },
            ExtraLineText = "USE_CART",
            Range = 2,
            Zone = 371,
            _index = 226
        },
        {
            Done = { 29926, 29930 },
            coord = { x = -2106, y = 2393.2 },
            Zone = 371,
            _index = 227
        },
        {
            PickUp = { 29931 },
            coord = { x = -2106, y = 2393.2 },
            Zone = 371,
            _index = 228
        },
        {
            PickUp = { 29745 },
            coord = { x = -1949, y = 2488.5 },
            Zone = 371,
            _index = 229
        },
        {
            Qpart = { [29745] = { 2 } },
            coord = { x = -1976.7, y = 2663.9 },
            Fillers = { [29745] = { 1 } },
            Range = 2,
            Zone = 371,
            _index = 230
        },
        {
            Qpart = { [29745] = { 1 } },
            coord = { x = -1972.9, y = 2640.6 },
            Range = 30,
            Zone = 371,
            _index = 231
        },
        {
            Done = { 29745 },
            NoArrow = 1,
            Zone = 371,
            _index = 232
        },
        {
            PickUp = { 29747 },
            NoArrow = 1,
            Zone = 371,
            _index = 233
        },
        {
            PickUp = { 29748 },
            coord = { x = -1939.8, y = 2694.1 },
            Zone = 371,
            _index = 234
        },
        {
            Qpart = { [29747] = { 1 }, [29748] = { 1 } },
            coord = { x = -1943.9, y = 2700.7 },
            Range = 60,
            Zone = 371,
            _index = 235
        },
        {
            Done = { 29747, 29748 },
            NoArrow = 1,
            Zone = 371,
            _index = 236
        },
        {
            PickUp = { 29749 },
            NoArrow = 1,
            Zone = 371,
            _index = 237
        },
        {
            Qpart = { [29749] = { 1 } },
            coord = { x = -1636.8, y = 2956.1 },
            Zone = 371,
            _index = 238
        },
        {
            Qpart = { [29749] = { 2 } },
            coord = { x = -1645.9, y = 2931.5 },
            ExtraLineText = "KILL_ANCIENT_SPIRITS_TO_INTERRUPT_RITUAL",
            Range = 5,
            Zone = 371,
            _index = 239
        },
        {
            Done = { 29749 },
            coord = { x = -1637, y = 2952.6 },
            Zone = 371,
            _index = 240
        },
        {
            PickUp = { 29751, 29750, 29752 },
            coord = { x = -1637, y = 2952.6 },
            Zone = 371,
            _index = 241
        },
        {
            Qpart = { [29751] = { 1 } },
            coord = { x = -1522, y = 2918.5 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 242
        },
        {
            Qpart = { [29751] = { 2 } },
            coord = { x = -1454.6, y = 2985.3 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 243
        },
        {
            Qpart = { [29751] = { 3 } },
            coord = { x = -1499.2, y = 2857.2 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 244
        },
        {
            Waypoint = 29750,
            coord = { x = -1499.1, y = 2839.2 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 371,
            _index = 245
        },
        {
            Qpart = { [29750] = { 1 }, [29752] = { 1 } },
            coord = { x = -1466.5, y = 2957 },
            Range = 60,
            Zone = 371,
            _index = 246
        },
        {
            Done = { 29750, 29751, 29752 },
            coord = { x = -1637.2, y = 2953 },
            Zone = 371,
            _index = 247
        },
        {
            PickUp = { 29753, 29756 },
            coord = { x = -1637.2, y = 2953 },
            Zone = 371,
            _index = 248
        },
        {
            Qpart = { [29753] = { 1 }, [29756] = { 1 } },
            coord = { x = -1265.3, y = 3140.3 },
            Button = { ["29753-1"] = 74808 },
            ExtraLineText = "THROW_JAR_TO_RELEASE_SPIRIT",
            Range = 30,
            Zone = 371,
            _index = 249
        },
        {
            Done = { 29753, 29756 },
            coord = { x = -1637, y = 2952.8 },
            Zone = 371,
            _index = 250
        },
        {
            PickUp = { 29754 },
            coord = { x = -1637, y = 2952.8 },
            Zone = 371,
            _index = 251
        },
        {
            Qpart = { [29754] = { 1 } },
            coord = { x = -1606.8, y = 3067.2 },
            Range = 30,
            Zone = 371,
            _index = 252
        },
        {
            Done = { 29754 },
            coord = { x = -1606.8, y = 3067.2 },
            Zone = 371,
            _index = 253
        },
        {
            PickUp = { 29755 },
            coord = { x = -1606.8, y = 3067.2 },
            Zone = 371,
            _index = 254
        },
        {
            Qpart = { [29755] = { 1 } },
            coord = { x = -1517.2, y = 3167.1 },
            ExtraLineText = "THERE_ARE_2_PHASES",
            ExtraLineText2 = "KILL_COLOSSUS",
            ExtraLineText3 = "THEN_KILL_SHAN_JITONG",
            Range = 30,
            Zone = 371,
            _index = 255
        },
        {
            Done = { 29755 },
            coord = { x = -1610.7, y = 3069.2 },
            Zone = 371,
            _index = 256
        },
        {
            Waypoint = 29617,
            coord = { x = -1179.6, y = 3038.9 },
            Range = 5,
            Zone = 371,
            _index = 257
        },
        {
            Waypoint = 29617,
            coord = { x = -1153.6, y = 2670.5 },
            Range = 5,
            Zone = 371,
            _index = 258
        },
        {
            Waypoint = 29617,
            coord = { x = -1220.7, y = 2519.2 },
            Range = 5,
            Zone = 371,
            _index = 259
        },
        {
            Waypoint = 29617,
            coord = { x = -1538.2, y = 2487.6 },
            Range = 5,
            Zone = 371,
            _index = 260
        },
        {
            GetFP = 971,
            coord = { x = -1588.1, y = 2507.6 },
            Zone = 371,
            _index = 261
        },
        {
            Done = { 29617 },
            coord = { x = -1689.3, y = 2489.5 },
            Zone = 371,
            _index = 262
        },
        {
            PickUp = { 29618 },
            coord = { x = -1689.3, y = 2489.5 },
            Zone = 371,
            _index = 263
        },
        {
            Waypoint = 29618,
            coord = { x = -1737.5, y = 2496.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 264
        },
        {
            Waypoint = 29618,
            coord = { x = -1736.9, y = 2474.5 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 265
        },
        {
            Waypoint = 29618,
            coord = { x = -1713.8, y = 2474 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 266
        },
        {
            Waypoint = 29618,
            coord = { x = -1713.9, y = 2496.9 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 267
        },
        {
            Waypoint = 29618,
            coord = { x = -1736.9, y = 2494.9 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 268
        },
        {
            Waypoint = 29618,
            coord = { x = -1733.6, y = 2476 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 269
        },
        {
            Done = { 29618 },
            coord = { x = -1706.8, y = 2485.4 },
            ExtraLineText = "UPSTAIRS",
            Zone = 371,
            _index = 270
        },
        {
            PickUp = { 29619 },
            coord = { x = -1689.9, y = 2490.2 },
            ExtraLineText = "JUMP_OFF",
            Zone = 371,
            _index = 271
        },
        {
            Qpart = { [29619] = { 1 } },
            coord = { x = -1747.5, y = 2370.1 },
            ExtraLineText = "LOOT_FROM_GROUND_OR_KILL_MOBS",
            Range = 10,
            Zone = 371,
            _index = 272
        },
        {
            Waypoint = 29619,
            coord = { x = -1627, y = 2479.8 },
            Range = 5,
            Zone = 371,
            _index = 273
        },
        {
            Done = { 29619 },
            coord = { x = -1690.3, y = 2489.6 },
            Zone = 371,
            _index = 274
        },
        {
            PickUp = { 29620 },
            coord = { x = -1690.3, y = 2489.6 },
            Zone = 371,
            _index = 275
        },
        {
            Qpart = { [29620] = { 1 } },
            coord = { x = -1532.3, y = 2573.7 },
            GossipOptionIDs = { 39493, 40364 },
            Zone = 371,
            _index = 276
        },
        {
            Done = { 29620 },
            coord = { x = -1532.3, y = 2573.7 },
            Zone = 371,
            _index = 277
        },
        {
            PickUp = { 29622, 29626 },
            coord = { x = -1559.4, y = 2552.4 },
            Zone = 371,
            _index = 278
        },
        {
            PickUp = { 29632 },
            coord = { x = -1567.2, y = 2499.9 },
            Zone = 371,
            _index = 279
        },
        {
            Qpart = { [29632] = { 1 } },
            coord = { x = -1566.6, y = 2483.1 },
            GossipOptionIDs = { 40241 },
            Range = 15,
            Zone = 371,
            _index = 280
        },
        {
            Done = { 29632 },
            coord = { x = -1566.2, y = 2498.8 },
            Zone = 371,
            _index = 281
        },
        {
            PickUp = { 29633, 29634 },
            coord = { x = -1566.2, y = 2498.8 },
            Zone = 371,
            _index = 282
        },
        {
            Qpart = { [29633] = { 1 } },
            coord = { x = -1554.5, y = 2442.2 },
            GossipOptionIDs = { 40594 },
            Zone = 371,
            _index = 283
        },
        {
            Done = { 29626 },
            coord = { x = -1453, y = 2548.5 },
            Zone = 371,
            _index = 284
        },
        {
            PickUp = { 29627 },
            coord = { x = -1453, y = 2548.5 },
            Zone = 371,
            _index = 285
        },
        {
            Qpart = { [29627] = { 2 } },
            coord = { x = -1439.2, y = 2527.4 },
            Fillers = { [29627] = { 1 } },
            BuyMerchant = { { itemID = 72954, quantity = 1, questID = 29627 } },
            Zone = 371,
            _index = 286
        },
        {
            Qpart = { [29627] = { 3 } },
            coord = { x = -1465, y = 2504.5 },
            Fillers = { [29627] = { 1 } },
            BuyMerchant = { { itemID = 72979, quantity = 3, questID = 29627 } },
            Zone = 371,
            _index = 287
        },
        {
            Qpart = { [29627] = { 1 } },
            coord = { x = -1451.3, y = 2507.9 },
            Range = 60,
            Zone = 371,
            _index = 288
        },
        {
            Done = { 29627 },
            coord = { x = -1455.2, y = 2549.1 },
            Zone = 371,
            _index = 289
        },
        {
            PickUp = { 29628, 29629, 29630 },
            coord = { x = -1455.2, y = 2549.1 },
            Zone = 371,
            _index = 290
        },
        {
            PickUp = { 29631 },
            coord = { x = -1202, y = 2546.4 },
            Zone = 371,
            _index = 291
        },
        {
            Qpart = { [29629] = { 1 }, [29631] = { 1 } },
            coord = { x = -949, y = 2684.6 },
            Range = 69,
            Zone = 371,
            _index = 292
        },
        {
            Qpart = { [29628] = { 1 } },
            coord = { x = -1184.6, y = 2833.3 },
            Fillers = { [29630] = { 1 } },
            Range = 30,
            Zone = 371,
            _index = 293
        },
        {
            Qpart = { [29630] = { 1 } },
            coord = { x = -1190.5, y = 2615.6 },
            Range = 45,
            Zone = 371,
            _index = 294
        },
        {
            Done = { 29631 },
            coord = { x = -1203.7, y = 2547.1 },
            Zone = 371,
            _index = 295
        },
        {
            Qpart = { [29628] = { 2 } },
            coord = { x = -1453.5, y = 2548.7 },
            Range = 30,
            Zone = 371,
            _index = 296
        },
        {
            Done = { 29628, 29629, 29630 },
            coord = { x = -1453.5, y = 2548.7 },
            Zone = 371,
            _index = 297
        },
        {
            Done = { 29622 },
            coord = { x = -1454.1, y = 2334.2 },
            Zone = 371,
            _index = 298
        },
        {
            PickUp = { 29623 },
            coord = { x = -1454.1, y = 2334.2 },
            Zone = 371,
            _index = 299
        },
        {
            Qpart = { [29623] = { 1 } },
            coord = { x = -1436.1, y = 2375.8 },
            ExtraLineText = "COPY_INSTRUCTOR",
            ExtraLineText2 = "PUNCHES_PRESS_1",
            ExtraLineText3 = "KICKS_PRESS_2",
            ExtraLineText4 = "GROWLS_PRESS_3",
            Range = 15,
            Zone = 371,
            _index = 300
        },
        {
            Done = { 29623 },
            coord = { x = -1454.2, y = 2332.4 },
            Zone = 371,
            _index = 301
        },
        {
            PickUp = { 29624 },
            coord = { x = -1454.2, y = 2332.4 },
            Zone = 371,
            _index = 302
        },
        {
            Qpart = { [29624] = { 1 } },
            coord = { x = -1417.3, y = 2396.8 },
            ExtraLineText = "HIT_BAG_ACCORDING_TO_YELLOW_TEXT_IN_MIDDLE_SCREEN",
            Range = 30,
            Zone = 371,
            _index = 303
        },
        {
            Done = { 29624 },
            coord = { x = -1454.4, y = 2333.6 },
            Zone = 371,
            _index = 304
        },
        {
            Waypoint = 29633,
            coord = { x = -1392.2, y = 2488.5 },
            Range = 5,
            Zone = 371,
            _index = 305
        },
        {
            Done = { 29633 },
            coord = { x = -1566.6, y = 2498.1 },
            Zone = 371,
            _index = 306
        },
        {
            Qpart = { [29634] = { 1 } },
            coord = { x = -1660.1, y = 2532.9 },
            GossipOptionIDs = { 40595 },
            Zone = 371,
            _index = 307
        },
        {
            Done = { 29634 },
            coord = { x = -1567.4, y = 2500.3 },
            Zone = 371,
            _index = 308
        },
        {
            PickUp = { 29635 },
            coord = { x = -1567.4, y = 2500.3 },
            Zone = 371,
            _index = 309
        },
        {
            Qpart = { [29635] = { 1 } },
            coord = { x = -1560.1, y = 2552.1 },
            GossipOptionIDs = { 40337 },
            Zone = 371,
            _index = 310
        },
        {
            Done = { 29635 },
            coord = { x = -1567.7, y = 2499.1 },
            Zone = 371,
            _index = 311
        },
        {
            PickUp = { 29636 },
            coord = { x = -1567.7, y = 2499.1 },
            Zone = 371,
            _index = 312
        },
        {
            Done = { 29636 },
            coord = { x = -1268.9, y = 2532.6 },
            Zone = 371,
            _index = 313
        },
        {
            PickUp = { 29637 },
            coord = { x = -1268.9, y = 2532.6 },
            Zone = 371,
            _index = 314
        },
        {
            Qpart = { [29637] = { 1 } },
            coord = { x = -1270.8, y = 2573.8 },
            Button = { ["29637-1"] = 73369 },
            ExtraLineText = "USE_FIREWORKS_TO_START_COMBAT_AND_SURVIVE_2_MINUTES",
            Range = 5,
            Zone = 371,
            _index = 315
        },
        {
            Done = { 29637 },
            coord = { x = -1269.2, y = 2532.1 },
            Zone = 371,
            _index = 316
        },
        {
            PickUp = { 29647 },
            coord = { x = -1269.2, y = 2532.1 },
            Zone = 371,
            _index = 317
        },
        {
            Waypoint = 29647,
            coord = { x = -1530.2, y = 2487.8 },
            Range = 5,
            Zone = 371,
            _index = 318
        },
        {
            Waypoint = 29647,
            coord = { x = -1573.7, y = 2524.4 },
            Range = 5,
            Zone = 371,
            _index = 319
        },
        {
            Done = { 29647 },
            coord = { x = -1533.2, y = 2572.5 },
            Zone = 371,
            _index = 320
        },
        {
            UseFlightPath = 29576,
            NodeID = 895,
            coord = { x = -1589.8, y = 2508.5 },
            ETA = 39,
            Zone = 371,
            _index = 321
        },
        {
            Waypoint = 29576,
            coord = { x = -1803.9, y = 1478.5 },
            Range = 5,
            Zone = 371,
            _index = 322
        },
        {
            Waypoint = 29576,
            coord = { x = -1774.4, y = 1292 },
            Range = 5,
            Zone = 371,
            _index = 323
        },
        {
            Waypoint = 29576,
            coord = { x = -1756.1, y = 991.3 },
            Range = 5,
            Zone = 371,
            _index = 324
        },
        {
            Waypoint = 29576,
            coord = { x = -1611.4, y = 844.2 },
            Range = 5,
            Zone = 371,
            _index = 325
        },
        {
            Waypoint = 29576,
            coord = { x = -1488.4, y = 843 },
            Range = 5,
            Zone = 371,
            _index = 326
        },
        {
            Waypoint = 29576,
            coord = { x = -1463.3, y = 764.7 },
            Range = 5,
            Zone = 371,
            _index = 327
        },
        {
            Waypoint = 29576,
            coord = { x = -1488.2, y = 551.8 },
            Range = 5,
            Zone = 371,
            _index = 328
        },
        {
            Waypoint = 29576,
            coord = { x = -1449.6, y = 437.9 },
            Range = 5,
            Zone = 371,
            _index = 329
        },
        {
            Waypoint = 29576,
            coord = { x = -1563.2, y = 276.7 },
            Range = 5,
            Zone = 371,
            _index = 330
        },
        {
            Done = { 29576 },
            coord = { x = -1587.7, y = 118.5 },
            Zone = 371,
            _index = 331
        },
        {
            PickUp = { 29578, 29579 },
            coord = { x = -1587.7, y = 118.5 },
            Zone = 371,
            _index = 332
        },
        {
            PickUp = { 29580, 29585 },
            coord = { x = -1570.5, y = 126.8 },
            Zone = 371,
            _index = 333
        },
        {
            Qpart = { [29578] = { 1, 2 }, [29579] = { 1 }, [29580] = { 1 }, [29585] = { 1 } },
            coord = { x = -1621.6, y = 156.5 },
            Button = { ["29585-1"] = 72578 },
            GossipOptionIDs = { 39167 },
            Range = 69,
            Zone = 371,
            _index = 334
        },
        {
            Done = { 29578, 29579 },
            coord = { x = -1586.7, y = 118.9 },
            Zone = 371,
            _index = 335
        },
        {
            Done = { 29585, 29580 },
            coord = { x = -1568.3, y = 116.5 },
            Zone = 371,
            _index = 336
        },
        {
            PickUp = { 29586 },
            coord = { x = -1568.3, y = 116.5 },
            Zone = 371,
            _index = 337
        },
        {
            Qpart = { [29586] = { 1 } },
            coord = { x = -1390.6, y = 201.7 },
            Range = 5,
            Zone = 371,
            _index = 338
        },
        {
            Done = { 29586 },
            coord = { x = -1409.9, y = 210 },
            Zone = 371,
            _index = 339
        },
        {
            PickUp = { 29587, 29670 },
            coord = { x = -1409.9, y = 210 },
            Zone = 371,
            _index = 340
        },
        {
            Qpart = { [29670] = { 1 } },
            coord = { x = -1192.1, y = 98 },
            Fillers = { [29587] = { 1 } },
            Range = 30,
            Zone = 371,
            _index = 341
        },
        {
            Qpart = { [29587] = { 1 } },
            coord = { x = -1306.2, y = 158.7 },
            Range = 30,
            Zone = 371,
            _index = 342
        },
        {
            Done = { 29587, 29670 },
            coord = { x = -1409.7, y = 210.7 },
            Zone = 371,
            _index = 343
        },
        {
            Waypoint = 29931,
            coord = { x = -1448.6, y = 436 },
            Range = 5,
            Zone = 371,
            _index = 344
        },
        {
            Waypoint = 29931,
            coord = { x = -1512.5, y = 656.4 },
            Range = 5,
            Zone = 371,
            _index = 345
        },
        {
            Waypoint = 29931,
            coord = { x = -1497.4, y = 844.6 },
            Range = 5,
            Zone = 371,
            _index = 346
        },
        {
            Waypoint = 29931,
            coord = { x = -1550.9, y = 853.1 },
            Range = 5,
            Zone = 371,
            _index = 347
        },
        {
            Done = { 29931 },
            coord = { x = -1921.9, y = 796.5 },
            Zone = 371,
            _index = 348
        },
        {
            PickUp = { 30495 },
            coord = { x = -1921.9, y = 796.5 },
            Zone = 371,
            _index = 349
        },
        {
            Qpart = { [30495] = { 3 } },
            coord = { x = -1912.8, y = 858.4 },
            GossipOptionIDs = { 39632 },
            Zone = 371,
            _index = 350
        },
        {
            UseFlightPath = 30495,
            NodeID = 1080,
            coord = { x = -1912.8, y = 858.4 },
            ExtraLineText = "TALK_NPC",
            GossipOptionIDs = { 39631 },
            ETA = 24,
            RaidIcon = 59392,
            Zone = 371,
            _index = 351
        },
        {
            Qpart = { [30495] = { 4 } },
            coord = { x = -1870.1, y = 828.7 },
            GossipOptionIDs = { 39805 },
            Zone = 371,
            _index = 352
        },
        {
            UseFlightPath = 30495,
            NodeID = 968,
            coord = { x = -1861.6, y = 836.1 },
            ExtraLineText = "TALK_NPC",
            GossipOptionIDs = { 39806 },
            ETA = 11,
            RaidIcon = 59400,
            Zone = 371,
            _index = 353
        },
        {
            Qpart = { [30495] = { 2 } },
            coord = { x = -1826.2, y = 842.7 },
            GossipOptionIDs = { 40697 },
            Zone = 371,
            _index = 354
        },
        {
            Qpart = { [30495] = { 1 } },
            coord = { x = -1784.8, y = 775.3 },
            GossipOptionIDs = { 39183 },
            Zone = 371,
            _index = 355
        },
        {
            Done = { 30495 },
            coord = { x = -1921.9, y = 797.2 },
            Zone = 371,
            _index = 356
        },
        {
            PickUp = { 29932 },
            coord = { x = -1921.9, y = 797.2 },
            Zone = 371,
            _index = 357
        },
        {
            UseFlightPath = 29932,
            NodeID = 968,
            coord = { x = -1912.6, y = 858.5 },
            ExtraLineText = "TALK_NPC",
            GossipOptionIDs = { 39633 },
            ETA = 48,
            RaidIcon = 59392,
            Zone = 371,
            _index = 358
        },
        {
            Qpart = { [29932] = { 1 } },
            coord = { x = -2447.7, y = 995.7 },
            GossipOptionIDs = { 40586 },
            Zone = 371,
            _index = 359
        },
        {
            Done = { 29932 },
            coord = { x = -2607.3, y = 921.2 },
            Zone = 371,
            _index = 360
        },
        {
            PickUp = { 29997, 29998 },
            coord = { x = -2607.3, y = 921.2 },
            Zone = 371,
            _index = 361
        },
        {
            PickUp = { 29999, 30005 },
            coord = { x = -2600.3, y = 905.6 },
            Zone = 371,
            _index = 362
        },
        {
            Qpart = { [29999] = { 3 } },
            coord = { x = -2495.2, y = 935.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 363
        },
        {
            Qpart = { [29999] = { 1 } },
            coord = { x = -2680.6, y = 1010.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 364
        },
        {
            Qpart = { [29999] = { 2 } },
            coord = { x = -2610.7, y = 793.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 365
        },
        {
            Done = { 29998 },
            coord = { x = -2476.7, y = 839.3 },
            Zone = 371,
            _index = 366
        },
        {
            PickUp = { 30001, 30002 },
            coord = { x = -2476.7, y = 839.3 },
            Zone = 371,
            _index = 367
        },
        {
            Qpart = { [29999] = { 4 } },
            coord = { x = -2457.2, y = 843.9 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 368
        },
        {
            Qpart = { [30001] = { 1 }, [30002] = { 1 } },
            coord = { x = -2467.3, y = 856.1 },
            ExtraLineText = "CLICK_ON_THE_INFESTED_BOOKS_THEN_CLICK_ON_THE_BOOKWORMS_THAT_COME_OUT_TO_SQUISH_THEM",
            Range = 30,
            Zone = 371,
            _index = 369
        },
        {
            Done = { 30001, 30002 },
            coord = { x = -2477, y = 839.8 },
            Zone = 371,
            _index = 370
        },
        {
            PickUp = { 30004 },
            coord = { x = -2477, y = 839.8 },
            Zone = 371,
            _index = 371
        },
        {
            Waypoint = 29997,
            coord = { x = -2445.4, y = 870.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 372
        },
        {
            Waypoint = 29997,
            coord = { x = -2506.5, y = 851.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 373
        },
        {
            Waypoint = 29997,
            coord = { x = -2488.5, y = 812.4 },
            Range = 5,
            Zone = 371,
            _index = 374
        },
        {
            Waypoint = 29997,
            coord = { x = -2430.8, y = 832.8 },
            Range = 5,
            Zone = 371,
            _index = 375
        },
        {
            Waypoint = 29997,
            coord = { x = -2449, y = 893.3 },
            Range = 5,
            Zone = 371,
            _index = 376
        },
        {
            Waypoint = 29997,
            coord = { x = -2479.9, y = 883.2 },
            Range = 5,
            Zone = 371,
            _index = 377
        },
        {
            Waypoint = 29997,
            coord = { x = -2520.1, y = 1008.5 },
            Range = 5,
            Zone = 371,
            _index = 378
        },
        {
            Waypoint = 29997,
            coord = { x = -2488.7, y = 1025.3 },
            Range = 5,
            Zone = 371,
            _index = 379
        },
        {
            Qpart = { [29997] = { 1 } },
            coord = { x = -2535.9, y = 1054.9 },
            ExtraLineText = "KILL_WATER_ELEMENTS_UNTIL_YOU_DROP_THE_STAFF",
            Range = 30,
            Zone = 371,
            _index = 380
        },
        {
            Done = { 29997 },
            coord = { x = -2567.7, y = 1045 },
            Zone = 371,
            _index = 381
        },
        {
            PickUp = { 30011 },
            coord = { x = -2567.7, y = 1045 },
            Zone = 371,
            _index = 382
        },
        {
            Qpart = { [30005] = { 1 } },
            coord = { x = -2554.9, y = 933 },
            Range = 69,
            Zone = 371,
            _index = 383
        },
        {
            Done = { 30004, 30011 },
            coord = { x = -2607.4, y = 921.5 },
            Zone = 371,
            _index = 384
        },
        {
            Done = { 29999, 30005 },
            coord = { x = -2600, y = 905.7 },
            Zone = 371,
            _index = 385
        },
        {
            PickUp = { 30000 },
            coord = { x = -2600.4, y = 905.6 },
            Zone = 371,
            _index = 386
        },
        {
            Qpart = { [30000] = { 1 } },
            coord = { x = -2157.9, y = 945.7 },
            Range = 5,
            Zone = 371,
            _index = 387
        },
        {
            Done = { 30000 },
            coord = { x = -2446.8, y = 994.9 },
            Zone = 371,
            _index = 388
        },
        {
            PickUp = { 30498 },
            coord = { x = -2446.5, y = 995 },
            Zone = 371,
            _index = 389
        },
        {
            UseFlightPath = 30498,
            NodeID = 972,
            coord = { x = -2358.7, y = 778.2 },
            GossipOptionIDs = { 28346 },
            ETA = 45,
            Zone = 371,
            _index = 390
        },
        {
            PickUp = { 30565 },
            coord = { x = -2636.3, y = -179 },
            Zone = 371,
            _index = 391
        },
        {
            PickUp = { 30568 },
            coord = { x = -2604.1, y = -103 },
            Zone = 371,
            _index = 392
        },
        {
            Done = { 30498 },
            coord = { x = -2604.1, y = -103 },
            Zone = 371,
            _index = 393
        },
        {
            Qpart = { [30568] = { 2 } },
            coord = { x = -2366.9, y = -74.2 },
            GossipOptionIDs = { 39488 },
            Range = 5,
            Zone = 371,
            _index = 394
        },
        {
            Qpart = { [30568] = { 1 } },
            coord = { x = -2684.3, y = -241.7 },
            GossipOptionIDs = { 39293 },
            Zone = 371,
            _index = 395
        },
        {
            Qpart = { [30568] = { 3 } },
            coord = { x = -2718.1, y = -406.1 },
            Range = 15,
            Zone = 371,
            _index = 396
        },
        {
            Qpart = { [30565] = { 1, 2 } },
            coord = { x = -2977.7, y = 36 },
            Range = 30,
            Zone = 371,
            _index = 397
        },
        {
            Done = { 30565 },
            coord = { x = -2638.2, y = -178.5 },
            Zone = 371,
            _index = 398
        },
        {
            Done = { 30568 },
            coord = { x = -2603.4, y = -103.3 },
            Zone = 371,
            _index = 399
        },
        {
            PickUp = { 31362 },
            coord = { x = -2655.8, y = -123.8 },
            Zone = 371,
            _index = 400
        },
        {
            UseFlightPath = 31362,
            NodeID = 1080,
            coord = { x = -2655.8, y = -121.1 },
            GossipOptionIDs = { 28425 },
            ETA = 65,
            Zone = 371,
            _index = 401
        },
        {
            Qpart = { [31362] = { 1 } },
            coord = { x = -1656.9, y = 535.9 },
            Button = { ["31362-1"] = 80071 },
            Range = 2,
            Zone = 371,
            _index = 402
        },
        {
            Done = { 31362 },
            coord = { x = -1672.6, y = 529.7 },
            Zone = 371,
            _index = 403
        },
        {
            PickUp = { 31303 },
            coord = { x = -1674.1, y = 529.4 },
            Zone = 371,
            _index = 404
        },
        {
            GetFP = 1080,
            coord = { x = -1569.2, y = 473.4 },
            Zone = 371,
            _index = 405
        },
        {
            Qpart = { [31303] = { 1 } },
            coord = { x = -1674.3, y = 532 },
            GossipOptionIDs = { 38770 },
            Zone = 371,
            _index = 406
        },
        {
            Done = { 31303 },
            coord = { x = -1989.8, y = 791.9 },
            Zone = 371,
            _index = 407
        },
        {
            PickUp = { 30500, 30502, 31319 },
            coord = { x = -1989.7, y = 792.6 },
            Zone = 371,
            _index = 408
        },
        {
            Qpart = { [31319] = { 1 } },
            coord = { x = -1880, y = 764.4 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["31319-1"] = 86511 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 409
        },
        {
            Qpart = { [31319] = { 2 } },
            coord = { x = -1786.7, y = 782.3 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["31319-2"] = 86511 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 410
        },
        {
            Qpart = { [31319] = { 3 } },
            coord = { x = -1866.6, y = 897.1 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["31319-3"] = 86511 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 411
        },
        {
            Qpart = { [30500] = { 1 }, [30502] = { 1 } },
            coord = { x = -1974.6, y = 783.5 },
            Button = { ["30502-1"] = 80074 },
            Range = 69,
            Zone = 371,
            _index = 412
        },
        {
            Done = { 30500, 30502, 31319 },
            coord = { x = -1988.9, y = 791.1 },
            Zone = 371,
            _index = 413
        },
        {
            PickUp = { 30648 },
            coord = { x = -1990.8, y = 792.6 },
            Zone = 371,
            _index = 414
        },
        {
            Qpart = { [30648] = { 1 } },
            coord = { x = -1990.8, y = 792.6 },
            GossipOptionIDs = { 29679 },
            ETA = 102,
            Zone = 371,
            _index = 415
        },
        {
            Done = { 30648 },
            coord = { x = -695, y = 527.6 },
            Zone = 376,
            _index = 416
        },
        {
            Done = { 32018 },
            coord = { x = -693.6, y = 518 },
            DontHaveAura = 424143,
            Zone = 376,
            _index = 417
        },
        {
            RouteCompleted = 1,
            _index = 418
        }
    }

    APR.RouteQuestStepList["418-Krasarang Wilds"] = {
        {
            PickUp = { 30079 },
            coord = { x = -628.1, y = -332.2 },
            Zone = 418,
            _index = 1
        },
        {
            GetFP = 986,
            coord = { x = -643.8, y = -370.2 },
            Zone = 418,
            _index = 2
        },
        {
            Qpart = { [30079] = { 4 } },
            coord = { x = -609, y = -347.7 },
            Range = 2,
            Zone = 418,
            _index = 3
        },
        {
            PickUp = { 30080 },
            coord = { x = -609, y = -347.7 },
            Zone = 418,
            _index = 4
        },
        {
            Qpart = { [30079] = { 1 } },
            coord = { x = -615, y = -366.9 },
            Range = 2,
            Zone = 418,
            _index = 5
        },
        {
            Qpart = { [30079] = { 3 } },
            coord = { x = -592.1, y = -398.8 },
            Range = 2,
            Zone = 418,
            _index = 6
        },
        {
            Qpart = { [30079] = { 2 } },
            coord = { x = -682.5, y = -378.6 },
            Range = 2,
            Zone = 418,
            _index = 7
        },
        {
            Qpart = { [30080] = { 1 } },
            coord = { x = -862.7, y = -324.4 },
            Range = 2,
            Zone = 418,
            _index = 8
        },
        {
            Done = { 30080 },
            coord = { x = -862.7, y = -324.4 },
            Zone = 418,
            _index = 9
        },
        {
            PickUp = { 30082 },
            coord = { x = -862.7, y = -324.4 },
            Zone = 418,
            _index = 10
        },
        {
            Qpart = { [30082] = { 1 } },
            coord = { x = -862.7, y = -324.4 },
            ExtraLineText = "TALK_TO_NPC_THEN_PUSH_HIM_TO_VILLAGE",
            GossipOptionIDs = { 40643, 40646 },
            Range = 5,
            Zone = 418,
            _index = 11
        },
        {
            Done = { 30082 },
            coord = { x = -608.8, y = -348.3 },
            Zone = 418,
            _index = 12
        },
        {
            PickUp = { 30091 },
            coord = { x = -608.8, y = -348.3 },
            Zone = 418,
            _index = 13
        },
        {
            Done = { 30079 },
            coord = { x = -625.3, y = -332.8 },
            Zone = 418,
            _index = 14
        },
        {
            PickUp = { 30081 },
            coord = { x = -625.3, y = -332.8 },
            Zone = 418,
            _index = 15
        },
        {
            Qpart = { [30081] = { 1, 2, 3 }, [30091] = { 1 } },
            coord = { x = -591.8, y = -458.2 },
            Range = 30,
            Zone = 418,
            _index = 16
        },
        {
            Done = { 30091 },
            coord = { x = -609.8, y = -348.1 },
            Zone = 418,
            _index = 17
        },
        {
            PickUp = { 30083, 30084 },
            coord = { x = -609.8, y = -348.1 },
            Zone = 418,
            _index = 18
        },
        {
            Done = { 30081 },
            coord = { x = -627.1, y = -331.2 },
            Zone = 418,
            _index = 19
        },
        {
            PickUp = { 30088 },
            coord = { x = -627.1, y = -331.2 },
            Zone = 418,
            _index = 20
        },
        {
            Qpart = { [30084] = { 2 } },
            coord = { x = -514.2, y = -639 },
            Fillers = { [30088] = { 1 } },
            Button = { ["30084-2"] = 78928 },
            Range = 5,
            Zone = 418,
            _index = 21
        },
        {
            Qpart = { [30084] = { 1 } },
            coord = { x = -467.2, y = -676.4 },
            Fillers = { [30088] = { 1 } },
            Button = { ["30084-1"] = 78928 },
            Range = 5,
            Zone = 418,
            _index = 22
        },
        {
            Qpart = { [30084] = { 3 } },
            coord = { x = -388.6, y = -662.1 },
            Fillers = { [30088] = { 1 } },
            Button = { ["30084-3"] = 78928 },
            Range = 30,
            Zone = 418,
            _index = 23
        },
        {
            Qpart = { [30088] = { 1 } },
            coord = { x = -452.7, y = -645.8 },
            Range = 30,
            Zone = 418,
            _index = 24
        },
        {
            Waypoint = 30083,
            coord = { x = -363, y = -409.1 },
            Range = 5,
            Zone = 418,
            _index = 25
        },
        {
            Qpart = { [30088] = { 2 } },
            coord = { x = -218.8, y = -381.8 },
            Fillers = { [30083] = { 1 } },
            Range = 5,
            Zone = 376,
            _index = 26
        },
        {
            Qpart = { [30083] = { 1 } },
            coord = { x = -325.6, y = -386.9 },
            Range = 30,
            Zone = 376,
            _index = 27
        },
        {
            Done = { 30083, 30084 },
            coord = { x = -606.9, y = -347.2 },
            Zone = 418,
            _index = 28
        },
        {
            Done = { 30088 },
            coord = { x = -625.6, y = -331 },
            Zone = 418,
            _index = 29
        },
        {
            PickUp = { 30089 },
            coord = { x = -627, y = -331.6 },
            Zone = 418,
            _index = 30
        },
        {
            Qpart = { [30089] = { 1 } },
            coord = { x = -633.9, y = -373.9 },
            Button = { ["30089-1"] = 79021 },
            Range = 30,
            Zone = 418,
            _index = 31
        },
        {
            Done = { 30089 },
            coord = { x = -626.3, y = -332.5 },
            Zone = 418,
            _index = 32
        },
        {
            PickUp = { 30090 },
            coord = { x = -626.3, y = -332.5 },
            Zone = 418,
            _index = 33
        },
        {
            Qpart = { [30090] = { 1 } },
            coord = { x = -632.3, y = -376 },
            Button = { ["30090-1"] = 79057 },
            Range = 30,
            Zone = 418,
            _index = 34
        },
        {
            Qpart = { [30090] = { 2 } },
            coord = { x = -634, y = -381.6 },
            Button = { ["30090-2"] = 79057 },
            Range = 2,
            Zone = 418,
            _index = 35
        },
        {
            Done = { 30090 },
            coord = { x = -626.6, y = -331.9 },
            Zone = 418,
            _index = 36
        },
        {
            PickUp = { 30133 },
            PickUpDB = { 30133, 30178 },
            coord = { x = -610.3, y = -347.6 },
            Zone = 418,
            _index = 37
        },
        {
            PickUp = { 30352, 30353 },
            coord = { x = -222.8, y = -914.7 },
            Zone = 418,
            _index = 38
        },
        {
            PickUp = { 30274 },
            coord = { x = -158.4, y = -1076.3 },
            Zone = 418,
            _index = 39
        },
        {
            Qpart = { [30178] = { 1 } },
            coord = { x = -158.4, y = -1076.3 },
            GossipOptionIDs = { 41038 },
            Zone = 418,
            _index = 40
        },
        {
            Qpart = { [30274] = { 2 } },
            coord = { x = -178.1, y = -1097.2 },
            Range = 2,
            Zone = 418,
            _index = 41
        },
        {
            Qpart = { [30274] = { 3 } },
            coord = { x = -187, y = -1167.4 },
            Range = 5,
            Zone = 418,
            _index = 42
        },
        {
            Qpart = { [30274] = { 1 } },
            coord = { x = -237.1, y = -1095.8 },
            Range = 2,
            Zone = 418,
            _index = 43
        },
        {
            Done = { 30274, 29874 },
            coord = { x = -213.7, y = -1130.4 },
            Zone = 418,
            _index = 44
        },
        {
            PickUp = { 30344, 30384, 30350 },
            coord = { x = -212.5, y = -1130.4 },
            Zone = 418,
            _index = 45
        },
        {
            GetFP = 988,
            coord = { x = -228.5, y = -1125.6 },
            Zone = 418,
            _index = 46
        },
        {
            Qpart = { [30344] = { 1 } },
            coord = { x = -243.1, y = -811.3 },
            Fillers = { [30350] = { 1 }, [30352] = { 1 }, [30353] = { 1 } },
            Range = 30,
            Zone = 418,
            _index = 47
        },
        {
            Qpart = { [30384] = { 1 } },
            coord = { x = -64.9, y = -885.2 },
            Fillers = { [30350] = { 1 }, [30352] = { 1 }, [30353] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 48
        },
        {
            Qpart = { [30350] = { 1 }, [30352] = { 1 }, [30353] = { 1 } },
            coord = { x = -60.7, y = -1027.9 },
            ExtraLineText = "TIGERS_ARE_INVISIBLE_AROUND_BIRDS",
            Range = 100,
            Zone = 418,
            _index = 49
        },
        {
            Done = { 30352, 30353 },
            coord = { x = -222.6, y = -914.3 },
            Zone = 418,
            _index = 50
        },
        {
            PickUp = { 31262, 31260 },
            coord = { x = -222.6, y = -914.3 },
            Zone = 418,
            _index = 51
        },
        {
            Qpart = { [31262] = { 1 } },
            coord = { x = -7.9, y = -751.6 },
            Range = 5,
            Zone = 418,
            _index = 52
        },
        {
            Qpart = { [31260] = { 1 } },
            coord = { x = 61.6, y = -1112.2 },
            Range = 5,
            Zone = 418,
            _index = 53
        },
        {
            Done = { 31262, 31260 },
            coord = { x = -222.4, y = -914.6 },
            Zone = 418,
            _index = 54
        },
        {
            Done = { 30344, 30384, 30350 },
            coord = { x = -212.4, y = -1131.6 },
            Zone = 418,
            _index = 55
        },
        {
            PickUp = { 30346, 30349, 30351 },
            coord = { x = -212.9, y = -1131.4 },
            Zone = 418,
            _index = 56
        },
        {
            Qpart = { [30346] = { 1 } },
            coord = { x = 346.2, y = -1187.8 },
            Fillers = { [30349] = { 1, 2, 3 }, [30351] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 57
        },
        {
            Done = { 30346 },
            NoArrow = 1,
            Zone = 418,
            _index = 58
        },
        {
            PickUp = { 30347 },
            NoArrow = 1,
            Zone = 418,
            _index = 59
        },
        {
            Qpart = { [30349] = { 1, 2, 3 }, [30351] = { 1 } },
            coord = { x = 344, y = -1252.5 },
            Range = 100,
            Zone = 418,
            _index = 60
        },
        {
            Done = { 30351 },
            NoArrow = 1,
            Zone = 418,
            _index = 61
        },
        {
            Qpart = { [30347] = { 1 } },
            coord = { x = 515.1, y = -1133 },
            GossipOptionIDs = { 39799 },
            Range = 5,
            Zone = 418,
            _index = 62
        },
        {
            Done = { 30347, 30349 },
            coord = { x = -213.7, y = -1131.3 },
            Zone = 418,
            _index = 63
        },
        {
            PickUp = { 30348 },
            coord = { x = -213.7, y = -1131.3 },
            Zone = 418,
            _index = 64
        },
        {
            Qpart = { [30348] = { 1 } },
            coord = { x = -213.7, y = -1131.3 },
            Range = 30,
            Zone = 418,
            _index = 65
        },
        {
            Done = { 30348 },
            coord = { x = -213.7, y = -1131.3 },
            Zone = 418,
            _index = 66
        },
        {
            PickUp = { 30363 },
            coord = { x = -213.7, y = -1131.3 },
            Zone = 418,
            _index = 67
        },
        {
            Qpart = { [30363] = { 1 } },
            coord = { x = 888.7, y = -1466.3 },
            Zone = 418,
            _index = 68
        },
        {
            Done = { 30178 },
            coord = { x = 875.4, y = -1450.5 },
            Zone = 418,
            _index = 69
        },
        {
            PickUp = { 30269 },
            coord = { x = 875.4, y = -1450.5 },
            Zone = 418,
            _index = 70
        },
        {
            PickUp = { 30269 },
            coord = { x = 876, y = -1450.9 },
            Zone = 418,
            _index = 71
        },
        {
            Waypoint = 30269,
            coord = { x = 895.2, y = -1308.8 },
            ExtraLineText = "ESCORTS_NPC",
            GossipOptionIDs = { 40208 },
            Range = 1,
            Zone = 418,
            _index = 72
        },
        {
            Qpart = { [30269] = { 1 } },
            coord = { x = 897.3, y = -1234.7 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 2,
            Zone = 418,
            _index = 73
        },
        {
            Done = { 30269 },
            coord = { x = 1043.9, y = -1163.2 },
            Zone = 418,
            _index = 74
        },
        {
            PickUp = { 30270, 30694 },
            coord = { x = 1045, y = -1163.2 },
            Zone = 418,
            _index = 75
        },
        {
            PickUp = { 30268 },
            coord = { x = 1050.3, y = -1193.7 },
            Zone = 418,
            _index = 76
        },
        {
            Qpart = { [30270] = { 1 }, [30694] = { 1 } },
            coord = { x = 783.7, y = -1204.4 },
            Button = { ["30694-1"] = 80828 },
            Range = 60,
            Zone = 418,
            _index = 77
        },
        {
            Qpart = { [30268] = { 1 } },
            coord = { x = 1080.4, y = -1269.1 },
            Range = 30,
            Zone = 418,
            _index = 78
        },
        {
            Done = { 30268 },
            coord = { x = 1050, y = -1193.5 },
            Zone = 418,
            _index = 79
        },
        {
            Done = { 30270, 30694 },
            coord = { x = 1045.3, y = -1163.1 },
            Zone = 418,
            _index = 80
        },
        {
            PickUp = { 30272, 30695, 30271 },
            coord = { x = 1045.3, y = -1163.1 },
            Zone = 418,
            _index = 81
        },
        {
            Qpart = { [30695] = { 1 } },
            coord = { x = 1179.5, y = -1810 },
            Fillers = { [30271] = { 1 }, [30272] = { 1 } },
            ExtraLineText = "KILL_HAUNTS_NEAR_MONKS_INSPIRE",
            Range = 5,
            Zone = 418,
            _index = 82
        },
        {
            Qpart = { [30695] = { 2 } },
            coord = { x = 939.3, y = -1804.5 },
            Fillers = { [30271] = { 1 }, [30272] = { 1 } },
            ExtraLineText = "KILL_HAUNTS_NEAR_MONKS_INSPIRE",
            Range = 5,
            Zone = 418,
            _index = 83
        },
        {
            Done = { 30695 },
            NoArrow = 1,
            Zone = 418,
            _index = 84
        },
        {
            Qpart = { [30271] = { 1 }, [30272] = { 1 } },
            coord = { x = 1053.8, y = -1678.7 },
            ExtraLineText = "KILL_HAUNTS_NEAR_MONKS_INSPIRE",
            Range = 60,
            Zone = 418,
            _index = 85
        },
        {
            Done = { 30271, 30272 },
            NoArrow = 1,
            Zone = 418,
            _index = 86
        },
        {
            PickUp = { 30273 },
            NoArrow = 1,
            Zone = 418,
            _index = 87
        },
        {
            Waypoint = 30273,
            coord = { x = 1053.3, y = -1732.4 },
            Range = 5,
            Zone = 418,
            _index = 88
        },
        {
            Waypoint = 30273,
            coord = { x = 1053.2, y = -1900.6 },
            Range = 5,
            Zone = 418,
            _index = 89
        },
        {
            Waypoint = 30273,
            coord = { x = 1077.9, y = -1894.3 },
            Range = 5,
            Zone = 418,
            _index = 90
        },
        {
            Qpart = { [30273] = { 1 } },
            coord = { x = 1053.9, y = -1815.6 },
            GossipOptionIDs = { 39489 },
            Range = 3,
            Zone = 418,
            _index = 91
        },
        {
            Waypoint = 30273,
            coord = { x = 1052.4, y = -1896.4 },
            Range = 5,
            Zone = 418,
            _index = 92
        },
        {
            Done = { 30273 },
            coord = { x = 1053, y = -1647.9 },
            Zone = 418,
            _index = 93
        },
        {
            PickUp = { 30667 },
            coord = { x = 526, y = -2464.4 },
            Zone = 418,
            _index = 94
        },
        {
            PickUp = { 30666 },
            coord = { x = 533, y = -2511.9 },
            Zone = 418,
            _index = 95
        },
        {
            GetFP = 993,
            coord = { x = 487.9, y = -2504.5 },
            Zone = 418,
            _index = 96
        },
        {
            Qpart = { [30666] = { 1 } },
            coord = { x = 727.7, y = -2269 },
            Fillers = { [30667] = { 1, 2, 3 } },
            Range = 30,
            Zone = 418,
            _index = 97
        },
        {
            Qpart = { [30667] = { 1, 2, 3 } },
            coord = { x = 810.1, y = -2268.7 },
            Range = 30,
            Zone = 418,
            _index = 98
        },
        {
            Done = { 30667 },
            coord = { x = 526.4, y = -2463.2 },
            Zone = 418,
            _index = 99
        },
        {
            Done = { 30666 },
            coord = { x = 532.3, y = -2512 },
            Zone = 418,
            _index = 100
        },
        {
            PickUp = { 30668 },
            coord = { x = 532.3, y = -2512 },
            Zone = 418,
            _index = 101
        },
        {
            Qpart = { [30668] = { 2 } },
            coord = { x = 498.8, y = -2545.7 },
            Range = 2,
            Zone = 418,
            _index = 102
        },
        {
            Qpart = { [30668] = { 1 } },
            coord = { x = 491.1, y = -2490.5 },
            Range = 2,
            Zone = 418,
            _index = 103
        },
        {
            Done = { 30668 },
            coord = { x = 532.9, y = -2512.3 },
            Zone = 418,
            _index = 104
        },
        {
            PickUp = { 30669 },
            coord = { x = 532.9, y = -2512.3 },
            Zone = 418,
            _index = 105
        },
        {
            Qpart = { [30669] = { 1 } },
            coord = { x = 525.6, y = -2502.8 },
            Zone = 418,
            _index = 106
        },
        {
            Done = { 30669 },
            coord = { x = 792.5, y = -2576.3 },
            Zone = 418,
            _index = 107
        },
        {
            PickUp = { 30671, 30691 },
            coord = { x = 792.5, y = -2576.3 },
            Zone = 418,
            _index = 108
        },
        {
            Waypoint = 30691,
            coord = { x = 792.1, y = -2599.1 },
            Fillers = { [30671] = { 1 } },
            ExtraLineText = "JUMP_INTO_WATER_AND_ENTER_IN_UNDERWATER_CAVE",
            Range = 5,
            Zone = 418,
            _index = 109
        },
        {
            Qpart = { [30691] = { 1 } },
            coord = { x = 781.8, y = -2717.1 },
            Fillers = { [30671] = { 1 } },
            ExtraLineText = "JUMP_INTO_WATER_AND_ENTER_IN_UNDERWATER_CAVE",
            Range = 2,
            Zone = 418,
            _index = 110
        },
        {
            Done = { 30691 },
            NoArrow = 1,
            Zone = 418,
            _index = 111
        },
        {
            Qpart = { [30671] = { 1 } },
            coord = { x = 736.5, y = -2584.5 },
            Range = 30,
            Zone = 418,
            _index = 112
        },
        {
            Done = { 30671 },
            coord = { x = 794.7, y = -2579.9 },
            Zone = 418,
            _index = 113
        },
        {
            PickUp = { 30672 },
            coord = { x = 792.7, y = -2576.6 },
            Zone = 418,
            _index = 114
        },
        {
            PickUp = { 30674 },
            coord = { x = 828.3, y = -2758.4 },
            Zone = 418,
            _index = 115
        },
        {
            DropQuest = 30675,
            DroppableQuest = { MobId = 60299, Qid = 30675, Text = "Unga Fish-Getter" },
            coord = { x = 700.1, y = -2833.4 },
            Range = 30,
            Zone = 418,
            _index = 116
        },
        {
            Qpart = { [30672] = { 1 }, [30674] = { 1 } },
            coord = { x = 700.1, y = -2833.4 },
            Fillers = { [30675] = { 1 } },
            Range = 100,
            Zone = 418,
            _index = 117
        },
        {
            Done = { 30674 },
            NoArrow = 1,
            Zone = 418,
            _index = 118
        },
        {
            Qpart = { [30675] = { 1 } },
            coord = { x = 753.3, y = -2885.2 },
            Range = 100,
            Zone = 418,
            _index = 119
        },
        {
            Done = { 30675 },
            NoArrow = 1,
            Zone = 418,
            _index = 120
        },
        {
            Done = { 30672 },
            coord = { x = 532.7, y = -2512.1 },
            Zone = 418,
            _index = 121
        },
        {
            GetFP = 992,
            coord = { x = 1487.9, y = -2084.3 },
            Zone = 418,
            _index = 122
        },
        {
            PickUp = { 30168, 30169 },
            coord = { x = 1557.1, y = -1331.1 },
            Zone = 418,
            _index = 123
        },
        {
            Qpart = { [30169] = { 1 } },
            coord = { x = 1457.4, y = -1016.2 },
            Fillers = { [30168] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 124
        },
        {
            Waypoint = 30168,
            coord = { x = 1411.1, y = -1029.3 },
            Fillers = { [30168] = { 1 } },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 418,
            _index = 125
        },
        {
            Qpart = { [30168] = { 1 } },
            coord = { x = 1418.6, y = -1013.6 },
            Range = 30,
            Zone = 418,
            _index = 126
        },
        {
            Done = { 30168, 30169 },
            coord = { x = 1557, y = -1331.1 },
            Zone = 418,
            _index = 127
        },
        {
            Done = { 30363 },
            coord = { x = 1789.7, y = -1174.1 },
            Zone = 418,
            _index = 128
        },
        {
            PickUp = { 30354, 30356 },
            coord = { x = 1789.7, y = -1174.1 },
            Zone = 418,
            _index = 129
        },
        {
            GetFP = 991,
            coord = { x = 1769.5, y = -1156 },
            Zone = 418,
            _index = 130
        },
        {
            PickUp = { 30355 },
            coord = { x = 1766.6, y = -1189.4 },
            Zone = 418,
            _index = 131
        },
        {
            Qpart = { [30354] = { 1 }, [30355] = { 1 }, [30356] = { 1 } },
            coord = { x = 1798.7, y = -1328 },
            Range = 45,
            Zone = 418,
            _index = 132
        },
        {
            Done = { 30355 },
            coord = { x = 1766.8, y = -1189.3 },
            Zone = 418,
            _index = 133
        },
        {
            Done = { 30354, 30356 },
            coord = { x = 1789.9, y = -1174 },
            Zone = 418,
            _index = 134
        },
        {
            PickUp = { 30361 },
            coord = { x = 1782.2, y = -1184.4 },
            Zone = 418,
            _index = 135
        },
        {
            PickUp = { 30357 },
            coord = { x = 2241, y = -1342.2 },
            Zone = 418,
            _index = 136
        },
        {
            Qpart = { [30357] = { 1 }, [30361] = { 1 } },
            coord = { x = 2187, y = -1241.9 },
            Button = { ["30357-1"] = 79163 },
            Range = 40,
            Zone = 418,
            _index = 137
        },
        {
            Done = { 30361 },
            coord = { x = 2212.3, y = -1351.4 },
            Zone = 418,
            _index = 138
        },
        {
            Done = { 30357 },
            coord = { x = 2241.2, y = -1342.2 },
            Zone = 418,
            _index = 139
        },
        {
            PickUp = { 30359 },
            coord = { x = 2241.2, y = -1342.2 },
            Zone = 418,
            _index = 140
        },
        {
            Qpart = { [30359] = { 1 } },
            coord = { x = 1842.7, y = -1636.5 },
            GossipOptionIDs = { 40353 },
            Zone = 418,
            _index = 141
        },
        {
            Done = { 30359 },
            coord = { x = 1790.3, y = -1172.5 },
            Zone = 418,
            _index = 142
        },
        {
            PickUp = { 30445 },
            coord = { x = 1790.3, y = -1172.5 },
            Zone = 418,
            _index = 143
        },
        {
            Qpart = { [30445] = { 1 } },
            coord = { x = 1790.2, y = -1172.6 },
            Zone = 418,
            _index = 144
        },
        {
            Done = { 30445 },
            coord = { x = 1789.9, y = -1174.1 },
            Zone = 418,
            _index = 145
        },
        {
            PickUp = { 30360 },
            coord = { x = 1789.9, y = -1174.1 },
            Zone = 418,
            _index = 146
        },
        {
            UseFlightPath = 30360,
            NodeID = 989,
            coord = { x = 1769.5, y = -1156.3 },
            ETA = 40,
            Zone = 418,
            _index = 147
        },
        {
            Done = { 30360 },
            coord = { x = 1911.9, y = -392.9 },
            Zone = 376,
            _index = 148
        },
        {
            PickUp = { 30623, 30622 },
            coord = { x = 1976.4, y = -380.1 },
            Zone = 376,
            _index = 149
        },
        {
            PickUp = { 30624 },
            coord = { x = 1965.7, y = -362.1 },
            Zone = 376,
            _index = 150
        },
        {
            Qpart = { [30624] = { 1 } },
            coord = { x = 1995.9, y = -220.9 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 151
        },
        {
            Qpart = { [30624] = { 4 } },
            coord = { x = 2091.9, y = -220.9 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 152
        },
        {
            Qpart = { [30624] = { 2 } },
            coord = { x = 2083.8, y = -354.3 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 153
        },
        {
            Qpart = { [30624] = { 3 } },
            coord = { x = 2257.5, y = -361 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 154
        },
        {
            Done = { 30624 },
            NoArrow = 1,
            Zone = 376,
            _index = 155
        },
        {
            Qpart = { [30622] = { 1 }, [30623] = { 1 } },
            coord = { x = 2172.1, y = -299.5 },
            Button = { ["30623-1"] = 80337 },
            Range = 30,
            Zone = 376,
            _index = 156
        },
        {
            Done = { 30623, 30622 },
            coord = { x = 2225.1, y = -199 },
            Zone = 376,
            _index = 157
        },
        {
            PickUp = { 30625 },
            coord = { x = 2225.1, y = -199 },
            Zone = 376,
            _index = 158
        },
        {
            Qpart = { [30625] = { 3 } },
            coord = { x = 2303.1, y = -314.9 },
            Range = 5,
            Zone = 376,
            _index = 159
        },
        {
            Qpart = { [30625] = { 4 } },
            coord = { x = 2305.7, y = -424.3 },
            Range = 5,
            Zone = 376,
            _index = 160
        },
        {
            Qpart = { [30625] = { 1 } },
            coord = { x = 2328.3, y = -323.8 },
            Range = 5,
            Zone = 376,
            _index = 161
        },
        {
            Qpart = { [30625] = { 2 } },
            coord = { x = 2322.1, y = -244.8 },
            Range = 5,
            Zone = 376,
            _index = 162
        },
        {
            Done = { 30625 },
            coord = { x = 2222.8, y = -198.7 },
            Zone = 376,
            _index = 163
        },
        {
            PickUp = { 30626 },
            coord = { x = 2222.8, y = -198.7 },
            Zone = 376,
            _index = 164
        },
        {
            Done = { 30626 },
            coord = { x = 1978.3, y = -377.1 },
            Zone = 376,
            _index = 165
        },
        {
            PickUp = { 30627 },
            coord = { x = 1975.2, y = -362 },
            Zone = 376,
            _index = 166
        },
        {
            Qpart = { [30627] = { 1 } },
            coord = { x = 1976.1, y = -388.9 },
            GossipOptionIDs = { 39267 },
            RaidIcon = 59857,
            Zone = 376,
            _index = 167
        },
        {
            Done = { 30627 },
            coord = { x = 1977.7, y = -374.9 },
            Zone = 376,
            _index = 168
        },
        {
            PickUp = { 30628 },
            coord = { x = 1977.7, y = -374.9 },
            Zone = 376,
            _index = 169
        },
        {
            Waypoint = 30628,
            coord = { x = 1905.4, y = -379.3 },
            ExtraLineText = "UPSTAIRS",
            Range = 3,
            Zone = 376,
            _index = 170
        },
        {
            Done = { 30628 },
            coord = { x = 1901.3, y = -367.5 },
            ExtraLineText = "UPSTAIRS",
            Zone = 376,
            _index = 171
        },
        {
            UseFlightPath = 31286,
            NodeID = 1052,
            coord = { x = 1882.1, y = -439.1 },
            ETA = 79,
            Zone = 376,
            _index = 172
        },
        {
            RouteCompleted = 1,
            _index = 173
        }
    }

    APR.RouteQuestStepList["379-Kun-Lai Summit"] = {
        {
            PickUp = { 31392 },
            coord = { x = 479.2, y = -260.4 },
            Zone = 376,
            _index = 1
        },
        {
            PickUp = { 31254 },
            coord = { x = 508.4, y = -217.7 },
            Zone = 376,
            _index = 2
        },
        {
            Qpart = { [31254] = { 1 } },
            coord = { x = -70.7, y = 481.4 },
            RaidIcon = 62738,
            Zone = 376,
            _index = 3
        },
        {
            GetFP = 1029,
            coord = { x = -205.1, y = 784.4 },
            Zone = 433,
            _index = 4
        },
        {
            PickUp = { 31286, 31287 },
            coord = { x = -148.6, y = 901.7 },
            Zone = 433,
            _index = 5
        },
        {
            Waypoint = 31286,
            coord = { x = -182.1, y = 1026.8 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 433,
            _index = 6
        },
        {
            Waypoint = 31286,
            coord = { x = 23.9, y = 1121.9 },
            Fillers = { [31286] = { 1 } },
            Range = 5,
            Zone = 433,
            _index = 7
        },
        {
            Waypoint = 31286,
            coord = { x = -52.1, y = 1172.6 },
            Fillers = { [31286] = { 1 } },
            Range = 5,
            Zone = 433,
            _index = 8
        },
        {
            Qpart = { [31287] = { 1 } },
            coord = { x = -102.4, y = 1170.5 },
            Fillers = { [31286] = { 1 } },
            Range = 5,
            Zone = 433,
            _index = 9
        },
        {
            Qpart = { [31286] = { 1 } },
            coord = { x = -96.4, y = 1144 },
            Range = 30,
            Zone = 433,
            _index = 10
        },
        {
            Waypoint = 31286,
            coord = { x = -173, y = 1031.2 },
            ExtraLineText = "EXIT_CAVE",
            Range = 5,
            Zone = 433,
            _index = 11
        },
        {
            Done = { 31286, 31287 },
            coord = { x = -149.2, y = 902.8 },
            Zone = 433,
            _index = 12
        },
        {
            Qpart = { [31254] = { 2 } },
            coord = { x = -119, y = 1166.6 },
            Zone = 433,
            _index = 13
        },
        {
            PickUp = { 31285, 31611 },
            coord = { x = -119, y = 1166.6 },
            Zone = 433,
            _index = 14
        },
        {
            Qpart = { [31285] = { 1 } },
            coord = { x = -119, y = 1166.6 },
            ExtraLineText = "GET_IN_BOAT",
            Range = 5,
            Zone = 433,
            _index = 15
        },
        {
            Done = { 31285 },
            coord = { x = 292.1, y = 1736.5 },
            Zone = 379,
            _index = 16
        },
        {
            GetFP = 1017,
            coord = { x = 299.6, y = 1689 },
            Zone = 379,
            _index = 17
        },
        {
            PickUp = { 30460 },
            coord = { x = 361, y = 1745.1 },
            Zone = 379,
            _index = 18
        },
        {
            Done = { 31254 },
            coord = { x = 316.8, y = 1785 },
            Zone = 379,
            _index = 19
        },
        {
            PickUp = { 30457 },
            coord = { x = 316.9, y = 1785.4 },
            Zone = 379,
            _index = 20
        },
        {
            PickUp = { 30459 },
            coord = { x = 412.2, y = 1847.9 },
            Zone = 379,
            _index = 21
        },
        {
            Qpart = { [30457] = { 1 }, [30459] = { 1 }, [30460] = { 1 } },
            coord = { x = 552.6, y = 1924.2 },
            Button = { ["30460-1"] = 79819 },
            Range = 60,
            Zone = 379,
            _index = 22
        },
        {
            Qpart = { [30457] = { 2 } },
            coord = { x = 559.4, y = 1923.9 },
            Range = 5,
            Zone = 379,
            _index = 23
        },
        {
            Done = { 30459 },
            coord = { x = 412.1, y = 1848.3 },
            Zone = 379,
            _index = 24
        },
        {
            Done = { 30457 },
            coord = { x = 316.5, y = 1785.5 },
            Zone = 379,
            _index = 25
        },
        {
            Done = { 30460 },
            coord = { x = 360.3, y = 1744.9 },
            Zone = 379,
            _index = 26
        },
        {
            PickUp = { 30508 },
            coord = { x = 360.3, y = 1744.9 },
            Zone = 379,
            _index = 27
        },
        {
            Done = { 30508 },
            coord = { x = 362.3, y = 1734.6 },
            ExtraLineText = "UPSTAIRS",
            Zone = 379,
            _index = 28
        },
        {
            PickUp = { 30512 },
            coord = { x = 362.3, y = 1734.6 },
            Zone = 379,
            _index = 29
        },
        {
            SetHS = 30512,
            coord = { x = 291.9, y = 1765.8 },
            Zone = 379,
            _index = 30
        },
        {
            PickUp = { 30467, 30469 },
            coord = { x = 147.7, y = 1910.7 },
            Zone = 379,
            _index = 31
        },
        {
            PickUp = { 30468 },
            coord = { x = 159.2, y = 1918.4 },
            Zone = 379,
            _index = 32
        },
        {
            PickUp = { 30496, 30967 },
            coord = { x = 137.1, y = 1950 },
            Zone = 379,
            _index = 33
        },
        {
            Done = { 30467 },
            coord = { x = 165.9, y = 2408.5 },
            Zone = 379,
            _index = 34
        },
        {
            PickUp = { 30834 },
            coord = { x = 165.9, y = 2408.5 },
            Zone = 379,
            _index = 35
        },
        {
            Qpart = { [30496] = { 1 } },
            coord = { x = 204.6, y = 2361.4 },
            Fillers = { [30468] = { 1 }, [30469] = { 1 }, [30967] = { 1 } },
            GossipOptionIDs = { 35732 },
            Range = 5,
            Zone = 379,
            _index = 36
        },
        {
            Qpart = { [30468] = { 1 }, [30469] = { 1 }, [30967] = { 1 } },
            coord = { x = 208.1, y = 2343.7 },
            GossipOptionIDs = { 35732 },
            Range = 45,
            Zone = 379,
            _index = 37
        },
        {
            Done = { 30496, 30967 },
            coord = { x = 132.8, y = 1936.6 },
            Zone = 379,
            _index = 38
        },
        {
            Qpart = { [30834] = { 1 } },
            coord = { x = 148.1, y = 1910.8 },
            Zone = 379,
            _index = 39
        },
        {
            Done = { 30834 },
            coord = { x = 148.1, y = 1910.8 },
            Zone = 379,
            _index = 40
        },
        {
            Done = { 30469 },
            coord = { x = 148.7, y = 1910.6 },
            Zone = 379,
            _index = 41
        },
        {
            Done = { 30468 },
            coord = { x = 159.8, y = 1919.5 },
            Zone = 379,
            _index = 42
        },
        {
            PickUp = { 30480 },
            coord = { x = 132, y = 1935.8 },
            Zone = 379,
            _index = 43
        },
        {
            Qpart = { [30480] = { 1 } },
            coord = { x = 133.6, y = 1935.2 },
            GossipOptionIDs = { 38108 },
            Zone = 379,
            _index = 44
        },
        {
            Qpart = { [30480] = { 2, 3, 3 } },
            coord = { x = 154, y = 1918.6 },
            Range = 5,
            Zone = 379,
            _index = 45
        },
        {
            Done = { 30480 },
            coord = { x = 151.9, y = 1922 },
            Zone = 379,
            _index = 46
        },
        {
            PickUp = { 30828 },
            coord = { x = 151.9, y = 1922 },
            Zone = 379,
            _index = 47
        },
        {
            Qpart = { [30828] = { 1 } },
            coord = { x = 316.9, y = 2067.2 },
            Range = 30,
            Zone = 379,
            _index = 48
        },
        {
            Done = { 30828 },
            NoArrow = 1,
            Zone = 379,
            _index = 49
        },
        {
            PickUp = { 30855 },
            NoArrow = 1,
            Zone = 379,
            _index = 50
        },
        {
            Qpart = { [30855] = { 1 } },
            coord = { x = 377.6, y = 2182.8 },
            ExtraLineText = "KILL_SMALL_SHA_ON_ISLAND_CLOSE_TO_SHAI_HU_TO_WEAKEN_HIM",
            Range = 30,
            Zone = 379,
            _index = 51
        },
        {
            Done = { 30855 },
            coord = { x = 151.8, y = 1922.5 },
            Zone = 379,
            _index = 52
        },
        {
            Qpart = { [30512] = { 1 } },
            coord = { x = 1155.3, y = 2261 },
            GossipOptionIDs = { 41284 },
            Zone = 379,
            _index = 53
        },
        {
            Qpart = { [30512] = { 2 } },
            coord = { x = 1313.3, y = 2096.9 },
            GossipOptionIDs = { 41467 },
            Zone = 379,
            _index = 54
        },
        {
            Done = { 30512 },
            coord = { x = 1313.3, y = 2096.9 },
            Zone = 379,
            _index = 55
        },
        {
            PickUp = { 30514 },
            coord = { x = 1313.3, y = 2096.9 },
            Zone = 379,
            _index = 56
        },
        {
            Qpart = { [30514] = { 1 } },
            coord = { x = 1197.8, y = 2109.4 },
            ExtraLineText = "CLICK_ON_BANNER",
            Range = 5,
            Zone = 379,
            _index = 57
        },
        {
            Done = { 30514 },
            coord = { x = 1416.4, y = 2104.5 },
            Zone = 379,
            _index = 58
        },
        {
            PickUp = { 30575 },
            coord = { x = 1474.6, y = 2169 },
            Zone = 379,
            _index = 59
        },
        {
            SetHS = 30575,
            coord = { x = 1454.8, y = 2160.8 },
            Zone = 379,
            _index = 60
        },
        {
            PickUp = { 30583 },
            coord = { x = 1449.4, y = 2144 },
            Zone = 379,
            _index = 61
        },
        {
            PickUp = { 30619 },
            coord = { x = 1449.5, y = 2137.5 },
            Zone = 379,
            _index = 62
        },
        {
            PickUp = { 30593 },
            coord = { x = 1496.4, y = 2152.3 },
            Zone = 379,
            _index = 63
        },
        {
            PickUp = { 30569 },
            coord = { x = 1473.5, y = 2108.6 },
            Zone = 379,
            _index = 64
        },
        {
            GetFP = 1020,
            coord = { x = 1461.6, y = 2102.3 },
            Zone = 379,
            _index = 65
        },
        {
            Done = { 30569 },
            coord = { x = 1069.4, y = 2038.7 },
            Zone = 379,
            _index = 66
        },
        {
            PickUp = { 30571 },
            coord = { x = 1069.4, y = 2038.7 },
            Zone = 379,
            _index = 67
        },
        {
            PickUp = { 30581 },
            coord = { x = 1073.8, y = 2033.4 },
            Zone = 379,
            _index = 68
        },
        {
            Qpart = { [30581] = { 2 } },
            coord = { x = 1082.6, y = 1928.6 },
            ExtraLineText = "INSIDE",
            Range = 2,
            Zone = 379,
            _index = 69
        },
        {
            Qpart = { [30571] = { 1 }, [30581] = { 1 } },
            coord = { x = 1083.1, y = 1949.1 },
            Range = 60,
            Zone = 379,
            _index = 70
        },
        {
            Done = { 30581 },
            coord = { x = 1073.8, y = 2033.2 },
            Zone = 379,
            _index = 71
        },
        {
            Done = { 30571 },
            coord = { x = 1069.3, y = 2038.8 },
            Zone = 379,
            _index = 72
        },
        {
            PickUp = { 31252 },
            coord = { x = 1069.3, y = 2038.8 },
            Zone = 379,
            _index = 73
        },
        {
            PickUp = { 30595 },
            coord = { x = 1109.2, y = 2354.7 },
            Zone = 379,
            _index = 74
        },
        {
            Qpart = { [30619] = { 1 } },
            coord = { x = 1202.5, y = 2660.1 },
            Fillers = { [30593] = { 1 }, [30595] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 75
        },
        {
            Qpart = { [30593] = { 1 }, [30595] = { 1 } },
            coord = { x = 1193.9, y = 2496.5 },
            Range = 30,
            Zone = 379,
            _index = 76
        },
        {
            Done = { 30595 },
            coord = { x = 1109.2, y = 2354.7 },
            Zone = 379,
            _index = 77
        },
        {
            Qpart = { [30583] = { 1 } },
            coord = { x = 1685.4, y = 2102.3 },
            Fillers = { [30575] = { 1 } },
            ExtraLineText = "FIND_3_YAKS_WHILE_KILLING_MOBS",
            Range = 100,
            Zone = 379,
            _index = 78
        },
        {
            Qpart = { [30575] = { 1 } },
            coord = { x = 1466.6, y = 2112.5 },
            ExtraLineText = "FIND_3_YAKS_WHILE_KILLING_MOBS",
            Range = 5,
            Zone = 379,
            _index = 79
        },
        {
            Done = { 30619 },
            coord = { x = 1449.9, y = 2137.4 },
            Zone = 379,
            _index = 80
        },
        {
            Done = { 30583 },
            coord = { x = 1449.3, y = 2144 },
            Zone = 379,
            _index = 81
        },
        {
            Done = { 31252 },
            coord = { x = 1473.6, y = 2109 },
            Zone = 379,
            _index = 82
        },
        {
            Done = { 30593 },
            coord = { x = 1481, y = 2144.3 },
            Zone = 379,
            _index = 83
        },
        {
            Done = { 30575 },
            coord = { x = 1474.8, y = 2169.2 },
            Zone = 379,
            _index = 84
        },
        {
            PickUp = { 30652 },
            coord = { x = 1474.5, y = 2169.1 },
            Zone = 379,
            _index = 85
        },
        {
            PickUp = { 30651 },
            coord = { x = 1449.5, y = 2143.8 },
            Zone = 379,
            _index = 86
        },
        {
            PickUp = { 30650 },
            coord = { x = 1449.5, y = 2137.7 },
            Zone = 379,
            _index = 87
        },
        {
            Waypoint = 30652,
            coord = { x = 1631.6, y = 2310.1 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 2,
            Zone = 379,
            _index = 88
        },
        {
            Qpart = { [30651] = { 1 } },
            coord = { x = 1648.1, y = 2307 },
            Fillers = { [30650] = { 1 } },
            Button = { ["30651-1"] = 80528 },
            Zone = 379,
            _index = 89
        },
        {
            Qpart = { [30652] = { 1 } },
            coord = { x = 1682.3, y = 2338.5 },
            Fillers = { [30650] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 90
        },
        {
            Qpart = { [30652] = { 3 } },
            coord = { x = 1746.1, y = 2343.8 },
            Fillers = { [30650] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 91
        },
        {
            Qpart = { [30652] = { 4 } },
            coord = { x = 1764.9, y = 2267.3 },
            Fillers = { [30650] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 92
        },
        {
            Waypoint = 30652,
            coord = { x = 1751.7, y = 2234.8 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 2,
            Zone = 379,
            _index = 93
        },
        {
            Qpart = { [30651] = { 2 } },
            coord = { x = 1734.5, y = 2238.7 },
            Fillers = { [30650] = { 1 } },
            Button = { ["30656-1"] = 80528 },
            Range = 30,
            Zone = 379,
            _index = 94
        },
        {
            Qpart = { [30652] = { 2 } },
            coord = { x = 1853.5, y = 2279.7 },
            Fillers = { [30650] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 95
        },
        {
            Done = { 30652 },
            NoArrow = 1,
            Zone = 379,
            _index = 96
        },
        {
            PickUp = { 30660 },
            NoArrow = 1,
            Zone = 379,
            _index = 97
        },
        {
            Waypoint = 30651,
            coord = { x = 1864.8, y = 2275.6 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 1,
            Zone = 379,
            _index = 98
        },
        {
            Qpart = { [30651] = { 3 } },
            coord = { x = 1844.3, y = 2221.2 },
            Fillers = { [30650] = { 1 } },
            Button = { ["30651-3"] = 80528 },
            Range = 2,
            Zone = 379,
            _index = 99
        },
        {
            Qpart = { [30650] = { 1 } },
            coord = { x = 1772.2, y = 2252.1 },
            Range = 30,
            Zone = 379,
            _index = 100
        },
        {
            Waypoint = 30651,
            coord = { x = 1774.4, y = 2408.9 },
            Range = 5,
            Zone = 379,
            _index = 101
        },
        {
            Qpart = { [30660] = { 1 } },
            coord = { x = 1813.1, y = 2417.2 },
            Range = 5,
            Zone = 379,
            _index = 102
        },
        {
            Done = { 30651 },
            coord = { x = 1449.7, y = 2143.9 },
            Zone = 379,
            _index = 103
        },
        {
            Done = { 30660, 30650 },
            coord = { x = 1469.8, y = 2140.3 },
            Zone = 379,
            _index = 104
        },
        {
            PickUp = { 31455 },
            coord = { x = 1469.8, y = 2140.3 },
            Zone = 379,
            _index = 105
        },
        {
            PickUp = { 31460 },
            coord = { x = 1480.5, y = 2144.1 },
            Zone = 379,
            _index = 106
        },
        {
            PickUp = { 31695 },
            coord = { x = 1449.5, y = 2137.7 },
            Zone = 379,
            _index = 107
        },
        {
            PickUp = { 31456 },
            coord = { x = 1473.4, y = 2108.9 },
            Zone = 379,
            _index = 108
        },
        {
            Done = { 31456 },
            coord = { x = 385.4, y = 2723.6 },
            Zone = 379,
            _index = 109
        },
        {
            PickUp = { 30488, 30489 },
            coord = { x = 385.4, y = 2723.6 },
            Zone = 379,
            _index = 110
        },
        {
            Waypoint = 30488,
            coord = { x = 269.7, y = 2554.2 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 111
        },
        {
            Waypoint = 30488,
            coord = { x = 225.7, y = 2503.4 },
            Range = 5,
            Zone = 379,
            _index = 112
        },
        {
            Waypoint = 30488,
            coord = { x = 198.9, y = 2521.6 },
            Range = 5,
            Zone = 379,
            _index = 113
        },
        {
            Waypoint = 30488,
            coord = { x = 186.9, y = 2549.7 },
            Range = 5,
            Zone = 379,
            _index = 114
        },
        {
            Waypoint = 30488,
            coord = { x = 134.2, y = 2518.6 },
            Range = 5,
            Zone = 379,
            _index = 115
        },
        {
            Done = { 30488 },
            coord = { x = 149.2, y = 2507.6 },
            ExtraLineText = "KILL_MOBS_TO_SAVE_NPC",
            Zone = 379,
            _index = 116
        },
        {
            PickUp = { 30491 },
            coord = { x = 149, y = 2508.9 },
            Zone = 379,
            _index = 117
        },
        {
            Qpart = { [30489] = { 1 } },
            coord = { x = 243.6, y = 2543.8 },
            ExtraLineText = "RIDE_YAK",
            Range = 60,
            Zone = 379,
            _index = 118
        },
        {
            PickUp = { 30587 },
            coord = { x = 474, y = 2559 },
            ExtraLineText = "KILL_BURILGI_DESPOILERS_TO_PICKUP_QUEST",
            Range = 30,
            Zone = 379,
            _index = 119
        },
        {
            DropQuest = 30582,
            DroppableQuest = { MobId = 59335, Qid = 30582, Text = "Burilgi Despoiler" },
            coord = { x = 437.8, y = 2604.5 },
            Range = 45,
            Zone = 379,
            _index = 120
        },
        {
            Done = { 30582, 30489 },
            coord = { x = 381.1, y = 2726.6 },
            Zone = 379,
            _index = 121
        },
        {
            PickUp = { 30804 },
            coord = { x = 381.1, y = 2726.6 },
            Zone = 379,
            _index = 122
        },
        {
            Qpart = { [30804] = { 1 } },
            coord = { x = 593.4, y = 2531.3 },
            Fillers = { [30587] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 123
        },
        {
            Qpart = { [30491] = { 1 }, [30587] = { 1 } },
            coord = { x = 474, y = 2559 },
            ExtraLineText = "RIDE_YAK",
            ExtraLineText2 = "ONCE_ON_YAK_BRING_IT_BACK_TO_STABLE_AND_REPEAT_THAT_5_TIMES",
            Range = 60,
            Zone = 379,
            _index = 124
        },
        {
            Done = { 30491 },
            coord = { x = 371.6, y = 2727.8 },
            Zone = 379,
            _index = 125
        },
        {
            Done = { 30587, 30804 },
            coord = { x = 349.9, y = 2686.3 },
            Zone = 379,
            _index = 126
        },
        {
            PickUp = { 30492 },
            coord = { x = 371.7, y = 2728.2 },
            Zone = 379,
            _index = 127
        },
        {
            Qpart = { [30492] = { 1 } },
            coord = { x = 761.2, y = 3063.6 },
            Range = 5,
            Zone = 379,
            _index = 128
        },
        {
            Done = { 30492 },
            coord = { x = 789.7, y = 3041.6 },
            Zone = 379,
            _index = 129
        },
        {
            PickUp = { 30808 },
            coord = { x = 789.7, y = 3041.6 },
            Zone = 379,
            _index = 130
        },
        {
            PickUp = { 30614 },
            coord = { x = 741, y = 3080.5 },
            Zone = 379,
            _index = 131
        },
        {
            PickUp = { 30616 },
            coord = { x = 779, y = 3094.4 },
            Zone = 379,
            _index = 132
        },
        {
            Qpart = { [30614] = { 1 }, [30616] = { 1 }, [30808] = { 1 } },
            coord = { x = 922.6, y = 2775.7 },
            Range = 40,
            Zone = 379,
            _index = 133
        },
        {
            Done = { 30808 },
            coord = { x = 789.9, y = 3041.8 },
            Zone = 379,
            _index = 134
        },
        {
            Done = { 30614 },
            coord = { x = 740.7, y = 3080.8 },
            Zone = 379,
            _index = 135
        },
        {
            Done = { 30616 },
            coord = { x = 778.7, y = 3094.6 },
            Zone = 379,
            _index = 136
        },
        {
            PickUp = { 30617 },
            coord = { x = 778.7, y = 3094.6 },
            Zone = 379,
            _index = 137
        },
        {
            GetFP = 1018,
            coord = { x = 690.1, y = 3504.4 },
            Zone = 379,
            _index = 138
        },
        {
            Done = { 31392 },
            coord = { x = 535.3, y = 3819.5 },
            Zone = 379,
            _index = 139
        },
        {
            PickUp = { 31394 },
            coord = { x = 535.3, y = 3819.5 },
            Zone = 379,
            _index = 140
        },
        {
            Qpart = { [31394] = { 1 } },
            coord = { x = 528.3, y = 3832.9 },
            Range = 2,
            Zone = 379,
            _index = 141
        },
        {
            Qpart = { [31394] = { 2, 3, 4 } },
            coord = { x = 534.9, y = 3783.4 },
            Range = 5,
            ETA = 35,
            Zone = 379,
            _index = 142
        },
        {
            Done = { 31394 },
            coord = { x = 538.4, y = 3823.9 },
            Zone = 379,
            _index = 143
        },
        {
            PickUp = { 31512 },
            coord = { x = 538.4, y = 3823.9 },
            Zone = 379,
            _index = 144
        },
        {
            Waypoint = 30617,
            coord = { x = 849.1, y = 3154 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 145
        },
        {
            Waypoint = 30617,
            coord = { x = 895.8, y = 3109.9 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 146
        },
        {
            Waypoint = 30617,
            coord = { x = 894.1, y = 2993.1 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 147
        },
        {
            Waypoint = 30617,
            coord = { x = 916.7, y = 2923.1 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 148
        },
        {
            Qpart = { [30617] = { 1 } },
            coord = { x = 1078.5, y = 2878 },
            Range = 30,
            Zone = 379,
            _index = 149
        },
        {
            Done = { 30617 },
            coord = { x = 1204, y = 3053.3 },
            Zone = 379,
            _index = 150
        },
        {
            PickUp = { 30592 },
            coord = { x = 1204, y = 3053.3 },
            Zone = 379,
            _index = 151
        },
        {
            Done = { 31460 },
            coord = { x = 1250.8, y = 3045 },
            Zone = 379,
            _index = 152
        },
        {
            PickUp = { 30999 },
            coord = { x = 1250.8, y = 3045 },
            Zone = 379,
            _index = 153
        },
        {
            Done = { 30999 },
            coord = { x = 1258.7, y = 3065.5 },
            Zone = 379,
            _index = 154
        },
        {
            PickUp = { 30601 },
            coord = { x = 1258.7, y = 3065.5 },
            Zone = 379,
            _index = 155
        },
        {
            PickUp = { 30621 },
            coord = { x = 1250.7, y = 3107.8 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 156
        },
        {
            SetHS = 30618,
            coord = { x = 1246.9, y = 3111.3 },
            Zone = 379,
            _index = 157
        },
        {
            GetFP = 1022,
            coord = { x = 1227.4, y = 3128.2 },
            Zone = 379,
            _index = 158
        },
        {
            PickUp = { 30618 },
            coord = { x = 1227.9, y = 3042.2 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 159
        },
        {
            Qpart = { [30601] = { 1 }, [30618] = { 1 }, [30621] = { 1, 2, 3, 4 } },
            coord = { x = 1247.4, y = 3523.1 },
            GossipOptionIDs = { 33656, 33655 },
            Range = 100,
            Zone = 379,
            _index = 160
        },
        {
            UseHS = 30621,
            Zone = 380,
            _index = 161
        },
        {
            Done = { 30621 },
            coord = { x = 1251.8, y = 3107 },
            Zone = 379,
            _index = 162
        },
        {
            Done = { 30601 },
            coord = { x = 1258.6, y = 3064.9 },
            Zone = 379,
            _index = 163
        },
        {
            Done = { 30618 },
            coord = { x = 1227.6, y = 3041.7 },
            Zone = 379,
            _index = 164
        },
        {
            PickUp = { 30487 },
            coord = { x = 1257.4, y = 3064.3 },
            Zone = 379,
            _index = 165
        },
        {
            Qpart = { [30487] = { 1 } },
            coord = { x = 1252.5, y = 3049.3 },
            ExtraLineText = "GET_IN_CART",
            Zone = 379,
            _index = 166
        },
        {
            Qpart = { [30487] = { 2 } },
            coord = { x = 1833.5, y = 3578.9 },
            Zone = 379,
            _index = 167
        },
        {
            Done = { 30487 },
            coord = { x = 1827.9, y = 3572.8 },
            Zone = 379,
            _index = 168
        },
        {
            PickUp = { 30683 },
            coord = { x = 1827.9, y = 3572.8 },
            Zone = 379,
            _index = 169
        },
        {
            Qpart = { [30683] = { 1 } },
            coord = { x = 1706.4, y = 3564.4 },
            Range = 2,
            Zone = 379,
            _index = 170
        },
        {
            Qpart = { [30683] = { 2 } },
            coord = { x = 1695.9, y = 3553.7 },
            Range = 5,
            Zone = 379,
            _index = 171
        },
        {
            Done = { 30683 },
            coord = { x = 1827.8, y = 3571.9 },
            Zone = 379,
            _index = 172
        },
        {
            PickUp = { 30684 },
            coord = { x = 1827.8, y = 3571.9 },
            Zone = 379,
            _index = 173
        },
        {
            Qpart = { [30684] = { 1 } },
            coord = { x = 2035.7, y = 3566.8 },
            Zone = 379,
            _index = 174
        },
        {
            Qpart = { [30684] = { 2 } },
            coord = { x = 2168.1, y = 3531.3 },
            Zone = 379,
            _index = 175
        },
        {
            Qpart = { [30684] = { 3 } },
            coord = { x = 2136.9, y = 3449.8 },
            Zone = 379,
            _index = 176
        },
        {
            Done = { 30684 },
            coord = { x = 2099.2, y = 3488.5 },
            Zone = 379,
            _index = 177
        },
        {
            PickUp = { 30829 },
            coord = { x = 2099.2, y = 3488.5 },
            Zone = 379,
            _index = 178
        },
        {
            Qpart = { [30829] = { 1 } },
            coord = { x = 2118.3, y = 3474.5 },
            ExtraLineText = "TALK_TO_NPC_TO_START_QUEST",
            GossipOptionIDs = { 40517 },
            Range = 5,
            Zone = 379,
            _index = 179
        },
        {
            Done = { 30829 },
            coord = { x = 2100.9, y = 3485.9 },
            Zone = 379,
            _index = 180
        },
        {
            PickUp = { 30795 },
            coord = { x = 2100.9, y = 3485.9 },
            Zone = 379,
            _index = 181
        },
        {
            UseFlightPath = 30795,
            NodeID = 1022,
            coord = { x = 2102.1, y = 3477.2 },
            GossipOptionIDs = { 40519 },
            ETA = 31,
            Zone = 379,
            _index = 182
        },
        {
            Qpart = { [30795] = { 1 } },
            coord = { x = 1220.4, y = 3579.6 },
            Button = { ["30795-1"] = 81712 },
            Range = 5,
            Zone = 379,
            _index = 183
        },
        {
            Done = { 30795 },
            coord = { x = 1224, y = 3583.5 },
            Zone = 379,
            _index = 184
        },
        {
            PickUp = { 30796 },
            coord = { x = 1224, y = 3583.5 },
            Zone = 379,
            _index = 185
        },
        {
            PickUp = { 30797 },
            coord = { x = 1265.7, y = 3620.1 },
            Zone = 379,
            _index = 186
        },
        {
            Qpart = { [30797] = { 1 } },
            coord = { x = 1264.4, y = 3619.4 },
            Fillers = { [30796] = { 1 } },
            Zone = 379,
            _index = 187
        },
        {
            Qpart = { [30796] = { 1 } },
            coord = { x = 1290.9, y = 3641.9 },
            Range = 15,
            Zone = 379,
            _index = 188
        },
        {
            Done = { 30796, 30797 },
            coord = { x = 1224, y = 3584.7 },
            Button = { ["30796"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 189
        },
        {
            PickUp = { 30799 },
            coord = { x = 1224, y = 3584.7 },
            Button = { ["30799"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 190
        },
        {
            Waypoint = 30799,
            coord = { x = 1342.1, y = 3691.3 },
            Range = 5,
            Zone = 379,
            _index = 191
        },
        {
            Waypoint = 30799,
            coord = { x = 1300.8, y = 3759.3 },
            Range = 5,
            Zone = 379,
            _index = 192
        },
        {
            Qpart = { [30799] = { 3 } },
            coord = { x = 1268.1, y = 3739.4 },
            Zone = 379,
            _index = 193
        },
        {
            Qpart = { [30799] = { 1 } },
            coord = { x = 1263.6, y = 3803.8 },
            Zone = 379,
            _index = 194
        },
        {
            Qpart = { [30799] = { 2 } },
            coord = { x = 1311.7, y = 3806.3 },
            Zone = 379,
            _index = 195
        },
        {
            Waypoint = 30799,
            coord = { x = 1342.8, y = 3689.7 },
            Range = 5,
            Zone = 379,
            _index = 196
        },
        {
            Done = { 30799 },
            coord = { x = 1344.3, y = 3687 },
            Button = { ["30799"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 197
        },
        {
            PickUp = { 30798 },
            coord = { x = 1344.3, y = 3687 },
            Button = { ["30798"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 198
        },
        {
            Waypoint = 30798,
            coord = { x = 1501.5, y = 3563.4 },
            Range = 5,
            Zone = 379,
            _index = 199
        },
        {
            Qpart = { [30798] = { 1 } },
            coord = { x = 1524.9, y = 3476.5 },
            Range = 5,
            Zone = 379,
            _index = 200
        },
        {
            Waypoint = 30798,
            coord = { x = 1501.8, y = 3561.9 },
            Range = 5,
            Zone = 379,
            _index = 201
        },
        {
            Done = { 30798 },
            coord = { x = 1499.3, y = 3572.5 },
            Button = { ["30798"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 202
        },
        {
            PickUp = { 30800 },
            coord = { x = 1499.3, y = 3572.5 },
            Button = { ["30800"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 203
        },
        {
            Waypoint = 30800,
            coord = { x = 1524.2, y = 3675.1 },
            Range = 5,
            Zone = 379,
            _index = 204
        },
        {
            Waypoint = 30800,
            coord = { x = 1557.5, y = 3632.8 },
            Range = 5,
            Zone = 379,
            _index = 205
        },
        {
            Qpart = { [30800] = { 1 } },
            coord = { x = 1673.4, y = 3609.6 },
            Zone = 379,
            _index = 206
        },
        {
            Qpart = { [30800] = { 2 } },
            coord = { x = 1786.1, y = 3644.4 },
            Zone = 379,
            _index = 207
        },
        {
            Done = { 30800 },
            coord = { x = 1788.4, y = 3636.1 },
            Button = { ["30800"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 208
        },
        {
            PickUp = { 30801 },
            coord = { x = 1788.4, y = 3636.1 },
            Button = { ["30801"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 209
        },
        {
            Qpart = { [30801] = { 1 } },
            coord = { x = 1786, y = 3644.4 },
            Zone = 379,
            _index = 210
        },
        {
            Done = { 30801 },
            coord = { x = 1788, y = 3639.3 },
            Button = { ["30801"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 211
        },
        {
            PickUp = { 30802 },
            coord = { x = 1788, y = 3639.3 },
            Button = { ["30802"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 212
        },
        {
            Qpart = { [30802] = { 1 } },
            coord = { x = 1683.3, y = 3611.4 },
            Range = 30,
            Zone = 379,
            _index = 213
        },
        {
            Waypoint = 30802,
            coord = { x = 1560.3, y = 3596.5 },
            Range = 5,
            Zone = 379,
            _index = 214
        },
        {
            Waypoint = 30802,
            coord = { x = 1558.9, y = 3636.6 },
            Range = 5,
            Zone = 379,
            _index = 215
        },
        {
            Done = { 30802 },
            coord = { x = 1685.6, y = 3611.7 },
            Button = { ["30802"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 216
        },
        {
            PickUp = { 30935 },
            coord = { x = 1685.6, y = 3611.7 },
            Button = { ["30935"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 217
        },
        {
            Qpart = { [30935] = { 1 } },
            coord = { x = 1524.7, y = 3683.1 },
            GossipOptionIDs = { 30224 },
            Zone = 379,
            _index = 218
        },
        {
            Waypoint = 30935,
            coord = { x = 839.2, y = 3766.2 },
            Range = 5,
            Zone = 379,
            _index = 219
        },
        {
            Waypoint = 30935,
            coord = { x = 850.6, y = 3802 },
            Range = 5,
            Zone = 379,
            _index = 220
        },
        {
            Waypoint = 30935,
            coord = { x = 886.7, y = 3811.9 },
            Range = 5,
            Zone = 379,
            _index = 221
        },
        {
            Qpart = { [30935] = { 2 } },
            coord = { x = 877.2, y = 3940.1 },
            GossipOptionIDs = { 30226 },
            Range = 2,
            Zone = 379,
            _index = 222
        },
        {
            Done = { 30935 },
            coord = { x = 938.6, y = 4404.9 },
            ETA = 131,
            Zone = 379,
            _index = 223
        },
        {
            PickUp = { 30944 },
            coord = { x = 938.6, y = 4404.9 },
            Zone = 379,
            _index = 224
        },
        {
            GetFP = 1021,
            coord = { x = 931.8, y = 4361.3 },
            Zone = 379,
            _index = 225
        },
        {
            PickUp = { 30945 },
            coord = { x = 873.9, y = 4339 },
            Zone = 379,
            _index = 226
        },
        {
            PickUp = { 30942 },
            coord = { x = 851.6, y = 4338.6 },
            Zone = 379,
            _index = 227
        },
        {
            PickUp = { 30816 },
            coord = { x = 886.2, y = 4393.2 },
            Zone = 379,
            _index = 228
        },
        {
            PickUp = { 30943 },
            coord = { x = 874.7, y = 4419.8 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 229
        },
        {
            Done = { 30816 },
            coord = { x = 1046.7, y = 4728.1 },
            Zone = 379,
            _index = 230
        },
        {
            PickUp = { 30794 },
            coord = { x = 1046.7, y = 4728.1 },
            Zone = 379,
            _index = 231
        },
        {
            Waypoint = 30794,
            coord = { x = 1021.3, y = 4720.1 },
            ExtraLineText = "LOOT_HEALING_POTION",
            Range = 1,
            Zone = 379,
            _index = 232
        },
        {
            Qpart = { [30794] = { 1 } },
            coord = { x = 1047, y = 4728.3 },
            Button = { ["30794-1"] = 81177 },
            ExtraLineText = "USE_POTION_OR_HEALING_SPELL",
            Zone = 379,
            _index = 233
        },
        {
            Done = { 30794 },
            coord = { x = 1047, y = 4728.3 },
            Zone = 379,
            _index = 234
        },
        {
            PickUp = { 30805, 30806, 30807 },
            coord = { x = 1047, y = 4728.3 },
            Zone = 379,
            _index = 235
        },
        {
            Qpart = { [30807] = { 1 } },
            coord = { x = 1139.1, y = 4481.5 },
            Fillers = { [30806] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 236
        },
        {
            Qpart = { [30805] = { 1 } },
            coord = { x = 950.1, y = 4619.1 },
            Fillers = { [30805] = { 2 }, [30806] = { 1, 2 } },
            Range = 5,
            Zone = 379,
            _index = 237
        },
        {
            Qpart = { [30805] = { 2 }, [30806] = { 2 } },
            coord = { x = 880.4, y = 4719.5 },
            Fillers = { [30806] = { 1 } },
            Range = 40,
            Zone = 379,
            _index = 238
        },
        {
            Qpart = { [30806] = { 1 } },
            coord = { x = 1090.9, y = 4724.7 },
            Range = 30,
            Zone = 379,
            _index = 239
        },
        {
            Done = { 30805, 30806, 30807 },
            coord = { x = 1047.4, y = 4727.5 },
            Zone = 379,
            _index = 240
        },
        {
            PickUp = { 30819 },
            coord = { x = 1047.4, y = 4727.5 },
            Zone = 379,
            _index = 241
        },
        {
            Qpart = { [30942] = { 1 }, [30944] = { 1 } },
            coord = { x = 967.9, y = 4428.1 },
            GossipOptionIDs = { 38591, 38585 },
            Range = 40,
            Zone = 379,
            _index = 242
        },
        {
            Done = { 30819 },
            coord = { x = 886.5, y = 4393.5 },
            Zone = 379,
            _index = 243
        },
        {
            PickUp = { 30820 },
            coord = { x = 886.5, y = 4393.5 },
            Zone = 379,
            _index = 244
        },
        {
            Qpart = { [30820] = { 1 } },
            coord = { x = 650.2, y = 4228.2 },
            Zone = 379,
            _index = 245
        },
        {
            Done = { 30820 },
            coord = { x = 643.9, y = 4227.3 },
            Zone = 379,
            _index = 246
        },
        {
            Qpart = { [30942] = { 2, 3 }, [30943] = { 1 } },
            coord = { x = 381.3, y = 4468.4 },
            Fillers = { [30945] = { 1 } },
            Range = 50,
            Zone = 379,
            _index = 247
        },
        {
            Done = { 30942 },
            NoArrow = 1,
            Zone = 379,
            _index = 248
        },
        {
            Qpart = { [30945] = { 1 } },
            coord = { x = 406.2, y = 4466 },
            Range = 50,
            Zone = 379,
            _index = 249
        },
        {
            Done = { 30945 },
            coord = { x = 874.9, y = 4334.6 },
            Zone = 379,
            _index = 250
        },
        {
            Done = { 30943 },
            coord = { x = 873.4, y = 4420.2 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 251
        },
        {
            Done = { 30944 },
            coord = { x = 939.7, y = 4405.5 },
            Zone = 379,
            _index = 252
        },
        {
            PickUp = { 31011 },
            coord = { x = 939.7, y = 4405.5 },
            Zone = 379,
            _index = 253
        },
        {
            Qpart = { [31011] = { 2 } },
            coord = { x = 1009.9, y = 4405 },
            Fillers = { [31011] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 254
        },
        {
            Qpart = { [31011] = { 3 } },
            coord = { x = 809.3, y = 4407.4 },
            Fillers = { [31011] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 255
        },
        {
            Qpart = { [31011] = { 1 } },
            coord = { x = 914.4, y = 4370.2 },
            Range = 40,
            Zone = 379,
            _index = 256
        },
        {
            Done = { 31011 },
            coord = { x = 939.3, y = 4405.9 },
            Zone = 379,
            _index = 257
        },
        {
            PickUp = { 30946 },
            coord = { x = 939.3, y = 4405.9 },
            Zone = 379,
            _index = 258
        },
        {
            Qpart = { [30946] = { 1 } },
            coord = { x = 929.9, y = 4415.1 },
            ExtraLineText = "UPSTAIRS",
            GossipOptionIDs = { 40352 },
            Zone = 379,
            _index = 259
        },
        {
            Done = { 30946 },
            coord = { x = 939.3, y = 4406.6 },
            Zone = 379,
            _index = 260
        },
        {
            PickUp = { 31228 },
            coord = { x = 939.3, y = 4406.6 },
            Zone = 379,
            _index = 261
        },
        {
            Qpart = { [31228] = { 1 } },
            coord = { x = 940.6, y = 4395 },
            GossipOptionIDs = { 41466 },
            Zone = 379,
            _index = 262
        },
        {
            Qpart = { [31228] = { 2 } },
            coord = { x = 58.6, y = 5235.3 },
            Fillers = { [31228] = { 3 } },
            ExtraLineText = "STAY_ON_TABLE_TO_AVOID_ZONE_DEBUFF",
            Range = 5,
            ETA = 32,
            Zone = 379,
            _index = 263
        },
        {
            Qpart = { [31228] = { 3 } },
            coord = { x = 72.8, y = 5066.1 },
            Range = 40,
            Zone = 379,
            _index = 264
        },
        {
            UseFlightPath = 31228,
            NodeID = 1021,
            coord = { x = 72.8, y = 5140.7 },
            GossipOptionIDs = { 40729 },
            ETA = 35,
            Zone = 379,
            _index = 265
        },
        {
            Done = { 31228 },
            coord = { x = 939.5, y = 4405.9 },
            Zone = 379,
            _index = 266
        },
        {
            UseHS = 30592,
            Zone = 379,
            _index = 267
        },
        {
            Qpart = { [30592] = { 1 } },
            ExtraLineText = "OPEN_YOUR_MAP_TO_SEE_WHERE_NPCS_TO_ESCORT",
            NoArrow = 1,
            Zone = 379,
            _index = 268
        },
        {
            Done = { 30592 },
            coord = { x = 1607, y = 2787.9 },
            Zone = 379,
            _index = 269
        },
        {
            PickUp = { 30602 },
            coord = { x = 1607, y = 2787.9 },
            Zone = 379,
            _index = 270
        },
        {
            Qpart = { [30602] = { 1 } },
            coord = { x = 1766.8, y = 2678.9 },
            Zone = 379,
            _index = 271
        },
        {
            PickUp = { 30603 },
            coord = { x = 1766.8, y = 2678.9 },
            Zone = 379,
            _index = 272
        },
        {
            Qpart = { [30603] = { 1 } },
            coord = { x = 1835.8, y = 2560.5 },
            Range = 5,
            Zone = 379,
            _index = 273
        },
        {
            Done = { 30602, 30603 },
            coord = { x = 1586.8, y = 2813.7 },
            Zone = 379,
            _index = 274
        },
        {
            PickUp = { 30599, 30600, 30604 },
            coord = { x = 1586.8, y = 2813.7 },
            Zone = 379,
            _index = 275
        },
        {
            Qpart = { [30599] = { 2 } },
            coord = { x = 1566.8, y = 2639.2 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_KO_KO_TO_LOOT_HIS_BODY_THEN_CLICK_ON_KNIFE_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 276
        },
        {
            Waypoint = 30599,
            coord = { x = 1532.7, y = 2645.5 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 277
        },
        {
            Qpart = { [30599] = { 1 } },
            coord = { x = 1549.2, y = 2577.3 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_DAK_DAK_TO_LOOT_HIS_BODY_THEN_CLICK_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 278
        },
        {
            Qpart = { [30599] = { 3 } },
            coord = { x = 1284.3, y = 2656.3 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_TAK_TAK_TO_LOOT_HIS_BODY_THEN_CLICK_ON_KNIFE_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 279
        },
        {
            Qpart = { [30600] = { 1 }, [30604] = { 1, 2 } },
            coord = { x = 1531.1, y = 2677.1 },
            Range = 45,
            Zone = 379,
            _index = 280
        },
        {
            Done = { 30600, 30604, 30599 },
            coord = { x = 1587, y = 2814.7 },
            Zone = 379,
            _index = 281
        },
        {
            PickUp = { 30605 },
            coord = { x = 1587, y = 2814.7 },
            Zone = 379,
            _index = 282
        },
        {
            Qpart = { [30605] = { 1 } },
            coord = { x = 1677.7, y = 2940.2 },
            Zone = 379,
            _index = 283
        },
        {
            Done = { 30605 },
            coord = { x = 1675.4, y = 2944.8 },
            Zone = 379,
            _index = 284
        },
        {
            PickUp = { 30607, 30606, 30608 },
            coord = { x = 1675.4, y = 2944.8 },
            Zone = 379,
            _index = 285
        },
        {
            Qpart = { [30606] = { 1 }, [30608] = { 1 } },
            coord = { x = 1652.4, y = 2998.3 },
            Range = 30,
            Zone = 379,
            _index = 286
        },
        {
            Waypoint = 30606,
            coord = { x = 1685.2, y = 3037.4 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 287
        },
        {
            Waypoint = 30606,
            coord = { x = 1700.1, y = 3102.1 },
            Range = 5,
            Zone = 382,
            _index = 288
        },
        {
            Waypoint = 30606,
            coord = { x = 1754.8, y = 3082.7 },
            Range = 5,
            Zone = 382,
            _index = 289
        },
        {
            Qpart = { [30607] = { 1 } },
            coord = { x = 1782.5, y = 3149.8 },
            Range = 5,
            Zone = 382,
            _index = 290
        },
        {
            Qpart = { [30607] = { 2 } },
            coord = { x = 1764.6, y = 3141.3 },
            Zone = 382,
            _index = 291
        },
        {
            Done = { 30606, 30607, 30608 },
            coord = { x = 1584.8, y = 2813.9 },
            Zone = 379,
            _index = 292
        },
        {
            PickUp = { 30610, 30611 },
            coord = { x = 1584.8, y = 2813.9 },
            Zone = 379,
            _index = 293
        },
        {
            Qpart = { [30610] = { 1 }, [30611] = { 1 } },
            coord = { x = 1941.5, y = 2950.6 },
            Range = 30,
            Zone = 379,
            _index = 294
        },
        {
            Waypoint = 30610,
            coord = { x = 1976.2, y = 3035.9 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 379,
            _index = 295
        },
        {
            Done = { 30610, 30611 },
            coord = { x = 1964.6, y = 2946.5 },
            Zone = 379,
            _index = 296
        },
        {
            PickUp = { 30612 },
            coord = { x = 1964.6, y = 2946.5 },
            Zone = 379,
            _index = 297
        },
        {
            Qpart = { [30612] = { 1, 2 } },
            coord = { x = 1960.1, y = 2979.9 },
            Range = 5,
            Zone = 379,
            _index = 298
        },
        {
            Done = { 30612 },
            coord = { x = 1586.3, y = 2813 },
            Zone = 379,
            _index = 299
        },
        {
            PickUp = { 30692 },
            coord = { x = 1606.5, y = 2788.6 },
            Zone = 379,
            _index = 300
        },
        {
            Qpart = { [30692] = { 1 } },
            ExtraLineText = "OPEN_YOUR_MAP_TO_SEE_WHERE_NPCS_TO_ESCORT",
            NoArrow = 1,
            Zone = 379,
            _index = 301
        },
        {
            GetFP = 1023,
            coord = { x = 2160.5, y = 2713.6 },
            Zone = 379,
            _index = 302
        },
        {
            SetHS = 30744,
            coord = { x = 2169.9, y = 2709.4 },
            Zone = 379,
            _index = 303
        },
        {
            PickUp = { 30744, 30745, 30742, 30743 },
            coord = { x = 2185.8, y = 2711.7 },
            Zone = 379,
            _index = 304
        },
        {
            Done = { 30692 },
            coord = { x = 2183, y = 2741.6 },
            Zone = 379,
            _index = 305
        },
        {
            Waypoint = 30744,
            coord = { x = 2492.2, y = 2365.9 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 306
        },
        {
            Qpart = { [30744] = { 1 }, [30745] = { 1 } },
            coord = { x = 2546.9, y = 2409.3 },
            Fillers = { [30742] = { 1 }, [30743] = { 1 } },
            Button = { ["30744-1"] = 81054 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 30,
            Zone = 379,
            _index = 307
        },
        {
            Done = { 30744 },
            NoArrow = 1,
            Zone = 379,
            _index = 308
        },
        {
            PickUp = { 30746 },
            NoArrow = 1,
            Zone = 379,
            _index = 309
        },
        {
            Waypoint = 30746,
            coord = { x = 2495, y = 2366.4 },
            Range = 5,
            Zone = 379,
            _index = 310
        },
        {
            Qpart = { [30742] = { 1 }, [30743] = { 1 } },
            coord = { x = 2470.4, y = 2522 },
            Range = 69,
            Zone = 379,
            _index = 311
        },
        {
            Waypoint = 30746,
            coord = { x = 2507.5, y = 2454.4 },
            Range = 5,
            Zone = 379,
            _index = 312
        },
        {
            Done = { 30746 },
            coord = { x = 2527.5, y = 2438.6 },
            Zone = 379,
            _index = 313
        },
        {
            Done = { 30745, 30742, 30743 },
            coord = { x = 2177, y = 2722.4 },
            ETA = 20,
            Zone = 379,
            _index = 314
        },
        {
            PickUp = { 30747 },
            coord = { x = 2180.8, y = 2724.4 },
            Zone = 379,
            _index = 315
        },
        {
            Qpart = { [30747] = { 1 } },
            coord = { x = 1711.8, y = 2784.4 },
            ExtraLineText = "TALK_TO_KOTA_KON_TO_GET_ON_HIS_BACK",
            GossipOptionIDs = { 34810 },
            Range = 100,
            Zone = 379,
            _index = 316
        },
        {
            Done = { 30747 },
            coord = { x = 2178.4, y = 2725.9 },
            Zone = 379,
            _index = 317
        },
        {
            Waypoint = 31453,
            coord = { x = 2020.6, y = 1864.1 },
            Range = 2,
            Zone = 379,
            _index = 318
        },
        {
            Done = { 31453 },
            coord = { x = 2056.3, y = 1866.5 },
            Zone = 379,
            _index = 319
        },
        {
            PickUp = { 30665, 30670 },
            coord = { x = 2056.3, y = 1866.5 },
            Zone = 379,
            _index = 320
        },
        {
            PickUp = { 30682 },
            coord = { x = 2152.2, y = 1932.9 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 321
        },
        {
            Qpart = { [30682] = { 4 } },
            coord = { x = 2150.5, y = 1932.5 },
            ExtraLineText = "IF_SYA_ZHONG_IS_NOT_RESCUED_IMMEDIATELY_AFTER_ACCEPTING_QUEST_ABANDON_IT_AND_TAKE_IT_AGAIN",
            Zone = 379,
            _index = 322
        },
        {
            Qpart = { [30682] = { 2 } },
            coord = { x = 2270.7, y = 1988.9 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 37051 },
            Zone = 379,
            _index = 323
        },
        {
            Qpart = { [30682] = { 3 } },
            coord = { x = 2158.7, y = 2042.6 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 37052 },
            Zone = 379,
            _index = 324
        },
        {
            Qpart = { [30682] = { 1 } },
            coord = { x = 2093.5, y = 2023.5 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 35293 },
            Zone = 379,
            _index = 325
        },
        {
            Qpart = { [30670] = { 1 } },
            coord = { x = 2210.2, y = 1998.4 },
            Fillers = { [30665] = { 1 } },
            Range = 30,
            Zone = 379,
            _index = 326
        },
        {
            Qpart = { [30665] = { 1 } },
            coord = { x = 2051.1, y = 1933.4 },
            Range = 30,
            Zone = 379,
            _index = 327
        },
        {
            Done = { 30670, 30665, 30682 },
            coord = { x = 2055.9, y = 1867.1 },
            Zone = 379,
            _index = 328
        },
        {
            PickUp = { 30690 },
            coord = { x = 2055.9, y = 1867.1 },
            Zone = 379,
            _index = 329
        },
        {
            Qpart = { [30690] = { 1, 2 } },
            coord = { x = 1994.9, y = 2028 },
            Button = { ["30690-1"] = 81741 },
            ExtraLineText = "SET_UP_TRAP_AND_PULL_MOB_ONTO_IT_ONCE_TRAPPED_USE_YOUR_EXTRA_ACTION_BUTTON_TO_SPAWN_SHA",
            Range = 5,
            ExtraActionB = 1,
            Zone = 379,
            _index = 330
        },
        {
            Done = { 30690 },
            coord = { x = 2055.7, y = 1866.4 },
            Zone = 379,
            _index = 331
        },
        {
            PickUp = { 30699 },
            coord = { x = 2055.7, y = 1866.4 },
            Zone = 379,
            _index = 332
        },
        {
            GetFP = 1024,
            coord = { x = 2092, y = 1880.8 },
            ExtraLineText = "UP_TOWER",
            Zone = 379,
            _index = 333
        },
        {
            UseHS = 30699,
            Zone = 379,
            _index = 334
        },
        {
            Done = { 30699 },
            coord = { x = 2652.1, y = 3139.8 },
            Zone = 379,
            _index = 335
        },
        {
            PickUp = { 30723 },
            coord = { x = 2652.1, y = 3139.8 },
            Zone = 379,
            _index = 336
        },
        {
            PickUp = { 30715 },
            coord = { x = 2641.1, y = 3128.4 },
            Zone = 379,
            _index = 337
        },
        {
            GetFP = 1025,
            coord = { x = 2678.6, y = 3151.8 },
            Zone = 379,
            _index = 338
        },
        {
            PickUp = { 31847 },
            coord = { x = 2678.6, y = 3151.8 },
            Zone = 379,
            _index = 339
        },
        {
            Qpart = { [30715] = { 1 } },
            coord = { x = 2938.5, y = 3113.3 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 340
        },
        {
            Qpart = { [30715] = { 2 } },
            coord = { x = 2951.6, y = 3010.5 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 341
        },
        {
            Qpart = { [30715] = { 3 } },
            coord = { x = 2963.9, y = 2930.2 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 342
        },
        {
            Qpart = { [30723] = { 1 } },
            coord = { x = 2919.3, y = 3010.3 },
            Range = 45,
            Zone = 379,
            _index = 343
        },
        {
            Done = { 30715 },
            coord = { x = 2641.7, y = 3129.5 },
            Zone = 379,
            _index = 344
        },
        {
            Done = { 30723 },
            coord = { x = 2652.7, y = 3144 },
            Zone = 379,
            _index = 345
        },
        {
            PickUp = { 30724 },
            coord = { x = 2652.7, y = 3144 },
            Zone = 379,
            _index = 346
        },
        {
            Qpart = { [30724] = { 1 } },
            coord = { x = 2677.5, y = 3151.3 },
            GossipOptionIDs = { 29681 },
            Range = 30,
            Zone = 379,
            _index = 347
        },
        {
            Done = { 30724 },
            coord = { x = 3005.8, y = 3018.5 },
            ETA = 14,
            Zone = 379,
            _index = 348
        },
        {
            PickUp = { 30750, 30751 },
            coord = { x = 3005.8, y = 3018.5 },
            Zone = 379,
            _index = 349
        },
        {
            Qpart = { [30750] = { 1 }, [30751] = { 1 } },
            coord = { x = 3135.2, y = 3094.9 },
            Range = 30,
            Zone = 379,
            _index = 350
        },
        {
            Done = { 30751, 30750 },
            coord = { x = 3007.6, y = 3019.7 },
            Zone = 379,
            _index = 351
        },
        {
            PickUp = { 30994 },
            coord = { x = 3007.6, y = 3019.7 },
            Zone = 379,
            _index = 352
        },
        {
            Qpart = { [30994] = { 1 } },
            coord = { x = 3006, y = 3020.2 },
            GossipOptionIDs = { 30541 },
            Range = 30,
            Zone = 379,
            _index = 353
        },
        {
            Done = { 30994 },
            coord = { x = 2848.5, y = 3110.8 },
            ETA = 6,
            Zone = 379,
            _index = 354
        },
        {
            PickUp = { 30991 },
            coord = { x = 2848.5, y = 3110.8 },
            Zone = 379,
            _index = 355
        },
        {
            Qpart = { [30991] = { 2 } },
            coord = { x = 2835.5, y = 3097 },
            ExtraLineText = "CLICK_ON_BARREL_TO_CONTROL_IT_AND_KILL_MOBS",
            Range = 2,
            Zone = 379,
            _index = 356
        },
        {
            Done = { 30991 },
            coord = { x = 2848.2, y = 3110.3 },
            Zone = 379,
            _index = 357
        },
        {
            PickUp = { 30992 },
            coord = { x = 2848.2, y = 3110.3 },
            Zone = 379,
            _index = 358
        },
        {
            Qpart = { [30992] = { 1 } },
            coord = { x = 2902.3, y = 3028.6 },
            Range = 5,
            Zone = 379,
            _index = 359
        },
        {
            Done = { 30992 },
            coord = { x = 2880.5, y = 3052 },
            Zone = 379,
            _index = 360
        },
        {
            PickUp = { 30993 },
            coord = { x = 2880.5, y = 3052 },
            Zone = 379,
            _index = 361
        },
        {
            Qpart = { [30993] = { 1 } },
            coord = { x = 2881, y = 3052.6 },
            GossipOptionIDs = { 29128 },
            Zone = 379,
            _index = 362
        },
        {
            Qpart = { [30993] = { 2 } },
            coord = { x = 2714.4, y = 3172.6 },
            GossipOptionIDs = { 29129 },
            Zone = 379,
            _index = 363
        },
        {
            Done = { 30993 },
            coord = { x = 2630, y = 3551.2 },
            Zone = 379,
            _index = 364
        },
        {
            PickUp = { 30752 },
            coord = { x = 2630, y = 3551.2 },
            Zone = 379,
            _index = 365
        },
        {
            Qpart = { [30752] = { 1 } },
            coord = { x = 2543.2, y = 3629.1 },
            GossipOptionIDs = { 41432 },
            Zone = 379,
            _index = 366
        },
        {
            Done = { 30752 },
            coord = { x = 2543.2, y = 3629.1 },
            Zone = 379,
            _index = 367
        },
        {
            PickUp = { 31030 },
            PickUpDB = { 31030, 31031 },
            coord = { x = 2543.2, y = 3629.1 },
            Zone = 379,
            _index = 368
        },
        {
            Done = { 31030 },
            DoneDB = { 31030, 31031 },
            ExtraLineText = "TURN_IN_QUEST_INSIDE_DUNGEON_THEN_EXIT",
            NoArrow = 1,
            _index = 369
        },
        {
            UseHS = 31512,
            Zone = 379,
            _index = 370
        },
        {
            Qpart = { [31512] = { 1 } },
            coord = { x = 1390.8, y = 1790.8 },
            GossipOptionIDs = { 41177 },
            Zone = 379,
            _index = 371
        },
        {
            Done = { 31512 },
            coord = { x = 282.4, y = 786.3 },
            Zone = 393,
            _index = 372
        },
        {
            UseFlightPath = 31695,
            NodeID = 1024,
            coord = { x = 336.7, y = 894.2 },
            ETA = 111,
            Zone = 390,
            _index = 373
        },
        {
            GetFP = 1053,
            coord = { x = 2995.1, y = 2363.3 },
            Zone = 388,
            _index = 374
        },
        {
            RouteCompleted = 1,
            _index = 375
        }
    }

    APR.RouteQuestStepList["390-Isle of Thunder"] = {
        {
            PickUp = { 32679 },
            coord = { x = 353.7, y = 957.8 },
            Zone = 390,
            _index = 1
        },
        {
            UseFlightPath = 32679,
            NodeID = 1056,
            coord = { x = 337.8, y = 895.7 },
            ETA = 195,
            Zone = 390,
            _index = 2
        },
        {
            Done = { 32679 },
            coord = { x = 4211, y = 1914.7 },
            Zone = 388,
            _index = 3
        },
        {
            PickUp = { 32681 },
            coord = { x = 4211, y = 1914.7 },
            Zone = 388,
            _index = 4
        },
        {
            Qpart = { [32681] = { 1 } },
            coord = { x = 4211, y = 1914.7 },
            GossipOptionIDs = { 41772 },
            Range = 30,
            Zone = 388,
            _index = 5
        },
        {
            Done = { 32681 },
            coord = { x = 6223.2, y = 5682.6 },
            Zone = 504,
            _index = 6
        },
        {
            PickUp = { 32644, 32706 },
            coord = { x = 6223.2, y = 5682.6 },
            Zone = 504,
            _index = 7
        },
        {
            Qpart = { [32644] = { 1 } },
            coord = { x = 6223.1, y = 5682.6 },
            GossipOptionIDs = { 41766 },
            RaidIcon = 70370,
            Zone = 504,
            _index = 8
        },
        {
            Qpart = { [32644] = { 2 } },
            coord = { x = 4991, y = 6135.5 },
            Range = 5,
            Zone = 516,
            _index = 9
        },
        {
            Done = { 32644 },
            coord = { x = 5039.1, y = 6157.3 },
            Zone = 504,
            _index = 10
        },
        {
            PickUp = { 32654 },
            coord = { x = 5039.1, y = 6157.3 },
            Zone = 504,
            _index = 11
        },
        {
            Qpart = { [32654] = { 1 } },
            coord = { x = 5039.1, y = 6157.3 },
            GossipOptionIDs = { 41768 },
            RaidIcon = 67992,
            Zone = 504,
            _index = 12
        },
        {
            Qpart = { [32654] = { 2 } },
            coord = { x = 5391, y = 6884.4 },
            Range = 5,
            Zone = 516,
            _index = 13
        },
        {
            Done = { 32654 },
            coord = { x = 5039.3, y = 6157.2 },
            ExtraLineText = "USE_GATE",
            Zone = 504,
            _index = 14
        },
        {
            PickUp = { 32652 },
            coord = { x = 5039.3, y = 6157.2 },
            Zone = 504,
            _index = 15
        },
        {
            Qpart = { [32652] = { 1 } },
            coord = { x = 5039.3, y = 6157.2 },
            GossipOptionIDs = { 41767 },
            RaidIcon = 67992,
            Zone = 504,
            _index = 16
        },
        {
            Qpart = { [32652] = { 2 } },
            coord = { x = 5636.6, y = 7314.4 },
            Range = 5,
            RaidIcon = 69917,
            Zone = 517,
            _index = 17
        },
        {
            Done = { 32652 },
            coord = { x = 5042.2, y = 6111.7 },
            ExtraLineText = "USE_GATEWAY",
            Zone = 504,
            _index = 18
        },
        {
            PickUp = { 32655 },
            coord = { x = 5040.3, y = 6110.7 },
            Zone = 504,
            _index = 19
        },
        {
            Qpart = { [32655] = { 1 } },
            coord = { x = 5040.3, y = 6110.7 },
            GossipOptionIDs = { 41662 },
            Range = 5,
            ExtraActionB = 1,
            RaidIcon = 70297,
            Zone = 516,
            _index = 20
        },
        {
            Done = { 32655 },
            coord = { x = 5039.2, y = 6157.3 },
            Zone = 504,
            _index = 21
        },
        {
            PickUp = { 32656 },
            coord = { x = 5039.2, y = 6157.3 },
            Zone = 504,
            _index = 22
        },
        {
            Qpart = { [32656] = { 1 } },
            coord = { x = 5039.2, y = 6157.3 },
            GossipOptionIDs = { 41765 },
            RaidIcon = 67992,
            Zone = 504,
            _index = 23
        },
        {
            Qpart = { [32656] = { 2 } },
            coord = { x = 5177.7, y = 7104.7 },
            Range = 5,
            Zone = 516,
            _index = 24
        },
        {
            Done = { 32656 },
            coord = { x = 5039.3, y = 6157.4 },
            Zone = 504,
            _index = 25
        },
        {
            Done = { 32706 },
            coord = { x = 5527.8, y = 6877.7 },
            Zone = 504,
            _index = 26
        },
        {
            PickUp = { 32707 },
            coord = { x = 5527.8, y = 6877.7 },
            Zone = 504,
            _index = 27
        },
        {
            Qpart = { [32707] = { 1 } },
            coord = { x = 5659.3, y = 6427.5 },
            ExtraLineText = "LOOK_FOR_RARES_AND_TREASURE_CHESTS_ON_ISLAND",
            Range = 600,
            Zone = 504,
            _index = 28
        },
        {
            Done = { 32707 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 29
        },
        {
            PickUp = { 32708 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 30
        },
        {
            Waypoint = 32708,
            coord = { x = 5397.1, y = 6048.7 },
            Range = 5,
            Zone = 504,
            _index = 31
        },
        {
            Qpart = { [32708] = { 1, 2 } },
            coord = { x = 5372.7, y = 5730.5 },
            Range = 1,
            Zone = 504,
            _index = 32
        },
        {
            Qpart = { [32708] = { 2 } },
            coord = { x = 5384.1, y = 5723.5 },
            Range = 5,
            Zone = 504,
            _index = 33
        },
        {
            Done = { 32708 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 34
        },
        {
            PickUp = { 32640 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 35
        },
        {
            Qpart = { [32640] = { 1, 2, 3 } },
            coord = { x = 5659.3, y = 6427.5 },
            ExtraLineText = "YOU_NEED_3_SHANZE_RITUAL_STONE_FOR_EACH_OBJECTIVE",
            Range = 600,
            Zone = 504,
            _index = 36
        },
        {
            Done = { 32640 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 37
        },
        {
            RouteCompleted = 1,
            _index = 38
        }
    }
end
