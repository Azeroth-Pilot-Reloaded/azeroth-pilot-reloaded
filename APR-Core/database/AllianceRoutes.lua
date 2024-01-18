if (APR.Faction == "Alliance") then
    APR.RouteMainMapID = {
        ["01-10 Exile's Reach"] = 1409,
        ["Dwarf Start"] = 27,
        ["Human Start"] = 37,
        ["Gnome Start"] = 30,
        ["Draenei Start"] = 97,
        ["Night Elf Start"] = 57,
        ["Worgen Start"] = 179,
        ["Demon Hunter Start"] = 672,
        ["Death Knight Start"] = 23,
        ["Allied Death Knight Start"] = 2297,
        ["Dracthyr Start"] = 2118,
        ["Dun Morogh"] = 27,
        ["Elwynn Forest"] = 37,
        ["Loch Modan"] = 48,
        ["Westfall"] = 52,
        ["Darkshore"] = 62,
        ["Ashenvale"] = 63,
        ["Azuremyst Isle"] = 97,
        ["Bloodmyst Isle"] = 106,
        ["Wetlands"] = 56,
        ["Burning Steppes"] = 36,
        ["Arathi Highlands"] = 14,
        ["The Hinterlands"] = 26,
        ["Western Plaguelands"] = 22,
        ["Swamp of Sorrows"] = 51,
        ["Blasted Lands"] = 17,
        ["Eastern Plaguelands"] = 23,
        ["Felwood"] = 77,
        ["Duskwood"] = 47,
        ["Redridge Mountauns"] = 49,
        ["Winterspring"] = 83,
        ["Stonetalon Mountains"] = 65,
        ["Southern Barrens"] = 199,
        ["Dustwallow Marsh"] = 70,
        ["Desolace"] = 66,
        ["Feralas"] = 69,
        ["Thousand Needles"] = 64,
        ["Tanaris"] = 71,
        ["Un'Goro Crater"] = 78,
        ["Silithus"] = 81,
        ["Teldrassil"] = 57,
        ["Badlands"] = 15,
        ["Searing Gorge"] = 32,
        ["Northern Stranglethorn"] = 224,
        ["Cape of Stranglethorn"] = 224,
        ["WOD01 - Stormwind"] = 84,
        ["WOD02 - Tanaan Jungle"] = 577,
        ["WOD03 - Shadowmoon"] = 539,
        ["WOD04 - Gorgrond"] = 543,
        ["WOD05 - Talador"] = 535,
        ["WOD06 - Shadowmoon"] = 539,
        ["WOD07 - Talador"] = 535,
        ["WOD08 - Spires of Arak"] = 542,
        ["Legion - Azsuna"] = 630,
        ["Legion - Val'Sharah"] = 641,
        ["Legion - Stormheim"] = 634,
        ["BFA01 - Intro"] = 84,
        ["BFA02 - Tiragarde Sound"] = 895,
        ["BFA04 - Stormsong Valley"] = 942,
        ["BFA03 - Dustvar"] = 896,
        ["SL - Intro"] = 118,
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
        ["SL - StoryMode Only"] = 1670,
        ["DF01 - Dragonflight Stormwind"] = 84,
        ["DF02 - Waking Shores - Alliance"] = 2022,
        ["DF03 - Waking Shores - Neutral"] = 2022,
        ["DF04 - Ohn'Ahran Plains"] = 2023,
        ["DF05 - Azure Span"] = 2024,
        ["DF06 - Thaldraszus"] = 2025,
    }
    APR.RouteList.Vanilla = {
        ["1409-Exile's Reach"] = "01-10 Exile's Reach",
        ["A97-AzuremystIsle"] = "Azuremyst Isle",
        ["A106-BloodmystIsle"] = "Bloodmyst Isle",
        ["A62-Darkshore"] = "Darkshore",
        ["A63-Ashenvale"] = "Ashenvale",
        ["A77-Felwood"] = "Felwood",
        ["A83-Winterspring"] = "Winterspring",
        ["A65-StonetalonMountains"] = "Stonetalon Mountains",
        ["A199-SouthernBarrens"] = "Southern Barrens",
        ["A70-DustwallowMarsh"] = "Dustwallow Marsh",
        ["A66-Desolace"] = "Desolace",
        ["A69-Feralas"] = "Feralas",
        ["A64-ThousandNeedles"] = "Thousand Needles",
        ["A71-Tanaris"] = "Tanaris",
        ["A78-UnGoroCrater"] = "Un'Goro Crater",
        ["A81-Silithus"] = "Silithus",
        ["A57-Teldrassil"] = "Teldrassil",
        ["A27-Kharanos"] = "Dun Morogh",
        ["A48-LochModan"] = "Loch Modan",
        ["A37-ElwynnForest"] = "Elwynn Forest",
        ["A52-Westfall"] = "Westfall",
        ["A51-SwampofSorrows"] = "Swamp of Sorrows",
        ["A17-BlastedLands"] = "Blasted Lands",
        ["A56-Wetlands"] = "Wetlands",
        ["A36-BurningSteppes"] = "Burning Steppes",
        ["A14-ArathiHighlands"] = "Arathi Highlands",
        ["A26-TheHinterlands"] = "The Hinterlands",
        ["A22-WesternPlaguelands"] = "Western Plaguelands",
        ["A23-EasternPlaguelands"] = "Eastern Plaguelands",
        ["A47-Duskwood"] = "Duskwood",
        ["A49-RedridgeMountauns"] = "Redridge Mountauns",
        ["A15-Badlands"] = "Badlands",
        ["A32-SearingGorge"] = "Searing Gorge",
        ["A224-NorthernStranglethorn"] = "Northern Stranglethorn",
        ["A224-TheCapeofStranglethorn"] = "Cape of Stranglethorn",

    }
    APR.RouteList.TheBurningCrusade = {}
    APR.RouteList.WrathOfTheLichKing = {}
    APR.RouteList.Cataclysm = {}
    APR.RouteList.MistsOfPandaria = {}
    APR.RouteList.WarlordsOfDraenor = {
        ["A84-DesMephisto-Stormwind-War"] = "WOD01 - Stormwind",
        ["A577-DesMephisto-TanaanJungle"] = "WOD02 - Tanaan Jungle",
        ["A539-DesMephisto-Shadowmoon1"] = "WOD03 - Shadowmoon",
        ["A535-DesMephisto-Talador"] = "WOD05 - Talador",
        ["A539-DesMephisto-Shadowmoon2"] = "WOD06 - Shadowmoon",
        ["A535-DesMephisto-Talador2"] = "WOD07 - Talador",
        ["A542-DesMephisto-SpiresOfArak"] = "WOD08 - Spires of Arak",
    }
    APR.RouteList.Legion = {
        ["A630-Azsuna"] = "Legion - Azsuna",
        ["A641-ValSharah"] = "Legion - Val'Sharah",
        ["A634-Stormheim"] = "Legion - Stormheim",
    }
    APR.RouteList.BattleForAzeroth = {
        ["A84-Stormwind"] = "BFA01 - Intro",
        ["A895-Tiragarde Sound"] = "BFA02 - Tiragarde Sound",
        ["A942-Stormsong Valley"] = "BFA04 - Stormsong Valley",
        ["A896-Dustvar"] = "BFA03 - Dustvar",
    }
    APR.RouteList.Shadowlands = {
        ["84-IntroQline"] = "SL - Intro",
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
        ["Shadowlands-StoryOnly-A"] = "SL - StoryMode Only",
    }
    APR.RouteList.Dragonflight = {
        ["DF01A-84-Stormwind"] = "DF01 - Dragonflight Stormwind",
        ["DF03A-2022-WakingShores"] = "DF02 - Waking Shores - Alliance",
        ["DF03N-2022-WakingShores"] = "DF03 - Waking Shores - Neutral",
        ["DF04-2023-OhnahranPlains"] = "DF04 - Ohn'Ahran Plains",
        ["DF05-2024-AzureSpan"] = "DF05 - Azure Span",
        ["DF06A-2025-Thaldraszus"] = "DF06 - Thaldraszus",
    }

    if (APR.Race == "NightElf") then
        APR.RouteList.Vanilla["A57-ShadowglenNightElf"] = "Night Elf Start"
    elseif (APR.Race == "Draenei") then
        APR.RouteList.Vanilla["A97-AmmenVale"] = "Draenei Start"
    elseif (APR.Race == "Dwarf") then
        APR.RouteList.Vanilla["A27-ColdridgeValleyDwarf"] = "Dwarf Start"
    elseif (APR.Race == "Human") then
        APR.RouteList.Vanilla["A37-NorthshireHuman"] = "Human Start"
    elseif (APR.Race == "Gnome") then
        APR.RouteList.Vanilla["A27-NewTinkertown"] = "Gnome Start"
    elseif (APR.Race == "Worgen") then
        APR.RouteList.Vanilla["A179-Gilneas"] = "Worgen Start"
    elseif (APR.ClassId == APR.Classes["Demon Hunter"]) then
        APR.RouteList.Vanilla["672-Mardum"] = "Demon Hunter Start"
    elseif (APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23) then
        APR.RouteList.Vanilla["A_Allied_Icecrown Citadel"] = "Allied Death Knight Start"
    elseif (APR.ClassId == APR.Classes["Death Knight"]) then
        APR.RouteList.Vanilla["A23-ScarletEnclave"] = "Death Knight Start"
    elseif (APR.Race == "Dracthyr") then
        APR.RouteList.Dragonflight["2118-DracthyrStart-A"] = "Dracthyr Start"
    end

    -- Lumbermill Wod route
    if C_QuestLog.IsQuestFlaggedCompleted(35049) then
        APR.RouteQuestStepList["A543-DesMephisto-Gorgrond-Lumbermill"] = "WOD04 - Gorgrond"
    else
        APR.RouteQuestStepList["A543-DesMephisto-Gorgrond"] = "WOD04 - Gorgrond"
    end
end
