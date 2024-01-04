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
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end
            },
            WoD_prefab = {
                order = 1.1,
                name = "Warlords of Draenor - " .. L["ONLY"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetWODPrefab()
                end
            },
            BFA_prefab = {
                order = 1.2,
                name = "Battle for Azeroth - " .. L["ONLY"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetBFAPrefab()
                end
            },
            SL_prefab = {
                order = 1.3,
                name = "Shadowlands - " .. L["ONLY"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSLPrefab()
                end
            },
            DF_prefab = {
                order = 1.4,
                name = "Dragonflight - " .. L["ONLY"],
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetDFPrefab()
                end,
                hidden = function()
                    return APR.Level < 58
                end,
            },
            reset_custom_path = {
                order = 1.5,
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
        if not Contains(APRCustomPath[APR.PlayerID], routeName) then
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
                    _G.GetTotalSteps(route.fileName)
                end
                status = APRData[APR.PlayerID][route.fileName] ..
                    "/" .. APRData[APR.PlayerID][route.fileName .. '-TotalSteps']
            end
            statusText:SetText(status)

            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route.routeName)
                GameTooltip:AddLine(L["MOVE_ZONE_TO_CUSTOM_PATH"], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            lineContainer:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            lineContainer:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    tinsert(APRCustomPath[APR.PlayerID], route.routeName)
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
        -- to trigger the frame
        APR.BookingList["UpdateMapId"] = true
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
    if Contains({ 1409, 1726, 1727, 1728 }, APR:GetPlayerParentMapID()) then
        tinsert(APRCustomPath[APR.PlayerID], "01-10 Exile's Reach")
    elseif not APRZoneCompleted[APR.PlayerID]["01-10 Exile's Reach"] then
        --NEUTRAL
        if APR.Level >= 58 and APR.ClassId == APR.Classes["Dracthyr"] then
            tinsert(APRCustomPath[APR.PlayerID], "Dracthyr Start")
        elseif APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23 then -- Allied DK
            tinsert(APRCustomPath[APR.PlayerID], "Allied Death Knight Start")
        elseif APR.ClassId == APR.Classes["Death Knight"] then                      -- DK
            tinsert(APRCustomPath[APR.PlayerID], "Death Knight Start")
        elseif APR.ClassId == APR.Classes["Demon Hunter"] then
            tinsert(APRCustomPath[APR.PlayerID], "Demon Hunter Start")
        elseif APR.Level < 10 then
            if (APR.Race == "Pandaren") then
                tinsert(APRCustomPath[APR.PlayerID], "Pandaren Start")
                -- HORDE
            elseif (APR.Race == "Orc") then
                tinsert(APRCustomPath[APR.PlayerID], "Orc Start")
            elseif (APR.Race == "Tauren") then
                tinsert(APRCustomPath[APR.PlayerID], "Tauren Start")
            elseif (APR.Race == "Troll") then
                tinsert(APRCustomPath[APR.PlayerID], "Troll Start")
            elseif (APR.Race == "Scourge") then --Undead
                tinsert(APRCustomPath[APR.PlayerID], "Scourge Start")
            elseif (APR.Race == "BloodElf") then
                tinsert(APRCustomPath[APR.PlayerID], "Blood Elf Start")
            elseif (APR.Race == "Goblin") then
                tinsert(APRCustomPath[APR.PlayerID], "Goblin Start")
                -- ALLIANCE
            elseif (APR.Race == "NightElf") then
                tinsert(APRCustomPath[APR.PlayerID], "Night Elf Start")
            elseif (APR.Race == "Draenei") then
                tinsert(APRCustomPath[APR.PlayerID], "Draenei Start")
                tinsert(APRCustomPath[APR.PlayerID], "Azuremyst Isle")
                tinsert(APRCustomPath[APR.PlayerID], "Bloodmyst Isle")
            elseif (APR.Race == "Dwarf") then
                tinsert(APRCustomPath[APR.PlayerID], "Dwarf Start")
                tinsert(APRCustomPath[APR.PlayerID], "Dun Morogh")
            elseif (APR.Race == "Human") then
                tinsert(APRCustomPath[APR.PlayerID], "Human Start")
            elseif (APR.Race == "Gnome") then
                tinsert(APRCustomPath[APR.PlayerID], "Gnome Start")
            elseif (APR.Race == "Worgen") then
                tinsert(APRCustomPath[APR.PlayerID], "Worgen Start")
            end
        end
    end
    self:LoadRouteAddonFile("WrathOfTheLichKing")
    self:LoadRouteAddonFile("Legion")
    self:LoadRouteAddonFile("Shadowlands")
    self:LoadRouteAddonFile("Dragonflight")
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
    self:LoadRouteAddonFile("WarlordsOfDraenor")
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
        tinsert(APRCustomPath[APR.PlayerID], "BFA02 - Intro")
        tinsert(APRCustomPath[APR.PlayerID], "BFA03 - Zuldazar")
        tinsert(APRCustomPath[APR.PlayerID], "BFA04 - Nazmir")
        tinsert(APRCustomPath[APR.PlayerID], "BFA05 - Naz-end Vol-begin")
        tinsert(APRCustomPath[APR.PlayerID], "BFA06 - Vol'dun")
    end
    self:LoadRouteAddonFile("BattleForAzeroth")
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
    self:LoadRouteAddonFile("Shadowlands")
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
    self:LoadRouteAddonFile("Dragonflight")
    self:SendMessage("APR_Custom_Path_Update")
end

---------------------------------------------------------------------------------------
------------------------------ Route config function ----------------------------------
---------------------------------------------------------------------------------------

--Loads addon if needed for a route
-- //TODO: call this on addonLoad
function APR.routeconfig:LoadRouteAddonFile(tabName)
    if APRCustomPath[APR.PlayerID] then
        local function checkAddon(zoneName, addonName)
            if tabName == zoneName and not C_AddOns.IsAddOnLoaded(addonName) then
                local loaded, _ = C_AddOns.LoadAddOn(addonName)
                if not loaded then
                    C_AddOns.EnableAddOn(addonName, UnitName("player"))
                    C_AddOns.SaveAddOns()
                    print("APR: " .. addonName .. " " .. L["DISABLED_ADDON_LIST"])
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

function APR.routeconfig:HasRouteInCustomPaht()
    if not next(APRCustomPath[APR.PlayerID]) then
        return false
    end
    return true
end

function APR.routeconfig:CheckIsCustomPathEmpty()
    if (APR.settings.profile.debug) then
        print("Function: APR.routeconfig:CheckIsCustomPathEmpty()")
    end
    if not next(APRCustomPath[APR.PlayerID]) then
        APR.ActiveRoute = nil
        APR.currentStep:RemoveQuestStepsAndExtraLineTexts()

        APR.currentStep:AddExtraLineText("NO_ROUTE", L["NO_ROUTE"], true)
        APR.currentStep:ButtonDisable()
        APR.currentStep:ProgressBar()
        APR:SendMessage("APR_MAP_UPDATE")
        APR.map:RemoveMapLine()
        APR.map:RemoveMinimapLine()
        APR.questOrderList:AddStepFromRoute()
    end
end

APR.routeconfig.eventFrame = CreateFrame("Frame")
APR.routeconfig.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
APR.routeconfig.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "PLAYER_LEVEL_UP") then
        local arg1, _ = ...;
        APR.Level = arg1
        if not IsTableEmpty(APRCustomPath[APR.PlayerID]) then
            if APR.Level == 50 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_SL"], function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSLPrefab()
                    APR.routeconfig:GetDFPrefab()
                end)
            elseif APR.Level == 60 then
                APR.questionDialog:CreateQuestionPopup(L["RESET_ROUTE_FOR_DF"], function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetDFPrefab()
                end)
            end
        end
    end
end)
