local F = dofile("tests/lua/navigation_v2_waypoint/fixture.lua")
local session, state = F.Session()
assert(#state.creates == 0)
local target = F.Target()
assert(session:SetTarget(target) == "active")
local sent = state.creates[1]
assert(sent.mapID == 42 and sent.x == 23 and sent.y == 67)
assert(sent.stripCoordinates == true and sent.name == target.title)
assert(sent.iconTexture == "APR-icon" and sent.iconType == "TEXTURE")
assert(sent.r == 0.2 and sent.g == 0.4 and sent.b == 0.8 and sent.requestRecolor == true)
assert(sent.suppressAudio == true and sent.fromWUI == false)
assert(sent.suppressPathfinding == true, "WUI must display APR's selected segment without replanning it")
assert(type(sent.flags) == "string" and sent.flags:find("APR", 1, true))
target.position.x, target.title = 0.99, "Mutated caller"
assert(session:Refresh() == "active" and #state.creates == 1)
assert(state.current.x == 0.23 and state.current.name == "Enter the gate")
assert(session:SetTarget(F.Target()) == "active" and #state.creates == 1)
session:Clear()
assert(state.current == nil and #state.clears == 1 and state.clears[1].suppressAdvance == true)
assert(state.pins.foreign and session:GetStatus() == "idle")
session:Clear()
assert(#state.clears == 1)

-- A manual close is sticky for the same target, including repeated host updates.
session:SetTarget(F.Target())
state.current = nil
assert(session:Refresh() == "dismissed")
assert(session:SetTarget(F.Target()) == "dismissed" and #state.creates == 2)
local renamed = F.Target()
renamed.title = "Updated instruction"
assert(session:SetTarget(renamed) == "dismissed" and #state.creates == 2,
    "A text refresh of the same active action must not reopen its dismissed marker")
assert(session:SetTarget(F.Target("next")) == "active" and #state.creates == 3)
state.tracked = false
assert(session:Refresh() == "dismissed", "Untracking respects the player's selection")
assert(state.current == nil and state.clears[#state.clears].preserve == true)

-- Neither an existing session nor a replacement may be overwritten or removed.
session, state = F.Session()
local foreign = { flags = "another addon" }
state.current = foreign
assert(session:SetTarget(F.Target()) == "occupied" and #state.creates == 0)
assert(state.current == foreign)
state.current = nil
assert(session:Refresh() == "active")
state.current = foreign
assert(session:Refresh() == "dismissed")
session:Clear()
assert(state.current == foreign and #state.clears == 0)

session, state = F.Session()
session:SetTarget(F.Target())
local impostor = {}
for key, value in pairs(state.current) do impostor[key] = value end
impostor.flags = "foreign-but-same-location-and-label"
state.current = impostor
session:Clear()
assert(state.current == impostor and #state.clears == 0)

-- Matching location/name alone never confers ownership, even between V2 sessions.
local a, shared, env = F.Session()
local library = F.Load()
local b = assert(library.NewWaypointSession({ getProvider = function() return env.api end,
    inCombat = function() return false end, defaultTitle = "Map pin" }))
a:SetTarget(F.Target())
assert(b:SetTarget(F.Target()) == "occupied")
b:Clear()
assert(shared.current ~= nil and #shared.clears == 0)
a:Clear()
assert(shared.current == nil)
