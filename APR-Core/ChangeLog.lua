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
    self:ShowChangeLog()
end

function APR.changelog:ShowChangeLog()
    ChangeLogFrame:Show()
    LibWindow.RestorePosition(PartyScreenPanel)
end

function APR.changelog:SetChangeLog()
    local news = {
        { "V3-Beta-2", "2023-09-29" },
        "TDB",

        { "V3-Beta",   "2023-09-23" },
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
        "",
        "#Routes",
        "- Merge the DF Horde starting route into one with the new zone step",
        "- Fixed a few errors in the Df route",
        "- Finalization of the Dracthyr route",
        "",
        "#Dev",
        "- Bunch of rework and optimization",
        "- A Coordinate frame for the route maker",
        "- Add a new zone step for route (zone= uiMapId)",
        "- Test of a new Logo (waiting for the final one)",
        "",
        "#Localization",
        "- French 100% ( Neogeekmo )",
        "- German 63.21% ( Kamian )",

        { "v2.4.5", "2023-09-06" },
        "#WoW",
        "- Update APR to be sync with the last WoW Interface Version (10.1.7)",
        "",
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
            changelog = changelog .. "|cffeda55f" .. line .. "|r" .. "\n"
        else
            changelog = changelog .. " \n"
        end
    end

    Text:SetText(changelog)
    TextFrame:SetHeight(Text:GetStringHeight())
end
