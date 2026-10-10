-- FarstriderLibData_Locale.ruRU.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

if (GetLocale() ~= "ruRU") then
    return;
end

FarstriderLibData.L = {
    ["ForeverPort_Auberdine"] = "Аубердин",
    ["ForeverPort_BootyBay"] = "Пиратская Бухта",
    ["ForeverPort_Dalaran"] = "Даларан",
    ["ForeverPort_Feathermoon"] = "Крепость Оперенной Луны",
    ["ForeverPort_ForgottenCoast"] = "Забытый Берег",
    ["ForeverPort_Menethil"] = "Гавань Менетилов",
    ["ForeverPort_Powderfuse"] = "Порт Powderfuse",
    ["ForeverPort_Ratchet"] = "Кабестан",
    ["ForeverPort_Ruttheran"] = "Деревня Рут’теран",
    ["ForeverPort_Skywatcher"] = "Плато Skywatcher",
    ["ForeverPort_Southshore"] = "Южнобережье",
    ["ForeverPort_Steamwheedle"] = "Порт Картеля",
    ["ForeverPort_Stormwind"] = "Штормград",
    ["ForeverPort_Theramore"] = "Остров Терамор",
    ["ForeverPort_Valanaar"] = "Валанаар",
    ["ForeverPort_Zephras"] = "Остров Зефрас",
    ["ForeverPort_Gromgol"] = "Лагерь Гром’гол",
    ["ForeverPort_Orgrimmar"] = "Оргриммар",
    ["ForeverPort_Undercity"] = "Подгород",
    ["Unknown Location"] = "Неизвестное местоположение",
    ["Waypoint_1000"] = "Добраться до пункта назначения",
    ["Waypoint_1001"] = "Поговорите с распорядителем полётов, чтобы отправиться в %s",
    ["Waypoint_1002"] = "Возьмите портал в %s",
    ["Waypoint_1003"] = "Сядьте на корабль из %s в %s",
    ["Waypoint_1004"] = "Сядьте на дирижабль из %s в %s",
    ["Waypoint_1005"] = "Используйте %s для %s",
    ["Waypoint_1006"] = "Каст %s на %s",
};

setmetatable(FarstriderLibData.L, {
    __index = function(t, k)
        rawset(t, k, k); return k;
    end
})
