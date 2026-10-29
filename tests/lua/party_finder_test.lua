local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local env = Fixture.New()
local finder = env.finder
assert(finder.channelID == 7 and #env.joined == 1 and #env:Messages() == 0)
assert(env:ActiveTimers() == 0, "Visible idle players do not periodically broadcast their progression")
assert(finder:Search())
local queries = env:Messages("Q", "CHANNEL")
assert(#queries == 1 and queries[1].target == 7 and finder:GetStatus() == "searching")
local oldQuery = finder.query.id
env:Receive("P", env:Presence(), "Peer-Home", "CHANNEL")
assert(finder:GetCount() == 0, "A public presence must never enter the private discovery cache")
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
assert(finder:GetCount() == 1 and finder:GetCandidates()[1].key == "Peer-Home")
assert(finder:GetCandidates()[1].languageSource == "player")
env:Receive("P", env:Presence(), "Peer-Home", "WHISPER")
assert(finder:GetCount() == 1 and finder.query.count == 1, "Duplicate snapshots cannot multiply rows or results")
local success, reason = finder:Search()
assert(not success and reason == "throttled" and #env:Messages("Q") == 1)
env:Advance(11)
env:Receive("P", env:Presence({ id = oldQuery }), "Late-Home", "WHISPER")
assert(finder:GetCount() == 1, "A response received after its query expired is stale")
env:Advance(110)
assert(finder:GetCount() == 0 and env:ActiveTimers() == 0, "Results expire and leave no permanent cleanup ticker")

-- Visibility controls responses, while manual searches remain available.
env = Fixture.New({ settings = { visible = false } })
finder = env.finder
env:Receive("Q", env:Query())
env:Advance(4)
assert(#env:Messages("P") == 0)
assert(finder:Search() and #env:Messages("Q") == 1)
finder:SetOption("visible", true)
env:Advance(0.5)
env:Receive("Q", env:Query({ id = "visible-now" }))
env:Advance(4)
local replies = env:Messages("P")
assert(#replies == 1 and replies[1].channel == "WHISPER" and replies[1].target == "Peer-Home",
    "Eligible discovery replies are addressed privately to the real sender")

-- A permitted language wins for multilingual players; an English-only requester remains excluded.
env = Fixture.New({ settings = { visibleLanguages = { fr = true }, blockedLanguages = { en = true },
    languages = { fr = true } } })
finder = env.finder
env:Receive("Q", env:Query({ id = "english", primary = "en", languages = 1 }), "English-Home")
env:Receive("Q", env:Query({ id = "bilingual", primary = "en", languages = 3 }), "Bilingual-Home")
env:Advance(4)
replies = env:Messages("P")
assert(#replies == 1 and replies[1].target == "Bilingual-Home")
assert(finder:Search())
env:Receive("P", env:Presence({ primary = "en", languages = 1 }), "English-Home", "WHISPER")
env:Receive("P", env:Presence({ primary = "en", languages = 3 }), "Bilingual-Home", "WHISPER")
assert(finder:GetCount() == 1 and finder:GetCandidates()[1].key == "Bilingual-Home")

-- Route/progress boundaries are independently chosen; sorted results favour exact positions.
env = Fixture.New()
finder = env.finder
assert(finder:Search())
env:Receive("P", env:Presence({ progressId = "main:8", step = 8 }), "Boundary-Home", "WHISPER")
env:Receive("P", env:Presence({ progressId = "main:9", step = 9 }), "TooFar-Home", "WHISPER")
env:Receive("P", env:Presence({ progressId = "main:1", step = 1 }), "Behind-Home", "WHISPER")
env:Receive("P", env:Presence(), "Exact-Home", "WHISPER")
env:Receive("P", env:Presence({ route = "ffffffff" }), "OtherRoute-Home", "WHISPER")
env:Receive("P", env:Presence({ revision = "ffffffff" }), "OtherRevision-Home", "WHISPER")
env:Receive("P", env:Presence({ progressId = "parallel:1:1" }), "OtherBranch-Home", "WHISPER")
local ordered = finder:GetCandidates()
assert(#ordered == 3 and ordered[1].key == "Exact-Home" and ordered[2].key == "Behind-Home"
    and ordered[3].key == "Boundary-Home", "Same step, then two behind, then five ahead")
finder:SetLanguageOption("blockedLanguages", "fr", true)
assert(finder:GetCount() == 0, "A policy change immediately reevaluates already cached results")

-- Channel metadata, packet context, nonce, sender identity and supported transport all participate.
env = Fixture.New()
finder = env.finder
local query = env:Query()
env:Receive("Q", query, "Peer-Home", "CHANNEL", { localID = 99 })
env:Receive("Q", query, "Peer-Home", "CHANNEL", { name = "OtherChannel" })
env:Receive("Q", query, "Peer-Home", "WHISPER")
env:Receive("Q", query, "Peer-Home", "PARTY")
env:Receive("Q", query, "Peer-Home", "CHANNEL", { prefix = "OtherAddon" })
env:Receive("Q", query, "Local-Home")
env:Receive("Q", query, "Unsafe|Name")
env:ReceiveWire("1|Q|broken", "Malformed-Home")
env:Advance(4)
assert(#env:Messages("P") == 0 and not next(finder.responses))
assert(finder:Search())
env:Receive("P", env:Presence({ id = "old-search" }), "Old-Home", "WHISPER")
env:Receive("P", env:Presence({ context = "ffffffff" }), "OtherContext-Home", "WHISPER")
env:Receive("P", env:Presence(), "Local-Home", "WHISPER")
env:Receive("P", env:Presence(), "Unsafe|Name", "WHISPER")
assert(finder:GetCount() == 0)
env:Receive("P", env:Presence(), "Real-OtherRealm", "WHISPER")
assert(finder:GetCount() == 1 and finder:GetCandidates()[1].key == "Real-OtherRealm",
    "Real event senders retain their realm identity; payloads cannot claim another name")

-- Irrelevant traffic returns before touching route state; world-event bursts share one deferred refresh.
env = Fixture.New()
finder = env.finder
local getState = finder.GetLocalState
finder.GetLocalState = function() error("Unrelated addon traffic must not resolve the current route") end
for _ = 1, 200 do
    finder:HandleAddonMessage("AnotherAddon", "noise", "CHANNEL", "Peer-Home", nil, 0, 7, finder.channelName)
end
finder.GetLocalState = getState
assert(env:ActiveTimers() == 0)
local previousContext = finder.context
env.map = 502
for _ = 1, 100 do env:Event("ZONE_CHANGED_NEW_AREA") end
assert(env:ActiveTimers() == 1, "Zone bursts coalesce before any route or transport refresh")
env:Advance(0.5)
assert(finder.context ~= previousContext and #env.joined == 2 and #env.left == 1,
    "Changing zone replaces exactly one discovery membership")

-- Zone mode works without a route; route-based modes explain the missing prerequisite.
env = Fixture.New()
finder = env.finder
APR.ActiveRoute = nil
finder.localDirty = true
success, reason = finder:Search()
assert(not success and reason == "no_route" and #env:Messages("Q") == 0)
finder:SetOption("matchMode", "zone")
assert(finder:Search())
env:Receive("P", env:Presence(), "ZonePeer-Home", "WHISPER")
assert(finder:GetCount() == 1, "Zone discovery does not require a shared route")

-- Responses are coalesced per peer and paced globally; finished queries cancel pending work.
env = Fixture.New({ throttle = true })
finder = env.finder
for _ = 1, 100 do env:Receive("Q", env:Query(), "Burst-Home") end
env:Advance(4)
assert(#env:Messages("P") == 1)
env:Receive("Q", env:Query({ id = "repeat" }), "Burst-Home")
env:Advance(4)
assert(#env:Messages("P") == 1, "A new nonce does not bypass the per-requester cooldown")
env:Receive("Q", env:Query({ id = "other-a" }), "Second-Home")
env:Receive("Q", env:Query({ id = "other-b" }), "Third-Home")
env:Receive("Q", env:Query({ id = "cancelled" }), "Cancelled-Home")
env:Receive("D", { id = "cancelled" }, "Cancelled-Home")
env:Advance(6)
replies = env:Messages("P")
assert(#replies == 3)
for index = 2, #replies do assert(replies[index].at - replies[index - 1].at >= 1) end
for _, reply in ipairs(replies) do assert(reply.channel == "WHISPER" and reply.target ~= "Cancelled-Home") end

env = Fixture.New()
finder = env.finder
env:Receive("Q", env:Query(), "Pending-Home")
assert(next(finder.responses))
finder:SetOption("visible", false)
env:Advance(4)
assert(#env:Messages("P") == 0 and not next(finder.responses),
    "Hiding cancels delayed presence instead of leaking the old visible state")

-- A discovery transport failure is explicit and a later user retry can recover.
env = Fixture.New()
finder = env.finder
env.sendResult = Enum.SendAddonMessageResult.InvalidChatType
success, reason = finder:Search()
assert(not success and reason == "unavailable" and finder:GetStatus() == "unavailable")
assert(not finder.channelID and not finder.query)
local failedAttempts = #env.sent
env:Advance(30)
assert(#env.sent == failedAttempts, "An unsupported transport does not create an automatic retry loop")
env.sendResult = 0
assert(finder:Search(), "A deliberate manual search must retry a transport that has become available")
assert(#env:Messages("Q") == 1 and finder:GetStatus() == "searching")

-- Rejected searches must not fill permanent sender accounting and silence future legitimate peers.
env = Fixture.New({ settings = { visibleLanguages = { fr = true } } })
finder = env.finder
for batch = 1, 5 do
    for index = 1, 40 do
        env:Receive("Q", env:Query({ id = "excluded", primary = "en", languages = 1 }),
            "Excluded" .. ((batch - 1) * 40 + index) .. "-Home")
    end
    env:Advance(1)
end
assert(#env:Messages("P") == 0)
env:Advance(121)
env:Receive("Q", env:Query({ id = "allowed-later" }), "Allowed-Home")
env:Advance(4)
assert(#env:Messages("P") == 1 and env:Messages("P")[1].target == "Allowed-Home",
    "Expired rejected requests cannot permanently exhaust the sender budget")

-- A refused private reply transport never turns into a public presence broadcast.
env = Fixture.New()
finder = env.finder
env.sendResult = function(channel) return channel == "WHISPER" and 4 or 0 end
env:Receive("Q", env:Query())
env:Advance(4)
assert(#env:Messages("P") == 0 and finder:GetStatus() == "unavailable")
for _, message in ipairs(env.sent) do
    assert(message.packet.kind ~= "P" or message.channel == "WHISPER")
end

-- Auto scan has no UI dependency; changing it cancels future scans immediately.
env = Fixture.New({ settings = { autoScan = true } })
finder = env.finder
assert(APR.Workspace == nil and finder.autoTimer)
env:Advance(106)
assert(#env:Messages("Q") >= 1 and finder.autoTimer,
    "Automatic search continues while no companion window exists")
finder:SetOption("autoScan", false)
assert(finder.autoTimer == nil)
local scans = #env:Messages("Q")
env:Advance(220)
assert(#env:Messages("Q") == scans)
finder:SetOption("autoScan", true)
assert(finder.autoTimer)
finder:SetOption("enabled", false)
assert(not finder.autoTimer and finder:GetStatus() == "disabled")
scans = #env:Messages("Q")
env:Advance(250)
assert(#env:Messages("Q") == scans and env:ActiveTimers() == 0,
    "A disabled feature retains no periodic discovery or UI work")

-- Dense synthetic populations retain a fixed number of candidates across fresh queries.
env = Fixture.New({ settings = { matchMode = "zone" } })
finder = env.finder
for batch = 1, 7 do
    if batch > 1 then env:Advance(15) end
    assert(finder:Search())
    for index = 1, 30 do
        env:Receive("P", env:Presence(), "Dense" .. ((batch - 1) * 30 + index) .. "-Home", "WHISPER")
    end
end
assert(finder:GetCount() == 200, "Discovery cache cannot grow beyond its declared budget")
env:Advance(122)
assert(finder:GetCount() == 0)

print("Companion discovery: private presence, independent visibility, bilingual policies, expiry, sender/channel validation, pacing, auto-scan and bounded caches passed")

env = Fixture.New()
finder = env.finder
assert(finder:Search())
env:Receive("P", env:Presence(), "Cached-Home", "WHISPER")
local cached = finder:GetCandidates()
assert(finder:GetCandidates() == cached, "Unchanged badge/window reads reuse the filtered, sorted view")
finder:SetLanguageOption("languages", "en", true)
assert(finder:GetCount() == 0)
env:Advance(122)
assert(not next(finder.candidates) and env:ActiveTimers() == 0,
    "Filtered-out entries also expire without leaving a tight expiry polling loop")
finder:SetOption("enabled", false)
env:Advance(1)
assert(not next(finder.eventFrame.events), "Disabled discovery unregisters its listeners")
finder:QueueStateRefresh()
assert(env:ActiveTimers() == 0, "Disabled discovery ignores world/progress refresh work")

-- Entry points keep the companions window independent from the settings workspace.
env = Fixture.New()
finder = env.finder
local opened, searched, configured = 0, 0, 0
APR.PartyFinderPanel = {Show = function() opened = opened + 1 end}
APR.Workspace = {Show = function(_, page, section)
    assert(page == "options" and section == "groupFinder",
        "Only the dedicated finder settings category belongs to the workspace")
    configured = configured + 1
end}
function finder:Search() searched = searched + 1 end
finder:Open()
finder:OpenSettings()
assert(opened == 1 and configured == 1 and searched == 0,
    "The companions window owns its search; opening it must not also open the workspace or search twice")
