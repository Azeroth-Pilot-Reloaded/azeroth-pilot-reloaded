-- Synthetic service contract; version integration reuses only this constructor.
local Fixture = {}

function Fixture.New(options)
    options = options or {}
    local env = {now = 100, timers = {}, joined = {}, left = {}, sent = {}, frames = {}, errors = {},
        id = options.prejoined and 7 or 0, restricted = options.restricted == true, map = 501, instance = false,
        combat = options.combat == true, legacyID = options.legacyVersion and 9 or 0,
        unrelatedChannels = {General = 1, Trade = 2, ["Synthetic user channel"] = 6},
        lookups = 0, legacyLookups = 0, client = options.client or "retail", options = options}
    APR = {
        version = options.version or "7.3.0", Username = "Local-Home",
        settings = {profile = {enableAddon = true, checkForUpdate = true}},
        GAME_VERSIONS = {Classic = "classic", Retail = "retail", Forever = "forever"},
        NewModule = function() return {} end,
        GetGameVersion = function() return env.client end,
        RegisterSupportedEvent = function(_, frame, event) frame:RegisterEvent(event) end,
        WrapTextWithAppearanceColor = function(_, value) return value end,
        questionDialog = {CreateMessagePopup = function() env.alerts = (env.alerts or 0) + 1 end},
    }
    function LibStub() return {GetLocale = function() return {OUTDATED_VERSION_ALERT = "%s %s"} end} end
    function GetTime() return env.now end
    function GetNormalizedRealmName() return "Home" end
    function IsInGroup() return false end
    function IsInInstance() return env.instance end
    function InCombatLockdown() return env.combat end
    C_Map = {GetBestMapForUnit = function() return env.map end}
    function issecretvalue(value) return env.secret ~= nil and value == env.secret end
    function geterrorhandler() return function(err) env.errors[#env.errors + 1] = err end end
    function CreateFrame()
        local frame = {events = {}, scripts = {}}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        env.frames[#env.frames + 1] = frame
        return frame
    end
    C_Timer = {NewTimer = function(delay, callback)
        assert(type(delay) == "number" and delay >= 0 and delay < math.huge)
        local timer = {at = env.now + delay, callback = callback}
        function timer:Cancel() self.cancelled = true end
        env.timers[#env.timers + 1] = timer
        return timer
    end, NewTicker = function() error("The shared channel must not poll") end}
    function GetChannelName(name)
        if name == "APRVersion" then
            env.legacyLookups = env.legacyLookups + 1
            if options.legacyLookupError then error("Unavailable legacy channel lookup") end
            if env.legacyLookup then return env.legacyLookup() end
            return env.legacyID, env.legacyID and env.legacyID > 0 and "APRVersion" or nil
        end
        assert(name == "APR", "Only APR and its exact legacy version channel may be inspected")
        env.lookups = env.lookups + 1
        if options.lookupError then error("Unavailable channel lookup") end
        return env.id, env.id > 0 and "APR" or nil
    end
    function JoinTemporaryChannel(name)
        assert(name == "APR", "Discovery and versions must share one channel")
        env.joined[#env.joined + 1] = {name = name, at = env.now}
        if options.joinError then error("Unavailable join") end
        if not options.delayedJoin then env.id = 7 end
    end
    function LeaveChannelByName(name)
        assert(name == "APR" or name == "APRVersion", "Unrelated native and user channels must remain untouched")
        env.left[#env.left + 1] = name
        if name == "APRVersion" then
            if options.legacyLeaveError then error("Unavailable legacy channel leave") end
            env.legacyID = 0
            if options.legacyRenumbersAPR then env.id = options.legacyRenumbersAPR end
        else
            env.id = 0
        end
    end
    local function ProtectedChat() error("Shared membership cannot reorder or alter chat windows") end
    SwapChatChannelsByChannelIndex, SwapChatChannelByLocalID = ProtectedChat, ProtectedChat
    ChatConfigChannelSettings_SwapChannelsByIndex = ProtectedChat
    SetSelectedDisplayChannel, AddChatWindowChannel, RemoveChatWindowChannel = ProtectedChat, ProtectedChat, ProtectedChat
    ChatFrame_AddChannel, ChatFrame_RemoveChannel, JoinPermanentChannel = ProtectedChat, ProtectedChat, ProtectedChat
    ChatFrameUtil = {AddChannel = ProtectedChat, RemoveChannel = ProtectedChat}
    Enum = {SendAddonMessageResult = {Success = 0, InvalidChatType = 4, InvalidChannel = 7,
        AddonMessageThrottle = 3, AddOnMessageLockdown = 11}}
    C_ChatInfo = {
        InChatMessagingLockdown = function() return env.restricted end,
        SwapChatChannelsByChannelIndex = ProtectedChat,
        SendAddonMessage = function(prefix, message, distribution, target)
            env.sent[#env.sent + 1] = {prefix = prefix, message = message, distribution = distribution,
                target = target, at = env.now, restricted = env.restricted}
            if env.restricted then return Enum.SendAddonMessageResult.AddOnMessageLockdown end
            return options.sendResult or 0
        end,
    }
    if options.noJoinAPI then JoinTemporaryChannel = nil end
    dofile("APR-Core/core/CommunicationChannel.lua")
    env.channel = APR.CommunicationChannel
    function env:Advance(seconds)
        local target, iterations = self.now + seconds, 0
        while true do
            local earliest
            for _, timer in ipairs(self.timers) do
                if not timer.cancelled and not timer.fired and timer.at <= target
                    and (not earliest or timer.at < earliest.at) then earliest = timer end
            end
            if not earliest then break end
            iterations = iterations + 1
            assert(iterations <= 1000, "Shared timers must converge without periodic polling")
            self.now, earliest.fired = earliest.at, true
            earliest.callback()
        end
        self.now = target
    end
    function env:ActiveTimers()
        local count = 0
        for _, timer in ipairs(self.timers) do if not timer.cancelled and not timer.fired then count = count + 1 end end
        return count
    end
    function env:Event(event, ...)
        local frame = self.channel.frame
        assert(frame and frame.events[event], "Expected service event: " .. event)
        frame.scripts.OnEvent(frame, event, ...)
    end
    return env
end

if ... == "fixture" then return Fixture end

-- Sending must re-resolve the named channel even before CHANNEL_UI_UPDATE.
do
    local env = Fixture.New({prejoined = true})
    env.channel:Acquire("partyFinder", function() end)
    env.id = 9
    assert(env.channel:GetChannelID() == 7 and env.channel:GetSendChannelID() == 9)
    env.id = 0
    assert(env.channel:GetSendChannelID() == nil and env.channel:GetChannelID() == nil,
        "A recently vacated slot must never be used as APR's destination")
    assert(#env.joined == 0 and #env.left == 0)
end

for _, client in ipairs({"retail", "forever"}) do
    local env = Fixture.New({client = client})
    local channel, updates = env.channel, {}
    local status, id = channel:Acquire("versionCheck", function(currentID, currentStatus)
        updates[#updates + 1] = {id = currentID, status = currentStatus}
    end)
    assert(status == "joining" and id == nil and #env.joined == 0 and env:ActiveTimers() == 1)
    local finderID
    channel:Acquire("partyFinder", function(currentID) finderID = currentID end)
    env:Advance(1.99)
    assert(#env.joined == 0)
    env:Advance(0.01)
    assert(#env.joined == 1 and env.joined[1].at == 102 and channel:IsReady()
        and channel:GetChannelID() == 7 and finderID == 7 and env:ActiveTimers() == 0)
    local callbacks, lookups, timers = #updates, env.lookups, #env.timers
    for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE") end
    assert(env.lookups == lookups and #env.timers == timers + 1, "UI event bursts coalesce before native lookup")
    env:Advance(0.1)
    assert(env.lookups == lookups + 1 and #updates == callbacks and #env.joined == 1 and #env.left == 0)
    channel:Release("versionCheck")
    assert(channel.owners.partyFinder and channel:IsReady() and #env.left == 0)
    channel:Release("partyFinder")
    assert(#env.left == 1 and not next(channel.owners) and env:ActiveTimers() == 0 and not next(channel.frame.events))
end

-- Native membership may complete asynchronously, including without its UI event.
local env = Fixture.New({delayedJoin = true})
local channel = env.channel
channel:Acquire("partyFinder", function() end)
env:Advance(2)
assert(#env.joined == 1 and channel.status == "joining" and env:ActiveTimers() == 1)
env:Advance(9.9)
assert(channel.status == "joining")
env.id = 7
env:Advance(0.1)
assert(channel:IsReady() and channel:GetChannelID() == 7 and env:ActiveTimers() == 0,
    "The single ten-second timeout resolves a missed native readiness event")

for _, options in ipairs({{delayedJoin = true}, {joinError = true}, {lookupError = true}}) do
    env = Fixture.New(options)
    channel = env.channel
    channel:Acquire("partyFinder", function() end)
    env:Advance(12)
    assert(channel.status == "unavailable" and #env.joined == 1 and env:ActiveTimers() == 0)
    for _ = 1, 100 do env:Event("CHANNEL_UI_UPDATE") end
    env:Advance(100)
    assert(#env.joined == 1 and env:ActiveTimers() == 0, "A failed join cannot become an automatic join loop")
    channel:Release("partyFinder")
end

env = Fixture.New({prejoined = true})
channel = env.channel
local synchronousID
channel:Acquire("versionCheck", function(id, status) if status == "ready" then synchronousID = id end end)
assert(synchronousID == 7 and #env.joined == 0 and env:ActiveTimers() == 0)
channel:Release("versionCheck")
assert(#env.left == 0 and env.id == 7, "A prejoined channel belongs to the user")

-- Transient world data and restrictions do not authorize membership changes.
env = Fixture.New()
channel = env.channel
channel:Acquire("partyFinder", function() end)
env:Advance(2)
for index = 1, 100 do
    env.map = index % 2 == 0 and 501 or nil
    env.instance, env.restricted = index % 3 == 0, index % 4 == 0
    env:Event("PLAYER_ENTERING_WORLD", false, false)
    env:Event("CHANNEL_UI_UPDATE")
    env:Event("PLAYER_REGEN_ENABLED")
    env:Advance(0.1)
    assert(channel:GetChannelID() == 7 and #env.joined == 1 and #env.left == 0)
end
env.restricted, env.instance = false, false
env.id = 0
env:Event("CHANNEL_UI_UPDATE")
env:Advance(0.1)
assert(channel.status == "unavailable" and not channel:GetChannelID())
for _ = 1, 100 do env:Event("CHANNEL_UI_UPDATE"); env:Event("PLAYER_ENTERING_WORLD") end
env:Advance(100)
assert(#env.joined == 1, "A manual leave must be respected until an explicit retry")
channel:Retry()
assert(#env.joined == 2 and channel:IsReady())
channel:Retry()
assert(#env.joined == 2, "A ready service has nothing to retry")

for _, options in ipairs({{client = "classic"}, {noJoinAPI = true}}) do
    env = Fixture.New(options)
    channel = env.channel
    channel:Acquire("versionCheck", function() end)
    env:Advance(100)
    assert(channel.status == "unavailable" and #env.joined == 0 and env:ActiveTimers() == 0)
    channel:Release("versionCheck")
    assert(#env.left == 0)
end

-- Every callback boundary must tolerate the final owner releasing itself.
env = Fixture.New()
channel = env.channel
channel:Acquire("versionCheck", function(_, status) if status == "joining" then channel:Release("versionCheck") end end)
assert(not next(channel.owners) and env:ActiveTimers() == 0, "Release inside Acquire cannot leave a startup timer behind")
env:Advance(30)
assert(#env.joined == 0 and #env.left == 0)

env = Fixture.New({restricted = true})
channel = env.channel
local cancelResume = false
channel:Acquire("versionCheck", function(_, status)
    if cancelResume and status == "joining" then channel:Release("versionCheck") end
end)
env:Advance(2)
assert(channel.status == "restricted" and #env.joined == 0 and env:ActiveTimers() == 0)
cancelResume, env.restricted = true, false
env:Event("PLAYER_REGEN_ENABLED")
assert(not next(channel.owners) and env:ActiveTimers() == 0 and #env.joined == 0,
    "Release during restriction recovery cannot create an orphan join")

env = Fixture.New()
channel = env.channel
local secondReady = 0
channel:Acquire("versionCheck", function(_, status) if status == "ready" then error("Synthetic consumer failure") end end)
channel:Acquire("partyFinder", function(_, status) if status == "ready" then secondReady = secondReady + 1 end end)
local ok = pcall(function() env:Advance(2) end)
assert(ok and secondReady == 1 and channel:IsReady(), "One failed callback cannot abort another consumer's readiness")
env:Event("PLAYER_LOGOUT")
assert(#env.left == 1 and env:ActiveTimers() == 0 and not next(channel.frame.events))

-- A native legacy membership survives Lua reloads; retire only that exact name
-- after the new shared channel is confirmed ready, once per loaded session.
for _, client in ipairs({"retail", "forever"}) do
    env = Fixture.New({client = client, legacyVersion = true, delayedJoin = true})
    assert(env.legacyID == 9)
    dofile("APR-Core/core/CommunicationChannel.lua")
    env.channel, channel = APR.CommunicationChannel, APR.CommunicationChannel
    assert(env.legacyID == 9 and #env.left == 0, "A Lua reload does not remove native persisted memberships")
    channel:Acquire("versionCheck", function() end)
    channel:Acquire("partyFinder", function() end)
    env:Advance(2)
    assert(#env.joined == 1 and channel.status == "joining" and env.legacyID == 9
        and env.legacyLookups == 0 and #env.left == 0,
        "Legacy membership is retained until the replacement channel is ready")
    env.id = 7
    env:Event("CHANNEL_UI_UPDATE")
    env:Advance(0.1)
    assert(channel:IsReady() and channel:GetChannelID() == 7 and env.legacyID == 0)
    assert(#env.joined == 1 and #env.left == 1 and env.left[1] == "APRVersion" and env.legacyLookups == 1)
    assert(env.unrelatedChannels.General == 1 and env.unrelatedChannels.Trade == 2
        and env.unrelatedChannels["Synthetic user channel"] == 6)
    local legacyLookups, left = env.legacyLookups, #env.left
    for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE") end
    env:Advance(0.1)
    assert(env.legacyLookups == legacyLookups and #env.left == left and #env.joined == 1
        and env:ActiveTimers() == 0, "A completed migration performs no repeated legacy work")
    channel:Release("versionCheck")
    assert(channel:IsReady() and channel.owners.partyFinder and #env.left == left)
    channel:Release("partyFinder")
    assert(#env.left == left + 1 and env.left[#env.left] == "APR")
    -- A later explicit user membership is not removed after all owners restart.
    env.id, env.legacyID = 7, 9
    channel:Acquire("partyFinder", function() end)
    assert(channel:IsReady() and env.legacyID == 9 and env.legacyLookups == legacyLookups
        and #env.left == left + 1, "Shutdown preserves the session's completed migration marker")
end

env = Fixture.New({prejoined = true, legacyVersion = true})
channel = env.channel
channel:Acquire("versionCheck", function() end)
channel:Acquire("partyFinder", function() end)
assert(channel:IsReady() and env.id == 7 and env.legacyID == 0 and #env.joined == 0)
assert(#env.left == 1 and env.left[1] == "APRVersion")
channel:Release("versionCheck")
channel:Release("partyFinder")
assert(env.id == 7 and #env.left == 1, "Retiring the legacy name does not take ownership of prejoined APR")

env = Fixture.New({prejoined = true, legacyVersion = true, legacyRenumbersAPR = 8})
channel = env.channel
local readyDestination
channel:Acquire("versionCheck", function(_, status)
    if status == "ready" then readyDestination = channel:GetSendChannelID() end
end)
assert(readyDestination == 8 and channel:GetChannelID() == 8 and env.id == 8 and env.legacyID == 0
    and env.legacyLookups == 1 and #env.joined == 0 and #env.left == 1,
    "Readiness consumers re-resolve APR after a legacy leave renumbers its slot, before any native UI event")

env = Fixture.New({prejoined = true})
channel = env.channel
channel:Acquire("versionCheck", function() end)
assert(channel:IsReady() and env.legacyLookups == 1 and #env.left == 0)
for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE") end
env:Advance(0.1)
assert(env.legacyLookups == 1 and #env.left == 0 and env:ActiveTimers() == 0,
    "A confirmed absent legacy channel also completes the one-session check")

for _, blocked in ipairs({"combat", "restricted"}) do
    env = Fixture.New({prejoined = true, legacyVersion = true, [blocked] = true})
    channel = env.channel
    channel:Acquire("versionCheck", function() end)
    for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE") end
    env:Advance(20)
    assert(env.legacyID == 9 and #env.left == 0 and env.legacyLookups == 0 and env:ActiveTimers() == 0,
        "Combat and chat restrictions defer migration without polling")
    env[blocked] = false
    env:Event("PLAYER_REGEN_ENABLED")
    env:Advance(0.1)
    assert(channel:IsReady() and env.id == 7 and env.legacyID == 0
        and #env.left == 1 and env.left[1] == "APRVersion" and env:ActiveTimers() == 0,
        "An unrestricted recovery event also retries migration when readiness is unchanged")
end

env = Fixture.New({prejoined = true, legacyVersion = true})
channel = env.channel
local leave = LeaveChannelByName
LeaveChannelByName = nil
channel:Acquire("versionCheck", function() end)
env:Advance(20)
assert(channel:IsReady() and env.id == 7 and env.legacyID == 9 and #env.left == 0 and env:ActiveTimers() == 0)
LeaveChannelByName = leave
env:Event("PLAYER_REGEN_ENABLED")
env:Advance(0.1)
assert(env.legacyID == 0 and #env.left == 1 and env.left[1] == "APRVersion",
    "A missing optional leave API can recover on the next native event")

env = Fixture.New({prejoined = true, legacyVersion = true})
channel = env.channel
local lookup = GetChannelName
GetChannelName = nil
channel:Acquire("versionCheck", function() end)
env:Advance(20)
assert(channel.status == "unavailable" and env.id == 7 and env.legacyID == 9
    and env.legacyLookups == 0 and #env.left == 0 and env:ActiveTimers() == 0)
GetChannelName = lookup
env:Event("PLAYER_REGEN_ENABLED")
env:Advance(0.1)
assert(channel:IsReady() and env.id == 7 and env.legacyID == 0 and #env.left == 1)

-- Invalid or private native lookup results cannot authorize a membership change.
for _, result in ipairs({{}, {0}, {-1}, {1.5}, {math.huge}, {0 / 0}, {"9"}, {false},
    {9}, {9, "General"}, {9, "APRVersion", secret = 9}, {9, "APRVersion", secret = "APRVersion"}}) do
    env = Fixture.New({prejoined = true, legacyVersion = true})
    channel = env.channel
    env.secret = result.secret
    env.legacyLookup = function() return result[1], result[2] end
    local ok = pcall(function() channel:Acquire("versionCheck", function() end) end)
    assert(ok and channel:IsReady() and env.id == 7 and env.legacyID == 9 and #env.left == 0,
        "Only a public positive integer ID with the exact public legacy name can be retired")
    for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE") end
    env:Advance(0.1)
    assert(env.legacyLookups == 1 and #env.left == 0 and env:ActiveTimers() == 0,
        "An invalid native result does not trigger repeated migration attempts")
end

for _, failure in ipairs({"legacyLookupError", "legacyLeaveError"}) do
    env = Fixture.New({prejoined = true, legacyVersion = true, [failure] = true})
    channel = env.channel
    local ok = pcall(function() channel:Acquire("versionCheck", function() end) end)
    local expectedLeaves = failure == "legacyLeaveError" and 1 or 0
    assert(ok and channel:IsReady() and env.id == 7 and env.legacyID == 9
        and env.legacyLookups == 1 and #env.left == expectedLeaves,
        "A failed native migration operation cannot abort the shared channel")
    for _ = 1, 1000 do env:Event("CHANNEL_UI_UPDATE"); env:Event("PLAYER_REGEN_ENABLED") end
    env:Advance(20)
    assert(env.legacyLookups == 1 and #env.left == expectedLeaves and env:ActiveTimers() == 0,
        "A failed migration is best effort, with no retry loop or polling timer")
    if expectedLeaves == 1 then assert(env.left[1] == "APRVersion") end
end

print("Shared channel: delayed shared membership, bounded events, owner isolation, transient recovery and exact legacy retirement passed")
