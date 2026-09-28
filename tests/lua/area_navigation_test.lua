-- Map percentages must be converted to world yards before computing area radii.
function LibStub() return { GetLocale = function() return {} end } end

APR = {}
function APR:NewModule() return {} end

dofile("APR-Core/features/navigation/WorldCoordinateConverter.lua")
local converter = APR.worldCoordinateConverter
function converter:ConvertMapCoordinate(zone, x, y)
    assert(zone == 2521)
    if x == 99 then return nil end
    return { x = x * 100, y = y * 10 }
end

local points = { { 0, 0, 35 }, { 10, 10, 20 }, { 6, 5, 1 } }
local radius = converter:GetMapAreaRadius(2521, 5, 5, points)
assert(radius == 538, "Range is in world yards and includes the point's own arrival radius")
for _, point in ipairs(points) do
    local dx, dy = point[1] * 100 - 500, point[2] * 10 - 50
    assert(math.sqrt(dx * dx + dy * dy) + point[3] <= radius)
end
assert(converter:GetMapAreaRadius(2521, 5, 5, { { 5, 5, 35 } }) == 35)
assert(converter:GetMapAreaRadius(2521, 99, 5, points) == nil)
assert(converter:GetMapAreaRadius(2521, 5, 5, { { 99, 5, 35 } }) == nil,
    "Missing client geometry must not produce a fabricated radius")
print("Farming areas: world-yard conversion, full point coverage, arrival margins and missing geometry passed")

local mixed = { { 0, 0, 10, true }, { 10, 10, 20, true }, { -200, 300, 40, false } }
local center = converter:GetMixedAreaCenter(2521, mixed)
assert(center.x == 400 and center.y == 150, "Center combines converted and recorded world coordinates")
local mixedRadius = converter:GetMixedAreaRadius(2521, mixed)
for _, point in ipairs(mixed) do
    local coord = point[4] and converter:ConvertMapCoordinate(2521, point[1], point[2])
        or { x = point[1], y = point[2] }
    local dx, dy = coord.x - center.x, coord.y - center.y
    assert(math.sqrt(dx * dx + dy * dy) + point[3] <= mixedRadius)
end
assert(converter:GetMixedAreaCenter(2521, {}) == nil)
assert(converter:GetMixedAreaCenter(2521, { { 99, 5, 35, true }, { 10, 20, 40, false } }) == nil)
assert(converter:GetMixedAreaRadius(2521, { { 99, 5, 35, true }, { 10, 20, 40, false } }) == nil)
print("Mixed farming areas: common units, complete coverage and missing geometry passed")
