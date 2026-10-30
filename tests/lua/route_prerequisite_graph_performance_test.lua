-- Shared prerequisite branches form a graph, not a tree to walk repeatedly.
local env = dofile("tests/lua/route_prefab_test_env.lua")
env.gameVersion = APR.GAME_VERSIONS.Retail
local depth = 12
local function route(key, label, required)
    local result = env.route(key, label)
    result.expansion, result.requiredRoute = APR.EXPANSIONS.Custom, required
    return result
end
local previous
for level = 1, depth do
    local left, right = "left-" .. level, "right-" .. level
    route(left, "Layer " .. level .. " left", previous)
    route(right, "Layer " .. level .. " right", previous)
    previous = { left, right }
end
route("root", "Requested route", previous)
local realRequired = APR.GetRouteRequiredRouteKeys
local expansions, clock = 0, 0
function APR:GetRouteRequiredRouteKeys(key)
    expansions, clock = expansions + 1, clock + 0.05
    return realRequired(self, key)
end
local function expectLayers(first)
    local path = APRCustomPath.player
    assert(path[1] == "Existing selection")
    local index = 2
    for level = first, depth do
        assert(path[index] == "Layer " .. level .. " left")
        assert(path[index + 1] == "Layer " .. level .. " right")
        index = index + 2
    end
    assert(path[index] == "Requested route" and #path == index,
        "Prerequisite ordering, existing selections and the requested route stay unchanged")
end
APRCustomPath.player = { "Existing selection" }
assert(APR:AddRouteToCustomPathByKey("root"))
expectLayers(1)
assert(expansions == depth * 2 + 1,
    "Each declaration in a shared prerequisite graph is expanded once, got " .. expansions)
assert(clock < 1.3, "A small diamond graph cannot amplify one query into hundreds of simulated milliseconds")

expansions = 0
assert(not APR:AddRouteToCustomPathByKey("root"))
expectLayers(1)
assert(expansions == depth * 2 + 1, "A fresh call reevaluates declarations without adding duplicate path labels")

-- A local visited set must never become a cross-call cache of eligibility.
APRZoneCompleted.player["Layer 1 left"] = true
APR.RouteQuestStepList["right-1"].conditions = { Faction = "Alliance" }
APRCustomPath.player = { "Existing selection" }
assert(APR:AddRouteToCustomPathByKey("root"))
expectLayers(2)
APRZoneCompleted.player["Layer 1 left"] = nil
APR.RouteQuestStepList["right-1"].conditions = nil

route("cycle-a", "Cycle A", { "cycle-b", "cycle-b", "absent" })
route("cycle-b", "Cycle B", { "cycle-a", "leaf" })
route("leaf", "Leaf")
APRCustomPath.player = {}
expansions = 0
assert(APR:AddRouteToCustomPathByKey("cycle-a"))
assert(table.concat(APRCustomPath.player, ",") == "Leaf,Cycle B,Cycle A" and expansions == 3,
    "Cycles, repeated edges and absent prerequisites remain finite and preserve dependency order")
local unchanged = APRCustomPath.player
assert(not APR:AddRouteToCustomPathByKey("absent") and APRCustomPath.player == unchanged)

-- A failed call leaves no persistent traversal marks that could poison retry.
local realData, fail = APR.GetRouteData, true
function APR:GetRouteData(key)
    if fail and key == "leaf" then fail = false; error("Synthetic lookup unavailable") end
    return realData(self, key)
end
APRCustomPath.player = {}
local ok, err = pcall(APR.AddRouteToCustomPathByKey, APR, "cycle-a")
assert(not ok and err:find("Synthetic lookup unavailable", 1, true))
assert(APR:AddRouteToCustomPathByKey("cycle-a"))
assert(table.concat(APRCustomPath.player, ",") == "Leaf,Cycle B,Cycle A")
print("Prerequisite graphs: shared diamonds expanded once, stable order/cycles, live eligibility and failure retry passed")
