-- FarstriderLibData_Locale.enUS.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

FarstriderLibData.L = {
    ["ForeverPort_Auberdine"] = "Auberdine",
    ["ForeverPort_BootyBay"] = "Booty Bay",
    ["ForeverPort_Dalaran"] = "Dalaran",
    ["ForeverPort_Feathermoon"] = "Feathermoon Stronghold",
    ["ForeverPort_ForgottenCoast"] = "Forgotten Coast",
    ["ForeverPort_Menethil"] = "Menethil Harbor",
    ["ForeverPort_Powderfuse"] = "Powderfuse Port",
    ["ForeverPort_Ratchet"] = "Ratchet",
    ["ForeverPort_Ruttheran"] = "Rut'theran Village",
    ["ForeverPort_Skywatcher"] = "Skywatcher Plateau",
    ["ForeverPort_Southshore"] = "Southshore",
    ["ForeverPort_Steamwheedle"] = "Steamwheedle Port",
    ["ForeverPort_Stormwind"] = "Stormwind",
    ["ForeverPort_Theramore"] = "Theramore Isle",
    ["ForeverPort_Valanaar"] = "Valanaar",
    ["ForeverPort_Zephras"] = "Zephras Isle",
    ["ForeverPort_Gromgol"] = "Grom'gol Base Camp",
    ["ForeverPort_Orgrimmar"] = "Orgrimmar",
    ["ForeverPort_Undercity"] = "Undercity",
  ["Unknown Location"] = "Unknown Location",
  ["Waypoint_1000"] = "Reach the destination",
  ["Waypoint_1001"] = "Talk to the Flightmaster to travel to %s",
  ["Waypoint_1002"] = "Take the portal to %s",
  ["Waypoint_1003"] = "Take the boat from %s to %s",
  ["Waypoint_1004"] = "Take the zeppelin from %s to %s",
  ["Waypoint_1005"] = "Use %s to %s",
  ["Waypoint_1006"] = "Cast %s to %s",
};

setmetatable(FarstriderLibData.L, {
  __index = function(t, k)
    rawset(t, k, k); return k;
  end
})
