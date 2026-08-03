-- FarstriderLibData_Locale.ruRU.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "ruRU") then
    return;
end

FarstriderLibData.L = {
    ["Unknown Location"] = "Неизвестное местоположение",
    ["Waypoint_1000"] = "Добраться до пункта назначения",
    ["Waypoint_1001"] = "Поговорите с распорядителем полётов, чтобы отправиться в %s",
    ["Waypoint_1002"] = "Возьмите портал в %s",
    ["Waypoint_1003"] = "Сядьте на корабль из %s в %s",
    ["Waypoint_1004"] = "Сядьте на дирижабль из %s в %s",
    ["Waypoint_1005"] = "Используйте %s для %s",
    ["Waypoint_1006"] = "Каст %s на %s",
};

setmetatable(FarstriderLibData.L, {
    __index = function(t, k)
        rawset(t, k, k); return k;
    end
})
