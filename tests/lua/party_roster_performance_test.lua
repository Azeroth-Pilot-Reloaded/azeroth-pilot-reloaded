-- Fragment bursts share a frame's roster without extending membership past
-- a native roster update or carrying names across party/raid transitions.
local env = dofile("tests/lua/route_ui_test_env.lua")
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = env.widget(frame), env.widget(frame)
    end
    return frame
end

local now, grouped, raid, rosterReads, versions = 10, true, false, 0, 0
local roster = { party1 = { "Peer", "Other Realm" } }
function GetTime() return now end
function IsInGroup() return grouped end
function IsInRaid() return raid end
function GetNormalizedRealmName() return "Home" end
function APR:SafeUnitName(unit)
    rosterReads = rosterReads + 1
    if roster[unit] then return unpack(roster[unit]) end
end
APR.Username = "Local"
APR.settings.profile.enableAddon = true
APR.settings.profile.receiveGroupData, APR.settings.profile.showGroup = false, false
APR.versionCheck = { HandleVersionMessage = function(_, message)
    assert(message == "synthetic-version")
    versions = versions + 1
end }
dofile("APR-Core/features/group/PartyProtocol.lua")
dofile("APR-Core/features/group/Party.lua")
local party = APR.party
local function receive(sender, channel)
    party:GroupUpdateHandler("APRVersionCheck", "synthetic-version", channel or "PARTY", sender)
end
for _ = 1, 500 do receive("Peer-OtherRealm") end
assert(versions == 500 and rosterReads == 4,
    "500 frame-local packets require four native unit-name reads instead of 2,000")
receive("Peer-Home"); receive("Outsider-OtherRealm")
assert(versions == 500 and rosterReads == 4, "A cached roster retains realm-specific membership checks")

now = now + 0.01
receive("Peer-OtherRealm")
assert(versions == 501 and rosterReads == 8, "The next frame samples current native membership")

-- Event.lua already calls PopulateMissingGroupMembers on GROUP_ROSTER_UPDATE.
roster.party1 = { "Replacement", "Home" }
party:PopulateMissingGroupMembers()
assert(rosterReads == 12, "An explicit roster update refreshes within the same game frame")
receive("Peer-OtherRealm"); receive("Replacement-Home")
assert(versions == 502 and rosterReads == 12, "Removed members are rejected immediately after the roster event")

raid, roster = true, { raid2 = { "RaidPeer", "Home" } }
receive("Replacement-Home", "RAID"); receive("RaidPeer-Home", "RAID")
assert(versions == 503 and rosterReads == 52, "Party-to-raid conversion refreshes all raid unit tokens once")
raid, roster = false, { party1 = { "NewPeer", "Home" } }
receive("RaidPeer-Home"); receive("NewPeer-Home")
assert(versions == 504 and rosterReads == 56, "Raid-to-party conversion cannot reuse raid membership")

grouped = false
receive("NewPeer-Home")
assert(versions == 504 and rosterReads == 56, "Leaving a group immediately discards all cached membership")
grouped, roster = true, { party1 = { "Rejoined", "Home" } }
receive("NewPeer-Home"); receive("Rejoined-Home")
assert(versions == 505 and rosterReads == 60, "Rejoining in the same frame obtains a fresh roster")
party:RemoveTeam()
roster.party1 = { "AfterReset", "Home" }
receive("Rejoined-Home"); receive("AfterReset-Home")
assert(versions == 506 and rosterReads == 64, "Resetting party state also resets frame-local membership")
print("Party roster: 500 packets use four native reads; frame, notification, realm, group/raid and reset invalidation passed")
