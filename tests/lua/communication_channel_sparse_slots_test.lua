-- Native community/user channels can keep high slot numbers after other channels leave.
local Fixture = assert(loadfile("tests/lua/communication_channel_test.lua"))("fixture")

for _, client in ipairs({ "retail", "forever" }) do
    local env = Fixture.New({ client = client })
    local channel = env.channel
    env.unrelatedChannels = { Alpha = 1, Beta = 2, Gamma = 3, Delta = 4, ["Synthetic community"] = 11 }
    function JoinTemporaryChannel(name)
        assert(name == "APR")
        env.id = 5
        env.joined[#env.joined + 1] = { name = name, at = env.now }
    end
    channel:Acquire("partyFinder", function() end)
    env:Advance(4.99)
    assert(#env.joined == 0, "Sparse user channels do not bypass the startup grace period")
    env:Advance(0.01)
    assert(
        #env.joined == 1 and channel:IsReady() and channel:GetSendChannelID() == 5,
        "A gap after the native slots must not leave discovery waiting forever"
    )
    assert(
        env.unrelatedChannels.Alpha == 1
            and env.unrelatedChannels.Beta == 2
            and env.unrelatedChannels["Synthetic community"] == 11,
        "Joining a free later slot must not renumber the player's existing channels"
    )
    for _ = 1, 100 do
        env:Event("CHANNEL_UI_UPDATE")
    end
    env:Advance(1)
    assert(#env.joined == 1 and env:ActiveTimers() == 0)

    for _, native in ipairs({ { Alpha = 1, Later = 11 }, { Beta = 2, Later = 11 } }) do
        env = Fixture.New({ client = client })
        env.unrelatedChannels = native
        env.channel:Acquire("partyFinder", function() end)
        env:Advance(60)
        assert(
            #env.joined == 0 and env.channel.status == "joining" and not env.channel.attempted,
            "A later community channel does not authorize occupying missing native /1 or /2"
        )
    end
end

print(
    "Shared channel sparse slots: later gaps allowed on both clients, native-slot protection, startup and stable numbering passed"
)
