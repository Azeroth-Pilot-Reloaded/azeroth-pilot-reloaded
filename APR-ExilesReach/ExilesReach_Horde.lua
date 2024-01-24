if (APR.Faction == "Horde") then
    APR.RouteQuestStepList["1409-Exile's Reach"] = {
        {
            PickUp = {
                59926,
            },
        },
        {
            Qpart = {
                [59926] = { 1 },
            },
        },
        {
            Done = {
                59926,
            },
        },
        {
            PickUp = {
                59927,
            },
        },
        {
            Qpart = {
                [59927] = { 1 },
            },
            RaidIcon = 166814,
        },
        {
            Done = {
                59927,
            },
        },
        {
            PickUp = {
                59928,
            },
        },
        {
            Done = {
                59928,
            },
        },
        {
            PickUp = {
                59929,
            },
            Coord = {
                x = -2610.2,
                y = -434.7,
            },
        },
        {
            Qpart = {
                [59929] = { 1 },
            },
            Range = 38.11,
            Coord = {
                x = -2561.9,
                y = -365.9,
            },
        },
        {
            Coord = {
                x = -2610.2,
                y = -434.4,
            },
            Done = {
                59929,
            },
        },
        {
            PickUp = {
                59930,
            },
            Coord = {
                x = -2610.2,
                y = -434.4,
            },
        },
        {
            Qpart = {
                [59930] = { 2 },
            },
            Button = {
                ["59930-2"] = 168410,
            },
            RaidIcon = 166786,
            Range = 0.75,
            Coord = {
                x = -2605.7,
                y = -447.5,
            },
        },
        {
            Qpart = {
                [59930] = { 3 },
            },
            Button = {
                ["59930-3"] = 168410,
            },
            RaidIcon = 166791,
            Range = 0.61,
            Coord = {
                x = -2593.7,
                y = -428.4,
            },
        },
        {
            Qpart = {
                [59930] = { 1 },
            },
            Button = {
                ["59930-1"] = 168410,
            },
            RaidIcon = 166796,
            Range = 0.69,
            Coord = {
                x = -2599.7,
                y = -420.4,
            },
        },
        {
            Done = {
                59930,
            },
            RaidIcon = 166782,
            Coord = {
                x = -2610.4,
                y = -434.8,
            },
        },
        {
            PickUp = {
                59931,
            },
            Coord = {
                x = -2610.4,
                y = -434.8,
            },
        },
        {
            Qpart = {
                [59931] = { 1, 4 },
            },
            Range = 0.61,
            Coord = {
                x = -2492.9,
                y = -247.9,
            },
        },
        {
            Coord = {
                x = -2491.2,
                y = -245.5,
            },
            Done = {
                59931,
            },
        },
        {
            PickUp = {
                59932,
            },
            Coord = {
                x = -2492.5,
                y = -248.5,
            },
        },
        {
            Qpart = {
                [59932] = { 1 },
            },
            Range = 37.96,
            Coord = {
                x = -2477.5,
                y = -184,
            },
        },
        {
            Qpart = {
                [59932] = { 2 },
            },
            Range = 0.61,
            Coord = {
                x = -2490.4,
                y = -247.2,
            },
        },
        {
            Coord = {
                x = -2491.5,
                y = -245,
            },
            Done = {
                59932,
            },
        },
        --- Class Quest
        -- Druid
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "DRUID"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "DRUID"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "DRUID"
        },
        -- Hunter
        {
            PickUp = {
                59937,
            },
            Coord = {
                x = -2638.9,
                y = -141,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59937] = { 2 },
            },
            Range = 64.18,
            Coord = {
                x = -2574.5,
                y = -170,
            },
            Class = "HUNTER"
        },
        {
            Coord = {
                x = -2638.9,
                y = -140.7,
            },
            Done = {
                59937,
            },
            Class = "HUNTER"
        },
        -- Mage
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "MAGE"
        },
        -- Monk
        {
            PickUp = {
                59934,
            },
            Coord = {
                x = -2492.4,
                y = -248,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59934] = {
                    1,
                    2,
                },
            },
            RaidIcon = 164577,
            Range = 0.69,
            Coord = {
                x = -2481.4,
                y = -194,
            },
            Class = "MONK"
        },
        {
            Coord = {
                x = -2492,
                y = -249.2,
            },
            Done = {
                59934,
            },
            Class = "MONK"
        },
        -- Paladin
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "PALADIN"
        },
        -- Priest
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "PRIEST"
        },
        -- Rogue
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "ROGUE"
        },
        -- Shaman
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "SHAMAN"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "SHAMAN"
        },
        -- Warlock
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "WARLOCK"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "WARLOCK"
        },
        -- Warrior
        {
            PickUp = {
                59933,
            },
            Coord = {
                x = -2492,
                y = -249,
            },
            Class = "WARRIOR"
        },
        {
            Qpart = {
                [59933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2482.5,
                y = -235.4,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                x = -2492,
                y = -248.9,
            },
            Done = {
                59933,
            },
            Class = "WARRIOR"
        },
        --- End Class Quest
        {
            PickUp = {
                59935,
            },
            Coord = {
                x = -2491.9,
                y = -245,
            },
        },
        {
            Coord = {
                x = -2638.4,
                y = -141.2,
            },
            Done = {
                59935,
            },
        },
        {
            PickUp = {
                59938,
                59939,
            },
            Coord = {
                x = -2638.4,
                y = -141.2,
            },
        },
        {
            Waypoint = 59938,
            Fillers = {
                [59939] = { 1 },
            },
            Range = 14.94,
            Coord = {
                x = -2641.2,
                y = -76.9,
            },
        },
        {
            Waypoint = 59938,
            Fillers = {
                [59939] = { 1 },
            },
            Range = 16.13,
            Coord = {
                x = -2578.2,
                y = 43.5,
            },
        },
        {
            Qpart = {
                [59938] = { 1 },
            },
            Fillers = {
                [59939] = { 1 },
            },
            RaidIcon = 151091,
            Range = 0.61,
            Coord = {
                x = -2513,
                y = 16.1,
            },
        },
        {
            Qpart = {
                [59939] = { 1 },
            },
            Range = 65.49,
            Coord = {
                x = -2580.5,
                y = 50.5,
            },
        },
        {
            Coord = {
                x = -2419,
                y = 101,
            },
            Done = {
                59938,
                59939,
            },
        },
        {
            PickUp = {
                59940,
            },
            Coord = {
                x = -2417.9,
                y = 101.3,
            },
        },
        {
            Qpart = {
                [59940] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2412.5,
                y = 107.8,
            },
        },
        {
            Coord = {
                x = -2417.5,
                y = 101,
            },
            Done = {
                59940,
            },
        },
        {
            PickUp = {
                59941,
            },
            Coord = {
                x = -2417.5,
                y = 101,
            },
        },
        {
            Qpart = {
                [59941] = { 1 },
            },
            Button = {
                ["59941-1"] = 178051,
            },
            Range = 28.36,
            Coord = {
                x = -2444.4,
                y = 134.6,
            },
        },
        {
            Coord = {
                x = -2420.4,
                y = 103.4,
            },
            Done = {
                59941,
            },
        },
        {
            PickUp = {
                59942,
            },
            Coord = {
                x = -2417.7,
                y = 101.2,
            },
        },
        {
            Qpart = {
                [59942] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2414.2,
                y = 108.5,
            },
        },
        {
            Qpart = {
                [59942] = { 2 },
            },
            Range = 170.21,
            Coord = {
                x = -2414.2,
                y = 108.5,
            },
        },
        {
            Qpart = {
                [59942] = { 3 },
            },
            RaidIcon = 162817,
            Range = 0.61,
            Coord = {
                x = -2243.4,
                y = 244.1,
            },
        },
        {
            Done = {
                59942,
            },
            RaidIcon = 167128,
            Coord = {
                x = -2296.2,
                y = 231.1,
            },
        },
        {
            Range = 8.65,
            Waypoint = 59950,
            Coord = {
                x = -2275.5,
                y = 231.8,
            },
        },
        {
            PickUp = {
                59950,
            },
            Coord = {
                x = -2282.5,
                y = 186.6,
            },
        },
        {
            Qpart = {
                [59950] = { 1, 2 },
            },
            RaidIcon = 167213,
            Range = 0.69,
            Coord = {
                x = -2292,
                y = 179.4,
            },
        },
        {
            Coord = {
                x = -2282.5,
                y = 186.4,
            },
            Done = {
                59950,
            },
        },
        {
            PickUp = {
                59943,
            },
            Coord = {
                x = -2337,
                y = 257.7,
            },
        },
        {
            Coord = {
                x = -2443.2,
                y = 391.5,
            },
            Done = {
                59943,
            },
        },
        {
            PickUp = {
                59945,
                59944,
                59946,
            },
            Coord = {
                x = -2441.7,
                y = 392.3,
            },
        },
        {
            Qpart = {
                [59944] = { 1 },
            },
            Fillers = {
                [59945] = { 1 },
            },
            Gossip = 1,
            Range = 0.75,
            Coord = {
                x = -2354.2,
                y = 496.1,
            },
        },
        {
            Qpart = {
                [59946] = { 1 },
                [59945] = { 1 },
            },
            Gossip = 1,
            Range = 38.88,
            Coord = {
                x = -2518.9,
                y = 466.3,
            },
        },
        {
            Coord = {
                x = -2442.2,
                y = 392.3,
            },
            Done = {
                59945,
                59944,
                59946,
            },
        },
        {
            PickUp = {
                59947,
            },
            Coord = {
                x = -2439.7,
                y = 392.7,
            },
        },
        {
            PickUp = {
                54933,
            },
            Coord = {
                x = -2485.5,
                y = 302.7,
            },
        },
        {
            Qpart = {
                [54933] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2460.4,
                y = 313.7,
            },
        },
        {
            Qpart = {
                [54933] = { 2 },
            },
            Range = 0.75,
            Coord = {
                x = -2495.5,
                y = 325.3,
            },
        },
        {
            Qpart = {
                [54933] = { 3 },
            },
            Range = 0.61,
            Coord = {
                x = -2513.2,
                y = 291.3,
            },
        },
        {
            Qpart = {
                [54933] = { 4 },
            },
            Range = 0.69,
            Coord = {
                x = -2473.5,
                y = 279.8,
            },
        },
        {
            Coord = {
                x = -2485.7,
                y = 301.8,
            },
            Done = {
                54933,
            },
        },
        {
            Coord = {
                x = -2282.4,
                y = 186.1,
            },
            Done = {
                59947,
            },
        },
        {
            PickUp = {
                59948,
            },
            Coord = {
                x = -2307.2,
                y = 161.1,
            },
        },
        {
            Done = {
                59948,
            },
            RaidIcon = 167225,
            Coord = {
                x = -2246.4,
                y = 92.5,
            },
        },
        {
            PickUp = {
                59949,
            },
            Coord = {
                x = -2246.4,
                y = 92.5,
            },
        },
        {
            Qpart = {
                [59949] = { 1 },
            },
            Range = 17.9,
            Coord = {
                x = -2228,
                y = 85,
            },
        },
        {
            Range = 6.36,
            Waypoint = 59949,
            Coord = {
                x = -2213.5,
                y = 82.9,
            },
        },
        {
            Qpart = {
                [59949] = { 2 },
            },
            RaidIcon = 156900,
            Range = 0.75,
            Coord = {
                x = -2126.7,
                y = 72.5,
            },
        },
        {
            Qpart = {
                [59949] = { 3 },
            },
            Range = 0.75,
            Coord = {
                x = -2134,
                y = 75.3,
            },
        },
        {
            Coord = {
                x = -2282.5,
                y = 186.5,
            },
            Done = {
                59949,
            },
        },
        --- Class Quest Start
        -- Druid
        {
            PickUp = {
                59951,
            },
            Coord = {
                x = -2287.7,
                y = 184,
            },
            Class = "DRUID"
        },
        {
            Qpart = {
                [59951] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -2053,
                y = 323.1,
            },
            Class = "DRUID"
        },
        {
            Coord = {
                x = -2056.2,
                y = 324,
            },
            Done = {
                59951,
            },
            Class = "DRUID"
        },
        -- Hunter
        {
            PickUp = {
                59952,
            },
            Coord = {
                x = -2290.9,
                y = 188.1,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59952] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 156886,
            Range = 0.75,
            Coord = {
                x = -2285.5,
                y = 183.8,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59952] = { 2 },
            },
            Range = 0.69,
            Coord = {
                x = -2283.9,
                y = 237.8,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59952] = { 3 },
            },
            Range = 0.69,
            Coord = {
                x = -2270.7,
                y = 270,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                59952,
            },
            Coord = {
                x = -2290.5,
                y = 187.8,
            },
            Class = "HUNTER"
        },
        {
            PickUp = {
                59953,
            },
            Coord = {
                x = -2290.5,
                y = 187.8,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59953] = { 1 },
            },
            Range = 18.66,
            Coord = {
                x = -2273,
                y = 228.8,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                59953,
            },
            Coord = {
                x = -2290,
                y = 188.6,
            },
            Class = "HUNTER"
        },
        {
            PickUp = {
                60162,
            },
            Coord = {
                x = -2290,
                y = 188.6,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60162] = { 1 },
            },
            Range = 0.75,
            Coord = {
                x = -2289.2,
                y = 189.4,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60162] = { 2 },
            },
            Gossip = 2,
            RaidIcon = 161666,
            Range = 0.69,
            Coord = {
                x = -2290.7,
                y = 188.6,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60162] = { 3 },
            },
            Gossip = 1,
            Range = 0.75,
            Coord = {
                x = -2290,
                y = 188.8,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                60162,
            },
            Coord = {
                x = -2290,
                y = 188.8,
            },
            Class = "HUNTER"
        },
        -- Mage
        {
            PickUp = {
                59954,
            },
            Coord = {
                x = -2285.7,
                y = 183.5,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59954] = { 1 },
            },
            Range = 0.61,
            Coord = {
                x = -2274.7,
                y = 310.3,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                x = -2286.2,
                y = 182.9,
            },
            Done = {
                59954,
            },
            Class = "MAGE"
        },
        {
            PickUp = {
                59955,
            },
            Coord = {
                x = -2286.2,
                y = 184.1,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59955] = { 1 },
            },
            Gossip = 1,
            Range = 0.75,
            Coord = {
                x = -2286.2,
                y = 184.1,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59955] = { 2 },
            },
            Range = 0.69,
            Coord = {
                x = -2332.2,
                y = 178.9,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                x = -2286,
                y = 183.8,
            },
            Done = {
                59955,
            },
            Class = "MAGE"
        },
        -- Monk
        {
            PickUp = {
                59956,
            },
            Coord = {
                x = -2281.2,
                y = 179.6,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59956] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 164835,
            Range = 0.75,
            Coord = {
                x = -2297.5,
                y = 317.5,
            },
            Class = "MONK"
        },
        {
            Coord = {
                x = -2298.5,
                y = 318.3,
            },
            Done = {
                59956,
            },
            Class = "MONK"
        },
        {
            PickUp = {
                59957,
            },
            Coord = {
                x = -2298.5,
                y = 318.3,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59957] = { 1 },
            },
            RaidIcon = 164868,
            Range = 0.75,
            Coord = {
                x = -2325.7,
                y = 309,
            },
            Class = "MONK"
        },
        {
            Coord = {
                x = -2288.7,
                y = 186.6,
            },
            Done = {
                59957,
            },
            Class = "MONK"
        },
        -- Paladin
        {
            PickUp = {
                59958,
            },
            Coord = {
                x = -2279,
                y = 187.6,
            },
            Class = "PALADIN"
        },
        {
            Range = 12.06,
            Waypoint = 59958,
            Coord = {
                x = -2398.5,
                y = 347.5,
            },
            Class = "PALADIN"
        },
        {
            Range = 8.18,
            Waypoint = 59958,
            Coord = {
                x = -2444.2,
                y = 313.5,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [59958] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 162998,
            Range = 0.75,
            Coord = {
                x = -2464.7,
                y = 257.5,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                x = -2464.7,
                y = 257.5,
            },
            Done = {
                59958,
            },
            Class = "PALADIN"
        },
        {
            PickUp = {
                60174,
            },
            Coord = {
                x = -2464.7,
                y = 257.5,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [60174] = { 1 },
            },
            Range = 0.75,
            Coord = {
                x = -2463.7,
                y = 258.5,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [60174] = { 2 },
            },
            Range = 0.69,
            Coord = {
                x = -2450,
                y = 246.6,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                x = -2464.5,
                y = 256.6,
            },
            Done = {
                60174,
            },
            Class = "PALADIN"
        },
        -- Priest
        {
            PickUp = {
                59961,
            },
            Coord = {
                x = -2277.5,
                y = 184.1,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [59961] = { 1 },
            },
            RaidIcon = 167188,
            Range = 0.75,
            Coord = {
                x = -2415.2,
                y = 223.3,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                x = -2415.2,
                y = 223.3,
            },
            Done = {
                59961,
            },
            Class = "PRIEST"
        },
        {
            PickUp = {
                59965,
            },
            Coord = {
                x = -2415.2,
                y = 223.3,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [59965] = { 1 },
            },
            Range = 5.29,
            Coord = {
                x = -2421.7,
                y = 227.8,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                x = -2415.2,
                y = 224.1,
            },
            Done = {
                59965,
            },
            Class = "PRIEST"
        },
        -- Rogue
        {
            PickUp = {
                59967,
            },
            Coord = {
                x = -2279.4,
                y = 187.9,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59967] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 162972,
            Range = 0.69,
            Coord = {
                x = -2061.7,
                y = 168.9,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59967] = { 2 },
            },
            Range = 9.76,
            Coord = {
                x = -2038.6,
                y = 185,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                x = -2061.5,
                y = 168.6,
            },
            Done = {
                59967,
            },
            Class = "ROGUE"
        },
        {
            PickUp = {
                59968,
            },
            Coord = {
                x = -2061.5,
                y = 168.6,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59968] = { 1 },
            },
            Range = 0.75,
            Coord = {
                x = -2063.5,
                y = 175.5,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59968] = { 2 },
            },
            RaidIcon = 163036,
            Range = 0.69,
            Coord = {
                x = -2159.2,
                y = 270.7,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                x = -2279.7,
                y = 187.4,
            },
            Done = {
                59968,
            },
            Class = "ROGUE"
        },
        -- Shaman
        {
            PickUp = {
                59969,
            },
            Coord = {
                x = -2286.7,
                y = 179.6,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59969] = { 1 },
            },
            Range = 10.81,
            Coord = {
                x = -2288.9,
                y = 276.1,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59969] = { 2 },
            },
            Range = 0.69,
            Coord = {
                x = -2284,
                y = 180.9,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59969] = { 3 },
            },
            Range = 23.61,
            Coord = {
                x = -2352.7,
                y = 148,
            },
            Class = "SHAMAN"
        },
        {
            Coord = {
                x = -2286.9,
                y = 179.8,
            },
            Done = {
                59969,
            },
            Class = "SHAMAN"
        },
        -- Warlock
        {
            PickUp = {
                59970,
            },
            Coord = {
                x = -2279.2,
                y = 187.6,
            },
            Class = "WARLOCK"
        },
        {
            Range = 11.53,
            Waypoint = 59970,
            Coord = {
                x = -2344.5,
                y = 354.6,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [59970] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 163209,
            Range = 0.75,
            Coord = {
                x = -2295.2,
                y = 398.8,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [59970] = { 2 },
            },
            Range = 0.61,
            Coord = {
                x = -2296.7,
                y = 399.8,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [59970] = { 3 },
            },
            Button = {
                ["59970-3"] = 174947,
            },
            Range = 0.61,
            Coord = {
                x = -2296.7,
                y = 399.8,
            },
            Class = "WARLOCK"
        },
        {
            Coord = {
                x = -2297.2,
                y = 409.5,
            },
            Done = {
                59970,
            },
            Class = "WARLOCK"
        },
        -- Warrior
        {
            PickUp = {
                59971,
            },
            Coord = {
                x = -2279.4,
                y = 188.1,
            },
            Class = "WARRIOR"
        },
        {
            Range = 20.09,
            Waypoint = 59971,
            Coord = {
                x = -2331.5,
                y = 272.8,
            },
            Class = "WARRIOR"
        },
        {
            Range = 10.6,
            Waypoint = 59971,
            Coord = {
                x = -2346.9,
                y = 352.8,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                x = -2257.4,
                y = 355.8,
            },
            Done = {
                59971,
            },
            Class = "WARRIOR"
        },
        {
            PickUp = {
                59972,
            },
            Coord = {
                x = -2257.4,
                y = 355.8,
            },
            Class = "WARRIOR"
        },
        {
            Qpart = {
                [59972] = { 1 },
            },
            RaidIcon = 162948,
            Range = 0.61,
            Coord = {
                x = -2257.4,
                y = 355.8,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                x = -2279.5,
                y = 187.8,
            },
            Done = {
                59972,
            },
            Class = "WARRIOR"
        },
        --- Class Quest End
        {
            PickUp = {
                59975,
            },
            Coord = {
                x = -2284,
                y = 186.1,
            },
        },
        {
            PickUp = {
                56839,
            },
            Coord = {
                x = -2168,
                y = 211.5,
            },
        },
        {
            Qpart = {
                [56839] = { 1 },
            },
            RaidIcon = 153266,
            Range = 0.61,
            Coord = {
                x = -2058.4,
                y = 205.1,
            },
        },
        {
            Done = {
                56839,
            },
            Coord = {
                x = -1986.5,
                y = 280.8,
            },
        },
        {
            Waypoint = 59975,
            Range = 17.88,
            Coord = {
                x = -2060.4,
                y = 217.4,
            },
        },
        {
            Waypoint = 59975,
            Range = 20.92,
            Coord = {
                x = -2128,
                y = 219.6,
            },
        },
        {
            Done = {
                59975,
            },
            Coord = {
                x = -2174.7,
                y = 323.5,
            },
        },
        {
            PickUp = {
                59978,
            },
            Coord = {
                x = -2174.7,
                y = 323.5,
            },
        },
        {
            Qpart = {
                [59978] = { 1 },
            },
            Gossip = 1,
            RaidIcon = 156943,
            Range = 0.69,
            Coord = {
                x = -2176.5,
                y = 324.6,
            },
        },
        {
            Qpart = {
                [59978] = { 2 },
            },
            Range = 0.69,
            Coord = {
                x = -2044.8,
                y = 457.3,
            },
        },
        {
            Qpart = {
                [59978] = { 3 },
            },
            Range = 0.75,
            Coord = {
                x = -2063,
                y = 575.4,
            },
        },
        {
            Qpart = {
                [59978] = { 4 },
            },
            Range = 0.75,
            Coord = {
                x = -2062.5,
                y = 586.4,
            },
        },
        {
            Waypoint = 59978,
            Range = 11.9,
            Coord = {
                x = -2076.2,
                y = 619,
            },
        },
        {
            Qpart = {
                [59978] = { 6, },
            },
            Range = 0.75,
            Coord = {
                x = -1893.6,
                y = 699,
            },
        },
        {
            Done = {
                59978,
            },
            Coord = {
                x = -1876.8,
                y = 704.2,
            },
        },
        {
            PickUp = {
                59981,
                59980,
                59979,
            },
            Coord = {
                x = -1877.6,
                y = 703.9,
            },
        },
        {
            Range = 27.27,
            Waypoint = 59981,
            Coord = {
                x = -2012.4,
                y = 616.5,
            },
        },
        {
            Qpart = {
                [59981] = { 2 },
            },
            RaidIcon = 153582,
            Range = 0.69,
            Coord = {
                x = -2009.4,
                y = 592.5,
            },
        },
        {
            Qpart = {
                [59981] = { 1 },
            },
            Fillers = {
                [59980] = { 1 },
                [59979] = { 1 },
            },
            RaidIcon = 153583,
            Range = 0.75,
            Coord = {
                x = -2127,
                y = 659.4,
            },
        },
        {
            Qpart = {
                [59981] = { 3 },
            },
            Fillers = {
                [59980] = { 1 },
                [59979] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -1965,
                y = 511.7,
            },
        },
        {
            Qpart = {
                [59980] = { 1 },
                [59979] = { 1 },
            },
            Range = 59.07,
            Coord = {
                x = -2039.5,
                y = 505.7,
            },
        },
        {
            Coord = {
                x = -1879.3,
                y = 704.2,
            },
            Done = {
                59979,
                59980,
            },
        },
        {
            Qpart = {
                [59981] = { 4 },
            },
            Range = 5.99,
            Coord = {
                x = -1869.5,
                y = 708.9,
            },
        },
        {
            Coord = {
                x = -1869,
                y = 709,
            },
            Done = {
                59981,
            },
        },
        {
            PickUp = {
                59984,
            },
            Coord = {
                x = -1869,
                y = 709,
            },
        },
        {
            Qpart = {
                [59984] = { 1 },
            },
            Range = 0.69,
            Coord = {
                x = -1869,
                y = 709,
            },
        },
        {
            Coord = {
                x = -1858.5,
                y = 713.5,
            },
            Done = {
                59984,
            },
        },
        {
            PickUp = {
                59985,
            },
            Coord = {
                x = -1858.5,
                y = 713.5,
            },
        },
        {
            Qpart = {
                [59985] = { 1 },
            },
            ETA = 75,
            Range = 0.75,
            Coord = {
                x = -1882.6,
                y = 698.6,
            },
        },
        {
            Done = {
                59985,
            },
            Coord = {
                x = -4419.2,
                y = 1465,
            },
        },
        {
            ExitTutorial = 62568,
            Coord = {
                x = -4419.2,
                y = 1465,
            },
            ExtraLineText = "YES_TO_EXIT_TUTORIAL",
            Gossip = 2,
        },
        {
            Coord = {
                x = -4438.4,
                y = 1573.9,
            },
            Gossip = 1,
            SetHS = 34398,
        },
        {
            Done = {
                62568,
            },
            RaidIcon = 167032,
            Coord = {
                x = -4215.9,
                y = 1558.2,
            },
        },
        {
            ZoneDoneSave = 1,
        },
    }
end
