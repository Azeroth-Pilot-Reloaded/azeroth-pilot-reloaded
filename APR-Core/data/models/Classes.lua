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

function APR:GetClassNameById(id)
    for className, classId in pairs(APR.Classes) do
        if classId == id then
            return className
        end
    end
    return nil
end
