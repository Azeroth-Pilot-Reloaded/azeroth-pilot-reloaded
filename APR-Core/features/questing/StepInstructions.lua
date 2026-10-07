-- Renders route hints and action buttons, including legacy item-collection hints and optional group quests.

APR.stepHandlers = APR.stepHandlers or {}
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local handlers = APR.stepHandlers

function handlers.GroupQuestPopup()
    local step = APR:GetCurrentStep()

    if not step then return end

    local context = APR:CaptureStepContext()
    local questId = step.Group.questID
    if not C_QuestLog.IsQuestFlaggedCompleted(questId) and not step.QuestLineSkip then
        local sugestGroupNumber = step.Group.Number
        local dialogText = string.format(L["OPTIONAL_SUGGESTED_PLAYERS"], sugestGroupNumber)

        APR.questionDialog:CreateQuestionPopup(dialogText,
            dialogText,
            function()
                if not APR:IsStepContextCurrent(context) then return end
                APRData[APR.PlayerID].WantedQuestList[questId] = 1
                APR:UpdateNextStep()
            end,
            function()
                if not APR:IsStepContextCurrent(context) then return end
                APRData[APR.PlayerID].WantedQuestList[questId] = 0
                APR:UpdateNextStep()
            end
        )
    else
        APR:UpdateNextStep()
    end
end

-- This helper centralises the handling of ExtraLine quest hints so future special cases stay readable.
-- Returning true means the helper triggered a step transition and the caller should exit early.
function handlers.HandleExtraLine(extraline)
    -- Only process when there is an ExtraLine directive and the player is within the route's intended zone.
    if not extraline or not APR.IsInRouteZone then
        return false
    end

    -- Reusable closure to handle single-item collection requirements.
    local function handleSingleItemRequirement(questID, requirement)
        local itemCount = C_Item.GetItemCount(requirement.itemID)

        -- Keep the player informed about their progress on the required item.
        if itemCount < requirement.count then
            APR.currentStep:AddQuestSteps(
                questID,
                requirement.description .. " (" .. itemCount .. "/" .. requirement.count .. ")",
                requirement.itemID
            )
            return false
        end

        -- Progression should advance automatically when the requirement is met.
        APR:NextQuestStep()
        return true
    end

    -- Single item requirements are mapped here for clarity and to simplify future additions.
    local extraLineQuests = {
        [13544] = {
            itemID = 44886,
            description = L["KILL_FLEETFOOT"],
            count = 1,
        },
        [13595] = {
            itemID = 44967,
            description = L["LOOT_WILDFIRE_BOTTLE"],
            count = 1,
        },
        [25654] = {
            itemID = 9530,
            description = L["LOOT_HARPYS_HORN"],
            count = 1,
        },
    }

    -- Handle simple one-item routes first.
    if extraLineQuests[extraline] then
        return handleSingleItemRequirement(extraline, extraLineQuests[extraline])
    end

    -- Quest 14358 has multiple parallel requirements; keep them grouped for clarity.
    if extraline == 14358 then
        local requirements = {
            {
                itemID = 48106,
                description = L["LOOT_MELONFRUIT"],
                requiredCount = 8,
            },
            {
                itemID = 48857,
                description = L["KILL_SATYR_FLESH"],
                requiredCount = 10,
            },
            {
                itemID = 48943,
                description = L["LOOT_SATYR_SABER"],
                requiredCount = 20,
            },
        }

        local allRequirementsComplete = true

        -- Iterate over every needed item and record missing progress on the step frame.
        for _, requirement in ipairs(requirements) do
            local itemCount = C_Item.GetItemCount(requirement.itemID)

            if itemCount < requirement.requiredCount then
                APR.currentStep:AddQuestSteps(
                    extraline,
                    requirement.description .. " (" .. itemCount .. "/" .. requirement.requiredCount .. ")",
                    requirement.itemID
                )
                allRequirementsComplete = false
            end
        end

        -- When all three collections are complete, move to the following route entry immediately.
        if allRequirementsComplete then
            APR:NextQuestStep()
            return true
        end
    end

    -- No special ExtraLine handling triggered.
    return false
end

function APR:SetButton()
    if not (APR.IsInRouteZone or (APR.farstrider and APR.farstrider.showOutOfZoneStepContent)) then
        return
    end
    APR:Debug("Function: APR:SetButton()")


    local step = APR:GetCurrentStep()
    if not step then
        return
    end

    local occupied = {}
    for _, kind in ipairs({ "item", "spell" }) do
        local buttons = step[kind == "item" and "Button" or "SpellButton"]
        for questKey, value in pairs(buttons or {}) do
            local questID, objective = APR:SplitQuestAndObjective(questKey)
            if not (questID and objective and C_QuestLog.ReadyForTurnIn(questID)) then
                local actionIDs = type(value) == "table" and value or { value }
                for buttonIndex, actionID in ipairs(actionIDs) do
                    local key = questKey
                    local currentStep = APR.currentStep
                    local container = (currentStep.questsList or {})[key] or (currentStep.fillersList or {})[key]
                    if not container or occupied[key] then
                        -- Each additional action needs its own stable row and secure button.
                        local rowID = "ROUTE_BUTTON_" .. kind .. "_" .. tostring(questKey)
                        if buttonIndex > 1 then rowID = rowID .. "_" .. buttonIndex end
                        local info = kind == "spell" and C_Spell.GetSpellInfo(actionID) or nil
                        local name = kind == "item" and C_Item.GetItemInfo(actionID) or (info and info.name)
                        local label = string.format(L[kind == "item" and "USE_ITEM" or "USE_SPELL"], name or UNKNOWN)
                        currentStep:AddQuestSteps(rowID, label, "Action", false, true)
                        key = rowID .. "-Action"
                    end
                    occupied[key] = true
                    currentStep:AddStepButton(key, actionID, kind)
                end
            end
        end
    end

    -- After doing some count to the current step, it updates the current step. So we need to sync the current cooldown
    APR.currentStep:UpdateStepButtonCooldowns()
end

-- Shared secondary fields are evaluated before the primary route action.
function handlers.RenderRequirements(step, showStepDetails, currentStepIndex)
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
            if (item.questID and C_QuestLog.IsQuestFlaggedCompleted(item.questID)) then
                flagged = flagged + 1
            end
            local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(item.itemID)
            local name = itemName or UNKNOWN
            APR.currentStep:AddQuestSteps("BUY_ITEM_" .. name,
                format(L["BUY_ITEM"], item.quantity, name), name)
        end
        if flagged == #step.BuyMerchant then
            APR:NextQuestStep()
            return true
        end
    end
    if step.LearnProfession then
        APR:Debug("APR.UpdateStep:LearnProfession" .. APRData[APR.PlayerID][APR.ActiveRoute])

        local spellID = step.LearnProfession

        if APR:IsSpellKnown(spellID) then
            APR:NextQuestStep()
            return true
        end
        local name = APR:GetSpellName(spellID) or UNKNOWN
        APR.currentStep:AddQuestSteps("LEARN_PROFESSION", format(L["LEARN_PROFESSION_DETAILS"], name), name)
    end

    if step.LootItems then
        local completed = 0
        for _, item in ipairs(step.LootItems) do
            local required = math.max(item.quantity or 1, 1)
            local count = APR:GetCollectionItemCount(item.itemID)
            if count >= required or (item.questID and C_QuestLog.IsQuestFlaggedCompleted(item.questID)) then
                completed = completed + 1
            end
            local name = C_Item.GetItemInfo(item.itemID) or UNKNOWN
            local label = format(L["LOOT_ITEM"], name)
            if required > 1 then label = label .. " (" .. count .. "/" .. required .. ")" end
            APR.currentStep:AddQuestSteps(item.itemID, label, item.itemID)
        end
        if completed == #step.LootItems then
            APR:NextQuestStep(); return true
        end
    end

    if (step.VehicleExit) then
        VehicleExit()
    end

    if (step.GroupTask and APRData[APR.PlayerID].WantedQuestList[step.GroupTask] and APRData[APR.PlayerID].WantedQuestList[step.GroupTask] == 0) then
        APR:UpdateNextStep()
        return true
    end
    if (step.ETA and not step.UseFlightPath and not step.SpecialETAHide) then
        if (APR.AFK.lastStep ~= currentStepIndex) then
            APR.AFK:SetAfkTimer(step.ETA)
            APR.AFK.lastStep = currentStepIndex
        end
    end
    if (step.SpecialETAHide) then
        APR.AFK:HideFrame()
    end
    if (step.UseGlider and showStepDetails) then
        APR.currentStep:AddExtraLineText("USE_ITEM_GLIDER",
            string.format(L["USE_ITEM"], APR:UseGlider()))
    end
    if (step.Bloodlust and showStepDetails) then
        APR.currentStep:AddExtraLineText("BLOODLUST", L["BLOODLUST"])
    end
    if (step.InVehicle and not UnitInVehicle("player") and showStepDetails) then
        APR.currentStep:AddExtraLineText("MOUNT_HORSE_SCARE_SPIDER", L["MOUNT_HORSE_SCARE_SPIDER"])
    elseif (step.InVehicle and step.InVehicle == 2 and UnitInVehicle("player") and showStepDetails) then
        APR.currentStep:AddExtraLineText("SCARE_SPIDER_INTO_LUMBERMILL", L["SCARE_SPIDER_INTO_LUMBERMILL"])
    end

    if step.Fillers then
        local questIDs = step.Fillers
        for questId, objectives in pairs(questIDs) do
            questId = tonumber(questId)
            local questData = APR.ActiveQuests[questId]
            for _, objectiveId in pairs(objectives) do
                objectiveId = tonumber(objectiveId)
                if not C_QuestLog.IsQuestFlaggedCompleted(questId) and not APRData[APR.PlayerID].BonusSkips[questId] then
                    if questData and questData.objectives and questData.objectives[objectiveId]
                        and questData.objectives[objectiveId].status ~= APR.QUEST_STATUS.COMPLETE
                        and showStepDetails
                    then
                        local questText = APR:GetQuestTextForProgressBar(questId, objectiveId)
                        APR.fillersFrame:AddFillerStep(questId, questText, objectiveId)
                    end
                end
            end
        end
    end
end
