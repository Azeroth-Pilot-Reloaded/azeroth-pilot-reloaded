-- Navigation labels for esMX; English supplies missing-key fallbacks.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
if GetLocale() ~= "esMX" then return end

FarstriderLibData.L = setmetatable({
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Bahía del Botín",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Bastión Plumaluna",
    ["ForeverPort_ForgottenCoast"] = "Costa Olvidada",
    ["ForeverPort_Menethil"] = "Puerto de Menethil",
    ["ForeverPort_Powderfuse"] = "Puerto Powderfuse",
    ["ForeverPort_Ratchet"] = "Trinquete",
    ["ForeverPort_Ruttheran"] = "Aldea Rut'theran",
    ["ForeverPort_Skywatcher"] = "Meseta Skywatcher",
    ["ForeverPort_Southshore"] = "Costasur",
    ["ForeverPort_Steamwheedle"] = "Puerto Bonvapor",
    ["ForeverPort_Stormwind"] = "Ventormenta",
    ["ForeverPort_Theramore"] = "Isla Theramore",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Isla Zephras",
    ["ForeverPort_Gromgol"] = "Campamento Grom'gol",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Entrañas",
    ["Unknown Location"] = "Ubicación desconocida",
    ["Waypoint_1000"] = "Llega al destino",
    ["Waypoint_1001"] = "Habla con el maestro de vuelo para viajar a %s",
    ["Waypoint_1002"] = "Usa el portal a %s",
    ["Waypoint_1003"] = "Toma el barco de %s a %s",
    ["Waypoint_1004"] = "Toma el zepelín de %s a %s",
    ["Waypoint_1005"] = "Usa %s para ir a %s",
    ["Waypoint_1006"] = "Lanza %s para ir a %s",
    ["Unknown Item"] = "Objeto desconocido",
    ["Unknown Spell"] = "Hechizo desconocido",
}, { __index = FarstriderLibData.L })
