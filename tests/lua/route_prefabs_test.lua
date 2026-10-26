-- Prefabs queue future chapters, filter characters and order metadata.
local env = dofile("tests/lua/route_prefab_test_env.lua")
local dungeon = APR.PREFAB_TYPES.Dungeons
local routes = APR.RouteQuestStepList
local first = env.route("fixture-first", "A translated starter", { Faction = "Horde", Race = "Orc" }, { [dungeon] = 1 })
local later = env.route("fixture-later", "A future chapter", { Faction = "Horde", MinLevel = 20 }, { [dungeon] = 3 })
local middle = env.route("fixture-middle", "An eligible class chapter", { Faction = "Horde", Class = "WARRIOR" },
    { [dungeon] = { index = 2, conditions = { Race = "Orc" } } })
env.route("fixture-other-faction", "Other faction", { Faction = "Alliance" }, { [dungeon] = 1 })
env.route("fixture-other-race", "Other race", { Race = "Tauren" }, { [dungeon] = 1 })
env.route("fixture-other-class", "Other class", { Class = "MAGE" }, { [dungeon] = 1 })
env.route("fixture-entry-filter", "Filtered prefab entry", {},
    { [dungeon] = { index = 1, conditions = { Race = "Tauren" } } })
env.route("Forever-MageAoE-fixture", "Separate scope", { Class = "MAGE" }, { [dungeon] = 1 })
env.route("fixture-standalone", "Standalone dungeon", nil, nil, APR.CATEGORIES.Dungeons)
local function expectPath(expected)
    assert(#APRCustomPath.player == #expected, "Only eligible, unfinished prefab entries are queued")
    for index, route in ipairs(expected) do assert(APRCustomPath.player[index] == route.label) end
end
assert(APR.routeconfig:BuildDungeonPrefab())
expectPath({ first, middle, later })
assert(not APR:CanStartRoute("fixture-later"), "Queuing a future chapter cannot waive activation's level gate")
APR.Level = 20
assert(APR:CanStartRoute("fixture-later"))
APR.Level = 1
-- A queued successor takes precedence over a starter's ordinary continuation.
first.nextRoute = { "fixture-other-class" }
local finished = false
APR:SuggestNextRoutes("fixture-first", function() finished = true end)
assert(finished)
APRZoneCompleted.player[first.label] = true
assert(APR.routeconfig:BuildDungeonPrefab())
expectPath({ middle, later })
-- Names and optional restrictions are input, not expected catalog snapshots.
middle.label, middle.conditions.Class = "Nom changé sans modifier le test", nil
APR.ClassName, APR.ClassId = "PRIEST", 5
assert(APR.routeconfig:BuildDungeonPrefab())
expectPath({ middle, later })
-- Equal indices sort deterministically by key, independent of registration order.
routes["fixture-z"] = env.route("fixture-z", "Last tie", nil, { [dungeon] = 2 })
routes["fixture-a"] = env.route("fixture-a", "First tie", nil, { [dungeon] = 2 })
assert(APR.routeconfig:BuildDungeonPrefab())
expectPath({ routes["fixture-a"], middle, routes["fixture-z"], later })
for _, version in ipairs({ APR.GAME_VERSIONS.Retail, APR.GAME_VERSIONS.Forever }) do
    env.gameVersion, APR.Faction = version, version == APR.GAME_VERSIONS.Forever and "Neutral" or "Horde"
    APRCustomPath.player = { "Existing selection" }
    assert(not APR.routeconfig:BuildDungeonPrefab() and APRCustomPath.player[1] == "Existing selection")
end
