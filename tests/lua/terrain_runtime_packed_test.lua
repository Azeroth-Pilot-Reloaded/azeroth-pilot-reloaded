local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local data, raw = F.map(), {}
data.packed, data.counts = {}, {}
for _, field in ipairs({ "grid", "height", "graph", "floor", "class" }) do
    data.packed[field] = {}
    for key, value in pairs(data[field]) do
        local token = field .. "-" .. key
        raw[token] = value
        data.packed[field][key] = { token }
    end
    data.counts[field] = next(data[field]) and 1 or 0
    data[field] = nil
end
-- Extra distant data must remain compressed while the local tile is searched.
data.nx = 2
for _, field in ipairs({ "grid", "height", "graph", "class" }) do
    data.packed[field][2] = { "distant-unread" }
    data.counts[field] = 2
end
local provider = F.provider(lib, data)
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
local job = provider:CreatePathJob(a, b, { walkSpeed = 10 })
assert(F.finish(job) == "unavailable", "Missing native decoder must remain unavailable")
Enum = { CompressionMethod = { Zlib = 1 } }
local reads = 0
C_EncodingUtil = {
    DecodeBase64 = function(block) return block end,
    DecompressString = function(block, method)
        assert(method == 1 and block ~= "distant-unread", "Decoding must stay local to requested clusters")
        reads = reads + 1
        return raw[block]
    end,
}
assert(provider:HasMap(900) and reads == 0, "HasMap reads metadata without decoding")
local status, result = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }), 1)
assert(status == "ready")
F.near(result.seconds, 5 * F.cellSize / 10)
assert(reads > 0 and reads <= 4)
assert(data.grid == nil and data.packed.grid[1][1] == "grid-1", "Registered data stays immutable")
local before = reads
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 })) == "ready")
assert(reads == before, "A warm local query reuses the private decoded cache")

local elevated = F.map()
elevated.heightDigits = 3
elevated.zstep = 2
elevated.height[1] = "v" .. F.number(131072 + 2500, 3) .. string.rep("X", 63)
elevated.floor[1] = "AAB" .. F.number(9, 3) .. "BB" .. F.number(131072 - 6000, 3) .. "AA" .. "AAA"
provider = F.provider(lib, elevated, 2)
local start, destination = F.point(1, 1, 5000), F.point(6, 1, 5000)
status, result = F.finish(provider:CreatePathJob(start, destination, { walkSpeed = 10 }))
assert(status == "ready", "Wide base heights remain walkable above the legacy encoding limit")
F.near(result.seconds, 5 * F.cellSize / 10)
assert(F.finish(provider:CreatePathJob(F.point(1, 1, -6000), destination, { walkSpeed = 10 })) == "no_path",
    "A decoded lower floor remains disconnected from the high base surface")
print("terrain runtime packed: guarded native decoder, lazy clusters, private ownership and warm reuse passed")
