-- Source-backed local instructions stay visible without a fake arrow target.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, timers, rows = {}, {}, {}
local function noop() end
local position = { x = 1, y = 2, instanceID = 2552, uiMapID = 2248 }
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", level = 90, mapID = 2248 } end,
    getPlayerPosition = function() return position end,
    isQuestCompleted = function(id) return completed[id] == true end,
    isQuestActive = function(id) return id == 7 end,
    isQuestObjectiveCompleted = function() return false end,
    getLocale = function() return "frFR" end,
}
Lib:RegisterData("positionless-host", "test", { unlockRoutes = {
    { id = "tracker", goal = { key = "quest", value = 99 }, guidanceQuestID = 7, steps = {
        { kind = "objective", questID = 7, objectiveIndices = { 1 }, noArrow = true, sourceID = 1 },
    } },
} })
local data = Lib:New({ profile = "positionless-host", environment = env })
APR.NavigationData, APR.NavigationEngine = data, Lib.Engine
APR.PlayerID, APR.ActiveRoute = "test", "parent"
APRData = { test = { parent = 8 } }
APR.settings = { profile = { enableAddon = true } }
APR.Arrow, APR.event = { SetCoord = noop, SetArrowActive = noop }, { QueueStepRefresh = noop }
APR.currentStep = { AddQuestSteps = function(_, _, text) rows[#rows + 1] = text end,
    AddQuestDivider = noop, AddStepButton = noop }
APR.SendMessage = noop
function APR:NewModule() return {} end
function APR:GetNavigationPlayerPosition() return position end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function InCombatLockdown() return false end
local parent = { Zone = 2472, Coord = { x = 10, y = 20, mapID = 2472, instanceID = 2738 } }
local context = { route = "parent", index = 8 }
function APR:CaptureStepContext() return context end
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetCurrentStep() return parent, 8 end
function APR:ActivateTemporaryRoute() error("Standalone guidance cannot activate APR routes") end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
dofile("APR-Core/features/navigation/Navigation.lua")
dofile("APR-Core/features/navigation/NavigationUnlocks.lua")
local nav = APR.navigation
nav.destination = { x = 20, y = 10, uiMapID = 2472, instanceID = 2738 }
local function drain()
    for _ = 1, 1000 do
        local timer = table.remove(timers, 1)
        if not timer then return end
        if not timer.cancelled then timer.callback() end
    end
    error("Unbounded positionless host scheduling")
end
assert(APR:StartNavigationUnlock({ { id = "access", blockedRequirements = { quest = 99 } } }, context))
drain()
local step = assert(APR:GetNavigationUnlockStep())
assert(step.NoArrow and not step.Coord and not step.unlockAction.target)
assert(nav:IsNavigating() and nav:GetActiveStep().kind == "unlock" and #rows > 0)
assert(APRData.test.parent == 8 and APR.ActiveRoute == "parent")
assert(APRData.test.NavigationUnlockState.library.destination.uiMapID == 2472)
nav:Cancel("disabled")
assert(not APR._navigationUnlock)
assert(APR:StartNavigationUnlock({ { id = "access", blockedRequirements = { quest = 99 } } }, context),
    "Cancelling before access is obtained cannot permanently suppress the same entrance")
drain()
completed[7] = true
nav:Update(); drain()
step = assert(APR:GetNavigationUnlockStep())
assert(step.unlockAction.reason == "tracker_not_observed" and nav:IsNavigating(), "Waiting for a hidden tracker remains an explicit instruction")
assert(step.label:find("confirmation", 1, true))
APR._navigationUnlock = nil
assert(APR:RestoreNavigationUnlockRoute())
nav:Update(); drain()
assert(nav:IsNavigating() and APR:GetNavigationUnlockStep().NoArrow)
completed[99] = true
assert(APR:RefreshNavigationUnlockRoute() == false and not APR._navigationUnlock)
assert(APRData.test.parent == 8 and not APRData.test.NavigationUnlockState and nav.dirty)
print("Positionless unlock host: visible sourced instruction, no fake arrow, tracker wait, reload and unchanged parent route passed")
