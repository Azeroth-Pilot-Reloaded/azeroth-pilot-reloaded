-- FarstriderLibData_Locale.frFR.lua
-- local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "frFR") then
    return;
end

FarstriderLibData.L = {
    ["Unknown Location"] = "Emplacement inconnu",
    ["Waypoint_1000"] = "Atteindre la destination",
    ["Waypoint_1001"] = "Parlez au maître de vol pour voyager vers %s",
    ["Waypoint_1002"] = "Prenez le portail pour %s",
    ["Waypoint_1003"] = "Prenez le bateau de %s vers %s",
    ["Waypoint_1004"] = "Prenez le zeppelin de %s vers %s",
    ["Waypoint_1005"] = "Utilisez %s vers %s",
    ["Waypoint_1006"] = "Lancez %s vers %s",
};

setmetatable(FarstriderLibData.L, {
    __index = function(t, k)
        rawset(t, k, k); return k;
    end
})
