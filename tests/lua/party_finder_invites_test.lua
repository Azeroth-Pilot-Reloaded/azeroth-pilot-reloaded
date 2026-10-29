local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function Setup(settings)
    local env = Fixture.New({invites = true, settings = settings})
    dofile("APR-Core/utils/SharedMedia.lua")
    env.invited, env.requested, env.notices = {}, {}, {}
    C_PartyInfo = {
        CanInvite = function() return env.canInvite ~= false end,
        InviteUnit = function(name) env.invited[#env.invited + 1] = name; return env.nativeResult end,
        RequestInviteFromUnit = function(name) env.requested[#env.requested + 1] = name; return env.nativeResult end,
    }
    APR.PartyFinderPanel = {
        ShowInviteContext = function(_, data) env.notices[#env.notices + 1] = data end,
        HideInviteContext = function() env.hidden = (env.hidden or 0) + 1 end,
    }
    local locale = LibStub():GetLocale()
    locale.GF_PROGRESS_same = "Same step"
    return env, env.finder
end

local function Candidate(env, sender, changes)
    assert(env.finder:Search())
    env:Receive("P", env:Presence(changes), sender or "Peer-Home", "WHISPER")
    return env.finder:GetCandidates()[1]
end

-- Discovering and alerting never issue invites; one explicit list action does.
local env, finder = Setup({notifications = true})
local candidate = Candidate(env)
assert(#env.invited == 0 and #env.requested == 0)
assert(#env.soundEvents == 1 and finder:GetCount() == 1)
finder:GetSettings().sounds.sent = { enabled = true, sound = "default", cooldown = 3 }
assert(finder:Invite(candidate.key))
assert(#env.invited == 1 and env.invited[1] == "Peer-Home")
assert(#env.soundEvents == 1 and candidate.status == "sent",
    "Sending stays silent with a legacy enabled sound preference while retaining its text status")
assert(not finder:PreviewSound("sent") and not finder:PlayEventSound("sent"))
local contexts = env:Messages("I", "WHISPER")
assert(#contexts == 1 and contexts[1].target == "Peer-Home")
assert(contexts[1].packet.route == env.protocol.Hash("synthetic") and contexts[1].packet.step == 3)
assert(not finder:Invite(candidate.key) and #env.invited == 1, "Pending invitation clicks are deduplicated")
assert(candidate.status == "sent")
env:Receive("R", {id = "unrelated", status = "declined"}, "Peer-Home", "WHISPER")
env:Receive("R", {id = contexts[1].packet.id, status = "declined"}, "Other-Home", "WHISPER")
assert(candidate.status == "sent", "Only the matching real peer and nonce can report a result")
env:Receive("R", {id = contexts[1].packet.id, status = "accepted"}, "Peer-Home", "WHISPER")
assert(candidate.status == "sent", "A clicked acceptance is not yet a confirmed group")
env.size = 2
function GetUnitName(unit) return unit == "party1" and "Peer-Home" or unit == "player" and "Local-Home" or nil end
finder:CheckInvitationRoster()
assert(candidate.status == "joined", "The real roster confirms the group")

-- Native failures, explicit refusal and expiry remain distinct.
env, finder = Setup()
candidate = Candidate(env)
env.nativeResult = false
assert(not finder:Invite(candidate.key) and candidate.status == "failed")
env:Advance(16)
env.nativeResult = nil
assert(finder:Invite(candidate.key))
local pending = finder.outgoingInvites[candidate.key]
env:Receive("R", {id = pending.id, status = "declined"}, candidate.key, "WHISPER")
assert(candidate.status == "declined")
env:Advance(16)
assert(finder:Invite(candidate.key))
env:Advance(61)
assert(candidate.status == "expired", "No reply is expiry, never an invented refusal")

-- Permission, party size, combat and unavailable peers gate the actual action.
env, finder = Setup()
candidate = Candidate(env)
env.canInvite = false
assert(not finder:Invite(candidate.key) and #env.invited == 0)
env.canInvite, env.combat = true, true
assert(not finder:Invite(candidate.key) and #env.invited == 0)
env.combat, env.size = false, 5
assert(not finder:Invite(candidate.key) and #env.invited == 0)
env.size = 0
finder.candidates[candidate.key] = nil
assert(not finder:Invite(candidate.key))

env, finder = Setup()
candidate = Candidate(env, "Leader-Home", {groupSize = 3, leader = true, recruiting = true})
finder:GetSettings().sounds.sent = { enabled = true, sound = "default", cooldown = 3 }
assert(finder:RequestInvite(candidate.key) and #env.requested == 1 and #env.invited == 0)
assert(#env.soundEvents == 0, "Requesting an invitation also remains silent for legacy profiles")
assert(#env:Messages("I") == 0, "A request to join must not pretend it is an incoming invitation")

-- Neither a forged context nor an addon-only message can display a native invitation.
env, finder = Setup()
local packet = {id = "invite-1", route = env.protocol.Hash("synthetic"), revision = finder.revision,
    progressId = "main:3", step = 3, total = 20}
env:Receive("I", packet, "Stranger-Home", "WHISPER")
finder:OnNativeInvitation("Stranger-Home")
assert(#env.notices == 0 and #env.invited == 0)
finder:CloseIncomingInvitation()
finder.repliedTo["Peer-Home"] = env.now
env:Receive("I", packet, "Peer-Home", "WHISPER")
assert(#env.notices == 0)
finder:OnNativeInvitation("Peer-Home")
assert(#env.notices == 1 and env.notices[1].name == "Peer")
env:Receive("I", packet, "Peer-Home", "WHISPER")
assert(#env.notices == 1, "Duplicate context does not re-display or replay sound")
finder:OnInviteDialogAction("declined")
local results = env:Messages("R", "WHISPER")
assert(#results == 1 and results[1].packet.status == "declined" and results[1].target == "Peer-Home")
finder:OnInviteDialogAction("declined")
assert(#env:Messages("R") == 1)

-- Native-first arrival also works, and a preceding unrelated context cannot reserve the slot.
env, finder = Setup()
finder.repliedTo["Old-Home"], finder.repliedTo["Peer-Home"] = env.now, env.now
env:Receive("I", packet, "Old-Home", "WHISPER")
finder:OnNativeInvitation("Peer-Home")
env:Receive("I", packet, "Peer-Home", "WHISPER")
assert(#env.notices == 1 and env.notices[1].sender == "Peer-Home")
finder:CloseIncomingInvitation()
assert(#env:Messages("R") == 0, "Native cancellation/hide cannot manufacture a refusal")

env, finder = Setup()
finder.repliedTo["Peer-Home"] = env.now
finder:OnNativeInvitation("Peer-Home")
finder:OnInviteDialogAction("declined")
env:Receive("I", packet, "Peer-Home", "WHISPER")
assert(#env.notices == 0, "Late APR context must not revive an already declined native invitation")

-- APR nonces cannot replace the context bound to a single native invitation.
-- Keep the original nonce for the explicit response as well as the one-shot alert.
for _, nativeFirst in ipairs({false, true}) do
    env, finder = Setup()
    finder:GetSettings().sounds.received.enabled = true
    finder.repliedTo["Peer-Home"] = env.now
    local function context(id)
        return {id = id, route = env.protocol.Hash("synthetic"), revision = finder.revision,
            progressId = "main:3", step = 3, total = 20}
    end
    if nativeFirst then finder:OnNativeInvitation("Peer-Home") end
    env:Receive("I", context("first-context"), "Peer-Home", "WHISPER")
    local retained = finder.incomingContext
    local retainedTimer = finder.incomingInviteTimer
    env:Receive("I", context("second-context"), "Peer-Home", "WHISPER")
    assert(finder.incomingContext == retained and finder.incomingInviteTimer == retainedTimer,
        "A changed nonce cannot replace a pending/displayed context or rearm its timer")
    if not nativeFirst then finder:OnNativeInvitation("Peer-Home") end
    assert(#env.notices == 1 and #env.soundEvents == 1)
    for index = 1, 3 do
        env:Advance(6)
        env:Receive("I", context("repeated-" .. index), "Peer-Home", "WHISPER")
    end
    assert(#env.notices == 1 and #env.soundEvents == 1 and finder.incomingContext == retained,
        "Even after the sound cooldown, one native invitation has one APR context and alert")
    finder:OnInviteDialogAction("declined")
    local result = env:Messages("R", "WHISPER")
    assert(#result == 1 and result[1].packet.id == "first-context" and result[1].packet.status == "declined")

    -- A genuine subsequent native invitation, including from the same peer,
    -- starts a fresh lifecycle and permits another context/alert.
    env:Advance(6)
    env:Receive("I", context("new-before-native"), "Peer-Home", "WHISPER")
    finder:OnNativeInvitation("Peer-Home")
    assert(#env.notices == 2 and #env.soundEvents == 2)
    env:Advance(6)
    finder:OnNativeInvitation("Peer-Home")
    assert(not finder.incomingContext and #env.notices == 2,
        "A new native request cannot redisplay the preceding invitation's context")
    env:Receive("I", context("new-after-native"), "Peer-Home", "WHISPER")
    assert(#env.notices == 3 and #env.soundEvents == 3)
    env:Event("PARTY_INVITE_CANCEL")
    assert(not finder.incomingContext and not finder.nativeInviter and not finder.incomingInviteTimer)
    env:Advance(61)
    assert(#env:Messages("R") == 1, "Native cancellation and expiration cannot manufacture another response")
end

-- Native-first invitations expire even without an APR packet; unmatched APR
-- contexts have their shorter deadline and cannot keep a stale native request.
env, finder = Setup()
finder:OnNativeInvitation("Peer-Home")
assert(finder.incomingInviteTimer and finder.nativeInviter == "Peer-Home")
env:Advance(61)
assert(not finder.nativeInviter and not finder.incomingInviteTimer and #env.notices == 0)
finder.repliedTo["Peer-Home"] = env.now
env:Receive("I", {id = "unmatched", route = env.protocol.Hash("synthetic"), revision = finder.revision,
    progressId = "main:3", step = 3, total = 20}, "Peer-Home", "WHISPER")
env:Advance(31)
assert(not finder.incomingContext and not finder.incomingInviteTimer)
finder:OnNativeInvitation("Peer-Home")
assert(#env.notices == 0, "An expired APR context cannot attach to a later native invitation")

-- The receiver's route label describes the inviter only for a known shared route.
for _, routeCase in ipairs({"same", "other", "local_missing", "peer_missing", "both_missing"}) do
    env, finder = Setup()
    local locale = LibStub():GetLocale()
    locale.GROUP_SYNCED, locale.GROUP_OTHER_ROUTE, locale.GROUP_SYNC_UNAVAILABLE = "At the same step", "A different route", "Progress unavailable"
    if routeCase == "local_missing" or routeCase == "both_missing" then
        APR.ActiveRoute = nil
        finder.localDirty = true
    end
    finder:GetLocalState()
    local incoming = {id = "route-context", route = env.protocol.Hash("synthetic"), revision = finder.revision or "00000000",
        progressId = "main:3", step = 3, total = 20}
    if routeCase == "other" then incoming.route = "ffffffff" end
    if routeCase == "peer_missing" or routeCase == "both_missing" then
        incoming.route, incoming.revision, incoming.progressId, incoming.step, incoming.total = "00000000", "00000000", "unknown", 0, 0
    end
    finder.repliedTo["Peer-Home"] = env.now
    env:Receive("I", incoming, "Peer-Home", "WHISPER")
    finder:OnNativeInvitation("Peer-Home")
    local expected = routeCase == "same" and "Invented route · At the same step"
        or routeCase == "other" and "A different route" or "Progress unavailable"
    assert(#env.notices == 1 and env.notices[1].description == expected,
        "Invitation context must identify only a proven shared route: " .. routeCase)
end

-- Every built-in event is one precomposed file, with no runtime sequencing or
-- Blizzard sound-kit fallback. Preview and real playback use the same asset.
env, finder = Setup()
local expectedSounds = {
    {event = "match", file = "companion-match.ogg", channel = "Master"},
    {event = "received", file = "companion-received.ogg", channel = "SFX"},
    {event = "joined", file = "companion-joined.ogg", channel = "Dialog"},
    {event = "declined", file = "companion-declined.ogg", channel = "Master"},
    {event = "expired", file = "companion-expired.ogg", channel = "Master"},
    {event = "error", file = "companion-error.ogg", channel = "Master"},
}
local timersBeforePlayback = #env.timers
PlaySound = function() error("Companion audio must use its bundled palette, never a Blizzard kit") end
for index, expected in ipairs(expectedSounds) do
    finder:GetSettings().sounds[expected.event].enabled = true
    finder:GetSettings().soundChannel = expected.channel
    assert(finder:PreviewSound(expected.event) and not finder.soundTimes[expected.event])
    assert(finder:PlayEventSound(expected.event))
    assert(not finder:PlayEventSound(expected.event), "Repeated events respect their own cooldown")
    for soundIndex = index * 2 - 1, index * 2 do
        assert(env.soundEvents[soundIndex].path == "Interface\\AddOns\\APR\\APR-Core\\assets\\sound\\" .. expected.file)
        assert(env.soundEvents[soundIndex].channel == expected.channel)
    end
end
assert(#env.soundEvents == 12 and #env.timers == timersBeforePlayback and env:ActiveTimers() == 0,
    "Six events each play one asset per request, without composing sounds through timers")

-- Saved custom media keep their own path and configured channel. Missing media
-- or a failed API result stay silent and do not consume the event cooldown.
env, finder = Setup()
local originalSoundLibStub = LibStub
local customPath = "Interface\\AddOns\\SyntheticMedia\\custom.ogg"
local fetched = 0
local soundMedia = {Fetch = function(_, kind, name, noDefault)
    assert(kind == "sound" and name == "Custom bell" and noDefault == true)
    fetched = fetched + 1
    return customPath
end}
LibStub = function(name, silent)
    if name == "LibSharedMedia-3.0" then assert(silent); return soundMedia end
    return originalSoundLibStub(name, silent)
end
local soundEntry = finder:GetSettings().sounds.received
soundEntry.enabled, soundEntry.sound = true, "media:Custom bell"
finder:GetSettings().soundChannel = "Dialog"
assert(finder:PreviewSound("received") and finder.soundTimes.received == nil)
assert(finder:PlayEventSound("received") and fetched == 2)
assert(#env.soundEvents == 2 and env.soundEvents[1].path == customPath and env.soundEvents[2].path == customPath
    and env.soundEvents[2].channel == "Dialog")
env:Advance(6)
soundMedia = nil
assert(not finder:PlayEventSound("received") and #env.soundEvents == 2)
soundEntry.sound = "default"
local playedPath, playedChannel
PlaySoundFile = function(path, channel) playedPath, playedChannel = path, channel; return false end
assert(not finder:PlayEventSound("received"))
local lastPlayedAt = finder.soundTimes.received
PlaySoundFile = function() return nil end
assert(not finder:PlayEventSound("received") and finder.soundTimes.received == lastPlayedAt)
PlaySoundFile = function(path, channel) playedPath, playedChannel = path, channel; return true end
finder:GetSettings().soundChannel = "invalid-channel"
assert(finder:PlayEventSound("received") and playedChannel == "Master"
    and playedPath == "Interface\\AddOns\\APR\\APR-Core\\assets\\sound\\companion-received.ogg",
    "Failed custom/default playback permits immediate recovery with the bundled asset")
PlaySoundFile = nil
assert(not finder:PreviewSound("error") and finder.soundTimes.error == nil)
LibStub = originalSoundLibStub

-- Sound cooldown is per event; previews and missing media do not consume it.
env, finder = Setup({notifications = true, notificationCooldown = 30})
local sounds = finder:GetSettings().sounds
sounds.joined.enabled, sounds.declined.enabled = true, true
assert(finder:PreviewSound("match"))
assert(finder.soundTimes.match == nil)
candidate = Candidate(env)
assert(#env.soundEvents == 2)
env:Advance(16)
assert(finder:Search())
env:Receive("P", env:Presence(), "Second-Home", "WHISPER")
assert(#env.soundEvents == 2, "Global discovery cooldown suppresses a burst of different peers")
env:Advance(16)
assert(finder:Search())
env:Receive("P", env:Presence(), "Third-Home", "WHISPER")
assert(#env.soundEvents == 3)
assert(finder:PlayEventSound("joined"))
assert(not finder:PlayEventSound("joined"))
assert(finder:PlayEventSound("declined"))
sounds.received.enabled, sounds.received.sound = true, "media:missing"
assert(not finder:PlayEventSound("received") and finder.soundTimes.received == nil)
finder:GetSettings().soundEnabled = false
env:Advance(40)
assert(not finder:PlayEventSound("joined"))

for _, flag in ipairs({"combat", "afk", "dnd"}) do
    env, finder = Setup({notifications = true})
    env[flag] = true
    finder.localDirty = true
    Candidate(env)
    assert(#env.soundEvents == 0, "Discovery alert remains silent while " .. flag)
end

env, finder = Setup({notifications = true})
Candidate(env, "Full-Home", {groupSize = 5, leader = true, recruiting = true})
assert(#env.soundEvents == 0, "A full party is not an actionable discovery alert")

env, finder = Setup({notifications = true, recruiting = true})
env.size = 5
finder.localDirty = true
Candidate(env)
assert(#env.soundEvents == 0, "A full local party does not request more companions")

-- Page labels stay cheap even with a large shared-media catalogue. Reading the
-- actual index is explicit and deferred until a picker opens.
env, finder = Setup()
local originalLibStub = LibStub
local names, mediaReads = {}, 0
for index = 1, 10000 do names[index] = string.format("Synthetic sound %05d", index) end
local media = {
    List = function(_, kind)
        assert(kind == "sound")
        mediaReads = mediaReads + 1
        return names
    end,
    HashTable = function() error("The sound picker must not copy the shared-media catalogue") end,
    Fetch = function() error("Displaying sound labels must not resolve or load sound assets") end,
    RegisterCallback = function() error("A shared sound index needs no APR subscription") end,
}
LibStub = function(name, silent)
    if name == "LibSharedMedia-3.0" then assert(silent); return media end
    return originalLibStub(name, silent)
end
DEFAULT = "Synthetic default sound"
local locale = originalLibStub():GetLocale()
local paletteLabels = {
    {event = "match", media = "APR - Companion Match"},
    {event = "received", media = "APR - Companion Received"},
    {event = "joined", media = "APR - Companion Joined"},
    {event = "declined", media = "APR - Companion Declined"},
    {event = "expired", media = "APR - Companion Expired"},
    {event = "error", media = "APR - Companion Error"},
}
for _, entry in ipairs(paletteLabels) do locale["GF_SOUND_EVENT_" .. entry.event] = "Translated " .. entry.event end
local choices = finder:GetSoundChoices()
for _, entry in ipairs(paletteLabels) do
    assert(choices["media:" .. entry.media] == "APR - Translated " .. entry.event,
        "Bundled palette labels reuse the localized event text")
end
for index = 1, 7 do
    assert(finder:GetSoundChoices() == choices, "Every notification selector shares one label lookup")
    assert(choices["media:Synthetic sound 10000"] == "Synthetic sound 10000")
end
assert(choices.default == DEFAULT and mediaReads == 0,
    "Building all event controls must not read or enumerate the sound catalogue")
local choiceCount = 0
for _ in pairs(choices) do choiceCount = choiceCount + 1 end
assert(choiceCount == 7, "Only the default and six fixed palette labels are materialized")
assert(choices["media:Removed optional sound"] == "Removed optional sound",
    "A saved missing-media preference stays legible without validating assets")
assert(choices[false] == nil and choices["media:"] == nil and choices["unrelated:value"] == nil)
local catalog = finder:GetSoundCatalog()
assert(catalog == names and #catalog == 10000 and mediaReads == 1,
    "Opening a picker borrows the shared name index instead of copying it")
table.insert(names, 1, "A newly registered sound")
assert(finder:GetSoundCatalog() == catalog and #catalog == 10001 and catalog[1] == "A newly registered sound",
    "Later registrations and shifted indices are visible on the next picker open")
assert(finder:GetSoundChoices() == choices and choices["media:A newly registered sound"] == catalog[1])
media = nil
local emptyCatalog = finder:GetSoundCatalog()
assert(type(emptyCatalog) == "table" and #emptyCatalog == 0 and finder:GetSoundCatalog() == emptyCatalog)
media = {List = function() return nil end}
assert(finder:GetSoundCatalog() == emptyCatalog, "Missing optional media data uses the same empty source")
media = {List = function() return names end}
assert(finder:GetSoundCatalog() == names, "Media installed after the page opened is discovered lazily")
LibStub = originalLibStub

print("Companion invitations: one-click native actions, correlated private context, refusal/expiry/roster and audio cooldowns passed")
