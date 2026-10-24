-- APR hosts the standalone library session without activating temporary routes.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local completed, active = { [79573] = true }, {}
data.env.isQuestAvailable = function(id) return id ~= 84957 or completed[84956] == true end
data.env.isQuestCompleted = function(id) return completed[id] == true end
data.env.isQuestActive = function(id) return active[id] == true end
data.env.isQuestCompletedOnAccount = function() return false end
data.env.getCharacter = function() return { level = 90, faction = "Alliance", mapID = 2248 } end
local timers = {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers+1] = timer; return timer
end }
function debugprofilestop() return 0 end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function InCombatLockdown() return false end
function IsFlyableArea() return false end
function GetMoney() return 0 end
local function noop() end
APR.PlayerID, APR.ActiveRoute = "test", "parent"
APRData, APRCustomPath = { test = { parent = 8 } }, { test = { "parent" } }
APR.RouteQuestStepList = nil -- Any accidental dependency on authored routes fails.
APR.settings = { profile = { enableAddon = true } }
APR.Arrow, APR.event = { SetCoord = noop, SetArrowActive = noop }, { QueueStepRefresh = noop }
APR.currentStep = { AddQuestSteps = noop, AddQuestDivider = noop, AddStepButton = noop }
APR.SendMessage = noop
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
APR.GAME_VERSIONS = { Forever = "forever" }
local parent = { Zone = 2371, Coord = { x = 44, y = 99, mapID = 2371, instanceID = 2738 } }
local context = { route = "parent", index = 8, definition = { steps = { [8] = parent } } }
function APR:CaptureStepContext() return context end
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetCurrentStep() return parent, 8 end
function APR:PeekCurrentStep() return parent end
function APR:GetCurrentRouteMapIDsAndName() return { 2371 }, 2371 end
function APR:GetStepCoord(step) return step.Coord, step.Zone end
function APR:GetPreferredStepZone(step) return step.Zone end
function APR:CheckNavigationZoneReady() return true end
local position = { x = 2923, y = -2418.2, instanceID = 2552, uiMapID = 2248 }
function APR:GetNavigationPlayerPosition() return position end
function APR:ActivateTemporaryRoute() error("An unlock cannot use APR's route engine") end
function APR:GetRouteData() error("An unlock cannot look up APR routes") end
local Lib = LibStub("LibAPRNavigation-1.0")
APR.NavigationEngine = Lib.Engine
APR.taxiData = { BuildEdges = function() return {}, {} end }
APR.NavigationAdapter = nil
-- The path to the observed quest giver is deliberately local and deterministic.
function data:CreateEdgeBuild()
    return { Step = function() return "ready", {}, { resources = {} } end }
end
function data:CanWalk(a, b) return a.uiMapID == b.uiMapID end
function data:GetWalkingSpeed(_, speed) return speed end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
dofile("APR-Core/features/navigation/NavigationUnlocks.lua")
local nav = APR.navigation
nav.destination = { x = 99, y = 44, instanceID = 2738, uiMapID = 2371 }
local edge = { id = "karesh", from = { uiMapID = 2248 },
    blockedRequirements = { minLevel = 80, any = { { quest = 84957 }, { questActive = 84957 } } } }
local function drain()
    for _ = 1, 10000 do
        local timer = table.remove(timers, 1)
        if not timer then return end
        if not timer.cancelled then timer.callback() end
    end
    error("Unbounded unlock scheduling")
end
assert(APR:StartNavigationUnlock({ edge }, context))
drain()
local step = assert(APR:GetNavigationUnlockStep())
assert(step.unlockAction.questID == 84956 and step.unlockAction.kind == "accept")
assert(nav:GetActiveStep().kind == "unlock" and nav:IsNavigating(), "Arrival displays the native quest action")
assert(APR.ActiveRoute == "parent" and APRData.test.parent == 8 and APRCustomPath.test[1] == "parent")
assert(not APRData.test.TemporaryRouteState and APRData.test.NavigationUnlockState,
    "Only a library checkpoint is persisted; APR's temporary route state stays unused")
assert(nav:IsObjectiveCurrent(nav._routeInputs), "The unlock target participates in normal stale-result protection")
APR.navigationPreview = { Build = function(_, _, target)
    assert(target == APR:GetNavigationUnlockStep(), "The map previews the unlock target while the original destination is blocked")
end }
nav:GetPreview()
APR.navigationPreview = nil
data.env.getQuestName = function(id) return "Loaded quest " .. id end
APR:RefreshNavigationUnlockRoute()
assert(nav:GetActiveStep().label:find("Loaded quest", 1, true), "Client names arriving later refresh the existing native action")
nav:PollArrival(); drain()
assert(APR:GetNavigationUnlockStep() == step, "Arrival alone does not advance the native quest action")
active[84956] = true
nav:Update(); drain()
step = APR:GetNavigationUnlockStep()
assert(step.unlockAction.kind == "turnin" and APRData.test.parent == 8)
completed[84956], active[84956] = true, nil
nav:Update(); drain()
assert(APR:GetNavigationUnlockStep().unlockAction.questID == 84957)
-- Simulate a reload with only the persisted standalone checkpoint.
APR._navigationUnlock = nil
assert(APR:RestoreNavigationUnlockRoute())
nav:Update(); drain()
assert(APR:GetNavigationUnlockStep().unlockAction.questID == 84957)
active[84957] = true
assert(APR:RefreshNavigationUnlockRoute() == false and not APR._navigationUnlock)
assert(not APRData.test.NavigationUnlockState and nav.dirty and APR.ActiveRoute == "parent" and APRData.test.parent == 8,
    "Live access resumes the same authored step without incrementing its progress")
assert(not APR:StartNavigationUnlock({ edge }, context), "A retired detour is not forced repeatedly at one parent step")

active, completed = {}, {}
context = { route = "parent", index = 9 }
assert(APR:StartNavigationUnlock({ edge }, context))
context = { route = "another", index = 1 }
APR:RefreshNavigationUnlockRoute(); drain()
assert(not APR._navigationUnlock and not APRData.test.NavigationUnlockState,
    "Changing the route or its step cancels the saved detour and stale callbacks")
context = { route = "parent", index = 10 }
assert(APR:StartNavigationUnlock({ edge }, context))
nav:Cancel("disabled")
drain()
assert(not APR._navigationUnlock, "Disabling navigation releases the standalone session")
print("Navigation unlock adapter: no APR routes/engine, native actions, reload, original progress, stale callbacks and cancellation passed")
