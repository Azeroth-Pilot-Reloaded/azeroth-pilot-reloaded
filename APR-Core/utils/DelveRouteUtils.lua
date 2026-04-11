local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local function GetPlayerData()
    if not APRData or not APR.PlayerID then
        return nil
    end

    APRData[APR.PlayerID] = APRData[APR.PlayerID] or {}
    return APRData[APR.PlayerID]
end

local function GetTemporaryRouteState(create)
    local playerData = GetPlayerData()
    if not playerData then
        return nil
    end

    local state = playerData.TemporaryRouteState
    if not state and create then
        state = {}
        playerData.TemporaryRouteState = state
    end

    return state
end

local function BuildDelveSessionKey(context)
    local scenarioID = tonumber(context and context.scenarioID)
    if scenarioID then
        return "scenario:" .. tostring(scenarioID)
    end

    return "map:" .. tostring(context and context.mapID or 0)
end

local function CancelDelveRefreshTimer()
    if APR._delveRouteRefreshTimer then
        APR._delveRouteRefreshTimer:Cancel()
        APR._delveRouteRefreshTimer = nil
    end
end

function APR:IsTemporaryRoute(routeKey)
    local routeData = routeKey and self.RouteQuestStepList and self.RouteQuestStepList[routeKey] or nil
    return type(routeData) == "table" and (routeData.temporary == true or self:IsDelveRoute(routeKey))
end

function APR:IsTemporaryRouteActive()
    return self:IsTemporaryRoute(self.ActiveRoute)
end

function APR:IsDelveRoute(routeKey)
    local routeData = routeKey and self.RouteQuestStepList and self.RouteQuestStepList[routeKey] or nil
    if type(routeData) ~= "table" then
        return false
    end

    if self.DelveRouteRegistry and self.DelveRouteRegistry[routeKey] then
        return true
    end

    return type(routeData.delve) == "table"
end

function APR:GetDelveScenarioBlocks(routeKey)
    local routeData = routeKey and self:GetRouteData(routeKey) or nil
    local scenarios = routeData and (routeData.scenarios or routeData.steps) or nil
    if type(scenarios) ~= "table" or #scenarios == 0 then
        return nil
    end

    local blocks = {}
    for _, entry in ipairs(scenarios) do
        if type(entry) ~= "table" or entry.scenarioID == nil or type(entry.steps) ~= "table" then
            return nil
        end

        table.insert(blocks, entry)
    end

    return #blocks > 0 and blocks or nil
end

function APR:GetDelveScenarioIDs(routeKey)
    local blocks = self:GetDelveScenarioBlocks(routeKey)
    if not blocks then
        return {}
    end

    local scenarioIDs = {}
    local seenScenarioIDs = {}
    for _, block in ipairs(blocks) do
        local scenarioID = tonumber(block.scenarioID)
        if scenarioID and not seenScenarioIDs[scenarioID] then
            seenScenarioIDs[scenarioID] = true
            table.insert(scenarioIDs, scenarioID)
        end
    end

    table.sort(scenarioIDs)
    return scenarioIDs
end

function APR:HasDelveScenarioBlock(routeKey, scenarioID)
    scenarioID = tonumber(scenarioID)
    if not scenarioID then
        return false
    end

    return self:Contains(self:GetDelveScenarioIDs(routeKey), scenarioID)
end

function APR:GetScenarioZoneInfo(scenarioMapID)
    if not scenarioMapID or not self.ZonesData or not self.ZonesData.Scenarios then
        return nil
    end

    local scenarioContinentID = self:GetContinent(scenarioMapID)
    local scenariosByContinent = scenarioContinentID and self.ZonesData.Scenarios[scenarioContinentID] or nil
    return scenariosByContinent and scenariosByContinent[scenarioMapID] or nil
end

function APR:GetPrimaryCustomPathRouteKey()
    if not APRCustomPath or not self.PlayerID or not APRCustomPath[self.PlayerID] then
        return nil
    end

    local _, currentRouteName = next(APRCustomPath[self.PlayerID])
    if not currentRouteName then
        return nil
    end

    local _, _, routeKey = self:GetRouteMapIDsAndName(currentRouteName)
    if routeKey and routeKey ~= "" then
        return routeKey
    end

    return nil
end

function APR:GetScenarioMapIDForStep(step, routeKey)
    if type(step) ~= "table" then
        return nil
    end

    local resolvedRouteKey = routeKey or self.ActiveRoute

    for _, scenarioRef in ipairs({
        step.EnterScenario,
        step.DoScenario,
        step.LeaveScenario,
        step.EnterInstance,
        step.LeaveInstance,
    }) do
        if type(scenarioRef) == "table" and scenarioRef.mapID then
            return scenarioRef.mapID
        end
    end

    if step.Scenario then
        -- Delve scenario steps are driven by step coordinates + scenario criteria.
        -- Falling back to routeData.mapID often points to delve entrance and breaks arrow guidance.
        if resolvedRouteKey and self:IsDelveRoute(resolvedRouteKey) then
            return nil
        end

        local routeData = resolvedRouteKey and self:GetRouteData(resolvedRouteKey) or nil
        if routeData and routeData.mapID and self:GetScenarioZoneInfo(routeData.mapID) then
            return routeData.mapID
        end
    end

    return nil
end

function APR:GetScenarioStepTarget(step, routeKey)
    local scenarioMapID = self:GetScenarioMapIDForStep(step, routeKey)
    if not scenarioMapID then
        return nil, nil
    end

    return scenarioMapID, self:GetScenarioZoneInfo(scenarioMapID)
end

function APR:GetCurrentDelveContext()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        return nil
    end

    local scenarioEntry = self:GetScenarioZoneInfo(currentMapID)
    local isDelveMap = scenarioEntry and scenarioEntry.type == "DELVE"
    local scenarioInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo and C_ScenarioInfo.GetScenarioInfo() or nil
    local stepInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo and C_ScenarioInfo.GetScenarioStepInfo() or
        nil
    local scenarioID = scenarioInfo and scenarioInfo.scenarioID or nil

    if not isDelveMap then
        local matches, _ = self:FindDelveRoutesForContext({ scenarioID = scenarioID })
        if #matches == 0 then
            return nil
        end
    end

    local delveName = (isDelveMap and scenarioEntry and scenarioEntry.name) or
        ((type(scenarioInfo) == "table" and scenarioInfo.name) or nil)

    if not delveName or delveName == "" then
        delveName = L["DELVE"] or "Delve"
    end

    return {
        entry = scenarioEntry,
        mapID = currentMapID,
        name = delveName,
        scenarioID = scenarioID,
        sessionKey = BuildDelveSessionKey({ mapID = currentMapID, scenarioID = scenarioID }),
        stepID = stepInfo and stepInfo.stepID or nil,
    }
end

function APR:FindDelveRoutesForContext(context)
    if not context then
        return {}, false
    end

    local contextScenarioID = tonumber(context.scenarioID)
    if not contextScenarioID then
        return {}, false
    end

    local exactMatches = {}

    for routeKey, routeData in pairs(self.RouteQuestStepList or {}) do
        if self:IsDelveRoute(routeKey) then
            local scenarioIDs = self:GetDelveScenarioIDs(routeKey)
            if self:Contains(scenarioIDs, contextScenarioID) then
                table.insert(exactMatches, {
                    key = routeKey,
                    label = routeData.label or routeKey,
                })
            end
        end
    end

    table.sort(exactMatches, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)


    return exactMatches, #exactMatches > 0
end

function APR:ActivateTemporaryRoute(routeKey, options)
    local routeData = self:GetRouteData(routeKey)
    local state = GetTemporaryRouteState(true)
    local playerData = GetPlayerData()
    options = options or {}

    if not routeData or not state or not playerData then
        return false
    end

    local sessionKey = options.sessionKey
    local sameSession = state.routeKey == routeKey and state.sessionKey == sessionKey and self.ActiveRoute == routeKey
    if sameSession then
        return true
    end

    local previousRouteKey = options.previousRouteKey or self.ActiveRoute
    if self:IsTemporaryRoute(previousRouteKey) then
        previousRouteKey = state.previousRouteKey
    end

    state.routeKey = routeKey
    state.sessionKey = sessionKey
    state.kind = options.kind or "delve"
    state.previousRouteKey = previousRouteKey
    state.mapID = options.mapID
    state.scenarioID = options.scenarioID

    if options.resume ~= true then
        playerData[routeKey] = 1
        playerData[routeKey .. "-SkippedStep"] = 0
        playerData[routeKey .. "-ParallelStepsState"] = nil
        playerData[routeKey .. "-TotalSteps"] = nil
        playerData[routeKey .. "-RawTotalSteps"] = nil
    else
        playerData[routeKey] = playerData[routeKey] or 1
        playerData[routeKey .. "-SkippedStep"] = playerData[routeKey .. "-SkippedStep"] or 0
    end

    self:InvalidateEffectiveRouteStepsCache(routeKey)
    self.ActiveRoute = routeKey
    self:GetTotalSteps(routeKey)
    playerData[routeKey .. "-RawTotalSteps"] = self:GetRawStepCount(routeKey)

    self._delveRoutePromptState = {
        sessionKey = sessionKey,
        resolved = true,
    }

    if self.transport and self.transport._routingThrottle then
        self.transport._routingThrottle.count = 0
        self.transport._routingThrottle.firstCall = GetTime()
    end
    if self.transport then
        self.transport._routingForceRefresh = true
    end

    self:UpdateMapId()
    self:UpdateStep()
    return true
end

function APR:ClearTemporaryRoute(options)
    local state = GetTemporaryRouteState(false)
    options = options or {}
    if not state or not state.routeKey then
        return false
    end

    local restoredRouteKey = self:GetPrimaryCustomPathRouteKey() or state.previousRouteKey
    if restoredRouteKey and not self:GetRouteData(restoredRouteKey) then
        restoredRouteKey = nil
    end

    local playerData = GetPlayerData()
    if playerData then
        playerData.TemporaryRouteState = nil
    end

    self.ActiveRoute = restoredRouteKey
    if options.preserveSessionKey then
        self._delveRoutePromptState = {
            completed = true,
            resolved = true,
            sessionKey = state.sessionKey,
        }
    else
        self._delveRoutePromptState = nil
    end

    if self.transport and self.transport._routingThrottle then
        self.transport._routingThrottle.count = 0
        self.transport._routingThrottle.firstCall = GetTime()
    end
    if self.transport then
        self.transport._routingForceRefresh = true
    end

    if self.ActiveRoute then
        self:UpdateMapId()
        self:UpdateStep()
    else
        if self.routeconfig and self.routeconfig.CheckIsCustomPathEmpty then
            self.routeconfig:CheckIsCustomPathEmpty()
        end
        self:UpdateMapId()
        self:UpdateStep()
    end

    return true
end

function APR:PromptForDelveRoute(context, routes)
    local sessionKey = context and context.sessionKey or nil
    if not sessionKey or not routes or #routes == 0 then
        return
    end

    self._delveRoutePromptState = {
        sessionKey = sessionKey,
        resolved = false,
    }

    if #routes == 1 then
        local route = routes[1]
        self.questionDialog:CreateQuestionPopup(
            "APR_DELVE_ROUTE_" .. string.gsub(sessionKey, ":", "_"),
            (L["ROUTE_SUGGESTION"]) .. "\n\n" .. route.label,
            function()
                APR:ActivateTemporaryRoute(route.key, {
                    kind = "delve",
                    mapID = context.mapID,
                    previousRouteKey = APR.ActiveRoute,
                    scenarioID = context.scenarioID,
                    sessionKey = sessionKey,
                })
            end,
            function()
                APR._delveRoutePromptState = {
                    sessionKey = sessionKey,
                    resolved = true,
                }
            end
        )
        return
    end

    local options = {}
    for _, route in ipairs(routes) do
        table.insert(options, {
            key = route.key,
            label = route.label,
        })
    end

    self.questionDialog:CreateSelectionPopup(
        L["ROUTE_SUGGESTION"],
        context.name or (L["DELVE"]),
        options,
        function(option)
            if not option or not option.key then
                return
            end

            APR:ActivateTemporaryRoute(option.key, {
                kind = "delve",
                mapID = context.mapID,
                previousRouteKey = APR.ActiveRoute,
                scenarioID = context.scenarioID,
                sessionKey = sessionKey,
            })
        end,
        function()
            APR._delveRoutePromptState = {
                sessionKey = sessionKey,
                resolved = true,
            }
        end
    )
end

function APR:RefreshTemporaryDelveRoute()
    local context = self:GetCurrentDelveContext()
    local state = GetTemporaryRouteState(false)

    if not context then
        self._delvePendingScenarioAttempts = nil
        if state and state.kind == "delve" then
            self:ClearTemporaryRoute()
        else
            self._delveRoutePromptState = nil
        end
        return
    end

    local contextScenarioID = tonumber(context.scenarioID)
    if not contextScenarioID then
        self._delvePendingScenarioAttempts = (self._delvePendingScenarioAttempts or 0) + 1

        if self._delvePendingScenarioAttempts <= 24 then
            self:ScheduleDelveRouteRefresh(0.35)
        end
        return
    end

    self._delvePendingScenarioAttempts = nil

    local sessionKey = context.sessionKey
    if state and state.kind == "delve" and state.sessionKey == sessionKey and state.routeKey then
        if state.scenarioID ~= context.scenarioID and self:HasDelveScenarioBlock(state.routeKey, context.scenarioID) then
            local playerData = GetPlayerData()
            state.scenarioID = context.scenarioID

            if playerData then
                playerData[state.routeKey] = 1
                playerData[state.routeKey .. "-SkippedStep"] = 0
                playerData[state.routeKey .. "-ParallelStepsState"] = nil
                playerData[state.routeKey .. "-TotalSteps"] = nil
                playerData[state.routeKey .. "-RawTotalSteps"] = self:GetRawStepCount(state.routeKey)
            end

            self:InvalidateEffectiveRouteStepsCache(state.routeKey)
            self:GetTotalSteps(state.routeKey)
            self:UpdateMapId()
            self:UpdateStep()
            return
        end

        if self.ActiveRoute ~= state.routeKey then
            self.ActiveRoute = state.routeKey
            self:UpdateMapId()
            self:UpdateStep()
        end
        return
    end

    if state and state.kind == "delve" and state.sessionKey ~= sessionKey then
        self:ClearTemporaryRoute()
        state = nil
    end

    local routes, hasExactMatch = self:FindDelveRoutesForContext(context)
    if #routes == 0 then
        return
    end

    local hasPrimaryRoute = self:GetPrimaryCustomPathRouteKey() ~= nil
    local hasNormalActiveRoute = self.ActiveRoute and not self:IsTemporaryRouteActive()

    if (hasPrimaryRoute or hasNormalActiveRoute) and (#routes == 1 or hasExactMatch) then
        self:ActivateTemporaryRoute(routes[1].key, {
            kind = "delve",
            mapID = context.mapID,
            previousRouteKey = self.ActiveRoute,
            scenarioID = context.scenarioID,
            sessionKey = sessionKey,
        })
        return
    end

    local promptState = self._delveRoutePromptState
    if promptState and promptState.sessionKey == sessionKey then
        return
    end

    self:PromptForDelveRoute(context, routes)
end

function APR:ScheduleDelveRouteRefresh(delay)
    CancelDelveRefreshTimer()

    APR._delveRouteRefreshTimer = C_Timer.NewTimer(delay or 0.25, function()
        APR._delveRouteRefreshTimer = nil
        APR:RefreshTemporaryDelveRoute()
    end)
end
