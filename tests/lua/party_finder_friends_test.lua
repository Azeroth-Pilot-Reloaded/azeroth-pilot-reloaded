-- Online social peers use the real discovery codec, filters and invitation lifecycle.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function Game(name, id, overrides)
    local game = {
        gameAccountID = id,
        clientProgram = "WoW",
        isOnline = true,
        isAppearOffline = false,
        isInCurrentRegion = true,
        regionID = 3,
        wowProjectID = 1,
        characterName = name,
        realmName = "Far Realm",
        factionName = "Alliance",
    }
    for key, value in pairs(overrides or {}) do
        game[key] = value
    end
    return game
end

local function Friend(...)
    return {
        isFriend = true,
        appearOffline = false,
        accountName = "Private Account Name",
        battleTag = "PrivateTag#1234",
        accounts = { ... },
    }
end

local function OneFriend(options)
    options = options or {}
    options.bnetFriends = options.bnetFriends or { Friend(Game("Violet", 41)) }
    return Fixture.New(options)
end

local function Targets(messages)
    local targets = {}
    for _, message in ipairs(messages) do
        targets[message.target] = (targets[message.target] or 0) + 1
    end
    return targets
end

-- A normal search queries the public rendezvous and each distinct online friend.
for _, client in ipairs({ "retail", "forever" }) do
    local env = Fixture.New({
        client = client,
        friends = {
            { name = "Wisp-Home", connected = true },
            { name = "Offline-Home", connected = false },
            { name = "Violet-FarRealm", connected = true },
        },
        bnetFriends = { Friend(Game("Violet", 41)) },
    })
    local finder = env.finder
    assert(finder:Search())
    env:Advance(2)
    local wow, bnet = Targets(env:Messages("Q", "WHISPER")), Targets(env:Messages("Q", "BNET"))
    assert(#env:Messages("Q", "CHANNEL") == 1, "Social discovery preserves the public query")
    assert(wow["Wisp-Home"] == 1 and not wow["Offline-Home"])
    assert(
        not wow["Violet-FarRealm"] and bnet[41] == 1,
        "The same character in both friend lists has one query, using Battle.net"
    )
    assert(finder:GetCount() == 0, "An online social entry is not itself evidence that its character runs APR")
    local count = #env:Messages("Q")
    for _ = 1, 20 do
        finder:Search()
    end
    env:Advance(1)
    assert(#env:Messages("Q") == count, "Friends share the ordinary search cooldown")
end

-- Friend accounts can have several online WoW licenses; unsupported or private sessions stay out.
do
    local hidden = Friend(Game("Hidden", 50))
    hidden.appearOffline = true
    local stranger = Friend(Game("Stranger", 51))
    stranger.isFriend = false
    local missingProject, missingRegion = Game("UnknownProject", 52), Game("UnknownRegion", 53)
    missingProject.wowProjectID, missingRegion.isInCurrentRegion = nil, nil
    local env = Fixture.New({
        bnetFriends = {
            Friend(
                Game("Violet", 41),
                Game("Copper", 42),
                Game("Offline", 43, { isOnline = false }),
                Game("OtherGame", 44, { clientProgram = "D3" }),
                Game("OtherProject", 45, { wowProjectID = 2 }),
                Game("OtherRegion", 46, { isInCurrentRegion = false }),
                Game("PrivateSession", 47, { isAppearOffline = true }),
                Game("", 48),
                Game("Unsafe|Name", 49)
            ),
            hidden,
            stranger,
            { missingInfo = true },
            Friend(missingProject, missingRegion),
        },
    })
    assert(env.finder:Search())
    env:Advance(3)
    local targets = Targets(env:Messages("Q", "BNET"))
    assert(
        targets[41] == 1 and targets[42] == 1 and #env:Messages("Q", "BNET") == 2,
        "Every eligible game account is queried, with no arbitrary cross-project or cross-region send"
    )
end

-- A missing channel must not stop direct discovery of online social peers.
do
    local env = OneFriend({ joinError = true, noPopulationAPI = true, settings = { matchMode = "world" } })
    assert(env.finder:Search(), "Friends remain usable when the public APR channel cannot be joined")
    env:Advance(1)
    assert(not env.finder.channelID and #env:Messages("Q", "BNET") == 1)
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(env.finder:GetCount() == 1 and env.finder:GetCandidates()[1].key == "Violet-FarRealm")
end

-- Only trusted online senders can initiate private discovery; replies use the incoming transport.
for _, distribution in ipairs({ "WHISPER", "BNET" }) do
    local env = Fixture.New({
        noPopulationAPI = true,
        settings = { matchMode = "world" },
        friends = { { name = "Wisp-Home", connected = true } },
        bnetFriends = { Friend(Game("Violet", 41)) },
    })
    local query = env:Query({
        mode = "world",
        context = env.finder:GetLocalState().worldContext,
        route = "00000000",
        revision = "00000000",
        progressId = "unknown",
        step = 0,
        total = 0,
    })
    env:Receive("Q", query, "Stranger-Home", "WHISPER")
    env:ReceiveBattleNet("Q", query, 999)
    env:Advance(1)
    assert(#env:Messages("P") == 0, "A stranger cannot turn private messages into discovery queries")
    if distribution == "BNET" then
        env:ReceiveBattleNet("Q", query, 41)
    else
        env:Receive("Q", query, "Wisp-Home", "WHISPER")
    end
    env:Advance(2)
    local sent = env:Messages("P", distribution)
    assert(
        #sent == 1 and sent[1].packet.id == query.id,
        "Directed world replies do not depend on a public channel-population estimate"
    )
    assert(sent[1].target == (distribution == "BNET" and 41 or "Wisp-Home"))
    assert(#env:Messages("Q") == 0, "Direct friend discovery does not relay a request to friends of friends")
end

-- Private searches honor visibility, language policies, progress, levels and current context.
for _, example in ipairs({
    { settings = { visible = false } },
    { settings = { visibleLanguages = { en = true } } },
    { settings = { blockedLanguages = { fr = true } } },
    { query = { minLevel = 30 } },
    { query = { route = "abcdef12" } },
    { query = { range = 1, progressId = "main:9", step = 9 } },
    { query = { context = "ffffffff" } },
}) do
    local env = OneFriend({ settings = example.settings })
    env:ReceiveBattleNet("Q", env:Query(example.query), 41)
    env:Advance(10)
    assert(#env:Messages("P") == 0, "The same discovery eligibility applies to Battle.net friends")
end

-- Returned data is still correlated with the active nonce and real discovery filters.
do
    local env = OneFriend({ settings = { minLevel = 15, maxLevel = 20, languages = { fr = true } } })
    local finder = env.finder
    assert(finder:Search())
    env:Advance(1)
    for _, change in ipairs({
        { id = "old-search" },
        { context = "ffffffff" },
        { level = 21 },
        { primary = "en", languages = 1 },
        { warMode = true, context = finder:GetLocalState().alternateContext },
    }) do
        env:ReceiveBattleNet("P", env:Presence(change), 41)
        assert(finder:GetCount() == 0)
    end
    env:ReceiveBattleNet("P", env:Presence(), 999)
    assert(finder:GetCount() == 0, "A numeric account ID alone does not establish friendship")
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(finder:GetCount() == 1 and finder.query.count == 1)
    local candidate = finder:GetCandidates()[1]
    assert(candidate.key == "Violet-FarRealm" and candidate.name:find("Violet", 1, true))
    for _ = 1, 4 do
        env:ReceiveBattleNet("P", env:Presence(), 41)
    end
    env:Receive("P", env:Presence(), "Violet-FarRealm", "WHISPER")
    assert(
        finder:GetCount() == 1 and finder.query.count == 1,
        "The same character never consumes extra result slots through another transport"
    )
    for _, row in ipairs(finder:GetTrafficRows()) do
        for _, field in ipairs({ "peer", "wire", "result" }) do
            local value = tostring(row[field])
            assert(
                not value:find("Private Account Name", 1, true) and not value:find("PrivateTag", 1, true),
                "The traffic journal does not reveal BattleTag or account names"
            )
        end
    end
    env:Advance(121)
    assert(finder:GetCount() == 0, "Friend candidates expire through the ordinary bounded cache")
end

-- Forever's region-unique names keep their spaces and do not gain a fake realm suffix.
do
    local env = OneFriend({ client = "forever", regional = true, bnetFriends = { Friend(Game("Violet Meadow", 41)) } })
    assert(env.finder:Search())
    env:Advance(1)
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(env.finder:GetCount() == 1 and env.finder:GetCandidates()[1].key == "Violet Meadow")
end

-- Friendship and online state are revalidated before dispatch and before accepting a reply.
do
    local env = OneFriend()
    assert(env.finder:Search())
    env.bnetFriends[1].accounts[1].isOnline = false
    env:Event("BN_FRIEND_INFO_CHANGED", 1)
    env:Advance(2)
    assert(#env:Messages("Q", "BNET") == 0, "An offline account does not receive queued work")
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(env.finder:GetCount() == 0)
    env.bnetFriends[1].accounts[1].isOnline = true
    env:Event("BN_FRIEND_INFO_CHANGED", 1)
    env:Advance(60)
    assert(env.finder:Search())
    env:Advance(1)
    assert(#env:Messages("Q", "BNET") == 1, "An online transition is picked up by the next deliberate search")
    env.bnetFriends[1].isFriend = false
    env:Event("BN_FRIEND_INFO_CHANGED", 1)
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(env.finder:GetCount() == 0, "Removing the friendship immediately revokes inbound trust")
end

-- Cancellation owns both scheduled probes and snapshots, with no hidden idle work.
for _, cancel in ipairs({ "finish", "disable", "context" }) do
    local env = OneFriend()
    local finder = env.finder
    assert(finder:Search())
    if cancel == "finish" then
        finder:FinishQuery()
    elseif cancel == "disable" then
        finder:SetOption("enabled", false)
    else
        env.map = 777
        finder.localDirty = true
        finder:RefreshTransport()
    end
    env:Advance(11)
    assert(#env:Messages("Q", "BNET") == 0, "Cancelled queries must never leave the social queue")
    if cancel == "disable" then
        assert(not finder.eventFrame.events.BN_CHAT_MSG_ADDON and not finder.eventFrame.events.FRIENDLIST_UPDATE)
        assert(env:ActiveTimers() == 0, "Disabled social discovery leaves no timers or listeners")
    end
end

for _, cancel in ipairs({ "hidden", "disabled", "context", "policy" }) do
    local env = OneFriend()
    local finder = env.finder
    env:ReceiveBattleNet("Q", env:Query(), 41)
    if cancel == "hidden" then
        finder:SetOption("visible", false)
    elseif cancel == "disabled" then
        finder:SetOption("enabled", false)
    elseif cancel == "context" then
        env.map = 777
        finder.localDirty = true
        finder:RefreshTransport()
    else
        finder:SetLanguageOption("blockedLanguages", "fr", true)
    end
    env:Advance(11)
    assert(#env:Messages("P", "BNET") == 0, "A revoked private presence cannot be sent later")
end

-- Large lists are paced and rotate across searches instead of flooding or starving later friends.
do
    local friends = {}
    for index = 1, 90 do
        friends[index] = Friend(Game("Friend" .. index, 1000 + index))
    end
    local env = Fixture.New({ bnetFriends = friends })
    assert(env.finder:Search())
    env:Advance(10)
    local first, firstTargets = env:Messages("Q", "BNET"), Targets(env:Messages("Q", "BNET"))
    assert(#first > 0 and #first < #friends, "A large roster must fit a bounded search batch")
    for index = 2, #first do
        assert(first[index].at > first[index - 1].at, "Social discovery messages are paced")
    end
    env:Advance(50)
    assert(env.finder:Search())
    env:Advance(10)
    local covered, newTarget = {}, false
    for target in pairs(firstTargets) do
        covered[target] = true
    end
    for _, message in ipairs(env:Messages("Q", "BNET")) do
        if not covered[message.target] then newTarget = true end
    end
    assert(newTarget, "A later search gives a turn to friends outside the earlier batch")
    local sent = #env:Messages("Q", "BNET")
    env.finder:SetOption("enabled", false)
    env:Advance(300)
    assert(
        #env:Messages("Q", "BNET") == sent and env:ActiveTimers() == 0,
        "Disabling the feature stops every scheduled social probe"
    )
end

-- Public and social discovery share the same result limit.
do
    local friends = {}
    for index = 1, 35 do
        friends[index] = Friend(Game("Result" .. index, 2000 + index))
    end
    local env = Fixture.New({ bnetFriends = friends })
    assert(env.finder:Search())
    env:Advance(1)
    local presence = env:Presence()
    for index = 1, 35 do
        env:ReceiveBattleNet("P", presence, 2000 + index)
    end
    assert(
        env.finder:GetCount() == 30 and not env.finder.query,
        "Friend results share the existing thirty-result search bound"
    )
end

-- Private ingress has a budget before parsing; unsupported prefixes never reach the decoder.
do
    local env = OneFriend()
    local decode, calls = env.protocol.Decode, 0
    env.protocol.Decode = function(wire)
        calls = calls + 1
        return decode(wire)
    end
    for _ = 1, 500 do
        env:ReceiveBattleNetWire("1|invalid", 999, { prefix = "OTHER" })
    end
    assert(calls == 0, "Unrelated prefixes must not consume this addon's parsing budget")
    for _ = 1, 500 do
        env:ReceiveBattleNetWire("1|invalid", 41)
    end
    assert(calls > 0 and calls <= 64, "Malformed friend traffic cannot cause unbounded protocol parsing")
    env.protocol.Decode = decode
    env:Advance(1)
    env:ReceiveBattleNet("Q", env:Query({ id = "after-flood" }), 41)
    env:Advance(2)
    assert(#env:Messages("P", "BNET") == 1, "A later valid request recovers after the ingress budget resets")
end

-- Battle.net carries invitation context and results, while the native invite stays an explicit action.
do
    local env = OneFriend({ invites = true })
    local finder, nativeInvites, battleNetInvites = env.finder, 0, 0
    C_PartyInfo =
        { CanInvite = function() return true end, InviteUnit = function() nativeInvites = nativeInvites + 1 end }
    C_BattleNet.InviteFriend = function(id)
        assert(id == 41)
        nativeInvites, battleNetInvites = nativeInvites + 1, battleNetInvites + 1
    end
    assert(finder:Search())
    env:Advance(1)
    env:ReceiveBattleNet("P", env:Presence(), 41)
    env:Receive("P", env:Presence(), "Violet-FarRealm", "WHISPER")
    assert(nativeInvites == 0, "Discovery must never cause a native invitation")
    assert(
        finder:Invite("Violet-FarRealm") and nativeInvites == 1 and battleNetInvites == 1,
        "A duplicate presence on WHISPER must retain the proven Battle.net invitation route"
    )
    env:Advance(1)
    assert(#env:Messages("I", "BNET") == 1 and env:Messages("I", "BNET")[1].target == 41)
    local pending = finder.outgoingInvites["Violet-FarRealm"]
    env:ReceiveBattleNet("R", { id = pending.id, status = "declined" }, 41)
    assert(pending.status == "declined" and pending.finished)
end

-- Requesting an invitation to an existing friend-led group also uses the native Battle.net API.
do
    local env = OneFriend({ invites = true })
    local finder, requests = env.finder, 0
    local previous = BNRequestInviteFriend
    C_PartyInfo = { RequestInviteFromUnit = function() error("Use the proven Battle.net friend route") end }
    BNRequestInviteFriend = function(id)
        assert(id == 41)
        requests = requests + 1
    end
    assert(finder:Search())
    env:Advance(1)
    env:ReceiveBattleNet("P", env:Presence({ groupSize = 3, leader = true, recruiting = true }), 41)
    assert(requests == 0, "A recruiting friend is never contacted by a native group action during discovery")
    assert(finder:RequestInvite("Violet-FarRealm") and requests == 1)
    assert(finder.outgoingInvites["Violet-FarRealm"].request == true)
    BNRequestInviteFriend = previous
end

-- Earlier supported clients use the legacy Battle.net names and accept nil send results.
do
    local env = OneFriend({ invites = true })
    local finder, invitations = env.finder, 0
    local previousSend, previousInvite = BNSendGameData, BNInviteFriend
    C_BattleNet.SendGameData, C_BattleNet.InviteFriend = nil, nil
    BNSendGameData = function(target, prefix, wire)
        assert(target == 41 and prefix == "APRFindV1")
        local packet = env.protocol.Decode(wire)
        assert(packet)
        env.sent[#env.sent + 1] = {
            target = target,
            prefix = prefix,
            wire = wire,
            packet = packet,
            channel = "BNET",
            at = env.now,
            result = 0,
        }
        return nil
    end
    BNInviteFriend = function(target)
        assert(target == 41)
        invitations = invitations + 1
    end
    C_PartyInfo = {
        CanInvite = function() return true end,
        InviteUnit = function() error("The legacy Battle.net invitation API is available") end,
    }
    assert(finder:Search())
    env:Advance(1)
    assert(#env:Messages("Q", "BNET") == 1, "The legacy nil result means the send was accepted")
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(finder:Invite("Violet-FarRealm") and invitations == 1)
    env:Advance(1)
    assert(#env:Messages("I", "BNET") == 1)
    BNSendGameData, BNInviteFriend = previousSend, previousInvite
end

-- A directed cancellation must remove a response already waiting behind paced Battle.net output.
for _, cancelled in ipairs({ false, true }) do
    local env = OneFriend()
    local finder, query = env.finder, env:Query({ id = "paced-private-query" })
    for index = 1, 8 do
        assert(
            finder:Send("R", { id = "earlier-control-" .. index, status = "declined" }, "BNET", "Violet-FarRealm", true)
        )
    end
    env:ReceiveBattleNet("Q", query, 41)
    env:Advance(0.1)
    assert(#env:Messages("R", "BNET") > 0 and #env:Messages("P", "BNET") == 0)
    if cancelled then env:ReceiveBattleNet("D", { id = query.id }, 41) end
    env:Advance(3)
    assert(
        #env:Messages("P", "BNET") == (cancelled and 0 or 1),
        "A private D packet cancels the matching queued presence without breaking ordinary delayed replies"
    )
end

-- Policy changes and compatibility changes withdraw a presence that was actually sent.
for _, change in ipairs({ "hidden", "language", "context", "disabled" }) do
    local env = OneFriend()
    local finder = env.finder
    env:ReceiveBattleNet("Q", env:Query(), 41)
    env:Advance(1)
    assert(#env:Messages("P", "BNET") == 1)
    if change == "hidden" then
        finder:SetOption("visible", false)
    elseif change == "language" then
        finder:SetLanguageOption("blockedLanguages", "fr", true)
    elseif change == "context" then
        env.warMode, finder.localDirty = true, true
        finder:RefreshTransport()
    else
        finder:SetOption("enabled", false)
    end
    env:Advance(2)
    assert(
        #env:Messages("W", "BNET") == 1 and env:Messages("W", "BNET")[1].target == 41,
        "A previously answered friend receives one bounded withdrawal when visibility is revoked"
    )
    if change == "disabled" then assert(env:ActiveTimers() == 0) end
end

-- A removed native friend cannot receive a presence retained in ChatThrottleLib's queue.
do
    local env = Fixture.New({ friends = { { name = "Wisp-Home", connected = true } } })
    env.directCTL.avail = -100000
    env:Receive("Q", env:Query(), "Wisp-Home", "WHISPER")
    env:Advance(0.2)
    assert(env.directCTL.bQueueing and #env:Messages("P", "WHISPER") == 0)
    env.friends[1].connected = false
    env:Event("FRIENDLIST_UPDATE")
    env.directCTL.avail = 4000
    env:Advance(3)
    assert(
        #env:Messages("P", "WHISPER") == 0,
        "Friendship and online status are checked again at eventual native dispatch"
    )
end

-- Battle.net disconnect events invalidate trust even when the client temporarily retains an online roster.
do
    local env = OneFriend({ friends = { { name = "Wisp-Home", connected = true } } })
    local finder = env.finder
    assert(finder:Search())
    env:Event("BN_DISCONNECTED")
    env:Advance(2)
    assert(
        env.bnetFriends[1].accounts[1].isOnline == true,
        "This fixture deliberately preserves stale online social API data"
    )
    assert(#env:Messages("Q", "BNET") == 0)
    assert(
        #env:Messages("Q", "WHISPER") == 1,
        "A Battle.net disconnect does not interrupt connected native WoW friends"
    )
    env:ReceiveBattleNet("P", env:Presence(), 41)
    assert(finder:GetCount() == 0, "Disconnected Battle.net data cannot establish a peer")
    env:Event("BN_CONNECTED")
    env:Advance(60)
    assert(finder:Search())
    env:Advance(1)
    assert(#env:Messages("Q", "BNET") == 1, "A reconnect restores direct discovery on a later search")
end

do
    local previous = BNConnected
    BNConnected = function() return false end
    local env = OneFriend()
    assert(env.finder:Search())
    env:Advance(1)
    assert(
        #env:Messages("Q", "BNET") == 0,
        "Initial connection state also overrides stale online friend data before any event"
    )
    BNConnected = previous
end

-- Secret or incomplete social API data is not converted into guessed peer identities.
do
    local env = OneFriend({ friends = { { name = "Wisp-Home", connected = true } } })
    local secret = setmetatable({}, { __tostring = function() error("A secret must not be formatted") end })
    local previous = issecretvalue
    function issecretvalue(value) return value == secret end
    env.friends[1].name = secret
    env.bnetFriends[1].accounts[1].gameAccountID = secret
    env.finder:InvalidateFriendPeers()
    assert(env.finder:Search())
    env:Advance(2)
    assert(
        #env:Messages("Q", "WHISPER") == 0 and #env:Messages("Q", "BNET") == 0,
        "Opaque names and IDs must never be coerced into a transport destination"
    )
    issecretvalue = previous
end

-- Optional or temporarily absent API results degrade to the existing public search.
do
    local env = Fixture.New({ friends = {}, bnetFriends = { { missingInfo = true }, { missingCount = true } } })
    C_FriendList.GetNumFriends = function() return nil end
    env.finder:InvalidateFriendPeers()
    assert(env.finder:Search())
    env:Advance(1)
    assert(#env:Messages("Q", "CHANNEL") == 1 and #env:Messages("Q", "BNET") == 0)
    C_FriendList, C_BattleNet, BNGetNumFriends = nil, nil, nil
    env.finder:InvalidateFriendPeers()
    env:Advance(60)
    assert(env.finder:Search())
    env:Advance(1)
    assert(#env:Messages("Q", "CHANNEL") == 2)
end

print(
    "Finder friends: online roster selection, private queries/replies, cross-realm Battle.net, filters, deduplication, privacy, pacing, cancellation and explicit invitations passed"
)
