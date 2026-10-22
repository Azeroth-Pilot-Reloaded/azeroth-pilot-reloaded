-- Ordinary combat cooldowns should not rebuild the travel catalogue.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local adapter, environment = APR.NavigationAdapter, APR.NavigationAdapter.environment
local calls, status = 0, {
    [1] = { true }, [2] = { false, "cooldown" }, [3] = { false, "unknown" },
}
function APR:GetRouteActionUsability(_, id, ignoreCooldown, ignoreGlobalCooldown)
    assert(ignoreCooldown == false and ignoreGlobalCooldown == true,
        "Navigation ignores only the global cooldown, not the action's own cooldown")
    calls = calls + 1
    return unpack(status[id])
end
for id = 1, 3 do environment.getActionUsability("spell", id) end
calls = 0
local check = adapter:CreateCooldownCheck()
assert(check:Step(1, 0.5) == "planning" and calls == 1,
    "A cooldown check yields after its requested operation allowance")
local state, changed
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(not changed and calls == 2, "Unknown spells are excluded from cooldown polling")
status[2] = { true }
environment.getActionUsability("spell", 2)
check = adapter:CreateCooldownCheck()
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(changed, "An owned travel action becoming ready requests a comparison even after a live UI check")
check = adapter:CreateCooldownCheck()
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(not changed, "One readiness transition cannot repeatedly invalidate the route")

-- One shared cooldown must settle every watched baseline before rebuilding.
status[1], status[2] = { false, "cooldown" }, { false, "cooldown" }
calls = 0
local clock = 0
check = adapter:CreateCooldownCheck()
check.clock = function() clock = clock + 1; return clock end
state, changed = check:Step(8, 0.5)
assert(state == "planning" and changed == nil and calls == 1,
    "Finding a changed action preserves the time budget and defers invalidation until the scan completes")
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(changed and calls == 2,
    "A shared cooldown scans every owned action before reporting one completed invalidation")
calls = 0
check = adapter:CreateCooldownCheck()
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(not changed and calls == 2,
    "All shared cooldown baselines were consumed by the preceding scan")

-- A live action can disappear while the batched check is between frames.
check = adapter:CreateCooldownCheck()
assert(check:Step(1, 0.5) == "planning")
status[1], status[2] = { false, "missing" }, { false, "missing" }
environment.getActionUsability("spell", 1)
environment.getActionUsability("spell", 2)
repeat state, changed = check:Step(1, 0.5) until state == "ready"
assert(not changed, "Collection changes cannot invalidate the iterator's saved key")

-- Exercise the host's separate UI and planning decisions with the real helper.
local globalOnly, durationArgument = true
C_Spell = {
    GetSpellInfo = function() return {} end,
    IsSpellUsable = function() return true end,
    GetSpellCooldown = function() return { isActive = true } end,
    GetSpellCooldownDuration = function(_, ignoreGlobal)
        durationArgument = ignoreGlobal
        return { IsZero = function() return globalOnly end }
    end,
}
dofile("APR-Core/utils/PlayerUtils.lua")
function APR:IsSpellKnown() return true end
assert(not APR:GetRouteActionUsability("spell", 1), "A secure button still waits for the current global cooldown")
assert(APR:GetRouteActionUsability("spell", 1, false, true) and durationArgument == true,
    "A global cooldown alone does not remove an otherwise usable travel spell")
globalOnly = false
assert(not APR:GetRouteActionUsability("spell", 1, false, true), "A real travel cooldown remains unavailable")

C_Spell.GetSpellCooldownDuration = nil
local actualDuration = 1.5
C_Spell.GetSpellCooldown = function(id)
    return { startTime = 20, duration = id == 61304 and 1.5 or actualDuration, isActive = true }
end
assert(APR:GetRouteActionUsability("spell", 1, false, true), "Legacy clients compare the exact global cooldown interval")
actualDuration = 300
assert(not APR:GetRouteActionUsability("spell", 1, false, true), "A different cooldown interval is never mistaken for the global cooldown")
print("Navigation cooldowns: owned-action batches, stable transitions, removed actions and global cooldown separation passed")
