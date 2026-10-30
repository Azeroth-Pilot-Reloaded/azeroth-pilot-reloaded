local DirectEnv = dofile("tests/lua/party_finder_direct_test_env.lua")

local function New()
    local env = {now = 100, calls = {}, frames = {}, settings = {visible = true}, notices = 0}
    function GetTime() return env.now end
    function issecretvalue(value) return type(value) == "table" and value.secret == true end
    function hooksecurefunc() end
    function CreateFrame()
        local frame = {scripts = {}, events = {}}
        function frame:SetScript(name, callback) self.scripts[name] = callback end
        function frame:RegisterEvent(name) self.events[name] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        env.frames[#env.frames + 1] = frame
        return frame
    end
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function() end,
        SendAddonMessage = function(prefix, wire, channel, target)
            env.calls[#env.calls + 1] = {prefix = prefix, wire = wire, channel = channel, target = target}
            return env.result
        end,
    }
    env.result = 0
    Enum = {SendAddonMessageResult = {Success = 0, AddonMessageThrottle = 3, InvalidChatType = 4,
        InvalidChannel = 7, GeneralError = 9, AddOnMessageLockdown = 11, TargetOffline = 12}}
    LibStub, ChatThrottleLib = nil, nil
    APR = {partyFinder = {context = "12345678", worldContext = "87654321", status = "ready"}}
    dofile("APR-Core/features/group/PartyFinderProtocol.lua")
    DirectEnv.Install(env)
    dofile("APR-Core/features/group/PartyFinderDirect.lua")
    local finder = APR.partyFinder
    function finder:IsEnabled() return not env.disabled end
    function finder:IsRestricted() return env.restricted == true end
    function finder:GetSettings() return env.settings end
    function finder:Notify() env.notices = env.notices + 1 end
    env.finder, env.protocol = finder, APR.PartyFinderProtocol
    env.nativeSend = C_ChatInfo.SendAddonMessage
    function env:Pump(seconds)
        self.now = self.now + (seconds or 1)
        self:PumpDirect(seconds or 1)
    end
    function env:Receive(prefix, wire, channel, sender)
        local frame = self.directAceComm.frame
        frame:GetScript("OnEvent")(frame, "CHAT_MSG_ADDON", prefix, wire, channel or "WHISPER", sender or "Peer-Other")
    end
    function env:Presence(id)
        return self.protocol.Encode("P", {id = id or "query-a", context = "12345678", map = 501,
            route = "11223344", revision = "55667788", progressId = "main:3", step = 3, total = 20,
            primary = "fr", languages = 2, languageSource = "player", level = 17, class = 8,
            groupSize = 0, leader = true, recruiting = true, afk = false, dnd = false, warMode = false})
    end
    function env:Reply(id) return self.protocol.Encode("R", {id = id or "invite-a", status = "declined"}) end
    return env, finder
end

-- Real AceComm and CTL preserve the small wire format and native success variants.
for _, result in ipairs({0, true, "nil"}) do
    local env, finder = New()
    env.result = result == "nil" and nil or result
    if result == "nil" then env.result = nil end
    assert(finder:SendDirect("R", env:Reply(), "Peer-Other"))
    assert(#env.calls == 1 and env.calls[1].prefix == "APRFindV1"
        and env.calls[1].wire == env:Reply() and env.calls[1].channel == "WHISPER")
    assert(C_ChatInfo.SendAddonMessage == env.nativeSend, "No native API is replaced")
    assert(not finder.directRegistered and finder.directReady, "Raw reception remains authoritative")
end

for _, example in ipairs({{4, "unavailable"}, {7, "unavailable"}, {11, "restricted"}, {12, "ready"}}) do
    local env, finder = New()
    env.result = example[1]
    assert(not finder:SendDirect("R", env:Reply(), "Peer-Other"))
    assert(finder.status == example[2], "Captured CTL results preserve native failure distinctions")
end

-- Nothing enters CTL for bad packets, unavailable contracts or invalid guards.
do
    local env, finder = New()
    assert(not finder:SendDirect("Q", env:Reply(), "Peer-Other"))
    assert(not finder:SendDirect("R", "1|R|" .. string.rep("x", 241), "Peer-Other"))
    assert(not finder:SendDirect("R", "\001fragment", "Peer-Other"))
    assert(not finder:SendDirect("R", env:Reply(), "Unsafe|Peer"))
    assert(not finder:SendDirect("R", env:Reply(), "Peer-Other", function() return false end))
    assert(not finder:SendDirect("R", env:Reply(), "Peer-Other", nil, math.huge))
    env.directCTL.version = 33
    assert(not finder:SendDirect("R", env:Reply(), "Peer-Other") and #env.calls == 0)
end

do
    local env, finder = New()
    env.directCTL.Prio.NORMAL.Ring = nil
    assert(not finder:SendDirect("R", env:Reply(), "Peer-Other") and #env.calls == 0)
end

-- The last-moment guard also covers an enqueue caused by a native throttle.
do
    local env, finder = New()
    local allowed = true
    env.result = 3
    assert(finder:SendDirect("P", env:Presence(), "Peer-Other", function() return allowed end))
    assert(#env.calls == 1 and env.directCTL.bQueueing)
    allowed, env.result = false, 0
    env:Pump()
    assert(#env.calls == 1, "A previously throttled snapshot is checked again before retry")
end

do
    local env, finder = New()
    env.directCTL.avail = 0
    assert(finder:SendDirect("R", env:Reply(), "Peer-Other"))
    env.result = 11
    env:Pump()
    assert(finder.status == "restricted" and #env.calls == 1,
        "Deferred native errors keep their real status after the AceComm callback adapter")
end

for _, change in ipairs({"hidden", "context", "expired", "stopped"}) do
    local env, finder = New()
    env.directCTL.avail = 0
    assert(finder:SendDirect("P", env:Presence(), "Peer-Other", nil, .5) and #env.calls == 0)
    if change == "hidden" then env.settings.visible = false
    elseif change == "context" then finder.context = "ffffffff"
    elseif change == "stopped" then finder:StopDirectTransport() end
    env:Pump()
    assert(#env.calls == 0, "Hidden, expired, stopped or incompatible snapshots are not delivered")
end

-- Cancellation is scoped by recipient and query, without discarding invitation results.
do
    local env, finder = New()
    env.directCTL.avail = 0
    assert(finder:SendDirect("P", env:Presence("cancel-me"), "Peer-Other"))
    assert(finder:SendDirect("P", env:Presence("keep-me"), "Second-Other"))
    assert(finder:SendDirect("R", env:Reply(), "Peer-Other"))
    finder:CancelDirectPresence("Peer-Other", "cancel-me")
    env:Pump()
    assert(#env.calls == 2 and env.calls[1].target == "Second-Other"
        and env.protocol.Decode(env.calls[2].wire).kind == "R")
end

-- Stop/reinitialize cannot escape the global bound while CTL still owns records.
do
    local env, finder = New()
    env.directCTL.avail = 0
    for index = 1, 32 do assert(finder:SendDirect("R", env:Reply("invite-" .. index), "Peer-Other")) end
    assert(not finder:SendDirect("R", env:Reply("overflow"), "Peer-Other"))
    finder:StopDirectTransport()
    assert(finder:InitializeDirectTransport())
    assert(not finder:SendDirect("R", env:Reply("still-full"), "Peer-Other"))
    env:Pump(2)
    assert(#env.calls == 0, "Stop invalidates the backlog without leaking it on reinitialization")
    assert(finder:SendDirect("R", env:Reply("recovered"), "Peer-Other"))
    env:Pump()
    assert(#env.calls == 1)
end

-- Invitation/results have a finite 60-second lifetime, independent of presence.
do
    local env, finder = New()
    env.directCTL.avail = 0
    assert(finder:SendDirect("R", env:Reply(), "Peer-Other"))
    env:Pump(61)
    assert(#env.calls == 0)
end

-- Prefix guards precede AceComm's multipart assembly, including without RegisterComm.
do
    local env, finder = New()
    assert(finder:InitializeDirectTransport())
    local ace = env.directAceComm
    for _, wire in ipairs({"\001start", "\002next", "\003last", "\004escape", string.rep("x", 241)}) do
        env:Receive("APRFindV1", wire)
    end
    assert(not next(ace.multipart_spool), "APR never creates an unbounded multipart spool")
    local received, foreign = {}, {}
    ace.RegisterComm(foreign, "ForeignTest", function(prefix, wire, channel, sender)
        received[#received + 1] = {prefix, wire, channel, sender}
    end)
    env:Receive("ForeignTest", "\001first")
    env:Receive("ForeignTest", "\002middle")
    env:Receive("ForeignTest", "\003last")
    assert(#received == 1 and received[1][2] == "firstmiddlelast" and received[1][4] == "Peer-Other")
    ace.SendCommMessage(foreign, "ForeignTest", "ordinary", "WHISPER", "Other-Home")
    assert(#env.calls == 1 and env.calls[1].prefix == "ForeignTest")
    env.directCTL.avail = 0
    ace.SendCommMessage(foreign, "ForeignTest", "queued-foreign", "WHISPER", "Other-Home")
    assert(env.directCTL.Prio.NORMAL.ByName.ForeignTest[1].f == env.nativeSend,
        "Foreign queue entries retain their original send function")
    finder:CancelDirectPresence()
    env:Pump()
    assert(#env.calls == 2 and env.calls[2].wire == "queued-foreign")

    local old, calls = ace.frame:GetScript("OnEvent"), 0
    ace.frame:SetScript("OnEvent", function(frame, event, prefix, ...)
        if prefix == "APRFindV1" then calls = calls + 1 end
        return old(frame, event, prefix, ...)
    end)
    assert(finder:InitializeDirectTransport(), "A library handler replacement can be guarded again")
    env.now = env.now + 1
    for _ = 1, 65 do env:Receive("APRFindV1", env:Reply()) end
    assert(calls == 64, "Receive budget is checked before entering the former AceComm handler")
    finder:StopDirectTransport()
    env:Receive("APRFindV1", "\001after-stop")
    assert(not next(ace.multipart_spool), "Prefix safety persists while native registration remains")
end

-- Shared discovery uses the same real-library prerequisites as this isolated suite.
local shared = dofile("tests/lua/party_finder_test_env.lua").New()
assert(shared.directCTL and shared.directAceComm and shared.finder.directReady)
print("Direct companion transport: real AceComm/CTL, bounded backlog, cancellation, native results and scoped multipart protection passed")
