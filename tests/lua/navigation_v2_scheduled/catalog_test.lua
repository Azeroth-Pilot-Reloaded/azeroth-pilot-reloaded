local F = assert(loadfile("tests/lua/navigation_v2_scheduled/fixture.lua"))()
local S = F.Scheduled
local route = F.Route()
route.access = "available"
local catalog = assert(S.NewCatalog({ route }))
local edge = assert(catalog:Edge("west pier", 1, 100))
assert(edge.from == "west pier" and edge.to == "east pier" and edge.seconds == 62)
assert(edge.kind == "scheduled" and edge.transportId == "river crossing" and edge.access == "available")
assert(catalog:Edge("east pier", 1, 100) == nil, "A reverse service must not be invented")
assert(catalog:Edge("west pier", 2, 100) == nil)
route.costs.ride = 900
assert(catalog:Edge("west pier", 1, 100).seconds == 62)
assert(S.NewCatalog({ F.Route(), F.Route() }) == nil)
assert(S.NewCatalog({ [2] = F.Route() }) == nil)
assert(S.NewCatalog({ [257] = F.Route() }) == nil)
route = F.Route()
assert(S.NewCatalog({ route }):Edge("west pier", 1, 100).access == "unknown")
route.access = "invented"
assert(S.NewCatalog({ route }) == nil)
route.access = false
assert(S.NewCatalog({ route }) == nil)

route = F.Route()
route.wait = { mode = "periodic", firstDeparture = 110, periodSeconds = 30 }
catalog = assert(S.NewCatalog({ route }))
assert(catalog:Edge("west pier", 1, 105).seconds == 71)
local absent, reason = catalog:Edge("west pier", 1, nil)
assert(absent == nil and reason == "unknown_schedule_epoch")
local session = assert(catalog:NewExecution("river crossing", { objectiveID = "fixture", now = 100, timeoutSeconds = 200 }))
assert(session:GetState().phase == "approach")
assert(catalog:NewExecution("missing", {}) == nil)
