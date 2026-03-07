local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.QUEST_STATUS = {
    COMPLETE = "COMPLETE",
    PROGRESS = "IN_PROGRESS",
}

APR.EXPANSIONS = {
    Vanilla = "Vanilla",
    TheBurningCrusade = "The Burning Crusade",
    WrathOfTheLichKing = "Wrath of the Lich King",
    Cataclysm = "Cataclysm",
    MistsOfPandaria = "Mists of Pandaria",
    WarlordsOfDraenor = "Warlords of Draenor",
    Legion = "Legion",
    BattleForAzeroth = "Battle for Azeroth",
    Shadowlands = "Shadowlands",
    Dragonflight = "Dragonflight",
    TheWarWithin = "The War Within",
    Midnight = "Midnight",
    Custom = "Custom",
}

APR.CATEGORIES = {
    Leveling = L["Leveling"],
    Sojourner = L["Sojourner"],
    Achievement = "ACHIEVEMENTS",
    AlliedRace = L["AlliedRace"],
    Professions = L["Professions"],
    Events = L["EVENTS"],
    Miscellaneous = "MISCELLANEOUS",
    Mount = "MOUNT",
    Pet = "PET",
    Toy = "TOY",
    Daily = "DAILY",
}


APR.EVENTS = {
    Holidays = "Holidays",
    Remix = "Remix",
}


APR.RACES = {
    -- Alliance
    Dwarf = "Dwarf",
    Gnome = "Gnome",
    Human = "Human",
    NightElf = "NightElf",
    Draenei = "Draenei",
    Worgen = "Worgen",
    LightforgedDraenei = "LightforgedDraenei",
    VoidElf = "VoidElf",
    DarkIronDwarf = "DarkIronDwarf",
    KulTiran = "KulTiran",
    Mechagnome = "Mechagnome",
    -- Horde
    Orc = "Orc",
    Scourge = "Scourge",
    Tauren = "Tauren",
    Troll = "Troll",
    BloodElf = "BloodElf",
    Goblin = "Goblin",
    HighmountainTauren = "HighmountainTauren",
    Nightborne = "Nightborne",
    MagharOrc = "MagharOrc",
    Vulpera = "Vulpera",
    ZandalariTroll = "ZandalariTroll",
    -- Neutral
    Dracthyr = "Dracthyr",
    EarthenDwarf = "EarthenDwarf",
    Harronir = "Harronir"
}

function APR:GetEnumKeyByValue(enum, value)
    for key, val in pairs(enum) do
        if val == value then
            return key
        end
    end
    return nil
end
