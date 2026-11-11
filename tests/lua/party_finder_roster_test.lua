local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function New(count, options)
    local env = Fixture.New(options)
    env.roster, env.selected, env.selections = {}, 2, {}
    for i = 1, count do
        env.roster[i] = "Peer" .. i .. "-Home"
    end
    env.population = count + 1
    function GetSelectedDisplayChannel() return env.selected end
    function SetSelectedDisplayChannel(index)
        env.selected = index
        env.selections[#env.selections + 1] = index
    end
    C_ChatInfo.GetChannelRosterInfo = function(index, row)
        assert(
            index == (env.finder:GetRosterTransport() == APR.CommunicationChannel and 3 or 4),
            "Roster must use display index, not local channel number"
        )
        if env.rosterMissing then return end
        return row == 1 and GetUnitName("player") or env.roster[row - 1]
    end
    return env, env.finder, env.finder:GetSearchTransport()
end

local function Deny(env, channel, id, name)
    env:Event(
        "CHAT_MSG_CHANNEL_NOTICE",
        "NOT_ALLOWED_IN_CHANNEL",
        "",
        "",
        "",
        "",
        "",
        0,
        id or channel:GetChannelID(),
        name or channel.name
    )
end

local env, finder, channel = New(48)
assert(finder:Search())
assert(channel.addonTransport == nil, "Success never certifies delivery")
Deny(env, channel, 1, "Other")
assert(not finder.sweep and channel.addonTransport == nil)
Deny(env, channel)
assert(channel.addonTransport == "blocked" and channel:IsReady() and finder.sweep)
env:Advance(0.1)
assert(env.selected == 2 and env.selections[1] == 4 and env.selections[2] == 2)
assert(finder.sweep.total == 48)
local first = finder.query.id
env:Receive("P", env:Presence(), "Unasked-Home", "WHISPER")
assert(finder:GetCount() == 0)
env:Receive("P", env:Presence(), "Peer1-Home", "WHISPER")
assert(finder:GetCount() == 1, "First answer appears before later batches")
env:Advance(5.7)
assert(#env:Messages("Q", "WHISPER") == 24)
env:Advance(4.9)
assert(#env:Messages("Q", "WHISPER") == 24, "Five seconds between batches belong to replies")
env:Advance(0.5)
assert(finder.query.id ~= first)
env:Receive("P", env:Presence({ id = first }), "Peer1-Home", "WHISPER")
assert(finder.candidates["Peer1-Home"].queryID == first)
env:Advance(22)
assert(not finder.sweep and #env:Messages("Q", "WHISPER") == 48)
local previous
for _, msg in ipairs(env:Messages("Q", "WHISPER")) do
    if previous then assert(msg.at - previous >= 0.2499) end
    previous = msg.at
end

env, finder, channel = New(2)
assert(finder:Search())
env:Advance(11)
assert(channel.addonTransport == nil and not finder.sweep, "Silence is unknown, never blocked")
env:Advance(6)
Deny(env, channel)
assert(channel.addonTransport == nil, "A stale attempt cannot attribute a server refusal")

env, finder, channel = New(3)
env.rosterMissing = true
assert(finder:Search())
Deny(env, channel)
env:Advance(2)
assert(finder.sweep.loading and #env:Messages("Q", "WHISPER") == 0)
env.rosterMissing = false
env:Event("CHANNEL_ROSTER_UPDATE", 4, 4)
env:Advance(0.4)
assert(finder.sweep and not finder.sweep.loading and finder.sweep.total == 3)
finder:StopAPRSweep()
local sent = #env.sent
env:Advance(40)
assert(#env.sent == sent and not finder.query)

env, finder, channel = New(2)
env.roster = { "Peer-Home", "Peer-Home" }
assert(finder:Search())
Deny(env, channel)
env:Advance(0.1)
assert(finder.sweep.total == 1, "Deduplicate and exclude self")
finder:SetOption("minLevel", 5)
assert(not finder.sweep)

-- Non-friends require native membership, including at response dispatch.
env, finder = New(1)
env:Receive("Q", env:Query(), "Peer1-Home", "WHISPER")
env:Advance(0.5)
assert(#env:Messages("P", "WHISPER") == 1)
env:Receive("Q", env:Query({ id = "foreign" }), "Stranger-Home", "WHISPER")
env:Advance(11)
assert(#env:Messages("P", "WHISPER") == 1)

env, finder, channel = New(2, { regional = true, client = "forever" })
env.roster = { "Same Givenname", "Same Othername" }
assert(finder:Search())
Deny(env, channel)
env:Advance(0.1)
assert(finder.sweep.total == 2 and finder.query.targets["Same Givenname"])
env:Event("PLAYER_CAMPING")
local before = #env.sent
env:Event("LOGOUT_CANCEL")
env:Advance(2)
assert(not finder.sweep and not finder.query and #env.sent == before)

env, finder, channel = New(1)
env.rosterMissing = true
assert(finder:Search())
Deny(env, channel)
env:Advance(11)
assert(not finder.sweep and finder.status == "roster_unavailable")
assert(#env:Messages("Q", "WHISPER") == 0)

env, finder, channel = New(2)
env.roster[2] = nil
assert(finder:Search())
Deny(env, channel)
env:Advance(11)
assert(finder.sweep.total == 1 and finder.rosterStatus == "partial")
env:Receive("P", env:Presence(), "Peer1-Home", "WHISPER")
finder:StopAPRSweep()
finder.candidates["Peer1-Home"].seenAt = env.now - 121
finder.candidatesDirty = true
assert(finder:GetCandidates()[1].stale)
assert(finder:RevalidateCandidate("Peer1-Home"))
env:Receive("P", env:Presence(), "Peer1-Home", "WHISPER")
assert(not finder:GetCandidates()[1].stale)

env, finder, channel = New(1)
C_ChatInfo.GetChannelRosterInfo = nil
assert(finder:Search())
Deny(env, channel)
assert(not finder.sweep and finder.status == "roster_unavailable")

env, finder, channel = New(1, { client = "forever" })
C_GameRules.IsGameRuleActive = nil
local context = finder:GetContext(501)
assert(context == nil and finder.rulesetIdentity:find("?", 1, true))
C_GameRules.GetCurrentGameModeRecordID = function() return 543 end
context = finder:GetContext(501)
assert(context and finder.rulesetIdentity:find("mode=543", 1, true))
local other = context
C_GameRules.GetCurrentGameModeRecordID = function() return 544 end
assert(finder:GetContext(501) ~= other)

env, finder, channel = New(1, { friends = { { name = "Wisp-Home", connected = true } } })
C_ChatInfo.GetChannelRosterInfo = nil
assert(finder:Search())
local friendQuery = finder.query
Deny(env, channel)
assert(not finder.sweep and finder.query == friendQuery, "An unavailable roster preserves the ongoing friend transport")
env:Receive("P", env:Presence(), "Wisp-Home", "WHISPER")
assert(finder:GetCount() == 1)

-- Renumbering before a roster request still selects APR by display index.
env, finder, channel = New(2)
assert(finder:Search())
env.channels[channel.name], env.channelID = 9, 9
channel:Refresh()
channel:RecordSend(9, true, 0)
Deny(env, channel, 9)
env:Advance(0.1)
assert(finder.sweep and finder.sweep.total == 2 and finder.channelID == 9 and finder.worldChannelID == 7)
local currentID = finder.query.id
env:ReceiveWire("0|P|legacy", "Peer1-Home", "WHISPER")
assert(finder.query.id == currentID and finder:GetCount() == 0)
finder:SetOption("enabled", false)
local stopped = #env.sent
env:Advance(20)
assert(not finder.sweep and #env.sent == stopped)

-- Thousands of members, bounded native rate and all batches, no 30/200 cap.
env, finder, channel = New(2401)
local native = C_ChatInfo.SendAddonMessage
C_ChatInfo.SendAddonMessage = function(prefix, wire, distribution, target)
    local result = native(prefix, wire, distribution, target)
    local packet = env.protocol.Decode(wire)
    if distribution == "WHISPER" and packet.kind == "Q" then
        env:Receive("P", env:Presence({ id = packet.id }), target, "WHISPER")
    end
    return result
end
assert(finder:Search())
Deny(env, channel)
for _ = 1, 1800 do
    env:Advance(1)
    local timers = {}
    for _, timer in ipairs(env.timers) do
        if not timer.fired and not timer.cancelled then timers[#timers + 1] = timer end
    end
    env.timers = timers
    if not finder.sweep then break end
end
assert(not finder.sweep and #env:Messages("Q", "WHISPER") == 2401)
assert(finder:GetCount() == 2401, "Retain accumulated results throughout a long sweep")
assert(finder.candidates["Peer1-Home"].stale)
env:Advance(119)
assert(finder:GetCount() == 2401)
env:Advance(2)
assert(finder:GetCount() == 0)

-- CTL back pressure leaves one request queued; Stop cancels it at dispatch.
env, finder, channel = New(100)
env.directCTL.avail, env.directCTL.bQueueing = -100000, true
assert(finder:Search())
Deny(env, channel)
env:Advance(0.1)
finder:StopAPRSweep()
env.directCTL.avail = 10000
env:PumpDirect(1)
assert(#env:Messages("Q", "WHISPER") == 0)

print(
    "APR roster: asynchronous refusal, silence, verified peers, progressive batches, pacing, retention and cancellation passed"
)
