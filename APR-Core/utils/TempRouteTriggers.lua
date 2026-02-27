local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.TemporaryRouteTriggers = APR.TemporaryRouteTriggers or {
    routes = {},
    byQuestID = {},
}

local function containsRoute(routeList, routeKey)
    for i = 1, #routeList do
        if routeList[i] == routeKey then
            return true
        end
    end
    return false
end

function APR:RegisterTemporaryRouteTrigger(routeKey, triggers, label)
    if not routeKey or type(triggers) ~= "table" then
        return
    end

    self.TemporaryRouteTriggers.routes[routeKey] = {
        key = routeKey,
        label = label,
        triggers = triggers,
    }

    for i = 1, #triggers do
        local questID = tonumber(triggers[i])
        if questID then
            self.TemporaryRouteTriggers.byQuestID[questID] = self.TemporaryRouteTriggers.byQuestID[questID] or {}
            if not containsRoute(self.TemporaryRouteTriggers.byQuestID[questID], routeKey) then
                table.insert(self.TemporaryRouteTriggers.byQuestID[questID], routeKey)
            end
        end
    end
end

local function appendQuestIdsFromField(destination, fieldValue, excludedQuestId, maxCount)
    if type(fieldValue) ~= "table" then
        return
    end

    for i = 1, #fieldValue do
        local questID = tonumber(fieldValue[i])
        if questID and questID ~= excludedQuestId and not containsRoute(destination, questID) then
            table.insert(destination, questID)
            if #destination >= maxCount then
                return
            end
        end
    end
end

local function collectFirstQuestTriggers(stepList, excludedQuestId, maxCount, startStepIndex)
    local questIDs = {}
    if type(stepList) ~= "table" then
        return questIDs
    end

    local startIndex = tonumber(startStepIndex) or 1
    if startIndex < 1 then
        startIndex = 1
    elseif startIndex > #stepList then
        return questIDs
    end

    for i = startIndex, #stepList do
        local step = stepList[i]
        if type(step) == "table" then
            appendQuestIdsFromField(questIDs, step.PickUp, excludedQuestId, maxCount)
            if #questIDs >= maxCount then
                return questIDs
            end
        end
    end

    for i = startIndex, #stepList do
        local step = stepList[i]
        if type(step) == "table" then
            appendQuestIdsFromField(questIDs, step.Done, excludedQuestId, maxCount)
            if #questIDs >= maxCount then
                return questIDs
            end
        end
    end

    return questIDs
end

function APR:InitTemporaryRouteTriggers()
    self.TemporaryRouteTriggers.routes = {}
    self.TemporaryRouteTriggers.byQuestID = {}

    local excludedQuestId = 1
    local maxTriggersPerRoute = 6
    local routeKeys = {}

    for routeKey in pairs(APR.RouteQuestStepList) do
        table.insert(routeKeys, routeKey)
    end

    table.sort(routeKeys)

    for i = 1, #routeKeys do
        local routeKey = routeKeys[i]
        local stepList = APR.RouteQuestStepList[routeKey]
        local skippedSteps = 0
        if APRData and APRData[self.PlayerID] then
            skippedSteps = tonumber(APRData[self.PlayerID][routeKey .. "-SkippedStep"]) or 0
        end

        local startStepIndex = skippedSteps + 1
        local triggers = collectFirstQuestTriggers(stepList, excludedQuestId, maxTriggersPerRoute, startStepIndex)
        if #triggers > 0 then
            self:RegisterTemporaryRouteTrigger(routeKey, triggers)
        end
    end
end

local function getRouteDisplayName(routeKey, routeData)
    if routeData and routeData.label then
        return routeData.label
    end

    if APR.GetRouteDisplayName then
        local routeName = APR:GetRouteDisplayName(routeKey)
        if routeName then
            return routeName
        end
    end

    return routeKey
end

function APR:ActivateRouteFromTemporaryTrigger(routeKey)
    if not routeKey then
        return
    end

    local routeName = getRouteDisplayName(routeKey, self.TemporaryRouteTriggers.routes[routeKey])
    APRCustomPath[self.PlayerID] = APRCustomPath[self.PlayerID] or {}
    APRCustomPath[self.PlayerID][1] = routeName

    APR.ActiveRoute = routeKey
    APRData[self.PlayerID][routeKey] = APRData[self.PlayerID][routeKey] or 1
    APRData[self.PlayerID][routeKey .. "-SkippedStep"] = APRData[self.PlayerID][routeKey .. "-SkippedStep"] or 0

    self:UpdateMapId()
    self:UpdateStep()
end

function APR:HandleTemporaryRouteTriggerQuestAccepted(questID)
    if APR.GetRouteSuggestionDontAsk and APR:GetRouteSuggestionDontAsk() then
        return
    end

    -- Don't suggest routes if the player already has an active route loaded.
    -- The quest being accepted is likely part of the current route's flow.
    if APR.ActiveRoute and APRCustomPath[self.PlayerID] and next(APRCustomPath[self.PlayerID]) then
        return
    end

    local routeKeys = self.TemporaryRouteTriggers.byQuestID[tonumber(questID)]
    if not routeKeys or #routeKeys == 0 then
        return
    end

    for i = 1, #routeKeys do
        if routeKeys[i] == APR.ActiveRoute then
            return
        end
    end

    local routes = {}
    for i = 1, #routeKeys do
        local routeKey = routeKeys[i]
        local routeData = self.TemporaryRouteTriggers.routes[routeKey]
        table.insert(routes, {
            key = routeKey,
            label = getRouteDisplayName(routeKey, routeData),
        })
    end

    APR.questionDialog:CreateRouteTriggerPopup(
        L["ROUTE_SUGGESTION"],
        routes,
        function(route)
            if route and route.key then
                APR:ActivateRouteFromTemporaryTrigger(route.key)
            end
        end,
        nil,
        function()
            if APR.SetRouteSuggestionDontAsk then
                APR:SetRouteSuggestionDontAsk(true)
            end
        end
    )
end
