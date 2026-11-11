-- Two native memberships, controlled map hierarchies and independent roster snapshots.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")
local function Move(env, map)
    env.map = map
    env:Event("ZONE_CHANGED_NEW_AREA")
    env:Advance(0.5)
end
local function Deny(env, transport)
    env:Event(
        "CHAT_MSG_CHANNEL_NOTICE",
        "NOT_ALLOWED_IN_CHANNEL",
        "",
        "",
        "",
        "",
        "",
        0,
        transport:GetChannelID(),
        transport.name
    )
end
for _, client in ipairs({ "forever", "retail" }) do
    for _, faction in ipairs({ "Alliance", "Horde" }) do
        local env = Fixture.New({ client = client, faction = faction })
        local finder, global = env.finder, APR.CommunicationChannel
        local base = client == "forever" and ("APR" .. faction) or "APR"
        assert(global.name == base and finder.zoneChannel.name == base .. "Z501")
        assert(#env.joined == 2 and global:GetChannelID() ~= finder.zoneChannel:GetChannelID())
        assert(finder:GetSearchTransport() == finder.zoneChannel)
        local zone, frame = finder.zoneChannel, finder.zoneChannel.frame
        C_Map.GetMapInfo = function(map)
            if map == 9061 or map == 9062 then return { mapType = 5, parentMapID = 9050 } end
            if map == 9050 or map == 9051 then return { mapType = 3, parentMapID = 9000 } end
            return { mapType = 2, parentMapID = 0 }
        end
        Move(env, 9061)
        assert(finder.zoneChannel == zone and zone.frame == frame and zone.name == base .. "Z9050")
        assert(not env.channels[base .. "Z501"] and env.channels[base] == 7)
        assert(finder:Search())
        local query, joins, leaves = finder.query, #env.joined, #env.left
        Move(env, 9062)
        assert(
            finder.query == query and #env.joined == joins and #env.left == leaves,
            "Moving between subzones preserves the native channel and current search"
        )
        Move(env, 9051)
        assert(zone.name == base .. "Z9051" and not env.channels[base .. "Z9050"])
        assert(
            finder.query and finder.query ~= query and finder.query.channelTransport == zone,
            "A local search restarts on the new large zone, with no old query left queued"
        )
        finder:StopSearch()
        finder:SetOption("matchMode", "world")
        assert(finder:Search() and finder.query.channelTransport == global)
        local worldQuery = finder.query
        Move(env, 9061)
        assert(
            finder.query == worldQuery and finder:GetSearchTransport() == global,
            "Changing the zone channel cannot interrupt a world search"
        )
        assert(zone.frame == frame and env.channels[base] == 7)
        finder:StopSearch()
        for _, mode in ipairs({ "zone", "nearby", "step" }) do
            finder:SetOption("matchMode", mode)
            assert(finder:Search() and finder.query.channelTransport == zone, "Every local scope prioritizes the zone")
            finder:StopSearch()
        end
        env:Event("PLAYER_CAMPING")
        assert(not env.channels[base] and not env.channels[zone.name])
        env:Event("LOGOUT_CANCEL")
        env:Advance(6)
        assert(global:IsReady() and zone:IsReady() and finder.zoneChannel == zone and zone.frame == frame)
    end
end

for _, client in ipairs({ "forever", "retail" }) do
    local base = client == "forever" and "APRAlliance" or "APR"
    local env = Fixture.New({ client = client, population = 5 })
    local finder, global = env.finder, APR.CommunicationChannel
    local zone = finder.zoneChannel
    env.zonePopulation = 3
    local lists = {
        [3] = { "Local-Home", "Remote-Home", "Other-Home", "Near1-Home", "Near2-Home" },
        [4] = { "Local-Home", "Near1-Home", "Near2-Home" },
    }
    C_ChatInfo.GetChannelRosterInfo = function(index, row) return lists[index] and lists[index][row] end
    assert(finder:Search())
    local localID = finder.query.id
    global:RecordSend(global:GetChannelID(), true, 0)
    Deny(env, global)
    assert(not finder.sweep and finder.query.id == localID, "A global refusal cannot interrupt a zone search")
    Deny(env, zone)
    local worldRequest = env:Query({ id = "world-private", mode = "world", context = finder.worldContext })
    env:Receive("Q", worldRequest, "Remote-Home", "WHISPER")
    env:Advance(1.5)
    assert(finder.sweep and finder.sweep.transport == zone and finder.sweep.total == 2)
    for _, request in ipairs(env:Messages("Q", "WHISPER")) do
        assert(
            request.target == "Near1-Home" or request.target == "Near2-Home",
            "Local sweeps never enumerate the world roster"
        )
    end
    local answered = false
    for _, response in ipairs(env:Messages("P", "WHISPER")) do
        if response.target == "Remote-Home" then answered = true end
    end
    assert(answered, "A player searching locally can still answer a verified private world request")
    assert(finder.aprRosters[global].id == global:GetChannelID() and finder.aprRosters[zone].id == zone:GetChannelID())
    finder:StopSearch()
    finder:SetOption("matchMode", "world")
    assert(finder:Search())
    env:Advance(0.1)
    assert(
        finder.sweep and finder.sweep.transport == global and finder.sweep.total == 4,
        "World fallback scans the global channel, independently of the local directory"
    )
    finder:StopSearch()

    -- Failed zone membership is bounded; a local search can still use the global rendezvous.
    env = Fixture.New({ client = client, zoneJoinError = true })
    finder, global = env.finder, APR.CommunicationChannel
    env:Advance(40)
    assert(global:IsReady() and finder.zoneChannel.status == "unavailable" and finder:GetSearchTransport() == global)
    assert(finder:Search() and finder.query.channelTransport == global)

    -- A native zone rejection falls back without releasing the global version/discovery lease.
    env = Fixture.New({ client = client })
    finder, global = env.finder, APR.CommunicationChannel
    local failedID = finder.zoneChannel:GetChannelID()
    env.sendResult = function(channel, packet, target)
        return channel == "CHANNEL" and packet.kind == "Q" and target == failedID and 7 or 0
    end
    assert(finder:Search() and finder.query.channelTransport == global and global:IsReady())
    local requests = {}
    for _, message in ipairs(env.sent) do
        if message.channel == "CHANNEL" and message.packet.kind == "Q" then requests[#requests + 1] = message end
    end
    assert(#requests == 2 and requests[1].target == failedID and requests[2].target == global:GetChannelID())

    -- Invalid/cyclic hierarchy never creates a continent/micro channel; later map readiness recovers.
    env = Fixture.New({ client = client })
    finder = env.finder
    C_Map.GetMapInfo = function(map) return { mapType = 5, parentMapID = map } end
    Move(env, 8080)
    assert(not finder.zoneChannel and APR.CommunicationChannel:IsReady())
    C_Map.GetMapInfo = function() return { mapType = 3, parentMapID = 0 } end
    Move(env, 8081)
    assert(finder.zoneChannel.name == base .. "Z8081" and finder.zoneChannel:IsReady())

    -- Hiding/ending manual discovery releases the zone, while a version owner keeps the global lease.
    env = Fixture.New({ client = client, settings = { visible = false } })
    finder, global = env.finder, APR.CommunicationChannel
    global:Acquire("versionCheck", function() end)
    env:Advance(6)
    finder:Search()
    env:Advance(6)
    assert(finder.zoneChannel and finder.query)
    finder:StopSearch()
    assert(not finder.zoneChannel and global:IsReady() and global.owners.versionCheck and not global.owners.partyFinder)
    assert(not env.channels[base .. "Z501"])

    -- A retained current-zone membership belongs to the generated lease and leaves on a move.
    env = Fixture.New({ client = client, prejoinedZone = true })
    assert(env.finder.zoneChannel:IsReady() and env.channels[base .. "Z501"] == 8)
    Move(env, 8020)
    assert(not env.channels[base .. "Z501"] and env.channels[base .. "Z8020"])

    -- Old generated memberships from another UI session are retired, preserving native/user channels.
    env.channels.APRAllianceZ1234 = 12
    env.channels.APRHordeZ1235 = 13
    env.channels.APRZ1236 = 15
    function GetChannelList()
        return 1,
            "General",
            nil,
            2,
            "Trade",
            nil,
            7,
            base,
            nil,
            env.finder.zoneChannel:GetChannelID(),
            env.finder.zoneChannel.name,
            nil,
            12,
            "APRAllianceZ1234",
            nil,
            13,
            "APRHordeZ1235",
            nil,
            14,
            "Other user channel",
            nil,
            15,
            "APRZ1236",
            nil
    end
    env.finder.zoneRetiredName = nil
    env.finder:RefreshTransport()
    assert(not env.channels.APRAllianceZ1234 and not env.channels.APRHordeZ1235)
    assert(not env.channels.APRZ1236)
    assert(env.channels[base] == 7 and env.channels[base .. "Z8020"])
    for _, name in ipairs(env.left) do
        assert(name ~= "General" and name ~= "Trade" and name ~= "Other user channel")
    end

    -- Visibility changes invalidate cached discovery on both memberships.
    env = Fixture.New({ client = client })
    local before = #env.sent
    env.finder:SetOption("visible", false)
    local withdrawn = {}
    for index = before + 1, #env.sent do
        local message = env.sent[index]
        if message.packet.kind == "W" and message.result == 0 then withdrawn[message.target] = true end
    end
    assert(withdrawn[7] and withdrawn[8] and not env.channels[base .. "Z501"])
end
print(
    "Zone channels: factions, major maps/subzones, query continuity, independent rosters, world reach, bounded fallback and lifecycle passed"
)
