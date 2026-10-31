-- Composition, not a native timing benchmark. All four owners run unchanged:
-- QuestCache + CurrentStep rows, Navigation/controller/library, Party snapshot
-- serialization, Event bank debounce + LootUtils bank scan.
--
-- One 60 FPS scheduler: zero-delay timers always run on a later frame. Its CPU
-- clock is independent of wall time and charges selected native boundaries:
-- quest APIs, bank slot/contents APIs and font writes cost 0.01 / 0.02 ms;
-- party font reads share that unit cost; native navigation action probes cost
-- 0.25 ms, matching navigation_catalog_action_budget_test. Clock probes cost
-- 0.001 ms. These are explicit sensitivity profiles, not measured WoW costs.
-- Uncharged Lua/serialization/layout work means these are partial CPU models.
-- A reported >16.67 ms frame is evidence that local bounds do not compose into
-- a global bound under that profile, not a claim about native frame duration.
local FRAME_MS, QUESTS, OBJECTIVES, BANK_SLOTS = 1000 / 60, 50, 3, 280
local noop = function() end
local function point(x)
    return { space = "world", instanceID = 7, uiMapID = 51002, x = x, y = 50 }
end

local function fixture(unitCost)
    local navFixture = dofile("tests/lua/navigation_fixture.lua")
    navFixture.currentMap, navFixture.player = 51002, point(100)
    navFixture.maps = {
        [51000] = { mapID = 51000, parentMapID = 0, mapType = 0 },
        [51001] = { mapID = 51001, parentMapID = 51000, mapType = 2 },
        [51002] = { mapID = 51002, parentMapID = 51001, mapType = 3 },
    }
    navFixture.translations = setmetatable({}, { __index = function(_, key) return key end })
    local alternatives = {}
    for i = 1, 500 do alternatives[i] = { type = "spell", id = 880000 + i } end
    navFixture.spells[880500] = true
    local data = navFixture:Load({ config = { IsolatedAreas = {} }, connections = {
        { id = "invented-shortcut", kind = "spell", seconds = 2,
            from = { dynamic = "player" }, to = point(1490), actions = alternatives },
    } })
    local navigationAPR, actualLibStub = APR, LibStub
    local env = dofile("tests/lua/route_ui_test_env.lua")
    for key, value in pairs(navigationAPR) do APR[key] = value end
    local uiLibStub, createFrame = LibStub, CreateFrame
    LibStub = actualLibStub
    dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
    local serializer = actualLibStub("AceSerializer-3.0")
    function LibStub(name, ...)
        if name == "AceSerializer-3.0" or name == "LibAPRNavigation-1.0" then
            return actualLibStub(name, ...)
        end
        if name == "AceLocale-3.0" then return { GetLocale = function() return navFixture.translations end } end
        return uiLibStub(name, ...)
    end
    function CreateFrame(kind, name, parent, template)
        local frame = createFrame(kind, name, parent, template)
        if template == "ObjectiveTrackerContainerHeaderTemplate" then
            frame.Text, frame.MinimizeButton = env.widget(frame), env.widget(frame)
        end
        return frame
    end
    local s = { frame = 0, wall = 0, cpu = 0, timers = {}, ledger = {}, enabled = false,
        owner = "setup", queries = 0, journalRefreshes = 0, bankReads = 0, partyReads = 0, actionReads = 0,
        renders = 0, sends = {}, paints = {}, unitCost = unitCost }
    function s:charge(kind, units, cost)
        if not self.enabled then return end
        local frame = self.ledger[self.frame]
        if not frame then frame = { cpu = 0, owners = {}, counts = {} }; self.ledger[self.frame] = frame end
        local spent = (units or 1) * (cost or unitCost)
        self.cpu, frame.cpu = self.cpu + spent, frame.cpu + spent
        frame.owners[self.owner] = (frame.owners[self.owner] or 0) + spent
        frame.counts[kind] = (frame.counts[kind] or 0) + (units or 1)
    end
    function s:as(owner, callback)
        local previous = self.owner
        self.owner = owner
        local ok, message = pcall(callback)
        self.owner = previous
        assert(ok, message)
    end
    function GetTime() return 10 + s.wall / 1000 end
    function debugprofilestop() s:charge("clock", 1, 0.001); return s.cpu end
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { callback = callback, owner = s.owner,
            due = math.max(s.frame + 1, math.ceil((s.wall + delay * 1000) / FRAME_MS - 0.000001)),
            Cancel = function(self) self.cancelled = true end }
        s.timers[#s.timers + 1] = timer
        return timer
    end }
    C_Timer.After = function(delay, callback) C_Timer.NewTimer(delay, callback) end
    function s:frameOnce()
        self.frame, self.wall = self.frame + 1, (self.frame + 1) * FRAME_MS
        local commit = self.commit
        if commit and commit.frame < self.frame and APR:IsStepContextCurrent(commit.context) then
            self.paints[#self.paints + 1] = { frame = self.frame, context = commit.context, revision = commit.revision }
            self.firstPaint = self.firstPaint or self.paints[#self.paints]
        end
        local pending = self.timers; self.timers = {}
        for _, timer in ipairs(pending) do
            if not timer.cancelled then
                if timer.due <= self.frame then self:as(timer.owner, timer.callback)
                else self.timers[#self.timers + 1] = timer end
            end
        end
    end
    function s:untilFrame(frame) while self.frame < frame do self:frameOnce() end end
    function s:drain()
        local deadline = self.frame + 2000
        while #self.timers > 0 do assert(self.frame < deadline, "Composed jobs must terminate"); self:frameOnce() end
    end
    function UnitIsDeadOrGhost() return false end
    function IsFlyableArea() return false end
    function IsFlying() return false end
    function IsMounted() return false end
    function GetUnitSpeed() return 0, 10, 0 end
    function GetMoney() return 100 end
    function GetBindLocation() return nil end
    LE_PARTY_CATEGORY_INSTANCE = 1
    function IsInGroup(category) return category == nil end
    function IsInRaid() return false end
    function GetNormalizedRealmName() return "Home" end
    APR.Username, APR.PlayerID, APR.ActiveRoute = "Local", "player", "invented-composition"
    APR.settings.profile.enableAddon, APR.settings.profile.sojournerSkipCampaign = true, true
    APR.QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" }
    APRData = { player = { [APR.ActiveRoute] = 2, [APR.ActiveRoute .. "-TotalSteps"] = 3 } }
    local step = { Zone = 51002, Coord = { x = 50, y = 1500, instanceID = 7 }, Qpart = {} }
    APR.RouteQuestStepList = { [APR.ActiveRoute] = { steps = { {}, step, {} } } }
    function APR:GetCurrentStep()
        local index = APRData[self.PlayerID][self.ActiveRoute]
        local steps = self.RouteQuestStepList[self.ActiveRoute].steps
        return steps[index], index, steps
    end
    function APR:PeekCurrentStep() return self:GetCurrentStep() end
    function APR:GetStep(index) return self.RouteQuestStepList[self.ActiveRoute].steps[index] end
    function APR:GetRouteDisplayName() return "Invented composition" end
    function APR:GetCurrentRouteMapIDsAndName() return { 51002 }, 51002 end
    function APR:GetStepCoord(value) return value.Coord, value.Zone end
    function APR:GetPreferredStepZone(value) return value.Zone end
    function APR:GetNavigationPlayerPosition() return point(100) end
    function APR:GetGroupRouteProgress(route, index)
        return { id = "main:" .. index, step = index, total = 3 }
    end
    function APR:StepUsesAnyOption(value, keys)
        for _, key in ipairs(keys) do if value and value[key] ~= nil then return true end end
        return false
    end
    APR.Debug, APR.ResetQuestTitleRequests = noop, noop
    APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop
    APR.UpdateQpartPart, APR.SendMessage = noop, noop
    APR.npcInteraction, APR.Arrow = { Clear = noop }, {}
    APR.fillersFrame.UpdateFillerStep = noop -- No filler declarations in this controlled route.
    APR.fillersFrame.ReOrderFillerSteps = noop
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/NavigationZones.lua")
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/NavigationTaxi.lua")
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    dofile("APR-Core/features/navigation/Navigation.lua")
    dofile("APR-Core/features/group/PartyProtocol.lua")
    dofile("APR-Core/features/group/Party.lua")
    dofile("APR-Core/utils/LootUtils.lua")
    dofile("APR-Core/features/questing/QuestCache.lua")
    dofile("APR-Core/core/Event.lua")
    local objectives, revision = {}, 0
    for id = 1, QUESTS do
        step.Qpart[id], objectives[id] = { 1, 2, 3 }, {}
        for index = 1, OBJECTIVES do objectives[id][index] = { text = "q" .. id .. ":0", finished = false } end
    end
    APR.ActiveQuests = {}
    local function questRead() s.queries = s.queries + 1; s:charge("quest") end
    C_QuestLog.GetNumQuestLogEntries = function()
        s.journalRefreshes = s.journalRefreshes + 1; questRead(); return QUESTS
    end
    C_QuestLog.GetInfo = function(index) questRead(); return { questID = index } end
    C_QuestLog.IsComplete = function() questRead(); return false end
    C_QuestLog.GetNumQuestObjectives = function() questRead(); return OBJECTIVES end
    C_QuestLog.GetQuestObjectives = function(id) questRead(); return objectives[id] end
    C_QuestLog.GetTitleForQuestID = function(id) return "Quest " .. id end
    C_QuestLog.IsQuestFlaggedCompleted = function() return false end
    local bankContents = {}
    NUM_BAG_SLOTS, NUM_BANKBAGSLOTS = 4, 7
    C_Container = {
        GetContainerNumSlots = function(bag)
            s:charge("bankSlots")
            return bag == -1 and 28 or (bag >= 5 and bag <= 11 and 36 or 0)
        end,
        GetContainerItemInfo = function(bag, slot)
            s.bankReads = s.bankReads + 1; s:charge("bank")
            return bankContents[bag] and bankContents[bag][slot]
        end,
    }
    for _, bag in ipairs({ -1, 5, 6, 7, 8, 9, 10, 11 }) do
        bankContents[bag] = {}
        for slot = 1, (bag == -1 and 28 or 36) do
            bankContents[bag][slot] = { itemID = slot % 2 == 0 and 770002 or 770001, stackCount = 1 }
        end
    end
    local originalSetText, originalGetText = env.methods.SetText, env.methods.GetText
    function env.methods:SetText(text)
        s:charge("fontWrite")
        return originalSetText(self, text)
    end
    function env.methods:GetText()
        if s.owner == "party" then s.partyReads = s.partyReads + 1; s:charge("party") end
        return originalGetText(self)
    end
    local actionUsability = APR.GetRouteActionUsability
    function APR:GetRouteActionUsability(kind, id)
        s.actionReads = s.actionReads + 1; s:charge("navigationAction", 1, 0.25)
        return actionUsability(self, kind, id)
    end
    data.env.getActionCastSeconds = function() return 2 end
    local function recordCommit()
        if s.rendered and APR:IsStepContextCurrent(s.rendered) and APR.navigation.state == "ready"
            and APR.Arrow.Active and APR.IsInRouteZone then
            s.commit = { frame = s.frame, context = s.rendered, revision = revision }
        end
    end
    function APR:UpdateStep()
        s.renders = s.renders + 1
        local rows = self.currentStep
        rows:BeginContentUpdate()
        for id = 1, QUESTS do for index = 1, OBJECTIVES do
            rows:AddQuestSteps(id, self.ActiveQuests[id].objectives[index].text, index)
        end end
        rows:EndContentUpdate(true)
        rows.progressBar = { key = self.ActiveRoute, currentStep = APRData.player[self.ActiveRoute] - 1 }
        s.rendered = self:CaptureStepContext()
        recordCommit()
    end
    function APR.Arrow:SetArrowActive(active) self.Active = active end
    function APR.Arrow:SetCoord()
        local guidance = APR.navigation:GetActiveStep()
        local coord = guidance and guidance.Coord or (APR.IsInRouteZone and select(1, APR:GetCurrentStep()).Coord)
        self.Active = coord ~= nil
        if coord then self.x, self.y = coord.x, coord.y end
        recordCommit()
    end
    APR.Arrow.UpdateActionText = noop
    function APR:SendAddonMessageSplit(prefix, wire, channel, target, callback)
        assert(prefix == "APRPartyData" and channel == "PARTY" and target == nil)
        s.sends[#s.sends + 1] = { wire = wire, frame = s.frame }; callback(true)
    end
    APR:UpdateQuest(true); APR:UpdateStep()
    APR.routeBankOpen = true; APR:SaveBankItemCounts()
    APR.party.GroupListSteps.Local = APR.party:BuildGroupPayload()
    s.queries, s.journalRefreshes, s.bankReads, s.partyReads, s.actionReads = 0, 0, 0, 0, 0
    s.enabled = true
    s:as("navigation", function() APR.navigation:Update() end)
    assert(APR.navigation.state == "ready" and APR.navigation.search and s.actionReads < 500,
        "A useful direct baseline must precede catalogue completion")
    for id = 1, QUESTS do for index = 1, OBJECTIVES do objectives[id][index].text = "q" .. id .. ":1" end end
    revision = 1
    s:as("quest", function() for _ = 1, 100 do APR.event:DebouncedUpdateQuest(0.5) end end)
    s:as("party", function() for _ = 1, 100 do APR.party:SendGroupMessage() end end)
    s:as("bank", function() C_Timer.NewTimer(27 * FRAME_MS / 1000, function()
        bankContents[-1][1] = { itemID = 770003, stackCount = 9 }
        for _ = 1, 1000 do APR.event.functions.bank("PLAYERBANKSLOTS_CHANGED"); APR.event:QueueBankRefresh() end
        s.queuedBankTimer = APR.event.bankRefreshTimer
    end) end)
    s.env, s.data, s.objectives, s.serializer, s.bankContents = env, data, objectives, serializer, bankContents
    return s
end

local reports = {}
for _, unitCost in ipairs({ 0.01, 0.02 }) do
    local s = fixture(unitCost)
    s:untilFrame(31)
    assert(s.firstPaint and s.firstPaint.frame == 1 and s.firstPaint.context.route == "invented-composition"
        and s.firstPaint.context.index == 2, "Useful guidance must paint before the overlapping dense refresh")
    assert(s.paints[#s.paints].revision == 1 and s.paints[#s.paints].frame == 31,
        "The updated objective content paints on the next frame, never in its callback frame")
    for id = 1, QUESTS do for index = 1, OBJECTIVES do
        assert(APR.ActiveQuests[id].objectives[index].text == "q" .. id .. ":1")
        assert(APR.currentStep.questsList[id .. "-" .. index].objectiveText == "q" .. id .. ":1")
    end end
    assert(s.journalRefreshes == 1 and s.queries <= 1 + QUESTS * 4 + 3 * QUESTS * OBJECTIVES
        and s.bankReads == BANK_SLOTS,
        "Dense event bursts cause one complete quest refresh and one bank scan")
    assert(APRData.player.BankItems[770001] == 139 and APRData.player.BankItems[770002] == 140
        and APRData.player.BankItems[770003] == 9 and not APR.event.bankRefreshTimer)
    assert(#s.sends == 1 and s.sends[1].frame == 30 and s.partyReads <= 129)
    local ok, received = s.serializer:Deserialize(s.sends[1].wire)
    assert(ok and #s.sends[1].wire <= 2048 and received.currentStep == 1 and received.totalSteps == 3
        and received.routeProgress.id == "main:2" and received.sojournerSkipCampaign
        and #received.stepFrameDetails.questSteps == 0,
        "The bounded party snapshot preserves exact progress and drops the whole oversized tooltip")
    local overlap = assert(s.ledger[30])
    for _, owner in ipairs({ "quest", "navigation", "party", "bank" }) do
        assert((overlap.owners[owner] or 0) > 0, "All four real owners must spend work in the same frame")
    end
    -- Existing bounds add, rather than each owning an independent frame:
    -- 201 cache queries + <=300 progress queries (150 refreshed rows and 150
    -- rendered rows) + <=150 font writes, 129 party reads, 280 bank items
    -- +9 bag-size queries, and a 1 ms navigation slice with one action-probe
    -- overshoot (0.25 ms) and measured clock-probe overhead outside the slice.
    assert(overlap.counts.quest <= 501 and overlap.counts.bank == 280 and overlap.counts.bankSlots == 9)
    assert((overlap.counts.fontWrite or 0) <= 150 and (overlap.counts.party or 0) <= 129)
    local additiveBound = (501 + 150 + 129 + 280 + 9) * unitCost + 1.25
        + (overlap.counts.clock or 0) * 0.001
    assert(overlap.cpu <= additiveBound + 0.000001, "The common frame must respect the sum of current local bounds")
    s:drain()
    assert(APR.navigation:IsNavigating() and not APR.navigation.search
        and APR.navigation:GetActiveStep().kind == "spell" and APR.navigation:GetActiveStep().action.data == 880500
        and APRData.player[APR.ActiveRoute] == 2 and not APR.party.groupSendTimer)
    -- Public cancellations are exercised with the same scheduler, including a
    -- manually delivered stale native timer after close/context replacement.
    s:as("bank", function() APR.event:QueueBankRefresh() end)
    local staleBank = APR.event.bankRefreshTimer
    s.bankContents[-1][1] = nil
    s:as("bank", function() APR.event.functions.bank("BANKFRAME_CLOSED") end)
    local reads = s.bankReads
    assert(staleBank.cancelled and APRData.player.BankItems[770003] == nil)
    staleBank.callback()
    assert(s.bankReads == reads and not APR.event.bankRefreshTimer)
    s:as("party", function() APR.party:SendGroupMessage() end)
    local staleParty, sends = APR.party.groupSendTimer, #s.sends
    APR.party:CancelGroupSend()
    assert(staleParty.cancelled)
    staleParty.callback()
    assert(#s.sends == sends)
    s:as("navigation", function() APR.navigation:ForceRefresh(); APR.navigation:Update() end)
    local obsolete, obsoleteTimer, probes = APR.navigation.search, APR.navigation._searchTimer, s.actionReads
    local paints = #s.paints
    APRData.player[APR.ActiveRoute] = 3
    APR.navigation:Cancel("context_changed")
    if obsoleteTimer then obsoleteTimer.callback() end
    assert(obsolete.status == "cancelled" and s.actionReads == probes and not APR.navigation.search)
    s:drain()
    assert(#s.sends == sends and APRData.player[APR.ActiveRoute] == 3 and #s.paints == paints,
        "Cancelled group/native/navigation callbacks cannot publish an obsolete route state")
    local maximum, peakFrame = 0, 0
    for frame, entry in pairs(s.ledger) do if entry.cpu > maximum then maximum, peakFrame = entry.cpu, frame end end
    reports[#reports + 1] = { unitCostMs = unitCost, peakFrame = peakFrame, peakMs = maximum,
        frameBudgetMs = FRAME_MS, modelSpike = maximum > FRAME_MS, additiveBoundMs = additiveBound,
        firstUsefulPaintFrame = s.firstPaint.frame, firstUsefulPaintMs = s.firstPaint.frame * FRAME_MS,
        overlapOwners = overlap.owners, overlapCounts = overlap.counts }
    print(string.format("Composed budget %.0f us: frame %d peak %.3f ms / %.3f ms at 60 FPS (%s); " ..
        "frame30 additive bound %.3f ms; first useful paint %d; all cancellations passed",
        unitCost * 1000, peakFrame, maximum, FRAME_MS, maximum > FRAME_MS and "MODEL SPIKE" or "within model",
        additiveBound, s.firstPaint.frame))
end
return reports
