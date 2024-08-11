local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Party  module
APR.changelog = APR:NewModule("ChangeLog")

---------------------------------------------------------------------------------------
--------------------------------- Change log Frames -----------------------------------
---------------------------------------------------------------------------------------

local ChangeLogFrame = CreateFrame("Frame", "ChangeLogFrame", UIParent, "BackdropTemplate")
ChangeLogFrame:SetSize(600, 500)
ChangeLogFrame:SetPoint("CENTER", 0, 0)
ChangeLogFrame:SetFrameStrata("FULLSCREEN")
ChangeLogFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
})
ChangeLogFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))
ChangeLogFrame:EnableMouse(true)

local headerFrame = CreateFrame('Frame', nil, ChangeLogFrame, 'TitleDragAreaTemplate')
headerFrame:SetPoint('CENTER', ChangeLogFrame, 'TOP')
headerFrame:SetSize(600, 150)

local CloseButton = CreateFrame("Button", nil, headerFrame, "UIPanelCloseButton")
CloseButton:SetSize(16, 16)
CloseButton:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", 0, -10)
CloseButton:SetScript("OnClick", function()
    ChangeLogFrame:Hide()
end)

local headerTexture = headerFrame:CreateTexture(nil, "ARTWORK")
headerTexture:SetSize(600, 150)
headerTexture:SetPoint("TOP", headerFrame, "TOP", 0, 0)
headerTexture:SetTexture("Interface\\Addons\\APR\\APR-Core\\assets\\header")

local ScrollFrame = CreateFrame("ScrollFrame", "ChangeLogScrollFrame", ChangeLogFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetSize(ChangeLogFrame:GetWidth() - 40, ChangeLogFrame:GetHeight() - 75)
ScrollFrame:SetPoint("CENTER", -5, -30)

local TextFrame = CreateFrame("Frame", nil, ScrollFrame)
TextFrame:SetSize(ScrollFrame:GetWidth(), ScrollFrame:GetHeight())
ScrollFrame:SetScrollChild(TextFrame)

local Text = TextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Text:SetPoint("TOPLEFT", 10, -10)
Text:SetWidth(TextFrame:GetWidth() - 20)
Text:SetJustifyH("LEFT")
Text:SetWordWrap(true)

---------------------------------------------------------------------------------------
------------------------------ Function Party Frames ----------------------------------
---------------------------------------------------------------------------------------

-- Initialize the Party frame
function APR.changelog:OnInit()
    LibWindow.RegisterConfig(ChangeLogFrame, APR.settings.profile.changeLogFrame)
    ChangeLogFrame.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(ChangeLogFrame)
    self:SetChangeLog()
    ChangeLogFrame:Hide()


    if APR.version ~= APR.settings.profile.lastRecordedVersion then
        if APR.settings.profile.showChangeLog then
            self:ShowChangeLog()
        end
        APR.settings.profile.lastRecordedVersion = APR.version
    end
end

function APR.changelog:ShowChangeLog()
    ChangeLogFrame:Show()
    LibWindow.RestorePosition(PartyScreenPanel)
end

function APR.changelog:SetChangeLog()
    local news = {
        { "vBETA TWW - w33", "2024-08-12" },
        "#Features",
        "- Added /apr about command to open the about & help menu",
        "- Update of the content of the About & Help menu",
        "- Removed the ** from the Extra line text",
        "- Display of the quest name for PickUp and Done step in the Current Step frame",
        "- Added auto tracking of the quest for Qpart and Done step to highlight the right quest",
        "- Added tooltips on quest in the Current Step frame to display more details about the quest",

        "#TWW",
        "- Fixed TWW - Isle of dorn route Alliance first quest order",
        "- Fixed TWW - Ringing Deeps route (Route blocked at the campaign quest 'Ghost of a Company Town' due to Blizzard issue)",

        { "vBETA TWW - w32", "2024-08-07" },
        "#Bug",
        "- Added missing extra button message",

        "#TWW",
        "- Added TWW - Isle of dorn route (~70-72/73)",
        "- Added TWW - Ringing Deeps route (Route blocked at the campaign quest 'Ghost of a Company Town' due to Blizzard issue)",

        { "v4.1.4", "2024-08-06" },
        "#Bug",
        "- Enabled instance quest ui for every type of instance,",
        "- Fixed lua error if missing objectif on QpartPart step",
        "- Fixed update of the scenario step",

        "#TWW",
        "- Added new portals for Dornogal/capital",
        "- Added new Taxi for TWW continent",

        { "v4.1.3", "2024-08-03" },
        "#Bug",
        "- Fixed empty current step frame with new route",
        "- Fixed arrow for NoArrow step with a wrong zone error",

        { "v4.1.2", "2024-08-03" },
        "#Bug",
        "- Fixed Qpartpart step option detection",
        "- Added new zone detection for some indoor zone",
        "- Fixed some step syntax",

        "#Route",
        "- Fixed Pre-patch TWW intro route",

        { "v4.1.1", "2024-08-01" },
        "#Route",
        "- Added TWW section in route settings",
        "- Added Pre-patch TWW intro route",

        { "v4.1.0", "2024-07-28" },
        "#Features",
        "- Support for Scenario Steps",
        "    - Support for MoP scenarios (no route available)",
        "    - Support for TWW Delves (no route available due to the temporary removal of beta servers)",
        "    - Support for instances flagged as scenarios (mainly storyline quests)",
        "- Adding the ability to have Gossip as main step action (to avoid bugs with the Route Recorder)",

        "#Bug",
        "- Enable prefab route button for DF",

        { "v4.0.3", "2024-07-26" },
        "#Bug",
        "- Fix deprecated version issue",

        { "v4.0.2", "2024-07-24" },
        "#Bug",
        "- Fixed ACE dropdown dependency causing lua error",
        "- Fixed deprecated Spell Cooldown function",

        { "v4.0.1", "2024-07-24" },
        "#Bug",
        "- Fix skip cinematic lua error (GameMovieFinished to CinematicFinished)",
        "- Enable Df route for new character",
        "- Fix starting quest of DF route",

        { "v4.0.0", "2024-07-24" },
        "#Features",
        "- Added Taxi Nodes for TWW",
        "- Rework of the menu with the new menu template",
        "- Added toogle function for setting frame on minimap icon",

        "#Bug",
        "- Fix for the position of the current stage frame when attached to the questlog",
        "- Fix Header of all frame + button (close, minimize)",
        "- Fix shortcut to open settings",
        "- Fix BG overlapping on frame header",

        "#Dev",
        "- Updated Lib",

        { "v3.3.4", "2024-06-23" },
        "#Bug",
        "- Fixed wrong coords for last MoP Remix quest (Horde)",

        { "v3.3.3", "2024-06-11" },
        "#Bug",
        "- Fixed missing button for quest 30504 (Emergency Response)",
        "- Added missing qpart for quest 29910 (Rampaging Rodents)",
        "- Fixed Mop remix Jade Forest quest",

        { "v3.3.2", "2024-06-06" },
        "#Features",
        "- Added two auto skip options for waypoints (full or only if you can fly)",

        "#Bug",
        "- Fixed bug on saving NPC data for DropQuest step",

        { "v3.3.1", "2024-06-03" },
        "#Features",
        "- Reduce the number of renderings of the Quest Order Liste Frame to no longer cause freezes",
        "- Reduce the number of renderings of the Current Step Frame to no longer cause freezes",
        "- Added APR prefix to utils function to avoid conflict with other addon",

        "#Bug",
        "- Fixed update of Qpart objective during combat",
        "- Fixed TOC addon version to display",
        "- Removed unwanted Qpart 29765-1 (Cryin' My Eyes Out)",
        "- Updated Pickup 31261 to dropQuest (Captain Jack's Dead)",
        "- Merged quest 29717 with 29716 pickup step in Jade forest (Down Kitty!)",
        "- Added 81638 and 81976 quest for mop remix in horde Jade forest (Home Is Where the Hearthstone Is, Bazaar, Isn't It?)",
        "- Fixed Waypoint, UseHS, UseFlightPath questID if you reset ou forceReset your routes",

        { "v3.2.9", "2024-06-01" },
        "#Features",
        "- Changed event for GetFP to detect new taxi node",

        "#Bug",
        "- Added fillers to 31286 cave waypoints (Robbing Robbers of Robbers)",
        "- Adjust coords for 30624 (It Does You No Good In The Keg)",
        "- Added MoP portal coord for Isle of thunder to avoid transport module bug",
        "- Removed useless waypoints in Jade forest route",

        { "v3.2.8", "2024-05-25" },
        "#Features",
        "- Remove force reset with the v3.2.0",

        { "v3.2.7", "2024-05-25" },
        "#Bugs",
        "- Fixed Coord and Range for Qpart 30182-1 (Fox Mastery)",
        "- Fixed Qpart for 30051 due to blizzard Hotfix (The Great Water Hunt)",
        "- Added missing Qpart for 30350 (Squirmy Delight)",

        { "v3.2.6", "2024-05-22" },
        "#Bugs",
        "- Fixed Isle of Thunder Route",
        "- Fixed a lua error for RaidIcon Step",
        "- Fixed a lua error with the Arrow calcul position",

        { "v3.2.5", "2024-05-21" },
        "#Bugs",
        "- Fixed Townlong Steppes",

        { "v3.2.4", "2024-05-20" },
        "#Bugs",
        "- Fixed Range for The Talon King quest (35734)",
        "- Fixed some coords for Krasarang Wilds route",
        "- Fixed some coords for Kun Lai route",
        "- Removed dialog for DF at lvl 60 on MoP Remix characeter",
        "- Fixed Extra Line Text order on the current step frame",
        "- Fixed/Added Quest info and mob name for the Drop Quest step",

        { "v3.2.3", "2024-05-17" },
        "#Features",
        "- Added a new step option: HasAura & DontHaveAura",
        "- Added Mop Remix character detection",
        "- Disabled Heirloom frame for Mop Remix character",

        "#Bugs",
        "- Fixed Valley of the four winds route (coord, missing qpart, ...)",
        "- Fixed auto-gossip on UseFlightPath step for the free flight",

        { "v3.2.2", "2024-05-17" },
        "#Bugs",
        "- Add missing qpart for MoP remix intro",
        "- Jade Forest: Update coords for some steps",
        "- Valley of the four winds: removing of the cooking quest steps",

        { "v3.2.1", "2024-05-16" },
        "#Bugs",
        "- Fixed wrong zone message for route with only Zone step option",
        "- Fixed quest DB step missing in Quest Order List",

        "#Routes",
        "- Added command to reset all the custom route (/apr resetcustom)",
        "- Support of all MoP zone for both faction",

        { "v3.2.0", "2024-05-14" },
        "#Features",
        "- Updated the position of the minimap buttons",
        "- Added auto-retry for auto-accept on PickUp steps",
        "- Added auto-accept for quests on Adventure Maps",
        "- Reworked BuyMerchant steps to add multiple purchases and quantities",
        "- Added a new step option, LearnProfession",
        "- Creation of a route recording addon for APR (Azeroth Pilot Reloaded - Route Recorder)",

        "#Bugs",
        "- Fixed 'Don't Skip Video' step option",
        "- Fixed a bug where there was no taxi name for UseFlightPath steps",
        "- Fixed a bug blocking the detection of hearthstone usage",
        "- Fixed a bug blocking the use of quest buttons since version 102.6",
        "- Fixed loading custom routes created with APR - Route Recorder",

        "#Routes",
        "- New Horde Pandaren Starting zone",
        "- New starting routes for allied races",
        "- Added part 2 of the Tauren starting zone",
        "- Added part 2 of the Blood Elf starting zone",
        "- Added MoP Remix intro route",
        "- Added prefab button for MoP Remix in route selection",
        "- Added routes for all MoP zones for the Horde",
        "- Added MoP intro and Jade Forest routes for the Alliance",
        "- Added waypoints in the BFA intro scenario route",
        "- Fixed the end of the Exile's Reach route for the Alliance",
        "- Added a missing button for quest 31767",
        "- Fixed coordinates and quest duplication for the Frostfire Ridge route for the Horde",

        "#WoW",
        "- Merged all route addons into one",
        "- Updated version for 10.2.7",
    }

    local changelog = "|cFFF1F1F1|c33ecc00f" .. APR.title .. "|r"

    for i = 1, #news do
        local line = news[i]
        if type(line) == "table" then
            local version, date = line[1], line[2]
            changelog = changelog .. "\n\n|cFFFFFF00" .. version .. " (|cFFFF8800" .. date .. "|r):|r\n\n"
        elseif line ~= "" and not line:match("^#") then
            changelog = changelog .. line .. "\n"
        elseif line:match("^#") then
            changelog = changelog .. "\n|cffeda55f" .. line .. "|r" .. "\n"
        else
            changelog = changelog .. " \n"
        end
    end

    Text:SetText(changelog)
    TextFrame:SetHeight(Text:GetStringHeight())
end
