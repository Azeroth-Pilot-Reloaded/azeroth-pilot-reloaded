-- Normalizes client skill APIs and evaluates nested skill/equipment/collection route conditions.
-- The same predicates feed route execution and the quest-order preview.

local skills = {
    alchemy = 171,
    blacksmithing = 164,
    cooking = 185,
    enchanting = 333,
    engineering = 202,
    firstaid = 129,
    fishing = 356,
    herbalism = 182,
    leatherworking = 165,
    mining = 186,
    skinning = 393,
    tailoring = 197,
    riding = 762
}
local skillSpells = {
    alchemy = 2259,
    blacksmithing = 2018,
    cooking = 2550,
    enchanting = 7411,
    engineering = 4036,
    firstaid = 3273,
    fishing = 7620,
    herbalism = 9134,
    leatherworking = 2108,
    mining = 2575,
    skinning = 8613,
    tailoring = 3908,
    riding = 33388
}

function APR:GetRouteSkill(requirement)
    local wanted = tonumber(requirement.skillID) or tonumber(requirement.skill) or skills[requirement.skill]
    local wantedName = requirement.name
    local spellID = skillSpells[requirement.skill]
    if wanted and not spellID then
        for key, id in pairs(skills) do
            if id == wanted then
                spellID = skillSpells[key]; break
            end
        end
    end
    if spellID then
        wantedName = wantedName or self:GetSpellName(spellID)
    end
    local function Matches(name, id)
        return (wanted and id == wanted) or (wantedName and name == wantedName)
            or (name and requirement.skill and name:lower():gsub("%s", "") == requirement.skill)
    end

    -- Forever exposes structured skill data, including skills in collapsed headers.
    if C_SkillInfo then
        if wanted and C_SkillInfo.GetSkillLineInfoByID then
            local info = C_SkillInfo.GetSkillLineInfoByID(wanted)
            return info and not info.isHeader and (requirement.maximum and info.maxRank or info.rank) or 0
        end
        if C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo then
            for i = 1, C_SkillInfo.GetNumSkillLines() do
                local info = C_SkillInfo.GetSkillLineInfo(i)
                if info and not info.isHeader and Matches(info.name, info.skillID) then
                    return requirement.maximum and info.maxRank or info.rank
                end
            end
            return 0
        end
    end
    for i = 1, (GetNumSkillLines and GetSkillLineInfo and GetNumSkillLines() or 0) do
        local name, header, _, rank, _, _, maximum, _, _, _, _, _, id = GetSkillLineInfo(i)
        if not header and Matches(name, id) then
            return requirement.maximum and maximum or rank
        end
    end
    if GetProfessions and GetProfessionInfo then
        local indices = { GetProfessions() }
        for _, index in pairs(indices) do
            local name, _, rank, maximum, _, _, id = GetProfessionInfo(index)
            if (wanted and id == wanted) or (wantedName and name == wantedName) then
                return requirement.maximum and maximum or rank
            end
        end
    end
    return 0
end

--- Count learned primary professions, excluding every secondary skill.
function APR:GetPrimaryProfessionCount()
    if GetProfessions then
        local first, second = GetProfessions()
        return (first and 1 or 0) + (second and 1 or 0)
    end

    -- Older clients expose skill lines rather than profession slots.
    local count = 0
    for _, skillID in ipairs({ 164, 165, 171, 182, 186, 197, 202, 333, 393, 755, 773 }) do
        if self:GetRouteSkill({ skillID = skillID }) > 0 then count = count + 1 end
    end
    return count
end

-- Nested conditions use the full predicate set, exactly like top-level step filters.
function APR:MeetsExtendedRouteConditions(conditions)
    for _, required in ipairs(conditions.AllOf or {}) do
        if not self:AreConditionalFiltersMet(required) then return false end
    end
    if conditions.Not and self:AreConditionalFiltersMet(conditions.Not) then return false end

    local skill = conditions.Skill
    if skill and not self:CompareRouteNumber(self:GetRouteSkill(skill), skill.operator or ">=", skill.rank or 1) then
        return false
    end
    local professionLimit = conditions.SkipForPrimaryProfessions
    if professionLimit and self:GetPrimaryProfessionCount() >= professionLimit then return false end
    if conditions.EquippedItem and not self:MeetsEquippedItem(conditions.EquippedItem) then return false end
    if conditions.Collection and not self:IsRouteCollectionComplete(conditions.Collection) then return false end
    return true
end
