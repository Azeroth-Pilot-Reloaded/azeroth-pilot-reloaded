local AceGUI = LibStub("AceGUI-3.0")
local HereBeDragons = LibStub("HereBeDragons-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.worldCoordinateConverter = APR:NewModule("WorldCoordinateConverter")

local TEXT = {
    title = "APR - Map to world coordinates",
    route = "Route (type to search)",
    convert = "Convert",
    output = "Result (Ctrl+C to copy)",
    selectRoute = "Select a route, then convert it. Addon route data is not modified.",
    noRoute = "Unable to find the selected route.",
    noCoordinates = "No convertible coordinates were found in this route.",
    status = "%d coordinate(s) converted, %d error(s).",
}

local function IsCoordinate(value)
    return type(value) == "table" and type(value.x) == "number" and type(value.y) == "number"
end

local function GetFirstZone(value)
    if type(value) ~= "table" then
        return value
    end

    if value[1] then
        return value[1]
    end

    for zoneKey, zone in pairs(value) do
        if type(zone) == "boolean" then
            if zone then
                return zoneKey
            end
        else
            return zone
        end
    end
end

local function GetRouteSteps(route)
    if type(route) ~= "table" then
        return nil
    end

    return route.steps or route
end

local function AddCoordinateTarget(targets, stepIndex, coordinate, zone, path)
    if not IsCoordinate(coordinate) then
        return
    end

    targets[#targets + 1] = {
        stepIndex = stepIndex,
        coordinate = coordinate,
        zone = GetFirstZone(zone),
        path = path,
    }
end

local function GetCoordinatePath(step, coordinateKey)
    local sourceName = step.Coords and "Coords" or "Coord"
    if type(coordinateKey) == "number" then
        return string.format(".%s[%d]", sourceName, coordinateKey)
    end

    return string.format(".%s[%q]", sourceName, tostring(coordinateKey))
end

local function AddCoordinateEntry(targets, step, stepIndex, entry, coordinateKey, zone)
    local path = GetCoordinatePath(step, coordinateKey)
    if IsCoordinate(entry) then
        AddCoordinateTarget(targets, stepIndex, entry, zone, path)
    elseif type(entry) == "table" and IsCoordinate(entry.Coord) then
        AddCoordinateTarget(targets, stepIndex, entry.Coord, zone, path .. ".Coord")
    end
end

local function GetCoordinateTargets(route, step, stepIndex)
    local targets = {}
    local fallbackZone = step.Zone or step.Zones or route.mapID or route.MapID or route.Zone

    if IsCoordinate(step.Coord) then
        AddCoordinateTarget(targets, stepIndex, step.Coord, fallbackZone, ".Coord")
        return targets
    end

    local coordinates = step.Coords or step.Coord
    if type(coordinates) ~= "table" then
        return targets
    end

    for coordinateIndex, entry in ipairs(coordinates) do
        local zone = type(entry) == "table" and
            (entry.Zone or entry.zone or entry.mapID or entry.MapID or entry.uiMapID or entry.UiMapID) or nil
        zone = zone or (type(fallbackZone) == "table" and fallbackZone[coordinateIndex]) or fallbackZone
        AddCoordinateEntry(targets, step, stepIndex, entry, coordinateIndex, zone)
    end

    if #coordinates == 0 then
        local coordinateKeys = {}
        for coordinateKey in pairs(coordinates) do
            coordinateKeys[#coordinateKeys + 1] = coordinateKey
        end
        table.sort(coordinateKeys, function(left, right)
            if type(left) == "number" and type(right) == "number" then
                return left < right
            end
            return tostring(left) < tostring(right)
        end)

        for _, coordinateKey in ipairs(coordinateKeys) do
            local entry = coordinates[coordinateKey]
            local zone = type(entry) == "table" and
                (entry.Zone or entry.zone or entry.mapID or entry.MapID or entry.uiMapID or entry.UiMapID) or nil
            zone = zone or tonumber(coordinateKey) or fallbackZone
            AddCoordinateEntry(targets, step, stepIndex, entry, coordinateKey, zone)
        end
    end

    return targets
end

local function GetRouteNames()
    local names = {}
    local labels = {}

    for routeName, route in pairs(APR.RouteQuestStepList or {}) do
        if type(routeName) == "string" and type(route) == "table" and GetRouteSteps(route) then
            names[#names + 1] = routeName
            local label = type(route.label) == "string" and route.label or nil
            labels[routeName] = label and string.format("%s - %s", routeName, label) or routeName
        end
    end

    table.sort(names)
    return names, labels
end

local MAX_SUGGESTIONS = 10

local function GetRouteMatches(routeNames, routeLabels, query)
    local normalizedQuery = string.lower(APR:TrimString(query or ""))
    local matches = {}

    for _, routeName in ipairs(routeNames) do
        local routeNameLower = string.lower(routeName)
        local searchableText = string.lower(routeLabels[routeName] or routeName)
        local matchesAllTokens = true

        for token in string.gmatch(normalizedQuery, "%S+") do
            if not string.find(searchableText, token, 1, true) then
                matchesAllTokens = false
                break
            end
        end

        if matchesAllTokens then
            local rank = 4
            if routeNameLower == normalizedQuery then
                rank = 0
            elseif normalizedQuery ~= "" and string.find(routeNameLower, normalizedQuery, 1, true) == 1 then
                rank = 1
            elseif normalizedQuery ~= "" and string.find(searchableText, normalizedQuery, 1, true) == 1 then
                rank = 2
            elseif normalizedQuery ~= "" and string.find(searchableText, normalizedQuery, 1, true) then
                rank = 3
            end

            matches[#matches + 1] = { name = routeName, rank = rank }
        end
    end

    table.sort(matches, function(left, right)
        if left.rank ~= right.rank then
            return left.rank < right.rank
        end
        return left.name < right.name
    end)

    return matches
end

local function CreateSuggestionFrame()
    local suggestionFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    suggestionFrame:SetFrameStrata("TOOLTIP")
    suggestionFrame:SetFrameLevel(1000)
    suggestionFrame:SetToplevel(true)
    suggestionFrame:SetClampedToScreen(true)
    suggestionFrame:EnableMouse(true)
    suggestionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    suggestionFrame.buttons = {}

    for index = 1, MAX_SUGGESTIONS do
        local button = CreateFrame("Button", nil, suggestionFrame)
        button:SetHeight(22)
        button:SetPoint("LEFT", suggestionFrame, "LEFT", 5, 0)
        button:SetPoint("RIGHT", suggestionFrame, "RIGHT", -5, 0)
        if index == 1 then
            button:SetPoint("TOP", suggestionFrame, "TOP", 0, -5)
        else
            button:SetPoint("TOP", suggestionFrame.buttons[index - 1], "BOTTOM", 0, 0)
        end
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.text:SetPoint("LEFT", button, "LEFT", 5, 0)
        button.text:SetPoint("RIGHT", button, "RIGHT", -5, 0)
        button.text:SetJustifyH("LEFT")
        button.text:SetWordWrap(false)

        button:SetScript("OnClick", function(self)
            if suggestionFrame.onSelect and self.routeName then
                suggestionFrame.onSelect(self.routeName)
            end
        end)

        suggestionFrame.buttons[index] = button
    end

    suggestionFrame:Hide()
    return suggestionFrame
end

local ROUTE_KEY_ORDER = {
    label = 1,
    expansion = 2,
    category = 3,
    prefab = 4,
    mapID = 5,
    conditions = 6,
    requiredRoute = 7,
    nextRoute = 8,
    steps = 1000,
}

local KEY_TYPE_ORDER = {
    number = 1,
    string = 2,
    boolean = 3,
    table = 4,
}

local function CopyRouteValue(value, copies)
    if type(value) ~= "table" then
        return value
    end

    copies = copies or {}
    if copies[value] then
        return copies[value]
    end

    local copy = {}
    copies[value] = copy
    for key, childValue in pairs(value) do
        copy[CopyRouteValue(key, copies)] = CopyRouteValue(childValue, copies)
    end
    return copy
end

local function GetEnumExpression(enumName, enumValues, value)
    if type(enumValues) ~= "table" then
        return nil
    end

    for enumKey, enumValue in pairs(enumValues) do
        if enumValue == value and type(enumKey) == "string" and
            string.match(enumKey, "^[%a_][%w_]*$") then
            return string.format("APR.%s.%s", enumName, enumKey)
        end
    end
end

local localeKeysByValue
local function GetLocaleExpression(value)
    if type(value) ~= "string" then
        return nil
    end

    if not localeKeysByValue then
        localeKeysByValue = {}
        for localeKey, localizedValue in pairs(L) do
            if type(localeKey) == "string" and type(localizedValue) == "string" then
                local currentKey = localeKeysByValue[localizedValue]
                if not currentKey or localeKey < currentKey then
                    localeKeysByValue[localizedValue] = localeKey
                end
            end
        end
    end

    local localeKey = localeKeysByValue[value]
    return localeKey and string.format("L[%q]", localeKey) or nil
end

local function IsArray(value)
    local count = 0
    local maximumIndex = 0

    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false, 0
        end
        count = count + 1
        maximumIndex = math.max(maximumIndex, key)
    end

    return count == maximumIndex, maximumIndex
end

local function GetOrderedKeys(value, tableKind)
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        if tableKind == "route" then
            local leftOrder = ROUTE_KEY_ORDER[left] or 500
            local rightOrder = ROUTE_KEY_ORDER[right] or 500
            if leftOrder ~= rightOrder then
                return leftOrder < rightOrder
            end
        end

        if left == "_index" then
            return false
        elseif right == "_index" then
            return true
        end

        local leftType = type(left)
        local rightType = type(right)
        if leftType == rightType and (leftType == "number" or leftType == "string") then
            return left < right
        elseif leftType == rightType then
            return tostring(left) < tostring(right)
        end
        return (KEY_TYPE_ORDER[leftType] or 99) < (KEY_TYPE_ORDER[rightType] or 99)
    end)

    return keys
end

local function SerializeScalar(value, key, tableKind, warnings)
    local valueType = type(value)
    if valueType == "string" then
        if key == "label" then
            local localeExpression = GetLocaleExpression(value)
            if localeExpression then
                return localeExpression
            end
        elseif key == "expansion" then
            local expansionExpression = GetEnumExpression("EXPANSIONS", APR.EXPANSIONS, value)
            if expansionExpression then
                return expansionExpression
            end
        elseif key == "category" then
            local categoryExpression = GetEnumExpression("CATEGORIES", APR.CATEGORIES, value)
            if categoryExpression then
                return categoryExpression
            end
        end
        return string.format("%q", value)
    elseif valueType == "number" then
        if value ~= value then
            return "(0 / 0)"
        elseif value == math.huge then
            return "math.huge"
        elseif value == -math.huge then
            return "-math.huge"
        end
        return tostring(value)
    elseif valueType == "boolean" then
        return tostring(value)
    elseif valueType == "nil" then
        return "nil"
    end

    warnings[#warnings + 1] = string.format("unsupported Lua value type: %s", valueType)
    return string.format("nil --[[ unsupported %s ]]", valueType)
end

local function SerializeKey(key, tableKind, warnings)
    if tableKind == "prefab" then
        local prefabExpression = GetEnumExpression("PREFAB_TYPES", APR.PREFAB_TYPES, key)
        if prefabExpression then
            return string.format("[%s]", prefabExpression)
        end
    end

    if type(key) == "string" and string.match(key, "^[%a_][%w_]*$") then
        return key
    end
    return string.format("[%s]", SerializeScalar(key, nil, nil, warnings))
end

local SerializeValue

local function SerializeTable(value, depth, stack, tableKind, warnings)
    if stack[value] then
        warnings[#warnings + 1] = "cyclic table replaced with nil"
        return "nil --[[ cyclic table ]]"
    end

    if not next(value) then
        return "{}"
    end

    stack[value] = true
    local isArray, arrayLength = IsArray(value)
    local keys = isArray and nil or GetOrderedKeys(value, tableKind)
    local inlineParts = {}
    local canInline = true

    if isArray then
        for index = 1, arrayLength do
            if type(value[index]) == "table" then
                canInline = false
                break
            end
            inlineParts[#inlineParts + 1] = SerializeValue(value[index], depth + 1, stack, nil, nil, warnings)
        end
    else
        for _, key in ipairs(keys) do
            if type(value[key]) == "table" then
                canInline = false
                break
            end
            inlineParts[#inlineParts + 1] = string.format("%s = %s",
                SerializeKey(key, tableKind, warnings),
                SerializeValue(value[key], depth + 1, stack, key, nil, warnings))
        end
    end

    local inlineValue = canInline and string.format("{ %s }", table.concat(inlineParts, ", ")) or nil
    if inlineValue and #inlineValue <= 120 then
        stack[value] = nil
        return inlineValue
    end

    local indentation = string.rep("    ", depth)
    local childIndentation = string.rep("    ", depth + 1)
    local lines = { "{" }

    if isArray then
        for index = 1, arrayLength do
            local childKind = tableKind == "steps" and "step" or nil
            lines[#lines + 1] = childIndentation ..
                SerializeValue(value[index], depth + 1, stack, nil, childKind, warnings) .. ","
        end
    else
        for _, key in ipairs(keys) do
            local childKind
            if key == "steps" then
                childKind = "steps"
            elseif key == "prefab" then
                childKind = "prefab"
            end
            lines[#lines + 1] = string.format("%s%s = %s,", childIndentation,
                SerializeKey(key, tableKind, warnings),
                SerializeValue(value[key], depth + 1, stack, key, childKind, warnings))
        end
    end

    lines[#lines + 1] = indentation .. "}"
    stack[value] = nil
    return table.concat(lines, "\n")
end

SerializeValue = function(value, depth, stack, key, tableKind, warnings)
    if type(value) == "table" then
        return SerializeTable(value, depth, stack, tableKind, warnings)
    end
    return SerializeScalar(value, key, tableKind, warnings)
end

function APR.worldCoordinateConverter:ConvertRoute(routeName)
    local route = APR.RouteQuestStepList and APR.RouteQuestStepList[routeName]
    local convertedRoute = CopyRouteValue(route)
    local steps = GetRouteSteps(convertedRoute)
    if not steps then
        return TEXT.noRoute, 0, 1
    end

    local conversionErrors = {}
    local convertedCount = 0
    local errorCount = 0

    for stepIndex, step in ipairs(steps) do
        if type(step) == "table" then
            local targets = GetCoordinateTargets(convertedRoute, step, stepIndex)
            for _, target in ipairs(targets) do
                local coordinate = target.coordinate
                local zone = tonumber(target.zone)

                if not zone then
                    errorCount = errorCount + 1
                    conversionErrors[#conversionErrors + 1] = string.format(
                        "Step %02d%s: missing Zone/mapID for Local=(%.2f,%.2f)",
                        stepIndex, target.path, coordinate.x, coordinate.y)
                else
                    local worldX, worldY = HereBeDragons:GetWorldCoordinatesFromZone(
                        coordinate.x / 100, coordinate.y / 100, zone)

                    if worldX and worldY then
                        convertedCount = convertedCount + 1
                        coordinate.x = tonumber(string.format("%.1f", worldX))
                        coordinate.y = tonumber(string.format("%.1f", worldY))
                    else
                        errorCount = errorCount + 1
                        conversionErrors[#conversionErrors + 1] = string.format(
                            "Step %02d%s: conversion failed for Zone=%d Local=(%.2f,%.2f)",
                            stepIndex, target.path, zone, coordinate.x, coordinate.y)
                    end
                end
            end
        end
    end

    local serializationWarnings = {}
    local serializedRoute = SerializeValue(convertedRoute, 0, {}, nil, "route", serializationWarnings)
    local output = {}

    for _, conversionError in ipairs(conversionErrors) do
        output[#output + 1] = "-- ERROR: " .. conversionError
    end
    for _, serializationWarning in ipairs(serializationWarnings) do
        output[#output + 1] = "-- WARNING: " .. serializationWarning
        errorCount = errorCount + 1
    end
    if #output > 0 then
        output[#output + 1] = ""
    end

    output[#output + 1] = string.format("APR.RouteQuestStepList[%q] = %s", routeName, serializedRoute)

    return table.concat(output, "\n"), convertedCount, errorCount
end

function APR.worldCoordinateConverter:Show()
    if self.frame then
        self.frame:Show()
        return
    end

    local routeNames, routeLabels = GetRouteNames()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(TEXT.title)
    frame:SetStatusText(TEXT.selectRoute)
    frame:SetWidth(900)
    frame:SetHeight(650)
    frame:SetLayout("Flow")
    frame:EnableResize(false)

    local routeSearch = AceGUI:Create("EditBox")
    routeSearch:SetLabel(TEXT.route)
    routeSearch:DisableButton(true)
    routeSearch:SetRelativeWidth(0.78)
    frame:AddChild(routeSearch)

    local convertButton = AceGUI:Create("Button")
    convertButton:SetText(TEXT.convert)
    convertButton:SetRelativeWidth(0.2)
    convertButton:SetDisabled(true)
    frame:AddChild(convertButton)

    local output = AceGUI:Create("MultiLineEditBox")
    output:SetLabel(TEXT.output)
    output:SetNumLines(34)
    output:SetFullWidth(true)
    output:DisableButton(true)
    output:SetText(TEXT.selectRoute)
    frame:AddChild(output)

    local selectedRoute
    local suggestions = {}
    local selectedSuggestionIndex = 0
    local suggestionFrame = self.suggestionFrame or CreateSuggestionFrame()
    self.suggestionFrame = suggestionFrame
    -- Keep the popup on UIParent. Parenting it to the AceGUI window places it
    -- below the MultiLineEditBox's scroll frame on some clients.
    suggestionFrame:SetParent(UIParent)
    suggestionFrame:SetFrameStrata("TOOLTIP")
    suggestionFrame:SetFrameLevel(1000)
    suggestionFrame:ClearAllPoints()
    suggestionFrame:SetPoint("TOPLEFT", routeSearch.editbox, "BOTTOMLEFT", -5, -3)
    suggestionFrame:SetPoint("TOPRIGHT", routeSearch.editbox, "BOTTOMRIGHT", 5, -3)

    local function UpdateSuggestionHighlight()
        for index, button in ipairs(suggestionFrame.buttons) do
            if index == selectedSuggestionIndex and button:IsShown() then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end
    end

    local function HideSuggestions()
        suggestionFrame:Hide()
        selectedSuggestionIndex = 0
    end

    local function SelectRoute(routeName)
        if not routeLabels[routeName] then
            return
        end

        selectedRoute = routeName
        routeSearch:SetText(routeName)
        convertButton:SetDisabled(false)
        HideSuggestions()
    end

    local function UpdateSuggestions(query)
        suggestions = GetRouteMatches(routeNames, routeLabels, query)
        local visibleCount = math.min(#suggestions, MAX_SUGGESTIONS)

        for index, button in ipairs(suggestionFrame.buttons) do
            local match = suggestions[index]
            if index <= visibleCount and match then
                button.routeName = match.name
                button.text:SetText(routeLabels[match.name])
                button:Show()
            else
                button.routeName = nil
                button:Hide()
            end
        end

        if visibleCount > 0 then
            selectedSuggestionIndex = 1
            suggestionFrame:SetHeight((visibleCount * 22) + 10)
            suggestionFrame:Show()
            suggestionFrame:Raise()
            UpdateSuggestionHighlight()
        else
            HideSuggestions()
        end
    end

    suggestionFrame.onSelect = SelectRoute

    routeSearch:SetCallback("OnTextChanged", function(_, _, value)
        selectedRoute = nil
        convertButton:SetDisabled(true)
        UpdateSuggestions(value)
    end)

    routeSearch:SetCallback("OnEnterPressed", function()
        local match = suggestions[selectedSuggestionIndex] or suggestions[1]
        if match then
            SelectRoute(match.name)
        end
        return true
    end)

    local editbox = routeSearch.editbox
    local originalFocusGained = editbox:GetScript("OnEditFocusGained")
    local originalArrowPressed = editbox:GetScript("OnArrowPressed")
    local originalTabPressed = editbox:GetScript("OnTabPressed")
    local originalEscapePressed = editbox:GetScript("OnEscapePressed")

    editbox:SetScript("OnEditFocusGained", function(editboxFrame, ...)
        if originalFocusGained then
            originalFocusGained(editboxFrame, ...)
        end
        if selectedRoute and editboxFrame:GetText() == selectedRoute then
            routeSearch:HighlightText()
        end
        UpdateSuggestions(editboxFrame:GetText())
    end)
    editbox:SetScript("OnArrowPressed", function(editboxFrame, key, ...)
        if originalArrowPressed then
            originalArrowPressed(editboxFrame, key, ...)
        end

        local visibleCount = math.min(#suggestions, MAX_SUGGESTIONS)
        if visibleCount == 0 then
            return
        end

        if key == "UP" then
            selectedSuggestionIndex = math.max(1, selectedSuggestionIndex - 1)
        elseif key == "DOWN" then
            selectedSuggestionIndex = math.min(visibleCount, selectedSuggestionIndex + 1)
        end
        UpdateSuggestionHighlight()
    end)
    editbox:SetScript("OnTabPressed", function(editboxFrame, ...)
        if originalTabPressed then
            originalTabPressed(editboxFrame, ...)
        end

        local match = suggestions[selectedSuggestionIndex] or suggestions[1]
        if match then
            SelectRoute(match.name)
        end
    end)
    editbox:SetScript("OnEscapePressed", function(editboxFrame, ...)
        HideSuggestions()
        if originalEscapePressed then
            originalEscapePressed(editboxFrame, ...)
        end
    end)

    convertButton:SetCallback("OnClick", function()
        local result, convertedCount, errorCount = self:ConvertRoute(selectedRoute)
        output:SetText(result)
        output:HighlightText()
        frame:SetStatusText(string.format(TEXT.status, convertedCount, errorCount))
    end)

    frame:SetCallback("OnClose", function(widget)
        suggestionFrame:Hide()
        suggestionFrame.onSelect = nil
        suggestionFrame:ClearAllPoints()
        suggestionFrame:SetParent(UIParent)
        editbox:SetScript("OnEditFocusGained", originalFocusGained)
        editbox:SetScript("OnArrowPressed", originalArrowPressed)
        editbox:SetScript("OnTabPressed", originalTabPressed)
        editbox:SetScript("OnEscapePressed", originalEscapePressed)
        AceGUI:Release(widget)
        self.frame = nil
    end)

    self.frame = frame
    routeSearch:SetFocus()
end
