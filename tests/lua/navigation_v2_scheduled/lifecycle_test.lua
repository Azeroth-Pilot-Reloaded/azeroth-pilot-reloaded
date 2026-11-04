local F = assert(loadfile("tests/lua/navigation_v2_scheduled/fixture.lua"))()

for _, kind in ipairs({ "boat", "zeppelin", "elevator" }) do
    local session = F.New(F.Route(kind))
    assert(session:GetState().phase == "approach")
    assert(session:GetState().target.position.mapID == 77)
    local wrong = F.Observation("origin", 1)
    wrong.stopID = "other berth"
    local state, reason = session:Observe(wrong, 101)
    assert(state.phase == "approach" and reason == "wrong_origin")
    assert(session:Observe(F.Observation("origin", 2), 102).phase == "waiting")
    assert(session:GetState().target == nil)
    assert(session:GetState().wait.mode == "estimated")
    assert(session:Observe(F.Observation("boarded", 3), 103).phase == "waiting")
    assert(session:Observe(F.Observation("transport_ready", 4), 104).phase == "boarding")
    assert(session:GetState().target.position.x == 0.2)
    assert(session:Observe(F.Observation("boarded", 5), 105).phase == "riding")
    assert(session:GetState().target == nil)
    assert(session:Observe(F.Observation("destination", 6, true), 106).phase == "riding")
    assert(session:Observe(F.Observation("departed", 7), 107).phase == "riding")
    assert(session:Observe(F.Observation("loading", 8), 108).phase == "riding")
    assert(session:Observe(F.Observation("destination", 9, true), 109).phase == "disembarking")
    assert(session:GetState().target.position.mapID == 78)
    assert(session:Observe(F.Observation("disembarked", 10, true), 110).status == "complete")
    assert(session:GetState().target == nil)
    assert(session:Tick(10000).status == "complete")
    assert(session:Cancel().status == "complete")
end

local session = F.New()
F.Ride(session)
for index, field in ipairs({ "stopID", "worldID", "floorID", "phaseID", "onTransport", "confirmed", "routeID" }) do
    local observation = F.Observation("destination", 4 + index, true)
    observation[field] = nil
    assert(session:Observe(observation, 110 + index).phase == "riding", field)
end
for index, field in ipairs({ "stopID", "worldID", "floorID", "phaseID" }) do
    local observation = F.Observation("destination", 20 + index, true)
    observation[field] = type(observation[field]) == "number" and 999 or "wrong"
    assert(session:Observe(observation, 120 + index).phase == "riding", field)
end
assert(session:Observe(F.Observation("destination", 30, true), 130).phase == "disembarking")
local aboard = F.Observation("disembarked", 31, true)
aboard.onTransport = true
assert(session:Observe(aboard, 131).status == "running")
assert(session:Observe(F.Observation("disembarked", 32), 132).status == "running")
assert(session:Observe(F.Observation("disembarked", 33, true), 133).status == "complete")
