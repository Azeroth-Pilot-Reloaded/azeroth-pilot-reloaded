-- Navigation labels for koKR; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "koKR" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "알 수 없는 위치",
    ["Waypoint_1000"] = "목적지에 도착하세요",
    ["Waypoint_1001"] = "비행 조련사와 대화하여 %s 지역으로 이동하세요",
    ["Waypoint_1002"] = "%s 지역으로 가는 차원문을 이용하세요",
    ["Waypoint_1003"] = "%s에서 %s 지역으로 가는 배를 타세요",
    ["Waypoint_1004"] = "%s에서 %s 지역으로 가는 비행선을 타세요",
    ["Waypoint_1005"] = "%s 사용 후 %s 지역으로 이동하세요",
    ["Waypoint_1006"] = "%s 시전 후 %s 지역으로 이동하세요",
}, { __index = FarstriderLib.Locale })
