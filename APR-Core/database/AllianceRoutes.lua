if (APR.Faction == "Alliance") then
    APR.RouteList.Vanilla = {
        ["1409-Exile's Reach"] = "01-10 Exile's Reach",
        ["97-AzuremystIsle"] = "Azuremyst Isle",
        ["106-BloodmystIsle"] = "Bloodmyst Isle",
        ["62-Darkshore"] = "Darkshore",
        ["63-Ashenvale"] = "Ashenvale",
        ["77-Felwood"] = "Felwood",
        ["83-Winterspring"] = "Winterspring",
        ["65-StonetalonMountains"] = "Stonetalon Mountains",
        ["199-SouthernBarrens"] = "Southern Barrens",
        ["70-DustwallowMarsh"] = "Dustwallow Marsh",
        ["66-Desolace"] = "Desolace",
        ["69-Feralas"] = "Feralas",
        ["64-ThousandNeedles"] = "Thousand Needles",
        ["71-Tanaris"] = "Tanaris",
        ["78-UnGoroCrater"] = "Un'Goro Crater",
        ["81-Silithus"] = "Silithus",
        ["57-Teldrassil"] = "Teldrassil",
        ["27-Kharanos"] = "Dun Morogh",
        ["48-LochModan"] = "Loch Modan",
        ["37-ElwynnForest"] = "Elwynn Forest",
        ["52-Westfall"] = "Westfall",
        ["51-SwampofSorrows"] = "Swamp of Sorrows",
        ["17-BlastedLands"] = "Blasted Lands",
        ["56-Wetlands"] = "Wetlands",
        ["36-BurningSteppes"] = "Burning Steppes",
        ["14-ArathiHighlands"] = "Arathi Highlands",
        ["26-TheHinterlands"] = "The Hinterlands",
        ["22-WesternPlaguelands"] = "Western Plaguelands",
        ["23-EasternPlaguelands"] = "Eastern Plaguelands",
        ["47-Duskwood"] = "Duskwood",
        ["49-RedridgeMountauns"] = "Redridge Mountauns",
        ["15-Badlands"] = "Badlands",
        ["32-SearingGorge"] = "Searing Gorge",
        ["224-NorthernStranglethorn"] = "Northern Stranglethorn",
        ["224-TheCapeofStranglethorn"] = "Cape of Stranglethorn",

    }
    APR.RouteList.TheBurningCrusade = {}
    APR.RouteList.WrathOfTheLichKing = {}
    APR.RouteList.Cataclysm = {}
    APR.RouteList.MistsOfPandaria = {
        ["554-MoP Remix Intro"] = "MoP Remix - Intro"
    }
    APR.RouteList.WarlordsOfDraenor = {
        ["84-DesMephisto-Stormwind-War"] = "WOD01 - Stormwind",
        ["577-DesMephisto-TanaanJungle"] = "WOD02 - Tanaan Jungle",
        ["539-DesMephisto-Shadowmoon1"] = "WOD03 - Shadowmoon",
        ["535-DesMephisto-Talador"] = "WOD05 - Talador",
        ["539-DesMephisto-Shadowmoon2"] = "WOD06 - Shadowmoon",
        ["535-DesMephisto-Talador2"] = "WOD07 - Talador",
        ["542-DesMephisto-SpiresOfArak"] = "WOD08 - Spires of Arak",
    }
    APR.RouteList.Legion = {
        ["630-Azsuna"] = "Legion - Azsuna",
        ["641-ValSharah"] = "Legion - Val'Sharah",
        ["634-Stormheim"] = "Legion - Stormheim",
    }
    APR.RouteList.BattleForAzeroth = {
        ["84-BFA-Stormwind"] = "BFA01 - Intro",
        ["895-Tiragarde Sound"] = "BFA02 - Tiragarde Sound",
        ["942-Stormsong Valley"] = "BFA04 - Stormsong Valley",
        ["896-Dustvar"] = "BFA03 - Dustvar",
    }
    APR.RouteList.Shadowlands = {
        ["118-IntroQline"] = "SL - Intro",
        ["1648-Z0-TheMaw-Story"] = "SL01 - The Maw",
        ["1670-Z1-Oribos-Story"] = "SL02 - Oribos",
        ["1533-Z2-Bastion-Story"] = "SL03 - Bastion",
        ["1670-Z3-Oribos-Story"] = "SL04 - Oribos",
        ["1536-Z4-Maldraxxus-Story"] = "SL05 - Maldraxxus",
        ["1670-Z5-Oribos-Story"] = "SL06 - Oribos",
        ["1960-Z6-TheMaw-Story"] = "SL07 - The Maw",
        ["1670-Z7-Oribos-Story"] = "SL08 - Oribos",
        ["1536-Z8-Maldraxxus-Story"] = "SL09 - Maldraxxus",
        ["1670-Z9-Oribos-Story"] = "SL10 - Oribos",
        ["1565-Z10-Ardenweald-Story"] = "SL11 - Ardenweald",
        ["1670-Z11-Oribos-Story"] = "SL12 - Oribos",
        ["1525-Z12-Revendreth-Story"] = "SL13 - Revendreth",
        ["1543-Z13-TheMaw-Story"] = "SL14 - The Maw",
        ["1525-Z14-Revendreth-Story"] = "SL15 - Revendreth",
        ["1670-Z15-Oribos-Story"] = "SL16 - Oribos",
        ["1670-Shadowlands-StoryOnly-A"] = "SL - StoryMode Only",
    }
    APR.RouteList.Dragonflight = {
        ["84-DF01A-Stormwind"] = "DF01 - Dragonflight Stormwind",
        ["2022-DF03A-WakingShores"] = "DF02 - Waking Shores - Alliance",
        ["2022-DF03N-WakingShores"] = "DF03 - Waking Shores - Neutral",
        ["2023-DF04-OhnahranPlains"] = "DF04 - Ohn'Ahran Plains",
        ["2024-DF05-AzureSpan"] = "DF05 - Azure Span",
        ["2025-DF06A-Thaldraszus"] = "DF06 - Thaldraszus",
    }
    APR.RouteList.Custom = {}


    -- WARNING Class before race
    if (APR.ClassId == APR.Classes["Demon Hunter"]) then
        APR.RouteList.Legion["672-Mardum"] = "Demon Hunter Start"
    elseif (APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23) then
        APR.RouteList.WrathOfTheLichKing["118-Allied_Icecrown Citadel"] = "Allied Death Knight Start"
    elseif (APR.ClassId == APR.Classes["Death Knight"]) then
        APR.RouteList.WrathOfTheLichKing["23-ScarletEnclave"] = "Death Knight Start"
    elseif (APR.Race == "Dracthyr") then
        APR.RouteList.Dragonflight["2118-DracthyrStart-A"] = "Dracthyr Start"
    elseif (APR.Race == "NightElf") then
        APR.RouteList.Vanilla["57-ShadowglenNightElf"] = "Night Elf Start"
    elseif (APR.Race == "Dwarf") then
        APR.RouteList.Vanilla["27-ColdridgeValleyDwarf"] = "Dwarf Start"
    elseif (APR.Race == "Human") then
        APR.RouteList.Vanilla["37-NorthshireHuman"] = "Human Start"
    elseif (APR.Race == "Gnome") then
        APR.RouteList.Vanilla["30-NewTinkertown"] = "Gnome Start"
    elseif (APR.Race == "Draenei") then
        APR.RouteList.TheBurningCrusade["97-AmmenVale"] = "Draenei Start"
    elseif (APR.Race == "Worgen") then
        APR.RouteList.Cataclysm["179-Gilneas"] = "Worgen Start"
    elseif (APR.Race == "VoidElf") then
        APR.RouteList.Legion["971-VoidElf-intro"] = "Void Elf Start"
    elseif (APR.Race == "LightforgedDraenei") then
        APR.RouteList.Legion["940-LightforgedDraenei-intro"] = "Lightforged Draenei Start"
    elseif (APR.Race == "DarkIronDwarf") then
        APR.RouteList.BattleForAzeroth["1186-DarkIronDwarf-intro"] = "DarkIron Dwarf Start"
    elseif (APR.Race == "Mechagnome") then
        APR.RouteList.BattleForAzeroth["1573-Mechagnome-intro"] = "Mechagnome Start"
    elseif (APR.Race == "KulTiran") then
        APR.RouteList.BattleForAzeroth["1161-KulTiran-intro"] = "Kul Tiran Start"
    end

    -- Lumbermill Wod route
    if C_QuestLog.IsQuestFlaggedCompleted(35049) then
        APR.RouteList.WarlordsOfDraenor["543-DesMephisto-Gorgrond-Lumbermill"] = "WOD04 - Gorgrond"
    else
        APR.RouteList.WarlordsOfDraenor["543-DesMephisto-Gorgrond"] = "WOD04 - Gorgrond"
    end
end
