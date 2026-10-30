-- Deterministic outdoor discovery environment; no guide catalogue or live network.
local Fixture = {}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

function Fixture.New(options)
    options = options or {}
    local env = {
        now = 100, timers = {}, sent = {}, joined = {}, left = {}, frames = {}, badges = {},
        map = 501, level = 17, class = 8, step = 3, faction = "Alliance", size = 0,
        channelID = options.prejoined and 7 or 0, options = options, soundEvents = {},
        instance = options.instance == true, restricted = options.restricted == true,
        outgoingRestricted = options.outgoingRestricted == true,
        channels = {}, population = options.population or 2, populationReads = 0,
    }
    local locale = setmetatable({ GROUP_STEPS_AHEAD = "%d ahead", GROUP_STEPS_BEHIND = "%d behind" },
        { __index = function(_, key) return key end })
    function LibStub()
        return { GetLocale = function() return locale end }
    end
    function GetTime() return env.now end
    function debugprofilestop() return 0 end
    function GetLocale() return options.locale or "frFR" end
    function GetNormalizedRealmName() return "Home" end
    function GetRealmName() return "Home" end
    function GetUnitName() return options.regional and "Local Surname" or "Local-Home" end
    function RegionalUniqueNamesEnabled() return options.regional == true end
    function UnitFactionGroup() return env.faction end
    function UnitLevel() return env.level end
    function UnitClass() return "Mage", "MAGE", env.class end
    function UnitIsGroupLeader() return env.leader ~= false end
    function UnitIsAFK() return env.afk == true end
    function UnitIsDND() return env.dnd == true end
    function GetNumGroupMembers() return env.size end
    function IsInGroup() return env.size > 0 end
    function IsInRaid() return false end
    function IsInInstance() return env.instance == true end
    function InCombatLockdown() return env.combat == true end
    function PlaySound(id, channel)
        env.soundEvents[#env.soundEvents + 1] = { id = id, channel = channel, at = env.now }
        return true
    end
    function PlaySoundFile(path, channel)
        env.soundEvents[#env.soundEvents + 1] = { path = path, channel = channel, at = env.now }
        return true
    end
    function hooksecurefunc() end
    function CreateFrame()
        local frame = { events = {}, scripts = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(key, callback) self.scripts[key] = callback end
        env.frames[#env.frames + 1] = frame
        return frame
    end
    Enum = { UIMapType = { Zone = 3 },
        GameRule = { HardcoreRuleset = 1, PvPRuleset = 2, RPRuleset = 3 },
        SendAddonMessageResult = { Success = 0, InvalidChatType = 4, InvalidChannel = 7,
            AddonMessageThrottle = 3, AddOnMessageLockdown = 11, TargetOffline = 12 } }
    C_Map = {
        GetBestMapForUnit = function() return env.map end,
        GetMapInfo = function(map) return { mapID = map, mapType = 3, parentMapID = 0 } end,
    }
    C_GameRules = { IsGameRuleActive = function(rule) return options.rules and options.rules[rule] or false end }
    C_PvP = { IsWarModeActive = function() return env.warMode == true end }
    C_PlayerInfo = { IsPlayerInChromieTime = function() return env.chromie == true end }
    C_Timer = { NewTimer = function(delay, callback)
        assert(type(delay) == "number" and delay >= 0, "Timers need a finite nonnegative delay")
        local timer = { at = env.now + delay, callback = callback,
            Cancel = function(self) self.cancelled = true end }
        env.timers[#env.timers + 1] = timer
        return timer
    end, NewTicker = function() error("Finder must use cancellable one-shot timers") end }
    function GetChannelName(name)
        if name == "APRVersion" then return 0 end
        assert(name == "APR", "Discovery must only use the stable shared rendezvous")
        if options.prejoined or options.prejoinedWorld then env.channels[name] = env.channelID > 0 and env.channelID or 7 end
        local id = env.channels[name]
        return id or 0, id and name or nil
    end
    function JoinTemporaryChannel(name)
        env.joined[#env.joined + 1] = name
        if options.joinError then error("Channel unavailable") end
        assert(name == "APR", "No per-zone or APRVersion channel may be joined")
        if not options.delayedJoin then env.channels[name], env.channelID = 7, 7 end
    end
    function LeaveChannelByName(name)
        env.left[#env.left + 1] = name
        if env.channels[name] == env.channelID then env.channelID = 0 end
        env.channels[name] = nil
    end
    GetNumDisplayChannels, GetChannelDisplayInfo = nil, nil
    if not options.noPopulationAPI then
        function GetNumDisplayChannels()
            env.populationReads = env.populationReads + 1
            return 3
        end
        function GetChannelDisplayInfo(index)
            if index == 1 then return "Synthetic header", true, false, 0, 0, true end
            if index == 2 then return "Existing channel", false, false, 1, 1, true end
            if index == 3 and env.channels.APR then return "APR", false, false, env.channels.APR, env.population, true end
        end
    end
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix) assert(prefix == "APRFindV1") end,
        InChatMessagingLockdown = function() return env.restricted == true end,
        AreOutgoingAddonChatMessagesRestricted = function() return env.outgoingRestricted == true end,
        SendAddonMessage = function(prefix, wire, channel, target)
            assert(prefix == "APRFindV1" and #wire <= 240)
            local packet = APR.PartyFinderProtocol.Decode(wire)
            assert(packet, "Outgoing messages must satisfy the real wire contract")
            local result = env.sendResult or 0
            if type(result) == "function" then result = result(channel, packet, target) end
            env.sent[#env.sent + 1] = { prefix = prefix, wire = wire, packet = packet,
                channel = channel, target = target, at = env.now, result = result }
            return result
        end,
    }
    ChatThrottleLib = options.throttle and { SendAddonMessage = function(_, priority, prefix, wire, channel, target, _, callback)
        assert(priority == "BULK")
        local result = C_ChatInfo.SendAddonMessage(prefix, wire, channel, target)
        if callback then callback(nil, result == 0) end
    end } or nil
    local definition = { label = "Invented route", steps = {} }
    for index = 1, 20 do
        definition.steps[index] = { PickUp = { 900000 + index }, Coord = { x = index, y = index + 1 } }
    end
    env.definition = definition
    APRData = { fixture = { synthetic = env.step } }
    APR = {
        PlayerID = "fixture", Username = "Local-Home", ActiveRoute = "synthetic", ClassId = 8,
        settings = { profile = { enableAddon = options.enabled ~= false } },
        NewModule = function() return {} end,
        GetGameVersion = function() return options.client or "retail" end,
        GetSettingsProfile = function(self) return self.settings.profile end,
        GetRouteData = function(_, route) return route == "synthetic" and env.definition or nil end,
        GetRouteDisplayName = function() return "Invented route" end,
        GetGroupRouteProgress = function(_, _, step) return { id = "main:" .. step, step = step, total = 20 } end,
        FinishPerformanceSample = function() end,
        RegisterSupportedEvent = function(_, frame, event) frame:RegisterEvent(event) end,
        currentStep = { RefreshPartyFinderButton = function(_, count) env.badges[#env.badges + 1] = count end },
        party = { SendGroupMessage = function() end },
    }
    local DirectEnv = dofile("tests/lua/party_finder_direct_test_env.lua")
    DirectEnv.Install(env)
    dofile("APR-Core/config/Config_GroupFinder.lua")
    APR.settings.profile.groupFinder = Copy(APR.GroupFinderDefaults)
    for key, value in pairs(options.settings or {}) do APR.settings.profile.groupFinder[key] = Copy(value) end
    dofile("APR-Core/features/group/PartyFinderProtocol.lua")
    dofile("APR-Core/features/group/PartyProtocol.lua")
    dofile("APR-Core/core/CommunicationChannel.lua")
    dofile("APR-Core/features/group/PartyFinder.lua")
    dofile("APR-Core/features/group/PartyFinderDirect.lua")
    dofile("APR-Core/features/group/PartyFinderWorld.lua")
    local finder = APR.partyFinder
    function finder:MaybeNotifyCandidate(candidate) env.lastCandidate = candidate end
    function finder:HandleInviteMessage() end
    function finder:OnNativeInvitation() end
    function finder:CloseIncomingInvitation() end
    function finder:CheckInvitationRoster() end
    function finder:HookInvitationDialogs() end
    env.finder = finder
    env.protocol = APR.PartyFinderProtocol

    function env:Advance(seconds)
        local limit, target = 0, self.now + seconds
        while true do
            local nextTimer
            for _, timer in ipairs(self.timers) do
                if not timer.cancelled and not timer.fired and timer.at <= target
                    and (not nextTimer or timer.at < nextTimer.at) then nextTimer = timer end
            end
            if not nextTimer then break end
            limit = limit + 1
            assert(limit <= 10000, "Timer scheduling must converge without an idle polling loop")
            local elapsed = nextTimer.at - self.now
            self.now, nextTimer.fired = nextTimer.at, true
            nextTimer.callback()
            self:PumpDirect(elapsed)
        end
        local elapsed = target - self.now
        self.now = target
        self:PumpDirect(elapsed)
    end
    function env:ActiveTimers()
        local count = 0
        for _, timer in ipairs(self.timers) do if not timer.cancelled and not timer.fired then count = count + 1 end end
        return count
    end
    function env:Messages(kind, channel)
        local result = {}
        for _, message in ipairs(self.sent) do
            if (not kind or message.packet.kind == kind) and (not channel or message.channel == channel)
                and message.result == 0 then result[#result + 1] = message end
        end
        return result
    end
    function env:Event(event, ...)
        local delivered = false
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, event, ...)
                delivered = true
            end
        end
        assert(delivered, "Expected event subscription")
    end
    function env:Query(overrides)
        local own = finder:GetLocalState()
        local packet = { id = "request-1", context = own.context, route = own.route, revision = own.revision,
            progressId = "main:3", step = 3, total = 20, mode = "nearby", range = 5,
            minLevel = 0, maxLevel = 0, primary = "fr", languages = 2 }
        for key, value in pairs(overrides or {}) do packet[key] = value end
        return packet
    end
    function env:Presence(overrides)
        local own = finder:GetLocalState()
        local packet = { id = finder.query and finder.query.id or "unrequested",
            context = finder.query and finder.query.mode == "world" and own.worldContext or own.context,
            route = own.route, revision = own.revision, progressId = "main:3", step = 3, total = 20,
            map = env.map, level = 18, class = 1, primary = "fr", languages = 2, groupSize = 0,
            leader = true, recruiting = false, afk = false, dnd = false, warMode = false, languageSource = "player" }
        for key, value in pairs(overrides or {}) do packet[key] = value end
        return packet
    end
    function env:Receive(kind, data, sender, channel, details)
        local wire = self.protocol.Encode(kind, data)
        assert(wire, "The test packet must be valid before exercising controller behavior")
        self:ReceiveWire(wire, sender, channel, details)
    end
    function env:ReceiveWire(wire, sender, channel, details)
        details = details or {}
        channel = channel or "CHANNEL"
        local frame = self.directAceComm.frame
        frame:GetScript("OnEvent")(frame, "CHAT_MSG_ADDON", details.prefix or "APRFindV1", wire, channel, sender or "Peer-Home")
        finder:HandleAddonMessage(details.prefix or "APRFindV1", wire, channel, sender or "Peer-Home",
            details.target or "Local-Home", 0,
            details.localID or (details.world and finder.worldChannelID or self.channelID),
            details.name or (details.world and finder.worldChannelName or finder.channelName))
    end
    function env:SetStep(step)
        self.step = step
        APRData.fixture.synthetic = step
        finder:QueueStateRefresh()
    end
    function env:LoadInvites()
        dofile("APR-Core/features/group/PartyFinderInvites.lua")
    end
    if options.invites then env:LoadInvites() end
    finder:OnInit()
    env:Advance(options.noSettle and 0 or 3)
    return env
end

return Fixture
