-- Synthetic realm traffic over the real codec, AceComm and CTL; no live directory.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function Count(entries)
    local count = 0
    for _ in pairs(entries) do count = count + 1 end
    return count
end

local function ForbiddenChat()
    error("Discovery cannot reorder channels, reset native channels or modify chat windows")
end

local function New(options)
    SwapChatChannelsByChannelIndex, SwapChatChannelByLocalID = ForbiddenChat, ForbiddenChat
    ChatConfigChannelSettings_SwapChannelsByIndex = ForbiddenChat
    AddChatWindowChannel, RemoveChatWindowChannel = ForbiddenChat, ForbiddenChat
    ChatFrame_AddChannel, ChatFrame_RemoveChannel = ForbiddenChat, ForbiddenChat
    SetSelectedDisplayChannel, ListChannelByName, GetChannelRosterInfo = ForbiddenChat, ForbiddenChat, ForbiddenChat
    ChatFrameUtil = {AddChannel = ForbiddenChat, RemoveChannel = ForbiddenChat}
    local original = dofile
    dofile = function(path)
        if path == "APR-Core/core/CommunicationChannel.lua" then
            C_ChatInfo.SwapChatChannelsByChannelIndex = ForbiddenChat
            C_ChatInfo.ResetDefaultZoneChannels = ForbiddenChat
        end
        return original(path)
    end
    local ok, env = pcall(Fixture.New, options)
    dofile = original
    assert(ok, env)
    return env
end

local function Queued(env)
    local pipe = env.directCTL.Prio.NORMAL.ByName.APRFindV1
    return pipe and #pipe or 0
end

local function BlockOutput(env)
    env.directCTL.avail, env.directCTL.bQueueing = 0, true
    for _, priority in pairs(env.directCTL.Prio) do priority.avail = 0 end
end

-- A realm-scale stream of map/rules/instance transitions retains one membership.
for _, client in ipairs({"retail", "forever"}) do
    local env = New({client = client, population = 10000})
    local finder = env.finder
    assert(finder.channelID == 7 and #env.joined == 1 and env.joined[1] == "APR")
    for index = 1, 100 do
        env.map, env.warMode, env.instance = 600 + index, index % 2 == 0, index % 5 == 0
        env:Event("ZONE_CHANGED_NEW_AREA")
        env:Advance(0.5)
        assert(finder.channelName == "APR" and finder.worldChannelName == "APR"
            and finder.channelID == 7 and finder.worldChannelID == 7)
    end
    env.instance = false
    env:Event("PLAYER_ENTERING_WORLD")
    env:Advance(0.5)
    assert(#env.joined == 1 and #env.left == 0 and #env:Messages("Q") == 0 and #env:Messages("P") == 0)
    assert(not next(finder.responses) and env:ActiveTimers() == 0,
        "Stable membership and inactive discovery must settle without polling")
end

-- Count/UI bursts allocate one refresh of each kind and do no route work.
local env = New({population = 10000})
local finder = env.finder
local reads, timers = env.populationReads, #env.timers
local routeReads, getRoute = 0, APR.GetRouteData
APR.GetRouteData = function(...)
    routeReads = routeReads + 1
    return getRoute(...)
end
for _ = 1, 1000 do
    env:Event("CHANNEL_COUNT_UPDATE")
    env:Event("CHANNEL_UI_UPDATE")
end
assert(env.populationReads == reads and #env.timers == timers + 3 and env:ActiveTimers() == 3)
env:Advance(0.5)
assert(env.populationReads == reads + 1 and routeReads == 0 and env:ActiveTimers() == 0)
assert(#env.timers <= timers + 4, "One delayed notification may follow the three coalesced refreshes")

-- Foreign contexts on the common channel stop before route state and allocation.
env = New({population = 10000, settings = {matchMode = "zone"}})
finder = env.finder
local foreign = env:Query({mode = "zone", context = finder:GetContext(599)})
local wire = assert(env.protocol.Encode("Q", foreign))
local decode, decoded = env.protocol.Decode, 0
env.protocol.Decode = function(value) decoded = decoded + 1; return decode(value) end
local getState = finder.GetLocalState
finder.GetLocalState = function() error("A foreign zone cannot resolve local route state") end
timers = #env.timers
for index = 1, 5000 do env:ReceiveWire(wire, "Foreign" .. index .. "-Home") end
assert(decoded == 16 and not next(finder.responses) and not next(finder.requestTimes) and #env.timers == timers)
for index = 1, 1000 do
    env:ReceiveWire(wire, "WrongChannel" .. index .. "-Home", "CHANNEL", {localID = 99, name = "Other"})
    env:ReceiveWire(string.rep("x", 241), "Oversized-Home")
    env:ReceiveWire("1|Q|bad\001payload", "ControlByte-Home")
end
assert(decoded == 16, "Wrong channels and invalid envelopes cannot consume decoding work")
finder.GetLocalState, env.protocol.Decode = getState, decode
assert(finder:Search(), "Foreign traffic cannot starve a deliberate first search")
assert(#env:Messages("Q") == 1 and env:Messages("Q")[1].target == 7)

-- Unsolicited private traffic shares a finite decoder budget and no route work.
env = New()
finder = env.finder
wire = assert(env.protocol.Encode("P", env:Presence({id = "unsolicited"})))
decode, decoded = env.protocol.Decode, 0
env.protocol.Decode = function(value) decoded = decoded + 1; return decode(value) end
finder.GetLocalState = function() error("An unsolicited presence cannot resolve local route state") end
timers = #env.timers
for index = 1, 3000 do env:ReceiveWire(wire, "Unsolicited" .. index .. "-Home", "WHISPER") end
assert(decoded == 64 and not next(finder.candidates) and #env.timers == timers,
    "Private packet floods stop before decode after the fixed 64-message budget")

-- A small compatible zone remains eligible among many unrelated realm members.
env = New({population = 100000, settings = {matchMode = "zone"}})
finder = env.finder
local localQuery = env:Query({id = "small-zone", mode = "zone"})
local stateReads = 0
getState = finder.GetLocalState
finder.GetLocalState = function(self, ...)
    stateReads = stateReads + 1
    return getState(self, ...)
end
env:Receive("Q", localQuery, "SmallZone-Home")
assert(finder.responses["SmallZone-Home"] and stateReads == 1,
    "Local compatibility precedes heavy state and is never sampled against realm population")
assert(finder.responses["SmallZone-Home"].due <= env.now + 9)
env:Advance(10)
assert(#env:Messages("P", "WHISPER") == 1 and env:Messages("P")[1].target == "SmallZone-Home")

-- Sustained public floods bound decode, route work, timers and pending responses.
env = New({population = 100000})
finder = env.finder
local burst = env:Query({id = "sustained-local", mode = "zone"})
wire = assert(env.protocol.Encode("Q", burst))
finder.GetDiscoveryResponseDelay = function() return 9 end
decode, decoded, stateReads = env.protocol.Decode, 0, 0
env.protocol.Decode = function(value) decoded = decoded + 1; return decode(value) end
getState = finder.GetLocalState
finder.GetLocalState = function(self, ...)
    stateReads = stateReads + 1
    return getState(self, ...)
end
timers = #env.timers
for second = 1, 3 do
    for index = 1, 2000 do
        env:ReceiveWire(wire, "Burst" .. ((second - 1) * 2000 + index) .. "-Home")
    end
    assert(decoded == second * 16 and Count(finder.responses) == math.min(second * 16, 32))
    assert(Count(finder.requestTimes) == math.min(second * 16, 32) and stateReads == math.min(second * 16, 32))
    assert(env:ActiveTimers() == 2 and #env.timers == timers + 2,
        "A public flood shares a single reply deadline and sender-expiry timer")
    if second < 3 then env:Advance(1) end
end
env:Receive("D", {id = "another-query"}, "Burst1-Home")
assert(finder.responses["Burst1-Home"], "Cancellation must match the queued nonce")
env:Receive("D", {id = burst.id}, "Burst1-Home")
env:Receive("D", {id = burst.id}, "Burst2001-Home")
assert(not finder.responses["Burst1-Home"] and not finder.responses["Burst2001-Home"]
    and Count(finder.responses) == 30,
    "Reserved control capacity must accept matching cancellations after the query budget is exhausted")
env:Receive("D", {id = burst.id}, "Burst2-Home")
env:Receive("D", {id = burst.id}, "Burst3-Home")
assert(not finder.responses["Burst2-Home"] and finder.responses["Burst3-Home"]
    and Count(finder.responses) == 29 and decoded == 52,
    "The fifth control is rejected before decoding, keeping the reserved budget finite")
env.protocol.Decode = decode
env:Advance(20)
assert(#env:Messages("P") == 1 and not next(finder.responses) and not finder.replyTimer,
    "Delayed replies expire instead of extending a burst past its query lifetime")
env:Advance(121)
assert(not next(finder.requestTimes) and not next(finder.repliedTo) and env:ActiveTimers() == 0)

-- AceComm's real multipart parser must never spool hostile data for this prefix.
env = New()
finder = env.finder
local ace = env.directAceComm
local onEvent = ace.frame:GetScript("OnEvent")
for index = 1, 5000 do
    onEvent(ace.frame, "CHAT_MSG_ADDON", "APRFindV1", "\001" .. string.rep("x", 239), "WHISPER", "Multipart" .. index .. "-Home")
    onEvent(ace.frame, "CHAT_MSG_ADDON", "APRFindV1", "\002continuation", "WHISPER", "Multipart" .. index .. "-Home")
end
assert(not next(ace.multipart_spool), "Rejected multipart traffic must allocate no AceComm receive spool")
onEvent(ace.frame, "CHAT_MSG_ADDON", "OtherLoad", "\001first", "WHISPER", "Other-Home")
assert(Count(ace.multipart_spool) == 1, "The prefix guard must preserve another addon's multipart receiver")
onEvent(ace.frame, "CHAT_MSG_ADDON", "OtherLoad", "\003last", "WHISPER", "Other-Home")
assert(not next(ace.multipart_spool))
assert(finder:Search())
local received, handle = 0, finder.HandlePresence
finder.HandlePresence = function(self, ...)
    received = received + 1
    return handle(self, ...)
end
env:Receive("P", env:Presence(), "Valid-Home", "WHISPER")
assert(received == 1 and finder:GetCount() == 1,
    "A valid private packet must reach the controller once despite the real AceComm event listener")

-- A blocked real CTL queue has one global bound, even across disable/re-enable.
env = New()
finder = env.finder
BlockOutput(env)
local presence = env:Presence({id = "queued-load"})
local frames = #env.frames
for index = 1, 1000 do
    local queued = finder:Send("P", presence, "WHISPER", "Queued" .. index .. "-Home")
    assert(queued == (index <= 32), "Only the first 32 private records may enter the library queue")
end
assert(Queued(env) == 32 and #env:Messages("P") == 0 and #env.frames == frames)
finder:SetOption("enabled", false)
finder:SetOption("enabled", true)
assert(not finder:Send("P", env:Presence(), "WHISPER", "AfterRestart-Home") and Queued(env) == 32,
    "Restarting cannot forget queued records and grow an uncancellable backlog")
env.directCTL.avail = 4000
for _, priority in pairs(env.directCTL.Prio) do priority.avail = 4000 end
env:PumpDirect(1)
assert(Queued(env) == 0 and #env:Messages("P") == 0,
    "Cancelled queued snapshots must retire without calling the native send")
assert(finder:Send("P", env:Presence(), "WHISPER", "Fresh-Home"))
env:PumpDirect(1)
assert(#env:Messages("P") == 1 and env:Messages("P")[1].target == "Fresh-Home",
    "Retiring cancelled records restores the private capacity")

-- Native throttling can queue a real controller reply; revocation still wins.
for _, revoke in ipairs({"cancel", "invisible", "disabled", "policy", "context", "instance", "restricted", "expired"}) do
    env = New()
    finder = env.finder
    finder.GetDiscoveryResponseDelay = function() return 0.25 end
    local query = env:Query({id = "queued-" .. revoke, mode = "zone"})
    env.sendResult = function(_, packet) return packet.kind == "P" and 3 or 0 end
    env:Receive("Q", query, "Requester-Home")
    env:Advance(0.3)
    assert(Queued(env) == 1 and #env:Messages("P") == 0, "The native throttle must really leave a presence queued")
    if revoke == "cancel" then env:Receive("D", {id = query.id}, "Requester-Home")
    elseif revoke == "invisible" then finder:SetOption("visible", false)
    elseif revoke == "disabled" then finder:SetOption("enabled", false)
    elseif revoke == "policy" then finder:SetLanguageOption("blockedLanguages", "fr", true)
    elseif revoke == "context" then env.map = 599; env:Event("ZONE_CHANGED_NEW_AREA")
    elseif revoke == "instance" then env.instance = true; env:Event("PLAYER_ENTERING_WORLD")
    elseif revoke == "restricted" then env.restricted = true; env:Event("PLAYER_REGEN_ENABLED")
    else env:Advance(11) end
    env:Advance(0.2)
    env.sendResult = 0
    env:Advance(2)
    assert(Queued(env) == 0 and #env:Messages("P") == 0,
        "Queued presence must remain private after " .. revoke)
    assert(not env.libraryErrors or #env.libraryErrors == 0)
end

print("Companion load: stable channel, coalesced events, bounded decode/state/queues, local reach, multipart guard and cancelled private output passed")
