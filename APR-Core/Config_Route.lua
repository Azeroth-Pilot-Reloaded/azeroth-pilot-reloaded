local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize APR Route module
APR.routeconfig = APR:NewModule("routeconfig", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local lineColor = APR.Color.grayAlpha
local customPathListeWidget = nil
local tabRouteListWidget = nil
local routeSearchWidget = nil
local currentTabName = nil

local routeSearchText = ""
local routeSortKey = "name"
local routeSortAsc = true

local PREFAB_BUTTON_WIDGET_TYPE = "APRWrappedButton"
local PREFAB_BUTTON_WIDGET_VERSION = 1
local PREFAB_BUTTON_RELATIVE_SPACER = 0.02

local function ClampNumber(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function EnsurePrefabWrappedButtonWidget()
    local currentVersion = AceGUI:GetWidgetVersion(PREFAB_BUTTON_WIDGET_TYPE) or 0
    if currentVersion >= PREFAB_BUTTON_WIDGET_VERSION then
        return
    end

    local function Button_OnClick(frame, ...)
        AceGUI:ClearFocus()
        PlaySound(852)
        frame.obj:Fire("OnClick", ...)
    end

    local function Control_OnEnter(frame)
        frame.obj:Fire("OnEnter")
    end

    local function Control_OnLeave(frame)
        frame.obj:Fire("OnLeave")
    end

    local methods = {
        OnAcquire = function(self)
            self:SetHeight(34)
            self:SetWidth(200)
            self:SetDisabled(false)
            self:SetText("")
        end,
        SetText = function(self, text)
            self.text:SetText(text)
        end,
        SetDisabled = function(self, disabled)
            self.disabled = disabled
            if disabled then
                self.frame:Disable()
            else
                self.frame:Enable()
            end
        end,
    }

    local function Constructor()
        local name = PREFAB_BUTTON_WIDGET_TYPE .. AceGUI:GetNextWidgetNum(PREFAB_BUTTON_WIDGET_TYPE)
        local frame = CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate")
        frame:Hide()

        frame:EnableMouse(true)
        frame:SetScript("OnClick", Button_OnClick)
        frame:SetScript("OnEnter", Control_OnEnter)
        frame:SetScript("OnLeave", Control_OnLeave)

        local text = frame:GetFontString()
        text:ClearAllPoints()
        text:SetPoint("TOPLEFT", 8, -1)
        text:SetPoint("BOTTOMRIGHT", -8, 1)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetWordWrap(false)
        text:SetFontObject(GameFontNormalSmall)

        local widget = {
            text = text,
            frame = frame,
            type = PREFAB_BUTTON_WIDGET_TYPE,
        }

        for method, func in pairs(methods) do
            widget[method] = func
        end

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(PREFAB_BUTTON_WIDGET_TYPE, Constructor, PREFAB_BUTTON_WIDGET_VERSION)
end

local function BuildPrefabButtonName(localeKey)
    return L[localeKey] or localeKey
end

local PREFAB_BUTTON_LABELS = {
    speedrun_prefab = BuildPrefabButtonName("SPEEDRUN"),
    all_quests_prefab = BuildPrefabButtonName("ALL_QUESTS"),
    leveling_prefab = BuildPrefabButtonName("LEVELING_PREFAB"),
    reset_custom_path = BuildPrefabButtonName("CLEAR"),
}

local function BuildPrefabRelativeWidthMap()
    local keys = {
        "speedrun_prefab",
        "all_quests_prefab",
        "leveling_prefab",
        "reset_custom_path",
    }

    local weightedTotal = 0
    local weights = {}

    for _, key in ipairs(keys) do
        local label = tostring(PREFAB_BUTTON_LABELS[key] or "")
        local weight = math.max(8, #label + 4)
        weights[key] = weight
        weightedTotal = weightedTotal + weight
    end

    local available = 1 - PREFAB_BUTTON_RELATIVE_SPACER
    local relativeWidths = {}

    for _, key in ipairs(keys) do
        local ratio = weightedTotal > 0 and (weights[key] / weightedTotal) or 0.25
        relativeWidths[key] = ClampNumber(ratio * available, 0.12, 0.58)
    end

    local sum = 0
    for _, key in ipairs(keys) do
        sum = sum + relativeWidths[key]
    end

    if sum > 0 then
        local rescale = available / sum
        for _, key in ipairs(keys) do
            relativeWidths[key] = relativeWidths[key] * rescale
        end
    end

    return relativeWidths
end

local PREFAB_BUTTON_RELATIVE_WIDTHS = BuildPrefabRelativeWidthMap()

local PREFAB_ACTION_ORDER = {
    "speedrun_prefab",
    "all_quests_prefab",
    "leveling_prefab",
    "reset_custom_path_spacer_1",
    "reset_custom_path",
}

local PREFAB_ACTION_DEFINITIONS = {
    speedrun_prefab = {
        order = 1.0,
        type = "execute",
        dialogControl = PREFAB_BUTTON_WIDGET_TYPE,
        name = PREFAB_BUTTON_LABELS.speedrun_prefab,
        width = "relative",
        relWidth = PREFAB_BUTTON_RELATIVE_WIDTHS.speedrun_prefab,
        desc = L["SPEEDRUN_TOOLTIPS"],
        func = function()
            APRCustomPath[APR.PlayerID] = {}
            APR.routeconfig:GetSpeedRunPrefab()
        end,
    },
    all_quests_prefab = {
        order = 1.1,
        type = "execute",
        dialogControl = PREFAB_BUTTON_WIDGET_TYPE,
        name = PREFAB_BUTTON_LABELS.all_quests_prefab,
        width = "relative",
        relWidth = PREFAB_BUTTON_RELATIVE_WIDTHS.all_quests_prefab,
        desc = L["ALL_QUESTS_TOOLTIPS"],
        func = function()
            APR.routeconfig:OpenAllQuestsPopup()
        end,
    },
    leveling_prefab = {
        order = 1.2,
        type = "execute",
        dialogControl = PREFAB_BUTTON_WIDGET_TYPE,
        name = PREFAB_BUTTON_LABELS.leveling_prefab,
        width = "relative",
        relWidth = PREFAB_BUTTON_RELATIVE_WIDTHS.leveling_prefab,
        desc = L["LEVELING_TOOLTIPS"],
        func = function()
            APR.routeconfig:OpenLevelingPopup()
        end,
    },
    reset_custom_path_spacer_1 = {
        order = 1.3,
        type = "description",
        name = " ",
        width = "relative",
        relWidth = PREFAB_BUTTON_RELATIVE_SPACER,
    },
    reset_custom_path = {
        order = 1.4,
        type = "execute",
        dialogControl = PREFAB_BUTTON_WIDGET_TYPE,
        name = PREFAB_BUTTON_LABELS.reset_custom_path,
        width = "relative",
        relWidth = PREFAB_BUTTON_RELATIVE_WIDTHS.reset_custom_path,
        desc = L["CLEAR_CUSTOM_PATH"],
        func = function()
            APRCustomPath[APR.PlayerID] = {}
            APR.routeconfig:SendMessage("APR_Custom_Path_Update")
        end,
        disabled = function()
            return not next(APRCustomPath[APR.PlayerID])
        end,
    },
}

local ROUTE_TAB_EXPANSION_VALUES = {}
for _, expansionKey in ipairs(APR.EXPANSION_ORDER_KEYS or {}) do
    local expansionName = APR.EXPANSIONS[expansionKey]
    if expansionName then
        tinsert(ROUTE_TAB_EXPANSION_VALUES, expansionName)
    end
end

local function GetRouteStatusText(fileName, routeName)
    if APRZoneCompleted[APR.PlayerID][routeName] then
        return L["ROUTE_COMPLETED"]
    end

    if APRData[APR.PlayerID][fileName] then
        if not APRData[APR.PlayerID][fileName .. '-TotalSteps'] then
            APR:GetTotalSteps(fileName)
        end
        return (APRData[APR.PlayerID][fileName] - (APRData[APR.PlayerID][fileName .. '-SkippedStep'] or 0)) ..
            "/" .. APRData[APR.PlayerID][fileName .. '-TotalSteps']
    end

    return ""
end

local function ToggleRouteSort(key)
    if routeSortKey == key then
        routeSortAsc = not routeSortAsc
    else
        routeSortKey = key
        routeSortAsc = true
    end

    if tabRouteListWidget and currentTabName then
        SetRouteListTab(tabRouteListWidget, currentTabName)
    end
end

local function UpdateRouteSortHeaderLabels(frame)
    if not frame then
        return
    end

    if frame.nameColumn then
        frame.nameColumn:SetText(L["NAME"])
    end
    if frame.categoryColumn then
        frame.categoryColumn:SetText(L["CATEGORY"])
    end
    if frame.statusColumn then
        frame.statusColumn:SetText(L["STATUS"])
    end

    if frame.sortIndicators then
        for _, indicator in pairs(frame.sortIndicators) do
            indicator:Hide()
        end

        local activeIndicator = frame.sortIndicators[routeSortKey]
        if activeIndicator then
            if routeSortAsc then
                activeIndicator:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
                activeIndicator:ClearAllPoints()
                if routeSortKey == "status" then
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", 10, 8)
                elseif routeSortKey == "category" then
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", 5, 8)
                else
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", -4, 8)
                end
                activeIndicator:SetSize(14, 14)
            else
                activeIndicator:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
                activeIndicator:ClearAllPoints()
                if routeSortKey == "status" then
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", 10, 2)
                elseif routeSortKey == "category" then
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", 5, 2)
                else
                    activeIndicator:SetPoint("RIGHT", activeIndicator:GetParent(), "RIGHT", -4, 2)
                end
                activeIndicator:SetSize(14, 14)
            end
            activeIndicator:Show()
        end
    end
end


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



local function CreateRouteTreeGroupOption(expansionName, order)
    return {
        order = order,
        name = expansionName,
        type = "group",
        childGroups = "tree",
        inline = false,
        args = {
            route = {
                type = "input",
                order = 1,
                name = expansionName,
                dialogControl = "RouteListFrame",
            },
        },
    }
end

local function AddPrefabActionOptions(args)
    for _, key in ipairs(PREFAB_ACTION_ORDER) do
        args[key] = PREFAB_ACTION_DEFINITIONS[key]
    end
end

local function AddRouteTreeGroupOptions(args, startOrder)
    local order = startOrder
    for _, expansionName in ipairs(ROUTE_TAB_EXPANSION_VALUES) do
        args[expansionName] = CreateRouteTreeGroupOption(expansionName, order)
        order = order + 1
    end
end

---------------------------------------------------------------------------------------
------------------------- Config functionality for Route ------------------------------
---------------------------------------------------------------------------------------

local function GetConfigOptionTable()
    local args = {
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
    }

    AddPrefabActionOptions(args)
    AddRouteTreeGroupOptions(args, 3)

    local routeOptions = {
        name = L["ROUTE_SELECTION"],
        type = "group",
        inline = false,
        order = 0,
        args = args
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
    local rowHeight = 29
    local rowOddBgColor = { 0, 0, 0, 0 }
    local rowEvenBgColor = { 0, 0, 0, 0.24 }
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

            local rowBackground = lineContainer:CreateTexture(nil, "BACKGROUND")
            rowBackground:SetAllPoints()
            if i % 2 == 0 then
                rowBackground:SetColorTexture(unpack(rowEvenBgColor))
            else
                rowBackground:SetColorTexture(unpack(rowOddBgColor))
            end

            local borderTexture = lineContainer:CreateTexture(nil, "BACKGROUND")
            borderTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            borderTexture:SetSize(600, 1)
            borderTexture:SetPoint("TOPLEFT", lineContainer, "TOPLEFT", 0, 0)
            borderTexture:SetPoint("TOPRIGHT", lineContainer, "TOPRIGHT", 0, 0)
            borderTexture:SetVertexColor(unpack(lineColor))

            local routeID = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            routeID:SetPoint("LEFT")
            routeID:SetText(tostring(i))

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
        local maxVisibleRoutes = 4
        local maxHeight = 15 + (25 * maxVisibleRoutes)
        local height = (-yOffset < maxHeight and -yOffset or maxHeight)
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
    frame.nameColumn = nameColumn

    local categoryColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryColumn:SetPoint("TOPLEFT", 285, 0)
    categoryColumn:SetText(L["CATEGORY"])
    frame.categoryColumn = categoryColumn

    local statusColumn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusColumn:SetPoint("TOPRIGHT", -10, 0)
    statusColumn:SetWidth(58)
    statusColumn:SetJustifyH("RIGHT")
    statusColumn:SetText(L["STATUS"])
    frame.statusColumn = statusColumn

    local function CreateSortClickArea(key)
        local button = CreateFrame("Button", nil, frame)
        button:SetHeight(20)
        button:SetScript("OnClick", function()
            ToggleRouteSort(key)
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine((L["CLICK"] or "Click") .. " : Sort")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.sortIndicators = frame.sortIndicators or {}
        local indicator = button:CreateTexture(nil, "OVERLAY")
        indicator:SetPoint("RIGHT", button, "RIGHT", -4, 10)
        indicator:SetSize(14, 14)
        indicator:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        indicator:Hide()
        frame.sortIndicators[key] = indicator

        return button
    end

    frame.nameSortButton = CreateSortClickArea("name")
    frame.nameSortButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -2)
    frame.nameSortButton:SetWidth(270)

    frame.categorySortButton = CreateSortClickArea("category")
    frame.categorySortButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 282, -2)
    frame.categorySortButton:SetWidth(70)

    frame.statusSortButton = CreateSortClickArea("status")
    frame.statusSortButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -2)
    frame.statusSortButton:SetWidth(84)

    UpdateRouteSortHeaderLabels(frame)

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
    UpdateRouteSortHeaderLabels(widget.frame)
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
    local rowHeight = 34
    local rowOddBgColor = { 0, 0, 0, 0 }
    local rowEvenBgColor = { 0, 0, 0, 0.24 }

    -- Collect routes from APR.RouteQuestStepList for a given expansion tab.
    local function AddRoutesForExpansion(tabName)
        for fileName, routeData in pairs(APR.RouteQuestStepList) do
            if type(routeData) ~= "table" or not routeData.label or routeData.expansion ~= tabName then
                -- skip
            else
                local visibility = APR:GetRouteVisibility(fileName)
                if visibility == "hidden" then
                    -- skip: conditions not met
                else
                    local routeName = routeData.label
                    if not APR:Contains(APRCustomPath[APR.PlayerID], routeName) then
                        if search == "" then
                            tinsert(sortedRoutes,
                                { fileName = fileName, routeName = routeName, tabName = tabName, visibility = visibility })
                        else
                            local rn = routeName:lower()
                            local fn = fileName:lower()
                            if rn:find(search, 1, true) or fn:find(search, 1, true) then
                                tinsert(sortedRoutes,
                                    {
                                        fileName = fileName,
                                        routeName = routeName,
                                        tabName = tabName,
                                        visibility =
                                            visibility
                                    })
                            end
                        end
                    end
                end
            end
        end
    end

    if search == "" then
        AddRoutesForExpansion(name)
    else
        -- Search across all expansions
        for fileName, routeData in pairs(APR.RouteQuestStepList) do
            if type(routeData) == "table" and routeData.label then
                local visibility = APR:GetRouteVisibility(fileName)
                if visibility ~= "hidden" then
                    local routeName = routeData.label
                    local tabName = routeData.expansion or "Unknown"
                    if not APR:Contains(APRCustomPath[APR.PlayerID], routeName) then
                        local rn = routeName:lower()
                        local fn = fileName:lower()
                        if rn:find(search, 1, true) or fn:find(search, 1, true) then
                            tinsert(sortedRoutes,
                                { fileName = fileName, routeName = routeName, tabName = tabName, visibility = visibility })
                        end
                    end
                end
            end
        end
    end

    for _, route in ipairs(sortedRoutes) do
        local routeData = APR:GetRouteData(route.fileName)
        route.categoryValue = (routeData and routeData.category) or L["LEVELING_CAT"]
        route.statusValue = GetRouteStatusText(route.fileName, route.routeName)
    end

    table.sort(sortedRoutes, function(a, b)
        local function normalize(value)
            return (value or ""):lower()
        end

        local aValue
        local bValue

        if routeSortKey == "status" then
            aValue = normalize(a.statusValue)
            bValue = normalize(b.statusValue)
        elseif routeSortKey == "category" then
            aValue = normalize(a.categoryValue)
            bValue = normalize(b.categoryValue)
        else
            aValue = normalize(a.routeName)
            bValue = normalize(b.routeName)
        end

        if aValue == bValue then
            local aName = normalize(a.routeName)
            local bName = normalize(b.routeName)
            if aName == bName then
                return normalize(a.fileName) < normalize(b.fileName)
            end
            return aName < bName
        end

        if routeSortAsc then
            return aValue < bValue
        end
        return aValue > bValue
    end)

    if #sortedRoutes == 0 then
        local noRoutesContainer = CreateFrame("Frame", nil, widget.frame)
        noRoutesContainer:SetSize(400, rowHeight)
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
        for index, route in ipairs(sortedRoutes) do
            -- Create a container for each line
            local lineContainer = CreateFrame("Frame", nil, widget.frame, "BackdropTemplate")
            lineContainer:SetSize(430, rowHeight)
            lineContainer:SetPoint("TOPLEFT", 10, yOffset)
            lineContainer:SetPoint("TOPRIGHT", -10, yOffset)

            local rowBackground = lineContainer:CreateTexture(nil, "BACKGROUND")
            rowBackground:SetAllPoints()
            if index % 2 == 0 then
                rowBackground:SetColorTexture(unpack(rowEvenBgColor))
            else
                rowBackground:SetColorTexture(unpack(rowOddBgColor))
            end

            local borderTexture = lineContainer:CreateTexture(nil, "BACKGROUND")
            borderTexture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            borderTexture:SetSize(450, 1)
            borderTexture:SetPoint("TOPLEFT", lineContainer, "TOPLEFT", 0, 0)
            borderTexture:SetPoint("TOPRIGHT", lineContainer, "TOPRIGHT", 0, 0)
            borderTexture:SetVertexColor(unpack(lineColor))

            local nameText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("LEFT")
            nameText:SetWidth(270)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(route.routeName)

            local categoryText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            categoryText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
            categoryText:SetWidth(70)
            categoryText:SetJustifyH("LEFT")
            categoryText:SetText(route.categoryValue)

            local statusText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            statusText:SetPoint("RIGHT")
            statusText:SetWidth(58)
            statusText:SetJustifyH("RIGHT")
            statusText:SetWordWrap(true)

            statusText:SetText(route.statusValue)

            local routeTabName = route.tabName or name
            local isDisabled = (route.visibility == "disabled")
            lineContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                -- Route name (yellow title)
                GameTooltip:AddLine(route.routeName, 1, 0.82, 0)
                -- Category & Status
                GameTooltip:AddLine((L["CATEGORY"] or "Category") .. ": " .. route.categoryValue, 0.8, 0.8, 0.8)
                GameTooltip:AddLine((L["STATUS"] or "Status") .. ": " .. route.statusValue, 0.8, 0.8, 0.8)
                GameTooltip:AddLine(" ")
                if isDisabled then
                    GameTooltip:AddLine(L["ROUTE_DISABLED"], 1, 0.3, 0.3, true)
                    -- Show unmet conditions
                    local unmetConditions = APR:GetUnmetConditions(route.fileName)
                    if #unmetConditions > 0 then
                        for _, condition in ipairs(unmetConditions) do
                            GameTooltip:AddLine("  - " .. condition, 1, 0.5, 0.3)
                        end
                    end
                else
                    GameTooltip:AddLine(L["MOVE_ROUTE_TO_CUSTOM_PATH"], 0.5, 0.8, 1, true)
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
                    APR:AddRouteToCustomPathByKey(route.fileName)
                    APR.routeconfig:SendMessage("APR_Custom_Path_Update")
                end
            end)
            if isDisabled then
                nameText:SetTextColor(unpack(APR.Color.midGray))
                categoryText:SetTextColor(unpack(APR.Color.midGray))
                statusText:SetTextColor(unpack(APR.Color.midGray))
                lineContainer:SetScript("OnMouseDown", nil)
            end

            yOffset = yOffset - rowHeight
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
    EnsurePrefabWrappedButtonWidget()

    APR.routeconfig:RegisterMessage("APR_Custom_Path_Update", function()
        if APR.OptionsRoute:IsVisible() then
            SetCustomPathListFrame(customPathListeWidget, "custom_path_area")
            SetRouteListTab(tabRouteListWidget, currentTabName)
            APR.settings:OpenSettings(L["ROUTE"])
        end

        -- to trigger the frame
        APR:Debug("Caller: APR.routeconfig:InitRouteConfig/Custom_Path_Update -> GetCurrentRouteMapIDsAndName")
        APR.currentStep:Reset()

        local routeZoneMapIDs, mapID, routeFileName, expansion = APR:GetCurrentRouteMapIDsAndName()
        APR.ActiveRoute = routeFileName

        APR:UpdateMapId()
        APR:UpdateStep()

        -- Invalidate zone check cache when route changes to ensure fresh detection
        APR._lastRouteZoneCheck = nil
        APR._lastRouteZoneResult = nil

        -- Trigger zone detection and navigation after loading new prefab routes
        local profile = APR:GetSettingsProfile()
        if APR.ActiveRoute and profile and profile.enableAddon then
            APR:InvalidatePlayerZoneCache()
            APR.transport:GetMeToRightZone()
        end

        if APR.StatusFrame and APR.StatusFrame:IsShown() and APR.updateStatusFrame then
            APR:updateStatusFrame()
        end
    end)
    InitRouteSearchFrame("RouteSearchFrame")
    InitDialogControlFrame("CustomPathRouteListFrame", CreateCustomPathTableFrame, SetCustomPathListFrame)
    InitDialogControlFrame("RouteListFrame", CreateRouteTableFrame, SetRouteListTab)
    return GetConfigOptionTable()
end

function APR.routeconfig:SendCustomPathUpdate(suppressUpdate)
    if suppressUpdate or self._isBuildingSpeedrunPrefab then
        return
    end
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
        local currentRouteKey = APR:GetRouteKeyFromDisplayName(currentRouteName)
        local currentRouteData = APR:GetRouteData(currentRouteKey)

        if currentRouteData and currentRouteData.notSkippable then
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
                    APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.TheWarWithin)
                end)
        end
    end
end
