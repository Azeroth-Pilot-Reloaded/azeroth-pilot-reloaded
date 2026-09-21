local skills = { alchemy = 171, blacksmithing = 164, cooking = 185, enchanting = 333,
    engineering = 202, firstaid = 129, fishing = 356, herbalism = 182, leatherworking = 165,
    mining = 186, skinning = 393, tailoring = 197, riding = 762 }
local skillSpells = { alchemy = 2259, blacksmithing = 2018, cooking = 2550, enchanting = 7411,
    engineering = 4036, firstaid = 3273, fishing = 7620, herbalism = 9134, leatherworking = 2108,
    mining = 2575, skinning = 8613, tailoring = 3908, riding = 33388 }

function APR:GetRouteSkill(requirement)
    local wanted = tonumber(requirement.skillID) or tonumber(requirement.skill) or skills[requirement.skill]
    local wantedName = requirement.name
    local spellID = skillSpells[requirement.skill]
    if wanted and not spellID then
        for key, id in pairs(skills) do if id == wanted then spellID = skillSpells[key]; break end end
    end
    if spellID then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        wantedName = wantedName or (info and info.name) or (GetSpellInfo and GetSpellInfo(spellID))
    end
    for i = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
        local name, header, _, rank, _, _, maximum, _, _, _, _, _, id = GetSkillLineInfo(i)
        if not header and ((wanted and id == wanted) or (wantedName and name == wantedName)
            or (name and requirement.skill and name:lower():gsub("%s", "") == requirement.skill)) then
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

function APR:MeetsExtendedRouteConditions(c)
    if c.AllOf then for _, v in ipairs(c.AllOf) do if not self:AreConditionalFiltersMet(v) then return false end end end
    if c.Not and self:AreConditionalFiltersMet(c.Not) then return false end
    if c.Skill and not self:CompareRouteNumber(self:GetRouteSkill(c.Skill), c.Skill.operator or ">=", c.Skill.rank or 1) then return false end
    if c.EquippedItem then
        local r = c.EquippedItem
        local id = GetInventoryItemID("player", r.slot)
        local matches = r.itemID and id == r.itemID or not r.itemID and id ~= nil
        if r.invert then matches = not matches end
        if not matches then return false end
    end
    if c.Collection and not self:IsRouteCollectionComplete(c.Collection) then return false end
    return true
end
