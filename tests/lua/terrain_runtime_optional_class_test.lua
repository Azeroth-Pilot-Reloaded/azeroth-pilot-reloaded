local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
local revision = 0
local function check(data, expected)
    revision = revision + 1
    local provider = F.provider(lib, data, revision)
    local state, result = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 10 }), 1)
    assert(state == expected, "An omitted normal class page must follow the codec contract: " .. state)
    if state == "ready" then
        F.near(result.yards, 5 * F.cellSize)
        F.near(result.seconds, 5 * F.cellSize / 10)
        local batchState, batch = F.finish(provider:CreateCostJob(a, { b }, { walkSpeed = 10 }))
        assert(batchState == "ready" and batch.costs[1].state == "ready")
        F.near(batch.costs[1].seconds, 5 * F.cellSize / 10)
    end
end
for _, format in ipairs({ 2, 3 }) do
    local data = F.map()
    data.format, data.class = format, {}
    check(data, "ready")

    local packed, raw = F.map(), {}
    packed.format, packed.packed, packed.counts = format, {}, {}
    packed.class = {}
    for _, field in ipairs({ "grid", "height", "graph", "floor", "class" }) do
        packed.packed[field] = {}
        for key, value in pairs(packed[field]) do
            local token = field .. key
            raw[token], packed.packed[field][key] = value, { token }
        end
        packed.counts[field] = next(packed[field]) and 1 or 0
        packed[field] = nil
    end
    Enum = { CompressionMethod = { Zlib = 1 } }
    C_EncodingUtil = { DecodeBase64 = function(value) return value end,
        DecompressString = function(value) return assert(raw[value]) end }
    check(packed, "ready")
    -- Declaring a nonzero class page count still makes a missing part invalid.
    packed.counts.class = 1
    check(packed, "unavailable")
end
print("terrain runtime optional class: omitted normal pages accepted, declared missing pages rejected")
