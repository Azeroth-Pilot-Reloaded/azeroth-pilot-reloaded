local Fixture = dofile("tests/lua/party_finder_test_env.lua")
for _, client in ipairs({"retail", "forever"}) do
    for _, mode in ipairs({"nearby", "zone", "world"}) do
        local env = Fixture.New({client = client, settings = {matchMode = mode}})
        local finder = env.finder
        local own = finder:GetLocalState()
        local opposite = mode == "world" and own.alternateWorldContext or own.alternateContext
        assert(finder:GetSettings().showIncompatibleWarMode == false)
        assert(finder:Search() and #env:Messages("Q") == 1)
        env:Receive("P", env:Presence({context = opposite, warMode = true}), "OtherMode-Home", "WHISPER")
        assert(finder:GetCount() == 0, "Different war mode is excluded by default")

        env = Fixture.New({client = client, settings = {matchMode = mode, showIncompatibleWarMode = true}})
        finder, own = env.finder, env.finder:GetLocalState()
        opposite = mode == "world" and own.alternateWorldContext or own.alternateContext
        assert(finder:Search())
        local sent = env:Messages("Q")
        assert(#sent == 2 and sent[1].packet.id == sent[2].packet.id
            and sent[1].packet.context ~= sent[2].packet.context and sent[2].packet.context == opposite)
        env:Receive("P", env:Presence({context = opposite, warMode = true}), "OtherMode-Home", "WHISPER")
        assert(finder:GetCount() == 1 and finder:GetCandidates()[1].warModeCompatible == false)
        env:Receive("P", env:Presence({context = "ffffffff", warMode = true}), "WrongContext-Home", "WHISPER")
        assert(finder:GetCount() == 1, "Showing both war modes must preserve other context boundaries")
        finder:SetOption("showIncompatibleWarMode", false)
        assert(finder:GetCount() == 0, "The option immediately filters already received candidates")
        finder:SetOption("showIncompatibleWarMode", true)
        assert(finder:GetCount() == 1)
        for _ = 1, 100 do finder:Search() end
        assert(#env:Messages("Q") == 2, "The broader search still has one shared cooldown")
    end
end

-- Deliver the actual opposite-context V1 query to a normal WM-on responder,
-- then return its encoded private reply to a WM-off searcher.
local env = Fixture.New({settings = {showIncompatibleWarMode = true}})
local finder = env.finder
assert(finder:Search())
local remoteQuery = env:Messages("Q")[2]
local queryID = finder.query.id
env = Fixture.New()
env.warMode = true
env:Event("WAR_MODE_STATUS_UPDATE"); env:Advance(0.5)
assert(not env.finder:GetSettings().showIncompatibleWarMode)
env:ReceiveWire(remoteQuery.wire, "BroadSearcher-Home")
env:Advance(10)
local reply = env:Messages("P")[1]
assert(reply and reply.packet.warMode == true and reply.target == "BroadSearcher-Home")
env = Fixture.New({settings = {showIncompatibleWarMode = true}})
finder = env.finder
assert(finder:Search())
finder.query.id = queryID
env:ReceiveWire(reply.wire, "OtherMode-Home", "WHISPER")
assert(finder:GetCount() == 1 and not finder:GetCandidates()[1].warModeCompatible)

env = Fixture.New()
finder = env.finder
C_PvP = nil
finder.localDirty = true
finder:SetOption("showIncompatibleWarMode", true)
env:Advance(0.5)
assert(finder:Search() and #env:Messages("Q") == 1,
    "Clients without war mode must neither call the optional API nor issue duplicate queries")
finder:SetOption("stepRange", 400)
assert(finder:GetSettings().stepRange == 30)
finder:SetOption("minLevel", 25); finder:SetOption("maxLevel", 10)
assert(finder:GetSettings().minLevel == 10 and finder:GetSettings().maxLevel == 10)
finder:SetOption("minLevel", 50)
assert(finder:GetSettings().maxLevel == 50)
finder:SetOption("maxLevel", 0)
assert(finder:GetSettings().minLevel == 50 and finder:GetSettings().maxLevel == 0)
print("Finder war mode: default exclusion, both contexts, V1 replies, cached filters, budgets, optional API and level bounds passed")
