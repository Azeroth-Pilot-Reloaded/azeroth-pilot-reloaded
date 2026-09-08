-- Builds Farstrider's flight-path graph from the standalone LibTaxiData addon.
-- This integration deliberately lives in APR so embedded libraries remain pristine.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

local taxi = _G.LibTaxiData_API
local canUseTaxiData = type(taxi) == "table"
    and type(taxi.GetAllNodes) == "function"
    and type(taxi.GetNodeName) == "function"
    and type(taxi.IsNodeAvailable) == "function"
    and type(taxi.IsNodeVisible) == "function"

FarstriderLibData.Waypoints = {}
FarstriderLibData.WaypointL = {}

if not canUseTaxiData then return end

local FLIGHTPATH_LOCALE_ID = 1001
local TAXI_SPEED_YARDS_PER_SECOND = 32

local function isUsable(nodeID)
    return taxi.IsNodeAvailable(nodeID) ~= false and taxi.IsNodeVisible(nodeID) ~= false
end

local function makeLocation(nodeID, node, destinationID)
    return {
        unknown1 = 0,
        flags = 0,
        loc = {
            mapId = node.continentID,
            pos = { x = node.x, y = node.y, z = node.z or 0 },
            isUI = false,
        },
        condition = function() return isUsable(nodeID) and isUsable(destinationID) end,
        type = 1,
        important = true,
        locaId = FLIGHTPATH_LOCALE_ID,
        locaArgs = function()
            return { taxi.GetNodeName(destinationID) or FarstriderLibData.L["Unknown Location"] }
        end,
    }
end

local nodesByContinent = {}
for nodeID, node in pairs(taxi.GetAllNodes()) do
    if type(node) == "table"
        and type(node.continentID) == "number"
        and type(node.x) == "number"
        and type(node.y) == "number"
        and isUsable(nodeID)
    then
        local nodes = nodesByContinent[node.continentID]
        if not nodes then
            nodes = {}
            nodesByContinent[node.continentID] = nodes
        end
        nodes[#nodes + 1] = { id = nodeID, data = node }
    end
end

for _, nodes in pairs(nodesByContinent) do
    for fromIndex = 1, #nodes - 1 do
        local from = nodes[fromIndex]
        for toIndex = fromIndex + 1, #nodes do
            local to = nodes[toIndex]
            local deltaX = from.data.x - to.data.x
            local deltaY = from.data.y - to.data.y
            local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)

            FarstriderLibData.Waypoints[#FarstriderLibData.Waypoints + 1] = {
                id = from.id * 100000 + to.id,
                from = makeLocation(from.id, from.data, to.id),
                to = makeLocation(to.id, to.data, from.id),
                bidirectional = true,
                cost = math.max(1, distance / TAXI_SPEED_YARDS_PER_SECOND),
            }
        end
    end
end
