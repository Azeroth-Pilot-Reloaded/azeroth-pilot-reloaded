-- Faction channels share the original service's lifecycle and both consumers.
local Fixture = assert(loadfile("tests/lua/communication_channel_test.lua"))("fixture")
for _, case in ipairs({
    { client = "forever", faction = "Alliance", name = "APRAlliance", other = "APRHorde" },
    { client = "forever", faction = "Horde", name = "APRHorde", other = "APRAlliance" },
    { client = "retail", faction = "Alliance", name = "APR" },
    { client = "retail", faction = "Horde", name = "APR" },
}) do
    local env = Fixture.New(case)
    local channel = env.channel
    if case.other then
        env.retired.APR, env.retired[case.other] = 8, 9
    end
    -- The first return is the stable tag, not the translated display label.
    function UnitFactionGroup() return case.faction, "Localized faction" end
    APRData = {}
    dofile("APR-Core/features/group/PartyProtocol.lua")
    dofile("APR-Core/core/VersionCheck.lua")
    APR.versionCheck:OnInit()
    channel:Acquire("partyFinder", function() end)
    env:Advance(5)
    assert(channel:IsReady() and channel.name == case.name)
    assert(#env.joined == 1 and env.joined[1].name == case.name)
    assert(#env.sent == 1 and env.sent[1].target == channel:GetChannelID())
    if case.other then
        assert(#env.left == 2 and not next(env.retired), "Retire old common/opposite membership only after joining")
    else
        assert(#env.left == 0, "Retail keeps its common channel")
    end
    local version = APR.versionCheck
    version:HandleSharedMessage(
        "APRVersionCheck",
        "V:8.0.0",
        "CHANNEL",
        "Peer-Home",
        nil,
        0,
        env.id,
        case.other or "Other"
    )
    assert(APRData.versionCheck[case.client] ~= "8.0.0", "The opposite channel cannot provide a version reply")
    version:HandleSharedMessage("APRVersionCheck", "V:8.0.0", "CHANNEL", "Peer-Home", nil, 0, env.id, case.name)
    assert(APRData.versionCheck[case.client] == "8.0.0", "Versions consume the same faction rendezvous as discovery")
    channel:Release("partyFinder")
    assert(channel:IsReady(), "The version consumer retains shared ownership")
    version:StopSharedChannel()
    assert(env.left[#env.left] == case.name and env.id == 0)
end

-- A missing/neutral/secret faction must never fall back to the common/opposite channel.
for _, pending in ipairs({ "Neutral", "Unknown", "missing", "secret", "api" }) do
    local env = Fixture.New({ client = "forever", faction = "Horde" })
    env.faction = pending
    if pending == "missing" then env.faction = nil end
    if pending == "secret" then env.faction = "Horde" end
    local unitFaction = UnitFactionGroup
    if pending == "api" then UnitFactionGroup = nil end
    if pending == "secret" then env.secret = "Horde" end
    env.channel:Acquire("partyFinder", function() end)
    env:Advance(6)
    assert(#env.joined == 0 and not env.channel.name)
    env:Event("CHAT_MSG_CHANNEL_NOTICE", "NOT_ALLOWED_IN_CHANNEL", "", "", "", "", "", 0, 7, "APR")
    env.channel:ObserveReceive(nil, "APR")
    assert(not env.channel.lastNotice and not env.channel.lastReceive)
    env.faction, env.secret, UnitFactionGroup = "Horde", nil, unitFaction
    env:Event("PLAYER_ENTERING_WORLD")
    env:Advance(6)
    assert(#env.joined == 1 and env.joined[1].name == "APRHorde" and env.channel:IsReady())
    env:Advance(60)
    assert(#env.joined == 1 and env:ActiveTimers() == 0)
end
print(
    "Faction channels: Alliance/Horde isolation, Retail stability, migration, shared versions and deferred faction readiness passed"
)

local FinderFixture = dofile("tests/lua/party_finder_test_env.lua")
for _, case in ipairs({
    { faction = "Alliance", name = "APRAlliance", other = "APRHorde" },
    { faction = "Horde", name = "APRHorde", other = "APRAlliance" },
}) do
    local env = FinderFixture.New({ client = "forever", faction = case.faction, population = 2 })
    local finder, channel = env.finder, APR.CommunicationChannel
    assert(channel.name == case.name and finder.channelName == case.name .. "Z501" and finder.worldChannelName == case.name)
    C_ChatInfo.GetChannelRosterInfo = function(index, row)
        assert(index == 4)
        return row == 1 and GetUnitName("player") or row == 2 and "Friendly-Home" or nil
    end
    assert(finder:Search())
    env:Event("CHAT_MSG_CHANNEL_NOTICE", "NOT_ALLOWED_IN_CHANNEL", "", "", "", "", "", 0, 7, case.other)
    assert(not finder.sweep, "The opposite faction's notice cannot restrict this transport")
    env:Event("CHAT_MSG_CHANNEL_NOTICE", "NOT_ALLOWED_IN_CHANNEL", "", "", "", "", "", 0, finder.channelID, finder.channelName)
    env:Advance(0.1)
    assert(finder.sweep and finder.sweep.total == 1 and finder.sweep.sent == 1)
    env:Receive("P", env:Presence(), "Friendly-Home", "WHISPER")
    assert(finder:GetCount() == 1, "Private roster discovery works on either faction channel")
    env:Event("PLAYER_CAMPING")
    assert(not channel:IsReady() and not finder.zoneChannel:IsReady() and not env.channels[case.name] and not env.channels[case.name .. "Z501"])
    env:Event("LOGOUT_CANCEL")
    env:Advance(6)
    assert(channel:IsReady() and finder.zoneChannel:IsReady())
    for _, name in ipairs(env.joined) do
        assert(name == case.name or name == case.name .. "Z501", "Recovery must never join another faction")
    end
end
print(
    "Faction discovery: roster lookup, isolated notices, private replies and logout cancellation passed for both factions"
)
