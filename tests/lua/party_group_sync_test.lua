-- Exercise the complete wire path with real serialization and realm-qualified senders.
local env = dofile("tests/lua/route_ui_test_env.lua")
local setText = env.methods.SetText
function env.methods:SetText(value) setText(self, value ~= nil and tostring(value) or "") end
local uiLibStub, createFrame = LibStub, CreateFrame
strmatch = string.match
LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local serializer = LibStub("AceSerializer-3.0")
LibStub = function(name)
    if name == "AceSerializer-3.0" then return serializer end
    return uiLibStub(name)
end
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = env.widget(frame), env.widget(frame)
    end
    return frame
end

local grouped, raid, instance = true, false, false
local roster = { party1 = { "Peer", "" }, party2 = { "Peer", "Other Realm" },
    party3 = { "Local", "Other Realm" }, party4 = { "WithoutAddon", "Home" } }
local sent, timers, now = {}, {}, 10
local function advance(seconds)
    now = now + seconds
    local due = timers
    timers = {}
    for _, timer in ipairs(due) do
        if not timer.cancelled then
            if timer.at <= now then timer.callback() else timers[#timers + 1] = timer end
        end
    end
end
LE_PARTY_CATEGORY_INSTANCE = 2
function IsInGroup(category) return grouped and (category ~= LE_PARTY_CATEGORY_INSTANCE or instance) end
function IsInRaid() return raid end
function GetNormalizedRealmName() return "Home" end
function GetTime() return now end
-- These APIs need unit tokens; a sender string must not be used for membership checks.
function UnitInParty(unit) return roster[unit] ~= nil and unit:match("^party") ~= nil end
function UnitInRaid(unit) return roster[unit] and unit:match("^raid(%d+)$") end
function APR:SafeUnitName(unit)
    if unit == "player" then return "Local", "Home" end
    if roster[unit] then return unpack(roster[unit]) end
end
function APR:StartPerformanceSample() return 0 end
function APR:FinishPerformanceSample() end
function APR:IsPetBattleActive() return false end
function APR:SetPanelColor() end
function APR:GetCurrentRouteMapIDsAndName() end
function APR:GetRouteDisplayName() return "Test route" end
function APR.currentStep:GetCurrentStepDetails()
    return { progress = { index = 4, step = 4, total = 10 },
        questSteps = { { text = "Quest", subSteps = { { text = "1/5 items" } } } } }
end
APR.Username, APR.ActiveRoute = "Local", "test-route"
APR.settings.profile.enableAddon = true
APR.settings.profile.receiveGroupData = true
APR.settings.profile.showGroup = true
APR.settings.profile.groupScale = 1
C_Timer = {
    NewTicker = function() return { Cancel = function() end } end,
    NewTimer = function(delay, callback)
        local timer = { at = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end,
}
C_ChatInfo = { SendAddonMessage = function(prefix, message, channel)
    sent[#sent + 1] = { prefix = prefix, message = message, channel = channel }
end }
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/features/group/PartyProtocol.lua")
dofile("APR-Core/features/group/Party.lua")
local party = APR.party
local function receive(username, sender, step, channel)
    local payload = party:BuildGroupPayload(username)
    payload.currentStep, payload.stepFrameDetails.progress.step = step, step
    local start = #sent + 1
    APR:SendAddonMessageSplit("APRPartyData", serializer:Serialize(payload), channel or "PARTY")
    for index = #sent, start, -1 do
        local fragment = sent[index]
        party:GroupUpdateHandler(fragment.prefix, fragment.message, fragment.channel, sender)
    end
end

party:SendGroupMessage(true)
assert(party.GroupListSteps.Local.currentStep == 4)
assert(PartyScreenPanel:IsShown(), "The progress frame is visible in a party")
receive("Peer", "Peer-Home", 5)
assert(party.GroupListSteps.Peer and party.GroupListSteps.Peer.currentStep == 5,
    "Realm-qualified group senders must reach deserialization and remain visible")
assert(party.teamList.Peer.fontIndex.text == "5")
assert(party.GroupListSteps.Peer.stepFrameDetails.questSteps[1].subSteps[1].text == "1/5 items")
receive("Peer", "Peer-OtherRealm", 6)
assert(party.GroupListSteps["Peer-OtherRealm"].currentStep == 6)
assert(party.teamList["Peer-OtherRealm"].fontIndex.text == "6")
receive("Local", "Local-OtherRealm", 7)
assert(party.GroupListSteps["Local-OtherRealm"].currentStep == 7,
    "A peer with our character name on another realm is not our own echo")
assert(party.teamList.WithoutAddon.playerData.noAddon, "Members without APR remain visible")
party:PopulateMissingGroupMembers()
assert(party.teamList["Peer-OtherRealm"].playerData.currentStep == 6,
    "Roster refresh must not replace remote progress with a missing-addon placeholder")
receive("Peer", "Peer", 8)
assert(party.GroupListSteps.Peer.currentStep == 8, "Bare same-realm senders stay compatible")

local before = #sent
party:GroupUpdateHandler("APRPartyRequest", "APRPartyRequest", "PARTY", "Peer-Home")
assert(#sent == before, "A requested reply cannot bypass the send interval")
advance(2)
assert(#sent > before, "Requests from realm-qualified peers must trigger a reply")
before = #sent
party:GroupUpdateHandler("APRPartyRequest", "APRPartyRequest", "PARTY", "Outsider-Home")
assert(#sent == before, "Nonmembers cannot trigger replies")
receive("Peer", "Outsider-Home", 9)
receive("Peer", "Peer-WrongRealm", 9)
receive("Peer", "Local-Home", 9)
assert(party.GroupListSteps.Peer.currentStep == 8 and party.GroupListSteps.Local.currentStep == 4)
receive("Impostor", "Peer-Home", 9)
assert(party.lastRejectReason == "sender_mismatch" and not party.GroupListSteps.Impostor)
APR.settings.profile.receiveGroupData = false
receive("Peer", "Peer-Home", 9)
assert(party.GroupListSteps.Peer.currentStep == 8)
APR.settings.profile.receiveGroupData = true

roster.party2 = nil
party:PopulateMissingGroupMembers()
assert(not party.GroupListSteps["Peer-OtherRealm"] and not party.teamList["Peer-OtherRealm"])
assert(party.GroupListSteps.Peer.currentStep == 8, "Leaving one realm must not remove the namesake")

dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
raid = true
roster = { raid1 = { "Local", "Home" }, raid6 = { "RaidPeer", "Other Realm" } }
APR.event.functions.group("GROUP_ROSTER_UPDATE")
assert(not PartyScreenPanel:IsShown(), "Converting to a raid immediately hides the progress frame")
local raidStart = #sent
party:SendGroupMessage(true)
party:RequestData()
party:SendGroupMessageDelete()
assert(#sent == raidStart and not party.groupSendTimer, "Raids do not exchange progression data")
receive("RaidPeer", "RaidPeer-OtherRealm", 9, "RAID")
assert(not next(party.GroupListSteps) and not next(party.teamList), "Incoming raid progression is ignored")
assert(not PartyScreenPanel:IsShown(), "Incoming raid data must not show the frame")
party:RefreshPartyFrameAnchor(true)
assert(not PartyScreenPanel:IsShown(), "The frame remains hidden in a raid even in preview mode")
assert(not party.teamList.Peer, "Party members who left must be removed on a raid roster refresh")
instance = true
raidStart = #sent
party:SendGroupMessage(true)
assert(#sent == raidStart, "Instance raids also skip progression sends")
receive("RaidPeer", "RaidPeer-OtherRealm", 10, "INSTANCE_CHAT")
assert(not next(party.GroupListSteps))
assert(not PartyScreenPanel:IsShown(), "Instance raids also keep the frame hidden")
raid = false
roster = { party1 = { "RaidPeer", "Other Realm" } }
APR.event.functions.group("GROUP_ROSTER_UPDATE")
party:SendGroupMessage(true)
advance(2)
assert(PartyScreenPanel:IsShown(), "Returning to a party restores the progress frame")
assert(sent[#sent].channel == "INSTANCE_CHAT", "Instance parties still exchange progress")
receive("RaidPeer", "RaidPeer-OtherRealm", 10, "INSTANCE_CHAT")
assert(party.GroupListSteps["RaidPeer-OtherRealm"].currentStep == 10)

-- Bursts build only the newest state and obey the same interval for peer replies.
local displayedStep, builds = 4, 0
function APR.currentStep:GetCurrentStepDetails()
    builds = builds + 1
    return { progress = { index = displayedStep, step = displayedStep, total = 100 },
        questSteps = { { key = "unused", text = "Quest", subSteps = { { questID = 42, name = "unused", text = "1/5" } } } } }
end
before = #sent
for index = 1, 1000 do
    displayedStep = (index % 10) + 1
    party:SendGroupMessage()
end
assert(#sent == before and builds == 0 and party.groupSendTimer)
advance(1)
assert(#sent == before and builds == 0)
advance(1)
assert(#sent > before and builds == 1 and party.GroupListSteps.Local.currentStep == displayedStep)
before = #sent
for _ = 1, 1000 do party:SendGroupMessage() end
advance(2)
assert(#sent == before and builds == 2, "Unchanged progression causes no network traffic")
party:SendGroupMessage(true)
assert(#sent > before, "An explicit peer reply can resend an unchanged snapshot after the cooldown")
before = #sent
for _ = 1, 1000 do party:SendGroupMessage(true) end
assert(#sent == before)
advance(2)
assert(#sent > before and not party.groupSendTimer, "Forced bursts coalesce into one reply")
before = #sent
party:RequestData()
assert(#sent == before + 1)
for _ = 1, 1000 do party:RequestData() end
assert(#sent == before + 1, "Data requests have their own cooldown")
advance(5)
party:RequestData()
assert(#sent == before + 2)

-- A saturated transport retains one snapshot in flight and one latest state.
local transport = {}
ChatThrottleLib = { SendAddonMessage = function(_, priority, prefix, message, channel, target, _, callback)
    assert(priority == "BULK" and #message <= 255)
    transport[#transport + 1] = { message = message, callback = callback }
end }
local function drain(success)
    local batch = transport
    transport = {}
    for _, fragment in ipairs(batch) do fragment.callback(nil, success) end
    return batch
end
party:SendGroupMessage(true)
local queued, previousBuilds = #transport, builds
assert(queued > 0 and party.groupSendInFlight)
for index = 1, 1000 do displayedStep = (index % 10) + 1; party:SendGroupMessage() end
assert(#transport == queued and builds == previousBuilds)
advance(10)
assert(#transport == queued and builds == previousBuilds, "A blocked transport cannot accumulate obsolete snapshots")
drain(true)
advance(0.5)
assert(not next(transport), "The pending state is still deduplicated after the transport drains")
displayedStep = 12
party:SendGroupMessage()
advance(0.5)
assert(#transport > 0 and party.groupSendInFlight)
displayedStep = 13
party:SendGroupMessage()
drain(true)
advance(2)
assert(#transport > 0 and party.GroupListSteps.Local.currentStep == 13,
    "The latest changed state follows the completed snapshot")
drain(false)
assert(not party.lastGroupPayload, "Failed fragments do not suppress future retries as duplicates")

function APR.currentStep:GetCurrentStepDetails()
    local rows = {}
    for index = 1, 128 do rows[index] = { text = string.rep("x", 1000) } end
    return { progress = { index = 14, step = 14, total = 100 }, questSteps = rows }
end
party:SendGroupMessage()
advance(2)
local batch = drain(true)
local parts = {}
for _, fragment in ipairs(batch) do
    local _, index, _, part = fragment.message:match("^([^|]+)|(%d+)|(%d+)|(.*)$")
    parts[tonumber(index)] = part
end
local wire = table.concat(parts)
assert(#wire <= 2048 and #batch <= 12, "Outgoing snapshots have a strict byte and fragment budget")
local ok, decoded = serializer:Deserialize(wire)
assert(ok and decoded.currentStep == 14 and not decoded.stepFrameDetails.questSteps,
    "Oversized tooltips keep route and progress while dropping optional rows")
assert(#party.GroupListSteps.Local.stepFrameDetails.questSteps == 128, "The local tooltip remains complete")
party:SendGroupMessage()
grouped = false
advance(2)
assert(not party.groupSendTimer and not next(transport), "Leaving the group cancels pending sends")
ChatThrottleLib = nil
grouped = false
party:PopulateMissingGroupMembers()
assert(not next(party.teamList) and not next(party.GroupListSteps))
print("Party sync: real wire roundtrip, realms, raid silence, burst coalescing, deduplication, byte limits and transport backpressure passed")
