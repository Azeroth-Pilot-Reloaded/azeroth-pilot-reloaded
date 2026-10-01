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

-- Profession slots are authoritative on Forever and Retail; only the first two count.
local first, second
GetProfessions = function() return first, second, 3, 4, 5 end
GetNumSkillLines = unexpectedLegacy
assert(APR:GetPrimaryProfessionCount() == 0, "Secondary professions must not count")
first = 1
assert(APR:GetPrimaryProfessionCount() == 1)
second = 2
assert(APR:GetPrimaryProfessionCount() == 2)
first = nil
assert(APR:GetPrimaryProfessionCount() == 1, "A nil first slot must not hide the second")
GetProfessions = nil

-- The skill-line fallback is independent of locale and collapsed UI headers.
local learned = { [171] = 1, [333] = 75, [185] = 100, [129] = 50, [356] = 20, [762] = 75 }
C_SkillInfo = { GetSkillLineInfoByID = function(id)
    if learned[id] then return { skillID = id, name = "Localized", isHeader = false, rank = learned[id] } end
end }
assert(APR:GetPrimaryProfessionCount() == 2, "Secondary skills and riding must be excluded")
learned[333] = 0
assert(APR:GetPrimaryProfessionCount() == 1, "Unlearned skills must not count")
learned[171] = nil
assert(APR:GetPrimaryProfessionCount() == 0)
learned[755], learned[773] = 1, 1
assert(APR:GetPrimaryProfessionCount() == 2, "Jewelcrafting and Inscription are primary professions")
C_SkillInfo = nil
GetNumSkillLines = function() return 2 end
GetSkillLineInfo = function(index)
    local id = index == 1 and 171 or 185
    return "Localized", false, false, 1, 0, 0, 75, nil, nil, nil, nil, nil, id
end
assert(APR:GetPrimaryProfessionCount() == 1, "Legacy skill lines only count primary professions")
GetNumSkillLines, GetSkillLineInfo = nil, nil
assert(APR:GetPrimaryProfessionCount() == 0)
print("Skills: modern tables, collapsed headers, API priority and legacy fallbacks passed")
