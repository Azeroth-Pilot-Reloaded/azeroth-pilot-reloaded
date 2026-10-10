-- FarstriderLibData_Locale.frFR.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "frFR") then
    return;
end

FarstriderLibData.L = {
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Baie-du-Butin",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Bastion de Pennelune",
    ["ForeverPort_ForgottenCoast"] = "Côte oubliée",
    ["ForeverPort_Menethil"] = "Port de Menethil",
    ["ForeverPort_Powderfuse"] = "Port de Powderfuse",
    ["ForeverPort_Ratchet"] = "Cabestan",
    ["ForeverPort_Ruttheran"] = "Village de Rut'theran",
    ["ForeverPort_Skywatcher"] = "Plateau de Skywatcher",
    ["ForeverPort_Southshore"] = "Austrivage",
    ["ForeverPort_Steamwheedle"] = "Port Gentepression",
    ["ForeverPort_Stormwind"] = "Hurlevent",
    ["ForeverPort_Theramore"] = "Île de Theramore",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Île de Zephras",
    ["ForeverPort_Gromgol"] = "Campement Grom'gol",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Fossoyeuse",
    ["Unknown Location"] = "Emplacement inconnu",
    ["Waypoint_1000"] = "Atteindre la destination",
    ["Waypoint_1001"] = "Parlez au maître de vol pour voyager vers %s",
    ["Waypoint_1002"] = "Prenez le portail pour %s",
    ["Waypoint_1003"] = "Prenez le bateau de %s vers %s",
    ["Waypoint_1004"] = "Prenez le zeppelin de %s vers %s",
    ["Waypoint_1005"] = "Utilisez %s vers %s",
    ["Waypoint_1006"] = "Lancez %s vers %s",
};
