local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.flightPath = APR:NewModule("FlightPath")
APR.flightPath.CurrentTaxiNode = {}
APR.flightPath.StepTaxiNode = {}

APR.flightPath.eventFrame = CreateFrame("Frame")
APR.flightPath.eventFrame:RegisterEvent("TAXIMAP_OPENED")
APR.flightPath.eventFrame:RegisterEvent("PLAYER_CONTROL_LOST")
APR.flightPath.eventFrame:SetScript("OnEvent", function(self, event)
    if not APR.settings.profile.enableAddon then
        return
    end

    local step = APR.ActiveRoute and APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute]) or nil
    if APR.settings.profile.showEvent then
        APR:PrintInfo(string.format(L["FLIGHT_PATH_EVENT"], event))
    end

    if event == "TAXIMAP_OPENED" then
        local taxiMapID = GetTaxiMapID()
        local taxiNodes = (taxiMapID and C_TaxiMap.GetAllTaxiNodes(taxiMapID)) or {}
        APR:CacheTaxiNodeNames(taxiNodes)

        APR.flightPath.CurrentTaxiNode = {}
        APR.flightPath.StepTaxiNode = {}

        for _, node in ipairs(taxiNodes) do
            if node.state ~= Enum.FlightPathState.Unreachable and not APRTaxiNodes[APR.PlayerID][node.nodeID] then
                APRTaxiNodes[APR.PlayerID][node.nodeID] = node.name
            end
            if node.state == Enum.FlightPathState.Current then
                APR.flightPath.CurrentTaxiNode = node
            end
            if step and step.NodeID == node.nodeID then
                APR.flightPath.StepTaxiNode = node
            end
        end

        if step and step.UseFlightPath then
            local currentNodeID = APR.flightPath.CurrentTaxiNode.nodeID
            local stepNodeID = APR.flightPath.StepTaxiNode.nodeID
            if currentNodeID and stepNodeID and currentNodeID == stepNodeID then
                APR:NextQuestStep()
            elseif not IsModifierKeyDown() and APR.flightPath.StepTaxiNode.slotIndex then
                if APR.settings.profile.autoFlight then
                    TakeTaxiNode(APR.flightPath.StepTaxiNode.slotIndex)
                end
            end
        end
    elseif event == "PLAYER_CONTROL_LOST" then
        C_Timer.After(2, function()
            if not UnitOnTaxi("player") then
                return
            end

            if step and step.ETA then
                APR.AFK:SetAfkTimer(step.ETA)
            elseif next(APR.flightPath.CurrentTaxiNode) and next(APR.flightPath.StepTaxiNode) then
                local taxiPath = APR.flightPath.CurrentTaxiNode.name .. "-" .. APR.flightPath.StepTaxiNode.name
                local timer = APRTaxiNodesTimer[taxiPath]
                if not timer then
                    APR.AFK.TaxiTimerRecorder:Play()
                else
                    APR.AFK:SetAfkTimer(timer)
                end
            end

            if step and step.UseFlightPath then
                APR:UpdateNextStep()
            end
        end)
    end
end)
