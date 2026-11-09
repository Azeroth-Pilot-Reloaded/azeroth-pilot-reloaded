local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/features/questing/RouteCatalog.lua")
local profile, timers, dialogs = { enableAddon = true }, {}, {}
function APR:GetSettingsProfile() return profile end
function APR:GetPlayerParentMapID() return 7 end
function APR:GetRouteSignature() return "synthetic-signature" end
function APR:SetRouteProgress(key, index)
    if APRData.player[key] == index then return false end
    APRData.player[key] = index
    return true
end
function APR:ResetRoute(key)
    self:SetRouteProgress(key, 1)
    APRData.player[key .. "-ParallelStepsState"] = nil
end
function APR:ActivateRoute(key) self.ActiveRoute = key end
local notifications = 0
function APR.routeconfig:SendCustomPathUpdate() notifications = notifications + 1 end
local journal = { { isHeader = true }, { questID = 101 }, { questID = 102 } }
C_QuestLog = {
    GetNumQuestLogEntries = function() return #journal end,
    GetInfo = function(index) return journal[index] end,
}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
function geterrorhandler() return function(message) error(message) end end
APR.questionDialog = {}
local visibleSelection
function APR.questionDialog:CreateQuestionPopup(_, text, accept, cancel)
    dialogs[#dialogs + 1] = { text = text, accept = accept, cancel = cancel }
end
function APR.questionDialog:CreateSelectionPopup(_, text, options, select, cancel)
    -- Shared native dialogs hide their previous owner before rebinding callbacks.
    if visibleSelection and visibleSelection.cancel then visibleSelection.cancel() end
    local dialog = { text = text, options = options, cancel = cancel }
    if select then
        dialog.select = function(option)
            visibleSelection = nil
            select(option)
        end
    end
    visibleSelection = dialog
    dialogs[#dialogs + 1] = dialog
end
function APR.questionDialog:CreateMessagePopup(text) dialogs[#dialogs + 1] = { text = text } end
local function tick()
    local timer = table.remove(timers, 1)
    assert(timer)
    if not timer.cancelled then timer.callback() end
end
local function drain()
    local ticks = 0
    while #timers > 0 do tick(); ticks = ticks + 1; assert(ticks < 1000) end
    return dialogs[#dialogs]
end
local function route(key, label, map, conditions)
    local data = env.route(key, label, conditions)
    data.mapID = map
    data.levelRange = { min = 10, max = 20 }
    data.steps = { { PickUp = { 101 } }, { Qpart = { [101] = { "1" } } }, { Done = { 101, 102 } } }
    return data
end
APR.Level = 15
local localRoute = route("local", "Local", 7)
route("remote", "Remote", 9)
local blocked = route("blocked", "Blocked", 7, { Class = "MAGE" })
blocked.steps = setmetatable({}, { __index = function() error("Blocked steps must never be read") end })
route("future", "Future", 7).levelRange.min = 16
route("expired", "Expired", 7).levelRange.max = 14
route("hidden", "Hidden", 7).hiddenFromSelection = true
route("temporary", "Temporary", 7).temporary = true
local incompatible = route("incompatible", "Incompatible", 7)
incompatible.gameVersion = APR.GAME_VERSIONS.Retail
local filtered = route("filtered", "Filtered", 7)
filtered.steps = { { Qpart = { [101] = { "1" } }, Class = "MAGE" } }
-- A long synthetic route demonstrates bounded work including the contents of fields.
local long = route("long", "Long", 9)
long.steps = {}
for i = 1, 2000 do long.steps[i] = { Done = { 900000 + i } } end
dofile("APR-Core/features/questing/QuestLogSuggestions.lua")
local search = APR.QuestLogSuggestions
assert(#timers == 0, "Loading the feature does not scan routes")
search:Open()
assert(#timers == 0 and dialogs[#dialogs].accept, "Warning precedes all search work")
dialogs[#dialogs].accept()
tick()
assert(#timers == 1 and not dialogs[#dialogs].select, "No partial results after a bounded slice")
local results = drain()
assert(#results.options == 2)
assert(results.options[1].result.key == "local" and results.options[1].result.count == 2,
    "Local routes first and matching quest IDs counted once")
assert(results.options[2].result.key == "remote")
assert(#APRCustomPath.player == 0 and not APRData.player["local"], "Search is read-only")
results.select(results.options[1])
local choice = dialogs[#dialogs]
assert(#choice.options == 2 and choice.cancel, "Both entry choices retain cancellation")
choice.select(choice.options[2])
assert(APR.ActiveRoute == "local" and APRData.player["local"] == 2, "Resume at objective, not pickup")
assert(APRCustomPath.player[1] == "Local" and APRData.player.RouteChoices.Local == "local")
assert(notifications == 1 and not search.job)
-- Restart is valid even when the saved index already equals the requested index.
search:Run(); results = drain(); results.select(results.options[1])
choice = dialogs[#dialogs]; choice.select(choice.options[1])
assert(APRData.player["local"] == 1 and notifications == 2 and #APRCustomPath.player == 1)
search:Run(); results = drain(); results.select(results.options[1]); choice = dialogs[#dialogs]
journal = {}
choice.select(choice.options[2])
assert(APRData.player["local"] == 1 and notifications == 2, "Abandoned quests cannot mutate the path")
search:Run(); results = drain()
assert(#results.options == 0, "Empty journal returns an explicit empty result")
journal = { { questID = 101 } }
search:Run(); tick(); dialogs[#dialogs].cancel(); drain()
assert(not search.job and notifications == 2, "Cancellation kills the worker")
search:Run(); tick(); APR.Level = 30; results = drain()
assert(#results.options == 0, "Live eligibility rechecked before publishing")
APR.Level = 15
search:Run(); results = drain(); results.select(results.options[1]); choice = dialogs[#dialogs]
localRoute.conditions = { Class = "MAGE" }
choice.select(choice.options[1])
assert(notifications == 2, "Stale selection cannot bypass route gates")
print("Journal suggestions: prefilter, bounded search, ranking, unique matches, choices, cancellation and stale state")
