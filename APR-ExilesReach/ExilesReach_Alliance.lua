if (APR.Faction == "Alliance") then
    APR.RouteQuestStepList["1409-Exile's Reach"] = {
        {
            PickUp = {
                56775,
            },
        },
        {
            Qpart = {
                [56775] = {
                    1,
                },
            },
        },
        {
            Done = {
                56775,
            },
        },
        {
            PickUp = {
                58209,
            },
        },
        {
            Qpart = {
                [58209] = {
                    1,
                },
            },
            RaidIcon = 157051,
        },
        {
            Done = {
                58209,
            },
        },
        {
            PickUp = {
                58208,
            },
        },
        {
            Done = {
                58208,
            },
        },
        {
            PickUp = {
                55122,
            },
        },
        {
            Qpart = {
                [55122] = {
                    1,
                },
            },
            Range = 24.31,
            Coord = {
                y = -359.8,
                x = -2563.2,
            },
        },
        {
            Coord = {
                y = -434.7,
                x = -2610.4,
            },
            Done = {
                55122,
            },
        },
        {
            PickUp = {
                54951,
            },
            Coord = {
                y = -434.7,
                x = -2610.4,
            },
        },
        {
            Qpart = {
                [54951] = {
                    2,
                },
            },
            Button = {
                ["54951-2"] = 168410,
            },
            RaidIcon = 156612,
            Range = 0.75,
            Coord = {
                y = -447.9,
                x = -2605.5,
            },
        },
        {
            Qpart = {
                [54951] = {
                    3,
                },
            },
            Button = {
                ["54951-3"] = 168410,
            },
            RaidIcon = 156610,
            Range = 0.61,
            Coord = {
                y = -428.7,
                x = -2593.7,
            },
        },
        {
            Qpart = {
                [54951] = {
                    1,
                },
            },
            Button = {
                ["54951-1"] = 168410,
            },
            RaidIcon = 156609,
            Range = 0.69,
            Coord = {
                y = -420.4,
                x = -2599.5,
            },
        },
        {
            Coord = {
                y = -434.4,
                x = -2610.4,
            },
            Done = {
                54951,
            },
        },
        {
            PickUp = {
                54952,
            },
            Coord = {
                y = -434.4,
                x = -2610.4,
            },
        },
        {
            Qpart = {
                [54952] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -273.9,
                x = -2493,
            },
        },
        {
            Coord = {
                y = -245.2,
                x = -2491.5,
            },
            Done = {
                54952,
            },
        },
        {
            PickUp = {
                55174,
            },
            Coord = {
                y = -249.2,
                x = -2492,
            },
        },
        {
            Qpart = {
                [55174] = {
                    1,
                },
            },
            Range = 38.75,
            Coord = {
                y = -182.4,
                x = -2498.7,
            },
        },
        {
            Qpart = {
                [55174] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = -247.4,
                x = -2490.5,
            },
        },
        {
            Coord = {
                y = -244.7,
                x = -2491.7,
            },
            Done = {
                55174,
            },
        },
        ---- Class Quests Start
        -- Druid
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "DRUID"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -211,
                x = -2522,
            },
            Class = "DRUID"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "DRUID"
        },
        -- Hunter
        {
            PickUp = {
                55173,
            },
            Coord = {
                y = -245,
                x = -2491.5,
            },
            Class = "HUNTER"
        },
        {
            Coord = {
                y = -141,
                x = -2638.9,
            },
            Done = {
                55173,
            },
            Class = "HUNTER"
        },
        {
            PickUp = {
                59342,
            },
            Coord = {
                y = -141,
                x = -2638.9,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59342] = {
                    2,
                },
            },
            Range = 64.18,
            Coord = {
                y = -170,
                x = -2574.5,
            },
            Class = "HUNTER"
        },
        {
            Coord = {
                y = -140.7,
                x = -2638.9,
            },
            Done = {
                59342,
            },
            Class = "HUNTER"
        },
        -- Mage
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -196.7,
                x = -2464.7,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "MAGE"
        },
        -- Monk
        {
            PickUp = {
                59339,
            },
            Coord = {
                y = -248,
                x = -2492.4,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59339] = {
                    1,
                    2,
                },
            },
            RaidIcon = 164577,
            Range = 0.69,
            Coord = {
                y = -194,
                x = -2481.4,
            },
            Class = "MONK"
        },
        {
            Coord = {
                y = -249.2,
                x = -2492,
            },
            Done = {
                59339,
            },
            Class = "MONK"
        },
        -- Paladin
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -211,
                x = -2522,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "PALADIN"
        },
        -- Priest
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -221.5,
                x = -2478.7,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "PRIEST"
        },
        -- Rogue
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -224.2,
                x = -2524,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "ROGUE"
        },
        {
            PickUp = {
                55173,
            },
            Coord = {
                y = -245,
                x = -2491.5,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                y = -141,
                x = -2638.9,
            },
            Done = {
                55173,
            },
            Class = "ROGUE"
        },
        -- Shaman
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -207.2,
                x = -2471.9,
            },
            Class = "SHAMAN"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "SHAMAN"
        },
        -- Warlock
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -221.5,
                x = -2478.7,
            },
            Class = "WARLOCK"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "WARLOCK"
        },
        -- Warrior
        {
            PickUp = {
                59254,
            },
            Coord = {
                y = -247.7,
                x = -2492.7,
            },
            Class = "WARRIOR"
        },
        {
            Qpart = {
                [59254] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = -196.7,
                x = -2464.7,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                y = -248.9,
                x = -2491.5,
            },
            Done = {
                59254,
            },
            Class = "WARRIOR"
        },
        -- END Class Quests Start
        {
            PickUp = {
                55173,
            },
            Coord = {
                y = -245,
                x = -2491.5,
            },
        },
        {
            Coord = {
                y = -141,
                x = -2638.9,
            },
            Done = {
                55173,
            },
        },
        {
            PickUp = {
                55186,
                55184,
            },
            Coord = {
                y = -140.7,
                x = -2638.9,
            },
        },
        {
            Waypoint = 55186,
            Fillers = {
                [55184] = {
                    1,
                },
            },
            Range = 15.15,
            Coord = {
                y = -77,
                x = -2641.2,
            },
        },
        {
            Waypoint = 55186,
            Fillers = {
                [55184] = {
                    1,
                },
            },
            Range = 10.87,
            Coord = {
                y = 45.1,
                x = -2577.2,
            },
        },
        {
            Qpart = {
                [55186] = {
                    1,
                },
            },
            Fillers = {
                [55184] = {
                    1,
                },
            },
            RaidIcon = 151091,
            Range = 0.69,
            Coord = {
                y = 15.6,
                x = -2512.5,
            },
        },
        {
            Qpart = {
                [55184] = {
                    1,
                },
            },
            Range = 19.19,
            Coord = {
                y = 43.1,
                x = -2559.2,
            },
        },
        {
            Range = 15.09,
            Waypoint = 55186,
            Coord = {
                y = 49.1,
                x = -2496.7,
            },
        },
        {
            Coord = {
                y = 100.7,
                x = -2419.4,
            },
            Done = {
                55186,
                55184,
            },
        },
        {
            PickUp = {
                55193,
            },
            Coord = {
                y = 101.4,
                x = -2417.5,
            },
        },
        {
            Qpart = {
                [55193] = {
                    1,
                },
            },
            RaidIcon = 156518,
            Range = 0.75,
            Coord = {
                y = 108.3,
                x = -2413.5,
            },
        },
        {
            Coord = {
                y = 101.7,
                x = -2417.7,
            },
            Done = {
                55193,
            },
        },
        {
            PickUp = {
                56034,
            },
            Coord = {
                y = 101.7,
                x = -2417.7,
            },
        },
        {
            Qpart = {
                [56034] = {
                    1,
                },
            },
            Button = {
                ["56034-1"] = 170557,
            },
            Range = 29.47,
            Coord = {
                y = 118.8,
                x = -2440.4,
            },
        },
        {
            Done = {
                56034,
            },
            Coord = {
                y = 103.3,
                x = -2420.4,
            },
        },
        {
            PickUp = {
                55879,
            },
            Coord = {
                y = 103.3,
                x = -2420.4,
            },
        },
        {
            Qpart = {
                [55879] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 115.3,
                x = -2428.2,
            },
        },
        {
            Qpart = {
                [55879] = {
                    2,
                },
            },
            Range = 33.81,
            Coord = {
                y = 212.6,
                x = -2300.7,
            },
        },
        {
            Qpart = {
                [55879] = {
                    3,
                },
            },
            RaidIcon = 162817,
            Range = 0.75,
            Coord = {
                y = 244.1,
                x = -2245.5,
            },
        },
        {
            Done = {
                55879,
            },
            Coord = {
                y = 231.5,
                x = -2296.4,
            },
        },
        {
            Waypoint = 55194,
            Range = 3.3,
            Coord = {
                y = 231.8,
                x = -2279.7,
            },
        },
        {
            PickUp = {
                55194,
            },
            Coord = {
                y = 187,
                x = -2288,
            },
        },
        {
            Qpart = {
                [55194] = {
                    1,
                    2,
                },
            },
            RaidIcon = 156800,
            Range = 0.75,
            Coord = {
                y = 187.3,
                x = -2284.2,
            },
        },
        {
            Done = {
                55194,
            },
            Coord = {
                y = 187.1,
                x = -2288.4,
            },
        },
        {
            PickUp = {
                55965,
            },
            Coord = {
                y = 192.3,
                x = -2310.5,
            },
        },
        {
            PickUp = {
                55196,
            },
            Coord = {
                y = 254.1,
                x = -2327.7,
            },
        },
        {
            Done = {
                55196,
            },
            Coord = {
                y = 392.6,
                x = -2439.7,
            },
        },
        {
            PickUp = {
                55763,
                55881,
                55764,
            },
            Coord = {
                y = 391.8,
                x = -2441.4,
            },
        },
        {
            Waypoint = 55763,
            Fillers = {
                [55764] = {
                    1,
                },
                [55881] = {
                    1,
                },
            },
            Range = 8.77,
            Coord = {
                y = 492.1,
                x = -2423.9,
            },
        },
        {
            Qpart = {
                [55763] = {
                    1,
                },
            },
            Gossip = 1,
            Fillers = {
                [55764] = {
                    1,
                },
                [55881] = {
                    1,
                },
            },
            RaidIcon = 153211,
            Range = 0.75,
            Coord = {
                y = 496.1,
                x = -2353.5,
            },
        },
        {
            Qpart = {
                [55764] = {
                    1,
                },
                [55881] = {
                    1,
                },
            },
            Gossip = 1,
            Range = 54.1,
            Coord = {
                y = 496.1,
                x = -2507.5,
            },
        },
        {
            Done = {
                55763,
                55764,
                55881,
            },
            Coord = {
                y = 392.3,
                x = -2441.5,
            },
        },
        {
            PickUp = {
                55882,
            },
            Coord = {
                y = 392.7,
                x = -2439.7,
            },
        },
        {
            PickUp = {
                54933,
            },
            Coord = {
                y = 302.3,
                x = -2485.7,
            },
        },
        {
            Qpart = {
                [54933] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 313.8,
                x = -2460.5,
            },
        },
        {
            Qpart = {
                [54933] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 325.3,
                x = -2495.4,
            },
        },
        {
            Qpart = {
                [54933] = {
                    3,
                },
            },
            Range = 0.69,
            Coord = {
                y = 291.6,
                x = -2513.2,
            },
        },
        {
            Qpart = {
                [54933] = {
                    4,
                },
            },
            Range = 0.75,
            Coord = {
                y = 280,
                x = -2473.5,
            },
        },
        {
            Done = {
                54933,
            },
            Coord = {
                y = 302.2,
                x = -2484.7,
            },
        },
        {
            Done = {
                55882,
            },
            Coord = {
                y = 186.9,
                x = -2288.7,
            },
        },
        ---- Class Quest Start
        -- Druid
        -- Hunter
        {
            PickUp = {
                59355,
            },
            Coord = {
                y = 188.1,
                x = -2290.9,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59355] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 156886,
            Range = 0.75,
            Coord = {
                y = 183.8,
                x = -2285.5,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59355] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 237.8,
                x = -2283.9,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59355] = {
                    3,
                },
            },
            Range = 0.69,
            Coord = {
                y = 270,
                x = -2270.7,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                59355,
            },
            Coord = {
                y = 187.8,
                x = -2290.5,
            },
            Class = "HUNTER"
        },
        {
            PickUp = {
                59356,
            },
            Coord = {
                y = 187.8,
                x = -2290.5,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [59356] = {
                    1,
                },
            },
            Range = 18.66,
            Coord = {
                y = 228.8,
                x = -2273,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                59356,
            },
            Coord = {
                y = 188.6,
                x = -2290,
            },
            Class = "HUNTER"
        },
        {
            PickUp = {
                60168,
            },
            Coord = {
                y = 188.6,
                x = -2290,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60168] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 189.4,
                x = -2289.2,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60168] = {
                    2,
                },
            },
            Gossip = 2,
            RaidIcon = 161666,
            Range = 0.69,
            Coord = {
                y = 188.6,
                x = -2290.7,
            },
            Class = "HUNTER"
        },
        {
            Qpart = {
                [60168] = {
                    3,
                },
            },
            Gossip = 1,
            Range = 0.75,
            Coord = {
                y = 188.8,
                x = -2290,
            },
            Class = "HUNTER"
        },
        {
            Done = {
                60168,
            },
            Coord = {
                y = 188.8,
                x = -2290,
            },
            Class = "HUNTER"
        },
        -- Mage
        {
            PickUp = {
                59352,
            },
            Coord = {
                y = 183.5,
                x = -2285.7,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59352] = {
                    1,
                },
            },
            Range = 0.61,
            Coord = {
                y = 310.3,
                x = -2274.7,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                y = 182.9,
                x = -2286.2,
            },
            Done = {
                59352,
            },
            Class = "MAGE"
        },
        {
            PickUp = {
                59354,
            },
            Coord = {
                y = 184.1,
                x = -2286.2,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59354] = {
                    1,
                },
            },
            Gossip = 1,
            Range = 0.75,
            Coord = {
                y = 184.1,
                x = -2286.2,
            },
            Class = "MAGE"
        },
        {
            Qpart = {
                [59354] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 178.9,
                x = -2332.2,
            },
            Class = "MAGE"
        },
        {
            Coord = {
                y = 183.8,
                x = -2286,
            },
            Done = {
                59354,
            },
            Class = "MAGE"
        },
        -- Monk
        {
            PickUp = {
                59347,
            },
            Coord = {
                y = 179.6,
                x = -2281.2,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59347] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 164835,
            Range = 0.75,
            Coord = {
                y = 317.5,
                x = -2297.5,
            },
            Class = "MONK"
        },
        {
            Coord = {
                y = 318.3,
                x = -2298.5,
            },
            Done = {
                59347,
            },
            Class = "MONK"
        },
        {
            PickUp = {
                59349,
            },
            Coord = {
                y = 318.3,
                x = -2298.5,
            },
            Class = "MONK"
        },
        {
            Qpart = {
                [59349] = {
                    1,
                },
            },
            RaidIcon = 164868,
            Range = 0.75,
            Coord = {
                y = 309,
                x = -2325.7,
            },
            Class = "MONK"
        },
        {
            Coord = {
                y = 186.6,
                x = -2288.7,
            },
            Done = {
                59349,
            },
            Class = "MONK"
        },
        -- Paladin
        {
            PickUp = {
                58923,
            },
            Coord = {
                y = 187.6,
                x = -2279,
            },
            Class = "PALADIN"
        },
        {
            Range = 12.06,
            Waypoint = 58923,
            Coord = {
                y = 347.5,
                x = -2398.5,
            },
            Class = "PALADIN"
        },
        {
            Range = 8.18,
            Waypoint = 58923,
            Coord = {
                y = 313.5,
                x = -2444.2,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [58923] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 162998,
            Range = 0.75,
            Coord = {
                y = 257.5,
                x = -2464.7,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                y = 257.5,
                x = -2464.7,
            },
            Done = {
                58923,
            },
            Class = "PALADIN"
        },
        {
            PickUp = {
                58946,
            },
            Coord = {
                y = 257.5,
                x = -2464.7,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [58946] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 258.5,
                x = -2463.7,
            },
            Class = "PALADIN"
        },
        {
            Qpart = {
                [58946] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 246.6,
                x = -2450,
            },
            Class = "PALADIN"
        },
        {
            Coord = {
                y = 256.6,
                x = -2464.5,
            },
            Done = {
                58946,
            },
            Class = "PALADIN"
        },
        -- Priest
        {
            PickUp = {
                58953,
            },
            Coord = {
                y = 187.8,
                x = -2279.5,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [58953] = {
                    1,
                },
            },
            Range = 0.69,
            Coord = {
                y = 221.9,
                x = -2415.2,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                y = 221.9,
                x = -2415.2,
            },
            Done = {
                58953,
            },
            Class = "PRIEST"
        },
        {
            PickUp = {
                58960,
            },
            Coord = {
                y = 221.9,
                x = -2415.2,
            },
            Class = "PRIEST"
        },
        {
            Qpart = {
                [58960] = {
                    1,
                },
            },
            Range = 5.28,
            Coord = {
                y = 228.1,
                x = -2419.7,
            },
            Class = "PRIEST"
        },
        {
            Coord = {
                y = 223.4,
                x = -2415.5,
            },
            Done = {
                58960,
            },
            Class = "PRIEST"
        },
        -- Rogue
        {
            PickUp = {
                58917,
            },
            Coord = {
                y = 187.9,
                x = -2279.4,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [58917] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 162972,
            Range = 0.69,
            Coord = {
                y = 168.9,
                x = -2061.7,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [58917] = {
                    2,
                },
            },
            Range = 9.76,
            Coord = {
                y = 185,
                x = -2038.6,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                y = 168.6,
                x = -2061.5,
            },
            Done = {
                58917,
            },
            Class = "ROGUE"
        },
        {
            PickUp = {
                58933,
            },
            Coord = {
                y = 168.6,
                x = -2061.5,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [58933] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 175.5,
                x = -2063.5,
            },
            Class = "ROGUE"
        },
        {
            Qpart = {
                [58933] = {
                    2,
                },
            },
            RaidIcon = 163036,
            Range = 0.69,
            Coord = {
                y = 270.7,
                x = -2159.2,
            },
            Class = "ROGUE"
        },
        {
            Coord = {
                y = 187.4,
                x = -2279.7,
            },
            Done = {
                58933,
            },
            Class = "ROGUE"
        },
        -- Shaman
        {
            PickUp = {
                59002,
            },
            Coord = {
                y = 179.6,
                x = -2286.7,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59002] = {
                    1,
                },
            },
            Range = 10.81,
            Coord = {
                y = 276.1,
                x = -2288.9,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59002] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 180.9,
                x = -2284,
            },
            Class = "SHAMAN"
        },
        {
            Qpart = {
                [59002] = {
                    3,
                },
            },
            Range = 23.61,
            Coord = {
                y = 148,
                x = -2352.7,
            },
            Class = "SHAMAN"
        },
        {
            Coord = {
                y = 179.8,
                x = -2286.9,
            },
            Done = {
                59002,
            },
            Class = "SHAMAN"
        },
        -- Warlock
        {
            PickUp = {
                58962,
            },
            Coord = {
                y = 187.6,
                x = -2279.2,
            },
            Class = "WARLOCK"
        },
        {
            Range = 11.53,
            Waypoint = 58962,
            Coord = {
                y = 354.6,
                x = -2344.5,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [58962] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 163209,
            Range = 0.75,
            Coord = {
                y = 398.8,
                x = -2295.2,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [58962] = {
                    2,
                },
            },
            Range = 0.61,
            Coord = {
                y = 399.8,
                x = -2296.7,
            },
            Class = "WARLOCK"
        },
        {
            Qpart = {
                [58962] = {
                    3,
                },
            },
            Button = {
                ["58962-3"] = 174947,
            },
            Range = 0.61,
            Coord = {
                y = 399.8,
                x = -2296.7,
            },
            Class = "WARLOCK"
        },
        {
            Coord = {
                y = 409.5,
                x = -2297.2,
            },
            Done = {
                58962,
            },
            Class = "WARLOCK"
        },
        -- Warrior
        {
            PickUp = {
                58914,
            },
            Coord = {
                y = 188.1,
                x = -2279.4,
            },
            Class = "WARRIOR"
        },
        {
            Range = 20.09,
            Waypoint = 58914,
            Coord = {
                y = 272.8,
                x = -2331.5,
            },
            Class = "WARRIOR"
        },
        {
            Range = 10.6,
            Waypoint = 58914,
            Coord = {
                y = 352.8,
                x = -2346.9,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                y = 355.8,
                x = -2257.4,
            },
            Done = {
                58914,
            },
            Class = "WARRIOR"
        },
        {
            PickUp = {
                58915,
            },
            Coord = {
                y = 355.8,
                x = -2257.4,
            },
            Class = "WARRIOR"
        },
        {
            Qpart = {
                [58915] = {
                    1,
                },
            },
            RaidIcon = 162948,
            Range = 0.61,
            Coord = {
                y = 355.8,
                x = -2257.4,
            },
            Class = "WARRIOR"
        },
        {
            Coord = {
                y = 187.8,
                x = -2279.5,
            },
            Done = {
                58915,
            },
            Class = "WARRIOR"
        },
        ---- Class Quest End
        {
            Done = {
                55965,
            },
            Coord = {
                y = 90.3,
                x = -2248.9,
            },
        },
        {
            PickUp = {
                55639,
            },
            Coord = {
                y = 92.5,
                x = -2246.5,
            },
        },
        {
            Qpart = {
                [55639] = {
                    1,
                },
            },
            Range = 70.21,
            Coord = {
                y = 71,
                x = -2240,
            },
        },
        {
            Waypoint = 55639,
            Range = 7.92,
            Coord = {
                y = 83.3,
                x = -2214.2,
            },
        },
        {
            Qpart = {
                [55639] = {
                    2,
                },
            },
            RaidIcon = 156900,
            Range = 0.69,
            Coord = {
                y = 72.5,
                x = -2127.5,
            },
        },
        {
            Qpart = {
                [55639] = {
                    3,
                },
            },
            Range = 0.75,
            Coord = {
                y = 75.3,
                x = -2134.5,
            },
        },
        {
            Done = {
                55639,
            },
            Coord = {
                y = 186,
                x = -2288.7,
            },
        },
        ---- Class Quest Start DRUID
        {
            PickUp = {
                59350,
            },
            Coord = {
                y = 184,
                x = -2287.7,
            },
            Class = "DRUID"
        },
        {
            Qpart = {
                [59350] = {
                    1,
                },
            },
            Range = 0.69,
            Coord = {
                y = 323.1,
                x = -2053,
            },
            Class = "DRUID"
        },
        {
            Coord = {
                y = 324,
                x = -2056.2,
            },
            Done = {
                59350,
            },
            Class = "DRUID"
        },
        ---- Class Quest End DRUID
        {
            PickUp = {
                56344,
            },
            Coord = {
                y = 186,
                x = -2288.7,
            },
        },
        {
            PickUp = {
                56839,
            },
            Coord = {
                y = 211.5,
                x = -2168,
            },
        },
        {
            Qpart = {
                [56839] = {
                    1,
                },
            },
            RaidIcon = 153266,
            Range = 0.61,
            Coord = {
                y = 205.1,
                x = -2058.4,
            },
        },
        {
            Done = {
                56839,
            },
            Coord = {
                y = 280.8,
                x = -1986.5,
            },
        },
        {
            Waypoint = 56344,
            Range = 17.88,
            Coord = {
                y = 217.4,
                x = -2060.4,
            },
        },
        {
            Waypoint = 56344,
            Range = 20.92,
            Coord = {
                y = 219.6,
                x = -2128,
            },
        },
        {
            Done = {
                56344,
            },
            Coord = {
                y = 323.5,
                x = -2174.7,
            },
        },
        {
            PickUp = {
                55981,
            },
            Coord = {
                y = 323.5,
                x = -2174.7,
            },
        },
        {
            Qpart = {
                [55981] = {
                    1,
                },
            },
            Gossip = 1,
            RaidIcon = 156943,
            Range = 0.69,
            Coord = {
                y = 324.6,
                x = -2176.5,
            },
        },
        {
            Qpart = {
                [55981] = {
                    2,
                },
            },
            Range = 0.69,
            Coord = {
                y = 457.3,
                x = -2044.8,
            },
        },
        {
            Qpart = {
                [55981] = {
                    3,
                },
            },
            Range = 0.75,
            Coord = {
                y = 575.4,
                x = -2063,
            },
        },
        {
            Qpart = {
                [55981] = {
                    4,
                },
            },
            Range = 0.75,
            Coord = {
                y = 586.4,
                x = -2062.5,
            },
        },
        {
            Waypoint = 55981,
            Range = 11.9,
            Coord = {
                y = 619,
                x = -2076.2,
            },
        },
        {
            Done = {
                55981,
            },
            Coord = {
                y = 704.2,
                x = -1876.8,
            },
        },
        {
            PickUp = {
                55988,
                55990,
                55989,
            },
            Coord = {
                y = 703.9,
                x = -1877.6,
            },
        },
        {
            Range = 27.27,
            Waypoint = 55990,
            Coord = {
                y = 616.5,
                x = -2012.4,
            },
        },
        {
            Qpart = {
                [55990] = {
                    2,
                },
            },
            RaidIcon = 153582,
            Range = 0.69,
            Coord = {
                y = 592.5,
                x = -2009.4,
            },
        },
        {
            Qpart = {
                [55990] = {
                    1,
                },
            },
            Fillers = {
                [55989] = {
                    1,
                },
                [55988] = {
                    1,
                },
            },
            RaidIcon = 153583,
            Range = 0.75,
            Coord = {
                y = 659.4,
                x = -2127,
            },
        },
        {
            Qpart = {
                [55990] = {
                    3,
                },
            },
            Fillers = {
                [55989] = {
                    1,
                },
                [55988] = {
                    1,
                },
            },
            Range = 0.69,
            Coord = {
                y = 511.7,
                x = -1965,
            },
        },
        {
            Qpart = {
                [55989] = {
                    1,
                },
            },
            Fillers = {
                [55988] = {
                    1,
                },
            },
            Range = 59.07,
            Coord = {
                y = 505.7,
                x = -2039.5,
            },
        },
        {
            Qpart = {
                [55988] = {
                    1,
                },
            },
            Range = 49.21,
            Coord = {
                y = 608.9,
                x = -2085.2,
            },
        },
        {
            Coord = {
                y = 704.2,
                x = -1879.3,
            },
            Done = {
                55989,
                55988,
            },
        },
        {
            Qpart = {
                [55990] = {
                    4,
                },
            },
            Range = 5.99,
            Coord = {
                y = 708.9,
                x = -1869.5,
            },
        },
        {
            Coord = {
                y = 709,
                x = -1869,
            },
            Done = {
                55990,
            },
        },
        {
            PickUp = {
                55992,
            },
            Coord = {
                y = 709,
                x = -1869,
            },
        },
        {
            Qpart = {
                [55992] = {
                    1,
                },
            },
            Range = 0.69,
            Coord = {
                y = 709,
                x = -1869,
            },
        },
        {
            Coord = {
                y = 713.5,
                x = -1858.5,
            },
            Done = {
                55992,
            },
        },
        {
            PickUp = {
                55991,
            },
            Coord = {
                y = 713.5,
                x = -1858.5,
            },
        },
        {
            Qpart = {
                [55991] = {
                    1,
                },
            },
            Range = 0.75,
            Coord = {
                y = 698.6,
                x = -1882.6,
            },
        },
        {
            Done = {
                55991,
            },
            Coord = {
                y = -9055,
                x = 442,
            },
        },
        {
            ExitTutorial = 62567,
            Coord = {
                y = -9055,
                x = 442,
            },
            ExtraLineText = "YES_TO_EXIT_TUTORIAL",
            Gossip = 1,
        },
        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8843,
                x = 610.4,
            },
        },
        {
            Coord = {
                y = -8867.5,
                x = 673.2,
            },
            Gossip = 1,
            RaidIcon = 44919,
            SetHS = 34398,
        },

        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8769.9,
                x = 606.3,
            },
        },
        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8745.7,
                x = 557.5,
            },
        },
        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8610.4,
                x = 516.1,
            },
        },
        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8541.5,
                x = 503,
            },
        },
        {
            Range = 6.45,
            Waypoint = 34398,
            Coord = {
                y = -8333.8,
                x = 648,
            },
        },
        {
            Done = {
                62567,
            },
            Coord = {
                y = -8196.3,
                x = 745.9,
            },
        },
        {
            ZoneDoneSave = 1,
        },
    }
end
