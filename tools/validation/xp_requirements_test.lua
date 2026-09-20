-- Absolute XP offsets use this client's XP total, without assuming a Classic XP table.
local level, xp, maxXP = 2, 0, 900
local L = { GRIND = "Reach level %d" }
function LibStub() return { GetLocale = function() return L end } end
function UnitLevel() return level end
function UnitXP() return xp end
function UnitXPMax() return maxXP end
APR = {}
C_Map = { GetBestMapForUnit = function() return 1411 end }
dofile("APR-Core/utils/RouteUtils.lua")
local intoLevel = { level = 3, xp = 325 }
local beforeLevel = { level = 4, xp = -700 }
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(intoLevel))
level, xp, maxXP = 3, 324, 1400
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(intoLevel))
assert(not APR:AreConditionalFiltersMet({ MinLevel = intoLevel }))
assert(APR:AreConditionalFiltersMet({ SkipForLvl = intoLevel }))
xp = 325
assert(APR:GetPlayerEffectiveLevel() == APR:ResolveLevelRequirement(intoLevel))
assert(APR:AreConditionalFiltersMet({ MinLevel = intoLevel }))
assert(not APR:AreConditionalFiltersMet({ SkipForLvl = intoLevel }))
xp = 699
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(beforeLevel))
xp = 700
assert(APR:GetPlayerEffectiveLevel() == APR:ResolveLevelRequirement(beforeLevel))
-- A different server XP table must preserve the absolute offset, not a fixed percentage.
xp, maxXP = 1299, 2000
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(beforeLevel))
xp = 1300
assert(APR:GetPlayerEffectiveLevel() == APR:ResolveLevelRequirement(beforeLevel))
level, xp, maxXP = 4, 0, 2100
assert(APR:GetPlayerEffectiveLevel() >= APR:ResolveLevelRequirement(intoLevel))
assert(APR:GetPlayerEffectiveLevel() >= APR:ResolveLevelRequirement(beforeLevel))
level, xp, maxXP = 3, 0, 0
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(intoLevel))
assert(APR:GetPlayerEffectiveLevel() < APR:ResolveLevelRequirement(beforeLevel))
assert(APR:GetGrindStepText(intoLevel) == "Reach level 3 + 325 XP")
assert(APR:GetGrindStepText(beforeLevel) == "Reach level 4 - 700 XP")
assert(APR:ResolveLevelRequirement(3.5) == 3.5)
assert(not pcall(APR.ResolveLevelRequirement, APR, { level = 3.5, xp = 1 }))
assert(not pcall(APR.ResolveLevelRequirement, APR, { level = 3 }))
print("Absolute XP: exact boundaries, client XP totals, filters, level-up and missing XP data passed")
