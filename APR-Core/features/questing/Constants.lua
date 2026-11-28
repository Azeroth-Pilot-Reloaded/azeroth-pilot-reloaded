-- Read-only configuration for questing features. Runtime state stays with the owning module.
APR.QuestingConstants = {
    -- Known gossip options.
    Gossip = {
        DARKMOON_GOSSIP = {
            [40007] = true, -- Darkmoon Faire Mystic Mage (Horde)
            [40457] = true, -- Darkmoon Faire Mystic Mage (Alliance)
        },
        QUEST_GOSSIP = {
            -- usually only added if they're repeatable
            [109275] = true, -- Soridormi - begin time rift
            [120619] = true, -- Big Dig task
            [120620] = true, -- Big Dig task
            [120555] = true, -- Awakening The Machine
            [120733] = true, -- Theater Troupe

            -- Darkmoon Faire
            [40563] = true, -- whack
            [28701] = true, -- cannon
            [31202] = true, -- shoot
            [39245] = true, -- tonk
            [40224] = true, -- ring toss
            [43060] = true, -- firebird
            [52651] = true, -- dance
            [41759] = true, -- pet battle 1
            [42668] = true, -- pet battle 2
            [40872] = true, -- cannon return (Teleportologist Fozlebub)
        },
        IGNORE_GOSSIP = {
            -- when we don't want to automate gossip because it's counter-intuitive
            [122442] = true, -- leave the dungeon in remix

            -- avoid accidental teleports
            [44733] = true,
            [125350] = true, -- siren isle
            [125351] = true, -- siren isle
            [131324] = true, -- winter veil hillsbrad
            [131325] = true, -- winter veil hillsbrad
        },
    },

    -- Stat names returned by the item API.
    RewardScoring = {
        attributeAliases = {
            Strength = { "ITEM_MOD_STRENGTH_SHORT" },
            Agility = { "ITEM_MOD_AGILITY_SHORT" },
            Intellect = { "ITEM_MOD_INTELLECT_SHORT" },
        },
        aliases = {
            Stamina = { "ITEM_MOD_STAMINA_SHORT" },
            Spirit = { "ITEM_MOD_SPIRIT_SHORT" },
            Crit = {
                "ITEM_MOD_CRIT_RATING_SHORT",
                "ITEM_MOD_SPELL_CRIT_RATING_SHORT",
                "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
            },
            Haste = {
                "ITEM_MOD_HASTE_RATING_SHORT",
                "ITEM_MOD_SPELL_HASTE_RATING_SHORT",
                "ITEM_MOD_HASTE_SPELL_RATING_SHORT",
            },
            Hit = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_SPELL_HIT_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT" },
            Mastery = { "ITEM_MOD_MASTERY_RATING_SHORT" },
            Versatility = { "ITEM_MOD_VERSATILITY", "ITEM_MOD_VERSATILITY_RATING_SHORT" },
            Armor = { "RESISTANCE0_NAME", "ITEM_MOD_ARMOR_SHORT" },
            AttackPower = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
            SpellPower = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
            Healing = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
            ManaRegen = { "ITEM_MOD_MANA_REGENERATION_SHORT" },
            WeaponDPS = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" },
            Dodge = { "ITEM_MOD_DODGE_RATING_SHORT" },
            Parry = { "ITEM_MOD_PARRY_RATING_SHORT" },
            Defense = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
            Block = { "ITEM_MOD_BLOCK_RATING_SHORT" },
        },
        hybrids = {
            { "ITEM_MOD_AGILITY_OR_INTELLECT_SHORT", "Agility", "Intellect" },
            { "ITEM_MOD_AGILITY_OR_STRENGTH_SHORT", "Agility", "Strength" },
            { "ITEM_MOD_STRENGTH_OR_INTELLECT_SHORT", "Strength", "Intellect" },
            { "ITEM_MOD_AGILITY_STRENGTH_INTELLECT_SHORT", "Agility", "Strength", "Intellect" },
        },
    },

    -- Route level and starting-character condition fields.
    RouteManager = {
        routeLevelFields = { "Level", "MinLevel", "MaxLevel", "BeLvl", "SkipForLvl" },
        levelConditionGroups = { "AnyOf", "AllOf" },
        characterAdviceFields = { Race = true, Class = true, ClassNot = true, AlliedRace = true },
        classRouteAdviceFields = { Race = true, AlliedRace = true },
        characterAdviceOrder = { "Race", "Class", "ClassNot", "AlliedRace" },
        mageClasses = { "MAGE", 8 },
        falseConditions = { AnyOf = {} },
    },

    -- Recent transition history size.
    StepTransitions = {
        HISTORY_LIMIT = 40,
    },
}
