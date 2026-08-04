local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.taxiData = APR:NewModule("TaxiData")

local ADDON_NAME = "LibTaxiData"
local REQUIRED_METHODS = {
    "GetNode",
    "GetNodeDetails",
    "GetNodeName",
    "GetNodeWorldPosition",
    "GetNodeAPRWorldPosition",
    "GetNodeMapPosition",
    "MapToWorld",
    "WorldToMap",
    "FindNearestNodeFromWorld",
    "FindNearestNodeFromAPRWorld",
    "FindNearestNodeFromMap",
    "FindNearestNodeToPlayer",
    "SetWaypointToNode",
}

---Return LibTaxiData's public API when every API used by APR is available.
---Capabilities are checked instead of pinning APR to a library release number.
---@return table|nil api
---@return string|nil missingDependency
function APR.taxiData:GetAPI()
    local api = _G.LibTaxiData_API
    if type(api) ~= "table" then
        return nil, ADDON_NAME
    end

    for _, methodName in ipairs(REQUIRED_METHODS) do
        if type(api[methodName]) ~= "function" then
            return nil, ADDON_NAME
        end
    end

    return api
end

function APR.taxiData:IsAvailable()
    return self:GetAPI() ~= nil
end

---Call a LibTaxiData API without exposing its global table throughout APR.
---Wrapper failures return nil plus the missing dependency name; successful calls
---forward every value from the library method unchanged.
---@param methodName string
---@param ... any
---@return any
function APR.taxiData:Call(methodName, ...)
    local api, missingDependency = self:GetAPI()
    if not api then
        return nil, missingDependency
    end

    local method = api[methodName]
    if type(method) ~= "function" then
        return nil, ADDON_NAME
    end

    return method(...)
end

function APR.taxiData:GetNode(nodeID)
    return self:Call("GetNode", nodeID)
end

function APR.taxiData:GetNodeDetails(nodeID, uiMapID)
    return self:Call("GetNodeDetails", nodeID, uiMapID)
end

function APR.taxiData:GetNodeName(nodeID)
    return self:Call("GetNodeName", nodeID)
end

function APR.taxiData:GetNodeWorldPosition(nodeID, coordinateFormat)
    return self:Call("GetNodeWorldPosition", nodeID, coordinateFormat)
end

function APR.taxiData:GetNodeAPRWorldPosition(nodeID)
    return self:Call("GetNodeAPRWorldPosition", nodeID)
end

function APR.taxiData:GetNodeMapPosition(nodeID, uiMapID, allowOutOfBounds)
    return self:Call("GetNodeMapPosition", nodeID, uiMapID, allowOutOfBounds)
end

function APR.taxiData:MapToWorld(uiMapID, mapX, mapY)
    return self:Call("MapToWorld", uiMapID, mapX, mapY)
end

function APR.taxiData:WorldToMap(instanceID, worldX, worldY, uiMapID, allowOutOfBounds)
    return self:Call("WorldToMap", instanceID, worldX, worldY, uiMapID, allowOutOfBounds)
end

function APR.taxiData:FindNearestNodeFromWorld(worldX, worldY, instanceID, options)
    return self:Call("FindNearestNodeFromWorld", worldX, worldY, instanceID, options)
end

function APR.taxiData:FindNearestNodeFromAPRWorld(aprX, aprY, instanceID, options)
    return self:Call("FindNearestNodeFromAPRWorld", aprX, aprY, instanceID, options)
end

function APR.taxiData:FindNearestNodeFromMap(uiMapID, mapX, mapY, options)
    return self:Call("FindNearestNodeFromMap", uiMapID, mapX, mapY, options)
end

function APR.taxiData:FindNearestNodeToPlayer(options)
    return self:Call("FindNearestNodeToPlayer", options)
end

function APR.taxiData:SetWaypointToNode(nodeID, preferredMapID)
    return self:Call("SetWaypointToNode", nodeID, preferredMapID)
end

local dependencyEventFrame = CreateFrame("Frame")
dependencyEventFrame:RegisterEvent("PLAYER_LOGIN")
dependencyEventFrame:SetScript("OnEvent", function()
    local _, missingDependency = APR.taxiData:GetAPI()
    if missingDependency then
        APR:PrintError(string.format(L["ADDON_DEPENDENCY_MISSING"], missingDependency))
    end
end)
