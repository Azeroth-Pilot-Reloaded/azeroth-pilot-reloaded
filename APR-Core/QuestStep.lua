local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.ETAStep = APR.ETAStep or 0
APR.Updateblock = APR.Updateblock or 0
APR.GossipCount = APR.GossipCount or 0

function APR:LeaveQuest(QuestIDs)
    C_QuestLog.SetSelectedQuest(QuestIDs)
    C_QuestLog.AbandonQuest()
end

function APR:QAskPopWanted()
    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])

    local Qid = step.Group.QuestId
    if not C_QuestLog.IsQuestFlaggedCompleted(Qid) and not step.QuestLineSkip then
        local SugGroupNr = step.Group.Number
        local dialogText = L["OPTIONAL"] .. " - " .. L["SUGGESTED_PLAYERS"] .. ": " .. SugGroupNr

        APR.questionDialog:CreateQuestionPopup(
            dialogText,
            function()
                APRData[APR.PlayerID].WantedQuestList[Qid] = 1
                APR:UpdateNextStep()
            end,
            function()
                APRData[APR.PlayerID].WantedQuestList[Qid] = 0
                APR:UpdateNextStep()
            end
        )
    else
        APR:UpdateNextStep()
    end
end

function APR:SkipStepCondition(step)
    -- Skip steps if not Faction or Race or Class or Achievement
    if APR:StepFilterQuestHandler(step) then
        -- Counter for skipper step in the current route
        APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] = (APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-SkippedStep'] or 0) + 1
        APR:UpdateNextStep()
        return true
    end
    return false
end

function APR:UpdateStep()
    if not APR.settings.profile.enableAddon then
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR:UpdateStep()")
    end
    if (APR.ActiveRoute and not APRData[APR.PlayerID][APR.ActiveRoute]) then
        APRData[APR.PlayerID][APR.ActiveRoute] = 1
    end

    -- //TODO Return if not in the right zone (check why no data on zone change with the return)
    if APR.IsInRouteZone then
        APR.currentStep:Reset()
    end

    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    -- Extra liners here
    local MissingQs = {}

    -- update for group
    APR.party:SendGroupMessage()
    APR.party:RefreshPartyFrameAnchor()

    if (APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute] and APR.RouteQuestStepList[APR.ActiveRoute][CurStep]) then
        local step = APR.RouteQuestStepList[APR.ActiveRoute][CurStep]

        APR.currentStep:ButtonEnable()
        APR:SendMessage("APR_MAP_UPDATE")
        APR.AFK:HideFrame()

        if (self:SkipStepCondition(step)) then
            return
        end

        -- set the arrow coord before the step logic to avoid double completion
        APR.Arrow:SetCoord()

        if (APR.ActiveRoute) then
            local function checkChromieTimeline(id)
                if APR.Level >= APR.MaxLevelChromie then
                    return
                end
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
        -- //TODO REWORK LOA
        if (step.PickedLoa and step.PickedLoa == 2 and (APR.ActiveQuests[47440] or C_QuestLog.IsQuestFlaggedCompleted(47440))) then
            APR:UpdateNextStep()
            if (APR.settings.profile.debug) then
                print("PickedLoa Skip 2 step:" .. CurStep)
            end
            return
        elseif (step.PickedLoa and step.PickedLoa == 1 and (APR.ActiveQuests[47439] or C_QuestLog.IsQuestFlaggedCompleted(47439))) then
            APR:UpdateNextStep()
            if (APR.settings.profile.debug) then
                print("PickedLoa Skip 1 step:" .. CurStep)
            end
            return
        end

        local function handleScenarioStep(stepType, scenarioMapID)
            if APR.settings.profile.debug then
                print(stepType .. " Step:" .. CurStep)
            end

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
                local questID = next(step.Qpart)
                if (APR.ActiveQuests[questID] and APR.ActiveQuests[questID] == "C") and isCompleted then
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
            if (APR.settings.profile.debug) then
                print("APR.UpdateStep:BuyMerchant" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
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
            if APR.settings.profile.debug then
                print("APR.UpdateStep:LearnProfession" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
            local spellID = step.LearnProfession
            if IsSpellKnown(spellID) then
                APR:NextQuestStep()
                return
            end
            local name = C_Spell.GetSpellInfo(spellID).name
            APR.currentStep:AddExtraLineText("LEARN_PROFESSION", format(L["LEARN_PROFESSION_DETAILS"], name))
        end

        if step.LootItem then
            if APR.settings.profile.debug then
                print("APR.UpdateStep:Loot Item" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
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
            self:LeaveQuest(step.LeaveQuest)
        end
        if (step.LeaveQuests) then
            for _, questID in pairs(step.LeaveQuests) do
                self:LeaveQuest(questID)
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
            if (APR.ETAStep ~= CurStep) then
                APR.AFK:SetAfkTimer(step.ETA)
                APR.ETAStep = CurStep
            end
        end
        if (step.SpecialETAHide) then
            APR.AFK:HideFrame()
        end
        if (step.UseGlider and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("USE_ITEM_GLIDER", L["USE_ITEM"] .. ": " .. self:GliderFunc())
        end
        if (step.Bloodlust and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("BLOODLUST", L["BLOODLUST"])
        end
        if (step.InVehicle and not UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("MOUNT_HORSE_SCARE_SPIDER", L["MOUNT_HORSE_SCARE_SPIDER"])
        elseif (step.InVehicle and step.InVehicle == 2 and UnitInVehicle("player") and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("SCARE_SPIDER_INTO_LUMBERMILL", L["SCARE_SPIDER_INTO_LUMBERMILL"])
        end
        if (step.Qpart) then
            local questIDs = step.Qpart
            local questToHighlight = nil

            if (step.QpartDB) then
                local wantedQuestId = 0
                for index = 1, getn(step.QpartDB) do
                    local qPartDBQuestId = step.QpartDB[index]
                    if (C_QuestLog.IsQuestFlaggedCompleted(qPartDBQuestId) or APR.ActiveQuests[qPartDBQuestId]) then
                        wantedQuestId = qPartDBQuestId
                        break
                    end
                end
                local newList = questIDs[1]
                questIDs = {}
                questIDs[wantedQuestId] = newList
            end

            local Flagged = 0
            local Total = 0
            for questID, objectives in pairs(questIDs) do
                for _, objectiveIndex in pairs(objectives) do
                    Total = Total + 1
                    local qid = questID .. "-" .. objectiveIndex
                    if (C_QuestLog.IsQuestFlaggedCompleted(questID) or ((UnitLevel("player") == APR.MaxLevel) and APR:Contains(APR.BonusObj, questID)) or APRData[APR.PlayerID].BonusSkips[questID]) then
                        Flagged = Flagged + 1
                    elseif (APR.ActiveQuests[qid] and APR.ActiveQuests[qid] == "C") then
                        Flagged = Flagged + 1
                    elseif (APR.ActiveQuests[qid]) then
                        if (APR.IsInRouteZone) then
                            local checkpbar = C_QuestLog.GetQuestObjectives(questID)
                            if (not string.find(APR.ActiveQuests[qid], "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(objectiveIndex)] and checkpbar[tonumber(objectiveIndex)].type and checkpbar[tonumber(objectiveIndex)].type == "progressbar") then
                                APR.currentStep:AddQuestSteps(questID,
                                    "(" .. GetQuestProgressBarPercent(questID) .. "%) " .. APR.ActiveQuests[qid],
                                    objectiveIndex)
                            else
                                APR.currentStep:AddQuestSteps(questID, APR.ActiveQuests[qid], objectiveIndex)
                            end
                        end

                        questToHighlight = questToHighlight or questID
                    elseif (not APR.ActiveQuests[questID] and not MissingQs[questID]) then
                        if (APR.IsInRouteZone) then
                            APR:MissingQuest(questID, objectiveIndex)
                            MissingQs[questID] = 1
                        end
                    end
                end
            end
            if (Flagged == Total and Flagged > 0) then
                APR:UpdateNextStep()
                return
            end

            if questToHighlight then
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
            if APR.settings.profile.debug then
                print("APR.UpdateStep:PickUp:" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end

            if pickUpDB then
                local hasQuestCompleted = false
                local myQuestID = nil

                for _, questID in ipairs(pickUpDB) do
                    local questName = C_QuestLog.GetTitleForQuestID(questID)
                    if questName then
                        myQuestID = questID
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
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
                    if not (APR.ActiveQuests[questID] or C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                        tinsert(uncompletedIDs, questID)
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
                        completedCount = completedCount + 1
                    end
                end
                if #questIDs == completedCount then
                    if APR.settings.profile.debug then
                        print("APR.UpdateStep:PickUp:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                    end
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
                    if (APR.settings.profile.debug) then
                        print("APR.UpdateStep:Waypoint:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                    end
                    APR:NextQuestStep()
                    return
                elseif APR.IsInRouteZone then
                    APR.currentStep:AddExtraLineText("Waypoint" .. questID, self:CheckWaypointText())
                end
            end
        elseif (step.Treasure) then
            local questID = step.Treasure
            if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                if (APR.settings.profile.debug) then
                    print("APR.UpdateStep:Treasure:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
                APR:NextQuestStep()
                return
            elseif APR.IsInRouteZone then
                APR.currentStep:AddQuestSteps(questID, L["GET_TREASURE"], "Treasure")
            end
        elseif (step.DropQuest) then
            local questID = step.DropQuest
            if (C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID]) then
                if (APR.settings.profile.debug) then
                    print("APR.UpdateStep:DropQuest:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
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

                if APR.settings.profile.debug then
                    print("APR.UpdateStep:Done:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end

                for _, questID in ipairs(doneDBList) do
                    local questName = C_QuestLog.GetTitleForQuestID(questID)
                    if questName then
                        myQuestID = questID
                    end
                    if C_QuestLog.IsQuestFlaggedCompleted(questID) or APR.ActiveQuests[questID] then
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
                    if APR.ActiveQuests[questID] then
                        tinsert(uncompletedIDs, questID)
                        questToHighlight = questToHighlight or questID
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
                if APR.settings.profile.debug then
                    print("APR.UpdateStep:WarMode:" .. APRData[APR.PlayerID][APR.ActiveRoute])
                end
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
                self:QAskPopWanted()
            end
        elseif step.QpartPart then
            local questIDs = step.QpartPart
            local questToHighlight = nil

            for questID, objectives in pairs(questIDs) do
                for _, objectiveIndex in ipairs(objectives) do
                    local qid = questID .. "-" .. objectiveIndex
                    local questText = APR.ActiveQuests[qid]
                    if questText == "C" or C_QuestLog.IsQuestFlaggedCompleted(questID) then
                        APR:UpdateNextStep()
                        return
                    end

                    if APR.IsInRouteZone then
                        if questText then
                            APR.currentStep:AddQuestSteps(questID, questText, objectiveIndex)
                        elseif not MissingQs[questID] then
                            APR:MissingQuest(questID, objectiveIndex)
                            MissingQs[questID] = 1
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
                for _, objectiveId in pairs(objectives) do
                    local qid = questId .. "-" .. objectiveId
                    if C_QuestLog.IsQuestFlaggedCompleted(questId) == false and not APRData[APR.PlayerID].BonusSkips[questId] then
                        if APR.ActiveQuests[qid] and APR.ActiveQuests[qid] ~= "C" and APR.IsInRouteZone then
                            local checkpbar = C_QuestLog.GetQuestObjectives(questId)
                            local questText = APR.ActiveQuests[qid]
                            if not string.find(questText, "(.*)(%d+)(.*)") and checkpbar and checkpbar[tonumber(objectiveId)] and checkpbar[tonumber(objectiveId)].type and checkpbar[tonumber(objectiveId)].type == "progressbar" then
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
                print("|cff00bfffAPR|r Route Reseted")
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
        self:SetButton()
        APR.questOrderList:DelayedUpdate()
        -- set Progress bar with the right total
        APR.currentStep:SetProgressBar(CurStep)
    else
        APR.routeconfig:CheckIsCustomPathEmpty()
    end
end

