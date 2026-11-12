-- Two isolated players use real route progression, fingerprinting and wire delivery.
local function Player(client, mode)
    local globals = setmetatable({}, { __index = _G })
    globals._G = globals
    globals.dofile = function(path)
        local chunk = assert(loadfile(path))
        setfenv(chunk, globals)
        return chunk()
    end
    local env = globals.dofile("tests/lua/party_finder_test_env.lua").New({
        client = client, settings = { matchMode = mode or "nearby" },
    })
    globals.dofile("APR-Core/features/questing/RouteManager.lua")
    local apr = globals.APR
    function apr:IsDelveRoute() return false end
    function apr:AreConditionalFiltersMet() return false end
    local definition = {
        steps = {
            { PickUp = { 801 } }, { Qpart = { [801] = { "1" } } }, { Done = { 801 } },
        },
        parallelSteps = { { steps = { { UseItem = { itemID = 802 } } } } },
    }
    apr.RouteQuestStepList = { synthetic = definition }
    globals.APRData.fixture.synthetic = 2
    env.finder.localDirty = true
    env.finder:GetLocalState()
    env:Advance(1)
    return env, globals, definition
end

for _, client in ipairs({ "retail", "forever" }) do
    local alpha, ga, da = Player(client)
    local beta, gb, db = Player(client)
    local a, b = alpha.finder, beta.finder
    a.playerKey, b.playerKey = "Alpha-Home", "Beta-Home"
    assert(a:GetLocalState().revision == b:GetLocalState().revision)
    assert(a:Search())
    beta:ReceiveWire(alpha:Messages("Q")[1].wire, "Alpha-Home", "CHANNEL")
    assert(b.replyTimer)
    local delay = b.replyTimer.at - beta.now + 0.01
    beta:Advance(delay)
    alpha:Advance(delay)
    local reply = beta:Messages("P", "WHISPER")[1]
    assert(reply and reply.target == "Alpha-Home")
    alpha:ReceiveWire(reply.wire, "Beta-Home", "WHISPER")
    assert(a:GetCount() == 1 and a:GetCandidateDescription(a:GetCandidates()[1]) == "GROUP_SYNCED")

    -- Progress can become ready without an intervening party/chat event.
    ga.APRData.fixture.synthetic = nil
    assert(a:GetLocalState().progressId == "unknown")
    ga.APRData.fixture.synthetic = 3
    assert(a:GetLocalState().progressId == "main:3")
    assert(a:GetCandidateDescription(a:GetCandidates()[1]) == "1 behind")

    -- Replacing a definition while idle cannot reuse a previous revision.
    local oldRevision = a:GetLocalState().revision
    ga.APR.RouteQuestStepList.synthetic = nil
    assert(a:GetLocalState().revision == "00000000")
    ga.APR.RouteQuestStepList.synthetic = da
    a:GetLocalState()
    alpha:Advance(1)
    assert(a:GetLocalState().revision == oldRevision)

    -- In-place edits are invalidated even when the route table is unchanged.
    da.steps[2].Qpart = { [803] = { "1" } }
    ga.APR:InvalidateEffectiveRouteStepsCache("synthetic")
    assert(a:GetLocalState().revision == "00000000")
    alpha:Advance(1)
    local current = a:GetLocalState()
    assert(current.revision ~= oldRevision)
    assert(alpha.protocol.CompareProgress(current, b:GetLocalState()) == "unknown")
    assert(not a:Matches(b:GetLocalState(), a:MakeQuery(current)))

    -- Route switches and a switch back refresh both progression and revision.
    ga.APR.RouteQuestStepList.other = { steps = { { PickUp = { 804 } } } }
    ga.APRData.fixture.other, ga.APR.ActiveRoute = 1, "other"
    a:GetLocalState()
    alpha:Advance(1)
    assert(a:GetLocalState().progressId == "main:1" and a:GetLocalState().total == 1)
    ga.APR.ActiveRoute = "synthetic"
    a:GetLocalState()
    alpha:Advance(1)
    assert(a:GetLocalState().progressId == "main:3" and a:GetLocalState().total == 3)

    -- Equal counters never establish proximity across different optional branches.
    local own = { route = "abcdef01", revision = "abcdef02", total = 3, step = 2, progressId = "parallel:1:1" }
    local peer = { route = own.route, revision = own.revision, total = 3, step = 2, progressId = "main:2" }
    local status, gap = alpha.protocol.CompareProgress(own, peer)
    assert(status == "different" and gap == nil)

    local branch, gc = Player(client, "zone")
    local main = Player(client, "zone")
    function gc.APR:AreConditionalFiltersMet() return true end
    gc.APR:InvalidateEffectiveRouteStepsCache("synthetic")
    branch.finder:GetLocalState()
    branch:Advance(1)
    local branchState, mainState = branch.finder:GetLocalState(), main.finder:GetLocalState()
    assert(branchState.revision == mainState.revision, "Activating optional steps does not change the definition")
    assert(branchState.progressId == "parallel:1:1" and mainState.progressId == "main:2")
    status, gap = branch.protocol.CompareProgress(branchState, mainState)
    assert(status == "different" and gap == nil)

    -- A pending large fingerprint must not publish the previous route's revision.
    local pending, gp = Player(client)
    local large = { steps = {} }
    for index = 1, 600 do large.steps[index] = { PickUp = { 1000 + index } } end
    gp.APR.RouteQuestStepList.large = large
    gp.APRData.fixture.large, gp.APR.ActiveRoute = 1, "large"
    local waiting = pending.finder:GetLocalState()
    assert(waiting.revision == "00000000" and waiting.progressId == "main:1")
    assert(pending.finder.fingerprintJob)
    local abandoned = pending.finder.fingerprintJob
    gp.APR.ActiveRoute = "synthetic"
    pending.finder:GetLocalState()
    pending:Advance(1)
    assert(pending.finder.fingerprintJob ~= abandoned)
    assert(pending.finder:GetLocalState().total == 3 and pending.finder:GetLocalState().revision ~= "00000000")

    -- An incoming search during a deferred revision is replayed after readiness.
    gp.APR.ActiveRoute = "large"
    pending.finder:GetLocalState()
    assert(pending.finder.fingerprintJob)
    gb.APR.RouteQuestStepList.large = large
    gb.APRData.fixture.large, gb.APR.ActiveRoute = 1, "large"
    b:GetLocalState()
    beta:Advance(1)
    local query = b:MakeQuery(b:GetLocalState())
    query.id = "deferred-revision"
    pending:Receive("Q", query, "ReadyPeer-Home", "CHANNEL")
    assert(pending.finder.pendingQueries["ReadyPeer-Home"] and not next(pending.finder.responses))
    pending:Advance(10)
    local messages = pending:Messages("P", "WHISPER")
    assert(#messages == 1 and messages[1].target == "ReadyPeer-Home")
    assert(messages[1].packet.revision == query.revision and messages[1].packet.total == 600)
end

print("Finder progression: two real route/wire peers, deferred progress, revision invalidation and route switches passed")
