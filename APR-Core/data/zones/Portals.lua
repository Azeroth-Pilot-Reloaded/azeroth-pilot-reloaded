--//TODO add and manage druid portals zone

APR.Portals = {}
APR.Portals.Coords = {
    ["Alliance"] = {
        [12] = {
            ["Stormwind"] = { x = -11576.5, y = -4053 },
            ["Exodar"] = { x = 2506.6, y = 9656.3 },
            ["DarkPortal BC"] = { x = 2510.3, y = 9661.5 }
        },
        [13] = {
            ["StormwindPortalRoom"] = { x = 876.7, y = -9015.8 },
            ["Shattrath"] = { x = 943.4, y = -8988.8 },
            ["Exodar"] = { x = 965.2, y = -9005.5 },
            ["DalaranLichKing"] = { x = 951.7, y = -9022.8 },
            ["JadeForestMoP"] = { x = 929.5, y = -9004.8 },
            ["StormshieldWoD"] = { x = 1004.4, y = -9036.6 },
            ["AzsunaLegion"] = { x = 991.9, y = -9054.2 },
            ["BoralusBFA"] = { x = 876.7, y = -9098.1 },
            ["Ashran"] = { x = 888.1, y = -9061.7 },
            ["Oribos"] = { x = 895.9, y = -9095 },
            ["Valdrakken"] = { x = 875.2, y = -9079.1 },
            ["Dornogal"] = { x = 1014.2, y = -9070.8 },
            ["DarkPortal Talk"] = { x = 869.6, y = -9007.7 },
            ["DarkPortal"] = { x = -3207.5, y = -11902.7 },
            ["DalaranLegion"] = { x = 642.3, y = -8790.2 },
            ["HomeToStormwind"] = { x = -159.8, y = 3804.4 },
            ["StormwindToHome"] = { x = 907.4, y = -9076.4 },
            ["Bel'ameth"] = { x = 971.5, y = -9126 },

            --Order Hall
            ["Paladin To Dalaran"] = { x = -5319.9, y = 2376.1 },
        },
        [101] = { ["Stormwind"] = { x = 5388.7, y = -1893.5 }, ["Stormwind DarkPortal"] = { x = 931.9, y = -274.6 } },
        [113] = { ["Stormwind"] = { x = 720.2, y = 5719.5 } },
        [424] = {
            ["Stormwind Jade Forest"] = { x = -1776, y = -311.3 },
            ["Stormwind Blossom"] = { x = 176.9, y = 828.6 },
            ["Isle of Thunder"] = { x = 4222, y = 1928.8 },
            ["Townlong Steppes"] = { x = 4977.8, y = 6122.6, }
        },
        [572] = { ["Stormwind"] = { x = -4042.4, y = 3735.5 } },
        [619] = {
            ["Stormwind"] = { x = 4548.5, y = -929.5 },
            ["Stormwind AzsunaLegion"] = { x = 6756.2, y = -13.4 },
            ["Stormwind Telogrus Rift"] = { x = 3331.6, y = 2149.6 },
            ["Stormwind Vindicaar"] = { x = 1469.5, y = 499.6 },
            ["Remix Dalaran to Bazar"] = { x = 4280.1, y = -805.5 },  -- temp fix until next update
            ["Remix Bazar to Dalaran"] = { x = 4490.5, y = -1208.8 }, -- temp fix until next update

            --Order Hall
            ["Demon Hunter To Order Hall"] = { x = 4066, y = -963.9 },
            ["Demon Hunter To Dalaran"] = { x = 1414.6, y = 1665.2 },
            ["Paladin To Order Hall"] = { x = 4604.7, y = -967.1 },
            ["Mage To Dalaran"] = { x = 4707.6, y = -945.3 },
            ["Warrior To Dalaran"] = { x = 72293.2, y = 1083.2 },
            ["Warrior To Order Hall"] = { x = 4254.6, y = -841.9 },
        },
        [876] = {
            ["Stormwind"] = { x = -524.3, y = 1133.5 },
            ["Ironforge"] = { x = -537.9, y = 1149.2 },
            ["Exodar"] = { x = -528.8, y = 1153.4 },
            ["Silithus"] = { x = -454.5, y = 1037.9 },
            ["ArathiHighlands"] = { x = -516.5, y = 1143 },
            ["Zuldazar"] = { x = -485.2, y = 1015.2 },
            ["Nazmir"] = { x = -485.2, y = 1015.2 },
            ["Vol'dun"] = { x = -485.2, y = 1015.2 }
        },
        [875] = {
            ["Zuldazar"] = { x = 2286.1, y = -2627.7 },
            ["Nazmir"] = { x = 188, y = 2124.9 },
            ["Vol'dun"] = { x = 4312, y = 2804.5 }
        },
        [1550] = { ["Stormwind"] = { x = 1538.4, y = -1808.8 }, ["OribosInMaldraxxus"] = { x = -2517.7, y = 2573.5 } },
        [1978] = {
            ["Stormwind"] = { x = -1066.8, y = 246.5 },
            ["Bel'ameth to Stormwind"] = { x = 6852.9, y = -1934.3 },
        },
        [2274] = {
            ["Stormwind"] = { x = -2397.7, y = 2982.1 },

            -- isle of dorn
            ["RingingDeepsTunnel"] = { x = -2413.1, y = 2462.7 },
            ["RingingDeepsElevator"] = { x = -4093.8, y = 3375.0 },
            ["AzjKahetPortal"] = { x = -2869.2, y = 2567.7 },
            ["EnterUndermineTP"] = { x = -2633.4, y = 2595.4 },
            ["K'areshPortal"] = { x = -2379.6, y = 2982.6 },

            -- Ringing Deeps
            ["IsleOfDornTunnel"] = { x = -2250.7, y = 2430.6 },
            ["IsleOfDornElevator"] = { x = -3199.5, y = 1686.2 },
            ["HallowFallGate"] = { x = -2192.5, y = 2622.8 },
            ["AzjKahetEast"] = { x = -2810.5, y = 601.1 },
            ["EnterUndermine"] = { x = -4913.4, y = 310.2 },
            ["ExitUndermine"] = { x = 1062, y = 3.3 },
            ["ExitUndermineTP"] = { x = 846.9, y = -42.6 },

            -- hallowfall
            ["RingingDeepsGate"] = { x = -2254.7, y = 2643.9 },
            ["AzjKahetNothEast"] = { x = -1729.7, y = 1381.9 },
            ["AzjKahetNothWest"] = { x = 831.8, y = 234.8 },

            --Azj Kahet
            ["RingingDeepsSouth"] = { x = -3010.1, y = 633.9 },
            ["HallowFallNothEast"] = { x = -1617.4, y = 1474.1 },
            ["HallowFallNothWest"] = { x = 887.5, y = 373.4 },
            ["IsleOfDornPortal"] = { x = -1481.4, y = -360.8 },
            --K'aresh
            ["DornogalFromK'areshPortal"] = { x = -500, y = -1650.3 },
        },

    },
    ["Horde"] = {
        [12] = {
            ["STVZep"] = { x = -4419.8, y = 1872 },
            ["Zuldazar"] = { x = -4511.8, y = 1445 },
            ["JadeForest"] = { x = -4505, y = 1417.8 },
            ["DalaranLichKing"] = { x = -4484.9, y = 1423.8 },
            ["Undercity"] = { x = -4388.8, y = 1842.7 },
            ["Silvermoon"] = { x = -4457.2, y = 1438.9 },
            ["Shattrath"] = { x = -4505.3, y = 1424.9 },
            ["TolBarad"] = { x = -4331.7, y = 2031.3 },
            ["OrgrimmarFromTolBarad"] = { x = 5283.4, y = -1240.5 },
            ["Uldum"] = { x = -4359.2, y = 2041.1 },
            ["Hyjal"] = { x = -4391.9, y = 2044.1 },
            ["TwilightHighlands"] = { x = -4380.2, y = 2030 },
            ["Deepholm"] = { x = -4390.5, y = 2065.2 },
            ["WarspearWoD"] = { x = -4466.8, y = 1422.3 },
            ["DarkPortal Talk"] = { x = -4500.3, y = 1434.8 },
            ["DalaranLegion"] = { x = -4440.7, y = 1598.6 },
            ["AzsunaLegion"] = { x = -4501.3, y = 1462.6 },
            ["Oribos"] = { x = -4519.3, y = 1466.5 },
            ["Valdrakken"] = { x = -4499.9, y = 1472.5 },
            ["Dornogal"] = { x = -4525, y = 1427.4 },
            ["HomeToOgrimmar"] = { x = 189.0, y = 2089.9 },
            ["OgrimmarToHome"] = { x = -4530.8, y = 1448.6 }
        },
        [13] = {
            ["Orgrimmar"] = { x = 289.3, y = 2070.5 },
            ["Orgrimmar Silvermoon"] = { x = -7109.4, y = 10002.7 },
            ["Howling Fjord"] = { x = 362.8, y = 2062.7 },
            ["DarkPortal"] = { x = -3207.5, y = -11902.7 },
            ["DarkPortal BC"] = { x = 55.8, y = 1768.7 },

            --Order Hall
            ["Paladin To Dalaran"] = { x = -5319.9, y = 2376.1 },
        },
        [101] = { ["Orgrimmar"] = { x = 5394.1, y = -1898.9 }, ["Orgrimmar DarkPortal"] = { x = 932.3, y = -222.8 } },
        [113] = { ["Orgrimmar"] = { x = 593.7, y = 5926.2 }, },
        [424] = {
            ["Orgrimmar Jade Forest"] = { x = -539.3, y = 3000.4 },
            ["Orgrimmar Blossom"] = { x = 873.10003662109, y = 1735 },
            ["Isle of Thunder"] = { x = 4170.20, y = 1747.5 },
            ["Townlong Steppes"] = { x = 4170.1000976562, y = 1747.5, }
        },
        [572] = { ["Orgrimmar"] = { x = -4074.7, y = 5267 } },
        [619] = {
            ["Orgrimmar"] = { x = 4418.6, y = -714.8 },
            ["Orgrimmar AzsunaLegion"] = { x = 6755.1, y = -8.5 },
            ["Orgrimmar Suramar"] = { x = 3428.6, y = 213.6 },
            ["Orgrimmar Highmountain"] = { x = 4415, y = 4082.4 },
            ["Remix Dalaran to Bazar"] = { x = 4280.1, y = -805.5 },  -- temp fix until next update
            ["Remix Bazar to Dalaran"] = { x = 4490.5, y = -1208.8 }, -- temp fix until next update

            -- Order Hall
            ["Demon Hunter To Order Hall"] = { x = 4066, y = -963.9 },
            ["Demon Hunter To Dalaran"] = { x = 1414.6, y = 1665.2 },
            ["Paladin To Order Hall"] = { x = 4363.6, y = -657.3 },
            ["Mage To Dalaran"] = { x = 4707.6, y = -945.3 },
            ["Warrior To Dalaran"] = { x = 72293.2, y = 1083.2 },
            ["Warrior To Order Hall"] = { x = 4254.6, y = -841.9 },

        },
        [876] = {
            ["DrustvarSail"] = { x = 750.6, y = -1123 },
            ["StormsongValleySail"] = { x = 394.8, y = 4238.3 },
            ["TiragardeSoundSail"] = { x = -1527.4, y = -218.5 }
        },
        [875] = {
            ["Orgrimmar"] = { x = 750.6, y = -1123 },
            ["Orgrimmar Dazaralor"] = { x = 805.7, y = -1085.1 },
            ["Drustvar"] = { x = 762.9, y = -2173.9 },
            ["StormsongValley"] = { x = 762.9, y = -2173.9 },
            ["TiragardeSound"] = { x = 762.9, y = -2173.9 }
        },
        [1550] = { ["Orgrimmar"] = { x = 1539.3, y = -1859.5 }, ["OribosInMaldraxxus"] = { x = -2517.7, y = 2573.5 } },
        [1978] = { ["Orgrimmar"] = { x = -1023, y = 278 } },
        [2274] = {
            ["Orgrimmar"] = { x = -2334.7, y = 2919.1 },

            -- isle of dorn
            ["RingingDeepsTunnel"] = { x = -2413.1, y = 2462.7 },
            ["RingingDeepsElevator"] = { x = -4093.8, y = 3375.0 },
            ["AzjKahetPortal"] = { x = -2869.2, y = 2567.7 },
            ["EnterUndermineTP"] = { x = -2633.4, y = 2595.4 },
            ["K'areshPortal"] = { x = -2379.6, y = 2982.6 },


            -- Ringing Deeps
            ["IsleOfDornTunnel"] = { x = -2250.7, y = 2430.6 },
            ["IsleOfDornElevator"] = { x = -3199.5, y = 1686.2 },
            ["HallowFallGate"] = { x = -2192.5, y = 2622.8 },
            ["AzjKahetEast"] = { x = -2810.5, y = 601.1 },
            ["EnterUndermine"] = { x = -4913.4, y = 310.2 },
            ["ExitUndermine"] = { x = 1062, y = 3.3 },
            ["ExitUndermineTP"] = { x = 846.9, y = -42.6 },

            -- hallowfall
            ["RingingDeepsGate"] = { x = -2254.7, y = 2643.9 },
            ["AzjKahetNothEast"] = { x = -1729.7, y = 1381.9 },
            ["AzjKahetNothWest"] = { x = 831.8, y = 234.8 },

            --Azj Kahet
            ["RingingDeepsSouth"] = { x = -3010.1, y = 633.9 },
            ["HallowFallNothEast"] = { x = -1617.4, y = 1474.1 },
            ["HallowFallNothWest"] = { x = 887.5, y = 373.4 },
            ["IsleOfDornPortal"] = { x = -1481.4, y = -360.8 },

            --K'aresh
            ["DornogalFromK'areshPortal"] = { x = -500, y = -1650.3 },
        },
    }
}

APR.Portals.SwitchCont = {
    ["Alliance"] = {
        { continent = 13,   nextContinent = 12,   nextZone = 103,  portalKey = "Exodar",                  closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 101,  nextZone = 111,  portalKey = "Shattrath",               closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 113,  nextZone = 125,  portalKey = "DalaranLichKing",         closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 424,  nextZone = 371,  portalKey = "JadeForestMoP",           closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 12,   nextZone = 17,   portalKey = "DarkPortal Talk",         closestTaxiNode = "Stormwind, Elwynn",                               extraText = "TALK_TO" },
        { continent = 13,   nextContinent = 572,  nextZone = 577,  portalKey = "DarkPortal Talk",         closestTaxiNode = "Stormwind, Elwynn",                               extraText = "TALK_TO" },
        { continent = 13,   nextContinent = 572,  nextZone = 577,  portalKey = "DarkPortal" },
        { continent = 13,   nextContinent = 572,  nextZone = 622,  portalKey = "StormshieldWoD",          closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 619,  nextZone = 630,  portalKey = "AzsunaLegion",            closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 876,  nextZone = 1161, portalKey = "BoralusBFA",              closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 1550, nextZone = 1670, portalKey = "Oribos",                  closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 1978, nextZone = 2112, portalKey = "Valdrakken",              closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 1978, nextZone = 2239, portalKey = "Bel'ameth",               closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 2274, nextZone = 2248, portalKey = "Dornogal",                closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 619,  nextZone = 627,  portalKey = "DalaranLegion",           closestTaxiNode = "Stormwind, Elwynn" },
        { continent = 13,   nextContinent = 619,  nextZone = 627,  portalKey = "Paladin To Dalaran" },
        { continent = 13,   nextContinent = 619,  nextZone = 627,  portalKey = "Paladin To Dalaran" },

        { continent = 12,   nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "The Exodar" },
        { continent = 12,   nextContinent = 13,   nextZone = 84,   portalKey = "Exodar",                  closestTaxiNode = "Darnassus, Teldrassil" },
        { continent = 12,   nextContinent = 101,  nextZone = 530,  portalKey = "DarkPortal BC" },

        { continent = 101,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Shattrath, Terokkar Forest" },
        { continent = 101,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind DarkPortal",    closestTaxiNode = "Hellfire Peninsula, The Dark Portal" },

        { continent = 113,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Dalaran" },

        { continent = 424,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind Blossom",       closestTaxiNode = "Shrine of Seven Stars, Vale of Eternal Blossoms", extraText = "UPSTAIRS_TO" },
        { continent = 424,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind Jade Forest",   closestTaxiNode = "Paw'Don Village, Jade Forest" },

        { continent = 572,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Stormshield (Alliance), Ashran" },

        { continent = 619,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Dalaran" },
        { continent = 619,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind AzsunaLegion", },
        { continent = 619,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind Telogrus Rift", },
        { continent = 619,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind Vindicaar", },
        { continent = 619,  nextContinent = 13,   nextZone = 23,   portalKey = "Paladin To Order Hall" },

        { continent = 875,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind", },
        { continent = 876,  nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Tradewinds Market, Tiragarde Sound" },

        { continent = 1550, nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Oribos" },
        { continent = 1978, nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Valdrakken, Thaldraszus" },
        { continent = 1978, nextContinent = 13,   nextZone = 84,   portalKey = "Bel'ameth to Stormwind" },

        { continent = 2274, nextContinent = 13,   nextZone = 84,   portalKey = "Stormwind",               closestTaxiNode = "Dornogal, Isle of Dorn", },

    },
    ["Horde"] = {
        { continent = 12,   nextContinent = 13,   nextZone = 224,  portalKey = "STVZep",                 closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "USE_ZEPPELIN_TO" },
        { continent = 12,   nextContinent = 13,   nextZone = 90,   portalKey = "Undercity",              closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 101,  nextZone = 111,  portalKey = "Shattrath",              closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "DOWNSTAIRS_TO" },
        { continent = 12,   nextContinent = 113,  nextZone = 126,  portalKey = "DalaranLichKing",        closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 424,  nextZone = 371,  portalKey = "JadeForest",             closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 572,  nextZone = 577,  portalKey = "DarkPortal Talk",        closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "TALK_NPC" },
        { continent = 12,   nextContinent = 572,  nextZone = 624,  portalKey = "WarspearWoD",            closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "DOWNSTAIRS_TO" },
        { continent = 12,   nextContinent = 875,  nextZone = 862,  portalKey = "Zuldazar",               closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "DOWNSTAIRS_TO" },
        { continent = 12,   nextContinent = 1550, nextZone = 1670, portalKey = "Oribos",                 closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 1978, nextZone = 2112, portalKey = "Valdrakken",             closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 2274, nextZone = 2248, portalKey = "Dornogal",               closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 619,  nextZone = 627,  portalKey = "DalaranLegion",          closestTaxiNode = "Orgrimmar, Durotar" },
        { continent = 12,   nextContinent = 619,  nextZone = 630,  portalKey = "AzsunaLegion",           closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "DOWNSTAIRS_TO" },
        { continent = 12,   nextContinent = 13,   nextZone = 110,  portalKey = "Silvermoon",             closestTaxiNode = "Orgrimmar, Durotar",                            extraText = "DOWNSTAIRS_TO" },

        { continent = 13,   nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar" },
        { continent = 13,   nextContinent = 572,  nextZone = 577,  portalKey = "DarkPortal" },
        { continent = 13,   nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Silvermoon",   closestTaxiNode = "Silvermoon City" },
        { continent = 13,   nextContinent = 101,  nextZone = 530,  portalKey = "DarkPortal BC" },
        { continent = 13,   nextContinent = 113,  nextZone = 571,  portalKey = "Howling Fjord" },
        { continent = 13,   nextContinent = 619,  nextZone = 627,  portalKey = "Paladin To Dalaran" },

        { continent = 101,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Shattrath, Terokkar Forest" },
        { continent = 101,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar DarkPortal",   closestTaxiNode = "Hellfire Peninsula, The Dark Portal" },

        { continent = 113,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Dalaran" },

        { continent = 424,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Blossom",      closestTaxiNode = "Shrine of Two Moons, Vale of Eternal Blossoms", extraText = "UPSTAIRS_TO" },
        { continent = 424,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Jade Forest",  closestTaxiNode = "Honeydew Village, Jade Forest" },

        { continent = 572,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Warspear, Ashran" },

        { continent = 619,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Dalaran" },
        { continent = 619,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Suramar", },
        { continent = 619,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar AzsunaLegion", },
        { continent = 619,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Highmountain", },
        { continent = 619,  nextContinent = 13,   nextZone = 23,   portalKey = "Paladin To Order Hall" },


        { continent = 875,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Port of Zandalar, Zuldazar" },
        { continent = 875,  nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar Dazaralor", },

        { continent = 1550, nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Oribos" },
        { continent = 1978, nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Valdrakken, Thaldraszus" },

        { continent = 875,  nextContinent = 876,  nextZone = 876,  portalKey = "Drustvar",               closestTaxiNode = "Port of Zandalar, Zuldazar",                    extraText = "SAIL_TO" },
        { continent = 875,  nextContinent = 876,  nextZone = 942,  portalKey = "StormsongValley",        closestTaxiNode = "Port of Zandalar, Zuldazar",                    extraText = "SAIL_TO" },
        { continent = 875,  nextContinent = 876,  nextZone = 895,  portalKey = "TiragardeSound",         closestTaxiNode = "Port of Zandalar, Zuldazar",                    extraText = "SAIL_TO" },

        { continent = 1550, nextContinent = 1550, nextZone = 1536, portalKey = "OribosInMaldraxxus",     closestTaxiNode = "Theater of Pain, Maldraxxus" },

        { continent = 2274, nextContinent = 12,   nextZone = 85,   portalKey = "Orgrimmar",              closestTaxiNode = "Dornogal, Isle of Dorn", },
    },
}

APR.Portals.SwitchZones = {
    ["Alliance"] = {
        { continent = 12,   nextContinent = 12,   nextZone = 103,  portalKey = "Exodar" },

        { continent = 13,   nextContinent = 13,   nextZone = 84,   portalKey = "HomeToStormwind" },
        { continent = 13,   nextContinent = 13,   nextZone = 2352, portalKey = "StormwindToHome" },

        { continent = 424,  nextContinent = 424,  nextZone = 504,  portalKey = "Isle of Thunder", },
        { continent = 424,  nextContinent = 424,  nextZone = 388,  portalKey = "Townlong Steppes", },

        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Mage To Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 619,  portalKey = "Remix Dalaran to Bazar", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Remix Bazar to Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 720,  portalKey = "Demon Hunter To Order Hall", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Demon Hunter To Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Warrior To Dalaran",         extraText = "TALK_TO" },
        { continent = 619,  nextContinent = 619,  nextZone = 695,  portalKey = "Warrior To Order Hall",      extraText = "TALK_TO" },

        { continent = 875,  nextContinent = 875,  nextZone = 862,  portalKey = "Zuldazar",                   closestTaxiNode = "Xibala, Zuldazar",                   extraText = "TALK_TO" },
        { continent = 875,  nextContinent = 875,  nextZone = 863,  portalKey = "Nazmir",                     closestTaxiNode = "Fort Victory, Nazmir",               extraText = "TALK_TO" },
        { continent = 875,  nextContinent = 875,  nextZone = 864,  portalKey = "Vol'dun",                    closestTaxiNode = "Shatterstone Harbor, Vol'dun",       extraText = "TALK_TO" },
        { continent = 876,  nextContinent = 875,  nextZone = 862,  portalKey = "Zuldazar",                   closestTaxiNode = "Tradewinds Market, Tiragarde Sound", extraText = "SAIL_TO" },
        { continent = 876,  nextContinent = 875,  nextZone = 863,  portalKey = "Nazmir",                     closestTaxiNode = "Tradewinds Market, Tiragarde Sound", extraText = "SAIL_TO" },
        { continent = 876,  nextContinent = 875,  nextZone = 864,  portalKey = "Vol'dun",                    closestTaxiNode = "Tradewinds Market, Tiragarde Sound", extraText = "SAIL_TO" },
        { continent = 876,  nextContinent = 875,  nextZone = 864,  portalKey = "Vol'dun",                    closestTaxiNode = "Tradewinds Market, Tiragarde Sound", extraText = "SAIL_TO" },

        -- Isle of dorn
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornTunnel",           extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornElevator",         extraText = "USE_ELEVATOR" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornPortal" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "EnterUndermine",             extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "ExitUndermineTP",            extraText = "USE_TELEPORT" },
        { continent = 2274, nextContinent = 2274, nextZone = 2371, portalKey = "K'areshPortal" },


        -- Ringing Deeps
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsTunnel",         extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsElevator",       extraText = "USE_ELEVATOR" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsGate",           extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsSouth",          extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2346, portalKey = "EnterUndermine",             extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "ExitUndermine",              extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "EnterUndermineTP",           extraText = "USE_TELEPORT" },
        -- Hallowfall
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "RingingDeepsTunnel",         extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallGate",             extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallNothEast",         extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallNothWest",         extraText = "GO_TO" },
        --Azj Kahet
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetPortal",             closestTaxiNode = "Dornogal, Isle of Dorn", },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetEast",               extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetNothEast",           extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetNothWest",           extraText = "GO_TO" },

        -- K'aresh
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "DornogalFromK'areshPortal" },

    },
    ["Horde"] = {
        { continent = 12,   nextContinent = 12,   nextZone = 17,   portalKey = "DarkPortal Talk",            closestTaxiNode = "Orgrimmar, Durotar",              extraText = "TALK_NPC" },
        { continent = 12,   nextContinent = 12,   nextZone = 85,   portalKey = "HomeToOgrimmar", },
        { continent = 12,   nextContinent = 12,   nextZone = 2351, portalKey = "OgrimmarToHome", },

        { continent = 424,  nextContinent = 424,  nextZone = 388,  portalKey = "Townlong Steppes", },
        { continent = 424,  nextContinent = 424,  nextZone = 504,  portalKey = "Isle of Thunder", },

        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Mage To Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 619,  portalKey = "Remix Dalaran to Bazar", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Remix Bazar to Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 720,  portalKey = "Demon Hunter To Order Hall", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Demon Hunter To Dalaran", },
        { continent = 619,  nextContinent = 619,  nextZone = 627,  portalKey = "Warrior To Dalaran",         extraText = "TALK_TO" },
        { continent = 619,  nextContinent = 619,  nextZone = 695,  portalKey = "Warrior To Order Hall",      extraText = "TALK_TO" },

        { continent = 876,  nextContinent = 876,  nextZone = 896,  portalKey = "DrustvarSail",               closestTaxiNode = "Anyport, Drustvar",               extraText = "TALK_TO" },
        { continent = 876,  nextContinent = 876,  nextZone = 942,  portalKey = "StormsongValleySail",        closestTaxiNode = "Warfang Hold, Stormsong Valley",  extraText = "TALK_TO" },
        { continent = 876,  nextContinent = 876,  nextZone = 895,  portalKey = "TiragardeSoundSail",         closestTaxiNode = "Plunder Harbor, Tiragarde Sound", extraText = "TALK_TO" },

        -- Isle of dorn
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornTunnel",           extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornElevator",         extraText = "USE_ELEVATOR" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "IsleOfDornPortal" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "EnterUndermine",             extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "ExitUndermineTP",            extraText = "USE_TELEPORT" },
        { continent = 2274, nextContinent = 2274, nextZone = 2371, portalKey = "K'areshPortal" },


        -- Ringing Deeps
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsTunnel",         extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsElevator",       extraText = "USE_ELEVATOR" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsGate",           extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "RingingDeepsSouth",          extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2346, portalKey = "EnterUndermine",             extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "ExitUndermine",              extraText = "TALK_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2214, portalKey = "EnterUndermineTP",           extraText = "USE_TELEPORT" },

        -- Hallowfall
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "RingingDeepsTunnel",         extraText = "FOLLOW_TUNNEL_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallGate",             extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallNothEast",         extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2215, portalKey = "HallowFallNothWest",         extraText = "GO_TO" },
        --Azj Kahet
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetPortal",             closestTaxiNode = "Dornogal, Isle of Dorn", },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetEast",               extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetNothEast",           extraText = "GO_TO" },
        { continent = 2274, nextContinent = 2274, nextZone = 2255, portalKey = "AzjKahetNothWest",           extraText = "GO_TO" },
        -- K'aresh
        { continent = 2274, nextContinent = 2274, nextZone = 2248, portalKey = "DornogalFromK'areshPortal" },
    }
}

APR.Portals.Spells = {
    --MAGE
    { nextContinent = 13,   nextZone = 84,   coords = { x = 917.7, y = -9041.0 },    spellID = 3561 },   -- Stormwind
    { nextContinent = 13,   nextZone = 87,   coords = { x = -915.3, y = -4613.7 },   spellID = 3562 },   --Ironforge
    { nextContinent = 13,   nextZone = 2070, coords = { x = -101.7, y = 1948.7 },    spellID = 3563 },   -- Undercity
    { nextContinent = 12,   nextZone = 62,   coords = { x = 46.2, y = 7415.1 },      spellID = 3565 },   --Darnassus
    { nextContinent = 12,   nextZone = 88,   coords = { x = 284.8, y = -967.4 },     spellID = 3566 },   --Thunder Bluff
    { nextContinent = 12,   nextZone = 85,   coords = { x = -4499.6, y = 1445.2 },   spellID = 3567 },   --Orgrimmar
    { nextContinent = 12,   nextZone = 103,  coords = { x = -11569.6, y = -4031.2 }, spellID = 32271 },  -- Exodar
    { nextContinent = 13,   nextZone = 110,  coords = { x = -7106.6, y = 9998.5 },   spellID = 32272 },  --Silvermoon
    { nextContinent = 101,  nextZone = 111,  coords = { x = 5417, y = -1824.3 },     spellID = 33690 },  -- Shattrath
    { nextContinent = 101,  nextZone = 111,  coords = { x = 5442.9, y = -1902.5 },   spellID = 35715 },  --Shattrath
    { nextContinent = 13,   nextZone = 51,   coords = { x = -3331.5, y = -10469.0 }, spellID = 49358 },  -- Stonard
    { nextContinent = 12,   nextZone = 70,   coords = { x = -4440.2, y = -3748.1 },  spellID = 49359 },  -- Theramore
    { nextContinent = 113,  nextZone = 127,  coords = { x = 588.4, y = 5807.8 },     spellID = 53140 },  -- Dalaran (WotLK)
    { nextContinent = 13,   nextZone = 245,  coords = { x = 1058.7, y = -369.2 },    spellID = 88342 },  -- Tol Barad
    { nextContinent = 13,   nextZone = 245,  coords = { x = 1387.6, y = -603.7 },    spellID = 88344 },  -- Tol Barad
    { nextContinent = 424,  nextZone = 390,  coords = { x = 294.9, y = 917.6 },      spellID = 132621 }, --Vale of Eternal Blossoms
    { nextContinent = 424,  nextZone = 390,  coords = { x = 897.8, y = 1579.7 },     spellID = 132627 }, --Vale of Eternal Blossoms
    { nextContinent = 572,  nextZone = 588,  coords = { x = -4060.3, y = 5267.8 },   spellID = 176242 }, -- Warspear
    { nextContinent = 572,  nextZone = 588,  coords = { x = -4055.9, y = 3744.3 },   spellID = 176248 }, -- Stormshield
    { nextContinent = 619,  nextZone = 734,  coords = { x = 4706.4, y = -935.2 },    spellID = 193759 }, --Hall of the Guardian
    { nextContinent = 619,  nextZone = 627,  coords = { x = 4371.8, y = -828.7 },    spellID = 224869 }, -- Dalaran (Legion)
    { nextContinent = 876,  nextZone = 895,  coords = { x = -538.6, y = 1137.4 },    spellID = 281403 }, -- Boralus
    { nextContinent = 875,  nextZone = 862,  coords = { x = 774.2, y = -1129.2 },    spellID = 281404 }, -- Dazaralor
    { nextContinent = 1550, nextZone = 1670, coords = { x = 1542.3, y = -1834.2 },   spellID = 344587 }, -- Oribos
    { nextContinent = 1978, nextZone = 2025, coords = { x = -1048.2, y = 266.7 },    spellID = 395277 }, -- Valdrakken
    { nextContinent = 2274, nextZone = 2248, coords = { x = -2400.3, y = 2915.7 },   spellID = 446540 }, -- Dornogal

    --DRUID
    { nextContinent = 12,   nextZone = 80,   coords = { x = -2679.8, y = 7995.6 },   spellID = 18960 },  -- Moonglade
    { nextContinent = 619,  nextZone = 641,  coords = { x = 1582.1, y = 1633.0 },    spellID = 193753 }, -- Emerald Dreamway

    --DK
    { nextContinent = 13,   nextZone = 23,   coords = { x = -5662.4, y = 2359.6 },   spellID = 50977 }, -- Death Gate (Ebon Hold)


}

APR.Portals.Items = { -- WIP
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 18984 }, -- Dimensional Ripper - Everlook
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 18986 }, -- Ultrasafe Transporter: Gadgetzan
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 22631 }, -- Atiesh, Greatstaff of the Guardian
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 30542 }, -- Dimensional Ripper - Area 52
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 30544 }, -- Ultrasafe Transporter: Toshley's Station
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 32757 }, -- Blessed Medallion of Karabor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 46874 }, -- Argent Crusader's Tabard
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 40585 }, -- Signet of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 40586 }, -- Band of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 44934 }, -- Loop of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 44935 }, -- Ring of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 45688 }, -- Inscribed Band of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 45689 }, -- Inscribed Loop of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 45690 }, -- Inscribed Ring of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 45691 }, -- Inscribed Signet of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 48954 }, -- Etched Band of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 48955 }, -- Etched Loop of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 48956 }, -- Etched Ring of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 48957 }, -- Etched Signet of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 50287 }, -- Boots of the Bay
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 51557 }, -- Runed Signet of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 51558 }, -- Runed Loop of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 51559 }, -- Runed Ring of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 51560 }, -- Runed Band of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 52251 }, -- Jaina's Locket
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 58487 }, -- Potion of Deepholm
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 63206 }, -- Wrap of Unity
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 63352 }, -- Shroud of Cooperation
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 65360 }, -- Cloak of Coordination
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 63207 }, -- Wrap of Unity
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 63353 }, -- Shroud of Cooperation
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 65274 }, -- Cloak of Coordination
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 103678 }, -- Time-Lost Artifact
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 95567 }, -- Kirin Tor Beacon
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 95568 }, -- Sunreaver Beacon
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 110560 }, -- Garrison Hearthstone
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 110560 }, -- Garrison Hearthstone
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 139599 }, -- Empowered Ring of the Kirin Tor
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 140192 }, -- Dalaran Hearthstone
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 142469 }, -- Violet Seal of the Grand Magus
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 166560 }, -- Captain's Signet of Command
    -- { nextContinent = 0, nextZone = 0, coords = { x = 0, y =0 }, itemID = 166559 }, -- Commander's Signet of Battle
}
