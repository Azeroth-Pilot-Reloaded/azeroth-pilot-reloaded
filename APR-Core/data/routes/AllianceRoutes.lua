local L = LibStub("AceLocale-3.0"):GetLocale("APR")

if (APR.Faction == "Alliance") then
    APR.RouteList.Vanilla = {
        ["1409-Exile's Reach"] = L["01-10 Exile's Reach"],
        ["97-AzuremystIsle"] = L["Azuremyst Isle"],
        ["106-BloodmystIsle"] = L["Bloodmyst Isle"],
        ["62-Darkshore"] = L["Darkshore"],
        ["63-Ashenvale"] = L["Ashenvale"],
        ["77-Felwood"] = L["Felwood"],
        ["83-Winterspring"] = L["Winterspring"],
        ["65-StonetalonMountains"] = L["Stonetalon Mountains"],
        ["199-SouthernBarrens"] = L["Southern Barrens"],
        ["70-DustwallowMarsh"] = L["Dustwallow Marsh"],
        ["66-Desolace"] = L["Desolace"],
        ["69-Feralas"] = L["Feralas"],
        ["64-ThousandNeedles"] = L["Thousand Needles"],
        ["71-Tanaris"] = L["Tanaris"],
        ["78-UnGoroCrater"] = L["Un'Goro Crater"],
        ["81-Silithus"] = L["Silithus"],
        ["57-Teldrassil"] = L["Teldrassil"],
        ["27-Kharanos"] = L["Dun Morogh"],
        ["48-LochModan"] = L["Loch Modan"],
        ["37-ElwynnForest"] = L["Elwynn Forest"],
        ["52-Westfall"] = L["Westfall"],
        ["51-SwampofSorrows"] = L["Swamp of Sorrows"],
        ["17-BlastedLands"] = L["Blasted Lands"],
        ["56-Wetlands"] = L["Wetlands"],
        ["36-BurningSteppes"] = L["Burning Steppes"],
        ["14-ArathiHighlands"] = L["Arathi Highlands"],
        ["26-TheHinterlands"] = L["The Hinterlands"],
        ["22-WesternPlaguelands"] = L["Western Plaguelands"],
        ["23-EasternPlaguelands"] = L["Eastern Plaguelands"],
        ["47-Duskwood"] = L["Duskwood"],
        ["49-RedridgeMountauns"] = L["Redridge Mountauns"],
        ["15-Badlands"] = L["Badlands"],
        ["32-SearingGorge"] = L["Searing Gorge"],
        ["224-NorthernStranglethorn"] = L["Northern Stranglethorn"],
        ["224-TheCapeofStranglethorn"] = L["Cape of Stranglethorn"],

    }
    APR.RouteList.TheBurningCrusade = {}
    APR.RouteList.WrathOfTheLichKing = {}
    APR.RouteList.Cataclysm = {}
    APR.RouteList.MistsOfPandaria = {
        ["554-MoP Remix Intro"]          = L["MoP Remix - Intro"],
        ["84-MoP Intro"]                 = L["MoP - Intro"],
        ["371-The Jade Forest"]          = L["The Jade Forest"],
        ["376-Valley of the four winds"] = L["Valley of the four winds"],
        ["418-Krasarang Wilds"]          = L["Krasarang Wilds"],
        ["379-Kun-Lai Summit"]           = L["Kun-Lai Summit"],
        ["388-Townlong Steppes"]         = L["Townlong Steppes"],
        ["390-Dread Wastes"]             = L["Dread Wastes"],
        ["390-Isle of Thunder"]          = L["Isle of Thunder"],
    }
    APR.RouteList.WarlordsOfDraenor = {
        ["84-DesMephisto-Stormwind-War"] = L["WOD01 - Stormwind"],
        ["577-DesMephisto-TanaanJungle"] = L["WOD02 - Tanaan Jungle"],
        ["539-DesMephisto-Shadowmoon1"] = L["WOD03 - Shadowmoon"],
        ["535-DesMephisto-Talador"] = L["WOD05 - Talador"],
        ["539-DesMephisto-Shadowmoon2"] = L["WOD06 - Shadowmoon"],
        ["535-DesMephisto-Talador2"] = L["WOD07 - Talador"],
        ["542-DesMephisto-SpiresOfArak"] = L["WOD08 - Spires of Arak"],
    }
    APR.RouteList.Legion = {
        ["630-Azsuna"] = L["Legion - Azsuna"],
        ["641-ValSharah"] = L["Legion - Val'Sharah"],
        ["634-Stormheim"] = L["Legion - Stormheim"],
    }
    APR.RouteList.BattleForAzeroth = {
        ["84-BFA-Stormwind"] = L["BFA01 - Intro"],
        ["895-Tiragarde Sound"] = L["BFA02 - Tiragarde Sound"],
        ["896-Dustvar"] = L["BFA03 - Dustvar"],
        ["942-Stormsong Valley"] = L["BFA04 - Stormsong Valley"],
    }
    APR.RouteList.Shadowlands = {
        ["118-IntroQline"] = L["SL - Intro"],
        ["1648-Z0-TheMaw-Story"] = L["SL01 - The Maw"],
        ["1670-Z1-Oribos-Story"] = L["SL02 - Oribos"],
        ["1533-Z2-Bastion-Story"] = L["SL03 - Bastion"],
        ["1670-Z3-Oribos-Story"] = L["SL04 - Oribos"],
        ["1536-Z4-Maldraxxus-Story"] = L["SL05 - Maldraxxus"],
        ["1670-Z5-Oribos-Story"] = L["SL06 - Oribos"],
        ["1960-Z6-TheMaw-Story"] = L["SL07 - The Maw"],
        ["1670-Z7-Oribos-Story"] = L["SL08 - Oribos"],
        ["1536-Z8-Maldraxxus-Story"] = L["SL09 - Maldraxxus"],
        ["1670-Z9-Oribos-Story"] = L["SL10 - Oribos"],
        ["1565-Z10-Ardenweald-Story"] = L["SL11 - Ardenweald"],
        ["1670-Z11-Oribos-Story"] = L["SL12 - Oribos"],
        ["1525-Z12-Revendreth-Story"] = L["SL13 - Revendreth"],
        ["1543-Z13-TheMaw-Story"] = L["SL14 - The Maw"],
        ["1525-Z14-Revendreth-Story"] = L["SL15 - Revendreth"],
        ["1670-Z15-Oribos-Story"] = L["SL16 - Oribos"],
        ["1670-Shadowlands-StoryOnly-A"] = L["SL - StoryMode Only"],
    }
    APR.RouteList.Dragonflight = {
        ["84-DF01A-Stormwind"] = L["DF01 - Dragonflight Stormwind"],
        ["2022-DF03A-WakingShores"] = L["DF02 - Waking Shores - Alliance"],
        ["2022-DF03N-WakingShores"] = L["DF03 - Waking Shores - Neutral"],
        ["2023-DF04-OhnahranPlains"] = L["DF04 - Ohn'Ahran Plains"],
        ["2024-DF05-AzureSpan"] = L["DF05 - Azure Span"],
        ["2025-DF06A-Thaldraszus"] = L["DF06 - Thaldraszus"],
    }
    APR.RouteList.TheWarWithin = {
        ["81-TWW-Intro"] = L["TWW - 01 - Intro"],
        ["2248-TWW-Isle-of-Dorn"] = L["TWW - 02 - Isle of Dorn"],
        ["2214-TWW-Ringing-Deeps"] = L["TWW - 03 - Ringing Deeps"],
        ["2215-TWW-Hallowfall"] = L["TWW - 04 - Hallowfall"],
        ["2255-TWW-Azj-Kahet"] = L["TWW - 05 - Azj-Kahet"],
        ["2248-TWW-Against-the-Current-storyline"] = L["TWW - 06 - Against the Current Storyline"],
        ["2248-TWW-Ties-That-Bind-storyline"] = L["TWW - 07 - Ties That Bind Storyline"],
        ["2248-TWW-News-from-Below-storyline"] = L["TWW - 08 - News from Below Storyline"],
        ["2248-TWW-The-Machines-March-to-War-storyline"] = L["TWW - 09 - The Machines March to War Storyline"],
        ["2248-TWW-Light-in-the-Dark-storyline"] = L["TWW - 10 - Light in the Dark Storyline"],
        ["2248-TWW-Lingering-Shadow-Storyline"] = L["TWW - 11 - Lingering Shadow Storyline"],
        ["2248-TWW-Fate-of-the-Kirin-Tor"] = L["TWW - 12 - Fate of the Kirin Tor"],
        ["2248-TWW-Siren-Isle-Intro"] = L["TWW - Siren Isle Intro"],
        ["2248-TWW-Undermine"] = L["TWW - Undermine"],
        ["2248-TWW-Nightfall"] = L["TWW - Nightfall"],
        ["2248-TWW-Rise-of-the-Red-Dawn-Storyline"] = L["TWW - Rise of the Red Dawn"],
        ["2248-TWW-Isle-of-Dorn-campaign-only"] = L["TWW - Isle of Dorn - Campaign Only"],
        ["2214-TWW-Ringing-Deeps-campaign-only"] = L["TWW - Ringing Deeps - Campaign Only"],
        ["2215-TWW-Hallowfall-campaign-only"] = L["TWW - Hallowfall - Campaign Only"],
        ["2255-TWW-Azj-Kahet-campaign-only"] = L["TWW - Azj Kahet - Campaign Only"],
        ["2255-TWW-Allied-Races-Earthen"] = L["TWW Allied Races Earthen"],
        ["2248-TWW-Isle-of-Dorn-Full"] = L["TWW - Isle of Dorn - All quests - Sojourner"],
        ["2214-TWW-Ringing-Deeps-Full"] = L["TWW - Ringing Deeps - All quests - Sojourner"],
        ["2248-TWW-K'aresh-Storyline"] = L["TWW - K'aresh Storyline"],
    }
    APR.RouteList.Custom = {
        ["84-EclipseGlaives-10-to-70"] = L["10-70 route by EclipseGlaives"],
    }

    -- Starting Route or custom
    ---
    local function assignRoute(expansion, key, label)
        APR.RouteList[expansion][key] = label
    end

    local startRoutes = {
        Dwarf = { expansion = "Vanilla", key = "27-ColdridgeValleyDwarf", label = L["Dwarf Start"] },
        Gnome = { expansion = "Vanilla", key = "30-NewTinkertown", label = L["Gnome Start"] },
        Human = { expansion = "Vanilla", key = "37-NorthshireHuman", label = L["Human Start"] },
        NightElf = { expansion = "Vanilla", key = "57-ShadowglenNightElf", label = L["Night Elf Start"] },
        Draenei = { expansion = "TheBurningCrusade", key = "97-AmmenVale", label = L["Draenei Start"] },
        ["Death Knight"] = {
            allied = { expansion = "WrathOfTheLichKing", key = "118-Allied_Icecrown Citadel", label = L["Allied Death Knight Start"] },
            default = { expansion = "WrathOfTheLichKing", key = "23-ScarletEnclave", label = L["Death Knight Start"] }
        },
        Worgen = { expansion = "Cataclysm", key = "179-Gilneas", label = L["Worgen Start"] },
        ["Demon Hunter"] = { expansion = "Legion", key = "672-Mardum", label = L["Demon Hunter Start"] },
        LightforgedDraenei = { expansion = "Legion", key = "940-LightforgedDraenei-intro", label = L["Lightforged Draenei Start"] },
        VoidElf = { expansion = "Legion", key = "971-VoidElf-intro", label = L["Void Elf Start"] },
        DarkIronDwarf = { expansion = "BattleForAzeroth", key = "1186-DarkIronDwarf-intro", label = L["Dark Iron Dwarf Start"] },
        KulTiran = { expansion = "BattleForAzeroth", key = "1161-KulTiran-intro", label = L["Kul Tiran Start"] },
        Mechagnome = { expansion = "BattleForAzeroth", key = "1573-Mechagnome-intro", label = L["Mechagnome Start"] },
        Dracthyr = {
            evoker = { expansion = "Dragonflight", key = "2118-DracthyrStart-Evo", label = L["Dracthyr Start"] },
            default = { expansion = "Dragonflight", key = "2118-DracthyrStart-Other", label = L["Dracthyr Start"] }
        },
        EarthenDwarf = { expansion = "TheWarWithin", key = "2248-TWW-Earthen", label = L["Earthen Dwarf Start"] }
    }

    -- WARNING Class before race
    ---

    local route
    if APR.ClassId == APR.Classes["Demon Hunter"] then
        route = startRoutes["Demon Hunter"]
    elseif APR.ClassId == APR.Classes["Death Knight"] then
        -- Use allied start if race ID is >= 23; otherwise, default Death Knight start
        route = APR.RaceID >= 23 and startRoutes["Death Knight"].allied or startRoutes["Death Knight"].default
    elseif APR.Race == "Dracthyr" then
        -- Check for Dracthyr Evoker-specific start, else use general Dracthyr start
        route = APR.ClassId == APR.Classes.Evoker and startRoutes.Dracthyr.evoker or
            startRoutes.Dracthyr.default
    else
        route = startRoutes[APR.Race]
    end
    if route and route.expansion and route.key and route.label then
        assignRoute(route.expansion, route.key, route.label)
    end


    -- Lumbermill Wod route
    -- Special case for Warlords of Draenor route based on quest completion
    if C_QuestLog.IsQuestFlaggedCompleted(35049) then
        assignRoute("WarlordsOfDraenor", "543-DesMephisto-Gorgrond-Lumbermill", L["WOD04 - Gorgrond"])
    else
        assignRoute("WarlordsOfDraenor", "543-DesMephisto-Gorgrond", L["WOD04 - Gorgrond"])
    end
end
