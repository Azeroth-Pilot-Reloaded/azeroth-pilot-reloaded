-- Navigation labels for itIT; English supplies missing-key fallbacks.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
if GetLocale() ~= "itIT" then return end

FarstriderLibData.L = setmetatable({
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Baia del Bottino",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Roccaforte di Piumaluna",
    ["ForeverPort_ForgottenCoast"] = "Costa Dimenticata",
    ["ForeverPort_Menethil"] = "Porto di Menethil",
    ["ForeverPort_Powderfuse"] = "Porto Powderfuse",
    ["ForeverPort_Ratchet"] = "Porto Paranco",
    ["ForeverPort_Ruttheran"] = "Rut'theran",
    ["ForeverPort_Skywatcher"] = "Altopiano Skywatcher",
    ["ForeverPort_Southshore"] = "Riva del Sud",
    ["ForeverPort_Steamwheedle"] = "Porto degli Spargifumo",
    ["ForeverPort_Stormwind"] = "Roccavento",
    ["ForeverPort_Theramore"] = "Isola di Theramore",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Isola di Zephras",
    ["ForeverPort_Gromgol"] = "Campo di Grom'gol",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Sepulcra",
    ["Unknown Location"] = "Luogo sconosciuto",
    ["Waypoint_1000"] = "Raggiungi la destinazione",
    ["Waypoint_1001"] = "Parla con il maestro di volo per raggiungere %s",
    ["Waypoint_1002"] = "Usa il portale per %s",
    ["Waypoint_1003"] = "Prendi la nave da %s a %s",
    ["Waypoint_1004"] = "Prendi lo zeppelin da %s a %s",
    ["Waypoint_1005"] = "Usa %s per raggiungere %s",
    ["Waypoint_1006"] = "Lancia %s per raggiungere %s",
    ["Unknown Item"] = "Oggetto sconosciuto",
    ["Unknown Spell"] = "Incantesimo sconosciuto",
}, { __index = FarstriderLibData.L })
