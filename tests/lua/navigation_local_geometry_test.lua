-- Synthetic geometry only: editable transport observations are not regression fixtures.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local previous = LibStub:NewLibrary("LibAPRNavigation-1.0", 28)
previous.datasets = { retail = { additional_portals = { connections = {} } } }
previous.dataRevisions = {}
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, file in ipairs({ "Core.lua", "Geography.lua", "Conditions.lua" }) do
    dofile(root .. file)
end
local lib = LibStub("LibAPRNavigation-1.0")
assert(lib.datasets.retail.additional_portals == nil)
lib:RegisterData("retail", "additional_portals", { connections = {} }, 99)
assert(lib.datasets.retail.additional_portals == nil, "An older embed cannot restore a retired split catalogue")
lib:RegisterData("synthetic", "geometry", {
    config = {
        LocalRegions = {
            [101] = {
                { key = "road", polygon = { { 0.2, 0.2 }, { 0.6, 0.2 }, { 0.6, 0.8 }, { 0.2, 0.8 } } },
                { key = "dock", center = { 0.8, 0.8 }, radius = 5 },
            },
        },
        MapRemaps = { [100] = { { instanceID = 8, minX = 80, maxX = 160, minY = 0, maxY = 100, mapID = 101 } } },
    },
})
local ready, projections = true, 0
local env = {
    getMapInfo = function(map) return { mapType = map == 100 and 2 or 3, parentMapID = map == 100 and 0 or 100 } end,
    mapToWorld = function(_, x, y)
        projections = projections + 1
        assert(x >= 0 and x <= 1 and y >= 0 and y <= 1, "Only normalized API samples")
        if not ready then return end
        return 8, 100 + 200 * x + 30 * y, 50 - 20 * x + 100 * y
    end,
}
local data = lib:New({ profile = "synthetic", environment = env })
local function pos(x, y) return data:NormalizeLocation({ space = "map", uiMapID = 101, x = x, y = y }) end
ready = false
assert(pos(0.3, 0.3) == nil)
ready = true
local road, outdoor, edge = pos(0.3, 0.3), pos(0.7, 0.3), pos(0.6, 0.5)
assert(road.accessKey == "road" and edge.accessKey == "road" and outdoor.accessKey == nil)
assert(data:CanWalk(road, edge) and not data:CanWalk(road, outdoor))
assert(pos(0.8, 0.8).accessKey == "dock")
local count = projections
data:GetLocationAccessKey(road)
assert(projections == count, "Successful local geometry is reused")
local marked = data:NormalizeLocation({
    space = "world",
    uiMapID = 101,
    instanceID = 8,
    x = road.x,
    y = road.y,
    accessKey = "explicit",
})
assert(marked.accessKey == "explicit")
local mapped = data:NormalizeLocation({ space = "world", uiMapID = 100, instanceID = 8, x = 100, y = 80 })
assert(mapped.uiMapID == 101)
local other = data:NormalizeLocation({ space = "world", uiMapID = 100, instanceID = 9, x = 100, y = 80 })
assert(other.uiMapID == 100, "A matching rectangle in another world does not remap")
assert(data:NormalizeLocation({ space = "map", uiMapID = 101, x = 0.5, y = 1.2 }) == nil)
local extended = data:NormalizeLocation({ space = "mapProjection", uiMapID = 101, x = 0.5, y = 1.2 })
assert(math.abs(extended.x - 236) < 0.00001 and math.abs(extended.y - 160) < 0.00001)
ready = false
assert(data:NormalizeLocation({ space = "mapProjection", uiMapID = 101, x = 0.5, y = 1.2 }) == nil)
data:InvalidatePositionCache()
assert(data.localRegionGeometry == nil)
ready = true
assert(pos(0.4, 0.4).accessKey == "road")
assert(data:CheckRequirements({ race = "SyntheticRace" }, { race = "SyntheticRace" }) == true)
assert(data:CheckRequirements({ race = "SyntheticRace" }, { race = "AnotherRace" }) == false)
assert(data:CheckRequirements({ race = "SyntheticRace" }, {}) == nil)
print(
    "Local geometry: affine extended maps, polygons, boundaries, circles, world-scoped remaps, retry/cache and race gates passed"
)
