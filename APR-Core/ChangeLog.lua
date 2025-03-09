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
    end
end

function APR.changelog:ShowChangeLog()
    ChangeLogFrame:Show()
    LibWindow.RestorePosition(PartyScreenPanel)
end

function APR.changelog:SetChangeLog()
    local news = {
        { "v4.9.2", "2025-03-09" },
        "#Bugs",
        "- Fixed taxi node retrieval method",
        "- Fixed the mechanism to check if your route is up to date after an APR update for previous completed routes",
        "- ",

        { "v4.9.1", "2025-03-08" },
        "#Bugs",
        "- Fixed patch note display on reload when no route is loaded",

        { "v4.9.0", "2025-03-06" },
        "#Features",
        "- Added a mechanism to check if your route is up to date after an APR update",

        "#Bugs",
        "- Fixed index display in the route selection frame",
        "- Fixed reset route command",
        "- Fixed the index dsplayed in the route selection frame",

        "#Guides",
        "- Merged `Undermine Part 1` and `Part 2` routes and added the final chapter",
        "- Updated all mob names for droppable quests to their English version (the name will automatically update to your language after encountering the mob and will be saved for your other characters)",

        { "v4.8.7", "2025-03-05" },
        "#Bugs",
        "- Removed `End Campaign` message from `Undermine Part 1` route",
        "- Added German translation of `Undermine` routes",

        { "v4.8.6", "2025-03-05" },
        "#Bugs",
        "- Fixed Backyard Navy quest (83198) for the optional qpart",

        { "v4.8.5", "2025-03-04" },
        "#Guides",
        "- Added `Liberation of Undermine: The House Loses` quest to the route (required to unlock chapter 6)",

        { "v4.8.4", "2025-03-04" },
        "#Bugs",
        "- Updated IsQuestCompletedOnAccount / IsQuestUncompletedOnAccoun to use questId lists",
        "- Adding other IDs to the No More Walkin' Here quest",

        "#Guides",
        "- Added Undermine Part 2 route (Ignite the Fuel of Change Storyline)",

        { "v4.8.3", "2025-02-27" },
        "#Bugs",
        "-  Added missing portal Dornogal/Undermine",
        "- Added quest to unlock portal Dornogal/Undermine",
        "- Added quest to unlock the mount G-99",
        "- Fix Quest ID on waypoint in undermine route",
        "- Added missing gossip for Quest Snitches Get Stitches (85409)",
        "- Added missing Sidestreet Sluice delve Coords",

        "#Guides",
        "- Added new IsQuestCompletedOnAccount / IsQuestUncompletedOnAccount step options",
        "- Added Undermine Part 1 route to the sopeedrun and TWW prefab route button",

        { "v4.8.2", "2025-02-27" },
        "#WoW",
        "- Added Addon Quest category in addon list",

        { "v4.8.1", "2025-02-27" },
        "#WoW",
        "- Update TOC Interface for 11.1.0",

        { "v4.8.0", "2025-02-27" },
        "#Bugs",
        "- Added missing 11.1.0 taxi nodes",
        "- Added missing portal to undermine",

        "#Guides",
        "- Added Undermine Part 1 (Sorry for the delay, I'm in the middle of moving)",

        { "v4.7.1", "2025-02-16" },
        "#Bugs",
        "- Fix Siren Isle Intro route typo",

        { "v4.7.0", "2025-02-16" },
        "#Bugs",
        "- Fix Lingering Shadow Storyline route",
        "- Fix Siren Isle Intro route",

        "#Guides",
        "- Added Fate of the Kirin Tor Storyline route",
        "- Added Lingering Shadow, Fate of the Kirin Tor and Siren Isle routes to TWW prefab button",

        { "v4.6.4", "2025-01-21" },
        "#Bugs",
        "- Fix level requirements for speedrun routes (a lvl 60 will no longer be sent to TWW)",

        { "v4.6.3", "2025-01-01" },
        "#Bugs",
        "- Majorly updated new custom lvl 10-70 route by EclipseGlaives",

        { "v4.6.2", "2024-12-22" },
        "#Bugs",
        "- Fixed new custom lvl 10-70 route by EclipseGlaives",

        { "v4.6.1", "2024-12-22" },
        "#Guides",
        "- Added new custom lvl 10-70 route by EclipseGlaives",

        { "v4.6.0", "2024-12-20" },
        "#TWW",
        "- Added Lingering Shadow Storyline route",
        "- Added Siren Isle Intro route",

        { "v4.5.6", "2024-12-10" },
        "#Bugs",
        "- Removed `Renown of Khaz Algar` quest (84446)",
        "- Fixed coords for Cogchewer NPC for `Cracking Cogchewer` quest (78637)",

        { "v4.5.5", "2024-11-23" },
        "#Bugs",
        "- Fixed error when using quest item from the quest tracker",
        "- Fixed closest taxi posX error",

        "#WoW",
        "- Update TOC Interface for 11.0.7",

        { "v4.5.4", "2024-10-29" },
        "#Bugs",
        "- Fixed starting route assign function causing lua error",
        "- Changed 'ZoneDoneSave' to 'RouteCompleted'",

        { "v4.5.3", "2024-10-29" },
        "#Features",
        "- Added new starting route for other Dracthyr classes",

        "#Bugs",
        "- Fixed starting coordinates for first quest of Dracthyr Evoker route",
        "- Changed 'Scourge' to 'Undead' in route names",

        { "v4.5.2", "2024-10-23" },
        "#Bugs",
        "- Fixed starting zone route for troll",

        "#WoW",
        "- Update TOC Interface for 11.0.5",

        { "v4.5.1", "2024-10-01" },
        "#Bugs",
        "- Fixed prefab button for BFA in route selection",
        "- Clear AFK frame on step update",
        "- Fixed wrong step index on map/minimap blobs",

        { "v4.5.0", "2024-09-20" },
        "#Features",
        "- Added Extre Line Text coloring option",

        "#TWW",
        "- Added - TWW - Ringing Deeps - All quests - Sojourner",

        { "v4.4.5", "2024-09-09" },
        "#Features",
        "- Added `HasSpell` step option",
        "- Added `ResetRoute` step option to auto reset the route (useful for farming routes ;) )",
        "- Updated type of Race and Class to list format",

        "#Bugs",
        "- Fixed gossip for DF Horde quest `Whispers on the Winds` (65439)",
        "- Removed end of `TWW - Isle of Dorn All Quests` to move it into the next zone route (WIP)",
        "- Fixed typo on Step 1 of `TWW - Ringing Deeps`",
        "- Renamed `TWW - Isle of Dorn - All Quests` to `TWW - Isle of Dorn - All quests - Sojourner`",
        "- Fixed Rollback function to step before Step 1",
        "- Added Waypoint step on `New Candle, New Hope` scenario quest objectives (78642)",
        "- Renamed step to `Index, Step` in the status frame",

        { "v4.4.4", "2024-09-04" },
        "#Features",
        "- Added `Quest Order List` show/hide option in the current step menu",

        "#TWW",
        "- Added - TWW - Light in the Dark Storyline route",

        { "v4.4.3", "2024-09-02" },
        "#Features",
        "- Added new `WaypointDB` step option",

        "#Bugs",
        "- Fixed Lua error on `SetCooldown`",
        "- Fixed Lua error with Heirloom on a new character",
        "- Added some missing extra lines in WoD routes",
        "- Fixed adventure map quests for characters who completed the Campaign",

        "- Fixed multi extra line text order",
        { "v4.4.2", "2024-08-29" },
        "#Bugs",
        "- Fixed multi extra line text order",

        { "v4.4.1", "2024-08-29" },
        "#TWW",
        "- Fixed TWW - News from Below Storyline route",
        "- Fixed TWW - The Machines March to War Storyline route",

        { "v4.4.0", "2024-08-28" },
        "#Features",
        "- Managed the route recorder extra line text on custom routes",
        "- Added new `LootItem` step option",

        "#Bugs",
        "- Fixed Event for `Learn Profession` step option",
        "- Fixed TWW intro for Alliance",
        "- Improved route formatting with the new format in AprRC",
        "- Added index on each step for better debugging and support",

        { "v4.3.1", "2024-08-27" },
        "#TWW",
        "- Added missing end of Hidden Edicts storyline",
        "- Added 'Not available yet' message for TWW storyline",

        { "v4.3.0", "2024-08-27" },
        "#Bugs",
        "- Fix for error after an end of route (oops my bad)",
        "- Fixed message for quest 79124 in Ties That Bind Storyline",
        "- Removed message from first step of Earthen route and added a correct we before the quest The Councilward's Summons",
        "- Remove unavailble storyline from The War Within prefab route button",
        "- Fix for wrong zone message in Delve due to rework of transport module for TWW",

        "#TWW",
        "- Added TWW - Isle of Dorn - All quests route",

        "#Community",
        "- For those on EU servers, I've created an Azeroth Pilot Reloaded community: zWw7EWwFk97",

        { "v4.2.6", "2024-08-26" },
        "#Features",
        "- Update of Translator display in About menu",

        "#Bugs",
        "- Fix for zone transition in TWW (not optimal but this handle 90% of the cases)",
        "- Added force rerender of Current step frame after an end of route (test to avoid blank frame)",
        "- Added class check for ''Strength of One'' quest (9582) for Draenei starting zone",

        "#TWW",
        "- Remove 84664 quest from Campaign Only route of Azj Kahet",

        "#Translation/Localizations",
        "- Thanks to Jean, who joined the team to do the translation into Spanish (LATAM)",

        { "v4.2.5", "2024-08-24" },
        "#TWW",
        "- Added TWW - Allied Races Earthen starting zone route",
        "- Added/Fixed TWW adventure map quests for your alt",

        { "v4.2.4", "2024-08-23" },
        "#Features",
        "- Added auto gossip to open merchant for BuyMerchant step",

        "#Bugs",
        "- Fixed wrong coord, missing gossip for TWW Allied race route",
        "- Change the order of quest 78463, 79553, 79692 in isle of dorn route",
        "- Fixed auto accept any quest with ''Accept only quest(s) from route'' enable and no route selected",

        { "v4.2.3", "2024-08-23" },
        "#Bugs",
        "- Fixed 80511 error for horde route in TWW",
        "- Added missing button for quest 78718 in TWW intro",
        "- Removed useHS on leave scenario step to avoid wrong zone error",

        { "v4.2.2", "2024-08-22" },
        "#Bugs",
        "- Fixed lua error on arrow if no questStep available",
        "- Fixed azuna portal coord",
        "- Fixed priority portal selection for wrong zone",

        { "v4.2.1", "2024-08-22" },
        "#Features",
        "- Updated route config to remove Dracthyr restriction",
        "- Change for lvl 70 next route detection with TWW",
        "- Updated Speedrun prefab to WOD -> DF -> TWW (this will be change in the future)",

        "#Bugs",
        "- Fixed tooltip lua error for unknown questname",
        "- Fixed missing portal for Dalaran (Legion)",

        "#TWW",
        "- Added TWW - Allied Races Earthen route",

        { "v4.2.0", "2024-08-22" },
        "#Features",
        "- Added /apr about command to open the about & help menu",
        "- Update of the content of the About & Help menu",
        "- Removed the ** from the Extra line text",
        "- Display of the quest name for PickUp and Done step in the Current Step frame",
        "- Added auto tracking of the quest for Qpart and Done step to highlight the right quest",
        "- Added tooltips on quest in the Current Step frame to display more details about the quest/step",

        "#Bug",
        "- Fixed missing extra button message",
        "- Removal of raidIcon reset function causing conflict with manual raidIcon",
        "- Fix for some error lua with objective bonus when you leave the zone",
        "- Fixed unwanted auto skip of waypoint",
        "- Merged TWW taxi into the same continent id",

        "#TWW",
        "- Added TWW - Intro route",
        "- Added TWW - Isle of dorn route ",
        "- Added TWW - Ringing Deeps route ",
        "- Added TWW - Hallowfall route",
        "- Added TWW - Azj Kahet route",
        "- Added TWW - Against the Current Storyline route",
        "- Added TWW - Ties That Bind Storyline route",
        "- Added TWW - News from Below Storyline route",
        "- Added TWW - The Machines March to War Storyline route",
        "- Added Campaign only Routes (The route starting from level 70 doesn't allow reaching level 80)",
        "- Added elevator portal between Isle of Dorn and Ringing Deeps",
        "- Added portal between Isle of Dorn and Azj Kahet",

        "#Dev",
        "- Updated lib",

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
