-- same route for both faction
-- WakingShores neutral
APR.RouteQuestStepList["DF03N-2022-WakingShores"] = {
    { -- Step 1
        ["PickUp"] = {
            69914,
        },
        ["Coord"] = {
            ["y"] = 3535.9,
            ["x"] = -1427.5,
        },
    },
    { -- Step 2
        ["Qpart"] = {
            [69914] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3535.9,
            ["x"] = -1427.5,
        },
        ["Range"] = 1,
        ["Gossip"] = 3,
        ["ETA"] = 50,
    },
    { -- Step 3
        ["Done"] = {
            69914,
        },
        ["Coord"] = {
            ["y"] = 3542.3,
            ["x"] = -1430.1,
        },
    },
    { -- Step 4
        ["PickUp"] = {
            65760,
        },
        ["Coord"] = {
            ["y"] = 3542.3,
            ["x"] = -1430.1,
        },
    },
    { -- Step 5
        ["Qpart"] = {
            [65760] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3542.3,
            ["x"] = -1430.1,
        },
        ["Range"] = 1,
        ["Gossip"] = 3,
    },
    { -- Step 6
        ["Qpart"] = {
            [65760] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 3204.3,
            ["x"] = -1027.2,
        },
        ["Range"] = 25,
        ["ExtraLineText"] = "FOLLOW_SENDRAX_CLOSELY",
    },
    { -- Step 7
        ["Done"] = {
            65760,
        },
        ["Coord"] = {
            ["y"] = 3204.3,
            ["x"] = -1027.2,
        },
    },
    { -- Step 8
        ["PickUp"] = {
            65989,
            65990,
        },
        ["Coord"] = {
            ["y"] = 3204.3,
            ["x"] = -1027.2,
        },
    },
    { -- Step 9
        ["Qpart"] = {
            [65990] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2992.0,
            ["x"] = -968.1,
        },
        ["Range"] = 110,
        ["Fillers"] = { [65989] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "WHELPS_ARE_CONVENIENTLY_MARKED_ON_YOUR_MAP",
    },
    { -- Step 10
        ["Qpart"] = {
            [65989] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2992.0,
            ["x"] = -968.1,
        },
        ["Range"] = 110,
    },
    { -- Step 11
        ["Done"] = {
            65989,
            65990,
        },
        ["Coord"] = {
            ["y"] = 3204.3,
            ["x"] = -1027.2,
        },
    },
    { -- Step 12
        ["PickUp"] = {
            65991,
        },
        ["Coord"] = {
            ["y"] = 3204.3,
            ["x"] = -1027.2,
        },
    },
    { -- Step 13
        ["Waypoint"] = 65991,
        ["Coord"] = {
            ["y"] = 3486.2,
            ["x"] = -633.9,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["Range"] = 5,
    },
    { -- Step 14
        ["Qpart"] = {
            [65991] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3524.4,
            ["x"] = -639.1,
        },
        ["Range"] = 10,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "UP_RAMP",
    },
    { -- Step 15
        ["Done"] = {
            65991,
        },
        ["Coord"] = {
            ["y"] = 3513.9,
            ["x"] = -639.8,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 16
        ["PickUp"] = {
            65993,
            65992,
        },
        ["Coord"] = {
            ["y"] = 3513.9,
            ["x"] = -639.8,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 17
        ["Waypoint"] = 65993,
        ["Coord"] = {
            ["y"] = 3603.2,
            ["x"] = -494.6,
        },
        ["Range"] = 25,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "JUMP_DOWN_USE_GOBLIN_GLIDER",
    },
    { -- Step 18
        ["Waypoint"] = 66956,
        ["Coord"] = {
            ["y"] = 3621.8,
            ["x"] = -467.5,
        },
        ["Range"] = 20,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 19
        ["Qpart"] = {
            [66956] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3621.8,
            ["x"] = -467.5,
        },
        ["Range"] = 20,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KILL_DRAGONHUNTER_IGORDAN_BONUS_OBJECTIVE",
        ["RaidIcon"] = 191611,
    },
    { -- Step 20
        ["Qpart"] = {
            [65992] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3598.8,
            ["x"] = -375.5,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "CONSULT_KAVIA",
        ["Gossip"] = 1,
    },
    { -- Step 21
        ["Waypoint"] = 65992,
        ["Coord"] = {
            ["y"] = 3672.0,
            ["x"] = -370.7,
        },
        ["Range"] = 10,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 22
        ["Qpart"] = {
            [65993] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3807.2,
            ["x"] = -365.5,
        },
        ["Range"] = 20,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["RaidIcon"] = 186777,
    },
    { -- Step 23
        ["PickUp"] = {
            65995,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 24
        ["Qpart"] = {
            [65992] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 3836.6,
            ["x"] = -406.3,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "CONSULT_LEFT",
        ["Gossip"] = 1,
    },
    { -- Step 25
        ["Qpart"] = {
            [65992] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 3811.4,
            ["x"] = -539.4,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "CONSULT_RIGHT",
        ["Gossip"] = 1,
    },
    { -- Step 26
        ["Waypoint"] = 65993,
        ["Coord"] = {
            ["y"] = 3593.7,
            ["x"] = -479.0,
        },
        ["Range"] = 20,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 27
        ["Waypoint"] = 65993,
        ["Coord"] = {
            ["y"] = 3599.3,
            ["x"] = -367.5,
        },
        ["Range"] = 10,
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "UP_RAMP",
    },
    { -- Step 28
        ["Done"] = {
            65993,
            65992,
            65995,
        },
        ["Coord"] = {
            ["y"] = 3610.1,
            ["x"] = -343.1,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 29
        ["PickUp"] = {
            65996,
        },
        ["Coord"] = {
            ["y"] = 3612.5,
            ["x"] = -350.0,
        },
        ["Fillers"] = { [65994] = { ["1"] = "1", }, },
    },
    { -- Step 30
        ["Qpart"] = {
            [65994] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3587.2,
            ["x"] = -446.5,
        },
        ["Range"] = 256,
    },
    { -- Step 31
        ["PickUp"] = {
            66998,
        },
        ["Coord"] = {
            ["y"] = 3518.6,
            ["x"] = -60.9,
        },
        ["Fillers"] = { [65996] = { ["1"] = "1", }, },
        ["Button"] = {
            ["66998"] = 193917,
        },
    },
    { -- Step 32
        ["Qpart"] = {
            [66998] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3640.5,
            ["x"] = -54.2,
        },
        ["Range"] = 75,
        ["Fillers"] = { [65996] = { ["1"] = "1", }, },
        ["Button"] = {
            ["66998-1"] = 193917,
        },
    },
    { -- Step 33
        ["Done"] = {
            66998,
        },
        ["Coord"] = {
            ["y"] = 3518.6,
            ["x"] = -60.9,
        },
        ["Fillers"] = { [65996] = { ["1"] = "1", }, },
    },
    { -- Step 34
        ["Qpart"] = {
            [65996] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3541.4,
            ["x"] = -79.3,
        },
        ["Range"] = 290,
        ["Button"] = {
            ["65996-1"] = 193917,
        },
    },
    { -- Step 35
        ["Qpart"] = {
            [65996] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 3736.3,
            ["x"] = 267.8,
        },
        ["Range"] = 2,
    },
    { -- Step 36
        ["Done"] = {
            65996,
        },
        ["Coord"] = {
            ["y"] = 3736.3,
            ["x"] = 267.8,
        },
    },
    { -- Step 37
        ["PickUp"] = {
            65997,
        },
        ["Coord"] = {
            ["y"] = 3736.3,
            ["x"] = 267.8,
        },
    },
    { -- Step 38
        ["Qpart"] = {
            [65997] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 4045.7,
            ["x"] = 252.2,
        },
        ["Range"] = 2,
        ["Gossip"] = 3,
        ["GossipOptionID"] = 55225,
    },
    { -- Step 39
        ["Done"] = {
            65997,
        },
        ["Coord"] = {
            ["y"] = 4045.7,
            ["x"] = 252.2,
        },
    },
    { -- Step 40
        ["PickUp"] = {
            65998,
            65999,
        },
        ["Coord"] = {
            ["y"] = 4045.7,
            ["x"] = 252.2,
        },
    },
    { -- Step 41
        ["PickUp"] = {
            66000,
        },
        ["Coord"] = {
            ["y"] = 4058.7,
            ["x"] = 246.3,
        },
        ["ExtraLineText"] = "GET_QUEST_FROM_BOOK_ON_ROCK",
    },
    { -- Step 42
        ["Waypoint"] = 70648,
        ["Coord"] = {
            ["y"] = 4075.9,
            ["x"] = 154.9,
        },
        ["Range"] = 25,
    },
    { -- Step 43
        ["DropQuest"] = 70648,
        ["DroppableQuest"] = {
            ["Text"] = "FIRAVA_REKINDLER",
            ["Qid"] = 70648,
            ["MobId"] = 195915,
        },
        ["Coord"] = {
            ["y"] = 4075.9,
            ["x"] = 154.9,
        },
        ["Range"] = 25,
        ["Fillers"] = {
            [66000] = { ["1"] = "1", },
            [65998] = { ["1"] = "1", ["2"] = "2", },
            [65999] = { ["1"] = "1", },
            [70648] = { ["1"] = "1", },
        },
        ["ExtraLineText"] = "KILL_FIRAVA_REKINDLER_RESPAWNS_WITHIN_A_MINUTE_WANDERS_AROUND_THE_AREA",
        ["RaidIcon"] = 195915,
    },
    { -- Step 44
        ["Qpart"] = {
            [65999] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 4152.9,
            ["x"] = 180.6,
        },
        ["Range"] = 165,
        ["Fillers"] = { [66000] = { ["1"] = "1", }, [65998] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 45
        ["Qpart"] = {
            [66000] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 4152.9,
            ["x"] = 180.6,
        },
        ["Range"] = 165,
        ["Fillers"] = { [65998] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 46
        ["Qpart"] = {
            [65998] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 4152.9,
            ["x"] = 180.6,
        },
        ["Range"] = 165,
    },
    { -- Step 47
        ["Done"] = {
            65998,
            65999,
            66000,
        },
        ["Coord"] = {
            ["y"] = 4152.9,
            ["x"] = 180.6,
        },
        ["ExtraLineText"] = "TURN_IN_SENDRAX_WHO_SHOULD_BE_STANDING_NEXT_TO_YOU",
    },
    { -- Step 48
        ["PickUp"] = {
            66001,
        },
        ["Coord"] = {
            ["y"] = 4152.9,
            ["x"] = 180.6,
        },
        ["ExtraLineText"] = "PICK_UP_FROM_SENDRAX_WHO_SHOULD_BE_STANDING_NEXT_YOU",
    },
    { -- Step 49
        ["Waypoint"] = 66001,
        ["Coord"] = {
            ["y"] = 4199.5,
            ["x"] = 166.6,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "MEET_SENDRAX_BY_RITUAL_SITE_SPEAK_HER_WHEN_READY",
    },
    { -- Step 50
        ["Qpart"] = {
            [66001] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 4199.5,
            ["x"] = 166.6,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "TALK_SENDRAX",
        ["Gossip"] = 1,
        ["RaidIcon"] = 190269,
    },
    { -- Step 51
        ["Qpart"] = {
            [66001] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 4223.1,
            ["x"] = 113.5,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "GRAB_EGG",
    },
    { -- Step 52
        ["Qpart"] = {
            [66001] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 3735.7,
            ["x"] = 267.4,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "CARRY_EGG_SAFETY_DO_NOT_GET_ON_YOUR_MOUNT_OR_YOU_WILL_DROP_THE_EGG",
    },
    { -- Step 53
        ["PickUp"] = {
            70179,
        },
        ["Coord"] = {
            ["y"] = 3731.7,
            ["x"] = 311.4,
        },
    },
    { -- Step 54
        ["Qpart"] = {
            [70179] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 3657.8,
            ["x"] = 536.8,
        },
        ["Range"] = 200,
    },
    { -- Step 55
        ["Done"] = {
            70179,
        },
        ["Coord"] = {
            ["y"] = 3731.7,
            ["x"] = 311.4,
        },
    },
    { -- Step 56
        ["Done"] = {
            66001,
        },
        ["Coord"] = {
            ["y"] = 3724.5,
            ["x"] = 260.8,
        },
    },
    { -- Step 57
        ["PickUp"] = {
            66114,
        },
        ["Coord"] = {
            ["y"] = 3724.5,
            ["x"] = 260.8,
        },
    },
    { -- Step 58
        ["Qpart"] = {
            [66114] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1495.1,
            ["x"] = -312.5,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "RIDE_MAJORDOMO_SELISTRA_RUBY_LIFESHRINE",
        ["Gossip"] = 1,
        ["ETA"] = 65,
    },
    { -- Step 59
        ["Qpart"] = {
            [66114] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1488.0,
            ["x"] = -319.0,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "SHOW_ALEXSTRASZA_EGG",
        ["Gossip"] = 1,
        ["RaidIcon"] = 107094,
    },
    { -- Step 60
        ["Done"] = {
            66114,
        },
        ["Coord"] = {
            ["y"] = 1488.0,
            ["x"] = -319.0,
        },
    },
    { -- Step 61
        ["PickUp"] = {
            66115,
            68795,
        },
        ["Coord"] = {
            ["y"] = 1488.0,
            ["x"] = -319.0,
        },
    },
    { -- Step 62
        ["Qpart"] = {
            [66115] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1433.3,
            ["x"] = -188.6,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55288,
    },
    { -- Step 63
        ["Qpart"] = {
            [66115] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1519.4,
            ["x"] = -83.3,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55289,
    },
    { -- Step 64
        ["GetFP"] = 2807,
        ["Coord"] = {
            ["y"] = 1749.1,
            ["x"] = 41.9,
        },
        ["Range"] = 5,
    },
    { -- Step 65
        ["Qpart"] = {
            [68795] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1801.0,
            ["x"] = -2.4,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55643,
    },
    { -- Step 66
        ["PickUp"] = {
            70132,
        },
        ["Coord"] = {
            ["y"] = 1818.4,
            ["x"] = 39.3,
        },
        ["Range"] = 5,
    },
    { -- Step 67
        ["Qpart"] = {
            [70132] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1818.4,
            ["x"] = 39.3,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "CLICK_EXTRAACTIONBUTTON",
        ["SpellButton"] = {
            ["70132-1"] = 383740,
        },
        ["ExtraActionB"] = 1,
    },
    { -- Step 68
        ["Qpart"] = {
            [70132] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1818.4,
            ["x"] = 39.3,
        },
        ["Range"] = 1,
        ["Gossip"] = 2,
        ["GossipOptionID"] = 63862,
    },
    { -- Step 69
        ["Done"] = {
            70132,
        },
        ["Coord"] = {
            ["y"] = 1818.4,
            ["x"] = 39.3,
        },
    },
    { -- Step 70
        ["Done"] = {
            68795,
        },
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
    },
    { -- Step 71
        ["PickUp"] = {
            65118,
        },
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
    },
    { -- Step 72
        ["Waypoint"] = 65118,
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "MOUNT_ON_YOUR_DRAGON",
    },
    { -- Step 73
        ["Qpart"] = {
            [65118] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1822.4,
            ["x"] = 51.6,
        },
        ["Range"] = 50,
        ["ExtraLineText"] = "MOVE_EDGE_POINT_YOUR_CAMERA_AT_FIRST_RING_AND_WALK_OFF_EDGE_DO_NOT_JUMP",
    },
    { -- Step 74
        ["Qpart"] = {
            [65118] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2216.1,
            ["x"] = 68.1,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "LAND_ON_ROCK",
    },
    { -- Step 75
        ["Done"] = {
            65118,
        },
        ["Coord"] = {
            ["y"] = 2228.3,
            ["x"] = 70.4,
        },
    },
    { -- Step 76
        ["PickUp"] = {
            65120,
        },
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
    },
    { -- Step 77
        ["Waypoint"] = 65120,
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "MOUNT_ON_YOUR_DRAGON",
    },
    { -- Step 78
        ["Qpart"] = {
            [65120] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1822.4,
            ["x"] = 51.6,
        },
        ["Range"] = 50,
        ["ExtraLineText"] = "MOVE_EDGE_POINT_YOUR_CAMERA_AT_FIRST_RING_AND_WALK_OFF_EDGE_DO_NOT_JUMP",
    },
    { -- Step 79
        ["Qpart"] = {
            [65120] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2216.1,
            ["x"] = 68.1,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "LAND_ON_ROCK",
    },
    { -- Step 80
        ["Done"] = {
            65120,
        },
        ["Coord"] = {
            ["y"] = 2228.3,
            ["x"] = 70.4,
        },
    },
    { -- Step 81
        ["PickUp"] = {
            65133,
        },
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
    },
    { -- Step 82
        ["Waypoint"] = 65133,
        ["Coord"] = {
            ["y"] = 2228.3,
            ["x"] = 70.4,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "MOUNT_ON_YOUR_DRAGON",
    },
    { -- Step 83
        ["Qpart"] = {
            [65133] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1822.4,
            ["x"] = 51.6,
        },
        ["Range"] = 50,
        ["ExtraLineText"] = "MOVE_EDGE_POINT_YOUR_CAMERA_AT_FIRST_RING_AND_WALK_OFF_EDGE_DO_NOT_JUMP",
    },
    { -- Step 84
        ["Qpart"] = {
            [65133] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2216.1,
            ["x"] = 68.1,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "LAND_ON_ROCK",
    },
    { -- Step 85
        ["Done"] = {
            65133,
        },
        ["Coord"] = {
            ["y"] = 2228.3,
            ["x"] = 70.4,
        },
    },
    { -- Step undefined
        ["PickUp"] = {
            77345,
        },
    },
    { -- Step undefined
        ["Done"] = {
            77345,
        },
    },
    { -- Step 86
        ["PickUp"] = {
            68796,
        },
        ["Coord"] = {
            ["y"] = 1813.8,
            ["x"] = 54.5,
        },
    },
    { -- Step 87
        ["Qpart"] = {
            [68796] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1822.3,
            ["x"] = 49.2,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "SPEAK_WITH_CELORMU_START_RACE",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 107284,
    },
    { -- Step 88
        ["Qpart"] = {
            [68796] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1822.3,
            ["x"] = 49.2,
        },
        ["Range"] = 20,
        ["ExtraLineText"] =
        "USE_SURGE_FORWARD_PASS_FIRST_FOUR_RINGS_USE_ASCEND_TO_REACH_RING_FIVE_AND_ONCE_MORE_JUST_AFTER",
    },
    { -- Step 89
        ["Done"] = {
            68796,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 90
        ["PickUp"] = {
            68797,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 91
        ["Qpart"] = {
            [68797] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2290.5,
            ["x"] = -1258.5,
        },
        ["Range"] = 1,
    },
    { -- Step 92
        ["Qpart"] = {
            [68797] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2279.7,
            ["x"] = -1252.5,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "CLICK_ROSTRUM_OF_TRANSFORMATION",
    },
    { -- Step 93
        ["Done"] = {
            68797,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 94
        ["PickUp"] = {
            68798,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 95
        ["Qpart"] = {
            [68798] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2309.4,
            ["x"] = -1277.1,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "GET_DRAGON_GLYPH_FLOATING_IN_SKY_BY_FLYING_THROUGH_IT",
    },
    { -- Step 96
        ["Qpart"] = {
            [68798] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2341.5,
            ["x"] = -1295.2,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "SPEAK_WITH_LITHRAGOSA",
    },
    { -- Step 97
        ["Qpart"] = {
            [68798] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2341.5,
            ["x"] = -1295.2,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "SPEAK_WITH_LITHRAGOSA",
        ["Gossip"] = 2,
        ["GossipOptionID"] = 55584,
    },
    { -- Step 98
        ["Qpart"] = {
            [68798] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 2341.5,
            ["x"] = -1295.2,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "LEAN_TAKE_THE_SKIES_SKILL",
    },
    { -- Step 99
        ["Qpart"] = {
            [68798] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = 2602.8,
            ["x"] = -1190.0,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "SPEAK_CELORMU",
        ["Gossip"] = 1,
    },
    { -- Step 100
        ["Done"] = {
            68798,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 101
        ["PickUp"] = {
            68799,
        },
        ["Coord"] = {
            ["y"] = 2447.8,
            ["x"] = -1343.5,
        },
    },
    { -- Step 102
        ["Qpart"] = {
            [68799] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2415.8,
            ["x"] = -1331.0,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "HOP_ON_RELASTRASZA",
    },
    { -- Step 103
        ["Qpart"] = {
            [68799] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2335.3,
            ["x"] = -1349.0,
        },
        ["Range"] = 5,
        ["ETA"] = 20,
    },
    { -- Step 104
        ["Waypoint"] = 66115,
        ["Coord"] = {
            ["y"] = 1717.6,
            ["x"] = -253.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "DRAGONRIDE_BACK_TOWARDS_RUBY_LIFESHRINE",
    },
    { -- Step 105
        ["Qpart"] = {
            [66115] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.0,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "SPEAK_MOTHER_ELION",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55258,
    },
    { -- Step 106
        ["Qpart"] = {
            [66115] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 1625.1,
            ["x"] = -353.3,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "SPEAK_ZAHKRANA",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55290,
    },
    { -- Step 107
        ["Done"] = {
            66115,
        },
        ["Coord"] = {
            ["y"] = 1625.1,
            ["x"] = -353.3,
        },
    },
    { -- Step 108
        ["PickUp"] = {
            70061,
        },
        ["Coord"] = {
            ["y"] = 1617.9,
            ["x"] = -306.2,
        },
    },
    { -- Step 109
        ["Qpart"] = {
            [70061] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1570.8,
            ["x"] = -218.9,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "HOP_ON_RUBY_WHELPLING",
    },
    { -- Step 110
        ["Qpart"] = {
            [70061] = {
                ["2"] = "2",
                ["3"] = "3",
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 1550.1,
            ["x"] = -242.2,
        },
        ["Range"] = 35,
    },
    { -- Step 111
        ["Done"] = {
            70061,
        },
        ["Coord"] = {
            ["y"] = 1494.5,
            ["x"] = -317.1,
        },
    },
    { -- Step 112
        ["Done"] = {
            68799,
        },
        ["Coord"] = {
            ["y"] = 1488.0,
            ["x"] = -318.8,
        },
    },
    { -- Step 113
        ["PickUp"] = {
            66931,
        },
        ["Coord"] = {
            ["y"] = 1488.0,
            ["x"] = -318.8,
        },
    },
    { -- Step 114
        ["Qpart"] = {
            [66931] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1509.0,
            ["x"] = -93.8,
        },
        ["Range"] = 10,
    },
    { -- Step 115
        ["Done"] = {
            66931,
        },
        ["Coord"] = {
            ["y"] = 1509.0,
            ["x"] = -93.8,
        },
    },
    { -- Step 116
        ["PickUp"] = {
            66116,
        },
        ["Coord"] = {
            ["y"] = 1509.0,
            ["x"] = -93.8,
        },
    },
    { -- Step 117
        ["Qpart"] = {
            [66116] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1335.3,
            ["x"] = -84.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "GET_ON_DRAGONMOUNT_HOP_OVER_SIDE_GLIDE_DOWN_COMMANDER_LETHANAK",
    },
    { -- Step 118
        ["Done"] = {
            66116,
        },
        ["Coord"] = {
            ["y"] = 1336.3,
            ["x"] = -85.9,
        },
    },
    { -- Step 119
        ["PickUp"] = {
            66118,
        },
        ["Coord"] = {
            ["y"] = 1336.3,
            ["x"] = -85.9,
        },
    },
    { -- Step 120
        ["Qpart"] = {
            [66118] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1222.9,
            ["x"] = -102.7,
        },
        ["Range"] = 100,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, },
    },
    { -- Step 121
        ["Done"] = {
            66118,
        },
        ["Coord"] = {
            ["y"] = 1336.3,
            ["x"] = -85.9,
        },
    },
    { -- Step 122
        ["PickUp"] = {
            66122,
        },
        ["Coord"] = {
            ["y"] = 1336.3,
            ["x"] = -85.9,
        },
    },
    { -- Step 123
        ["PickUp"] = {
            66121,
        },
        ["Coord"] = {
            ["y"] = 1320.4,
            ["x"] = -91.7,
        },
    },
    { -- Step 124
        ["Qpart"] = {
            [66121] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1047.0,
            ["x"] = 175.9,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, [66122] = { ["2"] = "2", }, },
        ["ExtraLineText"] = "RESCUE_BRONZE_EGG",
    },
    { -- Step 125
        ["Qpart"] = {
            [66121] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 1065.7,
            ["x"] = 267.8,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, [66122] = { ["2"] = "2", }, [66960] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "RESCUE_RUBY_EGG",
    },
    { -- Step 126
        ["Qpart"] = {
            [66121] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 940.3,
            ["x"] = 241.0,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, [66122] = { ["2"] = "2", }, [66960] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "RESCUE_EMERALD_EGG",
    },
    { -- Step 127
        ["Qpart"] = {
            [66960] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 998.7,
            ["x"] = 282,
        },
        ["Range"] = 45,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, [66122] = { ["2"] = "2", }, },
    },
    { -- Step 128
        ["Qpart"] = {
            [66121] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 942.0,
            ["x"] = 79.2,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, [66122] = { ["2"] = "2", }, },
        ["ExtraLineText"] = "RESCUE_AZURE_EGG",
    },
    { -- Step 129
        ["Qpart"] = {
            [66122] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1039.0,
            ["x"] = 212.0,
        },
        ["Range"] = 225,
        ["Fillers"] = { [66117] = { ["1"] = "1", }, },
        ["Button"] = {
            ["66122-2"] = 192436,
        },
    },
    { -- Step 130
        ["Qpart"] = {
            [66117] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1039.0,
            ["x"] = 212.0,
        },
        ["Range"] = 225,
    },
    { -- Step 131
        ["Done"] = {
            66122,
        },
        ["Coord"] = {
            ["y"] = 1108.9,
            ["x"] = 371.5,
        },
    },
    { -- Step 132
        ["Done"] = {
            66121,
        },
        ["Coord"] = {
            ["y"] = 1108.9,
            ["x"] = 371.5,
        },
    },
    { -- Step 133
        ["PickUp"] = {
            66123,
        },
        ["Coord"] = {
            ["y"] = 1108.9,
            ["x"] = 371.5,
        },
    },
    { -- Step 134
        ["Qpart"] = {
            [66123] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 956.7,
            ["x"] = 376,
        },
        ["Range"] = 45,
        ["ExtraLineText"] = "USE_ITEM_FOR_DAMAGE_BOOST",
        ["Button"] = {
            ["66123-1"] = 192436,
        },
    },
    { -- Step 135
        ["Done"] = {
            66123,
        },
        ["Coord"] = {
            ["y"] = 1108.9,
            ["x"] = 371.5,
        },
    },
    { -- Step 136
        ["PickUp"] = {
            66124,
        },
        ["Coord"] = {
            ["y"] = 1108.9,
            ["x"] = 371.5,
        },
    },
    { -- Step 137
        ["PickUp"] = {
            66963,
        },
        ["Coord"] = {
            ["y"] = 1177.4,
            ["x"] = 786.9,
        },
    },
    { -- Step 138
        ["Done"] = {
            66963,
        },
        ["Coord"] = {
            ["y"] = 974.0,
            ["x"] = 786.2,
        },
    },
    { -- Step 139
        ["PickUp"] = {
            66524,
        },
        ["Coord"] = {
            ["y"] = 974.0,
            ["x"] = 786.2,
        },
    },
    { -- Step 140
        ["GetFP"] = 2809,
        ["Coord"] = {
            ["y"] = 939.9,
            ["x"] = 832.6,
        },
        ["Range"] = 5,
    },
    { -- Step 141
        ["Qpart"] = {
            [66524] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1002.2,
            ["x"] = 1030.9,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "JUMP_OFF_CLIFF_EGG_IS_DOWN_BELOW",
        ["Button"] = {
            ["66524-1"] = 192465,
        },
    },
    { -- Step 142
        ["Qpart"] = {
            [66524] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1024.2,
            ["x"] = 1152.5,
        },
        ["Range"] = 20,
        ["Button"] = {
            ["66524-2"] = 192465,
        },
    },
    { -- Step 143
        ["Qpart"] = {
            [66524] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1196.1,
            ["x"] = 1140.3,
        },
        ["Range"] = 20,
        ["Button"] = {
            ["66524-3"] = 192465,
        },
    },
    { -- Step 144
        ["Done"] = {
            66524,
        },
        ["Coord"] = {
            ["y"] = 944.0,
            ["x"] = 1541.5,
        },
    },
    { -- Step 145
        ["PickUp"] = {
            66525,
        },
        ["Coord"] = {
            ["y"] = 944.0,
            ["x"] = 1541.5,
        },
    },
    { -- Step 146
        ["PickUp"] = {
            66526,
        },
        ["Coord"] = {
            ["y"] = 942.2,
            ["x"] = 1536.7,
        },
    },
    { -- Step 147
        ["Qpart"] = {
            [66525] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1074.8,
            ["x"] = 1600.5,
        },
        ["Range"] = 20,
        ["Fillers"] = { [66526] = { ["1"] = "1", }, },
        ["Button"] = {
            ["66525-1"] = 192465,
        },
    },
    { -- Step 148
        ["Qpart"] = {
            [66525] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1052,
            ["x"] = 1582.4,
        },
        ["Range"] = 100,
        ["Fillers"] = { [66526] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "DRAGON_IS_FLYING_ABOVE_AREA_POINT_THE_CAMERA_AT_DRAGON",
        ["Button"] = {
            ["66525-2"] = 192465,
        },
    },
    { -- Step 149
        ["Qpart"] = {
            [66526] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1052,
            ["x"] = 1582.4,
        },
        ["Range"] = 100,
    },
    { -- Step 150
        ["Done"] = {
            66525,
        },
        ["Coord"] = {
            ["y"] = 944.0,
            ["x"] = 1541.5,
        },
    },
    { -- Step 151
        ["Done"] = {
            66526,
        },
        ["Coord"] = {
            ["y"] = 942.2,
            ["x"] = 1536.7,
        },
    },
    { -- Step 152
        ["PickUp"] = {
            66527,
        },
        ["Coord"] = {
            ["y"] = 944.0,
            ["x"] = 1541.5,
        },
    },
    { -- Step 153
        ["Qpart"] = {
            [66527] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 936.1,
            ["x"] = 1548.4,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "WALK_OVER_SPRING",
    },
    { -- Step 154
        ["Qpart"] = {
            [66527] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 900.9,
            ["x"] = 1562.0,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "PHOTOGRAPH_DRAGON",
        ["Button"] = {
            ["66527-2"] = 192465,
        },
    },
    { -- Step 155
        ["Done"] = {
            66527,
        },
        ["Coord"] = {
            ["y"] = 944.0,
            ["x"] = 1541.5,
        },
    },
    { -- Step 156
        ["PickUp"] = {
            66528,
        },
        ["Coord"] = {
            ["y"] = 942,
            ["x"] = 1536.8,
        },
    },
    { -- Step 157
        ["Qpart"] = {
            [66528] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 928.6,
            ["x"] = 1555.8,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INVESTIGATE_CHARRED_FORECLAW",
    },
    { -- Step 158
        ["Qpart"] = {
            [66528] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 907.2,
            ["x"] = 1534.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INVESTIGATE_SEVERED_SPINE",
    },
    { -- Step 159
        ["Qpart"] = {
            [66528] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 902.2,
            ["x"] = 1512.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INVESTIGATE_CRACKED_RIB",
    },
    { -- Step 160
        ["Done"] = {
            66528,
        },
        ["Coord"] = {
            ["y"] = 942,
            ["x"] = 1536.8,
        },
    },
    { -- Step 161
        ["PickUp"] = {
            66529,
        },
        ["Coord"] = {
            ["y"] = 942,
            ["x"] = 1536.8,
        },
    },
    { -- Step 162
        ["Qpart"] = {
            [66529] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 925.6,
            ["x"] = 1553.8,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "WAIT_FOR_DERVISHIAN_BE_IN_FRONT_OF_YOU_TO_TAKE_PICTURE",
    },
    { -- Step 163
        ["Done"] = {
            66529,
        },
        ["Coord"] = {
            ["y"] = 920.1,
            ["x"] = 1565.7,
        },
    },
    { -- Step 164
        ["Qpart"] = {
            [66124] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1199.7,
            ["x"] = 971.4,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 107159,
    },
    { -- Step 165
        ["Done"] = {
            66124,
        },
        ["Coord"] = {
            ["y"] = 1199.7,
            ["x"] = 971.4,
        },
    },
    { -- Step 166
        ["PickUp"] = {
            66079,
        },
        ["Coord"] = {
            ["y"] = 1207.2,
            ["x"] = 977.7,
        },
    },
    { -- Step 167
        ["Done"] = {
            66079,
        },
        ["Coord"] = {
            ["y"] = 1816.5,
            ["x"] = 1266.7,
        },
    },
    { -- Step 168
        ["PickUp"] = {
            72241,
        },
        ["Coord"] = {
            ["y"] = 1819.5,
            ["x"] = 1267.0,
        },
    },
    { -- Step 169
        ["Qpart"] = {
            [72241] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1819.5,
            ["x"] = 1267.0,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 107399,
    },
    { -- Step 170
        ["Done"] = {
            72241,
        },
        ["Coord"] = {
            ["y"] = 1819.5,
            ["x"] = 1267.0,
        },
    },
    { -- Step 171
        ["PickUp"] = {
            66048,
        },
        ["Coord"] = {
            ["y"] = 1819.5,
            ["x"] = 1267.0,
        },
    },
    { -- Step 172
        ["PickUp"] = {
            66078,
        },
        ["Coord"] = {
            ["y"] = 1816.5,
            ["x"] = 1266.8,
        },
    },
    { -- Step 173
        ["GetFP"] = 2808,
        ["Coord"] = {
            ["y"] = 1847.5,
            ["x"] = 1283.5,
        },
        ["Range"] = 2,
    },
    { -- Step 174
        ["Qpart"] = {
            [66048] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1851.2,
            ["x"] = 1271.0,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "TALK_WITH_FAO_THE_RELENTLESS_THEN_CLICK_BATTLE_PLANS_INSIDE_HUT",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55311,
        ["RaidIcon"] = 186331,
    },
    { -- Step 175
        ["Qpart"] = {
            [66048] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 1809.5,
            ["x"] = 1235.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "TALK_WITH_FORGEMASTER_BAZENTUS",
        ["Gossip"] = 1,
        ["RaidIcon"] = 186493,
    },
    { -- Step 176
        ["Waypoint"] = 66048,
        ["Coord"] = {
            ["y"] = 1830.0,
            ["x"] = 1164.4,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "RUN_UP_HILL",
    },
    { -- Step 177
        ["Qpart"] = {
            [66048] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1793.0,
            ["x"] = 1163.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "TALK_WITH_ARCHIVIST_EDRES_WAIT_FOR_HER_DIALOG_COMPLETE",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55307,
        ["RaidIcon"] = 187466,
    },
    { -- Step 178
        ["Waypoint"] = 66048,
        ["Coord"] = {
            ["y"] = 1771.8,
            ["x"] = 1255.9,
        },
        ["Range"] = 10,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "GO_BACK_DOWN_HILL",
    },
    { -- Step 179
        ["Qpart"] = {
            [66048] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1686.1,
            ["x"] = 1280.3,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66078] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "TALK_WITH_TALONSTALKER_KAVLA_THEN_USE_TELESCOPE",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54996,
        ["RaidIcon"] = 189507,
    },
    { -- Step 180
        ["Qpart"] = {
            [66078] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1794.3,
            ["x"] = 1248.5,
        },
        ["Range"] = 50,
        ["ExtraLineText"] =
        "TALK_WITH_BLACKTALON_ASSASSINS_OR_AVENGERS_START_COMBAT_YOU_CAN_DUEL_MULTIPLE_AT_ONCE_IF_INTERACTED_WITH",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54628,
    },
    { -- Step 181
        ["Done"] = {
            66078,
            66048,
        },
        ["Coord"] = {
            ["y"] = 1816.3,
            ["x"] = 1266.8,
        },
    },
    { -- Step 182
        ["PickUp"] = {
            65956,
            65957,
        },
        ["Coord"] = {
            ["y"] = 1816.3,
            ["x"] = 1266.8,
        },
    },
    { -- Step 183
        ["Qpart"] = {
            [65957] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1724.5,
            ["x"] = 1818.2,
        },
        ["Range"] = 10,
        ["Fillers"] = { [65956] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KILL_PIERCER_GIGRA",
        ["SpellButton"] = {
            ["65957-1"] = 369553,
        },
    },
    { -- Step 184
        ["Qpart"] = {
            [65957] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1810.0,
            ["x"] = 1876.9,
        },
        ["Range"] = 25,
        ["Fillers"] = { [65956] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KILL_OLPHIS_MOLTEN",
    },
    { -- Step 185
        ["Qpart"] = {
            [65957] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2142.6,
            ["x"] = 1815.3,
        },
        ["Range"] = 10,
        ["Fillers"] = { [65956] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KILL_MODAK_FLAMESPIT",
    },
    { -- Step 186
        ["Qpart"] = {
            [65956] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1866.0,
            ["x"] = 1831.0,
        },
        ["Range"] = 375,
    },
    { -- Step 187
        ["Done"] = {
            65956,
            65957,
        },
        ["Coord"] = {
            ["y"] = 2112.0,
            ["x"] = 1939.5,
        },
    },
    { -- Step 188
        ["PickUp"] = {
            65939,
        },
        ["Coord"] = {
            ["y"] = 2112.0,
            ["x"] = 1939.5,
        },
    },
    { -- Step 189
        ["Qpart"] = {
            [65939] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2112.0,
            ["x"] = 1939.5,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55405,
    },
    { -- Step 190
        ["Waypoint"] = 65939,
        ["Coord"] = {
            ["y"] = 2078.9,
            ["x"] = 2018.0,
        },
        ["Range"] = 5,
    },
    { -- Step 191
        ["Qpart"] = {
            [65939] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2135.9,
            ["x"] = 2223.3,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "ENTER_CITADEL",
    },
    { -- Step 192
        ["PickUp"] = {
            66044,
        },
        ["Coord"] = {
            ["y"] = 2243.1,
            ["x"] = 2328.6,
        },
    },
    { -- Step 193
        ["Qpart"] = {
            [66044] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2243.1,
            ["x"] = 2328.6,
        },
        ["Range"] = 5,
        ["Fillers"] = { [65939] = { ["3"] = "3", }, },
        ["ExtraLineText"] = "RIDE_WRATHION_TOP",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54627,
    },
    { -- Step 194
        ["Qpart"] = {
            [66044] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2183.1,
            ["x"] = 2515.6,
        },
        ["Range"] = 5,
        ["Fillers"] = { [65939] = { ["3"] = "3", }, },
    },
    { -- Step 195
        ["Qpart"] = {
            [66044] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2127.1,
            ["x"] = 2304.0,
        },
        ["Range"] = 5,
        ["Fillers"] = { [65939] = { ["3"] = "3", }, },
        ["ExtraLineText"] = "RIDE_YOUR_DRAGON_OR_WRATHION_NEXT_ARBALEST",
    },
    { -- Step 196
        ["Qpart"] = {
            [66044] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = 2355.5,
            ["x"] = 2435.1,
        },
        ["Range"] = 5,
        ["Fillers"] = { [65939] = { ["3"] = "3", }, },
        ["ExtraLineText"] = "RIDE_YOUR_DRAGON_OR_WRATHION_NEXT_ARBALEST",
    },
    { -- Step 197
        ["Qpart"] = {
            [66044] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = 2329.3,
            ["x"] = 2506.7,
        },
        ["Range"] = 5,
        ["Fillers"] = { [65939] = { ["3"] = "3", }, },
        ["RaidIcon"] = 186592,
    },
    { -- Step 198
        ["Qpart"] = {
            [65939] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2289.4,
            ["x"] = 2537.8,
        },
        ["Range"] = 100,
    },
    { -- Step 199
        ["Done"] = {
            65939,
            66044,
        },
        ["Coord"] = {
            ["y"] = 2245.9,
            ["x"] = 2546.4,
        },
    },
    { -- Step 200
        ["PickUp"] = {
            66049,
        },
        ["Coord"] = {
            ["y"] = 2245.9,
            ["x"] = 2546.4,
        },
    },
    { -- Step 201
        ["Qpart"] = {
            [66049] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2042.7,
            ["x"] = 2477.4,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55423,
    },
    { -- Step 202
        ["Qpart"] = {
            [66049] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2009.5,
            ["x"] = 2455.6,
        },
        ["Range"] = 5,
    },
    { -- Step 203
        ["Done"] = {
            66049,
        },
        ["Coord"] = {
            ["y"] = 2043.0,
            ["x"] = 2477.0,
        },
    },
    { -- Step 204
        ["PickUp"] = {
            66055,
        },
        ["Coord"] = {
            ["y"] = 2031.9,
            ["x"] = 2480.6,
        },
    },
    { -- Step 205
        ["Qpart"] = {
            [66055] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2130.6,
            ["x"] = 2484.6,
        },
        ["Range"] = 10,
        ["Fillers"] = { [66055] = { ["2"] = "2", }, },
        ["ExtraLineText"] = "ENTER_MOUNTAIN",
    },
    { -- Step 206
        ["Qpart"] = {
            [66055] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2281.5,
            ["x"] = 2692.3,
        },
        ["Range"] = 200,
        ["ExtraLineText"] = "SHARDS_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 207
        ["Done"] = {
            66055,
        },
        ["Coord"] = {
            ["y"] = 2031.9,
            ["x"] = 2480.6,
        },
    },
    { -- Step 208
        ["PickUp"] = {
            66056,
        },
        ["Coord"] = {
            ["y"] = 2031.9,
            ["x"] = 2480.6,
        },
    },
    { -- Step 209
        ["Qpart"] = {
            [66056] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2133.9,
            ["x"] = 2690.3,
        },
        ["Range"] = 10,
    },
    { -- Step 210
        ["Qpart"] = {
            [66056] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2121.6,
            ["x"] = 2662.6,
        },
        ["Range"] = 70,
        ["ExtraLineText"] = "KILL_ELEMENTALS_AND_LOOT_COAL",
    },
    { -- Step 211
        ["Done"] = {
            66056,
        },
        ["Coord"] = {
            ["y"] = 2120.1,
            ["x"] = 2686.6,
        },
    },
    { -- Step 212
        ["PickUp"] = {
            66354,
        },
        ["Coord"] = {
            ["y"] = 2120.1,
            ["x"] = 2686.6,
        },
    },
    { -- Step 213
        ["Qpart"] = {
            [66354] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2129.1,
            ["x"] = 2692.8,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "PLACE_FRAGMENTS",
    },
    { -- Step 214
        ["Qpart"] = {
            [66354] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2129.1,
            ["x"] = 2692.8,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "LOOT_OATHSTONE",
    },
    { -- Step 215
        ["Done"] = {
            66354,
        },
        ["Coord"] = {
            ["y"] = 2120.1,
            ["x"] = 2686.6,
        },
    },
    { -- Step 216
        ["PickUp"] = {
            66057,
        },
        ["Coord"] = {
            ["y"] = 2120.1,
            ["x"] = 2686.6,
        },
    },
    { -- Step 217
        ["Qpart"] = {
            [66057] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2042.9,
            ["x"] = 2477.6,
        },
        ["Range"] = 5,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 56143,
    },
    { -- Step 218
        ["Qpart"] = {
            [66057] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2062.4,
            ["x"] = 2494.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "RIDE_WRATHION_THRONE",
    },
    { -- Step 219
        ["Qpart"] = {
            [66057] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2360.0,
            ["x"] = 2639.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "COMPLETES_WHEN_YOU_GET_CLOSER_THRONE",
    },
    { -- Step 220
        ["Done"] = {
            66057,
        },
        ["Coord"] = {
            ["y"] = 2419.5,
            ["x"] = 2706.4,
        },
    },
    { -- Step 221
        ["PickUp"] = {
            66780,
        },
        ["Coord"] = {
            ["y"] = 2419.5,
            ["x"] = 2706.4,
        },
    },
    { -- Step 222
        ["PickUp"] = {
            66779,
        },
        ["Coord"] = {
            ["y"] = 2401.5,
            ["x"] = 2719.3,
        },
    },
    { -- Step 223
        ["Qpart"] = {
            [66780] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2438.3,
            ["x"] = 2660.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_LEFT_AND_RIGHT",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55355,
    },
    { -- Step 224
        ["Qpart"] = {
            [66780] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2470.8,
            ["x"] = 2551.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_TALONSTALKER_KAVIA",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55354,
    },
    { -- Step 225
        ["Qpart"] = {
            [66779] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2381.5,
            ["x"] = 2651.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_ARCHIVIST_EDRESS_TWICE",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55564,
    },
    { -- Step 226
        ["Qpart"] = {
            [66780] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 2381.5,
            ["x"] = 2651.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_ARCHIVIST_EDRESS_TWICE",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55565,
    },
    { -- Step 227
        ["Qpart"] = {
            [66779] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 2296.8,
            ["x"] = 2710.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_FORGEMASTER_BAZENTUS",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55566,
    },
    { -- Step 228
        ["Qpart"] = {
            [66779] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 2241.6,
            ["x"] = 2715.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_BASKILIAN",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55358,
    },
    { -- Step 229
        ["Done"] = {
            66779,
        },
        ["Coord"] = {
            ["y"] = 2401.5,
            ["x"] = 2719.3,
        },
    },
    { -- Step 230
        ["Done"] = {
            66780,
        },
        ["Coord"] = {
            ["y"] = 2419.5,
            ["x"] = 2706.4,
        },
    },
    { -- Step 231
        ["PickUp"] = {
            65793,
        },
        ["Coord"] = {
            ["y"] = 2401.5,
            ["x"] = 2719.3,
        },
    },
    { -- Step 232
        ["Qpart"] = {
            [65793] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 1838.0,
            ["x"] = 1157.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SPEAK_WITH_SABELLIAN",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55381,
    },
    { -- Step 233
        ["Qpart"] = {
            [65793] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1817.7,
            ["x"] = 513.6,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "FOLLOW_WAGON_CLOSELY_AND_KILL_MOBS",
    },
    { -- Step 234
        ["Done"] = {
            65793,
        },
        ["Coord"] = {
            ["y"] = 1791.7,
            ["x"] = 30.5,
        },
    },
    { -- Step 235
        ["PickUp"] = {
            66785,
        },
        ["Coord"] = {
            ["y"] = 1791.7,
            ["x"] = 30.5,
        },
    },
    { -- Step 236
        ["Done"] = {
            66785,
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.2,
        },
    },
    { -- Step 237
        ["PickUp"] = {
            66788,
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.2,
        },
    },
    { -- Step 238
        ["Qpart"] = {
            [66788] = {
                ["1"] = "1",
                ["2"] = "2",
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.2,
        },
        ["Range"] = 30,
        ["ExtraLineText"] = "CLEAN_SHRINE",
    },
    { -- Step 239
        ["Done"] = {
            66788,
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.2,
        },
    },
    { -- Step 240
        ["PickUp"] = {
            65791,
        },
        ["Coord"] = {
            ["y"] = 1717.4,
            ["x"] = -260.2,
        },
    },
    { -- Step 241
        ["Done"] = {
            65791,
        },
        ["Coord"] = {
            ["y"] = 1487.5,
            ["x"] = -319.5,
        },
    },
    { -- Step 242
        ["PickUp"] = {
            65794,
        },
        ["Coord"] = {
            ["y"] = 1487.5,
            ["x"] = -319.5,
        },
    },
    { -- Step 243
        ["Qpart"] = {
            [65794] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 1487.5,
            ["x"] = -319.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_ALEXSTRASZA",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55380,
    },
    { -- Step 244
        ["Done"] = {
            65794,
        },
        ["Coord"] = {
            ["y"] = 1725.0,
            ["x"] = -257.2,
        },
    },
    { -- Step 245
        ["PickUp"] = {
            65795,
        },
        ["Coord"] = {
            ["y"] = 1725.0,
            ["x"] = -257.2,
        },
    },
    { -- Step 246
        ["Coord"] = {
            ["y"] = 1749.9,
            ["x"] = 41.9,
        },
        ["UseFlightPath"] = 65795,
        ["Name"] = "Dragonscale Basecamp, The Waking Shores",
        ["NodeID"] = 2809,
    },
    { -- Step 247
        ["Done"] = {
            65795,
        },
        ["Coord"] = {
            ["y"] = 655.5,
            ["x"] = 803.5,
        },
    },
    { -- Step 248
        ["PickUp"] = {
            65779,
        },
        ["Coord"] = {
            ["y"] = 655.5,
            ["x"] = 803.5,
        },
    },
    { -- Step 249
        ["Done"] = {
            65779,
        },
        ["Coord"] = {
            ["y"] = 223.6,
            ["x"] = 933.9,
        },
    },
    { -- Step 250
        ["ZoneDoneSave"] = 1,
    },
}


-- Ohn'Ahran Plains
APR.RouteQuestStepList["DF04-2023-OhnahranPlains"] = {
    { -- Step 1
        ["Done"] = {
            65779,
        },
        ["Coord"] = {
            ["y"] = 223.6,
            ["x"] = 933.9,
        },
    },
    { -- Step 2
        ["PickUp"] = {
            65780,
        },
        ["Coord"] = {
            ["y"] = 223.6,
            ["x"] = 933.9,
        },
    },
    { -- Step 3
        ["Qpart"] = {
            [65780] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 71.5,
            ["x"] = 886.0,
        },
        ["Range"] = 45,
    },
    { -- Step 4
        ["Done"] = {
            65780,
        },
        ["Coord"] = {
            ["y"] = 140.5,
            ["x"] = 864.4,
        },
    },
    { -- Step 5
        ["PickUp"] = {
            65783,
        },
        ["Coord"] = {
            ["y"] = 140.5,
            ["x"] = 864.4,
        },
    },
    { -- Step 6
        ["Done"] = {
            65783,
        },
        ["Coord"] = {
            ["y"] = 139.0,
            ["x"] = 358.3,
        },
    },
    { -- Step 7
        ["PickUp"] = {
            70174,
        },
        ["Coord"] = {
            ["y"] = 139.0,
            ["x"] = 358.3,
        },
    },
    { -- Step 8
        ["Qpart"] = {
            [70174] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 143.4,
            ["x"] = 325.8,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 56190,
    },
    { -- Step 9
        ["Done"] = {
            70174,
        },
        ["Coord"] = {
            ["y"] = 143.4,
            ["x"] = 325.8,
        },
    },
    { -- Step 10
        ["PickUp"] = {
            65801,
        },
        ["Coord"] = {
            ["y"] = 143.4,
            ["x"] = 325.8,
        },
    },
    { -- Step 11
        ["PickUp"] = {
            65802,
        },
        ["Coord"] = {
            ["y"] = 143.4,
            ["x"] = 325.8,
        },
    },
    { -- Step 12
        ["Qpart"] = {
            [65801] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 369.1,
            ["x"] = 335.0,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65802] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "LOOT_CAMP_PROVISIONS_MARKED_ON_YOUR_MINIMAP_FERALBLOOM_PODS_ARE_AROUND_THE_CAMP",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54838,
    },
    { -- Step 13
        ["PickUp"] = {
            65951,
        },
        ["Coord"] = {
            ["y"] = 160.0,
            ["x"] = 432.1,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65802] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "LOOT_CAMP_PROVISIONS_MARKED_ON_YOUR_MINIMAP_FERALBLOOM_PODS_ARE_AROUND_THE_CAMP",
    },
    { -- Step 14
        ["PickUp"] = {
            65950,
        },
        ["Coord"] = {
            ["y"] = 159.1,
            ["x"] = 428.0,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65802] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "LOOT_CAMP_PROVISIONS_MARKED_ON_YOUR_MINIMAP_FERALBLOOM_PODS_ARE_AROUND_THE_CAMP",
    },
    { -- Step 15
        ["Qpart"] = {
            [65801] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = 115.5,
            ["x"] = 464.0,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65802] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "LOOT_CAMP_PROVISIONS_MARKED_ON_YOUR_MINIMAP_FERALBLOOM_PODS_ARE_AROUND_THE_CAMP",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55228,
    },
    { -- Step 16
        ["Qpart"] = {
            [65801] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 80.9,
            ["x"] = 326.3,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65802] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "LOOT_CAMP_PROVISIONS_MARKED_ON_YOUR_MINIMAP_FERALBLOOM_PODS_ARE_AROUND_THE_CAMP",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55270,
    },
    { -- Step 17
        ["Qpart"] = {
            [65802] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = 167.9,
            ["x"] = 398.3,
        },
        ["Range"] = 225,
    },
    { -- Step 18
        ["GetFP"] = 2790,
        ["Coord"] = {
            ["y"] = 204.9,
            ["x"] = 361.8,
        },
        ["Range"] = 1,
    },
    { -- Step 19
        ["Done"] = {
            65802,
        },
        ["Coord"] = {
            ["y"] = 269.3,
            ["x"] = 405.5,
        },
    },
    { -- Step 20
        ["PickUp"] = {
            65803,
        },
        ["Coord"] = {
            ["y"] = 269.3,
            ["x"] = 405.5,
        },
    },
    { -- Step 21
        ["Qpart"] = {
            [65803] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 223.6,
            ["x"] = 521.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "YOU_DO_NOT_HAVE_RIDE_WITH_CARAVAN_OR_WAIT_FOR_IT",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55267,
    },
    { -- Step 22
        ["Done"] = {
            65951,
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
        ["ExtraLineText"] = "YOU_DO_NOT_HAVE_RIDE_WITH_CARAVAN_OR_WAIT_FOR_IT",
    },
    { -- Step 23
        ["Qpart"] = {
            [65950] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -132.5,
            ["x"] = 638.7,
        },
        ["Range"] = 118,
    },
    { -- Step 24
        ["Done"] = {
            65950,
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
    },
    { -- Step 26
        ["PickUp"] = {
            65953,
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
    },
    { -- Step 27
        ["PickUp"] = {
            65954,
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
    },
    { -- Step 28
        ["PickUp"] = {
            65955,
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
    },
    { -- Step 29
        ["Qpart"] = {
            [65955] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -129.9,
            ["x"] = 718.7,
        },
        ["Range"] = 2,
    },
    { -- Step 30
        ["Qpart"] = {
            [65954] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -137,
            ["x"] = 641.1,
        },
        ["Range"] = 250,
        ["Fillers"] = { [65953] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "CAGED_BAKARS_AND_BAKAR_COLLARS_ARE_MARKED_ON_YOUR_MINIMAP",
    },
    { -- Step 31
        ["Qpart"] = {
            [65953] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -137,
            ["x"] = 641.1,
        },
        ["Range"] = 250,
    },
    { -- Step 32
        ["Qpart"] = {
            [65955] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 33
        ["Done"] = {
            65953,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 34
        ["Done"] = {
            65954,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 35
        ["Done"] = {
            65955,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 36
        ["PickUp"] = {
            65952,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 37
        ["Qpart"] = {
            [65952] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -158.3,
            ["x"] = 610.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "LOOT_MURLOC_START_A_QUEST",
    },
    { -- Step 38
        ["PickUp"] = {
            66005,
        },
        ["Coord"] = {
            ["y"] = -158.3,
            ["x"] = 610.7,
        },
    },
    { -- Step 39
        ["Done"] = {
            65952,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 40
        ["Done"] = {
            66005,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 41
        ["PickUp"] = {
            65949,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 42
        ["PickUp"] = {
            66006,
        },
        ["Coord"] = {
            ["y"] = -214.3,
            ["x"] = 505.5,
        },
    },
    { -- Step 43
        ["Qpart"] = {
            [66006] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -201.4,
            ["x"] = 495.2,
        },
        ["Range"] = 2,
    },
    { -- Step 44
        ["Done"] = {
            66006,
        },
        ["Coord"] = {
            ["y"] = 159.3,
            ["x"] = 427.5,
        },
    },
    { -- Step 45
        ["Done"] = {
            65949,
        },
        ["Coord"] = {
            ["y"] = 159.3,
            ["x"] = 427.5,
        },
    },
    { -- Step 46
        ["Done"] = {
            65803,
        },
        ["Coord"] = {
            ["y"] = -177.0,
            ["x"] = 1089.0,
        },
    },
    { -- Step 47
        ["PickUp"] = {
            65804,
        },
        ["Coord"] = {
            ["y"] = -177.0,
            ["x"] = 1089.0,
        },
    },
    { -- Step 48
        ["PickUp"] = {
            70185,
        },
        ["Coord"] = {
            ["y"] = -188.1,
            ["x"] = 1008.9,
        },
    },
    { -- Step 49
        ["Qpart"] = {
            [70185] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -366.0,
            ["x"] = 933.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 50
        ["Qpart"] = {
            [65804] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -179.6,
            ["x"] = 949.2,
        },
        ["Range"] = 125,
    },
    { -- Step 51
        ["Done"] = {
            65804,
        },
        ["Coord"] = {
            ["y"] = -177.0,
            ["x"] = 1089.0,
        },
    },
    { -- Step 52
        ["Done"] = {
            70185,
        },
        ["Coord"] = {
            ["y"] = -177.0,
            ["x"] = 1089.0,
        },
    },
    { -- Step 53
        ["PickUp"] = {
            65940,
        },
        ["Coord"] = {
            ["y"] = -177.0,
            ["x"] = 1089.0,
        },
    },
    { -- Step 54
        ["Done"] = {
            65940,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 55
        ["PickUp"] = {
            65805,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 56
        ["Qpart"] = {
            [65805] = {
                ["1"] = "1",
                ["2"] = "2",
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -498.3,
            ["x"] = 1548,
        },
        ["Range"] = 225,
    },
    { -- Step 57
        ["Done"] = {
            65805,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 58
        ["PickUp"] = {
            66848,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 59
        ["Qpart"] = {
            [66848] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
        ["Range"] = 2,
        ["Gossip"] = 3,
        ["GossipOptionID"] = 64063,
    },
    { -- Step 60
        ["Qpart"] = {
            [66848] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -477.2,
            ["x"] = 1524.5,
        },
        ["Range"] = 2,
    },
    { -- Step 61
        ["Done"] = {
            66848,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 62
        ["PickUp"] = {
            65806,
        },
        ["Coord"] = {
            ["y"] = -495.1,
            ["x"] = 1521.8,
        },
    },
    { -- Step 63
        ["Done"] = {
            65806,
        },
        ["Coord"] = {
            ["y"] = -575.5,
            ["x"] = 2166.3,
        },
    },
    { -- Step 64
        ["PickUp"] = {
            66018,
        },
        ["Coord"] = {
            ["y"] = -575.5,
            ["x"] = 2166.3,
        },
    },
    { -- Step 65
        ["PickUp"] = {
            66017,
        },
        ["Coord"] = {
            ["y"] = -575.5,
            ["x"] = 2166.3,
        },
    },
    { -- Step 66
        ["PickUp"] = {
            66016,
        },
        ["Coord"] = {
            ["y"] = -575.5,
            ["x"] = 2166.3,
        },
    },
    { -- Step 67
        ["Done"] = {
            66017,
        },
        ["Coord"] = {
            ["y"] = -279.6,
            ["x"] = 2051.4,
        },
    },
    { -- Step 68
        ["PickUp"] = {
            66020,
        },
        ["Coord"] = {
            ["y"] = -279.6,
            ["x"] = 2051.4,
        },
    },
    { -- Step 69
        ["Qpart"] = {
            [66020] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -352.3,
            ["x"] = 2049.6,
        },
        ["Range"] = 70,
        ["ExtraLineText"] = "LOOT_SWEETSUCKLE_BLOOMS_AROUND_HOUSE_AND_COMBINE_5_OF_THEM",
    },
    { -- Step 70
        ["Qpart"] = {
            [66020] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -280.6,
            ["x"] = 2062,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "BURN_INCENSE",
    },
    { -- Step 71
        ["Done"] = {
            66020,
        },
        ["Coord"] = {
            ["y"] = -279.6,
            ["x"] = 2051.4,
        },
    },
    { -- Step 72
        ["PickUp"] = {
            65890,
        },
        ["Coord"] = {
            ["y"] = 156.6,
            ["x"] = 1822.0,
        },
    },
    { -- Step 73
        ["Done"] = {
            65890,
        },
        ["Coord"] = {
            ["y"] = 498.0,
            ["x"] = 1972.5,
        },
    },
    { -- Step 74
        ["PickUp"] = {
            65891,
        },
        ["Coord"] = {
            ["y"] = 498.0,
            ["x"] = 1972.5,
        },
    },
    { -- Step 75
        ["PickUp"] = {
            65893,
        },
        ["Coord"] = {
            ["y"] = 498.0,
            ["x"] = 1972.5,
        },
    },
    { -- Step 76
        ["Qpart"] = {
            [65891] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 641.7,
            ["x"] = 2004.5,
        },
        ["Range"] = 125,
        ["Fillers"] = { [65892] = { ["1"] = "1", }, [65893] = { ["1"] = "1", }, },
    },
    { -- Step 77
        ["Qpart"] = {
            [65893] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 641.7,
            ["x"] = 2004.5,
        },
        ["Range"] = 125,
        ["Fillers"] = { [65892] = { ["1"] = "1", }, },
    },
    { -- Step 78
        ["Qpart"] = {
            [65892] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 641.7,
            ["x"] = 2004.5,
        },
        ["Range"] = 125,
        ["ExtraLineText"] = "BONUS_OBJECTIVE_IF_IT_DOES_NOT_APPEAR_WHEN_YOU_REACH_AREA_DO_APR_SKIP",
    },
    { -- Step 79
        ["Done"] = {
            65891,
        },
        ["Coord"] = {
            ["y"] = 498.0,
            ["x"] = 1972.5,
        },
    },
    { -- Step 80
        ["Done"] = {
            65893,
        },
        ["Coord"] = {
            ["y"] = 498.0,
            ["x"] = 1972.5,
        },
    },
    { -- Step 81
        ["Done"] = {
            66016,
        },
        ["Coord"] = {
            ["y"] = -477.3,
            ["x"] = 2340.8,
        },
    },
    { -- Step 82
        ["PickUp"] = {
            66019,
        },
        ["Coord"] = {
            ["y"] = -477.3,
            ["x"] = 2340.8,
        },
    },
    { -- Step 83
        ["Qpart"] = {
            [66019] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -485.6,
            ["x"] = 2324.1,
        },
        ["Range"] = 2,
    },
    { -- Step 84
        ["Qpart"] = {
            [66019] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -475.3,
            ["x"] = 2341.5,
        },
        ["Range"] = 2,
    },
    { -- Step 85
        ["Qpart"] = {
            [66019] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -462.0,
            ["x"] = 2329.9,
        },
        ["Range"] = 2,
    },
    { -- Step 86
        ["Qpart"] = {
            [66019] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -475.3,
            ["x"] = 2341.5,
        },
        ["Range"] = 2,
        ["SpellButton"] = {
            ["66019-4"] = 375680,
        },
    },
    { -- Step 87
        ["Qpart"] = {
            [66019] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = -465.7,
            ["x"] = 2325.0,
        },
        ["Range"] = 2,
    },
    { -- Step 88
        ["Qpart"] = {
            [66019] = {
                ["6"] = "6",
            },
        },
        ["Coord"] = {
            ["y"] = -475.3,
            ["x"] = 2341.5,
        },
        ["Range"] = 2,
        ["SpellButton"] = {
            ["66019-6"] = 375765,
        },
    },
    { -- Step 89
        ["Qpart"] = {
            [66019] = {
                ["7"] = "7",
            },
        },
        ["Coord"] = {
            ["y"] = -490.6,
            ["x"] = 2348.1,
        },
        ["Range"] = 2,
    },
    { -- Step 90
        ["Qpart"] = {
            [66019] = {
                ["8"] = "8",
            },
        },
        ["Coord"] = {
            ["y"] = -475.3,
            ["x"] = 2341.5,
        },
        ["Range"] = 2,
        ["SpellButton"] = {
            ["66019-8"] = 375771,
        },
    },
    { -- Step 91
        ["Qpart"] = {
            [66019] = {
                ["9"] = "9",
            },
        },
        ["Coord"] = {
            ["y"] = -475.3,
            ["x"] = 2341.5,
        },
        ["Range"] = 2,
    },
    { -- Step 92
        ["Qpart"] = {
            [66019] = {
                ["10"] = "10",
            },
        },
        ["Coord"] = {
            ["y"] = -461.1,
            ["x"] = 2361.1,
        },
        ["Range"] = 2,
        ["SpellButton"] = {
            ["66019-10"] = 375932,
        },
    },
    { -- Step 93
        ["Qpart"] = {
            [66019] = {
                ["11"] = "11",
            },
        },
        ["Coord"] = {
            ["y"] = -453.1,
            ["x"] = 2341.1,
        },
        ["Range"] = 2,
    },
    { -- Step 94
        ["Done"] = {
            66019,
        },
        ["Coord"] = {
            ["y"] = -477.3,
            ["x"] = 2340.8,
        },
    },
    { -- Step 95
        ["Done"] = {
            66018,
        },
        ["Coord"] = {
            ["y"] = -633.0,
            ["x"] = 2247.8,
        },
    },
    { -- Step 96
        ["PickUp"] = {
            66021,
        },
        ["Coord"] = {
            ["y"] = -633.0,
            ["x"] = 2247.8,
        },
    },
    { -- Step 97
        ["Qpart"] = {
            [66021] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -689,
            ["x"] = 2315,
        },
        ["Range"] = 20,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55277,
    },
    { -- Step 98
        ["Done"] = {
            66021,
        },
        ["Coord"] = {
            ["y"] = -685.2,
            ["x"] = 2093.0,
        },
    },
    { -- Step 99
        ["PickUp"] = {
            66969,
        },
        ["Coord"] = {
            ["y"] = -685.2,
            ["x"] = 2093.0,
        },
        ["ExtraLineText"] = "WAIT_FOR_NPC_SPAWN",
    },
    { -- Step 100
        ["Qpart"] = {
            [66969] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -574.4,
            ["x"] = 2166.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 56528,
    },
    { -- Step 101
        ["Qpart"] = {
            [66969] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -574.4,
            ["x"] = 2166.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SELECT_OPTION_1_THEN_4_THEN_2_THEN_3",
    },
    { -- Step 102
        ["Done"] = {
            66969,
        },
        ["Coord"] = {
            ["y"] = -574.4,
            ["x"] = 2166.6,
        },
    },
    { -- Step 103
        ["PickUp"] = {
            66948,
        },
        ["Coord"] = {
            ["y"] = -620.0,
            ["x"] = 2198.6,
        },
    },
    { -- Step 104
        ["Qpart"] = {
            [66948] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -620.0,
            ["x"] = 2198.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 4,
    },
    { -- Step 105
        ["Done"] = {
            66948,
        },
        ["Coord"] = {
            ["y"] = -620.0,
            ["x"] = 2198.6,
        },
    },
    { -- Step 106
        ["PickUp"] = {
            66022,
        },
        ["Coord"] = {
            ["y"] = -620.0,
            ["x"] = 2198.6,
        },
    },
    { -- Step 107
        ["Qpart"] = {
            [66022] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -491.2,
            ["x"] = 2254.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54895,
    },
    { -- Step 108
        ["Done"] = {
            66022,
        },
        ["Coord"] = {
            ["y"] = -491.2,
            ["x"] = 2254.6,
        },
    },
    { -- Step 109
        ["PickUp"] = {
            66023,
        },
        ["Coord"] = {
            ["y"] = -491.2,
            ["x"] = 2254.6,
        },
    },
    { -- Step 110
        ["PickUp"] = {
            66024,
        },
        ["Coord"] = {
            ["y"] = -534.2,
            ["x"] = 2313.6,
        },
    },
    { -- Step 111
        ["Qpart"] = {
            [66024] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -563.7,
            ["x"] = 2408.3,
        },
        ["Range"] = 20,
    },
    { -- Step 112
        ["Qpart"] = {
            [66023] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -532.2,
            ["x"] = 2324.6,
        },
        ["Range"] = 125,
    },
    { -- Step 113
        ["Done"] = {
            66023,
        },
        ["Coord"] = {
            ["y"] = -499.5,
            ["x"] = 2251.6,
        },
        ["ExtraLineText"] = "UPSTAIRS",
    },
    { -- Step 114
        ["Done"] = {
            66024,
        },
        ["Coord"] = {
            ["y"] = -499.5,
            ["x"] = 2251.6,
        },
        ["ExtraLineText"] = "UPSTAIRS",
    },
    { -- Step 115
        ["PickUp"] = {
            66025,
        },
        ["Coord"] = {
            ["y"] = -499.5,
            ["x"] = 2251.6,
        },
    },
    { -- Step 116
        ["Done"] = {
            66025,
        },
        ["Coord"] = {
            ["y"] = -471.2,
            ["x"] = 2276.1,
        },
        ["ExtraLineText"] = "WAIT_FOR_NPC_END_RP",
    },
    { -- Step 117
        ["PickUp"] = {
            66201,
        },
        ["Coord"] = {
            ["y"] = -471.2,
            ["x"] = 2276.1,
        },
    },
    { -- Step 118
        ["Done"] = {
            66201,
        },
        ["Coord"] = {
            ["y"] = -1698.9,
            ["x"] = 3648.8,
        },
    },
    { -- Step 119
        ["PickUp"] = {
            66222,
        },
        ["Coord"] = {
            ["y"] = -1698.9,
            ["x"] = 3648.8,
        },
    },
    { -- Step 120
        ["PickUp"] = {
            66651,
        },
        ["Coord"] = {
            ["y"] = -1690.0,
            ["x"] = 3721.1,
        },
    },
    { -- Step 121
        ["Done"] = {
            66651,
        },
        ["Coord"] = {
            ["y"] = -1911.5,
            ["x"] = 3864.9,
        },
    },
    { -- Step 122
        ["PickUp"] = {
            66652,
        },
        ["Coord"] = {
            ["y"] = -1911.5,
            ["x"] = 3864.9,
        },
    },
    { -- Step 123
        ["Qpart"] = {
            [66652] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1893.5,
            ["x"] = 4003.5,
        },
        ["Range"] = 20,
    },
    { -- Step 124
        ["Qpart"] = {
            [66652] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1885.0,
            ["x"] = 4015.8,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "LOOT_SPEAR",
    },
    { -- Step 125
        ["Done"] = {
            66652,
        },
        ["Coord"] = {
            ["y"] = -1911.5,
            ["x"] = 3864.9,
        },
    },
    { -- Step 126
        ["PickUp"] = {
            66654,
            66655,
        },
        ["Coord"] = {
            ["y"] = -1911.5,
            ["x"] = 3864.9,
        },
    },
    { -- Step 127
        ["Qpart"] = {
            [66654] = {
                ["1"] = "1",
                ["2"] = "2",
            },
            [66655] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1968.8,
            ["x"] = 4139.1,
        },
        ["Range"] = 75,
    },
    { -- Step 128
        ["Done"] = {
            66654,
            66655,
        },
        ["Coord"] = {
            ["y"] = -1878.9,
            ["x"] = 4264.8,
        },
    },
    { -- Step 129
        ["PickUp"] = {
            69936,
        },
        ["Coord"] = {
            ["y"] = -1878.9,
            ["x"] = 4264.8,
        },
    },
    { -- Step 130
        ["Qpart"] = {
            [69936] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1968.8,
            ["x"] = 4139.1,
        },
        ["Range"] = 75,
        ["ExtraLineText"] = "PATROLS_AROUND_AREA",
        ["RaidIcon"] = 191145,
    },
    { -- Step 131
        ["Done"] = {
            69936,
        },
        ["Coord"] = {
            ["y"] = -1878.9,
            ["x"] = 4264.8,
        },
    },
    { -- Step 132
        ["PickUp"] = {
            66656,
        },
        ["Coord"] = {
            ["y"] = -1878.9,
            ["x"] = 4264.8,
        },
    },
    { -- Step 133
        ["Qpart"] = {
            [66656] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2061.5,
            ["x"] = 4467.0,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "KILL_CATHAN_AND_USE_ZORIGS_TOTEM_OF_RESPITE_ON_THEIR_CORPSE",
        ["Button"] = {
            ["66656-1"] = 194447,
        },
        ["RaidIcon"] = 192224,
    },
    { -- Step 134
        ["Qpart"] = {
            [66656] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2169.4,
            ["x"] = 4467.4,
        },
        ["Range"] = 28,
        ["ExtraLineText"] = "KILL_ZAPHIL_AND_USE_ZORIGS_TOTEM_OF_RESPITE_ON_THEIR_CORPSE",
        ["Button"] = {
            ["66656-2"] = 194447,
        },
        ["RaidIcon"] = 192223,
    },
    { -- Step 135
        ["Qpart"] = {
            [66656] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -2203.1,
            ["x"] = 4310.4,
        },
        ["Range"] = 33,
        ["ExtraLineText"] = "KILL_DIHAR_AND_USE_ZORIGS_TOTEM_OF_RESPITE_ON_THEIR_CORPSE",
        ["Button"] = {
            ["66656-4"] = 194447,
        },
        ["RaidIcon"] = 192225,
    },
    { -- Step 136
        ["Qpart"] = {
            [66656] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -2154.0,
            ["x"] = 4369.8,
        },
        ["Range"] = 40,
        ["ExtraLineText"] = "KILL_GANMAT_AND_USE_ZORIGS_TOTEM_OF_RESPITE_ON_THEIR_CORPSE",
        ["Button"] = {
            ["66656-3"] = 194447,
        },
        ["RaidIcon"] = 192226,
    },
    { -- Step 137
        ["Done"] = {
            66656,
        },
        ["Coord"] = {
            ["y"] = -2115.5,
            ["x"] = 4401.1,
        },
        ["ExtraLineText"] = "TURN_IN_INITIATE_ZORIG_WHO_SHOULD_BE_RIGHT_BESIDE_YOU",
    },
    { -- Step 138
        ["PickUp"] = {
            66657,
        },
        ["Coord"] = {
            ["y"] = -2115.5,
            ["x"] = 4401.1,
        },
    },
    { -- Step 139
        ["Qpart"] = {
            [66657] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2171.5,
            ["x"] = 4449.7,
        },
        ["Range"] = 15,
    },
    { -- Step 140
        ["Qpart"] = {
            [66657] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2163.4,
            ["x"] = 4466.8,
        },
        ["Range"] = 2,
    },
    { -- Step 141
        ["Qpart"] = {
            [66657] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -2187.1,
            ["x"] = 4437.1,
        },
        ["Range"] = 2,
    },
    { -- Step 142
        ["Done"] = {
            66657,
        },
        ["Coord"] = {
            ["y"] = -2187.1,
            ["x"] = 4437.1,
        },
    },
    { -- Step 143
        ["Qpart"] = {
            [66222] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -1582.4,
            ["x"] = 3977.5,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 55139,
    },
    { -- Step 144
        ["Qpart"] = {
            [66222] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1477.8,
            ["x"] = 3906.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 87457,
    },
    { -- Step 145
        ["PickUp"] = {
            71027,
        },
        ["Coord"] = {
            ["y"] = -1427.9,
            ["x"] = 3825.4,
        },
        ["ExtraLineText"] = "POSTER_ON_POLE",
    },
    { -- Step 146
        ["Qpart"] = {
            [66222] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1373.0,
            ["x"] = 3829.1,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 56252,
    },
    { -- Step 147
        ["Qpart"] = {
            [66222] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1424.5,
            ["x"] = 3735.1,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54937,
    },
    { -- Step 148
        ["PickUp"] = {
            66687,
        },
        ["Coord"] = {
            ["y"] = -1443.5,
            ["x"] = 3670.5,
        },
    },
    { -- Step 149
        ["PickUp"] = {
            66688,
        },
        ["Coord"] = {
            ["y"] = -1443.5,
            ["x"] = 3670.5,
        },
    },
    { -- Step 150
        ["Qpart"] = {
            [66688] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1268.7,
            ["x"] = 3334.3,
        },
        ["Range"] = 191,
    },
    { -- Step 151
        ["Qpart"] = {
            [66687] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1221.1,
            ["x"] = 2761.6,
        },
        ["Range"] = 365,
    },
    { -- Step 152
        ["Done"] = {
            66688,
        },
        ["Coord"] = {
            ["y"] = -1079.7,
            ["x"] = 3084.6,
        },
    },
    { -- Step 153
        ["PickUp"] = {
            70374,
        },
        ["Coord"] = {
            ["y"] = -1079.7,
            ["x"] = 3084.6,
        },
    },
    { -- Step 154
        ["Qpart"] = {
            [70374] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1079.7,
            ["x"] = 3084.6,
        },
        ["Range"] = 10,
        ["Gossip"] = 1,
        ["GossipOptionID"] = 56476,
    },
    { -- Step 155
        ["Waypoint"] = 66687,
        ["Coord"] = {
            ["y"] = -993.7,
            ["x"] = 3531.3,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "GO_INSIDE_CAVE",
    },
    { -- Step 156
        ["Qpart"] = {
            [66687] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1112.6,
            ["x"] = 3521.1,
        },
        ["Range"] = 88,
    },
    { -- Step 157
        ["Waypoint"] = 66687,
        ["Coord"] = {
            ["y"] = -993.7,
            ["x"] = 3531.3,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "EXIT_CAVE",
    },
    { -- Step 158
        ["Qpart"] = {
            [71027] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -965.6,
            ["x"] = 3624.5,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66687] = { ["2"] = "2", }, },
    },
    { -- Step 159
        ["Qpart"] = {
            [66687] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -927.9,
            ["x"] = 3596.4,
        },
        ["Range"] = 165,
    },
    { -- Step 160
        ["Done"] = {
            66687,
        },
        ["Coord"] = {
            ["y"] = -1443.7,
            ["x"] = 3668.1,
        },
    },
    { -- Step 161
        ["Done"] = {
            70374,
        },
        ["Coord"] = {
            ["y"] = -1443.7,
            ["x"] = 3668.1,
        },
    },
    { -- Step 162
        ["PickUp"] = {
            66834,
        },
        ["Coord"] = {
            ["y"] = -1443.7,
            ["x"] = 3668.1,
        },
    },
    { -- Step 163
        ["Qpart"] = {
            [66834] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1497.7,
            ["x"] = 3781.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 164
        ["Qpart"] = {
            [66834] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1501.7,
            ["x"] = 3776.2,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "PICK_UP_TORCH",
    },
    { -- Step 165
        ["Qpart"] = {
            [66834] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1501.7,
            ["x"] = 3776.2,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "CLICK_EXTRAACTIONBUTTON",
        ["SpellButton"] = {
            ["66834-3"] = 384389,
        },
        ["ExtraActionB"] = 1,
    },
    { -- Step 166
        ["Qpart"] = {
            [66834] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -1496.0,
            ["x"] = 3786.7,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "PICK_UP_SPEAR",
    },
    { -- Step 167
        ["Qpart"] = {
            [66834] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = -1496.0,
            ["x"] = 3786.7,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "CLICK_EXTRAACTIONBUTTON",
        ["SpellButton"] = {
            ["66834-5"] = 384564,
        },
        ["ExtraActionB"] = 1,
    },
    { -- Step 168
        ["Qpart"] = {
            [66834] = {
                ["6"] = "6",
            },
        },
        ["Coord"] = {
            ["y"] = -1493.9,
            ["x"] = 3787.8,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "PICK_UP_BOW",
    },
    { -- Step 169
        ["Qpart"] = {
            [66834] = {
                ["7"] = "7",
            },
        },
        ["Coord"] = {
            ["y"] = -1493.9,
            ["x"] = 3787.8,
        },
        ["Range"] = 1,
        ["ExtraLineText"] = "CLICK_EXTRAACTIONBUTTON",
        ["SpellButton"] = {
            ["66834-7"] = 384588,
        },
        ["ExtraActionB"] = 1,
    },
    { -- Step 170
        ["Done"] = {
            66834,
        },
        ["Coord"] = {
            ["y"] = -1443.7,
            ["x"] = 3668.1,
        },
    },
    { -- Step 171
        ["Done"] = {
            71027,
        },
        ["Coord"] = {
            ["y"] = -1698.0,
            ["x"] = 3650.5,
        },
    },
    { -- Step 172
        ["Done"] = {
            66222,
        },
        ["Coord"] = {
            ["y"] = -1698.0,
            ["x"] = 3650.5,
        },
    },
    { -- Step 173
        ["PickUp"] = {
            70229,
        },
        ["Coord"] = {
            ["y"] = -1698.0,
            ["x"] = 3650.5,
        },
    },
    { -- Step 174
        ["Done"] = {
            70229,
        },
        ["Coord"] = {
            ["y"] = -1469.8,
            ["x"] = 4033.4,
        },
    },
    { -- Step 175
        ["PickUp"] = {
            66254,
        },
        ["Coord"] = {
            ["y"] = -1469.8,
            ["x"] = 4033.4,
        },
    },
    { -- Step 176
        ["Qpart"] = {
            [66254] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1480.9,
            ["x"] = 4024.5,
        },
        ["Range"] = 50,
    },
    { -- Step 177
        ["Done"] = {
            66254,
        },
        ["Coord"] = {
            ["y"] = -1469.8,
            ["x"] = 4033.4,
        },
    },
    { -- Step 178
        ["PickUp"] = {
            66224,
        },
        ["Coord"] = {
            ["y"] = -1469.8,
            ["x"] = 4033.4,
        },
    },
    { -- Step 179
        ["Qpart"] = {
            [66224] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1699.3,
            ["x"] = 3443.8,
        },
        ["Range"] = 10,
    },
    { -- Step 180
        ["Qpart"] = {
            [66224] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1707.2,
            ["x"] = 3446.5,
        },
        ["Range"] = 3,
        ["Gossip"] = 1,
    },
    { -- Step 181
        ["Qpart"] = {
            [66224] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1772.0,
            ["x"] = 3297.2,
        },
        ["Range"] = 20,
    },
    { -- Step 182
        ["Qpart"] = {
            [66224] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -1772.0,
            ["x"] = 3297.2,
        },
        ["Range"] = 3,
        ["Gossip"] = 1,
    },
    { -- Step 183
        ["Qpart"] = {
            [66224] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = -1770.1,
            ["x"] = 3085.4,
        },
        ["Range"] = 24,
    },
    { -- Step 184
        ["Done"] = {
            66224,
        },
        ["Coord"] = {
            ["y"] = -1770.1,
            ["x"] = 3085.4,
        },
    },
    { -- Step 185
        ["PickUp"] = {
            66225,
            70195,
        },
        ["Coord"] = {
            ["y"] = -1770.1,
            ["x"] = 3085.4,
        },
    },
    { -- Step 186
        ["Qpart"] = {
            [70195] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2055.1,
            ["x"] = 3114.1,
        },
        ["Range"] = 10,
        ["Fillers"] = { [66225] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "LOOT_RETREAT_ORDERS_FROM_SHELA_WINDBINDER",
    },
    { -- Step 187
        ["Qpart"] = {
            [66225] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1986.0,
            ["x"] = 3027.8,
        },
        ["Range"] = 141,
    },
    { -- Step 188
        ["Done"] = {
            66225,
            70195,
        },
        ["Coord"] = {
            ["y"] = -1772.0,
            ["x"] = 3086.8,
        },
    },
    { -- Step 189
        ["PickUp"] = {
            66236,
        },
        ["Coord"] = {
            ["y"] = -1772.0,
            ["x"] = 3086.8,
        },
    },
    { -- Step 190
        ["Done"] = {
            66236,
        },
        ["Coord"] = {
            ["y"] = -2061.6,
            ["x"] = 2419.9,
        },
    },
    { -- Step 191
        ["PickUp"] = {
            66242,
        },
        ["Coord"] = {
            ["y"] = -2061.6,
            ["x"] = 2419.9,
        },
    },
    { -- Step 192
        ["PickUp"] = {
            66256,
        },
        ["Coord"] = {
            ["y"] = -2061.6,
            ["x"] = 2419.9,
        },
    },
    { -- Step 193
        ["PickUp"] = {
            66257,
        },
        ["Coord"] = {
            ["y"] = -2061.6,
            ["x"] = 2419.9,
        },
    },
    { -- Step 194
        ["QpartPart"] = {
            [66257] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1982.1,
            ["x"] = 2415.9,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "DESTROY_FIRST_WAGON",
        ["TrigText"] = "1/4",
    },
    { -- Step 195
        ["Waypoint"] = 69968,
        ["Coord"] = {
            ["y"] = -1955.3,
            ["x"] = 2292.6,
        },
        ["Range"] = 5,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "HEAD_BONUS_OBJECTIVE",
    },
    { -- Step 196
        ["Qpart"] = {
            [69968] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1955.3,
            ["x"] = 2292.6,
        },
        ["Range"] = 10,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "KILL_PROZELA_GALESHOT_BONUS_OBJECTIVE",
        ["RaidIcon"] = 193669,
    },
    { -- Step 197
        ["QpartPart"] = {
            [66257] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1886.3,
            ["x"] = 2336.1,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "DESTROY_SECOND_WAGON",
        ["TrigText"] = "2/4",
    },
    { -- Step 198
        ["QpartPart"] = {
            [66257] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1701.6,
            ["x"] = 2364.0,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "DESTROY_THIRD_WAGON",
        ["TrigText"] = "3/4",
    },
    { -- Step 199
        ["QpartPart"] = {
            [66257] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1944.5,
            ["x"] = 2142.4,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66242] = { ["1"] = "1", ["2"] = "2", }, [66256] = { ["1"] = "1", ["2"] = "2", }, },
        ["ExtraLineText"] = "DESTROY_FOURTH_WAGON",
        ["TrigText"] = "4/4",
    },
    { -- Step 200
        ["Qpart"] = {
            [66242] = {
                ["1"] = "1",
                ["2"] = "2",
            },
            [66256] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1881.9,
            ["x"] = 2296.7,
        },
        ["Range"] = 210,
    },
    { -- Step 201
        ["Done"] = {
            66242,
            66256,
            66257,
        },
        ["Coord"] = {
            ["y"] = -1787.2,
            ["x"] = 2227.3,
        },
    },
    { -- Step 202
        ["PickUp"] = {
            66258,
        },
        ["Coord"] = {
            ["y"] = -1787.2,
            ["x"] = 2227.3,
        },
    },
    { -- Step 203
        ["Qpart"] = {
            [66258] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1856.0,
            ["x"] = 2239.8,
        },
        ["Range"] = 50,
    },
    { -- Step 204
        ["Done"] = {
            66258,
        },
        ["Coord"] = {
            ["y"] = -1748.5,
            ["x"] = 2169.3,
        },
    },
    { -- Step 205
        ["PickUp"] = {
            66259,
        },
        ["Coord"] = {
            ["y"] = -1748.5,
            ["x"] = 2169.3,
        },
    },
    { -- Step 206
        ["Qpart"] = {
            [66259] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -472.1,
            ["x"] = 2275.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_NPC",
        ["Gossip"] = 1,
    },
    { -- Step 207
        ["Done"] = {
            66259,
        },
        ["Coord"] = {
            ["y"] = -472.1,
            ["x"] = 2275.3,
        },
    },
    { -- Step 208
        ["PickUp"] = {
            66327,
        },
        ["Coord"] = {
            ["y"] = -472.1,
            ["x"] = 2275.3,
        },
    },
    { -- Step 209
        ["Qpart"] = {
            [66327] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -472.1,
            ["x"] = 2275.3,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
        ["ETA"] = 50,
    },
    { -- Step 210
        ["Qpart"] = {
            [66327] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -472.1,
            ["x"] = 2275.3,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 211
        ["Qpart"] = {
            [66327] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -628.1,
            ["x"] = 1289.9,
        },
        ["Range"] = 2,
    },
    { -- Step 212
        ["Done"] = {
            66327,
        },
        ["Coord"] = {
            ["y"] = -628.1,
            ["x"] = 1289.9,
        },
    },
    { -- Step 213
        ["PickUp"] = {
            70244,
        },
        ["Coord"] = {
            ["y"] = -628.1,
            ["x"] = 1289.9,
        },
    },
    { -- Step 214
        ["Qpart"] = {
            [70244] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -644.1,
            ["x"] = 1119.3,
        },
        ["Range"] = 135,
    },
    { -- Step 215
        ["Qpart"] = {
            [70244] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -641.7,
            ["x"] = 1054.0,
        },
        ["Range"] = 5,
        ["RaidIcon"] = 190932,
    },
    { -- Step 216
        ["Done"] = {
            70244,
        },
        ["Coord"] = {
            ["y"] = -645.2,
            ["x"] = 1010.7,
        },
    },
    { -- Step 217
        ["PickUp"] = {
            66329,
        },
        ["Coord"] = {
            ["y"] = -645.2,
            ["x"] = 1010.7,
        },
    },
    { -- Step 218
        ["Qpart"] = {
            [66329] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -645.2,
            ["x"] = 1010.7,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 219
        ["Done"] = {
            66329,
        },
        ["Coord"] = {
            ["y"] = -645.2,
            ["x"] = 1010.7,
        },
    },
    { -- Step 220
        ["PickUp"] = {
            66328,
        },
        ["Coord"] = {
            ["y"] = -645.2,
            ["x"] = 1010.7,
        },
    },
    { -- Step 221
        ["Qpart"] = {
            [66328] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1120.0,
            ["x"] = 1341.2,
        },
        ["Range"] = 30,
        ["ExtraLineText"] = "FIND_GREEN_DRAGONS",
    },
    { -- Step 222
        ["Qpart"] = {
            [66328] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1120.0,
            ["x"] = 1341.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SPEAK_KHANAM_MATRA",
        ["Gossip"] = 1,
    },
    { -- Step 223
        ["GetFP"] = 2798,
        ["Coord"] = {
            ["y"] = -1501.9,
            ["x"] = 727.7,
        },
        ["Range"] = 2,
    },
    { -- Step 224
        ["PickUp"] = {
            66681,
        },
        ["Coord"] = {
            ["y"] = -1554.8,
            ["x"] = 683.9,
        },
    },
    { -- Step 225
        ["PickUp"] = {
            66680,
        },
        ["Coord"] = {
            ["y"] = -1554.8,
            ["x"] = 683.9,
        },
    },
    { -- Step 226
        ["SetHS"] = 66680,
        ["Coord"] = {
            ["y"] = -1572.8,
            ["x"] = 660.6,
        },
        ["ExtraLineText"] = "PINEWOOD_POST_HS",
        ["Gossip"] = 1,
    },
    { -- Step 227
        ["Qpart"] = {
            [66680] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1545.8,
            ["x"] = 712.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "BUY_DICED_MEAT",
        ["Gossip"] = 1,
    },
    { -- Step 228
        ["Qpart"] = {
            [66680] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1584.7,
            ["x"] = 682.9,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CLICK_DOG",
        ["Gossip"] = 1,
    },
    { -- Step 229
        ["DropQuest"] = 66689,
        ["DroppableQuest"] = {
            ["Text"] = "PINEHOOF_DOE",
            ["Qid"] = 66689,
            ["MobId"] = 191496,
        },
        ["Coord"] = {
            ["y"] = -1878.0,
            ["x"] = 650.9,
        },
        ["Fillers"] = { [66680] = { ["3"] = "3", }, [66681] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "LOOT_STORMTOUCHED_SHARDS_START_A_QUEST",
    },
    { -- Step 230
        ["Qpart"] = {
            [66680] = {
                ["3"] = "3",
            },
            [66681] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1878.0,
            ["x"] = 650.9,
        },
        ["Range"] = 125,
        ["ExtraLineText"] = "USE_ITEM_ON_ARGALI",
        ["Button"] = {
            ["66680-3"] = 193892,
        },
    },
    { -- Step 231
        ["Done"] = {
            66680,
            66681,
            66689,
        },
        ["Coord"] = {
            ["y"] = -1556.4,
            ["x"] = 683.5,
        },
    },
    { -- Step 232
        ["PickUp"] = {
            66683,
        },
        ["Coord"] = {
            ["y"] = -1556.4,
            ["x"] = 683.5,
        },
    },
    { -- Step 233
        ["Qpart"] = {
            [66683] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1584.0,
            ["x"] = 688.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 234
        ["Qpart"] = {
            [66683] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1545.5,
            ["x"] = 712.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 2,
    },
    { -- Step 235
        ["Qpart"] = {
            [66683] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1502.3,
            ["x"] = 727.9,
        },
        ["Range"] = 2,
        ["Gossip"] = 2,
    },
    { -- Step 236
        ["Done"] = {
            66683,
        },
        ["Coord"] = {
            ["y"] = -1556.4,
            ["x"] = 683.5,
        },
    },
    { -- Step 237
        ["PickUp"] = {
            65836,
        },
        ["Coord"] = {
            ["y"] = -1556.4,
            ["x"] = 683.5,
        },
    },
    { -- Step 238
        ["Qpart"] = {
            [65836] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1646.7,
            ["x"] = 459.0,
        },
        ["Range"] = 10,
    },
    { -- Step 239
        ["Qpart"] = {
            [65836] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1646.7,
            ["x"] = 459.0,
        },
        ["Range"] = 10,
    },
    { -- Step 240
        ["Done"] = {
            65836,
        },
        ["Coord"] = {
            ["y"] = -1646.7,
            ["x"] = 459.0,
        },
    },
    { -- Step 241
        ["PickUp"] = {
            66684,
        },
        ["Coord"] = {
            ["y"] = -1646.7,
            ["x"] = 459.0,
        },
    },
    { -- Step 242
        ["Qpart"] = {
            [66684] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1820.8,
            ["x"] = 379.7,
        },
        ["Range"] = 15,
        ["ExtraLineText"] = "DESTROY_PILLAR_INSIDE_THE_CAVE",
    },
    { -- Step 243
        ["Done"] = {
            66684,
        },
        ["Coord"] = {
            ["y"] = -1555.0,
            ["x"] = 696.4,
        },
    },
    { -- Step 244
        ["Done"] = {
            66328,
        },
        ["Coord"] = {
            ["y"] = -1120.4,
            ["x"] = 1341.4,
        },
    },
    { -- Step 245
        ["PickUp"] = {
            66344,
        },
        ["Coord"] = {
            ["y"] = -1140.0,
            ["x"] = 1333.8,
        },
    },
    { -- Step 246
        ["Qpart"] = {
            [66344] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1139.0,
            ["x"] = 1344.4,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TAKE_DRAGON",
        ["Gossip"] = 1,
    },
    { -- Step 247
        ["Done"] = {
            66344,
        },
        ["Coord"] = {
            ["y"] = -1491.4,
            ["x"] = 4681.8,
        },
    },
    { -- Step 248
        ["PickUp"] = {
            70220,
        },
        ["Coord"] = {
            ["y"] = -1491.4,
            ["x"] = 4681.8,
        },
    },
    { -- Step 249
        ["Qpart"] = {
            [70220] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1490.4,
            ["x"] = 4563.0,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 250
        ["GetFP"] = 2796,
        ["Coord"] = {
            ["y"] = -1490.4,
            ["x"] = 4563.0,
        },
        ["Range"] = 2,
    },
    { -- Step 251
        ["Qpart"] = {
            [70220] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1390.8,
            ["x"] = 4535.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 252
        ["Qpart"] = {
            [70220] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1369.0,
            ["x"] = 4620.1,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 253
        ["Qpart"] = {
            [70220] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -1428.4,
            ["x"] = 4604.8,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 254
        ["Qpart"] = {
            [70220] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = -1621.0,
            ["x"] = 4551.2,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 255
        ["Done"] = {
            70220,
        },
        ["Coord"] = {
            ["y"] = -1491.4,
            ["x"] = 4681.7,
        },
    },
    { -- Step 256
        ["PickUp"] = {
            66331,
        },
        ["Coord"] = {
            ["y"] = -1491.4,
            ["x"] = 4681.7,
        },
    },
    { -- Step 257
        ["Qpart"] = {
            [66331] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -905.7,
            ["x"] = 4736.2,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 258
        ["Qpart"] = {
            [66331] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -813.2,
            ["x"] = 4873.1,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 259
        ["Qpart"] = {
            [66331] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -601.7,
            ["x"] = 4839.3,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 260
        ["Qpart"] = {
            [66331] = {
                ["5"] = "5",
            },
        },
        ["Coord"] = {
            ["y"] = -623.7,
            ["x"] = 4880.8,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 261
        ["Done"] = {
            66331,
        },
        ["Coord"] = {
            ["y"] = -619.2,
            ["x"] = 4878.5,
        },
    },
    { -- Step 262
        ["PickUp"] = {
            66333,
        },
        ["Coord"] = {
            ["y"] = -623.7,
            ["x"] = 4880.8,
        },
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 263
        ["QpartPart"] = {
            [66333] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -592.5,
            ["x"] = 4943.5,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66333] = { ["1"] = "1", }, [66421] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "DESTROY_FIRST_BALLISTA",
        ["TrigText"] = "1/3",
    },
    { -- Step 264
        ["QpartPart"] = {
            [66333] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -520.5,
            ["x"] = 4976.7,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66333] = { ["1"] = "1", }, [66421] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "DESTROY_SECOND_BALLISTA",
        ["TrigText"] = "2/3",
    },
    { -- Step 265
        ["QpartPart"] = {
            [66333] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -484.1,
            ["x"] = 4893.4,
        },
        ["Range"] = 3,
        ["Fillers"] = { [66333] = { ["1"] = "1", }, [66421] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "DESTROY_THIRD_BALLISTA",
        ["TrigText"] = "3/3",
    },
    { -- Step 266
        ["Qpart"] = {
            [66333] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -590.5,
            ["x"] = 4948.6,
        },
        ["Range"] = 125,
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 267
        ["Done"] = {
            66333,
        },
        ["Coord"] = {
            ["y"] = -488.6,
            ["x"] = 4896.3,
        },
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 268
        ["PickUp"] = {
            66784,
            66335,
        },
        ["Coord"] = {
            ["y"] = -488.6,
            ["x"] = 4896.3,
        },
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 269
        ["Qpart"] = {
            [66335] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -571.7,
            ["x"] = 5003.8,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 270
        ["Qpart"] = {
            [66335] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -475.7,
            ["x"] = 5067.3,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 271
        ["Qpart"] = {
            [66335] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -473.0,
            ["x"] = 5138.3,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 272
        ["Done"] = {
            66335,
        },
        ["Coord"] = {
            ["y"] = -473.0,
            ["x"] = 5138.3,
        },
        ["Fillers"] = { [66421] = { ["1"] = "1", }, },
    },
    { -- Step 273
        ["Qpart"] = {
            [66784] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -345.2,
            ["x"] = 4939.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "KILL_THREE_STORM_SUMMONERS",
    },
    { -- Step 274
        ["Done"] = {
            66784,
        },
        ["Coord"] = {
            ["y"] = -345.2,
            ["x"] = 4939.5,
        },
    },
    { -- Step 275
        ["Qpart"] = {
            [66421] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -488.6,
            ["x"] = 4896.3,
        },
        ["Range"] = 250,
        ["ExtraLineText"] = "BONUS_OBJECTIVE",
    },
    { -- Step 276
        ["PickUp"] = {
            66337,
        },
        ["Coord"] = {
            ["y"] = -345.2,
            ["x"] = 4939.5,
        },
    },
    { -- Step 277
        ["Qpart"] = {
            [66970] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -307.3,
            ["x"] = 4859.6,
        },
        ["Range"] = 2,
    },
    { -- Step 278
        ["Qpart"] = {
            [66337] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -577.0,
            ["x"] = 5124.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "KILL_BIG_DRAGON",
    },
    { -- Step 279
        ["Qpart"] = {
            [66337] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -607.9,
            ["x"] = 5085.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_DRAGON",
        ["Gossip"] = 1,
    },
    { -- Step 280
        ["Done"] = {
            66337,
        },
        ["Coord"] = {
            ["y"] = -1022.2,
            ["x"] = 4879.6,
        },
    },
    { -- Step 281
        ["PickUp"] = {
            66336,
        },
        ["Coord"] = {
            ["y"] = -1022.2,
            ["x"] = 4879.6,
        },
    },
    { -- Step 282
        ["Done"] = {
            66336,
        },
        ["Coord"] = {
            ["y"] = -1152.8,
            ["x"] = 5145.7,
        },
    },
    { -- Step 283
        ["PickUp"] = {
            66783,
        },
        ["Coord"] = {
            ["y"] = -1152.8,
            ["x"] = 5145.7,
        },
        ["Gossip"] = 1,
    },
    { -- Step 284
        ["Qpart"] = {
            [66783] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -1147.7,
            ["x"] = 5134.8,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CHOOSE_FIRST_HUNT_GIVE_SPEAR_MERITHRA",
        ["Gossip"] = 1,
        ["GossipOptionID"] = 54952,
    },
    { -- Step 285
        ["Qpart"] = {
            [66783] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -1156.2,
            ["x"] = 5128.9,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CHOOSE_EAGLE_FEATHER_GIVE_FEATHER_MERITHRA",
        ["Gossip"] = 3,
    },
    { -- Step 286
        ["Qpart"] = {
            [66783] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -1151.7,
            ["x"] = 5131.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CHOOSE_BLOOD_GIVE_BLOOD_MERITHRA",
        ["Gossip"] = 3,
    },
    { -- Step 287
        ["Qpart"] = {
            [66783] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -1152.8,
            ["x"] = 5145.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TAKE_MERITHRAS_OFFERING_KHANAM",
        ["Gossip"] = 3,
    },
    { -- Step 288
        ["Done"] = {
            66783,
        },
        ["Coord"] = {
            ["y"] = -1152.8,
            ["x"] = 5145.7,
        },
    },
    { -- Step 289
        ["PickUp"] = {
            66340,
        },
        ["Coord"] = {
            ["y"] = -1152.8,
            ["x"] = 5145.7,
        },
    },
    { -- Step 290
        ["UseHS"] = 66340,
        ["Button"] = {
            ["22345678-1"] = 6948,
        },
        ["ExtraLineText"] = "TO_PINEWOOD_POST",
    },
    { -- Step 291
        ["GetFP"] = 2793,
        ["Coord"] = {
            ["y"] = -2572.0,
            ["x"] = 1393.9,
        },
        ["Range"] = 2,
    },
    { -- Step 292
        ["Done"] = {
            66340,
        },
        ["Coord"] = {
            ["y"] = -2648.4,
            ["x"] = 1393.3,
        },
    },
    { -- Step 293
        ["PickUp"] = {
            65686,
        },
        ["Coord"] = {
            ["y"] = -2648.4,
            ["x"] = 1393.3,
        },
    },
    { -- Step 294
        ["Done"] = {
            65686,
        },
        ["Coord"] = {
            ["y"] = -3511.6,
            ["x"] = 981.7,
        },
    },
    { -- Step 295
        ["ZoneDoneSave"] = 1,
    },
}


-- Azure Span
APR.RouteQuestStepList["DF05-2024-AzureSpan"] = {
    { -- Step 1
        ["Done"] = {
            65686,
        },
        ["Coord"] = {
            ["y"] = -3511.6,
            ["x"] = 981.7,
        },
    },
    { -- Step 2
        ["PickUp"] = {
            66228,
        },
        ["Coord"] = {
            ["y"] = -3511.6,
            ["x"] = 981.7,
        },
    },
    { -- Step 3
        ["PickUp"] = {
            67174,
        },
        ["Coord"] = {
            ["y"] = -3531.3,
            ["x"] = 1005.7,
        },
    },
    { -- Step 4
        ["Qpart"] = {
            [67174] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3518.1,
            ["x"] = 987.4,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "EXAMINE_FLASK",
    },
    { -- Step 5
        ["Qpart"] = {
            [67174] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3528.4,
            ["x"] = 985.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "EXAMINE_TEAPOT",
    },
    { -- Step 6
        ["Qpart"] = {
            [67174] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3568.3,
            ["x"] = 1004.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "EXAMINE_TOY",
    },
    { -- Step 7
        ["PickUp"] = {
            67177,
        },
        ["Coord"] = {
            ["y"] = -3570.3,
            ["x"] = 984.4,
        },
    },
    { -- Step 8
        ["Done"] = {
            67174,
        },
        ["Coord"] = {
            ["y"] = -3531.3,
            ["x"] = 1005.7,
        },
    },
    { -- Step 9
        ["PickUp"] = {
            67175,
        },
        ["Coord"] = {
            ["y"] = -3531.3,
            ["x"] = 1005.7,
        },
    },
    { -- Step 10
        ["Qpart"] = {
            [67175] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3529.9,
            ["x"] = 1007.5,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 11
        ["Qpart"] = {
            [67175] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3533.4,
            ["x"] = 1009.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "LOOT_WAND",
    },
    { -- Step 12
        ["Qpart"] = {
            [67175] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3580.4,
            ["x"] = 1074.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "DISPELL_TOY_BOAT",
    },
    { -- Step 13
        ["Qpart"] = {
            [67177] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3635.9,
            ["x"] = 1158.2,
        },
        ["Range"] = 45,
        ["ExtraLineText"] = "KILL_GORGER_AND_LOOT_HORNS",
    },
    { -- Step 14
        ["Done"] = {
            67177,
        },
        ["Coord"] = {
            ["y"] = -3570.3,
            ["x"] = 984.4,
        },
    },
    { -- Step 15
        ["Done"] = {
            67175,
        },
        ["Coord"] = {
            ["y"] = -3531.3,
            ["x"] = 1005.7,
        },
    },
    { -- Step 16
        ["Done"] = {
            66228,
        },
        ["Coord"] = {
            ["y"] = -3842.0,
            ["x"] = 415.5,
        },
    },
    { -- Step 17
        ["PickUp"] = {
            67033,
        },
        ["Coord"] = {
            ["y"] = -3812.3,
            ["x"] = 411.0,
        },
    },
    { -- Step 18
        ["PickUp"] = {
            67035,
        },
        ["Coord"] = {
            ["y"] = -3812.3,
            ["x"] = 411.0,
        },
    },
    { -- Step 19
        ["Qpart"] = {
            [67033] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3811.4,
            ["x"] = 480.3,
        },
        ["Range"] = 75,
        ["Fillers"] = { [67035] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "ARCANE_DEVICES_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 20
        ["Qpart"] = {
            [67035] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3811.4,
            ["x"] = 480.3,
        },
        ["Range"] = 75,
    },
    { -- Step 21
        ["Done"] = {
            67033,
        },
        ["Coord"] = {
            ["y"] = -3812.3,
            ["x"] = 411.0,
        },
    },
    { -- Step 22
        ["Done"] = {
            67035,
        },
        ["Coord"] = {
            ["y"] = -3812.3,
            ["x"] = 411.0,
        },
    },
    { -- Step 23
        ["PickUp"] = {
            67036,
        },
        ["Coord"] = {
            ["y"] = -3812.3,
            ["x"] = 411.0,
        },
    },
    { -- Step 24
        ["Qpart"] = {
            [67036] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3746.9,
            ["x"] = 450.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SHOOT_DRAGONS_USING_ARCANE_BLASTER",
    },
    { -- Step 25
        ["GetFP"] = 2774,
        ["Coord"] = {
            ["y"] = -3798.6,
            ["x"] = 408.3,
        },
        ["Range"] = 2,
    },
    { -- Step 26
        ["Done"] = {
            67036,
        },
        ["Coord"] = {
            ["y"] = -3841.6,
            ["x"] = 415.7,
        },
    },
    { -- Step 27
        ["PickUp"] = {
            65688,
        },
        ["Coord"] = {
            ["y"] = -3841.6,
            ["x"] = 415.7,
        },
    },
    { -- Step 28
        ["PickUp"] = {
            66488,
        },
        ["Coord"] = {
            ["y"] = -3802.6,
            ["x"] = 467.8,
        },
        ["ExtraLineText"] = "ON_ROCK",
    },
    { -- Step 29
        ["Qpart"] = {
            [65688] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3742.5,
            ["x"] = 486.3,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 30
        ["Qpart"] = {
            [65688] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3750.0,
            ["x"] = 490.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "LOOT_BAG",
    },
    { -- Step 31
        ["Qpart"] = {
            [66488] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3692.4,
            ["x"] = 272.6,
        },
        ["Range"] = 25,
    },
    { -- Step 32
        ["Done"] = {
            66488,
        },
        ["Coord"] = {
            ["y"] = -3707.5,
            ["x"] = 484.3,
        },
    },
    { -- Step 33
        ["PickUp"] = {
            66489,
        },
        ["Coord"] = {
            ["y"] = -3715.3,
            ["x"] = 486.1,
        },
    },
    { -- Step 34
        ["Qpart"] = {
            [66489] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3744.9,
            ["x"] = 462.1,
        },
        ["Range"] = 25,
        ["ExtraLineText"] = "TARGET_AZURE_DEFENDERS_USE_WAND",
        ["Button"] = {
            ["66489-1"] = 192471,
        },
    },
    { -- Step 35
        ["Done"] = {
            66489,
        },
        ["Coord"] = {
            ["y"] = -3715.3,
            ["x"] = 486.1,
        },
    },
    { -- Step 36
        ["PickUp"] = {
            65914,
        },
        ["Coord"] = {
            ["y"] = -4601.0,
            ["x"] = 618.7,
        },
    },
    { -- Step 37
        ["PickUp"] = {
            65925,
        },
        ["Coord"] = {
            ["y"] = -4601.0,
            ["x"] = 618.7,
        },
    },
    { -- Step 38
        ["Qpart"] = {
            [65925] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4657.5,
            ["x"] = 337.0,
        },
        ["Range"] = 225,
        ["Fillers"] = { [65914] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 39
        ["Qpart"] = {
            [65914] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4657.5,
            ["x"] = 337.0,
        },
        ["Range"] = 225,
    },
    { -- Step 40
        ["Done"] = {
            65914,
        },
        ["Coord"] = {
            ["y"] = -4858.6,
            ["x"] = 548.7,
        },
    },
    { -- Step 41
        ["Done"] = {
            65925,
        },
        ["Coord"] = {
            ["y"] = -4858.6,
            ["x"] = 548.7,
        },
    },
    { -- Step 42
        ["PickUp"] = {
            65926,
        },
        ["Coord"] = {
            ["y"] = -4858.6,
            ["x"] = 548.7,
        },
    },
    { -- Step 43
        ["Qpart"] = {
            [65926] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4858.6,
            ["x"] = 548.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "BUILD_BOAT",
    },
    { -- Step 44
        ["Done"] = {
            65926,
        },
        ["Coord"] = {
            ["y"] = -4860.0,
            ["x"] = 538.2,
        },
    },
    { -- Step 45
        ["PickUp"] = {
            66724,
        },
        ["Coord"] = {
            ["y"] = -4860.0,
            ["x"] = 538.2,
        },
    },
    { -- Step 46
        ["Qpart"] = {
            [66724] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4862.7,
            ["x"] = 573.9,
        },
        ["Range"] = 75,
        ["ExtraLineText"] = "FISHES_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 47
        ["Qpart"] = {
            [66724] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4859.6,
            ["x"] = 542.1,
        },
        ["Range"] = 2,
    },
    { -- Step 48
        ["Done"] = {
            66724,
        },
        ["Coord"] = {
            ["y"] = -4858.7,
            ["x"] = 545.1,
        },
    },
    { -- Step 49
        ["PickUp"] = {
            65929,
        },
        ["Coord"] = {
            ["y"] = -4859.6,
            ["x"] = 538.3,
        },
    },
    { -- Step 50
        ["PickUp"] = {
            65928,
        },
        ["Coord"] = {
            ["y"] = -4855.0,
            ["x"] = 547.2,
        },
    },
    { -- Step 51
        ["Qpart"] = {
            [65929] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5101.0,
            ["x"] = 427.5,
        },
        ["Range"] = 75,
        ["Fillers"] = { [65928] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "FREEZING_WATERS_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 52
        ["Qpart"] = {
            [65928] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5101.0,
            ["x"] = 427.5,
        },
        ["Range"] = 75,
    },
    { -- Step 53
        ["Done"] = {
            65928,
        },
        ["Coord"] = {
            ["y"] = -4859.3,
            ["x"] = 541.7,
        },
    },
    { -- Step 54
        ["Done"] = {
            65929,
        },
        ["Coord"] = {
            ["y"] = -4859.3,
            ["x"] = 541.7,
        },
    },
    { -- Step 55
        ["Done"] = {
            65688,
        },
        ["Coord"] = {
            ["y"] = -4919.3,
            ["x"] = 1039.0,
        },
    },
    { -- Step 56
        ["PickUp"] = {
            65689,
        },
        ["Coord"] = {
            ["y"] = -4919.3,
            ["x"] = 1039.0,
        },
    },
    { -- Step 57
        ["Qpart"] = {
            [65689] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4938.8,
            ["x"] = 1015.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "USE_CRYSTAL_PYLON",
    },
    { -- Step 58
        ["Done"] = {
            65689,
        },
        ["Coord"] = {
            ["y"] = -5212.8,
            ["x"] = 1058.4,
        },
    },
    { -- Step 59
        ["PickUp"] = {
            65702,
        },
        ["Coord"] = {
            ["y"] = -5212.8,
            ["x"] = 1058.4,
        },
    },
    { -- Step 60
        ["PickUp"] = {
            65709,
        },
        ["Coord"] = {
            ["y"] = -5216.8,
            ["x"] = 1063.4,
        },
    },
    { -- Step 61
        ["Qpart"] = {
            [65709] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5216.8,
            ["x"] = 1063.4,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SEARCH_BAG",
        ["Button"] = {
            ["65709-1"] = 191953,
        },
    },
    { -- Step 62
        ["Qpart"] = {
            [65709] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -5300.3,
            ["x"] = 1183.5,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65702] = { ["1"] = "1", }, },
        ["Button"] = {
            ["65709-2"] = 191952,
        },
    },
    { -- Step 63
        ["Qpart"] = {
            [65709] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -5447.0,
            ["x"] = 1009.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65702] = { ["1"] = "1", }, },
        ["Button"] = {
            ["65709-3"] = 191952,
        },
    },
    { -- Step 64
        ["Qpart"] = {
            [65702] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5348.8,
            ["x"] = 1128.9,
        },
        ["Range"] = 200,
    },
    { -- Step 65
        ["Done"] = {
            65702,
        },
        ["Coord"] = {
            ["y"] = -5214.3,
            ["x"] = 1060.5,
        },
    },
    { -- Step 66
        ["Done"] = {
            65709,
        },
        ["Coord"] = {
            ["y"] = -5214.3,
            ["x"] = 1060.5,
        },
    },
    { -- Step 67
        ["PickUp"] = {
            65852,
        },
        ["Coord"] = {
            ["y"] = -5214.3,
            ["x"] = 1060.5,
        },
    },
    { -- Step 68
        ["Qpart"] = {
            [65852] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5302.3,
            ["x"] = 1185.4,
        },
        ["Range"] = 3,
        ["ExtraLineText"] = "SEARCH_BAG",
        ["Button"] = {
            ["65852-1"] = 191978,
        },
    },
    { -- Step 69
        ["Qpart"] = {
            [65852] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -5300.3,
            ["x"] = 1183.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "USE_TELEPORT_THE_TOP",
        ["SpellButton"] = {
            ["65852-2"] = 378026,
        },
    },
    { -- Step 70
        ["Done"] = {
            65852,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
        ["ExtraActionB"] = 1,
    },
    { -- Step 71
        ["PickUp"] = {
            65751,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
    },
    { -- Step 72
        ["PickUp"] = {
            65752,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
    },
    { -- Step 73
        ["Qpart"] = {
            [65751] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5404.7,
            ["x"] = 1150.2,
        },
        ["Range"] = 75,
        ["Fillers"] = { [65752] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "UNSTABLE_ARCANE_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 74
        ["Qpart"] = {
            [65752] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5404.7,
            ["x"] = 1150.2,
        },
        ["Range"] = 75,
        ["Button"] = {
            ["65752-1"] = 194891,
        },
    },
    { -- Step 75
        ["Done"] = {
            65752,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
    },
    { -- Step 76
        ["Done"] = {
            65751,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
    },
    { -- Step 77
        ["PickUp"] = {
            65854,
        },
        ["Coord"] = {
            ["y"] = -5388.0,
            ["x"] = 1142.5,
        },
    },
    { -- Step 78
        ["Qpart"] = {
            [65854] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5513.3,
            ["x"] = 1199.5,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 79
        ["Done"] = {
            65854,
        },
        ["Coord"] = {
            ["y"] = -5504.8,
            ["x"] = 1195.0,
        },
    },
    { -- Step 80
        ["PickUp"] = {
            65855,
        },
        ["Coord"] = {
            ["y"] = -5504.8,
            ["x"] = 1195.0,
        },
    },
    { -- Step 81
        ["SetHS"] = 65856,
        ["Coord"] = {
            ["y"] = -5458.7,
            ["x"] = 1425.7,
        },
        ["ExtraLineText"] = "INSIDE_MOUNTAIN",
        ["Gossip"] = 1,
    },
    { -- Step 82
        ["GetFP"] = 2773,
        ["Coord"] = {
            ["y"] = -5341.8,
            ["x"] = 1457.9,
        },
        ["Range"] = 2,
    },
    { -- Step 83
        ["UseFlightPath"] = 65855,
        ["Coord"] = {
            ["y"] = -5341.8,
            ["x"] = 1457.9,
        },
        ["Range"] = 2,
        ["Name"] = "Camp Antonidas, Azure Span",
        ["NodeID"] = 2774,
        ["ExtraLineText"] = "TO_CAMP_ANTODINAS",
    },
    { -- Step 84
        ["Done"] = {
            65855,
        },
        ["Coord"] = {
            ["y"] = -3841.9,
            ["x"] = 415.3,
        },
    },
    { -- Step 85
        ["PickUp"] = {
            66699,
        },
        ["Coord"] = {
            ["y"] = -3841.9,
            ["x"] = 415.3,
        },
    },
    { -- Step 86
        ["PickUp"] = {
            69904,
        },
        ["Coord"] = {
            ["y"] = -3841.9,
            ["x"] = 415.3,
        },
    },
    { -- Step 87
        ["Qpart"] = {
            [69904] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3847.6,
            ["x"] = 304.0,
        },
        ["Range"] = 2,
    },
    { -- Step 88
        ["Done"] = {
            69904,
        },
        ["Coord"] = {
            ["y"] = -3847.6,
            ["x"] = 304.0,
        },
    },
    { -- Step 89
        ["PickUp"] = {
            66500,
        },
        ["Coord"] = {
            ["y"] = -3847.6,
            ["x"] = 304.0,
        },
    },
    { -- Step 90
        ["Qpart"] = {
            [66500] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3830.9,
            ["x"] = 292.3,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 91
        ["Qpart"] = {
            [66500] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3858.4,
            ["x"] = 363.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_TOWER",
        ["Gossip"] = 1,
    },
    { -- Step 92
        ["Qpart"] = {
            [66500] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3901.1,
            ["x"] = 482.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_HOUSE",
        ["Gossip"] = 1,
    },
    { -- Step 93
        ["Qpart"] = {
            [66500] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -3729.9,
            ["x"] = 483.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "ON_PILLAR",
        ["Gossip"] = 1,
    },
    { -- Step 94
        ["Qpart"] = {
            [66699] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3729.1,
            ["x"] = 403.5,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 95
        ["Qpart"] = {
            [66699] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3696.1,
            ["x"] = 448.5,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 96
        ["Qpart"] = {
            [66699] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3746.6,
            ["x"] = 515.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 97
        ["Done"] = {
            66699,
        },
        ["Coord"] = {
            ["y"] = -3746.6,
            ["x"] = 515.6,
        },
    },
    { -- Step 98
        ["PickUp"] = {
            65864,
        },
        ["Coord"] = {
            ["y"] = -3746.6,
            ["x"] = 515.6,
        },
    },
    { -- Step 99
        ["Done"] = {
            66500,
        },
        ["Coord"] = {
            ["y"] = -3847.6,
            ["x"] = 304.0,
        },
    },
    { -- Step 100
        ["Qpart"] = {
            [65864] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3611.1,
            ["x"] = 1656.2,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 101
        ["Done"] = {
            65864,
        },
        ["Coord"] = {
            ["y"] = -3611.1,
            ["x"] = 1656.2,
        },
        ["ExtraLineText"] = "WAIT_FOR_RP_END",
    },
    { -- Step 102
        ["PickUp"] = {
            65868,
        },
        ["Coord"] = {
            ["y"] = -3608.1,
            ["x"] = 1643.2,
        },
    },
    { -- Step 103
        ["PickUp"] = {
            65866,
        },
        ["Coord"] = {
            ["y"] = -3608.6,
            ["x"] = 1652.7,
        },
    },
    { -- Step 104
        ["PickUp"] = {
            65867,
        },
        ["Coord"] = {
            ["y"] = -3608.6,
            ["x"] = 1652.7,
        },
        ["Fillers"] = { [65866] = { ["1"] = "1", }, [65868] = { ["1"] = "1", }, },
    },
    { -- Step 105
        ["Qpart"] = {
            [65867] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3443.0,
            ["x"] = 1619.8,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65866] = { ["1"] = "1", }, [65868] = { ["1"] = "1", }, },
    },
    { -- Step 106
        ["Qpart"] = {
            [65867] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3291.0,
            ["x"] = 1689.4,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65866] = { ["1"] = "1", }, [65868] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 107
        ["Qpart"] = {
            [65867] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3332.5,
            ["x"] = 1797.9,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65866] = { ["1"] = "1", }, [65868] = { ["1"] = "1", }, },
    },
    { -- Step 108
        ["Qpart"] = {
            [65868] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3361.0,
            ["x"] = 1649.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65866] = { ["1"] = "1", }, },
    },
    { -- Step 109
        ["Qpart"] = {
            [65866] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3361.0,
            ["x"] = 1649.7,
        },
        ["Range"] = 2,
    },
    { -- Step 110
        ["Waypoint"] = 67173,
        ["Coord"] = {
            ["y"] = -3283.1,
            ["x"] = 1485.0,
        },
        ["Range"] = 20,
    },
    { -- Step 111
        ["Qpart"] = {
            [67173] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3283.1,
            ["x"] = 1485.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "BONUS_OBJECTIVE_THIEVING_GNOLLS",
        ["RaidIcon"] = 192749,
    },
    { -- Step 112
        ["Done"] = {
            65866,
        },
        ["Coord"] = {
            ["y"] = -3198.0,
            ["x"] = 1762.7,
        },
    },
    { -- Step 113
        ["Done"] = {
            65868,
        },
        ["Coord"] = {
            ["y"] = -3198.0,
            ["x"] = 1762.7,
        },
    },
    { -- Step 114
        ["Done"] = {
            65867,
        },
        ["Coord"] = {
            ["y"] = -3198.0,
            ["x"] = 1762.7,
        },
    },
    { -- Step 115
        ["PickUp"] = {
            65871,
        },
        ["Coord"] = {
            ["y"] = -3185.0,
            ["x"] = 1746.8,
        },
    },
    { -- Step 116
        ["PickUp"] = {
            65870,
        },
        ["Coord"] = {
            ["y"] = -3177.8,
            ["x"] = 1753.5,
        },
    },
    { -- Step 117
        ["PickUp"] = {
            65872,
        },
        ["Coord"] = {
            ["y"] = -3177.8,
            ["x"] = 1753.5,
        },
    },
    { -- Step 118
        ["PickUp"] = {
            65873,
        },
        ["Coord"] = {
            ["y"] = -3177.8,
            ["x"] = 1753.5,
        },
    },
    { -- Step 119
        ["Qpart"] = {
            [65870] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3135.6,
            ["x"] = 1805.5,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65872] = { ["1"] = "1", }, [65871] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 120
        ["Qpart"] = {
            [65870] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3071.4,
            ["x"] = 1843.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65872] = { ["1"] = "1", }, [65871] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 121
        ["Qpart"] = {
            [65873] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2869.1,
            ["x"] = 1792.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65872] = { ["1"] = "1", }, [65871] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 122
        ["Qpart"] = {
            [65870] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2932.4,
            ["x"] = 1723.8,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65872] = { ["1"] = "1", }, [65871] = { ["1"] = "1", ["2"] = "2", }, },
    },
    { -- Step 123
        ["Qpart"] = {
            [65871] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2956.8,
            ["x"] = 1778.7,
        },
        ["Range"] = 75,
        ["Fillers"] = { [65872] = { ["1"] = "1", }, },
    },
    { -- Step 124
        ["Qpart"] = {
            [65872] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2956.8,
            ["x"] = 1778.7,
        },
        ["Range"] = 75,
    },
    { -- Step 125
        ["Done"] = {
            65870,
        },
        ["Coord"] = {
            ["y"] = -3177.9,
            ["x"] = 1753.8,
        },
    },
    { -- Step 126
        ["Done"] = {
            65872,
        },
        ["Coord"] = {
            ["y"] = -3177.9,
            ["x"] = 1753.8,
        },
    },
    { -- Step 127
        ["Done"] = {
            65873,
        },
        ["Coord"] = {
            ["y"] = -3177.9,
            ["x"] = 1753.8,
        },
    },
    { -- Step 128
        ["Done"] = {
            65871,
        },
        ["Coord"] = {
            ["y"] = -3184.6,
            ["x"] = 1746.3,
        },
    },
    { -- Step 129
        ["PickUp"] = {
            66239,
        },
        ["Coord"] = {
            ["y"] = -3178.6,
            ["x"] = 1751.7,
        },
    },
    { -- Step 130
        ["Done"] = {
            66239,
        },
        ["Coord"] = {
            ["y"] = -3454.5,
            ["x"] = 2370.3,
        },
    },
    { -- Step 131
        ["PickUp"] = {
            65869,
        },
        ["Coord"] = {
            ["y"] = -3454.5,
            ["x"] = 2370.3,
        },
    },
    { -- Step 132
        ["PickUp"] = {
            71233,
        },
        ["Coord"] = {
            ["y"] = -3475.6,
            ["x"] = 2394.6,
        },
    },
    { -- Step 133
        ["Qpart"] = {
            [65869] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3448.7,
            ["x"] = 2371.0,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 134
        ["Qpart"] = {
            [65869] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3301.0,
            ["x"] = 2385.0,
        },
        ["Range"] = 120,
        ["ExtraLineText"] = "EXAMINE_BODIES_MARKED_ON_YOUR_MAP",
        ["Gossip"] = 1,
    },
    { -- Step 135
        ["Done"] = {
            65869,
        },
        ["Coord"] = {
            ["y"] = -3448.8,
            ["x"] = 2359.1,
        },
    },
    { -- Step 136
        ["PickUp"] = {
            66026,
        },
        ["Coord"] = {
            ["y"] = -3448.8,
            ["x"] = 2359.1,
        },
    },
    { -- Step 137
        ["Done"] = {
            66026,
        },
        ["Coord"] = {
            ["y"] = -3516.4,
            ["x"] = 3251.9,
        },
    },
    { -- Step 138
        ["PickUp"] = {
            66843,
        },
        ["Coord"] = {
            ["y"] = -2879.6,
            ["x"] = 3397.4,
        },
    },
    { -- Step 139
        ["PickUp"] = {
            66844,
        },
        ["Coord"] = {
            ["y"] = -2667.1,
            ["x"] = 3420.0,
        },
    },
    { -- Step 140
        ["GetFP"] = 2789,
        ["Coord"] = {
            ["y"] = -2653.1,
            ["x"] = 3409.1,
        },
        ["Range"] = 2,
    },
    { -- Step 141
        ["PickUp"] = {
            66839,
        },
        ["Coord"] = {
            ["y"] = -2617.9,
            ["x"] = 3426.8,
        },
    },
    { -- Step 142
        ["Done"] = {
            71233,
        },
        ["Coord"] = {
            ["y"] = -2702.8,
            ["x"] = 3452.6,
        },
        ["ExtraLineText"] = "INSIDE_TENT",
    },
    { -- Step 143
        ["PickUp"] = {
            66837,
        },
        ["Coord"] = {
            ["y"] = -2702.8,
            ["x"] = 3452.6,
        },
    },
    { -- Step 144
        ["PickUp"] = {
            66838,
        },
        ["Coord"] = {
            ["y"] = -2702.8,
            ["x"] = 3452.6,
        },
    },
    { -- Step 145
        ["Qpart"] = {
            [66844] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2835.6,
            ["x"] = 4046.0,
        },
        ["Range"] = 25,
    },
    { -- Step 146
        ["Qpart"] = {
            [66843] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2925.6,
            ["x"] = 3793.3,
        },
        ["Range"] = 15,
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 147
        ["Qpart"] = {
            [66837] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -2911.1,
            ["x"] = 3695.0,
        },
        ["Range"] = 2,
    },
    { -- Step 148
        ["Done"] = {
            66843,
        },
        ["Coord"] = {
            ["y"] = -2879.9,
            ["x"] = 3396.9,
        },
    },
    { -- Step 149
        ["Qpart"] = {
            [66839] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2835.3,
            ["x"] = 3171.6,
        },
        ["Range"] = 200,
        ["Fillers"] = { [66838] = { ["1"] = "1", }, },
    },
    { -- Step 150
        ["Qpart"] = {
            [66838] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2835.3,
            ["x"] = 3171.6,
        },
        ["Range"] = 200,
    },
    { -- Step 151
        ["Done"] = {
            66844,
        },
        ["Coord"] = {
            ["y"] = -2667.6,
            ["x"] = 3419.8,
        },
    },
    { -- Step 152
        ["Done"] = {
            66839,
        },
        ["Coord"] = {
            ["y"] = -2617.5,
            ["x"] = 3426.8,
        },
    },
    { -- Step 153
        ["Done"] = {
            66837,
            66838,
        },
        ["Coord"] = {
            ["y"] = -2702.8,
            ["x"] = 3452.6,
        },
    },
    { -- Step 154
        ["PickUp"] = {
            66841,
        },
        ["Coord"] = {
            ["y"] = -2721.6,
            ["x"] = 3407.9,
        },
    },
    { -- Step 155
        ["PickUp"] = {
            66840,
        },
        ["Coord"] = {
            ["y"] = -2645.1,
            ["x"] = 3475.1,
        },
    },
    { -- Step 156
        ["Qpart"] = {
            [66840] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2639.0,
            ["x"] = 3450.0,
        },
        ["Range"] = 180,
        ["ExtraLineText"] = "WATERFALLS_CAN_BE_SEEN_ON_YOUR_MINIMAP",
        ["Button"] = {
            ["66840-1"] = 193569,
        },
    },
    { -- Step 157
        ["Done"] = {
            66840,
        },
        ["Coord"] = {
            ["y"] = -2645.6,
            ["x"] = 3475.4,
        },
    },
    { -- Step 158
        ["Qpart"] = {
            [66841] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2977.3,
            ["x"] = 3577.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "GET_ON_ROCK",
    },
    { -- Step 159
        ["Done"] = {
            66841,
        },
        ["Coord"] = {
            ["y"] = -2646.5,
            ["x"] = 3463.1,
        },
    },
    { -- Step 160
        ["PickUp"] = {
            66845,
        },
        ["Coord"] = {
            ["y"] = -2700.1,
            ["x"] = 3453.3,
        },
    },
    { -- Step 161
        ["Qpart"] = {
            [66845] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2823.1,
            ["x"] = 3613.0,
        },
        ["Range"] = 2,
    },
    { -- Step 162
        ["Done"] = {
            66845,
        },
        ["Coord"] = {
            ["y"] = -2700.1,
            ["x"] = 3453.3,
        },
    },
    { -- Step 163
        ["PickUp"] = {
            66846,
        },
        ["Coord"] = {
            ["y"] = -2700.1,
            ["x"] = 3453.3,
        },
    },
    { -- Step 164
        ["Qpart"] = {
            [66846] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2700.1,
            ["x"] = 3453.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_MYSTERIOUS_APPARITION",
        ["Gossip"] = 1,
    },
    { -- Step 165
        ["Done"] = {
            66846,
        },
        ["Coord"] = {
            ["y"] = -2700.1,
            ["x"] = 3453.3,
        },
        ["ExtraLineText"] = "MOVE_AWAY_AND_RETURN_IF_YOU_ARE_UNABLE_TURN_IN_QUEST",
    },
    { -- Step 166
        ["PickUp"] = {
            65838,
        },
        ["Coord"] = {
            ["y"] = -3517.3,
            ["x"] = 3258.1,
        },
    },
    { -- Step 167
        ["Qpart"] = {
            [65838] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3611.6,
            ["x"] = 3439.0,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
        ["Gossip"] = 1,
    },
    { -- Step 168
        ["Qpart"] = {
            [65838] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3448.8,
            ["x"] = 3486.6,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
        ["Gossip"] = 1,
    },
    { -- Step 169
        ["Qpart"] = {
            [65838] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3612.8,
            ["x"] = 3578.9,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
        ["Gossip"] = 1,
    },
    { -- Step 170
        ["Done"] = {
            65838,
        },
        ["Coord"] = {
            ["y"] = -3635.1,
            ["x"] = 3669.1,
        },
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
    },
    { -- Step 171
        ["PickUp"] = {
            65846,
        },
        ["Coord"] = {
            ["y"] = -3635.1,
            ["x"] = 3669.1,
        },
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
    },
    { -- Step 172
        ["PickUp"] = {
            65844,
        },
        ["Coord"] = {
            ["y"] = -3630.9,
            ["x"] = 3669.1,
        },
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
    },
    { -- Step 173
        ["PickUp"] = {
            65845,
        },
        ["Coord"] = {
            ["y"] = -3628.8,
            ["x"] = 3670.3,
        },
        ["Fillers"] = { [65841] = { ["1"] = "1", }, [65844] = { ["1"] = "1", ["2"] = "2", }, [65846] = { ["1"] = "1", }, },
    },
    { -- Step 174
        ["Qpart"] = {
            [65845] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3693.6,
            ["x"] = 3548.9,
        },
        ["Range"] = 125,
        ["Fillers"] = { [65841] = { ["1"] = "1", }, [65844] = { ["1"] = "1", ["2"] = "2", }, [65846] = { ["1"] = "1", }, },
        ["Button"] = {
            ["65845-1"] = 191928,
        },
    },
    { -- Step 175
        ["Qpart"] = {
            [65844] = {
                ["1"] = "1",
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3693.6,
            ["x"] = 3548.9,
        },
        ["Range"] = 125,
        ["Fillers"] = { [65846] = { ["1"] = "1", }, [65841] = { ["1"] = "1", }, },
    },
    { -- Step 176
        ["Qpart"] = {
            [65846] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3693.6,
            ["x"] = 3548.9,
        },
        ["Range"] = 125,
        ["Fillers"] = { [65841] = { ["1"] = "1", }, },
    },
    { -- Step 177
        ["Qpart"] = {
            [65841] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3693.6,
            ["x"] = 3548.9,
        },
        ["Range"] = 125,
        ["ExtraLineText"] = "BONUS_OBJECTIVE",
    },
    { -- Step 178
        ["Done"] = {
            65846,
        },
        ["Coord"] = {
            ["y"] = -3635.1,
            ["x"] = 3669.1,
        },
    },
    { -- Step 179
        ["Done"] = {
            65844,
        },
        ["Coord"] = {
            ["y"] = -3630.9,
            ["x"] = 3669.1,
        },
    },
    { -- Step 180
        ["Done"] = {
            65845,
        },
        ["Coord"] = {
            ["y"] = -3628.8,
            ["x"] = 3670.3,
        },
    },
    { -- Step 181
        ["PickUp"] = {
            65848,
        },
        ["Coord"] = {
            ["y"] = -3628.8,
            ["x"] = 3670.3,
        },
    },
    { -- Step 182
        ["Qpart"] = {
            [65848] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3628.8,
            ["x"] = 3670.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "SPEAK_KALECGOS",
        ["Gossip"] = 1,
    },
    { -- Step 183
        ["Qpart"] = {
            [65848] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3628.8,
            ["x"] = 3670.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "RIDE_TOME_OF_SPELLFLINGING",
    },
    { -- Step 184
        ["Qpart"] = {
            [65848] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3694.0,
            ["x"] = 3792.0,
        },
        ["Range"] = 50,
        ["ExtraLineText"] = "TAKE_OUT_3_BRACKENHIDE_PUTRIFIERS",
    },
    { -- Step 185
        ["Qpart"] = {
            [65848] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -3694.0,
            ["x"] = 3792.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "SLAY_TWISTED_ANCIENT",
    },
    { -- Step 186
        ["Done"] = {
            65848,
        },
        ["Coord"] = {
            ["y"] = -3788.9,
            ["x"] = 3828.3,
        },
    },
    { -- Step 187
        ["PickUp"] = {
            65847,
        },
        ["Coord"] = {
            ["y"] = -3788.9,
            ["x"] = 3828.3,
        },
    },
    { -- Step 188
        ["Qpart"] = {
            [65847] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3794.1,
            ["x"] = 3820.8,
        },
        ["Range"] = 2,
    },
    { -- Step 189
        ["Qpart"] = {
            [65847] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3780.3,
            ["x"] = 3805.6,
        },
        ["Range"] = 20,
    },
    { -- Step 190
        ["Waypoint"] = 65847,
        ["Coord"] = {
            ["y"] = -3736.9,
            ["x"] = 3852.6,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "EXIT_CAVE",
    },
    { -- Step 191
        ["Done"] = {
            65847,
        },
        ["Coord"] = {
            ["y"] = -3932.5,
            ["x"] = 3740.1,
        },
    },
    { -- Step 192
        ["PickUp"] = {
            65849,
        },
        ["Coord"] = {
            ["y"] = -3935.9,
            ["x"] = 3743.5,
        },
    },
    { -- Step 193
        ["Qpart"] = {
            [69872] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3957.0,
            ["x"] = 3615.6,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "RARE__YOU_SHOULD_ONLY_HAVE_BRING_HIM_TO_40_HP_TO_DEFEAT_HIM",
    },
    { -- Step 194
        ["Done"] = {
            65849,
        },
        ["Coord"] = {
            ["y"] = -4522.6,
            ["x"] = 4051.6,
        },
    },
    { -- Step 195
        ["PickUp"] = {
            66210,
        },
        ["Coord"] = {
            ["y"] = -4522.6,
            ["x"] = 4051.6,
        },
    },
    { -- Step 196
        ["PickUp"] = {
            72435,
        },
        ["Coord"] = {
            ["y"] = -4502.1,
            ["x"] = 4063.0,
        },
    },
    { -- Step 197
        ["PickUp"] = {
            66218,
        },
        ["Coord"] = {
            ["y"] = -4461.8,
            ["x"] = 4088.6,
        },
    },
    { -- Step 198
        ["Qpart"] = {
            [72435] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -4456.5,
            ["x"] = 4085.9,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_DRAKE_SCHOLAR",
        ["RaidIcon"] = 196544,
    },
    { -- Step 199
        ["Qpart"] = {
            [72435] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4448.8,
            ["x"] = 4059.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_EQUIPMENT_SUPPLIER",
        ["RaidIcon"] = 186449,
    },
    { -- Step 200
        ["Qpart"] = {
            [72435] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -4470.5,
            ["x"] = 4057.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_MOUNT_SUPPLIER",
        ["RaidIcon"] = 186462,
    },
    { -- Step 201
        ["GetFP"] = 2775,
        ["Coord"] = {
            ["y"] = -4466.3,
            ["x"] = 4047.3,
        },
        ["Range"] = 2,
    },
    { -- Step 202
        ["QpartPart"] = {
            [66210] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4452.3,
            ["x"] = 4025.8,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CLICK_DECORATED_TEAPOT",
        ["TrigText"] = "1/4",
    },
    { -- Step 203
        ["QpartPart"] = {
            [66210] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4518.8,
            ["x"] = 3983.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CLICK_HANDCRAFTED_BOAT",
        ["TrigText"] = "2/4",
    },
    { -- Step 204
        ["Qpart"] = {
            [72435] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4561.8,
            ["x"] = 3979.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "TALK_RECIPE_SUPPLIER",
        ["RaidIcon"] = 194059,
    },
    { -- Step 205
        ["QpartPart"] = {
            [66210] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4579.6,
            ["x"] = 4137.8,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CLICK_ORNAMENTED_SHIELD",
        ["TrigText"] = "3/4",
    },
    { -- Step 206
        ["Waypoint"] = 66213,
        ["Coord"] = {
            ["y"] = -4508.3,
            ["x"] = 4097.8,
        },
        ["Range"] = 10,
        ["ExtraLineText"] = "HEAD_ELDERS_HUT_AND_GO_DOWN_THE_TUNNEL",
    },
    { -- Step 207
        ["PickUp"] = {
            66213,
        },
        ["Coord"] = {
            ["y"] = -4512.5,
            ["x"] = 4141.8,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_TUNNEL",
    },
    { -- Step 208
        ["Qpart"] = {
            [66213] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4508.4,
            ["x"] = 4142.2,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 209
        ["Done"] = {
            66213,
        },
        ["Coord"] = {
            ["y"] = -4512.5,
            ["x"] = 4141.8,
        },
        ["Range"] = 2,
    },
    { -- Step 210
        ["QpartPart"] = {
            [66210] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4516.6,
            ["x"] = 4134.3,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CLICK_STONE_SCULPTURE",
    },
    { -- Step 211
        ["Waypoint"] = 66213,
        ["Coord"] = {
            ["y"] = -4508.3,
            ["x"] = 4097.8,
        },
        ["Range"] = 5,
        ["ExtraLineText"] = "HEAD_OUT",
    },
    { -- Step 212
        ["Qpart"] = {
            [66210] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4453.5,
            ["x"] = 4065.9,
        },
        ["Range"] = 2,
    },
    { -- Step 213
        ["Done"] = {
            72435,
        },
        ["Coord"] = {
            ["y"] = -4502.1,
            ["x"] = 4063.0,
        },
    },
    { -- Step 214
        ["Done"] = {
            66210,
        },
        ["Coord"] = {
            ["y"] = -4522.6,
            ["x"] = 4051.6,
        },
    },
    { -- Step 215
        ["PickUp"] = {
            65850,
        },
        ["Coord"] = {
            ["y"] = -4521.8,
            ["x"] = 4049.8,
        },
    },
    { -- Step 216
        ["PickUp"] = {
            66558,
        },
        ["Coord"] = {
            ["y"] = -4383.3,
            ["x"] = 3995.8,
        },
    },
    { -- Step 217
        ["Qpart"] = {
            [66218] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4329.0,
            ["x"] = 4340.0,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 218
        ["Done"] = {
            66218,
        },
        ["Coord"] = {
            ["y"] = -4329.0,
            ["x"] = 4340.0,
        },
    },
    { -- Step 219
        ["PickUp"] = {
            66223,
        },
        ["Coord"] = {
            ["y"] = -4329.0,
            ["x"] = 4340.0,
        },
    },
    { -- Step 220
        ["Qpart"] = {
            [66223] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4518.6,
            ["x"] = 3985.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "BUY_7_FRIGIDFISH_FROM_JINKUTUK",
        ["Gossip"] = 1,
        ["RaidIcon"] = 193637,
    },
    { -- Step 221
        ["Done"] = {
            66223,
        },
        ["Coord"] = {
            ["y"] = -4329.0,
            ["x"] = 4340.0,
        },
    },
    { -- Step 222
        ["PickUp"] = {
            66781,
        },
        ["Coord"] = {
            ["y"] = -4147.8,
            ["x"] = 4661.3,
        },
    },
    { -- Step 223
        ["Qpart"] = {
            [66781] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4200.3,
            ["x"] = 4705.8,
        },
        ["Range"] = 2,
    },
    { -- Step 224
        ["Done"] = {
            66781,
        },
        ["Coord"] = {
            ["y"] = -4147.8,
            ["x"] = 4661.3,
        },
    },
    { -- Step 225
        ["PickUp"] = {
            66164,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4660.7,
        },
    },
    { -- Step 226
        ["PickUp"] = {
            66154,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4660.7,
        },
    },
    { -- Step 227
        ["PickUp"] = {
            66147,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4660.7,
        },
    },
    { -- Step 228
        ["Qpart"] = {
            [66147] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4039.3,
            ["x"] = 4380.6,
        },
        ["Range"] = 56,
        ["Fillers"] = { [66154] = { ["1"] = "1", }, [66164] = { ["1"] = "1", }, },
    },
    { -- Step 229
        ["Qpart"] = {
            [66164] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4066.5,
            ["x"] = 4390.5,
        },
        ["Range"] = 68,
        ["Fillers"] = { [66154] = { ["1"] = "1", }, },
    },
    { -- Step 230
        ["Qpart"] = {
            [66154] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4070.7,
            ["x"] = 4376.8,
        },
        ["Range"] = 88,
    },
    { -- Step 231
        ["Done"] = {
            66147,
        },
        ["Coord"] = {
            ["y"] = -4137.6,
            ["x"] = 4662.1,
        },
    },
    { -- Step 232
        ["Done"] = {
            66154,
        },
        ["Coord"] = {
            ["y"] = -4140.1,
            ["x"] = 4659.1,
        },
    },
    { -- Step 233
        ["Done"] = {
            66164,
        },
        ["Coord"] = {
            ["y"] = -4145.0,
            ["x"] = 4661.2,
        },
    },
    { -- Step 234
        ["PickUp"] = {
            66175,
        },
        ["Coord"] = {
            ["y"] = -4145.0,
            ["x"] = 4661.2,
        },
    },
    { -- Step 235
        ["Qpart"] = {
            [66175] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4143.7,
            ["x"] = 4662.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "ACTIVATE_SCANNER",
    },
    { -- Step 236
        ["Done"] = {
            66175,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4660.7,
        },
    },
    { -- Step 237
        ["PickUp"] = {
            66177,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4660.7,
        },
    },
    { -- Step 238
        ["PickUp"] = {
            66232,
        },
        ["Coord"] = {
            ["y"] = -4141.5,
            ["x"] = 4680.3,
        },
    },
    { -- Step 239
        ["Qpart"] = {
            [66177] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4012.6,
            ["x"] = 4473.7,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66232] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "FIRST_CLUE",
    },
    { -- Step 240
        ["Qpart"] = {
            [66177] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3925.5,
            ["x"] = 4404.2,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66232] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "SECOND_CLUE",
    },
    { -- Step 241
        ["Qpart"] = {
            [66177] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3806.4,
            ["x"] = 4410.2,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66232] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "THIRD_CLUE",
    },
    { -- Step 242
        ["Qpart"] = {
            [66177] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -3919.4,
            ["x"] = 4338.2,
        },
        ["Range"] = 2,
        ["Fillers"] = { [66232] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "FOURTH_CLUE",
    },
    { -- Step 243
        ["Qpart"] = {
            [66232] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3944.9,
            ["x"] = 4415.8,
        },
        ["Range"] = 158,
    },
    { -- Step 244
        ["Done"] = {
            66177,
        },
        ["Coord"] = {
            ["y"] = -3915.6,
            ["x"] = 4321.1,
        },
    },
    { -- Step 245
        ["PickUp"] = {
            66187,
        },
        ["Coord"] = {
            ["y"] = -3915.6,
            ["x"] = 4321.1,
        },
    },
    { -- Step 246
        ["Qpart"] = {
            [66187] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3914.3,
            ["x"] = 4277.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "INSIDE_CAVE",
    },
    { -- Step 247
        ["Done"] = {
            66187,
        },
        ["Coord"] = {
            ["y"] = -3915.6,
            ["x"] = 4321.1,
        },
    },
    { -- Step 248
        ["PickUp"] = {
            66559,
        },
        ["Coord"] = {
            ["y"] = -3915.6,
            ["x"] = 4321.1,
        },
    },
    { -- Step 249
        ["Done"] = {
            66559,
        },
        ["Coord"] = {
            ["y"] = -4141.3,
            ["x"] = 4659.2,
        },
    },
    { -- Step 250
        ["Done"] = {
            66232,
        },
        ["Coord"] = {
            ["y"] = -4141.3,
            ["x"] = 4680.8,
        },
    },
    { -- Step 251
        ["Qpart"] = {
            [65850] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4522.6,
            ["x"] = 4051.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 252
        ["Qpart"] = {
            [65850] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4568.8,
            ["x"] = 4060.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "PUSH_BOAT",
    },
    { -- Step 253
        ["Done"] = {
            65850,
        },
        ["Coord"] = {
            ["y"] = -4584.2,
            ["x"] = 4085.1,
        },
    },
    { -- Step 254
        ["PickUp"] = {
            65911,
        },
        ["Coord"] = {
            ["y"] = -4584.2,
            ["x"] = 4085.1,
        },
    },
    { -- Step 255
        ["Qpart"] = {
            [66558] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4586.7,
            ["x"] = 3738.6,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 256
        ["Done"] = {
            66558,
        },
        ["Coord"] = {
            ["y"] = -4586.7,
            ["x"] = 3738.6,
        },
    },
    { -- Step 257
        ["PickUp"] = {
            70129,
        },
        ["Coord"] = {
            ["y"] = -4586.7,
            ["x"] = 3738.6,
        },
    },
    { -- Step 258
        ["Qpart"] = {
            [70129] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -4507.7,
            ["x"] = 3668.9,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "GO_INSIDE_CAVE",
        ["Gossip"] = 1,
    },
    { -- Step 259
        ["Done"] = {
            70129,
        },
        ["Coord"] = {
            ["y"] = -4484.3,
            ["x"] = 3991.1,
        },
    },
    { -- Step 260
        ["UseHS"] = 65911,
        ["Button"] = {
            ["22345678-1"] = 6948,
        },
        ["Coord"] = {
            ["y"] = -4484.3,
            ["x"] = 3991.1,
        },
        ["ExtraLineText"] = "TO_CONJURED_BISCUIT_INN",
    },
    { -- Step 261
        ["Done"] = {
            65911,
        },
        ["Coord"] = {
            ["y"] = -5500.8,
            ["x"] = 1195.9,
        },
    },
    { -- Step 262
        ["PickUp"] = {
            66027,
        },
        ["Coord"] = {
            ["y"] = -5500.8,
            ["x"] = 1195.9,
        },
    },
    { -- Step 263
        ["Qpart"] = {
            [66027] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5500.8,
            ["x"] = 1195.9,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 264
        ["Done"] = {
            66027,
        },
        ["Coord"] = {
            ["y"] = -5500.8,
            ["x"] = 1195.9,
        },
    },
    { -- Step 265
        ["PickUp"] = {
            65886,
        },
        ["Coord"] = {
            ["y"] = -5500.8,
            ["x"] = 1195.9,
        },
    },
    { -- Step 266
        ["Waypoint"] = 65886,
        ["Coord"] = {
            ["y"] = -5390.8,
            ["x"] = 1327.9,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "GO_ON_TOP_OF_ARCHIVES_AND_DRAGONFLY_CAMP_NOWHERE",
        ["SpellButton"] = {
            ["65886-2"] = 378026,
        },
    },
    { -- Step 267
        ["PickUp"] = {
            66391,
        },
        ["Coord"] = {
            ["y"] = -5136.1,
            ["x"] = -1413.0,
        },
    },
    { -- Step 268
        ["GetFP"] = 2784,
        ["Coord"] = {
            ["y"] = -5184.8,
            ["x"] = -1414.0,
        },
        ["Range"] = 2,
    },
    { -- Step 269
        ["Done"] = {
            66391,
        },
        ["Coord"] = {
            ["y"] = -5181.5,
            ["x"] = -1585.5,
        },
    },
    { -- Step 270
        ["PickUp"] = {
            66353,
        },
        ["Coord"] = {
            ["y"] = -5181.5,
            ["x"] = -1585.5,
        },
    },
    { -- Step 271
        ["PickUp"] = {
            66352,
        },
        ["Coord"] = {
            ["y"] = -5182.2,
            ["x"] = -1583.5,
        },
    },
    { -- Step 272
        ["Qpart"] = {
            [66353] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5247.8,
            ["x"] = -1680.9,
        },
        ["Range"] = 125,
        ["Fillers"] = { [66352] = { ["1"] = "1", }, },
        ["Button"] = {
            ["66353-1"] = 191909,
        },
    },
    { -- Step 273
        ["Qpart"] = {
            [66352] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5249.1,
            ["x"] = -1672.5,
        },
        ["Range"] = 125,
        ["Button"] = {
            ["66352-1"] = 191909,
        },
    },
    { -- Step 274
        ["Done"] = {
            66353,
        },
        ["Coord"] = {
            ["y"] = -5181.5,
            ["x"] = -1585.5,
        },
    },
    { -- Step 275
        ["Done"] = {
            66352,
        },
        ["Coord"] = {
            ["y"] = -5182.2,
            ["x"] = -1583.5,
        },
    },
    { -- Step 276
        ["PickUp"] = {
            66422,
        },
        ["Coord"] = {
            ["y"] = -5182.2,
            ["x"] = -1583.5,
        },
    },
    { -- Step 277
        ["Done"] = {
            66422,
        },
        ["Coord"] = {
            ["y"] = -5339.6,
            ["x"] = -1652.5,
        },
    },
    { -- Step 278
        ["PickUp"] = {
            66423,
        },
        ["Coord"] = {
            ["y"] = -5339.6,
            ["x"] = -1652.5,
        },
    },
    { -- Step 279
        ["Qpart"] = {
            [66423] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5333.8,
            ["x"] = -1646.0,
        },
        ["Range"] = 50,
        ["ExtraLineText"] = "CLUES_CAN_BE_SEEN_ON_YOUR_MINIMAP",
    },
    { -- Step 280
        ["Done"] = {
            66423,
        },
        ["Coord"] = {
            ["y"] = -5339.6,
            ["x"] = -1652.5,
        },
    },
    { -- Step 281
        ["PickUp"] = {
            66425,
        },
        ["Coord"] = {
            ["y"] = -5336.8,
            ["x"] = -1652.2,
        },
    },
    { -- Step 282
        ["Qpart"] = {
            [66425] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5374.0,
            ["x"] = -1613.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "TWO_DOWNSTAIRS_ONE_UPSTAIRS",
        ["Button"] = {
            ["66425-1"] = 192110,
        },
    },
    { -- Step 283
        ["Done"] = {
            66425,
        },
        ["Coord"] = {
            ["y"] = -5336.8,
            ["x"] = -1652.2,
        },
    },
    { -- Step 284
        ["PickUp"] = {
            66426,
        },
        ["Coord"] = {
            ["y"] = -5339.6,
            ["x"] = -1652.5,
        },
    },
    { -- Step 285
        ["Done"] = {
            66426,
        },
        ["Coord"] = {
            ["y"] = -5318.1,
            ["x"] = -1959.5,
        },
        ["ExtraLineText"] = "FLY_WITH_YOUR_DRAGON_AVOID_BOMBS",
    },
    { -- Step 286
        ["PickUp"] = {
            66427,
        },
        ["Coord"] = {
            ["y"] = -5318.1,
            ["x"] = -1959.5,
        },
    },
    { -- Step 287
        ["Qpart"] = {
            [66427] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5397.1,
            ["x"] = -1917.5,
        },
        ["Range"] = 2,
    },
    { -- Step 288
        ["Done"] = {
            66427,
        },
        ["Coord"] = {
            ["y"] = -5318.1,
            ["x"] = -1959.5,
        },
    },
    { -- Step 289
        ["PickUp"] = {
            66428,
        },
        ["Coord"] = {
            ["y"] = -5313.1,
            ["x"] = -1961.9,
        },
    },
    { -- Step 290
        ["Qpart"] = {
            [66428] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5311.1,
            ["x"] = -1971.0,
        },
        ["Range"] = 2,
        ["Button"] = {
            ["66428-1"] = 192475,
        },
    },
    { -- Step 291
        ["Done"] = {
            66428,
        },
        ["Coord"] = {
            ["y"] = -5316.3,
            ["x"] = -1964.4,
        },
    },
    { -- Step 292
        ["PickUp"] = {
            66429,
        },
        ["Coord"] = {
            ["y"] = -5316.3,
            ["x"] = -1964.4,
        },
    },
    { -- Step 293
        ["Done"] = {
            66429,
        },
        ["Coord"] = {
            ["y"] = -5202.8,
            ["x"] = -1439.8,
        },
    },
    { -- Step 294
        ["PickUp"] = {
            66709,
        },
        ["Coord"] = {
            ["y"] = -3810.6,
            ["x"] = -958.5,
        },
    },
    { -- Step 295
        ["Qpart"] = {
            [66709] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3810.6,
            ["x"] = -958.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "PULL_OUT_SPEAR",
    },
    { -- Step 296
        ["Qpart"] = {
            [66709] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3815.5,
            ["x"] = -951.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "COLLECT_WOOD",
    },
    { -- Step 297
        ["Qpart"] = {
            [66709] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3811.1,
            ["x"] = -957.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "BUILD_CAMPFIRE",
    },
    { -- Step 298
        ["Qpart"] = {
            [66709] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -3811.1,
            ["x"] = -957.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "CAUTERIZE_WOUND",
        ["Gossip"] = 1,
    },
    { -- Step 299
        ["Done"] = {
            66709,
        },
        ["Coord"] = {
            ["y"] = -3810.6,
            ["x"] = -958.5,
        },
    },
    { -- Step 300
        ["PickUp"] = {
            66715,
        },
        ["Coord"] = {
            ["y"] = -3810.6,
            ["x"] = -958.5,
        },
    },
    { -- Step 301
        ["Qpart"] = {
            [66715] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3978.1,
            ["x"] = -860.1,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "COMPLETES_WHEN_YOU_GET_CLOSE",
    },
    { -- Step 302
        ["Done"] = {
            66715,
        },
        ["Coord"] = {
            ["y"] = -3978.1,
            ["x"] = -860.1,
        },
    },
    { -- Step 303
        ["PickUp"] = {
            66703,
        },
        ["Coord"] = {
            ["y"] = -3978.1,
            ["x"] = -860.1,
        },
    },
    { -- Step 304
        ["Qpart"] = {
            [66703] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3998.5,
            ["x"] = -823.2,
        },
        ["Range"] = 75,
        ["Fillers"] = { [66718] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "SHAMANS_CAN_BE_SEEN_ON_YOUR_MINIMAP",
    },
    { -- Step 305
        ["Qpart"] = {
            [66718] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -4200.2,
            ["x"] = -804.1,
        },
        ["Range"] = 40,
        ["Fillers"] = { [66718] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KILL_SNOLL_ICEBREAKER",
        ["RaidIcon"] = 190384,
    },
    { -- Step 306
        ["Qpart"] = {
            [66718] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3998.5,
            ["x"] = -823.2,
        },
        ["Range"] = 40,
    },
    { -- Step 307
        ["Done"] = {
            66703,
        },
        ["Coord"] = {
            ["y"] = -3978.1,
            ["x"] = -860.1,
        },
    },
    { -- Step 308
        ["PickUp"] = {
            67050,
        },
        ["Coord"] = {
            ["y"] = -3978.1,
            ["x"] = -860.1,
        },
    },
    { -- Step 309
        ["Qpart"] = {
            [67050] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3972.1,
            ["x"] = -848.0,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "PLACE_TOTEMS",
    },
    { -- Step 310
        ["Qpart"] = {
            [67050] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3869.6,
            ["x"] = -872.2,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "COMPLETES_WHEN_YOU_TALK_NPC",
    },
    { -- Step 311
        ["Done"] = {
            67050,
        },
        ["Coord"] = {
            ["y"] = -3869.6,
            ["x"] = -872.2,
        },
    },
    { -- Step 312
        ["PickUp"] = {
            66730,
        },
        ["Coord"] = {
            ["y"] = -3869.6,
            ["x"] = -872.2,
        },
    },
    { -- Step 313
        ["Done"] = {
            66730,
        },
        ["Coord"] = {
            ["y"] = -3461.1,
            ["x"] = -906.7,
        },
    },
    { -- Step 314
        ["Qpart"] = {
            [65886] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2796.5,
            ["x"] = -1648.7,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "COMPLETES_WHEN_YOU_ARE_CLOSE_BUBBLE",
    },
    { -- Step 315
        ["Done"] = {
            65886,
        },
        ["Coord"] = {
            ["y"] = -2764.5,
            ["x"] = -1671.0,
        },
    },
    { -- Step 316
        ["PickUp"] = {
            65887,
        },
        ["Coord"] = {
            ["y"] = -2765.0,
            ["x"] = -1671.0,
        },
    },
    { -- Step 317
        ["PickUp"] = {
            67299,
        },
        ["Coord"] = {
            ["y"] = -2765.0,
            ["x"] = -1671.0,
        },
    },
    { -- Step 318
        ["GetFP"] = 2786,
        ["Coord"] = {
            ["y"] = -2769.8,
            ["x"] = -1692.0,
        },
        ["Range"] = 2,
    },
    { -- Step 319
        ["Qpart"] = {
            [67299] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -2784.6,
            ["x"] = -1699.0,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "USE_ARCANE_BLASTER_KILL_DRAGONS",
    },
    { -- Step 320
        ["Done"] = {
            67299,
        },
        ["Coord"] = {
            ["y"] = -2765.0,
            ["x"] = -1671.0,
        },
    },
    { -- Step 321
        ["Waypoint"] = 69895,
        ["Coord"] = {
            ["y"] = -3335.4,
            ["x"] = -2135.6,
        },
        ["Range"] = 25,
    },
    { -- Step 322
        ["Qpart"] = {
            [69895] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3335.4,
            ["x"] = -2135.6,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "BONUS_OBJECTIVE",
    },
    { -- Step 323
        ["Done"] = {
            65887,
        },
        ["Coord"] = {
            ["y"] = -3483.9,
            ["x"] = -2128.4,
        },
    },
    { -- Step 324
        ["PickUp"] = {
            65943,
        },
        ["Coord"] = {
            ["y"] = -3483.9,
            ["x"] = -2128.4,
        },
    },
    { -- Step 325
        ["PickUp"] = {
            65944,
        },
        ["Coord"] = {
            ["y"] = -3491.9,
            ["x"] = -2129.8,
        },
    },
    { -- Step 326
        ["PickUp"] = {
            66647,
        },
        ["Coord"] = {
            ["y"] = -3491.9,
            ["x"] = -2129.8,
        },
    },
    { -- Step 327
        ["Qpart"] = {
            [66647] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3727.6,
            ["x"] = -2441.1,
        },
        ["Range"] = 2,
        ["Fillers"] = { [65944] = { ["1"] = "1", }, [65943] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "LAVA_ORBS_CAN_BE_SEEN_ON_MINIMAP_KILL_AND_LOOT_RUVIN_STONEGRINDER",
    },
    { -- Step 328
        ["Qpart"] = {
            [65944] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3624.7,
            ["x"] = -2397.1,
        },
        ["Range"] = 200,
        ["Fillers"] = { [65943] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "LAVA_ORBS_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 329
        ["Qpart"] = {
            [65943] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3624.7,
            ["x"] = -2397.1,
        },
        ["Range"] = 200,
    },
    { -- Step 330
        ["Done"] = {
            65943,
        },
        ["Coord"] = {
            ["y"] = -3673.0,
            ["x"] = -2613.3,
        },
    },
    { -- Step 331
        ["Done"] = {
            65944,
        },
        ["Coord"] = {
            ["y"] = -3673.0,
            ["x"] = -2613.3,
        },
    },
    { -- Step 332
        ["Done"] = {
            66647,
        },
        ["Coord"] = {
            ["y"] = -3673.0,
            ["x"] = -2613.3,
        },
    },
    { -- Step 333
        ["PickUp"] = {
            65977,
        },
        ["Coord"] = {
            ["y"] = -3673.0,
            ["x"] = -2613.3,
        },
    },
    { -- Step 334
        ["PickUp"] = {
            65958,
        },
        ["Coord"] = {
            ["y"] = -3673.0,
            ["x"] = -2613.3,
        },
    },
    { -- Step 335
        ["Qpart"] = {
            [65977] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3685.6,
            ["x"] = -2724.1,
        },
        ["Range"] = 75,
        ["Fillers"] = { [65958] = { ["1"] = "1", }, },
        ["ExtraLineText"] = "KIRIN_TOR_MAGES_CAN_BE_SEEN_ON_MINIMAP",
        ["Button"] = {
            ["65977-1"] = 192479,
        },
    },
    { -- Step 336
        ["Qpart"] = {
            [65958] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3685.6,
            ["x"] = -2724.1,
        },
        ["Range"] = 75,
        ["Button"] = {
            ["65958-1"] = 192479,
        },
    },
    { -- Step 337
        ["Done"] = {
            65958,
        },
        ["Coord"] = {
            ["y"] = -3789.4,
            ["x"] = -2883.9,
        },
    },
    { -- Step 338
        ["Done"] = {
            65977,
        },
        ["Coord"] = {
            ["y"] = -3789.4,
            ["x"] = -2883.9,
        },
    },
    { -- Step 339
        ["PickUp"] = {
            66007,
        },
        ["Coord"] = {
            ["y"] = -3789.4,
            ["x"] = -2883.9,
        },
    },
    { -- Step 340
        ["Qpart"] = {
            [66007] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3758.6,
            ["x"] = -2952.0,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "LAVA_BEACONS_CAN_BE_SEEN_ON_MINIMAP",
    },
    { -- Step 341
        ["Done"] = {
            66007,
        },
        ["Coord"] = {
            ["y"] = -3829.1,
            ["x"] = -3039.5,
        },
    },
    { -- Step 342
        ["PickUp"] = {
            66009,
        },
        ["Coord"] = {
            ["y"] = -3829.1,
            ["x"] = -3039.5,
        },
    },
    { -- Step 343
        ["Qpart"] = {
            [66009] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3577.0,
            ["x"] = -3117.4,
        },
        ["Range"] = 2,
    },
    { -- Step 344
        ["Done"] = {
            66009,
        },
        ["Coord"] = {
            ["y"] = -3285.3,
            ["x"] = -2997.8,
        },
    },
    { -- Step 345
        ["PickUp"] = {
            70041,
        },
        ["Coord"] = {
            ["y"] = -3285.3,
            ["x"] = -2997.8,
        },
    },
    { -- Step 346
        ["Qpart"] = {
            [70041] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -3281.0,
            ["x"] = -3002.0,
        },
        ["Range"] = 3,
        ["ExtraLineText"] = "ENTER_DISC",
    },
    { -- Step 347
        ["Qpart"] = {
            [70041] = {
                ["2"] = "2",
            },
        },
        ["Coord"] = {
            ["y"] = -3281.0,
            ["x"] = -3002.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "KILL_ELEMENTALS",
    },
    { -- Step 348
        ["Qpart"] = {
            [70041] = {
                ["3"] = "3",
            },
        },
        ["Coord"] = {
            ["y"] = -3281.0,
            ["x"] = -3002.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "DISPELL_STORMS",
    },
    { -- Step 349
        ["Qpart"] = {
            [70041] = {
                ["4"] = "4",
            },
        },
        ["Coord"] = {
            ["y"] = -3281.0,
            ["x"] = -3002.0,
        },
        ["Range"] = 20,
        ["ExtraLineText"] = "KILL_ELEMENTALS",
    },
    { -- Step 350
        ["Done"] = {
            70041,
        },
        ["Coord"] = {
            ["y"] = -3346.6,
            ["x"] = -3022.6,
        },
    },
    { -- Step 351
        ["PickUp"] = {
            66015,
        },
        ["Coord"] = {
            ["y"] = -3346.6,
            ["x"] = -3022.6,
        },
    },
    { -- Step 352
        ["UseHS"] = 66015,
        ["Button"] = {
            ["22345678-1"] = 6948,
        },
        ["Coord"] = {
            ["y"] = -3346.6,
            ["x"] = -3022.6,
        },
        ["ExtraLineText"] = "TO_CONJURED_BISCUIT_INN",
    },
    { -- Step 353
        ["Qpart"] = {
            [66015] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = -5504.3,
            ["x"] = 1195.4,
        },
        ["Range"] = 2,
        ["Gossip"] = 1,
    },
    { -- Step 354
        ["Done"] = {
            66015,
        },
        ["Coord"] = {
            ["y"] = -5504.3,
            ["x"] = 1195.4,
        },
    },
    { -- Step 355
        ["PickUp"] = {
            66244,
        },
        ["Coord"] = {
            ["y"] = -5504.3,
            ["x"] = 1195.4,
        },
    },
    { -- Step 356
        ["UseFlightPath"] = 66244,
        ["Coord"] = {
            ["y"] = -5342.1,
            ["x"] = 1457.9,
        },
        ["Range"] = 2,
        ["Name"] = "Pinewood Post, Ohn'ahran Plains",
        ["NodeID"] = 2798,
        ["ExtraLineText"] = "TO_PINEWOOD_POST",
    },
    { -- Step 357
        ["Qpart"] = {
            [66244] = {
                ["1"] = "1",
            },
        },
        ["Coord"] = {
            ["y"] = 338.8,
            ["x"] = -1099.5,
        },
        ["Range"] = 2,
        ["ExtraLineText"] = "GET_INSIDE_AND_USE_PORTAL_TOP",
    },
    { -- Step 358
        ["Done"] = {
            66244,
        },
        ["Coord"] = {
            ["y"] = 306.5,
            ["x"] = -1042.4,
        },
        ["ExtraLineText"] = "GET_INSIDE_AND_USE_PORTAL_TOP",
    },
    { -- Step 359
        ["ZoneDoneSave"] = 1,
    },
}
