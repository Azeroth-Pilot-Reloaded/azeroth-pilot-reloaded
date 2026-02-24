local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.gossip = APR:NewModule("Gossip")

APR.gossip.counter = 0

local DARKMOON_GOSSIP = {
    [40007] = true, -- Darkmoon Faire Mystic Mage (Horde)
    [40457] = true, -- Darkmoon Faire Mystic Mage (Alliance)
}

local QUEST_GOSSIP = {
    -- usually only added if they're repeatable
    [109275] = true, -- Soridormi - begin time rift
    [120619] = true, -- Big Dig task
    [120620] = true, -- Big Dig task
    [120555] = true, -- Awakening The Machine
    [120733] = true, -- Theater Troupe

    -- Darkmoon Faire
    [40563] = true, -- whack
    [28701] = true, -- cannon
    [31202] = true, -- shoot
    [39245] = true, -- tonk
    [40224] = true, -- ring toss
    [43060] = true, -- firebird
    [52651] = true, -- dance
    [41759] = true, -- pet battle 1
    [42668] = true, -- pet battle 2
    [40872] = true, -- cannon return (Teleportologist Fozlebub)
}

local IGNORE_GOSSIP = {
    -- when we don't want to automate gossip because it's counter-intuitive
    [122442] = true, -- leave the dungeon in remix

    -- avoid accidental teleports
    [44733] = true,
    [125350] = true, -- siren isle
    [125351] = true, -- siren isle
    [131324] = true, -- winter veil hillsbrad
    [131325] = true, -- winter veil hillsbrad
}

-- To handle gossipOptionID
if C_GossipInfo and C_GossipInfo.SelectOption and hooksecurefunc then
    if not APR.gossip._hookedSelectOption then
        hooksecurefunc(C_GossipInfo, "SelectOption", function(optionID)
            if APR.ActiveRoute then
                local currentStepIndex = APRData[APR.PlayerID][APR.ActiveRoute]
                local step = APR:GetStep(currentStepIndex)
                if step and step.GossipOptionIDs and optionID and tContains(step.GossipOptionIDs, optionID) then
                    if not APR:HasAnyMainStepOption(step) then
                        APRGossipValidated[APR.PlayerID][optionID] = true
                        APR:Debug("Gossip selected option ID:", optionID)

                        --check if all completed
                        local isFullCompleted = APR:hasEveryGossipsCompleted(step.GossipOptionIDs)
                        if isFullCompleted then
                            APR:UpdateNextStep()
                        end
                    elseif step.GossipETA then
                        APR.gossip:TriggerGossipETA(currentStepIndex, step)
                    end
                end
            end
        end)
        APR.gossip._hookedSelectOption = true
    end
end

function APR.gossip:HandleGossip(step)
    local profile = APR:GetSettingsProfile()
    if not (profile and profile.autoGossip) then
        return
    end

    local selectedOption = false

    local function SelectOption(optionID, text, confirm)
        if not optionID then
            return false
        end
        selectedOption = true
        C_GossipInfo.SelectOption(optionID, text, confirm)
        return true
    end

    local function HandleQuickQuestGossipFallback()
        local gossip = C_GossipInfo.GetOptions()
        if not gossip or not next(gossip) then
            return false
        end

        local redOptions = {}
        local questOptions = {}

        -- Classify all options
        for _, info in next, gossip do
            if info.name and info.name:find("|cFFFF0000") then
                -- Red option (negation/denial) - search anywhere in text
                table.insert(redOptions, info.gossipOptionID)
            elseif DARKMOON_GOSSIP[info.gossipOptionID] then
                -- Only add Darkmoon if payment is enabled
                if profile.autoGossipPayDarkmoonFare then
                    table.insert(questOptions, info.gossipOptionID)
                end
            elseif QUEST_GOSSIP[info.gossipOptionID] then
                table.insert(questOptions, info.gossipOptionID)
            elseif FlagsUtil and FlagsUtil.IsSet and Enum and Enum.GossipOptionRecFlags and Enum.GossipOptionRecFlags.QuestLabelPrepend and FlagsUtil.IsSet(info.flags, Enum.GossipOptionRecFlags.QuestLabelPrepend) then
                table.insert(questOptions, info.gossipOptionID)
            end
        end

        -- Priority order:
        -- 2. Red option if override enabled
        if #redOptions > 0 and profile.autoGossipRedOption then
            return SelectOption(redOptions[1])
        end

        -- 3. If route quest option exists but no red override → do nothing (route takes priority)
        -- This is implicit: if APR had a route, it would have handled it already
        -- If autoGossipQuestOptions is true and we have quest options, we check below
        -- Otherwise we do nothing

        -- 4. If exactly one quest option → select it
        if profile.autoGossipQuestOptions then
            if #questOptions == 1 then
                return SelectOption(questOptions[1])
            end
            -- 5. If multiple quest options → do nothing
            if #questOptions > 1 then
                return false
            end
        end

        -- 6. If no quest/red options, check single misc option
        if (C_GossipInfo.GetNumActiveQuests() + C_GossipInfo.GetNumAvailableQuests()) > 0 then
            return false
        end

        if #gossip ~= 1 then
            return false
        end

        if not profile.autoGossipSingleOption then
            return false
        end

        if not gossip[1].gossipOptionID then
            return false
        end

        if IGNORE_GOSSIP[gossip[1].gossipOptionID] then
            return false
        end

        local _, instanceType = GetInstanceInfo()
        local singleOptionMode = profile.autoGossipSingleOptionWhen or 2
        if instanceType == "raid" then
            if singleOptionMode > 1 and (GetNumGroupMembers() <= 1 or singleOptionMode == 3) then
                return SelectOption(gossip[1].gossipOptionID)
            end
            return false
        end

        return SelectOption(gossip[1].gossipOptionID)
    end

    local function PickGossipByIcon(iconId)
        local gossipOption = C_GossipInfo.GetOptions()
        if next(gossipOption) then
            for _, gossip in pairs(gossipOption) do
                if gossip.icon == iconId then
                    if SelectOption(gossip.gossipOptionID) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local handledByAPR = false
    ------------------------------------
    -- SetHS
    if step and step.SetHS then
        handledByAPR = PickGossipByIcon(136458) or handledByAPR
    end
    ------------------------------------
    -- FlightPath
    if step and (step.UseFlightPath or step.GetFP) and not step.NoAutoFlightMap and not step.GossipOptionIDs then
        handledByAPR = PickGossipByIcon(132057) or handledByAPR
    end
    -- BuyMerchant
    if step and step.BuyMerchant and not step.GossipOptionIDs then
        handledByAPR = PickGossipByIcon(132060) or handledByAPR
    end
    ------------------------------------
    -- GOSSIP
    if step and (step.Gossip or step.GossipOptionIDs) then
        if (step.Gossip == 28202) then -- GOSSIP HARDCODED
            -- //TODO Remove this when all hardcoded gossip are removed
            -- This is a hardcoded gossip for the quest https://www.wowhead.com/quest=28205/a-perfect-costume
            self.counter = self:HandleHardcodedGossip()
            handledByAPR = true
        else
            local info = C_GossipInfo.GetOptions()
            if next(info) then
                if step.GossipOptionIDs then
                    for _, g in pairs(step.GossipOptionIDs) do
                        if SelectOption(g) then
                            handledByAPR = true
                        end
                    end
                else
                    for _, v in pairs(info) do
                        if (v.orderIndex + 1 == step.Gossip) then
                            if SelectOption(v.gossipOptionID) then
                                handledByAPR = true
                            end
                        end
                    end
                end
            end

            --CHROMIE
            if (step.ChromiePick) then
                local targetID = APR:GetTargetID()
                if (targetID == 167032) then
                    local extraText = L["SWITCH_TO_CHROMIE"] ..
                        " " .. C_ChromieTime.GetChromieTimeExpansionOption(step.ChromiePick).name
                    APR.currentStep:AddExtraLineText('ChromiePick', extraText)
                    C_Timer.After(1,
                        function() C_ChromieTime.SelectChromieTimeOption(step.ChromiePick) end)
                end
            end
        end
    end

    if not handledByAPR then
        HandleQuickQuestGossipFallback()
    end

    return selectedOption
end

function APR.gossip:HandleHardcodedGossip()
    local count = self.counter + 1
    if (count == 1) then
        C_GossipInfo.SelectOptionByIndex(1)
    elseif (count == 2) then
        if (APR.Race == "Gnome") then
            C_GossipInfo.SelectOptionByIndex(1)
        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
            C_GossipInfo.SelectOptionByIndex(2)
        elseif (APR.Race == "NightElf") then
            C_GossipInfo.SelectOptionByIndex(3)
        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
            C_GossipInfo.SelectOptionByIndex(4)
        end
    elseif (count == 3) then
        if (APR.Race == "Gnome") then
            C_GossipInfo.SelectOptionByIndex(3)
        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
            C_GossipInfo.SelectOptionByIndex(4)
        elseif (APR.Race == "NightElf") then
            C_GossipInfo.SelectOptionByIndex(2)
        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
            C_GossipInfo.SelectOptionByIndex(1)
        end
    elseif (count == 4) then
        if (APR.Race == "Gnome") then
            C_GossipInfo.SelectOptionByIndex(4)
        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
            C_GossipInfo.SelectOptionByIndex(2)
        elseif (APR.Race == "NightElf") then
            C_GossipInfo.SelectOptionByIndex(1)
        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
            C_GossipInfo.SelectOptionByIndex(3)
        end
    elseif (count == 5) then
        APR:UpdateNextStep()
    end
    return count
end

function APR.gossip:TriggerGossipETA(stepIndex, step)
    if not step or not step.GossipETA or step.SpecialETAHide then
        return
    end

    if APR.AFK.lastStep == stepIndex then
        return
    end

    APR.AFK:SetAfkTimer(step.GossipETA)
    APR.AFK.lastStep = stepIndex
end
