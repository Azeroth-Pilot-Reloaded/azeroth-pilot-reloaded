local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional class segments; elite and dungeon progression is selected separately.
APR.RouteQuestStepList["Forever-Class-Mage-Celestial-Power-Orb"] = {
    label = L["FOREVER_MAGE_CELESTIAL_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1445,
    conditions = { Class = "MAGE", MinLevel = 35, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } } },
    levelRange = { min = 35 },
    autoStartOnMap = false,
    steps = {
        { Done = { 1953 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1953 } }, AllOf = { { IsQuestOnQuest = 1953 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { PickUp = { 1954 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1954 } }, AllOf = { { IsQuestNotOnQuest = 1954 }, { IsQuestUncompleted = 1954 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Qpart = { [1954] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1443, 53.34, 79.05), RaidIcon = { { npcID = 4668, questID = 1954, objectiveIndex = 1 } }, AllOf = { { IsQuestOnQuest = 1954 }, { Not = { IsQuestReadyForTurnIn = 1954 } } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1443, },
        { Done = { 1954 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1954 } }, AllOf = { { IsQuestOnQuest = 1954 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { RouteCompleted = true, AllOf = { { IsQuestCompleted = 1954 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, },
    },
}
APR.RouteQuestStepList["Forever-Class-Mage-Celestial-Power-Group"] = {
    label = L["FOREVER_MAGE_CELESTIAL_DUNGEON"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1445,
    conditions = { Class = "MAGE", MinLevel = 35, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, IsQuestCompleted = 1954 },
    levelRange = { min = 35 },
    autoStartOnMap = false,
    steps = {
        { PickUp = { 1955 }, Note = { "CELESTIAL_EXORCISM_GROUP" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1955 } }, AllOf = { { IsQuestNotOnQuest = 1955 }, { IsQuestUncompleted = 1955 }, { IsQuestCompleted = 1954 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Qpart = { [1955] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.04, 57.1), RaidIcon = { { npcID = 6549, questID = 1955, objectiveIndex = 1 } }, AllOf = { { IsQuestOnQuest = 1955 }, { Not = { IsQuestReadyForTurnIn = 1955 } } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Done = { 1955 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1955 } }, AllOf = { { IsQuestOnQuest = 1955 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { PickUp = { 1956 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1956 } }, AllOf = { { IsQuestNotOnQuest = 1956 }, { IsQuestUncompleted = 1956 }, { IsQuestCompleted = 1955 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { EnterInstance = { dungeonKey = "INSTANCE_70", questID = 1956 }, AllOf = { { IsQuestOnQuest = 1956 }, { Not = { IsQuestReadyForTurnIn = 1956 } } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, },
        { Qpart = { [1956] = { 1 } }, Dungeon = "INSTANCE_70", RaidIcon = { { npcID = 7023, questID = 1956, objectiveIndex = 1 } }, AllOf = { { IsQuestOnQuest = 1956 }, { Not = { IsQuestReadyForTurnIn = 1956 } } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, },
        { LeaveInstance = { dungeonKey = "INSTANCE_70", questID = 1956 }, AllOf = { { IsQuestOnQuest = 1956 }, { IsQuestReadyForTurnIn = 1956 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, },
        { Done = { 1956 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1956 } }, AllOf = { { IsQuestOnQuest = 1956 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { PickUp = { 1957 }, Note = { "MANA_SURGES_RETRY" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1957 } }, AllOf = { { IsQuestNotOnQuest = 1957 }, { IsQuestUncompleted = 1957 }, { IsQuestCompleted = 1956 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Qpart = { [1957] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 45.85, 56.76), RaidIcon = { { npcID = 6550, questID = 1957, objectiveIndex = 1 } }, AllOf = { { IsQuestOnQuest = 1957 }, { Not = { IsQuestReadyForTurnIn = 1957 } } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Done = { 1957 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1957 } }, AllOf = { { IsQuestOnQuest = 1957 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { PickUp = { 1958 }, ExtraLineText = { "WAIT_FOR_NPC_END_RP" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1958 } }, AllOf = { { IsQuestNotOnQuest = 1958 }, { IsQuestUncompleted = 1958 }, { IsQuestCompleted = 1957 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { Done = { 1958 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09), Range = 3, RaidIcon = { { npcID = 6546, questID = 1958 } }, AllOf = { { IsQuestOnQuest = 1958 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, Zone = 1445, },
        { RouteCompleted = true, AllOf = { { IsQuestCompleted = 1958 } }, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }, Class = "MAGE", MinLevel = 35, },
    },
}
