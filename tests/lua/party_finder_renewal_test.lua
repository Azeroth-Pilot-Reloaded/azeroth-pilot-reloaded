local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function Seed(env, names)
    assert(env.finder:Search())
    for _, name in ipairs(names) do env:Receive("P", env:Presence(), name, "WHISPER") end
    env:Advance(11)
end

for _, client in ipairs({ "retail", "forever" }) do
    local env = Fixture.New({ client = client, settings = { autoScan = true, matchMode = "zone" } })
    local finder = env.finder
    Seed(env, { "Present-Home", "Absent-Home" })
    for cycle = 1, 3 do
        local finished = env.now - 1
        assert(finder.autoTimer and finder.autoTimer.at >= finished + 75 and finder.autoTimer.at <= finished + 105)
        -- Age alone cannot remove automatic results, even after a long interruption.
        finder:CancelTimer("autoTimer")
        env:Advance(130)
        assert(finder:GetCount() >= 1)
        assert(finder:Search(true) and not finder.autoTimer)
        assert(finder.candidates["Present-Home"])
        env:Advance(9)
        assert(finder.candidates["Present-Home"], "Keep old rows while waiting for a late answer")
        env:Receive("P", env:Presence({ level = 22 }), "Present-Home", "WHISPER")
        assert(finder.candidates["Present-Home"].level == 22)
        env:Advance(2)
        assert(finder:GetCount() == 1 and not finder.candidates["Absent-Home"])
    end

    -- Cancellation retains absent peers and starts the next automatic delay afterwards.
    env:Advance(30)
    assert(finder:Search())
    env:Receive("P", env:Presence(), "Unconfirmed-Home", "WHISPER")
    finder:StopSearch()
    assert(finder:GetCount() == 2 and finder.autoTimer)
    env:Advance(30)
    assert(finder:Search())
    finder.resultCycle.complete = false -- An incomplete transport cannot reconcile absence.
    env:Advance(11)
    assert(finder:GetCount() == 2)
    env:Receive("W", {}, "Unconfirmed-Home", "CHANNEL")
    assert(not finder.candidates["Unconfirmed-Home"], "Explicit withdrawals remain immediate")

    -- A manual query suspends the old TTL, including when cancelled.
    env = Fixture.New({ client = client, settings = { matchMode = "zone" } })
    finder = env.finder
    Seed(env, { "Old-Home" })
    env:Advance(104)
    assert(finder:Search())
    env:Advance(9)
    assert(finder:GetCount() == 1, "No expiry while a manual query is running")
    finder:StopSearch()
    assert(finder:GetCount() == 1)
    env:Advance(6)
    assert(finder:GetCount() == 0, "Cancellation resumes the remaining manual TTL")

    -- Failed sends do not erase the previous list.
    env = Fixture.New({ client = client, settings = { autoScan = true, matchMode = "zone" } })
    finder = env.finder
    Seed(env, { "Retained-Home" })
    env:Advance(30)
    env.sendResult = 3
    assert(not finder:Search())
    env:Advance(11)
    assert(finder:GetCount() == 1)

    -- Filtering remains immediate while rows are held for renewal.
    finder:SetOption("minLevel", 90)
    assert(finder:GetCount() == 0)

    -- Accepted into CTL's queue is not proof that the native query was sent.
    env = Fixture.New({
        client = client, friends = { { name = "Friend-Home", connected = true } },
        settings = { autoScan = true, matchMode = "zone" },
    })
    finder = env.finder
    Seed(env, { "Friend-Home" })
    env:Advance(30)
    env.directCTL.avail, env.directCTL.bQueueing = -100000, true
    assert(finder:Search())
    env:Advance(1)
    assert(finder.resultCycle.pending == 1)
    env:Advance(10)
    assert(finder.candidates["Friend-Home"], "Unsent queued requests cannot establish absence")
end

-- The second Retail context shares a cycle without recursively copying its state.
local broad = Fixture.New({ settings = { showIncompatibleWarMode = true, matchMode = "zone" } })
assert(broad.finder:Search() and #broad:Messages("Q", "CHANNEL") == 2)
broad:Advance(11)
assert(not broad.finder.resultCycle)

print("Finder renewal: complete cycles, late replies, automatic retention, manual TTL, cancellation and send failures passed")
