-- Navigation labels for deDE; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "deDE" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "Unbekannter Ort",
    ["Waypoint_1000"] = "Erreiche das Ziel",
    ["Waypoint_1001"] = "Redet mit dem Flugmeister um nach %s zu reisen",
    ["Waypoint_1002"] = "Nehmt das Portal zu %s",
    ["Waypoint_1003"] = "Nehmt das Schiff von %s nach %s",
    ["Waypoint_1004"] = "Nehmt den Zeppelin von %s nach %s",
    ["Waypoint_1005"] = "Benutze %s nach %s",
    ["Waypoint_1006"] = "Wirke %s nach %s",
}, { __index = FarstriderLib.Locale })
