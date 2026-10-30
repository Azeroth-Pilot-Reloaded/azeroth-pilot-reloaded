local Fixture = dofile("tests/lua/party_finder_test_env.lua")

-- Invisible idle discovery has no public membership, route preparation or cleanup work.
for _, client in ipairs({ "retail", "forever" }) do
    local env = Fixture.New({ client = client, settings = { visible = false } })
    local finder = env.finder
    assert(not finder.channelID and #env.joined == 0 and env:ActiveTimers() == 0)
    assert(not finder.fingerprintJob and not finder.fingerprintRoute)
    local timers = #env.timers
    finder.GetLocalState = function() error("Invisible idle discovery must not prepare a route") end
    local query = { id = "idle-query", context = "12345678", route = "23456789", revision = "34567890",
        progressId = "main:3", step = 3, total = 20, mode = "nearby", range = 5,
        minLevel = 0, maxLevel = 0, primary = "fr", languages = 2 }
    for index = 1, 64 do
        env:Receive("Q", query, "Other" .. index .. "-Home")
        finder:QueueResponse(query, "Direct" .. index .. "-Home")
        env:Event("PLAYER_FLAGS_CHANGED", "player")
    end
    env:Advance(2)
    assert(#env.timers == timers and env:ActiveTimers() == 0 and #env:Messages() == 0)
    assert(not next(finder.requestTimes) and not next(finder.responses) and finder:GetCount() == 0)
end

-- A deliberate invisible search joins only for its active query, preserving private results afterwards.
local env = Fixture.New({ invites = true, settings = { visible = false } })
local finder = env.finder
local sent, reason = finder:Search()
assert(not sent and reason == "joining", "The first search waits for incremental route preparation")
env:Advance(3)
assert(finder.query and #env.joined == 1 and #env:Messages("Q") == 1)
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
assert(finder:GetCount() == 1)
env:Advance(11)
assert(not finder.query and not finder.channelID and #env.left == 1 and finder:GetCount() == 1)
assert(finder:GetStatus() == "idle", "Cached private results do not claim an active public connection")
local invitations = 0
C_PartyInfo = { CanInvite = function() return true end,
    InviteUnit = function() invitations = invitations + 1 end }
assert(finder:Invite("Peer-Home") and invitations == 1 and #env:Messages("I", "WHISPER") == 1,
    "Leaving public discovery must not prevent an explicit invitation from a recent private result")
assert(finder.eventFrame.events.CHAT_MSG_ADDON and finder.eventFrame.events.GROUP_ROSTER_UPDATE)

-- Auto scanning works invisibly and releases the channel between scans.
env = Fixture.New({ settings = { visible = false, autoScan = true } })
finder = env.finder
assert(not finder.channelID and #env.joined == 0 and finder.autoTimer)
local scanAt = finder.autoTimer.at
env:Advance(scanAt - env.now + 3)
assert(finder.query and finder.channelID and #env:Messages("Q") == 1)
env:Advance(11)
assert(not finder.channelID and not finder.query and finder.autoTimer and #env.left == 1)
finder:SetOption("autoScan", false)
env:Advance(1)
assert(env:ActiveTimers() == 0)

-- Throttling a deliberate invisible query cannot strand a public membership.
env = Fixture.New({ settings = { visible = false } })
finder = env.finder
env.sendResult = Enum.SendAddonMessageResult.AddonMessageThrottle
finder:Search()
env:Advance(3)
assert(not finder.query and not finder.searchWanted and not finder.channelID and #env.left == 1)
assert(finder:GetStatus() == "throttled" and env:ActiveTimers() == 0)
env:Advance(200)
assert(#env.joined == 1 and #env.left == 1 and env:ActiveTimers() == 0)
env.sendResult = 0
finder:Search()
env:Advance(3)
assert(finder.query and finder.channelID and #env.joined == 2)

-- A route fingerprint with no remaining consumer is cancelled, then restarted on demand.
env = Fixture.New()
finder = env.finder
env.definition = { steps = {} }
for index = 1, 1000 do env.definition.steps[index] = { PickUp = { 700000 + index } } end
finder.localDirty = true
finder:GetLocalState()
local abandoned = finder.fingerprintJob
assert(abandoned and finder.fingerprintTimer)
finder:SetOption("visible", false)
assert(not finder.fingerprintJob and not finder.fingerprintTimer and not finder.fingerprintDefinition)
env:Advance(1)
assert(abandoned.visited == 0 and env:ActiveTimers() == 0, "Cancelled hashing consumes no further slices")
finder:Search()
assert(finder.fingerprintJob and finder.fingerprintJob ~= abandoned)
env:Advance(3)
assert(finder.query and finder.revision and not finder.fingerprintJob,
    "Cancellation must invalidate preparation so a deliberate search can finish it")

-- Hiding cancels pending presence while retaining the search the user actually requested.
env = Fixture.New()
finder = env.finder
assert(finder:Search())
env:Receive("Q", env:Query(), "Requester-Home")
assert(next(finder.responses))
finder:SetOption("visible", false)
assert(finder.query and finder.channelID and not next(finder.responses))
local requests, timerCount = 0, #env.timers
for _ in pairs(finder.requestTimes) do requests = requests + 1 end
for index = 1, 64 do env:Receive("Q", env:Query(), "Ignored" .. index .. "-Home") end
local after = 0
for _ in pairs(finder.requestTimes) do after = after + 1 end
assert(after == requests and #env.timers == timerCount, "Invisible active queries do not account for public requests")
env:Advance(1) -- The next packet gets a fresh receive-rate budget.
env:Receive("P", env:Presence(), "Result-Home", "WHISPER")
env:Advance(11)
assert(finder:GetCount() == 1 and not finder.channelID and #env:Messages("P") == 0)
finder:SetOption("visible", true)
env:Advance(3)
assert(finder.channelID and #env.joined == 2 and finder:GetCount() == 1)

-- Rejected visible bursts need one expiry timer, rather than one allocation per sender.
env = Fixture.New({ settings = { visibleLanguages = { fr = true } } })
finder = env.finder
local query = env:Query({ primary = "en", languages = 1 })
timerCount = #env.timers
for index = 1, 64 do env:Receive("Q", query, "Excluded" .. index .. "-Home") end
assert(#env.timers == timerCount + 1 and finder.expiryTimer and not next(finder.responses))
env:Advance(121)
assert(not next(finder.requestTimes) and env:ActiveTimers() == 0)

-- Earlier deadlines replace a timer; later ones can reuse a harmless earlier wakeup.
env = Fixture.New()
finder = env.finder
finder.notificationTimes.Recent = env.now
finder:ScheduleExpiry()
local late = finder.expiryTimer
finder.requestTimes.Earlier = env.now
finder:ScheduleExpiry()
local early = finder.expiryTimer
assert(late.cancelled and early ~= late and early.at == env.now + 120)
finder.requestTimes.Earlier = nil
finder:ScheduleExpiry()
assert(finder.expiryTimer == early and not early.cancelled)
env:Advance(121)
assert(early.fired and finder.expiryTimer.at == finder.notificationTimes.Recent + 600)
finder.notificationTimes.Recent = nil
finder:ScheduleExpiry()
assert(not finder.expiryTimer and not finder.expiryAt and env:ActiveTimers() == 0)

-- Presence is remote data; invitation status belongs to the local invitation lifecycle.
env = Fixture.New({ invites = true })
finder = env.finder
C_PartyInfo = { CanInvite = function() return true end, InviteUnit = function() end }
assert(finder:Search())
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
env:Advance(10)
assert(finder:Invite("Peer-Home"))
env:Advance(51)
assert(finder:Search())
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
assert(finder.candidates["Peer-Home"].status == "sent" and not finder.outgoingInvites["Peer-Home"].finished)
local pending = finder.outgoingInvites["Peer-Home"]
env:Receive("R", { id = pending.id, status = "declined" }, "Peer-Home", "WHISPER")
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
assert(finder.candidates["Peer-Home"].status == "declined")
env:Receive("P", env:Presence(), "Other-Home", "WHISPER")
assert(finder.candidates["Other-Home"].status == nil, "One peer's status must not leak to another row")

-- Presentation and audio controls must not restart discovery or discard an answer in flight.
for _, client in ipairs({ "retail", "forever" }) do
    env = Fixture.New({ client = client, settings = { autoScan = true } })
    finder = env.finder
    assert(finder:Search())
    env:Advance(0.25)
    env:Receive("Q", env:Query(), "Requester-Home")
    local activeQuery, responses, response = finder.query, finder.responses, finder.responses["Requester-Home"]
    local replyTimer, autoTimer = finder.replyTimer, finder.autoTimer
    local snapshot, revision = finder.localState, finder.revision
    local joins, leaves, messages = #env.joined, #env.left, #env.sent
    assert(response and replyTimer and autoTimer and snapshot and revision)

    local transportRefreshes, progressReads = 0, 0
    local refreshTransport, readProgress = finder.RefreshTransport, APR.GetGroupRouteProgress
    function finder:RefreshTransport(...)
        transportRefreshes = transportRefreshes + 1
        return refreshTransport(self, ...)
    end
    function APR:GetGroupRouteProgress(...)
        progressReads = progressReads + 1
        return readProgress(self, ...)
    end

    local timers = #env.timers
    finder:SetOption("enabled", true)
    finder:SetOption("visible", true)
    finder:SetOption("showButton", true)
    assert(#env.timers == timers, "Unchanged scalar settings must do no work")

    finder:SetOption("notifications", true)
    finder:SetOption("notificationCooldown", 90)
    finder:SetOption("soundEnabled", false)
    finder:SetOption("soundChannel", "Dialog")
    finder:SetSoundOption("declined", "enabled", true)
    finder:SetSoundOption("declined", "sound", "media:Example")
    finder:SetSoundOption("declined", "cooldown", 9)
    assert(#env.timers == timers, "Audio preferences do not schedule discovery or display work")

    finder:SetOption("showButton", false)
    finder:SetOption("showBadge", false)
    finder:SetOption("showButton", true)
    assert(#env.timers == timers + 1 and finder.notifyTimer,
        "Presentation changes share one display notification")
    assert(finder.query == activeQuery and finder.responses == responses and responses["Requester-Home"] == response,
        "Changing presentation or audio retains the active search and queued private answer")
    assert(finder.replyTimer == replyTimer and not replyTimer.cancelled
        and finder.autoTimer == autoTimer and not autoTimer.cancelled,
        "Changing presentation or audio cannot postpone discovery timers")
    assert(finder.localState == snapshot and not finder.localDirty and finder.revision == revision
        and not finder.fingerprintJob and transportRefreshes == 0 and progressReads == 0,
        "Unrelated settings must not rebuild route state or refresh the transport")
    assert(#env.joined == joins and #env.left == leaves and #env.sent == messages)
    local settings = finder:GetSettings()
    assert(settings.notifications and settings.notificationCooldown == 90 and not settings.soundEnabled
        and settings.soundChannel == "Dialog" and settings.showButton and not settings.showBadge)
    assert(settings.sounds.declined.enabled and settings.sounds.declined.sound == "media:Example"
        and settings.sounds.declined.cooldown == 9)

    env:Advance(4)
    assert(#env:Messages("P", "WHISPER") == 1 and env:Messages("P", "WHISPER")[1].target == "Requester-Home",
        "The queued answer is still sent after settings are changed")
    assert(finder.query == activeQuery and finder.autoTimer == autoTimer and not autoTimer.cancelled)
end

-- Realm policy is not proof that this transport is locked. The native API
-- result remains authoritative, including on Forever realms reporting true.
for _, client in ipairs({ "retail", "forever" }) do
    env = Fixture.New({ client = client, outgoingRestricted = true })
    finder = env.finder
    assert(not finder:IsRestricted() and finder.channelID and finder:Search())
    assert(#env:Messages("Q", "CHANNEL") == 1 and finder:GetStatus() == "searching",
        "A realm flag alone cannot suppress a successful native channel send")

    env = Fixture.New({ client = client, restricted = true })
    finder = env.finder
    assert(not finder:Search() and finder:GetStatus() == "restricted")
    assert(#env.joined == 0 and #env.sent == 0 and not finder.fingerprintJob,
        "Active chat lockdown prevents route preparation, joining and native sends")
    env.restricted = false
    env:Event("PLAYER_REGEN_ENABLED")
    env:Advance(3)
    assert(finder.query and #env:Messages("Q") == 1,
        "Discovery recovers after actual lockdown ends")

    env = Fixture.New({ client = client })
    finder = env.finder
    env.sendResult = Enum.SendAddonMessageResult.AddOnMessageLockdown
    local ok, status = finder:Search()
    assert(not ok and status == "restricted" and #env:Messages("Q") == 0 and #env.sent == 1,
        "A native lockdown rejection is still reported even when the preflight API returns false")
    env:Advance(200)
    assert(#env.sent == 1 and env:ActiveTimers() == 0,
        "A rejected manual query cannot create an automatic retry loop")
    env.sendResult = 0
    assert(finder:Search() and #env:Messages("Q") == 1)

    env = Fixture.New({ client = client, instance = true, outgoingRestricted = true })
    finder = env.finder
    assert(not finder:IsRestricted() and finder:IsDiscoveryInstance())
    assert(not finder:Search() and finder:GetStatus() == "instance"
        and #env.joined == 0 and #env.sent == 0 and not finder.fingerprintJob,
        "Outdoor discovery policy has its own status, not a claim that the game blocked communications")
    env.instance = false
    env:Event("PLAYER_ENTERING_WORLD")
    env:Advance(3)
    assert(finder.query and #env:Messages("Q") == 1,
        "Leaving an instance resumes normal discovery")

    -- Pending replies recheck the instance policy before the coalesced zone refresh.
    env = Fixture.New({ client = client })
    finder = env.finder
    env:Receive("Q", env:Query(), "Requester-Home")
    assert(next(finder.responses))
    env.instance = true
    env:Advance(4)
    assert(#env:Messages("P") == 0, "Entering an instance immediately prevents pending public discovery replies")

    C_ChatInfo.InChatMessagingLockdown = nil
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted = nil
    IsInInstance = nil
    assert(not finder:IsRestricted() and not finder:IsDiscoveryInstance(),
        "Optional restriction and instance APIs can be absent on a client variant")
    C_ChatInfo.InChatMessagingLockdown = function() return nil end
    assert(not finder:IsRestricted(), "Unavailable restriction data does not manufacture a blocked state")
end

print("Companion lifecycle: invisible idle, temporary search membership, private invitations, expiry coalescing, scoped settings and honest restriction/recovery states passed")

-- Disabling revokes all queued private traffic, including an invitation context.
env = Fixture.New({ invites = true })
finder = env.finder
C_PartyInfo = { CanInvite = function() return true end, InviteUnit = function() return true end }
assert(finder:Search())
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
env.directCTL.avail, env.directCTL.bQueueing = 0, true
for _, priority in pairs(env.directCTL.Prio) do priority.avail = 0 end
assert(finder:Invite("Peer-Home") and #env:Messages("I") == 0)
finder:SetOption("enabled", false)
finder:SetOption("enabled", true)
env:Advance(3)
assert(#env:Messages("I") == 0 and not next(finder.outgoingInvites),
    "An invitation erased by disabling cannot reappear from AceComm after reenabling")
