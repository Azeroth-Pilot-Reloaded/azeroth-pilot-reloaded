APR = {}
function GetNormalizedRealmName() return "Home" end
dofile("APR-Core/features/group/PartyProtocol.lua")
local protocol = APR.PartyProtocol
local function snapshot()
    return {
        username = "Player",
        route = "A route",
        routeFileName = "route-key",
        currentStep = 4,
        totalSteps = 10,
        stepFrameDetails = {
            progress = { index = 5, step = 4, total = 10 },
            questSteps = { { text = "|cffffff00Quest|r", subSteps = { { text = "1/5 items" } } } },
        },
    }
end
local clean = assert(protocol.NormalizeSnapshot(snapshot(), "Player-Home"))
assert(clean.username == "Player" and clean.stepFrameDetails.questSteps[1].text == "Quest")
assert(protocol.NormalizeSnapshot(snapshot(), "Player-Other").username == "Player-Other")
assert(not protocol.NormalizeSnapshot(snapshot(), "Impostor-Home"))
local goalSnapshot = snapshot()
goalSnapshot.stepFrameDetails.questSteps = { { text = "Métier inventé (9/10)" } }
assert(protocol.NormalizeSnapshot(goalSnapshot, "Player-Home").stepFrameDetails.questSteps[1].text == "Métier inventé (9/10)",
    "Skill progress uses the existing peer text contract without executing a local skill query")
local data = snapshot()
data.username = "Player-Other"
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
for _, bad in ipairs({ {}, "4", -1, math.huge }) do
    data = snapshot()
    data.currentStep = bad
    assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
end
data = snapshot()
data.currentStep = 0 / 0
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
data.currentStep = 12
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
data.stepFrameDetails.questSteps[1].text = {}
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
data.stepFrameDetails.questSteps[1].text = string.rep("x", 1025)
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
for index = 1, 129 do
    data.stepFrameDetails.questSteps[index] = { text = "row" }
end
assert(not protocol.NormalizeSnapshot(data, "Player-Home"))
data = snapshot()
data.unused = data
assert(
    protocol.NormalizeSnapshot(data, "Player-Home").unused == nil,
    "Unknown/cyclic fields are never walked or retained"
)
data = snapshot()
data.stepFrameDetails = nil
data.currentStep = nil
data.totalSteps = 0
data.route = nil
assert(protocol.NormalizeSnapshot(data, "Player-Home"), "Peers without a route remain compatible")

data = snapshot()
data.routeProgress = { id = "main:7", step = 7, total = 12, unused = {} }
clean = assert(protocol.NormalizeSnapshot(data, "Player-Home"))
assert(clean.routeProgress.id == "main:7" and clean.routeProgress.unused == nil)
for _, progress in ipairs({
    "7",
    {},
    { id = "main:7", step = 6, total = 12 },
    { id = "main:13", step = 13, total = 12 },
    { id = "main:0", step = 0, total = 12 },
    { id = "parallel:0:1", step = 7, total = 12 },
    { id = "parallel:1:0", step = 7, total = 12 },
    { id = "parallel:1:2", step = 14, total = 12 },
    { id = "end", step = 12, total = 12 },
    { id = "main:7", step = "7", total = 12 },
    { id = "main:7", step = 7, total = math.huge },
    { id = "unknown:7", step = 7, total = 12 },
    { id = string.rep("x", 65), step = 7, total = 12 },
}) do
    data = snapshot()
    data.routeProgress = progress
    assert(not protocol.NormalizeSnapshot(data, "Player-Home"), "Invalid stable positions are rejected")
end
for _, progress in ipairs({ { id = "parallel:1:2", step = 7, total = 12 }, { id = "end", step = 13, total = 12 } }) do
    data = snapshot()
    data.routeProgress = progress
    assert(protocol.NormalizeSnapshot(data, "Player-Home"))
end

data = snapshot()
local started = os.clock()
for _ = 1, 10000 do
    assert(protocol.NormalizeSnapshot(data, "Player-Home"))
end
local elapsed = os.clock() - started
print(
    string.format(
        "Party schema: identity, ranges, row budgets and legacy payloads passed; 10000 snapshots in %.3f s",
        elapsed
    )
)

function RegionalUniqueNamesEnabled() return true end
local fullName = "Violet Meadow"
function GetUnitName() return fullName end
local firstName, surname = "Violet", "Brook"
function UnitName(unit)
    assert(unit == "player", "Local identity reads the player unit")
    return firstName, surname
end
dofile("APR-Core/utils/SecretUtils.lua")
APRSecret:Attach(APR)
APR.Username = "Violet"
assert(protocol.LocalName() == "Violet Meadow", "The native full name takes precedence over the fallback")
assert(protocol.PlayerKey("Violet Meadow") == "Violet Meadow")
assert(protocol.PlayerKey("Violet Brook") ~= protocol.PlayerKey("Violet Meadow"))
assert(protocol.DisplayName("Violet Meadow") == "Violet Meadow")
assert(protocol.UnitName("party1") == "Violet Meadow")
for _, claimed in ipairs({ "Violet Meadow", "Violet" }) do
    data = snapshot()
    data.username = claimed
    clean = assert(protocol.NormalizeSnapshot(data, "Violet Meadow"))
    assert(clean.username == "Violet Meadow" and clean.sender == "Violet Meadow")
end
data = snapshot()
data.username = "Violet Brook"
assert(not protocol.NormalizeSnapshot(data, "Violet Meadow"))
data.username = "Vio"
assert(not protocol.NormalizeSnapshot(data, "Violet Meadow"))
fullName = nil
assert(protocol.UnitName("party1") == nil, "Missing native regional names stay unavailable")
local opaque = {}
function issecretvalue(value) return value == opaque end
fullName = opaque
assert(
    protocol.UnitName("party1") == nil and protocol.PlayerKey(opaque) == nil,
    "Restricted native names cannot enter membership or string operations"
)
assert(protocol.LocalName() == "Violet Brook", "Restricted full names fall back to safe name parts")
for _, unavailable in ipairs({ false, 42, {}, "" }) do
    fullName = unavailable
    assert(protocol.LocalName() == "Violet Brook", "Invalid full names fall back to safe name parts")
end
fullName = nil
assert(protocol.LocalName() == "Violet Brook", "Missing full names fall back to safe name parts")
local nativeGetUnitName = GetUnitName
GetUnitName = nil
assert(protocol.LocalName() == "Violet Brook", "An unavailable full-name API still permits local identity")
surname = ""
assert(protocol.LocalName() == "Violet", "An empty surname adds no separator")
surname = nil
assert(protocol.LocalName() == "Violet", "A missing surname preserves the first name")
surname = opaque
assert(protocol.LocalName() == "Violet", "A restricted surname is discarded by the safe reader")
firstName = nil
assert(protocol.LocalName() == nil, "Missing safe name parts leave the identity unavailable")
firstName = opaque
assert(protocol.LocalName() == nil, "A restricted first name cannot become a local identity")
GetUnitName, fullName = nativeGetUnitName, "Violet Meadow"
assert(protocol.LocalName() == "Violet Meadow", "Native identity recovers without caching a fallback")
function RegionalUniqueNamesEnabled() return false end
assert(protocol.LocalName() == "Violet", "Nonregional clients retain the saved username")
RegionalUniqueNamesEnabled = nil
assert(protocol.LocalName() == "Violet", "Clients without the regional API retain the saved username")
print(
    "Party regional schema: complete names, namesake isolation, authoritative legacy claims and unavailable/restricted data passed"
)
