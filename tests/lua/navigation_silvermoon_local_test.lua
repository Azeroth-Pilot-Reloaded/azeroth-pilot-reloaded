-- Reproduce the 2026-10-22 report through real geography and controller code.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.currentMap, fixture.faction = 2393, "Horde"
fixture.player = { x = 8547.3, y = -4815.3, instanceID = 0 }
fixture.translations = setmetatable({}, { __index = function(_, key) return key end })
local data = fixture:Load()
local noop = function() end
dofile("APR-Core/utils/Utils.lua")
APR.Debug = noop
dofile("APR-Core/utils/NavigationZones.lua")

local step = { Zone = 2395, Coord = { x = -4577.6, y = 8016.7 }, GossipOptionIDs = { 136992 } }
local steps = { {}, {}, {}, {}, {}, step }
APR.PlayerID, APR.ActiveRoute, APR.RouteQuestStepList = "player", "route", { route = steps }
APR.settings, APR.GAME_VERSIONS = { profile = { enableAddon = true } }, { Forever = "forever" }
APRData = { player = { route = 6 } }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
function APR:GetCurrentStep() return step, 6, steps end
function APR:GetCurrentRouteMapIDsAndName() return { 2393 }, 2393 end
function APR:GetStepCoord(value) return value.Coord, value.Zone end
function APR:GetPreferredStepZone(value) return value.Zone end
function UnitIsDeadOrGhost() return false end
function IsIndoors() return true end
function GetUnitSpeed() return 0, 7.1399984359741, 0 end
function GetMoney() return 100000 end
C_Timer = { NewTimer = function(_, callback)
    return { callback = callback, Cancel = function(self) self.cancelled = true end }
end }
local hides, plans = 0, 0
APR.Arrow = {
    SetArrowActive = function(self, active)
        self.Active = active
        if not active then hides = hides + 1 end
    end,
    SetCoord = function(self)
        local active = APR.navigation:GetActiveStep()
        local coord = active and active.Coord or step.Coord
        self.x, self.y, self.Active = coord.x, coord.y, true
    end,
}
APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
dofile("APR-Core/features/questing/StepTransitions.lua")
APR.NavigationPlanner = { Create = function()
    plans = plans + 1
    return { Step = function() return "planning" end, Cancel = noop }
end }
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
nav:Update()
assert(plans == 1 and nav.search, "Even the 581-yard objective must compare available shortcuts")
assert(nav.destination.uiMapID == 2395, "Use the step zone rather than the route map")
local context, generation = nav.context, nav.generation
nav:Publish({ segments = { { kind = "walk", from = nav.start, to = nav.destination, seconds = 82 } } }, context, generation)
assert(nav:GetState() == "ready" and not nav:GetActiveStep())
assert(APR.Arrow.x == -4577.6 and APR.Arrow.y == 8016.7 and APRData.player.route == 6)
local before = hides
nav:ForceRefresh(); nav:Update()
assert(plans == 2 and nav.recomputeKeepingDirect and APR.Arrow.Active,
    "Keep confirmed direct guidance visible while comparing a new catalogue")
local staleContext, staleGeneration = nav.context, nav.generation
nav:ForceRefresh(); nav:Update()
nav:Publish({ segments = { { kind = "walk", from = nav.start, to = nav.destination, seconds = 82 } } },
    nav.context, nav.generation)
nav:Publish({ queue = { { kind = "portal", id = "stale" } } }, staleContext, staleGeneration)
assert(nav:GetState() == "ready" and not nav:GetActiveStep() and hides == before and APRData.player.route == 6)
local count = plans
for _ = 1, 50 do nav:Update() end
assert(plans == count, "Idle local updates must not rebuild the catalogue")
-- Being nearby never overrides the entrance/access restriction.
data.config.IsolatedAreas[2393] = "test-interior"
data:InvalidatePositionCache()
nav:ForceRefresh(); nav:Update()
assert(plans == count + 1 and nav.search and not nav.zoneReady)
print("Silvermoon: compare shortcuts, retain direct arrow, reject stale results and preserve access restrictions")
