if APR.Faction == "Horde" then
    APR.RouteQuestStepList["85-MoP Intro"] = {
        {
            PickUp = { 60126 },
            ChromiePick = 8,
            coord = { x = -4216, y = 1559 },
            GossipOptionIDs = { 51901, 51902 },
            Zone = 85,
            _index = 1
        },
        {
            Waypoint = 60126,
            coord = { x = -4214.3, y = 1589.3 },
            Range = 5,
            Zone = 85,
            _index = 2
        },
        {
            Waypoint = 60126,
            coord = { x = -4267.4, y = 1607.6 },
            Range = 5,
            Zone = 85,
            _index = 3
        },
        {
            Waypoint = 60126,
            coord = { x = -4300.1, y = 1612.2 },
            Range = 5,
            Zone = 85,
            _index = 4
        },
        {
            Waypoint = 60126,
            coord = { x = -4374.7, y = 1608.2 },
            Range = 5,
            Zone = 85,
            _index = 5
        },
        {
            Done = { 60126 },
            coord = { x = -4354, y = 1665.7 },
            Zone = 85,
            _index = 6
        },
        {
            PickUp = { 31853 },
            coord = { x = -4354, y = 1665.7 },
            Zone = 85,
            _index = 7
        },
        {
            Waypoint = 31853,
            coord = { x = -4374.7, y = 1608.2 },
            Range = 5,
            Zone = 85,
            _index = 8
        },
        {
            Waypoint = 31853,
            coord = { x = -4393, y = 1612.7 },
            Range = 5,
            Zone = 85,
            _index = 9
        },
        {
            Waypoint = 31853,
            coord = { x = -4386.4, y = 1748.5 },
            ExtraLineText = "UP_ELEVATOR",
            Range = 5,
            Zone = 85,
            _index = 10
        },
        {
            Waypoint = 31853,
            coord = { x = -4387.6, y = 1768.8 },
            Range = 5,
            Zone = 85,
            _index = 11
        },
        {
            GetFP = 23,
            coord = { x = -4368.3, y = 1798.2 },
            Zone = 85,
            _index = 12
        },
        {
            Qpart = { [31853] = { 1 } },
            coord = { x = -4362.1, y = 1723.6 },
            GossipOptionIDs = { 30402 },
            ETA = 31,
            Zone = 85,
            _index = 13
        },
        {
            Qpart = { [31853] = { 2 } },
            coord = { x = -5462.9, y = 1860.1 },
            Zone = 12,
            _index = 14
        },
        {
            Done = { 31853 },
            coord = { x = -5462.9, y = 1860.1 },
            Zone = 12,
            _index = 15
        },
        {
            PickUp = { 29690 },
            coord = { x = -5462.9, y = 1860.1 },
            Zone = 12,
            _index = 16
        },
        {
            Qpart = { [29690] = { 1 } },
            coord = { x = -721.3, y = 3138.9 },
            GossipOptionIDs = { 41023 },
            Zone = 371,
            _index = 17
        },
        {
            Done = { 29690 },
            coord = { x = -698.2, y = 3176.7 },
            Zone = 371,
            _index = 18
        },
        {
            RouteCompleted = 1,
            _index = 19
        }
    }

    APR.RouteQuestStepList["371-The Jade Forest"] = {
        {
            PickUp = { 31765 },
            coord = { x = -698.2, y = 3176.7 },
            Zone = 371,
            _index = 1
        },
        {
            Waypoint = 31765,
            coord = { x = -712.5, y = 3149.9 },
            Range = 5,
            Zone = 371,
            _index = 2
        },
        {
            Waypoint = 31765,
            coord = { x = -737.7, y = 3139.3 },
            Range = 5,
            Zone = 371,
            _index = 3
        },
        {
            Waypoint = 31765,
            coord = { x = -737.5, y = 3099.9 },
            Range = 5,
            Zone = 371,
            _index = 4
        },
        {
            Waypoint = 31765,
            coord = { x = -721.4, y = 3116.2 },
            ExtraLineText = "USE_CANON",
            Range = 5,
            Zone = 371,
            _index = 5
        },
        {
            Waypoint = 31765,
            coord = { x = -746.5, y = 3138 },
            ExtraLineText = "USE_CANON",
            Range = 5,
            Zone = 371,
            _index = 6
        },
        {
            Qpart = { [31765] = { 1, 2 } },
            coord = { x = -748.2, y = 3138.8 },
            Range = 30,
            Zone = 371,
            _index = 7
        },
        {
            Done = { 31765 },
            coord = { x = -715.4, y = 3139.2 },
            Zone = 371,
            _index = 8
        },
        {
            PickUp = { 31766 },
            coord = { x = -715.4, y = 3139.2 },
            Zone = 371,
            _index = 9
        },
        {
            Qpart = { [31766] = { 1 } },
            coord = { x = -750.8, y = 3133.8 },
            ExtraLineText = "USE_ROPE",
            Range = 30,
            Zone = 371,
            _index = 10
        },
        {
            Done = { 31766 },
            coord = { x = -751.3, y = 3126.2 },
            Zone = 371,
            _index = 11
        },
        {
            PickUp = { 31767, 31768 },
            coord = { x = -751.3, y = 3126.2 },
            Zone = 371,
            _index = 12
        },
        {
            Qpart = { [31767] = { 1 }, [31768] = { 1 } },
            coord = { x = -927, y = 3282.8 },
            Button = { ["31768-1"] = 89605 },
            Range = 100,
            Zone = 371,
            _index = 13
        },
        {
            Done = { 31767, 31768 },
            coord = { x = -975.2, y = 3157.1 },
            Zone = 371,
            _index = 14
        },
        {
            PickUp = { 31769 },
            coord = { x = -975.2, y = 3157.1 },
            Zone = 371,
            _index = 15
        },
        {
            Qpart = { [31769] = { 1 } },
            coord = { x = -923.6, y = 3192.3 },
            Button = { ["31769-1"] = 89769 },
            Range = 5,
            Zone = 371,
            _index = 16
        },
        {
            Qpart = { [31769] = { 2 } },
            coord = { x = -971.1, y = 3194.8 },
            Button = { ["31769-2"] = 89769 },
            Range = 5,
            Zone = 371,
            _index = 17
        },
        {
            Qpart = { [31769] = { 3 } },
            coord = { x = -989.1, y = 3165.7 },
            Button = { ["31769-3"] = 89769 },
            Range = 30,
            Zone = 371,
            _index = 18
        },
        {
            Qpart = { [31769] = { 4 } },
            coord = { x = -897.8, y = 3158 },
            Button = { ["31769-4"] = 89769 },
            Range = 30,
            Zone = 371,
            _index = 19
        },
        {
            Done = { 31769 },
            coord = { x = -900, y = 3157.9 },
            Zone = 371,
            _index = 20
        },
        {
            PickUp = { 31771, 29694, 31770 },
            coord = { x = -900.7, y = 3157.2 },
            Zone = 371,
            _index = 21
        },
        {
            Qpart = { [31771] = { 1, 2 } },
            coord = { x = -950.3, y = 3157.8 },
            Range = 69,
            Zone = 371,
            _index = 22
        },
        {
            Qpart = { [29694] = { 1 } },
            coord = { x = -786, y = 3032.3 },
            GossipOptionIDs = { 39490 },
            Zone = 371,
            _index = 23
        },
        {
            PickUp = { 31773, 31978 },
            coord = { x = -786, y = 3032.3 },
            Zone = 371,
            _index = 24
        },
        {
            Qpart = { [29694] = { 3 } },
            coord = { x = -684.1, y = 3109.1 },
            Fillers = { [31773] = { 1 }, [31978] = { 1 } },
            GossipOptionIDs = { 39687 },
            Zone = 371,
            _index = 25
        },
        {
            Qpart = { [29694] = { 2 } },
            coord = { x = -678, y = 3315.3 },
            Fillers = { [31773] = { 1 }, [31978] = { 1 } },
            GossipOptionIDs = { 39686 },
            Zone = 371,
            _index = 26
        },
        {
            Qpart = { [29694] = { 4 } },
            coord = { x = -602, y = 3258.5 },
            Fillers = { [31773] = { 1 }, [31978] = { 1 } },
            GossipOptionIDs = { 39688 },
            Zone = 371,
            _index = 27
        },
        {
            Qpart = { [31773] = { 1 }, [31978] = { 1 } },
            coord = { x = -692.2, y = 3106.2 },
            Range = 45,
            Zone = 371,
            _index = 28
        },
        {
            Qpart = { [31770] = { 1 } },
            coord = { x = -589.6, y = 3023 },
            Range = 30,
            Zone = 371,
            _index = 29
        },
        {
            Done = { 31770, 31771, 31773, 29694 },
            coord = { x = -584.7, y = 3009.5 },
            Zone = 371,
            _index = 30
        },
        {
            PickUp = { 31774 },
            coord = { x = -584.7, y = 3009.5 },
            Zone = 371,
            _index = 31
        },
        {
            Done = { 31978 },
            coord = { x = -599.3, y = 3019.6 },
            Zone = 371,
            _index = 32
        },
        {
            Done = { 81638 },
            coord = { x = -538.9, y = 3031.3 },
            HasAura = 424143,
            Zone = 371,
            _index = 33
        },
        {
            SetHS = 31774,
            coord = { x = -541.6, y = 3031.2 },
            Zone = 371,
            _index = 34
        },
        {
            Waypoint = 31774,
            coord = { x = -550, y = 2968.5 },
            Range = 5,
            Zone = 371,
            _index = 35
        },
        {
            Waypoint = 31774,
            coord = { x = -504.8, y = 2967.1 },
            Range = 5,
            Zone = 371,
            _index = 36
        },
        {
            GetFP = 973,
            coord = { x = -503.1, y = 2919.1 },
            Zone = 371,
            _index = 37
        },
        {
            Waypoint = 31774,
            coord = { x = -523.3, y = 2866.8 },
            Range = 5,
            Zone = 371,
            _index = 38
        },
        {
            Done = { 31774 },
            coord = { x = -723, y = 2836.8 },
            Zone = 371,
            _index = 39
        },
        {
            PickUp = { 29765 },
            coord = { x = -723, y = 2836.8 },
            Zone = 371,
            _index = 40
        },
        {
            PickUp = { 29743 },
            coord = { x = -711.5, y = 2836.8 },
            Zone = 371,
            _index = 41
        },
        {
            Qpart = { [29743] = { 1 } },
            coord = { x = -597.7, y = 2771.5 },
            Fillers = { [29765] = { 1, 2, 3, 4 } },
            GossipOptionIDs = { 40006 },
            Zone = 371,
            _index = 42
        },
        {
            Qpart = { [29743] = { 2 } },
            coord = { x = -634.8, y = 2660.4 },
            Fillers = { [29765] = { 1, 2, 3, 4 } },
            GossipOptionIDs = { 39082 },
            Zone = 371,
            _index = 43
        },
        {
            Qpart = { [29743] = { 4 } },
            coord = { x = -639.4, y = 2610.9 },
            Fillers = { [29765] = { 1, 2, 3, 4 } },
            GossipOptionIDs = { 39808 },
            Zone = 371,
            _index = 44
        },
        {
            Qpart = { [29743] = { 3 } },
            coord = { x = -547.8, y = 2619.3 },
            Fillers = { [29765] = { 1, 2, 3, 4 } },
            GossipOptionIDs = { 39083 },
            Zone = 371,
            _index = 45
        },
        {
            Done = { 29743 },
            NoArrow = 1,
            Zone = 371,
            _index = 46
        },
        {
            Qpart = { [29765] = { 1, 2, 3, 4 } },
            coord = { x = -635.3, y = 2676.6 },
            Range = 69,
            Zone = 371,
            _index = 47
        },
        {
            Done = { 29765 },
            NoArrow = 1,
            Zone = 371,
            _index = 48
        },
        {
            PickUp = { 29804 },
            NoArrow = 1,
            Zone = 371,
            _index = 49
        },
        {
            Qpart = { [29804] = { 1 } },
            coord = { x = -777.7, y = 2618.9 },
            Range = 2,
            Zone = 371,
            _index = 50
        },
        {
            Done = { 29804 },
            coord = { x = -758.8, y = 2632.6 },
            Zone = 371,
            _index = 51
        },
        {
            PickUp = { 31775, 31776 },
            coord = { x = -758.8, y = 2632.6 },
            Zone = 371,
            _index = 52
        },
        {
            PickUp = { 31778 },
            coord = { x = -743.8, y = 2639 },
            Zone = 371,
            _index = 53
        },
        {
            PickUp = { 31777 },
            coord = { x = -723.8, y = 2647.8 },
            Zone = 371,
            _index = 54
        },
        {
            Qpart = { [31776] = { 2 } },
            coord = { x = -618.6, y = 2575 },
            Fillers = { [31775] = { 1 }, [31778] = { 1 } },
            GossipOptionIDs = { 41756, 41782 },
            Range = 5,
            Zone = 371,
            _index = 55
        },
        {
            Qpart = { [31776] = { 1 } },
            coord = { x = -660.5, y = 2524.4 },
            Fillers = { [31775] = { 1 }, [31778] = { 1 } },
            GossipOptionIDs = { 41756, 41782 },
            Range = 5,
            Zone = 371,
            _index = 56
        },
        {
            Qpart = { [31776] = { 3 } },
            coord = { x = -489, y = 2584.3 },
            Fillers = { [31775] = { 1 }, [31778] = { 1 } },
            GossipOptionIDs = { 41756, 41782 },
            Range = 5,
            Zone = 371,
            _index = 57
        },
        {
            Qpart = { [31776] = { 4 } },
            coord = { x = -491.7, y = 2577.4 },
            Fillers = { [31775] = { 1 }, [31778] = { 1 } },
            GossipOptionIDs = { 41756, 41782 },
            Range = 5,
            Zone = 371,
            _index = 58
        },
        {
            Qpart = { [31777] = { 1 } },
            coord = { x = -497.6, y = 2509.3 },
            Fillers = { [31775] = { 1 }, [31778] = { 1 } },
            Button = { ["31777-1"] = 89163 },
            ExtraLineText = "LOOT_REQUISITIONED_FIREWORK_LAUNCHER_IN_ZONE",
            GossipOptionIDs = { 41756, 41782 },
            Range = 45,
            Zone = 371,
            _index = 59
        },
        {
            Qpart = { [31775] = { 1 }, [31778] = { 1 } },
            coord = { x = -497.6, y = 2509.3 },
            GossipOptionIDs = { 41756, 41782 },
            Range = 45,
            Zone = 371,
            _index = 60
        },
        {
            Done = { 31777 },
            coord = { x = -721.2, y = 2647.9 },
            Zone = 371,
            _index = 61
        },
        {
            Done = { 31778 },
            coord = { x = -741, y = 2639.9 },
            Zone = 371,
            _index = 62
        },
        {
            Done = { 31775, 31776 },
            coord = { x = -759.1, y = 2632.8 },
            Zone = 371,
            _index = 63
        },
        {
            PickUp = { 31779 },
            coord = { x = -759.1, y = 2632.8 },
            Zone = 371,
            _index = 64
        },
        {
            Waypoint = 31779,
            coord = { x = -464.6, y = 2483.1 },
            Range = 5,
            Zone = 371,
            _index = 65
        },
        {
            Waypoint = 31779,
            coord = { x = -390.2, y = 2492.1 },
            Range = 5,
            Zone = 371,
            _index = 66
        },
        {
            Qpart = { [31779] = { 1 } },
            coord = { x = -348.3, y = 2548 },
            Range = 5,
            Zone = 371,
            _index = 67
        },
        {
            Done = { 31779 },
            coord = { x = -473.7, y = 2521.8 },
            Zone = 371,
            _index = 68
        },
        {
            PickUp = { 31999 },
            coord = { x = -473.7, y = 2521.8 },
            Zone = 371,
            _index = 69
        },
        {
            Done = { 31999 },
            coord = { x = -531.1, y = 2492.7 },
            Zone = 371,
            _index = 70
        },
        {
            PickUp = { 29815 },
            coord = { x = -516.5, y = 2497.6 },
            Zone = 371,
            _index = 71
        },
        {
            PickUp = { 29821 },
            coord = { x = -512.7, y = 2501.6 },
            Zone = 371,
            _index = 72
        },
        {
            Waypoint = 31112,
            coord = { x = -225.1, y = 2389.8 },
            Range = 5,
            Zone = 371,
            _index = 73
        },
        {
            Done = { 29821 },
            coord = { x = -147.5, y = 2227.4 },
            Button = { ["29821"] = 84157 },
            Zone = 371,
            _index = 74
        },
        {
            PickUp = { 31112 },
            coord = { x = -147.5, y = 2227.4 },
            Zone = 371,
            _index = 75
        },
        {
            Qpart = { [29815] = { 1 }, [31112] = { 1 } },
            coord = { x = -291.3, y = 2408.5 },
            Button = { ["31112"] = 84157 },
            Range = 60,
            Zone = 371,
            _index = 76
        },
        {
            Waypoint = 31112,
            coord = { x = -489, y = 2434.7 },
            Range = 5,
            Zone = 371,
            _index = 77
        },
        {
            Done = { 31112 },
            coord = { x = -508.7, y = 2501.9 },
            Zone = 371,
            _index = 78
        },
        {
            Done = { 29815 },
            coord = { x = -516.4, y = 2497.5 },
            Zone = 371,
            _index = 79
        },
        {
            PickUp = { 29827 },
            coord = { x = -516.4, y = 2497.5 },
            Zone = 371,
            _index = 80
        },
        {
            Waypoint = 29827,
            coord = { x = -507.4, y = 2497.9 },
            Range = 5,
            Zone = 371,
            _index = 81
        },
        {
            Qpart = { [29827] = { 1, 2 } },
            coord = { x = -508.1, y = 2498.2 },
            ExtraLineText = "USE_GYROCHOPPA",
            ExtraLineText2 = "DONT_SKIP_CINEMATIC",
            Dontskipvid = 1,
            Zone = 371,
            _index = 82
        },
        {
            Done = { 29827 },
            coord = { x = -516.6, y = 2498.4 },
            Zone = 371,
            _index = 83
        },
        {
            PickUp = { 29822 },
            coord = { x = -531.7, y = 2491.6 },
            Zone = 371,
            _index = 84
        },
        {
            Waypoint = 31112,
            coord = { x = -442.6, y = 2280.9 },
            Range = 5,
            Zone = 371,
            _index = 85
        },
        {
            Qpart = { [29822] = { 3 } },
            coord = { x = -487, y = 2241.6 },
            Range = 5,
            Zone = 371,
            _index = 86
        },
        {
            Waypoint = 31112,
            coord = { x = -461, y = 2202.1 },
            Range = 5,
            Zone = 371,
            _index = 87
        },
        {
            Qpart = { [29822] = { 2 } },
            coord = { x = -379.9, y = 2146.6 },
            Range = 30,
            Zone = 371,
            _index = 88
        },
        {
            Treasure = 31400,
            coord = { x = -379.9, y = 2146.6 },
            Range = 2,
            Zone = 371,
            _index = 89
        },
        {
            Qpart = { [29822] = { 1 } },
            coord = { x = -777.9, y = 2356.3 },
            Range = 30,
            Zone = 371,
            _index = 90
        },
        {
            Treasure = 31401,
            coord = { x = -779.4, y = 2360 },
            Range = 2,
            Zone = 371,
            _index = 91
        },
        {
            Waypoint = 29822,
            coord = { x = -503.8, y = 2195.8 },
            Range = 5,
            Zone = 371,
            _index = 92
        },
        {
            Waypoint = 29822,
            coord = { x = -452, y = 2167.8 },
            Range = 5,
            Zone = 371,
            _index = 93
        },
        {
            Done = { 29822 },
            coord = { x = -473.2, y = 2132.6 },
            Zone = 371,
            _index = 94
        },
        {
            PickUp = { 31121 },
            coord = { x = -473.2, y = 2132.6 },
            Zone = 371,
            _index = 95
        },
        {
            Qpart = { [31121] = { 1 } },
            coord = { x = -471.6, y = 2136.3 },
            Range = 1,
            ETA = 75,
            Zone = 371,
            _index = 96
        },
        {
            Done = { 31121 },
            coord = { x = -473.8, y = 2132 },
            Zone = 371,
            _index = 97
        },
        {
            PickUp = { 31132 },
            coord = { x = -473.8, y = 2132 },
            Zone = 371,
            _index = 98
        },
        {
            Waypoint = 31404,
            coord = { x = -289.7, y = 2059.3 },
            Range = 5,
            Zone = 371,
            _index = 99
        },
        {
            Treasure = 31404,
            coord = { x = -188.4, y = 2021.4 },
            Range = 2,
            Zone = 371,
            _index = 100
        },
        {
            Waypoint = 31132,
            coord = { x = -285.5, y = 1950.6 },
            Range = 5,
            Zone = 371,
            _index = 101
        },
        {
            Waypoint = 31132,
            coord = { x = -507.9, y = 2060.8 },
            Range = 5,
            Zone = 371,
            _index = 102
        },
        {
            Done = { 31132 },
            coord = { x = -700.6, y = 2065.5 },
            Zone = 371,
            _index = 103
        },
        {
            PickUp = { 31134 },
            coord = { x = -700.6, y = 2065.5 },
            Zone = 371,
            _index = 104
        },
        {
            Qpart = { [31134] = { 1 } },
            coord = { x = -703.6, y = 2085.1 },
            Range = 1,
            Zone = 371,
            _index = 105
        },
        {
            Qpart = { [31134] = { 2 } },
            coord = { x = -688.2, y = 2080.2 },
            Range = 1,
            Zone = 371,
            _index = 106
        },
        {
            Qpart = { [31134] = { 3 } },
            coord = { x = -684.1, y = 2062.5 },
            Range = 1,
            Zone = 371,
            _index = 107
        },
        {
            Done = { 31134 },
            coord = { x = -701.4, y = 2066.3 },
            Zone = 371,
            _index = 108
        },
        {
            PickUp = { 31152 },
            coord = { x = -701.4, y = 2066.3 },
            RaidIcon = 63290,
            Zone = 371,
            _index = 109
        },
        {
            Waypoint = 31152,
            coord = { x = -731.2, y = 2037.2 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 5,
            RaidIcon = 63290,
            Zone = 371,
            _index = 110
        },
        {
            Waypoint = 31152,
            coord = { x = -739.8, y = 2103.6 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 5,
            RaidIcon = 63290,
            Zone = 371,
            _index = 111
        },
        {
            Waypoint = 31152,
            coord = { x = -647.3, y = 2185.7 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 5,
            RaidIcon = 63290,
            Zone = 371,
            _index = 112
        },
        {
            Waypoint = 31152,
            coord = { x = -599.1, y = 2153.1 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 5,
            RaidIcon = 63290,
            Zone = 371,
            _index = 113
        },
        {
            Qpart = { [31152] = { 1 } },
            coord = { x = -560.5, y = 2133.9 },
            ExtraLineText = "ESCORTS_NPC",
            Range = 5,
            RaidIcon = 63290,
            Zone = 371,
            _index = 114
        },
        {
            Done = { 31152 },
            coord = { x = -560.5, y = 2133.9 },
            Zone = 371,
            _index = 115
        },
        {
            PickUp = { 31167 },
            coord = { x = -560.5, y = 2133.9 },
            Zone = 371,
            _index = 116
        },
        {
            Qpart = { [31167] = { 1 } },
            coord = { x = -558.6, y = 2140.9 },
            Zone = 371,
            _index = 117
        },
        {
            Done = { 31167 },
            coord = { x = -560.8, y = 2134.6 },
            Zone = 371,
            _index = 118
        },
        {
            PickUp = { 29879 },
            coord = { x = -560.8, y = 2134.6 },
            Zone = 371,
            _index = 119
        },
        {
            Waypoint = 29879,
            coord = { x = -509.7, y = 2060.4 },
            Range = 5,
            Zone = 371,
            _index = 120
        },
        {
            Qpart = { [29879] = { 1, 2 } },
            coord = { x = -189.2, y = 2020.7 },
            Range = 60,
            Zone = 371,
            _index = 121
        },
        {
            Done = { 29879 },
            coord = { x = -382.7, y = 1913.9 },
            Zone = 371,
            _index = 122
        },
        {
            PickUp = { 29935 },
            coord = { x = -382.7, y = 1913.9 },
            Zone = 371,
            _index = 123
        },
        {
            PickUp = { 29933 },
            coord = { x = -356, y = 1884.4 },
            Zone = 371,
            _index = 124
        },
        {
            PickUp = { 29924 },
            coord = { x = -360.3, y = 1849.2 },
            Zone = 371,
            _index = 125
        },
        {
            PickUp = { 31241 },
            coord = { x = -514.3, y = 1839.5 },
            Zone = 371,
            _index = 126
        },
        {
            Qpart = { [29924] = { 1 } },
            coord = { x = -878.5, y = 1714.7 },
            Fillers = { [31241] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 127
        },
        {
            Done = { 29924 },
            NoArrow = 1,
            Zone = 371,
            _index = 128
        },
        {
            DropQuest = 31261,
            DroppableQuest = { MobId = 63809, Qid = 31261, Text = "Jack Arrow" },
            coord = { x = -699.3, y = 1717.9 },
            RaidIcon = 63809,
            Zone = 371,
            _index = 129
        },
        {
            Qpart = { [31241] = { 1 } },
            coord = { x = -700.7, y = 1723.2 },
            Range = 60,
            Zone = 371,
            _index = 130
        },
        {
            Qpart = { [29933] = { 1 } },
            coord = { x = -624, y = 1573.4 },
            Range = 30,
            Zone = 371,
            _index = 131
        },
        {
            Done = { 29933, 29935 },
            coord = { x = -501.4, y = 1456.9 },
            Zone = 371,
            _index = 132
        },
        {
            PickUp = { 29936 },
            coord = { x = -501.4, y = 1456.9 },
            Zone = 371,
            _index = 133
        },
        {
            Done = { 31241, 31261 },
            coord = { x = -501.4, y = 1456.9 },
            Zone = 371,
            _index = 134
        },
        {
            Qpart = { [29936] = { 1 } },
            coord = { x = -502.3, y = 1471.4 },
            Button = { ["29936-1"] = 76305 },
            Dontskipvid = 1,
            Zone = 371,
            _index = 135
        },
        {
            Done = { 29936 },
            coord = { x = -523.3, y = 1429.9 },
            Zone = 371,
            _index = 136
        },
        {
            PickUp = { 29941 },
            coord = { x = -523.3, y = 1429.9 },
            Zone = 371,
            _index = 137
        },
        {
            Qpart = { [29941] = { 1 } },
            coord = { x = -527.8, y = 1465.8 },
            GossipOptionIDs = { 40184 },
            Zone = 371,
            _index = 138
        },
        {
            Qpart = { [29941] = { 4 } },
            coord = { x = -501.4, y = 1455.9 },
            GossipOptionIDs = { 40464 },
            Zone = 371,
            _index = 139
        },
        {
            GetFP = 894,
            coord = { x = -490.2, y = 1422.1 },
            Zone = 371,
            _index = 140
        },
        {
            Qpart = { [29941] = { 3 } },
            coord = { x = -438.9, y = 1371.9 },
            GossipOptionIDs = { 40187 },
            Zone = 371,
            _index = 141
        },
        {
            Qpart = { [29941] = { 2 } },
            coord = { x = -449.4, y = 1295.2 },
            GossipOptionIDs = { 40186 },
            Zone = 371,
            _index = 142
        },
        {
            Done = { 29941 },
            coord = { x = -523.2, y = 1428.4 },
            Zone = 371,
            _index = 143
        },
        {
            PickUp = { 29937 },
            coord = { x = -523.2, y = 1428.4 },
            Zone = 371,
            _index = 144
        },
        {
            PickUp = { 31239 },
            coord = { x = -502.5, y = 1456.3 },
            Zone = 371,
            _index = 145
        },
        {
            Qpart = { [29937] = { 1 } },
            coord = { x = -662.2, y = 1340.1 },
            Range = 100,
            Zone = 371,
            _index = 146
        },
        {
            Qpart = { [31239] = { 1 } },
            coord = { x = -705.4, y = 1451.5 },
            Range = 40,
            Zone = 371,
            _index = 147
        },
        {
            Done = { 31239 },
            coord = { x = -501.5, y = 1456.6 },
            Zone = 371,
            _index = 148
        },
        {
            Done = { 29937 },
            coord = { x = -448.7, y = 1288.5 },
            Zone = 371,
            _index = 149
        },
        {
            PickUp = { 29939 },
            coord = { x = -448.7, y = 1288.5 },
            Zone = 371,
            _index = 150
        },
        {
            PickUp = { 29942 },
            coord = { x = -435.9, y = 1287.4 },
            Zone = 371,
            _index = 151
        },
        {
            Qpart = { [29939] = { 1 }, [29942] = { 1 } },
            coord = { x = -414.6, y = 1074 },
            Button = { ["29939-1"] = 76262 },
            Range = 50,
            Zone = 371,
            _index = 152
        },
        {
            Done = { 29942 },
            coord = { x = -435.5, y = 1286.8 },
            Zone = 371,
            _index = 153
        },
        {
            Done = { 29939 },
            coord = { x = -449.7, y = 1288.3 },
            Zone = 371,
            _index = 154
        },
        {
            PickUp = { 29971 },
            coord = { x = -449.7, y = 1288.3 },
            Zone = 371,
            _index = 155
        },
        {
            Done = { 29971 },
            coord = { x = -547.6, y = 1447.4 },
            Zone = 371,
            _index = 156
        },
        {
            PickUp = { 29730 },
            coord = { x = -545.4, y = 1443.8 },
            Zone = 371,
            _index = 157
        },
        {
            Qpart = { [29730] = { 1 } },
            coord = { x = -1222.7, y = 1539.3 },
            Range = 5,
            Zone = 371,
            _index = 158
        },
        {
            Qpart = { [29730] = { 2 } },
            coord = { x = -1264.8, y = 1510.7 },
            Range = 5,
            Zone = 371,
            _index = 159
        },
        {
            Qpart = { [29730] = { 3 } },
            coord = { x = -1285.3, y = 1501.5 },
            GossipOptionIDs = { 40114 },
            Zone = 371,
            _index = 160
        },
        {
            Done = { 29730 },
            coord = { x = -545.5, y = 1444.2 },
            Zone = 371,
            _index = 161
        },
        {
            PickUp = { 29731 },
            coord = { x = -548.5, y = 1443.2 },
            Zone = 371,
            _index = 162
        },
        {
            Qpart = { [29731] = { 1 } },
            coord = { x = -1943, y = 846.5 },
            Range = 30,
            Zone = 371,
            _index = 163
        },
        {
            Done = { 29731 },
            coord = { x = -546.4, y = 1442.1 },
            Zone = 371,
            _index = 164
        },
        {
            PickUp = { 29823 },
            coord = { x = -546.4, y = 1442.1 },
            Zone = 371,
            _index = 165
        },
        {
            Qpart = { [29823] = { 1 } },
            coord = { x = -2026.9, y = 368.9 },
            GossipOptionIDs = { 39795 },
            Range = 5,
            Zone = 371,
            _index = 166
        },
        {
            Done = { 29823 },
            coord = { x = -545.5, y = 1444.4 },
            Zone = 371,
            _index = 167
        },
        {
            PickUp = { 29824 },
            coord = { x = -547.6, y = 1447.1 },
            Zone = 371,
            _index = 168
        },
        {
            Qpart = { [29824] = { 1 } },
            coord = { x = -2917, y = -171 },
            Range = 2,
            Zone = 371,
            _index = 169
        },
        {
            Done = { 29824 },
            coord = { x = -547.6, y = 1445.9 },
            Zone = 371,
            _index = 170
        },
        {
            PickUp = { 29943 },
            coord = { x = -548.4, y = 1440.7 },
            Zone = 371,
            _index = 171
        },
        {
            PickUp = { 29968 },
            coord = { x = -449.4, y = 1289.1 },
            Zone = 371,
            _index = 172
        },
        {
            Qpart = { [29943] = { 1 }, [29968] = { 1 } },
            coord = { x = -652, y = 1219.8 },
            Range = 69,
            Zone = 371,
            _index = 173
        },
        {
            Done = { 29943 },
            NoArrow = 1,
            Zone = 371,
            _index = 174
        },
        {
            PickUp = { 29966 },
            NoArrow = 1,
            Zone = 371,
            _index = 175
        },
        {
            Qpart = { [29966] = { 1 } },
            coord = { x = -611.5, y = 1138 },
            Button = { ["29966-1"] = 76336 },
            Range = 30,
            Zone = 371,
            _index = 176
        },
        {
            Waypoint = 29966,
            coord = { x = -631.9, y = 1162.6 },
            Range = 5,
            Zone = 371,
            _index = 177
        },
        {
            Waypoint = 29966,
            coord = { x = -547.8, y = 1267.3 },
            Range = 5,
            Zone = 371,
            _index = 178
        },
        {
            Waypoint = 29966,
            coord = { x = -546.5, y = 1284.4 },
            Range = 5,
            Zone = 371,
            _index = 179
        },
        {
            Done = { 29966 },
            coord = { x = -549.3, y = 1438.4 },
            Zone = 371,
            _index = 180
        },
        {
            Done = { 29968 },
            coord = { x = -452.3, y = 1290.2 },
            Zone = 371,
            _index = 181
        },
        {
            PickUp = { 29967 },
            coord = { x = -449.5, y = 1288.9 },
            Zone = 371,
            _index = 182
        },
        {
            Qpart = { [29967] = { 1 } },
            coord = { x = -567.1, y = 1363 },
            GossipOptionIDs = { 40650 },
            Range = 2,
            RaidIcon = 56525,
            Zone = 371,
            _index = 183
        },
        {
            Done = { 29967 },
            coord = { x = -571.6, y = 1367.4 },
            GossipOptionIDs = { 40650 },
            Zone = 371,
            _index = 184
        },
        {
            PickUp = { 30015 },
            coord = { x = -550.5, y = 1440 },
            Zone = 371,
            _index = 185
        },
        {
            UseFlightPath = 30015,
            NodeID = 895,
            coord = { x = -490, y = 1422.1 },
            GossipOptionIDs = { 34466 },
            ETA = 60,
            Zone = 371,
            _index = 186
        },
        {
            GetFP = 895,
            coord = { x = -1834.4, y = 1500.5 },
            Zone = 371,
            _index = 187
        },
        {
            Done = { 30015 },
            coord = { x = -1817.6, y = 1504.7 },
            Zone = 371,
            _index = 188
        },
        {
            PickUp = { 31230 },
            coord = { x = -1841, y = 1503.4 },
            Zone = 371,
            _index = 189
        },
        {
            Qpart = { [31230] = { 3 } },
            coord = { x = -1808.6, y = 1520.8 },
            Range = 5,
            Zone = 371,
            _index = 190
        },
        {
            Qpart = { [31230] = { 2 } },
            coord = { x = -1740.3, y = 1618.1 },
            Range = 2,
            Zone = 371,
            _index = 191
        },
        {
            SetHS = 31230,
            coord = { x = -1741.1, y = 1618.1 },
            Zone = 371,
            _index = 192
        },
        {
            PickUp = { 32018 },
            coord = { x = -1744.4, y = 1606.7 },
            DontHaveAura = 424143,
            Zone = 371,
            _index = 193
        },
        {
            Qpart = { [31230] = { 1 } },
            coord = { x = -1934, y = 1581.3 },
            Range = 2,
            Zone = 371,
            _index = 194
        },
        {
            Done = { 31230 },
            coord = { x = -1842, y = 1505.1 },
            Zone = 371,
            _index = 195
        },
        {
            PickUp = { 29716, 29717 },
            coord = { x = -1807, y = 1505 },
            Zone = 371,
            _index = 196
        },
        {
            PickUp = { 29865 },
            coord = { x = -1793, y = 1520.2 },
            Zone = 371,
            _index = 197
        },
        {
            PickUp = { 29866 },
            coord = { x = -1805, y = 1543.2 },
            Zone = 371,
            _index = 198
        },
        {
            Qpart = { [29865] = { 1 }, [29866] = { 1 } },
            coord = { x = -1598.7, y = 1371 },
            Range = 69,
            Zone = 371,
            _index = 199
        },
        {
            Waypoint = 29716,
            coord = { x = -1389.1, y = 1382.9 },
            Range = 5,
            Zone = 371,
            _index = 200
        },
        {
            Qpart = { [29716] = { 1 }, [29717] = { 1 } },
            coord = { x = -1166.2, y = 1489 },
            GossipOptionIDs = { 39304 },
            Range = 30,
            Zone = 371,
            _index = 201
        },
        {
            Done = { 29716, 29717 },
            NoArrow = 1,
            Zone = 371,
            _index = 202
        },
        {
            PickUp = { 29723 },
            NoArrow = 1,
            Zone = 371,
            _index = 203
        },
        {
            Waypoint = 29865,
            coord = { x = -1294.3, y = 1500.8 },
            GossipOptionIDs = { 39810 },
            Range = 2,
            Zone = 371,
            _index = 204
        },
        {
            Qpart = { [29723] = { 1 } },
            coord = { x = -1321.8, y = 1497.5 },
            GossipOptionIDs = { 39810 },
            Range = 5,
            Zone = 371,
            _index = 205
        },
        {
            Waypoint = 29865,
            coord = { x = -1364.2, y = 1393.3 },
            Range = 5,
            Zone = 371,
            _index = 206
        },
        {
            Waypoint = 29865,
            coord = { x = -1526.6, y = 1376.9 },
            Range = 5,
            Zone = 371,
            _index = 207
        },
        {
            Waypoint = 29865,
            coord = { x = -1803.2, y = 1477.8 },
            Range = 5,
            Zone = 371,
            _index = 208
        },
        {
            Done = { 29865 },
            coord = { x = -1793.6, y = 1519.8 },
            Zone = 371,
            _index = 209
        },
        {
            Done = { 29866 },
            coord = { x = -1803.3, y = 1540.7 },
            Zone = 371,
            _index = 210
        },
        {
            Done = { 29723 },
            coord = { x = -1792.2, y = 1593.2 },
            Zone = 371,
            _index = 211
        },
        {
            PickUp = { 29993 },
            coord = { x = -1822.7, y = 1513.2 },
            Zone = 371,
            _index = 212
        },
        {
            PickUp = { 29925 },
            coord = { x = -1841.3, y = 1503.4 },
            Zone = 371,
            _index = 213
        },
        {
            PickUp = { 29576 },
            coord = { x = -1922.4, y = 1508.5 },
            Zone = 371,
            _index = 214
        },
        {
            PickUp = { 29617 },
            coord = { x = -2013.1, y = 1519.6 },
            Zone = 371,
            _index = 215
        },
        {
            Waypoint = 29993,
            coord = { x = -2133.9, y = 1534.5 },
            Range = 5,
            Zone = 371,
            _index = 216
        },
        {
            Waypoint = 29993,
            coord = { x = -2348.7, y = 1460.9 },
            Range = 5,
            Zone = 371,
            _index = 217
        },
        {
            PickUp = { 29881 },
            coord = { x = -2382.6, y = 1541.7 },
            Zone = 371,
            _index = 218
        },
        {
            Done = { 29993 },
            coord = { x = -2365.7, y = 1598.2 },
            Zone = 371,
            _index = 219
        },
        {
            PickUp = { 29995 },
            coord = { x = -2365.7, y = 1598.2 },
            Zone = 371,
            _index = 220
        },
        {
            PickUp = { 29882 },
            coord = { x = -2409.5, y = 1544.7 },
            Zone = 371,
            _index = 221
        },
        {
            GetFP = 967,
            coord = { x = -2529.3, y = 1602.4 },
            Zone = 371,
            _index = 222
        },
        {
            Qpart = { [29881] = { 1 }, [29882] = { 1 } },
            coord = { x = -2261.6, y = 1594.3 },
            ExtraLineText = "LOOK_FOR_RED_FLOWERS_BENEATH_TREES",
            Range = 69,
            Zone = 371,
            _index = 223
        },
        {
            Done = { 29882 },
            coord = { x = -2411.5, y = 1545.7 },
            Zone = 371,
            _index = 224
        },
        {
            Done = { 29881 },
            coord = { x = -2381.2, y = 1543.3 },
            Zone = 371,
            _index = 225
        },
        {
            Waypoint = 29995,
            coord = { x = -2281.5, y = 1740.2 },
            Range = 5,
            Zone = 371,
            _index = 226
        },
        {
            Waypoint = 29995,
            coord = { x = -2259.6, y = 1792.3 },
            Range = 5,
            Zone = 371,
            _index = 227
        },
        {
            Done = { 29995 },
            coord = { x = -2218.6, y = 1876.6 },
            Zone = 371,
            _index = 228
        },
        {
            PickUp = { 29920 },
            coord = { x = -2218.6, y = 1876.6 },
            Zone = 371,
            _index = 229
        },
        {
            Qpart = { [29920] = { 2 } },
            coord = { x = -2324.7, y = 1862.3 },
            GossipOptionIDs = { 40636 },
            Zone = 371,
            _index = 230
        },
        {
            Qpart = { [29920] = { 3 } },
            coord = { x = -2289.9, y = 1942.1 },
            GossipOptionIDs = { 40637 },
            Zone = 371,
            _index = 231
        },
        {
            Qpart = { [29920] = { 1 } },
            coord = { x = -2217.2, y = 1996 },
            GossipOptionIDs = { 40541 },
            Zone = 371,
            _index = 232
        },
        {
            Done = { 29920 },
            coord = { x = -2220.8, y = 1877 },
            Zone = 371,
            _index = 233
        },
        {
            Waypoint = 29925,
            coord = { x = -2092.3, y = 2317.3 },
            Range = 5,
            Zone = 371,
            _index = 234
        },
        {
            Done = { 29925 },
            coord = { x = -2103.2, y = 2391.2 },
            Zone = 371,
            _index = 235
        },
        {
            PickUp = { 29928 },
            coord = { x = -2104.5, y = 2393.6 },
            Zone = 371,
            _index = 236
        },
        {
            GetFP = 970,
            coord = { x = -2098.2, y = 2401.4 },
            Zone = 371,
            _index = 237
        },
        {
            Qpart = { [29928] = { 1 } },
            coord = { x = -1923.3, y = 2160.9 },
            ExtraLineText = "KILL_MOD_TO_DROP_JADE",
            Range = 30,
            Zone = 371,
            _index = 238
        },
        {
            Done = { 29928 },
            coord = { x = -2106.4, y = 2393 },
            Zone = 371,
            _index = 239
        },
        {
            PickUp = { 29926, 29927 },
            coord = { x = -2106.4, y = 2393 },
            Zone = 371,
            _index = 240
        },
        {
            Waypoint = 29927,
            coord = { x = -1768.1, y = 2295.6 },
            Range = 5,
            Zone = 371,
            _index = 241
        },
        {
            Qpart = { [29927] = { 1 } },
            coord = { x = -1730.2, y = 2311 },
            Range = 30,
            Zone = 372,
            _index = 242
        },
        {
            Done = { 29927 },
            coord = { x = -1721.1, y = 2301.1 },
            Zone = 372,
            _index = 243
        },
        {
            PickUp = { 29929 },
            coord = { x = -1721.1, y = 2301.1 },
            Zone = 372,
            _index = 244
        },
        {
            Qpart = { [29926] = { 1, 2 }, [29929] = { 1 } },
            coord = { x = -1709.2, y = 2270 },
            Range = 45,
            Zone = 372,
            _index = 245
        },
        {
            Waypoint = 29929,
            coord = { x = -1688.1, y = 2279 },
            Range = 5,
            Zone = 373,
            _index = 246
        },
        {
            Waypoint = 29929,
            coord = { x = -1675.5, y = 2288.4 },
            Range = 5,
            Zone = 373,
            _index = 247
        },
        {
            Waypoint = 29929,
            coord = { x = -1688.7, y = 2302.2 },
            Range = 5,
            Zone = 372,
            _index = 248
        },
        {
            Waypoint = 29929,
            coord = { x = -1705.4, y = 2290.7 },
            Range = 5,
            Zone = 372,
            _index = 249
        },
        {
            Waypoint = 29929,
            coord = { x = -1750.3, y = 2310 },
            Range = 5,
            Zone = 371,
            _index = 250
        },
        {
            Done = { 29929 },
            coord = { x = -1780.5, y = 2285 },
            Zone = 371,
            _index = 251
        },
        {
            PickUp = { 29930 },
            coord = { x = -1780.5, y = 2285 },
            Zone = 371,
            _index = 252
        },
        {
            Qpart = { [29930] = { 1 } },
            coord = { x = -1780.5, y = 2285 },
            ExtraLineText = "USE_CART",
            Range = 2,
            Zone = 371,
            _index = 253
        },
        {
            Done = { 29926, 29930 },
            coord = { x = -2106, y = 2393.2 },
            Zone = 371,
            _index = 254
        },
        {
            PickUp = { 29931 },
            coord = { x = -2106, y = 2393.2 },
            Zone = 371,
            _index = 255
        },
        {
            PickUp = { 29745 },
            coord = { x = -1949, y = 2488.5 },
            Zone = 371,
            _index = 256
        },
        {
            Qpart = { [29745] = { 2 } },
            coord = { x = -1976.7, y = 2663.9 },
            Fillers = { [29745] = { 1 } },
            Range = 2,
            Zone = 371,
            _index = 257
        },
        {
            Qpart = { [29745] = { 1 } },
            coord = { x = -1972.9, y = 2640.6 },
            Range = 30,
            Zone = 371,
            _index = 258
        },
        {
            Done = { 29745 },
            NoArrow = 1,
            Zone = 371,
            _index = 259
        },
        {
            PickUp = { 29747 },
            NoArrow = 1,
            Zone = 371,
            _index = 260
        },
        {
            PickUp = { 29748 },
            coord = { x = -1939.8, y = 2694.1 },
            Zone = 371,
            _index = 261
        },
        {
            Qpart = { [29747] = { 1 }, [29748] = { 1 } },
            coord = { x = -1943.9, y = 2700.7 },
            Range = 60,
            Zone = 371,
            _index = 262
        },
        {
            Done = { 29747, 29748 },
            NoArrow = 1,
            Zone = 371,
            _index = 263
        },
        {
            PickUp = { 29749 },
            NoArrow = 1,
            Zone = 371,
            _index = 264
        },
        {
            Qpart = { [29749] = { 1 } },
            coord = { x = -1636.8, y = 2956.1 },
            Zone = 371,
            _index = 265
        },
        {
            Qpart = { [29749] = { 2 } },
            coord = { x = -1645.9, y = 2931.5 },
            ExtraLineText = "KILL_ANCIENT_SPIRITS_TO_INTERRUPT_RITUAL",
            Range = 5,
            Zone = 371,
            _index = 266
        },
        {
            Done = { 29749 },
            coord = { x = -1637, y = 2952.6 },
            Zone = 371,
            _index = 267
        },
        {
            PickUp = { 29751, 29750, 29752 },
            coord = { x = -1637, y = 2952.6 },
            Zone = 371,
            _index = 268
        },
        {
            Qpart = { [29751] = { 1 } },
            coord = { x = -1522, y = 2918.5 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 269
        },
        {
            Qpart = { [29751] = { 2 } },
            coord = { x = -1454.6, y = 2985.3 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 270
        },
        {
            Qpart = { [29751] = { 3 } },
            coord = { x = -1499.2, y = 2857.2 },
            Fillers = { [29750] = { 1 }, [29752] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 271
        },
        {
            Waypoint = 29750,
            coord = { x = -1499.1, y = 2839.2 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 371,
            _index = 272
        },
        {
            Qpart = { [29750] = { 1 }, [29752] = { 1 } },
            coord = { x = -1466.5, y = 2957 },
            Range = 60,
            Zone = 371,
            _index = 273
        },
        {
            Done = { 29750, 29751, 29752 },
            coord = { x = -1637.2, y = 2953 },
            Zone = 371,
            _index = 274
        },
        {
            PickUp = { 29753, 29756 },
            coord = { x = -1637.2, y = 2953 },
            Zone = 371,
            _index = 275
        },
        {
            Qpart = { [29753] = { 1 }, [29756] = { 1 } },
            coord = { x = -1265.3, y = 3140.3 },
            Button = { ["29753-1"] = 74808 },
            ExtraLineText = "THROW_JAR_TO_RELEASE_SPIRIT",
            Range = 30,
            Zone = 371,
            _index = 276
        },
        {
            Done = { 29753, 29756 },
            coord = { x = -1637, y = 2952.8 },
            Zone = 371,
            _index = 277
        },
        {
            PickUp = { 29754 },
            coord = { x = -1637, y = 2952.8 },
            Zone = 371,
            _index = 278
        },
        {
            Qpart = { [29754] = { 1 } },
            coord = { x = -1606.8, y = 3067.2 },
            Range = 30,
            Zone = 371,
            _index = 279
        },
        {
            Done = { 29754 },
            coord = { x = -1606.8, y = 3067.2 },
            Zone = 371,
            _index = 280
        },
        {
            PickUp = { 29755 },
            coord = { x = -1606.8, y = 3067.2 },
            Zone = 371,
            _index = 281
        },
        {
            Qpart = { [29755] = { 1 } },
            coord = { x = -1517.2, y = 3167.1 },
            ExtraLineText = "THERE_ARE_2_PHASES",
            ExtraLineText2 = "KILL_COLOSSUS",
            ExtraLineText3 = "THEN_KILL_SHAN_JITONG",
            Range = 30,
            Zone = 371,
            _index = 282
        },
        {
            Done = { 29755 },
            coord = { x = -1610.7, y = 3069.2 },
            Zone = 371,
            _index = 283
        },
        {
            Waypoint = 29617,
            coord = { x = -1179.6, y = 3038.9 },
            Range = 5,
            Zone = 371,
            _index = 284
        },
        {
            Waypoint = 29617,
            coord = { x = -1153.6, y = 2670.5 },
            Range = 5,
            Zone = 371,
            _index = 285
        },
        {
            Waypoint = 29617,
            coord = { x = -1220.7, y = 2519.2 },
            Range = 5,
            Zone = 371,
            _index = 286
        },
        {
            Waypoint = 29617,
            coord = { x = -1538.2, y = 2487.6 },
            Range = 5,
            Zone = 371,
            _index = 287
        },
        {
            GetFP = 971,
            coord = { x = -1588.1, y = 2507.6 },
            Zone = 371,
            _index = 288
        },
        {
            Done = { 29617 },
            coord = { x = -1689.3, y = 2489.5 },
            Zone = 371,
            _index = 289
        },
        {
            PickUp = { 29618 },
            coord = { x = -1689.3, y = 2489.5 },
            Zone = 371,
            _index = 290
        },
        {
            Waypoint = 29618,
            coord = { x = -1737.5, y = 2496.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 291
        },
        {
            Waypoint = 29618,
            coord = { x = -1736.9, y = 2474.5 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 292
        },
        {
            Waypoint = 29618,
            coord = { x = -1713.8, y = 2474 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 293
        },
        {
            Waypoint = 29618,
            coord = { x = -1713.9, y = 2496.9 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 294
        },
        {
            Waypoint = 29618,
            coord = { x = -1736.9, y = 2494.9 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 295
        },
        {
            Waypoint = 29618,
            coord = { x = -1733.6, y = 2476 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 296
        },
        {
            Done = { 29618 },
            coord = { x = -1706.8, y = 2485.4 },
            ExtraLineText = "UPSTAIRS",
            Zone = 371,
            _index = 297
        },
        {
            PickUp = { 29619 },
            coord = { x = -1689.9, y = 2490.2 },
            ExtraLineText = "JUMP_OFF",
            Zone = 371,
            _index = 298
        },
        {
            Qpart = { [29619] = { 1 } },
            coord = { x = -1747.5, y = 2370.1 },
            ExtraLineText = "LOOT_FROM_GROUND_OR_KILL_MOBS",
            Range = 10,
            Zone = 371,
            _index = 299
        },
        {
            Waypoint = 29619,
            coord = { x = -1627, y = 2479.8 },
            Range = 5,
            Zone = 371,
            _index = 300
        },
        {
            Done = { 29619 },
            coord = { x = -1690.3, y = 2489.6 },
            Zone = 371,
            _index = 301
        },
        {
            PickUp = { 29620 },
            coord = { x = -1690.3, y = 2489.6 },
            Zone = 371,
            _index = 302
        },
        {
            Qpart = { [29620] = { 1 } },
            coord = { x = -1532.3, y = 2573.7 },
            GossipOptionIDs = { 39493, 40364 },
            Zone = 371,
            _index = 303
        },
        {
            Done = { 29620 },
            coord = { x = -1532.3, y = 2573.7 },
            Zone = 371,
            _index = 304
        },
        {
            PickUp = { 29622, 29626 },
            coord = { x = -1559.4, y = 2552.4 },
            Zone = 371,
            _index = 305
        },
        {
            PickUp = { 29632 },
            coord = { x = -1567.2, y = 2499.9 },
            Zone = 371,
            _index = 306
        },
        {
            Qpart = { [29632] = { 1 } },
            coord = { x = -1566.6, y = 2483.1 },
            GossipOptionIDs = { 40241 },
            Range = 15,
            Zone = 371,
            _index = 307
        },
        {
            Done = { 29632 },
            coord = { x = -1566.2, y = 2498.8 },
            Zone = 371,
            _index = 308
        },
        {
            PickUp = { 29633, 29634 },
            coord = { x = -1566.2, y = 2498.8 },
            Zone = 371,
            _index = 309
        },
        {
            Qpart = { [29633] = { 1 } },
            coord = { x = -1554.5, y = 2442.2 },
            GossipOptionIDs = { 40594 },
            Zone = 371,
            _index = 310
        },
        {
            Done = { 29626 },
            coord = { x = -1453, y = 2548.5 },
            Zone = 371,
            _index = 311
        },
        {
            PickUp = { 29627 },
            coord = { x = -1453, y = 2548.5 },
            Zone = 371,
            _index = 312
        },
        {
            Qpart = { [29627] = { 2 } },
            coord = { x = -1439.2, y = 2527.4 },
            Fillers = { [29627] = { 1 } },
            BuyMerchant = { { itemID = 72954, quantity = 1, questID = 29627 } },
            Zone = 371,
            _index = 313
        },
        {
            Qpart = { [29627] = { 3 } },
            coord = { x = -1465, y = 2504.5 },
            Fillers = { [29627] = { 1 } },
            BuyMerchant = { { itemID = 72979, quantity = 3, questID = 29627 } },
            Zone = 371,
            _index = 314
        },
        {
            Qpart = { [29627] = { 1 } },
            coord = { x = -1451.3, y = 2507.9 },
            Range = 60,
            Zone = 371,
            _index = 315
        },
        {
            Done = { 29627 },
            coord = { x = -1455.2, y = 2549.1 },
            Zone = 371,
            _index = 316
        },
        {
            PickUp = { 29628, 29629, 29630 },
            coord = { x = -1455.2, y = 2549.1 },
            Zone = 371,
            _index = 317
        },
        {
            PickUp = { 29631 },
            coord = { x = -1202, y = 2546.4 },
            Zone = 371,
            _index = 318
        },
        {
            Qpart = { [29629] = { 1 }, [29631] = { 1 } },
            coord = { x = -949, y = 2684.6 },
            Range = 69,
            Zone = 371,
            _index = 319
        },
        {
            Qpart = { [29628] = { 1 } },
            coord = { x = -1184.6, y = 2833.3 },
            Fillers = { [29630] = { 1 } },
            Range = 30,
            Zone = 371,
            _index = 320
        },
        {
            Qpart = { [29630] = { 1 } },
            coord = { x = -1190.5, y = 2615.6 },
            Range = 45,
            Zone = 371,
            _index = 321
        },
        {
            Done = { 29631 },
            coord = { x = -1203.7, y = 2547.1 },
            Zone = 371,
            _index = 322
        },
        {
            Qpart = { [29628] = { 2 } },
            coord = { x = -1453.5, y = 2548.7 },
            Range = 30,
            Zone = 371,
            _index = 323
        },
        {
            Done = { 29628, 29629, 29630 },
            coord = { x = -1453.5, y = 2548.7 },
            Zone = 371,
            _index = 324
        },
        {
            Done = { 29622 },
            coord = { x = -1454.1, y = 2334.2 },
            Zone = 371,
            _index = 325
        },
        {
            PickUp = { 29623 },
            coord = { x = -1454.1, y = 2334.2 },
            Zone = 371,
            _index = 326
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
            _index = 327
        },
        {
            Done = { 29623 },
            coord = { x = -1454.2, y = 2332.4 },
            Zone = 371,
            _index = 328
        },
        {
            PickUp = { 29624 },
            coord = { x = -1454.2, y = 2332.4 },
            Zone = 371,
            _index = 329
        },
        {
            Qpart = { [29624] = { 1 } },
            coord = { x = -1417.3, y = 2396.8 },
            ExtraLineText = "HIT_BAG_ACCORDING_TO_YELLOW_TEXT_IN_MIDDLE_SCREEN",
            Range = 30,
            Zone = 371,
            _index = 330
        },
        {
            Done = { 29624 },
            coord = { x = -1454.4, y = 2333.6 },
            Zone = 371,
            _index = 331
        },
        {
            Waypoint = 29633,
            coord = { x = -1392.2, y = 2488.5 },
            Range = 5,
            Zone = 371,
            _index = 332
        },
        {
            Done = { 29633 },
            coord = { x = -1566.6, y = 2498.1 },
            Zone = 371,
            _index = 333
        },
        {
            Qpart = { [29634] = { 1 } },
            coord = { x = -1660.1, y = 2532.9 },
            GossipOptionIDs = { 40595 },
            Zone = 371,
            _index = 334
        },
        {
            Done = { 29634 },
            coord = { x = -1567.4, y = 2500.3 },
            Zone = 371,
            _index = 335
        },
        {
            PickUp = { 29635 },
            coord = { x = -1567.4, y = 2500.3 },
            Zone = 371,
            _index = 336
        },
        {
            Qpart = { [29635] = { 1 } },
            coord = { x = -1560.1, y = 2552.1 },
            GossipOptionIDs = { 40337 },
            Zone = 371,
            _index = 337
        },
        {
            Done = { 29635 },
            coord = { x = -1567.7, y = 2499.1 },
            Zone = 371,
            _index = 338
        },
        {
            PickUp = { 29636 },
            coord = { x = -1567.7, y = 2499.1 },
            Zone = 371,
            _index = 339
        },
        {
            Done = { 29636 },
            coord = { x = -1268.9, y = 2532.6 },
            Zone = 371,
            _index = 340
        },
        {
            PickUp = { 29637 },
            coord = { x = -1268.9, y = 2532.6 },
            Zone = 371,
            _index = 341
        },
        {
            Qpart = { [29637] = { 1 } },
            coord = { x = -1270.8, y = 2573.8 },
            Button = { ["29637-1"] = 73369 },
            ExtraLineText = "USE_FIREWORKS_TO_START_COMBAT_AND_SURVIVE_2_MINUTES",
            Range = 5,
            Zone = 371,
            _index = 342
        },
        {
            Done = { 29637 },
            coord = { x = -1269.2, y = 2532.1 },
            Zone = 371,
            _index = 343
        },
        {
            PickUp = { 29647 },
            coord = { x = -1269.2, y = 2532.1 },
            Zone = 371,
            _index = 344
        },
        {
            Waypoint = 29647,
            coord = { x = -1530.2, y = 2487.8 },
            Range = 5,
            Zone = 371,
            _index = 345
        },
        {
            Waypoint = 29647,
            coord = { x = -1573.7, y = 2524.4 },
            Range = 5,
            Zone = 371,
            _index = 346
        },
        {
            Done = { 29647 },
            coord = { x = -1533.2, y = 2572.5 },
            Zone = 371,
            _index = 347
        },
        {
            UseFlightPath = 29576,
            NodeID = 895,
            coord = { x = -1589.8, y = 2508.5 },
            ETA = 39,
            Zone = 371,
            _index = 348
        },
        {
            Waypoint = 29576,
            coord = { x = -1803.9, y = 1478.5 },
            Range = 5,
            Zone = 371,
            _index = 349
        },
        {
            Waypoint = 29576,
            coord = { x = -1774.4, y = 1292 },
            Range = 5,
            Zone = 371,
            _index = 350
        },
        {
            Waypoint = 29576,
            coord = { x = -1756.1, y = 991.3 },
            Range = 5,
            Zone = 371,
            _index = 351
        },
        {
            Waypoint = 29576,
            coord = { x = -1611.4, y = 844.2 },
            Range = 5,
            Zone = 371,
            _index = 352
        },
        {
            Waypoint = 29576,
            coord = { x = -1488.4, y = 843 },
            Range = 5,
            Zone = 371,
            _index = 353
        },
        {
            Waypoint = 29576,
            coord = { x = -1463.3, y = 764.7 },
            Range = 5,
            Zone = 371,
            _index = 354
        },
        {
            Waypoint = 29576,
            coord = { x = -1488.2, y = 551.8 },
            Range = 5,
            Zone = 371,
            _index = 355
        },
        {
            Waypoint = 29576,
            coord = { x = -1449.6, y = 437.9 },
            Range = 5,
            Zone = 371,
            _index = 356
        },
        {
            Waypoint = 29576,
            coord = { x = -1563.2, y = 276.7 },
            Range = 5,
            Zone = 371,
            _index = 357
        },
        {
            Done = { 29576 },
            coord = { x = -1587.7, y = 118.5 },
            Zone = 371,
            _index = 358
        },
        {
            PickUp = { 29578, 29579 },
            coord = { x = -1587.7, y = 118.5 },
            Zone = 371,
            _index = 359
        },
        {
            PickUp = { 29580, 29585 },
            coord = { x = -1570.5, y = 126.8 },
            Zone = 371,
            _index = 360
        },
        {
            Qpart = { [29578] = { 1, 2 }, [29579] = { 1 }, [29580] = { 1 }, [29585] = { 1 } },
            coord = { x = -1621.6, y = 156.5 },
            Button = { ["29585-1"] = 72578 },
            GossipOptionIDs = { 39167 },
            Range = 69,
            Zone = 371,
            _index = 361
        },
        {
            Done = { 29578, 29579 },
            coord = { x = -1586.7, y = 118.9 },
            Zone = 371,
            _index = 362
        },
        {
            Done = { 29585, 29580 },
            coord = { x = -1568.3, y = 116.5 },
            Zone = 371,
            _index = 363
        },
        {
            PickUp = { 29586 },
            coord = { x = -1568.3, y = 116.5 },
            Zone = 371,
            _index = 364
        },
        {
            Qpart = { [29586] = { 1 } },
            coord = { x = -1390.6, y = 201.7 },
            Range = 5,
            Zone = 371,
            _index = 365
        },
        {
            Done = { 29586 },
            coord = { x = -1409.9, y = 210 },
            Zone = 371,
            _index = 366
        },
        {
            PickUp = { 29587, 29670 },
            coord = { x = -1409.9, y = 210 },
            Zone = 371,
            _index = 367
        },
        {
            Qpart = { [29670] = { 1 } },
            coord = { x = -1192.1, y = 98 },
            Fillers = { [29587] = { 1 } },
            Range = 30,
            Zone = 371,
            _index = 368
        },
        {
            Qpart = { [29587] = { 1 } },
            coord = { x = -1306.2, y = 158.7 },
            Range = 30,
            Zone = 371,
            _index = 369
        },
        {
            Done = { 29587, 29670 },
            coord = { x = -1409.7, y = 210.7 },
            Zone = 371,
            _index = 370
        },
        {
            Waypoint = 29931,
            coord = { x = -1448.6, y = 436 },
            Range = 5,
            Zone = 371,
            _index = 371
        },
        {
            Waypoint = 29931,
            coord = { x = -1512.5, y = 656.4 },
            Range = 5,
            Zone = 371,
            _index = 372
        },
        {
            Waypoint = 29931,
            coord = { x = -1497.4, y = 844.6 },
            Range = 5,
            Zone = 371,
            _index = 373
        },
        {
            Waypoint = 29931,
            coord = { x = -1550.9, y = 853.1 },
            Range = 5,
            Zone = 371,
            _index = 374
        },
        {
            Done = { 29931 },
            coord = { x = -1921.9, y = 796.5 },
            Zone = 371,
            _index = 375
        },
        {
            PickUp = { 30495 },
            coord = { x = -1921.9, y = 796.5 },
            Zone = 371,
            _index = 376
        },
        {
            Qpart = { [30495] = { 3 } },
            coord = { x = -1912.8, y = 858.4 },
            GossipOptionIDs = { 39632 },
            Zone = 371,
            _index = 377
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
            _index = 378
        },
        {
            Qpart = { [30495] = { 4 } },
            coord = { x = -1870.1, y = 828.7 },
            GossipOptionIDs = { 39805 },
            Zone = 371,
            _index = 379
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
            _index = 380
        },
        {
            Qpart = { [30495] = { 2 } },
            coord = { x = -1826.2, y = 842.7 },
            GossipOptionIDs = { 40697 },
            Zone = 371,
            _index = 381
        },
        {
            Qpart = { [30495] = { 1 } },
            coord = { x = -1784.8, y = 775.3 },
            GossipOptionIDs = { 39183 },
            Zone = 371,
            _index = 382
        },
        {
            Done = { 30495 },
            coord = { x = -1921.9, y = 797.2 },
            Zone = 371,
            _index = 383
        },
        {
            PickUp = { 29932 },
            coord = { x = -1921.9, y = 797.2 },
            Zone = 371,
            _index = 384
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
            _index = 385
        },
        {
            Qpart = { [29932] = { 1 } },
            coord = { x = -2447.7, y = 995.7 },
            GossipOptionIDs = { 40586 },
            Zone = 371,
            _index = 386
        },
        {
            Done = { 29932 },
            coord = { x = -2607.3, y = 921.2 },
            Zone = 371,
            _index = 387
        },
        {
            PickUp = { 29997, 29998 },
            coord = { x = -2607.3, y = 921.2 },
            Zone = 371,
            _index = 388
        },
        {
            PickUp = { 29999, 30005 },
            coord = { x = -2600.3, y = 905.6 },
            Zone = 371,
            _index = 389
        },
        {
            Qpart = { [29999] = { 3 } },
            coord = { x = -2495.2, y = 935.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 390
        },
        {
            Qpart = { [29999] = { 1 } },
            coord = { x = -2680.6, y = 1010.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 391
        },
        {
            Qpart = { [29999] = { 2 } },
            coord = { x = -2610.7, y = 793.1 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 392
        },
        {
            Done = { 29998 },
            coord = { x = -2476.7, y = 839.3 },
            Zone = 371,
            _index = 393
        },
        {
            PickUp = { 30001, 30002 },
            coord = { x = -2476.7, y = 839.3 },
            Zone = 371,
            _index = 394
        },
        {
            Qpart = { [29999] = { 4 } },
            coord = { x = -2457.2, y = 843.9 },
            Fillers = { [30005] = { 1 } },
            Range = 5,
            Zone = 371,
            _index = 395
        },
        {
            Qpart = { [30001] = { 1 }, [30002] = { 1 } },
            coord = { x = -2467.3, y = 856.1 },
            ExtraLineText = "CLICK_ON_THE_INFESTED_BOOKS_THEN_CLICK_ON_THE_BOOKWORMS_THAT_COME_OUT_TO_SQUISH_THEM",
            Range = 30,
            Zone = 371,
            _index = 396
        },
        {
            Done = { 30001, 30002 },
            coord = { x = -2477, y = 839.8 },
            Zone = 371,
            _index = 397
        },
        {
            PickUp = { 30004 },
            coord = { x = -2477, y = 839.8 },
            Zone = 371,
            _index = 398
        },
        {
            Waypoint = 29997,
            coord = { x = -2445.4, y = 870.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 399
        },
        {
            Waypoint = 29997,
            coord = { x = -2506.5, y = 851.4 },
            ExtraLineText = "UPSTAIRS",
            Range = 5,
            Zone = 371,
            _index = 400
        },
        {
            Waypoint = 29997,
            coord = { x = -2488.5, y = 812.4 },
            Range = 5,
            Zone = 371,
            _index = 401
        },
        {
            Waypoint = 29997,
            coord = { x = -2430.8, y = 832.8 },
            Range = 5,
            Zone = 371,
            _index = 402
        },
        {
            Waypoint = 29997,
            coord = { x = -2449, y = 893.3 },
            Range = 5,
            Zone = 371,
            _index = 403
        },
        {
            Waypoint = 29997,
            coord = { x = -2479.9, y = 883.2 },
            Range = 5,
            Zone = 371,
            _index = 404
        },
        {
            Waypoint = 29997,
            coord = { x = -2520.1, y = 1008.5 },
            Range = 5,
            Zone = 371,
            _index = 405
        },
        {
            Waypoint = 29997,
            coord = { x = -2488.7, y = 1025.3 },
            Range = 5,
            Zone = 371,
            _index = 406
        },
        {
            Qpart = { [29997] = { 1 } },
            coord = { x = -2535.9, y = 1054.9 },
            ExtraLineText = "KILL_WATER_ELEMENTS_UNTIL_YOU_DROP_THE_STAFF",
            Range = 30,
            Zone = 371,
            _index = 407
        },
        {
            Done = { 29997 },
            coord = { x = -2567.7, y = 1045 },
            Zone = 371,
            _index = 408
        },
        {
            PickUp = { 30011 },
            coord = { x = -2567.7, y = 1045 },
            Zone = 371,
            _index = 409
        },
        {
            Qpart = { [30005] = { 1 } },
            coord = { x = -2554.9, y = 933 },
            Range = 69,
            Zone = 371,
            _index = 410
        },
        {
            Done = { 30004, 30011 },
            coord = { x = -2607.4, y = 921.5 },
            Zone = 371,
            _index = 411
        },
        {
            Done = { 29999, 30005 },
            coord = { x = -2600, y = 905.7 },
            Zone = 371,
            _index = 412
        },
        {
            PickUp = { 30000 },
            coord = { x = -2600.4, y = 905.6 },
            Zone = 371,
            _index = 413
        },
        {
            Qpart = { [30000] = { 1 } },
            coord = { x = -2157.9, y = 945.7 },
            Range = 5,
            Zone = 371,
            _index = 414
        },
        {
            Done = { 30000 },
            coord = { x = -2446.8, y = 994.9 },
            Zone = 371,
            _index = 415
        },
        {
            PickUp = { 30499 },
            coord = { x = -2446.8, y = 994.9 },
            Zone = 371,
            _index = 416
        },
        {
            Waypoint = 30499,
            coord = { x = -2450.4, y = 1006.9 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 371,
            _index = 417
        },
        {
            Waypoint = 30499,
            coord = { x = -2366.8, y = 994.5 },
            Range = 5,
            Zone = 371,
            _index = 418
        },
        {
            Waypoint = 30499,
            coord = { x = -2272.2, y = 1022.2 },
            Range = 5,
            Zone = 371,
            _index = 419
        },
        {
            Waypoint = 30499,
            coord = { x = -2252.9, y = 963.5 },
            Range = 5,
            Zone = 371,
            _index = 420
        },
        {
            UseFlightPath = 30499,
            NodeID = 894,
            coord = { x = -2358.9, y = 777.2 },
            GossipOptionIDs = { 28345 },
            ETA = 84,
            Zone = 371,
            _index = 421
        },
        {
            Done = { 30499 },
            coord = { x = -504.7, y = 1455.4 },
            Zone = 371,
            _index = 422
        },
        {
            PickUp = { 30484, 30466 },
            coord = { x = -504.7, y = 1455.4 },
            Zone = 371,
            _index = 423
        },
        {
            Qpart = { [30466] = { 2 } },
            coord = { x = -513, y = 1448.1 },
            Range = 2,
            Zone = 371,
            _index = 424
        },
        {
            Qpart = { [30484] = { 2 } },
            coord = { x = -532.4, y = 1427.7 },
            Fillers = { [30466] = { 1 } },
            Button = { ["30466-1"] = 79884 },
            GossipOptionIDs = { 40695 },
            Zone = 371,
            _index = 425
        },
        {
            Qpart = { [30484] = { 1 } },
            coord = { x = -584.5, y = 1283.1 },
            Fillers = { [30466] = { 1 } },
            Button = { ["30466-1"] = 79884 },
            GossipOptionIDs = { 40230 },
            Zone = 371,
            _index = 426
        },
        {
            Qpart = { [30484] = { 3 } },
            coord = { x = -531.9, y = 1233.9 },
            GossipOptionIDs = { 40583 },
            Zone = 371,
            _index = 427
        },
        {
            Qpart = { [30484] = { 4 } },
            coord = { x = -433.6, y = 1094.2 },
            GossipOptionIDs = { 40301 },
            Zone = 371,
            _index = 428
        },
        {
            Qpart = { [30466] = { 1 } },
            coord = { x = -544.3, y = 1444 },
            Button = { ["30466-1"] = 79884 },
            Range = 69,
            Zone = 371,
            _index = 429
        },
        {
            Done = { 30466, 30484 },
            coord = { x = -504.1, y = 1456.3 },
            Zone = 371,
            _index = 430
        },
        {
            PickUp = { 30485 },
            coord = { x = -518.3, y = 1477.6 },
            Zone = 371,
            _index = 431
        },
        {
            UseFlightPath = 30485,
            NodeID = 1080,
            coord = { x = -518.3, y = 1477.6 },
            GossipOptionIDs = { 28426 },
            ETA = 66,
            Zone = 371,
            _index = 432
        },
        {
            Qpart = { [30485] = { 1 } },
            coord = { x = -1656.4, y = 536.3 },
            Button = { ["30485-1"] = 80071 },
            Range = 2,
            Zone = 371,
            _index = 433
        },
        {
            Done = { 30485 },
            coord = { x = -1674.1, y = 529.4 },
            Zone = 371,
            _index = 434
        },
        {
            PickUp = { 31303 },
            coord = { x = -1674.1, y = 529.4 },
            Zone = 371,
            _index = 435
        },
        {
            GetFP = 1080,
            coord = { x = -1569.2, y = 473.4 },
            Zone = 371,
            _index = 436
        },
        {
            Qpart = { [31303] = { 1 } },
            coord = { x = -1674.3, y = 532 },
            GossipOptionIDs = { 38770 },
            Zone = 371,
            _index = 437
        },
        {
            Done = { 31303 },
            coord = { x = -1989.8, y = 791.9 },
            Zone = 371,
            _index = 438
        },
        {
            PickUp = { 30500, 30502, 30504 },
            coord = { x = -1989.8, y = 791.9 },
            Zone = 371,
            _index = 439
        },
        {
            Qpart = { [30504] = { 1 } },
            coord = { x = -1909.7, y = 776.7 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["30504-1"] = 86467 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 440
        },
        {
            Qpart = { [30504] = { 2 } },
            coord = { x = -1847.6, y = 742.5 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["30504-2"] = 86467 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 441
        },
        {
            Qpart = { [30504] = { 3 } },
            coord = { x = -1821.3, y = 827.2 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["30504-3"] = 86467 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 442
        },
        {
            Qpart = { [30504] = { 4 } },
            coord = { x = -1901.2, y = 902.3 },
            Fillers = { [30500] = { 1 }, [30502] = { 1 } },
            Button = { ["30502-1"] = 80074, ["30504-4"] = 86467 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 5,
            Zone = 371,
            _index = 443
        },
        {
            Qpart = { [30500] = { 1 }, [30502] = { 1 } },
            coord = { x = -1974.6, y = 783.5 },
            Button = { ["30502-1"] = 80074 },
            ExtraLineText = "PICK_UP_THE_JADE_CHUNKS_AND_USE_THEM_TO_WEAKEN_THE_ELITES",
            Range = 69,
            Zone = 371,
            _index = 444
        },
        {
            Done = { 30500, 30502, 30504 },
            coord = { x = -1990.7, y = 791.2 },
            Zone = 371,
            _index = 445
        },
        {
            PickUp = { 30648 },
            coord = { x = -1990.8, y = 792.6 },
            Zone = 371,
            _index = 446
        },
        {
            Qpart = { [30648] = { 1 } },
            coord = { x = -1990.8, y = 792.6 },
            GossipOptionIDs = { 29679 },
            ETA = 102,
            Zone = 371,
            _index = 447
        },
        {
            Done = { 30648 },
            coord = { x = -695, y = 527.6 },
            Zone = 376,
            _index = 448
        },
        {
            Done = { 32018 },
            coord = { x = -693.6, y = 518 },
            DontHaveAura = 424143,
            Zone = 376,
            _index = 449
        },
        {
            RouteCompleted = 1,
            _index = 450
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
            coord = { x = -610.3, y = -347.6 },
            Zone = 418,
            _index = 37
        },
        {
            PickUp = { 30179 },
            coord = { x = -277.2, y = -805.5 },
            Zone = 418,
            _index = 38
        },
        {
            Qpart = { [30179] = { 1 } },
            coord = { x = -239.8, y = -828.9 },
            Range = 30,
            Zone = 418,
            _index = 39
        },
        {
            PickUp = { 30352, 30353 },
            coord = { x = -222.8, y = -914.7 },
            Zone = 418,
            _index = 40
        },
        {
            Qpart = { [30133] = { 1 } },
            coord = { x = 16.7, y = -905.2 },
            GossipOptionIDs = { 41038 },
            RaidIcon = 59151,
            Zone = 418,
            _index = 41
        },
        {
            Done = { 29875 },
            DoneDB = { 29874, 29875 },
            coord = { x = 130.2, y = -891.8 },
            Zone = 418,
            _index = 42
        },
        {
            Done = { 30179 },
            coord = { x = 141.6, y = -881.2 },
            Zone = 418,
            _index = 43
        },
        {
            PickUp = { 30124 },
            coord = { x = 141.6, y = -882.3 },
            Zone = 418,
            _index = 44
        },
        {
            PickUp = { 30123 },
            coord = { x = 130.7, y = -892 },
            Zone = 418,
            _index = 45
        },
        {
            GetFP = 987,
            coord = { x = 174.1, y = -880.7 },
            Zone = 418,
            _index = 46
        },
        {
            Qpart = { [30124] = { 1 } },
            coord = { x = 46.5, y = -1064.9 },
            Fillers = { [30123] = { 1 }, [30352] = { 1 }, [30353] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 47
        },
        {
            Qpart = { [30123] = { 1 } },
            coord = { x = -35.2, y = -792.5 },
            Fillers = { [30352] = { 1 }, [30353] = { 1 } },
            Range = 30,
            Zone = 418,
            _index = 48
        },
        {
            Qpart = { [30352] = { 1 }, [30353] = { 1 } },
            coord = { x = -60.7, y = -1027.9 },
            ExtraLineText = "TIGERS_ARE_INVISIBLE_AROUND_BIRDS",
            Range = 100,
            Zone = 418,
            _index = 49
        },
        {
            Done = { 30352 },
            coord = { x = -223, y = -913.5 },
            Zone = 418,
            _index = 50
        },
        {
            PickUp = { 31262 },
            coord = { x = -223, y = -913.5 },
            Zone = 418,
            _index = 51
        },
        {
            Done = { 30353 },
            coord = { x = -223, y = -913.5 },
            Zone = 418,
            _index = 52
        },
        {
            PickUp = { 31260 },
            coord = { x = -223, y = -913.5 },
            Zone = 418,
            _index = 53
        },
        {
            Qpart = { [31262] = { 1 } },
            coord = { x = -4, y = -741.5 },
            Range = 5,
            Zone = 418,
            _index = 54
        },
        {
            Done = { 30123 },
            coord = { x = 133, y = -892.4 },
            Zone = 418,
            _index = 55
        },
        {
            Done = { 30124 },
            coord = { x = 141.8, y = -885 },
            Zone = 418,
            _index = 56
        },
        {
            PickUp = { 30127, 30130 },
            coord = { x = 141.8, y = -885 },
            Zone = 418,
            _index = 57
        },
        {
            PickUp = { 30129 },
            coord = { x = 131.6, y = -891.5 },
            Zone = 418,
            _index = 58
        },
        {
            Qpart = { [31260] = { 1 } },
            coord = { x = 64, y = -1107.5 },
            Range = 5,
            Zone = 418,
            _index = 59
        },
        {
            Qpart = { [30129] = { 1 } },
            coord = { x = 346.2, y = -1187.8 },
            Fillers = { [30127] = { 1, 2, 3 }, [30130] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 60
        },
        {
            Done = { 30129 },
            NoArrow = 1,
            Zone = 418,
            _index = 61
        },
        {
            PickUp = { 30128 },
            NoArrow = 1,
            Zone = 418,
            _index = 62
        },
        {
            Qpart = { [30127] = { 3, 2, 1 }, [30130] = { 1 } },
            coord = { x = 344, y = -1252.5 },
            Range = 100,
            Zone = 418,
            _index = 63
        },
        {
            Qpart = { [30128] = { 1 } },
            coord = { x = 515.4, y = -1133.7 },
            GossipOptionIDs = { 39799 },
            Zone = 418,
            _index = 64
        },
        {
            Done = { 31260, 31262 },
            coord = { x = -222.4, y = -914.5 },
            Zone = 418,
            _index = 65
        },
        {
            Done = { 30127, 30128, 30130 },
            coord = { x = 141.7, y = -883.4 },
            Zone = 418,
            _index = 66
        },
        {
            PickUp = { 30131 },
            coord = { x = 141.7, y = -883.4 },
            Zone = 418,
            _index = 67
        },
        {
            Qpart = { [30131] = { 1 } },
            coord = { x = 138.6, y = -883.8 },
            GossipOptionIDs = { 40273 },
            Zone = 418,
            _index = 68
        },
        {
            Done = { 30131 },
            coord = { x = 116.2, y = -908.6 },
            Zone = 418,
            _index = 69
        },
        {
            PickUp = { 30132 },
            coord = { x = 116.2, y = -908.6 },
            Zone = 418,
            _index = 70
        },
        {
            Qpart = { [30132] = { 1 } },
            coord = { x = 895.3, y = -1447.4 },
            Range = 5,
            Zone = 418,
            _index = 71
        },
        {
            Done = { 30133 },
            coord = { x = 876, y = -1450.9 },
            Zone = 418,
            _index = 72
        },
        {
            PickUp = { 30269 },
            coord = { x = 876, y = -1450.9 },
            Zone = 418,
            _index = 73
        },
        {
            Waypoint = 30269,
            coord = { x = 895.2, y = -1308.8 },
            ExtraLineText = "ESCORTS_NPC",
            GossipOptionIDs = { 40208 },
            Range = 1,
            Zone = 418,
            _index = 74
        },
        {
            Qpart = { [30269] = { 1 } },
            coord = { x = 897.3, y = -1234.7 },
            ExtraLineText = "ESCORTS_NPC",
            GossipOptionIDs = { 40208 },
            Range = 2,
            Zone = 418,
            _index = 75
        },
        {
            Done = { 30269 },
            coord = { x = 1044.7, y = -1163.5 },
            Zone = 418,
            _index = 76
        },
        {
            PickUp = { 30270, 30694 },
            coord = { x = 1044.7, y = -1163.5 },
            Zone = 418,
            _index = 77
        },
        {
            PickUp = { 30268 },
            coord = { x = 1050.8, y = -1194.1 },
            Zone = 418,
            _index = 78
        },
        {
            Qpart = { [30270] = { 1 }, [30694] = { 1 } },
            coord = { x = 783.7, y = -1204.4 },
            Button = { ["30694-1"] = 80828 },
            Range = 60,
            Zone = 418,
            _index = 79
        },
        {
            Qpart = { [30268] = { 1 } },
            coord = { x = 1080.4, y = -1269.1 },
            Range = 30,
            Zone = 418,
            _index = 80
        },
        {
            Done = { 30270, 30694 },
            coord = { x = 1044.7, y = -1163.6 },
            Zone = 418,
            _index = 81
        },
        {
            Done = { 30268 },
            coord = { x = 1050.5, y = -1193.2 },
            Zone = 418,
            _index = 82
        },
        {
            PickUp = { 30272, 30695, 30271 },
            coord = { x = 1045.3, y = -1162.7 },
            Zone = 418,
            _index = 83
        },
        {
            Qpart = { [30695] = { 1 } },
            coord = { x = 1179.5, y = -1810 },
            Fillers = { [30271] = { 1 }, [30272] = { 1 } },
            ExtraLineText = "KILL_HAUNTS_NEAR_MONKS_INSPIRE",
            Range = 5,
            Zone = 418,
            _index = 84
        },
        {
            Done = { 30695 },
            NoArrow = 1,
            Zone = 418,
            _index = 85
        },
        {
            Qpart = { [30271] = { 1 }, [30272] = { 1 } },
            coord = { x = 1053.8, y = -1678.7 },
            ExtraLineText = "KILL_HAUNTS_NEAR_MONKS_INSPIRE",
            Range = 60,
            Zone = 418,
            _index = 86
        },
        {
            Done = { 30271, 30272 },
            NoArrow = 1,
            Zone = 418,
            _index = 87
        },
        {
            PickUp = { 30273 },
            NoArrow = 1,
            Zone = 418,
            _index = 88
        },
        {
            Waypoint = 30273,
            coord = { x = 1053.3, y = -1732.4 },
            Range = 5,
            Zone = 418,
            _index = 89
        },
        {
            Waypoint = 30273,
            coord = { x = 1053.2, y = -1900.6 },
            Range = 5,
            Zone = 418,
            _index = 90
        },
        {
            Waypoint = 30273,
            coord = { x = 1077.9, y = -1894.3 },
            Range = 5,
            Zone = 418,
            _index = 91
        },
        {
            Qpart = { [30273] = { 1 } },
            coord = { x = 1053.9, y = -1815.6 },
            GossipOptionIDs = { 39489 },
            Range = 3,
            Zone = 418,
            _index = 92
        },
        {
            Waypoint = 30273,
            coord = { x = 1052.4, y = -1896.4 },
            Range = 5,
            Zone = 418,
            _index = 93
        },
        {
            Done = { 30273 },
            coord = { x = 1053.5, y = -1649.6 },
            Zone = 418,
            _index = 94
        },
        {
            PickUp = { 30667 },
            coord = { x = 526.1, y = -2465 },
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
            PickUp = { 30666 },
            coord = { x = 534.6, y = -2513.4 },
            Zone = 418,
            _index = 97
        },
        {
            Qpart = { [30666] = { 1 } },
            coord = { x = 727.7, y = -2269 },
            Fillers = { [30667] = { 1, 2, 3 } },
            Range = 30,
            Zone = 418,
            _index = 98
        },
        {
            Qpart = { [30667] = { 1, 2, 3 } },
            coord = { x = 810.1, y = -2268.7 },
            Range = 30,
            Zone = 418,
            _index = 99
        },
        {
            Done = { 30667 },
            coord = { x = 525.9, y = -2464.2 },
            Zone = 418,
            _index = 100
        },
        {
            Done = { 30666 },
            coord = { x = 532.8, y = -2512.3 },
            Zone = 418,
            _index = 101
        },
        {
            PickUp = { 30668 },
            coord = { x = 532.8, y = -2512.3 },
            Zone = 418,
            _index = 102
        },
        {
            Qpart = { [30668] = { 2 } },
            coord = { x = 498.8, y = -2545.7 },
            Range = 2,
            Zone = 418,
            _index = 103
        },
        {
            Qpart = { [30668] = { 1 } },
            coord = { x = 491.1, y = -2490.5 },
            Range = 2,
            Zone = 418,
            _index = 104
        },
        {
            Done = { 30668 },
            coord = { x = 532.9, y = -2513.2 },
            Zone = 418,
            _index = 105
        },
        {
            PickUp = { 30669 },
            coord = { x = 532.9, y = -2513.2 },
            Zone = 418,
            _index = 106
        },
        {
            Qpart = { [30669] = { 1 } },
            coord = { x = 525.6, y = -2502.8 },
            Zone = 418,
            _index = 107
        },
        {
            Done = { 30669 },
            coord = { x = 792.1, y = -2575.8 },
            Zone = 418,
            _index = 108
        },
        {
            PickUp = { 30671, 30691 },
            coord = { x = 792.1, y = -2575.8 },
            Zone = 418,
            _index = 109
        },
        {
            Waypoint = 30691,
            coord = { x = 792.1, y = -2599.1 },
            Fillers = { [30671] = { 1 } },
            ExtraLineText = "JUMP_INTO_WATER_AND_ENTER_IN_UNDERWATER_CAVE",
            Range = 5,
            Zone = 418,
            _index = 110
        },
        {
            Qpart = { [30691] = { 1 } },
            coord = { x = 781.8, y = -2717.1 },
            Fillers = { [30671] = { 1 } },
            ExtraLineText = "JUMP_INTO_WATER_AND_ENTER_IN_UNDERWATER_CAVE",
            Range = 2,
            Zone = 418,
            _index = 111
        },
        {
            Done = { 30691 },
            NoArrow = 1,
            Zone = 418,
            _index = 112
        },
        {
            Qpart = { [30671] = { 1 } },
            coord = { x = 736.5, y = -2584.5 },
            Range = 30,
            Zone = 418,
            _index = 113
        },
        {
            Done = { 30671 },
            coord = { x = 794.7, y = -2579.9 },
            Zone = 418,
            _index = 114
        },
        {
            PickUp = { 30672 },
            coord = { x = 791.9, y = -2576.4 },
            Zone = 418,
            _index = 115
        },
        {
            PickUp = { 30674 },
            coord = { x = 820, y = -2758.9 },
            Zone = 418,
            _index = 116
        },
        {
            DropQuest = 30675,
            DroppableQuest = { MobId = 60299, Qid = 30675, Text = "Unga Fish-Getter" },
            coord = { x = 700.1, y = -2833.4 },
            Range = 30,
            Zone = 418,
            _index = 117
        },
        {
            Qpart = { [30672] = { 1 }, [30674] = { 1 } },
            coord = { x = 700.1, y = -2833.4 },
            Fillers = { [30675] = { 1 } },
            Range = 100,
            Zone = 418,
            _index = 118
        },
        {
            Done = { 30674 },
            NoArrow = 1,
            Zone = 418,
            _index = 119
        },
        {
            Qpart = { [30675] = { 1 } },
            coord = { x = 753.3, y = -2885.2 },
            Range = 100,
            Zone = 418,
            _index = 120
        },
        {
            Done = { 30675 },
            NoArrow = 1,
            Zone = 418,
            _index = 121
        },
        {
            Done = { 30672 },
            coord = { x = 531.9, y = -2511.5 },
            Zone = 418,
            _index = 122
        },
        {
            GetFP = 990,
            coord = { x = 1592.6, y = -1687.4 },
            Zone = 418,
            _index = 123
        },
        {
            Done = { 30132 },
            coord = { x = 1603.5, y = -1700.2 },
            Zone = 418,
            _index = 124
        },
        {
            PickUp = { 30163, 30229 },
            coord = { x = 1603.5, y = -1700.2 },
            Zone = 418,
            _index = 125
        },
        {
            PickUp = { 30230 },
            coord = { x = 1596, y = -1690.9 },
            Zone = 418,
            _index = 126
        },
        {
            PickUp = { 30168, 30169 },
            coord = { x = 1556.2, y = -1330.3 },
            Zone = 418,
            _index = 127
        },
        {
            Qpart = { [30169] = { 1 } },
            coord = { x = 1457.4, y = -1016.2 },
            Fillers = { [30168] = { 1 } },
            Range = 5,
            Zone = 418,
            _index = 128
        },
        {
            Waypoint = 30168,
            coord = { x = 1411.1, y = -1029.3 },
            Fillers = { [30168] = { 1 } },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 418,
            _index = 129
        },
        {
            Qpart = { [30168] = { 1 } },
            coord = { x = 1418.6, y = -1013.6 },
            Range = 30,
            Zone = 418,
            _index = 130
        },
        {
            Done = { 30168, 30169 },
            coord = { x = 1556.9, y = -1331.7 },
            Zone = 418,
            _index = 131
        },
        {
            Qpart = { [30163] = { 1 }, [30229] = { 1 }, [30230] = { 1 } },
            coord = { x = 1798.7, y = -1328 },
            Range = 45,
            Zone = 418,
            _index = 132
        },
        {
            Done = { 30230 },
            coord = { x = 1597.4, y = -1691.6 },
            Zone = 418,
            _index = 133
        },
        {
            Done = { 30163, 30229 },
            coord = { x = 1602.1, y = -1700.8 },
            Zone = 418,
            _index = 134
        },
        {
            PickUp = { 30175 },
            coord = { x = 1585.9, y = -1708.3 },
            Zone = 418,
            _index = 135
        },
        {
            PickUp = { 30164 },
            coord = { x = 2199.4, y = -1353.8 },
            Zone = 418,
            _index = 136
        },
        {
            Qpart = { [30164] = { 1 }, [30175] = { 1 } },
            coord = { x = 2187, y = -1241.9 },
            Range = 30,
            Zone = 418,
            _index = 137
        },
        {
            Done = { 30175 },
            coord = { x = 2211.7, y = -1351.2 },
            Zone = 418,
            _index = 138
        },
        {
            Done = { 30164 },
            coord = { x = 2198.7, y = -1353.7 },
            Zone = 418,
            _index = 139
        },
        {
            PickUp = { 30174 },
            coord = { x = 2198.7, y = -1353.7 },
            Zone = 418,
            _index = 140
        },
        {
            Qpart = { [30174] = { 1 } },
            coord = { x = 1839.3, y = -1636.6 },
            GossipOptionIDs = { 40073 },
            Zone = 418,
            _index = 141
        },
        {
            Done = { 30174 },
            coord = { x = 1591.9, y = -1699.5 },
            Zone = 418,
            _index = 142
        },
        {
            PickUp = { 30241 },
            coord = { x = 1591.9, y = -1699.5 },
            Zone = 418,
            _index = 143
        },
        {
            UseFlightPath = 30241,
            NodeID = 989,
            coord = { x = 1588.4, y = -1685.1 },
            ETA = 46,
            Zone = 418,
            _index = 144
        },
        {
            Done = { 30241 },
            coord = { x = 1911.9, y = -392.9 },
            Zone = 376,
            _index = 145
        },
        {
            PickUp = { 30623, 30622 },
            coord = { x = 1976.4, y = -380.1 },
            Zone = 376,
            _index = 146
        },
        {
            PickUp = { 30653 },
            coord = { x = 1965.7, y = -362.1 },
            Zone = 376,
            _index = 147
        },
        {
            Qpart = { [30653] = { 1 } },
            coord = { x = 2004.8, y = -237.2 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 148
        },
        {
            Qpart = { [30653] = { 2 } },
            coord = { x = 2069.6, y = -354.3 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 149
        },
        {
            Qpart = { [30653] = { 4 } },
            coord = { x = 2164, y = -352.1 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 150
        },
        {
            Qpart = { [30653] = { 3 } },
            coord = { x = 2244.6, y = -367.3 },
            Fillers = { [30622] = { 1 }, [30623] = { 1 } },
            Range = 2,
            Zone = 376,
            _index = 151
        },
        {
            Done = { 30653 },
            NoArrow = 1,
            Zone = 376,
            _index = 152
        },
        {
            Qpart = { [30622] = { 1 }, [30623] = { 1 } },
            coord = { x = 2172.1, y = -299.5 },
            Button = { ["30623-1"] = 80337 },
            Range = 30,
            Zone = 376,
            _index = 153
        },
        {
            Done = { 30623, 30622 },
            coord = { x = 2225.1, y = -199 },
            Zone = 376,
            _index = 154
        },
        {
            PickUp = { 30625 },
            coord = { x = 2225.1, y = -199 },
            Zone = 376,
            _index = 155
        },
        {
            Qpart = { [30625] = { 1, 2, 3, 4 } },
            coord = { x = 2304, y = -318.2 },
            Range = 30,
            Zone = 376,
            _index = 156
        },
        {
            Done = { 30625 },
            coord = { x = 2222.8, y = -198.7 },
            Zone = 376,
            _index = 157
        },
        {
            PickUp = { 30626 },
            coord = { x = 2222.8, y = -198.7 },
            Zone = 376,
            _index = 158
        },
        {
            Done = { 30626 },
            coord = { x = 1978.3, y = -377.1 },
            Zone = 376,
            _index = 159
        },
        {
            PickUp = { 30627 },
            coord = { x = 1975.2, y = -362 },
            Zone = 376,
            _index = 160
        },
        {
            Qpart = { [30627] = { 1 } },
            coord = { x = 1976.1, y = -388.9 },
            GossipOptionIDs = { 39267 },
            RaidIcon = 59857,
            Zone = 376,
            _index = 161
        },
        {
            Done = { 30627 },
            coord = { x = 1977.7, y = -374.9 },
            Zone = 376,
            _index = 162
        },
        {
            PickUp = { 30628 },
            coord = { x = 1977.7, y = -374.9 },
            Zone = 376,
            _index = 163
        },
        {
            Waypoint = 30628,
            coord = { x = 1905.4, y = -379.3 },
            ExtraLineText = "UPSTAIRS",
            Range = 3,
            Zone = 376,
            _index = 164
        },
        {
            Done = { 30628 },
            coord = { x = 1901.3, y = -367.5 },
            ExtraLineText = "UPSTAIRS",
            Zone = 376,
            _index = 165
        },
        {
            UseFlightPath = 31286,
            NodeID = 1052,
            coord = { x = 1882.1, y = -439.1 },
            ETA = 79,
            Zone = 376,
            _index = 166
        },
        {
            RouteCompleted = 1,
            _index = 167
        }
    }

    APR.RouteQuestStepList["379-Kun-Lai Summit"] = {
        {
            PickUp = { 31393 },
            coord = { x = 479.2, y = -260.4 },
            Zone = 376,
            _index = 1
        },
        {
            PickUp = { 31255 },
            coord = { x = 508.4, y = -217.7 },
            Zone = 376,
            _index = 2
        },
        {
            Qpart = { [31255] = { 1 } },
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
            Range = 5,
            Zone = 433,
            _index = 7
        },
        {
            Waypoint = 31286,
            coord = { x = -52.1, y = 1172.6 },
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
            Qpart = { [31255] = { 2 } },
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
            Done = { 31255 },
            coord = { x = 316.8, y = 1785 },
            Zone = 379,
            _index = 19
        },
        {
            PickUp = { 30457 },
            coord = { x = 316.8, y = 1785 },
            Zone = 379,
            _index = 20
        },
        {
            PickUp = { 30459 },
            coord = { x = 413, y = 1848.3 },
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
            coord = { x = 411.2, y = 1848.1 },
            Zone = 379,
            _index = 24
        },
        {
            Done = { 30457 },
            coord = { x = 316.2, y = 1785.4 },
            Zone = 379,
            _index = 25
        },
        {
            Done = { 30460 },
            coord = { x = 360.1, y = 1745 },
            Zone = 379,
            _index = 26
        },
        {
            PickUp = { 30511 },
            coord = { x = 360.1, y = 1745 },
            Zone = 379,
            _index = 27
        },
        {
            Done = { 30511 },
            coord = { x = 355.8, y = 1733.2 },
            ExtraLineText = "UPSTAIRS",
            Zone = 379,
            _index = 28
        },
        {
            PickUp = { 30513 },
            coord = { x = 355.8, y = 1733.2 },
            Zone = 379,
            _index = 29
        },
        {
            PickUp = { 30467, 30469 },
            coord = { x = 147.9, y = 1910.8 },
            Zone = 379,
            _index = 30
        },
        {
            PickUp = { 30468 },
            coord = { x = 158.6, y = 1918.8 },
            Zone = 379,
            _index = 31
        },
        {
            PickUp = { 30496, 30967 },
            coord = { x = 137.3, y = 1949.7 },
            Zone = 379,
            _index = 32
        },
        {
            Done = { 30467 },
            coord = { x = 165.7, y = 2408.3 },
            Zone = 379,
            _index = 33
        },
        {
            PickUp = { 30834 },
            coord = { x = 165.7, y = 2408.3 },
            Zone = 379,
            _index = 34
        },
        {
            Qpart = { [30496] = { 1 } },
            coord = { x = 204.6, y = 2361.4 },
            Fillers = { [30468] = { 1 }, [30469] = { 1 }, [30967] = { 1 } },
            GossipOptionIDs = { 35732 },
            Range = 5,
            Zone = 379,
            _index = 35
        },
        {
            Qpart = { [30468] = { 1 }, [30469] = { 1 }, [30967] = { 1 } },
            coord = { x = 208.1, y = 2343.7 },
            GossipOptionIDs = { 35732 },
            Range = 45,
            Zone = 379,
            _index = 36
        },
        {
            Done = { 30496, 30967 },
            coord = { x = 132.8, y = 1936.6 },
            Zone = 379,
            _index = 37
        },
        {
            Qpart = { [30834] = { 1 } },
            coord = { x = 148.1, y = 1910.8 },
            Zone = 379,
            _index = 38
        },
        {
            Done = { 30834 },
            coord = { x = 148.1, y = 1910.8 },
            Zone = 379,
            _index = 39
        },
        {
            Done = { 30469 },
            coord = { x = 148.7, y = 1910.6 },
            Zone = 379,
            _index = 40
        },
        {
            Done = { 30468 },
            coord = { x = 159.8, y = 1919.5 },
            Zone = 379,
            _index = 41
        },
        {
            PickUp = { 30480 },
            coord = { x = 132, y = 1935.8 },
            Zone = 379,
            _index = 42
        },
        {
            Qpart = { [30480] = { 1 } },
            coord = { x = 133.6, y = 1935.2 },
            GossipOptionIDs = { 38108 },
            Zone = 379,
            _index = 43
        },
        {
            Qpart = { [30480] = { 2, 3 } },
            coord = { x = 154, y = 1918.6 },
            Range = 5,
            Zone = 379,
            _index = 44
        },
        {
            Done = { 30480 },
            coord = { x = 152.5, y = 1921.3 },
            Zone = 379,
            _index = 45
        },
        {
            PickUp = { 30828 },
            coord = { x = 152.5, y = 1921.3 },
            Zone = 379,
            _index = 46
        },
        {
            Qpart = { [30828] = { 1 } },
            coord = { x = 316.9, y = 2067.2 },
            Range = 30,
            Zone = 379,
            _index = 47
        },
        {
            Done = { 30828 },
            NoArrow = 1,
            Zone = 379,
            _index = 48
        },
        {
            PickUp = { 30855 },
            NoArrow = 1,
            Zone = 379,
            _index = 49
        },
        {
            Qpart = { [30855] = { 1 } },
            coord = { x = 377.6, y = 2182.8 },
            ExtraLineText = "KILL_SMALL_SHA_ON_ISLAND_CLOSE_TO_SHAI_HU_TO_WEAKEN_HIM",
            Range = 30,
            Zone = 379,
            _index = 50
        },
        {
            Done = { 30855 },
            coord = { x = 152.1, y = 1921.1 },
            Zone = 379,
            _index = 51
        },
        {
            Qpart = { [30513] = { 1 } },
            coord = { x = 853.7, y = 2003.1 },
            GossipOptionIDs = { 41283 },
            Zone = 379,
            _index = 52
        },
        {
            Qpart = { [30513] = { 2 } },
            coord = { x = 1009.5, y = 2188.3 },
            GossipOptionIDs = { 41465 },
            Zone = 379,
            _index = 53
        },
        {
            Done = { 30513 },
            coord = { x = 1009.5, y = 2188.3 },
            Zone = 379,
            _index = 54
        },
        {
            PickUp = { 30515 },
            coord = { x = 1009.5, y = 2188.3 },
            Zone = 379,
            _index = 55
        },
        {
            Qpart = { [30515] = { 1 } },
            coord = { x = 1195.4, y = 2109.1 },
            ExtraLineText = "CLICK_ON_BANNER",
            Range = 5,
            Zone = 379,
            _index = 56
        },
        {
            Done = { 30515 },
            coord = { x = 985.1, y = 2273.8 },
            Zone = 379,
            _index = 57
        },
        {
            PickUp = { 31256 },
            coord = { x = 896.5, y = 2271.6 },
            Zone = 379,
            _index = 58
        },
        {
            PickUp = { 31251 },
            coord = { x = 911.2, y = 2285.2 },
            Zone = 379,
            _index = 59
        },
        {
            PickUp = { 30570 },
            coord = { x = 926.2, y = 2303.3 },
            Zone = 379,
            _index = 60
        },
        {
            PickUp = { 30620 },
            coord = { x = 938.8, y = 2296.3 },
            Zone = 379,
            _index = 61
        },
        {
            PickUp = { 30594 },
            coord = { x = 916.2, y = 2250.4 },
            Zone = 379,
            _index = 62
        },
        {
            GetFP = 1019,
            coord = { x = 933, y = 2249.8 },
            Zone = 379,
            _index = 63
        },
        {
            Done = { 30570 },
            coord = { x = 1069.1, y = 2038.6 },
            Zone = 379,
            _index = 64
        },
        {
            PickUp = { 30571 },
            coord = { x = 1069.1, y = 2038.6 },
            Zone = 379,
            _index = 65
        },
        {
            PickUp = { 30581 },
            coord = { x = 1073.4, y = 2033.9 },
            Zone = 379,
            _index = 66
        },
        {
            Qpart = { [30581] = { 2 } },
            coord = { x = 1082.1, y = 1928.9 },
            ExtraLineText = "INSIDE",
            Range = 2,
            Zone = 379,
            _index = 67
        },
        {
            Qpart = { [30571] = { 1 }, [30581] = { 1 } },
            coord = { x = 1083.1, y = 1949.1 },
            Range = 60,
            Zone = 379,
            _index = 68
        },
        {
            Done = { 30581, 30571 },
            coord = { x = 1072, y = 2035 },
            Zone = 379,
            _index = 69
        },
        {
            PickUp = { 31253 },
            coord = { x = 1072, y = 2035 },
            Zone = 379,
            _index = 70
        },
        {
            PickUp = { 30595 },
            coord = { x = 1109.9, y = 2355.4 },
            Zone = 379,
            _index = 71
        },
        {
            Qpart = { [30620] = { 1 } },
            coord = { x = 1202.3, y = 2659.2 },
            Fillers = { [30594] = { 1 }, [30595] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 72
        },
        {
            Qpart = { [30594] = { 1 }, [30595] = { 1 } },
            coord = { x = 1195.4, y = 2490.6 },
            Range = 30,
            Zone = 379,
            _index = 73
        },
        {
            Done = { 30595 },
            coord = { x = 1108.7, y = 2355 },
            Zone = 379,
            _index = 74
        },
        {
            DropQuest = 30582,
            DroppableQuest = { MobId = 59718, Qid = 30582, Text = "Burilgi Despoiler" },
            coord = { x = 490.8, y = 2513.2 },
            Range = 15,
            Zone = 379,
            _index = 75
        },
        {
            Qpart = { [31251] = { 1 } },
            coord = { x = 618.5, y = 2427.6 },
            Fillers = { [31256] = { 1 } },
            ExtraLineText = "FIND_3_YAKS_WHILE_KILLING_MOBS",
            Range = 100,
            Zone = 379,
            _index = 76
        },
        {
            Qpart = { [31256] = { 1 } },
            coord = { x = 901.7, y = 2291.9 },
            ExtraLineText = "FIND_3_YAKS_WHILE_KILLING_MOBS",
            Range = 5,
            Zone = 379,
            _index = 77
        },
        {
            Done = { 31251 },
            coord = { x = 911.9, y = 2286.2 },
            Zone = 379,
            _index = 78
        },
        {
            Done = { 31253 },
            coord = { x = 925.1, y = 2303.9 },
            Zone = 379,
            _index = 79
        },
        {
            Done = { 30620 },
            coord = { x = 938.5, y = 2296.9 },
            Zone = 379,
            _index = 80
        },
        {
            PickUp = { 30655 },
            coord = { x = 938.5, y = 2296.9 },
            Zone = 379,
            _index = 81
        },
        {
            Done = { 30594 },
            coord = { x = 916.2, y = 2250 },
            Zone = 379,
            _index = 82
        },
        {
            PickUp = { 30656 },
            coord = { x = 911.7, y = 2283.9 },
            Zone = 379,
            _index = 83
        },
        {
            Done = { 31256 },
            coord = { x = 896.6, y = 2271.6 },
            Zone = 379,
            _index = 84
        },
        {
            PickUp = { 30657 },
            coord = { x = 896.6, y = 2271.6 },
            Zone = 379,
            _index = 85
        },
        {
            Waypoint = 30657,
            coord = { x = 1631.6, y = 2310.1 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 2,
            Zone = 379,
            _index = 86
        },
        {
            Qpart = { [30656] = { 1 } },
            coord = { x = 1648.1, y = 2307 },
            Fillers = { [30655] = { 1 } },
            Button = { ["30656-1"] = 80528 },
            Range = 2,
            Zone = 379,
            _index = 87
        },
        {
            Waypoint = 30657,
            coord = { x = 1686, y = 2311.3 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 379,
            _index = 88
        },
        {
            Qpart = { [30657] = { 1 } },
            coord = { x = 1684.3, y = 2337.3 },
            Fillers = { [30655] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 89
        },
        {
            Qpart = { [30657] = { 3 } },
            coord = { x = 1745.8, y = 2343.3 },
            Fillers = { [30655] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 90
        },
        {
            Qpart = { [30657] = { 4 } },
            coord = { x = 1765.3, y = 2265.8 },
            Fillers = { [30655] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 91
        },
        {
            Waypoint = 30657,
            coord = { x = 1751.7, y = 2234.8 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 2,
            Zone = 379,
            _index = 92
        },
        {
            Qpart = { [30656] = { 2 } },
            coord = { x = 1737.5, y = 2234.7 },
            Fillers = { [30655] = { 1 } },
            Button = { ["30656-2"] = 80528 },
            Range = 2,
            Zone = 379,
            _index = 93
        },
        {
            Qpart = { [30657] = { 2 } },
            coord = { x = 1855, y = 2282.9 },
            Fillers = { [30655] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 94
        },
        {
            Done = { 30657 },
            NoArrow = 1,
            Zone = 379,
            _index = 95
        },
        {
            PickUp = { 30661 },
            NoArrow = 1,
            Zone = 379,
            _index = 96
        },
        {
            Waypoint = 30656,
            coord = { x = 1864.8, y = 2275.6 },
            ExtraLineText = "TAKE_EXPLOSIVES_BARREL",
            Range = 1,
            Zone = 379,
            _index = 97
        },
        {
            Qpart = { [30656] = { 3 } },
            coord = { x = 1844.6, y = 2221.5 },
            Fillers = { [30655] = { 1 } },
            Button = { ["30656-3"] = 80528 },
            Range = 2,
            Zone = 379,
            _index = 98
        },
        {
            Qpart = { [30655] = { 1 } },
            coord = { x = 1783.2, y = 2251.3 },
            Range = 30,
            Zone = 379,
            _index = 99
        },
        {
            Waypoint = 30656,
            coord = { x = 1774.4, y = 2408.9 },
            Range = 5,
            Zone = 379,
            _index = 100
        },
        {
            Qpart = { [30661] = { 1 } },
            coord = { x = 1810.3, y = 2415.7 },
            Range = 5,
            Zone = 379,
            _index = 101
        },
        {
            Done = { 30656 },
            coord = { x = 910.4, y = 2285.4 },
            Zone = 379,
            _index = 102
        },
        {
            Done = { 30655, 30661 },
            coord = { x = 933.9, y = 2265.4 },
            Zone = 379,
            _index = 103
        },
        {
            PickUp = { 31453 },
            coord = { x = 933.9, y = 2265.4 },
            Zone = 379,
            _index = 104
        },
        {
            PickUp = { 31695 },
            PickUpDB = { 31695, 39127 },
            coord = { x = 936.5, y = 2297.3 },
            Zone = 379,
            _index = 105
        },
        {
            PickUp = { 31457 },
            coord = { x = 926, y = 2303.9 },
            Zone = 379,
            _index = 106
        },
        {
            PickUp = { 31459 },
            coord = { x = 915.9, y = 2250.6 },
            Zone = 379,
            _index = 107
        },
        {
            SetHS = 31459,
            coord = { x = 914.1, y = 2259.6 },
            Zone = 379,
            _index = 108
        },
        {
            Done = { 30582 },
            coord = { x = 351.6, y = 2686.9 },
            Zone = 379,
            _index = 109
        },
        {
            PickUp = { 30804 },
            coord = { x = 351.6, y = 2686.9 },
            Zone = 379,
            _index = 110
        },
        {
            Done = { 31457 },
            coord = { x = 351.6, y = 2686.9 },
            Zone = 379,
            _index = 111
        },
        {
            PickUp = { 30488, 30489 },
            coord = { x = 351.6, y = 2686.9 },
            Zone = 379,
            _index = 112
        },
        {
            Waypoint = 30488,
            coord = { x = 269.7, y = 2554.2 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 113
        },
        {
            Waypoint = 30488,
            coord = { x = 225.7, y = 2503.4 },
            Range = 5,
            Zone = 379,
            _index = 114
        },
        {
            Waypoint = 30488,
            coord = { x = 198.9, y = 2521.6 },
            Range = 5,
            Zone = 379,
            _index = 115
        },
        {
            Waypoint = 30488,
            coord = { x = 186.9, y = 2549.7 },
            Range = 5,
            Zone = 379,
            _index = 116
        },
        {
            Waypoint = 30488,
            coord = { x = 134.2, y = 2518.6 },
            Range = 5,
            Zone = 379,
            _index = 117
        },
        {
            Done = { 30488 },
            coord = { x = 149.2, y = 2507.6 },
            ExtraLineText = "KILL_MOBS_TO_SAVE_NPC",
            Zone = 379,
            _index = 118
        },
        {
            PickUp = { 30491 },
            coord = { x = 149.2, y = 2507.6 },
            Zone = 379,
            _index = 119
        },
        {
            Qpart = { [30489] = { 1 } },
            coord = { x = 243.6, y = 2543.8 },
            ExtraLineText = "RIDE_YAK",
            Range = 60,
            Zone = 379,
            _index = 120
        },
        {
            PickUp = { 30587 },
            coord = { x = 474, y = 2559 },
            ExtraLineText = "KILL_BURILGI_DESPOILERS_TO_PICKUP_QUEST",
            Range = 30,
            Zone = 379,
            _index = 121
        },
        {
            Qpart = { [30804] = { 1 } },
            coord = { x = 593.4, y = 2531.3 },
            Fillers = { [30587] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 122
        },
        {
            Qpart = { [30491] = { 1 }, [30587] = { 1 } },
            coord = { x = 474, y = 2559 },
            ExtraLineText = "RIDE_YAK",
            ExtraLineText2 = "ONCE_ON_YAK_BRING_IT_BACK_TO_STABLE_AND_REPEAT_THAT_5_TIMES",
            Range = 60,
            Zone = 379,
            _index = 123
        },
        {
            Done = { 30491 },
            coord = { x = 374.6, y = 2726.6 },
            Zone = 379,
            _index = 124
        },
        {
            Done = { 30587, 30804, 30489 },
            coord = { x = 372.1, y = 2706.9 },
            Zone = 379,
            _index = 125
        },
        {
            PickUp = { 30492 },
            coord = { x = 373.3, y = 2728.8 },
            Zone = 379,
            _index = 126
        },
        {
            Qpart = { [30492] = { 1 } },
            coord = { x = 761.2, y = 3063.6 },
            Range = 5,
            Zone = 379,
            _index = 127
        },
        {
            Done = { 30492 },
            coord = { x = 789.2, y = 3043.8 },
            Zone = 379,
            _index = 128
        },
        {
            PickUp = { 30808 },
            coord = { x = 789.2, y = 3043.8 },
            Zone = 379,
            _index = 129
        },
        {
            PickUp = { 30614 },
            coord = { x = 742.5, y = 3080.3 },
            Zone = 379,
            _index = 130
        },
        {
            PickUp = { 30616 },
            coord = { x = 779, y = 3095 },
            Zone = 379,
            _index = 131
        },
        {
            Qpart = { [30614] = { 1 }, [30616] = { 1 }, [30808] = { 1 } },
            coord = { x = 922.6, y = 2775.7 },
            Range = 40,
            Zone = 379,
            _index = 132
        },
        {
            Done = { 30808 },
            coord = { x = 788.9, y = 3041 },
            Zone = 379,
            _index = 133
        },
        {
            Done = { 30614 },
            coord = { x = 741.4, y = 3080.5 },
            Zone = 379,
            _index = 134
        },
        {
            Done = { 30616 },
            coord = { x = 779.6, y = 3095.1 },
            Zone = 379,
            _index = 135
        },
        {
            PickUp = { 30617 },
            coord = { x = 779.6, y = 3095.1 },
            Zone = 379,
            _index = 136
        },
        {
            GetFP = 1018,
            coord = { x = 690.1, y = 3504.4 },
            Zone = 379,
            _index = 137
        },
        {
            Done = { 31393 },
            coord = { x = 538.5, y = 3823.9 },
            Zone = 379,
            _index = 138
        },
        {
            PickUp = { 31395 },
            coord = { x = 538.5, y = 3823.9 },
            Zone = 379,
            _index = 139
        },
        {
            Qpart = { [31395] = { 1 } },
            coord = { x = 528.8, y = 3833.2 },
            Range = 2,
            Zone = 379,
            _index = 140
        },
        {
            Qpart = { [31395] = { 2, 3, 4 } },
            coord = { x = 534.9, y = 3783.4 },
            Range = 5,
            ETA = 35,
            Zone = 379,
            _index = 141
        },
        {
            Done = { 31395 },
            coord = { x = 538.4, y = 3823.9 },
            Zone = 379,
            _index = 142
        },
        {
            PickUp = { 31511 },
            coord = { x = 538.4, y = 3823.9 },
            Zone = 379,
            _index = 143
        },
        {
            Waypoint = 30617,
            coord = { x = 849.1, y = 3154 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 144
        },
        {
            Waypoint = 30617,
            coord = { x = 895.8, y = 3109.9 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 145
        },
        {
            Waypoint = 30617,
            coord = { x = 894.1, y = 2993.1 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 146
        },
        {
            Waypoint = 30617,
            coord = { x = 916.7, y = 2923.1 },
            Fillers = { [30617] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 147
        },
        {
            Qpart = { [30617] = { 1 } },
            coord = { x = 1078.5, y = 2878 },
            Range = 30,
            Zone = 379,
            _index = 148
        },
        {
            Done = { 30617 },
            coord = { x = 1204, y = 3053.3 },
            Zone = 379,
            _index = 149
        },
        {
            PickUp = { 30592 },
            coord = { x = 1204, y = 3053.3 },
            Zone = 379,
            _index = 150
        },
        {
            Done = { 31459 },
            coord = { x = 1250.8, y = 3045 },
            Zone = 379,
            _index = 151
        },
        {
            PickUp = { 30999 },
            coord = { x = 1250.8, y = 3045 },
            Zone = 379,
            _index = 152
        },
        {
            Done = { 30999 },
            coord = { x = 1258.7, y = 3065.5 },
            Zone = 379,
            _index = 153
        },
        {
            PickUp = { 30601 },
            coord = { x = 1258.7, y = 3065.5 },
            Zone = 379,
            _index = 154
        },
        {
            PickUp = { 30621 },
            coord = { x = 1250.7, y = 3107.8 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 155
        },
        {
            SetHS = 30618,
            coord = { x = 1246.9, y = 3111.3 },
            Zone = 379,
            _index = 156
        },
        {
            GetFP = 1022,
            coord = { x = 1227.4, y = 3128.2 },
            Zone = 379,
            _index = 157
        },
        {
            PickUp = { 30618 },
            coord = { x = 1227.9, y = 3042.2 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 158
        },
        {
            Waypoint = 30621,
            coord = { x = 1135.3, y = 3396 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
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
            Waypoint = 30684,
            coord = { x = 2096.6, y = 3481.4 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 1,
            Zone = 379,
            _index = 177
        },
        {
            Done = { 30684 },
            coord = { x = 2099.2, y = 3488.5 },
            Zone = 379,
            _index = 178
        },
        {
            PickUp = { 30829 },
            coord = { x = 2099.2, y = 3488.5 },
            Zone = 379,
            _index = 179
        },
        {
            Qpart = { [30829] = { 1 } },
            coord = { x = 2118.3, y = 3474.5 },
            ExtraLineText = "TALK_TO_NPC_TO_START_QUEST",
            GossipOptionIDs = { 40517 },
            Range = 5,
            Zone = 379,
            _index = 180
        },
        {
            Done = { 30829 },
            coord = { x = 2100.9, y = 3485.9 },
            Zone = 379,
            _index = 181
        },
        {
            PickUp = { 30795 },
            coord = { x = 2100.9, y = 3485.9 },
            Zone = 379,
            _index = 182
        },
        {
            UseFlightPath = 30795,
            NodeID = 1022,
            coord = { x = 2102.1, y = 3477.2 },
            GossipOptionIDs = { 40519 },
            ETA = 31,
            Zone = 379,
            _index = 183
        },
        {
            Qpart = { [30795] = { 1 } },
            coord = { x = 1220.4, y = 3579.6 },
            Button = { ["30795-1"] = 81712 },
            Range = 5,
            Zone = 379,
            _index = 184
        },
        {
            Done = { 30795 },
            coord = { x = 1224, y = 3583.5 },
            Zone = 379,
            _index = 185
        },
        {
            PickUp = { 30796 },
            coord = { x = 1224, y = 3583.5 },
            Zone = 379,
            _index = 186
        },
        {
            PickUp = { 30797 },
            coord = { x = 1265.7, y = 3620.1 },
            Zone = 379,
            _index = 187
        },
        {
            Qpart = { [30797] = { 1 } },
            coord = { x = 1264.4, y = 3619.4 },
            Fillers = { [30796] = { 1 } },
            Zone = 379,
            _index = 188
        },
        {
            Qpart = { [30796] = { 1 } },
            coord = { x = 1290.9, y = 3641.9 },
            Range = 15,
            Zone = 379,
            _index = 189
        },
        {
            Done = { 30796, 30797 },
            coord = { x = 1224, y = 3584.7 },
            Button = { ["30796"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 190
        },
        {
            PickUp = { 30799 },
            coord = { x = 1224, y = 3584.7 },
            Button = { ["30799"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 191
        },
        {
            Waypoint = 30799,
            coord = { x = 1342.1, y = 3691.3 },
            Range = 5,
            Zone = 379,
            _index = 192
        },
        {
            Waypoint = 30799,
            coord = { x = 1300.8, y = 3759.3 },
            Range = 5,
            Zone = 379,
            _index = 193
        },
        {
            Qpart = { [30799] = { 3 } },
            coord = { x = 1268.1, y = 3739.4 },
            Zone = 379,
            _index = 194
        },
        {
            Qpart = { [30799] = { 1 } },
            coord = { x = 1263.6, y = 3803.8 },
            Zone = 379,
            _index = 195
        },
        {
            Qpart = { [30799] = { 2 } },
            coord = { x = 1311.7, y = 3806.3 },
            Zone = 379,
            _index = 196
        },
        {
            Waypoint = 30799,
            coord = { x = 1342.8, y = 3689.7 },
            Range = 5,
            Zone = 379,
            _index = 197
        },
        {
            Done = { 30799 },
            coord = { x = 1344.3, y = 3687 },
            Button = { ["30799"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 198
        },
        {
            PickUp = { 30798 },
            coord = { x = 1344.3, y = 3687 },
            Button = { ["30798"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 199
        },
        {
            Waypoint = 30798,
            coord = { x = 1501.5, y = 3563.4 },
            Range = 5,
            Zone = 379,
            _index = 200
        },
        {
            Qpart = { [30798] = { 1 } },
            coord = { x = 1524.9, y = 3476.5 },
            Range = 5,
            Zone = 379,
            _index = 201
        },
        {
            Waypoint = 30798,
            coord = { x = 1501.8, y = 3561.9 },
            Range = 5,
            Zone = 379,
            _index = 202
        },
        {
            Done = { 30798 },
            coord = { x = 1499.3, y = 3572.5 },
            Button = { ["30798"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 203
        },
        {
            PickUp = { 30800 },
            coord = { x = 1499.3, y = 3572.5 },
            Button = { ["30800"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 204
        },
        {
            Waypoint = 30800,
            coord = { x = 1524.2, y = 3675.1 },
            Range = 5,
            Zone = 379,
            _index = 205
        },
        {
            Waypoint = 30800,
            coord = { x = 1557.5, y = 3632.8 },
            Range = 5,
            Zone = 379,
            _index = 206
        },
        {
            Waypoint = 30800,
            coord = { x = 1564.8, y = 3605 },
            Range = 5,
            Zone = 379,
            _index = 207
        },
        {
            Waypoint = 30800,
            coord = { x = 1673.1, y = 3613.6 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 379,
            _index = 208
        },
        {
            Qpart = { [30800] = { 1 } },
            coord = { x = 1673.4, y = 3609.6 },
            Zone = 379,
            _index = 209
        },
        {
            Qpart = { [30800] = { 2 } },
            coord = { x = 1786.1, y = 3644.4 },
            Zone = 379,
            _index = 210
        },
        {
            Done = { 30800 },
            coord = { x = 1788.4, y = 3636.1 },
            Button = { ["30800"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 211
        },
        {
            PickUp = { 30801 },
            coord = { x = 1788.4, y = 3636.1 },
            Button = { ["30801"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 212
        },
        {
            Qpart = { [30801] = { 1 } },
            coord = { x = 1786, y = 3644.4 },
            Zone = 379,
            _index = 213
        },
        {
            Done = { 30801 },
            coord = { x = 1788, y = 3639.3 },
            Button = { ["30801"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 214
        },
        {
            PickUp = { 30802 },
            coord = { x = 1788, y = 3639.3 },
            Button = { ["30802"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 215
        },
        {
            Qpart = { [30802] = { 1 } },
            coord = { x = 1683.3, y = 3611.4 },
            Range = 30,
            Zone = 379,
            _index = 216
        },
        {
            Waypoint = 30802,
            coord = { x = 1560.3, y = 3596.5 },
            Range = 5,
            Zone = 379,
            _index = 217
        },
        {
            Waypoint = 30802,
            coord = { x = 1558.9, y = 3636.6 },
            Range = 5,
            Zone = 379,
            _index = 218
        },
        {
            Done = { 30802 },
            coord = { x = 1685.6, y = 3611.7 },
            Button = { ["30802"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 219
        },
        {
            PickUp = { 30935 },
            coord = { x = 1685.6, y = 3611.7 },
            Button = { ["30935"] = 81712 },
            ExtraLineText = "USE_THE_TONGUE_BA_SHON_TO_SPAWN_NPC",
            Zone = 379,
            _index = 220
        },
        {
            Qpart = { [30935] = { 1 } },
            coord = { x = 1524.7, y = 3683.1 },
            GossipOptionIDs = { 30224 },
            Zone = 379,
            _index = 221
        },
        {
            Waypoint = 30935,
            coord = { x = 839.2, y = 3766.2 },
            Range = 5,
            Zone = 379,
            _index = 222
        },
        {
            Waypoint = 30935,
            coord = { x = 850.6, y = 3802 },
            Range = 5,
            Zone = 379,
            _index = 223
        },
        {
            Waypoint = 30935,
            coord = { x = 886.7, y = 3811.9 },
            Range = 5,
            Zone = 379,
            _index = 224
        },
        {
            Qpart = { [30935] = { 2 } },
            coord = { x = 877.2, y = 3940.1 },
            GossipOptionIDs = { 30226 },
            Range = 2,
            Zone = 379,
            _index = 225
        },
        {
            Done = { 30935 },
            coord = { x = 938.6, y = 4404.9 },
            ETA = 131,
            Zone = 379,
            _index = 226
        },
        {
            PickUp = { 30944 },
            coord = { x = 938.6, y = 4404.9 },
            Zone = 379,
            _index = 227
        },
        {
            GetFP = 1021,
            coord = { x = 931.8, y = 4361.3 },
            Zone = 379,
            _index = 228
        },
        {
            PickUp = { 30945 },
            coord = { x = 873.9, y = 4339 },
            Zone = 379,
            _index = 229
        },
        {
            PickUp = { 30942 },
            coord = { x = 851.6, y = 4338.6 },
            Zone = 379,
            _index = 230
        },
        {
            PickUp = { 30816 },
            coord = { x = 886.2, y = 4393.2 },
            Zone = 379,
            _index = 231
        },
        {
            PickUp = { 30943 },
            coord = { x = 874.7, y = 4419.8 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 232
        },
        {
            Done = { 30816 },
            coord = { x = 1046.7, y = 4728.1 },
            Zone = 379,
            _index = 233
        },
        {
            PickUp = { 30794 },
            coord = { x = 1046.7, y = 4728.1 },
            Zone = 379,
            _index = 234
        },
        {
            Waypoint = 30794,
            coord = { x = 1021.3, y = 4720.1 },
            ExtraLineText = "LOOT_HEALING_POTION",
            Range = 1,
            Zone = 379,
            _index = 235
        },
        {
            Qpart = { [30794] = { 1 } },
            coord = { x = 1047, y = 4728.3 },
            Button = { ["30794-1"] = 81177 },
            ExtraLineText = "USE_POTION_OR_HEALING_SPELL",
            Zone = 379,
            _index = 236
        },
        {
            Done = { 30794 },
            coord = { x = 1047, y = 4728.3 },
            Zone = 379,
            _index = 237
        },
        {
            PickUp = { 30805, 30806, 30807 },
            coord = { x = 1047, y = 4728.3 },
            Zone = 379,
            _index = 238
        },
        {
            Qpart = { [30807] = { 1 } },
            coord = { x = 1139.1, y = 4481.5 },
            Fillers = { [30806] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 239
        },
        {
            Qpart = { [30805] = { 1 } },
            coord = { x = 950.1, y = 4619.1 },
            Fillers = { [30805] = { 2 }, [30806] = { 1, 2 } },
            Range = 5,
            Zone = 379,
            _index = 240
        },
        {
            Qpart = { [30805] = { 2 }, [30806] = { 2 } },
            coord = { x = 880.4, y = 4719.5 },
            Fillers = { [30806] = { 1 } },
            Range = 40,
            Zone = 379,
            _index = 241
        },
        {
            Qpart = { [30806] = { 1 } },
            coord = { x = 1090.9, y = 4724.7 },
            Range = 30,
            Zone = 379,
            _index = 242
        },
        {
            Done = { 30805, 30806, 30807 },
            coord = { x = 1047.4, y = 4727.5 },
            Zone = 379,
            _index = 243
        },
        {
            PickUp = { 30819 },
            coord = { x = 1047.4, y = 4727.5 },
            Zone = 379,
            _index = 244
        },
        {
            Qpart = { [30942] = { 1 }, [30944] = { 1 } },
            coord = { x = 967.9, y = 4428.1 },
            GossipOptionIDs = { 38591, 38585 },
            Range = 40,
            Zone = 379,
            _index = 245
        },
        {
            Done = { 30819 },
            coord = { x = 886.5, y = 4393.5 },
            Zone = 379,
            _index = 246
        },
        {
            PickUp = { 30820 },
            coord = { x = 886.5, y = 4393.5 },
            Zone = 379,
            _index = 247
        },
        {
            Qpart = { [30820] = { 1 } },
            coord = { x = 650.2, y = 4228.2 },
            Zone = 379,
            _index = 248
        },
        {
            Done = { 30820 },
            coord = { x = 643.9, y = 4227.3 },
            Zone = 379,
            _index = 249
        },
        {
            Qpart = { [30942] = { 2, 3 }, [30943] = { 1 } },
            coord = { x = 381.3, y = 4468.4 },
            Fillers = { [30945] = { 1 } },
            Range = 50,
            Zone = 379,
            _index = 250
        },
        {
            Done = { 30942 },
            NoArrow = 1,
            Zone = 379,
            _index = 251
        },
        {
            Qpart = { [30945] = { 1 } },
            coord = { x = 406.2, y = 4466 },
            Range = 50,
            Zone = 379,
            _index = 252
        },
        {
            Done = { 30945 },
            coord = { x = 874.9, y = 4334.6 },
            Zone = 379,
            _index = 253
        },
        {
            Done = { 30943 },
            coord = { x = 873.4, y = 4420.2 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 254
        },
        {
            Done = { 30944 },
            coord = { x = 939.7, y = 4405.5 },
            Zone = 379,
            _index = 255
        },
        {
            PickUp = { 31011 },
            coord = { x = 939.7, y = 4405.5 },
            Zone = 379,
            _index = 256
        },
        {
            Qpart = { [31011] = { 2 } },
            coord = { x = 1009.9, y = 4405 },
            Fillers = { [31011] = { 1 } },
            Range = 2,
            Zone = 379,
            _index = 257
        },
        {
            Qpart = { [31011] = { 3 } },
            coord = { x = 809.3, y = 4407.4 },
            Fillers = { [31011] = { 1 } },
            Range = 5,
            Zone = 379,
            _index = 258
        },
        {
            Qpart = { [31011] = { 1 } },
            coord = { x = 914.4, y = 4370.2 },
            Range = 40,
            Zone = 379,
            _index = 259
        },
        {
            Done = { 31011 },
            coord = { x = 939.3, y = 4405.9 },
            Zone = 379,
            _index = 260
        },
        {
            PickUp = { 30946 },
            coord = { x = 939.3, y = 4405.9 },
            Zone = 379,
            _index = 261
        },
        {
            Qpart = { [30946] = { 1 } },
            coord = { x = 929.9, y = 4415.1 },
            ExtraLineText = "UPSTAIRS",
            GossipOptionIDs = { 40352 },
            Zone = 379,
            _index = 262
        },
        {
            Done = { 30946 },
            coord = { x = 939.3, y = 4406.6 },
            Zone = 379,
            _index = 263
        },
        {
            PickUp = { 31228 },
            coord = { x = 939.3, y = 4406.6 },
            Zone = 379,
            _index = 264
        },
        {
            Qpart = { [31228] = { 1 } },
            coord = { x = 940.6, y = 4395 },
            GossipOptionIDs = { 41466 },
            Zone = 379,
            _index = 265
        },
        {
            Qpart = { [31228] = { 2 } },
            coord = { x = 58.6, y = 5235.3 },
            Fillers = { [31228] = { 3 } },
            ExtraLineText = "STAY_ON_TABLE_TO_AVOID_ZONE_DEBUFF",
            Range = 5,
            ETA = 32,
            Zone = 379,
            _index = 266
        },
        {
            Qpart = { [31228] = { 3 } },
            coord = { x = 72.8, y = 5066.1 },
            Range = 40,
            Zone = 379,
            _index = 267
        },
        {
            UseFlightPath = 31228,
            NodeID = 1021,
            coord = { x = 72.8, y = 5140.7 },
            GossipOptionIDs = { 40729 },
            ETA = 35,
            Zone = 379,
            _index = 268
        },
        {
            Done = { 31228 },
            coord = { x = 939.5, y = 4405.9 },
            Zone = 379,
            _index = 269
        },
        {
            UseHS = 30592,
            Zone = 379,
            _index = 270
        },
        {
            Qpart = { [30592] = { 1 } },
            ExtraLineText = "OPEN_YOUR_MAP_TO_SEE_WHERE_NPCS_TO_ESCORT",
            NoArrow = 1,
            Zone = 379,
            _index = 271
        },
        {
            Done = { 30592 },
            coord = { x = 1607, y = 2787.9 },
            Zone = 379,
            _index = 272
        },
        {
            PickUp = { 30602 },
            coord = { x = 1607, y = 2787.9 },
            Zone = 379,
            _index = 273
        },
        {
            Qpart = { [30602] = { 1 } },
            coord = { x = 1766.8, y = 2678.9 },
            Zone = 379,
            _index = 274
        },
        {
            PickUp = { 30603 },
            coord = { x = 1766.8, y = 2678.9 },
            Zone = 379,
            _index = 275
        },
        {
            Qpart = { [30603] = { 1 } },
            coord = { x = 1835.8, y = 2560.5 },
            Range = 5,
            Zone = 379,
            _index = 276
        },
        {
            Done = { 30602, 30603 },
            coord = { x = 1586.8, y = 2813.7 },
            Zone = 379,
            _index = 277
        },
        {
            PickUp = { 30599, 30600, 30604 },
            coord = { x = 1586.8, y = 2813.7 },
            Zone = 379,
            _index = 278
        },
        {
            Qpart = { [30599] = { 2 } },
            coord = { x = 1566.8, y = 2639.2 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_KO_KO_TO_LOOT_HIS_BODY_THEN_CLICK_ON_KNIFE_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 279
        },
        {
            Waypoint = 30599,
            coord = { x = 1532.7, y = 2645.5 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 280
        },
        {
            Qpart = { [30599] = { 1 } },
            coord = { x = 1549.2, y = 2577.3 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_DAK_DAK_TO_LOOT_HIS_BODY_THEN_CLICK_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 281
        },
        {
            Qpart = { [30599] = { 3 } },
            coord = { x = 1284.3, y = 2656.3 },
            Fillers = { [30600] = { 1 }, [30604] = { 1, 2 } },
            ExtraLineText = "KILL_TAK_TAK_TO_LOOT_HIS_BODY_THEN_CLICK_ON_KNIFE_ON_ALTAR_TO_DESTROY_IT",
            Range = 5,
            Zone = 379,
            _index = 282
        },
        {
            Qpart = { [30600] = { 1 }, [30604] = { 1, 2 } },
            coord = { x = 1531.1, y = 2677.1 },
            Range = 45,
            Zone = 379,
            _index = 283
        },
        {
            Done = { 30600, 30604, 30599 },
            coord = { x = 1587, y = 2814.7 },
            Zone = 379,
            _index = 284
        },
        {
            PickUp = { 30605 },
            coord = { x = 1587, y = 2814.7 },
            Zone = 379,
            _index = 285
        },
        {
            Qpart = { [30605] = { 1 } },
            coord = { x = 1677.7, y = 2940.2 },
            Zone = 379,
            _index = 286
        },
        {
            Done = { 30605 },
            coord = { x = 1675.4, y = 2944.8 },
            Zone = 379,
            _index = 287
        },
        {
            PickUp = { 30607, 30606, 30608 },
            coord = { x = 1675.4, y = 2944.8 },
            Zone = 379,
            _index = 288
        },
        {
            Qpart = { [30606] = { 1 }, [30608] = { 1 } },
            coord = { x = 1652.4, y = 2998.3 },
            Range = 30,
            Zone = 379,
            _index = 289
        },
        {
            Waypoint = 30606,
            coord = { x = 1685.2, y = 3037.4 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 290
        },
        {
            Waypoint = 30606,
            coord = { x = 1700.1, y = 3102.1 },
            Range = 5,
            Zone = 382,
            _index = 291
        },
        {
            Waypoint = 30606,
            coord = { x = 1754.8, y = 3082.7 },
            Range = 5,
            Zone = 382,
            _index = 292
        },
        {
            Qpart = { [30607] = { 1 } },
            coord = { x = 1782.5, y = 3149.8 },
            Range = 5,
            Zone = 382,
            _index = 293
        },
        {
            Qpart = { [30607] = { 2 } },
            coord = { x = 1764.6, y = 3141.3 },
            Zone = 382,
            _index = 294
        },
        {
            Done = { 30606, 30607, 30608 },
            coord = { x = 1584.8, y = 2813.9 },
            Zone = 379,
            _index = 295
        },
        {
            PickUp = { 30610, 30611 },
            coord = { x = 1584.8, y = 2813.9 },
            Zone = 379,
            _index = 296
        },
        {
            Qpart = { [30610] = { 1 }, [30611] = { 1 } },
            coord = { x = 1941.5, y = 2950.6 },
            Range = 30,
            Zone = 379,
            _index = 297
        },
        {
            Waypoint = 30610,
            coord = { x = 1976.2, y = 3035.9 },
            ExtraLineText = "INTERACT_WITH_SCROLL",
            Range = 2,
            Zone = 379,
            _index = 298
        },
        {
            Done = { 30610, 30611 },
            coord = { x = 1964.6, y = 2946.5 },
            Zone = 379,
            _index = 299
        },
        {
            PickUp = { 30612 },
            coord = { x = 1964.6, y = 2946.5 },
            Zone = 379,
            _index = 300
        },
        {
            Qpart = { [30612] = { 1, 2 } },
            coord = { x = 1960.1, y = 2979.9 },
            Range = 5,
            Zone = 379,
            _index = 301
        },
        {
            Done = { 30612 },
            coord = { x = 1586.3, y = 2813 },
            Zone = 379,
            _index = 302
        },
        {
            PickUp = { 30692 },
            coord = { x = 1606.5, y = 2788.6 },
            Zone = 379,
            _index = 303
        },
        {
            Qpart = { [30692] = { 1 } },
            ExtraLineText = "OPEN_YOUR_MAP_TO_SEE_WHERE_NPCS_TO_ESCORT",
            NoArrow = 1,
            Zone = 379,
            _index = 304
        },
        {
            GetFP = 1023,
            coord = { x = 2160.5, y = 2713.6 },
            Zone = 379,
            _index = 305
        },
        {
            SetHS = 30744,
            coord = { x = 2169.9, y = 2709.4 },
            Zone = 379,
            _index = 306
        },
        {
            PickUp = { 30744, 30745, 30742, 30743 },
            coord = { x = 2185.8, y = 2711.7 },
            Zone = 379,
            _index = 307
        },
        {
            Done = { 30692 },
            coord = { x = 2183, y = 2741.6 },
            Zone = 379,
            _index = 308
        },
        {
            Waypoint = 30744,
            coord = { x = 2492.2, y = 2365.9 },
            ExtraLineText = "GO_INSIDE_CAVE",
            Range = 5,
            Zone = 379,
            _index = 309
        },
        {
            Qpart = { [30744] = { 1 }, [30745] = { 1 } },
            coord = { x = 2546.9, y = 2409.3 },
            Fillers = { [30742] = { 1 }, [30743] = { 1 } },
            Button = { ["30744-1"] = 81054 },
            ExtraLineText = "INSIDE_CAVE",
            Range = 30,
            Zone = 379,
            _index = 310
        },
        {
            Done = { 30744 },
            NoArrow = 1,
            Zone = 379,
            _index = 311
        },
        {
            PickUp = { 30746 },
            NoArrow = 1,
            Zone = 379,
            _index = 312
        },
        {
            Waypoint = 30746,
            coord = { x = 2495, y = 2366.4 },
            Range = 5,
            Zone = 379,
            _index = 313
        },
        {
            Qpart = { [30742] = { 1 }, [30743] = { 1 } },
            coord = { x = 2470.4, y = 2522 },
            Range = 69,
            Zone = 379,
            _index = 314
        },
        {
            Waypoint = 30746,
            coord = { x = 2507.5, y = 2454.4 },
            Range = 5,
            Zone = 379,
            _index = 315
        },
        {
            Done = { 30746 },
            coord = { x = 2527.5, y = 2438.6 },
            Zone = 379,
            _index = 316
        },
        {
            Done = { 30745, 30742, 30743 },
            coord = { x = 2177, y = 2722.4 },
            ETA = 20,
            Zone = 379,
            _index = 317
        },
        {
            PickUp = { 30747 },
            coord = { x = 2180.8, y = 2724.4 },
            Zone = 379,
            _index = 318
        },
        {
            Qpart = { [30747] = { 1 } },
            coord = { x = 1711.8, y = 2784.4 },
            ExtraLineText = "TALK_TO_KOTA_KON_TO_GET_ON_HIS_BACK",
            GossipOptionIDs = { 34810 },
            Range = 100,
            Zone = 379,
            _index = 319
        },
        {
            Done = { 30747 },
            coord = { x = 2178.4, y = 2725.9 },
            Zone = 379,
            _index = 320
        },
        {
            Waypoint = 31453,
            coord = { x = 2020.6, y = 1864.1 },
            Range = 2,
            Zone = 379,
            _index = 321
        },
        {
            Done = { 31453 },
            coord = { x = 2056.3, y = 1866.5 },
            Zone = 379,
            _index = 322
        },
        {
            PickUp = { 30665, 30670 },
            coord = { x = 2056.3, y = 1866.5 },
            Zone = 379,
            _index = 323
        },
        {
            PickUp = { 30682 },
            coord = { x = 2152.2, y = 1932.9 },
            ExtraLineText = "INSIDE",
            Zone = 379,
            _index = 324
        },
        {
            Qpart = { [30682] = { 4 } },
            coord = { x = 2150.5, y = 1932.5 },
            ExtraLineText = "IF_SYA_ZHONG_IS_NOT_RESCUED_IMMEDIATELY_AFTER_ACCEPTING_QUEST_ABANDON_IT_AND_TAKE_IT_AGAIN",
            Zone = 379,
            _index = 325
        },
        {
            Qpart = { [30682] = { 2 } },
            coord = { x = 2270.7, y = 1988.9 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 37051 },
            Zone = 379,
            _index = 326
        },
        {
            Qpart = { [30682] = { 3 } },
            coord = { x = 2158.7, y = 2042.6 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 37052 },
            Zone = 379,
            _index = 327
        },
        {
            Qpart = { [30682] = { 1 } },
            coord = { x = 2093.5, y = 2023.5 },
            Fillers = { [30665] = { 1 }, [30670] = { 1 } },
            ExtraLineText = "INSIDE",
            GossipOptionIDs = { 35293 },
            Zone = 379,
            _index = 328
        },
        {
            Qpart = { [30670] = { 1 } },
            coord = { x = 2210.2, y = 1998.4 },
            Fillers = { [30665] = { 1 } },
            Range = 30,
            Zone = 379,
            _index = 329
        },
        {
            Qpart = { [30665] = { 1 } },
            coord = { x = 2051.1, y = 1933.4 },
            Range = 30,
            Zone = 379,
            _index = 330
        },
        {
            Done = { 30670, 30665, 30682 },
            coord = { x = 2055.9, y = 1867.1 },
            Zone = 379,
            _index = 331
        },
        {
            PickUp = { 30690 },
            coord = { x = 2055.9, y = 1867.1 },
            Zone = 379,
            _index = 332
        },
        {
            Qpart = { [30690] = { 1, 2 } },
            coord = { x = 1994.9, y = 2028 },
            Button = { ["30690-1"] = 81741 },
            ExtraLineText = "SET_UP_TRAP_AND_PULL_MOB_ONTO_IT_ONCE_TRAPPED_USE_YOUR_EXTRA_ACTION_BUTTON_TO_SPAWN_SHA",
            Range = 5,
            ExtraActionB = 1,
            Zone = 379,
            _index = 333
        },
        {
            Done = { 30690 },
            coord = { x = 2055.7, y = 1866.4 },
            Zone = 379,
            _index = 334
        },
        {
            PickUp = { 30699 },
            coord = { x = 2055.7, y = 1866.4 },
            Zone = 379,
            _index = 335
        },
        {
            GetFP = 1024,
            coord = { x = 2092, y = 1880.8 },
            ExtraLineText = "UP_TOWER",
            Zone = 379,
            _index = 336
        },
        {
            UseHS = 30699,
            Zone = 379,
            _index = 337
        },
        {
            Done = { 30699 },
            coord = { x = 2652.1, y = 3139.8 },
            Zone = 379,
            _index = 338
        },
        {
            PickUp = { 30723 },
            coord = { x = 2652.1, y = 3139.8 },
            Zone = 379,
            _index = 339
        },
        {
            PickUp = { 30715 },
            coord = { x = 2641.1, y = 3128.4 },
            Zone = 379,
            _index = 340
        },
        {
            GetFP = 1025,
            coord = { x = 2678.6, y = 3151.8 },
            Zone = 379,
            _index = 341
        },
        {
            PickUp = { 31847 },
            coord = { x = 2678.6, y = 3151.8 },
            Zone = 379,
            _index = 342
        },
        {
            Qpart = { [30715] = { 1 } },
            coord = { x = 2938.5, y = 3113.3 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 343
        },
        {
            Qpart = { [30715] = { 2 } },
            coord = { x = 2951.6, y = 3010.5 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 344
        },
        {
            Qpart = { [30715] = { 3 } },
            coord = { x = 2963.9, y = 2930.2 },
            Fillers = { [30723] = { 1 } },
            Zone = 379,
            _index = 345
        },
        {
            Qpart = { [30723] = { 1 } },
            coord = { x = 2919.3, y = 3010.3 },
            Range = 45,
            Zone = 379,
            _index = 346
        },
        {
            Done = { 30715 },
            coord = { x = 2641.7, y = 3129.5 },
            Zone = 379,
            _index = 347
        },
        {
            Done = { 30723 },
            coord = { x = 2652.7, y = 3144 },
            Zone = 379,
            _index = 348
        },
        {
            PickUp = { 30724 },
            coord = { x = 2652.7, y = 3144 },
            Zone = 379,
            _index = 349
        },
        {
            Qpart = { [30724] = { 1 } },
            coord = { x = 2677.5, y = 3151.3 },
            GossipOptionIDs = { 29681 },
            Range = 30,
            Zone = 379,
            _index = 350
        },
        {
            Done = { 30724 },
            coord = { x = 3005.8, y = 3018.5 },
            ETA = 14,
            Zone = 379,
            _index = 351
        },
        {
            PickUp = { 30750, 30751 },
            coord = { x = 3005.8, y = 3018.5 },
            Zone = 379,
            _index = 352
        },
        {
            Qpart = { [30750] = { 1 }, [30751] = { 1 } },
            coord = { x = 3135.2, y = 3094.9 },
            Range = 30,
            Zone = 379,
            _index = 353
        },
        {
            Done = { 30751, 30750 },
            coord = { x = 3007.6, y = 3019.7 },
            Zone = 379,
            _index = 354
        },
        {
            PickUp = { 30994 },
            coord = { x = 3007.6, y = 3019.7 },
            Zone = 379,
            _index = 355
        },
        {
            Qpart = { [30994] = { 1 } },
            coord = { x = 3006, y = 3020.2 },
            GossipOptionIDs = { 30541 },
            Range = 30,
            Zone = 379,
            _index = 356
        },
        {
            Done = { 30994 },
            coord = { x = 2848.5, y = 3110.8 },
            ETA = 6,
            Zone = 379,
            _index = 357
        },
        {
            PickUp = { 30991 },
            coord = { x = 2848.5, y = 3110.8 },
            Zone = 379,
            _index = 358
        },
        {
            Qpart = { [30991] = { 2 } },
            coord = { x = 2835.5, y = 3097 },
            ExtraLineText = "CLICK_ON_BARREL_TO_CONTROL_IT_AND_KILL_MOBS",
            Range = 2,
            Zone = 379,
            _index = 359
        },
        {
            Done = { 30991 },
            coord = { x = 2848.2, y = 3110.3 },
            Zone = 379,
            _index = 360
        },
        {
            PickUp = { 30992 },
            coord = { x = 2848.2, y = 3110.3 },
            Zone = 379,
            _index = 361
        },
        {
            Qpart = { [30992] = { 1 } },
            coord = { x = 2902.3, y = 3028.6 },
            Range = 5,
            Zone = 379,
            _index = 362
        },
        {
            Done = { 30992 },
            coord = { x = 2880.5, y = 3052 },
            Zone = 379,
            _index = 363
        },
        {
            PickUp = { 30993 },
            coord = { x = 2880.5, y = 3052 },
            Zone = 379,
            _index = 364
        },
        {
            Qpart = { [30993] = { 1 } },
            coord = { x = 2881, y = 3052.6 },
            GossipOptionIDs = { 29128 },
            Zone = 379,
            _index = 365
        },
        {
            Qpart = { [30993] = { 2 } },
            coord = { x = 2714.4, y = 3172.6 },
            GossipOptionIDs = { 29129 },
            Zone = 379,
            _index = 366
        },
        {
            Done = { 30993 },
            coord = { x = 2630, y = 3551.2 },
            Zone = 379,
            _index = 367
        },
        {
            PickUp = { 30752 },
            coord = { x = 2630, y = 3551.2 },
            Zone = 379,
            _index = 368
        },
        {
            Qpart = { [30752] = { 1 } },
            coord = { x = 2543.2, y = 3629.1 },
            GossipOptionIDs = { 41432 },
            Zone = 379,
            _index = 369
        },
        {
            Done = { 30752 },
            coord = { x = 2543.2, y = 3629.1 },
            Zone = 379,
            _index = 370
        },
        {
            PickUp = { 31030 },
            PickUpDB = { 31030, 31031 },
            coord = { x = 2543.2, y = 3629.1 },
            Zone = 379,
            _index = 371
        },
        {
            Done = { 31030 },
            DoneDB = { 31030, 31031 },
            ExtraLineText = "TURN_IN_QUEST_INSIDE_DUNGEON_THEN_EXIT",
            NoArrow = 1,
            _index = 372
        },
        {
            UseHS = 31511,
            Zone = 379,
            _index = 373
        },
        {
            Qpart = { [31511] = { 1 } },
            coord = { x = 1322.6, y = 1797.4 },
            GossipOptionIDs = { 41178 },
            Zone = 379,
            _index = 374
        },
        {
            Waypoint = 31511,
            coord = { x = 924.6, y = 1628.1 },
            ExtraLineText = "INSIDE",
            Range = 5,
            Zone = 390,
            _index = 375
        },
        {
            Waypoint = 31511,
            coord = { x = 897.5, y = 1684.2 },
            Range = 5,
            Zone = 391,
            _index = 376
        },
        {
            Done = { 31511 },
            coord = { x = 893.2, y = 1698.5 },
            Zone = 391,
            _index = 377
        },
        {
            UseFlightPath = 31695,
            NodeID = 1024,
            coord = { x = 889.5, y = 1579.9 },
            ETA = 111,
            Zone = 390,
            _index = 378
        },
        {
            GetFP = 1117,
            coord = { x = 2588.4, y = 2124.9 },
            Zone = 379,
            _index = 379
        },
        {
            GetFP = 1053,
            coord = { x = 2995.1, y = 2363.3 },
            Zone = 388,
            _index = 380
        },
        {
            RouteCompleted = 1,
            _index = 381
        }
    }

    APR.RouteQuestStepList["390-Isle of Thunder"] = {
        {
            PickUp = { 32678 },
            coord = { x = 887.3, y = 1473.4 },
            Zone = 390,
            _index = 1
        },
        {
            UseFlightPath = 32678,
            NodeID = 1055,
            coord = { x = 888.6, y = 1580.3 },
            ETA = 147,
            Zone = 390,
            _index = 2
        },
        {
            Done = { 32678 },
            coord = { x = 4161.9, y = 1748.4 },
            Zone = 388,
            _index = 3
        },
        {
            PickUp = { 32680 },
            coord = { x = 4161.9, y = 1748.4 },
            Zone = 388,
            _index = 4
        },
        {
            Qpart = { [32680] = { 1 } },
            coord = { x = 4161.9, y = 1748.4 },
            GossipOptionIDs = { 41771 },
            Zone = 388,
            _index = 5
        },
        {
            Done = { 32680 },
            coord = { x = 6481.2, y = 6704.2 },
            ETA = 96,
            Zone = 504,
            _index = 6
        },
        {
            PickUp = { 32212, 32709 },
            coord = { x = 6473, y = 6708.5 },
            Zone = 504,
            _index = 7
        },
        {
            Qpart = { [32212] = { 1 } },
            coord = { x = 6473, y = 6708.5 },
            GossipOptionIDs = { 41876 },
            Range = 2,
            RaidIcon = 70371,
            Zone = 504,
            _index = 8
        },
        {
            Qpart = { [32212] = { 2 } },
            coord = { x = 6300.5, y = 7176.8 },
            Range = 5,
            Zone = 516,
            _index = 9
        },
        {
            Done = { 32212 },
            coord = { x = 6309.7, y = 7167.5 },
            Zone = 504,
            _index = 10
        },
        {
            PickUp = { 32276 },
            coord = { x = 6309.7, y = 7167.5 },
            Zone = 504,
            _index = 11
        },
        {
            Qpart = { [32276] = { 1 } },
            coord = { x = 6309.7, y = 7167.5 },
            GossipOptionIDs = { 41877 },
            Zone = 504,
            _index = 12
        },
        {
            Qpart = { [32276] = { 2 } },
            coord = { x = 5390.9, y = 6884.3 },
            Range = 5,
            Zone = 516,
            _index = 13
        },
        {
            Waypoint = 32276,
            coord = { x = 5417.1, y = 6873.1 },
            ExtraLineText = "USE_GATE",
            Range = 3,
            InstanceQuest = true,
            Zone = 516,
            _index = 14
        },
        {
            Done = { 32276 },
            coord = { x = 6309.6, y = 7167.2 },
            Zone = 504,
            _index = 15
        },
        {
            PickUp = { 32277 },
            coord = { x = 6309.6, y = 7167.2 },
            Zone = 504,
            _index = 16
        },
        {
            Qpart = { [32277] = { 1 } },
            coord = { x = 6309.6, y = 7167.2 },
            GossipOptionIDs = { 41879 },
            Zone = 504,
            _index = 17
        },
        {
            Qpart = { [32277] = { 2 } },
            coord = { x = 5631, y = 7311.6 },
            Range = 5,
            Zone = 517,
            _index = 18
        },
        {
            Waypoint = 32277,
            coord = { x = 5619.1, y = 7264.4 },
            ExtraLineText = "USE_GATE",
            Range = 5,
            InstanceQuest = true,
            Zone = 517,
            _index = 19
        },
        {
            Done = { 32277 },
            coord = { x = 6293.2, y = 7250.1 },
            Zone = 504,
            _index = 20
        },
        {
            PickUp = { 32278 },
            coord = { x = 6294.2, y = 7247.1 },
            RaidIcon = 70297,
            Zone = 504,
            _index = 21
        },
        {
            Qpart = { [32278] = { 1 } },
            coord = { x = 6294.2, y = 7247.1 },
            GossipOptionIDs = { 41662 },
            Zone = 516,
            _index = 22
        },
        {
            Waypoint = 32278,
            coord = { x = 5264.3, y = 6993.7 },
            ExtraLineText = "USE_GATE",
            Range = 5,
            InstanceQuest = true,
            Zone = 516,
            _index = 23
        },
        {
            Done = { 32278 },
            coord = { x = 6309.6, y = 7167.1 },
            Zone = 504,
            _index = 24
        },
        {
            PickUp = { 32279 },
            coord = { x = 6309.6, y = 7167.1 },
            Zone = 504,
            _index = 25
        },
        {
            Qpart = { [32279] = { 1 } },
            coord = { x = 6309.6, y = 7167.1 },
            GossipOptionIDs = { 41878 },
            RaidIcon = 67990,
            Zone = 504,
            _index = 26
        },
        {
            Qpart = { [32279] = { 2 } },
            coord = { x = 5183.9, y = 7097 },
            GossipOptionIDs = { 41897 },
            Range = 5,
            Zone = 516,
            _index = 27
        },
        {
            Waypoint = 32279,
            coord = { x = 5304.3, y = 7033.2 },
            ExtraLineText = "USE_GATE",
            Range = 5,
            InstanceQuest = true,
            Zone = 516,
            _index = 28
        },
        {
            Done = { 32279 },
            coord = { x = 6309.7, y = 7166.9 },
            Zone = 504,
            _index = 29
        },
        {
            Waypoint = 32709,
            coord = { x = 6044.7, y = 6945.3 },
            Range = 5,
            Zone = 504,
            _index = 30
        },
        {
            Waypoint = 32709,
            coord = { x = 5547, y = 6848.4 },
            Range = 5,
            Zone = 504,
            _index = 31
        },
        {
            Done = { 32709 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 32
        },
        {
            PickUp = { 32707 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 33
        },
        {
            Qpart = { [32707] = { 1 } },
            coord = { x = 5659.3, y = 6427.5 },
            ExtraLineText = "LOOK_FOR_RARES_AND_TREASURE_CHESTS_ON_ISLAND",
            Range = 600,
            Zone = 504,
            _index = 34
        },
        {
            Done = { 32707 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 35
        },
        {
            PickUp = { 32708 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 36
        },
        {
            Waypoint = 32708,
            coord = { x = 5397.1, y = 6048.7 },
            Range = 5,
            Zone = 504,
            _index = 37
        },
        {
            Qpart = { [32708] = { 1, 2 } },
            coord = { x = 5372.7, y = 5730.5 },
            Range = 1,
            Zone = 504,
            _index = 38
        },
        {
            Qpart = { [32708] = { 2 } },
            coord = { x = 5384.1, y = 5723.5 },
            Range = 5,
            Zone = 504,
            _index = 39
        },
        {
            Done = { 32708 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 40
        },
        {
            PickUp = { 32641 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 41
        },
        {
            Qpart = { [32641] = { 1, 2, 3 } },
            coord = { x = 5659.3, y = 6427.5 },
            ExtraLineText = "YOU_NEED_3_SHANZE_RITUAL_STONE_FOR_EACH_OBJECTIVE",
            Range = 600,
            Zone = 504,
            _index = 42
        },
        {
            Done = { 32641 },
            coord = { x = 5527.6, y = 6877.5 },
            Zone = 504,
            _index = 43
        },
        {
            RouteCompleted = 1,
            _index = 44
        }
    }
end
