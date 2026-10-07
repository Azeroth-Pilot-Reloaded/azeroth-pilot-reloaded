APR = {}
function GetNormalizedRealmName() return "Home" end
dofile("APR-Core/features/group/PartyProtocol.lua")
local protocol = APR.PartyProtocol
local function snapshot()
    return { username = "Player", route = "A route", routeFileName = "route-key", currentStep = 4, totalSteps = 10,
        stepFrameDetails = { progress = { index = 5, step = 4, total = 10 },
            questSteps = { { text = "|cffffff00Quest|r", subSteps = { { text = "1/5 items" } } } } } }
end
local clean = assert(protocol.NormalizeSnapshot(snapshot(), "Player-Home"))
assert(clean.username == "Player" and clean.stepFrameDetails.questSteps[1].text == "Quest")
assert(protocol.NormalizeSnapshot(snapshot(), "Player-Other").username == "Player-Other")
assert(not protocol.NormalizeSnapshot(snapshot(), "Impostor-Home"))
local data = snapshot()
data.username = "Player-Other"
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
for _, bad in ipairs({ {}, "4", -1, math.huge }) do
    data = snapshot(); data.currentStep = bad
    assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
end
data = snapshot(); data.currentStep = 0/0
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot(); data.currentStep = 12
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot(); data.stepFrameDetails.questSteps[1].text = {}
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot(); data.stepFrameDetails.questSteps[1].text = string.rep("x", 1025)
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
for index = 1, 129 do data.stepFrameDetails.questSteps[index] = { text = "row" } end
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot(); data.unused = data
assert(protocol.NormalizeSnapshot(data, "Player-Home").unused == nil, "Unknown/cyclic fields are never walked or retained")
data = snapshot(); data.stepFrameDetails = nil; data.currentStep = nil; data.totalSteps = 0; data.route = nil
assert(protocol.NormalizeSnapshot(data, "Player-Home"), "Peers without a route remain compatible")

data = snapshot()
local started = os.clock()
for _ = 1, 10000 do assert(protocol.NormalizeSnapshot(data, "Player-Home")) end
local elapsed = os.clock() - started
print(string.format("Party schema: identity, ranges, row budgets and legacy payloads passed; 10000 snapshots in %.3f s", elapsed))
