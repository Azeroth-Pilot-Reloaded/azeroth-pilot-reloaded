-- Renders travel/scenario actions and their completion checks; navigation overrides affect only the runtime step.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local handlers = APR.stepHandlers

function handlers.RenderScenarioTravel(step, currentStepIndex)
    local function handleScenarioStep(stepType, scenarioMapID)
        APR:Debug(stepType .. " Step:" .. currentStepIndex)

        local currentMapID    = C_Map.GetBestMapForUnit('player')
        local mapInfo         = APR:GetMapInfoCached(scenarioMapID)
        local scenarioInfo    = APR:GetScenarioZoneInfo(scenarioMapID)
        local isDelveScenario = scenarioInfo and scenarioInfo.type == "DELVE"
        local isCompleted     = (not isDelveScenario) and
            tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID) or false

        return currentMapID, scenarioInfo, mapInfo, isCompleted
    end

    if step.EnterScenario or step.EnterInstance then
        local scenarioMapID = step.EnterScenario and step.EnterScenario.mapID or step.EnterInstance.mapID
        local questID = step.EnterScenario and step.EnterScenario.questID or step.EnterInstance.questID
        local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Enter Scenario", scenarioMapID)


        if isCompleted or scenarioMapID == currentMapID or scenarioMapID == APR:GetPlayerParentMapID()
            or C_QuestLog.IsQuestFlaggedCompleted(questID)
            or APR:IsQuestReadyForTurnIn(questID) then
            APR:UpdateNextStep()
        end

        APR.currentStep:AddQuestSteps("ENTER_IN_" .. scenarioInfo.type,
            string.format(L["ENTER_IN"], L[scenarioInfo.type], mapInfo.name), mapInfo.name)
        step.Coord = scenarioInfo.Coord
        APR.Arrow:SetCoord()
    elseif step.DoScenario then
        local scenarioMapID = step.DoScenario.mapID
        local doScenarioQuestID = step.DoScenario.questID
        local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Do Scenario", scenarioMapID)

        if step.Qpart then
            local questID, objectiveIndex = next(step.Qpart)
            local questData = APR.ActiveQuests[questID]
            local objectiveData = questData and questData.objectives and questData.objectives[objectiveIndex] or nil
            if (objectiveData and objectiveData.status == APR.QUEST_STATUS.COMPLETE) and isCompleted then
                APR:UpdateNextStep()
            end
        elseif isCompleted or C_QuestLog.IsQuestFlaggedCompleted(doScenarioQuestID)
            or APR:IsQuestReadyForTurnIn(doScenarioQuestID) then
            APR:UpdateNextStep()
        end

        -- IF you're not inside the scenario, add coord to the entrance
        if scenarioMapID ~= currentMapID then
            step.Coord = scenarioInfo.Coord
            step.NoArrow = false
        else
            step.Coord = nil
            step.NoArrow = true
        end
        APR.Arrow:SetCoord()

        APR.currentStep:AddQuestSteps("COMPLETE_SOMETHING_" .. scenarioInfo.type,
            string.format(L["COMPLETE_SOMETHING"], L[scenarioInfo.type], mapInfo.name),
            mapInfo.name)
    elseif step.LeaveScenario then
        local scenarioMapID = step.LeaveScenario.mapID
        local questID = step.LeaveScenario.questID
        local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Leave Scenario", scenarioMapID)

        if (isCompleted or APR:IsQuestReadyForTurnIn(questID)) and scenarioMapID ~= currentMapID
            and scenarioMapID ~= APR:GetPlayerParentMapID()
            or C_QuestLog.IsQuestFlaggedCompleted(questID) then
            APR:UpdateNextStep()
        end

        if scenarioInfo then
            APR.currentStep:AddQuestSteps("LEAVE_" .. scenarioInfo.type,
                string.format(L["LEAVE_" .. scenarioInfo.type], mapInfo.name), mapInfo.name)
        end
    elseif step.LeaveInstance then
        local instanceMapID = step.LeaveInstance.mapID
        local questID = step.LeaveInstance.questID
        local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Leave Instance", instanceMapID)

        if isCompleted and instanceMapID ~= currentMapID or C_QuestLog.IsQuestFlaggedCompleted(questID) then
            APR:UpdateNextStep()
        end

        if scenarioInfo then
            APR.currentStep:AddQuestSteps("LEAVE_" .. scenarioInfo.type,
                string.format(L["LEAVE_" .. scenarioInfo.type], mapInfo.name), mapInfo.name)
        end
    end
end

function handlers.TakePortal(step, showStepDetails, currentStepIndex)
    local portalData = step.TakePortal

    local questID = portalData.questID
    local mapID = portalData.mapID
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local parentMapID = APR:GetPlayerParentMapID()

    if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        APR:NextQuestStep()
        return true
    end

    if mapID and (currentMapID == mapID or parentMapID == mapID) then
        APR:NextQuestStep()
        return true
    end

    if showStepDetails then
        local mapInfo = APR:GetMapInfoCached(mapID)
        local zoneName = (mapInfo and mapInfo.name) or UNKNOWN
        local text = string.format(L["USE_PORTAL_TO"], zoneName)

        APR.currentStep:AddQuestSteps("TAKE_PORTAL", text, mapID)
    end
end

function handlers.Waypoint(step, showStepDetails, currentStepIndex)
    local canAutoSkipWaypoint = not step.NonSkippableWaypoint

    if (canAutoSkipWaypoint and APR.settings.profile.autoSkipAllWaypoints) then
        APR:NextQuestStep()
    elseif (canAutoSkipWaypoint and APR.settings.profile.autoSkipWaypointsFly and IsFlyableArea() and not IsIndoors() and APR:CheckFlySkill()) then
        APR:NextQuestStep()
    else
        if step.WaypointDB then
            local questIDs = step.WaypointDB
            for _, questID in ipairs(questIDs) do
                if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                    APR:NextQuestStep()
                    return true
                end
            end
        end
        local questID = step.Waypoint
        if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
            APR:Debug("APR.UpdateStep:Waypoint:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])

            APR:NextQuestStep()
            return true
        elseif showStepDetails then
            APR.currentStep:AddExtraLineText("Waypoint" .. questID, APR:CheckWaypointText())
        end
    end
end

function handlers.UseHS(step, showStepDetails, currentStepIndex)
    local questKey, questText, useHSKey, spellID, type
    if step.UseHS then
        questKey = step.UseHS
        questText = L["USE_HEARTHSTONE"]
        useHSKey = "UseHS"
        spellID = APR:GetHearthstoneItemID()
        type = 'item'
    elseif step.UseDalaHS then
        questKey = step.UseDalaHS
        questText = L["USE_DALARAN_HEARTHSTONE"]
        useHSKey = "UseDalaHS"
        spellID = APR.dalaHSSpellID
        type = 'spell'
    else
        questKey = step.UseGarrisonHS
        questText = L["USE_GARRISON_HEARTHSTONE"]
        useHSKey = "UseGarrisonHS"
        spellID = APR.garrisonHSSpellID
        type = 'spell'
    end

    if showStepDetails then
        APR.currentStep:AddQuestSteps(questKey, questText, useHSKey)
        APR.currentStep:AddStepButton(questKey .. "-" .. useHSKey, spellID, type)
    end

    if C_QuestLog.IsQuestFlaggedCompleted(questKey) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.SetHS(step, showStepDetails, currentStepIndex)
    if showStepDetails then
        APR.currentStep:AddQuestSteps(step.SetHS, L["SET_HEARTHSTONE"], "SetHS")
    end
    if (C_QuestLog.IsQuestFlaggedCompleted(step.SetHS)) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.GetFP(step, showStepDetails, currentStepIndex)
    local routeZoneMapIDs, mapID, routeName, expansion = APR:GetCurrentRouteMapIDsAndName()
    local stepZones = APR:GetStepZoneList(step, mapID)
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local parentMapID = APR:GetPlayerParentMapID()

    local isInStepZone = false
    if #stepZones > 0 then
        isInStepZone =
            (currentMapID and APR:Contains(stepZones, currentMapID)) or
            (parentMapID and APR:Contains(stepZones, parentMapID))
    end

    if #stepZones > 0 and not isInStepZone then
        APR:Debug("APR.UpdateStep:GetFP:Skip zone mismatch: " ..
            tostring(step.GetFP) .. " | " .. tostring(currentMapID) .. " | " .. tostring(parentMapID))
        APR:UpdateNextStep()
        return true
    end

    if showStepDetails then
        APR.currentStep:AddQuestSteps(step.GetFP, L["GET_FLIGHTPATH"], "GetFP")
    end
    if APR:HasTaxiNode(step.GetFP) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.UseFlightPath(step, showStepDetails, currentStepIndex)
    if showStepDetails then
        local questText = step.Boat and
            string.format(L["USE_BOAT"], APR:GetTaxiNodeName(step)) or
            string.format(L["USE_FLIGHTPATH"], APR:GetTaxiNodeName(step))
        APR.currentStep:AddQuestSteps(step.UseFlightPath, questText, "UseFlightPath")
    end
    if C_QuestLog.IsQuestFlaggedCompleted(step.UseFlightPath) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.RenderScenarioProgress(step)
    if step.Scenario then
        local scenario = step.Scenario
        local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
        local questID = scenario.questID
        local scenarioProgressText = APR:GetScenarioCriteriaProgressText(scenario)
        local isDelveRoute = APR:IsDelveRoute(APR.ActiveRoute)
        local canUseScenarioQuestCompletion = questID and (not isDelveRoute) and tonumber(questID) ~= 1
        local canUseScenarioCompletedCache = not isDelveRoute

        if canUseScenarioQuestCompletion and C_QuestLog.IsQuestFlaggedCompleted(questID) then
            APR:UpdateNextStep()
            return true
        end

        if APR:IsScenarioTrigTextMatched(step, scenario) or
            APR:QpartPart_TrigTextMatch(step, scenario.scenarioID, scenarioProgressText) then
            APR:UpdateNextStep()
            return true
        end

        if not scenarioInfo then
            if canUseScenarioCompletedCache and APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], scenario.stepID, scenario.criteriaID, scenario.criteriaIndex) then
                APR:UpdateNextStep()
            else
                local scenarioStepInfo = C_ScenarioInfo.GetScenarioStepInfo(scenario.stepID)
                APR.currentStep:AddExtraLineText("SCENARIO-" .. scenario.criteriaID,
                    format(L["SCENARIO_ERROR"], scenarioStepInfo.title))
            end
        else
            if canUseScenarioCompletedCache and APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], scenario.stepID, scenario.criteriaID, scenario.criteriaIndex) then
                APR:UpdateNextStep()
                return true
            end

            local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario.criteriaIndex)
            if criteriaInfo.completed then
                APR:UpdateNextStep()
                return true
            else
                APR.currentStep:AddQuestSteps(
                    scenario.scenarioID,
                    scenarioProgressText or criteriaInfo.description,
                    scenario.criteriaID,
                    true
                )
            end
        end
    end
end
