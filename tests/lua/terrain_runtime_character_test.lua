local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local data = F.map()
local classes = {}
for x = 0, 7 do
    for y = 0, 7 do classes[#classes + 1] = x >= 3 and x <= 4 and y < 7 and "Q" or "A" end
end
data.class[1] = table.concat(classes)
lib:RegisterTerrainData("forever", 900, data, 1)
local faction, observations = "Horde", 0
local owner = setmetatable({ profile = "forever", env = {
    getCharacter = function() observations = observations + 1; return { faction = faction } end,
} }, lib.Instance)
local provider = assert(owner:GetWalkingProvider())
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
local status, friendly = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 }))
assert(status == "ready" and observations == 1)
F.near(friendly.yards, 5 * F.cellSize)
faction = "Alliance"
local second, hostile = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 }))
assert(second == "ready" and hostile.yards > 800 and observations == 2,
    "A fresh job must observe the owner's faction and avoid the hostile strip")
F.near(hostile.seconds, hostile.yards / 7)
local explicit, override = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7, faction = "Horde" }))
assert(explicit == "ready" and observations == 2)
F.near(override.yards, 5 * F.cellSize)
local speedReads = 0
local _, limited = F.finish(provider:CreatePathJob(a, b, {
    faction = "Horde", walkSpeed = 7,
    walkSpeedAt = function(p) speedReads = speedReads + 1; return p.x < 200 and 10 or 5 end,
}))
F.near(limited.seconds, 5 * F.cellSize / 5)
assert(speedReads > 0)
local _, pairSpeed = F.finish(provider:CreatePathJob(a, b, {
    faction = "Horde", walkSpeed = 7, walkSpeedFor = function() return 20 end,
}))
F.near(pairSpeed.seconds, 5 * F.cellSize / 20)
print("terrain runtime character: owner faction, context override and physical speed callbacks passed")
