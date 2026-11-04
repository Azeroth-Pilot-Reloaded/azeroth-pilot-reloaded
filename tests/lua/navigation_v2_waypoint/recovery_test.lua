local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, state, env = F.Session()
local base = env.api.NewUserNavigation
env.api.NewUserNavigation = function(options)
    base(options)
    error("partial provider failure")
end
assert(session:SetTarget(F.Target()) == "provider_error" and state.current)
assert(session:Refresh() == "provider_error" and #state.creates == 1)
assert(session:Clear() == "idle" and state.current == nil)

-- The provider is allowed to round normalized coordinates in its copied session.
session, state = F.Session()
local target = F.Target()
target.position.x = 0.29
assert(session:SetTarget(target) == "active")
state.current.x = 0.290000000000001
assert(session:Clear() == "idle" and #state.clears == 1)

-- A failed replacement never changes a previously accepted target or context.
session, state = F.Session()
session:SetTarget(F.Target())
assert(session:SetTarget({}) == "invalid_target")
assert(session:Refresh() == "active" and #state.creates == 1)

-- Provider exceptions and malformed APIs are safe at every boundary.
session, state, env = F.Session()
env.api = { NewUserNavigation = false }
assert(session:SetTarget(F.Target()) == "provider_unavailable" and #state.creates == 0)
env.api = select(1, F.Provider())
assert(session:Refresh() == "active")
env.api = nil
assert(session:Clear() == "idle", "Cleanup uses its captured provider, not a later global")

-- Arrival cannot use foreign positions, invalid distance, a lost or untracked marker.
session, state = F.Session()
session:SetTarget(F.Target())
for _, distance in ipairs({ -1, 5.001, math.huge, 0/0, false }) do
    assert(session:ObserveArrival(42, 0.23, 0.67, distance) == "active")
end
assert(session:ObserveArrival(41, 0.23, 0.67, 0) == "active")
assert(session:ObserveArrival(42, 0.24, 0.67, 0) == "active")
assert(session:ObserveArrival(42, 0.23, 0.67, 5) == "arrived")
assert(#state.clears == 1 and state.current == nil)
