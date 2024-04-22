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
ScrollFrame:SetPoint("CENTER", 0, -30)

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
        { "v3.1.14", "2024-04-17" },
        "#Features",
        "- Add Status Frame (Shows the current state of the addon)",
        "- Add header image on changelog (But you must have seen it ;))",

        "#Bugs",
        "- Remove debug print on Zone Done Save",
        "- Reoder command helper",

        { "v3.1.13", "2024-04-16" },
        "#Bugs",
        "- Add missing faction check in route file",

        { "v3.1.12", "2024-04-15" },
        "#Bugs",
        "- Fix bug on  mapID format with new route name format",

        { "v3.1.11", "2024-04-15" },
        "#Bugs",
        "- Fix Player lvl up dialog message with current lvl",
        "- Update GossipOptionIDs for quest 69911",
        "- Update DF route selection to lvl 60",
        "- Fix deprecated function from 10.2.6",
        "- Add Custom route tab for route recorder",
        "- Fix Legion quests 39515 & 19516",
        "- Reorder command + add to lowercase",
        "- Update syntax for ExtraLineText",

        { "v3.1.10", "2024-03-20" },
        "#Bugs",
        "- Fix questStep lua error due to missing data for arrow",
        "- Add Spell ID hearthStone list with the majority of hearthStones available for UseHS step option",
        "- Add Gossip Option ID do `Green Dragon Down` quest in Ohn'ahran Plain route",
        "- Remove non-compaign quest from Shadowlands-StoryOnly",

        "#WoW",
        "- Update interface addon version to 10.2.6",

        { "v3.1.9",  "2024-03-06" },
        "#Bugs",
        "- Fix DF starting zone with zone step",
        "- Add coord for all the step of DF alliance starting zone",
        "- Add Extra Line Text for the Forbidden Cave treasure in WOD",
        "- Fix route switch for Gorgrond Lumbermill",
        "- Remove useless step options (LoadPick/SpecialLeaveVehicle/SpecialFlight)",


        { "v3.1.8", "2024-02-11" },
        "#Bugs",
        "- Fix Lua error sometimes on load with empty custom path",
        "- Fix BFA route to add Chromie Timeline",
        "- Fix DK and DH route empty for some races",
        "- Fix Wrong zone for DK and DH route",

        { "v3.1.7", "2024-02-06" },
        "#Features",
        "- Add Buff frame for mandatory quest step buff (+ remove old sweatOfOurBrowBuff for Sl quest)",
        "- Add auto gossip for Set HS step",

        "#Bugs",
        "- Fix Qpart/Qpartpart step details in quest order list",
        "- Fix wrong distance on waypoint step",
        "- Recude the Scene cutter timer before cut",
        "- Fix Boat trigger typo",
        "- Add Skip waypoint button for use HS step",
        "- Fix auto handin quest with multiple rewards",
        "- Fix locales error for Giggling Basket quest emote",

        "#Route",
        "- Fix all SL route (Gossip, zones, missing steps, waypoint, flight, ...)",
        "- Add InstanceQuest step option for storyline intance",
        "- Add Buff step option (with buff frame feature)",
        "- Add GossipOptionIDs step option for multiple gossip on the same step",

        { "v3.1.6", "2024-02-02" },
        "#Bugs",
        "- Fix wrong starting zone for speedrun prefab route",
        "- Fix Party Frame displayed condition",
        "- Add check to portal list before closest taxi for wrong zone transport",
        "- Only display Auto share quest popup if you are in a group",

        { "v3.1.5", "2024-01-30" },
        "#Features",
        "- Auto HandIn Choice will no longer do anything in case of a quest with Comestic rewards",
        "- Add option to auto share new quests to your friend in group",

        "#Bugs",
        "- Change GigglingBacket (SL quest) for locales",
        "- Change Current step frame strata to match Quest order list frame",
        "- Fix cooldown on quest step button",
        "- Fix false green waypoint step on Quest order list",
        "- Fix Chromie timeline message for +60lvl character",

        "#Route",
        "- Prettier route file to line (it's more compact)",
        "- Change Qpart and Filler syntax",
        "- Remove useless syntax from route (ButtonSpellId, ButtonCooldown,...)",
        "- Add DoEmote step option, with the emote name",
        "- Add DoEmote for Exile's Reach routes",
        "- Add Auto buy tabar for Exile's Reach Horde Route",

        "#Localization",
        "- German 100% ( Kamian )",

        { "v3.1.4", "2024-01-23" },
        "#Bugs",
        "- Fix false wrong zone for Horde - WOD01 - Orgrimmar",
        "- Add Skip waypoint arrow button for UseHS step",
        "- Fix auto gossip for step with only GossipOptionID",
        "- Fix gossip option for Shadowland - SL - Intro",
        "- Fix missing heirloom in garrison",

        "#Localization",
        "- German 99% ( Kamian )",

        { "v3.1.3", "2024-01-23" },
        "#Bugs",
        "- Fix Error Lua : Set Texture on first load of the game",

        { "v3.1.2", "2024-01-20" },
        "#Bugs",
        "- Fix missing gorgrond route in WOD ",
        "- Fix Dreanor taxis that causes the error 404",
        "- Remove of the condition for selecting SL routes",
        "- Add the SL timeline for SL routes",
        "- Add a 'Too far away' message instead of 'wrong zone' if the distance is more than 4000",
        "- Add events for detecting zone change for transport",
        "- Remove of the line when the addon cannot find the route (error 404)",
        "- Fix of the detection of Boats in BFA",


        { "v3.1.1", "2024-01-18" },
        "#Features",
        "- Added font color and scale selection for map/minimap icon (map & minimap option)",
        "- Added SL to speedrun to avoid missing lvl for DF",

        "#Bugs",
        "- Fix wrong zone message when you are in your Garrison for Wod route",
        "- Fix CheckIsInRouteZone for continent and Zone step option",
        "- Fix no arrow/wrong line for wrong zone on range step",

        { "v3.1.0", "2024-01-17" },
        "#Features",
        "- Rework of the route selection and custom path",
        "    - Each element has its own tab with more options than before",
        "    - We have removed the old frames to put everything into Blizzard's options",
        "    - We now have different prefabs (speedrun, WOD only, BFA only, SL only, DF only)",
        "    - The routes are distributed according to the expansions",
        "    - Movement is still with a right click",
        "    - You can now move up and down routes in the custom path",
        "    - There is the status of the route, which allows you to see the completed ones",
        "    - New frame at first load and after a reset to open route options",
        "- Rework of the transport logic",
        "    - Now we no longer have 'Wrong zone' messages if we are on the correct continent and in one of the zones of the expansion",
        "    - For changing continents, if no path is available, then we redirect to the capital",
        "    - We have added all the Taxis according to factions",
        "    - We have added portals in our DB to change continents",
        "    - We switch to the wrong zone logic if we are too far away from the target (4000 yards/meters)",
        "- Addition of the Heirloom frame",
        "    - Button to use available Taxi cards",
        "    - Button to open the Heirloom item frame",
        "    - Heirloom Maps are not available in Exile's Reach",
        "- New command to open route options (/apr route)",
        "- Added a shortcut to open routes in the menu of the current step",
        "- Add QOL command to toggle qol (/apr qol)",
        "- Auto open/close the taxiMap on Flightpath step",
        "- Change Quest Order List resize key to resize right botton icon",
        "- Add option to select the position of the Current step quest button (left or right)",

        "#Bugs",
        "- Fix Auto Flightpath",
        "- Fix lua error from switching continent",
        "- Fix AddonLoad API for 10.2",
        "- Fix gap in Apr blizzard option on first load",
        "- Fix non reset of qol and current step frame with no route",
        "- Fix the load of exile reach route for +10lvl player still in the zone",
        "- Fix same saved variable for same character name",
        "- Fix transport error for instance",
        "- Fix transport missing wanted zone in current step durring wrong zone message",
        "- Fix no quest/item button on the current step",
        "- Fix starting zone for Goblin, Night Elf, Gnome, Human, Dreanei, Troll, Orc, Blood Elf, Undead",

        "#Route",
        "- New Grind step option (to ask to grind to lvl XX)",
        "- New Gender step option (for the goblin route for now)",
        "- Change CRange step to Waypoint",
        "- Change AreaTriggerZ step to ZoneStepTrigger",
        "- Change TT step to Coord",
        "- Remove all the Trigger step",

        "#Dev/Debug",
        "- Rework - transport logic",
        "- Deleting DF lib",
        "- Update DeBuff/Aura with the new 10.2.5 API",
        "- Fix wrong coord for some zone with the minimap line + coord frame",
        "- Fix bunch of tiny stuff in code",

        "#WoW",
        "- Upgrading TOC Interface to 10.2.5",

        "#Localization",
        "- French 100% ( Neogeekmo )",
        "- German 73.22% ( Kamian )",
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
