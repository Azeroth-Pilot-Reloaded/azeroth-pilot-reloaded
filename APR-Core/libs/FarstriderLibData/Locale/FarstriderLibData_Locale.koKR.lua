-- Navigation labels for koKR; English supplies missing-key fallbacks.
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end
if GetLocale() ~= "koKR" then return end

FarstriderLibData.L = setmetatable({
    ["ForeverPort_Auberdine"] = "아우버다인",
    ["ForeverPort_BootyBay"] = "무법항",
    ["ForeverPort_Dalaran"] = "달라란",
    ["ForeverPort_Feathermoon"] = "페더문 요새",
    ["ForeverPort_ForgottenCoast"] = "잊혀진 해안",
    ["ForeverPort_Menethil"] = "메네실 항구",
    ["ForeverPort_Powderfuse"] = "Powderfuse 항구",
    ["ForeverPort_Ratchet"] = "톱니항",
    ["ForeverPort_Ruttheran"] = "루테란 마을",
    ["ForeverPort_Skywatcher"] = "Skywatcher 고원",
    ["ForeverPort_Southshore"] = "사우스쇼어",
    ["ForeverPort_Steamwheedle"] = "스팀휘들 항구",
    ["ForeverPort_Stormwind"] = "스톰윈드",
    ["ForeverPort_Theramore"] = "테라모어 섬",
    ["ForeverPort_Valanaar"] = "발라나르",
    ["ForeverPort_Zephras"] = "제프라스 섬",
    ["ForeverPort_Gromgol"] = "그롬골 주둔지",
    ["ForeverPort_Orgrimmar"] = "오그리마",
    ["ForeverPort_Undercity"] = "언더시티",
    ["Unknown Location"] = "알 수 없는 위치",
    ["Waypoint_1000"] = "목적지에 도착하세요",
    ["Waypoint_1001"] = "비행 조련사와 대화하여 %s 지역으로 이동하세요",
    ["Waypoint_1002"] = "%s 지역으로 가는 차원문을 이용하세요",
    ["Waypoint_1003"] = "%s에서 %s 지역으로 가는 배를 타세요",
    ["Waypoint_1004"] = "%s에서 %s 지역으로 가는 비행선을 타세요",
    ["Waypoint_1005"] = "%s 사용 후 %s 지역으로 이동하세요",
    ["Waypoint_1006"] = "%s 시전 후 %s 지역으로 이동하세요",
    ["Unknown Item"] = "알 수 없는 아이템",
    ["Unknown Spell"] = "알 수 없는 주문",
}, { __index = FarstriderLibData.L })
