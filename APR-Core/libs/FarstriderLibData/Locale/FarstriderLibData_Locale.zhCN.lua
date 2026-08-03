-- FarstriderLibData_Locale.zhCN.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "zhCN") then
    return;
end

FarstriderLibData.L = {
    ["Unknown Location"] = "未知位置",
    ["Waypoint_1000"] = "到达目的地",
    ["Waypoint_1001"] = "与飞行管理员对话前往%s",
    ["Waypoint_1002"] = "传送到%s",
    ["Waypoint_1003"] = "从%s搭船到%s",
    ["Waypoint_1004"] = "从%s搭飞艇到%s",
    ["Waypoint_1005"] = "使用%s到%s",
    ["Waypoint_1006"] = "施放%s到%s",
};

setmetatable(FarstriderLibData.L, {
    __index = function(t, k)
        rawset(t, k, k); return k;
    end
})
