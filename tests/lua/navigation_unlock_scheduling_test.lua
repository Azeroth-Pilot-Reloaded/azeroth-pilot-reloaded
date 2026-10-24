local timers, calls, cancelled, timed = {}, 0, false, true
local context = { route = "parent", index = 1 }
APR = { navigation = {} }
APRData = nil
function debugprofilestop() return 0 end
function APR:IsStepContextCurrent(value) return value == context end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local session = { Step = function(_, operations, milliseconds)
    assert(operations == (timed and 4096 or 64) and milliseconds == 1,
        "Unlock discovery must spend the available time instead of yielding after 64 cheap operations")
    calls = calls + 1
    return "planning"
end, Cancel = function() cancelled = true end }
function APR.navigation:RequestUpdate() error("A planning continuation must not add the event debounce") end
function APR.navigation:Update(value)
    assert(value.route == "parent" and value.index == 1)
    APR:RefreshNavigationUnlockRoute()
end
dofile("APR-Core/features/navigation/NavigationUnlocks.lua")
APR._navigationUnlock = { context = context, session = session }
assert(APR:RefreshNavigationUnlockRoute() and #timers == 1 and timers[1].delay == 0)
timers[1].callback()
assert(calls == 2 and #timers == 2 and timers[2].delay == 0,
    "Each planning slice resumes directly on the next frame")
APR:CancelNavigationUnlock()
assert(cancelled and timers[2].cancelled and not APR._navigationUnlock)
timers[2].callback()
assert(calls == 2, "A retired session's callback cannot resume work")

debugprofilestop, timed, cancelled = nil, false, false
APR._navigationUnlock = { context = context, session = session }
APR:RefreshNavigationUnlockRoute()
assert(calls == 3, "Clients without a profiling clock retain the bounded operation fallback")
context = { route = "replacement", index = 2 }
timers[3].callback()
assert(cancelled and calls == 3 and not APR._navigationUnlock,
    "The next-frame continuation still validates the original route context")
print("Unlock scheduler: full timed throughput, next-frame continuations, untimed fallback and stale/cancelled session rejection passed")
