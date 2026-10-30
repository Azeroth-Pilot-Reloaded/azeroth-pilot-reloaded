-- Compose real discovery, invitations, progression codecs/UI, core group events
-- and temporary-route restoration. Only native APIs/widgets and the downstream
-- navigation/step renderer are simulated; no maintained guide is loaded.
local FinderFixture = dofile("tests/lua/party_finder_test_env.lua")

local function Setup(client)
    local ui = dofile("tests/lua/route_ui_test_env.lua")
    local uiAPR, uiCreateFrame, uiLibStub = APR, CreateFrame, LibStub
    local env = FinderFixture.New({ client = client, world = true, invites = true,
        settings = { matchMode = "world", notifications = false } })
    local finderLibStub = LibStub
    local finder, badge = env.finder, APR.currentStep.RefreshPartyFinderButton
    for key, value in pairs(uiAPR) do if APR[key] == nil then APR[key] = value end end
    for key, value in pairs(uiAPR.settings.profile) do
        if APR.settings.profile[key] == nil then APR.settings.profile[key] = value end
    end
    APR.currentStep = uiAPR.currentStep
    APR.currentStep.RefreshPartyFinderButton = badge
    APR.settings.profile.receiveGroupData, APR.settings.profile.showGroup = true, true
    APR.settings.profile.groupScale = 1
    APR.Username, APR.Faction = "Local", "Alliance"
    env.roster, env.partySent, env.invited, env.requested = {}, {}, {}, {}
    local setText = ui.methods.SetText
    function ui.methods:SetText(value) setText(self, value ~= nil and tostring(value) or "") end
    function CreateFrame(kind, name, parent, template)
        local frame = uiCreateFrame(kind, name, parent, template)
        if template == "ObjectiveTrackerContainerHeaderTemplate" then
            frame.Text, frame.MinimizeButton = ui.widget(frame), ui.widget(frame)
            frame.MinimizeButton:SetNormalTexture("")
            frame.MinimizeButton:SetPushedTexture("")
        end
        return frame
    end
    strmatch, tinsert, tremove = string.match, table.insert, table.remove
    LibStub = nil
    dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
    dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
    env.serializer = LibStub("AceSerializer-3.0")
    local locale = setmetatable({ ROUTE_LABEL = "Route %s", CURRENT_STEP_LABEL = "Step %s",
        GROUP_STEP_BEHIND = "%d behind", GROUP_STEPS_BEHIND = "%d behind",
        GROUP_STEP_AHEAD = "%d ahead", GROUP_STEPS_AHEAD = "%d ahead" },
        { __index = function(_, key) return key end })
    LibStub = function(name, silent)
        if name == "AceSerializer-3.0" then return env.serializer end
        if name == "AceLocale-3.0" then return { GetLocale = function() return locale end } end
        if name == "AceComm-3.0" or name == "CallbackHandler-1.0" then return finderLibStub(name, silent) end
        return uiLibStub(name, silent)
    end
    local sendFinder = C_ChatInfo.SendAddonMessage
    function C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
        if prefix == "APRFindV1" then return sendFinder(prefix, message, channel, target) end
        env.partySent[#env.partySent + 1] = { prefix = prefix, message = message, channel = channel, target = target }
        return 0
    end
    function C_Timer.NewTicker(interval, callback)
        local ticker = {}
        function ticker:Cancel()
            self.cancelled = true
            if self.timer then self.timer:Cancel() end
        end
        local function tick()
            if ticker.cancelled then return end
            callback(ticker)
            if not ticker.cancelled then ticker.timer = C_Timer.NewTimer(interval, tick) end
        end
        ticker.timer = C_Timer.NewTimer(interval, tick)
        return ticker
    end
    LE_PARTY_CATEGORY_INSTANCE = 2
    function IsInGroup(category)
        return env.size > 0 and (category ~= LE_PARTY_CATEGORY_INSTANCE or env.instanceGroup == true)
    end
    function IsInRaid() return env.raid == true end
    function IsInInstance() return env.instance == true, env.instanceType or "none" end
    function UnitName(unit)
        if unit == "player" then return "Local", "Home" end
        return unpack(env.roster[unit] or {})
    end
    function GetUnitName(unit)
        local name, realm = UnitName(unit)
        return name and (name .. "-" .. (realm or "Home"))
    end
    function APR:SafeUnitName(unit) return UnitName(unit) end
    function APR:IsPetBattleActive() return false end
    function APR:StartPerformanceSample() return 0 end
    function APR:SetPanelColor() end
    function APR:GetMapInfoCached(map) return C_Map.GetMapInfo(map) end
    function C_Map.GetMapInfo(map) return { mapID = map, name = "Synthetic interior", mapType = 3, parentMapID = 0 } end
    C_ScenarioInfo = {
        GetScenarioInfo = function() return env.scenarioID and { scenarioID = env.scenarioID } end,
        GetScenarioStepInfo = function() return env.scenarioID and { stepID = 9001 } end,
    }
    -- Forever has no native delve namespace. Synthetic declarations still cover
    -- engine restoration there without asserting that the client offers delves.
    C_DelvesUI = client == "retail" and { HasActiveDelve = function() return env.delve == true end } or nil
    C_PartyInfo = {
        CanInvite = function() return true end,
        InviteUnit = function(name) env.invited[#env.invited + 1] = name end,
        RequestInviteFromUnit = function(name) env.requested[#env.requested + 1] = name end,
    }
    APR.navigation = { ForceRefresh = function() env.navigationRefreshes = (env.navigationRefreshes or 0) + 1 end,
        RequestRouteCheck = function() end }
    APR.versionCheck = { ScheduleBroadcast = function() end }
    dofile("APR-Core/data/models/Enums.lua")
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/RouteUtils.lua")
    dofile("APR-Core/utils/SojournerUtils.lua")
    dofile("APR-Core/utils/SharedMedia.lua")
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/questing/RouteManager.lua")
    dofile("APR-Core/features/questing/DelveRoutes.lua")
    APR.RouteQuestStepList = { synthetic = env.definition,
        scenario = { label = "Invented scenario", temporary = true,
            steps = { { Note = "First scenario objective" }, { Note = "Last scenario objective" } } },
        delve = { label = "Invented delve", delve = {}, scenarios = {
            { scenarioID = 7001, steps = { { Note = "Delve objective" }, { Note = "Delve exit" } } },
        } },
    }
    env.definition.steps[5] = { DoScenario = { mapID = 603 } }
    APR.ScenarioEntrances = { [603] = { type = "DELVE" } }
    APRCustomPath = { fixture = { env.definition.label } }
    APRZoneCompleted = { fixture = {} }
    -- Rendering/navigation are sinks outside this journey; snapshots read real
    -- CurrentStep:GetCurrentStepDetails and real filtered route totals instead.
    function APR:UpdateStep() self.currentStep.progressBar = nil end
    APR:GetTotalSteps("synthetic")
    dofile("APR-Core/features/group/Party.lua")
    dofile("APR-Core/core/Event.lua")
    env.party = APR.party
    function hooksecurefunc(owner, method, callback)
        local original = owner[method]
        owner[method] = function(...)
            local result = { original(...) }
            callback(...)
            return unpack(result)
        end
    end
    finder.progressHooked = nil
    finder:OnInit()
    env:Advance(0.5)

    function env:GroupEvent(event)
        APR.event.functions.group(event)
        if event == "GROUP_ROSTER_UPDATE" then self:Event(event) end
    end
    function env:FinderPacket(kind, data, sender, channel, world)
        local wire = assert(self.protocol.Encode(kind, data))
        self:Event("CHAT_MSG_ADDON", "APRFindV1", wire, channel or "WHISPER", sender or "Peer-Home",
            "Local-Home", 0, world and finder.worldChannelID or finder.channelID,
            world and finder.worldChannelName or finder.channelName)
    end
    function env:PeerSnapshot(sender, payload, channel)
        local first = #self.partySent + 1
        APR:SendAddonMessageSplit("APRPartyData", self.serializer:Serialize(payload), channel or "PARTY")
        for index = #self.partySent, first, -1 do
            local fragment = self.partySent[index]
            APR.event.functions.party("CHAT_MSG_ADDON", fragment.prefix, fragment.message, fragment.channel, sender)
        end
    end
    function env:Enter(map, kind, raid, instanceGroup)
        self.map, self.instance, self.instanceType = map, true, kind
        self.raid, self.instanceGroup = raid == true, instanceGroup == true
        self:GroupEvent("GROUP_ROSTER_UPDATE")
        self:Event("PLAYER_ENTERING_WORLD", false, false)
        self:Advance(0.5)
    end
    return env, finder, APR.party
end

local function Journey(client)
    local env, finder, party = Setup(client)
    local ace, minor = LibStub("AceComm-3.0")
    assert(ace == env.directAceComm and minor == 14 and finder.directReady,
        "The composed journey retains the real embedded direct transport")
    assert(finder.channelID == 7 and finder.worldChannelID == 7 and #env.joined == 1)
    assert(finder:Search())
    local query = finder.query
    local presence = env:Presence({ map = 599 })
    env:FinderPacket("P", presence, "Peer-Home", "CHANNEL", true)
    assert(finder:GetCount() == 0, "Discovery never accepts public presence packets")
    env:FinderPacket("P", presence)
    local candidate = assert(finder:GetCandidates()[1])
    assert(candidate.map == 599 and finder:GetCount() == 1 and #env.invited == 0)
    assert(finder:Invite(candidate.key) and #env.invited == 1 and env.invited[1] == "Peer-Home")
    env.size, env.roster.party1 = 2, { "Peer", "Home" }
    env:GroupEvent("GROUP_JOINED")
    env:GroupEvent("GROUP_ROSTER_UPDATE")
    env:Advance(2)
    assert(candidate.status == "joined" and party.GroupListSteps.Local.currentStep == 3)
    assert(finder:GetLocalState().groupSize == 2 and PartyScreenPanel:IsShown())
    local peer = party:BuildGroupPayload("Peer")
    peer.stepFrameDetails.questSteps = { { text = "Une étape |Hquest:100|h[française]|h",
        subSteps = { { text = "2/4 objets" } } } }
    env:PeerSnapshot("Peer-Home", peer)
    assert(party.GroupListSteps.Peer.routeProgress.id == "main:3")
    assert(party.GroupListSteps.Peer.stepFrameDetails.questSteps[1].text == "Une étape [française]")
    assert(party.GroupListSteps.Peer.stepFrameDetails.questSteps[1].subSteps[1].text == "2/4 objets")
    env:PeerSnapshot("Peer-OtherRealm", peer)
    assert(not party.GroupListSteps["Peer-OtherRealm"], "A matching character name cannot bypass roster membership")

    -- Queue a real private response, then enter an instance before its timer.
    env:Advance(5)
    env:FinderPacket("Q", env:Query({ id = "pending-zone-query" }), "Waiting-Home", "CHANNEL")
    assert(next(finder.responses) and finder.replyTimer)
    local replies = #env:Messages("P", "WHISPER")
    env:Enter(601, "party", false, false)
    assert(finder:GetStatus() == "instance" and finder.channelID == 7 and finder.worldChannelID == 7)
    assert(env.channels.APR == 7 and #env.joined == 1 and #env.left == 0,
        "Instance entry retains the shared membership while suspending discovery")
    assert(not finder.query and not next(finder.responses) and not finder.replyTimer and not finder.queryTimer)
    env:Advance(12)
    assert(#env:Messages("P", "WHISPER") == replies, "Entering an instance cancels queued discovery replies")
    env:FinderPacket("P", presence)
    assert(finder:GetCount() == 0, "A late private reply cannot revive the cancelled outdoor query")
    assert(not finder:Search())
    assert(APR:TransitionStep(4, "journey", false))
    party:SendGroupMessage(true)
    assert(env.partySent[#env.partySent].channel == "PARTY", "Premade groups retain their native party channel inside")
    assert(party.GroupListSteps.Local.currentStep == 4 and PartyScreenPanel:IsShown())
    env.instanceGroup = true
    APR:TransitionStep(5, "journey", false)
    env:Advance(2)
    party:SendGroupMessage(true)
    assert(env.partySent[#env.partySent].channel == "INSTANCE_CHAT")
    env:PeerSnapshot("Peer-Home", peer, "INSTANCE_CHAT")
    assert(party.GroupListSteps.Peer.currentStep == 3, "Authenticated party progression still arrives in instance groups")

    -- A scenario temporarily replaces the current route, then restores the same
    -- parent progress and custom path before the delve insertion case.
    env.scenarioID = 7000
    env:Enter(602, "scenario", false, true)
    local customPath = APRCustomPath.fixture
    assert(APR:ActivateTemporaryRoute("scenario", { kind = "scenario", mapID = 602, sessionKey = "scenario:7000" }))
    env:Advance(2)
    party:SendGroupMessage(true)
    assert(APR.ActiveRoute == "scenario" and party.GroupListSteps.Local.routeFileName == "scenario")
    assert(party.GroupListSteps.Local.routeProgress.id == "main:1" and party.GroupListSteps.Local.totalSteps == 2)
    assert(finder:GetLocalState().route == env.protocol.Hash("scenario") and finder:GetLocalState().step == 1,
        "The real party-send hook refreshes companion state after a route switch")
    assert(APR:TransitionStep(2, "journey", false))
    assert(APR:ClearTemporaryRoute({ completed = true }))
    assert(APR.ActiveRoute == "synthetic" and APRData.fixture.synthetic == 5 and APRCustomPath.fixture == customPath)
    assert(not APRData.fixture.TemporaryRouteState)

    APR:TransitionStep(3, "journey", false)
    env.delve, env.scenarioID = true, 7001
    env:Enter(603, "scenario", false, false)
    local context = assert(APR:GetCurrentDelveContext())
    assert(context.mapID == 603 and context.scenarioID == 7001 and context.sessionKey == "scenario:7001")
    assert(APR:ActivateTemporaryRoute("delve", { kind = "delve", mapID = context.mapID,
        scenarioID = context.scenarioID, sessionKey = context.sessionKey }))
    local state = APRData.fixture.TemporaryRouteState
    assert(state.previousRouteKey == "synthetic" and state.parentStartIndex == 3 and state.replaceStepIndex == 5)
    local steps = APR:GetRouteSteps("delve")
    assert(#steps == 4 and steps[1] == env.definition.steps[3] and steps[3].Note == "Delve objective")
    if client == "retail" then
        env.map = nil
        APR:RefreshTemporaryDelveRoute()
        assert(APR.ActiveRoute == "delve" and APRData.fixture.TemporaryRouteState == state,
            "A loading screen with an active native delve retains the temporary session")
        env.map = 603
    end
    env.map, env.scenarioID, env.delve = 602, 7000, false
    APR:ScheduleDelveRouteRefresh(0.25)
    env:Advance(0.5)
    assert(APR.ActiveRoute == "synthetic" and APRData.fixture.synthetic == 3 and not APRData.fixture.TemporaryRouteState,
        "Abandoning a delve before its parent prefix advances restores the original parent position")
    env.map, env.scenarioID, env.delve = 603, 7001, true
    assert(APR:ActivateTemporaryRoute("delve", { kind = "delve", mapID = 603,
        scenarioID = 7001, sessionKey = "scenario:7001" }))
    assert(APR:TransitionStep(3, "journey", false))
    -- Simulate active-route reconstruction while character SavedVariables retain
    -- the temporary session; the real lifecycle must resume without resetting.
    APR:ActivateRoute("synthetic", "fixture_route_reconstruction")
    APR:RefreshTemporaryDelveRoute()
    assert(APR.ActiveRoute == "delve" and APRData.fixture.delve == 3)
    env:Advance(2)
    party:SendGroupMessage(true)
    -- The real CTL queue applies its post-zone bandwidth limit, then drains the
    -- previous snapshot before the latest coalesced route state can be sent.
    env:Advance(4)
    assert(not party.groupSendInFlight and not party.pendingGroupSend)
    assert(party.GroupListSteps.Local.routeFileName == "delve" and party.GroupListSteps.Local.currentStep == 3)
    assert(party.GroupListSteps.Local.routeProgress.id == "main:1" and party.GroupListSteps.Local.routeProgress.total == 2,
        "Party wire identities exclude the temporary parent prefix")
    assert(finder:GetCount() == 0 and not finder:Search())
    APRData.fixture.TemporaryRouteState.scenarioCompleted = true
    env.map, env.scenarioID, env.delve = 601, nil, false
    APR:ScheduleDelveRouteRefresh(0.25)
    env:Advance(0.5)
    assert(APR.ActiveRoute == "synthetic" and APRData.fixture.synthetic == 6,
        "Completing the temporary delve skips exactly its replaced parent action")
    assert(APRCustomPath.fixture == customPath and #customPath == 1)

    -- Raid conversion tears down progress and partial fragments, while leaving
    -- finder discovery off throughout the native raid interior.
    env:Event("CHAT_MSG_ADDON", "APRPartyData", "unfinished|1|2|partial", "PARTY", "Peer-Home")
    APR.event.functions.party("CHAT_MSG_ADDON", "APRPartyData", "unfinished|1|2|partial", "PARTY", "Peer-Home")
    assert(next(party.incomingFragments) and party.fragmentCleanupTicker)
    env.size, env.roster = 10, { raid1 = { "Local", "Home" }, raid2 = { "Peer", "Home" } }
    env:Enter(604, "raid", true, true)
    assert(not next(party.GroupListSteps) and not next(party.teamList) and not PartyScreenPanel:IsShown())
    assert(not next(party.incomingFragments) and not party.fragmentCleanupTicker)
    local beforeRaidSend = #env.partySent
    party:SendGroupMessage(true)
    assert(#env.partySent == beforeRaidSend, "Raids do not broadcast progression")
    env:PeerSnapshot("Peer-Home", peer, "RAID")
    assert(not next(party.GroupListSteps))

    env.delve, env.scenarioID = false, nil
    env.map, env.instance, env.instanceType = 599, false, "none"
    env.size, env.raid, env.instanceGroup = 2, false, false
    env.roster = { party1 = { "Peer", "Home" } }
    env:GroupEvent("GROUP_ROSTER_UPDATE")
    env:Event("PLAYER_ENTERING_WORLD", false, false)
    env:Advance(65)
    assert(finder.channelID == 7 and finder.worldChannelID == 7 and finder:GetStatus() == "ready")
    assert(#env.joined == 1 and #env.left == 0, "Returning outdoors reuses the same shared membership")
    assert(not APR:GetCurrentDelveContext() and APR.ActiveRoute == "synthetic" and APRData.fixture.synthetic == 6)
    party:SendGroupMessage(true)
    assert(party.GroupListSteps.Local.currentStep == 6 and PartyScreenPanel:IsShown())
    assert(finder:Search() and finder.query.id ~= query.id)
    env:FinderPacket("P", presence)
    assert(finder:GetCount() == 0, "The old outdoor nonce remains stale after returning")
    env:FinderPacket("P", env:Presence({ progressId = "main:6", step = 6 }), "NewPeer-Home")
    assert(finder:GetCount() == 1)

    env.size, env.roster = 0, {}
    env:GroupEvent("GROUP_LEFT")
    env:GroupEvent("GROUP_ROSTER_UPDATE")
    env:Advance(2)
    assert(not next(party.GroupListSteps) and not next(party.teamList) and not PartyScreenPanel:IsShown())
    assert(finder:GetLocalState().groupSize == 0)
    env:PeerSnapshot("Peer-Home", peer)
    assert(not next(party.GroupListSteps), "Former members cannot populate a departed party")
    finder:GetSettings().enabled = false
    finder:RefreshSettings()
    env:Advance(2)
    assert(not next(env.channels) and not next(finder.eventFrame.events) and env:ActiveTimers() == 0)
    finder:GetSettings().enabled = true
    finder:RefreshSettings()
    env:Advance(2)
    assert(finder.channelID == 7 and finder.worldChannelID == 7 and finder.eventFrame.events.CHAT_MSG_ADDON)
    finder:OnDisable()
    env:Advance(2)
    assert(env:ActiveTimers() == 0 and not next(env.channels))
end

Journey("retail")
Journey("forever")
print("Group journeys: private/world discovery, real invites/wire/UI, party/instance/scenario/delve/raid transitions and restoration passed")
