-- No APR or native waypoint APIs may be needed by the reusable AWP provider.
local sandbox = {
    assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
    type = type, tonumber = tonumber, tostring = tostring, select = select,
    pcall = pcall, xpcall = xpcall, unpack = unpack, rawget = rawget, rawset = rawset,
    setmetatable = setmetatable, getmetatable = getmetatable,
    math = math, string = string, table = table, strmatch = string.match,
}
sandbox._G = sandbox
local function Load(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, sandbox)
    return chunk()
end
Load("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
setmetatable(sandbox, { __index = function(_, key)
    error("Unexpected AWP provider global dependency: " .. tostring(key))
end })
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a")
manifest:close()
for path in xml:gmatch('file="([^"]+)"') do Load(root .. path) end
local library = sandbox.LibStub("LibAPRNavigation-1.0")
assert(type(library.Instance.ConnectAzerothWaypoint) == "function", "Ship the provider in the standalone manifest")
assert(rawget(sandbox, "APR") == nil and rawget(sandbox, "C_Map") == nil)

local function Target(token)
    return { mapID = 10, x = 0.25, y = 0.75, title = "Follow the route", subtext = "Through the gate",
        token = token or "first", source = "consumer.step#1", kind = "guide_goal" }
end

local function Provider(id)
    id = id or "guide"
    local values = { registrations = 0, schedules = {}, clears = {}, extracts = 0, activations = 0 }
    local originalTarget = { mapID = 99, x = 0.1, y = 0.2, title = "Quest target", rawTitle = "Raw quest",
        semanticKind = "quest", semanticQuestID = 123, questIDs = { 123, 456 }, custom = "metadata" }
    local original = {
        label = "Consumer", priority = 45, addonNames = { "Consumer", "Consumer_Extra" },
        isLoaded = function() return values.loaded ~= false end,
        getVisibilityState = function() return values.visible or "visible" end,
        installHooks = function() end,
        extractTarget = function(...)
            assert(select("#", ...) == 0, "The upstream extractor uses a dot call")
            values.extracts = values.extracts + 1
            if values.extractError then error("extract failure") end
            return originalTarget, values.suppressed
        end,
        getActivationToken = function(...)
            assert(select("#", ...) == 0, "The upstream activation token uses a dot call")
            values.activations = values.activations + 1
            if values.activationError then error("activation failure") end
            return values.originalToken or "upstream-token"
        end,
    }
    local ns = {}
    values.current = original
    function ns.GetGuideTargetProvider(key)
        assert(key == id)
        if values.getError then error("get failure") end
        return values.current
    end
    function ns.RegisterGuideTargetProvider(key, adapter)
        assert(key == id and type(adapter) == "table")
        if values.registerError then error("register failure") end
        if values.reject then return false end
        values.registrations = values.registrations + 1
        values.current = adapter
        return true
    end
    function ns.ScheduleGuideProviderEvaluation(key, reason)
        assert(key == id and reason == "LibAPRNavigation")
        if values.scheduleError then error("schedule failure") end
        if values.rejectSchedule then return false end
        values.schedules[#values.schedules + 1] = { key, reason }
        return true
    end
    function ns.ClearGuideRouteState(key)
        assert(key == id)
        if values.clearError then error("clear failure") end
        values.clears[#values.clears + 1] = key
    end
    return ns, values, original, originalTarget
end

local function New(ns, id)
    local state = { target = Target(), options = { guideMode = "override", context = { revision = 1 } } }
    local instance = setmetatable({ env = { getAzerothWaypointAPI = function() return ns end },
        waypointOptions = { guideProviderID = id or "guide" }, waypointUIEnabled = true }, library.Instance)
    function instance:GetWaypointTargetState()
        state.reads = (state.reads or 0) + 1
        if state.readError then error("host target failure") end
        if state.disableOnRead then self.waypointUIEnabled = false end
        return state.target, state.options
    end
    function instance:IsWaypointCombatLocked() return state.combat == true end
    return instance, state
end

local ns, provider, original, originalTarget = Provider()
local instance, state = New(ns)
assert(instance:RefreshAzerothWaypoint())
local adapter = provider.current
assert(adapter ~= original and provider.registrations == 1 and #provider.schedules == 1)
assert(adapter.priority == 45 and adapter.addonNames == original.addonNames
    and adapter.isLoaded == original.isLoaded and adapter.getVisibilityState == original.getVisibilityState
    and adapter.installHooks == original.installHooks, "Preserve all upstream availability and selection rules")
local target, suppressed = adapter.extractTarget()
assert(target ~= originalTarget and target.mapID == 10 and target.x == 0.25 and target.y == 0.75)
assert(suppressed == false and target.title == "Follow the route" and target.rawTitle == target.title)
assert(target.guideProvider == "guide" and target.semanticQuestID == 123
    and target.custom == "metadata" and target.questIDs == originalTarget.questIDs)
assert(originalTarget.mapID == 99 and originalTarget.title == "Quest target"
    and originalTarget.rawTitle == "Raw quest", "Override must not mutate upstream quest metadata")
assert(adapter.getActivationToken() == "first")
for _ = 1, 100 do assert(instance:RefreshAzerothWaypoint()) end
assert(provider.registrations == 1 and #provider.schedules == 1,
    "Identical ticks must neither register another wrapper nor reschedule")

-- Callbacks resolve their live host state even before the next refresh tick.
state.target = Target("second")
state.target.uiMapID, state.target.mapID = 20, nil
assert(adapter.extractTarget().mapID == 20 and adapter.getActivationToken() == "second")
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 2)
state.target.title = "Changed label"
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 3)
state.target.subtext = nil
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 4)
state.options.context = { revision = 1 }
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 4,
    "Equivalent context captures must not schedule every frame")
state.options.context.revision = 2
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 5)

state.options.guideMode = "fallback"
state.target = nil
local extracted = provider.extracts
target, suppressed = adapter.extractTarget()
assert(target == originalTarget and suppressed == nil and provider.extracts == extracted + 1)
assert(adapter.getActivationToken() == "upstream-token")
provider.suppressed = true
local _, upstreamSuppressed = adapter.extractTarget()
assert(upstreamSuppressed == true)
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 6)
provider.suppressed = nil

state.options.guideMode = "blocked"
extracted = provider.extracts
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true and provider.extracts == extracted)
assert(adapter.getActivationToken() == nil)
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == 7)
state.options.guideMode = "override"
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true and provider.extracts == extracted,
    "An absent override must not revive the previous authored objective")
assert(adapter.getActivationToken() == "upstream-token", "An absent target retains activation fallback")

state.target = Target("transient")
state.target.transient = true
target, suppressed = adapter.extractTarget()
assert(target.mapID == 10 and suppressed == false and target.semanticQuestID == nil
    and provider.extracts == extracted, "Travel legs must not inherit an authored quest's semantic icon")
state.target.x = 2
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true, "Malformed normalized positions must stay suppressed")
state.target = Target("valid-again")
state.readError = true
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true and adapter.getActivationToken() == nil)
state.readError = nil
state.disableOnRead = true
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true, "Reentrant host disable must stop publication immediately")
state.disableOnRead = nil
instance.waypointUIEnabled = true

-- Combat may sample live targets, but registration/evaluation/cleanup wait.
assert(instance:RefreshAzerothWaypoint())
local schedules = #provider.schedules
state.combat = true
state.target = Target("combat")
local connected, reason = instance:RefreshAzerothWaypoint()
assert(connected and reason == "waypoint_combat" and #provider.schedules == schedules)
instance.waypointUIEnabled = false
local released
released, reason = instance:ReleaseAzerothWaypoint()
assert(not released and reason == "waypoint_combat" and #provider.clears == 0)
target, suppressed = adapter.extractTarget()
assert(target == nil and suppressed == true and adapter.getActivationToken() == nil)
state.combat = false
assert(instance:ReleaseAzerothWaypoint() and #provider.clears == 1)
assert(provider.current == adapter and provider.registrations == 1,
    "Keep the disabled wrapper installed so native fallback stays suppressed")
assert(instance:ReleaseAzerothWaypoint() and #provider.clears == 1)
instance.waypointUIEnabled = true
assert(instance:RefreshAzerothWaypoint() and #provider.schedules == schedules + 1)
assert(provider.registrations == 1)

provider.clearError = true
released, reason = instance:ReleaseAzerothWaypoint()
assert(not released and reason == "azeroth_waypoint_error")
provider.clearError = nil
assert(instance:RefreshAzerothWaypoint() and #provider.clears == 2,
    "A failed release is retried before routing is evaluated again")
local replacement = { extractTarget = function() return { mapID = 77 }, false end }
provider.current = replacement
assert(instance:ReleaseAzerothWaypoint() and provider.current == replacement and #provider.clears == 2,
    "Releasing an obsolete bridge must never clear another adapter's route")
assert(instance:RefreshAzerothWaypoint() and provider.registrations == 2)
assert(adapter.extractTarget() == nil, "Retired wrappers must never publish a new instance target")

-- Lazy namespace and provider discovery supports addons loaded afterwards.
local late, lateState = New(nil, "other-addon")
late.env.getAzerothWaypointAPI = nil
assert(late:ConnectAzerothWaypoint() == false)
local lateNS, lateProvider = Provider("other-addon")
sandbox.AzerothWaypointNS = lateNS
lateState.combat = true
assert(late:ConnectAzerothWaypoint() == false and lateProvider.registrations == 0)
lateState.combat = false
assert(late:RefreshAzerothWaypoint() and lateProvider.registrations == 1)
assert(lateProvider.current.extractTarget().guideProvider == "other-addon")
sandbox.AzerothWaypointNS = nil

local errorsNS, errors = Provider()
local failures, failureState = New(errorsNS)
errors.getError = true
connected, reason = failures:ConnectAzerothWaypoint()
assert(not connected and reason == "azeroth_waypoint_error")
errors.getError, errors.registerError = nil, true
assert(failures:ConnectAzerothWaypoint() == false)
errors.registerError, errors.reject = nil, true
assert(failures:ConnectAzerothWaypoint() == false)
errors.reject = nil
errors.scheduleError = true
assert(failures:RefreshAzerothWaypoint() == false)
errors.scheduleError = nil
assert(failures:RefreshAzerothWaypoint() and errors.registrations == 1 and #errors.schedules == 1)
failureState.options.guideMode = "fallback"
errors.extractError, errors.activationError = true, true
target, suppressed = errors.current.extractTarget()
assert(target == nil and suppressed == true and errors.current.getActivationToken() == nil)
failures.env.getAzerothWaypointAPI = function() error("namespace failure") end
assert(failures:ConnectAzerothWaypoint() == false)
failures.env.getAzerothWaypointAPI = function() return { GetGuideTargetProvider = function() return original end } end
assert(failures:ConnectAzerothWaypoint() == false, "An incomplete namespace must allow WUI fallback")
failures.env.getAzerothWaypointAPI = function() return errorsNS end
errors.current = nil
assert(failures:ConnectAzerothWaypoint() == false)
failures.waypointOptions.guideProviderID = nil
assert(failures:ConnectAzerothWaypoint() == false, "The library must never assume an APR provider ID")

-- The public automatic option selects AWP ahead of WUI and owns combat cleanup.
local automaticNS, automaticProvider = Provider("independent")
local automaticTarget, automaticCombat, ticks = Target("automatic"), false, {}
local automatic = library:New({ profile = "retail", waypoints = { guideProviderID = "independent" },
    environment = {
        getAzerothWaypointAPI = function() return automaticNS end,
        getWaypointUIAPI = function() error("AWP must take precedence over WUI") end,
        getWaypointTarget = function() return automaticTarget, { guideMode = "override", context = "step-one" } end,
        isWaypointCombatLocked = function() return automaticCombat end,
        newWaypointTicker = function(_, callback)
            local ticker = { callback = callback }
            function ticker:Cancel() self.cancelled = true end
            ticks[#ticks + 1] = ticker
            return ticker
        end,
    } })
assert(#automaticProvider.schedules == 1 and automaticProvider.current.extractTarget().token == nil)
assert(automaticProvider.current.getActivationToken() == "automatic" and #ticks == 1)
automatic:RefreshWaypoints()
assert(#automaticProvider.schedules == 1)
automaticCombat = true
automatic:SetWaypointsEnabled(false)
assert(not ticks[1].cancelled and #automaticProvider.clears == 0)
target, suppressed = automaticProvider.current.extractTarget()
assert(target == nil and suppressed == true)
automaticCombat = false
ticks[1].callback()
assert(ticks[1].cancelled and #automaticProvider.clears == 1)

-- Explicit calls also use the provider when the automatic observer is disabled.
local manualNS, manualProvider = Provider("manual")
local manual, manualState = New(manualNS, "manual")
manual.waypointUIEnabled, manualState.readError = false, true
local explicit, visual = Target(), { name = "Manual destination" }
explicit.token = nil
local published = assert(manual:PublishAzerothWaypoint(explicit, visual))
assert(published ~= explicit and published.title == "Manual destination" and published.transient == true)
assert(explicit.title == "Follow the route" and visual.guideMode == nil)
assert(manualProvider.current.extractTarget().title == "Manual destination"
    and manualProvider.current.extractTarget().semanticQuestID == nil and manualProvider.extracts == 0)
assert(manualProvider.current.getActivationToken() == published.token)
assert(manual:PublishAzerothWaypoint(explicit, visual) and #manualProvider.schedules == 1,
    "Repeated explicit requests must preserve their generated activation token")
manualProvider.scheduleError = true
local failed = manual:PublishAzerothWaypoint(Target("failed-manual"), { name = "Failed replacement" })
assert(failed == nil and manualProvider.current.extractTarget().title == "Manual destination",
    "A rejected publication must restore the previous explicit target")
manualProvider.scheduleError = nil
manualState.combat = true
local cleared, clearReason = manual:ClearManualAzerothWaypoint()
assert(not cleared and clearReason == "waypoint_combat" and manual.waypointAzerothManual == nil)
target, suppressed = manualProvider.current.extractTarget()
assert(target == nil and suppressed == true)

-- Both existing public methods select AWP without enabling an observer first.
local publicNS, publicProvider = Provider("public")
local public = library:New({ profile = "retail", environment = {
    getAzerothWaypointAPI = function() return publicNS end,
    getWaypointUIAPI = function() error("Public AWP calls must not require WUI") end,
} })
public.waypointOptions.guideProviderID = "public"
assert(public.waypointUIEnabled ~= true)
assert(public:SetWaypoint({ space = "map", uiMapID = 30, x = 0.2, y = 0.8 }, { name = "Explicit pin" }))
assert(publicProvider.current.extractTarget().title == "Explicit pin")
assert(public:SetWaypointForSegment({ kind = "walk", instruction = "Walk destination",
    from = { space = "map", uiMapID = 30, x = 0.1, y = 0.1 },
    to = { space = "map", uiMapID = 30, x = 0.9, y = 0.7 } }))
target = publicProvider.current.extractTarget()
assert(target.x == 0.9 and target.y == 0.7 and target.title == "Walk destination")
assert(public:ClearWaypoint() and #publicProvider.clears == 1)
target, suppressed = publicProvider.current.extractTarget()
assert(target == nil and suppressed == true and public.waypointAzerothManual == nil)

-- Switching an already-owned WUI carrier to manual AWP retires that carrier.
local coexistNS, coexistProvider = Provider("coexist")
local coexistTarget, awLoaded = Target("observed-first"), false
local wuiState = { clears = 0 }
local wuiAPI = { Navigation = {} }
function wuiAPI.Navigation.NewUserNavigation(request)
    wuiState.current = { mapID = request.mapID, x = request.x / 100, y = request.y / 100,
        flags = request.flags, name = request.name }
    return wuiState.current
end
function wuiAPI.Navigation.GetUserNavigation() return wuiState.current end
function wuiAPI.Navigation.IsUserNavigationTracked() return true end
function wuiAPI.Navigation.ClearUserNavigation()
    wuiState.clears, wuiState.current = wuiState.clears + 1, nil
end
local coexist = library:New({ profile = "retail", waypoints = { guideProviderID = "coexist" }, environment = {
    getAzerothWaypointAPI = function() return awLoaded and coexistNS or nil end,
    getWaypointUIAPI = function() return wuiAPI end,
    getWaypointTarget = function() return coexistTarget, { guideMode = "override", context = "observed" } end,
} })
assert(wuiState.current and coexist.waypointUI)
awLoaded = true
assert(coexist:SetWaypoint(Target("manual-chosen"), { name = "AWP manual override" }))
assert(wuiState.current == nil and coexist.waypointUI == nil and wuiState.clears == 1,
    "Choosing manual AWP must not orphan the instance's previous WUI carrier")
coexist:RefreshWaypoints()
assert(coexistProvider.current.extractTarget().title == "AWP manual override" and #coexistProvider.schedules == 1,
    "Automatic refresh must retain the explicit target until the observed host target changes")
assert(coexist:SetWaypointForSegment({ kind = "walk", instruction = "Manual walking leg",
    from = { space = "map", uiMapID = 10, x = 0.1, y = 0.1 },
    to = { space = "map", uiMapID = 10, x = 0.8, y = 0.9 } }))
coexist:RefreshWaypoints()
assert(coexistProvider.current.extractTarget().x == 0.8)
coexistTarget = Target("observed-next")
coexistTarget.x = 0.3
coexist:RefreshWaypoints()
target = coexistProvider.current.extractTarget()
assert(coexist.waypointAzerothManual == nil and target.x == 0.3 and target.title == "Follow the route"
    and #coexistProvider.clears == 1, "An observed target change must resume automatic guidance")
coexist:ClearWaypoint()
target, suppressed = coexistProvider.current.extractTarget()
assert(target == nil and suppressed == true and #coexistProvider.clears == 2)
manualState.combat = false
assert(manual:ReleaseAzerothWaypoint() and #manualProvider.clears == 1)
assert(manual:ClearManualAzerothWaypoint() == false)

-- A manual WUI override must also suspend AWP's own native addon hooks.
manual.waypointUIEnabled, manualState.readError = true, nil
manual.waypointUIAutomatic = { manualOverride = true }
assert(manual:RefreshAzerothWaypoint())
target, suppressed = manualProvider.current.extractTarget()
assert(target == nil and suppressed == true and manualProvider.current.getActivationToken() == nil)

-- Standalone automatic consumers can still provide planned world-space legs.
local segmentNS, segmentProvider = Provider("segments")
local segmentTarget = { kind = "walk", instruction = "Walk to the dock", token = "leg-one",
    from = { space = "map", uiMapID = 10, x = 0.1, y = 0.2 },
    to = { space = "world", uiMapID = 20, instanceID = 0, x = -1234, y = -5678 } }
local segmentConsumer = library:New({ profile = "retail", waypoints = { guideProviderID = "segments" },
    environment = {
        getAzerothWaypointAPI = function() return segmentNS end,
        getWaypointTarget = function() return segmentTarget, { guideMode = "override" } end,
        worldToMap = function(instanceID, x, y, hint)
            assert(instanceID == 0 and x == -1234 and y == -5678 and hint == 20)
            return 20, 0.4, 0.6
        end,
        canSetWaypointOnMap = function() error("AWP must retain original maps without native map promotion") end,
    } })
target, suppressed = segmentProvider.current.extractTarget()
assert(target and target.mapID == 20 and target.x == 0.4 and target.y == 0.6
    and target.title == "Walk to the dock" and suppressed == false)
assert(segmentProvider.current.getActivationToken() == "leg-one" and #segmentProvider.schedules == 1)
segmentTarget = { sourceFree = true, action = { type = "spell", id = 1 } }
segmentConsumer:RefreshWaypoints()
target, suppressed = segmentProvider.current.extractTarget()
assert(target == nil and suppressed == true)
