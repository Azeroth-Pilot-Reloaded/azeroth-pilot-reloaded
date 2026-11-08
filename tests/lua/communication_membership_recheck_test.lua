local Fixture = assert(loadfile("tests/lua/communication_channel_test.lua"))("fixture")

-- A native triple may end in nil. This must not prevent the very first join.
local env = Fixture.New()
local channel = env.channel
function GetChannelList()
    return 1, "First native", nil, 2, "Second native", nil, 3, "Other addon", nil, 4, "Another addon", nil
end
channel:Acquire("partyFinder", function() end)
channel:EnsureJoined("partyFinder")
env:Advance(6)
assert(channel:IsReady() and #env.joined == 1)
assert(not channel.membershipTimer and not channel.membershipCheck)

-- The native channel disappears without a UI notification: ready is stale.
env.id = 0
channel:EnsureJoined("partyFinder")
assert(channel:IsReady() and #env.joined == 2)
env:Advance(20)
assert(#env.joined == 2 and env:ActiveTimers() == 0)

-- Reload has a new Lua service, but no retained APR membership.
env.id = 0
dofile("APR-Core/core/CommunicationChannel.lua")
channel, env.channel = APR.CommunicationChannel, APR.CommunicationChannel
channel:Acquire("partyFinder", function() end)
channel:EnsureJoined("partyFinder")
env:Advance(6)
assert(channel:IsReady() and #env.joined == 3)

-- A first native call can return normally without creating membership yet.
env = Fixture.New({ delayedJoin = true })
channel = env.channel
local attempts = 0
function JoinTemporaryChannel(name)
    assert(name == "APR")
    attempts = attempts + 1
    env.joined[#env.joined + 1] = { name = name, at = env.now }
    if attempts == 2 then env.id = 8 end
end
channel:Acquire("partyFinder", function() end)
channel:EnsureJoined("partyFinder")
env:Advance(16)
assert(channel:IsReady() and env.id == 8 and attempts == 2)
env:Advance(60)
assert(attempts == 2 and env:ActiveTimers() == 0)

-- Permanent rejection is finite, including repeated owner refreshes.
env = Fixture.New({ joinError = true })
channel = env.channel
channel:Acquire("partyFinder", function() end)
channel:EnsureJoined("partyFinder")
env:Advance(45)
assert(#env.joined == 3 and channel.status == "unavailable" and env:ActiveTimers() == 0)
for _ = 1, 100 do
    channel:EnsureJoined("partyFinder")
end
env:Advance(60)
assert(#env.joined == 3 and env:ActiveTimers() == 0)

-- Disable and countdown departure invalidate all deferred membership work.
for _, stop in ipairs({ "disable", "logout" }) do
    env = Fixture.New({ delayedJoin = true })
    channel = env.channel
    channel:Acquire("partyFinder", function() end)
    channel:EnsureJoined("partyFinder")
    local stale = channel.membershipTimer.callback
    if stop == "disable" then
        channel:Release("partyFinder")
    else
        channel:BeginDeparture()
    end
    stale()
    env:Advance(60)
    assert(#env.joined == 0 and not channel.membershipTimer)
end
print(
    "APR membership: nil native fields, stale ready, reload, confirmed recovery, finite retries and cancellation passed"
)
