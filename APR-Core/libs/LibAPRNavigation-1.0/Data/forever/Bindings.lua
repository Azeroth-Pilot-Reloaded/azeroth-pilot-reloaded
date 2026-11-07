-- Declarative travel data. Names are resolved through the game client.
-- Sources and coverage limits: ../Bindings.md. Multiple candidates retain explicit areaID.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "bindings", {
    bindings = {
        -- Innkeeper positions and initial character binds.
        [9] = { space = "map", uiMapID = 1429, x = 0.4806, y = 0.4365, areaID = 9 }, -- Northshire Valley (Elwynn Forest); initial bind
        [35] = { space = "map", uiMapID = 1434, x = 0.2704, y = 0.7731, areaID = 35 }, -- Booty Bay (Stranglethorn Vale); NPC 6807
        [42] = { space = "map", uiMapID = 1431, x = 0.7387, y = 0.4441, areaID = 42 }, -- Darkshire (Duskwood); NPC 6790
        [69] = { space = "map", uiMapID = 1433, x = 0.2192, y = 0.4482, areaID = 69 }, -- Lakeshire (Redridge Mountains); NPC 6727
        [75] = { space = "map", uiMapID = 1435, x = 0.4516, y = 0.5666, areaID = 75 }, -- Stonard (Swamp of Sorrows); NPC 6930
        [87] = { space = "map", uiMapID = 1429, x = 0.4377, y = 0.658, areaID = 87 }, -- Goldshire (Elwynn Forest); NPC 295
        [108] = { space = "map", uiMapID = 1436, x = 0.5286, y = 0.5371, areaID = 108 }, -- Sentinel Hill (Westfall); NPC 8931
        [117] = { space = "map", uiMapID = 1434, x = 0.3149, y = 0.2975, areaID = 117 }, -- Grom'gol Base Camp (Stranglethorn Vale); NPC 5814
        [132] = { space = "map", uiMapID = 1426, x = 0.2987, y = 0.7198, areaID = 132 }, -- Coldridge Valley (Dun Morogh); initial bind
        [186] = { space = "map", uiMapID = 1438, x = 0.5562, y = 0.5979, areaID = 186 }, -- Dolanaar (Teldrassil); NPC 6736
        [188] = { space = "map", uiMapID = 1438, x = 0.5859, y = 0.4479, areaID = 188 }, -- Shadowglen (Teldrassil); initial bind
        [221] = { space = "map", uiMapID = 1412, x = 0.4488, y = 0.7722, areaID = 221 }, -- Camp Narache (Mulgore); initial bind
        [222] = { space = "map", uiMapID = 1412, x = 0.4593, y = 0.6416, areaID = 222 }, -- Bloodhoof Village (Mulgore); NPC 6747
        [228] = { space = "map", uiMapID = 1421, x = 0.4318, y = 0.4128, areaID = 228 }, -- The Sepulcher (Silverpine Forest); NPC 6739
        [271] = { space = "map", uiMapID = 1424, x = 0.5117, y = 0.5893, areaID = 271 }, -- Southshore (Hillsbrad Foothills); NPC 2352
        [272] = { space = "map", uiMapID = 1424, x = 0.6278, y = 0.1903, areaID = 272 }, -- Tarren Mill (Hillsbrad Foothills); NPC 2388
        [321] = { space = "map", uiMapID = 1417, x = 0.7384, y = 0.3246, areaID = 321 }, -- Hammerfall (Arathi Highlands); NPC 9501
        [340] = { space = "map", uiMapID = 1418, x = 0.0282, y = 0.4586, areaID = 340 }, -- Kargath (Badlands); NPC 9356
        [349] = { space = "map", uiMapID = 1425, x = 0.1415, y = 0.4157, areaID = 349 }, -- Wildhammer Keep (The Hinterlands); NPC 7744
        [362] = { space = "map", uiMapID = 1411, x = 0.5151, y = 0.4164, areaID = 362 }, -- Razor Hill (Durotar); NPC 6928
        [363] = { space = "map", uiMapID = 1411, x = 0.4329, y = 0.6885, areaID = 363 }, -- Valley of Trials (Durotar); initial bind
        [378] = { space = "map", uiMapID = 1413, x = 0.4558, y = 0.5904, areaID = 378 }, -- Camp Taurajo (The Barrens); NPC 7714
        [380] = { space = "map", uiMapID = 1413, x = 0.5199, y = 0.2989, areaID = 380 }, -- The Crossroads (The Barrens); NPC 3934
        [392] = { space = "map", uiMapID = 1413, x = 0.6205, y = 0.3941, areaID = 392 }, -- Ratchet (The Barrens); NPC 6791
        [415] = { space = "map", uiMapID = 1440, x = 0.3699, y = 0.4922, areaID = 415 }, -- Astranaar (Ashenvale); NPC 6738
        [431] = { space = "map", uiMapID = 1440, x = 0.7399, y = 0.6065, areaID = 431 }, -- Splintertree Post (Ashenvale); NPC 12196
        [442] = { space = "map", uiMapID = 1439, x = 0.3704, y = 0.4413, areaID = 442 }, -- Auberdine (Darkshore); NPC 6737
        [460] = { space = "map", uiMapID = 1442, x = 0.4747, y = 0.6213, areaID = 460 }, -- Sun Rock Retreat (Stonetalon Mountains); NPC 7731
        [467] = { space = "map", uiMapID = 1442, x = 0.3579, y = 0.0574, areaID = 467 }, -- Stonetalon Peak (Stonetalon Mountains); NPC 16458
        [484] = { space = "map", uiMapID = 1441, x = 0.4607, y = 0.5152, areaID = 484 }, -- Freewind Post (Thousand Needles); NPC 11116
        [513] = { space = "map", uiMapID = 1445, x = 0.6659, y = 0.4522, areaID = 513 }, -- Theramore Isle (Dustwallow Marsh); NPC 6272
        [608] = { space = "map", uiMapID = 1443, x = 0.6627, y = 0.0655, areaID = 608 }, -- Nijel's Point (Desolace); NPC 11103
        [976] = { space = "map", uiMapID = 1446, x = 0.5251, y = 0.2791, areaID = 976 }, -- Gadgetzan (Tanaris); NPC 7733
        [1099] = { space = "map", uiMapID = 1444, x = 0.748, y = 0.4518, areaID = 1099 }, -- Camp Mojache (Feralas); NPC 7737
        [1116] = { space = "map", uiMapID = 1444, x = 0.3097, y = 0.4349, areaID = 1116 }, -- Feathermoon Stronghold (Feralas); NPC 7736
        [1497] = { space = "map", uiMapID = 1458, x = 0.6774, y = 0.3789, areaID = 1497 }, -- Undercity (Undercity); NPC 6741
        [1519] = { space = "world", instanceID = 0, uiMapID = 1453, x = -8867.76, y = 673.58, areaID = 1519 }, -- Stormwind City (Stormwind City); NPC 6740
        [1537] = { space = "map", uiMapID = 1455, x = 0.1815, y = 0.5145, areaID = 1537 }, -- Ironforge (Ironforge); NPC 5111
        [1637] = { space = "map", uiMapID = 1454, x = 0.541, y = 0.6841, areaID = 1637 }, -- Orgrimmar (Orgrimmar); NPC 6929
        [1638] = { space = "map", uiMapID = 1456, x = 0.4581, y = 0.6471, areaID = 1638 }, -- Thunder Bluff (Thunder Bluff); NPC 6746
        [1659] = { space = "map", uiMapID = 1457, x = 0.6742, y = 0.1565, areaID = 1659 }, -- Craftsmen's Terrace (Darnassus); NPC 6735
        [2101] = { space = "map", uiMapID = 1432, x = 0.3553, y = 0.484, areaID = 2101 }, -- Stoutlager Inn (Loch Modan); NPC 6734
        [2102] = { space = "map", uiMapID = 1426, x = 0.4738, y = 0.5252, areaID = 2102 }, -- Thunderbrew Distillery (Dun Morogh); NPC 1247
        [2104] = { space = "map", uiMapID = 1437, x = 0.107, y = 0.6095, areaID = 2104 }, -- Deepwater Tavern (Wetlands); NPC 1464
        [2117] = { space = "map", uiMapID = 1420, x = 0.3001, y = 0.7174, areaID = 2117 }, -- Shadow Grave (Tirisfal Glades); initial bind
        [2119] = { space = "map", uiMapID = 1420, x = 0.6172, y = 0.5205, areaID = 2119 }, -- Gallows' End Tavern (Tirisfal Glades); NPC 5688
        [2255] = { space = "map", uiMapID = 1452, x = 0.6136, y = 0.3883, areaID = 2255 }, -- Everlook (Winterspring); NPC 11118
        [2268] = { space = "map", uiMapID = 1423, x = 0.718, y = 0.4852, areaID = 2268 }, -- Light's Hope Chapel (Eastern Plaguelands); NPC 16256
        [2408] = { space = "map", uiMapID = 1443, x = 0.2409, y = 0.6821, areaID = 2408 }, -- Shadowprey Village (Desolace); NPC 11106
        [3317] = { space = "map", uiMapID = 1425, x = 0.7814, y = 0.8138, areaID = 3317 }, -- Revantusk Village (The Hinterlands); NPC 14731
        [3425] = { space = "map", uiMapID = 1451, x = 0.5189, y = 0.3916, areaID = 3425 }, -- Cenarion Hold (Silithus); NPC 15174
        [16509] = { space = "world", instanceID = 0, uiMapID = 1453, x = -8867.76, y = 673.58, areaID = 16509 }, -- Stormwind City (Stormwind City); NPC 6740
        [16624] = { space = "map", uiMapID = 2521, x = 0.4302, y = 0.4324, areaID = 16624 }, -- Shen'dar Village (The Skylands); NPC 254089
        [16638] = { space = "map", uiMapID = 2521, x = 0.6218, y = 0.72616, areaID = 16638 }, -- Valanaar (The Skylands); NPC 255940

        -- Legacy area representatives; retained where no verified inn replaces them.
        [24] = {
            space = "world",
            instanceID = 0,
            x = -8888.98046875,
            y = -0.54000002146,
            z = 94.38999938965,
            areaID = 24,
        },
        [139] = {
            space = "world",
            instanceID = 0,
            x = 2253.3999023438,
            y = -5344.8999023438,
            z = 83.37999725342,
            areaID = 139,
        },
        [144] = { space = "world", instanceID = 0, x = -5421.91015625, y = -2930.0100097656, z = 347.25, areaID = 144 },
        [150] = {
            space = "world",
            instanceID = 0,
            x = -3792.2600097656,
            y = -783.28997802734,
            z = 9.06000041962,
            areaID = 150,
        },
        [251] = {
            space = "world",
            instanceID = 0,
            x = -7504.0297851562,
            y = -2187.5400390625,
            z = 165.5299987793,
            areaID = 251,
        },
        [320] = {
            space = "world",
            instanceID = 0,
            x = -1240.5300292969,
            y = -2515.1101074219,
            z = 22.15999984741,
            areaID = 320,
        },
        [348] = {
            space = "world",
            instanceID = 0,
            x = 283.73999023438,
            y = -2002.7600097656,
            z = 194.74000549316,
            areaID = 348,
        },
        [489] = {
            space = "world",
            instanceID = 1,
            x = -4491.8798828125,
            y = -775.89001464844,
            z = -39.52000045776,
            areaID = 489,
        },
        [493] = {
            space = "world",
            instanceID = 1,
            x = 7458.4501953125,
            y = -2487.2099609375,
            z = 462.32998657227,
            areaID = 493,
        },
        [496] = {
            space = "world",
            instanceID = 1,
            x = -3147.3898925781,
            y = -2842.1799316406,
            z = 34.61000061035,
            areaID = 496,
        },
        [541] = {
            space = "world",
            instanceID = 1,
            x = -6113.8198242188,
            y = -1142.6999511719,
            z = -187.63000488281,
            areaID = 541,
        },
        [702] = {
            space = "world",
            instanceID = 1,
            x = 8643.58984375,
            y = 841.04998779297,
            z = 23.29999923706,
            areaID = 702,
        },
        [1237] = {
            space = "world",
            instanceID = 1,
            x = 3661.5200195312,
            y = -4390.3798828125,
            z = 113.05000305176,
            areaID = 1237,
        },
        [1438] = {
            space = "world",
            instanceID = 0,
            x = -11112.25,
            y = -3435.7399902344,
            z = 79.08999633789,
            areaID = 1438,
        },
        [1446] = {
            space = "world",
            instanceID = 0,
            x = -6552.58984375,
            y = -1168.2700195312,
            z = 309.30999755859,
            areaID = 1446,
        },
        [2263] = {
            space = "world",
            instanceID = 0,
            x = 1857.5600585938,
            y = -3658.4699707031,
            z = 143.72999572754,
            areaID = 2263,
        },
        [2271] = { space = "world", instanceID = 0, x = 2499.2299804688, y = -4742.8500976562, z = 93.5, areaID = 2271 },
        [2275] = {
            space = "world",
            instanceID = 0,
            x = 3109.3100585938,
            y = -4285.1298828125,
            z = 109.44999694824,
            areaID = 2275,
        },
        [2361] = {
            space = "world",
            instanceID = 1,
            x = 7793.6098632812,
            y = -2403.4699707031,
            z = 489.32000732422,
            areaID = 2361,
        },
        [2418] = {
            space = "world",
            instanceID = 0,
            x = -8364.6103515625,
            y = -2738.3500976562,
            z = 185.46000671387,
            areaID = 2418,
        },
        [2897] = {
            space = "world",
            instanceID = 1,
            x = 3374.7099609375,
            y = 996.96997070313,
            z = 5.19000005722,
            areaID = 2897,
        },
        [2959] = {
            space = "world",
            instanceID = 30,
            x = 574.21002197266,
            y = -46.65000152588,
            z = 37.61000061035,
            areaID = 2959,
        },
        [2978] = {
            space = "world",
            instanceID = 30,
            x = -1335.4399414062,
            y = -319.69000244141,
            z = 90.66000366211,
            areaID = 2978,
        },
        [3137] = {
            space = "world",
            instanceID = 1,
            x = 2721.9899902344,
            y = -3880.6398925781,
            z = 100.87000274658,
            areaID = 3137,
        },
        [3197] = {
            space = "world",
            instanceID = 0,
            x = 931.32000732422,
            y = -1430.1099853516,
            z = 64.66999816895,
            areaID = 3197,
        },
        [16724] = { space = "map", uiMapID = 2548, x = 0.6459, y = 0.8418, areaID = 16724 },
        [16727] = { space = "map", uiMapID = 2548, x = 0.788, y = 0.54, areaID = 16727 },
        [16743] = { space = "map", uiMapID = 2548, x = 0.58, y = 0.45, areaID = 16743 },
        [16635] = { space = "map", uiMapID = 2521, x = 0.4282, y = 0.2314, areaID = 16635 },
    },
}, 33)
