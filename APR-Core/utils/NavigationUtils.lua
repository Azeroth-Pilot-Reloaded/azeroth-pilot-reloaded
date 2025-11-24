local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--[[
    Navigation helpers kept apart from technical utilities so movement guidance is easy to locate.
]]

function APR:GuideToCorpse()
    local currentMapID = APR:GetPlayerParentMapID()
    local corpsePosition = C_DeathInfo.GetCorpseMapPosition(currentMapID)
    local worldCorpsePosition
    if corpsePosition then
        _, worldCorpsePosition = C_Map.GetWorldPosFromMapPos(currentMapID, corpsePosition)
    end

    if worldCorpsePosition then
        APR.currentStep:Reset()
        APR.Arrow:SetArrowActive(true, worldCorpsePosition.y, worldCorpsePosition.x)
        APR.currentStep:AddExtraLineText("DEAD_GUIDE", L["DEAD_GUIDE"], APR.HEXColor.red)
    end
end

--- Detect whether the player knows a taxi node.
function APR:HasTaxiNode(nodeID)
    for id in pairs(APRTaxiNodes[APR.PlayerID]) do
        if id == nodeID then
            return true
        end
    end
    return false
end

--- Resolve the most accurate name for a taxi node.
-- We check player-specific nodes first, then fall back to the route definition or faction-wide defaults.
function APR:GetTaxiNodeName(step)
    -- First, try to get the node name from the player's specific nodes
    local playerNodes = APRTaxiNodes[APR.PlayerID]
    if playerNodes and playerNodes[step.NodeID] then
        return playerNodes[step.NodeID]
    end

    -- Fallback to the name directly from the step object
    if step.Name then
        return step.Name
    end

    -- Check global faction nodes
    for _, factionNodes in pairs(APR.TaxiNodes) do
        for _, continentNode in pairs(factionNodes) do
            if continentNode[step.NodeID] then
                return continentNode[step.NodeID].Name
            end
        end
    end

    -- If no name found, return nil
    return nil
end
