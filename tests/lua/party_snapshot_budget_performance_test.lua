-- Bound optional party tooltip construction, not only its final serialization.
local env = dofile("tests/lua/route_ui_test_env.lua")
local createFrame, environmentLibStub = CreateFrame, LibStub
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = env.widget(frame), env.widget(frame)
    end
    return frame
end
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local serializer = LibStub("AceSerializer-3.0")
function LibStub(name)
    if name == "AceSerializer-3.0" then return serializer end
    return environmentLibStub(name)
end
local clock, fontReads, subReads, sortWork = 100, 0, 0, 0
LE_PARTY_CATEGORY_INSTANCE = 1
function GetTime() return clock end
function IsInGroup(category) return category == nil end
function IsInRaid() return false end
function GetNormalizedRealmName() return "Home" end
APR.Username, APR.PlayerID, APR.ActiveRoute = "Local", "player", "invented"
APRData = { player = { invented = 3, ["invented-TotalSteps"] = 10 } }
APR.settings.profile.enableAddon = true
APR.settings.profile.sojournerSkipCampaign = true
function APR:GetRouteDisplayName() return "Invented route" end
function APR:GetGroupRouteProgress(route, index)
    assert(route == "invented")
    return { id = "main:" .. index, step = index, total = 10 }
end
dofile("APR-Core/features/group/PartyProtocol.lua")
dofile("APR-Core/features/group/Party.lua")
local step, party = APR.currentStep, APR.party
step.progressBar = { key = "invented", currentStep = 2 }
local function row(text)
    return { font = { GetText = function() fontReads = fontReads + 1; return text end } }
end
local function reset()
    step.questsList, step.questsExtraTextList, step.fillersList = {}, {}, {}
    fontReads, subReads, sortWork = 0, 0, 0
end
local sort = table.sort
table.sort = function(values, ...)
    sortWork = sortWork + #values
    return sort(values, ...)
end

reset()
for index = 1, 3000 do step.questsList[index] = row("Dense text") end
local payload = party:BuildGroupPayload()
assert(fontReads <= 129 and sortWork == 0,
    "An oversized tooltip is rejected after at most 129 row reads, before sorting the full list")
assert(payload.currentStep == 2 and payload.totalSteps == 10 and payload.routeProgress.id == "main:3"
    and payload.stepFrameDetails.progress.index == 3)
assert(#payload.stepFrameDetails.questSteps == 0 and #payload.stepFrameDetails.extraLines == 0,
    "Overflow drops the complete optional tooltip rather than publishing a misleading partial objective list")
local firstBound = fontReads
fontReads, sortWork = 0, 0
local full = step:GetCurrentStepDetails(false)
assert(#full.questSteps == 3000 and fontReads == 3000 and sortWork == 3000,
    "Ordinary exports retain the complete original content and deterministic sort")
assert(full.questSteps[1].key == 1 and full.questSteps[2].key == 10)

-- The real send path still publishes all authoritative progress fields.
local sent
function APR:SendAddonMessageSplit(prefix, wire, channel, target, callback)
    assert(prefix == "APRPartyData" and channel == "PARTY" and target == nil)
    sent = wire
    callback(true)
end
party.GroupListSteps.Local = payload
fontReads, sortWork = 0, 0
party:SendGroupMessageNow()
local ok, received = serializer:Deserialize(sent)
assert(ok and #sent <= 2048 and received.currentStep == 2 and received.totalSteps == 10
    and received.routeProgress.id == "main:3" and received.sojournerSkipCampaign)
assert(fontReads <= 129 and sortWork == 0 and #received.stepFrameDetails.questSteps == 0)

reset()
local dense = row("Objective")
dense.subTexts = {}
for index = 1, 3000 do
    dense.subTexts[index] = setmetatable({ questID = 71, name = "Objective " .. index }, {
        __index = function(_, key) if key == "text" then subReads = subReads + 1; return "x" end end,
    })
end
step.questsList[1] = dense
payload = party:BuildGroupPayload()
assert(fontReads == 1 and subReads == 128 and sortWork == 0 and #payload.stepFrameDetails.questSteps == 0,
    "Sub-objectives share the same row budget instead of escaping through one parent row")
subReads = 0
full = step:GetCurrentStepDetails(false)
assert(#full.questSteps[1].subSteps == 3000 and subReads == 3000)

-- Exact row and byte boundaries preserve all content; one excess drops all rows.
reset()
step.questsList[1] = row("x")
step.questsList[1].subTexts = {}
for index = 1, 127 do step.questsList[1].subTexts[index] = { text = "x" } end
local exact = step:GetCurrentStepDetails(false, 128, 128)
assert(#exact.questSteps == 1 and #exact.questSteps[1].subSteps == 127)
assert(#step:GetCurrentStepDetails(false, 127, 128).questSteps == 0)
assert(#step:GetCurrentStepDetails(false, 128, 127).questSteps == 0)
assert(#step:GetCurrentStepDetails(false, 0, 128).questSteps == 0)

reset()
step.questsExtraTextList.b, step.questsExtraTextList.a = row("B"), row("A")
step.questsList[2], step.questsList[10] = row("Two"), row("Ten")
step.fillersList[1] = row("Optional")
local bounded = step:GetCurrentStepDetails(false, 128, 2048)
full = step:GetCurrentStepDetails()
assert(bounded.extraLines[1].text == "A" and bounded.extraLines[2].text == "B")
assert(bounded.questSteps[1].text == "Ten" and bounded.questSteps[2].text == "Two")
assert(bounded.fillerSteps == nil and #full.fillerSteps == 1 and full.fillerSteps[1].text == "Optional")
assert(full.extraLines ~= bounded.extraLines and full.extraLines[1] ~= bounded.extraLines[1],
    "Independent exports never share mutable result rows")
assert(#step:GetCurrentStepDetails(true, 4, 2048).questSteps == 0,
    "Optional callers that include fillers share one global row budget")

-- Non-emitted placeholders keep the legacy contract; only visible text spends
-- rows. Scanning empty containers remains a documented residual synchronous cost.
reset()
for index = 1, 200 do step.questsList[index] = index % 2 == 0 and {} or row(nil) end
step.questsList[201] = row("Visible")
bounded = step:GetCurrentStepDetails(false, 1, 7)
assert(#bounded.questSteps == 1 and bounded.questSteps[1].text == "Visible")
step.questsList[201].subTexts = { {} }
assert(#step:GetCurrentStepDetails(false, 128, 2048).questSteps == 0,
    "Incomplete optional sub-text cannot break outgoing progress serialization")
APRData.player.invented, step.progressBar.currentStep = 6, 5
payload = party:BuildGroupPayload()
assert(payload.currentStep == 5 and payload.routeProgress.id == "main:6"
    and payload.stepFrameDetails.progress.index == 6, "Later snapshots observe live progress")
APR.ActiveRoute = nil
assert(step:GetCurrentStepDetails(false, 128, 2048) == nil)
table.sort = sort
print("Party snapshots: 3000 rows -> " .. firstBound .. " reads, bounded sub-objectives/bytes, complete progress and unchanged ordinary exports")
