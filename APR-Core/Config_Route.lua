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
local routeSearchWidget = nil
local currentTabName = nil

local routeSearchText = ""

local function SetRouteSearchText(value)
    routeSearchText = value or ""
    if tabRouteListWidget and currentTabName then
        SetRouteListTab(tabRouteListWidget, currentTabName)
    end
end

local function ResetRouteSearchText()
    routeSearchText = ""
    if routeSearchWidget and routeSearchWidget.frame and routeSearchWidget.frame.editBox then
        routeSearchWidget.frame.editBox:SetText("")
        routeSearchWidget.frame.editBox:SetCursorPosition(0)
    end
end

local function CreateRouteSearchOption()
    return {
        order = 2.5,
        type = "input",
        dialogControl = "RouteSearchFrame",
        name = SEARCH,
        width = "full",
        get = function()
            return routeSearchText
        end,
        set = function(_, value)
            SetRouteSearchText(value)
        end,
    }
end

local notSkippableRoute = { "01-10 Exile's Reach", "Goblin - Lost Isles", "Dracthyr Start", "Pandaren Neutral Start",
    "Allied Death Knight Start", "Death Knight Start", "Demon Hunter Start", "Worgen Start", "Earthen Dwarf Start" }
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
                    APR.routeconfig:GetRemixPrefab()
                end,
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
            MIDNIGHT_prefab = {
                order = 1.7,
                name = "Midnight",
                type = "execute",
                width = optionsWidth,
                func = function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetMidnightPrefab()
                end,
                hidden = function()
                    return not next(APR.RouteList.Midnight) or not APR.isMidnightVersion
                end
            },
            reset_custom_path = {
                order = 1.8,
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
            route_search = CreateRouteSearchOption(),
            Vanilla = {
                order = 3,
                name = "Vanilla",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
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
                        order = 1,
                        name = "TheWarWithin",
                        dialogControl = "RouteListFrame",
                    },
                }
            },
            Midnight = {
                order = 14,
                name = "Midnight",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        order = 1,
                        name = "Midnight",
                        dialogControl = "RouteListFrame",
                    },
                },
                disabled = function()
                    return not APR.isMidnightVersion
                end
            },
            Custom = {
                order = 15,
                name = "Custom",
                type = "group",
                childGroups = "tree",
                inline = false,
                args = {
                    route = {
                        type = "input",
                        order = 1,
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
    nameColumn:SetText(L["NAME"])

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
    nameColumn:SetText(L["NAME"])

    local statusColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusColumn:SetPoint("TOPRIGHT", -10, 0)
    statusColumn:SetText(L["STATUS"])

    return frame
end

local function CreateRouteSearchFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(400, 25)
    frame:SetPoint("CENTER")

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", frame, "LEFT", 10, 0)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetSize(250, 18)
    editBox:SetPoint("LEFT", label, "RIGHT", 8, 0)
    editBox:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    editBox:SetTextInsets(6, 6, 0, 0)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then
            return
        end
        SetRouteSearchText(self:GetText() or "")
    end)

    frame.label = label
    frame.editBox = editBox

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

    local sortedRoutes = {}

    -- Get the search text (case-insensitive)
    local search = (routeSearchText or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

    local yOffset = -15

    -- Copy the routes into a new table for sorting (with filter)
    local function AddRoutesFromTab(tabName, routes)
        if type(routes) ~= "table" then
            return
        end
        for fileName, routeName in pairs(routes) do
            if not APR:Contains(APRCustomPath[APR.PlayerID], routeName) then
                if search == "" then
                    tinsert(sortedRoutes, { fileName = fileName, routeName = routeName, tabName = tabName })
                else
                    local rn = (routeName or ""):lower()
                    local fn = (fileName or ""):lower()
                    if rn:find(search, 1, true) or fn:find(search, 1, true) then
                        tinsert(sortedRoutes, { fileName = fileName, routeName = routeName, tabName = tabName })
                    end
                end
            end
        end
    end

    if search == "" then
        AddRoutesFromTab(name, APR.RouteList[name])
    else
        for tabName, routes in pairs(APR.RouteList) do
            AddRoutesFromTab(tabName, routes)
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
        if search ~= "" then
            noRoutesText:SetText(L["NO_ROUTE"])
        else
            noRoutesText:SetText(L["NO_ROUTE"])
        end

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

            local routeTabName = route.tabName or name
            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(route.routeName)
                if IsRouteDisabled(routeTabName, route.routeName) then
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
            if IsRouteDisabled(routeTabName, route.routeName) then
                nameText:SetTextColor(unpack(APR.Color.midGray))
                lineContainer:SetScript("OnMouseDown", nil)
            end

            yOffset = yOffset - 25
            tinsert(widget.fontStringsContainer, lineContainer)
        end
    end
    widget.frame:SetSize(400, -yOffset)
end

local function InitRouteSearchFrame(Type)
    local function Constructor()
        local Widget = {}

        local frame = CreateRouteSearchFrame(Type)
        frame.obj = Widget
        frame.editBox.obj = Widget

        Widget.frame = frame
        Widget.type = Type
        Widget.num = AceGUI:GetNextWidgetNum(Type)
        Widget.userdata = {}
        routeSearchWidget = Widget

        Widget.OnAcquire = function(self)
            self:SetDisabled(false)
            self:SetFullWidth(true)
        end

        Widget.SetLabel = function(self, text)
            self.frame.label:SetText(text or "")
        end

        Widget.SetText = function(self, text)
            self.frame.editBox:SetText(text or "")
            self.frame.editBox:SetCursorPosition(0)
        end

        Widget.OnWidthSet = function(self)
            if self.resizing then return end
            if self.AdjustHeightFunction then self:AdjustHeightFunction() end
        end

        Widget.SetDisabled = function(self, disabled)
            self.disabled = disabled
            if disabled then
                self.frame.editBox:EnableMouse(false)
                self.frame.editBox:ClearFocus()
                self.frame.editBox:SetTextColor(0.5, 0.5, 0.5)
                self.frame.label:SetTextColor(0.5, 0.5, 0.5)
            else
                self.frame.editBox:EnableMouse(true)
                self.frame.editBox:SetTextColor(1, 1, 1)
                self.frame.label:SetTextColor(1, 0.82, 0)
            end
        end

        Widget.OnRelease = function(self)
            self:SetDisabled(true)
            self.frame:ClearAllPoints()
        end

        return AceGUI:RegisterAsWidget(Widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, 1)
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
            if Type == "RouteListFrame" and name ~= currentTabName then
                ResetRouteSearchText()
            end
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
        local routeZoneMapIDs, mapID, routeFileName, expansion = APR:GetCurrentRouteMapIDsAndName()
        APR.ActiveRoute = routeFileName

        APR:UpdateMapId()
        APR:UpdateStep()
    end)
    InitRouteSearchFrame("RouteSearchFrame")
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
local function AddRouteToCustomPath(routeName)
    if not routeName or not APR.PlayerID then
        return
    end

    APRCustomPath[APR.PlayerID] = APRCustomPath[APR.PlayerID] or {}

    local _, _, routeFileName = APR:GetRouteMapIDsAndName(routeName)
    local playerData = APRData[APR.PlayerID]

    if routeFileName and playerData then
        if playerData[routeFileName]
            or playerData[routeFileName .. '-TotalSteps']
            or playerData[routeFileName .. '-SkippedStep'] then
            APR:CheckRouteChanges(routeFileName)
        end
    end

    tinsert(APRCustomPath[APR.PlayerID], routeName)
end


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
    if APR.isMidnightVersion then
        self:GetMidnightPrefab()
    end
end

function APR.routeconfig:GetStartingZonePrefab()
    if APR:Contains({ 1409, 1726, 1727, 1728 }, APR:GetPlayerParentMapID()) then
        AddRouteToCustomPath(L["01-10 Exile's Reach"])
    elseif APR:Contains({ 2451 }, APR:GetPlayerParentMapID()) then
        AddRouteToCustomPath(L["TWW - Arathi Highlands - Returning Player"])
    elseif not (C_QuestLog.IsQuestFlaggedCompleted(59926) or C_QuestLog.IsQuestFlaggedCompleted(56775)) and (APR.Level < APR.MinBoostLvl or APR.Level < 10) then -- first quest from Exile's Reach + boost
        --None skipable starting zone
        if APR.ClassId == APR.Classes["Death Knight"] and APR.RaceID >= 23 then                                                                                  -- Allied DK
            AddRouteToCustomPath(L["Allied Death Knight Start"])
        elseif APR.ClassId == APR.Classes["Death Knight"] then                                                                                                   -- DK
            AddRouteToCustomPath(L["Death Knight Start"])
        elseif APR.ClassId == APR.Classes["Demon Hunter"] then
            AddRouteToCustomPath(L["Demon Hunter Start"])

            -- Neutral Race
        elseif APR.Race == "Pandaren" then
            AddRouteToCustomPath(L["Pandaren Neutral Start"])
        elseif APR.Race == "Goblin" then
            AddRouteToCustomPath(L["Goblin Start"])
            AddRouteToCustomPath(L["Goblin - Lost Isles"])
        elseif APR.Race == "Worgen" then
            AddRouteToCustomPath(L["Worgen Start"])
        elseif APR.Race == "Dracthyr" then
            AddRouteToCustomPath(L["Dracthyr Start"])
        elseif APR.Race == "EarthenDwarf" then
            AddRouteToCustomPath(L["Earthen Dwarf Start"])
        elseif APR.Race == "Harronir" then
            AddRouteToCustomPath(L["Midnight - Haranir Start"])

            -- Horde Allied Race
        elseif APR.Race == "ZandalariTroll" then
            AddRouteToCustomPath(L["Zandalari Troll Start"])
        elseif APR.Race == "Vulpera" then
            AddRouteToCustomPath(L["Vulpera Start"])
        elseif APR.Race == "MagharOrc" then
            AddRouteToCustomPath(L["Maghar Orc Start"])
        elseif APR.Race == "Nightborne" then
            AddRouteToCustomPath(L["Nightborne Start"])
        elseif APR.Race == "Nightborne" then
            AddRouteToCustomPath(L["Nightborne Start"])
        elseif APR.Race == "HighmountainTauren" then
            AddRouteToCustomPath(L["Highmountain Tauren Start"])

            -- Alliance Allied Race
        elseif APR.Race == "VoidElf" then
            AddRouteToCustomPath(L["Void Elf Start"])
        elseif APR.Race == "LightforgedDraenei" then
            AddRouteToCustomPath(L["Lightforged Draenei Start"])
        elseif APR.Race == "DarkIronDwarf" then
            AddRouteToCustomPath(L["DarkIron Dwarf Start"])
        elseif APR.Race == "Mechagnome" then
            AddRouteToCustomPath(L["Mechagnome Start"])
        elseif APR.Race == "KulTiran" then
            AddRouteToCustomPath(L["Kul Tiran Start"])
        elseif APR.Level < 10 then -- Skipable starting zone
            -- HORDE
            if (APR.Race == "Orc") then
                AddRouteToCustomPath(L["Orc Start"])
                AddRouteToCustomPath(L["Durotar"])
            elseif (APR.Race == "Tauren") then
                AddRouteToCustomPath(L["Tauren Start"]) -- missing part 2
            elseif (APR.Race == "Troll") then
                AddRouteToCustomPath(L["Troll Start"])
                AddRouteToCustomPath(L["Durotar"])
            elseif (APR.Race == "Scourge") then --Undead
                AddRouteToCustomPath(L["Undead Start"])
            elseif (APR.Race == "BloodElf") then
                AddRouteToCustomPath(L["Blood Elf Start"]) -- missing part 2
                -- ALLIANCE
            elseif (APR.Race == "NightElf") then
                AddRouteToCustomPath(L["Night Elf Start"])
                AddRouteToCustomPath(L["Teldrassil"])
            elseif (APR.Race == "Draenei") then
                AddRouteToCustomPath(L["Draenei Start"])
                AddRouteToCustomPath(L["Azuremyst Isle"])
                AddRouteToCustomPath(L["Bloodmyst Isle"])
            elseif (APR.Race == "Dwarf") then
                AddRouteToCustomPath(L["Dwarf Start"])
                AddRouteToCustomPath(L["Dun Morogh"])
            elseif (APR.Race == "Human") then
                AddRouteToCustomPath(L["Human Start"])
                AddRouteToCustomPath(L["Elwynn Forest"])
            elseif (APR.Race == "Gnome") then
                AddRouteToCustomPath(L["Gnome Start"])
                AddRouteToCustomPath(L["Dun Morogh"])
            end
        end
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetWODPrefab()
    if APR.Faction == alliance then
        AddRouteToCustomPath(L["WOD01 - Stormwind"])
        AddRouteToCustomPath(L["WOD02 - Tanaan Jungle"])
        AddRouteToCustomPath(L["WOD03 - Shadowmoon"])
        AddRouteToCustomPath(L["WOD04 - Gorgrond"])
        AddRouteToCustomPath(L["WOD05 - Talador"])
        AddRouteToCustomPath(L["WOD06 - Shadowmoon"])
        AddRouteToCustomPath(L["WOD07 - Talador"])
        AddRouteToCustomPath(L["WOD08 - Spires of Arak"])
    elseif APR.Faction == horde then
        AddRouteToCustomPath(L["WOD01 - Orgrimmar"])
        AddRouteToCustomPath(L["WOD02 - Tanaan Jungle"])
        AddRouteToCustomPath(L["WOD03 - Frostfire Ridge"])
        AddRouteToCustomPath(L["WOD04 - Gorgrond"])
        AddRouteToCustomPath(L["WOD05 - Talador"])
        AddRouteToCustomPath(L["WOD06 - Spires of Arak"])
        AddRouteToCustomPath(L["WOD07 - Nagrand"])
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetBFAPrefab()
    if APR.Faction == alliance then
        AddRouteToCustomPath(L["BFA01 - Intro"])
        AddRouteToCustomPath(L["BFA02 - Tiragarde Sound"])
        AddRouteToCustomPath(L["BFA03 - Dustvar"])
        AddRouteToCustomPath(L["BFA04 - Stormsong Valley"])
    elseif APR.Faction == horde then
        AddRouteToCustomPath(L["BFA01 - Intro"])
        AddRouteToCustomPath(L["BFA02 - Zuldazar"])
        AddRouteToCustomPath(L["BFA03 - Nazmir"])
        AddRouteToCustomPath(L["BFA04 - Naz-end Vol-begin"])
        AddRouteToCustomPath(L["BFA05 - Vol'dun"])
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetSLPrefab()
    AddRouteToCustomPath(L["SL - Intro"])
    AddRouteToCustomPath(L["SL01 - The Maw"])
    AddRouteToCustomPath(L["SL02 - Oribos"])
    AddRouteToCustomPath(L["SL03 - Bastion"])
    AddRouteToCustomPath(L["SL04 - Oribos"])
    AddRouteToCustomPath(L["SL05 - Maldraxxus"])
    AddRouteToCustomPath(L["SL06 - Oribos"])
    AddRouteToCustomPath(L["SL07 - The Maw"])
    AddRouteToCustomPath(L["SL08 - Oribos"])
    AddRouteToCustomPath(L["SL09 - Maldraxxus"])
    AddRouteToCustomPath(L["SL10 - Oribos"])
    AddRouteToCustomPath(L["SL11 - Ardenweald"])
    AddRouteToCustomPath(L["SL12 - Oribos"])
    AddRouteToCustomPath(L["SL13 - Revendreth"])
    AddRouteToCustomPath(L["SL14 - The Maw"])
    AddRouteToCustomPath(L["SL15 - Revendreth"])
    AddRouteToCustomPath(L["SL16 - Oribos"])
    AddRouteToCustomPath(L["SL - StoryMode Only"])
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetDFPrefab()
    if APR.Faction == alliance then
        AddRouteToCustomPath(L["DF01 - Dragonflight Stormwind"])
        AddRouteToCustomPath(L["DF02 - Waking Shores - Alliance"])
        AddRouteToCustomPath(L["DF03 - Waking Shores - Neutral"])
        AddRouteToCustomPath(L["DF04 - Ohn'Ahran Plains"])
        AddRouteToCustomPath(L["DF05 - Azure Span"])
        AddRouteToCustomPath(L["DF06 - Thaldraszus"])
    elseif APR.Faction == horde then
        AddRouteToCustomPath(L["DF01/02 - Dragonflight Orgrimmar/Durotar"])
        AddRouteToCustomPath(L["DF03 - Waking Shores - Horde"])
        AddRouteToCustomPath(L["DF04 - Waking Shores - Neutral"])
        AddRouteToCustomPath(L["DF05 - Ohn'Ahran Plains"])
        AddRouteToCustomPath(L["DF06 - Azure Span"])
        AddRouteToCustomPath(L["DF07 - Thaldraszus"])
    end
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetTWWPrefab()
    -- Don't add TWW route if the player is neutral
    if APR.Faction == "Neutral" then return end

    AddRouteToCustomPath(L["TWW - 01 - Intro"])
    AddRouteToCustomPath(L["TWW - 02 - Isle of Dorn"])
    AddRouteToCustomPath(L["TWW - 03 - Ringing Deeps"])
    AddRouteToCustomPath(L["TWW - 04 - Hallowfall"])
    AddRouteToCustomPath(L["TWW - 05 - Azj-Kahet"])
    AddRouteToCustomPath(L["TWW - 06 - Against the Current Storyline"])
    AddRouteToCustomPath(L["TWW - 07 - Ties That Bind Storyline"])
    AddRouteToCustomPath(L["TWW - 08 - News from Below Storyline"])
    AddRouteToCustomPath(L["TWW - 09 - The Machines March to War Storyline"])
    AddRouteToCustomPath(L["TWW - 10 - Light in the Dark Storyline"])
    AddRouteToCustomPath(L["TWW - 11 - Lingering Shadow Storyline"])
    AddRouteToCustomPath(L["TWW - 12 - Fate of the Kirin Tor"])
    AddRouteToCustomPath(L["TWW - Siren Isle Intro"])
    AddRouteToCustomPath(L["TWW - Undermine"])
    AddRouteToCustomPath(L["TWW - Nightfall"])
    AddRouteToCustomPath(L["TWW - Rise of the Red Dawn"])
    AddRouteToCustomPath(L["TWW - K'aresh Storyline"])

    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetMidnightPrefab()
    if APR.Faction == "Neutral" then return end

    -- AddRouteToCustomPath(L["Midnight - Pre Patch"])
    AddRouteToCustomPath(L["Midnight - Intro"])
    AddRouteToCustomPath(L["Midnight - Eversong Woods - sojourner"])
    -- AddRouteToCustomPath(L["Midnight - Zul'Aman - sojourner"])
    -- AddRouteToCustomPath(L["Midnight - Harandar - sojourner"])
    -- AddRouteToCustomPath(L["Midnight - Voidstorm - sojourner"])
    AddRouteToCustomPath(L["Midnight - Arators Journey"])
    -- AddRouteToCustomPath(L["Midnight - Rage of the Ren'dorei"])

    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:GetPlayerSpecRoute(prefix)
    local routeKey = prefix .. " - " .. APR.GetClassSpecName()
    if APR.RouteQuestStepList[routeKey] then
        AddRouteToCustomPath(L[routeKey])
    end
end

function APR.routeconfig:GetRemixPrefab()
    AddRouteToCustomPath(L["Legion - Intro Remix"])
    AddRouteToCustomPath(L["Remix - Order Hall - Start"])
    APR.routeconfig:GetPlayerSpecRoute("Artifact Weapon")
    AddRouteToCustomPath(L["Remix - Order Hall - Next"])
    AddRouteToCustomPath(L["Legion - Azsuna"])
    AddRouteToCustomPath(L["Legion - Val'Sharah"])
    AddRouteToCustomPath(L["Legion - Highmountain"])
    AddRouteToCustomPath(L["Legion - Stormheim"])

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
    APR:Debug("Function: APR.routeconfig:CheckIsCustomPathEmpty()")
    if not self:HasRouteInCustomPaht() then
        APR.ActiveRoute = nil
        APR.currentStep:Reset()
        APR.currentStep:AddExtraLineText("NO_ROUTE", L["NO_ROUTE"])
        APR:SendMessage("APR_MAP_UPDATE")
        APR.map:RemoveMapLine()
        APR.map:RemoveMinimapLine()
        APR.questOrderList:AddStepFromRoute()
        APR.Arrow.Active = false
        APR.party:SendGroupMessage()
    end
end

function APR.routeconfig:CheckRouteResetOnLvlUp()
    if not APR:IsTableEmpty(APRCustomPath[APR.PlayerID]) then
        local _, currentRouteName = next(APRCustomPath[APR.PlayerID])
        if APR:Contains(L[notSkippableRoute], currentRouteName) then
            return
        elseif APR.Level == 10 then
            APR.questionDialog:CreateQuestionPopup("RESET_ROUTE_FOR_SPEEDRUN",
                format(L["RESET_ROUTE_FOR_SPEEDRUN"], APR.Level), function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetSpeedRunPrefab()
                end)
        elseif APR.Level == APR.MaxLevelChromie then
            APR.questionDialog:CreateQuestionPopup("RESET_ROUTE_FOR_TWW", format(L["RESET_ROUTE_FOR_TWW"], APR.Level),
                function()
                    APRCustomPath[APR.PlayerID] = {}
                    APR.routeconfig:GetTWWPrefab()
                end)
        end
    end
end
