-- Navigation labels for zhTW; English supplies missing-key fallbacks.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
if GetLocale() ~= "zhTW" then return end

FarstriderLibData.L = setmetatable({
    ["ForeverPort_Auberdine"] = "奧伯丁",
    ["ForeverPort_BootyBay"] = "藏寶海灣",
    ["ForeverPort_Dalaran"] = "達拉然",
    ["ForeverPort_Feathermoon"] = "羽月要塞",
    ["ForeverPort_ForgottenCoast"] = "被遺忘的海岸",
    ["ForeverPort_Menethil"] = "米奈希爾港",
    ["ForeverPort_Powderfuse"] = "Powderfuse港",
    ["ForeverPort_Ratchet"] = "棘齒城",
    ["ForeverPort_Ruttheran"] = "魯瑟蘭村",
    ["ForeverPort_Skywatcher"] = "Skywatcher高地",
    ["ForeverPort_Southshore"] = "南海鎮",
    ["ForeverPort_Steamwheedle"] = "熱砂港",
    ["ForeverPort_Stormwind"] = "暴風城",
    ["ForeverPort_Theramore"] = "塞拉摩島",
    ["ForeverPort_Valanaar"] = "瓦拉納爾",
    ["ForeverPort_Zephras"] = "澤弗拉斯島",
    ["ForeverPort_Gromgol"] = "格羅姆高營地",
    ["ForeverPort_Orgrimmar"] = "奧格瑪",
    ["ForeverPort_Undercity"] = "幽暗城",
    ["Unknown Location"] = "未知位置",
    ["Waypoint_1000"] = "到達目的地",
    ["Waypoint_1001"] = "與飛行管理員對話前往%s",
    ["Waypoint_1002"] = "傳送到%s",
    ["Waypoint_1003"] = "從%s搭船到%s",
    ["Waypoint_1004"] = "從%s搭飛船到%s",
    ["Waypoint_1005"] = "使用%s到%s",
    ["Waypoint_1006"] = "施放%s到%s",
    ["Unknown Item"] = "未知物品",
    ["Unknown Spell"] = "未知法術",
}, { __index = FarstriderLibData.L })
