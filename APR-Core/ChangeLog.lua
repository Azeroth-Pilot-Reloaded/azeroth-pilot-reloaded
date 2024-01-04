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
ChangeLogFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
})
ChangeLogFrame:SetBackdropColor(0, 0, 0, 0.75)
ChangeLogFrame:EnableMouse(true)

local CloseButton = CreateFrame("Button", nil, ChangeLogFrame, "UIPanelCloseButton")
CloseButton:SetSize(16, 16)
CloseButton:SetPoint("TOPRIGHT", ChangeLogFrame, "TOPRIGHT", 0, 0)
CloseButton:SetScript("OnClick", function()
    ChangeLogFrame:Hide()
end)


local ScrollFrame = CreateFrame("ScrollFrame", "ChangeLogScrollFrame", ChangeLogFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetSize(ChangeLogFrame:GetWidth() - 40, ChangeLogFrame:GetHeight() - 40)
ScrollFrame:SetPoint("CENTER", 0, 0)

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
        { "BETA-v3.1.0", "2024-01-04" },
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
        "- Addition of the Heirloom frame",
        "    - Button to use available Taxi cards",
        "    - Button to open the Heirloom item frame",
        "    - Heirloom Maps are not available in Exile's Reach",
        "- New command to open route options (/apr route)",
        "- Added a shortcut to open routes in the menu of the current step",
        "- Add QOL command to toggle qol (/apr qol)",
        "- Auto open/close the taxiMap on Flightpath step",

        "#Bugs",
        "- Fix lua error from switching continent",
        "- Fix AddonLoad API for 10.2",
        "- Fix gap in Apr blizzard option on first load",
        "- Fix non reset of qol and current step frame with no route",
        "- Fix the load of exile reach route for +10lvl player still in the zone",
        "- Fix same saved variable for same character name",
        "- Fix transport error for instance",
        "- Fix transport missing wanted zone in current step durring wrong zone message",

        "#Dev/Debug",
        "- Rework - transport logic",
        "- Fix bunch of tiny stuff in code",

        { "v3.0.3",      "2023-11-14" },
        "#Features",
        "- Glichy dotted line replaced by normal line (but you can now change color, transparency and size)",
        "- Add color and size option for the next steps icons on map and minimap",
        "- New `/apr route` command to open the APR route options (same on current step menu)",

        "#Bugs",
        "- Fix Error lua on taci map",
        "- Fix Jumping Current Step frame on update if not attach to quest log",
        "- Fix rollback did not rollback on waypoint step (Crange)",
        "- Add UI reload on reset command to the current route reset",

        "#Hint",
        "Check the help command or `The Ultimate Question of Life, the Universe and Everything`",

        { "v3.0.2", "2023-11-08" },
        "#WoW",
        "- Update compability with 10.2.0",

        "#Bugs",
        "- Fix the current step frame when his linked to the quest log",
        "- Fix the waypoint/travel to message",
        "- Little optimisation on Quest order list update (doesn't run anything if it's hidden)",
        "- Remove some multiple ugly call to the GetContinent function",
        "- Remove useless code",

        "#Dev/Debug",
        "- Add Show event option",

        { "v3.0.1", "2023-11-05" },
        "#Features",
        "- Added Background and color/alpha picker for Current Step Frame",
        "- Added a right click menu on the Current Step Frame Header with some shortcuts",
        "- Added slider to select the number of next step to displayed on the map/minimap",

        "#Bugs",
        "- Hide APR Frame during Pet battle",
        "- Fix Party frame (no more luad error + it's working now)",
        "- Change the default placement for the current step frame to not Attach to Quest Log",
        "- Fix the lock setting for the Current Step Frame",
        "- Fix Attach to Quest Log translation",
        "- Fix the constant next step icon on the map/minimap (with the slider + toogle settings)",

        { "v3.0.0", "2023-11-02" },
        "#Features",
        "- New Settings (now it's all in the blizz' options)",
        "    - Each element has its own tab with more options than before",
        "    - Route options will be available in a future release",
        "    - Ui options (color, font, ...) will be available in a future release",
        "- New Current step",
        "    - Can be attached to Quest Log",
        "    - Rollback/Skip button (or previous/next if you prefer)",
        "    - A route progress bar",
        "- New Quest Order List Frame",
        "    - new colour code (say bye bye to ugly red)",
        "    - you can resize it by holding down a modifier key (alt/shift/ctrl)",
        "    - it can be locked",
        "    - And for the artist, you can change the background color and alpha",
        "- New Party Frame (can change again in the future to have progress bars if you ask hard enough)",
        "- New AFK Frame (I love progress bar)",
        "- GoodBye APR MACRO and welcome back Item quest button (yeah I finally managed that F£#@ù bug)",
        "- Added the option of displaying the next 10 steps on the minimap (as on the map)",
        "- Current step icon added to map and minimap",
        "- Disabled Automatic skip of Cinematic (wow changed api, can't do it without lua error :'( .. press Escape to skip in the old way)",
        "- Added this new path note frame for update news",

        "#Route",
        "- Add support 'Adventure mode' for Dragonflight",
        "- Add Dracthyr route",
        "- Add new step option (Faction, Race, Class, HasAchievement, DontHaveAchievement)",
        "- Update of the Exile Reach route with the new Class step option",
        "- Merge the DF Horde starting route into one with the new zone step",
        "- Rework Zuldazar route to account for Blizz changes",
        "- Fixed a few errors in the Df route",

        "#Bugs",
        "- Fix the display of steps on the map (an improved icon and a tootltip are coming soon)",
        "- Add GossipOptionID check to avoid wrong gossip index",

        "#Dev",
        "- Bunch of rework and optimization :)",
        "- A Coordinate frame for the route maker",
        "- New Logo",
        "- Add support for us (Paypal/Patreon)",

        "#Localization",
        "- French 100% ( Neogeekmo )",
        "- German 63.03% ( Kamian )",

        { "v2.4.5", "2023-09-06" },
        "#WoW",
        "- Update APR to be sync with the last WoW Interface Version (10.1.7)",
        "#Localization",
        "- English -> Fix missing key due to V3 code",
        "- German -> Thanks to Kamian for starting the translation (27.59%)"
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
