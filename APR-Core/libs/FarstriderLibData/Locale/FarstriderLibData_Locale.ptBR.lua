-- Navigation labels for ptBR; English supplies missing-key fallbacks.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
if GetLocale() ~= "ptBR" then return end

FarstriderLibData.L = setmetatable({
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Angra do Butim",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Domínio de Plumaluna",
    ["ForeverPort_ForgottenCoast"] = "Costa Esquecida",
    ["ForeverPort_Menethil"] = "Porto de Menethil",
    ["ForeverPort_Powderfuse"] = "Porto Powderfuse",
    ["ForeverPort_Ratchet"] = "Vila Catraca",
    ["ForeverPort_Ruttheran"] = "Vila de Rut'theran",
    ["ForeverPort_Skywatcher"] = "Planalto Skywatcher",
    ["ForeverPort_Southshore"] = "Costa Sul",
    ["ForeverPort_Steamwheedle"] = "Porto Bondebico",
    ["ForeverPort_Stormwind"] = "Ventobravo",
    ["ForeverPort_Theramore"] = "Ilha Theramore",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Ilha de Zephras",
    ["ForeverPort_Gromgol"] = "Acampamento Grom'gol",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Cidade Baixa",
    ["Unknown Location"] = "Local desconhecido",
    ["Waypoint_1000"] = "Chegue ao destino",
    ["Waypoint_1001"] = "Fale com o mestre de voo para viajar até %s",
    ["Waypoint_1002"] = "Use o portal para %s",
    ["Waypoint_1003"] = "Pegue o barco de %s para %s",
    ["Waypoint_1004"] = "Pegue o zepelim de %s para %s",
    ["Waypoint_1005"] = "Use %s para ir até %s",
    ["Waypoint_1006"] = "Lance %s para ir até %s",
    ["Unknown Item"] = "Item desconhecido",
    ["Unknown Spell"] = "Feitiço desconhecido",
}, { __index = FarstriderLibData.L })
