local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR Route module
APR.routeconfig = APR:NewModule("routeconfig", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local alliance = "Alliance"
local horde = "Horde"

local optionsWidth = 1.2
local lineColor = APR.Color.grayAlpha
local customPathListeWidget = nil
local tabRouteListWidget = nil
local currentTabName = nil

local notSkippableRoute = { "01-10 Exile's Reach", "Goblin - Lost Isles", "Dracthyr Start", "Pandaren Neutral Start",
    "Allied Death Knight Start", "Death Knight Start", "Demon Hunter Start", "Worgen Start" }
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
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end
            },
            Event_prefab = {
                order = 1.1,
                name = "Event",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                end,
                hidden = true
            },
            WoD_prefab = {
                order = 1.2,
                name = "Warlords of Draenor",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetWODPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.WarlordsOfDraenor)
                end,

            },
            BFA_prefab = {
                order = 1.3,
                name = "Battle for Azeroth",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetBFAPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.BattleForAzeroth)
                end,
            },
            SL_prefab = {
                order = 1.4,
                name = "Shadowlands",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSLPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.Shadowlands)
                end
            },
            DF_prefab = {
                order = 1.5,
                name = "Dragonflight",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetDFPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.Dragonflight)
                end
            },
            TWW_prefab = {
                order = 1.6,
                name = "The War Within",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetTWWPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.TheWarWithin)
                end
            },
            reset_custom_path = {
                order = 1.7,
                name = L["CLEAN_CUSTOM_PATH"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end,
                disabled = function()
                    return not next(APRCustomPath[APR.PlayerID])
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
            TheWarWithin = {
                order = 13,
                name = "The War Within",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "TheWarWithin",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Custom = {
                order = 14,
                name = "Custom",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        name = "Custom",
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
    scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
    scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
    frame.scrollFrame = scrollFrame

    -- Create a content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(600, 35)
    scrollFrame:SetScrollChild(contentFrame)
    frame.contentFrame = contentFrame

    local idColumn = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    idColumn:SetPoint("TOPLEFT", 10, 0)
    idColumn:SetText(L["ROUTE_ID"])

    local nameColumn = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameColumn:SetPoint("TOPLEFT", idColumn, "TOPRIGHT", 50, 0)
    nameColumn:SetText(L["ROUTE_NAME"])

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

    local routes = APRCustomPath[APR.PlayerID]
    local yOffset = -15
    APRCustomPath[APR.PlayerID] = {}
    for _, routeName in ipairs(routes) do
        tinsert(APRCustomPath[APR.PlayerID], routeName)
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
        widget.frame:SetSize(600, 40)
        widget.frame.contentFrame:SetSize(600, 40)
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

            local upButton = CreateFrame("Button", nil, lineContainer, "BackdropTemplate")
            upButton:SetSize(22, 22)
            upButton:SetPoint("RIGHT", lineContainer, "RIGHT", -10, 7)
            upButton:SetNormalTexture("interface/minimap/ui-minimap-minimizebuttonup-up")
            upButton:SetPushedTexture("interface/minimap/ui-minimap-minimizebuttonup-down")
            upButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")
            upButton:SetDisabledTexture("interface/minimap/ui-minimap-minimizebuttonup-disabled")
            upButton:SetScript("OnClick", function()
                tremove(APRCustomPath[APR.PlayerID], i)
                tinsert(APRCustomPath[APR.PlayerID], i - 1, route)
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            end)
            upButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route .. " - " .. L["UP"])
                GameTooltip:Show()
            end)
            upButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            if i == 1 then
                upButton:Disable()
            end

            local downButton = CreateFrame("Button", nil, lineContainer, "BackdropTemplate")
            downButton:SetSize(22, 22)
            downButton:SetPoint("RIGHT", lineContainer, "RIGHT", -10, -5)
            downButton:SetNormalTexture("interface/minimap/ui-minimap-minimizebuttondown-up")
            downButton:SetPushedTexture("interface/minimap/ui-minimap-minimizebuttondown-down")
            downButton:SetHighlightTexture("interface/buttons/ui-panel-minimizebutton-highlight")
            downButton:SetDisabledTexture("interface/minimap/ui-minimap-minimizebuttondown-disabled")
            downButton:SetScript("OnClick", function()
                tremove(APRCustomPath[APR.PlayerID], i)
                tinsert(APRCustomPath[APR.PlayerID], i + 1, route)
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            end)
            downButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(route .. " - " .. L["DOWN"])
                GameTooltip:Show()
            end)
            downButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            if i == #routes then
                downButton:Disable()
            end

            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route)
                GameTooltip:AddLine(L["REMOVE_ZONE_FROM_CUSTOM_PATH"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            lineContainer:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            lineContainer:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    tremove(APRCustomPath[APR.PlayerID], i)
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end
            end)

            yOffset = yOffset - 25
            tinsert(widget.fontStringsContainer, lineContainer)
        end
        local height = (-yOffset < 200 and -yOffset or 200)
        widget.frame:SetSize(600, height)
        widget.frame.contentFrame:SetSize(600, -yOffset)
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
    nameColumn:SetText(L["ROUTE_NAME"])

    local statusColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusColumn:SetPoint("TOPRIGHT", -10, 0)
    statusColumn:SetText(L["ROUTE_STATUS"])

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


    local routes = APR.RouteList[name]
    local sortedRoutes = {}
    local yOffset = -15

    -- Copy the routes into a new table for sorting
    for fileName, routeName in pairs(routes) do
        if not APR:Contains(APRCustomPath[APR.PlayerID], routeName) then
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
            lineContainer:SetPoint("TOPRIGHT", -10, yOffset)

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

            local status = ""
            if APRZoneCompleted[APR.PlayerID][route.routeName] then
                status = L["ROUTE_COMPLETED"]
            elseif APRData[APR.PlayerID][route.fileName] then
                if not APRData[APR.PlayerID][route.fileName .. '-TotalSteps'] then
                    APR:GetTotalSteps(route.fileName)
                end
                status = (APRData[APR.PlayerID][route.fileName] - (APRData[APR.PlayerID][route.fileName .. '-SkippedStep'] or 0)) ..
                    "/" .. APRData[APR.PlayerID][route.fileName .. '-TotalSteps']
            end
            statusText:SetText(status)

            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route.routeName)
                if IsRouteDisabled(name, route.routeName) then
                    GameTooltip:AddLine(L["ROUTE_DISABLED"], 1, 1, 1, true)
                else
                    GameTooltip:AddLine(L["MOVE_ROUTE_TO_CUSTOM_PATH"], 1, 1, 1, true)
                end
                GameTooltip:Show()
            end)
            lineContainer:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            lineContainer:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    if IsShiftKeyDown() then
                        APR:ResetRoute(route.fileName)
                    else
                        -- Check is the route is up to date
                        if APRData[APR.PlayerID][route.fileName] then
                            APR:CheckRouteChanges(route.fileName)
                        end
                    end
                    tinsert(APRCustomPath[APR.PlayerID], route.routeName)
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end
            end)
            if IsRouteDisabled(name, route.routeName) then
                nameText:SetTextColor(unpack(APR.Color.midGray))
                lineContainer:SetScript("OnMouseDown", nil)
            end

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
        if APR.OptionsRoute:IsVisible() then
            SetCustomPathListFrame(customPathListeWidget, "custom_path_area")
            SetRouteListTab(tabRouteListWidget, currentTabName)
            APR.settings:OpenSettings(L["ROUTE"])
        end

        -- to trigger the frame
        local routeZoneMapIDs, mapID, routeName, expansion = APR:GetCurrentRouteMapIDsAndName()
        APR.ActiveRoute = routeName
        APR:UpdateStep()
        APR.BookingList["UpdateMapId"] = true
    end)
    InitDialogControlFrame("CustomPathRouteListFrame", CreateCustomPathTableFrame, SetCustomPathListFrame)
    InitDialogControlFrame("RouteListFrame", CreateRouteTableFrame, SetRouteListTab)
    return GetConfigOptionTable()
end

function IsRouteDisabled(tab, routeName)
    if routeName == "01-10 Exile's Reach" and not APR:Contains({ 1409, 1726, 1727, 1728 }, APR:GetPlayerParentMapID()) then
        return true
    end
    return false
end

---------------------------------------------------------------------------------------
----------------------------------- Prefab route --------------------------------------
---------------------------------------------------------------------------------------
function APR.routeconfig:GetSpeedRunPrefab()
    self:GetStartingZonePrefab()
    -- Don't add other route if the player is neutral
    if APR.Faction == "Neutral" then return end
    if APR.Level >= APR.MinBoostLvl and APR.Level < APR.MaxLevelChromie then
        self:GetDFPrefab()
    elseif APR.Level < APR.MinBoostLvl then
        self:GetWODPrefab()
        self:GetDFPrefab()
    end
    self:GetTWWPrefab()
end

function APR.routeconfig:GetStartingZonePrefab()
    if APR:Contains({ 1409, 1726, 1727, 1728 }, APR:GetPlayerParentMapID()) then
        tinsert(APRCustomPath[APR.PlayerID], "01-10 Exile's Reach")
    elseif not (C_QuestLog.IsQuestFlaggedCompleted(59926) or C_QuestLog.IsQuestFlaggedCompleted(56775)) and (APR.Level < APR.MinBoostLvl or APR.Level < 10) then -- first quest from Exile's Reach + boost
        --None skipable starting zone
        if APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23 then                                                                                  -- Allied DK
            tinsert(APRCustomPath[APR.PlayerID], "Allied Death Knight Start")
        elseif APR.ClassId == APR.Classes["Death Knight"] then                                                                                                   -- DK
            tinsert(APRCustomPath[APR.PlayerID], "Death Knight Start")
        elseif APR.ClassId == APR.Classes["Demon Hunter"] then
            tinsert(APRCustomPath[APR.PlayerID], "Demon Hunter Start")
        elseif APR.Race == "Pandaren" then
            tinsert(APRCustomPath[APR.PlayerID], "Pandaren Neutral Start")
        elseif APR.Race == "Goblin" then
            tinsert(APRCustomPath[APR.PlayerID], "Goblin Start")
            tinsert(APRCustomPath[APR.PlayerID], "Goblin - Lost Isles")
        elseif APR.Race == "Worgen" then
            tinsert(APRCustomPath[APR.PlayerID], "Worgen Start")

            -- Horde Allied Race
        elseif APR.Race == "ZandalariTroll" then
            tinsert(APRCustomPath[APR.PlayerID], "Zandalari Troll Start")
        elseif APR.Race == "Vulpera" then
            tinsert(APRCustomPath[APR.PlayerID], "Vulpera Start")
        elseif APR.Race == "MagharOrc" then
            tinsert(APRCustomPath[APR.PlayerID], "Maghar Orc Start")
        elseif APR.Race == "Nightborne" then
            tinsert(APRCustomPath[APR.PlayerID], "Nightborne Start")
        elseif APR.Race == "Nightborne" then
            tinsert(APRCustomPath[APR.PlayerID], "Nightborne Start")
        elseif APR.Race == "HighmountainTauren" then
            tinsert(APRCustomPath[APR.PlayerID], "Highmountain Tauren Start")

            -- Alliance Allied Race
        elseif APR.Race == "VoidElf" then
            tinsert(APRCustomPath[APR.PlayerID], "Void Elf Start")
        elseif APR.Race == "LightforgedDraenei" then
            tinsert(APRCustomPath[APR.PlayerID], "Lightforged Draenei Start")
        elseif APR.Race == "DarkIronDwarf" then
            tinsert(APRCustomPath[APR.PlayerID], "DarkIron Dwarf Start")
        elseif APR.Race == "Mechagnome" then
            tinsert(APRCustomPath[APR.PlayerID], "Mechagnome Start")
        elseif APR.Race == "KulTiran" then
            tinsert(APRCustomPath[APR.PlayerID], "Kul Tiran Start")
        elseif APR.Race == "Dracthyr" then
            tinsert(APRCustomPath[APR.PlayerID], "Dracthyr Start")
        elseif APR.Race == "EarthenDwarf" then
            tinsert(APRCustomPath[APR.PlayerID], "Earthen Dwarf Start")
        elseif APR.Level < 10 then -- Skipable starting zone
            -- HORDE
            if (APR.Race == "Orc") then
                tinsert(APRCustomPath[APR.PlayerID], "Orc Start")
                tinsert(APRCustomPath[APR.PlayerID], "Durotar")
            elseif (APR.Race == "Tauren") then
                tinsert(APRCustomPath[APR.PlayerID], "Tauren Start") -- missing part 2
            elseif (APR.Race == "Troll") then
                tinsert(APRCustomPath[APR.PlayerID], "Troll Start")
                tinsert(APRCustomPath[APR.PlayerID], "Durotar")
            elseif (APR.Race == "Scourge") then --Undead
                tinsert(APRCustomPath[APR.PlayerID], "Undead Start")
            elseif (APR.Race == "BloodElf") then
                tinsert(APRCustomPath[APR.PlayerID], "Blood Elf Start") -- missing part 2
                -- ALLIANCE
            elseif (APR.Race == "NightElf") then
                tinsert(APRCustomPath[APR.PlayerID], "Night Elf Start")
                tinsert(APRCustomPath[APR.PlayerID], "Teldrassil")
            elseif (APR.Race == "Draenei") then
                tinsert(APRCustomPath[APR.PlayerID], "Draenei Start")
                tinsert(APRCustomPath[APR.PlayerID], "Azuremyst Isle")
                tinsert(APRCustomPath[APR.PlayerID], "Bloodmyst Isle")
            elseif (APR.Race == "Dwarf") then
                tinsert(APRCustomPath[APR.PlayerID], "Dwarf Start")
                tinsert(APRCustomPath[APR.PlayerID], "Dun Morogh")
            elseif (APR.Race == "Human") then
                tinsert(APRCustomPath[APR.PlayerID], "Human Start")
                tinsert(APRCustomPath[APR.PlayerID], "Elwynn Forest")
            elseif (APR.Race == "Gnome") then
                tinsert(APRCustomPath[APR.PlayerID], "Gnome Start")
                tinsert(APRCustomPath[APR.PlayerID], "Dun Morogh")
            end
        end
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetWODPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.PlayerID], "WOD01 - Stormwind")
        tinsert(APRCustomPath[APR.PlayerID], "WOD02 - Tanaan Jungle")
        tinsert(APRCustomPath[APR.PlayerID], "WOD03 - Shadowmoon")
        tinsert(APRCustomPath[APR.PlayerID], "WOD04 - Gorgrond")
        tinsert(APRCustomPath[APR.PlayerID], "WOD05 - Talador")
        tinsert(APRCustomPath[APR.PlayerID], "WOD06 - Shadowmoon")
        tinsert(APRCustomPath[APR.PlayerID], "WOD07 - Talador")
        tinsert(APRCustomPath[APR.PlayerID], "WOD08 - Spires of Arak")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.PlayerID], "WOD01 - Orgrimmar")
        tinsert(APRCustomPath[APR.PlayerID], "WOD02 - Tanaan Jungle")
        tinsert(APRCustomPath[APR.PlayerID], "WOD03 - Frostfire Ridge")
        tinsert(APRCustomPath[APR.PlayerID], "WOD04 - Gorgrond")
        tinsert(APRCustomPath[APR.PlayerID], "WOD05 - Talador")
        tinsert(APRCustomPath[APR.PlayerID], "WOD06 - Spires of Arak")
        tinsert(APRCustomPath[APR.PlayerID], "WOD07 - Nagrand")
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetBFAPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.PlayerID], "BFA01 - Intro")
        tinsert(APRCustomPath[APR.PlayerID], "BFA02 - Tiragarde Sound")
        tinsert(APRCustomPath[APR.PlayerID], "BFA03 - Dustvar")
        tinsert(APRCustomPath[APR.PlayerID], "BFA04 - Stormsong Valley")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.PlayerID], "BFA01 - Intro")
        tinsert(APRCustomPath[APR.PlayerID], "BFA02 - Zuldazar")
        tinsert(APRCustomPath[APR.PlayerID], "BFA03 - Nazmir")
        tinsert(APRCustomPath[APR.PlayerID], "BFA04 - Naz-end Vol-begin")
        tinsert(APRCustomPath[APR.PlayerID], "BFA05 - Vol'dun")
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetSLPrefab()
    tinsert(APRCustomPath[APR.PlayerID], "SL - Intro")
    tinsert(APRCustomPath[APR.PlayerID], "SL01 - The Maw")
    tinsert(APRCustomPath[APR.PlayerID], "SL02 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL03 - Bastion")
    tinsert(APRCustomPath[APR.PlayerID], "SL04 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL05 - Maldraxxus")
    tinsert(APRCustomPath[APR.PlayerID], "SL06 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL07 - The Maw")
    tinsert(APRCustomPath[APR.PlayerID], "SL08 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL09 - Maldraxxus")
    tinsert(APRCustomPath[APR.PlayerID], "SL10 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL11 - Ardenweald")
    tinsert(APRCustomPath[APR.PlayerID], "SL12 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL13 - Revendreth")
    tinsert(APRCustomPath[APR.PlayerID], "SL14 - The Maw")
    tinsert(APRCustomPath[APR.PlayerID], "SL15 - Revendreth")
    tinsert(APRCustomPath[APR.PlayerID], "SL16 - Oribos")
    tinsert(APRCustomPath[APR.PlayerID], "SL - StoryMode Only")
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetDFPrefab()
    if APR.Faction == alliance then
        tinsert(APRCustomPath[APR.PlayerID], "DF01 - Dragonflight Stormwind")
        tinsert(APRCustomPath[APR.PlayerID], "DF02 - Waking Shores - Alliance")
        tinsert(APRCustomPath[APR.PlayerID], "DF03 - Waking Shores - Neutral")
        tinsert(APRCustomPath[APR.PlayerID], "DF04 - Ohn'Ahran Plains")
        tinsert(APRCustomPath[APR.PlayerID], "DF05 - Azure Span")
        tinsert(APRCustomPath[APR.PlayerID], "DF06 - Thaldraszus")
    elseif APR.Faction == horde then
        tinsert(APRCustomPath[APR.PlayerID], "DF01/02 - Dragonflight Orgrimmar/Durotar")
        tinsert(APRCustomPath[APR.PlayerID], "DF03 - Waking Shores - Horde")
        tinsert(APRCustomPath[APR.PlayerID], "DF04 - Waking Shores - Neutral")
        tinsert(APRCustomPath[APR.PlayerID], "DF05 - Ohn'Ahran Plains")
        tinsert(APRCustomPath[APR.PlayerID], "DF06 - Azure Span")
        tinsert(APRCustomPath[APR.PlayerID], "DF07 - Thaldraszus")
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetTWWPrefab()
    -- Don't add TWW route if the player is neutral
    if APR.Faction == "Neutral" then return end

    tinsert(APRCustomPath[APR.PlayerID], "TWW - 01 - Intro")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 02 - Isle of Dorn")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 03 - Ringing Deeps")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 04 - Hallowfall")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 05 - Azj-Kahet")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 06 - Against the Current Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 07 - Ties That Bind Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 08 - News from Below Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 09 - The Machines March to War Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 10 - Light in the Dark Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 11 - Lingering Shadow Storyline")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - 12 - Fate of the Kirin Tor")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - Siren Isle Intro")
    tinsert(APRCustomPath[APR.PlayerID], "TWW - Undermine")
    self:SendMessage("APR_Custom_Path_Update")
end

---------------------------------------------------------------------------------------
------------------------------ Route config function ----------------------------------
---------------------------------------------------------------------------------------

function APR.routeconfig:HasRouteInCustomPaht()
    if APRCustomPath[APR.PlayerID] and not next(APRCustomPath[APR.PlayerID]) then
        return false
    end
    return true
end

function APR.routeconfig:CheckIsCustomPathEmpty()
    if (APR.settings.profile.debug) then
        print("Function: APR.routeconfig:CheckIsCustomPathEmpty()")
    end
    if not self:HasRouteInCustomPaht() then
        APR.ActiveRoute = nil
        APR.currentStep:Reset()
        APR.currentStep:AddExtraLineText("NO_ROUTE", L["NO_ROUTE"])
        APR:SendMessage("APR_MAP_UPDATE")
        APR.map:RemoveMapLine()
        APR.map:RemoveMinimapLine()
        APR.questOrderList:AddStepFromRoute()
        APR.party:SendGroupMessageDelete()
        APR.Arrow.Active = false
    end
end

APR.routeconfig.eventFrame = CreateFrame("Frame")
APR.routeconfig.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
APR.routeconfig.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "PLAYER_LEVEL_UP") then
        local arg1, _ = ...;
        APR.Level = arg1
        if not APR:IsTableEmpty(APRCustomPath[APR.PlayerID]) then
            local _, currentRouteName = next(APRCustomPath[APR.PlayerID])
            if APR:Contains(notSkippableRoute, currentRouteName) then
                return
            elseif APR.Level == 10 then
                APR.questionDialog:CreateQuestionPopup(format(L["RESET_ROUTE_FOR_SPEEDRUN"], APR.Level), function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end)
            elseif APR.Level == APR.MaxLevelChromie then
                APR.questionDialog:CreateQuestionPopup(format(L["RESET_ROUTE_FOR_TWW"], APR.Level), function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetTWWPrefab()
                end)
            end
        end
    end
end)
