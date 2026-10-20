-- Exercise the actual routes, including class/race restrictions and future chapters.
dofile("tests/lua/forever_dungeon_prefab_test.lua")
function APR:GetGameVersion() return APR.GAME_VERSIONS.Forever end
APR.Faction, APR.Race, APR.RaceID = "Horde", "Orc", 2
APR.ClassName, APR.ClassId, APR.Level = "MAGE", 8, 1
for _, path in ipairs({
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Arathi.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Darkshore.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Dun_Morogh.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Duskwood.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Elwynn_Forest.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Hillsbrad.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Loch_Modan.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Redridge.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Wetlands.lua",
    "Routes/Forever/MageAoE/Alliance/Forever_MageAoE_Alliance_Zephras_Isle.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Arathi.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Durotar.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Dustwallow.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Silverpine.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Stonetalon.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_The_Barrens.lua",
    "Routes/Forever/MageAoE/Horde/Forever_MageAoE_Horde_Tirisfal_Glades.lua",
}) do dofile(path) end
-- Retired variants must be absent from the catalog, including mixed zone files.
for key, route in pairs(APR.RouteQuestStepList) do
    if key:find("^Forever%-MageAoE%-") then
        assert(not key:find("Advanced", 1, true))
        assert(not route.label:find("Hard", 1, true) and not route.label:find("Experienced", 1, true))
        for _, following in ipairs(route.nextRoute or {}) do
            local target = type(following) == "table" and following.route or following
            assert(APR.RouteQuestStepList[target], "Missing Mage AoE continuation: " .. target)
        end
    end
end
local config = APR.routeconfig
local popup, selectOption, messages
APR.questionDialog = {
    CreateSelectionPopup = function(_, _, _, options, callback) popup, selectOption = options, callback end,
    CreateMessagePopup = function() messages = (messages or 0) + 1 end,
}
assert(not config:HasPrefab("all_quests"))
assert(config:HasPrefab("speedrun") and config:HasPrefab("leveling") and config:HasPrefab("dungeons"))
config:OpenLevelingPopup()
assert(#popup == 3)
assert(popup[1].key == APR.EXPANSIONS.Forever and popup[1].label == "Forever")
assert(popup[2].key == "forever_dungeons" and popup[3].key == "forever_mage_aoe")
selectOption(popup[3])
assert(#APRCustomPath.player == 6, "Queue the complete Horde Mage AoE chain at level one")
assert(APRCustomPath.player[1] == APR.RouteQuestStepList["Forever-MageAoE-Horde-Starting-Zone-Troll-Orc"].label)
assert(APRCustomPath.player[6] == APR.RouteQuestStepList["Forever-MageAoE-Horde-Leveling-Camps"].label)
assert(not APR:CanStartRoute("Forever-MageAoE-Horde-The-Barrens"))
for _, label in ipairs(APRCustomPath.player) do assert(label:find("Mage AoE", 1, true)) end
-- One dungeon option applies directly; the normal path must not pick up Mage chapters.
popup = nil
config:OpenDungeonPopup()
assert(not popup and #APRCustomPath.player == 8)
for _, label in ipairs(APRCustomPath.player) do assert(not label:find("Mage AoE", 1, true)) end
-- A future Mage dungeon prefab becomes a second choice, isolated from the normal path.
local mage = APR.RouteQuestStepList["Forever-MageAoE-Horde-Starting-Zone-Troll-Orc"]
mage.prefab[APR.PREFAB_TYPES.Dungeons] = 1
config:OpenDungeonPopup()
assert(#popup == 2 and popup[2].key == "forever_mage_aoe")
selectOption(popup[2])
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == mage.label)
mage.prefab[APR.PREFAB_TYPES.Dungeons] = nil
-- No Mage option for a warrior.
APR.ClassName, APR.ClassId = "WARRIOR", 1
assert(#config:GetPrefabOptions("leveling") == 2)
-- One remaining leveling family applies without opening a selection dialog.
local dungeonEntries = {}
for key, data in pairs(APR.RouteQuestStepList) do
    if data.prefab and data.prefab[APR.PREFAB_TYPES.Dungeons] then
        dungeonEntries[key] = data.prefab[APR.PREFAB_TYPES.Dungeons]
        data.prefab[APR.PREFAB_TYPES.Dungeons] = nil
    end
end
popup = nil
config:OpenLevelingPopup()
assert(not popup and #APRCustomPath.player > 0)
assert(not config:HasPrefab("dungeons"))
for key, entry in pairs(dungeonEntries) do APR.RouteQuestStepList[key].prefab[APR.PREFAB_TYPES.Dungeons] = entry end
-- All supported Alliance starting variants follow the normal AoE chain once.
APR.Faction, APR.ClassName, APR.ClassId = "Alliance", "MAGE", 8
for _, case in ipairs({{"Human", 1, 9}, {"Gnome", 7, 9}, {"Skyborne", 97, 8}}) do
    APR.Race, APR.RaceID = case[1], case[2]
    config:OpenLevelingPopup()
    assert(#popup == 3)
    selectOption(popup[3])
    assert(#APRCustomPath.player == case[3], case[1] .. " Mage chain")
    assert(APRCustomPath.player[#APRCustomPath.player] == APR.RouteQuestStepList["Forever-MageAoE-Alliance-Leveling-Camps"].label)
    for _, label in ipairs(APRCustomPath.player) do
        assert(label:find("Mage AoE", 1, true) and not label:find("Hard", 1, true))
    end
end
assert(not messages)
