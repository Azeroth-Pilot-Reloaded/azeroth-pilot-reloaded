local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.gossip = APR:NewModule("Gossip")

APR.gossip.counter = 0

-- To handle gossipOptionID
if C_GossipInfo and C_GossipInfo.SelectOption and hooksecurefunc then
    if not APR.gossip._hookedSelectOption then
        hooksecurefunc(C_GossipInfo, "SelectOption", function(optionID)
            if APR.ActiveRoute then
                local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
                if step and step.GossipOptionIDs and not APR:HasAnyMainStepOption(step) then
                    if tContains(step.GossipOptionIDs, optionID) then
                        APRGossipValidated[APR.PlayerID][optionID] = true
                        APR:Debug("Gossip selected option ID:", optionID)

                        --check if all completed
                        local isFullCompleted = APR:hasEveryGossipsCompleted(step.GossipOptionIDs)
                        if isFullCompleted then
                            APR:UpdateNextStep()
                        end
                    end
                end
            end
        end)
        APR.gossip._hookedSelectOption = true
    end
end

function APR.gossip:HandleGossip(step)
    if not (step and APR.settings.profile.autoGossip) then
        return
    end
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
    if (step.UseFlightPath or step.GetFP) and not step.NoAutoFlightMap and not step.GossipOptionIDs then
        PickGossipByIcon(132057)
    end
    -- BuyMerchant
    if step.BuyMerchant and not step.GossipOptionIDs then
        PickGossipByIcon(132060)
    end
    ------------------------------------
    -- GOSSIP
    if step.Gossip or step.GossipOptionIDs then
        if (step.Gossip == 28202) then -- GOSSIP HARDCODED
            -- //TODO Remove this when all hardcoded gossip are removed
            -- This is a hardcoded gossip for the quest https://www.wowhead.com/quest=28205/a-perfect-costume
            self.counter = self:HandleHardcodedGossip()
        else
            local info = C_GossipInfo.GetOptions()
            if next(info) then
                if step.GossipOptionIDs then
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
