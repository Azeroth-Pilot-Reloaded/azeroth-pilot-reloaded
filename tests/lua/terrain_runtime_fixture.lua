-- Invented terrain only: one small tile, no maintained route or live map data.
local F = {}
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function F.number(value, width)
    local result = ""
    for _ = 1, width do
        local digit = value % 64
        result = alphabet:sub(digit + 1, digit + 1) .. result
        value = math.floor(value / 64)
    end
    assert(value == 0)
    return result
end
function F.map(options)
    options = options or {}
    local cells, heights, classes = {}, {}, {}
    for x = 0, 7 do
        for y = 0, 7 do
            local blocked = options.wall and x == 3 and (options.disconnected or y < 7)
            cells[#cells + 1] = blocked and "A" or "Q"
            if not blocked then heights[#heights + 1] = "X" end
            classes[#classes + 1] = options.class or "A"
        end
    end
    return {
        format = 2, cells = 8, nx = 1, ny = 1, cx0 = 0, cy0 = 0,
        swim = 2, zstep = 1,
        graph = { "AA" }, grid = { table.concat(cells) },
        height = { table.concat(heights) }, floor = {},
        class = { table.concat(classes) },
    }
end
F.cellSize = (1600 / 3) / 8
function F.point(x, y, z)
    return { instanceID = 900, x = (x + 0.5) * F.cellSize,
        y = (y + 0.5) * F.cellSize, z = z }
end
function F.load()
    strmatch = string.match
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    dofile("APR-Core/libs/LibAPRNavigation-1.0/Core.lua")
    local root = "APR-Core/libs/LibAPRNavigation-1.0/"
    for _, file in ipairs({ "Terrain/Namespace.lua", "Terrain/Costs.lua", "Terrain/PathGrid.lua",
        "Terrain/Path.lua", "Terrain.lua" }) do
        dofile(root .. file)
    end
    return LibStub("LibAPRNavigation-1.0")
end
function F.provider(lib, data, revision)
    lib:RegisterTerrainData("forever", 900, data or F.map(), revision or 1)
    -- The provider uses profile identity only; client reads belong to the consumer.
    local instance = setmetatable({ profile = "forever", env = {} }, lib.Instance)
    return assert(instance:GetWalkingProvider()), instance
end
function F.finish(job, operations)
    for _ = 1, 200000 do
        local status, result = job:Step(operations or 7, 10)
        assert(job.workLastStep <= (operations or 7), "A Step must obey its operation budget")
        if status ~= "planning" then return status, result end
    end
    error("terrain job never completed")
end
function F.near(actual, expected)
    assert(type(actual) == "number" and math.abs(actual - expected) < 0.00001,
        tostring(actual) .. " differs from " .. tostring(expected))
end
return F
