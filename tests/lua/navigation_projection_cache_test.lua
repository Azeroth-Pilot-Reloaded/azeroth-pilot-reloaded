local env = dofile("tests/lua/route_ui_test_env.lua")
local now, calls, available = 0, 0, true
function GetTime() return now end
local hbd = { GetZoneCoordinatesFromWorldInstance = function(_, x, y)
    calls = calls + 1
    if available then return x / 1000, y / 1000 end
end }
local stub = LibStub
function LibStub(name, ...)
    if name == "HereBeDragons-2.0" then return hbd end
    return stub(name, ...)
end
C_Map = { GetMapInfo = function() return { parentMapID = 0, mapType = 3 } end }
APR.GetPlayerMapPos = nil
dofile("APR-Core/features/navigation/Preview.lua")
local preview = APR.navigationPreview
local point = { Coord = { x = 100, y = 200 }, instanceID = 0, uiMapID = 1 }
local x, y = preview:ProjectPoint(point, 1)
assert(x == 0.1 and y == 0.2 and calls == 1)
for _ = 1, 1000 do assert(preview:ProjectPoint(point, 1) == 0.1) end
assert(calls == 1, "A fixed point on the same map must reuse the previous projection")
point.Coord.x = 300
assert(preview:ProjectPoint(point, 1) == 0.3 and calls == 2, "Mutable player coordinates must never reuse stale XY")
point.instanceID = 1
preview:ProjectPoint(point, 1)
assert(calls == 3)
point.uiMapID = 2
preview:ProjectPoint(point, 2)
assert(calls == 4)
point.accessKey = "interior"
preview:ProjectPoint(point, 2)
assert(calls == 5)
point.floor = 3
preview:ProjectPoint(point, 2)
assert(calls == 6)
APR.navigationGeometryRevision = 1
preview:ProjectPoint(point, 2)
assert(calls == 7, "A changed geometry revision invalidates point projections")
APR.NavigationData = { positions = {} }
preview:ProjectPoint(point, 2)
assert(calls == 8)
APR.NavigationData.positions = {}
preview:ProjectPoint(point, 2)
assert(calls == 9, "A direct library geometry invalidation is visible without a host revision")
preview:InvalidateProjectionCache()
preview:ProjectPoint(point, 2)
assert(calls == 10)

available = false
local loading = { Coord = { x = 1, y = 2 }, instanceID = 0, uiMapID = 1 }
assert(preview:ProjectPoint(loading, 1) == nil)
local failed = calls
for _ = 1, 100 do assert(preview:ProjectPoint(loading, 1) == nil) end
assert(calls == failed, "Loading failures must not rebuild ancestry for every segment in the same tick")
available, now = true, 0.21
assert(preview:ProjectPoint(loading, 1) == 0.001 and calls > failed,
    "Late geometry remains retryable without changing routes or reloading the addon")

local bounded = { Coord = { x = 4, y = 5 }, instanceID = 0 }
for map = 1, 12 do preview:ProjectPoint(bounded, map) end
local before = calls
preview:ProjectPoint(bounded, 1)
assert(calls > before, "Browsing many maps must evict old per-point projection entries")
local secret = {}
function issecretvalue(value) return value == secret end
bounded.Coord.x = secret
before = calls
assert(preview:ProjectPoint(bounded, 1) == nil and calls == before,
    "Restricted coordinates cannot enter numeric comparisons or projection APIs")
print("Point projection cache: stable hits, movement/maps/access/floors, geometry revisions, bounded entries, transient retries and secret safety passed")
