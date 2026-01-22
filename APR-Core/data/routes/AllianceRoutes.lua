local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:InitAllianceRoutes()
    if self.Faction ~= "Alliance" then return end

    local routesByExpansion = {
        Vanilla = {
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
            ["49-RedridgeMountains"] = L["Redridge Mountains"],
            ["15-Badlands"] = L["Badlands"],
            ["32-SearingGorge"] = L["Searing Gorge"],
            ["224-NorthernStranglethorn"] = L["Northern Stranglethorn"],
            ["224-TheCapeofStranglethorn"] = L["Cape of Stranglethorn"],
        },

        TheBurningCrusade = {},
        WrathOfTheLichKing = {},
        Cataclysm = {},
        MistsOfPandaria = {
            ["84-MoP Intro"] = L["MoP - Intro"],
        },


        WarlordsOfDraenor = {
            ["84-DesMephisto-Stormwind-War"] = L["WOD01 - Stormwind"],
            ["577-DesMephisto-TanaanJungle"] = L["WOD02 - Tanaan Jungle"],
            ["539-DesMephisto-Shadowmoon1"] = L["WOD03 - Shadowmoon"],
            ["535-DesMephisto-Talador"] = L["WOD05 - Talador"],
            ["539-DesMephisto-Shadowmoon2"] = L["WOD06 - Shadowmoon"],
            ["535-DesMephisto-Talador2"] = L["WOD07 - Talador"],
            ["542-DesMephisto-SpiresOfArak"] = L["WOD08 - Spires of Arak"],
        },

        Legion = {},

        BattleForAzeroth = {
            ["84-BFA-Stormwind"] = L["BFA01 - Intro"],
            ["895-Tiragarde Sound"] = L["BFA02 - Tiragarde Sound"],
            ["896-Dustvar"] = L["BFA03 - Dustvar"],
            ["942-Stormsong Valley"] = L["BFA04 - Stormsong Valley"],
        },

        Shadowlands = {
            ["118-IntroQline"] = L["SL - Intro"],
            ["1670-Shadowlands-StoryOnly-A"] = L["SL - StoryMode Only"],
        },

        Dragonflight = {
            ["84-DF01A-Stormwind"] = L["DF01 - Dragonflight Stormwind"],
            ["2022-DF03A-WakingShores"] = L["DF02 - Waking Shores - Alliance"],
            ["2025-DF06A-Thaldraszus"] = L["DF06 - Thaldraszus"],
        },

        TheWarWithin = {},
        Minight = {},
        Custom = {
            ["84-EclipseGlaives-10-to-70"] = L["10-70 route by EclipseGlaives"],
        },
    }

    -- Starting Route or custom
    local startRoutes = {
        -- Races
        Dwarf = { expansion = "Vanilla", key = "27-ColdridgeValleyDwarf", label = L["Dwarf Start"] },
        Gnome = { expansion = "Vanilla", key = "30-NewTinkertown", label = L["Gnome Start"] },
        Human = { expansion = "Vanilla", key = "37-NorthshireHuman", label = L["Human Start"] },
        NightElf = { expansion = "Vanilla", key = "57-ShadowglenNightElf", label = L["Night Elf Start"] },
        Draenei = { expansion = "TheBurningCrusade", key = "97-AmmenVale", label = L["Draenei Start"] },
        Worgen = { expansion = "Cataclysm", key = "179-Gilneas", label = L["Worgen Start"] },
        LightforgedDraenei = { expansion = "Legion", key = "940-LightforgedDraenei-intro", label = L["Lightforged Draenei Start"] },
        VoidElf = { expansion = "Legion", key = "971-VoidElf-intro", label = L["Void Elf Start"] },
        DarkIronDwarf = { expansion = "BattleForAzeroth", key = "1186-DarkIronDwarf-intro", label = L["Dark Iron Dwarf Start"] },
        KulTiran = { expansion = "BattleForAzeroth", key = "1161-KulTiran-intro", label = L["Kul Tiran Start"] },
        Mechagnome = { expansion = "BattleForAzeroth", key = "1573-Mechagnome-intro", label = L["Mechagnome Start"] },

        -- Classes
    }

    -- For Void elf
    if APR.ClassId == APR.Classes["Demon Hunter"] then
        APR.RouteList.Legion["84-Intro-Legion-DH"] = L["Legion - Intro"]
    else
        APR.RouteList.Legion["84-Intro-Legion"] = L["Legion - Intro"]
    end

    -- WARNING Class before race
    ---
    local routesToAssign = {}
    local className = APR:GetClassNameById(APR.ClassId)

    -- Races
    table.insert(routesToAssign, startRoutes[APR.Race])

    -- Apply all collected routes
    APR:assignRoutes(routesToAssign)
    APR:MergeExpansionRoutes(routesByExpansion)
end
