-- Optional waypoint output. A consumer may publish explicitly or enable an
-- observer of its current target; route progression always belongs to the host.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("waypoint-ui", 4) then return end
local Instance = Lib.Instance
local visualKeys = { "name", "iconTexture", "iconType", "r", "g", "b", "requestRecolor", "stripCoordinates" }

local function Finite(value)
    local secret = rawget(_G, "issecretvalue")
    if type(secret) == "function" then
        local ok, hidden = pcall(secret, value)
        if not ok or hidden then return false end
    end
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function MapID(value)
    return Finite(value) and value > 0 and value % 1 == 0
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
end

local function GlobalMethod(group, method)
    local api = rawget(_G, group)
    return type(api) == "table" and api[method]
end

local function SamePosition(a, b)
    return a and b and Finite(a.mapID) and Finite(b.mapID) and a.mapID == b.mapID and Finite(a.x) and Finite(a.y)
        and Finite(b.x) and Finite(b.y) and math.abs(a.x - b.x) < 0.0005 and math.abs(a.y - b.y) < 0.0005
end

local function NativeWaypoint(instance)
    if instance.env.getNativeWaypoint then return Call(instance.env.getNativeWaypoint) end
    local point = Call(GlobalMethod("C_Map", "GetUserWaypoint"))
    return point and point.position and { mapID = point.uiMapID, x = point.position.x, y = point.position.y }
end

local function PathTracked(api)
    return Call(api.IsPathStepWaypointTracked) == true
end

function Instance:IsWaypointCombatLocked()
    return Call(self.env.isWaypointCombatLocked or rawget(_G, "InCombatLockdown")) == true
end

local function NativeSourceEnabled(instance)
    local setting = instance.waypointOptions and instance.waypointOptions.nativeSupportSetting
    local settings = rawget(_G, "WaypointDB_Global")
    return setting and type(settings) == "table" and settings[setting] == true
end

local function RelevantTracking(instance, target)
    if instance.env.isWaypointTrackingRelevant then return Call(instance.env.isWaypointTrackingRelevant, target) == true end
    if Call(GlobalMethod("C_SuperTrack", "IsSuperTrackingAnything")) ~= true then return false end
    local x, y = Call(GlobalMethod("C_Navigation", "GetNextWaypointForMap")
        or GlobalMethod("C_SuperTrack", "GetNextWaypointForMap"), target.mapID)
    return SamePosition(target, { mapID = target.mapID, x = x, y = y })
end

local function NavigationAPI(instance)
    local api
    if instance.env.getWaypointUIAPI then
        local ok, value = pcall(instance.env.getWaypointUIAPI)
        if not ok then return nil, "waypoint_ui_error" end
        api = value
    else
        -- Waypoint UI may load after an addon embedding the library. This is
        -- resolved only when waypoint output is requested.
        api = rawget(_G, "WaypointUIAPI")
    end
    local navigation = type(api) == "table" and api.Navigation
    if type(navigation) ~= "table" or type(navigation.NewUserNavigation) ~= "function"
        or type(navigation.GetUserNavigation) ~= "function" or type(navigation.ClearUserNavigation) ~= "function" then
        return nil, "waypoint_ui_unavailable"
    end
    return navigation
end

local function MapPosition(instance, position, anyMap)
    if type(position) ~= "table" or not Finite(position.x) or not Finite(position.y) then
        return nil, "invalid_position"
    end
    local mapID, x, y = position.uiMapID or position.mapID, position.x, position.y
    local mapSpace = position.space == "map" or (position.mapID ~= nil and position.space ~= "world")
    if not mapSpace then
        -- Planner endpoints use world coordinates, even when they carry a map
        -- hint. They must never be mistaken for normalized map coordinates.
        if not Finite(position.instanceID) then return nil, "invalid_position" end
        if type(instance.env.worldToMap) ~= "function" then return nil, "projection_unavailable" end
        local ok
        ok, mapID, x, y = pcall(instance.env.worldToMap, position.instanceID, x, y, mapID)
        if not ok then return nil, "projection_unavailable" end
    end
    if not MapID(mapID) or not Finite(x) or not Finite(y) or x < 0 or x > 1 or y < 0 or y > 1 then
        return nil, mapSpace and "invalid_position" or "projection_unavailable"
    end
    local canSet = not anyMap and (instance.env.canSetWaypointOnMap or GlobalMethod("C_Map", "CanSetUserWaypointOnMap"))
    local seen, world = nil, position.worldPosition
    while canSet and Call(canSet, mapID) ~= true do
        seen = seen or {}
        if seen[mapID] then return nil, "projection_unavailable" end
        seen[mapID] = true
        local info = Call(instance.env.getMapInfo or GlobalMethod("C_Map", "GetMapInfo"), mapID)
        local parent = info and info.parentMapID
        if not MapID(parent) then return nil, "projection_unavailable" end
        local minX, maxX, minY, maxY = Call(instance.env.getMapRectOnMap
            or GlobalMethod("C_Map", "GetMapRectOnMap"), mapID, parent)
        if Finite(minX) and Finite(maxX) and Finite(minY) and Finite(maxY) and maxX > minX and maxY > minY then
            mapID, x, y = parent, minX + x * (maxX - minX), minY + y * (maxY - minY)
        else
            if not world then
                local worldID, worldX, worldY
                if mapSpace and instance.env.mapToWorld then worldID, worldX, worldY = Call(instance.env.mapToWorld, mapID, x, y)
                elseif not mapSpace then worldID, worldX, worldY = position.instanceID, position.x, position.y end
                world = { instanceID = worldID, x = worldX, y = worldY }
            end
            if not world or not Finite(world.instanceID) or not Finite(world.x)
                or not Finite(world.y) or not instance.env.worldToMap then return nil, "projection_unavailable" end
            mapID, x, y = Call(instance.env.worldToMap, world.instanceID, world.x, world.y, parent)
            if mapID ~= parent or not Finite(x) or not Finite(y) or x < 0 or x > 1 or y < 0 or y > 1 then
                return nil, "projection_unavailable"
            end
        end
    end
    return { mapID = mapID, x = x * 100, y = y * 100 }
end

local function SameRequest(a, b)
    if a.mapID ~= b.mapID or a.x ~= b.x or a.y ~= b.y or a.suppressAudio ~= b.suppressAudio
        or a.token ~= b.token then return false end
    for _, key in ipairs(visualKeys) do if a[key] ~= b[key] then return false end end
    return true
end

local function OwnsWaypoint(state, current)
    local point = state.point
    return current == state.session and type(current) == "table" and current.flags == state.flag
        and current.mapID == point.mapID and current.x == point.x and current.y == point.y
end

local ClearWaypoint
local function PublishWaypoint(self, position, options, automatic)
    if options ~= nil and type(options) ~= "table" then return nil, "invalid_options" end
    options = options or {}
    local request, reason = MapPosition(self, position)
    if not request then return nil, reason end
    local api
    api, reason = NavigationAPI(self)
    if not api then return nil, reason end
    for _, key in ipairs(visualKeys) do request[key] = options[key] end
    request.name = request.name or position.title or self:GetText("RUN_WAYPOINT")
    request.token = options.token or position.token
    request.suppressAudio = options.suppressAudio ~= false
    -- The host has already selected the active leg. Avoid another planner
    -- immediately replacing it when Waypoint UI receives this request.
    request.suppressPathfinding = true

    local state = self.waypointUI
    local ok, current = pcall(api.GetUserNavigation)
    if not ok then return nil, "waypoint_ui_error" end
    if automatic then
        if state and (state.api ~= api or not OwnsWaypoint(state, current)) then
            self.waypointDismissedToken, self.waypointUI = state.token, nil
            state = nil
        end
        local token = request.token or automatic.target
        if self.waypointDismissedToken == token then return nil, "waypoint_replaced" end
        if NativeSourceEnabled(self) then ClearWaypoint(self); return nil, "waypoint_native_source" end
        if state then
            local native = NativeWaypoint(self)
            if (native and not SamePosition(native, state.session) and not PathTracked(api))
                or state.session.superTracked == false then
                self.waypointDismissedToken = token
                ClearWaypoint(self)
                return nil, "waypoint_replaced"
            end
        elseif current or NativeWaypoint(self) then return nil, "waypoint_occupied"
        elseif RelevantTracking(self, { mapID = request.mapID, x = request.x / 100, y = request.y / 100 }) then
            return nil, "waypoint_already_tracked"
        end
    end
    if state and state.api == api and SameRequest(state.request, request) then
        if OwnsWaypoint(state, current) then
            if not automatic and type(api.IsUserNavigationTracked) == "function" then
                local success, tracked = pcall(api.IsUserNavigationTracked)
                if not success then return nil, "waypoint_ui_error" end
                if tracked ~= true then return nil, "waypoint_replaced" end
            end
            return current
        end
        -- Repeated frame updates must respect a manually cleared/replaced pin.
        -- ClearWaypoint resets the publication before an explicit retry.
        return nil, "waypoint_replaced"
    end
    if self:IsWaypointCombatLocked() then return nil, "waypoint_combat" end
    if not self.waypointUIFlag then
        Lib.waypointSequence = (Lib.waypointSequence or 0) + 1
        self.waypointUIFlag = "LibAPRNavigation-1.0:" .. Lib.waypointSequence
    end
    request.flags = self.waypointUIFlag
    -- Keep our comparison independent from provider mutations of its input.
    local savedRequest = {}
    for key, value in pairs(request) do savedRequest[key] = value end
    local ok, point = pcall(api.NewUserNavigation, request)
    if not ok then return nil, "waypoint_ui_error" end
    if type(point) ~= "table" then return nil, "waypoint_rejected" end
    self.waypointUI = { api = api, flag = self.waypointUIFlag, request = savedRequest, session = point,
        token = request.token or (automatic and automatic.target),
        point = { mapID = point.mapID, x = point.x, y = point.y } }
    return point
end

ClearWaypoint = function(self)
    local state = self.waypointUI
    if not state then return false end
    local ok, current = pcall(state.api.GetUserNavigation)
    if not ok then return false, "waypoint_ui_error" end
    if not OwnsWaypoint(state, current) then
        self.waypointUI = nil
        return false
    end
    if self:IsWaypointCombatLocked() then return false, "waypoint_combat" end
    -- WUI session validation can lag behind a changed native waypoint. Only
    -- remove the native marker when WUI confirms this session is still tracked.
    local tracked = false
    if type(state.api.IsUserNavigationTracked) == "function" then
        local success, value = pcall(state.api.IsUserNavigationTracked)
        tracked = success and value == true
    end
    local native = NativeWaypoint(self)
    local preserve = native and not SamePosition(native, current) or (not native and not tracked)
    if PathTracked(state.api) then preserve = false end
    -- No sourcePinID is created here. The second argument would also suppress
    -- Waypoint UI's path cleanup, so let its normal destination cleanup run.
    ok = pcall(state.api.ClearUserNavigation, preserve or nil)
    if not ok then return false, "waypoint_ui_error" end
    self.waypointUI = nil
    return true
end

local function PublishSegment(self, segment, options, automatic)
    if segment ~= nil and type(segment) ~= "table" then return nil, "invalid_position" end
    if options ~= nil and type(options) ~= "table" then return nil, "invalid_options" end
    if not segment or (segment.sourceFree and segment.action) then
        local _, reason = ClearWaypoint(self)
        return nil, reason or "no_waypoint"
    end
    local source, target = segment.from, segment.to
    local walking = segment.kind == "walk" or (segment.kind == "passage"
        and type(source) == "table" and type(target) == "table"
        and source.instanceID ~= nil and source.instanceID == target.instanceID)
    local output = {}
    for key, value in pairs(options or {}) do output[key] = value end
    output.name = output.name or segment.instruction
    local point = source
    if walking then point = target end
    return PublishWaypoint(self, point, output, automatic)
end

local function ManualOverride(instance)
    local automatic = instance.waypointUIAutomatic
    if instance.waypointUIEnabled and automatic then
        automatic.manualOverride, automatic.ownedWaypoint = true, nil
        automatic.point, automatic.reason = nil, "waypoint_manual_override"
    end
end

function Instance:SetWaypoint(position, options)
    if self.PublishAzerothWaypoint and self.waypointOptions and self.waypointOptions.guideProviderID then
        local target, invalid = self:GetWaypointMapTarget(position, options)
        if not target then return nil, invalid end
        local point, reason = self:PublishAzerothWaypoint(target, options)
        if point then
            local _, cleanupReason = ClearWaypoint(self)
            self.waypointPendingRelease = cleanupReason ~= nil
            ManualOverride(self)
            return point, cleanupReason
        end
        if reason == "waypoint_combat" then return nil, reason end
        if self.ClearManualAzerothWaypoint then
            local _, cleanupReason = self:ClearManualAzerothWaypoint()
            if cleanupReason then self.waypointAWPending = true; return nil, cleanupReason end
        end
        local released, cleanupReason = self:ReleaseAzerothWaypoint()
        if not released then self.waypointAWPending = true; return nil, cleanupReason end
    end
    local point, reason = PublishWaypoint(self, position, options)
    if point then ManualOverride(self) end
    return point, reason
end

function Instance:ClearWaypoint()
    local cleared, reason = ClearWaypoint(self)
    if self.ClearManualAzerothWaypoint then
        local awCleared, awReason = self:ClearManualAzerothWaypoint()
        cleared, reason = cleared or awCleared, reason or awReason
    end
    if self.ReleaseAzerothWaypoint then
        local released, awReason = self:ReleaseAzerothWaypoint()
        self.waypointAWPending = released == false
        reason = reason or awReason
    end
    self.waypointPendingRelease = reason ~= nil and self.waypointUI ~= nil
    if not reason or reason == "waypoint_combat" then ManualOverride(self) end
    return cleared, reason
end

function Instance:SetWaypointForSegment(segment, options)
    if options ~= nil and type(options) ~= "table" then return nil, "invalid_options" end
    if self.PublishAzerothWaypoint and self.waypointOptions and self.waypointOptions.guideProviderID then
        if segment == nil or (type(segment) == "table" and segment.sourceFree and segment.action) then
            local _, reason = self:ClearWaypoint()
            return nil, reason or "no_waypoint"
        end
        local target, invalid = self:GetWaypointMapTarget(segment, options)
        if not target then return nil, invalid end
        return self:SetWaypoint(target, options)
    end
    local point, reason = PublishSegment(self, segment, options)
    if point or reason == "no_waypoint" then ManualOverride(self) end
    return point, reason
end

local positionKeys = { "space", "mapID", "uiMapID", "instanceID", "x", "y", "z", "token", "title", "subtext" }
local function PositionSnapshot(position)
    if type(position) ~= "table" then return position end
    local result = {}
    for _, key in ipairs(positionKeys) do result[key] = position[key] end
    return result
end

local function IsSegment(target)
    return type(target) == "table" and (target.from ~= nil or target.to ~= nil)
end

function Instance:GetWaypointMapTarget(target, options)
    if options ~= nil and type(options) ~= "table" then return nil, "invalid_options" end
    options = options or {}
    if type(target) ~= "table" then return nil, "invalid_position" end
    if target.sourceFree and target.action then return nil, "no_waypoint" end
    local position = target
    if IsSegment(target) then
        local source, destination = target.from, target.to
        local walking = target.kind == "walk" or (target.kind == "passage"
            and type(source) == "table" and type(destination) == "table"
            and source.instanceID ~= nil and source.instanceID == destination.instanceID)
        position = source
        if walking then position = destination end
    end
    local point, reason = MapPosition(self, position, true)
    if not point then return nil, reason end
    local normalized = {}
    for key, value in pairs(target) do normalized[key] = value end
    normalized.from, normalized.to = nil, nil
    normalized.space, normalized.uiMapID = "map", point.mapID
    normalized.mapID, normalized.x, normalized.y = point.mapID, point.x / 100, point.y / 100
    normalized.title = options.title or target.title or options.name or target.instruction or self:GetText("RUN_WAYPOINT")
    normalized.subtext, normalized.token = options.subtext or target.subtext, options.token or target.token
    if not normalized.worldPosition and position.space ~= "map" and position.mapID == nil then
        normalized.worldPosition = { instanceID = position.instanceID, x = position.x, y = position.y }
    end
    return normalized
end

local function TargetSnapshot(target, options)
    local result = { options = {} }
    if IsSegment(target) then
        local action = target.action
        result.target = { kind = target.kind, sourceFree = target.sourceFree,
            instruction = target.instruction, from = PositionSnapshot(target.from), to = PositionSnapshot(target.to),
            action = type(action) == "table" and { type = action.type, id = action.id, data = action.data } or action }
    else result.target = PositionSnapshot(target) end
    for _, key in ipairs(visualKeys) do result.options[key] = options and options[key] end
    result.options.suppressAudio = not options or options.suppressAudio ~= false
    result.options.context = options and options.context
    result.options.token = options and options.token
    result.options.guideMode = options and options.guideMode
    return result
end

function Instance:GetWaypointTargetState()
    if not self.waypointUIEnabled then return nil, { guideMode = "blocked" }, "waypoint_ui_disabled" end
    if type(self.env.getWaypointTarget) ~= "function" then return nil, { guideMode = "blocked" }, "waypoint_target_unavailable" end
    local ok, target, options = pcall(self.env.getWaypointTarget)
    if not ok then return nil, { guideMode = "blocked" }, "waypoint_target_error" end
    if options ~= nil and type(options) ~= "table" then return nil, { guideMode = "blocked" }, "invalid_options" end
    options = options or {}
    if self.waypointCancelledContext ~= nil then
        if self.waypointCancelledContext == options.context then
            local blocked = {}
            for key, value in pairs(options) do blocked[key] = value end
            blocked.guideMode = "blocked"
            return nil, blocked
        end
        self.waypointCancelledContext = nil
    end
    return target, options
end

local function SameSnapshot(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not SameSnapshot(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local positionFields, optionFields = {}, { context = true, token = true, guideMode = true }
for _, key in ipairs(positionKeys) do positionFields[key] = true end
for _, key in ipairs(visualKeys) do optionFields[key] = true end
local segmentFields = { kind = true, sourceFree = true, instruction = true, from = true, to = true, action = true }
local actionFields = { type = true, id = true, data = true }

local function SameFields(snapshot, source, fields)
    if type(snapshot) ~= "table" or type(source) ~= "table" then return SameSnapshot(source, snapshot) end
    for key in pairs(fields) do
        local value, previous = source[key], snapshot[key]
        if value == nil then
            if previous ~= nil then return false end
        elseif type(value) == "table" then
            if not SameSnapshot(value, previous) then return false end
        elseif value ~= previous then return false end
    end
    for key in pairs(snapshot) do if not fields[key] then return false end end
    return true
end

local function SameTargetSnapshot(snapshot, target, options)
    if type(snapshot) ~= "table" or type(snapshot.options) ~= "table" then return false end
    local captured = snapshot.target
    if IsSegment(target) then
        if type(captured) ~= "table" then return false end
        for key in pairs(segmentFields) do
            local source, previous = target[key], captured[key]
            if key == "from" or key == "to" then
                if not SameFields(previous, source, positionFields) then return false end
            elseif key == "action" then
                if not SameFields(previous, source, actionFields) then return false end
            elseif not SameSnapshot(source, previous) then return false end
        end
        for key in pairs(captured) do if not segmentFields[key] then return false end end
    elseif not SameFields(captured, target, positionFields) then return false end
    local capturedOptions = snapshot.options
    if capturedOptions.suppressAudio ~= (options.suppressAudio ~= false) then return false end
    for key in pairs(optionFields) do
        local value, previous = options[key], capturedOptions[key]
        if value == nil then
            if previous ~= nil then return false end
        elseif type(value) == "table" then
            if not SameSnapshot(value, previous) then return false end
        elseif value ~= previous then return false end
    end
    for key in pairs(capturedOptions) do
        if key ~= "suppressAudio" and not optionFields[key] then return false end
    end
    return true
end

local function NeedsCapture(target, options)
    if getmetatable(options) ~= nil then return true end
    if type(target) ~= "table" then return false end
    if getmetatable(target) ~= nil then return true end
    if IsSegment(target) then
        local source, destination, action = target.from, target.to, target.action
        return (type(source) == "table" and getmetatable(source) ~= nil)
            or (type(destination) == "table" and getmetatable(destination) ~= nil)
            or (type(action) == "table" and getmetatable(action) ~= nil)
    end
end

local function ClearAutomatic(instance, automatic)
    if not automatic.ownedWaypoint or instance.waypointUI ~= automatic.ownedWaypoint then
        automatic.ownedWaypoint = nil
        return nil
    end
    local _, reason = ClearWaypoint(instance)
    if not reason then automatic.ownedWaypoint = nil end
    return reason
end

function Instance:GetWaypointUIStatus()
    local automatic = self.waypointUIAutomatic
    if not automatic then return nil, "waypoint_ui_disabled" end
    return automatic.point, automatic.reason
end

local function RefreshAutomatic(self, automatic)
    local generation = automatic.generation
    local target, options, errorReason = self:GetWaypointTargetState()
    -- A host callback may disable or restart automatic output while sampled.
    if not self.waypointUIEnabled or automatic.generation ~= generation then return self:GetWaypointUIStatus() end
    if errorReason then
        automatic.reason = errorReason
        return automatic.point, automatic.reason
    end
    local snapshot, unchanged
    if NeedsCapture(target, options) then
        -- A changing accessor must be sampled once, including protected
        -- metatables whose public marker is false.
        snapshot = TargetSnapshot(target, options)
        unchanged = automatic.hasTarget and SameSnapshot(snapshot, automatic.target)
    else
        -- Plain host tables may mutate in place. Compare the captured fields
        -- before allocating a new snapshot; still validate/publish every tick.
        unchanged = automatic.hasTarget and SameTargetSnapshot(automatic.target, target, options)
        if not unchanged then snapshot = TargetSnapshot(target, options) end
    end
    if not unchanged then
        if self.ClearManualAzerothWaypoint and self.waypointAzerothManual then
            local _, reason = self:ClearManualAzerothWaypoint()
            self.waypointAWPending = reason ~= nil
        end
        automatic.hasTarget, automatic.target, automatic.manualOverride = true, snapshot, nil
    end
    if automatic.manualOverride then
        automatic.point, automatic.reason = nil, "waypoint_manual_override"
        return nil, automatic.reason
    end
    local point, reason
    if options.guideMode == "blocked" then
        if self.ReleaseAzerothWaypoint then
            local released, awReason = self:ReleaseAzerothWaypoint()
            self.waypointAWPending = released == false
            reason = awReason
        end
        reason = ClearAutomatic(self, automatic) or reason or "no_waypoint"
        automatic.point, automatic.reason = nil, reason
        return nil, reason
    end
    if self.RefreshAzerothWaypoint and self:RefreshAzerothWaypoint() then
        reason = ClearAutomatic(self, automatic)
        automatic.point, automatic.reason = target, reason or automatic.schedulerReason
        return automatic.point, automatic.reason
    end
    if self.ReleaseAzerothWaypoint then
        local released, awReason = self:ReleaseAzerothWaypoint()
        if not released then
            self.waypointAWPending = true
            automatic.reason = awReason
            return automatic.point, awReason
        end
    end
    if target == nil or options.guideMode == "blocked" or (type(target) == "table" and target.sourceFree and target.action) then
        reason = ClearAutomatic(self, automatic) or "no_waypoint"
    elseif IsSegment(target) then
        point, reason = PublishSegment(self, target, options, automatic)
    else
        point, reason = PublishWaypoint(self, target, options, automatic)
    end
    if point then automatic.ownedWaypoint = self.waypointUI end
    automatic.point, automatic.reason = point, reason or automatic.schedulerReason
    return automatic.point, automatic.reason
end

local function StopTicker(automatic)
    if automatic.ticker then pcall(automatic.cancelTicker, automatic.ticker) end
    automatic.ticker, automatic.cancelTicker = nil, nil
    automatic.generation = automatic.generation + 1
end

function Instance:ReleaseWaypoints(suppressContext)
    local automatic = self.waypointUIAutomatic
    if suppressContext then
        local _, options = self:GetWaypointTargetState()
        self.waypointCancelledContext = options and options.context
    end
    if self.ClearManualAzerothWaypoint then self:ClearManualAzerothWaypoint() end
    local _, reason = ClearWaypoint(self)
    self.waypointPendingRelease = reason ~= nil
    if self.ReleaseAzerothWaypoint then
        local released, awReason = self:ReleaseAzerothWaypoint()
        self.waypointAWPending = released == false
        reason = reason or awReason
    end
    if automatic then
        automatic.point, automatic.ownedWaypoint = nil, nil
        automatic.hasTarget, automatic.target = nil, nil
        automatic.reason = reason or "no_waypoint"
    end
    return reason == nil, reason
end

local function FlushRelease(instance)
    if instance.waypointPendingRelease then
        local _, reason = ClearWaypoint(instance)
        instance.waypointPendingRelease = reason ~= nil
    end
    if instance.waypointAWPending and instance.ReleaseAzerothWaypoint then
        instance.waypointAWPending = instance:ReleaseAzerothWaypoint() == false
    end
    return instance.waypointPendingRelease or instance.waypointAWPending
end

function Instance:RefreshWaypointUI()
    local automatic = self.waypointUIAutomatic
    if not automatic then return nil, "waypoint_ui_disabled" end
    if automatic.refreshing then return automatic.point, automatic.reason end
    local pending = FlushRelease(self)
    if not self.waypointUIEnabled then
        if not pending then StopTicker(automatic) end
        return nil, automatic.reason or "waypoint_ui_disabled"
    end
    automatic.refreshing = true
    local ok, point, reason = pcall(RefreshAutomatic, self, automatic)
    automatic.refreshing = nil
    if not ok then
        automatic.reason = "waypoint_ui_error"
        return automatic.point, automatic.reason
    end
    return point, reason
end

function Instance:SetWaypointUIEnabled(enabled)
    local automatic = self.waypointUIAutomatic
    if enabled ~= true then
        self.waypointUIEnabled = false
        if not automatic then return nil, "waypoint_ui_disabled" end
        local reason = ClearAutomatic(self, automatic)
        self.waypointPendingRelease = reason ~= nil
        if self.ReleaseAzerothWaypoint and not self.waypointAzerothManual then
            local released, awReason = self:ReleaseAzerothWaypoint()
            self.waypointAWPending = released == false
            reason = reason or awReason
        end
        if not self.waypointPendingRelease and not self.waypointAWPending then StopTicker(automatic) end
        automatic.point, automatic.reason = nil, reason or "waypoint_ui_disabled"
        return nil, automatic.reason
    end
    if self.waypointUIEnabled and automatic then return self:RefreshWaypointUI() end
    automatic = automatic or { generation = 0 }
    if automatic.ticker then StopTicker(automatic) end
    self.waypointUIAutomatic, self.waypointUIEnabled = automatic, true
    automatic.generation = automatic.generation + 1
    automatic.hasTarget, automatic.manualOverride, automatic.schedulerReason = nil, nil, nil
    self.waypointCancelledContext, self.waypointDismissedToken = nil, nil
    local generation = automatic.generation
    local createTicker = self.env.newWaypointTicker
    if createTicker == nil then
        local timers = rawget(_G, "C_Timer")
        createTicker = type(timers) == "table" and timers.NewTicker
    end
    if type(createTicker) == "function" then
        local ok, ticker = pcall(createTicker, 0.2, function()
            if automatic.generation == generation then self:RefreshWaypointUI() end
        end)
        if ok and (type(ticker) == "table" or type(ticker) == "userdata") and type(ticker.Cancel) == "function" then
            automatic.ticker, automatic.cancelTicker = ticker, ticker.Cancel
        else automatic.schedulerReason = ok and "waypoint_scheduler_unavailable" or "waypoint_scheduler_error" end
    else automatic.schedulerReason = "waypoint_scheduler_unavailable" end
    return self:RefreshWaypointUI()
end

Instance.RefreshWaypoints = Instance.RefreshWaypointUI
Instance.SetWaypointsEnabled = Instance.SetWaypointUIEnabled
Instance.GetWaypointStatus = Instance.GetWaypointUIStatus
