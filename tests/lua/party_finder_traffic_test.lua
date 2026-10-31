local Fixture = dofile("tests/lua/party_finder_test_env.lua")
for _, client in ipairs({"retail", "forever"}) do
    local env = Fixture.New({client = client})
    local finder = env.finder
    finder:ClearTraffic()
    assert(finder:Search())
    local rows = finder:GetTrafficRows()
    assert(rows[1].direction == "TX" and rows[1].kind == "Q" and rows[1].channel == "CHANNEL"
        and rows[1].result == "0" and rows[1].wire:sub(1, 4) == "1|Q|")
    for _ = 1, 100 do assert(not finder:Search()) end
    assert(#env:Messages("Q") == 1 and finder:GetSearchCooldown() == 60,
        "Repeated clicks must not issue additional queries")
    env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
    rows = finder:GetTrafficRows()
    assert(rows[1].result == "candidate" and rows[2].direction == "RX" and rows[2].kind == "P")
    env:ReceiveWire("broken", "Peer-Home", "WHISPER")
    assert(finder:GetTrafficRows()[1].result == "decode")
    env:Advance(11)
    assert(not finder.query and finder:GetSearchCooldown() == 49)
    env:Advance(49)
    assert(finder:GetSearchCooldown() == 0 and finder:Search())
    finder:ClearTraffic()
    for index = 1, 450 do
        env.now = env.now + 1
        finder:TraceTraffic("TX", "Q", "CHANNEL", index, "0", "packet " .. index)
    end
    rows = finder:GetTrafficRows()
    assert(#rows == 300 and rows[1].wire == "packet 450" and rows[300].wire == "packet 151")
    assert(finder.traffic.total == 450 and finder.traffic.sent == 450)
    finder:ClearTraffic()
    for _ = 1, 1000 do finder:TraceTraffic("RX", "?", "WHISPER", "Peer", "decode", "bad\npacket") end
    assert(finder.traffic.count == 128 and finder.traffic.dropped == 872 and finder.traffic.received == 1000)
    assert(finder:GetTrafficRows()[1].wire == "bad?packet")
    finder:ClearTraffic()
    assert(#finder:GetTrafficRows() == 0)
    env = Fixture.New({client = client})
    finder = env.finder
    local query = env:Query({id = "during-refresh"})
    env:Event("GROUP_ROSTER_UPDATE")
    env:Receive("Q", query, "Waiting-Home")
    assert(finder.pendingQueries and finder.pendingQueries["Waiting-Home"] and not next(finder.responses))
    env:Advance(10)
    assert(not finder.pendingQueries and #env:Messages("P") == 1,
        "A valid query racing a local refresh must receive its private response")
    env = Fixture.New({client = client})
    finder = env.finder
    query = env:Query({id = "cancel-before-refresh"})
    env:Event("GROUP_ROSTER_UPDATE")
    env:Receive("Q", query, "Waiting-Home")
    env:Receive("D", {id = "cancel-before-refresh"}, "Waiting-Home")
    env:Advance(10)
    assert(#env:Messages("P") == 0, "Cancellation also retires a deferred query")
end
print("Finder traffic: both clients, attempts, reception, rejections, cooldown, ring order and flood limits passed")
