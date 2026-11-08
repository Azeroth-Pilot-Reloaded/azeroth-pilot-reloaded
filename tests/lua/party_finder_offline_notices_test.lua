local Fixture = dofile("tests/lua/party_finder_test_env.lua")
local env = Fixture.New({ regional = true })
local finder = env.finder
local filter, adds, removes = nil, 0, 0
ERR_CHAT_PLAYER_NOT_FOUND_S = "No player named '%s' is playing."
ChatFrameUtil = {
    AddMessageEventFilter = function(event, callback)
        assert(event == "CHAT_MSG_SYSTEM")
        filter, adds = callback, adds + 1
    end,
    RemoveMessageEventFilter = function(event, callback)
        assert(event == "CHAT_MSG_SYSTEM" and callback == filter)
        filter, removes = nil, removes + 1
    end,
}

local function send(name)
    local query = env:Query({ id = "automatic" })
    return finder:SendDirect("Q", env.protocol.Encode("Q", query), name)
end

assert(send("Invented Surname"))
assert(filter and adds == 1)
local offline = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "Invented Surname")
assert(filter({}, "CHAT_MSG_SYSTEM", offline))
assert(filter({}, "CHAT_MSG_SYSTEM", offline), "Each chat window must suppress the same native notice")
assert(not filter({}, "CHAT_MSG_SYSTEM", "You received loot."))
assert(not filter({}, "CHAT_MSG_SYSTEM", string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "Other Surname")))
assert(not filter({}, "CHAT_MSG_WHISPER", offline))
env:Advance(3)
assert(send("Second Surname"))
env:Advance(2.1)
assert(filter and not filter({}, "CHAT_MSG_SYSTEM", offline))
assert(filter({}, "CHAT_MSG_SYSTEM", string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "Second Surname")))
finder:StopDirectTransport()
env:Advance(3)
assert(not filter and removes == 1 and not finder.directOfflineNotices)

-- A queued-but-unsent request never hides a manual error for that player.
finder:InitializeDirectTransport()
env.directCTL.avail, env.directCTL.bQueueing = -100000, true
assert(send("Queued Surname"))
assert(not filter)
finder:StopDirectTransport()
env.directCTL.avail = 10000
env:PumpDirect(1)
assert(not filter)

-- Cancelling a pending search cannot resurrect it when its fingerprint finishes.
finder.query = nil
finder.searchWanted = true
finder:StopSearch()
assert(not finder.query and not finder.searchWanted)
print(
    "Private finder errors: exact localized recent targets, multiple windows, TTL, bounded cleanup and unsent cancellation passed"
)
