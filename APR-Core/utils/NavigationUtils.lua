local L = LibStub("AceLocale-3.0"):GetLocale("APR")

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

--- Keep only discovery state; localized names are supplied by LibTaxiData.
function APR:InitializeTaxiNodes()
    APRTaxiNodes = APRTaxiNodes or {}
    for _, playerNodes in pairs(APRTaxiNodes) do
        for nodeID, value in pairs(playerNodes) do
            if type(value) == "string" then
                playerNodes[nodeID] = true
            end
        end
    end
    APRTaxiNodes[self.PlayerID] = APRTaxiNodes[self.PlayerID] or {}
end

--- Detect whether the player has discovered a taxi node, not just whether it exists.
function APR:HasTaxiNode(nodeID)
    local playerNodes = APRTaxiNodes and APR.PlayerID and APRTaxiNodes[APR.PlayerID] or nil
    return playerNodes and playerNodes[nodeID] == true or false
end

--- Resolve the localized name without storing a second copy in APR.
---@param step table
---@return string nodeName
function APR:GetTaxiNodeName(step)
    if type(step) ~= "table" then
        return UNKNOWN
    end

    local nodeID = step.NodeID
    local libraryName = nodeID and APR.taxiData:GetNodeName(nodeID) or nil
    return libraryName or step.Name or UNKNOWN
end
