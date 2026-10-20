-- FarstriderLib~Data.lua
-- Data management
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

-- Locale files load first; the fallback does not depend on the data addon's API.
local L = FarstriderLib.Locale

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
