local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local ETAStep = 0
local Updateblock = 0
local APRGOSSIPCOUNT = 0

local function APR_LeaveQuest(QuestIDs)
    C_QuestLog.SetSelectedQuest(QuestIDs)
    C_QuestLog.AbandonQuest()
end

local function APR_QAskPopWanted()
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

local function SkipStepCondition(step)
    -- Skip steps if not Faction or Race or Class or Achievement
    if (
            (step.Faction and step.Faction ~= APR.Faction) or
            (step.Race and step.Race ~= APR.Race) or
            (step.Gender and step.Gender ~= APR.Gender) or
            (step.Class and step.Class ~= APR.ClassName) or
            (step.HasAchievement and not APR:HasAchievement(step.HasAchievement)) or
            (step.DontHaveAchievement and APR:HasAchievement(step.DontHaveAchievement)) or
            (step.HasAura and not APR:HasAura(step.HasAura)) or
            (step.DontHaveAura and APR:HasAura(step.DontHaveAura))
        ) then
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
        if APR.InCombat then
            APR.BookUpdAfterCombat = true
        end
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

        if (SkipStepCondition(step)) then
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
            local message = rawget(L, key) or rawget(AprRCData.ExtraLineTexts, key)
            if message then
                APR.currentStep:AddExtraLineText(i .. "_" .. key, message)
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
            APR_LeaveQuest(step.LeaveQuest)
        end
        if (step.LeaveQuests) then
            for _, questID in pairs(step.LeaveQuests) do
                APR_LeaveQuest(questID)
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
            if (ETAStep ~= CurStep) then
                APR.AFK:SetAfkTimer(step.ETA)
                ETAStep = CurStep
            end
        end
        if (step.SpecialETAHide) then
            APR.AFK:HideFrame()
        end
        if (step.UseGlider and APR.IsInRouteZone) then
            APR.currentStep:AddExtraLineText("USE_ITEM_GLIDER", L["USE_ITEM"] .. ": " .. APR.GliderFunc())
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
                local newList = {}
                for _, questID in pairs(questIDs) do
                    newList = questID
                    break
                end
                questIDs = nil
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
                    APR.currentStep:AddExtraLineText("Waypoint" .. questID, APR.CheckWaypointText())
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
                    APR.BookingList["UpdateStep"] = true
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
                APR_QAskPopWanted()
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
        if (step.ZoneDoneSave) then
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
        APR.SetButton()
        APR.questOrderList:DelayedUpdate()
        -- set Progress bar with the right total
        APR.currentStep:SetProgressBar(CurStep)
    else
        APR.routeconfig:CheckIsCustomPathEmpty()
    end
end

function APR.SetButton()
    if InCombatLockdown() or not APR.IsInRouteZone then
        return
    end
    if (APR.settings.profile.debug) then
        print("Function: APR.SetButton()")
    end

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

function APR.CheckWaypointText()
    local CurStep = APRData[APR.PlayerID][APR.ActiveRoute]
    local waypoints = {
        FlightPath = L["GET_FLIGHTPATH"],
        UseFlightPath = L["USE_FLIGHTPATH"],
        Boat = L["USE_BOAT"],
        PickUp = L["ACCEPT_Q"],
        Done = L["TURN_IN_Q"],
        Qpart = L["COMPLETE_Q"],
        SetHS = L["SET_HEARTHSTONE"],
        QpartPart = L["COMPLETE_Q"]
    }

    for i = CurStep, #APR.RouteQuestStepList[APR.ActiveRoute] do
        local step = APR.RouteQuestStepList[APR.ActiveRoute][i]
        if step then
            for waypoint, _ in pairs(waypoints) do
                if step[waypoint] then
                    return "[" .. L["WAYPOINT"] .. "] - " .. waypoints[waypoint]
                end
            end
        end
    end

    return L["TRAVEL_TO"] .. " - " .. L["WAYPOINT"]
end

local function APR_UpdateQuest()
    if APR.settings.profile.debug then
        print("Function: APR_UpdateQuest()")
    end

    local updateStep = false
    for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
        local questInfo = C_QuestLog.GetInfo(questIndex)
        if questInfo then
            local questID = questInfo.questID
            if questID > 0 and not questInfo.isHeader then
                local questTitle = C_QuestLog.GetTitleForQuestID(questID)
                local isQuestComplete = C_QuestLog.IsComplete(questID)
                local numQuestObjectives = C_QuestLog.GetNumQuestObjectives(questID)
                local objectiveText = ""
                local currentObjectiveIndex = 1

                if not APR.ActiveQuests[questID] then
                    if APR.settings.profile.debug then
                        print("New Q:" .. questID)
                    end
                end

                APR.ActiveQuests[questID] = isQuestComplete and "C" or "P"

                if numQuestObjectives == 0 then
                    local objectiveKey = questID .. "-1"
                    APR.ActiveQuests[objectiveKey] = isQuestComplete and "C" or questTitle
                else
                    local questObjectives = C_QuestLog.GetQuestObjectives(questID)
                    for objectiveIndex, objectiveInfo in ipairs(questObjectives) do
                        local isObjectiveComplete = objectiveInfo.finished
                        objectiveText = objectiveInfo.text
                        currentObjectiveIndex = objectiveIndex
                        local objectiveKey = questID .. "-" .. objectiveIndex

                        if isObjectiveComplete then
                            if APR.ActiveQuests[objectiveKey] and APR.ActiveQuests[objectiveKey] ~= "C" then
                                if APR.settings.profile.debug then
                                    print("Update: C")
                                end
                            end
                            APR.ActiveQuests[objectiveKey] = "C"
                            updateStep = true
                        else
                            if select(2, GetQuestObjectiveInfo(questID, objectiveIndex, false)) == "progressbar" and objectiveText then
                                if not APR.ProgressbarIgnore[objectiveKey] then
                                    local progressPercent = math.floor(tonumber(GetQuestProgressBarPercent(questID)) +
                                        0.5)
                                    objectiveText = "(" .. progressPercent .. "%) " .. objectiveText
                                end
                            end

                            if APR.ActiveQuests[objectiveKey] and APR.ActiveQuests[objectiveKey] ~= objectiveText then
                                if APR.settings.profile.debug then
                                    print("Update: " .. objectiveText)
                                end
                            end
                            APR.ActiveQuests[objectiveKey] = objectiveText
                            APR.currentStep:UpdateQuestStep(questID, objectiveText, currentObjectiveIndex)
                        end
                    end
                end
            end
        end
    end

    APR:UpdateQpartPart()

    if updateStep then
        APR.BookingList["UpdateStep"] = true
    end
end

function APR.GliderFunc()
    if (APR.settings.profile.debug) then
        print("Function: APR.GliderFunc()")
    end

    if APRData.GliderName then
        return APRData.GliderName
    end

    local itemName = L["GOBLIN_GLIDER"]
    local DerpGot = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if (itemID and itemID == 109076) then
                DerpGot = 1
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(
                    itemLink)
                itemName = itemEquipLoc
                break
            end
        end
        if DerpGot == 1 then
            APRData.GliderName = itemName
            return itemName
        end
    end

    return itemName
end

local function APR_QuestStepIds()
    if not APR.RouteQuestStepList[APR.ActiveRoute] then
        return
    end

    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if not step then return end
    if step.PickUp then
        return step.PickUp, "PickUp"
    elseif step.Qpart then
        return step.Qpart, "Qpart"
    elseif step.Done then
        return step.Done, "Done"
    end
end

local function APR_RemoveQuest(questID)
    if not questID then
        return
    end
    APR.ActiveQuests[questID] = nil

    for stepIndex, _ in pairs(APR.ActiveQuests) do
        local questId, _ = string.match(stepIndex, "(%d+)-(%d+)")
        if questId and tonumber(questId) == questID then
            APR.ActiveQuests[stepIndex] = nil
        end
    end

    local questIDs, StepP = APR_QuestStepIds()
    if StepP == "Done" then
        local NrLeft = 0
        for _, questId in pairs(questIDs) do
            if not C_QuestLog.IsQuestFlaggedCompleted(questId) and questID ~= questId then
                NrLeft = NrLeft + 1
            end
        end
        if NrLeft == 0 then
            APR:UpdateNextQuest()
            if APR.settings.profile.debug then
                print("APR.RemoveQuest:Plus" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
        end
    end

    APR.BookingList["UpdateMapId"] = true
    APR.BookingList["UpdateStep"] = true
end

local function APR_AddQuest(questID)
    APR.ActiveQuests[questID] = "P"
    local questIDs, StepP = APR_QuestStepIds()
    if StepP == "PickUp" then
        local NrLeft = 0
        for _, questId in pairs(questIDs) do
            if (not APR.ActiveQuests[questId]) then
                NrLeft = NrLeft + 1
            end
        end
        if (NrLeft == 0) then
            APR:UpdateNextQuest()
            if (APR.settings.profile.debug) then
                print("APR.AddQuest:Plus" .. APRData[APR.PlayerID][APR.ActiveRoute])
            end
        end
    end
    APR.BookingList["UpdateStep"] = true
end

local function APR_UpdateMapId()
    if (APR.settings.profile.debug) then
        print("Function: APR_UpdateMapId()")
    end
    APR:OverrideRouteData() -- Lumbermill Wod route
    APR.BookingList["GetMeToRightZone"] = true
end

local function APR_LoopBookingFunc() -- Main loop
    if not APR.settings.profile.enableAddon then
        return
    end
    -- Actions list
    local bookingActions = {
        GetMeToRightZone = function() APR.transport:GetMeToRightZone() end,
        UpdateMapId = function() APR_UpdateMapId() end,
        AddQuest = function() APR_AddQuest(APR.BookingList["AddQuest"]) end,
        RemoveQuest = function() APR_RemoveQuest(APR.BookingList["RemoveQuest"]) end,
        UpdateQuest = function() APR_UpdateQuest() end,
        UpdateStep = function() APR:UpdateStep() end,
        SetArrowCoord = function() APR.Arrow:SetCoord() end
    }

    for action, func in pairs(bookingActions) do
        if APR.BookingList[action] then
            if APR.settings.profile.debug then
                print("LoopBookingFunc:" .. action .. ":" .. (APRData[APR.PlayerID][APR.ActiveRoute] or ""))
            end
            APR.BookingList[action] = nil
            func()
        end
    end

    if APR.Arrow.UpdateFreq >= APR.settings.profile.arrowFPS then
        APR.Arrow:CalculPosition()
        APR.Arrow.UpdateFreq = 0
    else
        APR.Arrow.UpdateFreq = APR.Arrow.UpdateFreq + 1
    end
end

local function APR_PopupFunc()
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
        C_Timer.After(1, APR_PopupFunc)
    end
end

local function DoEmoteStep(step)
    if step and step.Emote then
        local npc_id = APR:GetTargetID() or APR:GetTargetID("mouseover")
        if npc_id == 153580 then
            DoEmote(step.Emote)
        end
    end
end

function APR_UpdQuestThing()
    APR.BookingList["UpdateQuest"] = true
    Updateblock = 0
    if (APR.settings.profile.debug) then
        print("Extra UpdQuestThing")
    end
end

APR.LoopBooking = CreateFrame("frame")
APR.LoopBooking:SetScript("OnUpdate", APR_LoopBookingFunc)

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent("ADVENTURE_MAP_OPEN")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_LOOT")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
APR_QH_EventFrame:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
APR_QH_EventFrame:RegisterEvent("GOSSIP_CLOSED")
APR_QH_EventFrame:RegisterEvent("GOSSIP_SHOW")
APR_QH_EventFrame:RegisterEvent("GROUP_JOINED")
APR_QH_EventFrame:RegisterEvent("GROUP_LEFT")
APR_QH_EventFrame:RegisterEvent("HEARTHSTONE_BOUND")
APR_QH_EventFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
APR_QH_EventFrame:RegisterEvent("MERCHANT_SHOW")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_CLOSE")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
APR_QH_EventFrame:RegisterEvent("PLAYER_CHOICE_UPDATE")
APR_QH_EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
APR_QH_EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
APR_QH_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPTED")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
APR_QH_EventFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_COMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_DETAIL")
APR_QH_EventFrame:RegisterEvent("QUEST_GREETING")
APR_QH_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR_QH_EventFrame:RegisterEvent("QUEST_PROGRESS")
APR_QH_EventFrame:RegisterEvent("QUEST_REMOVED")
APR_QH_EventFrame:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE")
APR_QH_EventFrame:RegisterEvent("SCENARIO_COMPLETED")
APR_QH_EventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
APR_QH_EventFrame:RegisterEvent("TAXIMAP_OPENED")
APR_QH_EventFrame:RegisterEvent("UI_INFO_MESSAGE")
APR_QH_EventFrame:RegisterEvent("UNIT_AURA")
APR_QH_EventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
APR_QH_EventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
APR_QH_EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
APR_QH_EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
APR_QH_EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR:IsInstanceWithUI() then
        if APR.settings.profile.debug then
            print("APR: EventFrame - IsInstanceWithUI : ", APR:IsInstanceWithUI())
        end
        APR.settings:ToggleAddon()
        return
    end

    if APR.settings.profile.showEvent then
        print("EVENT: QuestHandler - ", event)
    end

    if not APR.settings.profile.enableAddon then
        return
    end
    local autoAccept = APR.settings.profile.autoAccept
    local autoAcceptRoute = APR.settings.profile.autoAcceptQuestRoute
    local step = APR:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)

    if event == "ADVENTURE_MAP_OPEN" then
        if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
        if not APR:IsPickupStep() then
            C_AdventureMap.Close();
            print("APR: " .. L["NOT_YET"])
            return
        end
        C_Timer.After(0.3, function()
            local numChoices = C_AdventureMap.GetNumZoneChoices()
            for choiceIndex = 1, numChoices do
                local questID, textureKit, name, zoneDescription, normalizedX, normalizedY = C_AdventureMap
                    .GetZoneChoiceInfo(choiceIndex);
                if AdventureMap_IsQuestValid(questID, normalizedX, normalizedY) then
                    if step and (APR:Contains(step.PickUp, questID) or APR:Contains(step.PickUpDB, questID)) then
                        C_AdventureMap.StartQuest(questID)
                    end
                end
            end
        end)
    end

    if (event == "CHAT_MSG_COMBAT_XP_GAIN") then
        if (step and step.Treasure) then
            C_Timer.After(0.2, function() APR:UpdateQuestAndStep() end)
        end
    end

    if (event == "CHAT_MSG_LOOT") then
        if step and step.BuyMerchant and not step.Qpart then
            local message = ...
            local itemLink = string.match(message, "|Hitem:.-|h.-|h")
            local quantity = APR:GetQuantityfromLootMessage(message)
            if itemLink then
                local itemID, _, _, _, _, _, _ = C_Item.GetItemInfoInstant(itemLink)
                APR:UpdatePurchaseTracking(itemID, quantity)
            end
        end
    end

    if (event == "CHAT_MSG_MONSTER_SAY") then
        local text = ...;
        local npc_id, name = APR:GetTargetID(), UnitName("target")
        if npc_id and name then
            if npc_id == 159477 then -- quest 57870
                local gigglingBasket = {
                    ["GIGGLING_BASKET_ONE_TIME"] = "cheer",
                    ["GIGGLING_BASKET_SPRIGGANS"] = "flex",
                    ["GIGGLING_BASKET_MANY"] = "thank",
                    ["GIGGLING_BASKET_FAE"] = "introduce",
                    ["GIGGLING_BASKET_FEET"] = "dance",
                    ["GIGGLING_BASKET_HELP"] = "praise",
                }
                for key, emote in pairs(gigglingBasket) do
                    local message = L[key]
                    if string.find(text, message) then
                        if APR.settings.profile.debug then
                            print("APR: " .. L["DOING_EMOTE"] .. ": " .. emote)
                        end
                        DoEmote(emote)
                        break
                    end
                end
            end
        end
    end

    if event == "ENCOUNTER_LOOT_RECEIVED" then
        local encounterID, itemID, itemLink, quantity, playerName, classFileName = ...
        do
            if step and step.LootItem then
                local stepItemID = step.LootItem
                if stepItemID == itemID then
                    tinsert(APRItemLooted[APR.PlayerID], itemID)
                    APR:UpdateNextStep()
                end
            end
        end
    end

    if (event == "GOSSIP_CLOSED") then
        APRGOSSIPCOUNT = 0
    end

    if event == "GROUP_JOINED" then
        APR.party:SendGroupMessage()
    end

    if event == "GROUP_LEFT" then
        -- remove all the teammate then resend name + step to the group
        -- because wow don't send the username of the leaver
        APR.party:RemoveTeam()
        APR.party:SendGroupMessage()
        APR.party:RefreshPartyFrameAnchor()
    end

    if (event == "HEARTHSTONE_BOUND") then
        if (step and step.SetHS) then
            APR:UpdateNextStep()
        end
    end

    if (event == "LEARNED_SPELL_IN_SKILL_LINE") then
        local spellID, skillLineIndex = ...
        if step and step.LearnProfession then
            if spellID == step.LearnProfession then
                APR:UpdateNextStep()
            end
        end
    end

    if (event == "MERCHANT_SHOW") then
        if IsModifierKeyDown() then return end
        if (step and step.BuyMerchant) then
            APR:StartPurchaseTracking(step.BuyMerchant)
            APR:BuyMerchFunc(step.BuyMerchant)
        end
        if (APR.settings.profile.autoRepair) then
            if (CanMerchantRepair()) then
                local repairAllCost, canRepair = GetRepairAllCost();
                if (canRepair and repairAllCost > 0) then
                    local guildRepairedItems = false
                    if (IsInGuild() and CanGuildBankRepair()) then
                        local amount = GetGuildBankWithdrawMoney()
                        local guildBankMoney = GetGuildBankMoney()
                        amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                        if (amount >= repairAllCost) then
                            RepairAllItems(true);
                            guildRepairedItems = true
                            DEFAULT_CHAT_FRAME:AddMessage("APR: Equipment has been repaired by your Guild")
                        end
                    end
                    if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                        RepairAllItems(false);
                        print("APR: " ..
                            L["REPAIR_EQUIPEMENT"] .. " " .. C_CurrencyInfo.GetCoinTextureString(repairAllCost))
                    end
                end
            end
        end
        if (APR.settings.profile.autoVendor) then
            local APRtotal = 0
            for myBags = 0, 4 do
                for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
                    local CurrentItemId = C_Container.GetContainerItemID(myBags, bagSlots)
                    if CurrentItemId then
                        local itemQuality = C_Item.GetItemQualityByID(CurrentItemId)
                        local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(CurrentItemId)
                        local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                        if itemQuality == 0 and sellPrice > 0 and itemInfo.stackCount > 0 then
                            APRtotal = APRtotal + (sellPrice * itemInfo.stackCount)
                            C_Container.UseContainerItem(myBags, bagSlots)
                        end
                    end
                end
            end
            if APRtotal ~= 0 then
                print("APR:" .. L["ITEM_SOLD"] .. " " .. C_CurrencyInfo.GetCoinTextureString(APRtotal))
            end
        end
    end

    if event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then
        APR.currentStep:RefreshCurrentStepFrameAnchor()
        APR.party:RefreshPartyFrameAnchor()
        APR.questOrderList:RefreshFrameAnchor()
        APR.heirloom:RefreshFrameAnchor()
        APR.RouteSelection:RefreshFrameAnchor()
        APR.Buff:RefreshFrameAnchor()
    end

    if (event == "PLAYER_CHOICE_UPDATE") then
        local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
        if (choiceInfo and step) then
            if (step.Brewery or step.SparringRing) then
                for i, option in ipairs(choiceInfo.options) do
                    if (step.Brewery == option.id or step.SparringRing == option.id) then
                        C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
                        APR:NextQuestStep()
                        break
                    end
                end
            end
        end
    end

    if (event == "PLAYER_REGEN_DISABLED") then
        APR.InCombat = true
    end

    if (event == "PLAYER_REGEN_ENABLED") then
        APR.InCombat = false
        if (APR.BookUpdAfterCombat) then
            APR.BookingList["UpdateStep"] = true
        end
    end

    if (event == "PLAYER_TARGET_CHANGED") then
        DoEmoteStep(step)
    end

    if (event == "QUEST_ACCEPTED") then
        local questID = ...;
        if APR.settings.profile.firstAutoShareQuestWithFriend and IsInGroup() then
            APR.questionDialog:CreateQuestionPopup(L["SHOW_GROUP_SHAREWITHFRIEND_FIRSTTIME"], function()
                APR.settings.profile.autoShareQuestWithFriend = true
                if APR.party:CheckIfPartyMemberIsFriend() then
                    C_QuestLog.SetSelectedQuest(questID)
                    QuestLogPushQuest();
                end
            end)
            APR.settings.profile.firstAutoShareQuestWithFriend = false
        end
        if APR.settings.profile.autoShareQuestWithFriend then
            if APR.party:CheckIfPartyMemberIsFriend() then
                C_QuestLog.SetSelectedQuest(questID)
                QuestLogPushQuest();
            end
        end
        if (APR.settings.profile.debug) then
            print(L["Q_ACCEPTED"] .. ": " .. questID)
        end
        C_Timer.After(0.2, APR_UpdateMapId)
    end

    if (event == "QUEST_ACCEPT_CONFIRM") then -- escort quest
        if IsModifierKeyDown() then return end
        if (autoAccept or autoAcceptRoute) then
            C_Timer.After(0.2, APR_AcceptQuest)
        end
    end

    if (event == "QUEST_AUTOCOMPLETE") then
        if IsModifierKeyDown() then return end
        if (APR.settings.profile.autoHandIn) then
            APR_PopupFunc()
        end
    end

    if (event == "QUEST_COMPLETE") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)

        local function getItemEquipLoc(itemEquipLoc)
            local weaponsAndShields = {
                "INVTYPE_WEAPONOFFHAND",
                "INVTYPE_WEAPONMAINHAND",
                "INVTYPE_WEAPON",
                "INVTYPE_SHIELD",
                "INVTYPE_2HWEAPON",
                "INVTYPE_HOLDABLE",
                "INVTYPE_RANGED",
                "INVTYPE_THROWN",
                "INVTYPE_RANGEDRIGHT",
                "INVTYPE_RELIC"
            }
            return APR:Contains(weaponsAndShields, itemEquipLoc) and "INVTYPE_WEAPON" or itemEquipLoc
        end

        local function getPlayerGearIlvlList()
            local gearIlvlList = {}
            for playerSlot = 0, 18 do
                local inventoryItemLink = GetInventoryItemLink("player", playerSlot)
                if inventoryItemLink then
                    local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(inventoryItemLink)
                    if itemQuality == 7 then --Heirloom
                        itemLevel = C_Item.GetDetailedItemLevelInfo(inventoryItemLink)
                    end
                    if itemEquipLoc and itemLevel then
                        itemEquipLoc = getItemEquipLoc(itemEquipLoc)
                        gearIlvlList[itemEquipLoc] = math.min(gearIlvlList[itemEquipLoc] or itemLevel, itemLevel)
                    end
                end
            end
            return gearIlvlList
        end

        local function getQuestRewardIlvlDifference(gearIlvlList)
            local gearIlvlListDiff = {}
            local isCosmetic = false
            for i = 1, GetNumQuestChoices() do
                local questItemLink = GetQuestItemLink("choice", i)
                if questItemLink then
                    local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(
                        questItemLink)

                    -- check if quest reward is classID 4 (armor) and subClassID 5 (cosmetic), then we dont want to pick anything
                    if classID == 4 and subclassID == 5 then
                        isCosmetic = true
                    end
                    local itemLevel = C_Item.GetDetailedItemLevelInfo(questItemLink)
                    itemEquipLoc = getItemEquipLoc(itemEquipLoc)
                    if gearIlvlList[itemEquipLoc] then
                        gearIlvlListDiff[i] = itemLevel - gearIlvlList[itemEquipLoc]
                    end
                end
            end
            return gearIlvlListDiff, isCosmetic
        end

        local function chooseQuestReward()
            local gearIlvlList = getPlayerGearIlvlList()
            local gearIlvlListDiff, isCosmetic = getQuestRewardIlvlDifference(gearIlvlList)

            local highestIlvlDiff = -99999
            local choiceIndex = 0
            for index, ilvlDiff in pairs(gearIlvlListDiff) do
                if ilvlDiff > highestIlvlDiff then
                    choiceIndex = index
                    highestIlvlDiff = ilvlDiff
                end
            end

            if choiceIndex > 0 and not isCosmetic then
                GetQuestReward(choiceIndex)
            end
        end

        if APR.settings.profile.autoHandIn then
            if GetNumQuestChoices() > 1 then
                if APR.settings.profile.autoHandInChoice then
                    chooseQuestReward()
                end
            else
                local npc_id = APR:GetTargetID()
                if not (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 45400) or (npc_id == 25809) or (npc_id == 87391))) then
                    GetQuestReward(1)
                end
            end
        end
    end

    if (event == "QUEST_DETAIL") then -- Fired when the player is given a more detailed view of his quest.
        if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
        local function handleQuestDetail()
            local questID = GetQuestID()
            if questID then
                if QuestGetAutoAccept() then
                    C_Timer.After(0.2, APR_CloseQuest)
                elseif (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                    C_Timer.After(0.2, APR_AcceptQuest)
                elseif APR:IsPickupStep() then
                    C_Timer.After(0.2, APR_CloseQuest)
                    print("APR: " .. L["NOT_YET"])
                else
                    -- Retry
                    C_Timer.After(0.2, handleQuestDetail)
                end
                return
            end
            C_Timer.After(0.2, handleQuestDetail)
        end
        handleQuestDetail()
    end

    if (event == "QUEST_GREETING" or event == "GOSSIP_SHOW") then
        -- Exit function if you press Ctrl/shift/alt key before the
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        local npc_id = APR:GetTargetID()
        if (npc_id and (npc_id == 43733) and (npc_id == 45312)) then
            Dismount()
        end
        if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 25809) or (npc_id == 45400) or (npc_id == 87391))) then
            return
        end
        if step and APR.settings.profile.autoGossip then
            local function PickGossipByIcon(iconId)
                local gossipOption = C_GossipInfo.GetOptions()
                if next(gossipOption) then
                    for _, gossip in pairs(gossipOption) do
                        if gossip.icon == iconId then
                            C_GossipInfo.SelectOption(gossip.gossipOptionID)
                        end
                    end
                end
            end
            ------------------------------------
            -- SetHS
            if step.SetHS then
                PickGossipByIcon(136458)
            end
            ------------------------------------
            -- FlightPath
            if (step.UseFlightPath or step.GetFP) and not step.NoAutoFlightMap and not (step.GossipOptionID or step.GossipOptionIDs) then
                PickGossipByIcon(132057)
            end
            -- BuyMerchant
            if step.BuyMerchant and not (step.GossipOptionID or step.GossipOptionIDs) then
                PickGossipByIcon(132060)
            end
            ------------------------------------
            -- GOSSIP
            if step.Gossip or step.GossipOptionID or step.GossipOptionIDs then
                if (step.Gossip == 28202) then -- GOSSIP HARDCODED
                    APRGOSSIPCOUNT = APRGOSSIPCOUNT + 1
                    if (APRGOSSIPCOUNT == 1) then
                        C_GossipInfo.SelectOptionByIndex(1)
                    elseif (APRGOSSIPCOUNT == 2) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        end
                    elseif (APRGOSSIPCOUNT == 3) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        end
                    elseif (APRGOSSIPCOUNT == 4) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        end
                    elseif (APRGOSSIPCOUNT == 5) then
                        APR:UpdateNextStep()
                    end
                else
                    local info = C_GossipInfo.GetOptions()
                    if next(info) then
                        if step.GossipOptionID then
                            C_GossipInfo.SelectOption(step.GossipOptionID)
                        elseif step.GossipOptionIDs then
                            for _, g in pairs(step.GossipOptionIDs) do
                                C_GossipInfo.SelectOption(g)
                            end
                        else
                            for _, v in pairs(info) do
                                if (v.orderIndex + 1 == step.Gossip) then
                                    C_GossipInfo.SelectOption(v.gossipOptionID)
                                end
                            end
                        end
                    end
                    --CHROMIE
                    if (step.ChromiePick) then
                        local target = APR:GetTargetID()
                        if (target == 167032) then
                            local extraText = L["SWITCH_TO_CHROMIE"] ..
                                " " .. C_ChromieTime.GetChromieTimeExpansionOption(step.ChromiePick).name
                            APR.currentStep:AddExtraLineText('ChromiePick', extraText)
                            C_Timer.After(1,
                                function() C_ChromieTime.SelectChromieTimeOption(step.ChromiePick) end)
                        end
                    end
                end
            end
        end
        --PICKUP / HANDIN
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- Handin
        if (APR.settings.profile.autoHandIn) then
            if (event == "QUEST_GREETING") then
                for i = 1, GetNumActiveQuests() do
                    local title, isComplete = GetActiveTitle(i)
                    if title and isComplete then
                        return SelectActiveQuest(i)
                    end
                end
            elseif activeQuests then
                for titleIndex, questInfo in ipairs(activeQuests) do
                    if questInfo.title and questInfo.isComplete then
                        if questInfo.questID then
                            return C_GossipInfo.SelectActiveQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
        -- Pickup
        if autoAcceptRoute or autoAccept then
            local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
            if (event == "QUEST_GREETING") then
                local numAvailableQuests = GetNumAvailableQuests()
                for i = 1, numAvailableQuests do
                    local _, _, _, _, questID = GetAvailableQuestInfo(i)
                    if (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                        return SelectAvailableQuest(i)
                    elseif (i == numAvailableQuests and APR:IsPickupStep()) then
                        C_Timer.After(0.2, APR_CloseQuest)
                    end
                end
            elseif availableQuests then
                for titleIndex, questInfo in ipairs(availableQuests) do
                    if questInfo.questID then
                        if (autoAcceptRoute and APR:IsARouteQuest(questInfo.questID)) or autoAccept then
                            return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
    end

    if (event == "QUEST_LOG_UPDATE") then
        C_Timer.After(0.2, APR_UpdQuestThing)
    end

    if (event == "QUEST_PROGRESS") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        if (APR.settings.profile.autoHandIn) then
            CompleteQuest()
        end
    end

    if (event == "QUEST_REMOVED") then
        if (APR.settings.profile.debug) then
            print(L["Q_REMOVED"])
        end
        local questID = ...;
        APR.BookingList["RemoveQuest"] = questID
        if (APR.ActiveRoute == questID) then
            APR.BookingList["UpdateMapId"] = true
            APRData[APR.PlayerID][questID] = nil
            APR.map:RemoveMapLine()
        end
        APRData[APR.PlayerID].QuestCounter2 = APRData[APR.PlayerID].QuestCounter2 + 1
    end

    if (event == "REQUEST_CEMETERY_LIST_RESPONSE") then
        APR.BookingList["UpdateMapId"] = true
        APR.Arrow.currentStep = 0
        APR.BookingList["SetArrowCoord"] = true
    end
    if event == "SCENARIO_COMPLETED" then
        local currentMapID = C_Map.GetBestMapForUnit('player')
        tinsert(APRScenarioMapIDCompleted[APR.PlayerID], currentMapID)
        if step and step.DoScenario then
            if step.DoScenario == currentMapID then
                APR:UpdateNextStep()
            end
        end
    end

    if event == "SCENARIO_CRITERIA_UPDATE" then
        local criteriaID = ...
        if step and step.Scenario then
            local isCompleted = false
            local scenario = step.Scenario
            local stepInfo = C_ScenarioInfo.GetScenarioStepInfo()
            if not stepInfo then return end
            for i = 1, stepInfo.numCriteria do
                local criteria = C_ScenarioInfo.GetCriteriaInfoByStep(stepInfo.stepID, i)
                if criteria.criteriaID == criteriaID then
                    if criteria.completed then
                        APRScenarioCompleted[APR.PlayerID][scenario.scenarioID] = APRScenarioCompleted[APR.PlayerID]
                            [scenario.scenarioID] or {}
                        if not APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], stepInfo.stepID, criteriaID, i) then
                            tinsert(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID],
                                { stepID = stepInfo.stepID, criteriaID = criteriaID, criteriaIndex = i })
                            isCompleted = true
                        end
                    end
                end
            end
            if isCompleted then
                APR.BookingList["UpdateStep"] = true
            end
        end
    end

    if (event == "TAXIMAP_OPENED") then
        if IsModifierKeyDown() then return end
        if (step and step.GetFP) then
            APR:UpdateNextStep()
            CloseTaxiMap() -- auto Close the taxi map after getting the FP
        end
    end

    if (event == "UI_INFO_MESSAGE") then
        local errorType, msg = ...;
        if step and step.GetFP and (msg == _G.ERR_NEWTAXIPATH or msg == _G.ERR_TAXINOPATHS) then
            APR:UpdateNextStep()
        end
    end

    if (event == "UNIT_AURA") then
        if step and step.Button then
            APR.currentStep:UpdateStepButtonCooldowns()
        end
    end

    if (event == "UNIT_ENTERED_VEHICLE") then
        local unitTarget = ...;
        if (unitTarget == "player") then
            if (step and step.InVehicle) then
                APR.BookingList["UpdateStep"] = true
            end
        end
        if (step and step.MountVehicle) then
            APR:NextQuestStep()
        end
    end

    if (event == "UNIT_QUEST_LOG_CHANGED") then
        local unitTarget = ...;
        if (unitTarget == "player" and Updateblock == 0) then
            Updateblock = 1
            C_Timer.After(1, APR_UpdQuestThing)
        end
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...

        if (unitTarget == "player") and step then
            if (step.UseGarrisonHS and spellID == APR.garrisonHSSpellID) then
                APR:UpdateNextStep()
                return
            end
            if (step.UseDalaHS and spellID == APR.dalaHSSpellID) then
                APR:UpdateNextStep()
                return
            end
            if (APR:Contains(APR.hearthStoneSpellID, spellID) and step.UseHS) or (step.SpellTrigger and spellID == step.SpellTrigger) then
                APR:UpdateNextStep()
            end
        end
    end

    if (event == "UPDATE_MOUSEOVER_UNIT") then
        if (step and step.RaidIcon) then
            local targetGUID = UnitGUID("mouseover")
            if (targetGUID) then
                local targetID = select(6, strsplit("-", targetGUID))
                if (targetID and tonumber(step.RaidIcon) == tonumber(targetID)) then
                    if (not GetRaidTargetIndex("mouseover")) then
                        SetRaidTarget("mouseover", 8)
                    end
                end
            end
        elseif (step and step.DroppableQuest) then
            if (UnitGUID("mouseover") and UnitName("mouseover")) then
                local targetGUID, targetName = UnitGUID("mouseover"), UnitName("mouseover")
                local targetID = select(6, strsplit("-", targetGUID))
                if (targetID and step.DroppableQuest.MobId == tonumber(targetID)) then
                    APRData.NPCList[targetID] = targetName
                end
            end
        end

        DoEmoteStep(step)
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        if step and step.LeaveScenario then
            local scenarioMapID = step.LeaveScenario
            local mapID = C_Map.GetBestMapForUnit('player')
            local isCompleted = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)
            if scenarioMapID ~= mapID and isCompleted then
                APR:UpdateNextStep()
            end
        end
    end
end)
