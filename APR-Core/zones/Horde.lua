if (APR.Faction == "Horde") then
    APR.QuestStepListListingZone = {
        ["01-10 Orc Start"] = 1,
        ["01-10 Troll Start"] = 1,
        ["01-10 Tauren Start"] = 7,
        ["01-10 Scourge Start"] = 18,
        ["01-10 Blood Elf Start"] = 94,
        ["01-30 Goblin Start (Kezan)"] = 194,
        ["01-30 Goblin Start (Lost Isles)"] = 174,
        ["Demon Hunter Start"] = 672,
        ["01-10 Exile's Reach"] = 1409,
        ["01-30 Durotar (Full)"] = 1,
        ["Death Knight Start"] = 23,
        ["10-30 Northern Barrens"] = 10,
        ["10-30 Southern Barrens"] = 199,
        ["SL - Intro"] = 85,
        ["SL01 - The Maw"] = 1648,
        ["SL02 - Oribos"] = 1670,
        ["SL03 - Bastion"] = 1533,
        ["SL04 - Oribos"] = 1670,
        ["SL05 - Maldraxxus"] = 1536,
        ["SL06 - Oribos"] = 1670,
        ["SL07 - The Maw"] = 1543,
        ["SL08 - Oribos"] = 1670,
        ["SL09 - Maldraxxus"] = 1536,
        ["SL10 - Oribos"] = 1670,
        ["SL11 - Ardenweald"] = 1565,
        ["SL12 - Oribos"] = 1670,
        ["SL13 - Revendreth"] = 1525,
        ["SL14 - The Maw"] = 1543,
        ["SL15 - Revendreth"] = 1525,
        ["SL16 - Oribos"] = 1670,
        ["WOD01 - Orgrimmar"] = 85,
        ["WOD02 - Tanaan Jungle"] = 577,
        ["WOD03 - Frostfire Ridge"] = 525,
        ["WOD04 - Gorgrond"] = 543,
        ["WOD05 - Talador"] = 535,
        ["WOD06 - Spires of Arak"] = 542,
        ["WOD07 - Nagrand"] = 550,
        ["Legion - Azsuna"] = 630,
        ["Legion - Val'Sharah"] = 641,
        ["Legion - Stormheim"] = 634,
        ["BFA01 - Intro"] = 85,
        ["BFA02 - Intro"] = 862,
        ["BFA03 - Zuldazar"] = 862,
        ["BFA04 - Nazmir"] = 863,
        ["BFA05 - Naz-end Vol-begin"] = 862,
        ["BFA06 - Vol'dun"] = 864,
        ["Silverpine Forest"] = 21,
        ["Silverpine Forest 2"] = 217,
        ["Silverpine Forest 3"] = 21,
        ["Silverpine Forest 4"] = 25,
        ["Silverpine Forest 5"] = 21,
        ["WIP - Hillsbrad Foothills"] = 25,
        ["WIP - Western Plaguelands"] = 22,
        ["SL - StoryMode Only"] = 1670,
        ["DF01/02 - Dragonflight Orgrimmar/Durotar"] = 85,
        ["DF03 - Waking Shores - Horde"] = 2022,
        ["DF04 - Waking Shores - Neutral"] = 2022,
        ["DF05 - Ohn'Ahran Plains"] = 2023,
        ["DF06 - Azure Span"] = 2024,
        ["DF07 - Thaldraszus"] = 2025,
        ["WIP-The Jade Forest"] = 371,
        ["WIP-Kun-Lai Summit"] = 379,
        ["WIP-Highmountain"] = 650,
        ["Dracthyr Start"] = 2118,
        ["Allied Death Knight Start"] = 2297,
        ["01-30 Pandaren Start"] = 378,
    }

    --TODO: maybe split into kalindor et eastern for map icon/line/arrow
    APR.QuestStepListListing.Vanilla = {
        ["1-Durotar"] = "01-30 Durotar",
        ["10-NorthernBarrens"] = "10-30 Northern Barrens",
        ["199-SouthernBarrens"] = "10-30 Southern Barrens",
        ["DEV-Silverpine"] = "Silverpine Forest",
        ["217-Ruins of Gilneas"] = "Silverpine Forest 2",
        ["DEV-Silverpine2"] = "Silverpine Forest 3",
        ["DEV-DALARAN_CRATER"] = "Silverpine Forest 4",
        ["DEV-Silverpine3"] = "Silverpine Forest 5",
        ["DEV-Hillsbrad"] = "WIP - Hillsbrad Foothills",
        ["DEV-Western Plaguelands"] = "WIP - Western Plaguelands",
    }
    APR.QuestStepListListing.TheBurningCrusade = {}
    APR.QuestStepListListing.WrathOfTheLichKing = {}
    APR.QuestStepListListing.Cataclysm = {}
    APR.QuestStepListListing.MistsOfPandaria = {
        ["371-The Jade Forest"] = "WIP-The Jade Forest",
        ["379-Kun-Lai Summit"] = "WIP-Kun-Lai Summit",
    }
    APR.QuestStepListListing.WarlordsOfDraenor = {
        ["85-DesMephisto-Orgrimmar-p1"] = "WOD01 - Orgrimmar",
        ["577-DesMephisto-TanaanJungle"] = "WOD02 - Tanaan Jungle",
        ["525-DesMephisto-FrostfireRidge-p1"] = "WOD03 - Frostfire Ridge",
        ["543-DesMephisto-Gorgrond-p1"] = "WOD04 - Gorgrond",
        ["535-DesMephisto-Talador-p1"] = "WOD05 - Talador",
        ["542-DesMephisto-SpiresOfArak"] = "WOD06 - Spires of Arak",
        ["550-DesMephisto-Nagrand"] = "WOD07 - Nagrand",
    }
    APR.QuestStepListListing.Legion = {
        ["630-Azsuna"] = "Legion - Azsuna",
        ["641-ValSharah"] = "Legion - Val'Sharah",
        ["634-Stormheim"] = "Legion - Stormheim",
        ["650-Highmountain"] = "WIP-Highmountain",
    }
    APR.QuestStepListListing.BattleForAzeroth = {
        ["1-Orgrimmar"] = "BFA01 - Intro",
        ["862-Zuldazar"] = "BFA02 - Intro",
        ["862-Zuldazar-1"] = "BFA03 - Zuldazar",
        ["863-Nazmir"] = "BFA04 - Nazmir",
        ["862-Zuldazar-2"] = "BFA05 - Naz-end Vol-begin",
        ["864-Vol'dun"] = "BFA06 - Vol'dun",
    }
    APR.QuestStepListListing.Shadowlands = {
        ["85-IntroQline"] = "SL - Intro",
        ["1648-Z0-TheMaw-Story"] = "SL01 - The Maw",
        ["1670-Z1-Oribos-Story"] = "SL02 - Oribos",
        ["1533-Z2-Bastion-Story"] = "SL03 - Bastion",
        ["1613-Z3-Oribos-Story"] = "SL04 - Oribos",
        ["1536-Z4-Maldraxxus-Story"] = "SL05 - Maldraxxus",
        ["1670-Z5-Oribos-Story"] = "SL06 - Oribos",
        ["1543-Z6-TheMaw-Story"] = "SL07 - The Maw",
        ["1670-Z7-Oribos-Story"] = "SL08 - Oribos",
        ["1536-Z8-Maldraxxus-Story"] = "SL09 - Maldraxxus",
        ["1670-Z9-Oribos-Story"] = "SL10 - Oribos",
        ["1565-Z10-Ardenweald-Story"] = "SL11 - Ardenweald",
        ["1671-Z11-Oribos-Story"] = "SL12 - Oribos",
        ["1525-Z12-Revendreth-Story"] = "SL13 - Revendreth",
        ["1543-Z13-TheMaw-Story"] = "SL14 - The Maw",
        ["1525-Z14-Revendreth-Story"] = "SL15 - Revendreth",
        ["1671-Z15-Oribos-Story"] = "SL16 - Oribos",
        ["Shadowlands-StoryOnly-H"] = "SL - StoryMode Only",
    }
    APR.QuestStepListListing.Dragonflight = {
        ["DF01H-85-Orgrimmar"] = "DF01/02 - Dragonflight Orgrimmar/Durotar",
        ["DF03H-2022-WakingShores"] = "DF03 - Waking Shores - Horde",
        ["DF03N-2022-WakingShores"] = "DF04 - Waking Shores - Neutral",
        ["DF04-2023-OhnahranPlains"] = "DF05 - Ohn'Ahran Plains",
        ["DF05-2024-AzureSpan"] = "DF06 - Azure Span",
        ["DF06H-2025-Thaldraszus"] = "DF07 - Thaldraszus",
    }

    if (APR.Race == "Orc") then
        APR.QuestStepListListing.Vanilla["1-ValleyOfTrialsOrc"] = "01-10 Orc Start"
    elseif (APR.Race == "Tauren") then
        APR.QuestStepListListing.Vanilla["7-MulgoreTauren"] = "01-10 Tauren Start"
    elseif (APR.ClassId == APR.Classes["Warrior"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollWar"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Hunter"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollHunter"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Rogue"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollRogue"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Priest"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollPriest"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Shaman"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollShaman"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Mage"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollMage"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Warlock"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollWarlock"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Monk"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollMonk"] = "01-10 Troll Start"
    elseif (APR.ClassId == APR.Classes["Druid"] and APR.Race == "Troll") then
        APR.QuestStepListListing.Vanilla["1-EchoIslesTrollDruid"] = "01-10 Troll Start"
    elseif (APR.Race == "Scourge") then --Undead
        APR.QuestStepListListing.Vanilla["18-TirisfalGladesUndead"] = "01-10 Scourge Start"
    elseif (APR.Race == "BloodElf") then
        APR.QuestStepListListing.Vanilla["94-EversongWoodsBloodElf"] = "01-10 Blood Elf Start"
    elseif (APR.Race == "Goblin" and APR.Level < 2) then
        APR.QuestStepListListing.Cataclysm["194-Kezan"] = "01-30 Goblin Start (Kezan)"
        APR.QuestStepListListing.Cataclysm["174-LostIsles"] = "01-30 Goblin Start (Lost Isles)"
    elseif (APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23) then
        APR.QuestStepListListing.WrathOfTheLichKing["H_Allied_Icecrown Citadel"] = "Allied Death Knight Start"
    elseif (APR.ClassId == APR.Classes["Death Knight"]) then
        APR.QuestStepListListing.WrathOfTheLichKing["H23-ScarletEnclave"] = "Death Knight Start"
    elseif (APR.Race == "Pandaren") then
        APR.QuestStepListListing.MistsOfPandaria["378-WanderingIsle"] = "01-30 Pandaren Start"
    elseif (APR.ClassId == APR.Classes["Demon Hunter"]) then
        APR.QuestStepListListing.Legion["672-Mardum"] = "Demon Hunter Start"
    elseif (APR.Race == "Dracthyr") then
        APR.QuestStepListListing["Dragonflight"]["2118-DracthyrStart-H"] = "Dracthyr Start"
    end
    if APR.Level < 10 or Contains({ 1409, 1726, 1727 }, APR:GetPlayerParentMapID()) then
        APR.QuestStepListListing.Vanilla["1409-Exile's Reach"] = "01-10 Exile's Reach"
    end

    APR.Vanilla = {}
    APR.Vanilla[1] = 1
    APR.Vanilla[7] = 1
    APR.Vanilla[10] = 1
    APR.Vanilla[18] = 1
    APR.Vanilla[21] = 1
    APR.Vanilla[22] = 1
    APR.Vanilla[23] = 1
    APR.Vanilla[25] = 1
    APR.Vanilla[94] = 1
    APR.Vanilla[174] = 1
    APR.Vanilla[194] = 1
    APR.Vanilla[199] = 1
    APR.Vanilla[217] = 1
    APR.Vanilla[1409] = 1

    APR.TheBurningCrusade = {}

    APR.WrathOfTheLichKing = {}
    APR.WrathOfTheLichKing[1602] = 1
    APR.WrathOfTheLichKing[2297] = 1

    APR.Cataclysm = {}

    APR.MistsOfPandaria = {}
    APR.MistsOfPandaria[371] = 1
    APR.MistsOfPandaria[378] = 1
    APR.MistsOfPandaria[379] = 1

    APR.WarlordsOfDraenor = {}
    APR.WarlordsOfDraenor[85] = 1
    APR.WarlordsOfDraenor[525] = 1
    APR.WarlordsOfDraenor[535] = 1
    APR.WarlordsOfDraenor[542] = 1
    APR.WarlordsOfDraenor[543] = 1
    APR.WarlordsOfDraenor[550] = 1
    APR.WarlordsOfDraenor[577] = 1

    APR.Legion = {}
    APR.Legion[630] = 1
    APR.Legion[634] = 1
    APR.Legion[641] = 1
    APR.Legion[672] = 1

    APR.BattleForAzeroth = {}
    APR.BattleForAzeroth[85] = 1
    APR.BattleForAzeroth[862] = 1
    APR.BattleForAzeroth[863] = 1
    APR.BattleForAzeroth[864] = 1

    APR.Shadowlands = {}
    APR.Shadowlands[1409] = 1
    APR.Shadowlands[1525] = 1
    APR.Shadowlands[1533] = 1
    APR.Shadowlands[1536] = 1
    APR.Shadowlands[1543] = 1
    APR.Shadowlands[1565] = 1
    APR.Shadowlands[1613] = 1
    APR.Shadowlands[1648] = 1
    APR.Shadowlands[1670] = 1

    APR.Dragonflight = {}
    APR.Dragonflight[1] = 1
    APR.Dragonflight[85] = 1
    APR.Dragonflight[2022] = 1
    APR.Dragonflight[2023] = 1
    APR.Dragonflight[2024] = 1
    APR.Dragonflight[2025] = 1
    APR.Dragonflight[2107] = 1
    APR.Dragonflight[2109] = 1
    APR.Dragonflight[2110] = 1
    APR.Dragonflight[2118] = 1
end
