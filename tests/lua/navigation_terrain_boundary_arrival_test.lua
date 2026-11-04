-- A terrain gateway must be reached before following its interior corridor.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.currentMap = 501
local data = fixture:Load({ connections = {} })
local function point(x, z)
    return data:NormalizeLocation({ x = x, y = 0, z = z, instanceID = 0, uiMapID = 501 })
end
local context = {}
APR.settings = { profile = { enableAddon = true } }
APR.NewModule = function() return {} end
APR.ActiveRoute = "synthetic-boundary"
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetNavigationPlayerPosition() return fixture.player end
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
nav.Notify, nav.RequestUpdate = function() end, function() end
nav.MarkRouteReady = function(self) self.state = "ready" end
local source, gateway, destination = point(0, 10), point(100, 10), point(150, 10)
gateway.terrainBoundary = "synthetic-interior"
local entry = nav:PrepareGuidanceStep({ kind = "walk", from = source, to = gateway }, 1, 1, source)
assert(entry.terrainBoundary == "synthetic-interior" and entry.arrivalRange == 2 and entry.arrivalZTolerance == 2,
    "A gateway's precision and height proof must survive row preparation")
local after = nav:PrepareGuidanceStep({ kind = "walk", from = gateway, to = destination }, 2, 1, gateway)
nav.queue, nav.cursor, nav.state, nav.context = { entry, after }, 1, "guiding", context
fixture.player = point(85, 10)
nav:PollArrival()
assert(nav.cursor == 1, "The ordinary 20-yard arrival radius cannot enter a terrain corridor early")
fixture.player = point(99, 0)
nav:PollArrival()
assert(nav.cursor == 1, "Matching XY on another height cannot reach the gateway")
fixture.player = point(99)
nav:PollArrival()
assert(nav.cursor == 1, "Unknown height cannot prove a gateway with known elevation")
fixture.player = point(99, 10)
nav:PollArrival()
assert(nav.cursor == 2, "The gateway advances once its XY and height are observed within tolerance")
fixture.player = point(135, 10)
nav:PollArrival()
assert(nav.state == "ready", "Ordinary destinations retain their existing 20-yard arrival behavior")
print("Terrain gateways: precise attachment, observed height and ordinary arrival compatibility passed")
