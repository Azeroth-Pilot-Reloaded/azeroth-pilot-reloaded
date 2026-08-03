-- FarstriderLib~Data.lua
-- Data management
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

local L = {
    ["Unknown Location"] = "Unknown Location",
    ["Waypoint_1000"] = "Reach the destination",
    ["Waypoint_1001"] = "Talk to the Flightmaster to travel to %s",
    ["Waypoint_1002"] = "Take the portal to %s",
    ["Waypoint_1003"] = "Take the boat from %s to %s",
    ["Waypoint_1004"] = "Take the zeppelin from %s to %s",
    ["Waypoint_1005"] = "Use %s to %s",
    ["Waypoint_1006"] = "Cast %s to %s",
};

---@type FarstriderLibDataAPI
local defaults = {
    VERSION = 0,
    WAYPOINTS = {},
    CONFIG = {
        ElevationOverrides = {},
        MapTypeOverrides = {},
        ContinentMapOverrides = {},
        IsolatedAreas = {},
        IsolatedContinents = {},
    },
    GetLocalizedString = function(locaId) return L["Waypoint_" .. locaId] or L["Unknown Location"] end,
    IsBindLocationSupported = function() return false end,
    GetHousingData = function() return nil end,
    UpdateHousingExitLocation = function() end,
    GetHelpfulItems = function() return {} end,
}

---@type FarstriderLibDataAPI
FarstriderLib.Data = setmetatable({}, {
    __index = function(_, k)
        local api = FarstriderLibData_API
        if api and api[k] ~= nil then return api[k] end
        return defaults[k]
    end,
    __newindex = function(_, k, v)
        if not FarstriderLibData_API then FarstriderLibData_API = {} end
        FarstriderLibData_API[k] = v
    end,
})
