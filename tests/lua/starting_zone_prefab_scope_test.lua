-- StartingZone is both the existing starter marker and a scoped preset entry.
local env = dofile("tests/lua/route_prefab_test_env.lua")
local kind = APR.PREFAB_TYPES
APR.ClassName, APR.ClassId, APR.Level, APR.MinBoostLvl = "MAGE", 8, 1, 10
function APR:GetPlayerParentMapID() return 1 end
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }

local normal = env.route(
    "fixture-normal-start",
    "Ordinary invented starter",
    { Race = "Orc", Faction = "Horde" },
    { [kind.StartingZone] = 1 },
    APR.CATEGORIES.Leveling
)
normal.mapID = 1
-- This prefix is the public scope discriminator, independent of packaged guides.
local mage = env.route(
    "Forever-MageAoE-fixture-start",
    "Specialized invented starter",
    { Race = "Orc", Class = "MAGE", Faction = "Horde" },
    { [kind.StartingZone] = { index = 1 }, [kind.Leveling] = 1 },
    APR.CATEGORIES.Leveling
)
mage.mapID = 1
local internal = env.route(
    "fixture-hidden-start",
    "Internal invented chapter",
    { Race = "Orc", Faction = "Horde" },
    { [kind.StartingZone] = 2 },
    APR.CATEGORIES.Leveling
)
internal.mapID, internal.hiddenFromSelection = 1, true
local wrong = env.route(
    "fixture-wrong-race",
    "Other-race invented starter",
    { Race = "Tauren", Faction = "Horde" },
    { [kind.StartingZone] = 1 },
    APR.CATEGORIES.Leveling
)
wrong.mapID = 1

APR.routeconfig:GetStartingZonePrefab()
assert(
    #APRCustomPath.player == 1 and APRCustomPath.player[1] == normal.label,
    "A default Mage start must queue the ordinary starter once, without the AoE or hidden variants"
)
assert(
    APR:GetRouteVisibility("Forever-MageAoE-fixture-start") == "visible",
    "An unqueued specialized starter remains manually selectable"
)

APRCustomPath.player = {}
APR.RouteQuestStepList["fixture-normal-start"] = nil
APR.routeconfig:GetStartingZonePrefab()
assert(
    #APRCustomPath.player == 0,
    "A same-faction starter on the current map still requires its authored race for automatic selection"
)

APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever, "forever_mage_aoe")
assert(
    #APRCustomPath.player == 1 and APRCustomPath.player[1] == mage.label,
    "An explicit AoE preset still queues its specialized starter"
)

APRCustomPath.player = {}
APR.Level, mage.autoStartOnMap = 20, true
APR.routeconfig:GetStartingZonePrefab()
assert(#APRCustomPath.player == 0, "AoE map auto-start metadata cannot trigger the ordinary starter flow")

APR.RouteQuestStepList["fixture-normal-start"] = normal
normal.autoStartOnMap = true
APR.routeconfig:GetStartingZonePrefab()
assert(
    #APRCustomPath.player == 1 and APRCustomPath.player[1] == normal.label,
    "An ordinary map auto-start still works outside the new-character level range"
)
print(
    "Starting prefab scope: ordinary/AoE isolation, hidden chapters, same-faction races, fallback and map auto-start passed"
)
