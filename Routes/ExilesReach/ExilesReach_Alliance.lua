if APR.Faction == "Alliance" then
    APR.RouteQuestStepList["1409-Exile's Reach"] = {
        {
            PickUp = { 56775 },
            _index = 1
        },
        {
            Qpart = { [56775] = { 1 } },
            _index = 2
        },
        {
            Done = { 56775 },
            _index = 3
        },
        {
            PickUp = { 58209 },
            _index = 4
        },
        {
            Qpart = { [58209] = { 1 } },
            RaidIcon = 157051,
            _index = 5
        },
        {
            Done = { 58209 },
            _index = 6
        },
        {
            PickUp = { 58208 },
            _index = 7
        },
        {
            Done = { 58208 },
            _index = 8
        },
        {
            PickUp = { 55122 },
            _index = 9
        },
        {
            Qpart = { [55122] = { 1 } },
            coord = { x = -2563.2, y = -359.8 },
            Range = 24.31,
            _index = 10
        },
        {
            Done = { 55122 },
            coord = { x = -2610.4, y = -434.7 },
            _index = 11
        },
        {
            PickUp = { 54951 },
            coord = { x = -2610.4, y = -434.7 },
            _index = 12
        },
        {
            Qpart = { [54951] = { 2 } },
            coord = { x = -2605.5, y = -447.9 },
            Button = { ["54951-2"] = 168410 },
            Range = 0.75,
            RaidIcon = 156612,
            _index = 13
        },
        {
            Qpart = { [54951] = { 3 } },
            coord = { x = -2593.7, y = -428.7 },
            Button = { ["54951-3"] = 168410 },
            Range = 0.61,
            RaidIcon = 156610,
            _index = 14
        },
        {
            Qpart = { [54951] = { 1 } },
            coord = { x = -2599.5, y = -420.4 },
            Button = { ["54951-1"] = 168410 },
            Range = 0.69,
            RaidIcon = 156609,
            _index = 15
        },
        {
            Done = { 54951 },
            coord = { x = -2610.4, y = -434.4 },
            _index = 16
        },
        {
            PickUp = { 54952 },
            coord = { x = -2610.4, y = -434.4 },
            _index = 17
        },
        {
            Qpart = { [54952] = { 1 } },
            coord = { x = -2493, y = -273.9 },
            Range = 0.61,
            _index = 18
        },
        {
            Done = { 54952 },
            coord = { x = -2491.5, y = -245.2 },
            _index = 19
        },
        {
            PickUp = { 55174 },
            coord = { x = -2492, y = -249.2 },
            _index = 20
        },
        {
            Qpart = { [55174] = { 1 } },
            coord = { x = -2498.7, y = -182.4 },
            Range = 38.75,
            _index = 21
        },
        {
            Qpart = { [55174] = { 2 } },
            coord = { x = -2490.5, y = -247.4 },
            Range = 0.69,
            _index = 22
        },
        {
            Done = { 55174 },
            coord = { x = -2491.7, y = -244.7 },
            _index = 23
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "DRUID" },
            _index = 24
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2522, y = -211 },
            Range = 0.61,
            Class = { "DRUID" },
            _index = 25
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "DRUID" },
            _index = 26
        },
        {
            PickUp = { 55173 },
            coord = { x = -2491.5, y = -245 },
            Class = { "HUNTER" },
            _index = 27
        },
        {
            Done = { 55173 },
            coord = { x = -2638.9, y = -141 },
            Class = { "HUNTER" },
            _index = 28
        },
        {
            PickUp = { 59342 },
            coord = { x = -2638.9, y = -141 },
            Class = { "HUNTER" },
            _index = 29
        },
        {
            Qpart = { [59342] = { 2 } },
            coord = { x = -2574.5, y = -170 },
            Range = 64.18,
            Class = { "HUNTER" },
            _index = 30
        },
        {
            Done = { 59342 },
            coord = { x = -2638.9, y = -140.7 },
            Class = { "HUNTER" },
            _index = 31
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "MAGE" },
            _index = 32
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2464.7, y = -196.7 },
            Range = 0.61,
            Class = { "MAGE" },
            _index = 33
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "MAGE" },
            _index = 34
        },
        {
            PickUp = { 59339 },
            coord = { x = -2492.4, y = -248 },
            Class = { "MONK" },
            _index = 35
        },
        {
            Qpart = { [59339] = { 1, 2 } },
            coord = { x = -2481.4, y = -194 },
            Range = 0.69,
            Class = { "MONK" },
            RaidIcon = 164577,
            _index = 36
        },
        {
            Done = { 59339 },
            coord = { x = -2492, y = -249.2 },
            Class = { "MONK" },
            _index = 37
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "PALADIN" },
            _index = 38
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2522, y = -211 },
            Range = 0.61,
            Class = { "PALADIN" },
            _index = 39
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "PALADIN" },
            _index = 40
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "PRIEST" },
            _index = 41
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2478.7, y = -221.5 },
            Range = 0.61,
            Class = { "PRIEST" },
            _index = 42
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "PRIEST" },
            _index = 43
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "ROGUE" },
            _index = 44
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2524, y = -224.2 },
            Range = 0.61,
            Class = { "ROGUE" },
            _index = 45
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "ROGUE" },
            _index = 46
        },
        {
            PickUp = { 55173 },
            coord = { x = -2491.5, y = -245 },
            Class = { "ROGUE" },
            _index = 47
        },
        {
            Done = { 55173 },
            coord = { x = -2638.9, y = -141 },
            Class = { "ROGUE" },
            _index = 48
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "SHAMAN" },
            _index = 49
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2471.9, y = -207.2 },
            Range = 0.61,
            Class = { "SHAMAN" },
            _index = 50
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "SHAMAN" },
            _index = 51
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "WARLOCK" },
            _index = 52
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2478.7, y = -221.5 },
            Range = 0.61,
            Class = { "WARLOCK" },
            _index = 53
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "WARLOCK" },
            _index = 54
        },
        {
            PickUp = { 59254 },
            coord = { x = -2492.7, y = -247.7 },
            Class = { "WARRIOR" },
            _index = 55
        },
        {
            Qpart = { [59254] = { 1 } },
            coord = { x = -2464.7, y = -196.7 },
            Range = 0.61,
            Class = { "WARRIOR" },
            _index = 56
        },
        {
            Done = { 59254 },
            coord = { x = -2491.5, y = -248.9 },
            Class = { "WARRIOR" },
            _index = 57
        },
        {
            PickUp = { 55173 },
            coord = { x = -2491.5, y = -245 },
            _index = 58
        },
        {
            Done = { 55173 },
            coord = { x = -2638.9, y = -141 },
            _index = 59
        },
        {
            PickUp = { 55186, 55184 },
            coord = { x = -2638.9, y = -140.7 },
            _index = 60
        },
        {
            Waypoint = 625675186,
            coord = { x = -2641.2, y = -77 },
            Fillers = { [55184] = { 1 } },
            Range = 15.15,
            _index = 61
        },
        {
            Waypoint = 625675186,
            coord = { x = -2577.2, y = 45.1 },
            Fillers = { [55184] = { 1 } },
            Range = 10.87,
            _index = 62
        },
        {
            Qpart = { [55184] = { 1 } },
            coord = { x = -2559.2, y = 43.1 },
            Range = 30,
            _index = 63
        },
        {
            Qpart = { [55186] = { 1 } },
            coord = { x = -2512.5, y = 15.6 },
            Range = 0.69,
            RaidIcon = 151091,
            _index = 64
        },
        {
            Waypoint = 625675186,
            coord = { x = -2496.7, y = 49.1 },
            Range = 15.09,
            _index = 65
        },
        {
            Done = { 55186, 55184 },
            coord = { x = -2419.4, y = 100.7 },
            _index = 66
        },
        {
            PickUp = { 55193 },
            coord = { x = -2417.5, y = 101.4 },
            _index = 67
        },
        {
            Qpart = { [55193] = { 1 } },
            coord = { x = -2413.5, y = 108.3 },
            Range = 0.75,
            RaidIcon = 156518,
            _index = 68
        },
        {
            Done = { 55193 },
            coord = { x = -2417.7, y = 101.7 },
            _index = 69
        },
        {
            PickUp = { 56034 },
            coord = { x = -2417.7, y = 101.7 },
            _index = 70
        },
        {
            Qpart = { [56034] = { 1 } },
            coord = { x = -2440.4, y = 118.8 },
            Button = { ["56034-1"] = 170557 },
            Range = 29.47,
            _index = 71
        },
        {
            Done = { 56034 },
            coord = { x = -2420.4, y = 103.3 },
            _index = 72
        },
        {
            PickUp = { 55879 },
            coord = { x = -2420.4, y = 103.3 },
            _index = 73
        },
        {
            Qpart = { [55879] = { 1 } },
            coord = { x = -2428.2, y = 115.3 },
            Range = 0.75,
            _index = 74
        },
        {
            Qpart = { [55879] = { 2 } },
            coord = { x = -2300.7, y = 212.6 },
            Range = 33.81,
            _index = 75
        },
        {
            Qpart = { [55879] = { 3 } },
            coord = { x = -2245.5, y = 244.1 },
            Range = 0.75,
            RaidIcon = 162817,
            _index = 76
        },
        {
            Done = { 55879 },
            coord = { x = -2296.4, y = 231.5 },
            _index = 77
        },
        {
            Waypoint = 625675194,
            coord = { x = -2279.7, y = 231.8 },
            Range = 3.3,
            _index = 78
        },
        {
            PickUp = { 55194 },
            coord = { x = -2288, y = 187 },
            _index = 79
        },
        {
            Qpart = { [55194] = { 1, 2 } },
            coord = { x = -2284.2, y = 187.3 },
            Range = 0.75,
            RaidIcon = 156800,
            _index = 80
        },
        {
            Done = { 55194 },
            coord = { x = -2288.4, y = 187.1 },
            _index = 81
        },
        {
            PickUp = { 55965 },
            coord = { x = -2310.5, y = 192.3 },
            _index = 82
        },
        {
            PickUp = { 55196 },
            coord = { x = -2327.7, y = 254.1 },
            _index = 83
        },
        {
            Done = { 55196 },
            coord = { x = -2439.7, y = 392.6 },
            _index = 84
        },
        {
            PickUp = { 55763, 55881, 55764 },
            coord = { x = -2441.4, y = 391.8 },
            _index = 85
        },
        {
            Waypoint = 625675763,
            coord = { x = -2423.9, y = 492.1 },
            Fillers = { [55764] = { 1 }, [55881] = { 1 } },
            Range = 8.77,
            _index = 86
        },
        {
            Qpart = { [55763] = { 1 } },
            coord = { x = -2353.5, y = 496.1 },
            Fillers = { [55764] = { 1 }, [55881] = { 1 } },
            Range = 0.75,
            Gossip = 1,
            RaidIcon = 153211,
            _index = 87
        },
        {
            Qpart = { [55764] = { 1 }, [55881] = { 1 } },
            coord = { x = -2507.5, y = 496.1 },
            Range = 54.1,
            Gossip = 1,
            _index = 88
        },
        {
            Done = { 55763, 55764, 55881 },
            coord = { x = -2441.5, y = 392.3 },
            _index = 89
        },
        {
            PickUp = { 55882 },
            coord = { x = -2439.7, y = 392.7 },
            _index = 90
        },
        {
            PickUp = { 54933 },
            coord = { x = -2485.7, y = 302.3 },
            _index = 91
        },
        {
            Qpart = { [54933] = { 1 } },
            coord = { x = -2460.5, y = 313.8 },
            Range = 0.75,
            _index = 92
        },
        {
            Qpart = { [54933] = { 2 } },
            coord = { x = -2495.4, y = 325.3 },
            Range = 0.69,
            _index = 93
        },
        {
            Qpart = { [54933] = { 3 } },
            coord = { x = -2513.2, y = 291.6 },
            Range = 0.69,
            _index = 94
        },
        {
            Qpart = { [54933] = { 4 } },
            coord = { x = -2473.5, y = 280 },
            Range = 0.75,
            _index = 95
        },
        {
            Done = { 54933 },
            coord = { x = -2484.7, y = 302.2 },
            _index = 96
        },
        {
            Done = { 55882 },
            coord = { x = -2288.7, y = 186.9 },
            _index = 97
        },
        {
            PickUp = { 59355 },
            coord = { x = -2290.9, y = 188.1 },
            Class = { "HUNTER" },
            _index = 98
        },
        {
            Qpart = { [59355] = { 1 } },
            coord = { x = -2285.5, y = 183.8 },
            Range = 0.75,
            Class = { "HUNTER" },
            Gossip = 1,
            RaidIcon = 156886,
            _index = 99
        },
        {
            Qpart = { [59355] = { 2 } },
            coord = { x = -2283.9, y = 237.8 },
            Range = 0.69,
            Class = { "HUNTER" },
            _index = 100
        },
        {
            Qpart = { [59355] = { 3 } },
            coord = { x = -2270.7, y = 270 },
            Range = 0.69,
            Class = { "HUNTER" },
            _index = 101
        },
        {
            Done = { 59355 },
            coord = { x = -2290.5, y = 187.8 },
            Class = { "HUNTER" },
            _index = 102
        },
        {
            PickUp = { 59356 },
            coord = { x = -2290.5, y = 187.8 },
            Class = { "HUNTER" },
            _index = 103
        },
        {
            Qpart = { [59356] = { 1 } },
            coord = { x = -2273, y = 228.8 },
            Range = 18.66,
            Class = { "HUNTER" },
            _index = 104
        },
        {
            Done = { 59356 },
            coord = { x = -2290, y = 188.6 },
            Class = { "HUNTER" },
            _index = 105
        },
        {
            PickUp = { 60168 },
            coord = { x = -2290, y = 188.6 },
            Class = { "HUNTER" },
            _index = 106
        },
        {
            Qpart = { [60168] = { 1 } },
            coord = { x = -2289.2, y = 189.4 },
            Range = 0.75,
            Class = { "HUNTER" },
            _index = 107
        },
        {
            Qpart = { [60168] = { 2 } },
            coord = { x = -2290.7, y = 188.6 },
            Range = 0.69,
            Class = { "HUNTER" },
            Gossip = 2,
            RaidIcon = 161666,
            _index = 108
        },
        {
            Qpart = { [60168] = { 3 } },
            coord = { x = -2290, y = 188.8 },
            Range = 0.75,
            Class = { "HUNTER" },
            Gossip = 1,
            _index = 109
        },
        {
            Done = { 60168 },
            coord = { x = -2290, y = 188.8 },
            Class = { "HUNTER" },
            _index = 110
        },
        {
            PickUp = { 59352 },
            coord = { x = -2285.7, y = 183.5 },
            Class = { "MAGE" },
            _index = 111
        },
        {
            Qpart = { [59352] = { 1 } },
            coord = { x = -2274.7, y = 310.3 },
            Range = 0.61,
            Class = { "MAGE" },
            _index = 112
        },
        {
            Done = { 59352 },
            coord = { x = -2286.2, y = 182.9 },
            Class = { "MAGE" },
            _index = 113
        },
        {
            PickUp = { 59354 },
            coord = { x = -2286.2, y = 184.1 },
            Class = { "MAGE" },
            _index = 114
        },
        {
            Qpart = { [59354] = { 1 } },
            coord = { x = -2286.2, y = 184.1 },
            Range = 0.75,
            Class = { "MAGE" },
            Gossip = 1,
            _index = 115
        },
        {
            Qpart = { [59354] = { 2 } },
            coord = { x = -2332.2, y = 178.9 },
            Range = 0.69,
            Class = { "MAGE" },
            _index = 116
        },
        {
            Done = { 59354 },
            coord = { x = -2286, y = 183.8 },
            Class = { "MAGE" },
            _index = 117
        },
        {
            PickUp = { 59347 },
            coord = { x = -2281.2, y = 179.6 },
            Class = { "MONK" },
            _index = 118
        },
        {
            Qpart = { [59347] = { 1 } },
            coord = { x = -2297.5, y = 317.5 },
            Range = 0.75,
            Class = { "MONK" },
            Gossip = 1,
            RaidIcon = 164835,
            _index = 119
        },
        {
            Done = { 59347 },
            coord = { x = -2298.5, y = 318.3 },
            Class = { "MONK" },
            _index = 120
        },
        {
            PickUp = { 59349 },
            coord = { x = -2298.5, y = 318.3 },
            Class = { "MONK" },
            _index = 121
        },
        {
            Qpart = { [59349] = { 1 } },
            coord = { x = -2325.7, y = 309 },
            Range = 0.75,
            Class = { "MONK" },
            RaidIcon = 164868,
            _index = 122
        },
        {
            Done = { 59349 },
            coord = { x = -2288.7, y = 186.6 },
            Class = { "MONK" },
            _index = 123
        },
        {
            PickUp = { 58923 },
            coord = { x = -2279, y = 187.6 },
            Class = { "PALADIN" },
            _index = 124
        },
        {
            Waypoint = 625678923,
            coord = { x = -2398.5, y = 347.5 },
            Range = 12.06,
            Class = { "PALADIN" },
            _index = 125
        },
        {
            Waypoint = 625678923,
            coord = { x = -2444.2, y = 313.5 },
            Range = 8.18,
            Class = { "PALADIN" },
            _index = 126
        },
        {
            Qpart = { [58923] = { 1 } },
            coord = { x = -2464.7, y = 257.5 },
            Range = 0.75,
            Class = { "PALADIN" },
            Gossip = 1,
            RaidIcon = 162998,
            _index = 127
        },
        {
            Done = { 58923 },
            coord = { x = -2464.7, y = 257.5 },
            Class = { "PALADIN" },
            _index = 128
        },
        {
            PickUp = { 58946 },
            coord = { x = -2464.7, y = 257.5 },
            Class = { "PALADIN" },
            _index = 129
        },
        {
            Qpart = { [58946] = { 1 } },
            coord = { x = -2463.7, y = 258.5 },
            Range = 0.75,
            Class = { "PALADIN" },
            _index = 130
        },
        {
            Qpart = { [58946] = { 2 } },
            coord = { x = -2450, y = 246.6 },
            Range = 0.69,
            Class = { "PALADIN" },
            _index = 131
        },
        {
            Done = { 58946 },
            coord = { x = -2464.5, y = 256.6 },
            Class = { "PALADIN" },
            _index = 132
        },
        {
            PickUp = { 58953 },
            coord = { x = -2279.5, y = 187.8 },
            Class = { "PRIEST" },
            _index = 133
        },
        {
            Qpart = { [58953] = { 1 } },
            coord = { x = -2415.2, y = 221.9 },
            Range = 0.69,
            Class = { "PRIEST" },
            _index = 134
        },
        {
            Done = { 58953 },
            coord = { x = -2415.2, y = 221.9 },
            Class = { "PRIEST" },
            _index = 135
        },
        {
            PickUp = { 58960 },
            coord = { x = -2415.2, y = 221.9 },
            Class = { "PRIEST" },
            _index = 136
        },
        {
            Qpart = { [58960] = { 1 } },
            coord = { x = -2419.7, y = 228.1 },
            Range = 5.28,
            Class = { "PRIEST" },
            _index = 137
        },
        {
            Done = { 58960 },
            coord = { x = -2415.5, y = 223.4 },
            Class = { "PRIEST" },
            _index = 138
        },
        {
            PickUp = { 58917 },
            coord = { x = -2279.4, y = 187.9 },
            Class = { "ROGUE" },
            _index = 139
        },
        {
            Qpart = { [58917] = { 1 } },
            coord = { x = -2061.7, y = 168.9 },
            Range = 0.69,
            Class = { "ROGUE" },
            Gossip = 1,
            RaidIcon = 162972,
            _index = 140
        },
        {
            Qpart = { [58917] = { 2 } },
            coord = { x = -2038.6, y = 185 },
            Range = 9.76,
            Class = { "ROGUE" },
            _index = 141
        },
        {
            Done = { 58917 },
            coord = { x = -2061.5, y = 168.6 },
            Class = { "ROGUE" },
            _index = 142
        },
        {
            PickUp = { 58933 },
            coord = { x = -2061.5, y = 168.6 },
            Class = { "ROGUE" },
            _index = 143
        },
        {
            Qpart = { [58933] = { 1 } },
            coord = { x = -2063.5, y = 175.5 },
            Range = 0.75,
            Class = { "ROGUE" },
            _index = 144
        },
        {
            Qpart = { [58933] = { 2 } },
            coord = { x = -2159.2, y = 270.7 },
            Range = 0.69,
            Class = { "ROGUE" },
            RaidIcon = 163036,
            _index = 145
        },
        {
            Done = { 58933 },
            coord = { x = -2279.7, y = 187.4 },
            Class = { "ROGUE" },
            _index = 146
        },
        {
            PickUp = { 59002 },
            coord = { x = -2286.7, y = 179.6 },
            Class = { "SHAMAN" },
            _index = 147
        },
        {
            Qpart = { [59002] = { 1 } },
            coord = { x = -2288.9, y = 276.1 },
            Range = 10.81,
            Class = { "SHAMAN" },
            _index = 148
        },
        {
            Qpart = { [59002] = { 2 } },
            coord = { x = -2284, y = 180.9 },
            Range = 0.69,
            Class = { "SHAMAN" },
            _index = 149
        },
        {
            Qpart = { [59002] = { 3 } },
            coord = { x = -2352.7, y = 148 },
            Range = 23.61,
            Class = { "SHAMAN" },
            _index = 150
        },
        {
            Done = { 59002 },
            coord = { x = -2286.9, y = 179.8 },
            Class = { "SHAMAN" },
            _index = 151
        },
        {
            PickUp = { 58962 },
            coord = { x = -2279.2, y = 187.6 },
            Class = { "WARLOCK" },
            _index = 152
        },
        {
            Waypoint = 625678962,
            coord = { x = -2344.5, y = 354.6 },
            Range = 11.53,
            Class = { "WARLOCK" },
            _index = 153
        },
        {
            Qpart = { [58962] = { 1 } },
            coord = { x = -2295.2, y = 398.8 },
            Range = 0.75,
            Class = { "WARLOCK" },
            Gossip = 1,
            RaidIcon = 163209,
            _index = 154
        },
        {
            Qpart = { [58962] = { 2 } },
            coord = { x = -2296.7, y = 399.8 },
            Range = 0.61,
            Class = { "WARLOCK" },
            _index = 155
        },
        {
            Qpart = { [58962] = { 3 } },
            coord = { x = -2296.7, y = 399.8 },
            Button = { ["58962-3"] = 174947 },
            Range = 0.61,
            Class = { "WARLOCK" },
            _index = 156
        },
        {
            Done = { 58962 },
            coord = { x = -2297.2, y = 409.5 },
            Class = { "WARLOCK" },
            _index = 157
        },
        {
            PickUp = { 58914 },
            coord = { x = -2279.4, y = 188.1 },
            Class = { "WARRIOR" },
            _index = 158
        },
        {
            Waypoint = 625678914,
            coord = { x = -2331.5, y = 272.8 },
            Range = 20.09,
            Class = { "WARRIOR" },
            _index = 159
        },
        {
            Waypoint = 625678914,
            coord = { x = -2346.9, y = 352.8 },
            Range = 10.6,
            Class = { "WARRIOR" },
            _index = 160
        },
        {
            Done = { 58914 },
            coord = { x = -2257.4, y = 355.8 },
            Class = { "WARRIOR" },
            _index = 161
        },
        {
            PickUp = { 58915 },
            coord = { x = -2257.4, y = 355.8 },
            Class = { "WARRIOR" },
            _index = 162
        },
        {
            Qpart = { [58915] = { 1 } },
            coord = { x = -2257.4, y = 355.8 },
            Range = 0.61,
            Class = { "WARRIOR" },
            RaidIcon = 162948,
            _index = 163
        },
        {
            Done = { 58915 },
            coord = { x = -2279.5, y = 187.8 },
            Class = { "WARRIOR" },
            _index = 164
        },
        {
            Done = { 55965 },
            coord = { x = -2248.9, y = 90.3 },
            _index = 165
        },
        {
            PickUp = { 55639 },
            coord = { x = -2246.5, y = 92.5 },
            _index = 166
        },
        {
            Qpart = { [55639] = { 1 } },
            coord = { x = -2240, y = 71 },
            Range = 70.21,
            _index = 167
        },
        {
            Waypoint = 625675639,
            coord = { x = -2214.2, y = 83.3 },
            Range = 7.92,
            _index = 168
        },
        {
            Qpart = { [55639] = { 2 } },
            coord = { x = -2127.5, y = 72.5 },
            Range = 0.69,
            RaidIcon = 156900,
            _index = 169
        },
        {
            Qpart = { [55639] = { 3 } },
            coord = { x = -2134.5, y = 75.3 },
            Range = 0.75,
            _index = 170
        },
        {
            Done = { 55639 },
            coord = { x = -2288.7, y = 186 },
            _index = 171
        },
        {
            PickUp = { 59350 },
            coord = { x = -2287.7, y = 184 },
            Class = { "DRUID" },
            _index = 172
        },
        {
            Qpart = { [59350] = { 1 } },
            coord = { x = -2053, y = 323.1 },
            Range = 0.69,
            Class = { "DRUID" },
            _index = 173
        },
        {
            Done = { 59350 },
            coord = { x = -2056.2, y = 324 },
            Class = { "DRUID" },
            _index = 174
        },
        {
            PickUp = { 56344 },
            coord = { x = -2288.7, y = 186 },
            _index = 175
        },
        {
            PickUp = { 56839 },
            coord = { x = -2168, y = 211.5 },
            _index = 176
        },
        {
            Qpart = { [56839] = { 1 } },
            coord = { x = -2058.4, y = 205.1 },
            Range = 0.61,
            RaidIcon = 153266,
            _index = 177
        },
        {
            Done = { 56839 },
            coord = { x = -1986.5, y = 280.8 },
            _index = 178
        },
        {
            Waypoint = 625676344,
            coord = { x = -2060.4, y = 217.4 },
            Range = 17.88,
            _index = 179
        },
        {
            Waypoint = 625676344,
            coord = { x = -2128, y = 219.6 },
            Range = 20.92,
            _index = 180
        },
        {
            Done = { 56344 },
            coord = { x = -2174.7, y = 323.5 },
            _index = 181
        },
        {
            PickUp = { 55981 },
            coord = { x = -2174.7, y = 323.5 },
            _index = 182
        },
        {
            Qpart = { [55981] = { 1 } },
            coord = { x = -2176.5, y = 324.6 },
            Range = 0.69,
            Gossip = 1,
            RaidIcon = 156943,
            _index = 183
        },
        {
            Qpart = { [55981] = { 2 } },
            coord = { x = -2044.8, y = 457.3 },
            Range = 0.69,
            _index = 184
        },
        {
            Qpart = { [55981] = { 3 } },
            coord = { x = -2063, y = 575.4 },
            Range = 0.75,
            Emote = "HUG",
            _index = 185
        },
        {
            Qpart = { [55981] = { 4 } },
            coord = { x = -2062.5, y = 586.4 },
            Range = 0.75,
            Emote = "WAVE",
            _index = 186
        },
        {
            Waypoint = 625675981,
            coord = { x = -2076.2, y = 619 },
            Range = 11.9,
            _index = 187
        },
        {
            Done = { 55981 },
            coord = { x = -1876.8, y = 704.2 },
            _index = 188
        },
        {
            PickUp = { 55988, 55990, 55989 },
            coord = { x = -1877.6, y = 703.9 },
            _index = 189
        },
        {
            Waypoint = 625675990,
            coord = { x = -2012.4, y = 616.5 },
            Range = 27.27,
            _index = 190
        },
        {
            Qpart = { [55990] = { 2 } },
            coord = { x = -2009.4, y = 592.5 },
            Range = 0.69,
            RaidIcon = 153582,
            _index = 191
        },
        {
            Qpart = { [55990] = { 1 } },
            coord = { x = -2127, y = 659.4 },
            Fillers = { [55988] = { 1 }, [55989] = { 1 } },
            Range = 0.75,
            RaidIcon = 153583,
            _index = 192
        },
        {
            Qpart = { [55990] = { 3 } },
            coord = { x = -1965, y = 511.7 },
            Fillers = { [55988] = { 1 }, [55989] = { 1 } },
            Range = 0.69,
            _index = 193
        },
        {
            Qpart = { [55989] = { 1 } },
            coord = { x = -2039.5, y = 505.7 },
            Fillers = { [55988] = { 1 } },
            Range = 59.07,
            _index = 194
        },
        {
            Qpart = { [55988] = { 1 } },
            coord = { x = -2085.2, y = 608.9 },
            Range = 49.21,
            _index = 195
        },
        {
            Done = { 55989, 55988 },
            coord = { x = -1879.3, y = 704.2 },
            _index = 196
        },
        {
            Qpart = { [55990] = { 4 } },
            coord = { x = -1869.5, y = 708.9 },
            Range = 5.99,
            _index = 197
        },
        {
            Done = { 55990 },
            coord = { x = -1869, y = 709 },
            _index = 198
        },
        {
            PickUp = { 55992 },
            coord = { x = -1869, y = 709 },
            _index = 199
        },
        {
            Qpart = { [55992] = { 1 } },
            coord = { x = -1869, y = 709 },
            Range = 0.69,
            _index = 200
        },
        {
            Done = { 55992 },
            coord = { x = -1858.5, y = 713.5 },
            _index = 201
        },
        {
            PickUp = { 55991 },
            coord = { x = -1858.5, y = 713.5 },
            _index = 202
        },
        {
            Qpart = { [55991] = { 1 } },
            coord = { x = -1882.6, y = 698.6 },
            Range = 0.75,
            _index = 203
        },
        {
            Done = { 55991 },
            coord = { x = 442, y = -9055 },
            Zone = 84,
            _index = 204
        },
        {
            coord = { x = 442, y = -9055 },
            ExtraLineText = "YES_TO_EXIT_TUTORIAL",
            ExitTutorial = 62567,
            Gossip = 1,
            Zone = 84,
            _index = 205
        },
        {
            Waypoint = 62567,
            coord = { x = 513.4, y = -8962.3 },
            Range = 5,
            Zone = 84,
            _index = 206
        },
        {
            Waypoint = 62567,
            coord = { x = 502.8, y = -8920.7 },
            Range = 5,
            Zone = 84,
            _index = 207
        },
        {
            Waypoint = 62567,
            coord = { x = 545.4, y = -8922.8 },
            Range = 5,
            Zone = 84,
            _index = 208
        },
        {
            Waypoint = 62567,
            coord = { x = 624.1, y = -8837.4 },
            Range = 5,
            Zone = 84,
            _index = 209
        },
        {
            SetHS = 34398,
            coord = { x = 670.5, y = -8866.2 },
            Zone = 84,
            _index = 210
        },
        {
            Waypoint = 62567,
            coord = { x = 589.9, y = -8796.1 },
            Range = 5,
            Zone = 84,
            _index = 211
        },
        {
            Waypoint = 62567,
            coord = { x = 606.7, y = -8769.2 },
            Range = 5,
            Zone = 84,
            _index = 212
        },
        {
            Waypoint = 62567,
            coord = { x = 575.3, y = -8736.8 },
            Range = 5,
            Zone = 84,
            _index = 213
        },
        {
            Waypoint = 62567,
            coord = { x = 558.5, y = -8745.6 },
            Range = 5,
            Zone = 84,
            _index = 214
        },
        {
            Waypoint = 62567,
            coord = { x = 523.2, y = -8709 },
            Range = 5,
            Zone = 84,
            _index = 215
        },
        {
            Waypoint = 62567,
            coord = { x = 555.1, y = -8659 },
            Range = 5,
            Zone = 84,
            _index = 216
        },
        {
            Waypoint = 62567,
            coord = { x = 516.4, y = -8612.2 },
            Range = 5,
            Zone = 84,
            _index = 217
        },
        {
            Waypoint = 62567,
            coord = { x = 541.9, y = -8579.6 },
            Range = 5,
            Zone = 84,
            _index = 218
        },
        {
            Waypoint = 62567,
            coord = { x = 504.6, y = -8541.9 },
            Range = 5,
            Zone = 84,
            _index = 219
        },
        {
            Waypoint = 62567,
            coord = { x = 624.3, y = -8408.3 },
            Range = 5,
            Zone = 84,
            _index = 220
        },
        {
            Waypoint = 62567,
            coord = { x = 649.2, y = -8332 },
            Range = 5,
            Zone = 84,
            _index = 221
        },
        {
            Done = { 62567 },
            coord = { x = 745.9, y = -8196.3 },
            Zone = 84,
            _index = 222
        },
        {
            RouteCompleted = 1,
            _index = 223
        }
    }
end
