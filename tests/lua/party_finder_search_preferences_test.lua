local Fixture = dofile("tests/lua/party_finder_test_env.lua")

-- Cancel permits an immediate manual retry; ordinary completion still paces searches.
local env = Fixture.New()
local finder = env.finder
assert(finder:Search() and finder:GetSearchCooldown() > 0)
local cancelled = finder.query.id
finder:StopSearch()
assert(finder:GetSearchCooldown() == 0 and not finder.query)
assert(finder:Search() and finder.query.id ~= cancelled)
finder:FinishQuery()
assert(finder:GetSearchCooldown() > 0)
finder:StopSearch() -- no active search: this cannot erase a completed search's cooldown
assert(finder:GetSearchCooldown() > 0 and not finder:Search())

-- The same action cancels a private sweep and permits restarting it immediately.
env = Fixture.New()
finder = env.finder
C_ChatInfo.GetChannelRosterInfo = function(index, row)
    assert(index == 4)
    return ({ "Local-Home", "Peer-Home" })[row]
end
finder:GetSearchTransport().addonTransport = "blocked"
assert(finder:Search())
env:Advance(0.1)
local firstSweep = finder.sweep
finder:StopSearch()
assert(finder:GetSearchCooldown() == 0 and not finder.sweep)
assert(finder:Search() and finder.sweep ~= firstSweep)
env:Advance(0.3)
local requests = env:Messages("Q", "WHISPER")
assert(
    #requests == 2 and requests[2].at - requests[1].at >= 0.25,
    "Immediate manual restart still respects the private transport rate"
)

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

-- Exercise the actual embedded AceDB persistence/cleanup contract, not a fake
-- saved table. New Lua sessions reload both the DB and the actual Finder owner.
local function session(saved, client)
    local env = Fixture.New({ client = client, regional = client == "forever" })
    local finder = env.finder
    finder:OnDisable()
    finder.eventsEnabled = nil
    function UnitRace() return "Human", "Human" end
    function UnitNameUnmodified() return "Invented", "Surname" end
    function GetCurrentRegion() return 3 end
    function GetCurrentRegionName() return "EU" end
    strlenutf8 = string.len
    dofile("APR-Core/libs/AceDB-3.0/AceDB-3.0.lua")
    local ace = LibStub("AceDB-3.0")
    APRSettings = copy(saved or {})
    local db =
        ace:New("APRSettings", { profile = { enableAddon = true, groupFinder = APR.GroupFinderDefaults } }, "Default")
    APR.settings.db, APR.settings.profile = db, db.profile
    finder:OnInit()
    local function save()
        -- AceDB may strip defaults before Finder's logout listener runs.
        ace.frame:GetScript("OnEvent")(ace.frame, "PLAYER_LOGOUT")
        finder:OnDisable()
        return copy(APRSettings)
    end
    return finder, save
end

for _, client in ipairs({ "retail", "forever" }) do
    local finder, save = session(nil, client)
    assert(not finder:GetSettings().autoScan and finder:GetSettings().notifications)
    finder:SetOption("autoScan", true)
    assert(finder.autoTimer)
    finder, save = session(save(), client)
    assert(finder:GetSettings().autoScan and finder.autoTimer, "Saved auto-scan must resume in a new session")
    finder:StopSearch()
    assert(finder:GetSettings().autoScan, "Stopping a search cannot turn off the saved automation preference")
    finder:SetOption("autoScan", false)
    finder:SetOption("notifications", false)
    finder, save = session(save(), client)
    assert(not finder:GetSettings().autoScan and not finder.autoTimer)
    assert(not finder:GetSettings().notifications, "The notification default cannot override an explicit opt-out")
end
print(
    "Finder preferences: immediate retry after cancellation, completed-search pacing, real AceDB session persistence and default-on notifications passed"
)
