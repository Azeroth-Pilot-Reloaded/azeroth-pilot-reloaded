-- Version discovery consumes the shared channel contract without owning native events.
local now, timers, sent, popups, options, transport
local function activeTimers()
    local count = 0
    for _, timer in ipairs(timers) do
        if not timer.cancelled and not timer.fired then count = count + 1 end
    end
    return count
end
local function advance(seconds)
    local target, iterations = now + seconds, 0
    while true do
        local nextTimer
        for _, timer in ipairs(timers) do
            if not timer.cancelled and not timer.fired and timer.at <= target
                and (not nextTimer or timer.at < nextTimer.at) then nextTimer = timer end
        end
        if not nextTimer then break end
        iterations = iterations + 1
        assert(iterations <= 100, "The finite version exchange must converge")
        now, nextTimer.fired = nextTimer.at, true
        nextTimer.callback()
    end
    now = target
end
local function loadShared(config)
    options = config or {}
    now, timers, sent, popups = 100, {}, {}, {}
    APRData = options.saved or {}
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
    function GetTime() return now end
    function GetNormalizedRealmName() return "Home" end
    function IsInGroup() return false end
    function CreateFrame() error("Version discovery must borrow the service's events") end
    function GetChannelName() error("Version discovery must borrow the service's channel ID") end
    function JoinTemporaryChannel() error("Only the service may join a channel") end
    function LeaveChannelByName() error("Only the service may leave a channel") end
    Enum = { SendAddonMessageResult = { Success = 0, InvalidChatType = 4, InvalidChannel = 7, AddonMessageThrottle = 3 } }
    transport = { owners = {}, acquired = 0, released = 0, status = options.unavailable and "unavailable" or "joining" }
    if options.otherOwner then transport.owners.partyFinder = function() end end
    if options.prejoined then transport.status, transport.id = "ready", 7 end
    function transport:Acquire(owner, callback)
        assert(owner == "versionCheck" and type(callback) == "function")
        if not self.owners[owner] then self.acquired = self.acquired + 1 end
        self.owners[owner] = callback
        if self:IsReady() then callback(self.id, self.status) end
        return self.status, self.id
    end
    function transport:Release(owner)
        assert(owner == "versionCheck", "Version shutdown cannot release another consumer")
        if self.owners[owner] then self.released = self.released + 1; self.owners[owner] = nil end
    end
    function transport:GetChannelID() return self.id end
    function transport:IsReady() return self.status == "ready" and self.id ~= nil end
    function transport:SetState(status, id)
        if self.status == status and self.id == id then return end
        self.status, self.id = status, id
        local callbacks = {}
        for _, callback in pairs(self.owners) do callbacks[#callbacks + 1] = callback end
        for _, callback in ipairs(callbacks) do callback(id, status) end
    end
    APR.CommunicationChannel = transport
    if options.noService then APR.CommunicationChannel = nil end
    C_ChatInfo = { SendAddonMessage = function(prefix, message, chatType, target)
        if options.sendError then error("Unsupported CHANNEL transport") end
        assert(prefix == "APRVersionCheck" and chatType == "CHANNEL" and target == transport.id)
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
local function receive(check, message, sender, id, name)
    check:HandleSharedMessage("APRVersionCheck", message, "CHANNEL", sender or "Peer-Home", "7. APR", 0,
        id or transport.id, name or "APR")
end
local function ready(id) transport:SetState("ready", id or 7) end

-- The service supplies readiness after login/reload. Before that, the version
-- module owns a reference, but no startup/join timer or native event listener.
for _, session in ipairs({"login", "reload"}) do
    local check = loadShared()
    assert(transport.owners.versionCheck and transport.acquired == 1 and #sent == 0 and activeTimers() == 0, session)
    advance(2)
    ready()
    assert(sent[1].message == "Q:7.3.0" and sent[1].target == 7 and activeTimers() == 1)
    ready()
    for _ = 1, 100 do check:RefreshSharedChannel(); check:StartSharedChannel() end
    assert(#sent == 1 and transport.acquired == 1, "Repeated readiness cannot duplicate the startup query")
    advance(12)
    assert(#sent == 2 and activeTimers() == 0, "One bounded retry, then no idle work")
    advance(600)
    ready(9)
    assert(#sent == 2 and activeTimers() == 0, "Renumbering does not restart a completed exchange")
end

-- An existing owner may make Acquire call back synchronously before it returns.
local check = loadShared({prejoined = true, otherOwner = true})
assert(#sent == 1 and activeTimers() == 1 and transport.owners.partyFinder)
advance(12)
assert(#sent == 2 and activeTimers() == 0)
receive(check, "Q:7.2.0")
local staleReady = transport.owners.versionCheck
check:OnDisable()
assert(transport.released == 1 and transport.owners.partyFinder and not transport.owners.versionCheck
    and activeTimers() == 0, "Version shutdown releases only its reference and cancels pending responses")
staleReady(7, "ready")
advance(30)
assert(#sent == 2, "An old readiness callback cannot revive a disabled consumer")

check = loadShared()
advance(12)
assert(#sent == 0 and activeTimers() == 0, "Delayed service readiness does not start a version polling loop")
ready()
receive(check, "V:7.4.0")
assert(#popups == 1 and APRData.versionCheck.retail == "7.4.0" and activeTimers() == 0,
    "A newer solo peer cancels the unnecessary query retry")
receive(check, "V:7.5.0")
assert(#popups == 1 and APRData.versionCheck.retail == "7.5.0")
local saved = APRData
check = loadShared({version = "7.2.0", saved = saved})
assert(#popups == 1 and APRData.versionCheck.retail == "7.5.0",
    "A reload/downgrade still warns from the observed release cache before readiness")

-- Bursts allocate one pending response; equally recent peers suppress duplicate
-- broadcasts, while intermediate/older replies cannot hide the newest release.
check = loadShared()
ready()
advance(12)
local sentBefore, timerBefore = #sent, #timers
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(#timers == timerBefore + 1 and activeTimers() == 1 and #sent == sentBefore)
advance(2)
assert(#sent == sentBefore + 1 and sent[#sent].message == "V:7.3.0" and activeTimers() == 0)
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(activeTimers() == 0, "The response cooldown bounds request storms")
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
assert(activeTimers() == 1)
advance(2)
assert(sent[#sent].message == "V:7.3.0")
advance(10)
receive(check, "V:7.2.0")
assert(activeTimers() == 0, "Version replies cannot trigger response loops")

-- The service's current ID and APR channel name must both match. The old
-- APRVersion channel is not trusted just because it occupies the same slot.
local baseline = APRData.versionCheck.retail
for _, row in ipairs({
    { "V:9.0.0", "Peer-Home", 6, "APR" },
    { "V:9.0.0", "Peer-Home", 7, "OtherChannel" },
    { "V:9.0.0", "Peer-Home", 7, "APRVersion" },
    { "V:9.0.0", "Local-Home", 7, "APR" },
    { "V:9.0.0", "Local", 7, "APR" },
    { "V:9.0.0", "Bad|Hname", 7, "APR" },
    { "V:9.0.0junk", "Peer-Home", 7, "APR" },
    { "Q:@project-version@", "Peer-Home", 7, "APR" },
    { "X:9.0.0", "Peer-Home", 7, "APR" },
    { "7.4.0", "Peer-Home", 7, "APR" },
    { string.rep("9", 67), "Peer-Home", 7, "APR" },
}) do receive(check, unpack(row)) end
check:HandleSharedMessage("OTHER_ADDON", "V:9.0.0", "CHANNEL", "Peer-Home", nil, 0, 7, "APR")
check:HandleSharedMessage("APRVersionCheck", "V:9.0.0", "GUILD", "Peer-Home", nil, 0, 7, "APR")
assert(APRData.versionCheck.retail == baseline and #popups == 0 and activeTimers() == 0)
ready(9)
receive(check, "V:7.4.0", "Peer-Home", 7)
assert(#popups == 0, "A stale slot cannot update the cache after renumbering")
receive(check, "V:7.4.0", "Peer-OtherRealm", 9, "apr")
assert(#popups == 1)

-- Shared packets still bypass APR's general quest/UI event dispatcher.
function CreateFrame()
    return {RegisterEvent = function() end, SetScript = function() end}
end
dofile("APR-Core/core/Event.lua")
APR.GetSettingsProfile = function() error("Shared packets must not enter the quest/UI dispatcher") end
local packetCount = #sent
for _ = 1, 1000 do
    APR.event.EventHandler({ tag = "party" }, "CHAT_MSG_ADDON", "OTHER_ADDON", "noise", "CHANNEL", "Peer")
end
APR.event.EventHandler({ tag = "party" }, "CHAT_MSG_ADDON", "APRVersionCheck", "V:7.6.0", "CHANNEL",
    "Peer-Home", "9. APR", 0, 9, "APR")
assert(#sent == packetCount and APRData.versionCheck.retail == "7.6.0")

-- Unsupported/pending services do not trigger a fallback to visible chat or a
-- second channel. Only the service may decide whether a manual retry is allowed.
for _, config in ipairs({ { unavailable = true }, { noService = true }, { enabled = false },
    { notify = false }, { version = "@project-version@" } }) do
    check = loadShared(config)
    advance(60)
    assert(#sent == 0 and activeTimers() == 0)
end
for _, config in ipairs({ { sendResult = 4 }, { sendResult = 7 }, { sendError = true } }) do
    config.prejoined, config.otherOwner = true, true
    check = loadShared(config)
    advance(60)
    assert(not check.sharedChannelID and not check.sharedStarted and not transport.owners.versionCheck
        and transport.owners.partyFinder and transport.released == 1 and activeTimers() == 0,
        "A failed first send releases only versions, even inside synchronous Acquire")
end
check = loadShared({client = "forever", legacyResult = true})
ready()
advance(12)
assert(#sent == 2 and activeTimers() == 0, "Forever's successful legacy nil result stays supported")
check = loadShared({sendResult = 3})
ready()
advance(12)
receive(check, "Q:7.2.0")
advance(2)
for _ = 1, 1000 do receive(check, "Q:7.2.0") end
assert(#sent == 3 and activeTimers() == 0, "Failed responses are also rate-limited")
check = loadShared()
local callback = transport.owners.versionCheck
check:OnDisable()
callback(7, "ready")
advance(30)
assert(#sent == 0 and activeTimers() == 0 and not transport.owners.versionCheck)
check = loadShared({otherOwner = true})
APR.settings.profile.checkForUpdate = false
ready()
assert(transport.released == 1 and transport.owners.partyFinder and #sent == 0,
    "An opt-out arriving before readiness cannot release the finder")

-- A temporary unavailable state cannot leak a response; the owner's reference
-- stays registered and the finite startup retry uses the new ready slot.
check = loadShared({otherOwner = true})
ready()
receive(check, "Q:7.2.0")
transport:SetState("restricted", nil)
advance(2)
assert(#sent == 1 and transport.owners.versionCheck and transport.owners.partyFinder)
ready(9)
advance(10)
assert(#sent == 2 and sent[2].target == 9 and activeTimers() == 0,
    "The bounded retry follows authoritative service readiness and renumbering")

-- Live profile/enable changes borrow or release only the version reference.
check = loadShared({notify = false, prejoined = true, otherOwner = true,
    saved = {versionCheck = {retail = "7.4.0"}}})
assert(not transport.owners.versionCheck and transport.owners.partyFinder and #popups == 0)
APR.settings.profile.checkForUpdate = true
check:RefreshSettings()
assert(transport.owners.versionCheck and transport.acquired == 1 and #sent == 1 and #popups == 1,
    "Activating an initially opted-out profile checks the cached release and starts its solo exchange")
for _ = 1, 100 do check:RefreshSettings() end
assert(#sent == 1 and transport.acquired == 1 and activeTimers() == 1,
    "Unchanged settings cannot turn the finite startup exchange into repeated queries")
receive(check, "Q:7.2.0")
check.broadcastTimer = C_Timer.NewTimer(99, function() error("A disabled broadcast cannot run") end)
check.broadcastRetryTimer = C_Timer.NewTimer(100, function() error("A disabled retry cannot run") end)
APR.settings.profile.checkForUpdate = false
check:RefreshSettings()
assert(not transport.owners.versionCheck and transport.owners.partyFinder and activeTimers() == 0
    and not check.sharedQueryTimer and not check.sharedResponseTimer
    and not check.broadcastTimer and not check.broadcastRetryTimer)
APR.settings.profile.checkForUpdate, APR.settings.profile.enableAddon = true, false
check:RefreshSettings()
assert(transport.acquired == 1 and #sent == 1, "The master switch still prevents acquisition")
APR.settings.profile.enableAddon = true
check:RefreshSettings()
assert(transport.acquired == 2 and #sent == 2 and transport.owners.partyFinder and #popups == 1)
advance(12)
for _ = 1, 100 do check:RefreshSettings() end
assert(#sent == 3 and activeTimers() == 0, "Repeated profile refreshes cannot restart a completed exchange")

-- A realm-wide burst is rejected before version parsing and sender identity
-- normalization. Observe calls from the ingress handler, excluding cache comparisons.
check = loadShared({prejoined = true})
advance(12)
local ingressParses, identityReads, allParses = 0, 0, 0
local originalPlayerKey = APR.PartyProtocol.PlayerKey
APR.PartyProtocol.PlayerKey = function(name)
    if type(name) == "string" and name:match("^Flood%d+%-Home$") then identityReads = identityReads + 1 end
    return originalPlayerKey(name)
end
local function upvalue(fn, name)
    local index = 1
    while true do
        local key, value = debug.getupvalue(fn, index)
        if not key then return end
        if key == name then return value, index end
        index = index + 1
    end
end
local function unwrap(fn)
    while true do
        local original = upvalue(fn, "original")
        if type(original) ~= "function" or original == fn then return fn end
        fn = original
    end
end
local ingress = unwrap(check.HandleSharedMessage)
local originalParse, parseIndex = upvalue(ingress, "ParseVersion")
assert(type(originalParse) == "function" and parseIndex, "The test must observe the real shared parser cell")
-- Replacing the shared lexical cell observes every use, while delegating through
-- the original parser wrapper keeps Diagnostics fully enabled and instrumented.
debug.setupvalue(ingress, parseIndex, function(value)
    allParses = allParses + 1
    if debug.getinfo(2, "f").func == ingress then ingressParses = ingressParses + 1 end
    return originalParse(value)
end)
local burstTimers, burstPackets = #timers, #sent
local parsesAtLimit
for index = 1, 10000 do
    receive(check, "V:7.3.0", "Flood" .. index .. "-Home")
    if index == 64 then parsesAtLimit = allParses end
end
assert(ingressParses == 64 and identityReads == 64 and check.sharedReceiveCount == 64,
    "One shared 64-packet budget bounds parsing and identities across all senders")
assert(allParses == parsesAtLimit, "Overflow must not even parse the installed or cached version")
assert(#timers == burstTimers and activeTimers() == 0 and #sent == burstPackets and #popups == 0,
    "Overflow traffic cannot allocate timers, send replies or create alerts")
advance(1)
receive(check, "V:7.3.0", "Flood10001-Home")
assert(identityReads == 65 and check.sharedReceiveCount == 1, "A new second restores the finite ingress budget")

-- Missing/secret metadata is rejected before parsing or consuming the budget.
advance(1)
local secret = {}
function issecretvalue(value) return rawequal(value, secret) end
local previousIdentities, previousBudget = identityReads, check.sharedReceiveCount
ingressParses, allParses = 0, 0
for _, index in ipairs({1, 2, 3, 4, 7, 8}) do
    local args = {"APRVersionCheck", "V:7.3.0", "CHANNEL", "Flood10002-Home", nil, 0, 7, "APR"}
    args[index] = nil
    check:HandleSharedMessage(unpack(args, 1, 8))
    args[index] = secret
    check:HandleSharedMessage(unpack(args, 1, 8))
end
transport.id = secret
check:HandleSharedMessage("APRVersionCheck", "V:7.3.0", "CHANNEL", "Flood10002-Home", nil, 0, 7, "APR")
transport.id = 7
debug.setupvalue(ingress, parseIndex, originalParse)
issecretvalue = nil
assert(ingressParses == 0 and allParses == 0 and identityReads == previousIdentities and check.sharedReceiveCount == previousBudget
    and #timers == burstTimers and activeTimers() == 0,
    "Secret or nil metadata must never reach parsing, identities or reply scheduling")
print("Shared APR versions: borrowed transport, readiness/reentrance, solo retry/cache, bounded suppression, metadata and independent owners passed")
