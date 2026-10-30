-- The real version consumer and channel service share a synthetic native client.
local Fixture = assert(loadfile("tests/lua/communication_channel_test.lua"))("fixture")

local function New(options)
    local env = Fixture.New(options)
    APRData = {}
    dofile("APR-Core/features/group/PartyProtocol.lua")
    dofile("APR-Core/core/VersionCheck.lua")
    APR.versionCheck:OnInit()
    env.version = APR.versionCheck
    return env
end

local function Receive(env, message, id, name)
    env.version:HandleSharedMessage("APRVersionCheck", message, "CHANNEL", "Peer-Home", nil, 0,
        id or env.id, name or "APR")
end

for _, client in ipairs({"retail", "forever"}) do
    for _, flags in ipairs({{true, false}, {false, true}}) do
        local env = New({client = client})
        local channel, finderID = env.channel
        channel:Acquire("partyFinder", function(id) finderID = id end)
        assert(channel.owners.versionCheck and channel.owners.partyFinder and #env.frames == 1,
            "Both consumers borrow the one service frame")
        env:Event("PLAYER_ENTERING_WORLD", unpack(flags))
        env:Advance(1.99)
        assert(#env.joined == 0 and #env.sent == 0)
        env:Advance(0.01)
        assert(#env.joined == 1 and env.joined[1].name == "APR" and finderID == 7
            and channel:GetChannelID() == 7 and env.version.sharedChannelID == 7)
        assert(#env.sent == 1 and env.sent[1].prefix == "APRVersionCheck"
            and env.sent[1].message == "Q:7.3.0" and env.sent[1].target == 7)
        env:Advance(12)
        assert(#env.sent == 2 and env.sent[2].at - env.sent[1].at == 12 and env:ActiveTimers() == 0,
            "Login and reload each retain exactly one bounded query retry")
        for index = 1, 100 do
            env.map = index % 2 == 0 and 501 + index or nil
            env.instance, env.restricted = index % 3 == 0, index % 4 == 0
            env:Event("PLAYER_ENTERING_WORLD", false, false)
            env:Event("CHANNEL_UI_UPDATE")
            env:Event("PLAYER_REGEN_ENABLED")
            env:Advance(0.1)
            assert(#env.joined == 1 and #env.left == 0 and channel:GetChannelID() == 7,
                "Zone/map/instance/restriction changes cannot churn either consumer's shared membership")
        end
        assert(#env.sent == 2 and channel.owners.versionCheck and channel.owners.partyFinder)
        env.version:OnDisable()
        assert(channel.owners.partyFinder and not channel.owners.versionCheck and #env.left == 0)
        channel:Release("partyFinder")
        assert(#env.left == 1 and env:ActiveTimers() == 0 and not next(channel.frame.events))
    end
end

-- A newer direct response still suppresses the startup retry and updates cache.
local env = New()
env.channel:Acquire("partyFinder", function() end)
env:Advance(2)
Receive(env, "V:7.4.0")
assert(env.alerts == 1 and APRData.versionCheck.retail == "7.4.0")
env:Advance(60)
assert(#env.sent == 1 and env:ActiveTimers() == 0 and #env.joined == 1 and #env.left == 0)

-- Renumbering changes both consumers' authoritative ID without another join.
env = New()
local finderID
env.channel:Acquire("partyFinder", function(id) finderID = id end)
env:Advance(2)
env.id = 9
env:Event("CHANNEL_UI_UPDATE")
env:Advance(0.1)
assert(finderID == 9 and env.version.sharedChannelID == 9 and #env.joined == 1)
Receive(env, "V:7.4.0", 7)
assert(not env.alerts and APRData.versionCheck.retail == "7.3.0")
env:Advance(11.9)
assert(#env.sent == 2 and env.sent[2].target == 9, "The bounded retry follows native renumbering")
Receive(env, "V:7.4.0", 9, "apr")
assert(env.alerts == 1)

-- Startup lockdown waits for the native restriction to end, keeping owners.
env = New({restricted = true})
env.channel:Acquire("partyFinder", function() end)
env:Advance(20)
assert(#env.joined == 0 and #env.sent == 0 and env:ActiveTimers() == 0)
env.restricted = false
env:Event("PLAYER_REGEN_ENABLED")
assert(#env.joined == 1 and #env.sent == 1 and env.sent[1].target == 7)
env:Advance(12)
assert(#env.sent == 2 and #env.left == 0 and env:ActiveTimers() == 0)

-- A prejoined or asynchronously completed channel can become ready while chat
-- remains restricted. Its later usable transition must still start versions.
for _, options in ipairs({{prejoined = true, restricted = true}, {delayedJoin = true}}) do
    env = New(options)
    env.channel:Acquire("partyFinder", function() end)
    if options.delayedJoin then
        env:Advance(2)
        env.restricted, env.id = true, 7
        env:Advance(10) -- Native membership completes without CHANNEL_UI_UPDATE.
    end
    assert(#env.sent == 0 and env.channel:GetChannelID() == 7 and not env.channel:IsReady())
    local joins = #env.joined
    env.restricted = false
    env:Event("PLAYER_REGEN_ENABLED")
    env:Advance(0.1)
    assert(#env.sent == 1 and env.sent[1].message == "Q:7.3.0" and #env.joined == joins,
        "The first usable callback starts discovery without replacing the existing membership")
    env:Advance(12)
    assert(#env.sent == 2 and #env.left == 0 and env:ActiveTimers() == 0)
end

-- A temporary lockdown stops a pending retry/response from reaching the native
-- send API, but never revokes either consumer's membership or starts polling.
env = New()
env.channel:Acquire("partyFinder", function() end)
env:Advance(2)
Receive(env, "Q:7.2.0")
env.restricted = true
env:Event("CHANNEL_UI_UPDATE")
env:Advance(15)
assert(#env.sent == 1 and #env.joined == 1 and #env.left == 0 and env.channel:GetChannelID() == 7
    and env.channel.owners.versionCheck and env.channel.owners.partyFinder and env:ActiveTimers() == 0,
    "Temporary restrictions suppress native sends while preserving both references")
env.restricted = false
env:Event("PLAYER_REGEN_ENABLED")
env:Advance(0.1)
Receive(env, "Q:7.2.0")
env:Advance(2)
assert(#env.sent == 2 and env.sent[2].message == "V:7.3.0" and #env.left == 0)

-- A failed version transport must not leave or cancel a channel still used by
-- discovery, including when the ready callback releases versions reentrantly.
env = New({sendResult = 7})
env.channel:Acquire("partyFinder", function() end)
env:Advance(30)
assert(not env.channel.owners.versionCheck and env.channel.owners.partyFinder and #env.joined == 1
    and #env.left == 0 and env.channel:IsReady() and env:ActiveTimers() == 0)
env.channel:Release("partyFinder")
assert(#env.left == 1)

env = New({client = "classic"})
env.channel:Acquire("partyFinder", function() end)
env:Advance(60)
assert(#env.joined == 0 and #env.sent == 0 and env:ActiveTimers() == 0)

print("Version/shared service integration: solo login/reload, one membership for both owners, 100 transitions, bounded retry, renumbering and restrictions passed")
