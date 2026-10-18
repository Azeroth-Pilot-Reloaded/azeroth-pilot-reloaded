local env = dofile("tests/lua/route_ui_test_env.lua")
local step = APR.currentStep
APR.Color.orange, APR.Color.yellow, APR.Color.pink = { 1, 0.6, 0.1 }, { 1, 1, 0 }, { 1, 0.3, 0.7 }
APR.settings.profile.currentStepProgressBarColor = { 0.2, 0.4, 0.6, 0.35 }
APR.settings.profile.afkBarColor = { 0.8, 0.5, 0.2, 0.7 }
function APR:GetQuestObjectiveProgressPercent() return 45 end

local function render()
    step:ProgressBar("route", 100, 25)
    step:AddQuestSteps(1, "First objective", 1)
    step:AddQuestSteps(2, "Second objective", 1)
    step:AddQuestSteps("REPUTATION", "Standing", "Reputation", false, true)
    step:AddObjectiveProgressBar(step.questsList["REPUTATION-Reputation"], "reputationBar", 20, 100, "20%")
    step:AddQuestSteps("LOOT_MONEY", "Coins", "LootMoney", false, true)
    step:AddObjectiveProgressBar(step.questsList["LOOT_MONEY-LootMoney"], "lootMoneyBar", 30, 100, "30%")
end
render()
local guideBars = { step.progressBar, step.questsList["1-1"].questProgressBar,
    step.questsList["2-1"].questProgressBar, step.reputationBar, step.lootMoneyBar }
local afk = APR:CreateStatusBar(UIParent, nil, "afk", "afkBarColor")
local foreign = CreateFrame("StatusBar", nil, UIParent)
foreign:SetStatusBarColor(0, 1, 0, 1)
local function checkColor(bar, color)
    for index = 1, 4 do assert(bar.color[index] == color[index], "Unexpected bar color component " .. index) end
end
for _, bar in ipairs(guideBars) do checkColor(bar, APR.settings.profile.currentStepProgressBarColor) end
checkColor(afk, APR.settings.profile.afkBarColor)
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 100 do render() end
assert(env.frames() == frames and env.fonts() == fonts, "Shared creation preserves native bar reuse")

-- The existing option setter must update every live objective, not just the header.
APR.settings.profile.currentStepProgressBarColor = { 0.9, 0.1, 0.2, 0.45 }
step:UpdateProgressBarColor()
for _, bar in ipairs(guideBars) do checkColor(bar, APR.settings.profile.currentStepProgressBarColor) end
checkColor(afk, { 0.8, 0.5, 0.2, 0.7 })
afk:Hide()
APR.settings.profile.afkBarColor = { 0.1, 0.8, 0.3, 0.6 }
APR:RefreshStatusBarColors("afkBarColor")
checkColor(afk, APR.settings.profile.afkBarColor)
checkColor(foreign, { 0, 1, 0, 1 })

-- Exercise the actual Love lifecycle before settings exist and after they load.
dofile("APR-Core/utils/UIUtils.lua")
local date = { month = 10, monthDay = 3 }
C_DateAndTime = { GetCurrentCalendarTime = function() return date end }
APR:Love()
assert(not APR.loveColorsPending)
checkColor(guideBars[1], { 0.9, 0.1, 0.2, 0.45 })
local profile = APR.settings.profile
APR.settings.profile = nil
date = { month = 2, monthDay = 14 }
APR:Love()
assert(APR.loveColorsPending and APR.Color.blue == APR.Color.pink and APR.Color.yellow == APR.Color.pink)
APR.settings.profile = profile
APR:ApplyLoveColors()
assert(not APR.loveColorsPending)
for _, bar in ipairs(guideBars) do checkColor(bar, { 1, 0.3, 0.7, 0.45 }) end
checkColor(afk, { 1, 0.3, 0.7, 0.6 })
checkColor(foreign, { 0, 1, 0, 1 })
local later = APR:CreateStatusBar(UIParent)
checkColor(later, { 1, 0.3, 0.7, 0.45 })
APR:ApplyLoveColors()
checkColor(later, { 1, 0.3, 0.7, 0.45 })

-- Ordinary options still work after Love has applied its seasonal palette.
profile.currentStepProgressBarColor = { 0.4, 0.5, 0.6, 0.25 }
step:UpdateProgressBarColor()
checkColor(later, { 0.4, 0.5, 0.6, 0.25 })
for _, bar in ipairs(guideBars) do checkColor(bar, { 0.4, 0.5, 0.6, 0.25 }) end
-- Full class themes override explicit and legacy RGB on every registered APR bar.
dofile("APR-Core/integrations/SkinRegistry.lua")
function UnitClass() return "Mage", "MAGE" end
RAID_CLASS_COLORS = {MAGE = {r = 0.25, g = 0.78, b = 0.92}}
profile.uiTheme = "modern"
profile.uiThemeCustomization = {classColor = true}
profile.afkBarColorCustom = true
profile.currentStepProgressBarColorCustom = true
local savedAFK, savedGuide = profile.afkBarColor, profile.currentStepProgressBarColor
APR:RefreshStatusBarColors()
for _, bar in ipairs(guideBars) do checkColor(bar, {0.25, 0.78, 0.92, 0.25}) end
checkColor(afk, {0.25, 0.78, 0.92, 0.6})
checkColor(foreign, {0, 1, 0, 1})
local classBar = APR:CreateStatusBar(UIParent, nil, "afk", "afkBarColor")
checkColor(classBar, {0.25, 0.78, 0.92, 0.6})
render()
for _, bar in ipairs(guideBars) do checkColor(bar, {0.25, 0.78, 0.92, 0.25}) end
assert(profile.afkBarColor == savedAFK and profile.currentStepProgressBarColor == savedGuide,
    "Applying class fills never replaces saved colors")
profile.uiThemeCustomization.classColor = false
profile.globalTextAppearance = {accentClassColor = true}
APR:RefreshStatusBarColors()
for _, bar in ipairs(guideBars) do checkColor(bar, {0.25, 0.78, 0.92, 0.25}) end
checkColor(afk, {0.25, 0.78, 0.92, 0.6})
checkColor(classBar, {0.25, 0.78, 0.92, 0.6})
profile.uiTheme = "wow"
APR:RefreshStatusBarColors()
checkColor(afk, {0.25, 0.78, 0.92, 0.6})
assert(APR:GetStatusBarClassColor(), "Class text accents also color bars under Classic")
profile.globalTextAppearance.accentClassColor = false
APR:RefreshStatusBarColors()
for _, bar in ipairs(guideBars) do checkColor(bar, savedGuide) end
checkColor(afk, savedAFK)
checkColor(classBar, savedAFK)
assert(not APR:GetStatusBarClassColor(), "Disabling both class options restores saved fills")
profile.uiThemeCustomization.classColor = true
profile.uiTheme = "wow"
APR:RefreshStatusBarColors()
checkColor(afk, savedAFK)
assert(not APR:GetStatusBarClassColor(), "A dormant Modern class option cannot change Classic colors")
print("PASS: native bars, class themes and accents, existing/future/reused bars, alpha and saved color restore")
