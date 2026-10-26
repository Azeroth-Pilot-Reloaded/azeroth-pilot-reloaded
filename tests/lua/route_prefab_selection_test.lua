-- Popup composition follows eligible fixture metadata and scope, not guide names.
local env = dofile("tests/lua/route_prefab_test_env.lua")
APR.ClassName, APR.ClassId = "MAGE", 8
local kind = APR.PREFAB_TYPES
local normal = env.route("fixture-leveling", "Ordinary offer", nil, { [kind.Leveling] = 1 })
local dungeon = env.route("fixture-dungeon", "Dungeon offer", nil, { [kind.Dungeons] = 1 }, APR.CATEGORIES.Dungeons)
-- This prefix is the public scope discriminator, not a packaged guide key.
local mage = env.route("Forever-MageAoE-fixture", "Specialized offer", { Class = "MAGE", MinLevel = 20 }, { [kind.Leveling] = 1 })
local popup, selectOption, messages
APR.questionDialog = {
    CreateSelectionPopup = function(_, _, _, options, callback) popup, selectOption = options, callback end,
    CreateMessagePopup = function() messages = (messages or 0) + 1 end,
}
local config = APR.routeconfig
assert(not config:HasPrefab("all_quests"))
assert(config:HasPrefab("speedrun") and config:HasPrefab("leveling") and config:HasPrefab("dungeons"))
config:OpenLevelingPopup()
assert(#popup == 3 and popup[1].key == APR.EXPANSIONS.Forever)
assert(popup[2].key == "forever_dungeons" and popup[3].key == "forever_mage_aoe")
selectOption(popup[3])
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == mage.label)
assert(not APR:CanStartRoute("Forever-MageAoE-fixture"), "A future chapter remains gated after selection")
popup = nil
config:OpenDungeonPopup()
assert(not popup and #APRCustomPath.player == 1 and APRCustomPath.player[1] == dungeon.label)
mage.prefab[kind.Dungeons] = 1
config:OpenDungeonPopup()
assert(#popup == 2 and popup[2].key == "forever_mage_aoe")
selectOption(popup[2])
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == mage.label)
mage.prefab[kind.Dungeons] = nil
APR.ClassName, APR.ClassId = "WARRIOR", 1
assert(#config:GetPrefabOptions("leveling") == 2)
dungeon.prefab = nil
popup = nil
config:OpenLevelingPopup()
assert(not popup and #APRCustomPath.player == 1 and APRCustomPath.player[1] == normal.label)
assert(not config:HasPrefab("dungeons"))
normal.prefab = nil
config:OpenLevelingPopup()
assert(messages == 1, "No eligible offers produce an unavailable message")
