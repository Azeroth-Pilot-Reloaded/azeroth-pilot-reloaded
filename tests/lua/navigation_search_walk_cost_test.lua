-- An optimistic host cost may be zero and need not obey Euclidean transitivity.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
dofile(root .. "Core.lua")
dofile(root .. "Search.lua")
local engine = LibStub("LibAPRNavigation-1.0").Engine
local function point(x) return { instanceID = 8, region = "outside", x = x, y = 0 } end
local function finish(request)
    local job = engine:CreateSearch(request)
    for _ = 1, 20000 do
        local status, result = job:Step(4, 1)
        assert(job.workLastStep <= 4)
        if status ~= "planning" then assert(status == "ready", status); return result end
    end
    error("cost search did not finish")
end
local a, b = point(0), point(14)
local calls = 0
local result = finish({ start = a, goal = b, walkSecondsFor = function(from, to)
    assert(from == a and to == b)
    calls = calls + 1
    return 0
end })
assert(result.totalSeconds == 0 and calls == 1, "a valid zero bound is honored and cached")
for _, value in ipairs({ -1, math.huge, 0 / 0, "invalid" }) do
    result = finish({ start = a, goal = b, walkSecondsFor = function() return value end })
    assert(result.totalSeconds == 2, "invalid costs fall back to the ordinary 14/7-second walk")
end
result = finish({ start = a, goal = b, walkSecondsFor = function() return nil end })
assert(result.totalSeconds == 2, "nil delegates to ordinary movement costs")

local mid, goal = point(20), point(40)
result = finish({ start = a, goal = goal, walkSecondsFor = function(from, to)
    if from.x == 0 and to.x == 20 then return 3 end
    if from.x == 20 and to.x == 40 then return 4 end
    return 20
end, edges = { { from = mid, to = mid, kind = "portal", seconds = 1000 } } })
assert(result.totalSeconds == 7 and #result.segments == 2,
    "custom pair costs disable Euclidean pruning of a better consecutive walk")
print("Search walking costs: zero bounds, invalid-value fallback, caching and non-transitive costs passed")
