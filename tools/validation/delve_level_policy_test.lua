-- The policy is empirical, and counts the event only while an aura is active.
local auras, achievements, reads = {}, {}, 0
C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
    reads = reads + 1
    return auras[id]
end }
function LibStub() return { GetLocale = function() return { GRIND = "Reach level %d", USE_ITEM = "Use %s" } end } end
APR = {}
function APR:HasAura(id) reads = reads + 1; return auras[id] end
function APR:HasAchievement(id) reads = reads + 1; return achievements[id] end
local level, xp = 87, 0
local warMode = false
C_PvP = { IsWarModeActive = function() reads = reads + 1; return warMode end }
function UnitLevel() return level end
function UnitXP() return xp end
function UnitXPMax() return 1000 end
C_Map = { GetBestMapForUnit = function() return 2413 end }
dofile("APR-Core/config/LevelProfiles.lua")
dofile("APR-Core/utils/RouteUtils.lua")
local targets = { 89, 88.75, 88.5, 88.25, 88, 87.75 }
local eventTargets = { 88, 87.75, 87.5, 87.25, 87, 86.75 }
for tier = 0, 5 do
    achievements = {}
    for n = 1, tier do achievements[42327 + n] = true end
    for _, eventAura in ipairs({ 0, 1287282, 1214848 }) do
        auras = { [430191] = tier > 0 }
        if eventAura ~= 0 then auras[eventAura] = true end
        local expected = (eventAura ~= 0 and eventTargets or targets)[tier + 1]
        assert(APR:GetLevelProfileTarget("MidnightDelves", true) == expected, "Unexpected bonus tier")
        local before = reads
        for _ = 1, 1200 do APR:ResolveLevelRequirement("MidnightDelves") end
        assert(reads == before, "Long routes reuse the policy without scanning auras per row")
    end
end
auras = { [430191] = true, [1214848] = true, [1287282] = true }
achievements = { [42328] = true }
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 87.75, "Both event IDs still grant only 20%")
assert(APR:GetGrindStepText("MidnightDelves") == "Reach level 87 + 75% XP")
assert(APR:GetGrindStepText(90) == "Reach level 90")
xp = 749
assert(not APR:AreConditionalFiltersMet({ MinLevel = "MidnightDelves" }))
assert(APR:AreConditionalFiltersMet({ SkipForLvl = "MidnightDelves" }))
xp = 750
assert(APR:AreConditionalFiltersMet({ MinLevel = "MidnightDelves" }))
assert(not APR:AreConditionalFiltersMet({ SkipForLvl = "MidnightDelves" }))
local updates, lists = 0, 0
APR.ActiveRoute = "test"
function APR:UpdateStep() updates = updates + 1 end
APR.questOrderList = { DelayedUpdate = function(_, force) assert(force); lists = lists + 1 end }
auras[1214848], auras[1287282] = nil, nil
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 88.75 and updates == 1 and lists == 1,
    "Event expiry raises the target and refreshes the guide")
assert(not APR:AreConditionalFiltersMet({ MinLevel = "MidnightDelves" }))
for _ = 1, 100 do APR:RefreshLevelProfileTargets() end
assert(updates == 1 and lists == 1, "Unrelated aura changes do not rebuild the guide")
auras[430191] = nil
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 89, "An inactive mentor aura grants no bonus")
assert(APR:ResolveLevelRequirement(88) == 88 and APR:ResolveLevelRequirement(nil) == nil)
print("Delve thresholds: all mentorship/event tiers, aura expiry, exact XP boundaries and cached reads passed")

-- Another route can choose unrelated levels and sources without changing the engine.
APR.LevelBonusSources.OtherEvent = { auras = { 123 }, bonus = 12 }
APR.LevelRequirementProfiles.OtherRoute = {
    bonuses = { "OtherEvent", "OtherEvent" },
    levels = { [0] = 70, [10] = 69.5, [20] = 69 },
}
auras = { [123] = true }
assert(APR:ResolveLevelRequirement("OtherRoute") == 69.5,
    "Select the lower breakpoint and do not double-count duplicate sources")
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 89, "Profiles use only their configured bonuses")
APR.LevelRequirementProfiles.FixedRoute = { levels = { [0] = 60 } }
assert(APR:ResolveLevelRequirement("FixedRoute") == 60, "A profile may omit bonus sources")
local ok = pcall(APR.ResolveLevelRequirement, APR, "MisspelledProfile")
assert(not ok, "Unknown names must not silently disable a level gate")
auras = { [430191] = true, [1287282] = true }
updates, lists = 0, 0
APR:RefreshLevelProfileTargets()
assert(updates == 1 and lists == 1, "Multiple changed profiles trigger a single guide refresh")
assert(APR:ResolveLevelRequirement("OtherRoute") == 70)
assert(APR:ResolveLevelRequirement("MidnightDelves") == 87.75)
print("Level profiles: independent configuration, breakpoints, duplicate sources, unknown names and batched refresh passed")

-- Both mentorship sources may be listed; their disjoint level ranges prevent stacking.
APR.LevelRequirementProfiles.AllLevelMentorship = {
    bonuses = { "Below80Mentorship", "MidnightMentorship" },
    levels = { [0] = 90, [5] = 89, [10] = 88, [15] = 87, [20] = 86, [25] = 85 },
}
local legacyIDs = { 19470, 19460, 19475, 19476, 19477 }
auras = { [430191] = true }
for tier = 1, 5 do
    achievements = { [42332] = true }
    for n = 1, tier do achievements[legacyIDs[n]] = true end
    level = 79
    assert(APR:GetLevelProfileTarget("AllLevelMentorship", true) == 90 - tier,
        "Below 80 only the legacy achievement tier applies")
end
achievements = { [19477] = true, [42328] = true }
level = 79
assert(APR:GetLevelProfileTarget("AllLevelMentorship", true) == 85)
level = 80
assert(APR:GetLevelProfileTarget("AllLevelMentorship") == 89,
    "Reaching 80 invalidates the cache and selects the Midnight tier")
level = 89
assert(APR:GetLevelProfileTarget("AllLevelMentorship") == 89)
level = 90
assert(APR:GetLevelProfileTarget("AllLevelMentorship") == 90,
    "Neither mentorship source grants XP beyond its level cap")
level = 79
auras = {}
assert(APR:GetLevelProfileTarget("AllLevelMentorship") == 90, "Achievements alone do not activate mentorship")
print("Mentorship ranges: five legacy tiers, boundaries 79/80/89/90, no double-counting and level-aware cache passed")

-- Check every War Mode combination, including extrapolated seasonal targets.
level = 87
warMode = true
local warTargets = { 88.25, 88, 87.75, 87.5, 87.25, 87 }
local bothTargets = { 87.25, 87, 86.75, 86.5, 86.25, 86 }
for tier = 0, 5 do
    achievements = {}
    for n = 1, tier do achievements[42327 + n] = true end
    for _, eventAura in ipairs({ 0, 1287282, 1214848 }) do
        auras = { [430191] = tier > 0 }
        if eventAura ~= 0 then auras[eventAura] = true end
        local expected = (eventAura ~= 0 and bothTargets or warTargets)[tier + 1]
        assert(APR:GetLevelProfileTarget("MidnightDelves", true) == expected)
        local before = reads
        for _ = 1, 1200 do APR:ResolveLevelRequirement("MidnightDelves") end
        assert(reads == before, "War Mode checks are cached too")
    end
end
auras = { [430191] = true }
achievements = { [42332] = true }
APR:RefreshLevelProfileTargets()
updates, lists = 0, 0
warMode = false
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 87.75 and updates == 1 and lists == 1)
warMode = true
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 87 and updates == 2 and lists == 2)
APR:RefreshLevelProfileTargets()
assert(updates == 2 and lists == 2, "Unchanged War Mode events do not rebuild the guide")
print("War Mode: corrected anchors, all tiers, seasonal extrapolation, cache and activation/deactivation passed")

-- Timeways variants form one source, including Knowledge's stack progression.
warMode = false
achievements = {}
for _, id in ipairs({ 1269517, 423860 }) do
    for stacks, expected in ipairs({ 88.75, 88.5, 88.25, 87.5 }) do
        auras = { [id] = { applications = stacks } }
        assert(APR:GetLevelProfileTarget("MidnightDelves", true) == expected)
    end
    auras = { [id] = { applications = 0 } }
    assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 88.75)
end
for _, id in ipairs({ 1269518, 1229050, 423861 }) do
    auras = { [id] = { applications = 0 }, [1269517] = { applications = 3 } }
    assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 87.5,
        "Mastery replaces Knowledge rather than adding to it")
end
auras = { [1269517] = { applications = 2 }, [423860] = { applications = 3 } }
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 88.25,
    "Knowledge variants use the highest stack bonus")
auras[1269518], auras[1229050], auras[423861] = {}, {}, {}
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 87.5,
    "Mastery variants do not stack")
auras[430191], auras[1287282], auras[1214848] = true, true, true
achievements[42332] = true
warMode = true
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 84.5,
    "The table covers the maximum configured 90% total bonus")
local before = reads
for _ = 1, 1200 do APR:ResolveLevelRequirement("MidnightDelves") end
assert(reads == before, "Timeways stacks are cached across route rows")
warMode = false
achievements = {}
auras = { [1269517] = { applications = 1 } }
APR:RefreshLevelProfileTargets()
updates, lists = 0, 0
auras[1269517].applications = 2
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 88.5 and updates == 1 and lists == 1)
auras = { [1269518] = {} }
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 87.5 and updates == 2 and lists == 2)
auras = {}
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 89 and updates == 3 and lists == 3)
print("Timeways: stacks, variants, replacement, combined maximum, caching and expiry passed")

-- Consumables count only after use and reminders never count items in a bank.
function GetMaxLevelForPlayerExpansion() return 90 end
local bags, unusable = {}, {}
C_Item = {
    GetItemCount = function(id, bank, uses, reagents, account)
        assert(bank == false and uses == false and reagents == false and account == false)
        return bags[id] or 0
    end,
    IsUsableItem = function(id) return not unusable[id] end,
    GetItemInfo = function(id) return "Item " .. id end,
}
auras, achievements, warMode, level = {}, {}, false, 87
bags[239142] = 2
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 89, "Inventory is not an active XP bonus")
assert(APR:GetLevelConsumableReminders("MidnightDelves")[1] == 239142)
auras[1221184] = true
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 88.5)
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 0)
bags[93730], bags[171364] = 1, 1
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 1, "Only one hat variant is suggested")
auras[46668], auras[136583] = true, true
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 88, "Hat and WHEE do not stack")
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 0, "WHEE suppresses hat reminders")
auras = {}
unusable[93730], unusable[171364] = true, true
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 1, "Unusable event items are not suggested")
bags = {}
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 0)
APR.LevelRequirementProfiles.LowRoute = { bonuses = { "TenLands" }, levels = { [0] = 49, [10] = 48 } }
bags[166750], bags[166751] = 1, 1
level = 49
assert(#APR:GetLevelConsumableReminders("LowRoute") == 1)
level = 50
assert(#APR:GetLevelConsumableReminders("LowRoute") == 0)
auras[289982] = true
assert(APR:GetLevelProfileTarget("LowRoute", true) == 49, "Ten Lands XP excluded at 50")
level = 90
bags[239142] = 1
assert(#APR:GetLevelConsumableReminders("MidnightDelves") == 0, "No consumable reminders at level cap")

-- Reminder changes update only the current display; unchanged events do nothing.
level, auras, bags = 87, {}, {}
APR:RefreshLevelProfileTargets()
APR.PlayerID = "player"
APRData = { player = { test = 1 } }
APR.RouteQuestStepList = { test = { XPConsumables = "MidnightDelves" } }
local activeStep = {}
function APR:GetStep() return activeStep end
updates, lists = 0, 0
bags[239142] = 1
APR:RefreshLevelProfileTargets()
assert(updates == 1 and lists == 0)
for _ = 1, 100 do APR:RefreshLevelProfileTargets() end
assert(updates == 1 and lists == 0, "Unchanged inventory does not rebuild the guide")
local rows, buttons = {}, {}
APR.currentStep = {
    AddQuestSteps = function(_, id, text, objective, _, noTooltip)
        assert(noTooltip)
        rows[id .. "-" .. objective] = text
    end,
    AddStepButton = function(_, key, id, kind)
        assert(rows[key] and kind == "item")
        buttons[id] = true
    end,
}
APR:ShowLevelConsumableReminders(activeStep)
assert(buttons[239142], "Reminder uses the existing item button")
activeStep.XPConsumables = false
APR:RefreshLevelProfileTargets()
assert(updates == 2 and lists == 0)
assert(APR:GetActiveLevelConsumableProfile(activeStep) == false)
activeStep.XPConsumables = nil
auras[1221184] = true
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelProfileTarget("MidnightDelves") == 88.5)
auras[1221184] = nil
APR:RefreshLevelProfileTargets()
assert(APR:GetLevelConsumableReminders("MidnightDelves")[1] == 239142, "Expiry re-enables the reminder")
auras = { [430191] = true, [1287282] = true, [1269518] = {}, [1221184] = true, [136583] = true }
achievements, warMode = { [42332] = true }, true
assert(APR:GetLevelProfileTarget("MidnightDelves", true) == 83.5, "Maximum configured bonus is 110%")
print("XP consumables: active bonuses, bag-only reminders, variants, levels, expiry, buttons and coalesced refresh passed")
