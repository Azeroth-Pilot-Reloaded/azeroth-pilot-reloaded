-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Host lifecycle regressions from a saved custom-route Waypoint in Dornogal:
-- orphaned attempt records cannot suppress guidance, and read-only route map
-- getters may ask to restore an already active checkpoint repeatedly.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load(dofile("tests/lua/navigation_unlock_test_catalog.lua"))
data.env.isQuestCompleted = function() return false end
data.env.isQuestActive = function() return false end
data.env.isQuestCompletedOnAccount = function() return false end
data.env.getCharacter = function() return { level = 90, faction = "Horde", class = "PALADIN", mapID = 102 } end
local route = "fixture-parent-guide"
local context = { route = route, index = 8 }
local original = { uiMapID = 104, instanceID = 3, x = -1343, y = -515.6 }
local gate = { id = "karesh", from = { uiMapID = 101 }, blockedRequirements = {
    minLevel = 80, any = { { quest = 12 }, { questActive = 12 } },
} }
APR.PlayerID, APR.ActiveRoute = "test", route
function APR:CaptureStepContext() return context end
function APR:IsStepContextCurrent(value) return value == context end
function APR:GetCurrentStep() return { Zone = 104 }, 8 end
dofile("APR-Core/features/navigation/NavigationUnlocks.lua")
local function reset(attempted)
    APR._navigationUnlock = nil
    APRData = { test = { [route] = 8 } }
    if attempted then
        APRData.test.NavigationUnlockAttempts = { route = route, index = 8, edges = { karesh = true } }
    end
    APR.navigation = { destination = original, updates = 0,
        RequestUpdate = function(self) self.updates = self.updates + 1 end }
end
local failures = {}
local function check(name, fn)
    local ok, reason = pcall(fn)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(reason) end
end

check("orphaned saved attempt", function()
    reset(true)
    assert(APRData.test.NavigationUnlockState == nil and APR._navigationUnlock == nil)
    assert(APR:StartNavigationUnlock({ gate }, context),
        "A persisted attempt without a live/saved unlock must not permanently suppress this blocked entrance")
    assert(APR._navigationUnlock and APRData.test.NavigationUnlockState)
    assert(APR.navigation.dirty and APR.navigation.updates == 1)
    assert(APR.ActiveRoute == route and APRData.test[route] == 8)
    assert(APRData.test.NavigationUnlockState.library.destination.uiMapID == 104)
end)

check("idempotent active restore", function()
    reset(false)
    assert(APR:StartNavigationUnlock({ gate }, context))
    local state = APR._navigationUnlock
    local session, build = state.session, state.session.build
    assert(build:Step(1, 1) == "planning", "The regression covers a pending cooperative catalogue scan")
    for _ = 1, 3 do
        assert(APR:RestoreNavigationUnlockRoute())
        assert(APR._navigationUnlock == state and APR._navigationUnlock.session == session,
            "Repeated read-only restoration must reuse the active unlock session")
        assert(session.build == build and build.status == "planning",
            "Repeated route-map reads cannot cancel and restart pending unlock planning")
    end
    assert(APR.ActiveRoute == route and APRData.test[route] == 8)
end)

assert(#failures == 0, table.concat(failures, "\n"))
print("Unlock host recovery: orphan attempts self-heal and repeated active restores preserve cooperative planning")
