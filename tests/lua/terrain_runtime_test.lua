local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local provider, instance = F.provider(lib, F.map({ class = "D" }))
assert(provider == instance:GetWalkingProvider(), "Provider identity is stable per instance")
assert(provider:HasMap(900) and not provider:HasMap(901))
for _, profile in ipairs({ "retail", "unsupported" }) do
    assert(setmetatable({ profile = profile }, lib.Instance):GetWalkingProvider() == nil)
end
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
a.uiMapID, a.accessKey, a.floor = 9010, "private-a", 1
b.uiMapID, b.accessKey, b.floor = 9011, "private-a", 1
local status, path = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }), 1)
assert(status == "ready" and #path.path >= 2)
F.near(path.yards, 5 * F.cellSize)
F.near(path.seconds, path.yards / 10)
assert(path.path[1] ~= a and path.path[#path.path] ~= b)
assert(path.path[1].uiMapID == 9010 and path.path[#path.path].uiMapID == 9011)
assert(path.path[1].accessKey == "private-a" and path.path[#path.path].floor == 1)
path.path[1].x, path.path[2].accessKey = -999, "changed"
local again, clean = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 20 }))
assert(again == "ready" and clean.path[1].x == a.x and clean.path[#clean.path].accessKey == "private-a")
F.near(clean.seconds, clean.yards / 20)
local batchStatus, batch = F.finish(provider:CreateCostJob(a, { b, F.point(4, 1, 0),
    { instanceID = 901, x = 0, y = 0 } }, { walkSpeed = 10 }))
assert(batchStatus == "ready" and #batch.costs == 3)
assert(batch.costs[1].state == "ready" and batch.costs[3].state == "unavailable")
F.near(batch.costs[1].yards, 5 * F.cellSize)
F.near(batch.costs[1].seconds, 5 * F.cellSize / 10)
F.near(batch.costs[2].yards, 3 * F.cellSize)
assert(a.x > 0 and b.accessKey == "private-a")
print("terrain runtime: physical distances, private result copies, profiles and ordered costs passed")
F.provider(lib, F.map({ wall = true }), 2)
a.region, b.region = "fixture-corridor", "fixture-corridor"
local corridorStatus, corridor = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }))
assert(corridorStatus == "ready" and #corridor.path > 2)
for _, point in ipairs(corridor.path) do
    assert(point.accessKey == "private-a" and point.floor == 1 and point.region == "fixture-corridor",
        "Every guidance point must preserve the common access corridor")
end
b.region, b.accessKey, b.floor = "other-corridor", "private-b", 2
local _, separate = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }))
assert(separate.path[2].accessKey == nil and separate.path[2].floor == nil and separate.path[2].region == nil,
    "The provider may not invent shared access metadata between unlike endpoints")
