local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR Route module
APR.routeconfig = APR:NewModule("routeconfig", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local alliance = "Alliance"
local horde = "Horde"

local optionsWidth = 1.2
local lineColor = { 105 / 255, 105 / 255, 105 / 255, 0.4 }
local customPathListeWidget = nil
local tabRouteListWidget = nil
local currentTabName = nil
---------------------------------------------------------------------------------------
------------------------- Config functionality for Route ------------------------------
---------------------------------------------------------------------------------------

local function GetConfigOptionTable()
    local routeOptions = {
        name = L["ROUTE_HELPER"],
        type = "group",
        inline = false,
        order = 0,
        args = {
            speedrun_prefab = {
                order = 1.0,
                name = L["SPEEDRUN"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end
            },
            WoD_prefab = {
                order = 1.1,
                name = "Warlords of Draenor - Only",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetWODPrefab()
                end
            },
            BFA_prefab = {
                order = 1.2,
                name = "Battle for Azeroth - Only",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetBFAPrefab()
                end
            },
            SL_prefab = {
                order = 1.3,
                name = "Shadowlands - Only",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetSLPrefab()
                end
            },
            DF_prefab = {
                order = 1.4,
                name = "Dragonflight - Only",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                    APR.routeconfig:GetDFPrefab()
                end,
                hidden = function()
                    return APR.Level < 58
                end,
            },
            reset_custom_path = {
                order = 1.5,
                name = "Clean Custom Path",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
                end
            },
            custom_path_area = {
                order = 2,
                name = L["CUSTOM_PATH"],
                type = "group",
                inline = true,
                args = {
                    route = {
                        type = "input",
                        name = "custom_path_area",
                        dialogControl = "CustomPathRouteListFrame",
                    },
                }
            },
            Vanilla = {
                order = 3,
                name = "Vanilla",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Vanilla",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            TheBurningCrusade = {
                order = 4,
                name = "Burning Crusade",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "TheBurningCrusade",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            WrathOfTheLichKing = {
                order = 5,
                name = "Wrath of the Lich King",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "WrathOfTheLichKing",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Cataclysm = {
                order = 6,
                name = "Cataclysm",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Cataclysm",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            MistsOfPandaria = {
                order = 7,
                name = "Mists of Pandaria",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "MistsOfPandaria",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            WarlordsOfDraenor = {
                order = 8,
                name = "Warlords of Draenor",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "WarlordsOfDraenor",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Legion = {
                order = 9,
                name = "Legion",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Legion",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            BattleForAzeroth = {
                order = 10,
                name = "Battle for Azeroth",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "BattleForAzeroth",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Shadowlands = {
                order = 11,
                name = "Shadowlands",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Shadowlands",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Dragonflight = {
                order = 12,
                name = "Dragonflight",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Dragonflight",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
        }
    }


    return routeOptions
end

local function CreateCustomPathTableFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(600, 35)
    frame:SetPoint("CENTER")

    -- Create a ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()
    frame.scrollFrame = scrollFrame

    -- Create a content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(600, 35)
    scrollFrame:SetScrollChild(contentFrame)
    frame.contentFrame = contentFrame

    local idColumn = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idColumn:SetPoint("TOPLEFT", 10, 0)
    idColumn:SetText("ID")

    local nameColumn = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameColumn:SetPoint("TOPLEFT", idColumn, "TOPRIGHT", 50, 0)
    nameColumn:SetText("Name")

    return frame
end


function SetCustomPathListFrame(widget, name)
    customPathListeWidget = widget
    -- Hide the content before resetting the data
    if widget.fontStringsContainer then
        for _, container in ipairs(widget.fontStringsContainer) do
            container:Hide()
            container:ClearAllPoints()
            container:SetParent(nil)
        end
    else
        widget.fontStringsContainer = {}
    end

    local routes = APRCustomPath[APR.Username .. "-" .. APR.Realm]
    local yOffset = -15
    APRCustomPath[APR.Username .. "-" .. APR.Realm] = {}
    for _, routeName in ipairs(routes) do
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], routeName)
    end

    if #routes == 0 then
        local noRoutesContainer = CreateFrame("Frame", nil, widget.frame.contentFrame)
        noRoutesContainer:SetSize(600, 25)
        noRoutesContainer:SetPoint("TOPLEFT", 10, yOffset)

        local noRoutesID = noRoutesContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noRoutesID:SetPoint("LEFT")
        noRoutesID:SetText('-')
        local noRoutesText = noRoutesContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noRoutesText:SetPoint("LEFT", noRoutesID, "RIGHT", 50, 0)
        noRoutesText:SetText(L["NO_ROUTE"])

        -- Store the font string in the table
        tinsert(widget.fontStringsContainer, noRoutesContainer)
        widget.frame.contentFrame:SetSize(600, 35)
        widget.frame:SetSize(600, 35)
    else
        for i, route in ipairs(routes) do
            -- Create a container for each line
            local lineContainer = CreateFrame("Frame", nil, widget.frame.contentFrame)
            lineContainer:SetSize(600, 25)
            lineContainer:SetPoint("TOPLEFT", 10, yOffset)

            local borderTexture = lineContainer:CreateTexture(nil, "BACKGROUND")
            borderTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            borderTexture:SetSize(600, 1)
            borderTexture:SetPoint("TOPLEFT", lineContainer, "TOPLEFT", 0, 0)
            borderTexture:SetPoint("TOPRIGHT", lineContainer, "TOPRIGHT", 0, 0)
            borderTexture:SetVertexColor(unpack(lineColor))

            local routeID = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            routeID:SetPoint("LEFT")
            routeID:SetText(i)

            local nameText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("LEFT", routeID, "RIGHT", 50, 0)
            nameText:SetText(route)

            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route)
                GameTooltip:AddLine(L["MOVE_ZONE"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            lineContainer:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            lineContainer:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    tremove(APRCustomPath[APR.Username .. "-" .. APR.Realm], i)
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end
            end)

            yOffset = yOffset - 25
            tinsert(widget.fontStringsContainer, lineContainer)
        end
        widget.frame.contentFrame:SetSize(600, -yOffset)
        widget.frame:SetSize(600, (-yOffset < 200 and -yOffset or 200))
    end
    -- Reset the scroll position to the top
    widget.frame.scrollFrame:SetVerticalScroll(0)
end

local function CreateRouteTableFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(400, 25)
    frame:SetPoint("CENTER")

    local nameColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameColumn:SetPoint("TOPLEFT", 10, 0)
    nameColumn:SetText("Name")

    local statusColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusColumn:SetPoint("TOPRIGHT", -10, 0)
    statusColumn:SetText("Status")

    return frame
end

function SetRouteListTab(widget, name)
    tabRouteListWidget = widget
    -- Hide the content before resetting the data
    if widget.fontStringsContainer then
        for _, container in ipairs(widget.fontStringsContainer) do
            container:Hide()
            container:ClearAllPoints()
            container:SetParent(nil)
        end
    else
        widget.fontStringsContainer = {}
    end


    local routes = APR.QuestStepListListing[name]
    local sortedRoutes = {}
    local yOffset = -15

    -- Copy the routes into a new table for sorting
    for fileName, routeName in pairs(routes) do
        if not Contains(APRCustomPath[APR.Username .. "-" .. APR.Realm], routeName) then
            tinsert(sortedRoutes, { fileName = fileName, routeName = routeName })
        end
    end

    -- Sort the routes alphabetically by routeName
    table.sort(sortedRoutes, function(a, b)
        return a.routeName < b.routeName
    end)

    if #sortedRoutes == 0 then
        local noRoutesContainer = CreateFrame("Frame", nil, widget.frame)
        noRoutesContainer:SetSize(400, 25)
        noRoutesContainer:SetPoint("TOPLEFT", 10, yOffset)

        local noRoutesText = noRoutesContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noRoutesText:SetPoint("LEFT")
        noRoutesText:SetText(L["NO_ROUTE"])

        -- Store the font string in the table
        tinsert(widget.fontStringsContainer, noRoutesContainer)
    else
        for _, route in ipairs(sortedRoutes) do
            -- Create a container for each line
            local lineContainer = CreateFrame("Frame", nil, widget.frame, "BackdropTemplate")
            lineContainer:SetSize(430, 25)
            lineContainer:SetPoint("TOPLEFT", 10, yOffset)

            local borderTexture = lineContainer:CreateTexture(nil, "BACKGROUND")
            borderTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            borderTexture:SetSize(450, 1)
            borderTexture:SetPoint("TOPLEFT", lineContainer, "TOPLEFT", 0, 0)
            borderTexture:SetPoint("TOPRIGHT", lineContainer, "TOPRIGHT", 0, 0)
            borderTexture:SetVertexColor(unpack(lineColor))

            local nameText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("LEFT")
            nameText:SetText(route.routeName)

            local statusText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            statusText:SetPoint("RIGHT")
            statusText:SetText(APR_ZoneComplete[APR.Username .. "-" .. APR.Realm][route.routeName] and
                L["ROUTE_COMPLETED"] or
                "Unknow")

            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route.routeName)
                GameTooltip:AddLine(L["MOVE_ZONE"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            lineContainer:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            lineContainer:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], route.routeName)
                    APR.routeconfig:LoadRouteAddonFile(name)
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end
            end)

            yOffset = yOffset - 25

            tinsert(widget.fontStringsContainer, lineContainer)
        end
    end
    widget.frame:SetSize(400, -yOffset)
end

local function InitDialogControlFrame(Type, createFrameFunc, setLabelFunction)
    local function Constructor()
        local Widget = {}

        -- Container Frame
        local frame = createFrameFunc(Type)
        frame.obj = Widget

        -- Widget
        Widget.frame = frame
        Widget.type = Type
        Widget.num = AceGUI:GetNextWidgetNum(Type)

        -- Reccommended place to store ephemeral widget information.
        Widget.userdata = {}

        Widget.OnAcquire = function(self)
            self.resizing = true
            self:SetDisabled(true)
            self:SetFullWidth(true)
            self.resizing = nil
        end

        -- usefull to get set the data from the tab name
        Widget.SetLabel = function(self, name)
            currentTabName = name
            setLabelFunction(self, name)
        end

        -- Mandatory for ace3, but useless
        Widget.SetText = function(self) end
        Widget.OnWidthSet = function(self)
            if self.resizing then return end
            -- Whenever OnWidthSet() is called, adjust the height of the frames to contain all child frames.
            if self.AdjustHeightFunction then self:AdjustHeightFunction() end
        end
        -- Not sure if this is really necessary...
        Widget.SetDisabled = function(self, Disabled)
            self.disabled = Disabled
        end

        -- OnRelease gets called when hiding the widget.
        Widget.OnRelease = function(self)
            self:SetDisabled(true)
            self.frame:ClearAllPoints()
        end

        return AceGUI:RegisterAsWidget(Widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, 1)
end

function APR.routeconfig:InitRouteConfig()
    APR.routeconfig:RegisterMessage("APR_Custom_Path_Update", function()
        SetCustomPathListFrame(customPathListeWidget, "custom_path_area")
        SetRouteListTab(tabRouteListWidget, currentTabName)
        APR.settings:OpenSettings(L["ROUTE"])
        -- -- TODO: Check if needed
        -- APR.BookingList["UpdateMapId"] = true
    end)
    InitDialogControlFrame("CustomPathRouteListFrame", CreateCustomPathTableFrame, SetCustomPathListFrame)
    InitDialogControlFrame("RouteListFrame", CreateRouteTableFrame, SetRouteListTab)
    return GetConfigOptionTable()
end

---------------------------------------------------------------------------------------
----------------------------------- Prefab route --------------------------------------
---------------------------------------------------------------------------------------
function APR.routeconfig:GetSpeedRunPrefab()
    self:GetStartingZonePrefab()
    if APR.Level < 58 then
        self:GetWODPrefab()
    end
    self:GetDFPrefab()
end

function APR.routeconfig:GetStartingZonePrefab()
    -- Get player position for Exile's Reach (maybe move this to PlayerPosition util function)
    local playerMapId
    local currentMapId = C_Map.GetBestMapForUnit('player')
    if currentMapId and Enum and Enum.UIMapType and Enum.UIMapType.Continent then
        playerMapId = MapUtil.GetMapParentInfo(currentMapId, Enum.UIMapType.Continent + 1, true)
        playerMapId = playerMapId.mapID or currentMapId
    end

    if APR.Level < 10 and Contains({ 1409, 1726, 1727 }, playerMapId) then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "01-10 Exile's Reach")
    elseif APR.Level < 30 then
        if APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23 then -- Allied DK
            tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "Allied Death Knight Start")
        elseif APR.ClassId == APR.Classes["Death Knight"] then                  -- DK
            tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "Death Knight Start")
        elseif APR.ClassId == APR.Classes["Demon Hunter"] then
            tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "Demon Hunter Start")
        end
    elseif APR.Level >= 58 and APR.ClassId == APR.Classes["Dracthyr"] then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "Dracthyr Start")
    end
    self:LoadRouteAddonFile("WrathOfTheLichKing")
    self:LoadRouteAddonFile("Legion")
    self:LoadRouteAddonFile("Shadowlands")
    self:LoadRouteAddonFile("Dragonflight")
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetWODPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD01 - Stormwind")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD02 - Tanaan Jungle")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD03 - Shadowmoon")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD04 - Gorgrond")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD05 - Talador")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD06 - Shadowmoon")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD07 - Talador")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD08 - Spires of Arak")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD01 - Orgrimmar")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD02 - Tanaan Jungle")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD03 - Frostfire Ridge")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD04 - Gorgrond")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD05 - Talador")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD06 - Spires of Arak")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "WOD07 - Nagrand")
    end
    self:LoadRouteAddonFile("WarlordsOfDraenor")
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetBFAPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA01 - Intro")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA02 - Tiragarde Sound")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA03 - Dustvar")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA04 - Stormsong Valley")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA01 - Intro")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA02 - Intro")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA03 - Zuldazar")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA04 - Nazmir")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA05 - Naz-end Vol-begin")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "BFA06 - Vol'dun")
    end
    self:LoadRouteAddonFile("BattleForAzeroth")
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetSLPrefab()
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL - Intro")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL01 - The Maw")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL02 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL03 - Bastion")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL04 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL05 - Maldraxxus")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL06 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL07 - The Maw")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL08 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL09 - Maldraxxus")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL10 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL11 - Ardenweald")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL12 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL13 - Revendreth")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL14 - The Maw")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL15 - Revendreth")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL16 - Oribos")
    tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "SL - StoryMode Only")
    self:LoadRouteAddonFile("Shadowlands")
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetDFPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF01 - Dragonflight Stormwind")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF02 - Waking Shores - Alliance")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF03 - Waking Shores - Neutral")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF04 - Ohn'Ahran Plains")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF05 - Azure Span")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF06 - Thaldraszus")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF01/02 - Dragonflight Orgrimmar/Durotar")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF03 - Waking Shores - Horde")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF04 - Waking Shores - Neutral")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF05 - Ohn'Ahran Plains")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF06 - Azure Span")
        tinsert(APRCustomPath[APR.Username .. "-" .. APR.Realm], "DF07 - Thaldraszus")
    end
    self:LoadRouteAddonFile("Dragonflight")
    self:SendMessage("APR_Custom_Path_Update")
end

---------------------------------------------------------------------------------------
------------------------------ Route config function ----------------------------------
---------------------------------------------------------------------------------------

--Loads addon if needed for a route
function APR.routeconfig:LoadRouteAddonFile(tabName)
    if APRCustomPath[APR.Username .. "-" .. APR.Realm] then
        local function checkAddon(zoneName, addonName)
            if tabName == zoneName and not C_AddOns.IsAddOnLoaded(addonName) then
                local loaded, _ = C_AddOns.LoadAddOn(addonName)
                if not loaded then
                    C_AddOns.EnableAddOn(addonName, UnitName("player"))
                    C_AddOns.SaveAddOns()
                    print("APR: " .. addonName .. L["DISABLED_ADDON_LIST"])
                end
            end
        end
        checkAddon("Vanilla", "APR-Vanilla")
        checkAddon("TheBurningCrusade", "APR-TheBurningCrusade") -- No route
        checkAddon("WrathOfTheLichKing", "APR-WrathOfTheLichKing")
        checkAddon("Cataclysm", "APR-Vanilla")                   -- No route
        checkAddon("MistsOfPandaria", "APR-MistsOfPandaria")
        checkAddon("WarlordsOfDraenor", "APR-WarlordsOfDraenor")
        checkAddon("Legion", "APR-Legion")
        checkAddon("BattleForAzeroth", "APR-BattleForAzeroth")
        checkAddon("Shadowlands", "APR-ExilesReach")
        checkAddon("Shadowlands", "APR-Shadowlands")
        checkAddon("Dragonflight", "APR-Dragonflight")
    end
end
