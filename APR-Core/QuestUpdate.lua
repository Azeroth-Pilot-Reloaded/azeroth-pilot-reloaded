local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:UpdateQuest()
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
        APR:UpdateStep()
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
            local containerItemID = C_Container.GetContainerItemID(bag, slot) or 0
            if (containerItemID == 109076) then
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

function APR:QuestStepIds()
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

function APR:RemoveQuest(questID)
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

    local questIDs, StepP = APR:QuestStepIds()
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

    APR:UpdateMapId()
    APR:UpdateStep()
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

function APR:UpdQuestThing()
    APR:UpdateQuest()
    APR.Updateblock = 0
    if (APR.settings.profile.debug) then
        print("Extra UpdQuestThing")
    end
end

