local L = LibStub("AceLocale-3.0"):GetLocale("APR")

if (APR.Faction == "Horde") then
    APR.RouteList.Vanilla = {
        ["1409-Exile's Reach"] = L["01-10 Exile's Reach"],
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
    }
    APR.RouteList.TheBurningCrusade = {}
    APR.RouteList.WrathOfTheLichKing = {}
    APR.RouteList.Cataclysm = {}
    APR.RouteList.MistsOfPandaria = {
        ["554-MoP Remix Intro"] = L["MoP Remix - Intro"],
        ["85-MoP Intro"] = L["MoP - Intro"],
        ["371-The Jade Forest"] = L["The Jade Forest"],
        ["376-Valley of the four winds"] = L["Valley of the four winds"],
        ["418-Krasarang Wilds"] = L["Krasarang Wilds"],
        ["379-Kun-Lai Summit"] = L["Kun-Lai Summit"],
        ["388-Townlong Steppes"] = L["Townlong Steppes"],
        ["390-Dread Wastes"] = L["Dread Wastes"],
        ["390-Isle of Thunder"] = L["Isle of Thunder"],
    }
    APR.RouteList.WarlordsOfDraenor = {
        ["85-DesMephisto-Orgrimmar-p1"] = L["WOD01 - Orgrimmar"],
        ["577-DesMephisto-TanaanJungle"] = L["WOD02 - Tanaan Jungle"],
        ["525-DesMephisto-FrostfireRidge-p1"] = L["WOD03 - Frostfire Ridge"],
        ["535-DesMephisto-Talador-p1"] = L["WOD05 - Talador"],
        ["542-DesMephisto-SpiresOfArak"] = L["WOD06 - Spires of Arak"],
        ["550-DesMephisto-Nagrand"] = L["WOD07 - Nagrand"],
    }
    APR.RouteList.Legion = {
        ["85-Intro-Legion"] = L["Legion - Intro"],
        ["627-Intro-Remix"] = L["Legion - Intro Remix"],
        ["630-Azsuna"] = L["Legion - Azsuna"],
        ["641-ValSharah"] = L["Legion - Val'Sharah"],
        ["634-Stormheim"] = L["Legion - Stormheim"],
        ["619-Highmountain"] = L["Legion - Highmountain"],
    }
    APR.RouteList.BattleForAzeroth = {
        ["85-BFA-Orgrimmar"] = L["BFA01 - Intro"],
        ["862-Zuldazar"] = L["BFA02 - Zuldazar"],
        ["863-Nazmir"] = L["BFA03 - Nazmir"],
        ["862-Zuldazar-2"] = L["BFA04 - Naz-end Vol-begin"],
        ["864-Vol'dun"] = L["BFA05 - Vol'dun"],
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
        ["1670-Shadowlands-StoryOnly-H"] = L["SL - StoryMode Only"],
    }
    APR.RouteList.Dragonflight = {
        ["85-DF01H-Orgrimmar"] = L["DF01/02 - Dragonflight Orgrimmar/Durotar"],
        ["2022-DF03H-WakingShores"] = L["DF03 - Waking Shores - Horde"],
        ["2022-DF03N-WakingShores"] = L["DF04 - Waking Shores - Neutral"],
        ["2023-DF04-OhnahranPlains"] = L["DF05 - Ohn'Ahran Plains"],
        ["2024-DF05-AzureSpan"] = L["DF06 - Azure Span"],
        ["2025-DF06H-Thaldraszus"] = L["DF07 - Thaldraszus"],
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
        ["2451-Arathi-Highlands-Returning-Player"] = L["TWW - Arathi Highlands - Returning Player"],
    }

    APR.RouteList.Midnight = {
       ["2248-Midnight-Intro"] = L["Midnight - Intro"],
    }
    APR.RouteList.Custom = {}

    -- Starting Route or custom
    ---
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
        Dracthyr = {
            evoker = { expansion = "Dragonflight", key = "2118-DracthyrStart-Evo", label = L["Dracthyr Start"] },
            default = { expansion = "Dragonflight", key = "2118-DracthyrStart-Other", label = L["Dracthyr Start"] }
        },
        EarthenDwarf = { expansion = "TheWarWithin", key = "2248-TWW-Earthen", label = L["Earthen Dwarf Start"] },


        -- Classes
        ["Death Knight"] = {
            allied = { expansion = "WrathOfTheLichKing", key = "118-Allied_Icecrown Citadel", label = L["Allied Death Knight Start"] },
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Death Knight Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Death Knight Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Blood = { expansion = "Legion", key = "Artifact Weapon - Death Knight - Blood", label = L["Artifact Weapon - Death Knight - Blood"] },
                Frost = { expansion = "Legion", key = "Artifact Weapon - Death Knight - Frost", label = L["Artifact Weapon - Death Knight - Frost"] },
                Unholy = { expansion = "Legion", key = "Artifact Weapon - Death Knight - Unholy", label = L["Artifact Weapon - Death Knight - Unholy"] },
            },
            default = { expansion = "WrathOfTheLichKing", key = "23-ScarletEnclave", label = L["Death Knight Start"] },
        },
        ["Demon Hunter"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Demon Hunter Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Demon Hunter Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Havoc = { expansion = "Legion", key = "Artifact Weapon - Demon Hunter - Havoc", label = L["Artifact Weapon - Demon Hunter - Havoc"] },
                Vengeance = { expansion = "Legion", key = "Artifact Weapon - Demon Hunter - Vengeance", label = L["Artifact Weapon - Demon Hunter - Vengeance"] },
            },
            default = { expansion = "Legion", key = "672-Demon-Hunter-Start", label = L["Demon Hunter Start"] },
        },
        ["Druid"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Druid Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Druid Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Balance = { expansion = "Legion", key = "Artifact Weapon - Druid - Balance", label = L["Artifact Weapon - Druid - Balance"] },
                Feral = { expansion = "Legion", key = "Artifact Weapon - Druid - Feral", label = L["Artifact Weapon - Druid - Feral"] },
                Guardian = { expansion = "Legion", key = "Artifact Weapon - Druid - Guardian", label = L["Artifact Weapon - Druid - Guardian"] },
                Restoration = { expansion = "Legion", key = "Artifact Weapon - Druid - Restoration", label = L["Artifact Weapon - Druid - Restoration"] },
            },
        },
        ["Hunter"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Hunter Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Hunter Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                ["Beast Mastery"] = { expansion = "Legion", key = "Artifact Weapon - Hunter - Beast Mastery", label = L["Artifact Weapon - Hunter - Beast Mastery"] },
                ["Marksmanship"] = { expansion = "Legion", key = "Artifact Weapon - Hunter - Marksmanship", label = L["Artifact Weapon - Hunter - Marksmanship"] },
                ["Survival"] = { expansion = "Legion", key = "Artifact Weapon - Hunter - Survival", label = L["Artifact Weapon - Hunter - Survival"] },
            },
        },
        ["Mage"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Mage Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Mage Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Arcane = { expansion = "Legion", key = "Artifact Weapon - Mage - Arcane", label = L["Artifact Weapon - Mage - Arcane"] },
                Fire = { expansion = "Legion", key = "Artifact Weapon - Mage - Fire", label = L["Artifact Weapon - Mage - Fire"] },
                Frost = { expansion = "Legion", key = "Artifact Weapon - Mage - Frost", label = L["Artifact Weapon - Mage - Frost"] },
            },
        },
        ["Monk"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Monk Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Monk Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Brewmaster = { expansion = "Legion", key = "Artifact Weapon - Monk - Brewmaster", label = L["Artifact Weapon - Monk - Brewmaster"] },
                Mistweaver = { expansion = "Legion", key = "Artifact Weapon - Monk - Mistweaver", label = L["Artifact Weapon - Monk - Mistweaver"] },
                Windwalker = { expansion = "Legion", key = "Artifact Weapon - Monk - Windwalker", label = L["Artifact Weapon - Monk - Windwalker"] },
            },
        },
        ["Paladin"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Paladin Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Paladin Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Holy = { expansion = "Legion", key = "Artifact Weapon - Paladin - Holy", label = L["Artifact Weapon - Paladin - Holy"] },
                Protection = { expansion = "Legion", key = "Artifact Weapon - Paladin - Protection", label = L["Artifact Weapon - Paladin - Protection"] },
                Retribution = { expansion = "Legion", key = "Artifact Weapon - Paladin - Retribution", label = L["Artifact Weapon - Paladin - Retribution"] },
            },
        },
        ["Priest"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Priest Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Priest Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Discipline = { expansion = "Legion", key = "Artifact Weapon - Priest - Discipline", label = L["Artifact Weapon - Priest - Discipline"] },
                Holy = { expansion = "Legion", key = "Artifact Weapon - Priest - Holy", label = L["Artifact Weapon - Priest - Holy"] },
                Shadow = { expansion = "Legion", key = "Artifact Weapon - Priest - Shadow", label = L["Artifact Weapon - Priest - Shadow"] },
            },
        },
        ["Rogue"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Rogue Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Rogue Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Assassination = { expansion = "Legion", key = "Artifact Weapon - Rogue - Assassination", label = L["Artifact Weapon - Rogue - Assassination"] },
                Outlaw = { expansion = "Legion", key = "Artifact Weapon - Rogue - Outlaw", label = L["Artifact Weapon - Rogue - Outlaw"] },
                Subtlety = { expansion = "Legion", key = "Artifact Weapon - Rogue - Subtlety", label = L["Artifact Weapon - Rogue - Subtlety"] },
            },
        },
        ["Shaman"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Shaman Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Shaman Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Elemental = { expansion = "Legion", key = "Artifact Weapon - Shaman - Elemental", label = L["Artifact Weapon - Shaman - Elemental"] },
                Enhancement = { expansion = "Legion", key = "Artifact Weapon - Shaman - Enhancement", label = L["Artifact Weapon - Shaman - Enhancement"] },
                Restoration = { expansion = "Legion", key = "Artifact Weapon - Shaman - Restoration", label = L["Artifact Weapon - Shaman - Restoration"] },
            },
        },
        ["Warlock"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Warlock Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Warlock Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Affliction = { expansion = "Legion", key = "Artifact Weapon - Warlock - Affliction", label = L["Artifact Weapon - Warlock - Affliction"] },
                Demonology = { expansion = "Legion", key = "Artifact Weapon - Warlock - Demonology", label = L["Artifact Weapon - Warlock - Demonology"] },
                Destruction = { expansion = "Legion", key = "Artifact Weapon - Warlock - Destruction", label = L["Artifact Weapon - Warlock - Destruction"] },
            },
        },
        ["Warrior"] = {
            remix = {
                hub = { expansion = "Legion", key = "Order Hall Warrior Part 1", label = L["Remix - Order Hall - Start"] },
                hub2 = { expansion = "Legion", key = "Order Hall Warrior Part 2", label = L["Remix - Order Hall - Next"] },
            },
            spec = {
                Arms = { expansion = "Legion", key = "Artifact Weapon - Warrior - Arms", label = L["Artifact Weapon - Warrior - Arms"] },
                Fury = { expansion = "Legion", key = "Artifact Weapon - Warrior - Fury", label = L["Artifact Weapon - Warrior - Fury"] },
                Protection = { expansion = "Legion", key = "Artifact Weapon - Warrior - Protection", label = L["Artifact Weapon - Warrior - Protection"] },
            },
        },

    }


    local function assignRoutes(routes)
        if not routes then return end

        if routes.expansion and routes.key and routes.label then
            APR.RouteList[routes.expansion][routes.key] = routes.label
        elseif type(routes) == "table" then
            for _, route in ipairs(routes) do
                if route.expansion and route.key and route.label then
                    APR.RouteList[route.expansion][route.key] = route.label
                end
            end
        end
    end

    -- WARNING Class before race
    ---
    local routesToAssign = {}
    local className = APR:GetClassNameById(APR.ClassId)
    if APR:IsRemixCharacter() then
        -- Class-specific remix start routes
        table.insert(routesToAssign, startRoutes[className].remix.hub)
        table.insert(routesToAssign, startRoutes[className].remix.hub2)
    elseif APR.ClassId == APR.Classes["Demon Hunter"] then
        table.insert(routesToAssign, startRoutes["Demon Hunter"].default)
    elseif APR.ClassId == APR.Classes["Death Knight"] then
        -- Use allied start if race ID is >= 23; otherwise, default Death Knight start
        if APR.RaceID >= 23 then
            table.insert(routesToAssign, startRoutes["Death Knight"].allied)
        else
            table.insert(routesToAssign, startRoutes["Death Knight"].default)
        end
    elseif APR.Race == "Dracthyr" then
        -- Check for Dracthyr Evoker-specific start, else use general Dracthyr start
        if APR.ClassId == APR.Classes.Evoker then
            table.insert(routesToAssign, startRoutes.Dracthyr.evoker)
        else
            table.insert(routesToAssign, startRoutes.Dracthyr.default)
        end
    elseif APR.Race == "Goblin" then
        table.insert(routesToAssign, startRoutes.Goblin.main)
        table.insert(routesToAssign, startRoutes.Goblin.secondary)
    elseif APR.Race == "Troll" and startRoutes.Troll[className] then
        local trollRoute = startRoutes.Troll[className]
        table.insert(routesToAssign, trollRoute)
    else
        table.insert(routesToAssign, startRoutes[APR.Race])
    end

    if startRoutes[className] and startRoutes[className].spec then
        for specName, specRoute in pairs(startRoutes[className].spec) do
            table.insert(routesToAssign, specRoute)
        end
    end

    -- Lumbermill Wod route
    -- Special case for Warlords of Draenor route based on quest completion
    local gorgrondRoute
    if C_QuestLog.IsQuestFlaggedCompleted(35049) then
        gorgrondRoute = {
            expansion = "WarlordsOfDraenor",
            key = "543-DesMephisto-Gorgrond-Lumbermill",
            label = L["WOD04 - Gorgrond"],
        }
    else
        gorgrondRoute = {
            expansion = "WarlordsOfDraenor",
            key = "543-DesMephisto-Gorgrond-p1",
            label = L["WOD04 - Gorgrond"],
        }
    end
    table.insert(routesToAssign, gorgrondRoute)


    -- Apply all collected routes
    assignRoutes(routesToAssign)
end
