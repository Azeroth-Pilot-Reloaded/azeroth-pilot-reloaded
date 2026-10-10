-- FarstriderLibData_Locale.deDE.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "deDE") then
    return;
end

FarstriderLibData.L = {
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Beutebucht",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Mondfederfeste",
    ["ForeverPort_ForgottenCoast"] = "Vergessene Küste",
    ["ForeverPort_Menethil"] = "Hafen von Menethil",
    ["ForeverPort_Powderfuse"] = "Hafen von Powderfuse",
    ["ForeverPort_Ratchet"] = "Ratschet",
    ["ForeverPort_Ruttheran"] = "Rut'theran",
    ["ForeverPort_Skywatcher"] = "Skywatcher-Plateau",
    ["ForeverPort_Southshore"] = "Süderstade",
    ["ForeverPort_Steamwheedle"] = "Dampfdruckpier",
    ["ForeverPort_Stormwind"] = "Sturmwind",
    ["ForeverPort_Theramore"] = "Insel Theramore",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Insel Zephras",
    ["ForeverPort_Gromgol"] = "Basislager Grom'gol",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Unterstadt",
    ["Unknown Location"] = "Unbekannter Ort",
    ["Waypoint_1000"] = "Erreiche das Ziel",
    ["Waypoint_1001"] = "Redet mit dem Flugmeister um nach %s zu reisen",
    ["Waypoint_1002"] = "Nehmt das Portal zu %s",
    ["Waypoint_1003"] = "Nehmt das Schiff von %s nach %s",
    ["Waypoint_1004"] = "Nehmt den Zeppelin von %s nach %s",
    ["Waypoint_1005"] = "Benutze %s nach %s",
    ["Waypoint_1006"] = "Wirke %s nach %s",
};

setmetatable(FarstriderLibData.L, {
    __index = function(t, k)
        rawset(t, k, k); return k;
    end
})
