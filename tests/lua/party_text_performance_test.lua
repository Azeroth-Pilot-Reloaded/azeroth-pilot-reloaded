-- Malformed link/art markup must not retry a non-greedy search at every opener
-- while deserializing another party member's bounded tooltip snapshot.
APR = {}
function GetNormalizedRealmName() return "Home" end
dofile("APR-Core/features/group/PartyProtocol.lua")
local P = APR.PartyProtocol
local function snapshot(text)
    return { username = "Peer", route = "Synthetic route", routeFileName = "synthetic",
        currentStep = 1, totalSteps = 2, stepFrameDetails = { questSteps = { { text = text } } } }
end
local function clean(text)
    local data = assert(P.NormalizeSnapshot(snapshot(text), "Peer-Home"))
    return data.stepFrameDetails.questSteps[1].text
end
assert(clean("Plain text\nnext\tline\1") == "Plain text\nnext\tline")
assert(clean("A|Hitem:7|h[Name]|hB|Ticon:16|tC|Aatlas:8|aD|cffaabbccE|rF") == "A[Name]BCDEF")
assert(clean("|Hquest:7|h|cffaabbccQuest|r |Ticon|t|h") == "Quest ")
assert(clean("|Tfirst|a and |Asecond|t") == " and ", "Existing mixed-art closing rules remain compatible")
assert(clean("|Hone|hFirst|h / |Htwo|hSecond|h") == "First / Second")
assert(clean("|Hbroken|Hstill") == "|Hbroken|Hstill")
assert(clean("|Hbroken|hLabel") == "|Hbroken|hLabel")
assert(clean("|Tbroken|Abroken") == "|Tbroken|Abroken")
assert(clean("|Hone|hFirst|h|Hunfinished") == "First|Hunfinished")
assert(clean("|Tfirst|t|Tunfinished") == "|Tunfinished")
assert(clean("|h|t|a|cINVALID!") == "|h|t|a|cINVALID!")
assert(not P.NormalizeSnapshot(snapshot(string.rep("x", 1025)), "Peer-Home"),
    "The original per-row text limit remains enforced")

local find, gsub = string.find, string.gsub
local work = 0
string.find = function(subject, pattern, initial, plain)
    local first, last = find(subject, pattern, initial, plain)
    -- Fixed-width searches stop at their first match; failed searches consume
    -- the remaining suffix once. Count scanned bytes rather than machine time.
    work = work + (first or #subject + 1) - (initial or 1)
    return first, last
end
string.gsub = function(subject, pattern, ...)
    assert(not find(pattern, ".-", 1, true) and not find(pattern, ".*", 1, true),
        "Peer text cannot use an unbounded non-greedy or greedy pattern search")
    work = work + #subject
    return gsub(subject, pattern, ...)
end
for _, opener in ipairs({ "|H", "|T", "|A" }) do
    local value, data = string.rep(opener, 500), snapshot("")
    for index = 1, 20 do data.stepFrameDetails.questSteps[index] = { text = value } end
    work = 0
    local result = assert(P.NormalizeSnapshot(data, "Peer-Home"))
    assert(#result.stepFrameDetails.questSteps == 20)
    assert(result.stepFrameDetails.questSteps[20].text == value, "Incomplete markup preserves its literal suffix")
    assert(work < 20 * #value * 10,
        "A 20 KiB malformed snapshot must be sanitized in a fixed number of linear scans")
end
work = 0
assert(clean(string.rep("|Hx|hN|h|Tz|t", 50)) == string.rep("N", 50))
assert(work < 10000, "Many complete adjacent tags also consume linear scan work")
string.find, string.gsub = find, gsub
print("Party text: linear malformed/complete markup scans; hyperlink labels, art, colors, controls and limits preserved")
