-- Navigation labels for esMX; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "esMX" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "Ubicación desconocida",
    ["Waypoint_1000"] = "Llega al destino",
    ["Waypoint_1001"] = "Habla con el maestro de vuelo para viajar a %s",
    ["Waypoint_1002"] = "Usa el portal a %s",
    ["Waypoint_1003"] = "Toma el barco de %s a %s",
    ["Waypoint_1004"] = "Toma el zepelín de %s a %s",
    ["Waypoint_1005"] = "Usa %s para ir a %s",
    ["Waypoint_1006"] = "Lanza %s para ir a %s",
}, { __index = FarstriderLib.Locale })
