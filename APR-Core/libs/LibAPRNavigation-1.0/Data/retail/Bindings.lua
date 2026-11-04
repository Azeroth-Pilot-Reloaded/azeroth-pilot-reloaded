-- Declarative travel data. Names are resolved through the game client.
-- Sources and coverage limits: ../Bindings.md. Multiple candidates retain explicit areaID.
LibStub("LibAPRNavigation-1.0"):RegisterData("retail", "bindings", {
    bindings = {
        -- Innkeeper positions and initial character binds.
        [12] = { space = "map", uiMapID = 37, x = 0.742, y = 0.924, areaID = 12 },                         -- Elwynn Forest (Elwynn Forest); NPC 60566
        [35] = { space = "map", uiMapID = 210, x = 0.408, y = 0.738, areaID = 35 },                        -- Booty Bay (The Cape of Stranglethorn); NPC 6807
        [42] = { space = "map", uiMapID = 47, x = 0.739, y = 0.444, areaID = 42 },                         -- Darkshire (Duskwood); NPC 6790
        [69] = { space = "map", uiMapID = 49, x = 0.264, y = 0.414, areaID = 69 },                         -- Lakeshire (Redridge Mountains); NPC 6727
        [75] = { space = "map", uiMapID = 51, x = 0.468, y = 0.568, areaID = 75 },                         -- Stonard (Swamp of Sorrows); NPC 6930
        [108] = { space = "map", uiMapID = 52, x = 0.528, y = 0.536, areaID = 108 },                       -- Sentinel Hill (Westfall); NPC 8931
        [117] = { space = "map", uiMapID = 50, x = 0.372, y = 0.518, areaID = 117 },                       -- Grom'gol Base Camp (Northern Stranglethorn); NPC 5814
        [147] = { space = "map", uiMapID = 48, x = 0.819, y = 0.645, areaID = 147 },                       -- The Farstrider Lodge (Loch Modan); NPC 1156
        [152] = { space = "map", uiMapID = 18, x = 0.83, y = 0.718, areaID = 152 },                        -- The Bulwark (Tirisfal Glades); NPC 46271
        [159] = { space = "map", uiMapID = 18, x = 0.608, y = 0.516, areaID = 159 },                       -- Brill (Tirisfal Glades); NPC 5688
        [186] = { space = "map", uiMapID = 57, x = 0.554, y = 0.522, areaID = 186 },                       -- Dolanaar (Teldrassil); NPC 6736
        [188] = { space = "map", uiMapID = 460, x = 0.455, y = 0.747, areaID = 188 },                      -- Shadowglen (Shadowglen); NPC 2079
        [193] = { space = "map", uiMapID = 22, x = 0.482, y = 0.638, areaID = 193 },                       -- Andorhal (Western Plaguelands); NPC 47857
        [222] = { space = "map", uiMapID = 7, x = 0.468, y = 0.604, areaID = 222 },                        -- Bloodhoof Village (Mulgore); NPC 6747
        [228] = { space = "map", uiMapID = 21, x = 0.464, y = 0.426, areaID = 228 },                       -- The Sepulcher (Silverpine Forest); NPC 6739
        [272] = { space = "map", uiMapID = 25, x = 0.578, y = 0.472, areaID = 272 },                       -- Tarren Mill (Hillsbrad Foothills); NPC 2388
        [286] = { space = "map", uiMapID = 25, x = 0.358, y = 0.612, areaID = 286 },                       -- The Sludge Fields (Hillsbrad Foothills); NPC 49394
        [320] = { space = "map", uiMapID = 14, x = 0.399, y = 0.49, areaID = 320 },                        -- Refuge Pointe (Arathi Highlands); NPC 2808
        [321] = { space = "map", uiMapID = 14, x = 0.69, y = 0.332, areaID = 321 },                        -- Hammerfall (Arathi Highlands); NPC 7731
        [348] = { space = "map", uiMapID = 26, x = 0.14, y = 0.448, areaID = 348 },                        -- Aerie Peak (The Hinterlands); NPC 7744
        [362] = { space = "map", uiMapID = 1, x = 0.516, y = 0.416, areaID = 362 },                        -- Razor Hill (Durotar); NPC 6928
        [363] = { space = "map", uiMapID = 461, x = 0.452, y = 0.687, areaID = 363 },                      -- Valley of Trials (Valley of Trials); NPC 10176
        [380] = { space = "map", uiMapID = 10, x = 0.496, y = 0.58, areaID = 380 },                        -- The Crossroads (Northern Barrens); NPC 3934
        [392] = { space = "map", uiMapID = 10, x = 0.672, y = 0.746, areaID = 392 },                       -- Ratchet (Northern Barrens); NPC 6791
        [415] = { space = "map", uiMapID = 63, x = 0.37, y = 0.492, areaID = 415 },                        -- Astranaar (Ashenvale); NPC 6738
        [420] = { space = "map", uiMapID = 63, x = 0.504, y = 0.67, areaID = 420 },                        -- Silverwind Refuge (Ashenvale); NPC 43633
        [431] = { space = "map", uiMapID = 63, x = 0.74, y = 0.606, areaID = 431 },                        -- Splintertree Post (Ashenvale); NPC 12196
        [460] = { space = "map", uiMapID = 65, x = 0.504, y = 0.638, areaID = 460 },                       -- Sun Rock Retreat (Stonetalon Mountains); NPC 7731
        [496] = { space = "map", uiMapID = 70, x = 0.368, y = 0.322, areaID = 496 },                       -- Brackenwall Village (Dustwallow Marsh); NPC 24208
        [513] = { space = "map", uiMapID = 70, x = 0.666, y = 0.452, areaID = 513 },                       -- Theramore Isle (Dustwallow Marsh); NPC 6272
        [608] = { space = "map", uiMapID = 66, x = 0.662, y = 0.066, areaID = 608 },                       -- Nijel's Point (Desolace); NPC 11103
        [657] = { space = "map", uiMapID = 51, x = 0.29, y = 0.325, areaID = 657 },                        -- The Harborage (Swamp of Sorrows); NPC 47367
        [1099] = { space = "map", uiMapID = 69, x = 0.748, y = 0.452, areaID = 1099 },                     -- Camp Mojache (Feralas); NPC 7737
        [1437] = { space = "map", uiMapID = 17, x = 0.404, y = 0.114, areaID = 1437 },                     -- Dreadmaul Hold (Blasted Lands); NPC 44309
        [1438] = { space = "map", uiMapID = 17, x = 0.607, y = 0.14, areaID = 1438 },                      -- Nethergarde Keep (Blasted Lands); NPC 44325
        [1637] = { space = "map", uiMapID = 85, x = 0.536, y = 0.788, areaID = 1637 },                     -- Orgrimmar (Orgrimmar); NPC 6929
        [1659] = { space = "map", uiMapID = 89, x = 0.624, y = 0.328, areaID = 1659 },                     -- Craftsmen's Terrace (Darnassus); NPC 6735
        [1704] = { space = "map", uiMapID = 10, x = 0.562, y = 0.4, areaID = 1704 },                       -- Grol'dom Farm (Northern Barrens); NPC 43946
        [1739] = { space = "map", uiMapID = 210, x = 0.3508, y = 0.272, areaID = 1739 },                   -- Hardwrench Hideaway (The Cape of Stranglethorn); NPC 44190
        [1885] = { space = "map", uiMapID = 26, x = 0.318, y = 0.58, areaID = 1885 },                      -- Hiri'watha Research Station (The Hinterlands); NPC 43739
        [1998] = { space = "map", uiMapID = 77, x = 0.618, y = 0.266, areaID = 1998 },                     -- Talonbranch Glade (Felwood); NPC 47931
        [2101] = { space = "map", uiMapID = 48, x = 0.355, y = 0.484, areaID = 2101 },                     -- Stoutlager Inn (Loch Modan); NPC 6734
        [2102] = { space = "map", uiMapID = 27, x = 0.545, y = 0.508, areaID = 2102 },                     -- Thunderbrew Distillery (Dun Morogh); NPC 1247
        [2104] = { space = "map", uiMapID = 56, x = 0.107, y = 0.608, areaID = 2104 },                     -- Deepwater Tavern (Wetlands); NPC 1464
        [2268] = { space = "map", uiMapID = 24, x = 0.4401, y = 0.8949, areaID = 2268 },                   -- Light's Hope Chapel (Eastern Plaguelands); NPC 16256
        [2408] = { space = "map", uiMapID = 66, x = 0.24, y = 0.682, areaID = 2408 },                      -- Shadowprey Village (Desolace); NPC 11106
        [2897] = { space = "map", uiMapID = 63, x = 0.128, y = 0.34, areaID = 2897 },                      -- Zoram'gar Outpost (Ashenvale); NPC 43606
        [3197] = { space = "map", uiMapID = 22, x = 0.434, y = 0.846, areaID = 3197 },                     -- Chillwind Camp (Western Plaguelands); NPC 46269
        [3317] = { space = "map", uiMapID = 26, x = 0.782, y = 0.812, areaID = 3317 },                     -- Revantusk Village (The Hinterlands); NPC 14731
        [3462] = { space = "map", uiMapID = 94, x = 0.4367, y = 0.7132, areaID = 3462 },                   -- Fairbreeze Village (Eversong Woods); NPC 15397
        [3488] = { space = "map", uiMapID = 95, x = 0.488, y = 0.324, areaID = 3488 },                     -- Tranquillien (Ghostlands); NPC 16542
        [3521] = { space = "map", uiMapID = 102, x = 0.672, y = 0.49, areaID = 3521 },                     -- Zangarmarsh (Zangarmarsh); NPC 18251
        [3526] = { space = "map", uiMapID = 468, x = 0.6139, y = 0.2948, areaID = 3526 },                  -- Ammen Vale (Ammen Vale); initial bind
        [3536] = { space = "map", uiMapID = 100, x = 0.566, y = 0.376, areaID = 3536 },                    -- Thrallmar (Hellfire Peninsula); NPC 16602
        [3538] = { space = "map", uiMapID = 100, x = 0.542, y = 0.635, areaID = 3538 },                    -- Honor Hold (Hellfire Peninsula); NPC 16826
        [3552] = { space = "map", uiMapID = 100, x = 0.234, y = 0.364, areaID = 3552 },                    -- Temple of Telhamat (Hellfire Peninsula); NPC 18906
        [3554] = { space = "map", uiMapID = 100, x = 0.268, y = 0.596, areaID = 3554 },                    -- Falcon Watch (Hellfire Peninsula); NPC 18905
        [3557] = { space = "map", uiMapID = 103, x = 0.5991, y = 0.1945, areaID = 3557 },                  -- The Exodar (The Exodar); NPC 16739
        [3576] = { space = "map", uiMapID = 97, x = 0.484, y = 0.492, areaID = 3576 },                     -- Azure Watch (Azuremyst Isle); NPC 16553
        [3584] = { space = "map", uiMapID = 106, x = 0.556, y = 0.596, areaID = 3584 },                    -- Blood Watch (Bloodmyst Isle); NPC 17553
        [3613] = { space = "map", uiMapID = 107, x = 0.566, y = 0.346, areaID = 3613 },                    -- Garadar (Nagrand); NPC 18913
        [3626] = { space = "map", uiMapID = 107, x = 0.5422, y = 0.7611, areaID = 3626 },                  -- Telaar (Nagrand); NPC 18914
        [3645] = { space = "map", uiMapID = 102, x = 0.3066, y = 0.5093, areaID = 3645 },                  -- Zabra'jin (Zangarmarsh); NPC 18245
        [3683] = { space = "map", uiMapID = 108, x = 0.488, y = 0.45, areaID = 3683 },                     -- Stonebreaker Hold (Terokkar Forest); NPC 18957
        [3684] = { space = "map", uiMapID = 108, x = 0.567, y = 0.533, areaID = 3684 },                    -- Allerian Stronghold (Terokkar Forest); NPC 19296
        [3703] = { space = "map", uiMapID = 111, x = 0.282, y = 0.484, areaID = 3703 },                    -- Shattrath City (Shattrath City); NPC 19046
        [3738] = { space = "map", uiMapID = 109, x = 0.434, y = 0.36, areaID = 3738 },                     -- The Stormspire (Netherstorm); NPC 19531
        [3744] = { space = "map", uiMapID = 104, x = 0.302, y = 0.278, areaID = 3744 },                    -- Shadowmoon Village (Shadowmoon Valley); NPC 19319
        [3745] = { space = "map", uiMapID = 104, x = 0.37, y = 0.582, areaID = 3745 },                     -- Wildhammer Stronghold (Shadowmoon Valley); NPC 19352
        [3754] = { space = "map", uiMapID = 104, x = 0.61, y = 0.282, areaID = 3754 },                     -- Altar of Sha'tar (Shadowmoon Valley); NPC 21746
        [3766] = { space = "map", uiMapID = 102, x = 0.419, y = 0.263, areaID = 3766 },                    -- Orebor Harborage (Zangarmarsh); NPC 18908
        [3769] = { space = "map", uiMapID = 105, x = 0.532, y = 0.554, areaID = 3769 },                    -- Thunderlord Stronghold (Blade's Edge Mountains); NPC 19470
        [3772] = { space = "map", uiMapID = 105, x = 0.358, y = 0.639, areaID = 3772 },                    -- Sylvanaar (Blade's Edge Mountains); NPC 19495
        [3844] = { space = "map", uiMapID = 105, x = 0.76, y = 0.602, areaID = 3844 },                     -- Mok'Nathal Village (Blade's Edge Mountains); NPC 21088
        [3898] = { space = "map", uiMapID = 111, x = 0.562, y = 0.816, areaID = 3898 },                    -- Scryer's Tier (Shattrath City); NPC 19232
        [3918] = { space = "map", uiMapID = 105, x = 0.61, y = 0.681, areaID = 3918 },                     -- Toshley's Station (Blade's Edge Mountains); NPC 21110
        [3938] = { space = "map", uiMapID = 104, x = 0.562, y = 0.598, areaID = 3938 },                    -- Sanctum of the Stars (Shadowmoon Valley); NPC 21744
        [3951] = { space = "map", uiMapID = 105, x = 0.628, y = 0.382, areaID = 3951 },                    -- Evergrove (Blade's Edge Mountains); NPC 22922
        [3981] = { space = "map", uiMapID = 117, x = 0.584, y = 0.626, areaID = 3981 },                    -- Valgarde (Howling Fjord); NPC 23731
        [3988] = { space = "map", uiMapID = 117, x = 0.254, y = 0.598, areaID = 3988 },                    -- Kamagua (Howling Fjord); NPC 27148
        [3991] = { space = "map", uiMapID = 117, x = 0.522, y = 0.664, areaID = 3991 },                    -- New Agamand (Howling Fjord); NPC 24149
        [4000] = { space = "map", uiMapID = 117, x = 0.797, y = 0.308, areaID = 4000 },                    -- Vengeance Landing (Howling Fjord); NPC 24342
        [4003] = { space = "map", uiMapID = 117, x = 0.604, y = 0.158, areaID = 4003 },                    -- Fort Wildervar (Howling Fjord); NPC 24057
        [4010] = { space = "map", uiMapID = 70, x = 0.418, y = 0.74, areaID = 4010 },                      -- Mudsprocket (Dustwallow Marsh); NPC 23995
        [4018] = { space = "map", uiMapID = 117, x = 0.494, y = 0.108, areaID = 4018 },                    -- Camp Winterhoof (Howling Fjord); NPC 24033
        [4037] = { space = "map", uiMapID = 114, x = 0.762, y = 0.372, areaID = 4037 },                    -- Taunka'le Village (Borean Tundra); NPC 26709
        [4087] = { space = "map", uiMapID = 122, x = 0.512, y = 0.334, areaID = 4087 },                    -- Sun's Reach Harbor (Isle of Quel'Danas); NPC 25036
        [4108] = { space = "map", uiMapID = 114, x = 0.5712, y = 0.1871, areaID = 4108 },                  -- Fizzcrank Airstrip (Borean Tundra); NPC 26596
        [4113] = { space = "map", uiMapID = 114, x = 0.7839, y = 0.4928, areaID = 4113 },                  -- Unu'pe (Borean Tundra); NPC 27187
        [4129] = { space = "map", uiMapID = 114, x = 0.418, y = 0.546, areaID = 4129 },                    -- Warsong Hold (Borean Tundra); NPC 25278
        [4152] = { space = "map", uiMapID = 115, x = 0.4814, y = 0.7476, areaID = 4152 },                  -- Moa'ki Harbor (Dragonblight); NPC 27174
        [4158] = { space = "map", uiMapID = 115, x = 0.2889, y = 0.5609, areaID = 4158 },                  -- Stars' Rest (Dragonblight); NPC 27052
        [4159] = { space = "map", uiMapID = 116, x = 0.596, y = 0.264, areaID = 4159 },                    -- Westfall Brigade Encampment (Grizzly Hills); NPC 26375
        [4161] = { space = "map", uiMapID = 115, x = 0.598, y = 0.5424, areaID = 4161 },                   -- Wyrmrest Temple (Dragonblight); NPC 27950
        [4165] = { space = "map", uiMapID = 115, x = 0.382, y = 0.466, areaID = 4165 },                    -- Agmar's Hammer (Dragonblight); NPC 26985
        [4177] = { space = "map", uiMapID = 115, x = 0.774, y = 0.5184, areaID = 4177 },                   -- Wintergarde Keep (Dragonblight); NPC 27042
        [4186] = { space = "map", uiMapID = 115, x = 0.768, y = 0.63, areaID = 4186 },                     -- Venomspite (Dragonblight); NPC 27027
        [4204] = { space = "map", uiMapID = 116, x = 0.32, y = 0.602, areaID = 4204 },                     -- Amberpine Lodge (Grizzly Hills); NPC 27066
        [4206] = { space = "map", uiMapID = 116, x = 0.208, y = 0.646, areaID = 4206 },                    -- Conquest Hold (Grizzly Hills); NPC 27125
        [4211] = { space = "map", uiMapID = 116, x = 0.654, y = 0.47, areaID = 4211 },                     -- Camp Oneqwah (Grizzly Hills); NPC 26680
        [4275] = { space = "map", uiMapID = 121, x = 0.408, y = 0.662, areaID = 4275 },                    -- The Argent Stand (Zul'Drak); NPC 28791
        [4284] = { space = "map", uiMapID = 119, x = 0.2675, y = 0.5927, areaID = 4284 },                  -- Nesingwary Base Camp (Sholazar Basin); NPC 28038
        [4323] = { space = "map", uiMapID = 121, x = 0.592, y = 0.572, areaID = 4323 },                    -- Zim'Torga (Zul'Drak); NPC 29583
        [4380] = { space = "map", uiMapID = 117, x = 0.308, y = 0.414, areaID = 4380 },                    -- Westguard Inn (Howling Fjord); NPC 23937
        [4395] = { space = "map", uiMapID = 125, x = 0.51, y = 0.4, areaID = 4395 },                       -- Dalaran (Dalaran); NPC 28687
        [4418] = { space = "map", uiMapID = 120, x = 0.41, y = 0.858, areaID = 4418 },                     -- K3 (The Storm Peaks); NPC 29904
        [4422] = { space = "map", uiMapID = 120, x = 0.488, y = 0.65, areaID = 4422 },                     -- Brunnhildar Village (The Storm Peaks); NPC 30005
        [4428] = { space = "map", uiMapID = 120, x = 0.286, y = 0.744, areaID = 4428 },                    -- Frosthold (The Storm Peaks); NPC 29926
        [4429] = { space = "map", uiMapID = 120, x = 0.37, y = 0.496, areaID = 4429 },                     -- Grom'arsh Crash-Site (The Storm Peaks); NPC 29944
        [4441] = { space = "map", uiMapID = 120, x = 0.676, y = 0.506, areaID = 4441 },                    -- Camp Tunka'lo (The Storm Peaks); NPC 29971
        [4477] = { space = "map", uiMapID = 118, x = 0.4399, y = 0.2218, areaID = 4477 },                  -- The Shadow Vault (Icecrown); NPC 30308
        [4484] = { space = "map", uiMapID = 120, x = 0.308, y = 0.372, areaID = 4484 },                    -- Bouldercrag's Refuge (The Storm Peaks); NPC 29963
        [4560] = { space = "map", uiMapID = 125, x = 0.37, y = 0.568, areaID = 4560 },                     -- The Underbelly (Dalaran); NPC 29532
        ["4616:125:31557"] = { space = "map", uiMapID = 125, x = 0.656, y = 0.326, areaID = 4616 },        -- Sunreaver's Sanctuary (Dalaran); NPC 31557
        ["4616:125:32418"] = { space = "map", uiMapID = 125, x = 0.69, y = 0.334, areaID = 4616 },         -- Sunreaver's Sanctuary (Dalaran); NPC 32418
        [4659] = { space = "map", uiMapID = 62, x = 0.5092, y = 0.1863, areaID = 4659 },                   -- Lor'danel (Darkshore); NPC 43420
        [4666] = { space = "map", uiMapID = 118, x = 0.761, y = 0.2396, areaID = 4666 },                   -- Sunreaver Pavilion (Icecrown); NPC 33971
        [4667] = { space = "map", uiMapID = 118, x = 0.7619, y = 0.1966, areaID = 4667 },                  -- Silver Covenant Pavilion (Icecrown); NPC 33970
        [4691] = { space = "map", uiMapID = 63, x = 0.386, y = 0.422, areaID = 4691 },                     -- Hellscream's Watch (Ashenvale); NPC 43624
        [4721] = { space = "map", uiMapID = 174, x = 0.28, y = 0.758, areaID = 4721 },                     -- Shipwreck Shore (The Lost Isles); NPC 36496
        [4731] = { space = "map", uiMapID = 179, x = 0.6006, y = 0.9167, areaID = 4731 },                  -- Stormglen Village (Gilneas); NPC 38792
        ["4739:125:28687"] = { space = "map", uiMapID = 125, x = 0.51, y = 0.4, areaID = 4739 },           -- Runeweaver Square (Dalaran); NPC 28687
        ["4739:125:32411"] = { space = "map", uiMapID = 125, x = 0.496, y = 0.406, areaID = 4739 },        -- Runeweaver Square (Dalaran); NPC 32411
        [4740] = { space = "map", uiMapID = 125, x = 0.446, y = 0.63, areaID = 4740 },                     -- The Silver Enclave (Dalaran); NPC 32413
        [4765] = { space = "map", uiMapID = 194, x = 0.568, y = 0.77, areaID = 4765 },                     -- KTC Headquarters (Kezan); NPC 34668
        [4786] = { space = "map", uiMapID = 179, x = 0.368, y = 0.656, areaID = 4786 },                    -- Duskhaven (Gilneas); NPC 38791
        [4805] = { space = "map", uiMapID = 66, x = 0.568, y = 0.5, areaID = 4805 },                       -- Karnum's Glade (Desolace); NPC 43872
        [4843] = { space = "map", uiMapID = 199, x = 0.39, y = 0.11, areaID = 4843 },                      -- Honor's Stand (Southern Barrens); NPC 44219
        [4844] = { space = "map", uiMapID = 199, x = 0.392, y = 0.2, areaID = 4844 },                      -- Hunter's Hill (Southern Barrens); NPC 44270
        [4847] = { space = "map", uiMapID = 199, x = 0.656, y = 0.466, areaID = 4847 },                    -- Northwatch Hold (Southern Barrens); NPC 44268
        [4853] = { space = "map", uiMapID = 199, x = 0.408, y = 0.692, areaID = 4853 },                    -- Desolation Hold (Southern Barrens); NPC 44276
        [4854] = { space = "map", uiMapID = 199, x = 0.49, y = 0.685, areaID = 4854 },                     -- Fort Triumph (Southern Barrens); NPC 44267
        [4871] = { space = "map", uiMapID = 174, x = 0.45, y = 0.654, areaID = 4871 },                     -- Town-In-A-Box (The Lost Isles); NPC 42473
        [4882] = { space = "map", uiMapID = 78, x = 0.552, y = 0.622, areaID = 4882 },                     -- Marshal's Stand (Un'Goro Crater); NPC 38488
        [4912] = { space = "map", uiMapID = 174, x = 0.368, y = 0.432, areaID = 4912 },                    -- Warchief's Lookout (The Lost Isles); NPC 42473
        [4933] = { space = "map", uiMapID = 65, x = 0.664, y = 0.642, areaID = 4933 },                     -- Krom'gar Fortress (Stonetalon Mountains); NPC 41892
        [4937] = { space = "map", uiMapID = 65, x = 0.394, y = 0.328, areaID = 4937 },                     -- Thal'darah Overlook (Stonetalon Mountains); NPC 41491
        [4939] = { space = "map", uiMapID = 65, x = 0.314, y = 0.606, areaID = 4939 },                     -- Farwatcher's Glen (Stonetalon Mountains); NPC 44177
        [4940] = { space = "map", uiMapID = 65, x = 0.711, y = 0.791, areaID = 4940 },                     -- Northwatch Expedition Base Camp (Stonetalon Mountains); NPC 41286
        [4969] = { space = "map", uiMapID = 205, x = 0.497, y = 0.574, areaID = 4969 },                    -- Tranquil Wash (Shimmering Expanse); NPC 42873
        [4970] = { space = "map", uiMapID = 205, x = 0.516, y = 0.626, areaID = 4970 },                    -- Legion's Rest (Shimmering Expanse); NPC 42908
        [4975] = { space = "map", uiMapID = 204, x = 0.512, y = 0.606, areaID = 4975 },                    -- Tenebrous Cavern (Abyssal Depths); NPC 43141
        [4976] = { space = "map", uiMapID = 204, x = 0.548, y = 0.721, areaID = 4976 },                    -- Darkbreak Cove (Abyssal Depths); NPC 42963
        [4982] = { space = "map", uiMapID = 1, x = 0.456, y = 0.131, areaID = 4982 },                      -- The Dranosh'ar Blockade (Durotar); NPC 60570
        [4989] = { space = "map", uiMapID = 198, x = 0.186, y = 0.372, areaID = 4989 },                    -- Grove of Aessina (Mount Hyjal); NPC 53779
        [4990] = { space = "map", uiMapID = 198, x = 0.426, y = 0.456, areaID = 4990 },                    -- Shrine of Aviana (Mount Hyjal); NPC 50068
        [5002] = { space = "map", uiMapID = 69, x = 0.414, y = 0.156, areaID = 5002 },                     -- Camp Ataya (Feralas); NPC 40467
        [5003] = { space = "map", uiMapID = 69, x = 0.518, y = 0.476, areaID = 5003 },                     -- Stonemaul Hold (Feralas); NPC 44376
        [5005] = { space = "map", uiMapID = 205, x = 0.492, y = 0.419, areaID = 5005 },                    -- Silver Tide Hollow (Shimmering Expanse); NPC 39878
        [5012] = { space = "map", uiMapID = 201, x = 0.452, y = 0.234, areaID = 5012 },                    -- The Briny Cutter (Kelp'thar Forest); NPC 40697
        [5024] = { space = "map", uiMapID = 69, x = 0.51, y = 0.178, areaID = 5024 },                      -- Dreamer's Rest (Feralas); NPC 40968
        [5049] = { space = "map", uiMapID = 64, x = 0.764, y = 0.746, areaID = 5049 },                     -- Speedbarge Bar (Thousand Needles); NPC 40832
        [5052] = { space = "map", uiMapID = 201, x = 0.396, y = 0.308, areaID = 5052 },                    -- Legion's Fate (Kelp'thar Forest); NPC 41794
        [5058] = { space = "map", uiMapID = 201, x = 0.638, y = 0.598, areaID = 5058 },                    -- Deepmist Grotto (Kelp'thar Forest); NPC 41341
        [5062] = { space = "map", uiMapID = 71, x = 0.556, y = 0.608, areaID = 5062 },                     -- Bootlegger Outpost (Tanaris); NPC 38714
        [5072] = { space = "map", uiMapID = 69, x = 0.46, y = 0.452, areaID = 5072 },                      -- Feathermoon Stronghold (Feralas); NPC 44391
        [5073] = { space = "map", uiMapID = 65, x = 0.59, y = 0.564, areaID = 5073 },                      -- Fallowmere Inn (Stonetalon Mountains); NPC 40898
        [5084] = { space = "map", uiMapID = 17, x = 0.444, y = 0.876, areaID = 5084 },                     -- Surwich (Blasted Lands); NPC 44334
        [5117] = { space = "map", uiMapID = 10, x = 0.624, y = 0.166, areaID = 5117 },                     -- Nozzlepot's Outpost (Northern Barrens); NPC 43945
        [5136] = { space = "map", uiMapID = 241, x = 0.758, y = 0.526, areaID = 5136 },                    -- Dragonmaw Port (Twilight Highlands); NPC 49498
        [5137] = { space = "map", uiMapID = 241, x = 0.754, y = 0.166, areaID = 5137 },                    -- The Krazzworks (Twilight Highlands); NPC 49783
        [5138] = { space = "map", uiMapID = 241, x = 0.532, y = 0.428, areaID = 5138 },                    -- Bloodgulch (Twilight Highlands); NPC 49762
        ["5140:241:49686"] = { space = "map", uiMapID = 241, x = 0.79, y = 0.776, areaID = 5140 },         -- Highbank (Twilight Highlands); NPC 49686
        ["5140:241:49688"] = { space = "map", uiMapID = 241, x = 0.794, y = 0.785, areaID = 5140 },        -- Highbank (Twilight Highlands); NPC 49688
        [5141] = { space = "map", uiMapID = 241, x = 0.604, y = 0.58, areaID = 5141 },                     -- Firebeard's Patrol (Twilight Highlands); NPC 49795
        [5142] = { space = "map", uiMapID = 241, x = 0.495, y = 0.304, areaID = 5142 },                    -- Thundermar (Twilight Highlands); NPC 49591
        [5143] = { space = "map", uiMapID = 241, x = 0.546, y = 0.18, areaID = 5143 },                     -- Kirthaven (Twilight Highlands); NPC 49574
        [5148] = { space = "map", uiMapID = 84, x = 0.608, y = 0.748, areaID = 5148 },                     -- Trade District (Stormwind City); NPC 6740
        [5150] = { space = "map", uiMapID = 84, x = 0.648, y = 0.323, areaID = 5150 },                     -- Dwarven District (Stormwind City); NPC 44235
        [5168] = { space = "map", uiMapID = 85, x = 0.706, y = 0.492, areaID = 5168 },                     -- Valley of Honor (Orgrimmar); NPC 46642
        [5169] = { space = "map", uiMapID = 85, x = 0.328, y = 0.656, areaID = 5169 },                     -- Valley of Spirits (Orgrimmar); NPC 45086
        [5170] = { space = "map", uiMapID = 85, x = 0.536, y = 0.788, areaID = 5170 },                     -- Valley of Strength (Orgrimmar); NPC 6929
        [5171] = { space = "map", uiMapID = 85, x = 0.392, y = 0.484, areaID = 5171 },                     -- Valley of Wisdom (Orgrimmar); NPC 44785
        [5303] = { space = "map", uiMapID = 207, x = 0.498, y = 0.52, areaID = 5303 },                     -- Temple of Earth (Deepholm); NPC 45300
        [5304] = { space = "map", uiMapID = 56, x = 0.256, y = 0.258, areaID = 5304 },                     -- Swiftgear Station (Wetlands); NPC 44006
        [5305] = { space = "map", uiMapID = 56, x = 0.582, y = 0.392, areaID = 5305 },                     -- Greenwarden's Grove (Wetlands); NPC 43993
        [5320] = { space = "map", uiMapID = 50, x = 0.532, y = 0.668, areaID = 5320 },                     -- Fort Livingston (Northern Stranglethorn); NPC 44019
        [5323] = { space = "map", uiMapID = 26, x = 0.662, y = 0.444, areaID = 5323 },                     -- Stormfeather Outpost (The Hinterlands); NPC 43699
        [5386] = { space = "map", uiMapID = 21, x = 0.444, y = 0.206, areaID = 5386 },                     -- Forsaken Rear Guard (Silverpine Forest); NPC 45496
        [5458] = { space = "map", uiMapID = 51, x = 0.717, y = 0.139, areaID = 5458 },                     -- Bogpaddle (Swamp of Sorrows); NPC 47334
        ["5466:249:48886"] = { space = "map", uiMapID = 249, x = 0.547, y = 0.329, areaID = 5466 },        -- Ramkahen (Uldum); NPC 48886
        ["5466:1527:162938"] = { space = "map", uiMapID = 1527, x = 0.5467, y = 0.3293, areaID = 5466 },   -- Ramkahen (Uldum New); NPC 162938
        [5470] = { space = "map", uiMapID = 241, x = 0.436, y = 0.573, areaID = 5470 },                    -- Victor's Point (Twilight Highlands); NPC 49599
        [5471] = { space = "map", uiMapID = 241, x = 0.452, y = 0.764, areaID = 5471 },                    -- Crushblow (Twilight Highlands); NPC 49747
        [5496] = { space = "map", uiMapID = 15, x = 0.658, y = 0.356, areaID = 5496 },                     -- Fuselight (Badlands); NPC 48054
        [5497] = { space = "map", uiMapID = 15, x = 0.9, y = 0.376, areaID = 5497 },                       -- Fuselight-By-The-Sea (Badlands); NPC 49934
        [5564] = { space = "map", uiMapID = 15, x = 0.207, y = 0.562, areaID = 5564 },                     -- Dragon's Mouth (Badlands); NPC 48093
        [5565] = { space = "map", uiMapID = 15, x = 0.182, y = 0.428, areaID = 5565 },                     -- New Kargath (Badlands); NPC 9356
        [5603] = { space = "map", uiMapID = 25, x = 0.596, y = 0.648, areaID = 5603 },                     -- Eastpoint Tower (Hillsbrad Foothills); NPC 49430
        [5628] = { space = "map", uiMapID = 32, x = 0.394, y = 0.662, areaID = 5628 },                     -- Iron Summit (Searing Gorge); NPC 47942
        [5637] = { space = "map", uiMapID = 37, x = 0.438, y = 0.658, areaID = 5637 },                     -- Lion's Pride Inn (Elwynn Forest); NPC 295
        [5645] = { space = "map", uiMapID = 77, x = 0.448, y = 0.29, areaID = 5645 },                      -- Whisperwind Grove (Felwood); NPC 48215
        [5649] = { space = "map", uiMapID = 77, x = 0.44, y = 0.618, areaID = 5649 },                      -- Wildheart Point (Felwood); NPC 48599
        ["5670:249:49406"] = { space = "map", uiMapID = 249, x = 0.266, y = 0.073, areaID = 5670 },        -- Oasis of Vir'sar (Uldum); NPC 49406
        ["5670:1527:163252"] = { space = "map", uiMapID = 1527, x = 0.2662, y = 0.0724, areaID = 5670 },   -- Oasis of Vir'sar (Uldum New); NPC 163252
        [5700] = { space = "map", uiMapID = 249, x = 0.22, y = 0.644, areaID = 5700 },                     -- Schnottz's Hostel (Uldum); NPC 49528
        [5728] = { space = "map", uiMapID = 94, x = 0.481, y = 0.477, areaID = 5728 },                     -- Falconwing Inn (Eversong Woods); NPC 15433
        [5730] = { space = "map", uiMapID = 198, x = 0.631, y = 0.241, areaID = 5730 },                    -- Nordrassil Inn (Mount Hyjal); NPC 40843
        [5930] = { space = "map", uiMapID = 371, x = 0.457, y = 0.439, areaID = 5930 },                    -- Dawn's Blossom (The Jade Forest); NPC 55233
        [5935] = { space = "map", uiMapID = 371, x = 0.596, y = 0.832, areaID = 5935 },                    -- Pearlfin Village (The Jade Forest); NPC 61599
        [5936] = { space = "map", uiMapID = 376, x = 0.837, y = 0.202, areaID = 5936 },                    -- Pang's Stead (Valley of the Four Winds); NPC 65528
        [5950] = { space = "map", uiMapID = 371, x = 0.28, y = 0.474, areaID = 5950 },                     -- Grookin Hill (The Jade Forest); NPC 62975
        [5974] = { space = "map", uiMapID = 371, x = 0.546, y = 0.632, areaID = 5974 },                    -- Jade Temple Grounds (The Jade Forest); NPC 57313
        [6007] = { space = "map", uiMapID = 418, x = 0.609, y = 0.249, areaID = 6007 },                    -- Thunder Cleft (Krasarang Wilds); NPC 58184
        [6009] = { space = "map", uiMapID = 418, x = 0.673, y = 0.33, areaID = 6009 },                     -- The Incursion (Krasarang Wilds); NPC 58926
        [6013] = { space = "map", uiMapID = 418, x = 0.283, y = 0.508, areaID = 6013 },                    -- Dawnchaser Retreat (Krasarang Wilds); NPC 62967
        [6016] = { space = "map", uiMapID = 418, x = 0.255, y = 0.332, areaID = 6016 },                    -- Sentinel Basecamp (Krasarang Wilds); NPC 58926
        [6039] = { space = "map", uiMapID = 376, x = 0.527, y = 0.479, areaID = 6039 },                    -- Sunsong Ranch (Valley of the Four Winds); NPC 70585
        [6049] = { space = "map", uiMapID = 418, x = 0.408, y = 0.345, areaID = 6049 },                    -- Crane Wing Refuge (Krasarang Wilds); NPC 62869
        [6071] = { space = "map", uiMapID = 371, x = 0.4571, y = 0.437, areaID = 6071 },                   -- The Drunken Hozen (The Jade Forest); NPC 55809
        [6077] = { space = "map", uiMapID = 371, x = 0.558, y = 0.244, areaID = 6077 },                    -- Sri-La Village (The Jade Forest); NPC 62868
        [6094] = { space = "map", uiMapID = 379, x = 0.628, y = 0.805, areaID = 6094 },                    -- Eastwind Rest (Kun-Lai Summit); NPC 62883
        [6095] = { space = "map", uiMapID = 379, x = 0.541, y = 0.829, areaID = 6095 },                    -- Westwind Rest (Kun-Lai Summit); NPC 62882
        [6128] = { space = "map", uiMapID = 379, x = 0.444, y = 0.903, areaID = 6128 },                    -- Shado-Pan Fallback (Kun-Lai Summit); NPC 62877
        [6157] = { space = "map", uiMapID = 379, x = 0.427, y = 0.7, areaID = 6157 },                      -- Kota Basecamp (Kun-Lai Summit); NPC 60420
        [6166] = { space = "map", uiMapID = 388, x = 0.711, y = 0.579, areaID = 6166 },                    -- Longying Outpost (Townlong Steppes); NPC 62873
        [6174] = { space = "map", uiMapID = 379, x = 0.669, y = 0.51, areaID = 6174 },                     -- Temple of the White Tiger (Kun-Lai Summit); NPC 61651
        [6187] = { space = "map", uiMapID = 388, x = 0.76, y = 0.829, areaID = 6187 },                     -- Gao-Ran Battlefront (Townlong Steppes); NPC 62875
        [6197] = { space = "map", uiMapID = 388, x = 0.489, y = 0.708, areaID = 6197 },                    -- Shado-Pan Garrison (Townlong Steppes); NPC 62874
        [6315] = { space = "map", uiMapID = 422, x = 0.559, y = 0.323, areaID = 6315 },                    -- Klaxxi'vess (Dread Wastes); NPC 65220
        [6333] = { space = "map", uiMapID = 371, x = 0.417, y = 0.232, areaID = 6333 },                    -- Paur's Pub (The Jade Forest); NPC 62867
        [6354] = { space = "map", uiMapID = 376, x = 0.551, y = 0.503, areaID = 6354 },                    -- The Lazy Turnip (Valley of the Four Winds); NPC 59582
        [6355] = { space = "map", uiMapID = 376, x = 0.837, y = 0.203, areaID = 6355 },                    -- Thunderfoot Inn (Valley of the Four Winds); NPC 65528
        [6356] = { space = "map", uiMapID = 376, x = 0.197, y = 0.559, areaID = 6356 },                    -- Stone Mug Tavern (Valley of the Four Winds); NPC 62878
        [6358] = { space = "map", uiMapID = 418, x = 0.758, y = 0.073, areaID = 6358 },                    -- Wilds' Edge Inn (Krasarang Wilds); NPC 62879
        [6359] = { space = "map", uiMapID = 379, x = 0.727, y = 0.923, areaID = 6359 },                    -- Binan Brew & Stew (Kun-Lai Summit); NPC 62871
        [6360] = { space = "map", uiMapID = 379, x = 0.574, y = 0.6, areaID = 6360 },                      -- The Lucky Traveller (Kun-Lai Summit); NPC 59688
        [6361] = { space = "map", uiMapID = 379, x = 0.642, y = 0.614, areaID = 6361 },                    -- The Two Fisted Brew (Kun-Lai Summit); NPC 59405
        [6362] = { space = "map", uiMapID = 379, x = 0.625, y = 0.288, areaID = 6362 },                    -- North Wind Tavern (Kun-Lai Summit); NPC 60605
        ["6363:390:58691"] = { space = "map", uiMapID = 390, x = 0.3534, y = 0.7764, areaID = 6363 },      -- The Golden Rose (Vale of Eternal Blossoms); NPC 58691
        ["6363:1530:58691"] = { space = "map", uiMapID = 1530, x = 0.3534, y = 0.7764, areaID = 6363 },    -- The Golden Rose (Vale of Eternal Blossoms New); NPC 58691
        [6364] = { space = "map", uiMapID = 433, x = 0.55, y = 0.724, areaID = 6364 },                     -- Tavern in the Mists (The Veiled Stair); NPC 62917
        [6365] = { space = "map", uiMapID = 422, x = 0.552, y = 0.711, areaID = 6365 },                    -- The Chum Bucket (Dread Wastes); NPC 63016
        [6369] = { space = "map", uiMapID = 418, x = 0.888, y = 0.353, areaID = 6369 },                    -- Krasarang Cove (Krasarang Wilds); NPC 69088
        ["6484:393:64149"] = { space = "map", uiMapID = 393, x = 0.3638, y = 0.667, areaID = 6484 },       -- The Golden Lantern (Shrine of Seven Stars); NPC 64149
        ["6484:1530:64149"] = { space = "map", uiMapID = 1530, x = 0.8744, y = 0.6695, areaID = 6484 },    -- The Golden Lantern (Vale of Eternal Blossoms New); NPC 64149
        [6516] = { space = "map", uiMapID = 371, x = 0.449, y = 0.844, areaID = 6516 },                    -- Paw'don Village (The Jade Forest); NPC 371
        ["6519:391:62996"] = { space = "map", uiMapID = 391, x = 0.6842, y = 0.4772, areaID = 6519 },      -- Summer's Rest (Shrine of Two Moons); NPC 62996
        ["6519:1530:62996"] = { space = "map", uiMapID = 1530, x = 0.6292, y = 0.1195, areaID = 6519 },    -- Summer's Rest (Vale of Eternal Blossoms New); NPC 62996
        [6521] = { space = "map", uiMapID = 371, x = 0.285, y = 0.133, areaID = 6521 },                    -- Honeydew Village (The Jade Forest); NPC 700
        [6556] = { space = "map", uiMapID = 114, x = 0.5829, y = 0.6805, areaID = 6556 },                  -- Valiant Rest (Borean Tundra); NPC 25245
        [6583] = { space = "map", uiMapID = 504, x = 0.649, y = 0.73, areaID = 6583 },                     -- Violet Rise (Isle of Thunder); NPC 70182
        [6612] = { space = "map", uiMapID = 418, x = 0.108, y = 0.523, areaID = 6612 },                    -- Horde Landing Site (Krasarang Wilds); NPC 61122
        [6680] = { space = "map", uiMapID = 504, x = 0.649, y = 0.73, areaID = 6680 },                     -- Battlefront Provisions (Isle of Thunder); NPC 70182
        [6777] = { space = "map", uiMapID = 525, x = 0.407, y = 0.517, areaID = 6777 },                    -- Stonefang Outpost (Frostfire Ridge); NPC 72382
        [6830] = { space = "map", uiMapID = 554, x = 0.366, y = 0.468, areaID = 6830 },                    -- The Celestial Court (Timeless Isle); NPC 73622
        [6864] = { space = "map", uiMapID = 526, x = 0.4297, y = 0.4464, areaID = 6864 },                  -- Bladespire Citadel (Frostfire Ridge); NPC 76746
        [6866] = { space = "map", uiMapID = 539, x = 0.413, y = 0.551, areaID = 6866 },                    -- Twilight Glade (Shadowmoon Valley D); NPC 71641
        [6881] = { space = "map", uiMapID = 543, x = 0.46, y = 0.697, areaID = 6881 },                     -- Beastwatch (Gorgrond); NPC 74594
        [6925] = { space = "map", uiMapID = 535, x = 0.772, y = 0.575, areaID = 6925 },                    -- Anchorite's Sojourn (Talador); NPC 75430
        [6944] = { space = "map", uiMapID = 539, x = 0.705, y = 0.508, areaID = 6944 },                    -- Tranquil Court (Shadowmoon Valley D); NPC 83825
        [7033] = { space = "map", uiMapID = 525, x = 0.522, y = 0.397, areaID = 7033 },                    -- Darkspear's Edge (Frostfire Ridge); NPC 78672
        [7059] = { space = "map", uiMapID = 550, x = 0.826, y = 0.454, areaID = 7059 },                    -- Wor'var (Nagrand D); NPC 82345
        [7061] = { space = "map", uiMapID = 550, x = 0.622, y = 0.4, areaID = 7061 },                      -- Yrel's Watch (Nagrand D); NPC 81249
        [7063] = { space = "map", uiMapID = 550, x = 0.485, y = 0.473, areaID = 7063 },                    -- Riverside Post (Nagrand D); NPC 82341
        [7081] = { space = "map", uiMapID = 550, x = 0.636, y = 0.625, areaID = 7081 },                    -- Telaari Station (Nagrand D); NPC 80006
        [7097] = { space = "map", uiMapID = 535, x = 0.697, y = 0.218, areaID = 7097 },                    -- Fort Wrynn (Talador); NPC 81358
        [7098] = { space = "map", uiMapID = 535, x = 0.72, y = 0.3, areaID = 7098 },                       -- Vol'jin's Pride (Talador); NPC 81359
        [7112] = { space = "map", uiMapID = 535, x = 0.618, y = 0.11, areaID = 7112 },                     -- Frostwolf Overlook (Talador); NPC 77028
        [7158] = { space = "map", uiMapID = 543, x = 0.532, y = 0.598, areaID = 7158 },                    -- Highpass (Gorgrond); NPC 85968
        [7183] = { space = "map", uiMapID = 543, x = 0.459, y = 0.547, areaID = 7183 },                    -- Breaker's Crown (Gorgrond); NPC 84237
        [7197] = { space = "map", uiMapID = 542, x = 0.404, y = 0.429, areaID = 7197 },                    -- Axefall (Spires of Arak); NPC 84213
        [7198] = { space = "map", uiMapID = 542, x = 0.401, y = 0.615, areaID = 7198 },                    -- Southport (Spires of Arak); NPC 84134
        [7269] = { space = "map", uiMapID = 535, x = 0.509, y = 0.445, areaID = 7269 },                    -- Spire of Light (Talador); NPC 86316
        [7318] = { space = "map", uiMapID = 525, x = 0.209, y = 0.565, areaID = 7318 },                    -- The Sheltered Den (Frostfire Ridge); NPC 77460
        [7332] = { space = "map", uiMapID = 622, x = 0.357, y = 0.779, areaID = 7332 },                    -- Stormshield (Stormshield); NPC 85956
        [7333] = { space = "map", uiMapID = 624, x = 0.45, y = 0.432, areaID = 7333 },                     -- Warspear (Warspear); NPC 86307
        [7355] = { space = "map", uiMapID = 630, x = 0.4733, y = 0.4135, areaID = 7355 },                  -- Crumbled Palace (Azsuna); NPC 109372
        [7364] = { space = "map", uiMapID = 630, x = 0.4311, y = 0.4262, areaID = 7364 },                  -- Illidari Stand (Azsuna); NPC 89639
        [7414] = { space = "map", uiMapID = 543, x = 0.401, y = 0.363, areaID = 7414 },                    -- Skysea Ridge (Gorgrond); NPC 85830
        [7425] = { space = "map", uiMapID = 539, x = 0.467, y = 0.409, areaID = 7425 },                    -- Lamplighter Inn (Shadowmoon Valley D); NPC 78952
        [7426] = { space = "map", uiMapID = 539, x = 0.569, y = 0.574, areaID = 7426 },                    -- The Crescent Hearth (Shadowmoon Valley D); NPC 82770
        [7427] = { space = "map", uiMapID = 539, x = 0.6, y = 0.274, areaID = 7427 },                      -- The Silken Pillow (Shadowmoon Valley D); NPC 82775
        ["7508:627:96789"] = { space = "map", uiMapID = 627, x = 0.3881, y = 0.7182, areaID = 7508 },      -- Greyfang Enclave (Dalaran L); NPC 96789
        ["7508:627:96790"] = { space = "map", uiMapID = 627, x = 0.4419, y = 0.6378, areaID = 7508 },      -- Greyfang Enclave (Dalaran L); NPC 96790
        ["7589:627:96796"] = { space = "map", uiMapID = 627, x = 0.6538, y = 0.3221, areaID = 7589 },      -- Windrunner's Sanctuary (Dalaran L); NPC 96796
        ["7589:627:96799"] = { space = "map", uiMapID = 627, x = 0.6709, y = 0.3545, areaID = 7589 },      -- Windrunner's Sanctuary (Dalaran L); NPC 96799
        [7599] = { space = "map", uiMapID = 630, x = 0.5664, y = 0.5956, areaID = 7599 },                  -- Shackle's Den (Azsuna); NPC 91457
        [7662] = { space = "map", uiMapID = 650, x = 0.5461, y = 0.8494, areaID = 7662 },                  -- Ironhorn Enclave (Highmountain); NPC 108554
        [7733] = { space = "map", uiMapID = 650, x = 0.3998, y = 0.5256, areaID = 7733 },                  -- Nesingwary's Retreat (Highmountain); NPC 94099
        [7783] = { space = "map", uiMapID = 659, x = 0.3451, y = 0.6503, areaID = 7783 },                  -- Stonedark Grotto (Highmountain); NPC 99207
        [7794] = { space = "map", uiMapID = 534, x = 0.615, y = 0.462, areaID = 7794 },                    -- Vol'mar Hold (Tanaan Jungle); NPC 90989
        [7795] = { space = "map", uiMapID = 534, x = 0.586, y = 0.603, areaID = 7795 },                    -- The Lion's Den (Tanaan Jungle); NPC 90971
        [7803] = { space = "map", uiMapID = 634, x = 0.6054, y = 0.5027, areaID = 7803 },                  -- Valdisdall (Stormheim); NPC 103796
        [7861] = { space = "map", uiMapID = 650, x = 0.5739, y = 0.2771, areaID = 7861 },                  -- Prepfoot Compound (Highmountain); NPC 108559
        [8029] = { space = "map", uiMapID = 641, x = 0.6957, y = 0.4943, areaID = 8029 },                  -- Starsong Refuge (Val'sharah); NPC 95118
        ["8140:627:96806"] = { space = "map", uiMapID = 627, x = 0.4979, y = 0.4017, areaID = 8140 },      -- The Legerdemain Lounge (Dalaran L); NPC 96806
        ["8140:627:96807"] = { space = "map", uiMapID = 627, x = 0.4852, y = 0.4179, areaID = 8140 },      -- The Legerdemain Lounge (Dalaran L); NPC 96807
        [8271] = { space = "map", uiMapID = 641, x = 0.5607, y = 0.7351, areaID = 8271 },                  -- The Traveler's Den (Val'sharah); NPC 93460
        [8272] = { space = "map", uiMapID = 641, x = 0.5824, y = 0.848, areaID = 8272 },                   -- Lightsong (Val'sharah); NPC 109304
        [8273] = { space = "map", uiMapID = 641, x = 0.4257, y = 0.596, areaID = 8273 },                   -- Thornton's Cottage (Val'sharah); NPC 92684
        [8300] = { space = "map", uiMapID = 634, x = 0.5401, y = 0.7229, areaID = 8300 },                  -- Theodric's Lodge (Stormheim); NPC 98106
        [8301] = { space = "map", uiMapID = 634, x = 0.7163, y = 0.6061, areaID = 8301 },                  -- Greywatch Barracks (Stormheim); NPC 98112
        [8430] = { space = "map", uiMapID = 650, x = 0.53, y = 0.4488, areaID = 8430 },                    -- Tradewind Roost (Highmountain); NPC 97786
        [8607] = { space = "map", uiMapID = 83, x = 0.598, y = 0.518, areaID = 8607 },                     -- The Laughing Yeti (Winterspring); NPC 11118
        [8610] = { space = "map", uiMapID = 71, x = 0.526, y = 0.27, areaID = 8610 },                      -- The Road Warrior (Tanaris); NPC 7733
        [8611] = { space = "map", uiMapID = 81, x = 0.554, y = 0.366, areaID = 8611 },                     -- The Oasis Inn (Silithus); NPC 15174
        [8612] = { space = "map", uiMapID = 102, x = 0.786, y = 0.63, areaID = 8612 },                     -- Firefly Tavern (Zangarmarsh); NPC 18907
        [8613] = { space = "map", uiMapID = 109, x = 0.32, y = 0.644, areaID = 8613 },                     -- Rusty Rocket Tavern (Netherstorm); NPC 19571
        [8622] = { space = "map", uiMapID = 87, x = 0.186, y = 0.516, areaID = 8622 },                     -- The Stonefire Tavern (Ironforge); NPC 5111
        [8689] = { space = "map", uiMapID = 863, x = 0.3863, y = 0.7866, areaID = 8689 },                  -- Zul'jan Ruins (Nazmir); NPC 121840
        [8711] = { space = "map", uiMapID = 863, x = 0.6776, y = 0.4185, areaID = 8711 },                  -- Gloom Hollow (Nazmir); NPC 131988
        [8854] = { space = "map", uiMapID = 864, x = 0.5678, y = 0.4981, areaID = 8854 },                  -- Vulpera Hideaway (Vol'dun); NPC 124108
        [8861] = { space = "map", uiMapID = 864, x = 0.5192, y = 0.8983, areaID = 8861 },                  -- Temple of Akunda (Vol'dun); NPC 128335
        [8869] = { space = "map", uiMapID = 864, x = 0.2687, y = 0.5222, areaID = 8869 },                  -- Sanctuary of the Devoted (Vol'dun); NPC 128693
        [8954] = { space = "map", uiMapID = 862, x = 0.7136, y = 0.29, areaID = 8954 },                    -- Scaletrader Post (Zuldazar); NPC 138488
        [8965] = { space = "map", uiMapID = 862, x = 0.4461, y = 0.7176, areaID = 8965 },                  -- Xibala (Zuldazar); NPC 124458
        [9011] = { space = "map", uiMapID = 895, x = 0.5331, y = 0.2829, areaID = 9011 },                  -- Norwington Estate (Tiragarde Sound); NPC 136459
        [9226] = { space = "map", uiMapID = 864, x = 0.4304, y = 0.7646, areaID = 9226 },                  -- Scorched Sands Outpost (Vol'dun); NPC 135655
        [9236] = { space = "map", uiMapID = 895, x = 0.7567, y = 0.6452, areaID = 9236 },                  -- Kennings Lodge (Tiragarde Sound); NPC 136437
        [9305] = { space = "map", uiMapID = 895, x = 0.8526, y = 0.8032, areaID = 9305 },                  -- Castaway Point (Tiragarde Sound); NPC 128233
        [9317] = { space = "map", uiMapID = 895, x = 0.7739, y = 0.8397, areaID = 9317 },                  -- Dead Man's Tale (Tiragarde Sound); NPC 136479
        [9335] = { space = "map", uiMapID = 895, x = 0.6627, y = 0.2429, areaID = 9335 },                  -- Hatherford (Tiragarde Sound); NPC 133214
        [9370] = { space = "map", uiMapID = 942, x = 0.3483, y = 0.4715, areaID = 9370 },                  -- Fort Daelin (Stormsong Valley); NPC 138210
        [9379] = { space = "map", uiMapID = 895, x = 0.5795, y = 0.6208, areaID = 9379 },                  -- Vigil Hill (Tiragarde Sound); NPC 136482
        [9384] = { space = "map", uiMapID = 895, x = 0.4206, y = 0.2285, areaID = 9384 },                  -- Roughneck Camp (Tiragarde Sound); NPC 129159
        [9402] = { space = "map", uiMapID = 942, x = 0.3151, y = 0.6726, areaID = 9402 },                  -- Millstone Hamlet (Stormsong Valley); NPC 143328
        [9419] = { space = "map", uiMapID = 862, x = 0.5129, y = 0.5118, areaID = 9419 },                  -- Village in the Vines (Zuldazar); NPC 137331
        [9502] = { space = "map", uiMapID = 680, x = 0.5955, y = 0.8529, areaID = 9502 },                  -- The Nighthold (Suramar); initial bind
        [9556] = { space = "map", uiMapID = 864, x = 0.615, y = 0.2054, areaID = 9556 },                   -- Tortaka Refuge (Vol'dun); NPC 138917
        [9569] = { space = "map", uiMapID = 863, x = 0.4087, y = 0.4354, areaID = 9569 },                  -- Wayshrine of the Fallen (Nazmir); NPC 128701
        [9579] = { space = "map", uiMapID = 942, x = 0.6547, y = 0.483, areaID = 9579 },                   -- Tidecross (Stormsong Valley); NPC 142634
        [9581] = { space = "map", uiMapID = 942, x = 0.4328, y = 0.5423, areaID = 9581 },                  -- Deadwash (Stormsong Valley); NPC 134969
        [9582] = { space = "map", uiMapID = 895, x = 0.3533, y = 0.2422, areaID = 9582 },                  -- Outrigger Post (Tiragarde Sound); NPC 136465
        [9592] = { space = "map", uiMapID = 863, x = 0.6195, y = 0.4079, areaID = 9592 },                  -- Fort Victory (Nazmir); NPC 135082
        [9598] = { space = "map", uiMapID = 1163, x = 0.4874, y = 0.7195, areaID = 9598 },                 -- The Great Seal (Dazar'alor); NPC 122690
        [9599] = { space = "map", uiMapID = 1165, x = 0.5242, y = 0.8494, areaID = 9599 },                 -- Spirits Be With You (Dazar'alor); NPC 120840
        [9636] = { space = "map", uiMapID = 896, x = 0.3743, y = 0.4856, areaID = 9636 },                  -- Northwood Home (Drustvar); NPC 136480
        [9647] = { space = "map", uiMapID = 896, x = 0.2667, y = 0.7255, areaID = 9647 },                  -- Falcon's Roost (Drustvar); NPC 136655
        [9665] = { space = "map", uiMapID = 1165, x = 0.3474, y = 0.1159, areaID = 9665 },                 -- Atal'Jani (Dazar'alor); NPC 126330
        [9693] = { space = "map", uiMapID = 942, x = 0.4084, y = 0.3709, areaID = 9693 },                  -- Seekers' Vista (Stormsong Valley); NPC 137668
        [9731] = { space = "map", uiMapID = 896, x = 0.555, y = 0.3426, areaID = 9731 },                   -- The Swine's Larder (Drustvar); NPC 129992
        [9766] = { space = "map", uiMapID = 942, x = 0.5858, y = 0.7031, areaID = 9766 },                  -- The Golden Flagon (Stormsong Valley); NPC 138221
        [9801] = { space = "map", uiMapID = 895, x = 0.7528, y = 0.2284, areaID = 9801 },                  -- Snug Harbor Inn (Tiragarde Sound); NPC 135153
        [9962] = { space = "map", uiMapID = 1165, x = 0.5264, y = 0.172, areaID = 9962 },                  -- Watertusk Inn (Dazar'alor); NPC 133030
        [10009] = { space = "map", uiMapID = 862, x = 0.6656, y = 0.4235, areaID = 10009 },                -- Beastcaller Inn (Zuldazar); NPC 123062
        [10012] = { space = "map", uiMapID = 1165, x = 0.4845, y = 0.8796, areaID = 10012 },               -- The Hozen Throne (Dazar'alor); NPC 129556
        [10333] = { space = "map", uiMapID = 1355, x = 0.5094, y = 0.6572, areaID = 10333 },               -- Newhome (Nazjatar); NPC 151618
        [10334] = { space = "map", uiMapID = 1355, x = 0.378, y = 0.5548, areaID = 10334 },                -- Mezzamere (Nazjatar); NPC 155940
        [10418] = { space = "map", uiMapID = 1462, x = 0.7128, y = 0.3575, areaID = 10418 },               -- Rustbolt (Mechagon Island); NPC 150628
        [10983] = { space = "map", uiMapID = 1525, x = 0.4733, y = 0.7065, areaID = 10983 },               -- Wanecrypt Hill (Revendreth); NPC 156220
        [10986] = { space = "map", uiMapID = 1699, x = 0.6602, y = 0.3359, areaID = 10986 },               -- Sinfall (Sinfall); NPC 166137
        [10988] = { space = "map", uiMapID = 1525, x = 0.3119, y = 0.4663, areaID = 10988 },               -- Sanctuary of the Mad (Revendreth); NPC 166089
        [11012] = { space = "map", uiMapID = 1707, x = 0.4825, y = 0.5916, areaID = 11012 },               -- Elysian Hold (Elysian Hold); NPC 174581
        [11465] = { space = "map", uiMapID = 1536, x = 0.5095, y = 0.5317, areaID = 11465 },               -- Theater of Pain (Maldraxxus); NPC 161702
        [11467] = { space = "map", uiMapID = 1536, x = 0.3962, y = 0.552, areaID = 11467 },                -- The Spearhead (Maldraxxus); NPC 168952
        [11473] = { space = "map", uiMapID = 1533, x = 0.481, y = 0.7297, areaID = 11473 },                -- Aspirant's Rest (Bastion); NPC 160601
        [11505] = { space = "map", uiMapID = 1533, x = 0.4292, y = 0.3273, areaID = 11505 },               -- Sagehaven (Bastion); NPC 172576
        [11515] = { space = "map", uiMapID = 1565, x = 0.6256, y = 0.3531, areaID = 11515 },               -- Tirna Vaal (Ardenweald); NPC 162446
        [11519] = { space = "map", uiMapID = 1565, x = 0.3673, y = 0.37, areaID = 11519 },                 -- Dreamsong Fenn (Ardenweald); NPC 171015
        [11531] = { space = "map", uiMapID = 1565, x = 0.6048, y = 0.5393, areaID = 11531 },               -- Hibernal Hollow (Ardenweald); NPC 162445
        [12245] = { space = "map", uiMapID = 1565, x = 0.5069, y = 0.338, areaID = 12245 },                -- Glitterfall Basin (Ardenweald); NPC 163738
        [12782] = { space = "map", uiMapID = 1525, x = 0.7232, y = 0.3985, areaID = 12782 },               -- Absolution Crypt (Revendreth); NPC 158986
        ["12858:1565:168032"] = { space = "map", uiMapID = 1565, x = 0.4838, y = 0.5046, areaID = 12858 }, -- Heart of the Forest (Ardenweald); NPC 168032
        ["12858:1701:160292"] = { space = "map", uiMapID = 1701, x = 0.548, y = 0.5621, areaID = 12858 },  -- Heart of the Forest (Heart of the Forest); NPC 160292
        [12876] = { space = "map", uiMapID = 1698, x = 0.4691, y = 0.2984, areaID = 12876 },               -- Seat of the Primus (Seat of the Primus); NPC 161994
        [13414] = { space = "map", uiMapID = 1525, x = 0.6206, y = 0.6448, areaID = 13414 },               -- The Sinposium (Revendreth); NPC 156290
        [13499] = { space = "map", uiMapID = 1670, x = 0.6748, y = 0.5033, areaID = 13499 },               -- Ring of Fates (Oribos); NPC 156688
        [13625] = { space = "map", uiMapID = 1961, x = 0.6073, y = 0.2415, areaID = 13625 },               -- Keeper's Respite (Korthia); NPC 177156
        [13632] = { space = "map", uiMapID = 1970, x = 0.348, y = 0.6396, areaID = 13632 },                -- Haven (Zereth Mortis); NPC 180916
        [13658] = { space = "map", uiMapID = 1970, x = 0.6149, y = 0.4918, areaID = 13658 },               -- Pilgrim's Grace (Zereth Mortis); NPC 181084
        ["13722:2022:187403"] = { space = "map", uiMapID = 2022, x = 0.804, y = 0.2782, areaID = 13722 },  -- Wild Coast (The Waking Shores); NPC 187403
        ["13722:2022:187412"] = { space = "map", uiMapID = 2022, x = 0.8131, y = 0.319, areaID = 13722 },  -- Wild Coast (The Waking Shores); NPC 187412
        [13724] = { space = "map", uiMapID = 2022, x = 0.7607, y = 0.5471, areaID = 13724 },               -- Skytop Observatory (The Waking Shores); NPC 194432
        ["13727:2022:189400"] = { space = "map", uiMapID = 2022, x = 0.6516, y = 0.5806, areaID = 13727 }, -- Ruby Lifeshrine (The Waking Shores); NPC 189400
        ["13727:2022:191025"] = { space = "map", uiMapID = 2022, x = 0.619, y = 0.7382, areaID = 13727 },  -- Ruby Lifeshrine (The Waking Shores); NPC 191025
        [13732] = { space = "map", uiMapID = 2022, x = 0.4773, y = 0.8324, areaID = 13732 },               -- Dragonscale Basecamp (The Waking Shores); NPC 187408
        [13736] = { space = "map", uiMapID = 2022, x = 0.2441, y = 0.8219, areaID = 13736 },               -- Apex Observatory (The Waking Shores); NPC 198190
        [13739] = { space = "map", uiMapID = 2022, x = 0.4312, y = 0.6656, areaID = 13739 },               -- Obsidian Bulwark (The Waking Shores); NPC 191025
        [13743] = { space = "map", uiMapID = 2023, x = 0.851, y = 0.2603, areaID = 13743 },                -- Timberstep Outpost (Ohn'ahran Plains); NPC 196259
        [13750] = { space = "map", uiMapID = 2023, x = 0.8587, y = 0.3525, areaID = 13750 },               -- Rusza'thar Reach (Ohn'ahran Plains); NPC 196161
        [13755] = { space = "map", uiMapID = 2023, x = 0.7215, y = 0.805, areaID = 13755 },                -- Forkriver Crossing (Ohn'ahran Plains); NPC 192878
        [13764] = { space = "map", uiMapID = 2023, x = 0.6281, y = 0.4065, areaID = 13764 },               -- Maruukai (Ohn'ahran Plains); NPC 191269
        [13767] = { space = "map", uiMapID = 2023, x = 0.6639, y = 0.2438, areaID = 13767 },               -- Emberwatch (Ohn'ahran Plains); NPC 190087
        [13772] = { space = "map", uiMapID = 2023, x = 0.4612, y = 0.4061, areaID = 13772 },               -- Broadhoof Outpost (Ohn'ahran Plains); NPC 191813
        [13775] = { space = "map", uiMapID = 2023, x = 0.5715, y = 0.766, areaID = 13775 },                -- Ohn'iri Springs (Ohn'ahran Plains); NPC 192113
        [13780] = { space = "map", uiMapID = 2023, x = 0.4194, y = 0.6052, areaID = 13780 },               -- Teerakai (Ohn'ahran Plains); NPC 195104
        [13814] = { space = "map", uiMapID = 2025, x = 0.3511, y = 0.7924, areaID = 13814 },               -- Garden Shrine (Thaldraszus); NPC 194788
        [13818] = { space = "map", uiMapID = 2025, x = 0.5872, y = 0.8243, areaID = 13818 },               -- Temporal Conflux (Thaldraszus); NPC 189520
        [13862] = { space = "map", uiMapID = 2112, x = 0.4747, y = 0.462, areaID = 13862 },                -- Valdrakken (Valdrakken); NPC 185562
        [13864] = { space = "map", uiMapID = 2025, x = 0.5246, y = 0.696, areaID = 13864 },                -- Gelikyr Post (Thaldraszus); NPC 188887
        [13895] = { space = "map", uiMapID = 2024, x = 0.6553, y = 0.1619, areaID = 13895 },               -- Theron's Watch (The Azure Span); NPC 186762
        [13939] = { space = "map", uiMapID = 2022, x = 0.7633, y = 0.3562, areaID = 13939 },               -- Wingrest Embassy (The Waking Shores); NPC 193393
        [14147] = { space = "map", uiMapID = 2023, x = 0.8133, y = 0.593, areaID = 14147 },                -- Pinewood Post (Ohn'ahran Plains); NPC 191391
        [14346] = { space = "map", uiMapID = 2022, x = 0.4642, y = 0.2725, areaID = 14346 },               -- Uktulut Pier (The Waking Shores); NPC 197849
        [14429] = { space = "map", uiMapID = 2024, x = 0.124, y = 0.4941, areaID = 14429 },                -- The Filled Bowl (The Azure Span); NPC 186446
        [14430] = { space = "map", uiMapID = 2024, x = 0.4695, y = 0.4034, areaID = 14430 },               -- Mage's Rest (The Azure Span); NPC 189147
        [14431] = { space = "map", uiMapID = 2024, x = 0.6278, y = 0.5782, areaID = 14431 },               -- Mulsted's Marquee (The Azure Span); NPC 186851
        [14432] = { space = "map", uiMapID = 2024, x = 0.1873, y = 0.2447, areaID = 14432 },               -- The Missing Hinge Inn (The Azure Span); NPC 190315
        [14434] = { space = "map", uiMapID = 2024, x = 0.3736, y = 0.6243, areaID = 14434 },               -- The Conjured Biscuit Inn (The Azure Span); NPC 189460
        [14452] = { space = "map", uiMapID = 2023, x = 0.2857, y = 0.6051, areaID = 14452 },               -- Greenscale Inn (Ohn'ahran Plains); NPC 186502
        [14491] = { space = "map", uiMapID = 2025, x = 0.5022, y = 0.4254, areaID = 14491 },               -- The Late Night Lab (Thaldraszus); NPC 186458
        [14520] = { space = "map", uiMapID = 2133, x = 0.5622, y = 0.5631, areaID = 14520 },               -- Loamm (Zaralek Cavern); NPC 203293
        [14655] = { space = "map", uiMapID = 2133, x = 0.5224, y = 0.2632, areaID = 14655 },               -- Obsidian Rest (Zaralek Cavern); NPC 200892
        [14766] = { space = "map", uiMapID = 2255, x = 0.4628, y = 0.6892, areaID = 14766 },               -- Wildcamp Ul'ar (Azj-Kahet); NPC 223355
        [14767] = { space = "map", uiMapID = 2255, x = 0.7657, y = 0.6576, areaID = 14767 },               -- Mmarl (Azj-Kahet); NPC 220760
        [14771] = { space = "map", uiMapID = 2339, x = 0.4473, y = 0.464, areaID = 14771 },                -- Dornogal (Dornogal); NPC 212370
        [14772] = { space = "map", uiMapID = 2248, x = 0.4194, y = 0.7422, areaID = 14772 },               -- Freywold Village (Isle of Dorn); NPC 217440
        [14784] = { space = "map", uiMapID = 2248, x = 0.584, y = 0.2738, areaID = 14784 },                -- Rambleshire (Isle of Dorn); NPC 217543
        [14796] = { space = "map", uiMapID = 2214, x = 0.4799, y = 0.3217, areaID = 14796 },               -- Gundargaz (The Ringing Deeps); NPC 213840
        [14812] = { space = "map", uiMapID = 2214, x = 0.6334, y = 0.7887, areaID = 14812 },               -- Opportunity Point (The Ringing Deeps); NPC 225067
        [14814] = { space = "map", uiMapID = 2214, x = 0.5903, y = 0.6403, areaID = 14814 },               -- Camp Murroch (The Ringing Deeps); NPC 225018
        [14820] = { space = "map", uiMapID = 2214, x = 0.6176, y = 0.4617, areaID = 14820 },               -- Shadowvein Point (The Ringing Deeps); NPC 218390
        [14858] = { space = "map", uiMapID = 2200, x = 0.6953, y = 0.5324, areaID = 14858 },               -- Verdant Landing (The Emerald Dream); NPC 208286
        [14904] = { space = "map", uiMapID = 2200, x = 0.525, y = 0.251, areaID = 14904 },                 -- Eye of Ysera (The Emerald Dream); NPC 211352
        [14912] = { space = "map", uiMapID = 2200, x = 0.3656, y = 0.3262, areaID = 14912 },               -- Wellspring Overlook (The Emerald Dream); NPC 209430
        [14916] = { space = "map", uiMapID = 2215, x = 0.6918, y = 0.4561, areaID = 14916 },               -- Dunelle's Kindness (Hallowfall); NPC 217611
        [14917] = { space = "map", uiMapID = 2215, x = 0.428, y = 0.5583, areaID = 14917 },                -- Mereldar (Hallowfall); NPC 217642
        [14928] = { space = "map", uiMapID = 2215, x = 0.4061, y = 0.681, areaID = 14928 },                -- Light's Redoubt (Hallowfall); NPC 221376
        [14945] = { space = "map", uiMapID = 2255, x = 0.5921, y = 0.2523, areaID = 14945 },               -- Faerin's Advance (Azj-Kahet); NPC 211722
        [14960] = { space = "map", uiMapID = 2200, x = 0.4985, y = 0.6164, areaID = 14960 },               -- Central Encampment (The Emerald Dream); NPC 207627
        [15107] = { space = "map", uiMapID = 2215, x = 0.4916, y = 0.3947, areaID = 15107 },               -- Lorel's Crossing (Hallowfall); NPC 221776
        [15135] = { space = "map", uiMapID = 2239, x = 0.4829, y = 0.5403, areaID = 15135 },               -- The Silver Feather (Amirdrassil); NPC 216280
        [15388] = { space = "map", uiMapID = 2346, x = 0.435, y = 0.5169, areaID = 15388 },                -- The Incontinental Hotel (Undermine); NPC 231045
        ["15535:2369:228106"] = { space = "map", uiMapID = 2369, x = 0.714, y = 0.3744, areaID = 15535 },  -- Flotsam Shoal (Siren Isle); NPC 228106
        ["15535:2369:228390"] = { space = "map", uiMapID = 2369, x = 0.6898, y = 0.4644, areaID = 15535 }, -- Flotsam Shoal (Siren Isle); NPC 228390
        [15791] = { space = "map", uiMapID = 2371, x = 0.4998, y = 0.5947, areaID = 15791 },               -- Eco-Dome: Primus (K'aresh); NPC 245405
        [15792] = { space = "map", uiMapID = 2371, x = 0.7673, y = 0.3443, areaID = 15792 },               -- The Oasis (K'aresh); NPC 241507
        ["15802:2371:238572"] = { space = "map", uiMapID = 2371, x = 0.6072, y = 0.2764, areaID = 15802 }, -- Shan'dorah (K'aresh); NPC 238572
        ["15802:2472:235079"] = { space = "map", uiMapID = 2472, x = 0.4113, y = 0.251, areaID = 15802 },  -- Shan'dorah (Tazavesh); NPC 235079
        [15807] = { space = "map", uiMapID = 2371, x = 0.4869, y = 0.3845, areaID = 15807 },               -- Overlook Zo'Shuul (K'aresh); NPC 236097
        [15917] = { space = "map", uiMapID = 2413, x = 0.6913, y = 0.515, areaID = 15917 },                -- Har'athir (Harandar); NPC 251988
        [15921] = { space = "map", uiMapID = 2413, x = 0.6543, y = 0.6193, areaID = 15921 },               -- The Den (Harandar); NPC 258499
        [15924] = { space = "map", uiMapID = 2413, x = 0.6629, y = 0.2457, areaID = 15924 },               -- Har'kuai (Harandar); NPC 254942
        [15928] = { space = "map", uiMapID = 2413, x = 0.3507, y = 0.2295, areaID = 15928 },               -- Har'mara (Harandar); NPC 258354
        [15949] = { space = "map", uiMapID = 2405, x = 0.3568, y = 0.5868, areaID = 15949 },               -- The Ingress (Voidstorm); NPC 240578
        [15950] = { space = "map", uiMapID = 2405, x = 0.4171, y = 0.7464, areaID = 15950 },               -- Locus Point (Voidstorm); NPC 244912
        [15995] = { space = "map", uiMapID = 2395, x = 0.4627, y = 0.4594, areaID = 15995 },               -- Fairbreeze Village (Eversong Woods M); NPC 242949
        [16001] = { space = "map", uiMapID = 2395, x = 0.4897, y = 0.6859, areaID = 16001 },               -- Tranquillien (Eversong Woods M); NPC 236149
        [16183] = { space = "map", uiMapID = 2437, x = 0.4544, y = 0.65, areaID = 16183 },                 -- Amani'Zar Village (Zul Aman M); NPC 240274
        [16203] = { space = "map", uiMapID = 2437, x = 0.4654, y = 0.2575, areaID = 16203 },               -- Camp Stonewash (Zul Aman M); NPC 255184
        [16644] = { space = "map", uiMapID = 2393, x = 0.6691, y = 0.6205, areaID = 16644 },               -- Silvermoon City Inn (Silvermoon City M); NPC 247804
        [16645] = { space = "map", uiMapID = 2393, x = 0.5646, y = 0.7035, areaID = 16645 },               -- Wayfarer's Rest (Silvermoon City M); NPC 239630
        [16750] = { space = "map", uiMapID = 2413, x = 0.311, y = 0.651, areaID = 16750 },                 -- Har'alnor Den (Harandar); NPC 241791
        [16774] = { space = "map", uiMapID = 2512, x = 0.5842, y = 0.4539, areaID = 16774 },               -- Tokka's Landing (The Coiled Isle); NPC 265147
        [16844] = { space = "map", uiMapID = 2405, x = 0.5316, y = 0.6817, areaID = 16844 },               -- Dusk's Repose (Voidstorm); NPC 235701

        -- Legacy area representatives; retained where no verified inn replaces them.
        [20] = { space = "world", instanceID = 0, x = -10876.900390625, y = 1542.8800048828, z = 54.52890014648, areaID = 20 },
        [24] = { space = "world", instanceID = 0, x = -8888.98046875, y = -0.54000002146, z = 94.38999938965, areaID = 24 },
        [87] = { space = "world", instanceID = 0, x = -9433.990234375, y = 85.14929962158, z = 56.73400115967, areaID = 87 },
        [88] = { space = "world", instanceID = 0, x = -9475.7099609375, y = -1306.7399902344, z = 44.14960098267, areaID = 88 },
        [94] = { space = "world", instanceID = 0, x = -10737.599609375, y = 267.04299926758, z = 42.3478012085, areaID = 94 },
        [99] = { space = "world", instanceID = 0, x = -11344, y = -216.83000183106, z = 75.2200012207, areaID = 99 },
        [109] = { space = "world", instanceID = 0, x = -9838.509765625, y = 1273.9300537109, z = 40.70669937134, areaID = 109 },
        [131] = { space = "world", instanceID = 0, x = -5660.7998046875, y = -494.85101318359, z = 397.00799560547, areaID = 131 },
        [134] = { space = "world", instanceID = 0, x = -5714.1401367188, y = -1578.6400146484, z = 383.20401000977, areaID = 134 },
        [139] = { space = "world", instanceID = 0, x = 2253.3999023438, y = -5344.8999023438, z = 83.37999725342, areaID = 139 },
        [144] = { space = "world", instanceID = 0, x = -5421.91015625, y = -2930.0100097656, z = 347.25, areaID = 144 },
        [150] = { space = "world", instanceID = 0, x = -3787.8100585938, y = -777.69598388672, z = 1.55820000172, areaID = 150 },
        [190] = { space = "world", instanceID = 0, x = 2839.7800292969, y = -1500.5100097656, z = 146.0890045166, areaID = 190 },
        [205] = { space = "world", instanceID = 0, x = -2656.5400390625, y = -2464.2800292969, z = 80.33779907227, areaID = 205 },
        [251] = { space = "world", instanceID = 0, x = -7504.0297851562, y = -2187.5400390625, z = 165.5299987793, areaID = 251 },
        [271] = { space = "world", instanceID = 0, x = -661.83697509766, y = -536.49298095703, z = 28.21500015259, areaID = 271 },
        [280] = { space = "world", instanceID = 0, x = 622.85101318359, y = -979.57800292969, z = 169.62100219727, areaID = 280 },
        [285] = { space = "world", instanceID = 0, x = -605.18402099609, y = 435.46499633789, z = 79.44470214844, areaID = 285 },
        [367] = { space = "world", instanceID = 1, x = -780.26702880859, y = -4890.2797851562, z = 19.62150001526, areaID = 367 },
        [394] = { space = "world", instanceID = 571, x = 4267.3901367188, y = -3050.9299316406, z = 318.16000366211, areaID = 394 },
        [448] = { space = "world", instanceID = 1, x = 4970.5, y = 147.64999389648, z = 51.63999938965, areaID = 448 },
        [493] = { space = "world", instanceID = 1, x = 7458.4501953125, y = -2487.2099609375, z = 462.32998657227, areaID = 493 },
        [702] = { space = "world", instanceID = 1, x = 8383.75, y = 980.96398925781, z = 30.82920074463, areaID = 702 },
        [976] = { space = "world", instanceID = 1, x = -7185.9702148438, y = -3768.2399902344, z = 9.30053043365, areaID = 976 },
        [1237] = { space = "world", instanceID = 1, x = 2988.1298828125, y = -4161.3598632812, z = 101.26999664307, areaID = 1237 },
        [1446] = { space = "world", instanceID = 0, x = -6552.58984375, y = -1168.2700195312, z = 309.30999755859, areaID = 1446 },
        [1497] = { space = "world", instanceID = 0, x = 1568.6199951172, y = 267.9700012207, z = -43.09999847412, areaID = 1497 },
        [1519] = { space = "world", instanceID = 0, x = -8841.0595703125, y = 489.65600585938, z = 109.6070022583, areaID = 1519 },
        [1537] = { space = "world", instanceID = 0, x = -4821.7797851562, y = -1155.4399414062, z = 502.20999145508, areaID = 1537 },
        [1638] = { space = "world", instanceID = 1, x = -1197.2099609375, y = 29.70999908447, z = 176.94999694824, areaID = 1638 },
        [1657] = { space = "world", instanceID = 1, x = 9968.7998046875, y = 2622.0900878906, z = 1316.0799560547, areaID = 1657 },
        [2255] = { space = "world", instanceID = 1, x = 6796.7998046875, y = -4742.3901367188, z = 701.5, areaID = 2255 },
        [2263] = { space = "world", instanceID = 0, x = 1876.4000244141, y = -3693.3200683594, z = 157.68699645996, areaID = 2263 },
        [2271] = { space = "world", instanceID = 0, x = 2524.4399414062, y = -4769.5600585938, z = 104.08699798584, areaID = 2271 },
        [2275] = { space = "world", instanceID = 0, x = 3134.2600097656, y = -4354.7797851562, z = 133.46299743652, areaID = 2275 },
        [2358] = { space = "world", instanceID = 1, x = 3000.25, y = -3202.4099121094, z = 189.77000427246, areaID = 2358 },
        [2361] = { space = "world", instanceID = 1, x = 7793.6098632812, y = -2403.4699707031, z = 489.32000732422, areaID = 2361 },
        [2405] = { space = "world", instanceID = 1, x = -356.4700012207, y = 2478.8999023438, z = 75.94999694824, areaID = 2405 },
        [2418] = { space = "world", instanceID = 0, x = -8364.6103515625, y = -2738.3500976562, z = 185.46000671387, areaID = 2418 },
        [2479] = { space = "world", instanceID = 1, x = 3972.8400878906, y = -1324.5100097656, z = 244.80299377441, areaID = 2479 },
        [2539] = { space = "world", instanceID = 1, x = -111.94000244141, y = -260.41000366211, z = 23.87999916077, areaID = 2539 },
        [2619] = { space = "world", instanceID = 0, x = 1935.9699707031, y = -2694.4799804688, z = 61.94710159302, areaID = 2619 },
        [2620] = { space = "world", instanceID = 0, x = 1935.9699707031, y = -2694.4799804688, z = 61.94710159302, areaID = 2620 },
        [2959] = { space = "world", instanceID = 30, x = 574.21002197266, y = -46.65000152588, z = 37.61000061035, areaID = 2959 },
        [2978] = { space = "world", instanceID = 30, x = -1335.4399414062, y = -319.69000244141, z = 90.66000366211, areaID = 2978 },
        [3137] = { space = "world", instanceID = 1, x = 2721.9899902344, y = -3880.6398925781, z = 100.87000274658, areaID = 3137 },
        [3425] = { space = "world", instanceID = 1, x = -6811.3901367188, y = 836.73999023438, z = 49.81000137329, areaID = 3425 },
        [3483] = { space = "world", instanceID = 530, x = -327.35000610352, y = 1020.4899902344, z = 54.25, areaID = 3483 },
        [3644] = { space = "world", instanceID = 530, x = 213.75, y = 6063.75, z = 148.30999755859, areaID = 3644 },
        [3665] = { space = "world", instanceID = 530, x = 9501.9296875, y = -6767.08984375, z = 16.49360084534, areaID = 3665 },
        [3679] = { space = "world", instanceID = 530, x = -3364.6799316406, y = 3650.1799316406, z = 284.7799987793, areaID = 3679 },
        [3712] = { space = "world", instanceID = 530, x = 3082.3100585938, y = 3596.1101074219, z = 144.02000427246, areaID = 3712 },
        [3718] = { space = "world", instanceID = 530, x = 91.66999816895, y = 5214.919921875, z = 23.10000038147, areaID = 3718 },
        [3724] = { space = "world", instanceID = 530, x = 2974.9499511719, y = 1848.2399902344, z = 141.2799987793, areaID = 3724 },
        [3920] = { space = "world", instanceID = 530, x = 298.45999145508, y = 1501.1800537109, z = -14.27999973297, areaID = 3920 },
        [3998] = { space = "world", instanceID = 571, x = 1342.8399658203, y = -3287.8999023438, z = 174.44999694824, areaID = 3998 },
        [4023] = { space = "world", instanceID = 571, x = 3465.6599121094, y = 5901.759765625, z = 144.16999816895, areaID = 4023 },
        [4024] = { space = "world", instanceID = 571, x = 4026.9499511719, y = 7085.5400390625, z = 165.53999328613, areaID = 4024 },
        [4032] = { space = "world", instanceID = 571, x = 2269.5400390625, y = 5173.6899414062, z = 11.10000038147, areaID = 4032 },
        [4062] = { space = "world", instanceID = 571, x = 2108.1101074219, y = -2970.6201171875, z = 148.58000183106, areaID = 4062 },
        [4067] = { space = "world", instanceID = 0, x = 2965.5500488281, y = -3033.6101074219, z = 126.92900085449, areaID = 4067 },
        [4085] = { space = "world", instanceID = 530, x = 13012.700195312, y = -6908.3701171875, z = 9.57999992371, areaID = 4085 },
        [4105] = { space = "world", instanceID = 571, x = 3213.7399902344, y = 6084.7202148438, z = 138, areaID = 4105 },
        [4121] = { space = "world", instanceID = 571, x = 3575.4399414062, y = 6661.6401367188, z = 195.19000244141, areaID = 4121 },
        [4122] = { space = "world", instanceID = 571, x = 4474.7900390625, y = 5712.1298828125, z = 81.2799987793, areaID = 4122 },
        [4169] = { space = "world", instanceID = 571, x = 4612.2099609375, y = 1406.5999755859, z = 195.05999755859, areaID = 4169 },
        [4170] = { space = "world", instanceID = 571, x = 4946.669921875, y = 1165.9399414062, z = 239.57000732422, areaID = 4170 },
        [4281] = { space = "world", instanceID = 0, x = 2352.3701171875, y = -5666.91015625, z = 382.23999023438, areaID = 4281 },
        [4290] = { space = "world", instanceID = 571, x = 5506.2299804688, y = 4748.1000976562, z = -194.42999267578, areaID = 4290 },
        [4312] = { space = "world", instanceID = 571, x = 5218.8999023438, y = -1302.2199707031, z = 242.16000366211, areaID = 4312 },
        [4317] = { space = "world", instanceID = 571, x = 5190.1098632812, y = -2206.4599609375, z = 239.39999389648, areaID = 4317 },
        [4375] = { space = "world", instanceID = 571, x = 6897.6499023438, y = -4118.2299804688, z = 467.35000610352, areaID = 4375 },
        [4438] = { space = "world", instanceID = 571, x = 7308.0400390625, y = -2607.6000976562, z = 814.79998779297, areaID = 4438 },
        [4445] = { space = "world", instanceID = 571, x = 8864.740234375, y = -1324.3299560547, z = 1032.8199462891, areaID = 4445 },
        [4467] = { space = "world", instanceID = 571, x = 7427.3198242188, y = 4224.16015625, z = 314.10998535156, areaID = 4467 },
        [4501] = { space = "world", instanceID = 571, x = 6164.490234375, y = -61.31000137329, z = 388.17999267578, areaID = 4501 },
        [4558] = { space = "world", instanceID = 571, x = 5590.490234375, y = -693.22998046875, z = 206.63000488281, areaID = 4558 },
        [4559] = { space = "world", instanceID = 571, x = 5035.6499023438, y = -519.96002197266, z = 225.41000366211, areaID = 4559 },
        [4580] = { space = "world", instanceID = 571, x = 6402.0600585938, y = 467.85998535156, z = 511.29000854492, areaID = 4580 },
        [4645] = { space = "world", instanceID = 1, x = 3880.5100097656, y = 654.15997314453, z = 10.46000003815, areaID = 4645 },
        [4658] = { space = "world", instanceID = 571, x = 8475.7900390625, y = 891.20001220703, z = 547.28997802734, areaID = 4658 },
        [4711] = { space = "world", instanceID = 1, x = 1905.1099853516, y = -321.98999023438, z = 118.25, areaID = 4711 },
        [4798] = { space = "world", instanceID = 1, x = -1694.5300292969, y = 2577.5700683594, z = 136.58999633789, areaID = 4798 },
        [4803] = { space = "world", instanceID = 1, x = -439.14999389648, y = 2242.6201171875, z = 93.08999633789, areaID = 4803 },
        [4821] = { space = "world", instanceID = 1, x = 3547.1999511719, y = -6294.66015625, z = 0.7542449832, areaID = 4821 },
        [4883] = { space = "world", instanceID = 1, x = -6958.4399414062, y = -1095.2399902344, z = -272.64999389648, areaID = 4883 },
        [4925] = { space = "world", instanceID = 1, x = -534.03997802734, y = 1056.6800537109, z = 89.91000366211, areaID = 4925 },
        [4929] = { space = "world", instanceID = 1, x = 1268.5100097656, y = 432.86999511719, z = 95.55999755859, areaID = 4929 },
        [4934] = { space = "world", instanceID = 1, x = 1825.9399414062, y = 727.2080078125, z = 162.12300109863, areaID = 4934 },
        [4935] = { space = "world", instanceID = 1, x = 1379.4200439453, y = 1034.8599853516, z = 165.08799743652, areaID = 4935 },
        [4936] = { space = "world", instanceID = 1, x = 2188, y = 1241.8900146484, z = 465.76300048828, areaID = 4936 },
        [4986] = { space = "world", instanceID = 1, x = -2152.3500976562, y = -1724.3399658203, z = 92.52799987793, areaID = 4986 },
        [4998] = { space = "world", instanceID = 1, x = 4059.3999023438, y = -3966.75, z = 970.14898681641, areaID = 4998 },
        [5009] = { space = "world", instanceID = 1, x = -4996.8798828125, y = 73.94270324707, z = 99.83850097656, areaID = 5009 },
        [5011] = { space = "world", instanceID = 1, x = -4310.6098632812, y = -927.06402587891, z = 81.17960357666, areaID = 5011 },
        [5019] = { space = "world", instanceID = 1, x = 4397.7900390625, y = -2107.5300292969, z = 1204.3399658203, areaID = 5019 },
        [5038] = { space = "world", instanceID = 1, x = 5584.0600585938, y = -3569.8400878906, z = 1570.5999755859, areaID = 5038 },
        [5041] = { space = "world", instanceID = 1, x = -6075.3701171875, y = -3913.4399414062, z = 21.62240028381, areaID = 5041 },
        [5057] = { space = "world", instanceID = 0, x = -4588.0498046875, y = 3481.1201171875, z = -102.71800231934, areaID = 5057 },
        [5065] = { space = "world", instanceID = 1, x = -4863.6401367188, y = 1478.1600341797, z = 84.84750366211, areaID = 5065 },
        [5074] = { space = "world", instanceID = 0, x = -4113.6000976562, y = -2741.2099609375, z = 18.99110031128, areaID = 5074 },
        [5083] = { space = "world", instanceID = 0, x = -12357.599609375, y = -3058.2299804688, z = 90.32420349121, areaID = 5083 },
        [5121] = { space = "world", instanceID = 0, x = -952.37701416016, y = -1585.7399902344, z = 51.30039978027, areaID = 5121 },
        [5139] = { space = "world", instanceID = 0, x = -3494.6298828125, y = -4379.4799804688, z = 210.49200439453, areaID = 5139 },
        [5155] = { space = "world", instanceID = 0, x = -3032.7600097656, y = -3940.9699707031, z = 282.32699584961, areaID = 5155 },
        [5248] = { space = "world", instanceID = 0, x = -7209.7099609375, y = 3925.8500976562, z = 14.74660015106, areaID = 5248 },
        [5249] = { space = "world", instanceID = 0, x = -6878.5200195312, y = 4244.7099609375, z = 9.77591991425, areaID = 5249 },
        [5317] = { space = "world", instanceID = 0, x = -12092.200195312, y = -814.09899902344, z = 42.3410987854, areaID = 5317 },
        [5324] = { space = "world", instanceID = 0, x = -9641.669921875, y = -3479.3701171875, z = 121.95600128174, areaID = 5324 },
        [5326] = { space = "world", instanceID = 0, x = -9446.6396484375, y = -2836.9899902344, z = 64.57610321045, areaID = 5326 },
        [5345] = { space = "world", instanceID = 1, x = -1197.2099609375, y = 29.70999908447, z = 176.94999694824, areaID = 5345 },
        [5367] = { space = "world", instanceID = 0, x = 1864.3199462891, y = -1755.8199462891, z = 59.66199874878, areaID = 5367 },
        [5369] = { space = "world", instanceID = 0, x = 1421.0200195312, y = 1018.2299804688, z = 52.66719818115, areaID = 5369 },
        [5387] = { space = "world", instanceID = 0, x = -114.14199829102, y = 1312.3199462891, z = 56.74160003662, areaID = 5387 },
        [5388] = { space = "world", instanceID = 1, x = -9487.8896484375, y = -2467.1298828125, z = 16.72859954834, areaID = 5388 },
        [5408] = { space = "world", instanceID = 0, x = -13600.900390625, y = -85.54859924316, z = 37.80780029297, areaID = 5408 },
        [5434] = { space = "world", instanceID = 0, x = -910.22100830078, y = 1638.5999755859, z = 68.36959838867, areaID = 5434 },
        [5448] = { space = "world", instanceID = 0, x = 2262.1000976562, y = -4411.5200195312, z = 111.65200042725, areaID = 5448 },
        [5459] = { space = "world", instanceID = 0, x = -10176.599609375, y = -3836.5400390625, z = 17.98600006104, areaID = 5459 },
        [5524] = { space = "world", instanceID = 0, x = -6898.25, y = -3513.9899902344, z = 242.08500671387, areaID = 5524 },
        [5525] = { space = "world", instanceID = 0, x = -6594.08984375, y = -3401.1799316406, z = 279.20901489258, areaID = 5525 },
        [5602] = { space = "world", instanceID = 1, x = -10711.900390625, y = 1059.6199951172, z = 24.14900016785, areaID = 5602 },
        [5651] = { space = "world", instanceID = 0, x = -8092.259765625, y = -1025.7900390625, z = 132.66600036621, areaID = 5651 },
        [5654] = { space = "world", instanceID = 0, x = -7865.9301757812, y = -1919.5300292969, z = 144.72200012207, areaID = 5654 },
        [5676] = { space = "world", instanceID = 1, x = 6892.6899414062, y = -1620.4100341797, z = 503.10598754883, areaID = 5676 },
        [5731] = { space = "world", instanceID = 0, x = -3222.9299316406, y = -1989.4899902344, z = 50.54750061035, areaID = 5731 },
        [5855] = { space = "world", instanceID = 870, x = 2505.8999023438, y = -1590.8900146484, z = 400.86801147461, areaID = 5855 },
        [5931] = { space = "world", instanceID = 870, x = 1600.6600341797, y = -2530.2700195312, z = 152.21200561523, areaID = 5931 },
        [5948] = { space = "world", instanceID = 870, x = 460.54000854492, y = -100.46700286865, z = 179.53500366211, areaID = 5948 },
        [5962] = { space = "world", instanceID = 870, x = 2400.75, y = -2099.4299316406, z = 228.03399658203, areaID = 5962 },
        [5968] = { space = "world", instanceID = 870, x = -436.54000854492, y = 1886.6999511719, z = 131.13000488281, areaID = 5968 },
        [5980] = { space = "world", instanceID = 870, x = -221.32600402832, y = 464.55899047852, z = 185.44200134277, areaID = 5980 },
        [6000] = { space = "world", instanceID = 870, x = -375.68399047852, y = -647.96502685547, z = 117.51599884033, areaID = 6000 },
        [6059] = { space = "world", instanceID = 870, x = 1690.1099853516, y = 303.9580078125, z = 478.58700561523, areaID = 6059 },
        [6080] = { space = "world", instanceID = 870, x = 465.85598754883, y = -1558.5600585938, z = 154.88600158691, areaID = 6080 },
        [6085] = { space = "world", instanceID = 870, x = 3124.5200195312, y = 1224.2800292969, z = 654.23101806641, areaID = 6085 },
        [6141] = { space = "world", instanceID = 870, x = 1580.1600341797, y = 894.1669921875, z = 473.96398925781, areaID = 6141 },
        [6142] = { space = "world", instanceID = 870, x = 896.45300292969, y = 334.35101318359, z = 506.08499145508, areaID = 6142 },
        [6146] = { space = "world", instanceID = 870, x = -2504.0900878906, y = 491.5830078125, z = 2.33204007149, areaID = 6146 },
        [6155] = { space = "world", instanceID = 870, x = -2082.3000488281, y = 1483.6300048828, z = 0.55060398579, areaID = 6155 },
        [6169] = { space = "world", instanceID = 870, x = 4362.9599609375, y = 932.11798095703, z = 110.03900146484, areaID = 6169 },
        [6193] = { space = "world", instanceID = 870, x = 1531.7299804688, y = 3963.6999511719, z = 227.66600036621, areaID = 6193 },
        [6334] = { space = "world", instanceID = 870, x = 982.67700195313, y = 3451.8601074219, z = 256.76998901367, areaID = 6334 },
        [6368] = { space = "world", instanceID = 870, x = -1086.2099609375, y = 3136.1899414062, z = 0.98309999704, areaID = 6368 },
        [6383] = { space = "world", instanceID = 870, x = 3151.8500976562, y = 2677.7600097656, z = 579.73498535156, areaID = 6383 },
        [6391] = { space = "world", instanceID = 870, x = -570.40502929688, y = 3859.7900390625, z = 0.73435801268, areaID = 6391 },
        [6393] = { space = "world", instanceID = 870, x = 611.36499023438, y = 2125.0300292969, z = 368.35501098633, areaID = 6393 },
        [6394] = { space = "world", instanceID = 870, x = 611.36499023438, y = 2125.0300292969, z = 368.35501098633, areaID = 6394 },
        [6395] = { space = "world", instanceID = 870, x = 611.36499023438, y = 2125.0300292969, z = 368.35501098633, areaID = 6395 },
        [6528] = { space = "world", instanceID = 870, x = 611.36499023438, y = 2125.0300292969, z = 368.35501098633, areaID = 6528 },
        [6530] = { space = "world", instanceID = 870, x = 611.36499023438, y = 2125.0300292969, z = 368.35501098633, areaID = 6530 },
        [6553] = { space = "world", instanceID = 870, x = 896.45300292969, y = 334.35101318359, z = 506.08499145508, areaID = 6553 },
        [6554] = { space = "world", instanceID = 870, x = 1580.1600341797, y = 894.1669921875, z = 473.96398925781, areaID = 6554 },
        [6566] = { space = "world", instanceID = 870, x = -1752.1899414062, y = 2492.0200195312, z = 34.51319885254, areaID = 6566 },
        [6596] = { space = "world", instanceID = 870, x = -1193.5600585938, y = -1193.6999511719, z = 37.21189880371, areaID = 6596 },
        [6701] = { space = "world", instanceID = 870, x = 5753.759765625, y = 1255.5500488281, z = 1.5147600174, areaID = 6701 },
        [6702] = { space = "world", instanceID = 870, x = 5799.6401367188, y = 1080.5699462891, z = 1.13505005836, areaID = 6702 },
        [6833] = { space = "world", instanceID = 870, x = -901.36999511719, y = -4639.1201171875, z = 4.96100997925, areaID = 6833 },
        [6834] = { space = "world", instanceID = 870, x = -404.95001220703, y = -4608.5600585938, z = 4.33349990845, areaID = 6834 },
        [6869] = { space = "world", instanceID = 1116, x = 5988.6801757812, y = 6180.8598632812, z = 71.12470245361, areaID = 6869 },
        [6876] = { space = "world", instanceID = 1116, x = 4552.2700195312, y = 1274.5600585938, z = 144.92799377441, areaID = 6876 },
        [6880] = { space = "world", instanceID = 1116, x = 4837.6298828125, y = 1687.5500488281, z = 148.98300170898, areaID = 6880 },
        [6909] = { space = "world", instanceID = 1116, x = -799.67401123047, y = -671.42401123047, z = 107.10199737549, areaID = 6909 },
        [6910] = { space = "world", instanceID = 1116, x = -974.125, y = -1739.3000488281, z = 2.99791002274, areaID = 6910 },
        [6914] = { space = "world", instanceID = 1116, x = 5412.8500976562, y = 1271.0500488281, z = 101.88999938965, areaID = 6914 },
        [6923] = { space = "world", instanceID = 1116, x = 918.26397705078, y = -792.36102294922, z = -28.83379936218, areaID = 6923 },
        [6931] = { space = "world", instanceID = 1116, x = 602.69799804688, y = -1710.4499511719, z = 26.48369979858, areaID = 6931 },
        [6933] = { space = "world", instanceID = 1116, x = 2158.6499023438, y = 1634.4699707031, z = 131.81700134277, areaID = 6933 },
        [6957] = { space = "world", instanceID = 1116, x = 1526.3800048828, y = -788.89099121094, z = 43.06470108032, areaID = 6957 },
        [6965] = { space = "world", instanceID = 1116, x = 5789.5698242188, y = 2394.8898925781, z = 201.35400390625, areaID = 6965 },
        [6969] = { space = "world", instanceID = 1116, x = 7399.4501953125, y = 4358.41015625, z = 126.40599822998, areaID = 6969 },
        [6983] = { space = "world", instanceID = 1116, x = 5724.259765625, y = 2163.6398925781, z = 157.57499694824, areaID = 6983 },
        [7014] = { space = "world", instanceID = 1116, x = 5789.5698242188, y = 2394.8898925781, z = 201.35400390625, areaID = 7014 },
        [7020] = { space = "world", instanceID = 1116, x = 1378.4000244141, y = 3318.5200195312, z = 138.13400268555, areaID = 7020 },
        [7029] = { space = "world", instanceID = 1116, x = 1696.5, y = 2561.3500976562, z = 133.65899658203, areaID = 7029 },
        [7036] = { space = "world", instanceID = 1116, x = -398.9880065918, y = 1880.1199951172, z = 51.26839828491, areaID = 7036 },
        [7073] = { space = "world", instanceID = 1116, x = 3040.7800292969, y = 4783.080078125, z = 128.27499389648, areaID = 7073 },
        [7075] = { space = "world", instanceID = 1116, x = 5830.8598632812, y = 3004.0900878906, z = 183.21000671387, areaID = 7075 },
        [7111] = { space = "world", instanceID = 1116, x = 128.61500549316, y = 1544.6300048828, z = -1.7282500267, areaID = 7111 },
        [7113] = { space = "world", instanceID = 1116, x = 5830.8598632812, y = 3004.0900878906, z = 183.21000671387, areaID = 7113 },
        [7115] = { space = "world", instanceID = 1116, x = 3418.7800292969, y = 1040.1500244141, z = 178.08500671387, areaID = 7115 },
        [7132] = { space = "world", instanceID = 1116, x = 3407.7299804688, y = 2062, z = 160.39799499512, areaID = 7132 },
        [7133] = { space = "world", instanceID = 1116, x = 2808.7900390625, y = 2525.7399902344, z = 120.93900299072, areaID = 7133 },
        [7153] = { space = "world", instanceID = 1116, x = 6456.1000976562, y = -174.75500488281, z = 120.07099914551, areaID = 7153 },
        [7161] = { space = "world", instanceID = 1116, x = 128.56900024414, y = -1555.75, z = 31.48259925842, areaID = 7161 },
        [7162] = { space = "world", instanceID = 1116, x = -1579.1400146484, y = 993.09002685547, z = 8.08963012695, areaID = 7162 },
        [7180] = { space = "world", instanceID = 1116, x = -335.45098876953, y = 926.62200927734, z = 75.21530151367, areaID = 7180 },
        [7199] = { space = "world", instanceID = 1116, x = 387.5419921875, y = 2442.7299804688, z = 19.3169002533, areaID = 7199 },
        [7280] = { space = "world", instanceID = 1116, x = 3918.7900390625, y = 5131.4501953125, z = 62.72800064087, areaID = 7280 },
        [7320] = { space = "world", instanceID = 1116, x = 7093.6000976562, y = 404.73999023438, z = 112.00099945068, areaID = 7320 },
        [7340] = { space = "world", instanceID = 1220, x = 576.40502929688, y = 6644.0297851562, z = 58.5, areaID = 7340 },
        [7349] = { space = "world", instanceID = 1220, x = -88.43229675293, y = 8214.3203125, z = 355.52200317383, areaID = 7349 },
        [7481] = { space = "world", instanceID = 1116, x = 676.42401123047, y = 701.43902587891, z = 113.95999908447, areaID = 7481 },
        [7493] = { space = "world", instanceID = 1116, x = 5724.259765625, y = 2163.6398925781, z = 157.57499694824, areaID = 7493 },
        [7520] = { space = "world", instanceID = 1116, x = 8486.150390625, y = 1544.2399902344, z = 78.87539672852, areaID = 7520 },
        [7522] = { space = "world", instanceID = 1116, x = 3875.2199707031, y = -1311.7199707031, z = 90.46730041504, areaID = 7522 },
        [7523] = { space = "world", instanceID = 1116, x = 4307.91015625, y = -1465.3100585938, z = 78.94390106201, areaID = 7523 },
        [7527] = { space = "world", instanceID = 1116, x = 3979.3000488281, y = 1216.6199951172, z = 164.19700622559, areaID = 7527 },
        [7535] = { space = "world", instanceID = 1220, x = 1406.0799560547, y = 7140.7001953125, z = 60.78300094604, areaID = 7535 },
        [7536] = { space = "world", instanceID = 1116, x = 4569.4399414062, y = 335.0539855957, z = 221.19700622559, areaID = 7536 },
        [7537] = { space = "world", instanceID = 1116, x = 3475.2800292969, y = -762.55200195313, z = 41.39059829712, areaID = 7537 },
        [7555] = { space = "world", instanceID = 1220, x = 3217.6000976562, y = 3079.919921875, z = 440.30200195313, areaID = 7555 },
        [7564] = { space = "world", instanceID = 1220, x = 3987.5400390625, y = 2914.2900390625, z = 241.25700378418, areaID = 7564 },
        [7569] = { space = "world", instanceID = 1220, x = -88.43229675293, y = 8214.3203125, z = 355.52200317383, areaID = 7569 },
        [7578] = { space = "world", instanceID = 1220, x = -3362.3200683594, y = 4823.009765625, z = 17.55369949341, areaID = 7578 },
        [7600] = { space = "world", instanceID = 1220, x = 2299.8798828125, y = 6577.66015625, z = 141.78700256348, areaID = 7600 },
        [7612] = { space = "world", instanceID = 1220, x = 2113.3999023438, y = 2823.4599609375, z = 815.41900634766, areaID = 7612 },
        [7638] = { space = "world", instanceID = 0, x = 8444.3203125, y = -4765.7202148438, z = 49.00099945068, areaID = 7638 },
        [7642] = { space = "world", instanceID = 1220, x = 2814.2900390625, y = 7275.8198242188, z = 22.35320091248, areaID = 7642 },
        [7646] = { space = "world", instanceID = 1220, x = 554.0419921875, y = 5628.8798828125, z = 79.86769866943, areaID = 7646 },
        [7667] = { space = "world", instanceID = 1220, x = 2841.7900390625, y = 6482.2900390625, z = 206.32600402832, areaID = 7667 },
        [7679] = { space = "world", instanceID = 1220, x = -1437.4300537109, y = 1162.2399902344, z = 275.34600830078, areaID = 7679 },
        [7698] = { space = "world", instanceID = 1220, x = 2355.7199707031, y = 1870.0899658203, z = 24.98850059509, areaID = 7698 },
        [7699] = { space = "world", instanceID = 1220, x = 2863.9299316406, y = 849.17498779297, z = 77.88590240479, areaID = 7699 },
        [7726] = { space = "world", instanceID = 1220, x = 4833.9301757812, y = 3967.3701171875, z = 832.17498779297, areaID = 7726 },
        [7731] = { space = "world", instanceID = 1220, x = 4156.509765625, y = 4374.4501953125, z = 768.15997314453, areaID = 7731 },
        [7744] = { space = "world", instanceID = 1220, x = 4764.5200195312, y = -186.99699401856, z = 16.95140075684, areaID = 7744 },
        [7750] = { space = "world", instanceID = 1116, x = 3728.3798828125, y = 157.93099975586, z = 56.11529922485, areaID = 7750 },
        [7751] = { space = "world", instanceID = 1116, x = 4457.5400390625, y = -574.69299316406, z = 49.37649917603, areaID = 7751 },
        [7769] = { space = "world", instanceID = 1220, x = 5116.1098632812, y = 4982.16015625, z = 752.71099853516, areaID = 7769 },
        [7815] = { space = "world", instanceID = 1220, x = 2971.6899414062, y = 4343.4599609375, z = 652.03198242188, areaID = 7815 },
        [7840] = { space = "world", instanceID = 1220, x = 1615.5200195312, y = 4757.8598632812, z = 138.37100219727, areaID = 7840 },
        [7846] = { space = "world", instanceID = 1220, x = 4074.3200683594, y = 7225.4501953125, z = 51.49890136719, areaID = 7846 },
        [7849] = { space = "world", instanceID = 1220, x = 2885.6499023438, y = 2422.6101074219, z = 242.82899475098, areaID = 7849 },
        [7850] = { space = "world", instanceID = 1220, x = 2704.4899902344, y = 2860.2299804688, z = 309.26300048828, areaID = 7850 },
        [7857] = { space = "world", instanceID = 1220, x = 4764.5200195312, y = -186.99699401856, z = 16.95140075684, areaID = 7857 },
        [7877] = { space = "world", instanceID = 1220, x = 4634.2900390625, y = 5339.419921875, z = 849.23101806641, areaID = 7877 },
        [7883] = { space = "world", instanceID = 1220, x = 6466.83984375, y = 4727.990234375, z = 13.61979961395, areaID = 7883 },
        [7949] = { space = "world", instanceID = 1220, x = 3891.9499511719, y = 3500.1799316406, z = 800.65802001953, areaID = 7949 },
        [7999] = { space = "world", instanceID = 1220, x = 4156.509765625, y = 4374.4501953125, z = 768.15997314453, areaID = 7999 },
        [8023] = { space = "world", instanceID = 1519, x = 1659.1500244141, y = 1416.6800537109, z = 244.26300048828, areaID = 8023 },
        [8050] = { space = "world", instanceID = 1220, x = 3853.5500488281, y = 5150.58984375, z = 644.59698486328, areaID = 8050 },
        [8087] = { space = "world", instanceID = 1220, x = 1893.3000488281, y = 3092.5500488281, z = 221.23399353027, areaID = 8087 },
        [8091] = { space = "world", instanceID = 1, x = 5584.0600585938, y = -3569.8400878906, z = 1570.5999755859, areaID = 8091 },
        [8095] = { space = "world", instanceID = 1220, x = 3793.25, y = 2368.8400878906, z = 491.34600830078, areaID = 8095 },
        [8147] = { space = "world", instanceID = 1220, x = -1704.4399414062, y = 6472.990234375, z = 264.04901123047, areaID = 8147 },
        [8167] = { space = "world", instanceID = 1220, x = 3835.6101074219, y = 2016.1199951172, z = 244.06300354004, areaID = 8167 },
        [8204] = { space = "world", instanceID = 1220, x = 4156.509765625, y = 4374.4501953125, z = 768.15997314453, areaID = 8204 },
        [8206] = { space = "world", instanceID = 1220, x = -88.43229675293, y = 8214.3203125, z = 355.52200317383, areaID = 8206 },
        [8212] = { space = "world", instanceID = 1220, x = -88.43229675293, y = 8214.3203125, z = 355.52200317383, areaID = 8212 },
        [8230] = { space = "world", instanceID = 1220, x = 2268.8000488281, y = 5241.58984375, z = 113.11199951172, areaID = 8230 },
        [8234] = { space = "world", instanceID = 0, x = -8841.0595703125, y = 489.65600585938, z = 109.6070022583, areaID = 8234 },
        [8256] = { space = "world", instanceID = 1220, x = 5108.330078125, y = 5570.6098632812, z = 119.21800231934, areaID = 8256 },
        [8346] = { space = "world", instanceID = 0, x = 2253.3999023438, y = -5344.8999023438, z = 83.37999725342, areaID = 8346 },
        [8350] = { space = "world", instanceID = 1220, x = -228.43800354004, y = 7733.7001953125, z = 139.18899536133, areaID = 8350 },
        [8354] = { space = "world", instanceID = 0, x = 2253.3999023438, y = -5344.8999023438, z = 83.37999725342, areaID = 8354 },
        [8359] = { space = "world", instanceID = 0, x = 2524.4399414062, y = -4769.5600585938, z = 104.08699798584, areaID = 8359 },
        [8368] = { space = "world", instanceID = 1220, x = 2523.9399414062, y = 8174.8598632812, z = 12.4125995636, areaID = 8368 },
        [8370] = { space = "world", instanceID = 1220, x = -1804.7199707031, y = 6417.6298828125, z = 177.98599243164, areaID = 8370 },
        [8371] = { space = "world", instanceID = 1220, x = -1403.6300048828, y = 6656.8598632812, z = 11.94629955292, areaID = 8371 },
        [8373] = { space = "world", instanceID = 1220, x = -3362.3200683594, y = 4823.009765625, z = 17.55369949341, areaID = 8373 },
        [8393] = { space = "world", instanceID = 1220, x = 1797.3499755859, y = 1816.6999511719, z = 298.39599609375, areaID = 8393 },
        [8456] = { space = "world", instanceID = 0, x = -8841.0595703125, y = 489.65600585938, z = 109.6070022583, areaID = 8456 },
        [8517] = { space = "world", instanceID = 1220, x = -1647.6800537109, y = 3178.6398925781, z = 135.93099975586, areaID = 8517 },
        [8554] = { space = "world", instanceID = 1220, x = -1647.6800537109, y = 3178.6398925781, z = 135.93099975586, areaID = 8554 },
        [8560] = { space = "world", instanceID = 1220, x = -545.19097900391, y = 3001.7800292969, z = 40.20389938354, areaID = 8560 },
        [8648] = { space = "world", instanceID = 1220, x = -1225.5100097656, y = 2195.2299804688, z = 0.98000097275, areaID = 8648 },
        [8665] = { space = "world", instanceID = 1642, x = -1950.7800292969, y = 744.28002929688, z = 53.78540039063, areaID = 8665 },
        [8673] = { space = "world", instanceID = 1669, x = 985.81896972656, y = 1711.8900146484, z = 517.20001220703, areaID = 8673 },
        [8682] = { space = "world", instanceID = 1669, x = 4983.2998046875, y = 9823.4697265625, z = -78.69999694824, areaID = 8682 },
        [8716] = { space = "world", instanceID = 1643, x = 552.16802978516, y = -126.11799621582, z = 25.79800033569, areaID = 8716 },
        [8718] = { space = "world", instanceID = 1643, x = 1153.0300292969, y = -470.30099487305, z = 31.2922000885, areaID = 8718 },
        [8719] = { space = "world", instanceID = 1642, x = -1046.3199462891, y = 19.17359924316, z = 281.20300292969, areaID = 8719 },
        [8727] = { space = "world", instanceID = 1642, x = -104.02300262451, y = 1502.4799804688, z = 398.53100585938, areaID = 8727 },
        [8729] = { space = "world", instanceID = 1642, x = -624.58801269531, y = 715.30499267578, z = 234.49000549316, areaID = 8729 },
        [8732] = { space = "world", instanceID = 1642, x = -1132.6199951172, y = 1499.6999511719, z = 420.25399780273, areaID = 8732 },
        [8733] = { space = "world", instanceID = 1642, x = 512.45001220703, y = -835.21899414063, z = 26.49160003662, areaID = 8733 },
        [8738] = { space = "world", instanceID = 1, x = -780.26702880859, y = -4890.2797851562, z = 19.62150001526, areaID = 8738 },
        [8741] = { space = "world", instanceID = 1669, x = 5546.0600585938, y = 10563, z = 7.94999980927, areaID = 8741 },
        [8778] = { space = "world", instanceID = 1, x = -2152.3500976562, y = -1724.3399658203, z = 92.52799987793, areaID = 8778 },
        [8797] = { space = "world", instanceID = 1, x = -4310.6098632812, y = -927.06402587891, z = 81.17960357666, areaID = 8797 },
        [8866] = { space = "world", instanceID = 1642, x = 528.71197509766, y = 3983.0600585938, z = 2.2737801075, areaID = 8866 },
        [8872] = { space = "world", instanceID = 1642, x = 2740.1799316406, y = 3469.8999023438, z = 66.11019897461, areaID = 8872 },
        [8882] = { space = "world", instanceID = 1669, x = 5764.8901367188, y = 9493.7802734375, z = -66.69999694824, areaID = 8882 },
        [8886] = { space = "world", instanceID = 1669, x = 6307.330078125, y = 10116.5, z = -16, areaID = 8886 },
        [8903] = { space = "world", instanceID = 1643, x = 125.77600097656, y = -548.875, z = 4.9683599472, areaID = 8903 },
        [8913] = { space = "world", instanceID = 1642, x = 2025.8699951172, y = 1336.5300292969, z = 16.58760070801, areaID = 8913 },
        [8933] = { space = "world", instanceID = 1669, x = 1081.1300048828, y = 2275.75, z = 409, areaID = 8933 },
        [8948] = { space = "world", instanceID = 1642, x = 2596.8798828125, y = -848.68798828125, z = 1.98369002342, areaID = 8948 },
        [8953] = { space = "world", instanceID = 1643, x = -93.73780059814, y = -633.32299804688, z = 5.98346996307, areaID = 8953 },
        [8958] = { space = "world", instanceID = 1642, x = 1559.9399414062, y = 3777.5300292969, z = 37.28879928589, areaID = 8958 },
        [8961] = { space = "world", instanceID = 1642, x = 2778.2900390625, y = 4186.9599609375, z = 9.86785030365, areaID = 8961 },
        [8978] = { space = "world", instanceID = 1643, x = -80.04509735107, y = -2648.3500976562, z = 1.83972001076, areaID = 8978 },
        [9032] = { space = "world", instanceID = 1643, x = -66.31600189209, y = 2141.2399902344, z = 46.55770111084, areaID = 9032 },
        [9040] = { space = "world", instanceID = 1669, x = 1437.4799804688, y = 1444.2700195312, z = 491.79998779297, areaID = 9040 },
        [9045] = { space = "world", instanceID = 1642, x = -961.76702880859, y = -1064.6899414062, z = 25.57229995728, areaID = 9045 },
        [9078] = { space = "world", instanceID = 1643, x = -1786.5100097656, y = -729.38201904297, z = 61.87950134277, areaID = 9078 },
        [9124] = { space = "world", instanceID = 1643, x = 790.83697509766, y = 1861.5400390625, z = -0.23193000257, areaID = 9124 },
        [9130] = { space = "world", instanceID = 1643, x = -296.98300170898, y = 1227.5300292969, z = 5.66251993179, areaID = 9130 },
        [9138] = { space = "world", instanceID = 1669, x = -2367.0600585938, y = 8878.9296875, z = -139.89999389648, areaID = 9138 },
        [9139] = { space = "world", instanceID = 1669, x = -3516.0900878906, y = 8809.33984375, z = -180.60000610352, areaID = 9139 },
        [9140] = { space = "world", instanceID = 1669, x = -2934.8000488281, y = 8798.4296875, z = -231.5, areaID = 9140 },
        [9148] = { space = "world", instanceID = 1643, x = -1045.7299804688, y = 1277.6600341797, z = 7.27366018295, areaID = 9148 },
        [9231] = { space = "world", instanceID = 1643, x = 350.88500976563, y = 1710.3299560547, z = 10.03009986877, areaID = 9231 },
        [9235] = { space = "world", instanceID = 1642, x = -2022.5500488281, y = 1629.1600341797, z = 52.58290100098, areaID = 9235 },
        [9338] = { space = "world", instanceID = 1643, x = 1397.2600097656, y = 2043.4300537109, z = 264.55099487305, areaID = 9338 },
        [9339] = { space = "world", instanceID = 1643, x = -742.60900878906, y = 3115.2900390625, z = 328.46701049805, areaID = 9339 },
        [9366] = { space = "world", instanceID = 1643, x = 2495.5200195312, y = -44.36809921265, z = 55.23189926147, areaID = 9366 },
        [9380] = { space = "world", instanceID = 1643, x = -318.50500488281, y = 980.13702392578, z = 1.07104003429, areaID = 9380 },
        [9381] = { space = "world", instanceID = 1643, x = -145.05700683594, y = 41.04169845581, z = -0.05029340088, areaID = 9381 },
        [9404] = { space = "world", instanceID = 1642, x = -639.64898681641, y = 1806.0899658203, z = 664.166015625, areaID = 9404 },
        [9416] = { space = "world", instanceID = 1643, x = -1501.9699707031, y = 3755.7299804688, z = 5.86357021332, areaID = 9416 },
        [9423] = { space = "world", instanceID = 1643, x = 2508.0900878906, y = 458.83999633789, z = 66.40039825439, areaID = 9423 },
        [9432] = { space = "world", instanceID = 1643, x = 100.12799835205, y = 3478.3400878906, z = 197.0059967041, areaID = 9432 },
        [9470] = { space = "world", instanceID = 1643, x = 2700.2800292969, y = -547.56597900391, z = 5.33414983749, areaID = 9470 },
        [9543] = { space = "world", instanceID = 1642, x = -1849.6700439453, y = 1195.6999511719, z = 53.36199951172, areaID = 9543 },
        [9572] = { space = "world", instanceID = 1642, x = -624.58801269531, y = 715.30499267578, z = 234.49000549316, areaID = 9572 },
        [9587] = { space = "world", instanceID = 1643, x = 631.97900390625, y = 3829.4399414062, z = 101.73300170898, areaID = 9587 },
        [9602] = { space = "world", instanceID = 1643, x = 465.68798828125, y = -642.65100097656, z = 28.52779960632, areaID = 9602 },
        [9603] = { space = "world", instanceID = 1642, x = -3529.8500976562, y = 1103.2900390625, z = 8.04069042206, areaID = 9603 },
        [9604] = { space = "world", instanceID = 1642, x = -3018.7199707031, y = 686.41998291016, z = 14.82050037384, areaID = 9604 },
        [9617] = { space = "world", instanceID = 1643, x = -392.0950012207, y = 4203.8901367188, z = 29.39550018311, areaID = 9617 },
        [9624] = { space = "world", instanceID = 1642, x = -19.9375, y = 999.85900878906, z = 200.81500244141, areaID = 9624 },
        [9644] = { space = "world", instanceID = 1643, x = -254.58200073242, y = -362.44400024414, z = 116.10199737549, areaID = 9644 },
        [9655] = { space = "world", instanceID = 1643, x = 340.83200073242, y = 3160.4399414062, z = 367.20199584961, areaID = 9655 },
        [9657] = { space = "world", instanceID = 1642, x = 2778.2900390625, y = 4186.9599609375, z = 9.86785030365, areaID = 9657 },
        [9668] = { space = "world", instanceID = 1643, x = 4252.0200195312, y = -1080.8199462891, z = 178.71299743652, areaID = 9668 },
        [9694] = { space = "world", instanceID = 1643, x = -191.64100646973, y = -1487.9699707031, z = 14.22399997711, areaID = 9694 },
        [9696] = { space = "world", instanceID = 1643, x = 3889.080078125, y = 423.14898681641, z = 130.45700073242, areaID = 9696 },
        [9715] = { space = "world", instanceID = 1642, x = -1697.4200439453, y = -862.75201416016, z = 23.84919929504, areaID = 9715 },
        [9767] = { space = "world", instanceID = 1643, x = 4252.0200195312, y = -1080.8199462891, z = 178.71299743652, areaID = 9767 },
        [9768] = { space = "world", instanceID = 1642, x = 2623.3500976562, y = 3038.169921875, z = 82.42780303955, areaID = 9768 },
        [9779] = { space = "world", instanceID = 1643, x = -1001.0700073242, y = 1493.8800048828, z = 47.9089012146, areaID = 9779 },
        [9796] = { space = "world", instanceID = 1643, x = 1641.3399658203, y = 385.85198974609, z = 87.88179779053, areaID = 9796 },
        [9806] = { space = "world", instanceID = 1642, x = 2799.25, y = 774.20098876953, z = 6.21301984787, areaID = 9806 },
        [9813] = { space = "world", instanceID = 1643, x = -809.11297607422, y = 1041.0100097656, z = 50.89149856567, areaID = 9813 },
        [9824] = { space = "world", instanceID = 1643, x = 618.91101074219, y = 1740.3699951172, z = 0.95023798943, areaID = 9824 },
        [9829] = { space = "world", instanceID = 1643, x = 4133.5698242188, y = -110.0419998169, z = 208.53900146484, areaID = 9829 },
        [9833] = { space = "world", instanceID = 1643, x = 3298.9799804688, y = 262.875, z = 82.70719909668, areaID = 9833 },
        [9836] = { space = "world", instanceID = 1643, x = 2126.5, y = 349.99099731445, z = 127.70899963379, areaID = 9836 },
        [9947] = { space = "world", instanceID = 1643, x = 2636.4899902344, y = 1138.1500244141, z = 97.67960357666, areaID = 9947 },
        [9956] = { space = "world", instanceID = 1643, x = 2737.3898925781, y = -966.67901611328, z = 84.24389648438, areaID = 9956 },
        [9961] = { space = "world", instanceID = 1642, x = -696.90600585938, y = 1942.7399902344, z = 714.77600097656, areaID = 9961 },
        [9966] = { space = "world", instanceID = 1642, x = -150.21200561523, y = 1911.9499511719, z = 452.07800292969, areaID = 9966 },
        [9974] = { space = "world", instanceID = 1642, x = -1293.6199951172, y = 259.44799804688, z = 280.63101196289, areaID = 9974 },
        [9978] = { space = "world", instanceID = 1642, x = 1310.3100585938, y = 1647.5, z = 40.7598991394, areaID = 9978 },
        [10015] = { space = "world", instanceID = 1643, x = -80.04509735107, y = -2648.3500976562, z = 1.83972001076, areaID = 10015 },
        [10178] = { space = "world", instanceID = 571, x = 5506.2299804688, y = 4748.1000976562, z = -194.42999267578, areaID = 10178 },
        [10335] = { space = "world", instanceID = 1718, x = 1708.1999511719, y = 237.06799316406, z = -363.59799194336, areaID = 10335 },
        [10419] = { space = "world", instanceID = 1643, x = 3044.4099121094, y = 4800.759765625, z = 1.51100003719, areaID = 10419 },
        [10420] = { space = "world", instanceID = 1643, x = 3282.0200195312, y = 4900.4599609375, z = 3.51593995094, areaID = 10420 },
        [10547] = { space = "world", instanceID = 1718, x = 2113.0300292969, y = -584.93402099609, z = -609.46099853516, areaID = 10547 },
        [10550] = { space = "world", instanceID = 1718, x = 1747.1600341797, y = -1035.3399658203, z = -374.84100341797, areaID = 10550 },
        [10565] = { space = "world", instanceID = 2222, x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875, areaID = 10565 },
        [10718] = { space = "world", instanceID = 1220, x = 3217.6000976562, y = 3079.919921875, z = 440.30200195313, areaID = 10718 },
        [10720] = { space = "world", instanceID = 1220, x = 3987.5400390625, y = 2914.2900390625, z = 241.25700378418, areaID = 10720 },
        [10725] = { space = "world", instanceID = 1220, x = 2113.3999023438, y = 2823.4599609375, z = 815.41900634766, areaID = 10725 },
        [10734] = { space = "world", instanceID = 1220, x = 2355.7199707031, y = 1870.0899658203, z = 24.98850059509, areaID = 10734 },
        [10735] = { space = "world", instanceID = 1220, x = 2863.9299316406, y = 849.17498779297, z = 77.88590240479, areaID = 10735 },
        [10737] = { space = "world", instanceID = 1220, x = 2885.6499023438, y = 2422.6101074219, z = 242.82899475098, areaID = 10737 },
        [10738] = { space = "world", instanceID = 1220, x = 2704.4899902344, y = 2860.2299804688, z = 309.26300048828, areaID = 10738 },
        [10743] = { space = "world", instanceID = 1220, x = 4833.9301757812, y = 3967.3701171875, z = 832.17498779297, areaID = 10743 },
        [10753] = { space = "world", instanceID = 1220, x = 4764.5200195312, y = -186.99699401856, z = 16.95140075684, areaID = 10753 },
        [10764] = { space = "world", instanceID = 1220, x = 3891.9499511719, y = 3500.1799316406, z = 800.65802001953, areaID = 10764 },
        [10771] = { space = "world", instanceID = 1220, x = 1893.3000488281, y = 3092.5500488281, z = 221.23399353027, areaID = 10771 },
        [10775] = { space = "world", instanceID = 1220, x = 3835.6101074219, y = 2016.1199951172, z = 244.06300354004, areaID = 10775 },
        [10780] = { space = "world", instanceID = 1220, x = 3793.25, y = 2368.8400878906, z = 491.34600830078, areaID = 10780 },
        [10806] = { space = "world", instanceID = 1220, x = 1797.3499755859, y = 1816.6999511719, z = 298.39599609375, areaID = 10806 },
        [10979] = { space = "world", instanceID = 2222, x = -2623.9799804688, y = 6010.490234375, z = 4115.6899414062, areaID = 10979 },
        [10982] = { space = "world", instanceID = 2222, x = -3387.6999511719, y = 5461.4599609375, z = 4275.7202148438, areaID = 10982 },
        [10989] = { space = "world", instanceID = 2222, x = -1424.75, y = 7952.009765625, z = 4033.5400390625, areaID = 10989 },
        [10990] = { space = "world", instanceID = 2222, x = -1304.6899414062, y = 6367.6499023438, z = 4184.4702148438, areaID = 10990 },
        [10994] = { space = "world", instanceID = 2222, x = -2191.1000976562, y = 7223.6801757812, z = 4240.08984375, areaID = 10994 },
        [10995] = { space = "world", instanceID = 2222, x = -1848.2700195312, y = 5393.16015625, z = 4062.7700195312, areaID = 10995 },
        [11002] = { space = "world", instanceID = 2222, x = -1798.8800048828, y = 5975.6899414062, z = 4125.75, areaID = 11002 },
        [11008] = { space = "world", instanceID = 1718, x = 449.53799438477, y = 54.11629867554, z = -145.40400695801, areaID = 11008 },
        [11009] = { space = "world", instanceID = 1718, x = 359.45001220703, y = -299.94799804688, z = -191.75, areaID = 11009 },
        [11039] = { space = "world", instanceID = 870, x = 460.54000854492, y = -100.46700286865, z = 179.53500366211, areaID = 11039 },
        [11056] = { space = "world", instanceID = 1795, x = 685.71002197266, y = 1492.8100585938, z = 412.34100341797, areaID = 11056 },
        [11381] = { space = "world", instanceID = 2222, x = -2944.080078125, y = -4853.7099609375, z = 6704.2700195312, areaID = 11381 },
        [11394] = { space = "world", instanceID = 1718, x = 1316.75, y = -1130.3199462891, z = -349.43899536133, areaID = 11394 },
        [11411] = { space = "world", instanceID = 2222, x = -2986.0300292969, y = -5855.1899414062, z = 6547.0400390625, areaID = 11411 },
        [11413] = { space = "world", instanceID = 2222, x = -2239.5500488281, y = -5313.1000976562, z = 6541.4599609375, areaID = 11413 },
        [11466] = { space = "world", instanceID = 2222, x = 1974.7399902344, y = -2691.75, z = 3338.0300292969, areaID = 11466 },
        [12248] = { space = "world", instanceID = 2222, x = 3531.6799316406, y = -2766.6398925781, z = 3343.6298828125, areaID = 12248 },
        [12823] = { space = "world", instanceID = 2222, x = 2891.3200683594, y = -3648.0300292969, z = 3321.330078125, areaID = 12823 },
        [13161] = { space = "world", instanceID = 2222, x = -7747.3999023438, y = 657.875, z = 5521.2797851562, areaID = 13161 },
        [13179] = { space = "world", instanceID = 2222, x = 1974.7399902344, y = -2691.75, z = 3338.0300292969, areaID = 13179 },
        [13231] = { space = "world", instanceID = 2222, x = -6821.2299804688, y = 1804.9000244141, z = 5561.2700195312, areaID = 13231 },
        [13305] = { space = "world", instanceID = 2222, x = 1778.3199462891, y = -3039.2900390625, z = 3277.830078125, areaID = 13305 },
        [13317] = { space = "world", instanceID = 2222, x = 3531.6799316406, y = -2766.6398925781, z = 3343.6298828125, areaID = 13317 },
        [13333] = { space = "world", instanceID = 2222, x = 3587.0100097656, y = -1746.5600585938, z = 3225.9299316406, areaID = 13333 },
        [13399] = { space = "world", instanceID = 2222, x = -3316.8500976562, y = -4135.9399414062, z = 6599.4501953125, areaID = 13399 },
        [13437] = { space = "world", instanceID = 2222, x = 4535.1298828125, y = 6706.66015625, z = 4830.240234375, areaID = 13437 },
        [13567] = { space = "world", instanceID = 2222, x = -1837.6600341797, y = -3781.419921875, z = 6578.919921875, areaID = 13567 },
        [13672] = { space = "world", instanceID = 2222, x = -5895.6401367188, y = 4810.740234375, z = 4789.990234375, areaID = 13672 },
        [13690] = { space = "world", instanceID = 2374, x = -3540.5100097656, y = 679.70501708984, z = -44.92200088501, areaID = 13690 },
        [13710] = { space = "world", instanceID = 2444, x = 3407.9499511719, y = 322.64199829102, z = 19.27770042419, areaID = 13710 },
        [13725] = { space = "world", instanceID = 2444, x = 2321.3100585938, y = -533.65301513672, z = 54.45119857788, areaID = 13725 },
        [13728] = { space = "world", instanceID = 2444, x = 1753.25, y = 42.125, z = 312.45300292969, areaID = 13728 },
        [13787] = { space = "world", instanceID = 2374, x = -2813.669921875, y = 174.40600585938, z = -130.99499511719, areaID = 13787 },
        [13794] = { space = "world", instanceID = 2444, x = 2929.669921875, y = -3170.8601074219, z = 338.55999755859, areaID = 13794 },
        [13817] = { space = "world", instanceID = 2444, x = -1125.4200439453, y = -2708.8400878906, z = 1039.3100585938, areaID = 13817 },
        [13820] = { space = "world", instanceID = 2444, x = -1094.8599853516, y = -2180.9399414062, z = 1274.0400390625, areaID = 13820 },
        [13825] = { space = "world", instanceID = 2444, x = -5341.5698242188, y = 1454.6199951172, z = 777.35699462891, areaID = 13825 },
        [13834] = { space = "world", instanceID = 2444, x = -3800.9599609375, y = 404.45098876953, z = 659.10998535156, areaID = 13834 },
        [13835] = { space = "world", instanceID = 2444, x = -2575.580078125, y = 145.8159942627, z = 859.50598144531, areaID = 13835 },
        [13837] = { space = "world", instanceID = 2444, x = -4471.6000976562, y = 4051.169921875, z = 6.60776996613, areaID = 13837 },
        [13859] = { space = "world", instanceID = 2444, x = -5185.1401367188, y = -1414.0300292969, z = 529.34600830078, areaID = 13859 },
        [13888] = { space = "world", instanceID = 2444, x = -2646.1298828125, y = 3410.3100585938, z = 448.60501098633, areaID = 13888 },
        [13896] = { space = "world", instanceID = 2374, x = -2489.4299316406, y = 99.73259735107, z = -86.34929656982, areaID = 13896 },
        [13934] = { space = "world", instanceID = 2444, x = -2771.0600585938, y = -1691.8299560547, z = 967.43200683594, areaID = 13934 },
        [13941] = { space = "world", instanceID = 2444, x = 2337.2800292969, y = 2635.6101074219, z = 383.85000610352, areaID = 13941 },
        [13942] = { space = "world", instanceID = 2444, x = 568.22302246094, y = 882.83801269531, z = 279.1780090332, areaID = 13942 },
        [13957] = { space = "world", instanceID = 2481, x = -3830.1999511719, y = -2399.0200195312, z = 110.98100280762, areaID = 13957 },
        [13965] = { space = "world", instanceID = 2481, x = -3824.9899902344, y = -2609.5200195312, z = 78.75949859619, areaID = 13965 },
        [14010] = { space = "world", instanceID = 2444, x = -1493.5, y = 4564.6098632812, z = 159.78799438477, areaID = 14010 },
        [14089] = { space = "world", instanceID = 2444, x = -3162.3500976562, y = -2953.3798828125, z = 1545.8900146484, areaID = 14089 },
        [14095] = { space = "world", instanceID = 2444, x = 394.64898681641, y = -4186.8901367188, z = 1555.1899414062, areaID = 14095 },
        [14479] = { space = "world", instanceID = 2516, x = -663.99798583984, y = 3296.3798828125, z = 404.32800292969, areaID = 14479 },
        [14524] = { space = "world", instanceID = 2444, x = 652.89599609375, y = 3258.6000976562, z = 1.93669998646, areaID = 14524 },
        [14594] = { space = "world", instanceID = 2444, x = 6308.240234375, y = -2255.7800292969, z = 277.14498901367, areaID = 14594 },
        [14656] = { space = "world", instanceID = 2444, x = 6407.7099609375, y = -2560.2700195312, z = 13.51080036163, areaID = 14656 },
        [14659] = { space = "world", instanceID = 2454, x = -959.29901123047, y = 3140.2299804688, z = 50.34280014038, areaID = 14659 },
        [14690] = { space = "world", instanceID = 2444, x = -61.49829864502, y = 45.75870132446, z = 187.76400756836, areaID = 14690 },
        [14711] = { space = "world", instanceID = 2454, x = -68.65969848633, y = 757.78100585938, z = 82.08010101318, areaID = 14711 },
        [14743] = { space = "world", instanceID = 2444, x = -1593.9799804688, y = 4136.1098632812, z = 391.38900756836, areaID = 14743 },
        [14744] = { space = "world", instanceID = 2454, x = -1549.8399658203, y = 3535.5500488281, z = 220.8869934082, areaID = 14744 },
        [14745] = { space = "world", instanceID = 2454, x = -2068.419921875, y = 3454.7099609375, z = 279.77499389648, areaID = 14745 },
        [14746] = { space = "world", instanceID = 2444, x = -2598.3601074219, y = 3435.7299804688, z = 452.87899780273, areaID = 14746 },
        [14774] = { space = "world", instanceID = 2552, x = 1820.6899414062, y = -879.71899414063, z = 50.22919845581, areaID = 14774 },
        [14794] = { space = "world", instanceID = 2601, x = -2149.5600585938, y = -975.33001708984, z = -1325.1600341797, areaID = 14794 },
        [14837] = { space = "world", instanceID = 2552, x = 2673.6599121094, y = -4099.7299804688, z = 86.27510070801, areaID = 14837 },
        [14848] = { space = "world", instanceID = 2601, x = 1815.4899902344, y = -1522.8900146484, z = -140.91700744629, areaID = 14848 },
        [14918] = { space = "world", instanceID = 2601, x = 3074.3798828125, y = 988.04498291016, z = 516.01000976563, areaID = 14918 },
        [14958] = { space = "world", instanceID = 2601, x = -796.04302978516, y = 876.14398193359, z = -950.17102050781, areaID = 14958 },
        [15034] = { space = "world", instanceID = 2601, x = 1552.8399658203, y = 10.93400001526, z = -49.37860107422, areaID = 15034 },
        [15115] = { space = "world", instanceID = 2444, x = -1715.9699707031, y = 7073.8500976562, z = 198.11399841309, areaID = 15115 },
        [15337] = { space = "world", instanceID = 2601, x = 3074.3798828125, y = 988.04498291016, z = 516.01000976563, areaID = 15337 },
        [15351] = { space = "world", instanceID = 2706, x = -385.97900390625, y = 519.48602294922, z = 0.52693802118, areaID = 15351 },
        [15352] = { space = "world", instanceID = 2706, x = 38.32989883423, y = 153.47599792481, z = -15.26900005341, areaID = 15352 },
        [15363] = { space = "world", instanceID = 2657, x = -2843.1201171875, y = -396.56298828125, z = -1160.1899414062, areaID = 15363 },
        [15364] = { space = "world", instanceID = 2657, x = -2962.4399414062, y = -334.16299438477, z = -1489.2199707031, areaID = 15364 },
        [15366] = { space = "world", instanceID = 2657, x = -3505.7700195312, y = -112.17199707031, z = -1317.5100097656, areaID = 15366 },
        [15367] = { space = "world", instanceID = 2657, x = -3529.8400878906, y = -379.0710144043, z = -1078.8399658203, areaID = 15367 },
        [15370] = { space = "world", instanceID = 2657, x = -3264.0200195312, y = 103.30899810791, z = -1096.0899658203, areaID = 15370 },
        [15462] = { space = "world", instanceID = 2706, x = 576.26702880859, y = 225.82600402832, z = -7.36460018158, areaID = 15462 },
        [15465] = { space = "world", instanceID = 2706, x = -18.04170036316, y = 914.70697021484, z = 0.43435901403, areaID = 15465 },
        [15528] = { space = "world", instanceID = 2601, x = -180.31300354004, y = -4803.2700195312, z = -118.21700286865, areaID = 15528 },
        [15781] = { space = "world", instanceID = 2738, x = -1206.6500244141, y = -217.3390045166, z = 512.68103027344, areaID = 15781 },
        [15782] = { space = "world", instanceID = 2738, x = -289.4049987793, y = 787.75500488281, z = 246.04100036621, areaID = 15782 },
        [15788] = { space = "world", instanceID = 2738, x = -482.05599975586, y = 985.00897216797, z = 271.42599487305, areaID = 15788 },
        [15789] = { space = "world", instanceID = 2738, x = 25.08849906921, y = 365.99499511719, z = 125.8990020752, areaID = 15789 },
        [15795] = { space = "world", instanceID = 2738, x = 509.88198852539, y = -1143.6999511719, z = 8.91738986969, areaID = 15795 },
        [15797] = { space = "world", instanceID = 2738, x = -140.32600402832, y = -570.47900390625, z = -33.05099868774, areaID = 15797 },
        [15803] = { space = "world", instanceID = 2738, x = 2027.4699707031, y = 596.68402099609, z = -109.75900268555, areaID = 15803 },
        [15805] = { space = "world", instanceID = 2738, x = 1964.2399902344, y = 1738.0100097656, z = -277.13598632813, areaID = 15805 },
        [15806] = { space = "world", instanceID = 2738, x = 529.13201904297, y = 999.41101074219, z = 172.07200622559, areaID = 15806 },
        [15826] = { space = "world", instanceID = 2738, x = 562.82098388672, y = -170.86500549316, z = -55.11180114746, areaID = 15826 },
        [15932] = { space = "world", instanceID = 2694, x = -876.85400390625, y = 1176.6300048828, z = 1286.6999511719, areaID = 15932 },
        [15958] = { space = "world", instanceID = 2771, x = 2975.9399414062, y = 250.42900085449, z = -108.19000244141, areaID = 15958 },
        [15969] = { space = "world", instanceID = 0, x = 8583.7998046875, y = -5282.009765625, z = 64.15950012207, areaID = 15969 },
        [16084] = { space = "world", instanceID = 0, x = 8583.7998046875, y = -5282.009765625, z = 64.15950012207, areaID = 16084 },
        [16194] = { space = "world", instanceID = 0, x = 5114.33984375, y = -6473.7998046875, z = 210.31500244141, areaID = 16194 },
        [16202] = { space = "world", instanceID = 0, x = 6916.6401367188, y = -7113.9702148438, z = 229.46699523926, areaID = 16202 },
        [16226] = { space = "world", instanceID = 2736, x = 1769.7800292969, y = -651.52099609375, z = 147.47399902344, areaID = 16226 },
        [16333] = { space = "world", instanceID = 0, x = 8444.3203125, y = -4765.7202148438, z = 49.00099945068, areaID = 16333 },
        [16376] = { space = "world", instanceID = 2735, x = 2679.0200195312, y = -101.6490020752, z = 86.76879882813, areaID = 16376 },
        [16377] = { space = "world", instanceID = 2735, x = 2508.2800292969, y = 881.25, z = 51.5060005188, areaID = 16377 },
        [16378] = { space = "world", instanceID = 2735, x = 3115.5, y = 1191.8599853516, z = 18.50930023193, areaID = 16378 },
        [16418] = { space = "world", instanceID = 0, x = 6286.9799804688, y = -7580.1201171875, z = 141.79200744629, areaID = 16418 },
        [16426] = { space = "world", instanceID = 0, x = 4512.1098632812, y = -2780.0700683594, z = 5.37879991531, areaID = 16426 },
        [16586] = { space = "world", instanceID = 0, x = 3620.580078125, y = -6670.6801757812, z = 327.0419921875, areaID = 16586 },
        [16588] = { space = "world", instanceID = 2735, x = 3344.1899414062, y = 169.87800598145, z = 97.31199645996, areaID = 16588 },
        [16589] = { space = "world", instanceID = 2736, x = 1624.4200439453, y = 206.55900573731, z = 98.93890380859, areaID = 16589 },
        [16649] = { space = "world", instanceID = 2771, x = 2975.9399414062, y = 250.42900085449, z = -108.19000244141, areaID = 16649 },
        [16753] = { space = "world", instanceID = 2736, x = 1067.2900390625, y = -169.33999633789, z = 61.3703994751, areaID = 16753 },
        [16818] = { space = "world", instanceID = 2735, x = 3276.3999023438, y = -499.5539855957, z = 182.34300231934, areaID = 16818 },
        [16920] = { space = "world", instanceID = 3047, x = -4192.1499023438, y = 577.01898193359, z = 40.37160110474, areaID = 16920 },
        [16921] = { space = "world", instanceID = 3047, x = -3848.8200683594, y = 445.94400024414, z = 15.09539985657, areaID = 16921 },
        [16926] = { space = "world", instanceID = 3047, x = -4177.2099609375, y = 410.61801147461, z = 3.0639500618, areaID = 16926 },
        [17060] = { space = "world", instanceID = 3047, x = -4192.1499023438, y = 577.01898193359, z = 40.37160110474, areaID = 17060 },
        [17095] = { space = "world", instanceID = 3075, x = -1586, y = -1917, z = 3, areaID = 17095 },
        [17096] = { space = "world", instanceID = 3075, x = -1519.3499755859, y = -2468.3500976562, z = 2.08999991417, areaID = 17096 },
        [17104] = { space = "world", instanceID = 3075, x = -2180, y = -1709, z = 44, areaID = 17104 },
        [17218] = { space = "world", instanceID = 3047, x = -4169.9799804688, y = 727.62200927734, z = 34.3004989624, areaID = 17218 },
        [17650] = { space = "world", instanceID = 2916, x = 5028.16015625, y = -10316.599609375, z = 6.04624986649, areaID = 17650 },
    },
}, 31)
