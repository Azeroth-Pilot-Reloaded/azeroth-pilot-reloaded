-- Navigation labels for zhCN; English supplies missing-key fallbacks.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end
if GetLocale() ~= "zhCN" then return end

FarstriderLib.Locale = setmetatable({
    ["Unknown Location"] = "未知位置",
    ["Waypoint_1000"] = "到达目的地",
    ["Waypoint_1001"] = "与飞行管理员对话前往%s",
    ["Waypoint_1002"] = "传送到%s",
    ["Waypoint_1003"] = "从%s搭船到%s",
    ["Waypoint_1004"] = "从%s搭飞艇到%s",
    ["Waypoint_1005"] = "使用%s到%s",
    ["Waypoint_1006"] = "施放%s到%s",
}, { __index = FarstriderLib.Locale })
