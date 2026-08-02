local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local taxiNodeNameCache = {}
local scannedTaxiMaps = {}

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
    local playerNodes = APRTaxiNodes and APR.PlayerID and APRTaxiNodes[APR.PlayerID] or nil
    return playerNodes and playerNodes[nodeID] ~= nil or false
end

--- Cache names returned by either C_TaxiMap query.
---@param taxiNodes table|nil
function APR:CacheTaxiNodeNames(taxiNodes)
    for _, node in ipairs(taxiNodes or {}) do
        if node.nodeID and node.name and node.name ~= "" then
            taxiNodeNameCache[node.nodeID] = node.name
        end
    end
end

local function ScanTaxiMap(mapID)
    if type(mapID) ~= "number" or mapID <= 0 or scannedTaxiMaps[mapID] then
        return
    end
    if not C_TaxiMap or not C_TaxiMap.GetTaxiNodesForMap then
        return
    end

    local success, taxiNodes = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
    if success then
        scannedTaxiMaps[mapID] = true
        APR:CacheTaxiNodeNames(taxiNodes)
    end
end

local function ScanTaxiMapHierarchy(mapID)
    if type(mapID) ~= "number" or mapID <= 0 then
        return
    end

    local hierarchy = APR.GetMapParentChain and APR:GetMapParentChain(mapID) or { mapID }
    for _, hierarchyMapID in ipairs(hierarchy) do
        ScanTaxiMap(hierarchyMapID)
    end
end

local function ScanStepTaxiMaps(step, fallbackMapID)
    if type(step) ~= "table" then
        return
    end

    local zones = APR.GetStepZoneList and APR:GetStepZoneList(step, fallbackMapID) or {}
    for _, mapID in ipairs(zones) do
        ScanTaxiMapHierarchy(mapID)
    end
end

--- Resolve a taxi node name from live Blizzard data, then from LibTaxiData.
---@param step table
---@return string nodeName
function APR:GetTaxiNodeName(step)
    if type(step) ~= "table" then
        return UNKNOWN
    end

    local nodeID = step.NodeID
    local playerNodes = APRTaxiNodes and APR.PlayerID and APRTaxiNodes[APR.PlayerID] or nil
    if nodeID and playerNodes and playerNodes[nodeID] then
        return playerNodes[nodeID]
    end
    if nodeID and taxiNodeNameCache[nodeID] then
        return taxiNodeNameCache[nodeID]
    end
    local libraryName = nodeID and APR.taxiData:GetNodeName(nodeID) or nil
    if libraryName then
        return libraryName
    end

    ScanTaxiMapHierarchy(C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil)

    local routeData = APR.ActiveRoute and APR.GetRouteData and APR:GetRouteData(APR.ActiveRoute) or nil
    local fallbackMapID = routeData and routeData.mapID or nil
    ScanStepTaxiMaps(step, fallbackMapID)

    local currentStepIndex = routeData and APRData and APR.PlayerID and APRData[APR.PlayerID] and
        APRData[APR.PlayerID][APR.ActiveRoute] or nil
    if currentStepIndex and APR.GetStep then
        ScanStepTaxiMaps(APR:GetStep(currentStepIndex + 1), fallbackMapID)
    end

    if routeData and routeData.conditions and type(routeData.conditions.Zones) == "table" then
        for _, mapID in ipairs(routeData.conditions.Zones) do
            ScanTaxiMapHierarchy(mapID)
        end
    end

    return (nodeID and taxiNodeNameCache[nodeID]) or step.Name or UNKNOWN
end
