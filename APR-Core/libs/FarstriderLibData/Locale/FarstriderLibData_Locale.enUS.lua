-- FarstriderLibData_Locale.enUS.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

FarstriderLibData.L = {
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
