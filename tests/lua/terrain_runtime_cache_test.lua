local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local raw, data = F.map(), F.map()
data.format, data.nx = 3, 70
data.packed, data.counts = {}, {}
for _, field in ipairs({ "grid", "height", "graph", "floor", "class" }) do
    data[field], data.packed[field] = nil, {}
    data.counts[field] = field == "floor" and 0 or 70
    if field ~= "floor" then
        for tile = 1, 70 do data.packed[field][tile] = { field } end
    end
end
Enum = { CompressionMethod = { Zlib = 1 } }
local reads = 0
C_EncodingUtil = { DecodeBase64 = function(value) return value end,
    DecompressString = function(value)
        reads = reads + 1
        return assert(raw[value][1])
    end }
local provider = F.provider(lib, data)
for tile = 1, 70 do
    local a, b = F.point((tile - 1) * 8 + 1, 1, 0), F.point((tile - 1) * 8 + 6, 1, 0)
    local status, result = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }))
    assert(status == "ready")
    F.near(result.seconds, 5 * F.cellSize / 10)
end
local before = reads
assert(F.finish(provider:CreatePathJob(F.point(1, 1, 0), F.point(6, 1, 0), { walkSpeed = 10 })) == "ready")
assert(reads > before, "Cold pages must be evicted after traversing more than the private decoded-page bound")
print("terrain runtime cache: synthetic format-3 pages are evicted and safely decoded again")
