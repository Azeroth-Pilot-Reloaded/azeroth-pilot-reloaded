-- A native zero can be unavailable in an interior; infer only proved layers.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({ connections = {} })
data.env.requestTerrainData = function() return "ready" end
local lib = LibStub("LibAPRNavigation-1.0")
assert(type(data.ResolveTerrainGroundPosition) == "function", "A geometry-backed native-height resolver is required")
local function point(x, y, z, native)
    return { x = x, y = y, z = z, instanceID = 8, uiMapID = 18, region = "room",
        positionSource = native and "unit" or nil, observedZ = native and z or nil }
end
local nodes, anchors = {}, {}
local function surface(id, x, y, z, radius)
    local node = point(x, y, z); node.id = id; nodes[#nodes + 1] = node
    anchors[#anchors + 1] = { node = id, minX = x-radius, maxX = x+radius,
        minY = y-radius, maxY = y+radius, minZ = z-1, maxZ = z+1, mode = "ground", bidirectional = true }
end
surface("zero", -20, 0, 0, 2)
surface("zero-stacked", -40, 0, 0, 2)
surface("zero-overhead", -40, 0, 25, 2)
surface("corridor", -10, 0, 25, 2)
surface("stacked-low", 40, 0, 10, 2)
surface("stacked-high", 40, 0, 30, 2)
surface("connected-entry", 60, 0, 25, 5)
surface("connected-low", 65, 0, 25, 5)
surface("connected-overhead", 65, 0, 55, 5)
surface("outdoor", -60, 0, 20, 2); anchors[#anchors].indoor, nodes[#nodes].indoor = false, false
surface("indoor", -60, 0, 25, 2); anchors[#anchors].indoor, nodes[#nodes].indoor = true, true
surface("ramp-left", 85, 0, 25, 5)
surface("ramp-right", 95, 0, 26, 5)
local path = { point(0, 0, 30), point(10, 0, 25), point(10, 10, 20), point(20, 10, 15), point(20, 20, 10) }
for index, p in ipairs(path) do
    surface("stair-" .. index, p.x, p.y, p.z, 2)
    surface("upper-" .. index, p.x, p.y, p.z + 30, 2)
end
lib:RegisterTerrainData("retail", 8, { format = 1, nodes = nodes, anchors = anchors, edges = {} }, 1, "fixture")
local build = data:CreateTerrainEdgeBuild({ start = nodes[1], goal = nodes[2] })
for _ = 1, 1000 do if build:Step(64, 100) ~= "planning" then break end end
assert(build.status == "ready", "The synthetic ground visibility grid must be built")
local indoor = point(-60, 0, 0, true); indoor.indoors = true
assert(data:ResolveTerrainGroundPosition(indoor).z == 25, "Known indoor provenance excludes the overlapping outdoor terrain")
indoor.indoors, data._terrainGroundObservation = false, nil
assert(data:ResolveTerrainGroundPosition(indoor).z == 20, "An outdoor observation excludes the overlapping indoor collision")
indoor.indoors, data._terrainGroundObservation = nil, nil
assert(data:ResolveTerrainGroundPosition(indoor) == nil, "Unavailable indoor state cannot invent triangle provenance")
assert(data:ResolveTerrainGroundPosition(point(90, 0, 0, true)),
    "An inclusive face shared by two connected sloping ground cells is one traversable surface")
data._terrainGroundObservation = nil
local zero = point(-20, 0, 0, true)
local resolved, zeroReason = data:ResolveTerrainGroundPosition(zero)
assert(resolved and resolved.z == 0 and resolved.observedZ == 0 and resolved.heightSource == "terrain",
    "An observed zero on a proved sea-level floor remains a real zero: " .. tostring(zeroReason))
local _, stackedZeroReason = data:ResolveTerrainGroundPosition(point(-40, 0, 0, true))
assert(stackedZeroReason == "ambiguous_terrain_surface", "Native zero does not select the lowest of two overlapping floors")
local raw = point(-10, 0, 0, true)
resolved = data:ResolveTerrainGroundPosition(raw)
assert(resolved and resolved.z == 25 and resolved.observedZ == 0 and resolved.heightSource == "terrain" and raw.z == 0,
    "A unique XY layer supplies effective geometry while keeping the raw observation intact")
local authored = point(-10, 0, 0)
assert(data:ResolveTerrainGroundPosition(authored).z == 0, "Authored zero coordinates cannot be rewritten as native failures")
local _, reason = data:ResolveTerrainGroundPosition(point(40, 0, 0, true))
assert(reason == "ambiguous_terrain_surface", "Overlapping floors need connected progress proof")
local function finish(job)
    for _ = 1, 10000 do
        local status, result, coverage = job:Step(64, 100)
        if status ~= "planning" then return status, result, coverage end
    end
    error("Synthetic local route did not complete")
end
data._terrainGroundObservation = nil
local coldStatus, coldResult, coldCoverage = finish(data:CreateLocalRoute({
    start = point(40, 0, 0, true), goal = point(40, 0, 10) }))
assert(coldStatus == "waiting_data" and coldResult == nil and coldCoverage.missing[1].reason == "ambiguous_terrain_surface",
    "Cold ambiguity waits explicitly instead of publishing a direct chord or fabricating a first guidance layer")
local recovered = finish(data:CreateLocalRoute({ start = point(-10, 0, 0, true), goal = point(-10, 0, 25) }))
assert(recovered == "ready", "Moving into a unique proved layer unblocks the same native-height mechanism")
local reusedNative = point(40, 0, 10, true)
data:ResolveTerrainGroundPosition(reusedNative)
reusedNative.z, reusedNative.observedZ = 0, 0
assert(data:ResolveTerrainGroundPosition(reusedNative).z == 10,
    "A known nonzero native observation confirmed by the grid can seed a later placeholder zero")
data._terrainGroundObservation = nil
local foreign = point(-10, 0, 0, true); foreign.region = "other"
assert(data:ResolveTerrainGroundPosition(foreign) == nil, "A foreign region cannot borrow an XY-matching floor")
assert(data:ResolveTerrainGroundPosition(point(55, 0, 0, true)).z == 25)
assert(data:ResolveTerrainGroundPosition(point(65, 0, 0, true)).z == 25,
    "Before guidance exists, a fully proved connected ground segment can preserve the known layer")
local route = { totalSeconds = 20, segments = { { kind = "walk", terrain = true,
    movementMode = "ground", from = path[1], to = path[5], polyline = path, seconds = 20 } } }
local guidance = data:CreateGuidance(route, { arrivalRange = 0.5 })
local previousProgress = 101
for index, expected in ipairs(path) do
    resolved, reason = data:ResolveTerrainGroundPosition(point(expected.x, expected.y, 0, true), guidance)
    assert(resolved and resolved.z == expected.z and resolved.observedZ == 0,
        "Connected stair progress must keep its layer while the native API continuously reports zero")
    local _, status = guidance:Update(resolved)
    assert(status ~= "deviated" and status ~= "waiting_data")
    local progress = guidance.segmentIndex*100 + guidance.pointIndex
    assert(progress >= previousProgress and (status == "arrived" or guidance.pointIndex <= index + 1),
        "Recovering stair height must preserve monotonic local corner progress")
    previousProgress = progress
end
assert(guidance.status == "arrived", "All five observed stair samples complete the actual descending corridor")
local stale = data:CreateGuidance(route, {})
assert(data:ResolveTerrainGroundPosition(point(0, 0, 0, true), stale))
assert(data:ResolveTerrainGroundPosition(point(40, 0, 0, true), stale) == nil,
    "A large position jump cannot use the old corridor as height proof")

-- The actual native provider and controller retain raw zero while guiding stairs.
fixture.currentMap = 18
data.GetPositionRegion = function() return "room" end
dofile("APR-Core/utils/NavigationZones.lua")
fixture.player = { x = -10, y = 0, z = 0, instanceID = 8 }
local native = APR:GetNavigationPlayerPosition()
assert(native.z == 25 and native.observedZ == 0 and native.positionSource == "unit")
assert(data:NormalizeLocation(native).observedZ == 0, "Observation identity survives library normalization")
APR.settings, APR.ActiveRoute = { profile = { enableAddon = true } }, "fixture-route"
function APR:NewModule() return {} end
local context = {}
function APR:IsStepContextCurrent(value) return value == context end
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
nav.Notify, nav.RequestUpdate = function() end, function() end
nav.MarkRouteReady = function(self) self.state = "ready" end
local row = nav:PrepareGuidanceStep(route.segments[1], 1, 0, path[1])
nav.queue, nav.cursor, nav.context, nav.state = { row }, 1, context, "guiding"
for _, expected in ipairs(path) do
    fixture.player = { x = expected.x, y = expected.y, z = 0, instanceID = 8 }
    nav:PollArrival()
    assert(row.terrainPosition and row.terrainPosition.z == expected.z and row.terrainPosition.observedZ == 0,
        "Polling uses the proved stair elevation while raw native height stays observable")
end
assert(nav.state == "ready", "The controller completes the downstairs terrain leg with native zero throughout")
lib.terrainRevision = lib.terrainRevision + 1
assert(data:ResolveTerrainGroundPosition(raw) == nil, "Retired geometry cannot project a new native observation")
local staleProjected = point(0, 0, 30, true)
staleProjected.heightSource, staleProjected.observedZ = "terrain", 0
assert(nav:PollTerrainStep(row, staleProjected) == "waiting_data" and row.terrainHeightReason == "terrain_height_unavailable",
    "An old derived nonzero height cannot bypass a failed resolver after the geometry retires")
nav.waitingData, nav.lastPlanning = true, { status = "no_path", terrainReason = "ambiguous_terrain_surface" }
nav:SearchFailed({})
assert(nav.state == "waiting_data" and nav.reason == "ambiguous_terrain_surface",
    "The controller retains the precise height blocker after retiring the failed search")
print("Terrain height: observed zero, unique surfaces, ambiguous layers, connected stairs and stale/foreign observations")
