-- Bounded room inventory must remain local, including overlapping elevations.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({ connections = {} })
local lib = LibStub("LibAPRNavigation-1.0")
function GetBuildInfo() return "12.1.5", "42" end
function APR:GetGameVersion() return "retail" end
local function scope(id, low, high)
    return { id = id, bounds = { minX = 0, maxX = 100, minY = 0, maxY = 100, minZ = low, maxZ = high },
        accessKey = "sealed", groundOnly = true }
end
local lower, upper = scope("lower", 10, 30), scope("upper", 50, 70)
local packs = {
    { id = "west", addon = "FixtureWest", revision = 1, scope = lower,
        bounds = { minX = 0, maxX = 50, minY = 0, maxY = 100 } },
    { id = "east", addon = "FixtureEast", revision = 1, scope = lower,
        bounds = { minX = 50, maxX = 100, minY = 0, maxY = 100 } },
    { id = "upper", addon = "FixtureUpper", revision = 1, scope = upper },
}
APR.NavigationTerrainIndex = { schema = 1, profiles = { retail = {
    builds = { ["12.1.5.42"] = true }, worlds = {
        [9] = { packs = packs },
        [10] = { packs = { { id = "legacy", addon = "FixtureLegacy", revision = 1 } } },
    },
} } }
local loaded, loads = {}, {}
C_AddOns = {
    IsAddOnLoaded = function(addon) return loaded[addon] == true, loaded[addon] == true end,
    LoadAddOn = function(addon)
        loads[#loads + 1] = addon
        for _, pack in ipairs(packs) do
            if pack.addon == addon then
                lib:RegisterTerrainData("retail", 9, { format = 1, profile = "retail", build = "12.1.5.42",
                    scope = lib.Copy(pack.scope), nodes = {}, edges = {} }, pack.revision, pack.id)
                loaded[addon] = true
                return true
            end
        end
    end,
}
function InCombatLockdown() return false end
dofile("APR-Core/features/navigation/NavigationTerrain.lua")
local loader = APR.NavigationTerrain
local function point(x, z, key) return { x = x, y = 25, z = z, instanceID = 9, uiMapID = 101, accessKey = key } end
assert(not loader:HasData("retail", 9, point(25, 40)),
    "A room pack must not claim the unrelated altitude between two storeys")
assert(not loader:HasData("retail", 9, point(-5, 20)) and loader:HasData("retail", 9, point(25, 20)))
assert(loader:HasData("retail", 9, point(25, nil)) and loader:HasData("retail", 9, point(25, 20, "sealed")),
    "Unknown altitude stays conservative; a known compatible access key remains usable")
assert(not loader:HasData("retail", 9, point(25, 20, "different")),
    "A known incompatible access channel is not covered")
local nativeZero = point(25, 0, "sealed"); nativeZero.positionSource = "unit"
assert(loader:HasData("retail", 9, nativeZero), "The loader preserves native zero's unknown-height annotation")
nativeZero.accessKey = nil
assert(not loader:HasData("retail", 9, nativeZero), "Native placeholder zero cannot borrow an unproved isolated access key")
nativeZero.accessKey, nativeZero.heightSource = "sealed", "terrain"
assert(not loader:HasData("retail", 9, nativeZero), "A proved zero surface retains its real altitude bounds")
local boundary = point(0, 20); boundary.terrainBoundary = lower.id
assert(not loader:HasData("retail", 9, boundary), "A labelled external gateway stays outside its room scope")
assert(loader:HasData("retail", 9) and loader:HasData("retail") and not loader:HasData("retail", 11))
assert(loader:HasData("retail", 10, point(-1000, 400)), "Legacy packs retain world-level inventory semantics")
local scopes, unbounded = loader:GetScopes("retail", 9)
assert(#scopes == 2 and unbounded == false and scopes[1].id == "lower" and scopes[2].id == "upper",
    "Several tiles in one room advertise its scope once")
scopes, unbounded = loader:GetScopes("retail", 10)
assert(#scopes == 0 and unbounded == true)
assert(loader:GetScopes("retail", 11) == nil, "Missing inventory permits the library's registration fallback")
local env = APR.NavigationAdapter.environment
scopes, unbounded = env.getTerrainScopes("retail", 9)
assert(#scopes == 2 and unbounded == false, "The adapter preserves both inventory return values")
APR.NavigationTerrain = nil
assert(env.getTerrainScopes("retail", 9) == nil, "Missing host inventory preserves library fallback")
APR.NavigationTerrain = loader
assert(loader:RequestData("retail", 9, point(25, 40)) == "missing" and #loads == 0)
assert(loader:RequestData("retail", 9, point(25, 20)) == "ready" and #loads == 1 and loads[1] == "FixtureWest")
assert(loader:RequestData("retail", 9, point(75, 20)) == "ready" and #loads == 2 and loads[2] == "FixtureEast",
    "Selection intersects the room's 3D scope with each tile's XY bounds")
assert(loader:RequestData("retail", 9, point(25, 60)) == "ready" and #loads == 3 and loads[3] == "FixtureUpper")
assert(loader:RequestData("retail", 9) == "ready" and #loads == 3,
    "A bounded-world request can reuse every registered scope")
local registered = lib.terrainDatasets.retail[9].packs.west.data
registered.scope.bounds.maxZ = 31
assert(loader:RequestData("retail", 9, point(25, 20)) == "missing",
    "A loaded tile with different scope metadata cannot satisfy the index declaration")
registered.scope = lib.Copy(lower)
registered.scope.groundOnly = false
assert(loader:RequestData("retail", 9, point(25, 20)) == "missing",
    "Movement restrictions belong to the exact scope registration contract")
registered.scope = lib.Copy(lower)
assert(loader:RequestData("retail", 9, point(25, 20)) == "ready")
lib.terrainDatasets.retail[9] = nil
loaded, loads = {}, {}
assert(loader:RequestData("retail", 9) == "planning" and #loads == 1)
assert(loader:RequestData("retail", 9) == "planning" and #loads == 2)
assert(loader:RequestData("retail", 9) == "ready" and #loads == 3,
    "Whole bounded-world requests load all scopes in slices of at most one addon")
local maxZ = lower.bounds.maxZ
lower.bounds.maxZ = lower.bounds.minZ
scopes, unbounded = loader:GetScopes("retail", 9)
assert(unbounded == true and loader:RequestData("retail", 9) == "missing" and #loads == 3,
    "Malformed scope metadata fails closed without authorizing an exterior shortcut or native load")
lower.bounds.maxZ = maxZ
local opaque = {}
function issecretvalue(value) return rawequal(value, opaque) end
assert(loader:HasData("retail", 9, point(25, opaque)), "Protected optional height remains unknown")
local secretXY = point(25, 20); secretXY.x = opaque
assert(not loader:HasData("retail", 9, secretXY), "Protected required coordinates never reach numeric geometry")
function GetBuildInfo() return "12.1.5", "43" end
assert(not loader:HasData("retail", 9, point(-5, 20)) and loader:HasData("retail", 9, point(25, 20)))
assert(loader:RequestData("retail", 9) == "missing" and #loads == 3,
    "An incompatible build keeps its declared scope local while refusing its geometry")
function GetBuildInfo() return "12.1.5", "42" end

-- Outside endpoints can still cut through a managed room: the host must search.
local start, goal = point(-10, 20), point(110, 20)
APR.PlayerID, APR.ActiveRoute = "fixture-player", "fixture-route"
APR.settings = { profile = { enableAddon = true } }
APR.GAME_VERSIONS = { Forever = "forever" }
function APR:NewModule() return {} end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetMoney() return 0 end
function APR:GetNavigationPlayerPosition() return start end
local step = { Zone = 101, Coord = { x = 25, y = 110, z = 20, instanceID = 9, mapID = 101 } }
local definition = { step }
local context = { route = APR.ActiveRoute, index = 1, definition = definition, revision = 1 }
function APR:CaptureStepContext() return context end
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetCurrentStep() return step, 1, definition end
function APR:GetCurrentRouteMapIDsAndName() return { 101 }, 101 end
function APR:GetStepCoord(value) return value.Coord, value.Zone end
function APR:CheckNavigationZoneReady() return true end
APR.NavigationAdapter.CreatePreparation = function() return { Step = function() return "ready" end } end
APR.taxiData = { BuildEdges = function() return {} end }
C_Timer = { NewTimer = function(_, callback) return { callback = callback, Cancel = function() end } end }
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
nav.Notify, nav.Render = function() end, function() end
nav.GetThreshold = function() return 10000 end
nav.GetMovementSpeed = function() return 7 end
nav.state, nav.destination, nav._routedStepContext = "ready", goal, context
nav._routeInputs = { geometryRevision = APR.navigationGeometryRevision }
local objective = nav.IsObjectiveCurrent
nav.IsObjectiveCurrent = function() return true end
assert(data:CanWalk(start, goal) and not data:HasTerrainData(start) and not data:HasTerrainData(goal))
assert(not nav:IsDirectRouteValid(start), "An existing direct baseline cannot cross a room between outside endpoints")
start.y, goal.y = -10, -10
assert(nav:IsDirectRouteValid(start), "An unrelated exterior chord remains directly walkable")
start.y, goal.y = 25, 25
nav.IsObjectiveCurrent = objective
nav:Cancel("cleared")
nav:Update(context)
assert(nav.state == "planning" and not nav.recomputeKeepingDirect,
    "A cold baseline crossing a bounded scope cannot publish a direct chord while catalogue work is pending")
nav:Cancel("cleared")
print("Terrain host scopes: elevation/access inventory, exact lazy packs, adapter fallback and exterior crossing baselines")
