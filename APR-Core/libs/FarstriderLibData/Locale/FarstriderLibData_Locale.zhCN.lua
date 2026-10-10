-- FarstriderLibData_Locale.zhCN.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "zhCN") then
    return;
end

FarstriderLibData.L = {
    ["ForeverPort_Auberdine"] = "奥伯丁",
    ["ForeverPort_BootyBay"] = "藏宝海湾",
    ["ForeverPort_Dalaran"] = "达拉然",
    ["ForeverPort_Feathermoon"] = "羽月要塞",
    ["ForeverPort_ForgottenCoast"] = "被遗忘的海岸",
    ["ForeverPort_Menethil"] = "米奈希尔港",
    ["ForeverPort_Powderfuse"] = "Powderfuse港",
    ["ForeverPort_Ratchet"] = "棘齿城",
    ["ForeverPort_Ruttheran"] = "鲁瑟兰村",
    ["ForeverPort_Skywatcher"] = "Skywatcher高地",
    ["ForeverPort_Southshore"] = "南海镇",
    ["ForeverPort_Steamwheedle"] = "热砂港",
    ["ForeverPort_Stormwind"] = "暴风城",
    ["ForeverPort_Theramore"] = "塞拉摩岛",
    ["ForeverPort_Valanaar"] = "瓦拉纳尔",
    ["ForeverPort_Zephras"] = "泽弗拉斯岛",
    ["ForeverPort_Gromgol"] = "格罗姆高营地",
    ["ForeverPort_Orgrimmar"] = "奥格瑞玛",
    ["ForeverPort_Undercity"] = "幽暗城",
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
