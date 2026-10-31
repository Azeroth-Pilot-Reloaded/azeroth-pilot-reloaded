-- Optional guide-provider output. The consumer supplies its effective target;
-- AzerothWaypoint retains its own visibility, provider selection and routing.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("azeroth-waypoint", 4) then return end
local Instance = Lib.Instance

local function ProviderID(instance)
    local options = instance.waypointOptions
    local id = type(options) == "table" and options.guideProviderID
    if type(id) ~= "string" then return nil end
    id = id:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    return id ~= "" and id or nil
end

local function Namespace(instance)
    local ns
    if type(instance.env.getAzerothWaypointAPI) == "function" then
        local ok, value = pcall(instance.env.getAzerothWaypointAPI)
        if not ok then return nil, "azeroth_waypoint_error" end
        ns = value
    else ns = rawget(_G, "AzerothWaypointNS") end
    if type(ns) ~= "table" or type(ns.GetGuideTargetProvider) ~= "function"
        or type(ns.RegisterGuideTargetProvider) ~= "function"
        or type(ns.ScheduleGuideProviderEvaluation) ~= "function"
        or type(ns.ClearGuideRouteState) ~= "function" then
        return nil, "azeroth_waypoint_unavailable"
    end
    return ns
end

local function Combat(instance)
    return instance:IsWaypointCombatLocked()
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = child end
    return result
end

local function Same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    -- Match shallow copies: inherited entries are absent, while the stored
    -- values retain their normal equality semantics (including __eq).
    for key, value in pairs(a) do if rawget(b, key) ~= value then return false end end
    for key in pairs(b) do if rawget(a, key) == nil then return false end end
    return true
end

local function ReadTarget(instance)
    local manual = instance.waypointAzerothManual
    if manual then return manual.target, manual.options end
    local automatic = instance.waypointUIAutomatic
    if automatic and automatic.manualOverride then return nil, { guideMode = "blocked" } end
    if instance.waypointUIEnabled ~= true then return nil, { guideMode = "blocked" } end
    local ok, target, options = pcall(instance.GetWaypointTargetState, instance)
    if not ok or instance.waypointUIEnabled ~= true
        or (options ~= nil and type(options) ~= "table") then
        return nil, { guideMode = "blocked" }
    end
    options = options or {}
    local needsProjection = type(target) == "table" and (target.from ~= nil or target.to ~= nil
        or target.space == "world" or (target.instanceID ~= nil and target.mapID == nil and target.space ~= "map"))
    if needsProjection and type(instance.GetWaypointMapTarget) == "function" then
        local projected, normalized = pcall(instance.GetWaypointMapTarget, instance, target, options)
        if not projected then return nil, { guideMode = "blocked" } end
        target = normalized
    end
    return target, options
end

local function Mode(target, options)
    local mode = options.guideMode
    if mode == "blocked" or mode == "fallback" or mode == "override" then return mode end
    return target ~= nil and "override" or "fallback"
end

local function Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function ValidTarget(target)
    if type(target) ~= "table" then return false end
    local mapID = target.mapID or target.uiMapID
    return Finite(mapID) and mapID > 0 and mapID % 1 == 0
        and Finite(target.x) and target.x >= 0 and target.x <= 1
        and Finite(target.y) and target.y >= 0 and target.y <= 1
end

local function ExtractOriginal(extract, ...)
    local ok, target, suppressed = pcall(extract, ...)
    if ok then return target, suppressed end
    return nil, true
end

local function ActivationOriginal(activate, ...)
    if type(activate) ~= "function" then return nil end
    local ok, token = pcall(activate, ...)
    if ok then return token end
end

local function Wrap(instance, state, provider)
    local adapter = Copy(provider)
    local extract, activation = provider.extractTarget, provider.getActivationToken
    adapter.extractTarget = function(...)
        if instance.waypointAzeroth ~= state then return nil, true end
        local target, options = ReadTarget(instance)
        local mode = Mode(target, options)
        if mode == "blocked" then return nil, true end
        if mode == "fallback" then return ExtractOriginal(extract, ...) end
        if not ValidTarget(target) then return nil, true end
        local result = {}
        if not target.transient then
            local original = ExtractOriginal(extract, ...)
            if type(original) == "table" then result = Copy(original) end
        end
        result.mapID, result.x, result.y = target.mapID or target.uiMapID, target.x, target.y
        result.title, result.rawTitle, result.subtext = target.title, target.title, target.subtext
        result.source, result.kind = target.source, target.kind
        result.guideProvider = target.guideProvider or state.id
        return result, false
    end
    adapter.getActivationToken = function(...)
        if instance.waypointAzeroth ~= state then return nil end
        local target, options = ReadTarget(instance)
        local mode = Mode(target, options)
        if mode == "blocked" then return nil end
        if mode == "override" and ValidTarget(target) and target.token ~= nil then return target.token end
        return ActivationOriginal(activation, ...)
    end
    return adapter
end

function Instance:ConnectAzerothWaypoint()
    local id = ProviderID(self)
    if not id then return false, "azeroth_waypoint_unavailable" end
    local ns, reason = Namespace(self)
    if not ns then return false, reason end
    local ok, provider = pcall(ns.GetGuideTargetProvider, id)
    if not ok then return false, "azeroth_waypoint_error" end
    if type(provider) ~= "table" or type(provider.extractTarget) ~= "function" then
        return false, "azeroth_waypoint_unavailable"
    end
    local state = self.waypointAzeroth
    if state and state.ns == ns and state.id == id and state.adapter == provider then return true end
    if Combat(self) then return false, "waypoint_combat" end
    if state and (state.ns ~= ns or state.id ~= id) then
        local released, releaseReason = self:ReleaseAzerothWaypoint()
        if not released then return false, releaseReason end
    end
    state = { ns = ns, id = id }
    state.adapter = Wrap(self, state, provider)
    local registered
    ok, registered = pcall(ns.RegisterGuideTargetProvider, id, state.adapter)
    if not ok then return false, "azeroth_waypoint_error" end
    if registered == false then return false, "azeroth_waypoint_unavailable" end
    self.waypointAzeroth = state
    return true
end

local SnapshotFields = { "mapID", "uiMapID", "x", "y", "token", "title", "subtext",
    "source", "kind", "guideProvider", "transient" }

local function Snapshot(target, options)
    local result = { mode = Mode(target, options), context = Copy(options.context) }
    if type(target) == "table" then
        for _, key in ipairs(SnapshotFields) do result[key] = target[key] end
    end
    return result
end

local function SameTargetSnapshot(snapshot, target, options)
    if not snapshot or snapshot.mode ~= Mode(target, options)
        or not Same(snapshot.context, options.context) then return false end
    if type(target) ~= "table" then target = nil end
    for _, key in ipairs(SnapshotFields) do
        if snapshot[key] ~= (target and target[key]) then return false end
    end
    return true
end

local function SameSnapshot(a, b)
    if not a or not Same(a.context, b.context) then return false end
    for key, value in pairs(a) do if key ~= "context" and b[key] ~= value then return false end end
    for key, value in pairs(b) do if key ~= "context" and a[key] ~= value then return false end end
    return true
end

function Instance:PublishAzerothWaypoint(target, options)
    if options ~= nil and type(options) ~= "table" then return nil, "invalid_options" end
    if not ValidTarget(target) then return nil, "invalid_position" end
    options = Copy(options or {})
    target = Copy(target)
    target.mapID = target.mapID or target.uiMapID
    target.title = options.name or target.title or self:GetText("RUN_WAYPOINT")
    target.subtext = options.subtext or target.subtext
    target.token = options.token or target.token
    target.source, target.kind = target.source or "LibAPRNavigation.manual", target.kind or "guide_goal"
    target.transient = true
    options.guideMode = "override"
    local request = Snapshot(target, options)
    local previous = self.waypointAzerothManual
    if not target.token then
        if previous and SameSnapshot(previous.request, request) then target.token = previous.target.token
        else
            Lib.waypointAzerothManualSequence = (Lib.waypointAzerothManualSequence or 0) + 1
            target.token = "LibAPRNavigation.manual:" .. Lib.waypointAzerothManualSequence
        end
    end
    local connected, reason = self:ConnectAzerothWaypoint()
    if not connected then return nil, reason end
    if Combat(self) then return nil, "waypoint_combat" end
    self.waypointAzerothManual = { target = target, options = options, request = request }
    local refreshed
    refreshed, reason = self:RefreshAzerothWaypoint()
    if not refreshed then
        self.waypointAzerothManual = previous
        return nil, reason
    end
    return target
end

function Instance:ClearManualAzerothWaypoint()
    local manual = self.waypointAzerothManual
    if not manual then return false end
    self.waypointAzerothManual = nil
    local released, reason = self:ReleaseAzerothWaypoint()
    return released, reason
end

function Instance:RefreshAzerothWaypoint()
    local state = self.waypointAzeroth
    if state and state.pendingRelease then
        local released, reason = self:ReleaseAzerothWaypoint()
        if not released then return true, reason end
    end
    local connected, reason = self:ConnectAzerothWaypoint()
    if not connected then return false, reason end
    state = self.waypointAzeroth
    if Combat(self) then return true, "waypoint_combat" end
    local target, options = ReadTarget(self)
    local snapshot
    if (type(target) == "table" and getmetatable(target) ~= nil) or getmetatable(options) ~= nil then
        -- Accessors may change on every read. Preserve the original single
        -- capture, including metatables protected by a false public marker.
        snapshot = Snapshot(target, options)
        if SameSnapshot(state.snapshot, snapshot) then return true end
    else
        -- Ordinary host tables may mutate in place. Compare their values before
        -- allocating a capture, and copy only a changed request.
        if SameTargetSnapshot(state.snapshot, target, options) then return true end
        snapshot = Snapshot(target, options)
    end
    local ok, scheduled = pcall(state.ns.ScheduleGuideProviderEvaluation, state.id, "LibAPRNavigation")
    if not ok then return false, "azeroth_waypoint_error" end
    if scheduled == false then return false, "azeroth_waypoint_unavailable" end
    state.snapshot, state.active = snapshot, true
    return true
end

function Instance:ReleaseAzerothWaypoint()
    local state = self.waypointAzeroth
    if not state then return true end
    state.snapshot = nil
    if not state.active and not state.pendingRelease then return true end
    if Combat(self) then state.pendingRelease = true; return false, "waypoint_combat" end
    -- Another consumer may have replaced this provider while we were paused.
    -- Leave its route and adapter alone; our inactive wrapper remains harmless.
    local ok, provider = pcall(state.ns.GetGuideTargetProvider, state.id)
    if not ok then state.pendingRelease = true; return false, "azeroth_waypoint_error" end
    if provider == state.adapter then
        ok = pcall(state.ns.ClearGuideRouteState, state.id)
        if not ok then state.pendingRelease = true; return false, "azeroth_waypoint_error" end
    end
    state.active, state.pendingRelease = nil, nil
    return true
end
