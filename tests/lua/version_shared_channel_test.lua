local now, timers, sent, joined, left, frames, popups, channelID, options
local function activeTimers()
    local count = 0
    for _, timer in ipairs(timers) do
        if not timer.cancelled and not timer.fired then count = count + 1 end
    end
    return count
end
local function advance(seconds)
    local target = now + seconds
    while true do
        local nextTimer
        for _, timer in ipairs(timers) do
            if not timer.cancelled and not timer.fired and timer.at <= target
                and (not nextTimer or timer.at < nextTimer.at) then nextTimer = timer end
        end
        if not nextTimer then break end
        now, nextTimer.fired = nextTimer.at, true
        nextTimer.callback()
    end
    now = target
end
local function loadShared(config)
    options = config or {}
    now, timers, sent, joined, left, frames, popups = 100, {}, {}, {}, {}, {}, {}
    channelID = options.prejoined and 7 or 0
    APRData = {}
    APR = {
        version = options.version or "7.3.0", Username = "Local-Home",
        settings = { profile = { enableAddon = options.enabled ~= false, checkForUpdate = options.notify ~= false } },
        GAME_VERSIONS = { Classic = "classic", Retail = "retail", Forever = "forever" },
        NewModule = function() return {} end,
        GetGameVersion = function() return options.client or "retail" end,
        WrapTextWithAppearanceColor = function(_, value) return value end,
        questionDialog = { CreateMessagePopup = function(_, text) popups[#popups + 1] = text end },
    }
    function LibStub()
        return { GetLocale = function() return { OUTDATED_VERSION_ALERT = "%s %s" } end }
    end
    function CreateFrame()
        local frame = {
            events = {}, scripts = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            UnregisterEvent = function(self, event) self.events[event] = nil end,
            UnregisterAllEvents = function(self) self.events = {} end,
            SetScript = function(self, name, callback) self.scripts[name] = callback end,
        }
        frames[#frames + 1] = frame
        return frame
    end
    function GetTime() return now end
    function GetNormalizedRealmName() return "Home" end
    function IsInGroup() return false end
    function GetChannelName(name)
        assert(name == "APRVersion", "Only the APR channel may be queried")
        return channelID, channelID > 0 and "APRVersion" or nil
    end
    function JoinTemporaryChannel(name)
        joined[#joined + 1] = name
        if options.joinError then error("Channel unavailable") end
        if not options.delayedJoin then channelID = 7 end
    end
    function LeaveChannelByName(name)
        left[#left + 1] = name
        channelID = 0
    end
    Enum = { SendAddonMessageResult = { Success = 0, InvalidChatType = 4, InvalidChannel = 7, AddonMessageThrottle = 3 } }
    C_ChatInfo = { SendAddonMessage = function(prefix, message, chatType, target)
        if options.sendError then error("Unsupported CHANNEL transport") end
        assert(prefix == "APRVersionCheck" and chatType == "CHANNEL" and target == channelID)
        assert(#message <= 66 and message:match("^[QV]:"))
        sent[#sent + 1] = { prefix = prefix, message = message, channel = chatType, target = target }
        if options.legacyResult then return nil end
        return options.sendResult or 0
    end }
    C_Timer = {
        NewTimer = function(delay, callback)
            local timer = { at = now + delay, delay = delay, callback = callback,
                Cancel = function(self) self.cancelled = true end }
            timers[#timers + 1] = timer
            return timer
        end,
        NewTicker = function() error("Shared versions must never start periodic work") end,
    }
    dofile("APR-Core/features/group/PartyProtocol.lua")
    dofile("APR-Core/core/VersionCheck.lua")
    APR.versionCheck:OnInit()
    return APR.versionCheck
end
local function event(check, name, ...)
    local frame = check.channelFrame
    assert(frame.events[name], "Expected event subscription: " .. name)
    frame.scripts.OnEvent(frame, name, ...)
end
local function receive(check, message, sender, id, name)
    check:HandleSharedMessage("APRVersionCheck", message, "CHANNEL", sender or "Peer-Home", "7. APRVersion", 0,
        id or channelID, name or "APRVersion")
end

-- Actual frame wiring: both login and /reload work in solo play without a guild.
for _, flags in ipairs({ { true, false }, { false, true } }) do
    local check = loadShared()
    event(check, "PLAYER_ENTERING_WORLD", unpack(flags))
    assert(#joined == 0 and #sent == 0 and activeTimers() == 1)
    advance(2)
    assert(joined[1] == "APRVersion" and sent[1].message == "Q:7.3.0")
    assert(sent[1].target == 7 and activeTimers() == 1)
    event(check, "CHANNEL_UI_UPDATE")
    event(check, "PLAYER_ENTERING_WORLD", true, true)
    assert(#sent == 1, "Repeated UI/world events must not duplicate the startup query")
    advance(12)
    assert(#sent == 2 and activeTimers() == 0, "One finite retry, then no idle timers")
    advance(600)
    event(check, "PLAYER_ENTERING_WORLD", false, false)
    assert(#sent == 2 and #joined == 1 and activeTimers() == 0, "Ordinary zone loads do not restart discovery")
end

local check = loadShared({ delayedJoin = true })
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(2)
assert(#sent == 0 and activeTimers() == 1, "Wait for asynchronous channel membership")
channelID = 7
event(check, "CHANNEL_UI_UPDATE")
assert(sent[1].message == "Q:7.3.0")
receive(check, "V:7.4.0")
assert(#popups == 1 and APRData.versionCheck.retail == "7.4.0" and activeTimers() == 0,
    "A newer peer warns the solo player and cancels the unnecessary retry")
receive(check, "V:7.5.0")
assert(#popups == 1 and APRData.versionCheck.retail == "7.5.0")

check = loadShared({ delayedJoin = true })
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(2)
channelID = 7
advance(10)
assert(sent[1].message == "Q:7.3.0", "One final membership probe recovers a missed channel UI event")
advance(12)
assert(#sent == 2 and activeTimers() == 0)

-- Bursts allocate a single pending response; peers at the same/latest version
-- suppress duplicate broadcasts, and response packets never create new replies.
check = loadShared()
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(14)
local sentBefore, timerBefore = #sent, #timers
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(#timers == timerBefore + 1 and activeTimers() == 1 and #sent == sentBefore)
advance(2)
assert(#sent == sentBefore + 1 and sent[#sent].message == "V:7.3.0" and activeTimers() == 0)
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(activeTimers() == 0, "A response cooldown bounds request storms")
advance(10)
receive(check, "Q:7.2.0")
assert(activeTimers() == 1)
receive(check, "V:7.3.0", "Another-Home")
assert(activeTimers() == 0, "An equally recent peer suppresses our queued response")
advance(2)
assert(#sent == sentBefore + 1)
advance(10)
receive(check, "Q:7.2.0")
receive(check, "V:7.2.1", "Another-Home")
assert(activeTimers() == 1, "An intermediate release must not hide the newest available version")
advance(2)
assert(sent[#sent].message == "V:7.3.0")
advance(10)
receive(check, "V:7.2.0")
assert(activeTimers() == 0, "Responses cannot trigger response loops")

-- Reject other channels, other prefixes, self echoes and unstructured payloads.
local baseline = APRData.versionCheck.retail
for _, row in ipairs({
    { "V:9.0.0", "Peer-Home", 6, "APRVersion" },
    { "V:9.0.0", "Peer-Home", 7, "OtherChannel" },
    { "V:9.0.0", "Local-Home", 7, "APRVersion" },
    { "V:9.0.0", "Local", 7, "APRVersion" },
    { "V:9.0.0", "Bad|Hname", 7, "APRVersion" },
    { "V:9.0.0junk", "Peer-Home", 7, "APRVersion" },
    { "Q:@project-version@", "Peer-Home", 7, "APRVersion" },
    { "X:9.0.0", "Peer-Home", 7, "APRVersion" },
    { string.rep("9", 67), "Peer-Home", 7, "APRVersion" },
}) do receive(check, unpack(row)) end
check:HandleSharedMessage("OTHER_ADDON", "V:9.0.0", "CHANNEL", "Peer-Home", nil, 0, 7, "APRVersion")
check:HandleSharedMessage("APRVersionCheck", "V:9.0.0", "GUILD", "Peer-Home", nil, 0, 7, "APRVersion")
assert(APRData.versionCheck.retail == baseline and #popups == 0 and activeTimers() == 0)
channelID = 9
event(check, "CHANNEL_UI_UPDATE")
receive(check, "V:7.4.0", "Peer-Home", 7)
assert(#popups == 0, "A stale channel slot must not be trusted after renumbering")
receive(check, "V:7.4.0", "Peer-OtherRealm", 9, "aprversion")
assert(#popups == 1)

-- Incoming shared packets bypass APR's general quest/UI event path entirely.
dofile("APR-Core/core/Event.lua")
APR.GetSettingsProfile = function() error("Shared packets must not enter the quest/UI dispatcher") end
local packetCount = #sent
for _ = 1, 1000 do
    APR.event.EventHandler({ tag = "party" }, "CHAT_MSG_ADDON", "OTHER_ADDON", "noise", "CHANNEL", "Peer")
end
APR.event.EventHandler({ tag = "party" }, "CHAT_MSG_ADDON", "APRVersionCheck", "V:7.6.0", "CHANNEL",
    "Peer-Home", "9. APRVersion", 0, 9, "APRVersion")
assert(#sent == packetCount and APRData.versionCheck.retail == "7.6.0")

-- Unsupported/failed transports never use visible chat and never poll forever.
for _, config in ipairs({ { client = "classic" }, { enabled = false }, { notify = false }, { version = "@project-version@" } }) do
    check = loadShared(config)
    event(check, "PLAYER_ENTERING_WORLD", true, false)
    advance(60)
    assert(#joined == 0 and #sent == 0 and activeTimers() == 0)
end
for _, config in ipairs({ { sendResult = 4 }, { sendResult = 7 }, { sendError = true },
    { joinError = true }, { delayedJoin = true } }) do
    check = loadShared(config)
    event(check, "PLAYER_ENTERING_WORLD", true, false)
    advance(60)
    assert(not check.sharedChannelID and activeTimers() == 0 and #joined == 1 and #left == 1)
end
check = loadShared({ client = "forever", legacyResult = true })
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(14)
assert(#sent == 2 and activeTimers() == 0, "Support Forever when its client accepts CHANNEL messages")
check:OnDisable()
assert(#left == 1 and not next(check.channelFrame.events))
check = loadShared({ prejoined = true })
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(2)
receive(check, "Q:7.2.0")
check:OnDisable()
assert(#left == 0 and activeTimers() == 0, "Never leave a channel the user already joined")
check = loadShared({ sendResult = 3 })
event(check, "PLAYER_ENTERING_WORLD", true, false)
advance(14)
receive(check, "Q:7.2.0")
advance(2)
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(#sent == 3 and activeTimers() == 0, "Failed responses are also rate-limited")
check = loadShared()
event(check, "PLAYER_ENTERING_WORLD", false, true)
check:OnDisable()
advance(30)
assert(#joined == 0 and activeTimers() == 0, "Disabling before startup cancels joining")
print("Shared APR versions: solo login/reload, asynchronous join, bounded bursts, suppression, metadata, idle and unsupported clients passed")
