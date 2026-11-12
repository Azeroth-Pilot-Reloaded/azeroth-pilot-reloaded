-- Worldwide discovery uses invented players, maps and populations, never live guide content.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function Count(entries)
    local count = 0
    for _ in pairs(entries) do
        count = count + 1
    end
    return count
end

local function WorldQuery(env, overrides)
    local query = env:Query({
        mode = "world",
        context = env.finder:GetLocalState().worldContext,
        route = "00000000",
        revision = "00000000",
        progressId = "unknown",
        step = 0,
        total = 0,
    })
    for key, value in pairs(overrides or {}) do
        query[key] = value
    end
    return query
end

-- Listening worldwide is independent of the owner's local search criteria.
local env = Fixture.New({ world = true, settings = { matchMode = "nearby" } })
local finder = env.finder
assert(
    finder.channelID == 8
        and finder.worldChannelID == 7
        and #env.joined == 2
        and finder.channelName == "APRZ501"
        and finder.worldChannelName == "APR"
)
assert(
    finder.worldDisplayIndex == 3 and finder.worldPopulation == 2,
    "The population comes from the display row, not the channel number"
)
local remoteZoneContext, _, remoteWorldContext = finder:GetContext(599)
assert(remoteZoneContext ~= finder.context and remoteWorldContext == finder.worldContext)
env:Receive(
    "Q",
    WorldQuery(env, {
        id = "far-route",
        context = remoteWorldContext,
        route = "ffffffff",
        revision = "eeeeeeee",
        progressId = "main:19",
        step = 19,
        total = 20,
    }),
    "Far-Home",
    "CHANNEL",
    { world = true }
)
env:Advance(10)
local replies = env:Messages("P", "WHISPER")
assert(
    #replies == 1
        and replies[1].target == "Far-Home"
        and replies[1].packet.map == 501
        and replies[1].packet.context == finder.worldContext,
    "An eligible world query gets a private reply despite a different route and nearby-only local filter"
)

-- Compatibility changes retain the global membership while maps replace the zone lease.
local worldName, worldContext = finder.worldChannelName, finder.worldContext
local oldZoneContext = finder.context
env.map = 599
finder:QueueStateRefresh()
env:Advance(0.5)
assert(
    finder.context ~= oldZoneContext
        and finder.worldContext == worldContext
        and finder.worldChannelName == worldName
        and env.channels[worldName] == 7
        and #env.joined == 3
        and #env.left == 1,
    "Changing map must not leave/rejoin the shared channel"
)
env.warMode = true
finder:QueueStateRefresh()
env:Advance(0.5)
assert(
    finder.worldContext ~= worldContext
        and finder.worldChannelName == worldName
        and env.channels[worldName] == 7
        and #env.joined == 3
        and #env.left == 1,
    "Changing compatibility must update its context without changing channel membership"
)

-- Neither an absent route nor an unfinished fingerprint blocks a world search.
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
APR.ActiveRoute = nil
finder.localDirty = true
assert(finder:Search())
local queries = env:Messages("Q", "CHANNEL")
assert(
    #queries == 1
        and queries[1].target == 7
        and queries[1].packet.mode == "world"
        and queries[1].packet.route == "00000000"
        and queries[1].packet.progressId == "unknown"
)
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
env.definition = { steps = { { PickUp = { 920101 } }, { Done = { 920101 } } } }
finder.localDirty = true
finder:GetLocalState()
assert(finder.fingerprintJob, "The synthetic replacement must really have an unfinished fingerprint")
assert(
    finder:Search() and #env:Messages("Q", "CHANNEL") == 1 and finder.query.channelID == 7,
    "World discovery does not wait for route compatibility work"
)

-- World results admit other maps/routes but keep context, language, level and nonce checks.
env = Fixture.New({
    world = true,
    settings = {
        matchMode = "world",
        languages = { fr = true },
        blockedLanguages = { en = true },
        minLevel = 17,
        maxLevel = 21,
    },
})
finder = env.finder
assert(finder:Search())
local activeID = finder.query.id
env:Receive("P", env:Presence({ map = 599, route = "ffffffff" }), "Far-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 501 }), "Near-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599, context = "ffffffff" }), "WrongContext-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599, primary = "en", languages = 1 }), "WrongLanguage-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599, level = 16 }), "TooLow-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599, level = 22 }), "TooHigh-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599, id = "previous-query" }), "WrongNonce-Home", "WHISPER")
env:Receive("P", env:Presence({ map = 599 }), "PublicPresence-Home", "CHANNEL", { world = true })
assert(finder:GetCount() == 2 and finder.candidates["Far-Home"] and finder.candidates["Near-Home"])
env:Advance(11)
env:Receive("P", env:Presence({ map = 599, id = activeID }), "Late-Home", "WHISPER")
assert(finder:GetCount() == 2 and not finder.candidates["Late-Home"])
finder:SetOption("matchMode", "zone")
assert(
    finder:GetCount() == 1 and finder:GetCandidates()[1].key == "Near-Home",
    "Switching to a local filter excludes cached world results from other maps"
)

-- Only the authenticated shared channel can withdraw a result.
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
assert(finder:Search())
env:Receive("P", env:Presence(), "Moving-Home", "WHISPER")
env:Receive("W", {}, "Moving-Home", "CHANNEL", { localID = 99, name = "Unrelated" })
assert(finder.candidates["Moving-Home"], "An unrelated channel cannot withdraw a worldwide result")
env:Receive("W", {}, "Moving-Home", "CHANNEL", { world = true })
assert(not finder.candidates["Moving-Home"], "A worldwide visibility withdrawal still removes that result")
local notifications = 0
finder.Notify = function() notifications = notifications + 1 end
env:Receive("W", {}, "Unknown-Home", "CHANNEL", { world = true })
assert(notifications == 0, "Uncached worldwide departures cannot schedule UI rebuilds")

env = Fixture.New({ world = true, settings = { matchMode = "zone" } })
finder = env.finder
assert(finder:Search())
local zoneQuery, zoneContext, zoneChannel = finder.query, finder.context, finder.channelID
env.sendResult = function(channel, packet, target)
    return packet.kind == "W" and target == 7 and 7 or 0
end
finder:SetOption("recruiting", true)
assert(
    finder.query == zoneQuery and finder.context == zoneContext and finder.channelID == zoneChannel,
    "A failed visibility-policy withdrawal cannot destroy the active local query"
)

-- Every search mode shares the public query interval on the common channel.
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
assert(finder:Search())
env:Advance(29)
local success, reason = finder:Search()
assert(not success and reason == "throttled" and #env:Messages("Q") == 1)
env:Advance(1)
assert(finder:Search() and #env:Messages("Q") == 2, "A world manual retry becomes available at 30 seconds")
env = Fixture.New({ world = true, settings = { matchMode = "zone" } })
finder = env.finder
assert(finder:Search())
env:Advance(29)
assert(not finder:Search() and #env:Messages("Q") == 1)
env:Advance(1)
assert(
    finder:Search() and #env:Messages("Q") == 2 and env:Messages("Q")[2].target == finder.channelID,
    "Local searches share the 30-second public interval and stable channel"
)

-- Automatic searches yield to recent worldwide traffic; manual search remains deliberate.
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
env:Receive("Q", WorldQuery(env, { id = "observed-world" }), "Other-Home", "CHANNEL", { world = true })
env:Advance(29)
success, reason = finder:Search(true)
assert(not success and reason == "throttled" and #env:Messages("Q") == 0)
env:Advance(1)
assert(finder:Search(true) and #env:Messages("Q") == 1, "The automatic quiet period ends at 30 seconds")
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
env:Receive("Q", WorldQuery(env, { id = "manual-despite-traffic" }), "Other-Home", "CHANNEL", { world = true })
assert(finder:Search() and #env:Messages("Q") == 1, "Observed traffic does not forbid the first manual search")

-- Population changes coalesce independently of the number of eligible peers.
env = Fixture.New({ world = true })
finder = env.finder
finder:GetLocalState() -- Prime the completed fingerprint's cached snapshot.
local routeReads, getRoute = 0, APR.GetRouteData
APR.GetRouteData = function(...)
    routeReads = routeReads + 1
    return getRoute(...)
end
for _ = 1, 100 do
    env:Event("CHANNEL_UI_UPDATE")
    env:Event("CHANNEL_COUNT_UPDATE")
end
assert(env:ActiveTimers() <= 4, "Channel churn shares two service refreshes, one state and one population refresh")
env:Advance(0.5)
assert(routeReads == 0, "Membership and native count changes cannot rebuild the current route state")

env = Fixture.New({ world = true, population = 1001 })
finder = env.finder
local reads = env.populationReads
env.population = 77
for _ = 1, 100 do
    env:Event("CHANNEL_COUNT_UPDATE")
end
assert(env.populationReads == reads, "Count event bursts must not enumerate synchronously")
env:Advance(0.25)
assert(
    env.populationReads == reads + 1 and finder.worldPopulation == 77,
    "One coalesced native count refresh serves the entire burst"
)
env.population = 1001
finder:RefreshWorldPopulation()
local query = WorldQuery(env, { id = "all-eligible" })
env:Receive("Q", query, "LargePopulation-Home", "CHANNEL", { world = true })
assert(finder.responses["LargePopulation-Home"], "Large populations do not exclude eligible players")
env.population = 25
finder:RefreshWorldPopulation()
env:Receive("Q", query, "SmallPopulation-Home", "CHANNEL", { world = true })
assert(finder.responses["SmallPopulation-Home"], "Small populations use the same eligibility rules")

env = Fixture.New({ world = true })
finder = env.finder
env.population = nil
finder:RefreshWorldPopulation()
local unknownCountQuery = WorldQuery(env, { id = "unknown-count" })
env:Receive("Q", unknownCountQuery, "UnknownCount-Home", "CHANNEL", { world = true })
assert(finder.responses["UnknownCount-Home"])
env:Advance(11)
assert(#env:Messages("P") == 1, "Missing population data cannot exclude an eligible world reply")

-- Every eligible name participates, including large and regional populations.
for _, case in ipairs({
    { size = 10000, id = "request-516", suffix = "" },
    { size = 1000, id = "request-746", suffix = "-R" },
}) do
    env = Fixture.New({ world = true, population = case.size })
    finder = env.finder
    local query = WorldQuery(env, { id = case.id })
    finder.GetLocalState = function() error("Eligibility alone cannot prepare route state") end
    local admitted = 0
    for index = 1, case.size do
        finder.playerKey = "Peer" .. index .. case.suffix
        if finder:CanQueueWorldResponse(query) then admitted = admitted + 1 end
    end
    assert(admitted == case.size, "World discovery does not randomly exclude eligible players")
    assert(not next(finder.responses) and not next(finder.requestTimes), "Eligibility alone allocates no reply state")
end

-- Dense public traffic is limited before decode, with bounded pending replies and scoped cancellation.
env = Fixture.New({ world = true })
finder = env.finder
local burst = WorldQuery(env, { id = "burst-world" })
local wire = assert(env.protocol.Encode("Q", burst))
local decode, decoded = env.protocol.Decode, 0
env.protocol.Decode = function(message)
    decoded = decoded + 1
    return decode(message)
end
local random = math.random
math.random = function(_, maximum) return maximum end -- Keep replies pending while the burst is ingested.
for batch = 1, 3 do
    for index = 1, 80 do
        env:ReceiveWire(wire, "Burst" .. ((batch - 1) * 80 + index) .. "-Home", "CHANNEL", { world = true })
    end
    assert(decoded == batch * 16, "At most sixteen world messages are decoded in each second")
    assert(Count(finder.responses) <= 32, "Pending world responses stay inside the fixed queue budget")
    if batch < 3 then env:Advance(1) end
end
assert(Count(finder.responses) == 32)
math.random, env.protocol.Decode = random, decode
env:Advance(1)
assert(finder.responses["Burst1-Home"])
env:Receive("D", { id = burst.id }, "Burst1-Home", "CHANNEL", { localID = 99, name = "Unrelated" })
assert(finder.responses["Burst1-Home"], "An unrelated-channel cancellation cannot cancel a world query")
env:Receive("D", { id = burst.id }, "Burst1-Home", "CHANNEL", { world = true })
assert(not finder.responses["Burst1-Home"] and Count(finder.responses) == 31)
env:Advance(20)
assert(
    not next(finder.responses) and not finder.replyTimer,
    "Expired work drains instead of extending the public burst indefinitely"
)

-- Private world replies have a global five-second minimum, in addition to per-requester pacing.
env = Fixture.New({ world = true })
finder = env.finder
random = math.random
math.random = function(minimum) return minimum end
env:Receive("Q", WorldQuery(env, { id = "paced-first" }), "First-Home", "CHANNEL", { world = true })
env:Advance(0.125)
env:Receive("Q", WorldQuery(env, { id = "paced-second" }), "Second-Home", "CHANNEL", { world = true })
assert(Count(finder.responses) == 2, "Both queries enter the queue before either private reply is sent")
env:Advance(0.125)
assert(#env:Messages("P") == 1)
env:Receive("Q", WorldQuery(env, { id = "paced-too-soon" }), "Suppressed-Home", "CHANNEL", { world = true })
assert(not finder.responses["Suppressed-Home"])
env:Advance(4)
assert(
    #env:Messages("P") == 1 and finder.responses["Second-Home"],
    "Already queued responses cannot bypass global world pacing"
)
env:Advance(1)
math.random = random
replies = env:Messages("P", "WHISPER")
assert(
    #replies == 2
        and replies[2].at - replies[1].at >= 5
        and replies[1].target == "First-Home"
        and replies[2].target == "Second-Home"
)

env = Fixture.New({ world = true })
finder = env.finder
env.sendResult = function(_, packet) return packet.kind == "P" and 12 or 0 end
random = math.random
math.random = function(minimum) return minimum end
env:Receive("Q", WorldQuery(env, { id = "offline-first" }), "OfflineFirst-Home", "CHANNEL", { world = true })
env:Receive("Q", WorldQuery(env, { id = "offline-second" }), "OfflineSecond-Home", "CHANNEL", { world = true })
env:Advance(1)
local attempts = {}
for _, message in ipairs(env.sent) do
    if message.packet.kind == "P" then attempts[#attempts + 1] = message end
end
assert(#attempts == 1, "An offline target must still consume the world attempt budget")
env:Advance(4.5)
math.random = random
attempts = {}
for _, message in ipairs(env.sent) do
    if message.packet.kind == "P" then attempts[#attempts + 1] = message end
end
assert(#attempts == 2 and attempts[2].at - attempts[1].at >= 5 and not next(finder.repliedTo))

-- World discovery remains open past thirty replies and closes at its deadline.
env = Fixture.New({ world = true, settings = { matchMode = "world" } })
finder = env.finder
assert(finder:Search())
activeID = finder.query.id
for index = 1, 45 do
    env:Receive("P", env:Presence({ map = 599 }), "Result" .. index .. "-Home", "WHISPER")
end
assert(finder:GetCount() == 45 and finder.query)
env:Receive("P", env:Presence({ id = activeID, map = 599 }), "Overflow-Home", "WHISPER")
assert(finder:GetCount() == 46 and finder.candidates["Overflow-Home"])
env:Advance(11)
assert(not finder.query)
local cancellations = env:Messages("D", "CHANNEL")
assert(#cancellations == 1 and cancellations[1].target == 7 and cancellations[1].packet.id == activeID)
env:Receive("P", env:Presence({ id = activeID, map = 599 }), "Expired-Home", "WHISPER")
assert(finder:GetCount() == 46 and not finder.candidates["Expired-Home"])

-- Visibility and master disable release the owned membership; a prejoined channel stays joined.
for _, setting in ipairs({ "visible", "enabled" }) do
    env = Fixture.New({ world = true })
    finder = env.finder
    local zoneName, globalName = finder.channelName, finder.worldChannelName
    finder:SetOption(setting, false)
    env:Advance(1)
    assert(
        #env.left == 2
            and env.channels[zoneName] == nil
            and env.channels[globalName] == nil
            and finder.channelID == nil
            and finder.worldChannelID == nil,
        "Dormant discovery must release both owned channels"
    )
    assert(#env:Messages("W", "CHANNEL") == 2)
    if setting == "enabled" then assert(not next(finder.eventFrame.events) and env:ActiveTimers() == 0) end
end
env = Fixture.New({ world = true, prejoinedWorld = true })
finder = env.finder
worldName = finder.worldChannelName
assert(not APR.CommunicationChannel.owned and env.channels[worldName] == 7)
finder:SetOption("enabled", false)
env:Advance(1)
assert(
    #env.left == 1 and env.channels[worldName] == 7 and finder.worldChannelID == nil,
    "Disabling must preserve a prejoined shared channel"
)

print(
    "World companions: independent visibility, route-free search, world/local filters, pacing, complete eligibility, bounded decoding/queues and channel ownership passed"
)
