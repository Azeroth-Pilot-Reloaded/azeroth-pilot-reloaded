local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local function GroupQuestPopup()
    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])

    if not step then return end

    local questId = step.Group.QuestId
    if not C_QuestLog.IsQuestFlaggedCompleted(questId) and not step.QuestLineSkip then
        local sugestGroupNumber = step.Group.Number
        local dialogText = L["OPTIONAL"] .. " - " .. L["SUGGESTED_PLAYERS"] .. ": " .. sugestGroupNumber

        APR.questionDialog:CreateQuestionPopup(
            dialogText,
            function()
                APRData[APR.PlayerID].WantedQuestList[questId] = 1
                APR:UpdateNextStep()
            end,
            function()
                APRData[APR.PlayerID].WantedQuestList[questId] = 0
                APR:UpdateNextStep()
            end
        )
    else
        APR:UpdateNextStep()
    end
end

function APR:UpdateStep()
    if not APR.settings.profile.enableAddon then
        return
    end

    if (APR.ActiveRoute and not APRData[APR.PlayerID][APR.ActiveRoute]) then
        APRData[APR.PlayerID][APR.ActiveRoute] = 1
    end

    -- //TODO Return if not in the right zone (check why no data on zone change with the return)
    if APR.IsInRouteZone then
        APR.currentStep:Reset()
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]

    APR:ResetMissingQuests()

    if UnitIsDeadOrGhost("player") then
        APR:Debug("Function: APR:UpdateStep() -  Player is dead - guide to corpse")
        APR:GuideToCorpse()
        return
    end

    APR:Debug("APR.UpdateStep:Current Step:", CurStep)

    if (APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep]) then
        local step = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]

        APR.currentStep:ButtonEnable()
        APR:SendMessage("APR_MAP_UPDATE")

        -- Hide the AFK frame only if the step has changed
        if APR.AFK.lastStep ~= CurStep then
            APR.AFK:HideFrame()
        end

        if APR:SkipStepCondition(step) then
            return
        end

        -- set the arrow coord before the step logic to avoid double completion
        APR.Arrow.currentStep = 0
        APR.Arrow:SetCoord()

        if (APR.ActiveRoute) then
            local function checkChromieTimeline(id)
                if APR.Level >= APR.MaxLevelChromie then return end
                local chromieExpansionOption = C_ChromieTime.GetChromieTimeExpansionOption(id)
                if (not chromieExpansionOption) then
                    APR.currentStep:AddExtraLineText("NOT_IN_CHROMIE_TIMELINE", L["NOT_IN_CHROMIE_TIMELINE"])
                elseif (chromieExpansionOption.alreadyOn == false) then
                    APR.currentStep:AddExtraLineText("SWITCH_TO_CHROMIE" .. chromieExpansionOption.name,
                        L["SWITCH_TO_CHROMIE"] .. " " .. chromieExpansionOption.name)
                end
            end
            -- Uncomment if needed for new route
            -- if (APR.RouteList.Cataclysm[APR.ActiveRoute]) then
            --     checkChromieTimeline(5)
            -- end
            -- if (APR.RouteList.TheBurningCrusade[APR.ActiveRoute]) then
            --     checkChromieTimeline(6)
            -- end
            -- if (APR.RouteList.WrathOfTheLichKing[APR.ActiveRoute]) then
            --     checkChromieTimeline(7)
            -- end
            -- if (APR.RouteList.MistsOfPandaria[APR.ActiveRoute]) then
            --     checkChromieTimeline(8)
            -- end
            if (APR.RouteList.WarlordsOfDraenor[APR.ActiveRoute]) then
                checkChromieTimeline(9)
            end
            -- if (APR.RouteList.Legion[APR.ActiveRoute]) then
            --     checkChromieTimeline(10)
            -- end
            if (APR.RouteList.BattleForAzeroth[APR.ActiveRoute]) then
                checkChromieTimeline(15)
            end
            if (APR.RouteList.Shadowlands[APR.ActiveRoute]) then
                checkChromieTimeline(14)
            end
        end

        -- Check for ExtraLineText
        local extraLines = {}
        for key, value in pairs(step) do
            if string.match(key, "ExtraLineText+") and APR.IsInRouteZone then
                table.insert(extraLines, { key = key, text = value })
            end
        end
        table.sort(extraLines, function(a, b) return a.key < b.key end)
        for i, line in ipairs(extraLines) do
            local key = line.text
            local message = rawget(L, key) or
                (AprRCData and AprRCData.ExtraLineTexts and rawget(AprRCData.ExtraLineTexts, key))
            if message then
                local colorHex, formattedMessage = APR:ExtractColorAndText(message)
                APR.currentStep:AddExtraLineText(i .. "_" .. key, formattedMessage, colorHex)
            end
        end

        if step.ExtraActionB then
            APR.currentStep:AddExtraLineText("USE_EXTRAACTIONBUTTON", L["USE_EXTRAACTIONBUTTON"])
        end

        -- //TODO REWORK ExtraLine
        if (step.ExtraLine and APR.IsInRouteZone) then
            local extraline = step.ExtraLine
            local fleetfootItemID = 44886
            local wildfireBottleItemID = 44967
            local harpysHornItemID = 9530
            local extraLineQuests = {
                [13544] = {
                    itemID = fleetfootItemID,
                    description = L["KILL_FLEETFOOT"],
                    count = 1,
                },
                [13595] = {
                    itemID = wildfireBottleItemID,
                    description = L["LOOT_WILDFIRE_BOTTLE"],
                    count = 1,
                },
                [25654] = {
                    itemID = harpysHornItemID,
                    description = L["LOOT_HARPYS_HORN"],
                    count = 1,
                }
            }
            for questID, questInfo in pairs(extraLineQuests) do
                if extraline == questID then
                    local itemCount = C_Item.GetItemCount(questInfo.itemID)
                    if itemCount < questInfo.count then
                        APR.currentStep:AddQuestSteps(questID,
                            questInfo.description .. " (" .. itemCount .. "/" .. questInfo.count .. ")", questInfo
                            .itemID)
                    else
                        APR:NextQuestStep()
                        return
                    end
                    break
                end
            end

            if (extraline == 14358) then
                local melonFruitItemID = 48106
                local satyrFleshItemID = 48857
                local satyrSaberItemID = 48943
                local requiredMelonFruitCount = 8
                local requiredSatyrFleshCount = 10
                local requiredSatyrSaberCount = 20

                local melonFruitCount = C_Item.GetItemCount(melonFruitItemID)
                local satyrFleshCount = C_Item.GetItemCount(satyrFleshItemID)
                local satyrSaberCount = C_Item.GetItemCount(satyrSaberItemID)
                if melonFruitCount < requiredMelonFruitCount then
                    APR.currentStep:AddQuestSteps(14358,
                        L["LOOT_MELONFRUIT"] .. "( " .. melonFruitCount .. "/" .. requiredMelonFruitCount .. ")",
                        melonFruitItemID)
                end
                if satyrFleshCount < requiredSatyrFleshCount then
                    APR.currentStep:AddQuestSteps(14358,
                        L["KILL_SATYR_FLESH"] .. " (" .. satyrFleshCount .. "/" .. requiredSatyrFleshCount .. ")",
                        satyrFleshItemID)
                end
                if satyrSaberCount < requiredSatyrSaberCount then
                    APR.currentStep:AddQuestSteps(14358,
                        L["LOOT_SATYR_SABER"] .. " (" .. satyrSaberCount .. "/" .. requiredSatyrSaberCount .. ")",
                        satyrSaberItemID)
                end
                if melonFruitCount == requiredMelonFruitCount and satyrFleshCount == requiredSatyrFleshCount and satyrSaberCount == requiredSatyrSaberCount then
                    APR:NextQuestStep()
                    return
                end
            end
        end

        -- REWORK LOA (BfA Loa pick)
        if step.PickedLoa and step.PickedLoa == 2 and (APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440)) then
            APR:UpdateNextStep()
            APR:Debug("PickedLoa Skip 2 step:" .. CurStep)
            return
        elseif step.PickedLoa and step.PickedLoa == 1 and (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439)) then
            APR:UpdateNextStep()
            APR:Debug("PickedLoa Skip 1 step:" .. CurStep)
            return
        end

        local function handleScenarioStep(stepType, scenarioMapID)
            APR:Debug(stepType .. " Step:" .. CurStep)

            local currentMapID        = C_Map.GetBestMapForUnit('player')
            local scenarioContinentID = APR:GetContinent(scenarioMapID)
            local mapInfo             = C_Map.GetMapInfo(scenarioMapID)
            local scenarioInfo        = APR.ZonesData.Scenarios[scenarioContinentID][scenarioMapID]
            local isCompleted         = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)

            return currentMapID, scenarioInfo, mapInfo, isCompleted
        end

        if step.EnterScenario then
            local scenarioMapID = step.EnterScenario
            local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Enter Scenario", scenarioMapID)

            if isCompleted or scenarioMapID == currentMapID then
                APR:UpdateNextStep()
            end

            APR.currentStep:AddExtraLineText("ENTER_IN_" .. scenarioInfo.type,
                format(L["ENTER_IN"], L[scenarioInfo.type]) .. ": " .. mapInfo.name)
            step.Coord = scenarioInfo.Coord
            APR.Arrow:SetCoord()
        elseif step.DoScenario then
            local scenarioMapID = step.DoScenario
            local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Do Scenario", scenarioMapID)

            if step.Qpart then
                local questID, objectiveIndex = next(step.Qpart)
                local questData = APR.ActiveQuests[questID]
                local objectiveData = questData and questData.objectives and questData.objectives[objectiveIndex] or nil
                if (objectiveData and objectiveData.status == APR.QUEST_STATUS.COMPLETE) and isCompleted then
                    APR:UpdateNextStep()
                end
            elseif isCompleted then
                APR:UpdateNextStep()
            end

            -- IF you're not inside the scenario, add coord to the entrance
            if scenarioMapID ~= currentMapID then
                step.Coord = scenarioInfo.Coord
                step.NoArrow = nil
            else
                step.Coord = nil
                step.NoArrow = 1
            end
            APR.Arrow:SetCoord()

            APR.currentStep:AddExtraLineText("COMPLETE_SOMETHING_" .. scenarioInfo.type,
                format(L["COMPLETE_SOMETHING"], L[scenarioInfo.type]) .. ": " .. mapInfo.name)
        elseif step.LeaveScenario then
            local scenarioMapID                                    = step.LeaveScenario
            local currentMapID, scenarioInfo, mapInfo, isCompleted = handleScenarioStep("Leave Scenario", scenarioMapID)

            if isCompleted and scenarioMapID ~= currentMapID then
                APR:UpdateNextStep()
            end

            APR.currentStep:AddExtraLineText("LEAVE_" .. scenarioInfo.type,
                L["LEAVE_" .. scenarioInfo.type] .. ": " .. mapInfo.name)
        end

        if step.Buffs then
            APR.Buff:RemoveAllBuffIcon()
            for _, buff in pairs(step.Buffs) do
                APR.Buff:AddBuffIcon(buff)
            end
        else
            APR.Buff:RemoveAllBuffIcon()
        end
        if step.BuyMerchant then
            APR:Debug("APR.UpdateStep:BuyMerchant" .. APRData[APR.PlayerID][APR.ActiveRoute])

            local flagged = 0

            for _, item in ipairs(step.BuyMerchant) do
                if (C_QuestLog.IsQuestFlaggedCompleted(item.questID)) then
                    flagged = flagged + 1
                end
                local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(item.itemID)
                local name = itemName or UNKNOWN
                APR.currentStep:AddExtraLineText("BUY_ITEM_" .. name,
                    format(L["BUY_ITEM"], item.quantity, name))
            end
            if flagged == #step.BuyMerchant then
                APR:NextQuestStep()
                return
            end
        end
        if step.LearnProfession then
            APR:Debug("APR.UpdateStep:LearnProfession" .. APRData[APR.PlayerID][APR.ActiveRoute])

            local spellID = step.LearnProfession
            local IsSpellKnown = C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown or IsSpellKnown

            if IsSpellKnown(spellID) then
                APR:NextQuestStep()
                return
            end
            local name = C_Spell.GetSpellInfo(spellID).name
            APR.currentStep:AddExtraLineText("LEARN_PROFESSION", format(L["LEARN_PROFESSION_DETAILS"], name))
        end

        if step.LootItem then
            APR:Debug("APR.UpdateStep:Loot Item" .. APRData[APR.PlayerID][APR.ActiveRoute])

            local itemID = step.LootItem

            if tContains(APRItemLooted[APR.PlayerID], itemID) then
                APR:NextQuestStep()
                return
            end
            local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemID)
            local name = itemName or UNKNOWN
            APR.currentStep:AddExtraLineText("LOOT_ITEM", format(L["LOOT_ITEM"], name))
        end

        if (step.LeaveQuest) then
            APR:LeaveQuest(step.LeaveQuest)
        end
        if (step.LeaveQuests) then
            for _, questID in pairs(step.LeaveQuests) do
                APR:LeaveQuest(questID)
            end
        end
        if (step.VehicleExit) then
            VehicleExit()
        end

        if (step.GroupTask and APRData[APR.PlayerID].WantedQuestList[step.GroupTask] and APRData[APR.PlayerID].WantedQuestList[step.GroupTask] == 0) then
            APR:UpdateNextStep()
            return
        end
        if (step.ETA and not step.UseFlightPath and not step.SpecialETAHide) then
            if (APR.AFK.lastStep ~= CurStep) then
                APR.AFK:SetAfkTimer(step.ETA)
                APR.AFK.lastStep = CurStep
            end
        end
        if (step.SpecialETAHide) then
            APR.AFK:HideFrame()
        end
        if (step.UseGlider and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("USE_ITEM_GLIDER", L["USE_ITEM"] .. ": " .. APR:UseGlider())
        end
        if (step.Bloodlust and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("BLOODLUST", L["BLOODLUST"])
        end
        if (step.InVehicle and not UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("MOUNT_HORSE_SCARE_SPIDER", L["MOUNT_HORSE_SCARE_SPIDER"])
        elseif (step.InVehicle and step.InVehicle == 2 and UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("SCARE_SPIDER_INTO_LUMBERMILL", L["SCARE_SPIDER_INTO_LUMBERMILL"])
        end

        -- Qpart (objectives)
        if (step.Qpart) then
            APR:Debug("Qpart step detected")
            local questIDs = step.Qpart
            local questToHighlight = nil

            if (step.QpartDB) then
                APR:Debug("QpartDB detected")
                local wantedQuestId = 0
                for index = 1, getn(step.QpartDB) do
                    local qPartDBQuestId = step.QpartDB[index]
                    APR:Debug("QpartDB index: " .. index .. ", questID: " .. tostring(qPartDBQuestId))
                    if (C_QuestLog.IsQuestFlaggedCompleted(qPartDBQuestId) or APR.ActiveQuests[qPartDBQuestId]) then
                        wantedQuestId = qPartDBQuestId
                        APR:Debug("QpartDB wantedQuestId set: " .. tostring(wantedQuestId))
                        break
                    end
                end
                local newList = questIDs[1]
                questIDs = {}
                questIDs[wantedQuestId] = newList
                APR:Debug("QpartDB questIDs updated: " .. tostring(wantedQuestId))
            end

            local flagged = 0
            local total = 0
            for questID, objectives in pairs(questIDs) do
                questID = tonumber(questID)
                APR:Debug("Processing Qpart questID: " .. tostring(questID))
                local questData = APR.ActiveQuests[questID]
                for _, objectiveIndex in pairs(objectives) do
                    objectiveIndex = tonumber(objectiveIndex)
                    total = total + 1
                    APR:Debug("Qpart objectiveIndex: " .. tostring(objectiveIndex))

                    if C_QuestLog.IsQuestFlaggedCompleted(questID)
                        or ((UnitLevel("player") == APR.MaxLevel) and APR:Contains(APR.BonusObj, questID))
                        or APRData[APR.PlayerID].BonusSkips[questID]
                    then
                        flagged = flagged + 1
                        APR:Debug("Qpart flagged: " ..
                            tostring(flagged) .. "/" .. tostring(total) .. " for questID: " .. tostring(questID))
                    elseif questData and questData.objectives and questData.objectives[objectiveIndex]
                        and questData.objectives[objectiveIndex].status == APR.QUEST_STATUS.COMPLETE
                    then
                        flagged = flagged + 1
                        APR:Debug("Qpart objective complete: " ..
                            tostring(objectiveIndex) .. " for questID: " .. tostring(questID))
                    elseif questData and questData.objectives and questData.objectives[objectiveIndex] then
                        if APR.IsInRouteZone then
                            local obj = questData.objectives[objectiveIndex]
                            local checkpbar = C_QuestLog.GetQuestObjectives(questID)
                            local text = obj.text
                            APR:Debug("Qpart adding quest step: " ..
                                tostring(questID) .. " obj: " .. tostring(objectiveIndex) .. " text: " .. tostring(text))
                            if not string.find(text, "(.*)(%d+)(.*)") and checkpbar
                                and checkpbar[objectiveIndex]
                                and checkpbar[objectiveIndex].type == "progressbar"
                            then
                                APR.currentStep:AddQuestSteps(questID,
                                    "(" .. GetQuestProgressBarPercent(questID) .. "%) " .. text, objectiveIndex)
                            else
                                APR.currentStep:AddQuestSteps(questID, text, objectiveIndex)
                            end
                        end
                        questToHighlight = questToHighlight or questID
                    elseif not questData then
                        if APR.IsInRouteZone then
                            APR:Debug("Qpart missing quest: " ..
                                tostring(questID) .. " obj: " .. tostring(objectiveIndex))
                            APR:HandleMissingQuest(questID, objectiveIndex)
                        end
                    end
                end
            end
            APR:Debug("Qpart flagged/total: " .. tostring(flagged) .. "/" .. tostring(total))
            if flagged == total and (flagged > 0 or total == 0) then
                APR:Debug("Qpart all flagged, updating next step")
                APR:UpdateNextStep()
                return
            end

            if questToHighlight then
                APR:Debug("Qpart tracking quest: " .. tostring(questToHighlight))
                APR:TrackQuest(questToHighlight)
            end
        elseif (step.ExitTutorial) then
            if C_QuestLog.IsOnQuest(step.ExitTutorial) then
                APR:NextQuestStep()
                return
            end
        elseif (step.PickUp) then
            local questIDs = step.PickUp
            local pickUpDB = step.PickUpDB
            APR:Debug("APR.UpdateStep:PickUp:" .. APRData[APR.PlayerID][APR.ActiveRoute])

            if pickUpDB then
                local hasQuestCompleted = false
                local myQuestID = nil

                for _, questID in ipairs(pickUpDB) do
                    local questData = APR.ActiveQuests[questID]
                    local questName = C_QuestLog.GetTitleForQuestID(questID)
                    if questName then
                        myQuestID = questID
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                        hasQuestCompleted = true
                        break
                    end
                end
                if hasQuestCompleted then
                    APR:NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddQuestStepsWithDetails("PickUp", L["PICK_UP_Q"], { myQuestID })
                end
            else
                local completedCount = 0
                local uncompletedIDs = {}
                for _, questID in ipairs(questIDs) do
                    local questData = APR.ActiveQuests[questID]
                    if not (questData or C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                        tinsert(uncompletedIDs, questID)
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                        completedCount = completedCount + 1
                    end
                end
                if #questIDs == completedCount then
                    APR:Debug("APR.UpdateStep:PickUp:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                    APR:NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddQuestStepsWithDetails("PickUp", L["PICK_UP_Q"], uncompletedIDs)
                end
            end
        elseif (step.Waypoint) then
            if (APR.settings.profile.autoSkipAllWaypoints) then
                APR:NextQuestStep()
            elseif (APR.settings.profile.autoSkipWaypointsFly and IsFlyableArea() and not IsIndoors() and APR:CheckFlySkill()) then
                APR:NextQuestStep()
            else
                if step.WaypointDB then
                    local questIDs = step.WaypointDB
                    for _, questID in ipairs(questIDs) do
                        if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                            APR:NextQuestStep()
                            return
                        end
                    end
                end
                local questID = step.Waypoint
                if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                    APR:Debug("APR.UpdateStep:Waypoint:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])

                    APR:NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddExtraLineText("Waypoint" .. questID, APR:CheckWaypointText())
                end
            end
        elseif (step.Treasure) then
            local questID = step.Treasure
            if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                APR:Debug("APR.UpdateStep:Treasure:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])

                APR:NextQuestStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(questID, L["GET_TREASURE"], "Treasure")
            end
        elseif (step.DropQuest) then
            local questID = step.DropQuest
            local questData = APR.ActiveQuests[questID]
            if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                APR:Debug("APR.UpdateStep:DropQuest:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                APR:NextQuestStep()
                return
            end
        elseif (step.Done) then
            local doneList = step.Done
            local doneDBList = step.DoneDB
            local questToHighlight = nil

            if doneDBList then
                local hasQuestCompleted = false
                local myQuestID = nil

                APR:Debug("APR.UpdateStep:Done:" .. APRData[APR.PlayerID][APR.ActiveRoute])

                for _, questID in ipairs(doneDBList) do
                    local questData = APR.ActiveQuests[questID]
                    local questName = C_QuestLog.GetTitleForQuestID(questID)
                    if questName then
                        myQuestID = questID
                    elseif not questData and not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        if APR.IsInRouteZone then
                            APR:HandleMissingQuest(questID)
                        end
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                        hasQuestCompleted = true
                        break
                    end
                end
                if hasQuestCompleted then
                    APR:NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddQuestStepsWithDetails("Done", L["TURN_IN_Q"], { myQuestID })
                    questToHighlight = myQuestID
                end
            else
                local completedCount = 0
                local uncompletedIDs = {}
                for _, questID in ipairs(doneList) do
                    local questData = APR.ActiveQuests[questID]
                    if questData then
                        tinsert(uncompletedIDs, questID)
                        questToHighlight = questToHighlight or questID
                    elseif not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        if APR.IsInRouteZone then
                            APR:HandleMissingQuest(questID)
                        end
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        completedCount = completedCount + 1
                    end
                end

                if #doneList == completedCount then
                    APR:UpdateNextStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddQuestStepsWithDetails("Done", L["TURN_IN_Q"], uncompletedIDs)
                end
            end
            if questToHighlight then
                APR:TrackQuest(questToHighlight)
            end
        elseif (step.WarMode) then
            if C_QuestLog.IsQuestFlaggedCompleted(step.WarMode) or C_PvP.IsWarModeActive() then
                APR:Debug("APR.UpdateStep:WarMode:" .. APRData[APR.PlayerID][APR.ActiveRoute])

                APR:UpdateNextStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(step.WarMode, L["TURN_ON_WARMODE"], "WarMode")
                if not C_PvP.IsWarModeActive() and C_PvP.CanToggleWarModeInArea() then
                    C_PvP.ToggleWarMode()
                    APR:UpdateStep()
                end
            end
        elseif step.UseHS or step.UseDalaHS or step.UseGarrisonHS then
            local questKey, questText, useHSKey
            if step.UseHS then
                questKey = step.UseHS
                questText = L["USE_HEARTHSTONE"]
                useHSKey = "UseHS"
            elseif step.UseDalaHS then
                questKey = step.UseDalaHS
                questText = L["USE_DALARAN_HEARTHSTONE"]
                useHSKey = "UseDalaHS"
            else
                questKey = step.UseGarrisonHS
                questText = L["USE_GARRISON_HEARTHSTONE"]
                useHSKey = "UseGarrisonHS"
            end

            if APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(questKey, questText, useHSKey)
            end

            if C_QuestLog.IsQuestFlaggedCompleted(questKey) then
                APR:UpdateNextStep()
                return
            end
        elseif (step.SetHS) then
            if APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(step.SetHS, L["SET_HEARTHSTONE"], "SetHS")
            end
            if (C_QuestLog.IsQuestFlaggedCompleted(step.SetHS)) then
                APR:UpdateNextStep()
                return
            end
        elseif (step.GetFP) then
            if APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(step.GetFP, L["GET_FLIGHTPATH"], "GetFP")
            end
            if APR:HasTaxiNode(step.GetFP) then
                APR:UpdateNextStep()
                return
            end
        elseif (step.UseFlightPath) then
            if APR.IsInRouteZone then
                local questText = (step.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]) ..
                    ": " .. (APR:GetTaxiNodeName(step))
                APR.currentStep:AddQuestSteps(step.UseFlightPath, questText, "UseFlightPath")
            end
            if C_QuestLog.IsQuestFlaggedCompleted(step.UseFlightPath) then
                APR:UpdateNextStep()
                return
            end
        elseif (step.Group) then
            if (C_QuestLog.IsQuestFlaggedCompleted(step.Group.QuestId)) then
                APR:UpdateNextStep()
                return
            else
                GroupQuestPopup()
            end
        elseif step.QpartPart then
            local questIDs = step.QpartPart
            local questToHighlight = nil

            for questID, objectives in pairs(questIDs) do
                questID = tonumber(questID)
                local questData = APR.ActiveQuests[questID]
                for _, objectiveIndex in ipairs(objectives) do
                    objectiveIndex = tonumber(objectiveIndex)
                    local questText, questStatus
                    if questData and questData.objectives and questData.objectives[objectiveIndex] then
                        questText = questData.objectives[objectiveIndex].text
                        questStatus = questData.objectives[objectiveIndex].status
                    end
                    if questStatus == APR.QUEST_STATUS.COMPLETE or C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        APR:UpdateNextStep()
                        return
                    end

                    if APR.IsInRouteZone then
                        if questText then
                            APR.currentStep:AddQuestSteps(questID, questText, objectiveIndex)
                        else
                            APR:HandleMissingQuest(questID, objectiveIndex)
                        end
                        questToHighlight = questToHighlight or questID
                    end
                    APR:UpdateQpartPartWithQuesText(step, questText)
                end
            end

            if questToHighlight then
                APR:TrackQuest(questToHighlight)
            end
        elseif (step.GossipOptionIDs or step.GossipOptionID) and step.NPCIDs then
            APR.currentStep:AddExtraLineText("TALK_NPC-" .. next(step.NPCIDs), L["TALK_NPC"])
        end

        if step.Scenario then
            local scenario = step.Scenario
            local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
            if not scenarioInfo then
                if APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], scenario.stepID, scenario.criteriaID, scenario.criteriaIndex) then
                    APR:UpdateNextStep()
                else
                    local scenarioStepInfo = C_ScenarioInfo.GetScenarioStepInfo(scenario.stepID)
                    APR.currentStep:AddExtraLineText("SCENARIO-" .. scenario.criteriaID,
                        format(L["SCENARIO_ERROR"], scenarioStepInfo.title))
                end
            else
                if APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], scenario.stepID, scenario.criteriaID, scenario.criteriaIndex) then
                    APR:UpdateNextStep()
                    return
                end

                local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario.criteriaIndex)
                if criteriaInfo.completed then
                    APR:UpdateNextStep()
                    return
                else
                    APR.currentStep:AddQuestSteps(scenario.scenarioID, criteriaInfo.description, scenario.criteriaID,
                        true)
                end
            end
        end

        if step.DroppableQuest then
            local questData = step.DroppableQuest
            local Qid = questData.Qid

            if not C_QuestLog.IsQuestFlaggedCompleted(Qid) and not APR.ActiveQuests[Qid] then
                if APR.IsInRouteZone then
                    local MobId = questData.MobId
                    local MobName = APRData.NPCList[MobId] or questData.Text
                    local questText = format(L["Q_DROP"], MobName)

                    APR.currentStep:AddQuestSteps(Qid, questText, "DroppableQuest")
                end
            end
        end

        if step.Fillers then
            local questIDs = step.Fillers
            for questId, objectives in pairs(questIDs) do
                questId = tonumber(questId)
                local questData = APR.ActiveQuests[questId]
                for _, objectiveId in pairs(objectives) do
                    objectiveId = tonumber(objectiveId)
                    if C_QuestLog.IsQuestFlaggedCompleted(questId) == false and not APRData[APR.PlayerID].BonusSkips[questId] then
                        local objective
                        if questData and questData.objectives and questData.objectives[objectiveId]
                            and questData.objectives[objectiveId].status ~= APR.QUEST_STATUS.COMPLETE
                            and APR.IsInRouteZone
                        then
                            objective = questData.objectives[objectiveId]
                            local checkpbar = C_QuestLog.GetQuestObjectives(questId)
                            local questText = objective.text
                            if not string.find(questText, "(.*)(%d+)(.*)") and checkpbar and checkpbar[objectiveId] and checkpbar[objectiveId].type == "progressbar" then
                                questText = "(" .. GetQuestProgressBarPercent(questId) .. "%) " .. questText
                            end
                            APR.currentStep:AddQuestSteps(questId, questText, objectiveId)
                        end
                    end
                end
            end
        end
        if step.Grind then
            if APR.Level < step.Grind then
                APR.currentStep:AddExtraLineText("GRIND", L["GRIND"] .. " " .. step.Grind)
            else
                APR:UpdateNextStep()
                return
            end
        end
        if step.ResetRoute then
            APR.questionDialog:CreateQuestionPopup("RESET" .. "?", function()
                APRData[APR.PlayerID][APR.ActiveRoute] = 1
                APR:PrintInfo("|cff00bfffAPR|r Route Reseted")
                APR:UpdateQuestAndStep()
            end)
        end
        if (step.RouteCompleted) then
            local index, currentRouteName = next(APRCustomPath[APR.PlayerID])

            -- Force reset heirloom to show heirloom taximap (not avalaible in exile reach)
            if currentRouteName == "01-10 Exile's Reach" then
                APR.settings.profile.heirloomWarning = false
                APR.heirloom:RefreshFrameAnchor()
            end
            APRZoneCompleted[APR.PlayerID][currentRouteName] = true
            tremove(APRCustomPath[APR.PlayerID], index)
            APR.routeconfig:CheckIsCustomPathEmpty()
            APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            C_Timer.After(1, function() APR.routeconfig:SendMessage("APR_Custom_Path_Update") end) -- double send to try to avoid blank frame
            return
        end

        -- Set Quest Item Button
        APR:SetButton()
        APR.questOrderList:DelayedUpdate()
        -- set Progress bar with the right total
        APR.currentStep:SetProgressBar(CurStep)

        -- update for group
        APR.party:SendGroupMessage()
        APR.party:RefreshPartyFrameAnchor()
    else
        APR:Debug("APR.UpdateStep:No step found for current step:", CurStep)
        APR.routeconfig:CheckIsCustomPathEmpty()
    end
end

function APR:SetButton()
    if not APR.IsInRouteZone then
        return
    end
    APR:Debug("Function: APR:SetButton()")


    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if not step then
        return
    end

    if step.UseHS then
        APR.currentStep:AddStepButton(step.UseHS .. "-" .. "UseHS", APR.hearthStoneItemId)
    elseif step.UseGarrisonHS then
        APR.currentStep:AddStepButton(step.UseGarrisonHS .. "-" .. "UseGarrisonHS", APR.garrisonHSItemID)
    elseif step.Button then
        for questKey, itemID in pairs(step.Button) do
            local questID = select(1, APR:SplitQuestAndObjective(questKey))
            if not C_QuestLog.ReadyForTurnIn(questID) then
                APR.currentStep:AddStepButton(questKey, itemID, 'item')
            end
        end
    elseif step.SpellButton then
        for questKey, spellID in pairs(step.SpellButton) do
            local questID = select(1, APR:SplitQuestAndObjective(questKey))
            if not C_QuestLog.ReadyForTurnIn(questID) then
                APR.currentStep:AddStepButton(questKey, spellID, 'spell')
            end
        end
    end

    -- After doing some count to the current step, it updates the current step. So we need to sync the current cooldown
    APR.currentStep:UpdateStepButtonCooldowns()
end

function APR:UpdateQuest()
    APR:Debug("Function: APR_UpdateQuest()")

    local updateStep = false

    local numQuestLogEntries = C_QuestLog.GetNumQuestLogEntries()
    for questIndex = 1, numQuestLogEntries do
        local questInfo = C_QuestLog.GetInfo(questIndex)

        if questInfo and questInfo.questID > 0 and not questInfo.isHeader then
            local questID = questInfo.questID
            local questTitle = C_QuestLog.GetTitleForQuestID(questID)
            local isQuestComplete = C_QuestLog.IsComplete(questID)
            local numObjectives = C_QuestLog.GetNumQuestObjectives(questID)
            local questStatus = isQuestComplete and APR.QUEST_STATUS.COMPLETE or APR.QUEST_STATUS.PROGRESS

            APR.ActiveQuests[questID] = APR.ActiveQuests[questID] or {
                status = questStatus,
                title = questTitle,
                objectives = {},
            }

            if APR.ActiveQuests[questID].status ~= questStatus then
                APR:Debug(("Quest [%s] status updated: %s"):format(questTitle, questStatus))
                updateStep = true
            end
            -- Update quest status if it has changed
            APR.ActiveQuests[questID].status = questStatus

            -- Handle objectives
            local questObjectives = (numObjectives > 0) and C_QuestLog.GetQuestObjectives(questID) or nil
            if not questObjectives then
                -- Quest without objectives
                APR.ActiveQuests[questID].objectives[1] = {
                    text = questTitle,
                    status = questStatus,
                }
            else
                for i, objectiveInfo in ipairs(questObjectives) do
                    local status = objectiveInfo.finished and APR.QUEST_STATUS.COMPLETE or APR.QUEST_STATUS.PROGRESS
                    local text = objectiveInfo.text or ""

                    -- Progress bar
                    if select(2, GetQuestObjectiveInfo(questID, i, false)) == "progressbar" and text then
                        if not APR.ProgressbarIgnore[questID .. "-" .. i] then
                            local percent = math.floor(tonumber(GetQuestProgressBarPercent(questID)) + 0.5)
                            text = ("(%d%%) %s"):format(percent, text)
                        end
                    end

                    -- Update only if changed
                    local objEntry = APR.ActiveQuests[questID].objectives[i]
                    if not objEntry or objEntry.text ~= text or objEntry.status ~= status then
                        APR:Debug(("Objective [%s] - Step %d: %s (%s)"):format(
                            questTitle, i, text, status))
                    end

                    APR.ActiveQuests[questID].objectives[i] = {
                        text = text,
                        status = status,
                    }

                    if status == APR.QUEST_STATUS.COMPLETE then
                        updateStep = true
                    end

                    APR.currentStep:UpdateQuestStep(questID, text, i)
                end
            end
        end
    end
    APR:UpdateQpartPart()
    if updateStep then
        APR:UpdateStep()
    else
        -- update for group if not a new step
        APR.party:SendGroupMessage(true)
        APR.party:RefreshPartyFrameAnchor()
    end
end

function APR:RemoveQuest(questID)
    if not questID then return end

    APR.ActiveQuests[questID] = nil

    local questIDs, StepP = APR:GetQuestAndStepIds()
    if StepP == "Done" then
        local nrLeft = 0
        for _, id in pairs(questIDs) do
            if not C_QuestLog.IsQuestFlaggedCompleted(id) and questID ~= id then
                nrLeft = nrLeft + 1
            end
        end
        if nrLeft == 0 then
            self:UpdateQuest()
            self:Debug("APR - RemoveQuest", APRData[APR.PlayerID][APR.ActiveRoute])
        end
    end

    self:UpdateMapId()
    self:UpdateStep()
end

function APR:PopupAutocompleteQuest()
    if (GetNumAutoQuestPopUps() > 0) then
        local questID, popUpType = GetAutoQuestPopUp(1)
        if (popUpType == "OFFER") then
            ShowQuestOffer(1)
            ShowQuestOffer(questID)
        elseif (popUpType == "COMPLETE") then
            ShowQuestOffer(1)
            ShowQuestComplete(questID)
        end
    else
        C_Timer.After(1, function() APR:PopupAutocompleteQuest() end)
    end
end
