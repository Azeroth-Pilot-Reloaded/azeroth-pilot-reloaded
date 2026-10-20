-- FarstriderLibData~Finalizer.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

FarstriderLibData.Internal = nil

---@type FarstriderLibDataAPI
FarstriderLibData_API = {
    VERSION = FarstriderLibData.VERSION,
    WAYPOINTS = FarstriderLibData.Waypoints,
    CONFIG = FarstriderLibData.Config,
    GetLocalizedString = function(locaId)
        -- Edge-type IDs are reserved for generic, locale-specific instructions.
        -- An older waypoint label must not shadow their active locale.
        if type(locaId) == "number" and locaId >= 1000 and locaId <= 1006 then
            return FarstriderLibData.L["Waypoint_" .. locaId]
        end
        return FarstriderLibData.WaypointL[locaId] or FarstriderLibData.L["Waypoint_" .. locaId]
    end,
    IsBindLocationSupported = function()
        return FarstriderLibData.AreaL[GetBindLocation()] ~= nil
    end,
    GetHousingData = function()
        return FarstriderLibData.HousingData
    end,
    UpdateHousingExitLocation = function()
        if not FarstriderLibData_CharacterSettings then
            FarstriderLibData_CharacterSettings = {}
        end

        FarstriderLibData_CharacterSettings.housingExitLocation = FarstriderLibData.Util.GetPlayerLocation()
    end,
    GetHelpfulItems = function()
        return FarstriderLibData.Connections.helpfulItems
    end
}

-- legacy support for direct access, will be removed in a future update
_G.FarstriderLibData = FarstriderLibData
