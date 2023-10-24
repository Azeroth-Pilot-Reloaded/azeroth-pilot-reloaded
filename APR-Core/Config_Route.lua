local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local CustomListMixin = {}

-- Initialize APR Route module
APR.routeconfig = APR:NewModule("routeconfig")

local alliance = "Alliance"
local horde = "Horde"

---------------------------------------------------------------------------------------
------------------------- Config functionality for Route ------------------------------
---------------------------------------------------------------------------------------

function APR.routeconfig:getConfigOptionTable()
    local routeOptions = {
        name = L["ROUTE_HELPER"],
        type = "group",
        inline = false,
        order = 0,
        args={
            firstcharacter = {
                order = 2.1,
                name = L["FIRST_CHARACTER"],
                type = "execute",
                width = 1.2,
                func = function()
                    firstcharacter = not firstcharacter
                    if firstcharacter then
                        self.setAutoPathForRoute(2)
                        APR.BookingList["ClosedSettings"] = true
                    end
                end
            },
            speedrun = {
                order = 2.2,
                name = L["SPEEDRUN"],
                type = "execute",
                width = 1.2,
                func = function()
                    speedrun = not speedrun
                    if speedrun then
                        APR.routeconfig:setAutoPathForRoute(1)
                        APR.BookingList["ClosedSettings"] = true
                    else
                        APR.RoutePlan.Custompath:Hide()
                    end
                end
            },
            custom_path = {
                order = 2.3,
                name = L["CUSTOM_PATH"],
                type = "execute",
                width = 1.2,
                func = function()
                    custom_path = not custom_path
                    if custom_path then
                        APR.RoutePlan.Custompath:Show()
                        APR.BookingList["ClosedSettings"] = true
                    else
                        APR.RoutePlan.Custompath:Hide()
                    end
                end
            },
            custom_path_area = {
                order = 3,
                name = L["CUSTOM_PATH"],
                type = "group",
                width = full,
                inline = true,
                args={
                    general_settings={
                        order = 1,
                        name = "Place for the route",
                        type = "description",
                        width = "full",
                    }
                }
            },
            kalimdor={
                name = "Kalimdor",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 4,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemein",
                        type = "description",
                        width = "full",
                    },
                }
            },
            eastern_kingdoms={
                name = "EASTERN_KINGDOMS",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 5,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
            dragonflight={
                name = "DRAGONFLIGHT",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 6,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
            misc1={
                name = "MISC1",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 7,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
            misc2={
                name = "MISC2",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 8,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
            wod={
                name = "WOD",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 9,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
            shadowlands={
                name = "SHADOWLANDS",
                type = "group",
                childGroups = "tree",
                inline = false,
                order = 10,
                args={
                    general_settings={
                        order = 1,
                        name = "allgemei2n",
                        type = "description",
                        width = "full",
                    },
                }
            },
        }
    }

    return routeOptions
end


function APR.routeconfig:setAutoPathForRoute(routeChoice) -- For the Speed run and First character
    APRData[APR.Realm][APR.Username]["routeChoiceIndex"] = routeChoice
    local playerMapId = C_Map.GetBestMapForUnit("player")
    local currentMapId, TOP_MOST = C_Map.GetBestMapForUnit('player'), true
    if (Enum and Enum.UIMapType and Enum.UIMapType.Continent and currentMapId) then
        playerMapId = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, TOP_MOST)
    end
    if (playerMapId and playerMapId["mapID"]) then
        playerMapId = playerMapId["mapID"]
    else
        playerMapId = C_Map.GetBestMapForUnit("player")
    end
    APR_Custom[APR.Username .. "-" .. APR.Realm] = nil
    APR_Custom[APR.Username .. "-" .. APR.Realm] = {}
    for CLi = 1, 19 do
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
    end
    if (APR.Level < 10 and (playerMapId == 1409 or playerMapId == 1726 or playerMapId == 1727)) then
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "01-10 Exile's Reach")
    end
    if (APR.Level < 30) then
        if (APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23) then -- Allied DK
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "Allied Death Knight Start")
        elseif (APR.ClassId == APR.Classes["Death Knight"]) then                  -- DK
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "08-30 Death Knight Start")
        elseif (APR.ClassId == APR.Classes["Demon Hunter"]) then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "01-30 Demon Hunter Start")
        end
    end
    if (routeChoice == 1) then -- speedrun route
        self.getSpeedrunRoute()
    elseif (routeChoice == 2) then -- firstcharacter route
        self.getFirstcharacterRoute()
    end
    -- Dragonflight
    if (APR.Faction == alliance) then
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF01 - Dragonflight Stormwind")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF02 - Waking Shores - Alliance")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF03 - Waking Shores - Neutral")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF04 - Ohn'Ahran Plains")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF05 - Azure Span")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF06 - Thaldraszus")
    elseif (APR.Faction == horde) then
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF01 - Dragonflight Orgrimmar")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF02 - Dragonflight Durotar")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF03 - Waking Shores - Horde")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF04 - Waking Shores - Neutral")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF05 - Ohn'Ahran Plains")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF06 - Azure Span")
        tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DF07 - Thaldraszus")
    end
    for CLi = 1, 19 do
        if (APR_Custom[APR.Username .. "-" .. APR.Realm] and APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]]) then
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
            else
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText(APR_Custom[APR.Username .. "-" .. APR.Realm][CLi])
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Show()
            end
        else
            APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
            APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
        end
    end
    APR.RoutePlanCheckPos()
    APR.CheckPosMove()
    APR.BookingList["UpdateMapId"] = 1
end

function APR.routeconfig:getSpeedrunRoute()
    if (APR.Level < 60) then
        if (APR.Level >= 58 and APR.ClassId == APR.Classes["Dracthyr"]) then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "58-60 Dracthyr Start")
        elseif APR.Level >= 50 then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DEV - StoryMode Only (Not Enough XP)")
        elseif (APR.Faction == alliance) then
            -- WOD
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(1/8) 10-50 Stormwind")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(2/8) 10-50 Tanaan Jungle")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(3/8) 10-50 Shadowmoon")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(4/8) 10-50 Gorgrond")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(5/8) 10-50 Talador")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(6/8) 10-50 Shadowmoon")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(7/8) 10-50 Talador")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(8/8) 10-50 Spires of Arak")
        elseif (APR.Faction == horde) then
            -- WOD
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(1/7) 10-50 Orgrimmar")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(2/7) 10-50 Tanaan Jungle")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(3/7) 10-50 Frostfire Ridge")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(4/7) 10-50 Gorgrond")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(5/7) 10-50 Talador")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(6/7) 10-50 Spires of Arak")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "(7/7) 10-50 Nagrand")
        end
    end
end

function APR.routeconfig:getFirstcharacterRoute()
    if (APR.Level < 50) then
        if APR.Level >= 50 then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "DEV - StoryMode Only (Not Enough XP)")
        elseif (APR.Faction == alliance) then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 10-10 Intro")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 10-50 Tiragarde Sound")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 20-50 Dustvar")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 30-50 Stormsong Valley")
        elseif (APR.Faction == horde) then
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 10-10 Intro")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 10-10 Intro 2")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 10-50 Zuldazar")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 20-50 Nazmir")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 30-30 Naz-end Vol-begin")
            tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], "BFA - 30-50 Vol'dun")
        end
    end
end



























--Loads RoutePlan and option frame. RoutePlan is gui that pops when you hit "Custom Path" and a gui comes up allowing you to order them
function APR.RoutePlanLoadIn()
    -- Main Frame -- When click on custom path
    APR.RoutePlan = CreateFrame("frame", "APR.RoutePlanMainFrame1", UIParent)
    APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
        APR.settings.profile.topLiz)
    APR.RoutePlan:SetWidth(1)
    APR.RoutePlan:SetHeight(1)
    APR.RoutePlan:SetMovable(true)
    APR.RoutePlan:EnableMouse(true)
    APR.RoutePlan:SetFrameStrata("LOW")

    APR.RoutePlan.Custompath = CreateFrame("frame", "APR.RoutePlanMainFrame2", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath:SetWidth(1)
    APR.RoutePlan.Custompath:SetHeight(1)
    APR.RoutePlan.Custompath:SetMovable(true)
    APR.RoutePlan.Custompath:EnableMouse(true)
    APR.RoutePlan.Custompath:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath:SetPoint("TOPLEFT", APR.RoutePlan, "TOPLEFT", 0, 0)
    APR.RoutePlan.Custompath:SetScale(0.9)

    APR.RoutePlan.Custompath.HelpText = CreateFrame("frame", "APR.RoutePlanHelpTextFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.HelpText:SetHeight(20)
    APR.RoutePlan.Custompath.HelpText:SetMovable(true)
    APR.RoutePlan.Custompath.HelpText:EnableMouse(true)
    APR.RoutePlan.Custompath.HelpText:SetFrameStrata("MEDIUM")
    APR.RoutePlan.Custompath.HelpText:SetResizable(true)
    APR.RoutePlan.Custompath.HelpText:SetScale(0.7)
    APR.RoutePlan.Custompath.HelpText:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 0, 25)
    local t = APR.RoutePlan.Custompath.HelpText:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetAllPoints(APR.RoutePlan.Custompath.HelpText)
    t:SetColorTexture(0.1, 0.1, 0.4, 1)

    APR.RoutePlan.Custompath.HelpText.texture = t
    APR.RoutePlan.Custompath.HelpText.FS = APR.RoutePlan.Custompath.HelpText:CreateFontString("APR.RoutePlan_Help_Text", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.HelpText.FS:SetParent(APR.RoutePlan.Custompath.HelpText)
    APR.RoutePlan.Custompath.HelpText.FS:SetPoint("TOP", APR.RoutePlan.Custompath.HelpText, "TOP", 5, 1)
    APR.RoutePlan.Custompath.HelpText.FS:SetText(L["MOVE_ZONE"])
    APR.RoutePlan.Custompath.HelpText:SetWidth(APR.RoutePlan.Custompath.HelpText.FS:GetStringWidth() * 1.5)
    APR.RoutePlan.Custompath.HelpText.FS:SetWidth(APR.RoutePlan.Custompath.HelpText:GetWidth() - 10)
    APR.RoutePlan.Custompath.HelpText.FS:SetHeight(20)
    APR.RoutePlan.Custompath.HelpText.FS:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.HelpText.FS:SetFontObject("GameFontNormal")

    APR.RoutePlan.Custompath["CloseButton"] = CreateFrame("Button", "APR_RoutePlan_FG1_CloseButton", APR.RoutePlan.Custompath,
        "UIPanelButtonTemplate")
    APR.RoutePlan.Custompath["CloseButton"]:SetWidth(20)
    APR.RoutePlan.Custompath["CloseButton"]:SetHeight(20)
    APR.RoutePlan.Custompath["CloseButton"]:SetText("X")
    APR.RoutePlan.Custompath["CloseButton"]:SetPoint("TOPRIGHT", APR.RoutePlan.Custompath, "TOPRIGHT", 680, 20)
    APR.RoutePlan.Custompath["CloseButton"]:SetNormalFontObject("GameFontNormalLarge")
    APR.RoutePlan.Custompath["CloseButton"]:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            APR.RoutePlan.Custompath:Hide()
        end
    end)
    APR.RoutePlan.Custompath:Hide()

    --Custom Path
    APR.RoutePlan.Custompath.CPF = CreateFrame("frame", "APR.RoutePlanCustomPathFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.CPF:SetWidth(165)
    APR.RoutePlan.Custompath.CPF:SetHeight(275)
    APR.RoutePlan.Custompath.CPF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.CPF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, 0)
    local t = APR.RoutePlan.Custompath.CPF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.CPF)
    APR.RoutePlan.Custompath.CPF.texture = t
    APR.RoutePlan.Custompath.CPF:SetScript("OnMouseDown", function(self, button) --When mouse pressed
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.CPF:SetScript("OnMouseUp", function(self, button) -- When mouse released after being pressed
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.CPF:SetScript("OnHide",
        function(self) -- prevent routeplan from being movable or resizable when hidden, since you can't see it anyways
            if (APR.RoutePlan.isMoving) then
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)

    APR.RoutePlan.Custompath.CPT = CreateFrame("frame", "APR.RoutePlanCustomPathTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.CPT:SetWidth(165)
    APR.RoutePlan.Custompath.CPT:SetHeight(20)
    APR.RoutePlan.Custompath.CPT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.CPT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 0, 0)
    local t = APR.RoutePlan.Custompath.CPT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.CPT)
    APR.RoutePlan.Custompath.CPT.texture = t
    APR.RoutePlan.Custompath.CPT:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.CPT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.CPT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.CPT["FS"] = APR.RoutePlan.Custompath.CPT:CreateFontString("APR.RoutePlanCustomPathTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.CPT["FS"]:SetParent(APR.RoutePlan.Custompath.CPT)
    APR.RoutePlan.Custompath.CPT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.CPT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.CPT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.CPT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.CPT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.CPT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.CPT["FS"]:SetText(L["CUSTOM_PATH"])

    --Kalimdor
    APR.RoutePlan.Custompath.KALF = CreateFrame("frame", "APR.RoutePlanKalimdorFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.KALF:SetWidth(165)
    APR.RoutePlan.Custompath.KALF:SetHeight(275)
    APR.RoutePlan.Custompath.KALF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.KALF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 165, 0)
    local t = APR.RoutePlan.Custompath.KALF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.KALF)
    APR.RoutePlan.Custompath.KALF.texture = t
    APR.RoutePlan.Custompath.KALF:SetScript("OnMouseDown", function(self, button) -- When mouse pressed
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.KALF:SetScript("OnMouseUp", function(self, button) -- When mouse released after being pressed
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.KALF:SetScript("OnHide",
        function(self) -- prevent routeplan from being movable or resizable when hidden, since you can't see it anyways
            if (APR.RoutePlan.isMoving) then
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)

    APR.RoutePlan.Custompath.KALT = CreateFrame("frame", "APR.RoutePlanKalimdorTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.KALT:SetWidth(165)
    APR.RoutePlan.Custompath.KALT:SetHeight(20)
    APR.RoutePlan.Custompath.KALT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.KALT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 165, 0)
    local t = APR.RoutePlan.Custompath.KALT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.KALT)
    APR.RoutePlan.Custompath.KALT.texture = t
    APR.RoutePlan.Custompath.KALT:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.KALT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.KALT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.KALT["FS"] = APR.RoutePlan.Custompath.KALT:CreateFontString("APR.RoutePlanKalimdorTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.KALT["FS"]:SetParent(APR.RoutePlan.Custompath.KALT)
    APR.RoutePlan.Custompath.KALT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.KALT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.KALT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.KALT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.KALT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.KALT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.KALT["FS"]:SetText("Kalimdor")

    --EasternKingdoms
    APR.RoutePlan.Custompath.EKF = CreateFrame("frame", "APR.RoutePlanEasternKingdomsframe", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.EKF:SetWidth(165)
    APR.RoutePlan.Custompath.EKF:SetHeight(275)
    APR.RoutePlan.Custompath.EKF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.EKF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 330, 0)
    local t = APR.RoutePlan.Custompath.EKF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.EKF)
    APR.RoutePlan.Custompath.EKF.texture = t
    APR.RoutePlan.Custompath.EKF:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EKF:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EKF:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)

    APR.RoutePlan.Custompath.EKT = CreateFrame("frame", "APR.RoutePlanEasternKingdomsTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.EKT:SetWidth(165)
    APR.RoutePlan.Custompath.EKT:SetHeight(20)
    APR.RoutePlan.Custompath.EKT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.EKT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 330, 0)
    local t = APR.RoutePlan.Custompath.EKT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.EKT)
    APR.RoutePlan.Custompath.EKT.texture = t
    APR.RoutePlan.Custompath.EKT:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.EKT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EKT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.EKT["FS"] = APR.RoutePlan.Custompath.EKT:CreateFontString("APR.RoutePlanEasternKingdomsTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.EKT["FS"]:SetParent(APR.RoutePlan.Custompath.EKT)
    APR.RoutePlan.Custompath.EKT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.EKT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.EKT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.EKT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.EKT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.EKT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.EKT["FS"]:SetText("Eastern Kingdoms")

    --Shadowlands
    APR.RoutePlan.Custompath.SLF = CreateFrame("frame", "APR.RoutePlanShadowlandsFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.SLF:SetWidth(165)
    APR.RoutePlan.Custompath.SLF:SetHeight(275)
    APR.RoutePlan.Custompath.SLF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.SLF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 495, -293)
    local t = APR.RoutePlan.Custompath.SLF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.SLF)
    APR.RoutePlan.Custompath.SLF.texture = t
    APR.RoutePlan.Custompath.SLF:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.SLF:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.SLF:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)

    APR.RoutePlan.Custompath.SLT = CreateFrame("frame", "APR.RoutePlanShadowlandsTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.SLT:SetWidth(165)
    APR.RoutePlan.Custompath.SLT:SetHeight(20)
    APR.RoutePlan.Custompath.SLT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.SLT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 495, -293)
    local t = APR.RoutePlan.Custompath.SLT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.SLT)
    APR.RoutePlan.Custompath.SLT.texture = t
    APR.RoutePlan.Custompath.SLT:SetScript("OnMouseDown",
        function(self, button) --While right mouse button is clicked, allow the route plan to be moved around
            if button == "RightButton" then
                APR.RoutePlan:StartMoving();
                APR.RoutePlan.isMoving = true;
            else
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)
    APR.RoutePlan.Custompath.SLT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.SLT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.SLT["FS"] = APR.RoutePlan.Custompath.SLT:CreateFontString("APR.RoutePlanShadowlandsTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.SLT["FS"]:SetParent(APR.RoutePlan.Custompath.SLT)
    APR.RoutePlan.Custompath.SLT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.SLT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.SLT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.SLT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.SLT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.SLT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.SLT["FS"]:SetText("Shadowlands")

    --Extra
    APR.RoutePlan.Custompath.EXTF = CreateFrame("frame", "APR.RoutePlanExtraFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.EXTF:SetWidth(165)
    APR.RoutePlan.Custompath.EXTF:SetHeight(275)
    APR.RoutePlan.Custompath.EXTF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.EXTF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 330, -293)
    local t = APR.RoutePlan.Custompath.EXTF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.EXTF)
    APR.RoutePlan.Custompath.EXTF.texture = t
    APR.RoutePlan.Custompath.EXTF:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EXTF:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EXTF:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)

    APR.RoutePlan.Custompath.EXTT = CreateFrame("frame", "APR.RoutePlanExtraTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.EXTT:SetWidth(165)
    APR.RoutePlan.Custompath.EXTT:SetHeight(20)
    APR.RoutePlan.Custompath.EXTT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.EXTT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 330, -293)
    local t = APR.RoutePlan.Custompath.EXTT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.EXTT)
    APR.RoutePlan.Custompath.EXTT.texture = t
    APR.RoutePlan.Custompath.EXTT:SetScript("OnMouseDown",
        function(self, button) --While right mouse button is clicked, allow the route plan to be moved around
            if button == "RightButton" then
                APR.RoutePlan:StartMoving();
                APR.RoutePlan.isMoving = true;
            else
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)
    APR.RoutePlan.Custompath.EXTT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.EXTT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.EXTT["FS"] = APR.RoutePlan.Custompath.EXTT:CreateFontString("APR.RoutePlanExtraTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.EXTT["FS"]:SetParent(APR.RoutePlan.Custompath.EXTT)
    APR.RoutePlan.Custompath.EXTT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.EXTT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.EXTT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.EXTT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.EXTT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.EXTT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.EXTT["FS"]:SetText("WOD")

    -- Misc 1
    APR.RoutePlan.Custompath.MISC1F = CreateFrame("frame", "APR.RoutePlanMISC1Frame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.MISC1F:SetWidth(165)
    APR.RoutePlan.Custompath.MISC1F:SetHeight(275)
    APR.RoutePlan.Custompath.MISC1F:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.MISC1F:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -293)
    local t = APR.RoutePlan.Custompath.MISC1F:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.MISC1F)
    APR.RoutePlan.Custompath.MISC1F.texture = t
    APR.RoutePlan.Custompath.MISC1F:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC1F:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC1F:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)

    APR.RoutePlan.Custompath.MISC1T = CreateFrame("frame", "APR.RoutePlanMISC1Title", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.MISC1T:SetWidth(165)
    APR.RoutePlan.Custompath.MISC1T:SetHeight(20)
    APR.RoutePlan.Custompath.MISC1T:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.MISC1T:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 0, -293)
    local t = APR.RoutePlan.Custompath.MISC1T:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.MISC1T)
    APR.RoutePlan.Custompath.MISC1T.texture = t
    APR.RoutePlan.Custompath.MISC1T:SetScript("OnMouseDown",
        function(self, button) --While right mouse button is clicked, allow the route plan to be moved around
            if button == "RightButton" then
                APR.RoutePlan:StartMoving();
                APR.RoutePlan.isMoving = true;
            else
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)
    APR.RoutePlan.Custompath.MISC1T:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC1T:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.MISC1T["FS"] = APR.RoutePlan.Custompath.MISC1T:CreateFontString("APR.RoutePlanMISC1Title", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetParent(APR.RoutePlan.Custompath.MISC1T)
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.MISC1T, "TOP", 0, 0)
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.MISC1T["FS"]:SetText("MISC 1")

    -- Misc 2
    APR.RoutePlan.Custompath.MISC2F = CreateFrame("frame", "APR.RoutePlanMISC2Frame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.MISC2F:SetWidth(165)
    APR.RoutePlan.Custompath.MISC2F:SetHeight(275)
    APR.RoutePlan.Custompath.MISC2F:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.MISC2F:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 165, -293)
    local t = APR.RoutePlan.Custompath.MISC2F:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.MISC2F)
    APR.RoutePlan.Custompath.MISC2F.texture = t
    APR.RoutePlan.Custompath.MISC2F:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC2F:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC2F:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)

    APR.RoutePlan.Custompath.MISC2T = CreateFrame("frame", "APR.RoutePlanMISC2Title", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.MISC2T:SetWidth(165)
    APR.RoutePlan.Custompath.MISC2T:SetHeight(20)
    APR.RoutePlan.Custompath.MISC2T:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.MISC2T:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 165, -293)
    local t = APR.RoutePlan.Custompath.MISC2T:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.MISC2T)
    APR.RoutePlan.Custompath.MISC2T.texture = t
    APR.RoutePlan.Custompath.MISC2T:SetScript("OnMouseDown",
        function(self, button) --While right mouse button is clicked, allow the route plan to be moved around
            if button == "RightButton" then
                APR.RoutePlan:StartMoving();
                APR.RoutePlan.isMoving = true;
            else
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)
    APR.RoutePlan.Custompath.MISC2T:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.MISC2T:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.MISC2T["FS"] = APR.RoutePlan.Custompath.MISC2T:CreateFontString("APR.RoutePlanMISC2Title", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetParent(APR.RoutePlan.Custompath.MISC2T)
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.MISC2T, "TOP", 0, 0)
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.MISC2T["FS"]:SetText("MISC 2")

    --Dragonflight
    APR.RoutePlan.Custompath.DFF = CreateFrame("frame", "APR.RoutePlanDragonflightFrame", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.DFF:SetWidth(165)
    APR.RoutePlan.Custompath.DFF:SetHeight(275)
    APR.RoutePlan.Custompath.DFF:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.DFF:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 495, 0)
    local t = APR.RoutePlan.Custompath.DFF:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.DFF)
    APR.RoutePlan.Custompath.DFF.texture = t
    APR.RoutePlan.Custompath.DFF:SetScript("OnMouseDown", function(self, button) -- When mouse pressed
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.DFF:SetScript("OnMouseUp", function(self, button) -- When mouse released after being pressed
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.DFF:SetScript("OnHide",
        function(self) -- prevent routeplan from being movable or resizable when hidden, since you can't see it anyways
            if (APR.RoutePlan.isMoving) then
                APR.RoutePlan:StopMovingOrSizing();
                APR.RoutePlan.isMoving = false;
            end
        end)

    APR.RoutePlan.Custompath.DFT = CreateFrame("frame", "APR.RoutePlanDragonflightTitle", APR.RoutePlan.Custompath)
    APR.RoutePlan.Custompath.DFT:SetWidth(165)
    APR.RoutePlan.Custompath.DFT:SetHeight(20)
    APR.RoutePlan.Custompath.DFT:SetFrameStrata("LOW")
    APR.RoutePlan.Custompath.DFT:SetPoint("BOTTOMLEFT", APR.RoutePlan.Custompath, "BOTTOMLEFT", 495, 0)
    local t = APR.RoutePlan.Custompath.DFT:CreateTexture(nil, "BACKGROUND")
    t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    t:SetAllPoints(APR.RoutePlan.Custompath.DFT)
    APR.RoutePlan.Custompath.DFT.texture = t
    APR.RoutePlan.Custompath.DFT:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            APR.RoutePlan:StartMoving();
            APR.RoutePlan.isMoving = true;
        else
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.DFT:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and APR.RoutePlan.isMoving then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
            APR.settings.profile.leftLiz = APR.RoutePlan:GetLeft()
            APR.settings.profile.topLiz = APR.RoutePlan:GetTop() - GetScreenHeight()
            APR.RoutePlan:ClearAllPoints()
            APR.RoutePlan:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APR.settings.profile.leftLiz,
                APR.settings.profile.topLiz)
        end
    end)
    APR.RoutePlan.Custompath.DFT:SetScript("OnHide", function(self)
        if (APR.RoutePlan.isMoving) then
            APR.RoutePlan:StopMovingOrSizing();
            APR.RoutePlan.isMoving = false;
        end
    end)
    APR.RoutePlan.Custompath.DFT["FS"] = APR.RoutePlan.Custompath.DFT:CreateFontString("APR.RoutePlanDragonflightTitle", "ARTWORK",
        "ChatFontNormal")
    APR.RoutePlan.Custompath.DFT["FS"]:SetParent(APR.RoutePlan.Custompath.DFT)
    APR.RoutePlan.Custompath.DFT["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath.DFT, "TOP", 0, 0)
    APR.RoutePlan.Custompath.DFT["FS"]:SetWidth(165)
    APR.RoutePlan.Custompath.DFT["FS"]:SetHeight(20)
    APR.RoutePlan.Custompath.DFT["FS"]:SetJustifyH("CENTER")
    APR.RoutePlan.Custompath.DFT["FS"]:SetFontObject("GameFontNormal")
    APR.RoutePlan.Custompath.DFT["FS"]:SetText("Dragonflight")


    -- Looks like here happens the magic to get the route for speedrun
    local zenr = APR.NumbRoutePlan("SpeedRun")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["SPR3" .. CLi] = CreateFrame("frame", "APR.RoutePlanSpeedRun3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["SPR3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["SPR3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["SPR3" .. CLi].texture = t
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["SPR3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["SPR3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]
                        :GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.RoutePlan.Custompath["SPR3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["SPR3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["SPR3" .. CLi].isMoving = false;
                APR.CheckPosMove(5)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["SPR3" .. CLi]:SetScript("OnHide", function(self)
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"] = APR.RoutePlan.Custompath["SPR3" .. CLi]:CreateFontString(
            "APR.RoutePlanSpeedRun3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["SPR3" .. CLi])
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["SPR3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["SPR3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    local zenr = APR.NumbRoutePlan("EasternKingdom")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["EK3" .. CLi] = CreateFrame("frame", "APR.RoutePlanEasternKingdoms3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["EK3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["EK3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["EK3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["EK3" .. CLi].texture = t
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["EK3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["EK3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.RoutePlan.Custompath["EK3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["EK3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["EK3" .. CLi].isMoving = false;
                APR.CheckPosMove(1)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["EK3" .. CLi]:SetScript("OnHide", function(self)
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"] = APR.RoutePlan.Custompath["EK3" .. CLi]:CreateFontString(
            "APR.RoutePlanEasternKingdoms3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["EK3" .. CLi])
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["EK3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["EK3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    local zenr = APR.NumbRoutePlan("Kalimdor")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["KAL3" .. CLi] = CreateFrame("frame", "APR.RoutePlanKalimdor3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["KAL3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["KAL3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["KAL3" .. CLi].texture = t
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetScript("OnMouseDown", function(self, button) --On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["KAL3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["KAL3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]
                        :GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["KAL3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["KAL3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["KAL3" .. CLi].isMoving = false;
                APR.CheckPosMove(3)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["KAL3" .. CLi]:SetScript("OnHide", function(self) -- Prevent from moving while hidden
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"] = APR.RoutePlan.Custompath["KAL3" .. CLi]:CreateFontString(
            "APR.RoutePlanKalimdor3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["KAL3" .. CLi])
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["KAL3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["KAL3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    local zenr = APR.NumbRoutePlan("Shadowlands")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["SL3" .. CLi] = CreateFrame("frame", "APR.RoutePlanShadowlands3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["SL3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["SL3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["SL3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["SL3" .. CLi].texture = t
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetScript("OnMouseDown", function(self, button) -- On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["SL3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["SL3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["SL3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["SL3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["SL3" .. CLi].isMoving = false;
                APR.CheckPosMove(4)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["SL3" .. CLi]:SetScript("OnHide", function(self) --Prevent moving on hide
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"] = APR.RoutePlan.Custompath["SL3" .. CLi]:CreateFontString(
            "APR.RoutePlanShadowlands3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["SL3" .. CLi])
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["SL3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["SL3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    local zenr = APR.NumbRoutePlan("Extra")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["EX3" .. CLi] = CreateFrame("frame", "APR.RoutePlanExtra3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["EX3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["EX3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["EX3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["EX3" .. CLi].texture = t
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetScript("OnMouseDown", function(self, button) -- On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["EX3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["EX3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["EX3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["EX3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["EX3" .. CLi].isMoving = false;
                APR.CheckPosMove(4)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["EX3" .. CLi]:SetScript("OnHide", function(self) --Prevent moving on hide
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"] = APR.RoutePlan.Custompath["EX3" .. CLi]:CreateFontString(
            "APR.RoutePlanExtra3" .. CLi,
            "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["EX3" .. CLi])
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["EX3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["EX3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    local zenr = APR.NumbRoutePlan("MISC 1")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["MISC3" .. CLi] = CreateFrame("frame", "APR.RoutePlanMISC3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["MISC3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["MISC3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["MISC3" .. CLi].texture = t
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetScript("OnMouseDown", function(self, button) -- On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["MISC3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["MISC3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]
                        :GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["MISC3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["MISC3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["MISC3" .. CLi].isMoving = false;
                APR.CheckPosMove(4)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["MISC3" .. CLi]:SetScript("OnHide", function(self) --Prevent moving on hide
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"] = APR.RoutePlan.Custompath["MISC3" .. CLi]:CreateFontString(
            "APR.RoutePlanMISC3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["MISC3" .. CLi])
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["MISC3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["MISC3" .. CLi]["FS"]:SetText("Group " .. CLi)
    end

    local zenr = APR.NumbRoutePlan("MISC 2")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["MISC23" .. CLi] = CreateFrame("frame", "APR.RoutePlanMISC2" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["MISC23" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["MISC23" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["MISC23" .. CLi].texture = t
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetScript("OnMouseDown", function(self, button) -- On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["MISC23" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["MISC23" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]
                        :GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["MISC23" .. CLi].isMoving then
                APR.RoutePlan.Custompath["MISC23" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["MISC23" .. CLi].isMoving = false;
                APR.CheckPosMove(4)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["MISC23" .. CLi]:SetScript("OnHide", function(self) --Prevent moving on hide
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"] = APR.RoutePlan.Custompath["MISC23" .. CLi]:CreateFontString(
            "APR.RoutePlanMISC23" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["MISC23" .. CLi])
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["MISC23" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["MISC23" .. CLi]["FS"]:SetText("Group " .. CLi)
    end

    local zenr = APR.NumbRoutePlan("Dragonflight")
    for CLi = 1, zenr do
        APR.RoutePlan.Custompath["DF3" .. CLi] = CreateFrame("frame", "APR.RoutePlanDragonflight3" .. CLi, APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["DF3" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["DF3" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["DF3" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["DF3" .. CLi].texture = t
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetScript("OnMouseDown", function(self, button) --On clicked
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["DF3" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["DF3" .. CLi].isMoving = true;
            elseif button == "RightButton" then
                local zenew = getn(APR_Custom[APR.Username .. "-" .. APR.Realm]) + 1
                if (zenew < 19 or zenew == 19) then
                    tinsert(APR_Custom[APR.Username .. "-" .. APR.Realm], APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]["FS"]:SetText(APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:GetText())
                    APR.RoutePlan.Custompath["Fxz2Custom" .. zenew]:Show()
                end
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetScript("OnMouseUp", function(self, button) -- On click release
            if button == "LeftButton" and APR.RoutePlan.Custompath["DF3" .. CLi].isMoving then
                APR.RoutePlan.Custompath["DF3" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["DF3" .. CLi].isMoving = false;
                APR.CheckPosMove(3)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["DF3" .. CLi]:SetScript("OnHide", function(self) -- Prevent from moving while hidden
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"] = APR.RoutePlan.Custompath["DF3" .. CLi]:CreateFontString(
            "APR.RoutePlanKalimdor3" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["DF3" .. CLi])
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["DF3" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["DF3" .. CLi]["FS"]:SetText(L["GROUP"] .. CLi)
    end

    for CLi = 1, 19 do
        APR.RoutePlan.Custompath["FxzCustom" .. CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xxxsc" .. CLi,
            APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetWidth(25)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", -18, -((20 * CLi) - 17))
        local t = APR.RoutePlan.Custompath["FxzCustom" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["FxzCustom" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi].texture = t
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"] = APR.RoutePlan.Custompath["FxzCustom" .. CLi]:CreateFontString(
            "APR.RoutePlan_Fx3x_FFGs1S" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["FxzCustom" .. CLi])
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["FxzCustom" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetWidth(25)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetJustifyH("CENTER")
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        APR.RoutePlan.Custompath["FxzCustom" .. CLi]["FS"]:SetText(CLi)

        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi] = CreateFrame("frame", "APR.RoutePlanMainFsramex2xc2x" .. CLi,
            APR.RoutePlan.Custompath)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetWidth(225)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetHeight(20)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetMovable(true)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:EnableMouse(true)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetFrameStrata("MEDIUM")
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetResizable(true)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetScale(0.7)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetPoint("TOPLEFT", APR.RoutePlan.Custompath, "TOPLEFT", 0, -(20 * CLi))
        local t = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetAllPoints(APR.RoutePlan.Custompath["Fxz2Custom" .. CLi])
        t:SetColorTexture(0.1, 0.1, 0.4, 1)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].texture = t

        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:StartMoving();
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].isMoving = true;
            end
        end)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].isMoving then
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].isMoving = false;
                APR.CheckPosMove(2)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            else
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
                APR.FP.QuedFP = nil
                APR.CheckPosMove(2)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].isMoving then
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:StopMovingOrSizing();
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi].isMoving = false;
                APR.CheckPosMove(2)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            else
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
                APR.FP.QuedFP = nil
                APR.CheckPosMove(2)
                APR.RoutePlanCheckPos()
                APR.CheckCustomEmpty()
            end
        end)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:SetScript("OnHide", function(self)
            if (APR.RoutePlan.Custompath.isMoving) then
                APR.RoutePlan.Custompath:StopMovingOrSizing();
                APR.RoutePlan.Custompath.isMoving = false;
            end
        end)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"] = APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:CreateFontString(
            "APR.RoutePlan_Fx3x_FFGs21Sx" .. CLi, "ARTWORK", "ChatFontNormal")
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetParent(APR.RoutePlan.Custompath["Fxz2Custom" .. CLi])
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetPoint("TOP", APR.RoutePlan.Custompath["Fxz2Custom" .. CLi], "TOP", 0, 1)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetWidth(210)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetHeight(20)
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetJustifyH("LEFT")
        APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetFontObject("GameFontNormal")
        if (APR_Custom[APR.Username .. "-" .. APR.Realm] and APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]) then
            if (APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]]) then
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
            else
                if (APR_Custom[APR.Username .. "-" .. APR.Realm] and APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]) then
                    local zew = APR.QuestStepListListingZone[APR_Custom[APR.Username .. "-" .. APR.Realm][CLi]]
                    if (APR["EasternKingdomDB"] and APR["EasternKingdomDB"][zew] and IsAddOnLoaded("APR-EasternKingdoms") == false) then
                        local loaded, reason = LoadAddOn("APR-Vanilla")
                        if (not loaded) then
                            if (reason == "DISABLED") then
                                print("APR: APR - Eastern Kingdoms " .. L["DISABLED_ADDON_LIST"])
                            end
                        end
                    end
                    if (APR["BattleForAzeroth"] and APR["BattleForAzeroth"][zew] and IsAddOnLoaded("APR-BattleForAzeroth") == false) then
                        local loaded, reason = LoadAddOn("APR-BattleForAzeroth")
                        if (not loaded) then
                            if (reason == "DISABLED") then
                                print("APR: APR - BattleForAzeroth " .. L["DISABLED_ADDON_LIST"])
                            end
                        end
                    end
                    if (APR["Kalimdor"] and APR["Kalimdor"][zew] and IsAddOnLoaded("APR-Vanilla") == false) then
                        local loaded, reason = LoadAddOn("APR-Vanilla")
                        if (not loaded) then
                            if (reason == "DISABLED") then
                                print("APR: APR - Vanilla " .. L["DISABLED_ADDON_LIST"])
                            end
                        end
                    end
                    if (APR["Legion"] and APR["Legion"][zew] and IsAddOnLoaded("APR-Legion") == false) then
                        local loaded, reason = LoadAddOn("APR-Legion")
                        if (not loaded) then
                            if (reason == "DISABLED") then
                                print("APR: APR - Legion " .. L["DISABLED_ADDON_LIST"])
                            end
                        end
                    end
                    if (APR["ShadowlandsDB"] and APR["ShadowlandsDB"][zew] and IsAddOnLoaded("APR-Shadowlands") == false) then
                        local loaded, reason = LoadAddOn("APR-Shadowlands")
                        if (not loaded) then
                            if (reason == "DISABLED") then
                                print("APR: APR - Shadowlands " .. L["DISABLED_ADDON_LIST"])
                            end
                        end
                    end
                end
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText(APR_Custom[APR.Username .. "-" .. APR.Realm][CLi])
                APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Show()
            end
        else
            APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]["FS"]:SetText("")
            APR.RoutePlan.Custompath["Fxz2Custom" .. CLi]:Hide()
        end
    end

    local zenr2 = 0
    local dzer = {}
    local dzer2 = {}
    if (APR.QuestStepListListingStartAreas["Kalimdor"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListingStartAreas["Kalimdor"]) do
            dzer2[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer2) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["KAL3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end
    if (APR.QuestStepListListing and APR.QuestStepListListing["Kalimdor"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Kalimdor"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["KAL3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListingStartAreas["EasternKingdom"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListingStartAreas["EasternKingdom"]) do
            dzer2[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer2) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["EK3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end
    if (APR.QuestStepListListing and APR.QuestStepListListing["EasternKingdom"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["EasternKingdom"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["EK3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["Shadowlands"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Shadowlands"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["SL3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["Extra"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Extra"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["EX3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["MISC 2"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["MISC 2"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["MISC23" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["MISC 1"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["MISC 1"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["MISC3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["Dragonflight"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["Dragonflight"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["DF3" .. zenr2]["FS"]:SetText(APR_index2)
        end
    end

    zenr2 = 0
    dzer = nil
    dzer = {}
    dzer2 = nil
    dzer2 = {}
    if (APR.QuestStepListListing and APR.QuestStepListListing["SpeedRun"]) then
        for APR_index2, APR_value2 in PairsByKeys(APR.QuestStepListListing["SpeedRun"]) do
            dzer[APR_value2] = APR_index2
        end
        for APR_index2, APR_value2 in PairsByKeys(dzer) do
            zenr2 = zenr2 + 1
            APR.RoutePlan.Custompath["SPR3" .. zenr2]["FS"]:SetText("")
        end
    end

    APR.RoutePlanCheckPos()
    APR.CheckPosMove()
end