-- Navigation labels for itIT; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "itIT" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "Luogo sconosciuto",
    ["Waypoint_1000"] = "Raggiungi la destinazione",
    ["Waypoint_1001"] = "Parla con il maestro di volo per raggiungere %s",
    ["Waypoint_1002"] = "Usa il portale per %s",
    ["Waypoint_1003"] = "Prendi la nave da %s a %s",
    ["Waypoint_1004"] = "Prendi lo zeppelin da %s a %s",
    ["Waypoint_1005"] = "Usa %s per raggiungere %s",
    ["Waypoint_1006"] = "Lancia %s per raggiungere %s",
}, { __index = FarstriderLib.Locale })
