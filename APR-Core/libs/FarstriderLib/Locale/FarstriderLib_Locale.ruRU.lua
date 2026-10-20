-- Navigation labels for ruRU; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "ruRU" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "Неизвестное местоположение",
    ["Waypoint_1000"] = "Добраться до пункта назначения",
    ["Waypoint_1001"] = "Поговорите с распорядителем полётов, чтобы отправиться в %s",
    ["Waypoint_1002"] = "Возьмите портал в %s",
    ["Waypoint_1003"] = "Сядьте на корабль из %s в %s",
    ["Waypoint_1004"] = "Сядьте на дирижабль из %s в %s",
    ["Waypoint_1005"] = "Используйте %s для %s",
    ["Waypoint_1006"] = "Каст %s на %s",
}, { __index = FarstriderLib.Locale })
