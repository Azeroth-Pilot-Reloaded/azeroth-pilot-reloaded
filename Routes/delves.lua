local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.DelveRouteRegistry = APR.DelveRouteRegistry or {}

local function NormalizeDelveScenarioSteps(steps)
    steps = steps or {}

    for _, step in ipairs(steps) do
        if step.InstanceQuest == nil then
            step.InstanceQuest = true
        end
    end

    return steps
end

local function DelveScenarioBlock(scenarioID, index, label, steps)
    return {
        label = label,
        scenarioID = scenarioID,
        steps = NormalizeDelveScenarioSteps(steps),
        index = index,
    }
end

local function RegisterDelveRoute(routeKey, routeData)
    APR.DelveRouteRegistry[routeKey] = true
    APR.RouteQuestStepList[routeKey] = routeData
end

RegisterDelveRoute("FUNGAL_FOLLY_DELVE", {
    label = "Fungal Folly",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2249,
    scenarios = {
        DelveScenarioBlock(2311, 1, "Lost Miners", {
            {
                Coord = { x = -234.80000305176, y = -488.60000610352 },
                InstanceQuest = true,
                GossipOptionIDs = { 111366 },
                Scenario = { questID = 1, criteriaID = 62061, criteriaIndex = 1, scenarioID = 2311, stepID = 6588 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -84.200004577637, y = -310.70001220703 },
                InstanceQuest = true,
                Range = 250,
                Scenario = { questID = 1, criteriaID = 62060, criteriaIndex = 1, scenarioID = 2311, stepID = 6589 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -18.200000762939, y = -173.5 },
                InstanceQuest = true,
                Range = 5,
                Scenario = { questID = 1, criteriaID = 62763, criteriaIndex = 1, scenarioID = 2311, stepID = 6590 },
                Zone = 2248,
            }
            ,
        }),
        --         DelveScenarioBlock(0, 2, "Explorer's Competition"),
        -- DelveScenarioBlock(0, 3, "Spreading Decay"),
        --         DelveScenarioBlock(0, 4, "Oversparked Operation"),
    },
})

RegisterDelveRoute("KRIEGVALS_REST_DELVE", {
    label = "Kriegval's Rest",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2250,
    scenarios = {
        DelveScenarioBlock(2317, 1, "Lost Keepsakes", {
            {
                Coord = { x = -47.200000762939, y = -349.20001220703 },
                GossipOptionIDs = { 119802 },
                InstanceQuest = true,
                Scenario = { questID = 1, criteriaID = 62874, criteriaIndex = 2, scenarioID = 2317, stepID = 6605 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -99.700004577637, y = -351.5 },
                InstanceQuest = true,
                Range = 5,
                Scenario = { questID = 1, criteriaID = 62401, criteriaIndex = 1, scenarioID = 2317, stepID = 6605 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -363.39999389648, y = -510.39999389648 },
                InstanceQuest = true,
                Range = 300,
                Scenario = { questID = 1, criteriaID = 62876, criteriaIndex = 1, scenarioID = 2317, stepID = 6606 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -231.19999694824, y = -607.70001220703 },
                InstanceQuest = true,
                Range = 5,
                Scenario = { questID = 1, criteriaID = 62877, criteriaIndex = 1, scenarioID = 2317, stepID = 6623 },
                Zone = 2248,
            }
            ,
            {
                Coord = { x = -227.5, y = -612.90002441406 },
                InstanceQuest = true,
                Range = 5,
                Scenario = { questID = 1, criteriaID = 62680, criteriaIndex = 1, scenarioID = 2317, stepID = 6640 },
                Zone = 2248,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Dagran's Day Out"),
        -- DelveScenarioBlock(0, 3, "Swarming Kobolds"),
        -- DelveScenarioBlock(0, 4, "Corrupted Candles"),
    },
})

RegisterDelveRoute("WATERWORKS_DELVE", {
    label = "Waterworks",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2251,
    scenarios = {
        DelveScenarioBlock(2354, 1, "Captured Engineers", {
            {
                Scenario = { questID = 1, criteriaID = 63492, criteriaIndex = 1, scenarioID = 2354, stepID = 6757 },
                Coord = { x = 313.6, y = 38.7 },
                GossipOptionIDs = { 120018 },
                InstanceQuest = true,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 62401, criteriaIndex = 2, scenarioID = 2354, stepID = 6757 },
                Coord = { x = 313.9, y = 45.6 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 63493, criteriaIndex = 1, scenarioID = 2354, stepID = 6758 },
                Coord = { x = 265.5, y = -492.6 },
                InstanceQuest = true,
                Range = 600,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 63494, criteriaIndex = 1, scenarioID = 2354, stepID = 6759 },
                Coord = { x = 288.2, y = -752.3 },
                InstanceQuest = true,
                Range = 20,
                Zone = 2214
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Stomping Some Sense"),
        -- DelveScenarioBlock(0, 3, "Trust Issues"),
        -- DelveScenarioBlock(0, 4, "Put a Wrench on It!"),
    },
})

RegisterDelveRoute("DREAD_PIT_DELVE", {
    label = "Dread Pit",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2302,
    scenarios = {
        DelveScenarioBlock(2415, 1, "Lost Gems", {
            {
                Scenario = { questID = 1, criteriaID = 66407, criteriaIndex = 1, scenarioID = 2415, stepID = 7007 },
                Coord = { x = -129.6, y = -240.3 },
                GossipOptionIDs = { 121508 },
                InstanceQuest = true,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 0, criteriaIndex = 1, scenarioID = 2415, stepID = 7059 },
                Coord = { x = -168.6, y = -282.0 },
                ExtraLineText = "MANUAL_SKIP",
                GossipOptionIDs = { 121508 },
                Range = 200,
                InstanceQuest = true,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 69236, criteriaIndex = 1, scenarioID = 2415, stepID = 7798 },
                Coord = { x = -190.0, y = -235.1 },
                GossipOptionIDs = { 123392 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66450, criteriaIndex = 2, scenarioID = 2415, stepID = 7060 },
                Coord = { x = -193.7, y = -371.0 },
                InstanceQuest = true,
                ExtraActionB = true,
                Range = 5,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 69809, criteriaIndex = 1, scenarioID = 2415, stepID = 7060 },
                Coord = { x = -324.0, y = -199.4 },
                InstanceQuest = true,
                ExtraActionB = true,
                Range = 5,
                Zone = 2214
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66452, criteriaIndex = 1, scenarioID = 2415, stepID = 7062 },
                Coord = { x = -224.4, y = -89.4 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2214
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Kobold Kidnapping"),
        -- DelveScenarioBlock(0, 3, "Smashing Skardyn"),
        -- DelveScenarioBlock(0, 4, "Darkfuse Disruption"),
    },
})

RegisterDelveRoute("SKITTERING_BREACH_DELVE", {
    label = "Skittering Breach",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2310,
    scenarios = {
        DelveScenarioBlock(2422, 1, "Old Rituals", {
            {
                Scenario = { questID = 1, criteriaID = 66541, criteriaIndex = 1, scenarioID = 2422, stepID = 7029 },
                Coord = { x = -161.7, y = -70.0 },
                GossipOptionIDs = { 121408 },
                InstanceQuest = true,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66542, criteriaIndex = 1, scenarioID = 2422, stepID = 7104 },
                Coord = { x = 47.5, y = 28.8 },
                InstanceQuest = true,
                Range = 250,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 68253, criteriaIndex = 1, scenarioID = 2422, stepID = 7105 },
                Coord = { x = 47.5, y = 28.8 },
                InstanceQuest = true,
                Range = 250,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66546, criteriaIndex = 1, scenarioID = 2422, stepID = 7031 },
                Coord = { x = -89.1, y = 31.3 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Shadow Realm"),
        -- DelveScenarioBlock(0, 3, "Renilash Beckons"),
        -- DelveScenarioBlock(0, 4, "Relics of the Old Gods"),
    },
})

RegisterDelveRoute("MYCOMANCER_CAVERN_DELVE", {
    label = "Mycomancer Cavern",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2312,
    scenarios = {
        DelveScenarioBlock(2434, 1, "Missing Pigs", {
            {
                Scenario = { questID = 1, criteriaID = 66719, criteriaIndex = 1, scenarioID = 2434, stepID = 7152 },
                Coord = { x = 8, y = -754.60003662109 },
                GossipOptionIDs = { 121536 },
                InstanceQuest = true,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66485, criteriaIndex = 1, scenarioID = 2434, stepID = 7094 },
                InstanceQuest = true,
                NoArrow = true,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66737, criteriaIndex = 1, scenarioID = 2434, stepID = 7095 },
                Coord = { x = -127.40000152588, y = -810.70001220703 },
                InstanceQuest = true,
                Range = 10,
                Zone = 2215
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Mushroom Morsel"),
        -- DelveScenarioBlock(0, 3, "The Great Scavenger Hunt"),
    },
})

RegisterDelveRoute("SINKHOLE_DELVE", {
    label = "Sinkhole",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2301,
    scenarios = {
        DelveScenarioBlock(2409, 1, "Illusory Rescue", {
            {
                Scenario = { questID = 1, criteriaID = 66466, criteriaIndex = 1, scenarioID = 2409, stepID = 7001 },
                Coord = { x = -1659.5, y = -417.20001220703 },
                InstanceQuest = true,
                Range = 100,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66468, criteriaIndex = 1, scenarioID = 2409, stepID = 7085 },
                Coord = { x = -1557.0999755859, y = -593.20001220703 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66469, criteriaIndex = 1, scenarioID = 2409, stepID = 7086 },
                Coord = { x = -1478, y = -502.39999389648 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Lurking Terror"),
        -- DelveScenarioBlock(0, 3, "Raen's Gambit"),
        -- DelveScenarioBlock(0, 4, "Orphan's Holiday"),
    },
})

RegisterDelveRoute("NIGHTFALL_SANCTUM_DELVE", {
    label = "Nightfall Sanctum",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2277,
    scenarios = {
        DelveScenarioBlock(2397, 1, "Dark Ritual", {
            {
                Scenario = { questID = 1, criteriaID = 66008, criteriaIndex = 1, scenarioID = 2397, stepID = 6944 },
                Coord = { x = 97.599998474121, y = -778.60003662109 },
                InstanceQuest = true,
                Range = 150,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66021, criteriaIndex = 1, scenarioID = 2397, stepID = 6949 },
                Coord = { x = 141.10000610352, y = -670.40002441406 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215
            }
            ,
            {
                Coord = { x = 123.20000457764, y = -712.5 },
                ExtraLineText = "JUMP_OFF",
                InstanceQuest = true,
                Range = 5,
                Waypoint = 83755,
                Zone = 2215
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66050, criteriaIndex = 1, scenarioID = 2397, stepID = 6968 },
                Coord = { x = 88.099998474121, y = -730.10003662109 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215
            }
            ,
        }),
        DelveScenarioBlock(2398, 2, "Signal Noise", {
            {
                Scenario = { questID = 1, criteriaID = 66010, criteriaIndex = 1, scenarioID = 2398, stepID = 6945 },
                Coord = { x = -60.100002288818, y = -559.29998779297 },
                GossipOptionIDs = { 120767 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66013, criteriaIndex = 1, scenarioID = 2398, stepID = 6952 },
                Coord = { x = 105, y = -665.70001220703 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66034, criteriaIndex = 1, scenarioID = 2398, stepID = 6960 },
                Coord = { x = 174.40000915527, y = -740.79998779297 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66015, criteriaIndex = 1, scenarioID = 2398, stepID = 6953 },
                Coord = { x = -35.299999237061, y = -520.40002441406 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66021, criteriaIndex = 1, scenarioID = 2398, stepID = 6954 },
                Coord = { x = -63.100002288818, y = -540.70001220703 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2215,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 3, "Kyron's Assault"),
        -- DelveScenarioBlock(0, 4, "Aiming to get Even"),
    },
})

RegisterDelveRoute("SPIRAL_WEAVE_DELVE", {
    label = "Spiral Weave",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2347,
    scenarios = {
        DelveScenarioBlock(2401, 1, "Tortured Hostages", {
            {
                Scenario = { questID = 1, criteriaID = 66065, criteriaIndex = 1, scenarioID = 2401, stepID = 6972 },
                Coord = { x = 41.5, y = -135.10000610352 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66066, criteriaIndex = 1, scenarioID = 2401, stepID = 6973 },
                Coord = { x = 112.70000457764, y = 55.299999237061 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66088, criteriaIndex = 1, scenarioID = 2401, stepID = 6974 },
                Coord = { x = 57.5, y = -54 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Strange Disturbances"),
        -- DelveScenarioBlock(0, 3, "From the Weaver with Love"),
        -- DelveScenarioBlock(0, 4, "Down to Size"),
    },
})

RegisterDelveRoute("TAK_RETHAN_ABYSS_DELVE", {
    label = "Tak-Rethan Abyss",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2259,
    scenarios = {
        DelveScenarioBlock(2373, 1, "Goblin Mischief", {
            {
                Scenario = { questID = 1, criteriaID = 64509, criteriaIndex = 1, scenarioID = 2373, stepID = 6812 },
                Coord = { x = 235.69999694824, y = -328.20001220703 },
                GossipOptionIDs = { 120132 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 64510, criteriaIndex = 1, scenarioID = 2373, stepID = 6813 },
                Coord = { x = 297.20001220703, y = -558.90002441406 },
                ExtraActionB = true,
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 64527, criteriaIndex = 1, scenarioID = 2373, stepID = 6815 },
                Coord = { x = 376.70001220703, y = -619.29998779297 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 64528, criteriaIndex = 1, scenarioID = 2373, stepID = 6816 },
                Coord = { x = 236.19999694824, y = -609 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 64738, criteriaIndex = 1, scenarioID = 2373, stepID = 6814 },
                InstanceQuest = true,
                NoArrow = true,
                Zone = 2255,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Pheromone Fury"),
        -- DelveScenarioBlock(0, 3, "Niffen Napping"),
        -- DelveScenarioBlock(0, 4, "Pump the Brakes"),
    },
})

RegisterDelveRoute("UNDERKEEP_DELVE", {
    label = "Underkeep",
    expansion = APR.EXPANSIONS.TheWarWithin,
    mapID = 2299,
    scenarios = {
        DelveScenarioBlock(2426, 1, "Torture Victims", {
            {
                Scenario = { questID = 1, criteriaID = 66431, criteriaIndex = 1, scenarioID = 2426, stepID = 7041 },
                Coord = { x = 40.100002288818, y = -111.59999847412 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66433, criteriaIndex = 1, scenarioID = 2426, stepID = 7043 },
                Coord = { x = -107.09999847412, y = -277.5 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 66434, criteriaIndex = 1, scenarioID = 2426, stepID = 7044 },
                Coord = { x = -191.90000915527, y = -335.39999389648 },
                InstanceQuest = true,
                Range = 5,
                Zone = 2255,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Evolved Research"),
        -- DelveScenarioBlock(0, 3, "Third Party Operation"),
        -- DelveScenarioBlock(0, 4, "Weaver Rescue"),
        -- DelveScenarioBlock(0, 5, "Runaway Evolution"),
    },
})

RegisterDelveRoute("SHADOW_ENCLAVE", {
    label = "Shadow Enclave",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2502,
    scenarios = {
        DelveScenarioBlock(3257, 1, "Traitor's Due", {
            {
                Scenario = { questID = 1, criteriaID = 111078, criteriaIndex = 1, scenarioID = 3257, stepID = 16447 },
                Coord = { x = 125.6, y = -8.6 },
                GossipOptionIDs = { 137619 },
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 81, y = -16 },
                Range = 5,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 1.9, y = -55 },
                Range = 5,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = -66.4, y = 41.1 },
                Range = 5,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = -70.7, y = -23.5 },
                Range = 5,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = -170.3, y = -15.5 },
                Range = 10,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 110646, criteriaIndex = 1, scenarioID = 3257, stepID = 16448 },
                Coord = { x = -119.7, y = 86.9 },
                Range = 15,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 60399, criteriaIndex = 1, scenarioID = 3257, stepID = 16449 },
                Coord = { x = -56.2, y = 129.5 },
                Range = 15,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2395,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Mirror Shine"),
        -- DelveScenarioBlock(0, 3, "Shadowy Supplies"),
    },
})

RegisterDelveRoute("THE_GRUDGE_PIT_DELVE", {
    label = "The Grudge Pit",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2510,
    scenarios = {
        DelveScenarioBlock(3097, 1, "Dastardly Rotstalk", {
            {
                Scenario = { questID = 1, criteriaID = 106065, criteriaIndex = 1, scenarioID = 3097, stepID = 15912 },
                Coord = { x = -1809.3, y = -791.7 },
                GossipOptionIDs = { 134668 },
                Zone = 2413,
                _index = 1,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106066, criteriaIndex = 1, scenarioID = 3097, stepID = 15913 },
                Coord = { x = -1805.6, y = -794.1 },
                Range = 1,
                Zone = 2413,
                _index = 2,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 105769, criteriaIndex = 1, scenarioID = 3097, stepID = 15896 },
                Coord = { x = -1845.6, y = -809.8 },
                Range = 30,
                ExtraActionB = true,
                Zone = 2413,
                _index = 3,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 105770, criteriaIndex = 2, scenarioID = 3097, stepID = 15896 },
                Coord = { x = -1845.6, y = -809.8 },
                Range = 30,
                Zone = 2413,
                _index = 4,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106178, criteriaIndex = 1, scenarioID = 3097, stepID = 15897 },
                Coord = { x = -1831.6, y = -799.6 },
                Range = 5,
                ExtraActionB = true,
                Zone = 2413,
                _index = 5,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106236, criteriaIndex = 1, scenarioID = 3097, stepID = 15930 },
                Coord = { x = -1814.8, y = -813.9 },
                Range = 5,
                Zone = 2413,
                _index = 6,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106293, criteriaIndex = 2, scenarioID = 3097, stepID = 15930 },
                Coord = { x = -1839.5, y = -807.9 },
                Range = 5,
                Zone = 2413,
                _index = 7,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106314, criteriaIndex = 1, scenarioID = 3097, stepID = 15942 },
                Coord = { x = -1842.4, y = -810.4 },
                Range = 5,
                Zone = 2413,
                _index = 8,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 60399, criteriaIndex = 1, scenarioID = 3097, stepID = 15898 },
                Coord = { x = -1841.7, y = -805.2 },
                Range = 5,
                Zone = 2413,
                _index = 9,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 2, "Lightbloom Invasion"),
        -- DelveScenarioBlock(0, 3, "Arena Champion"),
    },
})

RegisterDelveRoute("GULD_OF_MEMORY_DELVE", {
    label = "Guld of Memory",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2505,
    scenarios = {
        -- DelveScenarioBlock(0, 1, "Descent of the Haranir"),
        -- DelveScenarioBlock(0, 2, "Sporasaur Special"),
        DelveScenarioBlock(3243, 3, "Alnmoth Munchies", {
            {
                Scenario = { questID = 1, criteriaID = 111078, criteriaIndex = 1, scenarioID = 3243, stepID = 16416 },
                Coord = { x = 648.1, y = 137.5 },
                GossipOptionIDs = { 137389 },
                InstanceQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 623.2, y = -58 },
                Range = 5,
                InstanceQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 524.9, y = 34.5 },
                Range = 15,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 511.8, y = -20 },
                Range = 10,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 544.6, y = -127.6 },
                Range = 10,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 639.3, y = -138.2 },
                Range = 10,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2413,
            }
            ,
            {
                Waypoint = 1,
                Coord = { x = 662, y = -200.9 },
                Range = 10,
                InstanceQuest = true,
                IsCampaignQuest = true,
                Zone = 2413,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 110329, criteriaIndex = 1, scenarioID = 3243, stepID = 16417 },
                Coord = { x = 747.4, y = -244.8 },
                Range = 15,
                InstanceQuest = true,
                Zone = 2413,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 60399, criteriaIndex = 1, scenarioID = 3243, stepID = 16418 },
                Coord = { x = 624.7, y = -235.5 },
                Range = 5,
                InstanceQuest = true,
                Zone = 2413,
            }
            ,
        }),
    },
})

RegisterDelveRoute("COLLEGIATE_CALAMITY_DELVE", {
    label = "Collegiate Calamity",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2577,
    scenarios = {
        -- DelveScenarioBlock(0, 1, "Invasive Glow"),
        -- DelveScenarioBlock(0, 2, "Faculty of Fear"),
        DelveScenarioBlock(3193, 3, "Academy Under Siege", {
            {
                Scenario = { questID = 1, criteriaID = 108804, criteriaIndex = 1, scenarioID = 3193, stepID = 16121 },
                Coord = { x = -4451.7, y = 8802.5 },
                GossipOptionIDs = { 135865 },
                InstanceQuest = true,
                Zone = 2395,
                _index = 10,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 109132, criteriaIndex = 2, scenarioID = 3193, stepID = 16122 },
                Coord = { x = -4405.9, y = 8787.8 },
                Range = 5,
                ExtraActionB = true,
                InstanceQuest = true,
                Zone = 2395,
                _index = 11,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 0, criteriaIndex = 1, scenarioID = 3193, stepID = 16122 },
                Coord = { x = -4366.1, y = 8752.4 },
                Range = 100,
                InstanceQuest = true,
                Zone = 2395,
                _index = 12,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 111611, criteriaIndex = 1, scenarioID = 3193, stepID = 16123 },
                Coord = { x = -4393.9, y = 8714.4 },
                Range = 5,
                Zone = 2395,
                _index = 13,
            }
            ,
        }),
    },
})

RegisterDelveRoute("ATAL_AMAN_DELVE", {
    label = "Atal'Aman",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2535,
    scenarios = {
        -- DelveScenarioBlock(0, 1, "Totem Annihilation"),
        DelveScenarioBlock(3148, 2, "Toadly Unbecoming", {
            {
                Scenario = { questID = 1, criteriaID = 109254, criteriaIndex = 1, scenarioID = 3148, stepID = 16162 },
                Coord = { x = -5952.3, y = 5185.9 },
                GossipOptionIDs = { 136385 },
                Zone = 2437,
                _index = 14,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 109366, criteriaIndex = 1, scenarioID = 3148, stepID = 16166 },
                Coord = { x = -5957.4, y = 5182.7 },
                Range = 1,
                Zone = 2437,
                _index = 15,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 109361, criteriaIndex = 2, scenarioID = 3148, stepID = 16009 },
                Coord = { x = -6207.9, y = 4918.1 },
                Range = 100,
                Zone = 2437,
                _index = 16,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 112426, criteriaIndex = 2, scenarioID = 3148, stepID = 16010 },
                GossipOptionIDs = { 138496 },
                NoArrow = true,
                Zone = 2437,
                _index = 17,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 111692, criteriaIndex = 1, scenarioID = 3148, stepID = 16010 },
                Coord = { x = -6240.1, y = 5052.2 },
                Range = 5,
                Zone = 2437,
                _index = 18,
            }
            ,
        }),
        -- DelveScenarioBlock(0, 3, "Ritual Interrupted"),
    },
})

RegisterDelveRoute("TWILIGHT_CRYPTS_DELVE", {
    label = "Twilight Crypts",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2503,
    scenarios = {
        -- DelveScenarioBlock(0, 1, "Party Crasher"),
        DelveScenarioBlock(3124, 2, "Loosed Loa", {
            {
                Scenario = { criteriaID = 105376, criteriaIndex = 1, questID = 91918, scenarioID = 3124, stepID = 15965 },
                Coord = { x = -675, y = 38.4 },
                Zone = 2437,
                GossipOptionIDs = { 135634 },
                InstanceQuest = true,
                _index = 19,
            }
            ,
            {
                Scenario = { criteriaID = 106442, criteriaIndex = 1, questID = 91918, scenarioID = 3124, stepID = 15966 },
                Coord = { x = -666, y = 22 },
                Zone = 2437,
                Range = 0.5,
                InstanceQuest = true,
                _index = 20,
            }
            ,
            {
                Scenario = { criteriaID = 108849, criteriaIndex = 2, questID = 91918, scenarioID = 3124, stepID = 15966 },
                Coord = { x = -548.7, y = -197.3 },
                Zone = 2437,
                Range = 5,
                InstanceQuest = true,
                _index = 21,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -522.3, y = -207.3 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 22,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -574.7, y = -203.1 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 23,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -563.1, y = -97.9 },
                Zone = 2437,
                Range = 5,
                _index = 24,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -534.3, y = -69.2 },
                Zone = 2437,
                Range = 5,
                _index = 25,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -501, y = -45.4 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 26,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -505.1, y = 2.1 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 27,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -476.5, y = -69 },
                Zone = 2437,
                Range = 5,
                _index = 28,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -460.7, y = -83.7 },
                Zone = 2437,
                Range = 5,
                _index = 29,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -410.3, y = -72.4 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 30,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -414.9, y = -123.6 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 31,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -462.1, y = -112.8 },
                Zone = 2437,
                Range = 5,
                _index = 32,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -487.8, y = -141.4 },
                Zone = 2437,
                Range = 8,
                _index = 33,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -533.8, y = -141.3 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 34,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -562.9, y = -127.4 },
                Zone = 2437,
                Range = 5,
                _index = 35,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -563.2, y = -112.4 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 36,
            }
            ,
            {
                Waypoint = 91918,
                Coord = { x = -674, y = -122.9 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                Range = 5,
                _index = 37,
            }
            ,
            {
                Scenario = { criteriaID = 106443, criteriaIndex = 1, questID = 91918, scenarioID = 3124, stepID = 15967 },
                Coord = { x = -674, y = -122.9 },
                Zone = 2437,
                ExtraLineText = "CLICK_ON_LEVERS",
                InstanceQuest = true,
                _index = 38,
            }
            ,
            {
                Scenario = { criteriaID = 60399, criteriaIndex = 1, questID = 91918, scenarioID = 3124, stepID = 15969 },
                Coord = { x = -672.4, y = -22.3 },
                Zone = 2437,
                Range = 10,
                InstanceQuest = true,
                _index = 39,
            }
            ,
        }),
        DelveScenarioBlock(3125, 3, "Trapped!", {
            {
                Scenario = { questID = 1, criteriaID = 105376, criteriaIndex = 1, scenarioID = 3125, stepID = 15970 },
                Coord = { x = -669.1, y = 32.9 },
                GossipOptionIDs = { 135811 },
                InstanceQuest = true,
                Zone = 2437,
                _index = 40,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106448, criteriaIndex = 1, scenarioID = 3125, stepID = 15971 },
                Coord = { x = -671.3, y = 35.2 },
                Range = 1,
                ExtraActionB = true,
                InstanceQuest = true,
                Zone = 2437,
                _index = 41,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 106449, criteriaIndex = 2, scenarioID = 3125, stepID = 15972 },
                Coord = { x = -480.5, y = -113.7 },
                Range = 100,
                InstanceQuest = true,
                Zone = 2437,
                _index = 42,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 109100, criteriaIndex = 1, scenarioID = 3125, stepID = 15972 },
                Coord = { x = -480.5, y = -113.7 },
                Range = 100,
                InstanceQuest = true,
                Zone = 2437,
                _index = 43,
            }
            ,
            {
                Scenario = { questID = 1, criteriaID = 60399, criteriaIndex = 1, scenarioID = 3125, stepID = 15974 },
                Coord = { x = -509, y = -12.7 },
                Range = 5,
                InstanceQuest = true,
                Zone = 2437,
                _index = 44,
            }
            ,
        }),
    },
})

RegisterDelveRoute("THE_DARKWAY_DELVE", {
    label = "The Darkway",
    expansion = APR.EXPANSIONS.Midnight,
    mapID = 2525,
    scenarios = {
        DelveScenarioBlock(3184, 1, "Focusers Under Pressure", {
            {
                Scenario = { criteriaID = 105376, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16133 },
                Coord = { x = 4799.3, y = 3544.5 },
                Zone = 2395,
                GossipOptionIDs = { 136141 },
                InstanceQuest = true,
                IsCampaignQuest = true,
                _index = 45,
            },
            {
                Scenario = { criteriaID = 108818, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16100 },
                Coord = { x = 4808.8, y = 3369.4 },
                Zone = 2395,
                Range = 2,
                InstanceQuest = true,
                _index = 46,
            },
            {
                Scenario = { criteriaID = 108822, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16102 },
                Coord = { x = 4804.9, y = 3237.1 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                _index = 47,
            },
            {
                Waypoint = 1,
                Coord = { x = 4772.9, y = 3225.9 },
                Zone = 2395,
                Range = 5,
                _index = 48,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4813.6, y = 3197.5 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "1/6",
                _index = 49,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4718.2, y = 3245.6 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "2/6",
                _index = 50,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4684.8, y = 3337.3 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "3/6",
                _index = 51,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4706.8, y = 3414.7 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "4/6",
                _index = 52,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4888.2, y = 3414.5 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "5/6",
                _index = 53,
            },
            {
                Waypoint = 1,
                Coord = { x = 4963.1, y = 3387.5 },
                Zone = 2395,
                Range = 10,
                _index = 54,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4978.3, y = 3337.6 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "6/6",
                _index = 55,
            },
            {
                Scenario = { criteriaID = 111466, criteriaIndex = 2, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4978.3, y = 3337.6 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                _index = 56,
            },
            {
                Waypoint = 1,
                Coord = { x = 4961.9, y = 3388.5 },
                Zone = 2395,
                Range = 10,
                _index = 57,
            },
            {
                Waypoint = 1,
                Coord = { x = 4860.1, y = 3414.5 },
                Zone = 2395,
                Range = 10,
                _index = 58,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4761.6, y = 3362.1 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "1/6",
                _index = 59,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4748.8, y = 3321.6 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "2/6",
                _index = 60,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4765.9, y = 3283.2 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "3/6",
                _index = 61,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4845.3, y = 3282.5 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "4/6",
                _index = 62,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4860.2, y = 3323 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "5/6",
                _index = 63,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4840.9, y = 3359.9 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                TrigText = "6/6",
                _index = 64,
            },
            {
                Scenario = { criteriaID = 108820, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16101 },
                Coord = { x = 4843.8, y = 3356.1 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                _index = 65,
            },
            {
                Waypoint = 1,
                Coord = { x = 4804.8, y = 3238.1 },
                Zone = 2395,
                Range = 10,
                _index = 66,
            },
            {
                Scenario = { criteriaID = 60399, criteriaIndex = 1, questID = 1, scenarioID = 3184, stepID = 16103 },
                Coord = { x = 4813.1, y = 3099.4 },
                Zone = 2395,
                Range = 5,
                InstanceQuest = true,
                _index = 67,
            }
        }),
        -- DelveScenarioBlock(0, 1, "Leyline Technician"),
        -- DelveScenarioBlock(0, 1, "Ogre Powered"),

    },
})
