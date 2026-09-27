-- Exercise the structured Forever API, with legacy globals deliberately unavailable.
APR = {}
dofile("APR-Core/utils/RouteConditions.lua")
local info = { skillID = 185, name = "Cuisine", isHeader = false, rank = 75, maxRank = 150 }
local function unexpectedLegacy() error("Available C_ API must take priority") end
GetNumSkillLines, GetSkillLineInfo, GetProfessions, GetSpellInfo =
    unexpectedLegacy, unexpectedLegacy, unexpectedLegacy, unexpectedLegacy
C_Spell = { GetSpellInfo = function() return { name = "Cuisine" } end }
C_SkillInfo = {
    GetSkillLineInfoByID = function(id) if id == 185 then return info end end,
    GetNumSkillLines = function() return 3 end,
    GetSkillLineInfo = function(index)
        if index == 1 then return { name = "Cuisine", isHeader = true } end
        if index == 3 then return info end
    end,
}
assert(APR:GetRouteSkill({ skill = "cooking" }) == 75)
assert(APR:GetRouteSkill({ skillID = 185, maximum = true }) == 150)
assert(APR:GetRouteSkill({ skillID = 762 }) == 0)
assert(APR:GetRouteSkill({ name = "Cuisine" }) == 75)
-- A known ID can be resolved even when the corresponding UI header is collapsed.
C_SkillInfo.GetNumSkillLines = function() return 0 end
assert(APR:GetRouteSkill({ skill = "185" }) == 75)
C_SkillInfo.GetSkillLineInfoByID = nil
C_SkillInfo.GetNumSkillLines = function() return 3 end
assert(APR:GetRouteSkill({ skill = "cooking" }) == 75)
assert(APR:GetRouteSkill({ name = "Missing" }) == 0)
-- A missing modern spell result must not fall through to the removed global API.
C_Spell.GetSpellInfo = function() return nil end
assert(APR:GetRouteSkill({ skillID = 185 }) == 75)

C_SkillInfo = nil
GetNumSkillLines = function() return 1 end
GetSkillLineInfo = function() return "Cuisine", false, false, 25, 0, 0, 75, nil, nil, nil, nil, nil, 185 end
assert(APR:GetRouteSkill({ skillID = 185 }) == 25)
assert(APR:GetRouteSkill({ name = "Cuisine", maximum = true }) == 75)
GetNumSkillLines, GetSkillLineInfo = nil, nil
GetProfessions = function() return 1 end
GetProfessionInfo = function() return "Cuisine", nil, 50, 100, nil, nil, 185 end
assert(APR:GetRouteSkill({ skillID = 185 }) == 50)
GetProfessions, GetProfessionInfo = nil, nil
assert(APR:GetRouteSkill({ skillID = 185 }) == 0)
print("Skills: modern tables, collapsed headers, API priority and legacy fallbacks passed")
