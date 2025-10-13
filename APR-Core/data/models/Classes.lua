APR.Classes = {
    Warrior = 1,
    Paladin = 2,
    Hunter = 3,
    Rogue = 4,
    Priest = 5,
    ["Death Knight"] = 6,
    Shaman = 7,
    Mage = 8,
    Warlock = 9,
    Monk = 10,
    Druid = 11,
    ["Demon Hunter"] = 12,
    Evoker = 13,
}

APR.Specs = {
    ["Mage - Arcane"] = 62,
    ["Mage - Fire"] = 63,
    ["Mage - Frost"] = 64,
    ["Paladin - Holy"] = 65,
    ["Paladin - Protection"] = 66,
    ["Paladin - Retribution"] = 70,
    ["Warrior - Arms"] = 71,
    ["Warrior - Fury"] = 72,
    ["Warrior - Protection"] = 73,
    ["Druid - Balance"] = 102,
    ["Druid - Feral"] = 103,
    ["Druid - Guardian"] = 104,
    ["Druid - Restoration"] = 105,
    ["Death Knight - Blood"] = 250,
    ["Death Knight - Frost"] = 251,
    ["Death Knight - Unholy"] = 252,
    ["Hunter -Beast Mastery"] = 253,
    ["Hunter - Marksmanship"] = 254,
    ["Hunter - Survival"] = 255,
    ["Priest - Discipline"] = 256,
    ["Priest - Holy"] = 257,
    ["Priest - Shadow"] = 258,
    ["Rogue - Assassination"] = 259,
    ["Rogue - Outlaw"] = 260,
    ["Rogue - Subtlety"] = 261,
    ["Shaman - Elemental"] = 262,
    ["Shaman - Enhancement"] = 263,
    ["Shaman - Restoration"] = 264,
    ["Warlock - Affliction"] = 265,
    ["Warlock - Demonology"] = 266,
    ["Warlock - Destruction"] = 267,
    ["Monk - Brewmaster"] = 268,
    ["Monk - Windwalker"] = 269,
    ["Monk - Mistweaver"] = 270,
    ["Demon Hunter - Havoc"] = 577,
    ["Demon Hunter - Vengeance"] = 581,
    ["Evoker - Devastation"] = 1467,
    ["Evoker - Preservation"] = 1468,
    ["Evoker - Augmentation"] = 1473,
    ["Adventurer"] = 1478
}


function APR:GetClassNameById(id)
    for className, classId in pairs(APR.Classes) do
        if classId == id then
            return className
        end
    end
    return nil
end

function APR:GetClassSpecName()
    local id = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())

    for classSpecName, classSpecId in pairs(APR.Specs) do
        if classSpecId == id then
            return classSpecName
        end
    end
    return nil
end
