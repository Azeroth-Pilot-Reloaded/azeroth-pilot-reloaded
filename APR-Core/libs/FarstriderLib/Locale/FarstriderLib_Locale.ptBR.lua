-- Navigation labels for ptBR; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "ptBR" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "Local desconhecido",
    ["Waypoint_1000"] = "Chegue ao destino",
    ["Waypoint_1001"] = "Fale com o mestre de voo para viajar até %s",
    ["Waypoint_1002"] = "Use o portal para %s",
    ["Waypoint_1003"] = "Pegue o barco de %s para %s",
    ["Waypoint_1004"] = "Pegue o zepelim de %s para %s",
    ["Waypoint_1005"] = "Use %s para ir até %s",
    ["Waypoint_1006"] = "Lance %s para ir até %s",
}, { __index = FarstriderLib.Locale })
