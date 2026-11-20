local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Geography.lua")
local owner = setmetatable({ profile = "forever", config = {}, env = {} }, lib.Instance)
lib:RegisterTerrainData("forever", 900, F.map({ wall = true }), 1)
local provider = assert(owner:GetWalkingProvider())
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
a.accessKey, b.accessKey, a.floor, b.floor = "fixture-room", "fixture-room", 3, 3
a.region, b.region = "900:fixture:outdoor", "900:fixture:outdoor"
a.uiMapID, b.uiMapID = 9010, 9011
assert(owner:CanWalk(a, b))
local status, result = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 }))
assert(status == "ready" and #result.path > 2)
for i = 1, #result.path do
    assert(owner:IsSameAccessRegion(a, result.path[i]),
        "Real geography must recognize every intermediate guidance point in the corridor")
end
assert(result.path[1].uiMapID == a.uiMapID and result.path[#result.path].uiMapID == b.uiMapID)
print("terrain runtime access: actual geography accepts all private corridor points without replacing endpoint maps")
