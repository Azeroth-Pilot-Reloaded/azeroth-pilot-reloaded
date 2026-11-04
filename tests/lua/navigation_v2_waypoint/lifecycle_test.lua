local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, state, env = F.Session()
env.api = nil
assert(session:SetTarget(F.Target()) == "provider_unavailable")
assert(#state.creates == 0)
env.api = select(1, F.Provider())
assert(session:Refresh() == "active", "Late API discovery must retain the target")
session:Clear()

session, state, env = F.Session()
env.combat = true
assert(session:SetTarget(F.Target()) == "combat" and #state.creates == 0)
session:Clear()
env.combat = false
session:Refresh()
assert(#state.creates == 0, "Cancellation in combat cannot publish later")
session:SetTarget(F.Target())
env.combat = true
assert(session:SetTarget(F.Target("next")) == "combat" and #state.creates == 1)
session:Clear()
assert(#state.clears == 0)
env.combat = false
assert(session:Refresh() == "idle")
assert(#state.clears == 1 and #state.creates == 1)

session, state, env = F.Session()
state.reject = true
assert(session:SetTarget(F.Target()) == "provider_rejected")
assert(#state.creates == 1)
session:Refresh()
assert(#state.creates == 1, "Rejected publication must not restart unchanged")
state.reject = false
assert(session:SetTarget(F.Target("new")) == "active")
assert(session:Arrive() == "arrived" and #state.clears == 1)
assert(session:SetTarget(F.Target("new")) == "arrived")
assert(session:Refresh() == "arrived" and #state.creates == 2)

-- Cleanup errors retain the owned handle until a safe retry; replacements survive.
session, state, env = F.Session()
session:SetTarget(F.Target())
local clear = env.api.ClearUserNavigation
env.api.ClearUserNavigation = function() error("provider internal error") end
assert(session:Clear() == "provider_error")
env.api.ClearUserNavigation = clear
assert(session:Refresh() == "idle" and #state.clears == 1)
session:SetTarget(F.Target("other"))
env.api.GetUserNavigation = function() error("unavailable") end
assert(session:Clear() == "provider_error")
env.api.GetUserNavigation = function() return state.current end
state.current = { flags = "foreign" }
assert(session:Refresh() == "idle" and #state.clears == 1)
