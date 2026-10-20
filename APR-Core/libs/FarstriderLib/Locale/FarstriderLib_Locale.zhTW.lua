-- Navigation labels for zhTW; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "zhTW" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "未知位置",
    ["Waypoint_1000"] = "到達目的地",
    ["Waypoint_1001"] = "與飛行管理員對話前往%s",
    ["Waypoint_1002"] = "傳送到%s",
    ["Waypoint_1003"] = "從%s搭船到%s",
    ["Waypoint_1004"] = "從%s搭飛船到%s",
    ["Waypoint_1005"] = "使用%s到%s",
    ["Waypoint_1006"] = "施放%s到%s",
}, { __index = FarstriderLib.Locale })
