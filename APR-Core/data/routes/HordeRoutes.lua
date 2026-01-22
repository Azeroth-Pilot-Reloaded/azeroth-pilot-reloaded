local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:InitHordeRoutes()
    if self.Faction ~= "Horde" then return end

    local routesByExpansion = {
        Vanilla = {
            ["1-Durotar"] = L["Durotar"],
            ["10-NorthernBarrens"] = L["Northern Barrens"],
            ["199-SouthernBarrens"] = L["Southern Barrens"],
            ["21-Silverpine"] = L["Silverpine Forest"],
            ["217-Ruins of Gilneas"] = L["Silverpine Forest 2"],
            ["21-Silverpine2"] = L["Silverpine Forest 3"],
            ["25-DEV-DALARAN_CRATER"] = L["Silverpine Forest 4"],
            ["21-Silverpine3"] = L["Silverpine Forest 5"],
            ["25-Hillsbrad"] = L["WIP - Hillsbrad Foothills"],
            ["22-Western Plaguelands"] = L["WIP - Western Plaguelands"],
        },

        TheBurningCrusade = {},
        WrathOfTheLichKing = {},
        Cataclysm = {},
        MistsOfPandaria = {
            ["85-MoP Intro"] = L["MoP - Intro"],
        },

        WarlordsOfDraenor = {
            ["85-DesMephisto-Orgrimmar-p1"] = L["WOD01 - Orgrimmar"],
            ["577-DesMephisto-TanaanJungle"] = L["WOD02 - Tanaan Jungle"],
            ["525-DesMephisto-FrostfireRidge-p1"] = L["WOD03 - Frostfire Ridge"],
            ["535-DesMephisto-Talador-p1"] = L["WOD05 - Talador"],
            ["542-DesMephisto-SpiresOfArak"] = L["WOD06 - Spires of Arak"],
            ["550-DesMephisto-Nagrand"] = L["WOD07 - Nagrand"],
        },

        Legion = {
            ["85-Intro-Legion"] = L["Legion - Intro"],
        },

        BattleForAzeroth = {
            ["85-BFA-Orgrimmar"] = L["BFA01 - Intro"],
            ["862-Zuldazar"] = L["BFA02 - Zuldazar"],
            ["863-Nazmir"] = L["BFA03 - Nazmir"],
            ["862-Zuldazar-2"] = L["BFA04 - Naz-end Vol-begin"],
            ["864-Vol'dun"] = L["BFA05 - Vol'dun"],
        },

        Shadowlands = {
            ["118-IntroQline"] = L["SL - Intro"],
            ["1670-Shadowlands-StoryOnly-H"] = L["SL - StoryMode Only"],
        },

        Dragonflight = {
            ["85-DF01H-Orgrimmar"] = L["DF01/02 - Dragonflight Orgrimmar/Durotar"],
            ["2022-DF03H-WakingShores"] = L["DF03 - Waking Shores - Horde"],
            ["2025-DF06H-Thaldraszus"] = L["DF07 - Thaldraszus"],
        },

        TheWarWithin = {},
        Minight = {},
        Custom = {},
    }


    local startRoutes = {
        -- Races
        Orc = { expansion = "Vanilla", key = "1-ValleyOfTrialsOrc", label = L["Orc Start"] },
        Scourge = { expansion = "Vanilla", key = "465-TirisfalGladesUndead", label = L["Undead Start"] },
        Tauren = { expansion = "Vanilla", key = "462-MulgoreTauren", label = L["Tauren Start"] },
        Troll = {
            Warrior = { expansion = "Vanilla", key = "463-EchoIslesTrollWar", label = L["Troll Start"] },
            Hunter = { expansion = "Vanilla", key = "463-EchoIslesTrollHunter", label = L["Troll Start"] },
            Rogue = { expansion = "Vanilla", key = "463-EchoIslesTrollRogue", label = L["Troll Start"] },
            Priest = { expansion = "Vanilla", key = "463-EchoIslesTrollPriest", label = L["Troll Start"] },
            Shaman = { expansion = "Vanilla", key = "463-EchoIslesTrollShaman", label = L["Troll Start"] },
            Mage = { expansion = "Vanilla", key = "463-EchoIslesTrollMage", label = L["Troll Start"] },
            Warlock = { expansion = "Vanilla", key = "463-EchoIslesTrollWarlock", label = L["Troll Start"] },
            Monk = { expansion = "Vanilla", key = "463-EchoIslesTrollMonk", label = L["Troll Start"] },
            Druid = { expansion = "Vanilla", key = "463-EchoIslesTrollDruid", label = L["Troll Start"] }
        },
        BloodElf = { expansion = "TheBurningCrusade", key = "467-BloodElf-intro", label = L["Blood Elf Start"] },
        Goblin = {
            main = { expansion = "Cataclysm", key = "194-Kezan", label = L["Goblin Start"] },
            secondary = { expansion = "Cataclysm", key = "174-LostIsles", label = L["Goblin - Lost Isles"] }
        },
        HighmountainTauren = { expansion = "Legion", key = "652-HighmountainTauren-intro", label = L["Highmountain Tauren Start"] },
        Nightborne = { expansion = "Legion", key = "680-Nightborne-intro", label = L["Nightborne Start"] },
        MagharOrc = { expansion = "BattleForAzeroth", key = "85-MagharOrc-intro", label = L["Maghar Orc Start"] },
        Vulpera = { expansion = "BattleForAzeroth", key = "85-Vulpera-intro", label = L["Vulpera Start"] },
        ZandalariTroll = { expansion = "BattleForAzeroth", key = "1165-Zandalari-intro", label = L["Zandalari Troll Start"] },

        -- Classes
    }


    -- WARNING Class before race
    ---
    local routesToAssign = {}
    local className = APR:GetClassNameById(APR.ClassId)

    if APR.Race == "Troll" and startRoutes.Troll[className] then
        local trollRoute = startRoutes.Troll[className]
        table.insert(routesToAssign, trollRoute)
    elseif APR.Race == "Goblin" then
        table.insert(routesToAssign, startRoutes.Goblin.main)
        table.insert(routesToAssign, startRoutes.Goblin.secondary)
    else
        table.insert(routesToAssign, startRoutes[APR.Race])
    end

    -- Apply all collected routes
    APR:assignRoutes(routesToAssign)
    APR:MergeExpansionRoutes(routesByExpansion)
end
