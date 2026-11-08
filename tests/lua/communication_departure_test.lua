local Fixture = loadfile("tests/lua/communication_channel_test.lua")("fixture")
for _, prejoined in ipairs({ false, true }) do
    local env = Fixture.New({ prejoined = prejoined })
    local channel, states = env.channel, {}
    channel:Acquire("one", function(_, status) states[#states + 1] = status end)
    channel:Acquire("two", function() end)
    env:Advance(6)
    local joins = #env.joined
    env:Event("PLAYER_CAMPING")
    env:Event("PLAYER_QUITING")
    assert(#env.left == 1 and not channel:IsReady() and channel.owners.one and channel.owners.two)
    assert(channel:GetSendChannelID() == nil)
    channel:Retry()
    channel:Acquire("three", function() end)
    env:Advance(30)
    assert(#env.joined == joins)
    channel:Release("two")
    env:Event("LOGOUT_CANCEL")
    assert(channel:IsReady() and #env.joined == joins + 1 and not channel.owners.two and channel.owners.three)
    env:Event("LOGOUT_CANCEL")
    assert(#env.joined == joins + 1)
    channel:Release("one")
    channel:Release("three")
    assert(#env.left == (prejoined and 1 or 2), "Cancellation preserves native prejoined ownership")
end

local env = Fixture.New()
local channel = env.channel
channel:Acquire("one", function() end)
local stale = channel.startTimer.callback
env:Event("PLAYER_CAMPING")
channel:Release("one")
env:Event("LOGOUT_CANCEL")
stale()
assert(#env.joined == 0 and not next(channel.owners), "Cancelled startup cannot revive a released owner")

env = Fixture.New({ prejoined = true })
channel = env.channel
channel:Acquire("one", function() end)
env:Event("PLAYER_QUITING")
env:Event("PLAYER_LOGOUT")
assert(#env.left == 1 and not next(channel.owners))
print(
    "Shared departure: immediate forced leave, preserved leases, idempotence, cancellation and stale callback guards passed"
)

env = Fixture.New({ prejoined = true })
channel = env.channel
channel:Acquire("one", function() end)
env:Event("PLAYER_CAMPING")
env.restricted = true
env:Event("LOGOUT_CANCEL")
assert(not channel:IsReady() and channel.status == "restricted")
env.restricted = false
env:Event("PLAYER_REGEN_ENABLED")
assert(channel:IsReady())
channel:Release("one")
assert(#env.left == 1, "A deferred cancellation restore preserves external ownership")

-- Native cancellation can precede the end of chat lockdown.
env = Fixture.New({ prejoined = true })
channel = env.channel
channel:Acquire("one", function() end)
env:Event("PLAYER_CAMPING")
env.restricted = true
env:Event("LOGOUT_CANCEL")
env.restricted = false
-- No regen/zone/channel event is needed to finish recovery.
env:Advance(0.5)
assert(channel:IsReady() and #env.joined == 1)
channel:Release("one")
assert(#env.left == 1)

-- Cancellation may beat the asynchronous leave acknowledgement.
env = Fixture.New({ prejoined = true })
channel = env.channel
channel:Acquire("one", function() end)
LeaveChannelByName = function(name)
    env.left[#env.left + 1] = name
    C_Timer.NewTimer(0.5, function()
        env.id = 0
        env:Event("CHAT_MSG_CHANNEL_NOTICE", "YOU_LEFT", "", "", "", "", "", 0, 7, "APR")
    end)
end
env:Event("PLAYER_CAMPING")
env:Event("PLAYER_STARTED_MOVING")
env:Advance(1)
assert(channel:IsReady() and #env.joined == 1, "The delayed leave cannot strand the cancelled logout")
env:Event("LOGOUT_CANCEL")
env:Advance(2)
assert(#env.joined == 1)

-- The native Cancel button is also observed when no cancellation event arrives.
env = Fixture.New({ prejoined = true })
channel = env.channel
local postCancel
function CancelLogout() end
function hooksecurefunc(name, callback)
    assert(name == "CancelLogout")
    postCancel = callback
end
channel:Acquire("one", function() end)
env:Event("PLAYER_QUITING")
assert(postCancel)
postCancel()
env:Advance(0.5)
assert(channel:IsReady() and #env.joined == 1)

-- Standing hides the native countdown even on clients missing the cancel event.
env = Fixture.New({ prejoined = true })
channel = env.channel
local visible = true
function StaticPopup_FindVisible(which) return which == "CAMP" and visible or nil end
channel:Acquire("one", function() end)
env:Event("PLAYER_CAMPING")
env:Advance(0.5)
visible = false
env:Advance(0.5)
assert(channel:IsReady() and #env.joined == 1)

-- Natural expiration and final logout must never trigger this fallback.
env = Fixture.New({ prejoined = true })
channel = env.channel
visible = true
channel:Acquire("one", function() end)
env:Event("PLAYER_CAMPING")
env:Advance(19.5)
visible = false
env:Advance(1)
assert(channel.departing and #env.joined == 0)
env:Event("PLAYER_LOGOUT")
assert(not next(channel.owners) and env:ActiveTimers() == 0)
