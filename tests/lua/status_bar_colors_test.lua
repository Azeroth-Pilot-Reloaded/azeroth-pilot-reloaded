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
print("PASS: all native bars share creation, live option colors, independent AFK colors, Love startup, pink fills and preserved alpha")
