-- A level-one preset must queue future chapters, while activation stays gated.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
DUNGEONS = "Dungeons"
tinsert, tremove = table.insert, table.remove
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
APR = { PlayerID = "player", Faction = "Horde", Race = "Orc", RaceID = 2,
    ClassName = "WARRIOR", ClassId = 1, Level = 1, RouteQuestStepList = {}, routeconfig = {} }
APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
function APR:NewModule() return {} end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/config/Config_Route_Prefabs.lua")
local gameVersion = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return gameVersion end
function APR:GetPlayerEffectiveLevel() return self.Level end
function APR:IsDelveRoute() return false end
function UnitFactionGroup() return APR.Faction end
function APR.routeconfig:SendCustomPathUpdate() end
APR.worldCoordinateConverter = {
    ConvertMapCoordinate = function(_, _, x, y) return { x = x, y = y } end,
    ConvertMapTrigger = function(_, map, x, y, range) return { mapID = map, x = x, y = y, Range = range } end,
    GetMixedAreaCenter = function() return { x = 0, y = 0 } end,
    GetMixedAreaRadius = function() return 10 end,
}
for _, path in ipairs({
    "Routes/Forever/Horde/Forever_Horde_Starting_Zone_Troll_Orc.lua",
    "Routes/Forever/Horde/Forever_Starting_Zone_Scourge.lua",
    "Routes/Forever/Horde/Forever_Starting_Zone_Tauren.lua",
    "Routes/Forever/Shared/Forever_Starting_Zone_Skyborne.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Silverpine.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Barrens_12_16.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Ragefire_Chasm.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Ruins_of_Lordaeron.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Barrens_18_21.lua",
    "Routes/Forever/Dungeons/Horde/Forever_Horde_Dungeons_Wailing_Caverns.lua",
    "Routes/Forever/Alliance/Forever_Alliance_Starting_Zone_Dwarf_Gnome.lua",
    "Routes/Forever/Alliance/Forever_Starting_Zone_Human.lua",
    "Routes/Forever/Alliance/Forever_Starting_Zone_NightElf.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Elwynn_Dwarf_Gnome.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Loch_Modan_Human.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Loch_Modan_Dwarf_Gnome.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Loch_Modan_Hunter.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Darkshore_Loch_Modan_NightElf.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Westfall.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Darkshore.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Hall_of_Thanes.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Ruins_of_Lordaeron.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Deadmines.lua",
    "Routes/Forever/Dungeons/Alliance/Forever_Alliance_Dungeons_Darkshore_Ashenvale.lua",
    "Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Ragefire_Chasm.lua",
    "Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Ruins_of_Lordaeron.lua",
    "Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Wailing_Caverns.lua",
    "Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Hall_of_Thanes.lua",
    "Routes/Forever/Dungeons/Shared/Forever_Shared_Dungeons_Deadmines.lua",
}) do dofile(path) end
for _, case in ipairs({
    { "Orc", "WARRIOR", 8 }, { "Orc", "HUNTER", 6 }, { "Troll", "PRIEST", 8 },
    { "Scourge", "PALADIN", 7 }, { "Tauren", "DRUID", 6 },
    { "Skyborne", "DRUID", 7 }, { "Skyborne", "SHAMAN", 6 },
}) do
    APR.Race, APR.ClassName = case[1], case[2]
    APR.ClassId = ({ WARRIOR = 1, HUNTER = 3, PRIEST = 5, PALADIN = 2, SHAMAN = 7, DRUID = 11 })[case[2]]
    APR.RaceID = ({ Orc = 2, Troll = 8, Scourge = 5, Tauren = 6, Skyborne = 97 })[case[1]]
    assert(APR.routeconfig:BuildDungeonPrefab())
    local path = APRCustomPath.player
    assert(#path == case[3], case[1] .. " " .. case[2] .. " queued " .. #path .. " chapters")
    assert(path[#path] == APR.RouteQuestStepList["Forever-Horde-Dungeons-Wailing-Caverns"].label)
    assert(not APR:CanStartRoute("Forever-Horde-Dungeons-Ragefire-Chasm"), "Queuing never waives the level gate")
end
-- Finishing a reused starter must respect the queued dungeon successor.
APR.Race, APR.ClassName = "Scourge", "PALADIN"
APR.RaceID, APR.ClassId = 5, 2
APR.routeconfig:BuildDungeonPrefab()
local completed = false
APR:SuggestNextRoutes("Forever-Starting-Zone-Scourge", function() completed = true end)
assert(completed, "Do not offer the normal outdoor branch over the queued dungeon chapter")

APR.Faction = "Alliance"
for _, case in ipairs({
    { "Human", "WARRIOR", 8 }, { "Dwarf", "HUNTER", 8 }, { "Dwarf", "PALADIN", 9 },
    { "Gnome", "MAGE", 9 }, { "NightElf", "DRUID", 6 },
    { "Skyborne", "HUNTER", 7 }, { "Skyborne", "SHAMAN", 7 },
}) do
    APR.Race, APR.ClassName = case[1], case[2]
    APR.ClassId = ({ WARRIOR = 1, HUNTER = 3, PALADIN = 2, SHAMAN = 7, DRUID = 11, MAGE = 8 })[case[2]]
    APR.RaceID = ({ Human = 1, Dwarf = 3, Gnome = 7, NightElf = 4 })[case[1]]
    assert(APR.routeconfig:BuildDungeonPrefab())
    local path = APRCustomPath.player
    assert(#path == case[3], case[1] .. " " .. case[2] .. " queued " .. #path .. " Alliance chapters")
    assert(path[#path] == APR.RouteQuestStepList["Forever-Alliance-Dungeons-Darkshore-Ashenvale"].label)
    for _, label in ipairs(path) do assert(not label:find("Horde", 1, true)) end
    assert(not APR:CanStartRoute("Forever-Alliance-Dungeons-Hall-of-Thanes"))
end
-- Shared runs remain available independently and never join the leveling prefab.
for _, faction in ipairs({ "Alliance", "Horde" }) do
    APR.Faction = faction
    for key, route in pairs(APR.RouteQuestStepList) do
        if key:find("Forever-Shared-Dungeons-", 1, true) then
            assert(not route.prefab and not route.nextRoute and not route.conditions.Faction)
            assert(APR:GetRouteVisibility(key) == "visible")
        end
    end
end
APR.Faction = "Neutral"
APRCustomPath.player = { "existing" }
assert(not APR.routeconfig:BuildDungeonPrefab() and APRCustomPath.player[1] == "existing")
APR.Faction, gameVersion = "Horde", APR.GAME_VERSIONS.Retail
assert(not APR.routeconfig:BuildDungeonPrefab() and APRCustomPath.player[1] == "existing")
