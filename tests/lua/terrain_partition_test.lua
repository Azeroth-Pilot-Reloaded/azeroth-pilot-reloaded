-- Two independent tiles in the same world. A distant objective can request
-- its own companion without re-registering the world or invalidating tile one.
local F = dofile("tests/lua/terrain_runtime_fixture.lua")
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local base = "APR-Core/libs/LibAPRNavigation-1.0/"
dofile(base .. "Core.lua")
dofile("tests/lua/manifest_fixture.lua")(base .. "Terrain/Runtime.xml", { terrainData = true })
local runtime = LibStub("LibAPRNavigation-1.0")._TerrainNamespace
dofile(base .. "Terrain.lua")
local lib = LibStub("LibAPRNavigation-1.0")
local sample = F.map()
local world = 900
local frameTime = 0
GetTime = function() return frameTime end
local header = {
    format = sample.format, cells = sample.cells, nx = 2, ny = 1, cx0 = 0, cy0 = 0,
    zstep = 1, swim = 2, packed = { grid = {}, graph = {}, height = {} },
    counts = { grid = 2, graph = 2, height = 2 },
}
local function row(key, group)
    return string.char(key, 0, 0, 0, group, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0)
end
local index = {
    schema = 1, width = 1, fields = { "grid", "height", "graph" },
    groupAddOnPrefix = "APR_NavData_Forever_900_", pages = { row(1, 1) .. row(2, 2) },
}
Enum = { CompressionMethod = { Zlib = 1 } }
C_EncodingUtil = {
    DecodeBase64 = function(value) return value end,
    DecompressString = function(value, method) assert(method == 1); return value end,
}
assert(not lib:RegisterTerrainPartitionIndex("retail", world, 2, header, index))
assert(lib:RegisterTerrainPartitionIndex("forever", world, 2, header, index))
local provider = assert(setmetatable({ profile = "forever", env = {} }, lib.Instance):GetWalkingProvider())
local function declaration(key)
    return {
        packed = { grid = { [key] = { sample.grid[1] } }, height = { [key] = { sample.height[1] } },
            graph = { [key] = { sample.graph[1] } } },
        componentLabels = {},
    }
end
local attempts, allowSecond = { 0, 0 }, false
C_AddOns = { LoadAddOn = function(name)
    local key = assert(tonumber(name:match("^APR_NavData_Forever_900_(%d+)$")))
    attempts[key] = attempts[key] + 1
    local page = declaration(key)
    if key == 2 and not allowSecond then page.packed.height[key] = nil end
    local ok = lib:RegisterTerrainPartitionPages("forever", world, 2, key, page)
    page.packed.grid[key][1] = "A"
    return ok
end }
local function path(offset)
    frameTime = frameTime + 0.016
    return F.finish(provider:CreatePathJob(F.point(offset + 1, 1), F.point(offset + 4, 1), {}))
end
local state, route = path(0)
assert(state == "ready" and route.yards > 0 and attempts[1] == 1 and attempts[2] == 0)
assert(not lib:RegisterTerrainPartitionPages("forever", world, 1, 2, declaration(2)))
assert(not lib:RegisterTerrainPartitionPages("forever", world, 2, 2, declaration(1)))
assert(path(8) == "unavailable" and attempts[2] > 0)
allowSecond = true
assert(path(8) == "ready" and path(0) == "ready" and attempts[1] == 1)
local prior = attempts[2]
assert(lib:RegisterTerrainPartitionIndex("forever", world, 2, header, index))
assert(path(8) == "ready" and attempts[2] == prior, "Repeated index must preserve loaded regions")
local broken = lib.Copy(index)
broken.pages = { row(1, 1) .. row(1, 1) }
assert(not lib:RegisterTerrainPartitionIndex("forever", world, 3, header, broken))
assert(path(0) == "ready", "Rejected replacement must preserve the usable revision")

local weighted = lib.Copy(index)
weighted.schema, weighted.width, weighted.groupCount, weighted.maxGroupBytes = 2, nil, 2, 4096
weighted.pages = { row(1, 2) .. row(2, 1) }
assert(lib:RegisterTerrainPartitionIndex("forever", world, 3, header, weighted))
assert(lib:RegisterTerrainPartitionPages("forever", world, 3, 2, declaration(1)))
assert(lib:RegisterTerrainPartitionPages("forever", world, 3, 1, declaration(2)))
assert(path(0) == "ready" and path(8) == "ready")
weighted.pages = { row(1, 2) .. row(2, 2) }
assert(not lib:RegisterTerrainPartitionIndex("forever", world, 4, header, weighted))

assert(lib:RegisterTerrainPartitionIndex("forever", world, 4, header, index))
local imports = 0
C_AddOns.LoadAddOn = function(name)
    local key = assert(tonumber(name:match("^APR_NavData_Forever_900_(%d+)$")))
    imports = imports + 1
    assert(lib:RegisterTerrainPartitionPages("forever", world, 4, key, declaration(key)))
    return true
end
provider:GetGuidanceHeight(F.point(1, 1))
provider:CanFollowWalkingSegment(F.point(1, 1, 0), F.point(11, 1, 0))
assert(imports == 0, "Synchronous guidance queries must leave cold companion data unloaded")
local batch = provider:CreateCostJob(F.point(1, 1), {F.point(4, 1), F.point(11, 1)})
local status, costs
for _ = 1, 20 do
    frameTime = frameTime + 0.016
    local priorImports = imports
    status, costs = batch:Step(100000, 1000)
    assert(imports - priorImports <= 1, "A single slice must never start two native imports")
    if status ~= "planning" then break end
end
assert(status == "ready" and imports == 2 and costs.costs[1].state == "ready")

assert(lib:RegisterTerrainPartitionIndex("forever", world, 5, header, index))
frameTime = 12
C_AddOns.LoadAddOn = function(name)
    imports = imports + 1
    local key = tonumber(name:match("_(%d+)$"))
    return lib:RegisterTerrainPartitionPages("forever", world, 5, key, declaration(key))
end
local first = provider:CreatePathJob(F.point(1, 1), F.point(4, 1), {})
local second = provider:CreatePathJob(F.point(9, 1), F.point(12, 1), {})
assert(F.finish(first) == "ready" and imports == 3)
assert(second:Step(100000, 1000) == "planning" and imports == 3)
assert(second:Step(100000, 1000) == "planning" and imports == 3)
frameTime = frameTime + 0.016
assert(F.finish(second) == "ready" and imports == 4)

local function u32(value) return string.char(value, 0, 0, 0) end
local function portalRow(key, baseOffset)
    return u32(key) .. u32(key) .. u32(baseOffset) .. string.char(2, 0, 7, 0)
end
local topology = lib.Copy(index)
topology.pages = { portalRow(1, 0) .. portalRow(2, 2) }
topology.components = { u32(0) .. u32(1) .. u32(2) .. u32(0) }
topology.dag = { u32(0) .. u32(1) .. u32(1) .. u32(2) }
assert(lib:RegisterTerrainPartitionIndex("forever", world, 6, header, topology))
local function reachable(a, b, c, d)
    return runtime.PartitionPortalReachable(runtime.Data(world), a, b, c, d)
end
assert(reachable(1, 1, 2, 1) == nil)
runtime.active = { quantum = 1000 }
assert(reachable(1, 1, 2, 2) == true)
assert(reachable(1, 1, 2, 1) == true)
assert(reachable(2, 1, 1, 2) == false)
assert(reachable(1, 3, 2, 1) == nil)
topology.dag = { "bad" }
assert(lib:RegisterTerrainPartitionIndex("forever", world, 7, header, topology))
assert(reachable(2, 1, 1, 2) == nil)
runtime.active = nil

local instance = setmetatable({ profile = "forever" }, lib.Instance)
local retail = setmetatable({ profile = "retail" }, lib.Instance)
local elapsed = 0
debugprofilestop = function() return elapsed end
assert(retail:BeginTerrainFrame() == nil)
assert(not retail:HasDeferredTerrainImports(world) and not instance:HasDeferredTerrainImports(world + 1))
lib:RegisterTerrainData("forever", world + 1, sample, 1)
assert(not instance:HasDeferredTerrainImports(world + 1) and instance:HasDeferredTerrainImports(world))
frameTime = 20
assert(lib:RegisterTerrainPartitionIndex("forever", world, 8, header, index))
local data = runtime.Data(world)
local calls = 0
C_AddOns.LoadAddOn = function(name)
    calls = calls + 1
    assert(runtime.active == nil and not runtime.EnsureTerrainPage(data, 2))
    if calls == 1 then error("fixture import failed") end
    return lib:RegisterTerrainPartitionPages("forever", world, 8, tonumber(name:match("_(%d+)$")), declaration(1))
end
local token = instance:BeginTerrainFrame()
elapsed = 1
local abandoned = provider:CreatePathJob(F.point(9, 1), F.point(12, 1), {})
assert(abandoned:Step(100, 5) == "planning" and abandoned.workLastStep == 100)
assert(token.deferred and calls == 0)
abandoned:Cancel()
local retry = provider:CreatePathJob(F.point(1, 1), F.point(4, 1), {})
assert(instance:BeginTerrainFrame() == token)
assert(retry:Step(100, 5) == "planning" and calls == 0)
frameTime = frameTime + 0.016
assert(not instance:BeginTerrainFrame().deferred)
assert(abandoned:Step(100, 5) == "cancelled")
assert(F.finish(retry) == "unavailable" and calls == 1)
local recovered = provider:CreatePathJob(F.point(1, 1), F.point(4, 1), {})
assert(recovered:Step(100, 5) == "planning" and calls == 1)
frameTime = frameTime + 0.016
instance:BeginTerrainFrame()
assert(F.finish(recovered) == "ready" and calls == 2)
assert(not runtime.EnsureTerrainPage(data, 2) and calls == 2)

-- A fresh frame still cannot enter the native loader with an expired grant.
frameTime = frameTime + 0.016
token = instance:BeginTerrainFrame()
local worker = { limit = 9, deadline = elapsed, clock = debugprofilestop }
local pending = coroutine.create(function() return runtime.EnsureTerrainPage(data, 2) end)
runtime.active = worker
assert(coroutine.resume(pending) and coroutine.status(pending) == "suspended")
assert(calls == 2 and token.deferred and worker.workLastStep == worker.limit)
worker.deadline = elapsed + 5
assert(coroutine.resume(pending) and coroutine.status(pending) == "suspended" and calls == 2)
frameTime = frameTime + 0.016
instance:BeginTerrainFrame()
C_AddOns.LoadAddOn = function()
    calls = calls + 1
    return lib:RegisterTerrainPartitionPages("forever", world, 8, 2, declaration(2))
end
local resumed, loaded = coroutine.resume(pending)
assert(resumed and loaded and coroutine.status(pending) == "dead" and calls == 3)
runtime.active = nil
