-- Queue edits preserve live step state; changing the selected route still refreshes it.
dofile("tests/lua/route_browser_test_env.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/config/Config_Route.lua")
local noop = function() end
local messages, calls, timers = {}, {}, {}
APR.settings.profile.enableAddon = true
local function count(name) calls[name] = (calls[name] or 0) + 1 end
function APR.routeconfig:RegisterMessage(name, callback) messages[name] = callback end
function APR.routeconfig:SendMessage(name) messages[name]() end
APR.currentStep = { Reset = function() count("reset") end }
APR.Buff = { RemoveAllBuffIcon = function() count("buffs") end }
APR.XPBuffOverlay = { QueueRefresh = function() count("xp") end }
APR.RouteBrowser.Refresh = function() count("browser") end
APR.StatusFrame = { IsShown = function() return true end }
function APR:updateStatusFrame() count("status") end
function APR:StartPerformanceSample() end
function APR:FinishPerformanceSample() end
function APR:UpdateMapId() count("map") end
function APR:UpdateStep() count("step") end
function APR:InvalidatePlayerZoneCache() count("zone") end
APR.navigation = { Cancel = function() count("cancel") end, RequestUpdate = noop }
function APR:GetRouteSelectionWarnings() return {} end
C_Timer = {}
C_Timer.NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = noop }
    timers[#timers + 1] = timer
    return timer
end
APR.routeconfig:InitRouteConfig()
local catalog = APR.RouteCatalog

local function record(key) return { key = key, label = APR.RouteQuestStepList[key].label } end
local function flushUi()
    local pending = timers
    timers = {}
    for _, timer in ipairs(pending) do timer.callback() end
end
local function setup(version, path, active)
    function APR:GetGameVersion() return version end
    APR.RouteQuestStepList = {}
    for _, key in ipairs({ "a", "b", "c", "d", "prerequisite", "temporary" }) do
        APR.RouteQuestStepList[key] = {
            label = "Invented " .. key,
            expansion = APR.EXPANSIONS.Custom,
            mapID = 42,
            steps = { { Qpart = { [123] = { "1" } } } },
        }
    end
    APR.RouteQuestStepList.temporary.temporary = true
    APRCustomPath.test, APRData.test, APRZoneCompleted.test = {}, { a = 7, b = 3 }, {}
    for _, key in ipairs(path) do table.insert(APRCustomPath.test, record(key).label) end
    APR.ActiveRoute, APR.stepRevision = active, 9
    APR.runtimeRouteStep, APR.routeActionState, APR.manualSkipUndo = {}, {}, {}
    APR._lastRouteZoneCheck, APR._lastRouteZoneResult = {}, true
    APR.routeconfig.pathUiRefreshTimer, APR.routeconfig.pathUiRefreshStatus = nil, nil
    APR.routeconfig.levelResetRequest = {}
    calls, timers = {}, {}
end
local function assertPreserved(active, runtime, action, undo, zone)
    assert(APR.ActiveRoute == active and APR.stepRevision == 9, "Queue edits preserve active route and step revision")
    assert(APR.runtimeRouteStep == runtime and APR.routeActionState == action and APR.manualSkipUndo == undo,
        "Queue edits preserve runtime actions and manual-skip undo")
    assert(APRData.test.a == 7 and APRData.test.b == 3, "Queue edits preserve saved progress")
    assert(APR._lastRouteZoneCheck == zone and APR._lastRouteZoneResult == true,
        "Queue edits preserve navigation's zone cache")
    assert(not next(calls), "Queue edits cannot reset the frame, buffs, navigation or render the current step")
    assert(not APR.routeconfig.levelResetRequest, "A queue edit retires a pending level-reset selection")
end

for _, version in ipairs({ APR.GAME_VERSIONS.Retail, APR.GAME_VERSIONS.Forever }) do
    setup(version, { "a", "b", "c" }, "a")
    local runtime, action, undo, zone = APR.runtimeRouteStep, APR.routeActionState,
        APR.manualSkipUndo, APR._lastRouteZoneCheck
    -- Adding a route also queues its unmet prerequisite after the existing tail.
    APR.RouteQuestStepList.d.requiredRoute = "prerequisite"
    assert(catalog:ChangePath(record("d"), "add"))
    assert(#APRCustomPath.test == 5 and APRCustomPath.test[4] == record("prerequisite").label)
    assert(catalog:ChangePath(record("c"), "up"))
    assert(catalog:ChangePath(record("c"), "down"))
    assert(catalog:ChangePath(record("b"), "remove"))
    assertPreserved("a", runtime, action, undo, zone)
    flushUi()
    assert(calls.browser == 1 and calls.status == 1, "Tail edits publish one up-to-date path/status refresh")
    assert(not catalog:ChangePath(record("d"), "add"), "Duplicates remain refused")

    -- Moving another route before the current one genuinely changes selection.
    calls = {}
    assert(catalog:ChangePath(record("c"), "up"))
    assert(APR.ActiveRoute == "c" and calls.reset == 1 and calls.step == 1 and calls.cancel == 1)
    assert(calls.map == 1 and calls.zone == 1 and not APR.runtimeRouteStep and not APR.manualSkipUndo)

    setup(version, { "a", "b" }, "a")
    assert(catalog:ChangePath(record("a"), "down"))
    assert(APR.ActiveRoute == "b" and calls.step == 1)
    setup(version, { "a", "b" }, "a")
    assert(catalog:ChangePath(record("a"), "remove"))
    assert(APR.ActiveRoute == "b" and calls.step == 1)
    setup(version, { "a" }, "a")
    assert(catalog:ChangePath(record("a"), "remove"))
    assert(APR.ActiveRoute == nil and calls.reset == 1 and calls.step == 1)
    setup(version, {}, nil)
    assert(catalog:ChangePath(record("a"), "add"))
    assert(APR.ActiveRoute == "a" and calls.step == 1, "An empty path still activates its first addition")

    -- Temporary routes own the active step even when the saved path is edited.
    setup(version, { "a" }, "temporary")
    runtime, action, undo, zone = APR.runtimeRouteStep, APR.routeActionState,
        APR.manualSkipUndo, APR._lastRouteZoneCheck
    assert(catalog:ChangePath(record("b"), "add"))
    assert(catalog:ChangePath(record("a"), "remove"))
    assertPreserved("temporary", runtime, action, undo, zone)

    -- A shared display label must not hide an explicitly changed variant key.
    setup(version, { "a" }, "a")
    APR.RouteQuestStepList.b.label = record("a").label
    APRData.test.RouteChoices = { [record("a").label] = "b" }
    APR.routeconfig:SendCustomPathUpdate(nil, true)
    assert(APR.ActiveRoute == "b" and calls.step == 1)

    setup(version, { "a" }, "a")
    APR.routeconfig:SendCustomPathUpdate(true, true)
    assert(not next(calls) and #timers == 0, "Suppressed updates remain silent")
    APR.routeconfig:SendCustomPathUpdate()
    assert(APR.ActiveRoute == "a" and calls.reset == 1 and calls.step == 1,
        "Explicit reset/preset notifications still refresh an unchanged route")
    messages.APR_Custom_Path_Update()
    assert(calls.step == 2, "Engine notifications retain their full refresh contract")
end
print("Custom path edits preserve active steps on both clients and refresh real selection changes")
