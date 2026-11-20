local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local number = F.number

-- Raw zlib blocks bypass Base64, and each block inflates independently.
local raw = F.map()
local data = F.map()
data.blocks, data.packed, data.grid = "zlib", { grid = { { "first", "second" } } }, nil
Enum = { CompressionMethod = { Zlib = 1 } }
C_EncodingUtil = {
    DecodeBase64 = function() error("raw zlib input reached Base64") end,
    DecompressString = function(block, method)
        assert(method == 1 and (block == "first" or block == "second"))
        return raw.grid[1]:sub(1, 32)
    end,
}
local provider = F.provider(lib, data)
local a, b = F.point(0, 1, 0), F.point(1, 1, 0)
assert(F.finish(provider:CreatePathJob(a, b, {}), 1) == "ready")

-- Two nearly coincident storeys. Only the upper one connects east to the
-- adjacent base surface. A height tolerance must not join the two storeys.
data = F.map()
data.zstep = 2 -- Base elevations use this scale. Extra floor heights are already in yards.
local cell = 1
data.floor[1] = number(1, 3)
    .. number(cell, 3)
    .. number(1, 1)
    .. number(1, 1)
    .. number(2052, 2)
    .. number(1, 2)
    .. number(0, 3)
provider = F.provider(lib, data, 2)
local upper = F.point(0, 1, 4)
assert(F.finish(provider:CreatePathJob(upper, b, {}), 1) == "ready")
assert(provider:CanFollowWalkingSegment(upper, b))
assert(provider:CanFollowWalkingSegment(b, upper))
assert(provider:CanFollowWalkingSegment(a, upper) == false)

-- A boundary has just one directed entrance edge. Independently encoded
-- graph records prevent symmetric cell adjacency from inventing a return.
data = F.map()
data.nx = 2
for _, field in ipairs({ "grid", "height", "class" }) do
    data[field][2] = data[field][1]
end

local function portal(cellIndex, outgoing)
    local node = number(cellIndex, 3) .. "AAB" .. number(outgoing and 1 or 0, 1)
    local edge = number(7, 1) .. "AA" .. string.rep(number(67, 3), 3) .. number(67, 2)
    return "AB" .. node .. (outgoing and edge or "")
end
data.graph = { portal(57, true), portal(1, false) }
provider = F.provider(lib, data, 3)
local east = F.point(14, 1, 0)
local state, result = F.finish(provider:CreatePathJob(a, east, {}), 1)
assert(state == "ready")
F.near(result.yards, 14 * F.cellSize)
assert(F.finish(provider:CreatePathJob(east, a, {}), 1) == "no_path")
assert(provider:CanFollowWalkingSegment(F.point(7, 1, 0), F.point(8, 2, 0)) == false,
    "An orthogonal portal does not certify a diagonal across the page boundary")

-- Starting off-centre can send a diagonal into the blocked side of a corner.
-- The turn remains reachable via the open orthogonal edges.
data = F.map()
local grid = {}
for x = 0, 7 do
    for y = 0, 7 do
        grid[#grid + 1] = x == 1 and y == 2 and "A" or "Q"
    end
end
data.grid[1], data.height[1] = table.concat(grid), string.rep("X", 63)
provider = F.provider(lib, data, 4)
local offset, diagonal = F.point(1, 1, 0), F.point(2, 2, 0)
offset.x, offset.y = 1.1 * F.cellSize, 1.9 * F.cellSize
state, result = F.finish(provider:CreatePathJob(offset, diagonal, {}))
assert(state == "ready" and #result.path > 2)
for i = 2, #result.path do
    assert(provider:CanFollowWalkingSegment(result.path[i - 1], result.path[i]))
end

-- Both ways around a corner may be open while a thin object cuts its diagonal.
-- The path, smoothing and guidance must all respect the independently encoded bit.
local start = F.point(2, 3, 0)
for _, dy in ipairs({ -1, 1 }) do
    local goal = F.point(3, 3 + dy, 0)
    for _,open in ipairs({ false, true }) do
        data = F.map()
        local index = 2 * data.cells + 3 + 1
        local encoded = number(16 + (open and (dy == 1 and 4 or 8) or 0), 1)
        data.grid[1] = data.grid[1]:sub(1, index - 1) .. encoded .. data.grid[1]:sub(index + 1)
        provider = F.provider(lib, data, (dy == 1 and 7 or 5) + (open and 1 or 0))
        state, result = F.finish(provider:CreatePathJob(start, goal, {}))
        assert(state == "ready")
        assert(provider:CanFollowWalkingSegment(start, goal) == open)
        assert(provider:CanFollowWalkingSegment(goal, start) == open)
        assert(#result.path == (open and 2 or 3))
        F.near(result.yards, F.cellSize * (open and math.sqrt(2) or 2))
    end
end

-- A stacked corner has an explicit diagonal and only one safe turn.
-- Preserve the turn so the path does not cut the corner of the other floor.
data = F.map()
local cornerCell = 1 * data.cells + 1
data.grid[1] = data.grid[1]:sub(1, cornerCell) .. "A" .. data.grid[1]:sub(cornerCell + 2)
data.height[1] = string.rep("X", 63)
data.floor[1] = number(1, 3) .. number(cornerCell, 3) .. "BB" .. number(2048, 2)
    .. number(17, 2) .. "AAA"
provider = F.provider(lib, data, 9)
local corner, bend, goal = F.point(1, 1, 0), F.point(2, 1, 0), F.point(2, 2, 0)
local cornerState, cornerResult = F.finish(provider:CreatePathJob(corner, goal, {}))
assert(cornerState == "ready" and #cornerResult.path == 3)
assert(cornerResult.path[2].x == bend.x and cornerResult.path[2].y == bend.y)
assert(provider:CanFollowWalkingSegment(corner, goal) == false)
